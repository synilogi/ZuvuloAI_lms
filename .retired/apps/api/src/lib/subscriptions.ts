import {
  ENTITLED_STATES,
  MAX_EXTENSION_DAYS,
  MAX_PAUSE_DAYS,
  addBillingPeriod,
  addDays,
  isTerminal,
  lifecycleEventFor,
  pauseEnd,
  pauseExtensionMs,
  nextStatus,
  transitionNamed,
  type BillingCycle,
  type Role,
  type SubscriptionState,
  type TransitionName,
} from '@syniastrolms/domain';
import type { Prisma, Subscription as SubscriptionRow } from '@prisma/client';

import { BILLING_AUDIT_ACTIONS, recordAuditLog } from './audit.js';
import { db, type DbClient } from './db.js';
import { ApiError, badRequest, conflict, forbidden, notFound } from './errors.js';
import { writeJson } from './json.js';
import { graceDays, repeatTrialsAllowed } from './billingConfig.js';
import { noticeForTransition } from './billingNotices.js';
import { now } from './clock.js';
import { observe } from './observe.js';
import { PlanUnavailableError, planForNewSubscription, resolvePlanVersion } from './plans.js';
import { currentContext, runAsPlatform, runInTenant } from './tenancy.js';

/*
 * Subscriptions (subscriptions.md §5, §6, §19) — the only writer of the Subscription and
 * SubscriptionEvent tables.
 *
 * A subscription belongs to an academy and holds the plan *version* it was sold, with the amount copied
 * from that version by the server. Its status moves only through the named transitions in
 * `packages/domain/src/lifecycle.ts`; each one writes a lifecycle event in the same transaction as the
 * status it records, event first. The database enforces the same rules (migration subscriptions): a
 * status change the latest event does not describe is refused, as is a plan or price change without a
 * matching `change_plan` event, and nothing here is ever deleted.
 *
 * Who may do what:
 *   - a person: a super admin, as the platform, or the academy's own admin, inside that academy;
 *   - the scheduler (`system`) for what time decides — a trial or a paid period running out;
 *   - a verified provider event (`provider`) for what money decides — a payment landing or failing.
 * Each transition lists which of those may cause it; a frontend callback is none of them (§43).
 *
 * Time comes from the server's clock (`lib/clock.ts`) and nowhere else: no function here takes a time
 * from its caller, so a trial or a grace period cannot be moved by anything a request carries (§7).
 * An academy gets one free trial unless the platform allows repeats (`SUBSCRIPTION_REPEAT_TRIALS`), and
 * a grace period's length is configuration (`SUBSCRIPTION_GRACE_DAYS`) — see `lib/billingConfig.ts`.
 *
 * Left to the modules that own them: plan changes and the rules around them (SAAS-006), payments
 * (SAAS-008 on), and the jobs that fire the time-driven transitions (SAAS-012).
 */

/** Who or what caused a lifecycle event. */
export type LifecycleActor =
  { type: 'user'; auth: { sub: string; role: Role } } | { type: 'system'; job: string } | { type: 'provider'; provider: string; reference?: string };

export interface SubscriptionRecord {
  id: string;
  tenantId: string;
  planId: string;
  planVersionId: string;
  status: SubscriptionState;
  billingCycle: BillingCycle;
  currency: string;
  /** Minor units, from the plan version. */
  amount: number;
  trialStartAt?: string;
  trialEndAt?: string;
  currentPeriodStartAt: string;
  currentPeriodEndAt: string;
  cancelAtPeriodEnd: boolean;
  cancelRequestedAt?: string;
  canceledAt?: string;
  cancellationReason?: string;
  pausedAt?: string;
  resumesAt?: string;
  /** When the current overdue episode began, and the provider's reason. */
  pastDueAt?: string;
  pastDueReason?: string;
  /** The grace window after retries are exhausted. */
  gracePeriodStartAt?: string;
  gracePeriodEndAt?: string;
  provider?: string;
  createdAt: string;
  updatedAt: string;
}

export interface LifecycleEntry {
  id: number;
  event: string;
  transition: string;
  fromStatus?: SubscriptionState;
  toStatus: SubscriptionState;
  actor: { type: LifecycleActor['type']; id?: string; source?: string };
  meta: Record<string, unknown>;
  at: string;
}

/** The subscription cannot make that move from where it is (§34 `INVALID_SUBSCRIPTION_STATE`). */
export class InvalidSubscriptionStateError extends ApiError {
  constructor(message: string) {
    super(409, message, undefined, 'INVALID_SUBSCRIPTION_STATE');
    this.name = 'InvalidSubscriptionStateError';
  }
}

/* ─── Mapping ──────────────────────────────────────────────────────────── */

const iso = (d: Date | null) => (d ? d.toISOString() : undefined);

