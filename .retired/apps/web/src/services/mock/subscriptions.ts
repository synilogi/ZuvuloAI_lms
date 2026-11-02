import type {
  AcademyBillingSummary,
  BillingAcademy,
  BillingDetails,
  Invoice,
  Kpi,
  PaymentStatus,
  Plan,
  PlanInput,
  PlanVersion,
  Subscription,
  SubscriptionEvent,
  SubscriptionPayment,
  SubscriptionPlanChange,
  SubscriptionStatus,
  TaxRule,
  WebhookReceipt,
} from '@syniastrolms/domain';
import {
  MAX_EXTENSION_DAYS,
  MAX_PAUSE_DAYS,
  PAYMENT_STATUSES,
  SUBSCRIPTION_STATUSES,
  classifyPlanChange,
  formatMoney,
  invoiceTotal,
  isBilling,
  isImmediate,
  monthlyValue,
  pauseExtensionMs,
  quoteImmediateChange,
  reachablePlanStatuses,
  taxRuleIssues,
  validatePlan,
} from '@syniastrolms/domain';
import { extensionSummary } from '@/lib/billingStates';
import type {
  CancelInput,
  ChangePlanInput,
  PaymentListResult,
  PaymentQuery,
  PlanDetail,
  PlanListResult,
  PlanQuery,
  PlanRow,
  SubscriberListResult,
  SubscriberQuery,
  SubscriptionDetail,
  SubscriptionOverview,
  SubscriptionRow,
  SubscriptionService,
} from '../contracts';
import { ServiceError } from '../contracts';
import { mockNow, mockNowIso } from './clock';
import { toIST } from './random';
import { CURRENCY, invoices, plans, subscriptions, subscriptionEvents } from './fixtures/subscriptions';
import { respond, scenario } from './simulation';

/*
 * The subscription layer of the platform workspace, served entirely from memory.
 *
 * The demo build's stand-in for the billing API (http mode reads `services/http/subscriptions.ts`).
 * Every record is invented. Actions follow the platform's real rules — an upgrade is quoted and waits
 * for a payment (D7, D8), a downgrade is scheduled for the period end (D10), a pause runs 1–30 days and
 * moves the renewal date by the time actually paused (D9) — but no money changes hands and no academy's
 * access is touched. The overview's current figures are computed from these same records; its month-by-
 * month history is modelled, not recorded, which the screen says.
 */

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const findPlan = (id: string): Plan => {
  const plan = plans.find((p) => p.id === id);
  if (!plan) throw new ServiceError('This plan no longer exists.', 'not-found');
  return plan;
};

const findSubscription = (id: string): Subscription => {
  const subscription = subscriptions.find((s) => s.id === id);
  if (!subscription) throw new ServiceError('This subscription no longer exists.', 'not-found');
  return subscription;
};

const replace = (next: Subscription) => {
  subscriptions[subscriptions.findIndex((s) => s.id === next.id)] = next;
  return next;
};

const rowFor = (subscription: Subscription): SubscriptionRow => {
  const plan = plans.find((p) => p.id === subscription.planId);
  return { subscription, planName: plan?.name ?? 'Unknown plan', planCode: plan?.code ?? '—' };
};

function planRow(plan: Plan): PlanRow {
  const on = subscriptions.filter((s) => s.planId === plan.id);
  return {
    plan,
    subscribers: on.length,
    activeSubscribers: on.filter((s) => isBilling(s.status) || s.status === 'trial').length,
    mrr: on.reduce((sum, s) => sum + monthlyValue(s), 0),
  };
}

/** Writes a history entry against a subscription, newest first, the way the detail page reads it. */
function record(subscriptionId: string, kind: SubscriptionEvent['kind'], summary: string, actor = 'Platform admin') {
  const list = subscriptionEvents[subscriptionId] ?? (subscriptionEvents[subscriptionId] = []);
  list.unshift({ id: `${subscriptionId}-${kind}-${list.length}-${Date.now()}`, subscriptionId, kind, at: mockNowIso(), summary, actor });
}

/** A date `days` from the demo clock, in IST like every other timestamp the mock serves. */
const plusDays = (days: number) => toIST(new Date(mockNow().getTime() + days * 86_400_000));

const money = (minor: number) => formatMoney(minor, CURRENCY);

const nextCode = (base: string) => {
  let n = 2;
  while (plans.some((p) => p.code === `${base}-${n}`)) n++;
  return `${base}-${n}`;
};

/** A deterministic shape for a history series: the same seed gives the same twelve months. */
function series(total: number, months: number, wobble: number[]): number[] {
  return wobble.slice(-months).map((factor) => Math.max(0, Math.round(total * factor)));
}

const kpi = (value: number, previous: number, history: number[], unit?: Kpi['unit']): Kpi => ({ value, previous, series: history, unit });

/* ─── Read models ───────────────────────────────────────────────────────── */

const GROWTH_SHAPE = [0.58, 0.62, 0.66, 0.71, 0.74, 0.79, 0.83, 0.86, 0.9, 0.93, 0.97, 1];

