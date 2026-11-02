import type {
  Invoice as InvoiceRow,
  Payment as PaymentRow,
  PaymentMethod as PaymentMethodRow,
  PlanChange as PlanChangeRow,
  Refund as RefundRow,
  Subscription as SubscriptionDbRow,
  SubscriptionEvent as EventRow,
} from '@prisma/client';
import {
  FEATURES,
  PAYMENT_STATUSES,
  SUBSCRIPTION_STATUSES,
  SUBSCRIPTION_STATUS_OF,
  formatMoney,
  isBilling,
  monthlyValue,
  type BillingCycle,
  type Invoice,
  type Kpi,
  type OpenPlanChange,
  type PaymentListResult,
  type PaymentMethod,
  type PaymentQuery,
  type PaymentStatus,
  type Plan,
  type PlanDetail,
  type PlanListResult,
  type PlanQuery,
  type PlanRow,
  type SubscriberListResult,
  type SubscriberQuery,
  type Subscription,
  type SubscriptionDetail,
  type SubscriptionEvent,
  type SubscriptionEventKind,
  type SubscriptionOverview,
  type SubscriptionRow,
  type SubscriptionState,
  type SubscriptionStatus,
  type TenantBilling,
  type TenantPayment,
} from '@syniastrolms/domain';

import { now } from './clock.js';
import { db } from './db.js';
import { entitlementEnforcement, getTenantEntitlements } from './entitlements.js';
import { forbidden, notFound } from './errors.js';
import { readJson } from './json.js';
import { activeProvider } from './paymentGateways.js';
import { displayMethod } from './payments.js';
import './razorpay.js';
import { listPlans, resolvePlanVersion, type PlanRecord, type PlanTerms } from './plans.js';
import { trialAvailable, withinAcademy } from './subscriptions.js';
import { signupChoiceFor } from './signup.js';
import { currentContext } from './tenancy.js';
import { usageSummary } from './usage.js';

/*
 * The subscription screens' read models (SAAS-015), built from the billing records and nothing else:
 * `packages/domain/src/billingViews.ts` names the shapes. Every figure — a count, an MRR, a month of
 * history, an invoice total — is computed here from stored rows, so the screens show the server's
 * numbers and never work one out themselves.
 *
 * History is replayed from the lifecycle log: a subscription's status, plan and price at the end of a
 * month are those its latest event before then left it with. Nothing is modelled or smoothed.
 *
 * Read-only. The Super Admin views need the platform context; the academy's own view runs in the
 * academy's context and reads nothing of any other academy.
 */

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const statusOf = (state: string): SubscriptionStatus => SUBSCRIPTION_STATUS_OF[state as SubscriptionState];
const per = (cycle: BillingCycle) => (cycle === 'annual' ? 'a year' : 'a month');
const day = (d: Date) => d.toISOString().slice(0, 10);

function assertPlatform() {
  if (currentContext()?.kind !== 'platform') throw forbidden('Only the platform reads every LMS’s billing.');
}

/* ─── Plans ────────────────────────────────────────────────────────────── */

/** A plan as the screens show it, on the terms of `terms` — its current version unless a subscription's own is given. */
export function toWebPlan(plan: PlanRecord | (Pick<PlanRecord, 'id' | 'code' | 'name' | 'status'> & Partial<PlanRecord>), terms: PlanTerms): Plan {
  return {
    id: plan.id,
    name: plan.name,
    description: plan.description ?? '',
    code: plan.code,
    monthlyPrice: terms.monthlyPrice ?? 0,
    annualPrice: terms.annualPrice ?? 0,
    currency: terms.currency,
    cycles: terms.cycles,
    trialEnabled: terms.trialDays > 0,
    trialDays: terms.trialDays,
    limits: terms.limits,
    features: terms.features,
    status: plan.status,
    order: plan.displayOrder ?? 0,
    createdAt: plan.createdAt ?? terms.createdAt,
    updatedAt: plan.updatedAt ?? terms.createdAt,
  };
}

/* ─── The book: every subscription with what its rows need ─────────────── */

interface Book {
  plans: Map<string, PlanRecord>;
  /** Plan version → plan, to read a plan change's target from the log. */
  planOfVersion: Map<string, string>;
  subs: SubscriptionDbRow[];
  tenants: Map<string, { name: string }>;
  profiles: Map<string, { email: string; city: string; country: string }>;
  learners: Map<string, number>;
  /** Each subscription's latest payment. */
  lastPayment: Map<string, PaymentRow>;
  /** Each academy's default saved method. */
  methods: Map<string, PaymentMethodRow>;
  /** What a past-due subscription owes: its open invoices. */
  owed: Map<string, number>;
}