function toRecord(row: SubscriptionRow): SubscriptionRecord {
  const optional = {
    trialStartAt: iso(row.trialStartAt),
    trialEndAt: iso(row.trialEndAt),
    cancelRequestedAt: iso(row.cancelRequestedAt),
    canceledAt: iso(row.canceledAt),
    cancellationReason: row.cancellationReason ?? undefined,
    pausedAt: iso(row.pausedAt),
    resumesAt: iso(row.resumesAt),
    pastDueAt: iso(row.pastDueAt),
    pastDueReason: row.pastDueReason ?? undefined,
    gracePeriodStartAt: iso(row.gracePeriodStartAt),
    gracePeriodEndAt: iso(row.gracePeriodEndAt),
    provider: row.provider ?? undefined,
  };
  return {
    id: row.id,
    tenantId: row.tenantId,
    planId: row.planId,
    planVersionId: row.planVersionId,
    status: row.status as SubscriptionState,
    billingCycle: row.billingCycle as BillingCycle,
    currency: row.currency,
    amount: row.amount,
    currentPeriodStartAt: row.currentPeriodStartAt.toISOString(),
    currentPeriodEndAt: row.currentPeriodEndAt.toISOString(),
    cancelAtPeriodEnd: row.cancelAtPeriodEnd,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
    ...(Object.fromEntries(Object.entries(optional).filter(([, v]) => v !== undefined)) as Partial<SubscriptionRecord>),
  };
}

const actorColumns = (actor: LifecycleActor) =>
  actor.type === 'user'
    ? { actorType: 'user', actorId: actor.auth.sub, source: null }
    : actor.type === 'system'
      ? { actorType: 'system', actorId: null, source: actor.job }
      : { actorType: 'provider', actorId: null, source: actor.provider };

/* ─── Guards ───────────────────────────────────────────────────────────── */

/**
 * A person acting on `tenantId`'s subscription must be a super admin working as the platform, or that
 * academy's own admin working inside it. Nobody else — an instructor, a learner, another academy's
 * admin — reaches a subscription at all.
 */
export function assertPersonMay(actor: LifecycleActor, tenantId: string, what: string) {
  if (actor.type !== 'user') return;
  const context = currentContext();
  if (actor.auth.role === 'superadmin' && context?.kind === 'platform') return;
  if (actor.auth.role === 'admin' && context?.kind === 'tenant' && context.tenantId === tenantId) return;
  throw forbidden(`You cannot ${what}.`);
}

/** Runs `fn` inside the subscription's academy, whether the caller is the platform or that academy. */
export async function withinAcademy<T>(tenantId: string, fn: () => Promise<T>): Promise<T> {
  const context = currentContext();
  if (context?.kind === 'tenant') {
    // An academy never reaches another academy's subscription: tenancy has already scoped the read
    // that found it, and this is the backstop.
    if (context.tenantId !== tenantId) throw notFound('Subscription not found.');
    return fn();
  }
  return runInTenant(tenantId, fn);
}

/** A subscription by id, found from the caller's own context — so an academy finds only its own. */
export async function loadSubscriptionRow(id: string): Promise<SubscriptionRow> {
  const row = await db.subscription.findUnique({ where: { id } });
  if (!row) throw notFound('Subscription not found.');
  return row;
}

/* ─── Reads ────────────────────────────────────────────────────────────── */

export const getSubscription = async (id: string): Promise<SubscriptionRecord> => toRecord(await loadSubscriptionRow(id));

/** The academy's live subscription — the one not cancelled or expired — if it has one. */
export async function liveSubscription(tenantId: string): Promise<SubscriptionRecord | null> {
  const row = await runAsPlatform('reading an academy’s live subscription', () =>
    db.subscription.findFirst({ where: { tenantId, status: { notIn: ['canceled', 'expired'] } } }),
  );
  return row ? toRecord(row) : null;
}

/** A subscription's lifecycle, oldest first. */
export async function listLifecycle(id: string): Promise<LifecycleEntry[]> {
  const sub = await loadSubscriptionRow(id);
  const rows = await withinAcademy(sub.tenantId, () => db.subscriptionEvent.findMany({ where: { subscriptionId: id }, orderBy: { id: 'asc' } }));
  return rows.map((r) => ({
    id: r.id,
    event: r.event,
    transition: r.transition,
    ...(r.fromStatus ? { fromStatus: r.fromStatus as SubscriptionState } : {}),
    toStatus: r.toStatus as SubscriptionState,
    actor: { type: r.actorType as LifecycleActor['type'], ...(r.actorId ? { id: r.actorId } : {}), ...(r.source ? { source: r.source } : {}) },
    meta: JSON.parse(r.metaJson) as Record<string, unknown>,
    at: r.createdAt.toISOString(),
  }));
}

/**
 * What the entitlement service asks: the plan version an academy is served, with the status it is
 * served under. The live subscription answers; with none, the most recent one says whether the academy
 * once had a plan that is now over. `null` means the academy has never subscribed.
 */
export async function subscriptionPlanFor(
  tenantId: string,
): Promise<{ planVersionId: string | null; status: SubscriptionState; lastPlanVersionId: string | null } | null> {
  const row = await runAsPlatform('the entitlement service reads which plan an academy is on', () =>
    db.subscription.findFirst({
      where: { tenantId },
      // The live one if there is one — the index allows only one — otherwise the latest to have ended.
      orderBy: [{ createdAt: 'desc' }],
      select: { planVersionId: true, status: true },
    }),
  );
  if (!row) return null;
  const status = row.status as SubscriptionState;
  // The version is served only in an entitled state; otherwise it is the plan the academy last had (restricted mode).
  return { planVersionId: ENTITLED_STATES.includes(status) ? row.planVersionId : null, status, lastPlanVersionId: row.planVersionId };
}

