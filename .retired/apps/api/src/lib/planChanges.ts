import {
  LIMIT_KEYS,
  addBillingPeriod,
  classifyPlanChange,
  isImmediate,
  quoteImmediateChange,
  type BillingCycle,
  type LimitKey,
  type PlanChangeKind,
  type PlanLimits,
} from '@syniastrolms/domain';
import type { PlanChange as PlanChangeRow } from '@prisma/client';

import { BILLING_AUDIT_ACTIONS, recordAuditLog } from './audit.js';
import { now } from './clock.js';
import { db } from './db.js';
import { getUsage } from './entitlements.js';
import { getBillingProfile, payableForAmount } from './billing.js';
import { forbidden, notFound } from './errors.js';
import { writeJson } from './json.js';
import { PlanUnavailableError, planForNewSubscription } from './plans.js';
import {
  InvalidSubscriptionStateError,
  assertPersonMay,
  loadSubscriptionRow,
  periodMeta,
  transition,
  withinAcademy,
  type LifecycleActor,
  type SubscriptionRecord,
} from './subscriptions.js';

/*
 * Plan changes (SAAS-006) — decisions D7, D8 and D10, as written in docs/06 › Plan changes before this
 * file was. The only writer of PlanChange.
 *
 *   requestPlanChange       a person asks to move a subscription to another plan or cycle
 *   confirmPlanChangePayment a verified provider payment settles an upgrade quote, and only then does
 *                           the subscription move (D7: never on a frontend callback)
 *   applyDueScheduledChange the scheduler applies a downgrade at the period boundary (D10)
 *   cancelPlanChange        a person withdraws an open change
 *
 * Every figure is integer paise from `packages/domain/src/planChange.ts`, calculated here on the server
 * from the subscription as stored and the plan version as published — nothing in a request is a price.
 * A quote's figures are never altered (triggers); the subscription changes only through its
 * `change_plan` transition, which names the change it applies.
 */

export type PlanChangeStatus = 'pending_payment' | 'scheduled' | 'applied' | 'canceled' | 'void' | 'expired';

export interface LimitConflict {
  limit: LimitKey;
  /** What the academy uses now. */
  usage: number;
  /** What the new plan allows. */
  newLimit: number;
}

export interface PlanChangeRecord {
  id: string;
  subscriptionId: string;
  kind: PlanChangeKind;
  status: PlanChangeStatus;
  from: { planVersionId: string; cycle: BillingCycle; amount: number };
  to: { planId: string; planVersionId: string; cycle: BillingCycle; amount: number };
  currency: string;
  /** Minor units: the unused value credited, what is charged, and credit that could not be used. */
  credit: number;
  charge: number;
  forfeited: number;
  /** The period the change was priced against; a scheduled change applies when it ends. */
  period: { start: string; end: string };
  quotedAt: string;
  /** Limits the academy already exceeds on the new plan. Its data stays; new usage past them is refused. */
  conflicts: LimitConflict[];
  appliedAt?: string;
  closedAt?: string;
  closedReason?: string;
}

function toRecord(row: PlanChangeRow): PlanChangeRecord {
  return {
    id: row.id,
    subscriptionId: row.subscriptionId,
    kind: row.kind as PlanChangeKind,
    status: row.status as PlanChangeStatus,
    from: { planVersionId: row.fromPlanVersionId, cycle: row.fromCycle as BillingCycle, amount: row.fromAmount },
    to: { planId: row.toPlanId, planVersionId: row.toPlanVersionId, cycle: row.toCycle as BillingCycle, amount: row.toAmount },
    currency: row.currency,
    credit: row.credit,
    charge: row.charge,
    forfeited: row.forfeited,
    period: { start: row.periodStartAt.toISOString(), end: row.periodEndAt.toISOString() },
    quotedAt: row.quotedAt.toISOString(),
    conflicts: JSON.parse(row.conflictsJson) as LimitConflict[],
    ...(row.appliedAt ? { appliedAt: row.appliedAt.toISOString() } : {}),
    ...(row.closedAt ? { closedAt: row.closedAt.toISOString() } : {}),
    ...(row.closedReason ? { closedReason: row.closedReason } : {}),
  };
}