async function loadBook(where: { tenantId?: string } = {}): Promise<Book> {
  const [plans, versions, subs, tenants, profiles, learners, payments, methods, open] = await Promise.all([
    listPlans(),
    db.planVersion.findMany({ select: { id: true, planId: true } }),
    db.subscription.findMany({ where, orderBy: { createdAt: 'desc' } }),
    db.tenant.findMany({ where: where.tenantId ? { id: where.tenantId } : {}, select: { id: true, name: true } }),
    db.billingProfile.findMany({ where, select: { tenantId: true, email: true, city: true, country: true } }),
    db.student.groupBy({ by: ['tenantId'], where, _count: { _all: true } }),
    db.payment.findMany({ where, orderBy: { createdAt: 'desc' } }),
    db.paymentMethod.findMany({ where: { ...where, removedAt: null }, orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }] }),
    db.invoice.findMany({ where: { ...where, status: 'open' }, select: { subscriptionId: true, total: true } }),
  ]);
  const lastPayment = new Map<string, PaymentRow>();
  for (const p of payments) if (p.subscriptionId && !lastPayment.has(p.subscriptionId)) lastPayment.set(p.subscriptionId, p);
  const method = new Map<string, PaymentMethodRow>();
  for (const m of methods) if (!method.has(m.tenantId)) method.set(m.tenantId, m);
  const owed = new Map<string, number>();
  for (const i of open) if (i.subscriptionId) owed.set(i.subscriptionId, (owed.get(i.subscriptionId) ?? 0) + i.total);
  return {
    plans: new Map(plans.map((p) => [p.id, p])),
    planOfVersion: new Map(versions.map((v) => [v.id, v.planId])),
    subs,
    tenants: new Map(tenants.map((t) => [t.id, t])),
    profiles: new Map(profiles.map((p) => [p.tenantId, p])),
    learners: new Map(learners.map((l) => [l.tenantId, l._count._all])),
    lastPayment,
    methods: method,
    owed,
  };
}

/** A saved method, masked as it is stored; an academy that pays by invoice has none. */
function methodOf(row: Pick<PaymentMethodRow, 'kind' | 'brand' | 'last4' | 'expMonth' | 'expYear'> | undefined): PaymentMethod {
  if (!row) return { kind: 'invoice', brand: 'Invoice' };
  return {
    kind: row.kind as PaymentMethod['kind'],
    brand: row.brand,
    ...(row.last4 ? { last4: row.last4 } : {}),
    ...(row.expMonth && row.expYear ? { expiry: `${String(row.expMonth).padStart(2, '0')}/${String(row.expYear).slice(-2)}` } : {}),
  };
}

const paymentStatusOf = (p: PaymentRow | undefined): PaymentStatus | undefined => (p ? (p.status as PaymentStatus) : undefined);

function toWebSubscription(row: SubscriptionDbRow, book: Book): Subscription {
  const profile = book.profiles.get(row.tenantId);
  const last = book.lastPayment.get(row.id);
  const status = statusOf(row.status);
  const ended = row.status === 'canceled' || row.status === 'expired';
  return {
    id: row.id,
    customer: {
      id: row.tenantId,
      name: book.tenants.get(row.tenantId)?.name ?? 'Unknown LMS',
      email: profile?.email ?? '',
      city: profile?.city ?? '',
      country: profile?.country ?? '',
      learners: book.learners.get(row.tenantId) ?? 0,
    },
    planId: row.planId,
    status,
    cycle: row.billingCycle as BillingCycle,
    amount: row.amount,
    currency: row.currency,
    startedAt: row.createdAt.toISOString(),
    renewsAt: row.currentPeriodEndAt.toISOString(),
    ...(row.trialStartAt ? { trialStartedAt: row.trialStartAt.toISOString() } : {}),
    ...(row.trialEndAt ? { trialEndsAt: row.trialEndAt.toISOString() } : {}),
    ...(row.canceledAt || row.cancelRequestedAt ? { canceledAt: (row.canceledAt ?? row.cancelRequestedAt)!.toISOString() } : {}),
    ...(row.cancellationReason ? { cancelReason: row.cancellationReason } : {}),
    ...(row.cancelAtPeriodEnd ? { cancelAt: 'period-end' as const } : ended && row.canceledAt ? { cancelAt: 'immediately' as const } : {}),
    ...(row.pausedAt ? { pausedAt: row.pausedAt.toISOString() } : {}),
    ...(row.resumesAt ? { resumesAt: row.resumesAt.toISOString() } : {}),
    paymentMethod: methodOf(book.methods.get(row.tenantId)),
    ...(last ? { lastPaymentAt: (last.paidAt ?? last.failedAt ?? last.createdAt).toISOString(), lastPaymentStatus: paymentStatusOf(last) } : {}),
    ...(row.status === 'past_due' ? { amountDue: book.owed.get(row.id) ?? 0 } : {}),
    ...(row.gracePeriodEndAt ? { graceEndsAt: row.gracePeriodEndAt.toISOString() } : {}),
    ...(row.pastDueReason ? { notes: row.pastDueReason } : {}),
  };
}

function toRow(row: SubscriptionDbRow, book: Book): SubscriptionRow {
  const plan = book.plans.get(row.planId);
  return { subscription: toWebSubscription(row, book), planName: plan?.name ?? 'Unknown plan', planCode: plan?.code ?? '—' };
}

/* ─── History, replayed from the lifecycle log ─────────────────────────── */

interface Moment {
  status: SubscriptionState;
  planId: string;
  amount: number;
  cycle: BillingCycle;
}