/* ─── Creating ─────────────────────────────────────────────────────────── */

/** Whether the academy has ever had a free trial, on any subscription — ended ones included. */
/**
 * Whether the academy may start a free trial now: it has no live subscription, and it has never had a trial
 * (unless the platform allows repeats). What the billing page offers a new academy (self-serve onboarding).
 */
export async function trialAvailable(tenantId: string): Promise<boolean> {
  if (await liveSubscription(tenantId)) return false;
  return repeatTrialsAllowed() || !(await hadTrial(tenantId));
}

async function hadTrial(tenantId: string): Promise<boolean> {
  const trials = await runAsPlatform('checking whether an academy has had a trial', () =>
    db.subscription.count({ where: { tenantId, trialStartAt: { not: null } } }),
  );
  return trials > 0;
}

export interface CreateSubscriptionInput {
  tenantId: string;
  planId: string;
  cycle: BillingCycle;
  /**
   * `trial` starts the plan's free trial. `active` starts a paid period straight away: for a verified
   * provider payment, or for an agreement billed outside the provider, which only the platform can
   * record. An academy admin never creates an active subscription by asking for one.
   */
  start: 'trial' | 'active';
  provider?: { name: string; customerId?: string; subscriptionId?: string };
  /**
   * A first purchase (SAAS-009): the paid `new_subscription` invoice this subscription is created from. The
   * provider only. The plan version, cycle and price are the invoice's — what was paid for — not the plan's
   * current terms, and the subscription records the invoice (once: a unique index and a trigger).
   */
  fromInvoice?: string;
}

/** What a paid first-purchase invoice sold: its plan version, at that version's price for the cycle. */
async function saleFromInvoice(tenantId: string, invoiceId: string, planId: string, cycle: BillingCycle) {
  const invoice = await runAsPlatform('reading the invoice a subscription is bought with', () => db.invoice.findUnique({ where: { id: invoiceId } }));
  if (!invoice || invoice.tenantId !== tenantId || invoice.purpose !== 'new_subscription' || invoice.status !== 'paid' || !invoice.planVersionId) {
    throw new InvalidSubscriptionStateError('A subscription is bought with a paid first-purchase invoice of the same LMS.');
  }
  if (invoice.billingCycle !== cycle) throw new InvalidSubscriptionStateError('The invoice was for another billing cycle.');
  const version = await resolvePlanVersion(invoice.planVersionId);
  if (version.plan.id !== planId) throw new InvalidSubscriptionStateError('The invoice was for another plan.');
  const amount = cycle === 'annual' ? version.annualPrice : version.monthlyPrice;
  if (amount === null) throw new PlanUnavailableError(`${version.plan.name} was not sold on the ${cycle} cycle.`);
  // The shape `planForNewSubscription` answers with, from the version that was paid for.
  return { plan: version.plan, version, amount };
}

/**
 * Creates an academy's subscription. The plan must be on sale on that cycle (`PLAN_UNAVAILABLE`), the
 * academy must have no live subscription already (`INVALID_SUBSCRIPTION_STATE`, and a unique index
 * behind it), and the amount is the version's — nothing in the input can set a price.
 */