const OPEN: PlanChangeStatus[] = ['pending_payment', 'scheduled'];

/** A change by id, found from the caller's own context — so an academy finds only its own. */
async function loadChange(id: string): Promise<PlanChangeRow> {
  const row = await db.planChange.findUnique({ where: { id } });
  if (!row) throw notFound('Plan change not found.');
  return row;
}

/** Limits the academy already exceeds under `limits` (D10: its data stays; it is told). */
async function limitConflicts(tenantId: string, limits: PlanLimits): Promise<LimitConflict[]> {
  const conflicts: LimitConflict[] = [];
  for (const limit of LIMIT_KEYS) {
    const newLimit = limits[limit];
    if (newLimit === null) continue;
    const usage = await getUsage(tenantId, limit, now());
    if (usage > newLimit) conflicts.push({ limit, usage, newLimit });
  }
  return conflicts;
}

/* ─── Requesting ───────────────────────────────────────────────────────── */

/**
 * A person asks to move an active subscription to `planId` on `cycle`. The server works out what kind of
 * change it is and, for an upgrade, what it costs:
 *   - upgrade (dearer, same cycle) and monthly → annual: a quote in `pending_payment` — credit, charge,
 *     priced now against the current period — which applies only once the payment is confirmed;
 *   - anything else: `scheduled` for the period boundary, with no money and the limit conflicts noted.
 * Refused during a trial (nothing has been paid to prorate), in any status but active, while another
 * change is open, for a plan not on sale, and across currencies.
 */
/** A change asked for as a downgrade is in fact an upgrade: charged now, so refused before anything is written. */
export class UnexpectedUpgradeError extends InvalidSubscriptionStateError {
  constructor() {
    super('That change is an upgrade: it is charged now. Ask for an upgrade instead.');
    this.name = 'UnexpectedUpgradeError';
  }
}

/** What a change would be and cost, worked out without writing anything: the same rules a request applies. */
async function priceChange(actor: LifecycleActor, subscriptionId: string, input: { planId: string; cycle: BillingCycle }, expect?: 'upgrade' | 'downgrade') {
  if (actor.type !== 'user') throw forbidden('A plan change is asked for by a person.');
  const sub = await loadSubscriptionRow(subscriptionId);
  assertPersonMay(actor, sub.tenantId, 'change this subscription’s plan');
  if (sub.status === 'trialing') throw new InvalidSubscriptionStateError('A trial’s plan cannot change: nothing has been paid yet. Convert the trial first.');
  if (sub.status !== 'active') throw new InvalidSubscriptionStateError(`A ${sub.status.replace('_', ' ')} subscription cannot change plan.`);
  const open = await withinAcademy(sub.tenantId, () => db.planChange.findFirst({ where: { subscriptionId, status: { in: OPEN } }, select: { id: true } }));
  if (open) throw new InvalidSubscriptionStateError('A plan change is already open on this subscription. Cancel it first.');

  const sale = await planForNewSubscription(input.planId, input.cycle);
  if (sale.version.currency !== sub.currency)
    throw new PlanUnavailableError(`${sale.plan.name} is priced in ${sale.version.currency}; this subscription is in ${sub.currency}.`);
  const current = { planVersionId: sub.planVersionId, cycle: sub.billingCycle as BillingCycle, amount: sub.amount };
  const kind = classifyPlanChange(current, { planVersionId: sale.version.id, cycle: input.cycle, amount: sale.amount });
  if (!kind) throw new InvalidSubscriptionStateError('The subscription is already on that plan and cycle.');
  if (expect === 'upgrade' && !isImmediate(kind))
    throw new InvalidSubscriptionStateError('That change is not an upgrade: it takes effect at the end of the period. Ask for a downgrade instead.');
  if (expect === 'downgrade' && isImmediate(kind)) throw new UnexpectedUpgradeError();

  const at = now();
  let money = { credit: 0, charge: 0, forfeited: 0 };
  if (isImmediate(kind)) {
    if (at >= sub.currentPeriodEndAt) throw new InvalidSubscriptionStateError('This billing period has ended. Renew it, then change plan.');
    const quote = quoteImmediateChange({
      kind: kind as 'upgrade' | 'cycle_upgrade',
      currentAmount: sub.amount,
      newAmount: sale.amount,
      periodStart: sub.currentPeriodStartAt,
      periodEnd: sub.currentPeriodEndAt,
      at,
    });
    money = { credit: quote.credit, charge: quote.charge, forfeited: quote.forfeited };
  }
  const conflicts = isImmediate(kind) ? [] : await limitConflicts(sub.tenantId, sale.version.limits);
  return { sub, sale, kind, money, conflicts, at };
}