/** Each subscription's state after each of its events, in order — what it was at any past moment. */
function timelines(events: EventRow[], book: Book): Map<string, { at: Date; state: Moment }[]> {
  const out = new Map<string, { at: Date; state: Moment }[]>();
  for (const e of [...events].sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime() || a.id - b.id)) {
    const line = out.get(e.subscriptionId) ?? [];
    const meta = readJson<Record<string, unknown>>(e.metaJson, {});
    const prev = line.at(-1)?.state;
    const sub = book.subs.find((s) => s.id === e.subscriptionId);
    let state: Moment = prev
      ? { ...prev, status: e.toStatus as SubscriptionState }
      : {
          status: e.toStatus as SubscriptionState,
          planId: (meta.planId as string) ?? sub?.planId ?? '',
          amount: typeof meta.amount === 'number' ? meta.amount : (sub?.amount ?? 0),
          cycle: ((meta.cycle as BillingCycle) ?? sub?.billingCycle ?? 'monthly') as BillingCycle,
        };
    if (e.transition === 'change_plan') {
      const to = (meta.to ?? {}) as { planVersionId?: string; amount?: number; billingCycle?: BillingCycle };
      state = {
        ...state,
        planId: (to.planVersionId && book.planOfVersion.get(to.planVersionId)) || state.planId,
        amount: to.amount ?? state.amount,
        cycle: to.billingCycle ?? state.cycle,
      };
    }
    line.push({ at: e.createdAt, state });
    out.set(e.subscriptionId, line);
  }
  return out;
}

/** What a subscription was at `t`, or undefined before it existed. */
function stateAt(line: { at: Date; state: Moment }[], t: Date): Moment | undefined {
  let found: Moment | undefined;
  for (const point of line) {
    if (point.at.getTime() > t.getTime()) break;
    found = point.state;
  }
  return found;
}

/** The last `n` calendar months (UTC), oldest first, each with its label and the moment it closed — now, for this month. */
function months(n: number, at: Date) {
  return Array.from({ length: n }, (_, i) => {
    const offset = n - 1 - i;
    const start = new Date(Date.UTC(at.getUTCFullYear(), at.getUTCMonth() - offset, 1));
    const next = new Date(Date.UTC(at.getUTCFullYear(), at.getUTCMonth() - offset + 1, 1));
    const end = offset === 0 ? at : new Date(next.getTime() - 1);
    return { label: MONTHS[start.getUTCMonth()], detail: `${MONTHS[start.getUTCMonth()]} ${start.getUTCFullYear()}`, start, next, end };
  });
}

const inMonth = (d: Date, m: { start: Date; next: Date }) => d >= m.start && d < m.next;
const CANCELLATIONS = new Set(['cancel_now', 'period_ended']);
const UPGRADES = new Set(['upgrade', 'cycle_upgrade']);
const DOWNGRADES = new Set(['downgrade', 'scheduled_change']);

const worth = (m: Moment | undefined) => (m ? monthlyValue({ amount: m.amount, cycle: m.cycle, status: statusOf(m.status) }) : 0);

/* ─── Super Admin: overview ────────────────────────────────────────────── */

export async function subscriptionOverview(): Promise<SubscriptionOverview> {
  assertPlatform();
  const at = now();
  const book = await loadBook();
  const events = await db.subscriptionEvent.findMany({ orderBy: { id: 'asc' } });
  const lines = timelines(events, book);
  const year = months(12, at);

  const countAt = (t: Date, status: SubscriptionState) => [...lines.values()].filter((l) => stateAt(l, t)?.status === status).length;
  const mrrAt = (t: Date) => [...lines.values()].reduce((sum, l) => sum + worth(stateAt(l, t)), 0);
  // Past months are replayed from the log; the current one is the book as it stands, so the headline
  // figure is always the one the subscriber list counts.
  const series = (past: (t: Date) => number, current: number) => year.map((m, i) => (i === year.length - 1 ? current : past(m.end)));
  const live = (status: SubscriptionState) => book.subs.filter((s) => s.status === status).length;
  const liveMrr = book.subs.reduce((sum, s) => sum + monthlyOf(s), 0);
  const kpi = (values: number[]): Kpi => ({ value: values.at(-1) ?? 0, previous: values.at(-2) ?? 0, series: values });

  const statusCounts = Object.fromEntries(SUBSCRIPTION_STATUSES.map((s) => [s, 0])) as Record<SubscriptionStatus, number>;
  for (const s of book.subs) statusCounts[statusOf(s.status)] += 1;

  const mrrSeries = series(mrrAt, liveMrr);
  const growth = year.map((m) => {
    const inside = events.filter((e) => inMonth(e.createdAt, m));
    const kinds = inside.filter((e) => e.transition === 'change_plan').map((e) => String(readJson<Record<string, unknown>>(e.metaJson, {}).kind ?? ''));
    return {
      label: m.label,
      detail: m.detail,
      added: inside.filter((e) => e.transition === 'create').length,
      upgrades: kinds.filter((k) => UPGRADES.has(k)).length,
      downgrades: kinds.filter((k) => DOWNGRADES.has(k)).length,
      cancellations: inside.filter((e) => CANCELLATIONS.has(e.transition)).length,
    };
  });

  const byPlan = [...book.plans.values()]
    .map((plan) => {
      const on = book.subs.filter((s) => s.planId === plan.id && isBilling(statusOf(s.status)));
      return { planId: plan.id, planName: plan.name, subscribers: on.length, mrr: on.reduce((sum, s) => sum + monthlyOf(s), 0) };
    })
    .filter((p) => p.subscribers > 0)
    .sort((a, b) => b.mrr - a.mrr);

  // Trials closing and grace periods running out, soonest first — what the platform acts on today.
  const attention = book.subs
    .filter((s) => (s.status === 'trialing' && s.trialEndAt) || (s.status === 'past_due' && s.gracePeriodEndAt))
    .sort((a, b) => (a.trialEndAt ?? a.gracePeriodEndAt)!.getTime() - (b.trialEndAt ?? b.gracePeriodEndAt)!.getTime())
    .slice(0, 5)
    .map((s) => toRow(s, book));

  const currency = book.subs[0]?.currency ?? [...book.plans.values()][0]?.current.currency ?? 'INR';
  return {
    kpis: {
      active: kpi(series((t) => countAt(t, 'active'), live('active'))),
      trial: kpi(series((t) => countAt(t, 'trialing'), live('trialing'))),
      pastDue: kpi(series((t) => countAt(t, 'past_due'), live('past_due'))),
      canceling: kpi(series((t) => countAt(t, 'canceling'), live('canceling'))),
      mrr: kpi(mrrSeries),
      arr: kpi(mrrSeries.map((v) => v * 12)),
    },
    growth,
    revenue: year.map((m, i) => ({ label: m.label, detail: m.detail, value: mrrSeries[i] })),
    byPlan,
    statusCounts,
    attention,
    currency,
    generatedAt: at.toISOString(),
  };
}