export async function createSubscription(actor: LifecycleActor, input: CreateSubscriptionInput): Promise<SubscriptionRecord> {
  assertPersonMay(actor, input.tenantId, 'start a subscription for this academy');
  // An academy's own admin may start one thing directly: its free trial (no money moves). A paid
  // subscription starts only through checkout.
  if (actor.type === 'user' && actor.auth.role !== 'superadmin' && !(actor.auth.role === 'admin' && input.start === 'trial'))
    throw forbidden('An LMS starts a paid subscription through checkout, not by writing one.');
  if (input.start === 'active' && actor.type === 'system') throw forbidden('The scheduler never starts a paid subscription.');

  const at = now();
  const tenant = await runAsPlatform('checking the academy a subscription is for', () =>
    db.tenant.findUnique({ where: { id: input.tenantId }, select: { id: true } }),
  );
  if (!tenant) throw notFound('Academy not found.');
  if (input.fromInvoice && (actor.type !== 'provider' || input.start !== 'active')) {
    throw forbidden('Only a verified provider payment turns a first-purchase invoice into an active subscription.');
  }
  const sale = input.fromInvoice
    ? await saleFromInvoice(input.tenantId, input.fromInvoice, input.planId, input.cycle)
    : await planForNewSubscription(input.planId, input.cycle);
  if (input.start === 'trial' && sale.version.trialDays < 1) throw new PlanUnavailableError(`${sale.plan.name} has no free trial.`);
  if (input.start === 'trial' && !repeatTrialsAllowed() && (await hadTrial(input.tenantId))) {
    throw new InvalidSubscriptionStateError('This LMS has already had its free trial.');
  }
  if (await liveSubscription(input.tenantId)) throw new InvalidSubscriptionStateError('This LMS already has a subscription. Change or cancel it instead.');

  const status: SubscriptionState = input.start === 'trial' ? 'trialing' : 'active';
  const trialEnd = input.start === 'trial' ? addDays(at, sale.version.trialDays) : null;
  const periodEnd = trialEnd ?? addBillingPeriod(at, input.cycle);

  const meta = {
    planId: sale.plan.id,
    planVersionId: sale.version.id,
    planCode: sale.plan.code,
    cycle: input.cycle,
    amount: sale.amount,
    currency: sale.version.currency,
    ...(trialEnd ? { trialDays: sale.version.trialDays, trialEndsAt: trialEnd.toISOString() } : {}),
    ...(input.fromInvoice ? { invoiceId: input.fromInvoice } : {}),
  };
  const id = await withinAcademy(input.tenantId, () =>
    db.$transaction(async (tx) => {
      // The subscription and its first lifecycle event in one statement: the tenancy layer stamps both
      // with the academy, and the event can point at a subscription the transaction has not committed.
      const row = await tx.subscription.create({
        data: {
          tenantId: input.tenantId,
          planId: sale.plan.id,
          planVersionId: sale.version.id,
          status,
          billingCycle: input.cycle,
          currency: sale.version.currency,
          amount: sale.amount,
          trialStartAt: trialEnd ? at : null,
          trialEndAt: trialEnd,
          currentPeriodStartAt: at,
          currentPeriodEndAt: periodEnd,
          provider: input.provider?.name ?? null,
          providerCustomerId: input.provider?.customerId ?? null,
          providerSubscriptionId: input.provider?.subscriptionId ?? null,
          sourceInvoiceId: input.fromInvoice ?? null,
          events: { create: eventData(actor, { tenantId: input.tenantId, transition: 'create', from: null, to: status, meta }) },
        },
        select: { id: true },
      });
      await audit(actor, tx, BILLING_AUDIT_ACTIONS.subscriptionCreated, row.id, {
        tenantId: input.tenantId,
        status,
        planCode: sale.plan.code,
        amount: sale.amount,
      });
      // An academy has one live subscription at most, so a new one always brings its entitlements with it.
      await recordAuditLog(
        actor,
        {
          action: BILLING_AUDIT_ACTIONS.entitlementChanged,
          targetType: 'tenant',
          targetId: input.tenantId,
          meta: { subscriptionId: row.id, transition: 'create', entitled: { from: false, to: true }, planVersion: { from: null, to: sale.version.id } },
        },
        tx,
      );
      return row.id;
    }),
  );
  observe('subscription.state_changed', { subscriptionId: id, tenantId: input.tenantId, transition: 'create', from: null, to: status, ...actorFields(actor) });
  await noticeForTransition({ tenantId: input.tenantId, subscriptionId: id, transition: 'create', from: null, to: status, byAcademyAdmin: false, meta });
  return withinAcademy(input.tenantId, () => getSubscription(id));
}

/* ─── Transitions ──────────────────────────────────────────────────────── */

interface EventInput {
  tenantId: string;
  transition: TransitionName | 'create';
  from: SubscriptionState | null;
  to: SubscriptionState;
  meta?: Record<string, unknown>;
}

/** A lifecycle row's columns, less the subscription it belongs to. */
const eventData = (actor: LifecycleActor, e: EventInput) => ({
  tenantId: e.tenantId,
  event: lifecycleEventFor(e.transition, e.from, e.to),
  transition: e.transition,
  fromStatus: e.from,
  toStatus: e.to,
  ...actorColumns(actor),
  metaJson: writeJson({ ...(actor.type === 'provider' && actor.reference ? { providerReference: actor.reference } : {}), ...(e.meta ?? {}) }),
  // The history is dated by the server's clock, like everything else billing decides.
  createdAt: now(),
});

async function writeEvent(tx: DbClient, actor: LifecycleActor, e: EventInput & { subscriptionId: string }) {
  await tx.subscriptionEvent.create({ data: { ...eventData(actor, e), subscriptionId: e.subscriptionId } });
}

/**
 * Every lifecycle move is audited (§36) — by whoever made it: a person by name, the scheduler as
 * `system`, the provider as `provider`. The lifecycle log keeps the full detail; the audit trail is where
 * the platform reads who did what across every academy.
 */
async function audit(actor: LifecycleActor, tx: DbClient, action: string, subscriptionId: string, meta: Record<string, unknown>) {
  await recordAuditLog(actor, { action, targetType: 'subscription', targetId: subscriptionId, meta }, tx);
}

/** The audit action a transition is recorded under. A payment that succeeds names what it did to the subscription. */
function auditActionFor(name: TransitionName, from: SubscriptionState): string {
  const A = BILLING_AUDIT_ACTIONS;
  switch (name) {
    case 'payment_succeeded':
      return from === 'trialing' ? A.subscriptionActivated : from === 'past_due' ? A.subscriptionRecovered : A.subscriptionRenewed;
    case 'payment_failed':
      return A.subscriptionPastDue;
    case 'grace_started':
      return A.subscriptionGraceStarted;
    case 'trial_expired':
      return A.subscriptionTrialExpired;
    case 'request_cancel':
      return A.subscriptionCancelRequested;
    case 'cancel_now':
    case 'period_ended':
      return A.subscriptionCanceled;
    case 'resume':
      return A.subscriptionResumed;
    case 'pause':
      return A.subscriptionPaused;
    case 'grace_expired':
      return A.subscriptionExpired;
    case 'change_plan':
      return A.subscriptionPlanChanged;
    case 'extend':
      return A.subscriptionExtended;
  }
}