export interface PlanChangePreview {
  kind: PlanChangeKind;
  /** Whether it is charged and applied now (on payment), or applies at the period boundary. */
  when: 'on_payment' | 'period_end';
  appliesAt: string;
  to: { planId: string; planName: string; cycle: BillingCycle; amount: number };
  currency: string;
  credit: number;
  charge: number;
  forfeited: number;
  /** The charge with tax at the academy's billing address; null when there is no address yet, or nothing to pay. */
  payable: { net: number; tax: number; gross: number } | null;
  needsBillingAddress: boolean;
  conflicts: LimitConflict[];
}

/**
 * What asking for this change would do, without asking: its kind, when it applies, the prorated credit and
 * charge with tax, and any limits the academy already exceeds on the new plan. Shown before the admin commits.
 */
export async function previewPlanChange(
  actor: LifecycleActor,
  subscriptionId: string,
  input: { planId: string; cycle: BillingCycle },
): Promise<PlanChangePreview> {
  const { sub, sale, kind, money, conflicts, at } = await priceChange(actor, subscriptionId, input);
  const immediate = isImmediate(kind);
  let payable: PlanChangePreview['payable'] = null;
  let needsBillingAddress = false;
  if (immediate && money.charge > 0) {
    if (await withinAcademy(sub.tenantId, () => getBillingProfile(sub.tenantId))) {
      const taxed = await withinAcademy(sub.tenantId, () => payableForAmount(sub.tenantId, money.charge, sub.currency, 'plan_change'));
      payable = { net: taxed.net, tax: taxed.tax, gross: taxed.gross };
    } else needsBillingAddress = true;
  }
  return {
    kind,
    when: immediate ? 'on_payment' : 'period_end',
    appliesAt: (immediate ? at : sub.currentPeriodEndAt).toISOString(),
    to: { planId: sale.plan.id, planName: sale.plan.name, cycle: input.cycle, amount: sale.amount },
    currency: sub.currency,
    ...money,
    payable,
    needsBillingAddress,
    conflicts,
  };
}