const monthlyOf = (s: SubscriptionDbRow) => monthlyValue({ amount: s.amount, cycle: s.billingCycle as BillingCycle, status: statusOf(s.status) });

/* ─── Super Admin: plans ───────────────────────────────────────────────── */

function planRow(plan: PlanRecord, book: Book): PlanRow {
  const on = book.subs.filter((s) => s.planId === plan.id);
  return {
    plan: toWebPlan(plan, plan.current),
    subscribers: on.length,
    activeSubscribers: on.filter((s) => isBilling(statusOf(s.status)) || s.status === 'trialing').length,
    mrr: on.reduce((sum, s) => sum + monthlyOf(s), 0),
  };
}

export async function planList(query: PlanQuery = {}): Promise<PlanListResult> {
  assertPlatform();
  const book = await loadBook();
  const q = (query.search ?? '').trim().toLowerCase();
  const matching = [...book.plans.values()].filter((p) => !q || `${p.name} ${p.code} ${p.description}`.toLowerCase().includes(q)).map((p) => planRow(p, book));
  const counts = {
    all: matching.length,
    active: matching.filter((r) => r.plan.status === 'active').length,
    draft: matching.filter((r) => r.plan.status === 'draft').length,
    archived: matching.filter((r) => r.plan.status === 'archived').length,
  };
  const status = query.status ?? 'all';
  const sort = query.sort ?? 'name';
  const rows = matching
    .filter((r) => status === 'all' || r.plan.status === status)
    .sort((a, b) =>
      sort === 'price'
        ? a.plan.monthlyPrice - b.plan.monthlyPrice
        : sort === 'subscribers'
          ? b.activeSubscribers - a.activeSubscribers
          : sort === 'updated'
            ? b.plan.updatedAt.localeCompare(a.plan.updatedAt)
            : a.plan.order - b.plan.order || a.plan.name.localeCompare(b.plan.name),
    );
  return { rows, counts };
}

export async function planDetail(planId: string): Promise<PlanDetail> {
  assertPlatform();
  const book = await loadBook();
  const plan = book.plans.get(planId);
  if (!plan) throw notFound('Plan not found.');
  const events = await db.subscriptionEvent.findMany({ orderBy: { id: 'asc' } });
  const lines = timelines(events, book);
  const trend = months(6, now()).map((m) => {
    let active = 0;
    let added = 0;
    let canceled = 0;
    for (const [id, line] of lines) {
      const at = stateAt(line, m.end);
      if (at?.planId === planId && (isBilling(statusOf(at.status)) || at.status === 'trialing')) active += 1;
      for (const e of events.filter((x) => x.subscriptionId === id && inMonth(x.createdAt, m))) {
        const then = stateAt(line, e.createdAt);
        if (then?.planId !== planId) continue;
        if (e.transition === 'create') added += 1;
        if (CANCELLATIONS.has(e.transition)) canceled += 1;
      }
    }
    return { label: m.label, detail: m.detail, active, added, canceled };
  });
  const on = book.subs.filter((s) => s.planId === planId);
  return {
    ...planRow(plan, book),
    trend,
    subscriptions: on.map((s) => toRow(s, book)),
    byStatus: SUBSCRIPTION_STATUSES.map((status) => ({ status, count: on.filter((s) => statusOf(s.status) === status).length })).filter((s) => s.count > 0),
  };
}

/* ─── Super Admin: subscribers ─────────────────────────────────────────── */

const emptyCounts = () => ({ all: 0, ...Object.fromEntries(SUBSCRIPTION_STATUSES.map((s) => [s, 0])) }) as Record<SubscriptionStatus | 'all', number>;

export async function subscriberList(query: SubscriberQuery = {}): Promise<SubscriberListResult> {
  assertPlatform();
  const book = await loadBook();
  const q = (query.search ?? '').trim().toLowerCase();
  const all = book.subs.map((s) => toRow(s, book));
  const matching = all.filter(({ subscription: s }) => {
    if (q && !`${s.customer.name} ${s.customer.email} ${s.id}`.toLowerCase().includes(q)) return false;
    if (query.planId && s.planId !== query.planId) return false;
    if (query.cycle && query.cycle !== 'all' && s.cycle !== query.cycle) return false;
    if (query.payment && query.payment !== 'all' && (s.lastPaymentStatus ?? 'pending') !== query.payment) return false;
    if (query.from && s.renewsAt.slice(0, 10) < query.from) return false;
    if (query.to && s.renewsAt.slice(0, 10) > query.to) return false;
    return true;
  });
  const counts = { ...emptyCounts(), all: matching.length };
  for (const r of matching) counts[r.subscription.status] += 1;
  const status = query.status ?? 'all';
  const sort = query.sort ?? 'renewal';
  const sorted = matching
    .filter((r) => status === 'all' || r.subscription.status === status)
    .sort((a, b) =>
      sort === 'customer'
        ? a.subscription.customer.name.localeCompare(b.subscription.customer.name)
        : sort === 'amount'
          ? b.subscription.amount - a.subscription.amount
          : sort === 'started'
            ? b.subscription.startedAt.localeCompare(a.subscription.startedAt)
            : a.subscription.renewsAt.localeCompare(b.subscription.renewsAt),
    );
  const page = Math.max(1, query.page ?? 1);
  const pageSize = Math.min(100, Math.max(1, query.pageSize ?? 20));
  return { rows: sorted.slice((page - 1) * pageSize, page * pageSize), total: sorted.length, counts };
}