/**
 * Statuses from which the period after this one no longer follows on: the subscription is over, ends at this
 * period's end, or is paused (which moves this period's end). A renewal invoice issued for that next period
 * would take money for nothing (`afterSettle` renews only a renewable subscription).
 */
const STOPS_RENEWAL: SubscriptionState[] = ['canceling', 'canceled', 'expired', 'paused'];

/** Whether a renewal invoice for the period starting at `periodStartAt` can still renew this subscription. */
export const renewsInto = (sub: Pick<SubscriptionRow, 'status' | 'cancelAtPeriodEnd' | 'currentPeriodEndAt'>, periodStartAt: Date | null) =>
  ['trialing', 'active', 'past_due'].includes(sub.status) && !sub.cancelAtPeriodEnd && periodStartAt?.getTime() === sub.currentPeriodEndAt.getTime();

/**
 * Voids the subscription's open renewal invoices in the transaction that stops its renewal, so none can be paid
 * for a period that will not come. One somebody has started paying is left for the platform to reconcile. If
 * the subscription renews again (a withdrawn cancellation, an ended pause), invoice generation issues a fresh
 * one for the period as it then stands.
 */
async function voidStaleRenewals(
  tx: DbClient,
  actor: LifecycleActor,
  subscriptionId: string,
  reason = 'The subscription will not renew into the period this invoice was for.',
) {
  const open = await tx.invoice.findMany({
    where: { subscriptionId, purpose: 'renewal', status: 'open' },
    select: { id: true, number: true, payments: { select: { status: true } } },
  });
  for (const invoice of open) {
    if (invoice.payments.some((p) => p.status !== 'failed')) continue;
    const moved = await tx.invoice.updateMany({ where: { id: invoice.id, status: 'open' }, data: { status: 'void', voidedAt: now(), voidReason: reason } });
    if (moved.count !== 1) continue;
    await recordAuditLog(
      actor,
      { action: BILLING_AUDIT_ACTIONS.invoiceVoided, targetType: 'invoice', targetId: invoice.id, meta: { number: invoice.number, reason, subscriptionId } },
      tx,
    );
  }
}

const isAcademyAdmin = (actor: LifecycleActor) => actor.type === 'user' && actor.auth.role === 'admin';

const actorFields = (actor: LifecycleActor) =>
  actor.type === 'user'
    ? { actorType: 'user', actorId: actor.auth.sub }
    : { actorType: actor.type, source: actor.type === 'system' ? actor.job : actor.provider };

/**
 * Moves a subscription through `name`. Refuses a move the machine does not allow from the current status
 * (`INVALID_SUBSCRIPTION_STATE`) and an actor the transition does not accept. Writes the lifecycle event,
 * then the status, in one transaction; the status is part of the update's filter, so two concurrent
 * moves cannot both succeed.
 */
export async function transition(
  actor: LifecycleActor,
  id: string,
  name: TransitionName,
  change: (sub: SubscriptionRow) => { data?: Prisma.SubscriptionUpdateManyMutationInput; meta?: Record<string, unknown> },
  /** More writes that must land in the same transaction — a plan change marked applied, say. */
  alongside?: (tx: DbClient, sub: SubscriptionRow) => Promise<void>,
): Promise<SubscriptionRecord> {
  const sub = await loadSubscriptionRow(id);
  const rule = transitionNamed(name);
  assertPersonMay(actor, sub.tenantId, 'change this subscription');
  if (!rule.by.includes(actor.type))
    throw forbidden(`A ${actor.type === 'user' ? 'person' : actor.type} cannot ${rule.description.charAt(0).toLowerCase()}${rule.description.slice(1, -1)}.`);
  const from = sub.status as SubscriptionState;
  const to = nextStatus(from, name);
  if (!to) throw new InvalidSubscriptionStateError(`A ${from.replace('_', ' ')} subscription cannot ${name.replace('_', ' ')}.`);
  const { data = {}, meta } = change(sub);

  return withinAcademy(sub.tenantId, async () => {
    await db.$transaction(async (tx) => {
      await writeEvent(tx, actor, { tenantId: sub.tenantId, subscriptionId: id, transition: name, from, to, meta });
      // A move that sets the period also requires the period it read: two renewals of an active subscription leave its
      // status alone, so only this stops both from adding a period.
      const period = 'currentPeriodEndAt' in data ? { currentPeriodEndAt: sub.currentPeriodEndAt } : {};
      const moved = await tx.subscription.updateMany({ where: { id, status: from, ...period }, data: { ...data, status: to } });
      if (moved.count !== 1) throw conflict('The subscription changed while this was being saved. Reload it and try again.');
      // A subscription that is over takes no plan change with it: an open one is voided (D7–D10).
      if (isTerminal(to)) {
        await tx.planChange.updateMany({
          where: { subscriptionId: id, status: { in: ['pending_payment', 'scheduled'] } },
          data: { status: 'void', closedAt: now(), closedReason: `The subscription is ${to}.` },
        });
      }
      if (STOPS_RENEWAL.includes(to))
        await voidStaleRenewals(tx, actor, id, `The subscription is ${to.replace('_', ' ')}, so the period this invoice was for will not be renewed.`);
      if (alongside) await alongside(tx, sub);
      await audit(actor, tx, auditActionFor(name, from), id, { tenantId: sub.tenantId, status: { from, to }, ...(meta ?? {}) });
      // What the academy may do changes when it enters or leaves an entitled status, or moves plan version.
      const entitled = { from: ENTITLED_STATES.includes(from), to: ENTITLED_STATES.includes(to) };
      const nextVersion = (data as { planVersionId?: unknown }).planVersionId;
      const version = typeof nextVersion === 'string' && nextVersion !== sub.planVersionId ? { from: sub.planVersionId, to: nextVersion } : null;
      if (entitled.from !== entitled.to || version) {
        await recordAuditLog(
          actor,
          {
            action: BILLING_AUDIT_ACTIONS.entitlementChanged,
            targetType: 'tenant',
            targetId: sub.tenantId,
            meta: { subscriptionId: id, transition: name, entitled, ...(version ? { planVersion: version } : {}) },
          },
          tx,
        );
      }
    });
    observe('subscription.state_changed', { subscriptionId: id, tenantId: sub.tenantId, transition: name, from, to, ...actorFields(actor) });
    await noticeForTransition({ tenantId: sub.tenantId, subscriptionId: id, transition: name, from, to, byAcademyAdmin: isAcademyAdmin(actor), meta });
    return getSubscription(id);
  });
}