function buildOverview(): SubscriptionOverview {
  const now = mockNow();
  const counts = Object.fromEntries(SUBSCRIPTION_STATUSES.map((s) => [s, subscriptions.filter((x) => x.status === s).length])) as Record<
    SubscriptionStatus,
    number
  >;
  const mrr = subscriptions.reduce((sum, s) => sum + monthlyValue(s), 0);
  const activeNow = counts.active + counts.canceling + counts['past-due'];

  const activeHistory = series(activeNow, 12, GROWTH_SHAPE);
  const mrrHistory = series(mrr, 12, GROWTH_SHAPE);
  const monthLabel = (offset: number) => {
    const d = new Date(now.getFullYear(), now.getMonth() - offset, 1);
    return { label: MONTHS[d.getMonth()], detail: `${MONTHS[d.getMonth()]} ${d.getFullYear()}` };
  };

  const growth = Array.from({ length: 12 }, (_, i) => {
    const offset = 11 - i;
    const added = Math.max(1, activeHistory[i] - (activeHistory[i - 1] ?? activeHistory[i]) + 2);
    return {
      ...monthLabel(offset),
      added,
      upgrades: Math.max(0, Math.round(added * 0.45)),
      downgrades: Math.max(0, Math.round(added * 0.18)),
      cancellations: Math.max(0, Math.round(added * 0.55) - 1),
    };
  });

  const revenue = Array.from({ length: 12 }, (_, i) => ({ ...monthLabel(11 - i), value: mrrHistory[i] }));

  const byPlan = plans
    .map((plan) => {
      const row = planRow(plan);
      return { planId: plan.id, planName: plan.name, subscribers: row.activeSubscribers, mrr: row.mrr };
    })
    .filter((p) => p.subscribers > 0)
    .sort((a, b) => b.mrr - a.mrr);

  // Trials closing and grace periods running out, soonest first — what a platform admin acts on today.
  const attention = subscriptions
    .filter((s) => s.status === 'trial' || s.status === 'past-due')
    .map((s) => ({ row: rowFor(s), at: s.status === 'trial' ? s.trialEndsAt : s.graceEndsAt }))
    .filter((x) => Boolean(x.at))
    .sort((a, b) => (a.at ?? '').localeCompare(b.at ?? ''))
    .slice(0, 5)
    .map((x) => x.row);

  return {
    kpis: {
      active: kpi(
        counts.active,
        Math.max(0, counts.active - 3),
        activeHistory.map((n) => Math.round(n * 0.86)),
      ),
      trial: kpi(counts.trial, Math.max(0, counts.trial - 1), series(counts.trial, 12, GROWTH_SHAPE)),
      pastDue: kpi(counts['past-due'], counts['past-due'] + 1, series(counts['past-due'] + 1, 12, GROWTH_SHAPE)),
      canceling: kpi(counts.canceling, Math.max(0, counts.canceling - 1), series(counts.canceling + 1, 12, GROWTH_SHAPE)),
      mrr: kpi(mrr, Math.round(mrr * 0.94), mrrHistory),
      arr: kpi(
        mrr * 12,
        Math.round(mrr * 12 * 0.94),
        mrrHistory.map((n) => n * 12),
      ),
    },
    growth,
    revenue,
    byPlan,
    statusCounts: counts,
    attention,
    currency: CURRENCY,
    generatedAt: mockNowIso(),
  };
}

function buildPlanDetail(plan: Plan): PlanDetail {
  const row = planRow(plan);
  const on = subscriptions.filter((s) => s.planId === plan.id);
  const now = mockNow();
  const trend = Array.from({ length: 6 }, (_, i) => {
    const offset = 5 - i;
    const d = new Date(now.getFullYear(), now.getMonth() - offset, 1);
    const factor = GROWTH_SHAPE[GROWTH_SHAPE.length - 6 + i];
    const active = Math.max(0, Math.round(row.activeSubscribers * factor));
    return {
      label: MONTHS[d.getMonth()],
      detail: `${MONTHS[d.getMonth()]} ${d.getFullYear()}`,
      active,
      added: Math.max(0, Math.round(active * 0.16) + (i % 2)),
      canceled: Math.max(0, Math.round(active * 0.07)),
    };
  });

  return {
    ...row,
    trend,
    subscriptions: [...on].sort((a, b) => b.startedAt.localeCompare(a.startedAt)).map(rowFor),
    byStatus: SUBSCRIPTION_STATUSES.map((status) => ({ status, count: on.filter((s) => s.status === status).length })).filter((s) => s.count > 0),
  };
}

/* ─── Payments, plan changes, versions ──────────────────────────────────── */

/** What has been refunded of each payment this session, minor units. */
const refundedSoFar = new Map<string, number>();
let refundSeq = 0;

const paymentId = (invoice: Invoice) => `pay-${invoice.id}`;

const methodDisplay = (method: Invoice['method']) => (method.last4 ? `${method.brand} •••• ${method.last4}` : method.brand);

/** A payment for every invoice that was charged — paid, refused or returned — as the billing API keeps them. */
function paymentOf(invoice: Invoice): SubscriptionPayment {
  const amount = invoiceTotal(invoice);
  const id = paymentId(invoice);
  // An invoice the fixtures already show as refunded was refunded in full before the demo began.
  const refunded = refundedSoFar.get(id) ?? (invoice.status === 'refunded' ? amount : 0);
  const failed = invoice.status === 'failed';
  return {
    id,
    invoiceId: invoice.id,
    provider: invoice.method.kind === 'invoice' ? 'offline' : 'razorpay',
    providerPaymentId: `pay_demo_${invoice.number.replace(/-/g, '')}`,
    amount,
    currency: invoice.currency,
    status: failed ? 'failed' : refunded >= amount ? 'refunded' : refunded > 0 ? 'partially_refunded' : 'paid',
    refunded,
    refundable: failed ? 0 : amount - refunded,
    method: methodDisplay(invoice.method),
    at: invoice.paidAt ?? invoice.issuedAt,
    ...(failed && invoice.note ? { failureMessage: invoice.note } : {}),
  };
}