export async function requestPlanChange(
  actor: LifecycleActor,
  subscriptionId: string,
  input: { planId: string; cycle: BillingCycle },
  /** What the caller asked for: an `upgrade` endpoint refuses a change that is in fact a downgrade, before anything is written. */
  expect?: 'upgrade' | 'downgrade',
): Promise<PlanChangeRecord> {
  const { sub, sale, kind, money, conflicts, at } = await priceChange(actor, subscriptionId, input, expect);
  if (actor.type !== 'user') throw forbidden('A plan change is asked for by a person.');

  const row = await withinAcademy(sub.tenantId, () =>
    db.$transaction(async (tx) => {
      const created = await tx.planChange.create({
        data: {
          tenantId: sub.tenantId,
          subscriptionId,
          kind,
          status: isImmediate(kind) ? 'pending_payment' : 'scheduled',
          fromPlanVersionId: sub.planVersionId,
          fromCycle: sub.billingCycle,
          fromAmount: sub.amount,
          toPlanId: sale.plan.id,
          toPlanVersionId: sale.version.id,
          toCycle: input.cycle,
          toAmount: sale.amount,
          currency: sub.currency,
          ...money,
          periodStartAt: sub.currentPeriodStartAt,
          periodEndAt: sub.currentPeriodEndAt,
          quotedAt: at,
          conflictsJson: writeJson(conflicts),
          requestedById: actor.auth.sub,
        },
      });
      await recordAuditLog(
        { auth: actor.auth },
        {
          action: BILLING_AUDIT_ACTIONS.subscriptionPlanChangeRequested,
          targetType: 'subscription',
          targetId: subscriptionId,
          meta: { planChangeId: created.id, kind, toPlanCode: sale.plan.code, toCycle: input.cycle, ...money, conflicts },
        },
        tx,
      );
      return created;
    }),
  );
  return toRecord(row);
}

/* ─── Applying ─────────────────────────────────────────────────────────── */

/** The subscription moves to the change's version, in the `change_plan` transition that names it. */
async function apply(actor: LifecycleActor, change: PlanChangeRow, extra: { period?: { start: Date; end: Date } } = {}): Promise<SubscriptionRecord> {
  return transition(
    actor,
    change.subscriptionId,
    'change_plan',
    () => ({
      data: {
        planId: change.toPlanId,
        planVersionId: change.toPlanVersionId,
        amount: change.toAmount,
        currency: change.currency,
        billingCycle: change.toCycle,
        ...(extra.period ? { currentPeriodStartAt: extra.period.start, currentPeriodEndAt: extra.period.end } : {}),
      },
      meta: {
        planChangeId: change.id,
        kind: change.kind,
        from: { planVersionId: change.fromPlanVersionId, amount: change.fromAmount, billingCycle: change.fromCycle },
        to: { planVersionId: change.toPlanVersionId, amount: change.toAmount, currency: change.currency, billingCycle: change.toCycle },
        credit: change.credit,
        charge: change.charge,
        forfeited: change.forfeited,
        ...(extra.period ? { period: periodMeta(extra.period.start, extra.period.end) } : {}),
      },
    }),
    async (tx) => {
      const marked = await tx.planChange.updateMany({ where: { id: change.id, status: change.status }, data: { status: 'applied', appliedAt: now() } });
      if (marked.count !== 1) throw new InvalidSubscriptionStateError('This plan change was settled already.');
    },
  );
}

/** Closes an open change that can no longer apply, and says why — audited under whoever closed it. */
async function close(actor: LifecycleActor, change: PlanChangeRow, status: 'expired' | 'void' | 'canceled', reason: string) {
  await withinAcademy(change.tenantId, () =>
    db.$transaction(async (tx) => {
      const closed = await tx.planChange.updateMany({
        where: { id: change.id, status: change.status },
        data: { status, closedAt: now(), closedReason: reason },
      });
      if (closed.count !== 1) return;
      await recordAuditLog(
        actor,
        {
          action: status === 'canceled' ? BILLING_AUDIT_ACTIONS.subscriptionPlanChangeCanceled : BILLING_AUDIT_ACTIONS.subscriptionPlanChangeClosed,
          targetType: 'subscription',
          targetId: change.subscriptionId,
          meta: { tenantId: change.tenantId, planChangeId: change.id, kind: change.kind, status: { from: change.status, to: status }, reason },
        },
        tx,
      );
    }),
  );
}

/**
 * A verified provider payment settles an upgrade quote (D7, D8). Only now does the subscription move, and
 * with it the entitlements. Same cycle: the renewal date is unchanged. Monthly → annual: the annual
 * period starts now — the effective date — and renews a year later. A quote that outlived its period, or
 * a subscription that changed since it was priced, is closed instead and must be quoted again.
 */