/**
 * The terms the next period is sold on: the subscription's own, unless a scheduled change (D10) takes effect
 * at the boundary between this period and the next — then that change's plan version, cycle and price.
 * What a renewal is invoiced at and for how long (SAAS-012).
 */
export async function nextPeriodTerms(sub: SubscriptionRow): Promise<{ planVersionId: string; amount: number; currency: string; cycle: BillingCycle }> {
  const scheduled = await withinAcademy(sub.tenantId, () =>
    db.planChange.findFirst({ where: { subscriptionId: sub.id, status: 'scheduled', periodEndAt: sub.currentPeriodEndAt } }),
  );
  if (scheduled)
    return { planVersionId: scheduled.toPlanVersionId, amount: scheduled.toAmount, currency: scheduled.currency, cycle: scheduled.toCycle as BillingCycle };
  return { planVersionId: sub.planVersionId, amount: sub.amount, currency: sub.currency, cycle: sub.billingCycle as BillingCycle };
}

/**
 * A period as a lifecycle event records it. The milliseconds are what the database checks a change of
 * period dates against (trigger Subscription_period_by_transition): no write moves a renewal date
 * unless the event it rides with names exactly the new one.
 */
export const periodMeta = (start: Date, end: Date) => ({ start: start.toISOString(), end: end.toISOString(), startMs: start.getTime(), endMs: end.getTime() });

/** A time-driven move may only happen once its moment has come, by the server's clock (§7). */
function assertDue(when: Date | null, what: string) {
  if (!when || now() < when) throw new InvalidSubscriptionStateError(`${what} has not come yet.`);
}

/**
 * Where the first paid period after this payment starts.
 *   - A trial converts now, but keeps the trial days it has left: its first paid period starts when the trial
 *     would have ended, so paying early never forfeits trial time.
 *   - A renewal follows on from the current period's end, so billing stays continuous.
 *   - An overdue subscription carries on from where the unpaid period ended too, unless that whole next period
 *     is already over. Then it starts afresh from now, since otherwise it would be overdue again the moment it
 *     recovered, and owe every missed period in turn.
 */
export function paidPeriodStart(sub: Pick<SubscriptionRow, 'status' | 'billingCycle' | 'currentPeriodEndAt'>, at: Date): Date {
  const carried = sub.currentPeriodEndAt;
  if (sub.status === 'trialing') return carried > at ? carried : at;
  if (sub.status === 'past_due' && addBillingPeriod(carried, sub.billingCycle as BillingCycle) <= at) return at;
  return carried;
}

/**
 * A payment is confirmed — by the provider, never by a browser. A trial converts; an active subscription
 * renews for the next period; an overdue one recovers and its overdue episode and any grace window are
 * closed. Where the paid period starts is `paidPeriodStart`.
 */
export const recordPaymentSucceeded = (actor: LifecycleActor, id: string) =>
  transition(actor, id, 'payment_succeeded', (sub) => {
    const cycle = sub.billingCycle as BillingCycle;
    const start = paidPeriodStart(sub, now());
    const end = addBillingPeriod(start, cycle);
    return {
      data: { currentPeriodStartAt: start, currentPeriodEndAt: end, pastDueAt: null, pastDueReason: null, gracePeriodStartAt: null, gracePeriodEndAt: null },
      meta: { period: periodMeta(start, end), ...(sub.status === 'past_due' ? { recoveredFrom: 'past_due' } : {}) },
    };
  });

/**
 * A charge failed. The subscription falls due and keeps its access while retries run (§8); when the
 * episode began and why are stored. The grace period comes later, once retries are exhausted.
 */