const charged = (invoice: Invoice) => invoice.status === 'paid' || invoice.status === 'refunded' || invoice.status === 'failed';

/** The plan change still open on each subscription — one at a time; a new request replaces it in the demo. */
const openChanges: Record<string, SubscriptionPlanChange> = {};
let changeSeq = 0;

/** Each plan's version history: the fixtures start every plan on version 1, and each edit to its terms adds one. */
const versions: Record<string, PlanVersion[]> = {};

const termsOf = (plan: Plan, version: number, createdAt: string): PlanVersion => ({
  id: `${plan.id}-v${version}`,
  version,
  currency: plan.currency,
  monthlyPrice: plan.cycles.includes('monthly') ? plan.monthlyPrice : null,
  annualPrice: plan.cycles.includes('annual') ? plan.annualPrice : null,
  cycles: [...plan.cycles],
  trialDays: plan.trialEnabled ? plan.trialDays : 0,
  features: [...plan.features],
  limits: { ...plan.limits },
  createdAt,
});

const versionsOf = (plan: Plan) => versions[plan.id] ?? (versions[plan.id] = [termsOf(plan, 1, plan.createdAt)]);

/** Writes the next version when the terms changed; a rename or a reorder leaves the version alone. */
function recordVersion(plan: Plan) {
  const list = versionsOf(plan);
  const last = list[list.length - 1];
  const next = termsOf(plan, last.version + 1, mockNowIso());
  const terms = (v: PlanVersion) => JSON.stringify({ ...v, id: '', version: 0, createdAt: '' });
  if (terms(last) !== terms(next)) list.push(next);
}

const detailFor = (subscription: Subscription): SubscriptionDetail => {
  const own = invoices.filter((i) => i.subscriptionId === subscription.id);
  const change = openChanges[subscription.id];
  return {
    subscription,
    plan: findPlan(subscription.planId),
    events: subscriptionEvents[subscription.id] ?? [],
    invoices: own,
    openChanges: change ? [change] : [],
    payments: own
      .filter(charged)
      .map(paymentOf)
      .sort((a, b) => b.at.localeCompare(a.at)),
  };
};

/* ─── Academies, profiles, tax rules, webhooks ──────────────────────────── */

/** Two academies that have never subscribed, beside every academy the fixtures bill — and any created this session. */
const UNSUBSCRIBED: { id: string; name: string; city?: string }[] = [
  { id: 'acad-shanti-jyotish-kendra', name: 'Shanti Jyotish Kendra', city: 'Pune' },
  { id: 'acad-nakshatra-vidya-peeth', name: 'Nakshatra Vidya Peeth', city: 'Varanasi' },
];

/** Adds an academy created this session (the platform demo's `createAcademy`): it starts on no plan. */
export function addDemoAcademy(academy: { id: string; name: string }) {
  UNSUBSCRIBED.push(academy);
}

export function academies(): BillingAcademy[] {
  const seen = new Map<string, BillingAcademy>();
  for (const s of subscriptions) {
    if (!seen.has(s.customer.id))
      seen.set(s.customer.id, { id: s.customer.id, name: s.customer.name, slug: s.customer.id.replace(/^acad-/, ''), status: 'active' });
  }
  for (const a of UNSUBSCRIBED) if (!seen.has(a.id)) seen.set(a.id, { id: a.id, name: a.name, slug: a.id.replace(/^acad-/, ''), status: 'active' });
  return [...seen.values()].sort((a, b) => a.name.localeCompare(b.name));
}

const isLive = (s: Subscription) => s.status !== 'canceled' && s.status !== 'expired';

/** The academy's live subscription, or its most recent one. */
export const subscriptionOfAcademy = (tenantId: string): Subscription | null =>
  subscriptions.filter((s) => s.customer.id === tenantId).sort((a, b) => Number(isLive(b)) - Number(isLive(a)) || b.startedAt.localeCompare(a.startedAt))[0] ??
  null;

/** Billing profiles set this session; an academy the fixtures bill starts with one made from its invoices. */
const profiles = new Map<string, BillingDetails>();

function profileOf(tenantId: string): BillingDetails | null {
  if (profiles.has(tenantId)) return profiles.get(tenantId)!;
  const s = subscriptions.find((x) => x.customer.id === tenantId);
  if (!s) return null;
  return { legalName: s.customer.name, email: s.customer.email, addressLine1: '12 Temple Road', city: s.customer.city, postalCode: '560001', country: 'IN' };
}

const taxRules: TaxRule[] = [
  {
    id: 'tax-in-gst',
    name: 'GST',
    country: 'IN',
    inclusive: false,
    components: [{ code: 'GST', label: 'Goods and Services Tax', rateBps: 1800 }],
    createdAt: '2026-04-01T00:00:00.000+05:30',
  },
];
let taxSeq = 0;

const WEBHOOK_TYPES: [string, WebhookReceipt['status'], string?][] = [
  ['payment.captured', 'processed'],
  ['order.paid', 'processed'],
  ['payment.failed', 'processed'],
  ['refund.processed', 'processed'],
  ['payment.authorized', 'ignored', 'Waits for the capture that follows.'],
  ['payment.captured', 'failed', 'No invoice matches order order_demo_0042.'],
  ['subscription.charged', 'ignored', 'Not an event the platform acts on.'],
  ['payment.captured', 'received'],
];