export async function confirmPlanChangePayment(actor: LifecycleActor, changeId: string): Promise<SubscriptionRecord> {
  if (actor.type !== 'provider') throw forbidden('Only a verified payment from the provider confirms a plan change.');
  const change = await loadChange(changeId);
  if (change.status !== 'pending_payment') throw new InvalidSubscriptionStateError('This plan change is not waiting for a payment.');
  const sub = await loadSubscriptionRow(change.subscriptionId);
  const at = now();
  if (at >= change.periodEndAt) {
    await close(actor, change, 'expired', 'The billing period it was priced against ended before payment.');
    throw new InvalidSubscriptionStateError('This quote expired with its billing period. Ask for the change again.');
  }
  if (sub.status !== 'active' || sub.planVersionId !== change.fromPlanVersionId || sub.currentPeriodEndAt.getTime() !== change.periodEndAt.getTime()) {
    await close(actor, change, 'void', 'The subscription changed after the quote was made.');
    throw new InvalidSubscriptionStateError('The subscription changed after this quote was made. Ask for the change again.');
  }
  const period = change.kind === 'cycle_upgrade' ? { start: at, end: addBillingPeriod(at, change.toCycle as BillingCycle) } : undefined;
  return apply(actor, change, { period });
}

/**
 * At the period boundary the scheduler applies a scheduled change (D10): until then the academy kept its
 * current plan and entitlements; from now it has the new ones. The renewal that follows is charged at the
 * new price. Refused before the boundary. Existing data is never touched.
 */
export async function applyDueScheduledChange(actor: LifecycleActor, subscriptionId: string): Promise<SubscriptionRecord> {
  if (actor.type !== 'system') throw forbidden('The scheduler applies a scheduled plan change at the period boundary.');
  const sub = await loadSubscriptionRow(subscriptionId);
  const change = await withinAcademy(sub.tenantId, () => db.planChange.findFirst({ where: { subscriptionId, status: 'scheduled' } }));
  if (!change) throw new InvalidSubscriptionStateError('This subscription has no scheduled plan change.');
  if (now() < sub.currentPeriodEndAt) throw new InvalidSubscriptionStateError('The billing period has not ended yet; the change applies when it does.');
  if (sub.status !== 'active') {
    await close(actor, change, 'void', `The subscription is ${sub.status.replace('_', ' ')} at the boundary.`);
    throw new InvalidSubscriptionStateError('Only an active subscription takes a scheduled plan change.');
  }
  return apply(actor, change);
}

/** A person withdraws an open change — an unpaid quote or a scheduled downgrade. */
export async function cancelPlanChange(actor: LifecycleActor, changeId: string, opts: { reason?: string } = {}): Promise<PlanChangeRecord> {
  if (actor.type !== 'user') throw forbidden('A person withdraws a plan change.');
  const change = await loadChange(changeId);
  assertPersonMay(actor, change.tenantId, 'withdraw this plan change');
  if (!OPEN.includes(change.status as PlanChangeStatus)) throw new InvalidSubscriptionStateError('This plan change is no longer open.');
  await close(actor, change, 'canceled', opts.reason ?? 'Withdrawn.');
  return toRecord(await withinAcademy(change.tenantId, () => loadChange(changeId)));
}

/** A subscription's plan changes, newest first — the pricing history kept with it (D8). */
export async function listPlanChanges(subscriptionId: string): Promise<PlanChangeRecord[]> {
  const sub = await loadSubscriptionRow(subscriptionId);
  const rows = await withinAcademy(sub.tenantId, () => db.planChange.findMany({ where: { subscriptionId }, orderBy: { createdAt: 'desc' } }));
  return rows.map(toRecord);
}

export const getPlanChange = async (id: string): Promise<PlanChangeRecord> => toRecord(await loadChange(id));