export const recordPaymentFailed = (actor: LifecycleActor, id: string, opts: { reason?: string; periodEndAt?: Date } = {}) =>
  transition(actor, id, 'payment_failed', (sub) => {
    // `periodEndAt`: the period the caller found unpaid. Renewed since (a payment settled in between), it is not due.
    if (opts.periodEndAt && sub.currentPeriodEndAt.getTime() !== opts.periodEndAt.getTime())
      throw new InvalidSubscriptionStateError('This subscription was renewed meanwhile.');
    return {
      // The period is written back unchanged so the update requires it (see `transition`): a renewal landing between
      // this read and the write makes the write refuse rather than put a paid subscription past due.
      data: { pastDueAt: now(), pastDueReason: opts.reason ?? null, ...(opts.periodEndAt ? { currentPeriodEndAt: sub.currentPeriodEndAt } : {}) },
      meta: opts.reason ? { reason: opts.reason } : {},
    };
  });

/**
 * Payment retries are exhausted: the grace period starts now and ends after the platform's configured
 * number of days (`SUBSCRIPTION_GRACE_DAYS`, never a constant here). The length is fixed into the row
 * when grace starts, so changing the configuration later does not move a grace period already running.
 * Once per overdue episode. Refused — and access simply continues — while no length is configured.
 */
export const startGracePeriod = (actor: LifecycleActor, id: string, opts: { reason: string }) =>
  transition(actor, id, 'grace_started', (sub) => {
    if (sub.gracePeriodEndAt) throw new InvalidSubscriptionStateError('This subscription’s grace period has already started.');
    const days = graceDays();
    const start = now();
    const end = addDays(start, days);
    return {
      data: { gracePeriodStartAt: start, gracePeriodEndAt: end },
      // The end in milliseconds is what the database checks the new window against.
      meta: { reason: opts.reason, graceDays: days, graceEndsAt: end.toISOString(), graceEndsAtMs: end.getTime() },
    };
  });

/** The trial ran out unconverted. Only once its end has passed on the server's clock. */
export const expireTrial = (actor: LifecycleActor, id: string) =>
  transition(actor, id, 'trial_expired', (sub) => {
    assertDue(sub.trialEndAt, 'The end of this trial');
    return { meta: { trialEndedAt: sub.trialEndAt!.toISOString() } };
  });

/** Cancel at the end of the paid period. Access runs until then. */
export const requestCancellation = (actor: LifecycleActor, id: string, opts: { reason?: string } = {}) =>
  transition(actor, id, 'request_cancel', (sub) => ({
    data: { cancelAtPeriodEnd: true, cancelRequestedAt: now(), cancellationReason: opts.reason ?? null },
    meta: { effectiveAt: sub.currentPeriodEndAt.toISOString(), ...(opts.reason ? { reason: opts.reason } : {}) },
  }));

/** Cancel now. The subscription is over and stays as history. */
export const cancelNow = (actor: LifecycleActor, id: string, opts: { reason?: string } = {}) =>
  transition(actor, id, 'cancel_now', () => {
    const at = now();
    return {
      data: { canceledAt: at, cancellationReason: opts.reason ?? null },
      meta: { effectiveAt: at.toISOString(), ...(opts.reason ? { reason: opts.reason } : {}) },
    };
  });

/**
 * Withdraw a pending cancellation, or end a pause. A person may do either at any time; the scheduler only
 * ends a pause, and only once its planned end has come. Ending a pause moves the period end out by the
 * actual paused time — never more than the pause was planned for, never more than 30 days (D9). The
 * event records who, when, why and the effective date.
 */
export const resumeSubscription = (actor: LifecycleActor, id: string, opts: { reason?: string } = {}) =>
  transition(actor, id, 'resume', (sub) => {
    const at = now();
    const common = { resumedFrom: sub.status, effectiveAt: at.toISOString(), ...(opts.reason ? { reason: opts.reason } : {}) };
    if (sub.status === 'canceling') {
      if (actor.type !== 'user') throw forbidden('Only a person can withdraw a cancellation.');
      return { data: { cancelAtPeriodEnd: false, cancelRequestedAt: null, cancellationReason: null }, meta: common };
    }
    if (actor.type === 'system') assertDue(sub.resumesAt, 'The end of this pause');
    // Only the platform pauses a subscription, so only the platform (or the pause's own end) lifts it.
    if (actor.type === 'user' && actor.auth.role !== 'superadmin')
      throw forbidden('This subscription was paused by the platform team. It resumes on its planned date, or when they end the pause.');
    const pausedAt = sub.pausedAt ?? at;
    const extensionMs = pauseExtensionMs(pausedAt, at, sub.resumesAt);
    const end = new Date(sub.currentPeriodEndAt.getTime() + extensionMs);
    return {
      data: { pausedAt: null, resumesAt: null, currentPeriodEndAt: end },
      meta: {
        ...common,
        pausedAt: pausedAt.toISOString(),
        ...(sub.resumesAt ? { plannedResumeAt: sub.resumesAt.toISOString() } : {}),
        extensionMs,
        period: periodMeta(sub.currentPeriodStartAt, end),
        previousPeriodEndAt: sub.currentPeriodEndAt.toISOString(),
      },
    };
  });

/**
 * Pause for `days` whole days, 1–30 (D9). The server sets both dates — now, and now plus the days; no
 * date is taken from the caller. The period end moves when the pause ends, by the time actually paused.
 */