/** The demo's webhook receipts: a day's worth from the provider, newest first. */
const webhooks: WebhookReceipt[] = Array.from({ length: 26 }, (_, i) => {
  const [eventType, status, note] = WEBHOOK_TYPES[i % WEBHOOK_TYPES.length];
  const receivedAt = toIST(new Date(mockNow().getTime() - (i * 53 + 4) * 60_000));
  return {
    id: `wh-${String(26 - i).padStart(4, '0')}`,
    provider: 'razorpay',
    providerEventId: `evt_demo_${(9_000_000 + i * 7919).toString(36)}`,
    eventType,
    status,
    attempts: status === 'failed' ? 3 : 1,
    ...(note ? { note } : {}),
    reference: { orderId: `order_demo_${String(100 + i).padStart(4, '0')}` },
    receivedAt,
    ...(status === 'processed' || status === 'ignored' ? { processedAt: toIST(new Date(new Date(receivedAt).getTime() + 1_200)) } : {}),
  };
});

const OFFLINE_BRAND = { bank_transfer: 'Bank transfer', cheque: 'Cheque', cash: 'Cash', upi: 'UPI', other: 'Offline payment' } as const;

const findInvoice = (id: string): Invoice => {
  const invoice = invoices.find((i) => i.id === id || i.number.toLowerCase() === id.toLowerCase());
  if (!invoice) throw new ServiceError('That invoice no longer exists.', 'not-found');
  return invoice;
};

const replaceInvoice = (next: Invoice) => {
  invoices[invoices.findIndex((i) => i.id === next.id)] = next;
  return next;
};

/* ─── Service ───────────────────────────────────────────────────────────── */