/* ─── History lines ────────────────────────────────────────────────────── */

const EVENT_KIND: Record<string, SubscriptionEventKind> = {
  payment_failed: 'payment-failed',
  grace_started: 'payment-failed',
  trial_expired: 'cancellation-completed',
  request_cancel: 'cancellation-requested',
  cancel_now: 'cancellation-completed',
  period_ended: 'cancellation-completed',
  grace_expired: 'cancellation-completed',
  pause: 'paused',
  change_plan: 'plan-changed',
  extend: 'extended',
};

/** One lifecycle event as a line of history, in words. */
function eventLine(e: EventRow, actor: string, book: Book): SubscriptionEvent {
  const meta = readJson<Record<string, unknown>>(e.metaJson, {});
  const text = (key: string) => (typeof meta[key] === 'string' ? (meta[key] as string) : undefined);
  const date = (key: string) => (text(key) ? day(new Date(text(key)!)) : undefined);
  const reason = text('reason');
  const period = meta.period as { end?: string } | undefined;
  let kind: SubscriptionEventKind = EVENT_KIND[e.transition] ?? 'created';
  let summary: string;
  switch (e.transition) {
    case 'create': {
      const plan = book.plans.get(String(meta.planId ?? ''));
      const cycle = (meta.cycle as BillingCycle) ?? 'monthly';
      if (e.toStatus === 'trialing') {
        kind = 'trial-started';
        summary = `Trial started on ${plan?.name ?? 'its plan'} — ${meta.trialDays ?? 0} days, ending ${date('trialEndsAt') ?? '—'}.`;
      } else {
        summary = `Subscribed to ${plan?.name ?? 'its plan'} (${cycle}) at ${formatMoney(Number(meta.amount ?? 0), String(meta.currency ?? 'INR'))} ${per(cycle)}.`;
      }
      break;
    }
    case 'payment_succeeded':
      kind = e.fromStatus === 'trialing' ? 'trial-converted' : 'payment-received';
      summary =
        e.fromStatus === 'trialing'
          ? `Trial converted — the first paid period runs to ${period?.end ? day(new Date(period.end)) : '—'}.`
          : `Payment received — ${e.fromStatus === 'past_due' ? 'recovered from past due, ' : ''}renewed to ${period?.end ? day(new Date(period.end)) : '—'}.`;
      break;
    case 'payment_failed':
      summary = `A payment failed${reason ? ` — ${reason}` : ''}. Access continues while retries run.`;
      break;
    case 'grace_started':
      summary = `Retries exhausted — ${meta.graceDays ?? 0} days of grace, until ${date('graceEndsAt') ?? '—'}.`;
      break;
    case 'trial_expired':
      summary = 'The trial ended without a payment.';
      break;
    case 'request_cancel':
      summary = `Cancellation requested${reason ? ` — ${reason}` : ''}. Access stays open until ${date('effectiveAt') ?? '—'}.`;
      break;
    case 'cancel_now':
      summary = `Cancelled immediately${reason ? ` — ${reason}` : ''}.`;
      break;
    case 'period_ended':
      summary = 'The cancellation took effect at the end of the paid period.';
      break;
    case 'grace_expired':
      summary = 'Expired after the grace period with nothing paid.';
      break;
    case 'pause':
      summary = `Paused for ${meta.days ?? '?'} days — resumes ${date('resumesAt') ?? '—'}${reason ? ` (${reason})` : ''}.`;
      break;
    case 'extend':
      summary = `Complimentary days added (${meta.days ?? '?'} days) — renews ${period?.end ? day(new Date(period.end)) : '—'}${reason ? ` (${reason})` : ''}.`;
      break;
    case 'resume':
      kind = e.fromStatus === 'canceling' ? 'reactivated' : 'resumed';
      summary =
        e.fromStatus === 'canceling'
          ? 'The cancellation was withdrawn. The subscription renews as before.'
          : `Resumed — the renewal date moved to ${period?.end ? day(new Date(period.end)) : '—'}.`;
      break;
    case 'change_plan': {
      const to = (meta.to ?? {}) as { planVersionId?: string; amount?: number; currency?: string; billingCycle?: BillingCycle };
      const plan = book.plans.get(book.planOfVersion.get(to.planVersionId ?? '') ?? '');
      const cycle = to.billingCycle ?? 'monthly';
      summary = `Moved to ${plan?.name ?? 'another plan'} (${cycle}) — ${formatMoney(to.amount ?? 0, to.currency ?? 'INR')} ${per(cycle)}.`;
      break;
    }
    default:
      summary = e.event;
  }
  return { id: `event-${e.id}`, subscriptionId: e.subscriptionId, kind, at: e.createdAt.toISOString(), summary, actor };
}