export const pauseSubscription = async (actor: LifecycleActor, id: string, opts: { days: number; reason?: string }) => {
  await assertNextPeriodUnpaid(id, 'pause it');
  return transition(actor, id, 'pause', () => {
    const at = now();
    let until: Date;
    try {
      until = pauseEnd(at, opts.days);
    } catch {
      throw badRequest(`A pause runs for 1 to ${MAX_PAUSE_DAYS} whole days.`);
    }
    return {
      data: { pausedAt: at, resumesAt: until },
      meta: { pausedAt: at.toISOString(), resumesAt: until.toISOString(), days: opts.days, ...(opts.reason ? { reason: opts.reason } : {}) },
    };
  });
};

/**
 * Refuses a move that would push the renewal date out after the next period was already paid for: the paid
 * renewal invoice is for the boundary as it stands, and moving the boundary would strand the payment.
 */
async function assertNextPeriodUnpaid(id: string, what: string) {
  const sub = await loadSubscriptionRow(id);
  const paid = await withinAcademy(sub.tenantId, () =>
    db.invoice.findFirst({ where: { subscriptionId: id, purpose: 'renewal', status: 'paid', periodStartAt: sub.currentPeriodEndAt } }),
  );
  if (paid)
    throw new InvalidSubscriptionStateError(`The next period is already paid (invoice ${paid.number}), so you cannot ${what} now. Do it once it renews.`);
}

/**
 * Complimentary days from a super admin (§25): the current period ends `days` later, at no charge, with a
 * reason on the record. An unpaid renewal invoice for the old end is voided in the same transaction, and
 * invoice generation issues the next one for the new end. Refused once the next period is paid.
 */
export const extendSubscription = async (actor: LifecycleActor, id: string, opts: { days: number; reason: string }) => {
  if (actor.type !== 'user' || actor.auth.role !== 'superadmin') throw forbidden('Only a super admin can give complimentary days.');
  if (!Number.isInteger(opts.days) || opts.days < 1 || opts.days > MAX_EXTENSION_DAYS)
    throw badRequest(`Complimentary days are a whole number from 1 to ${MAX_EXTENSION_DAYS}.`);
  const reason = opts.reason?.trim() ?? '';
  if (reason.length < 3) throw badRequest('Say why the days are given.');
  await assertNextPeriodUnpaid(id, 'extend it');
  return transition(
    actor,
    id,
    'extend',
    (sub) => {
      const end = addDays(sub.currentPeriodEndAt, opts.days);
      return {
        data: { currentPeriodEndAt: end },
        meta: { days: opts.days, reason, previousPeriodEndAt: sub.currentPeriodEndAt.toISOString(), period: periodMeta(sub.currentPeriodStartAt, end) },
      };
    },
    (tx) => voidStaleRenewals(tx, actor, id, `Replaced: the period was extended by ${opts.days} complimentary days.`),
  );
};

/** A cancelling subscription's paid period is over. Only once it has passed on the server's clock. */
export const endCancelledPeriod = (actor: LifecycleActor, id: string) =>
  transition(actor, id, 'period_ended', (sub) => {
    assertDue(sub.currentPeriodEndAt, 'The end of this period');
    return { data: { canceledAt: now() }, meta: { effectiveAt: sub.currentPeriodEndAt.toISOString() } };
  });

/** The grace period ran out with nothing paid. Only once `gracePeriodEndAt` has passed on the server's clock. */
export const expireGrace = (actor: LifecycleActor, id: string) =>
  transition(actor, id, 'grace_expired', (sub) => {
    assertDue(sub.gracePeriodEndAt, 'The end of the grace period');
    return { meta: { graceEndedAt: sub.gracePeriodEndAt!.toISOString(), ...(sub.pastDueReason ? { pastDueReason: sub.pastDueReason } : {}) } };
  });

/* ─── Platform lists ───────────────────────────────────────────────────── */

export interface SubscriptionListRow extends SubscriptionRecord {
  tenant: { id: string; name: string; slug: string };
  plan: { id: string; code: string; name: string };
}

/**
 * Every academy's subscriptions for the Super Admin, newest first — filtered by status or academy. Runs
 * as the platform: the caller is the platform router.
 */
export async function listSubscriptions(query: {
  status?: SubscriptionState;
  tenantId?: string;
  page: number;
  pageSize: number;
}): Promise<{ rows: SubscriptionListRow[]; total: number }> {
  if (currentContext()?.kind !== 'platform') throw forbidden('Only the platform lists every LMS’s subscriptions.');
  const where = { ...(query.status ? { status: query.status } : {}), ...(query.tenantId ? { tenantId: query.tenantId } : {}) };
  const [rows, total] = await Promise.all([
    db.subscription.findMany({
      where,
      include: { tenant: { select: { id: true, name: true, slug: true } }, plan: { select: { id: true, code: true, name: true } } },
      orderBy: { createdAt: 'desc' },
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
    }),
    db.subscription.count({ where }),
  ]);
  return { rows: rows.map((r) => ({ ...toRecord(r), tenant: r.tenant, plan: r.plan })), total };
}

/** The academy's subscription as it stands: the live one, or the latest to have ended; null if it never subscribed. */
export async function currentSubscription(tenantId: string): Promise<SubscriptionRecord | null> {
  const row = await withinAcademy(tenantId, () => db.subscription.findFirst({ where: { tenantId }, orderBy: { createdAt: 'desc' } }));
  return row ? toRecord(row) : null;
}