export const subscriptionService: SubscriptionService = {
  overview: () => respond(() => (scenario() === 'empty' ? emptyOverview() : buildOverview()), 520),

  listPlans: ({ search = '', status = 'all', sort = 'name' }: PlanQuery = {}) =>
    respond((): PlanListResult => {
      if (scenario() === 'empty') return { rows: [], counts: { all: 0, active: 0, draft: 0, archived: 0 } };
      const q = search.trim().toLowerCase();
      const matching = plans.filter((p) => !q || `${p.name} ${p.code} ${p.description}`.toLowerCase().includes(q)).map(planRow);
      const counts = {
        all: matching.length,
        active: matching.filter((r) => r.plan.status === 'active').length,
        draft: matching.filter((r) => r.plan.status === 'draft').length,
        archived: matching.filter((r) => r.plan.status === 'archived').length,
      };
      const rows = matching
        .filter((r) => status === 'all' || r.plan.status === status)
        .sort((a, b) =>
          sort === 'price'
            ? a.plan.monthlyPrice - b.plan.monthlyPrice
            : sort === 'subscribers'
              ? b.activeSubscribers - a.activeSubscribers
              : sort === 'updated'
                ? b.plan.updatedAt.localeCompare(a.plan.updatedAt)
                : a.plan.order - b.plan.order,
        );
      return { rows, counts };
    }, 420),

  getPlan: (id) =>
    respond(() => {
      const plan = findPlan(id);
      return { ...buildPlanDetail(plan), versions: [...versionsOf(plan)] };
    }, 380),

  createPlan: (input: PlanInput) =>
    respond(() => {
      assertReachable(null, input.status);
      assertPlan(input);
      const id = input.code.trim().toLowerCase();
      const plan: Plan = {
        ...normalise(input),
        id: plans.some((p) => p.id === id) ? `${id}-${plans.length + 1}` : id,
        createdAt: mockNowIso(),
        updatedAt: mockNowIso(),
      };
      plans.push(plan);
      return plan;
    }, 760),

  updatePlan: (id, input: PlanInput) =>
    respond(() => {
      const current = findPlan(id);
      assertReachable(current.status, input.status);
      assertPlan(input, id);
      versionsOf(current);
      const next: Plan = { ...current, ...normalise(input), id: current.id, createdAt: current.createdAt, updatedAt: mockNowIso() };
      plans[plans.findIndex((p) => p.id === id)] = next;
      recordVersion(next);
      return next;
    }, 700),

  duplicatePlan: (id) =>
    respond(() => {
      const source = findPlan(id);
      const code = nextCode(source.code);
      const copy: Plan = {
        ...structuredClone(source),
        id: code.toLowerCase(),
        name: `${source.name} (copy)`,
        code,
        status: 'draft',
        order: plans.length + 1,
        createdAt: mockNowIso(),
        updatedAt: mockNowIso(),
      };
      plans.push(copy);
      return copy;
    }, 620),

  archivePlan: (id) =>
    respond(() => {
      const plan = findPlan(id);
      if (plan.status === 'archived') throw new ServiceError('This plan is already archived.', 'conflict');
      const next: Plan = { ...plan, status: 'archived', updatedAt: mockNowIso() };
      plans[plans.findIndex((p) => p.id === id)] = next;
      return next;
    }, 560),

  restorePlan: (id) =>
    respond(() => {
      const plan = findPlan(id);
      if (plan.status !== 'archived') throw new ServiceError('Only an archived plan can be restored.', 'conflict');
      const next: Plan = { ...plan, status: 'active', updatedAt: mockNowIso() };
      plans[plans.findIndex((p) => p.id === id)] = next;
      return next;
    }, 560),

  publishPlan: (id) =>
    respond(() => {
      const plan = findPlan(id);
      if (plan.status !== 'draft') throw new ServiceError('Only a draft can be published.', 'conflict');
      assertPlan(plan, id);
      const next: Plan = { ...plan, status: 'active', updatedAt: mockNowIso() };
      plans[plans.findIndex((p) => p.id === id)] = next;
      return next;
    }, 560),

  listSubscribers: ({
    search = '',
    planId,
    status = 'all',
    cycle = 'all',
    payment = 'all',
    from,
    to,
    sort = 'renewal',
    page = 1,
    pageSize = 20,
  }: SubscriberQuery = {}) =>
    respond((): SubscriberListResult => {
      const empty = { rows: [], total: 0, counts: emptyCounts() };
      if (scenario() === 'empty') return empty;
      const q = search.trim().toLowerCase();
      const matching = subscriptions.filter((s) => {
        if (q && !`${s.customer.name} ${s.customer.email} ${s.id}`.toLowerCase().includes(q)) return false;
        if (planId && s.planId !== planId) return false;
        if (cycle !== 'all' && s.cycle !== cycle) return false;
        if (payment !== 'all' && (s.lastPaymentStatus ?? 'pending') !== payment) return false;
        if (from && s.renewsAt.slice(0, 10) < from) return false;
        if (to && s.renewsAt.slice(0, 10) > to) return false;
        return true;
      });

      const counts = { ...emptyCounts(), all: matching.length };
      for (const s of matching) counts[s.status] += 1;

      const filtered = matching.filter((s) => status === 'all' || s.status === status);
      const sorted = [...filtered].sort((a, b) =>
        sort === 'customer'
          ? a.customer.name.localeCompare(b.customer.name)
          : sort === 'amount'
            ? b.amount - a.amount
            : sort === 'started'
              ? b.startedAt.localeCompare(a.startedAt)
              : a.renewsAt.localeCompare(b.renewsAt),
      );
      const start = (page - 1) * pageSize;
      return { rows: sorted.slice(start, start + pageSize).map(rowFor), total: sorted.length, counts };
    }, 460),

  getSubscription: (id) => respond(() => detailFor(findSubscription(id)), 400),

  changePlan: (id, input: ChangePlanInput) =>
    respond(() => {
      const current = findSubscription(id);
      const plan = findPlan(input.planId);
      if (plan.id === current.planId && input.cycle === current.cycle) throw new ServiceError('That is the plan this subscription is already on.', 'conflict');
      if (plan.status !== 'active') throw new ServiceError(`${plan.name} is not on sale.`, 'conflict', 'PLAN_UNAVAILABLE');
      if (!plan.cycles.includes(input.cycle)) throw new ServiceError(`${plan.name} isn’t offered on a ${input.cycle} cycle.`, 'conflict', 'PLAN_UNAVAILABLE');
      if (current.status !== 'active') throw new ServiceError('Only an active subscription can change plan.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
      const amount = input.cycle === 'annual' ? plan.annualPrice : plan.monthlyPrice;
      const kind = classifyPlanChange(
        { planVersionId: current.planId, cycle: current.cycle, amount: current.amount },
        { planVersionId: plan.id, cycle: input.cycle, amount },
      )!;
      if (isImmediate(kind)) {
        // D7, D8: priced on what is left of the period, applied only once the payment is confirmed.
        const start = new Date(current.renewsAt);
        if (current.cycle === 'annual') start.setUTCFullYear(start.getUTCFullYear() - 1);
        else start.setUTCMonth(start.getUTCMonth() - 1);
        const quote = quoteImmediateChange({
          kind: kind as 'upgrade' | 'cycle_upgrade',
          currentAmount: current.amount,
          newAmount: amount,
          periodStart: start,
          periodEnd: new Date(current.renewsAt),
          at: mockNow(),
        });
        record(
          id,
          'plan-changed',
          `Upgrade to ${plan.name} (${input.cycle}) quoted — ${money(quote.charge)} due after a ${money(quote.credit)} credit. It applies once paid.`,
        );
        openChanges[id] = {
          id: `demo-change-${++changeSeq}`,
          kind,
          status: 'pending_payment',
          toPlanId: plan.id,
          toCycle: input.cycle,
          toAmount: amount,
          currency: current.currency,
          credit: quote.credit,
          charge: quote.charge,
          periodEnd: current.renewsAt,
          quotedAt: mockNowIso(),
        };
      } else {
        // D10: at the period boundary, nothing refunded, current entitlements until then.
        record(
          id,
          'plan-changed',
          `Move to ${plan.name} (${input.cycle}) scheduled for the end of the period, ${current.renewsAt.slice(0, 10)}. Nothing is refunded.`,
        );
        openChanges[id] = {
          id: `demo-change-${++changeSeq}`,
          kind,
          status: 'scheduled',
          toPlanId: plan.id,
          toCycle: input.cycle,
          toAmount: amount,
          currency: current.currency,
          credit: 0,
          charge: 0,
          periodEnd: current.renewsAt,
          quotedAt: mockNowIso(),
        };
      }
      return detailFor(current);
    }, 700),

  pause: (id, days) =>
    respond(() => {
      const current = findSubscription(id);
      if (current.status === 'paused') throw new ServiceError('This subscription is already paused.', 'conflict');
      if (current.status === 'canceled' || current.status === 'expired') throw new ServiceError('A closed subscription can’t be paused.', 'conflict');
      if (!Number.isInteger(days) || days < 1 || days > MAX_PAUSE_DAYS)
        throw new ServiceError(`A pause runs for 1 to ${MAX_PAUSE_DAYS} whole days.`, 'conflict');
      const resumesAt = plusDays(days);
      const next = replace({ ...current, status: 'paused', pausedAt: mockNowIso(), resumesAt });
      record(id, 'paused', `Paused for ${days} days — resumes ${resumesAt.slice(0, 10)}.`);
      return detailFor(next);
    }, 640),

  resume: (id) =>
    respond(() => {
      const current = findSubscription(id);
      if (current.status !== 'paused') throw new ServiceError('Only a paused subscription can be resumed.', 'conflict');
      // D9: the renewal date moves out by the time actually paused, never more than planned or 30 days.
      const extension = pauseExtensionMs(new Date(current.pausedAt ?? mockNowIso()), mockNow(), current.resumesAt ? new Date(current.resumesAt) : null);
      const next = replace({
        ...current,
        status: 'active',
        pausedAt: undefined,
        resumesAt: undefined,
        renewsAt: toIST(new Date(new Date(current.renewsAt).getTime() + extension)),
      });
      record(id, 'resumed', `Resumed on ${findPlan(current.planId).name} — the renewal date moved to ${next.renewsAt.slice(0, 10)}.`);
      return detailFor(next);
    }, 620),

  cancel: (id, input: CancelInput) =>
    respond(() => {
      const current = findSubscription(id);
      if (current.status === 'canceled') throw new ServiceError('This subscription is already cancelled.', 'conflict');
      if (input.reason.trim().length < 5) throw new ServiceError('Give a reason of at least 5 characters, so the history explains itself.', 'conflict');
      const immediately = input.effective === 'immediately';
      const next = replace({
        ...current,
        status: immediately ? 'canceled' : 'canceling',
        canceledAt: mockNowIso(),
        cancelReason: input.reason.trim(),
        cancelAt: input.effective,
        renewsAt: immediately ? mockNowIso() : current.renewsAt,
      });
      record(
        id,
        'cancellation-requested',
        `${input.reason.trim()} — access ${immediately ? 'closed now' : `stays open until ${current.renewsAt.slice(0, 10)}`}.`,
      );
      if (immediately) record(id, 'cancellation-completed', 'Access closed immediately at the platform admin’s request.');
      return detailFor(next);
    }, 720),

  reactivate: (id) =>
    respond(() => {
      const current = findSubscription(id);
      if (current.status !== 'canceling' && current.status !== 'canceled' && current.status !== 'expired') {
        throw new ServiceError('Only a cancelled or expired subscription can be reactivated.', 'conflict');
      }
      const plan = findPlan(current.planId);
      if (plan.status === 'archived')
        throw new ServiceError(`${plan.name} is archived. Change the plan first, then reactivate.`, 'conflict', 'PLAN_UNAVAILABLE');
      // A pending cancellation is withdrawn and the period carries on; a subscription that is over starts afresh today.
      const withdrawn = current.status === 'canceling';
      const next = replace({
        ...current,
        status: 'active',
        canceledAt: undefined,
        cancelReason: undefined,
        cancelAt: undefined,
        renewsAt: withdrawn ? current.renewsAt : plusDays(current.cycle === 'annual' ? 365 : 30),
      });
      record(
        id,
        'reactivated',
        withdrawn
          ? 'The cancellation was withdrawn. The subscription renews as before.'
          : `Reactivated on ${plan.name} — next charge ${next.renewsAt.slice(0, 10)}.`,
      );
      return detailFor(next);
    }, 680),

  extend: (id, { days, reason }) =>
    respond(() => {
      const current = findSubscription(id);
      if (current.status !== 'active')
        throw new ServiceError('Only an active subscription can be given complimentary days.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
      if (!Number.isInteger(days) || days < 1 || days > MAX_EXTENSION_DAYS)
        throw new ServiceError(`Give between 1 and ${MAX_EXTENSION_DAYS} whole days.`, 'conflict');
      if (reason.trim().length < 3) throw new ServiceError('Give a reason of at least 3 characters.', 'conflict');
      const next = replace({ ...current, renewsAt: toIST(new Date(new Date(current.renewsAt).getTime() + days * 86_400_000)) });
      record(id, 'extended', extensionSummary(days, reason.trim()));
      return detailFor(next);
    }, 600),

  startSubscription: ({ tenantId, planId, cycle, start }) =>
    respond(() => {
      const academy = academies().find((a) => a.id === tenantId);
      if (!academy) throw new ServiceError('That academy no longer exists.', 'not-found');
      const existing = subscriptionOfAcademy(tenantId);
      if (existing && isLive(existing)) throw new ServiceError('This academy already has a live subscription.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
      const plan = findPlan(planId);
      if (plan.status !== 'active') throw new ServiceError(`${plan.name} is not on sale.`, 'conflict', 'PLAN_UNAVAILABLE');
      if (!plan.cycles.includes(cycle)) throw new ServiceError(`${plan.name} isn’t offered on a ${cycle} cycle.`, 'conflict', 'PLAN_UNAVAILABLE');
      if (start === 'trial' && !(plan.trialEnabled && plan.trialDays > 0))
        throw new ServiceError(`${plan.name} has no trial. Start it as active instead.`, 'conflict', 'PLAN_UNAVAILABLE');
      const unsubscribed = UNSUBSCRIBED.find((a) => a.id === tenantId);
      const customer = existing?.customer ?? {
        id: tenantId,
        name: academy.name,
        email: `billing@${academy.slug.replace(/-/g, '')}.in`,
        city: unsubscribed?.city ?? 'Bengaluru',
        country: 'India',
        learners: 0,
      };
      const amount = cycle === 'annual' ? plan.annualPrice : plan.monthlyPrice;
      const trial = start === 'trial';
      const renewsAt = plusDays(trial ? plan.trialDays : cycle === 'annual' ? 365 : 30);
      const created: Subscription = {
        id: `sub-${String(subscriptions.length + 1).padStart(4, '0')}`,
        customer,
        planId,
        status: trial ? 'trial' : 'active',
        cycle,
        amount,
        currency: plan.currency,
        startedAt: mockNowIso(),
        renewsAt,
        ...(trial ? { trialStartedAt: mockNowIso(), trialEndsAt: renewsAt } : {}),
        paymentMethod: { kind: 'invoice', brand: 'Bank transfer' },
      };
      subscriptions.push(created);
      record(
        created.id,
        trial ? 'trial-started' : 'created',
        trial
          ? `Trial started on ${plan.name} — ${plan.trialDays} days, ending ${renewsAt.slice(0, 10)}.`
          : `Subscribed to ${plan.name} (${cycle}) at ${money(amount)}, billed outside the gateway.`,
      );
      return detailFor(created);
    }, 700),

  listPayments: ({ search = '', status = 'all', planId, page = 1, pageSize = 20 }: PaymentQuery = {}) =>
    respond((): PaymentListResult => {
      if (scenario() === 'empty') {
        return { rows: [], total: 0, counts: emptyPaymentCounts(), totals: { collected: 0, outstanding: 0, refunded: 0, currency: CURRENCY } };
      }
      const q = search.trim().toLowerCase();
      const planName = planId ? plans.find((p) => p.id === planId)?.name : undefined;
      const matching = invoices.filter((invoice) => {
        if (q && !`${invoice.customerName} ${invoice.number} ${invoice.subscriptionId}`.toLowerCase().includes(q)) return false;
        if (planName && invoice.planName !== planName) return false;
        return true;
      });

      const counts = { ...emptyPaymentCounts(), all: matching.length };
      for (const invoice of matching) counts[invoice.status] += 1;

      const filtered = matching.filter((i) => status === 'all' || i.status === status);
      const totals = {
        collected: filtered.filter((i) => i.status === 'paid').reduce((sum, i) => sum + invoiceTotal(i), 0),
        outstanding: filtered.filter((i) => i.status === 'pending' || i.status === 'failed').reduce((sum, i) => sum + invoiceTotal(i), 0),
        refunded: filtered.filter((i) => i.status === 'refunded').reduce((sum, i) => sum + invoiceTotal(i), 0),
        currency: CURRENCY,
      };
      const start = (page - 1) * pageSize;
      return { rows: filtered.slice(start, start + pageSize), total: filtered.length, counts, totals };
    }, 440),

  getInvoice: (id) => respond(() => findInvoice(id), 320),

  /** Settles an open invoice in full; an overdue subscription recovers, as it does when the API records the payment. */
  recordInvoicePayment: (invoiceId, { method, reference, note }) =>
    respond(() => {
      const invoice = findInvoice(invoiceId);
      if (invoice.status !== 'pending' && invoice.status !== 'failed')
        throw new ServiceError(invoice.status === 'void' ? 'This invoice is void and cannot be paid.' : 'This invoice is already paid.', 'conflict');
      if (reference.trim().length < 3 || reference.trim().length > 100)
        throw new ServiceError('Give the bank, cheque or receipt reference (3–100 characters).', 'conflict');
      replaceInvoice({
        ...invoice,
        status: 'paid',
        paidAt: mockNowIso(),
        method: { kind: method === 'upi' ? 'upi' : 'invoice', brand: OFFLINE_BRAND[method] },
        note: undefined,
      });
      const sub = subscriptions.find((s) => s.id === invoice.subscriptionId);
      if (sub) {
        const recovered = sub.status === 'past-due';
        replace({
          ...sub,
          status: recovered ? 'active' : sub.status,
          lastPaymentAt: mockNowIso(),
          lastPaymentStatus: 'paid',
          amountDue: undefined,
          nextRetryAt: undefined,
          graceEndsAt: undefined,
          retriesUsed: undefined,
        });
        record(
          sub.id,
          'payment-received',
          `${OFFLINE_BRAND[method]} of ${money(invoiceTotal(invoice))} recorded against ${invoice.number} — reference ${reference.trim()}${note ? ` (${note.trim()})` : ''}.`,
        );
      }
      return {
        status: 'paid' as const,
        settled: true,
        applied: true,
        message: `${money(invoiceTotal(invoice))} recorded against ${invoice.number}. The invoice is paid.`,
      };
    }, 640),

  voidInvoice: (invoiceId, reason) =>
    respond(() => {
      const invoice = findInvoice(invoiceId);
      if (invoice.status !== 'pending' && invoice.status !== 'failed') throw new ServiceError('Only an open invoice can be voided.', 'conflict');
      if (reason.trim().length < 3) throw new ServiceError('Give a reason of at least 3 characters.', 'conflict');
      return replaceInvoice({ ...invoice, status: 'void', note: `Void — ${reason.trim()}` });
    }, 520),

  refundPayment: (id, { amount, reason }) =>
    respond(() => {
      const invoice = invoices.find((i) => paymentId(i) === id && charged(i));
      if (!invoice) throw new ServiceError('Payment not found.', 'not-found');
      const payment = paymentOf(invoice);
      const refund = amount ?? payment.refundable;
      if (payment.refundable <= 0) throw new ServiceError('Nothing is left to refund on this payment.', 'conflict');
      if (!Number.isInteger(refund) || refund < 1 || refund > payment.refundable)
        throw new ServiceError(`Refund between ${money(1)} and ${money(payment.refundable)}.`, 'conflict');
      if (reason.trim().length < 3) throw new ServiceError('Give a reason of at least 3 characters.', 'conflict');
      const total = payment.refunded + refund;
      refundedSoFar.set(id, total);
      // Returned in full, the invoice reads as refunded; the subscription itself is not touched.
      if (total >= payment.amount) replaceInvoice({ ...invoice, status: 'refunded', note: `Refunded in full — ${reason.trim()}` });
      return { id: `demo-refund-${++refundSeq}`, amount: refund, currency: payment.currency, status: 'succeeded' as const };
    }, 600),

  listWebhooks: ({ status = 'all', page = 1, pageSize = 20 } = {}) =>
    respond(() => {
      const rows = scenario() === 'empty' ? [] : webhooks.filter((w) => status === 'all' || w.status === status);
      return { rows: rows.slice((page - 1) * pageSize, page * pageSize), total: rows.length, page, pageSize };
    }, 380),

  listTaxRules: ({ includeRetired = false } = {}) => respond(() => taxRules.filter((r) => includeRetired || !r.retiredAt).map((r) => ({ ...r })), 320),

  createTaxRule: (input) =>
    respond(() => {
      const issues = taxRuleIssues(input);
      if (issues.length) throw new ServiceError(issues[0], 'conflict');
      const country = input.country.trim().toUpperCase();
      const region = input.region?.trim().toUpperCase() || undefined;
      // The rule already set for the same place is retired in the new one's favour.
      for (const r of taxRules) if (!r.retiredAt && r.country === country && r.region === region) r.retiredAt = mockNowIso();
      const rule: TaxRule = {
        id: `demo-tax-${++taxSeq}`,
        name: input.name.trim(),
        country,
        ...(region ? { region } : {}),
        inclusive: Boolean(input.inclusive),
        components: input.components.map((c) => ({ code: c.code.trim().toUpperCase(), label: c.label.trim(), rateBps: c.rateBps })),
        createdAt: mockNowIso(),
      };
      taxRules.unshift(rule);
      return { ...rule };
    }, 520),

  retireTaxRule: (id) =>
    respond(() => {
      const rule = taxRules.find((r) => r.id === id);
      if (!rule) throw new ServiceError('That tax rule no longer exists.', 'not-found');
      if (rule.retiredAt) throw new ServiceError('This tax rule is already retired.', 'conflict');
      rule.retiredAt = mockNowIso();
      return { ...rule };
    }, 420),

  listAcademies: () => respond(academies, 360),

  getAcademyBilling: (tenantId) =>
    respond((): AcademyBillingSummary => {
      const academy = academies().find((a) => a.id === tenantId);
      if (!academy) throw new ServiceError('That academy no longer exists.', 'not-found');
      const subscription = subscriptionOfAcademy(tenantId);
      return {
        academy: { id: academy.id, name: academy.name },
        subscription,
        plan: subscription ? findPlan(subscription.planId) : null,
        profile: profileOf(tenantId),
      };
    }, 400),

  saveAcademyBillingProfile: (tenantId, details) =>
    respond(() => {
      if (!academies().some((a) => a.id === tenantId)) throw new ServiceError('That academy no longer exists.', 'not-found');
      const saved = { ...details, country: details.country.trim().toUpperCase() };
      profiles.set(tenantId, saved);
      return saved;
    }, 420),
};

/* ─── Helpers ───────────────────────────────────────────────────────────── */

/** The same rule the API keeps: a plan that has been offered never goes back to draft. */
function assertReachable(from: Plan['status'] | null, to: Plan['status']) {
  if (!reachablePlanStatuses(from).includes(to)) {
    throw new ServiceError(
      to === 'draft' ? 'A plan that has been offered cannot go back to draft.' : `A ${from ?? 'new'} plan cannot be made ${to}.`,
      'conflict',
    );
  }
}

function assertPlan(input: PlanInput, exceptId?: string) {
  const taken = plans.filter((p) => p.id !== exceptId).map((p) => p.code);
  const issues = validatePlan(input, taken);
  if (issues.length) throw new ServiceError(issues[0].message, 'conflict');
}

/** Trims what the form collected, so a plan is stored the way it is shown. */
const normalise = (input: PlanInput): PlanInput => ({
  ...input,
  name: input.name.trim(),
  description: input.description.trim(),
  code: input.code.trim().toUpperCase(),
  trialDays: input.trialEnabled ? input.trialDays : 0,
});

const emptyCounts = () => ({ all: 0, ...Object.fromEntries(SUBSCRIPTION_STATUSES.map((s) => [s, 0])) }) as Record<SubscriptionStatus | 'all', number>;

const emptyPaymentCounts = () => ({ all: 0, ...Object.fromEntries(PAYMENT_STATUSES.map((s) => [s, 0])) }) as Record<PaymentStatus | 'all', number>;

const zeroKpi = (): Kpi => ({ value: 0, previous: 0, series: [0, 0, 0, 0, 0, 0] });

/** `?scenario=empty`: a platform with nothing sold yet, so the empty states can be reviewed. */
function emptyOverview(): SubscriptionOverview {
  return {
    kpis: { active: zeroKpi(), trial: zeroKpi(), pastDue: zeroKpi(), canceling: zeroKpi(), mrr: zeroKpi(), arr: zeroKpi() },
    growth: [],
    revenue: [],
    byPlan: [],
    statusCounts: Object.fromEntries(SUBSCRIPTION_STATUSES.map((s) => [s, 0])) as Record<SubscriptionStatus, number>,
    attention: [],
    currency: CURRENCY,
    generatedAt: mockNowIso(),
  };
}