/** A plan change asked for, and — if it closed without applying — how it closed. */
function changeLines(c: PlanChangeRow, actor: string, book: Book): SubscriptionEvent[] {
  const plan = book.plans.get(c.toPlanId);
  const name = plan?.name ?? 'another plan';
  const upgrade = c.kind === 'upgrade' || c.kind === 'cycle_upgrade';
  const lines: SubscriptionEvent[] = [
    {
      id: `change-${c.id}`,
      subscriptionId: c.subscriptionId,
      kind: 'plan-changed',
      at: c.quotedAt.toISOString(),
      summary: upgrade
        ? `Upgrade to ${name} (${c.toCycle}) quoted — ${formatMoney(c.charge, c.currency)} due after a ${formatMoney(c.credit, c.currency)} credit. It applies once paid.`
        : `Move to ${name} (${c.toCycle}) scheduled for the end of the period, ${day(c.periodEndAt)}. Nothing is refunded.`,
      actor,
    },
  ];
  if (c.closedAt && c.status !== 'applied') {
    lines.push({
      id: `change-${c.id}-closed`,
      subscriptionId: c.subscriptionId,
      kind: 'plan-changed',
      at: c.closedAt.toISOString(),
      summary: `The change to ${name} was ${c.status === 'canceled' ? 'withdrawn' : c.status === 'expired' ? 'not paid in time' : 'voided'}${c.closedReason ? ` — ${c.closedReason}` : ''}.`,
      actor: c.status === 'canceled' ? actor : 'Billing',
    });
  }
  return lines;
}

async function actorNames(ids: (string | null)[]): Promise<Map<string, string>> {
  const wanted = [...new Set(ids.filter((id): id is string => Boolean(id)))];
  if (!wanted.length) return new Map();
  const users = await db.user.findMany({ where: { id: { in: wanted } }, select: { id: true, name: true, role: true } });
  return new Map(users.map((u) => [u.id, u.role === 'superadmin' ? `${u.name} (platform)` : u.name]));
}

const actorLabel = (type: string, id: string | null, source: string | null, names: Map<string, string>) =>
  type === 'user' ? (names.get(id ?? '') ?? 'A person') : type === 'system' ? `Scheduler (${source ?? 'job'})` : `Payment provider (${source ?? 'unknown'})`;

/* ─── Invoices ─────────────────────────────────────────────────────────── */

interface InvoiceContext {
  book: Book;
  payments: Map<string, (PaymentRow & { refunds: RefundRow[] })[]>;
  changes: Map<string, PlanChangeRow>;
}

function toWebInvoice(row: InvoiceRow, ctx: InvoiceContext): Invoice {
  const { book } = ctx;
  const pays = ctx.payments.get(row.id) ?? [];
  const paid = pays.find((p) => p.status === 'paid');
  const failed = pays.find((p) => p.status === 'failed');
  const refunded = paid ? paid.refunds.filter((r) => r.status === 'succeeded').reduce((sum, r) => sum + r.amount, 0) : 0;
  const status: PaymentStatus =
    row.status === 'void'
      ? 'void'
      : row.status === 'paid'
        ? refunded > 0 && refunded >= row.total
          ? 'refunded'
          : 'paid'
        : pays[0]?.status === 'failed'
          ? 'failed'
          : 'pending';
  const sub = row.subscriptionId ? book.subs.find((s) => s.id === row.subscriptionId) : undefined;
  const change = row.planChangeId ? ctx.changes.get(row.planChangeId) : undefined;
  // A first purchase has no subscription yet: its plan is the version it sold.
  const planId = change?.toPlanId ?? sub?.planId ?? (row.planVersionId ? book.planOfVersion.get(row.planVersionId) : undefined);
  const billedTo = readJson<Record<string, string | undefined>>(row.billedToJson, {});
  const lines = readJson<{ description: string; quantity: number; unitAmount: number }[]>(row.linesJson, []);
  const taxLines = readJson<{ rateBps: number }[]>(row.taxLinesJson, []);
  const note =
    row.status === 'void'
      ? `Void — ${row.voidReason ?? 'withdrawn'}`
      : status === 'failed'
        ? (failed?.failureMessage ?? 'The payment was refused.')
        : refunded > 0
          ? `${formatMoney(refunded, row.currency)} refunded — ${paid!.refunds.find((r) => r.status === 'succeeded')?.reason ?? ''}`.trim()
          : undefined;
  return {
    id: row.id,
    number: row.number,
    subscriptionId: row.subscriptionId ?? '',
    customerId: row.tenantId,
    customerName: book.tenants.get(row.tenantId)?.name ?? billedTo.legalName ?? '',
    planName: (planId && book.plans.get(planId)?.name) || '—',
    cycle: ((change?.toCycle ?? sub?.billingCycle ?? row.billingCycle) as BillingCycle) ?? 'monthly',
    issuedAt: row.issuedAt.toISOString(),
    periodStart: (row.periodStartAt ?? row.issuedAt).toISOString(),
    periodEnd: (row.periodEndAt ?? row.issuedAt).toISOString(),
    lines: lines.map((l) => ({ description: l.description, quantity: l.quantity, unitAmount: l.unitAmount })),
    taxPercent: taxLines.reduce((sum, t) => sum + t.rateBps, 0) / 100,
    currency: row.currency,
    status,
    ...(row.paidAt ? { paidAt: row.paidAt.toISOString() } : {}),
    method: paid?.methodKind
      ? methodOf({ kind: paid.methodKind, brand: paid.methodBrand ?? paid.methodKind, last4: paid.methodLast4, expMonth: null, expYear: null })
      : methodOf(book.methods.get(row.tenantId)),
    ...(note ? { note } : {}),
    billingAddress: [
      billedTo.legalName,
      billedTo.addressLine1,
      billedTo.addressLine2,
      [billedTo.city, billedTo.region, billedTo.postalCode].filter(Boolean).join(' '),
      billedTo.country,
      billedTo.taxRegistration ? `Tax registration ${billedTo.taxRegistration}` : undefined,
    ].filter((l): l is string => Boolean(l)),
    amounts: { subtotal: row.subtotal, tax: row.taxTotal, total: row.total },
  };
}

async function invoiceContext(book: Book, invoices: InvoiceRow[]): Promise<InvoiceContext> {
  const ids = invoices.map((i) => i.id);
  const changeIds = invoices.map((i) => i.planChangeId).filter((id): id is string => Boolean(id));
  const [payments, changes] = await Promise.all([
    db.payment.findMany({ where: { invoiceId: { in: ids } }, include: { refunds: true }, orderBy: { createdAt: 'desc' } }),
    changeIds.length ? db.planChange.findMany({ where: { id: { in: changeIds } } }) : Promise.resolve([]),
  ]);
  const byInvoice = new Map<string, (PaymentRow & { refunds: RefundRow[] })[]>();
  for (const p of payments) if (p.invoiceId) byInvoice.set(p.invoiceId, [...(byInvoice.get(p.invoiceId) ?? []), p]);
  return { book, payments: byInvoice, changes: new Map(changes.map((c) => [c.id, c])) };
}

const emptyPaymentCounts = () => ({ all: 0, ...Object.fromEntries(PAYMENT_STATUSES.map((s) => [s, 0])) }) as Record<PaymentStatus | 'all', number>;

/** Every academy's invoices with what came of them, and the totals across everything that matches. */
export async function paymentList(query: PaymentQuery = {}): Promise<PaymentListResult> {
  assertPlatform();
  const book = await loadBook();
  const rows = await db.invoice.findMany({ orderBy: [{ issuedAt: 'desc' }, { number: 'desc' }] });
  const ctx = await invoiceContext(book, rows);
  const q = (query.search ?? '').trim().toLowerCase();
  const matching = rows
    .map((r) => toWebInvoice(r, ctx))
    .filter((i) => {
      if (q && !`${i.customerName} ${i.number} ${i.subscriptionId}`.toLowerCase().includes(q)) return false;
      if (query.planId && book.plans.get(query.planId)?.name !== i.planName) return false;
      return true;
    });
  const counts = { ...emptyPaymentCounts(), all: matching.length };
  for (const i of matching) counts[i.status] += 1;
  const status = query.status ?? 'all';
  const filtered = matching.filter((i) => status === 'all' || i.status === status);
  const refundedOn = (i: Invoice) =>
    (ctx.payments.get(i.id) ?? []).flatMap((p) => p.refunds).reduce((sum, r) => sum + (r.status === 'succeeded' ? r.amount : 0), 0);
  const totals = {
    collected: filtered.filter((i) => i.status === 'paid' || i.status === 'refunded').reduce((sum, i) => sum + i.amounts!.total, 0),
    outstanding: filtered.filter((i) => i.status === 'pending' || i.status === 'failed').reduce((sum, i) => sum + i.amounts!.total, 0),
    refunded: filtered.reduce((sum, i) => sum + refundedOn(i), 0),
    currency: filtered[0]?.currency ?? rows[0]?.currency ?? 'INR',
  };
  const page = Math.max(1, query.page ?? 1);
  const pageSize = Math.min(100, Math.max(1, query.pageSize ?? 20));
  return { rows: filtered.slice((page - 1) * pageSize, page * pageSize), total: filtered.length, counts, totals };
}

/** One invoice, by id or by its printed number. In an academy's context only that academy's are found. */
export async function invoiceView(idOrNumber: string): Promise<Invoice> {
  const row = (await db.invoice.findUnique({ where: { id: idOrNumber } })) ?? (await db.invoice.findUnique({ where: { number: idOrNumber.toUpperCase() } }));
  if (!row) throw notFound('Invoice not found.');
  const book = await loadBook({ tenantId: row.tenantId });
  return toWebInvoice(row, await invoiceContext(book, [row]));
}

/* ─── Super Admin: one subscription ────────────────────────────────────── */

async function detailOf(row: SubscriptionDbRow, book: Book): Promise<SubscriptionDetail> {
  const [events, changes, invoices, version] = await Promise.all([
    db.subscriptionEvent.findMany({ where: { subscriptionId: row.id }, orderBy: { id: 'asc' } }),
    db.planChange.findMany({ where: { subscriptionId: row.id } }),
    db.invoice.findMany({ where: { subscriptionId: row.id }, orderBy: [{ issuedAt: 'desc' }, { number: 'desc' }] }),
    resolvePlanVersion(row.planVersionId),
  ]);
  const names = await actorNames([...events.map((e) => e.actorId), ...changes.map((c) => c.requestedById)]);
  const history = [
    ...events.map((e) => eventLine(e, actorLabel(e.actorType, e.actorId, e.source, names), book)),
    ...changes.flatMap((c) => changeLines(c, names.get(c.requestedById ?? '') ?? 'A person', book)),
  ].sort((a, b) => b.at.localeCompare(a.at) || b.id.localeCompare(a.id));
  const ctx = await invoiceContext(book, invoices);
  const plan = book.plans.get(row.planId);
  return {
    subscription: toWebSubscription(row, book),
    // The plan as this subscription has it: its own version's price, features and limits.
    plan: toWebPlan(plan ?? version.plan, version),
    events: history,
    invoices: invoices.map((i) => toWebInvoice(i, ctx)),
  };
}

export async function subscriptionView(id: string): Promise<SubscriptionDetail> {
  assertPlatform();
  const row = await db.subscription.findUnique({ where: { id } });
  if (!row) throw notFound('Subscription not found.');
  return detailOf(row, await loadBook({ tenantId: row.tenantId }));
}

/* ─── The academy's own billing (§24) ──────────────────────────────────── */

function openChangeOf(c: PlanChangeRow, book: Book): OpenPlanChange {
  const upgrade = c.kind === 'upgrade' || c.kind === 'cycle_upgrade';
  return {
    id: c.id,
    direction: upgrade ? 'upgrade' : 'downgrade',
    status: c.status as OpenPlanChange['status'],
    toPlanId: c.toPlanId,
    toPlanName: book.plans.get(c.toPlanId)?.name ?? 'another plan',
    toCycle: c.toCycle as BillingCycle,
    credit: c.credit,
    charge: c.charge,
    currency: c.currency,
    ...(upgrade ? {} : { effectiveAt: c.periodEndAt.toISOString() }),
    quotedAt: c.quotedAt.toISOString(),
  };
}

export async function openChangeView(changeId: string): Promise<OpenPlanChange> {
  const change = await db.planChange.findUnique({ where: { id: changeId } });
  if (!change) throw notFound('Plan change not found.');
  return openChangeOf(change, await loadBook({ tenantId: change.tenantId }));
}

/**
 * Everything the academy's billing page shows, for the academy the caller is signed in to. Read inside
 * its own context: another academy's subscription, invoices or payments cannot be reached from here.
 */
export async function tenantBillingView(tenantId: string): Promise<TenantBilling> {
  return withinAcademy(tenantId, async () => {
    const book = await loadBook({ tenantId });
    const row = book.subs.find((s) => !['canceled', 'expired'].includes(s.status)) ?? book.subs[0] ?? null;
    const [usage, granted, invoices, payments, open, onSale, version] = await Promise.all([
      usageSummary(tenantId),
      getTenantEntitlements(tenantId),
      db.invoice.findMany({ where: { tenantId }, orderBy: [{ issuedAt: 'desc' }, { number: 'desc' }] }),
      db.payment.findMany({ where: { tenantId }, include: { refunds: true, invoice: { select: { number: true } } }, orderBy: { createdAt: 'desc' } }),
      row ? db.planChange.findFirst({ where: { subscriptionId: row.id, status: { in: ['pending_payment', 'scheduled'] } } }) : Promise.resolve(null),
      listPlans({ status: 'active' }),
      row ? resolvePlanVersion(row.planVersionId) : Promise.resolve(null),
    ]);
    const ctx = await invoiceContext(book, invoices);
    const included = new Set(granted.features);
    const plan = row && version ? toWebPlan(book.plans.get(row.planId) ?? version.plan, version) : null;
    return {
      academy: { id: tenantId, name: book.tenants.get(tenantId)?.name ?? '' },
      subscription: row ? toWebSubscription(row, book) : null,
      plan,
      restricted: usage.restricted,
      enforced: entitlementEnforcement(),
      openChange: open ? openChangeOf(open, book) : null,
      usage: usage.lines.map((l) => ({ limit: l.limit, label: l.label, used: l.used, allowed: l.allowed, remaining: l.remaining })),
      features: FEATURES.map((f) => ({ key: f.key, label: f.label, included: included.has(f.key), enforcement: f.enforcement })),
      invoices: invoices.map((i) => toWebInvoice(i, ctx)),
      payments: payments.map((p): TenantPayment => {
        const refunded = p.refunds.filter((r) => r.status === 'succeeded').reduce((sum, r) => sum + r.amount, 0);
        return {
          id: p.id,
          ...(p.invoice?.number ? { invoiceNumber: p.invoice.number } : {}),
          amount: p.amount,
          currency: p.currency,
          status: p.status !== 'paid' || refunded === 0 ? (p.status as TenantPayment['status']) : refunded >= p.amount ? 'refunded' : 'partially_refunded',
          refunded,
          ...(p.methodKind
            ? {
                method: displayMethod({
                  kind: p.methodKind as never,
                  brand: p.methodBrand ?? p.methodKind,
                  ...(p.methodLast4 ? { last4: p.methodLast4 } : {}),
                }),
              }
            : {}),
          at: (p.paidAt ?? p.failedAt ?? p.createdAt).toISOString(),
          ...(p.status === 'failed' && p.failureMessage ? { failureMessage: p.failureMessage } : {}),
        };
      }),
      plans: onSale.sort((a, b) => a.displayOrder - b.displayOrder).map((p) => toWebPlan(p, p.current)),
      // Online payment is available while a gateway is active (SAAS-009, SAAS-017); without one an upgrade can
      // be quoted, and waits for a payment the platform records.
      checkoutAvailable: (await activeProvider()) !== null,
      trialAvailable: await trialAvailable(tenantId),
      signupChoice: await signupChoiceFor(tenantId),
    };
  });
}
