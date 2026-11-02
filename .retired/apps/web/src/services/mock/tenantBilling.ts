import type {
  AcademyPlan,
  BillingCycle,
  BillingDetails,
  Invoice,
  OpenPlanChange,
  Plan,
  PlanChangePreview,
  PlanChangeQuote,
  Subscription,
  TenantBilling,
  TenantPayment,
  UsageLine,
} from '@syniastrolms/domain';
import {
  FEATURES,
  LIMITS,
  SUBSCRIPTION_STATUS_OF,
  calculateTax,
  classifyPlanChange,
  invoiceTotal,
  isImmediate,
  quoteImmediateChange,
} from '@syniastrolms/domain';
import type { TenantBillingService } from '../contracts';
import { ServiceError } from '../contracts';
import { mockNow, mockNowIso } from './clock';
import { courses, instructors } from './fixtures/catalog';
import { students } from './fixtures/people';
import { CURRENCY, invoices, plans, subscriptions } from './fixtures/subscriptions';
import { toIST } from './random';
import { respond } from './simulation';

/*
 * The academy's own billing page for the demo build. Every figure is invented: the academy is shown on
 * one of the platform demo's subscriptions, renamed, and its usage is counted from the demo catalogue.
 * A plan change follows the real rules — an upgrade is quoted with the same proration the server uses
 * (D7, D8) and waits for a payment the demo never takes; a downgrade is scheduled for the period end
 * (D10) — so the screen behaves as it will against the API.
 */

const ACADEMY = { id: 'demo-academy', name: 'ZuviloAI Academy' };
const SOURCE_ID = subscriptions.find((s) => s.status === 'active' && s.cycle === 'monthly' && s.planId === 'growth')?.id ?? subscriptions[0].id;

let openChange: OpenPlanChange | null = null;
let changeSeq = 0;
/** What the academy's own cancel and resume changed this session, laid over the platform demo's record. */
let own: Partial<Subscription> = {};
/** A free trial the academy started itself this session — once its last subscription had ended. */
let trial: Subscription | null = null;
/** Whether the academy has had its one free trial. The demo record it starts from was bought, not trialled. */
let trialUsed = false;

const source = (): Subscription => ({ ...(trial ?? subscriptions.find((s) => s.id === SOURCE_ID)!), ...own });
const isLive = (s: Subscription) => s.status !== 'canceled' && s.status !== 'expired';
const SERVER_STATE = Object.fromEntries(Object.entries(SUBSCRIPTION_STATUS_OF).map(([server, ui]) => [ui, server])) as Record<
  Subscription['status'],
  NonNullable<AcademyPlan['status']>
>;
const planOf = (id: string): Plan => {
  const plan = plans.find((p) => p.id === id);
  if (!plan) throw new ServiceError('That plan is not available.', 'not-found', 'PLAN_UNAVAILABLE');
  return plan;
};

const periodStart = (renewsAt: string, cycle: BillingCycle) => {
  const d = new Date(renewsAt);
  if (cycle === 'annual') d.setUTCFullYear(d.getUTCFullYear() - 1);
  else d.setUTCMonth(d.getUTCMonth() - 1);
  return d;
};

function usage(plan: Plan): UsageLine[] {
  const used: Record<string, number> = {
    'learners.max': students.length,
    'instructors.max': instructors.length,
    'courses.max': courses.length,
    'storage.bytes': 3.2 * 1024 ** 3,
    'live_classes.max': 6,
    'admin_accounts.max': 2,
  };
  return LIMITS.map(({ key, label }) => {
    const allowed = plan.limits[key];
    const n = Math.round(used[key]);
    return { limit: key, label, used: n, allowed, remaining: allowed === null ? null : Math.max(0, allowed - n) };
  });
}

/** What a move would do, priced as the server prices it (D7–D10). Writes nothing. */
function preview(planId: string, cycle: BillingCycle): PlanChangePreview {
  const sub = source();
  if (sub.status !== 'active') throw new ServiceError('Only an active subscription can change plan.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
  const target = planOf(planId);
  if (target.status !== 'active') throw new ServiceError(`${target.name} is not on sale.`, 'conflict', 'PLAN_UNAVAILABLE');
  if (!target.cycles.includes(cycle)) throw new ServiceError(`${target.name} is not sold ${cycle}.`, 'conflict', 'PLAN_UNAVAILABLE');
  if (openChange) throw new ServiceError('A plan change is already waiting. Withdraw it first.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
  const amount = cycle === 'annual' ? target.annualPrice : target.monthlyPrice;
  const kind = classifyPlanChange({ planVersionId: sub.planId, cycle: sub.cycle, amount: sub.amount }, { planVersionId: planId, cycle, amount });
  if (!kind) throw new ServiceError('The subscription is already on that plan and cycle.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
  const to = { planId, planName: target.name, cycle, amount };
  // Limits the academy already uses past: kept, but nothing new past them once the change applies.
  const conflicts = usage(target)
    .filter((u) => u.allowed !== null && u.used > u.allowed)
    .map((u) => ({ limit: u.limit, usage: u.used, newLimit: u.allowed! }));
  if (!isImmediate(kind)) {
    return {
      kind,
      when: 'period_end',
      appliesAt: sub.renewsAt,
      to,
      currency: CURRENCY,
      credit: 0,
      charge: 0,
      forfeited: 0,
      payable: null,
      needsBillingAddress: false,
      conflicts,
    };
  }
  const quote = quoteImmediateChange({
    kind: kind as 'upgrade' | 'cycle_upgrade',
    currentAmount: sub.amount,
    newAmount: amount,
    periodStart: periodStart(sub.renewsAt, sub.cycle),
    periodEnd: new Date(sub.renewsAt),
    at: mockNow(),
  });
  const tax = calculateTax(quote.charge, CURRENCY, [{ code: 'GST', label: 'GST', rateBps: 1800 }]);
  const needsBillingAddress = quote.charge > 0 && !billingDetails;
  return {
    kind,
    when: 'on_payment',
    appliesAt: mockNowIso(),
    to,
    currency: CURRENCY,
    credit: quote.credit,
    charge: quote.charge,
    forfeited: quote.forfeited,
    payable: quote.charge > 0 && !needsBillingAddress ? { net: tax.net, tax: tax.tax, gross: tax.gross } : null,
    needsBillingAddress,
    conflicts,
  };
}

function ownInvoices(): Invoice[] {
  return invoices.filter((i) => i.subscriptionId === SOURCE_ID).map((i) => ({ ...i, customerName: ACADEMY.name }));
}

function summary(): TenantBilling {
  const sub = source();
  const plan = planOf(sub.planId);
  const own = ownInvoices();
  const payments: TenantPayment[] = own
    .filter((i) => i.status !== 'pending' && i.status !== 'void')
    .map((i) => ({
      id: `pay-${i.id}`,
      invoiceNumber: i.number,
      amount: invoiceTotal(i),
      currency: i.currency,
      status: i.status === 'failed' ? 'failed' : i.status === 'refunded' ? 'refunded' : 'paid',
      refunded: i.status === 'refunded' ? invoiceTotal(i) : 0,
      method: i.method.last4 ? `${i.method.brand} •••• ${i.method.last4}` : i.method.brand,
      at: i.paidAt ?? i.issuedAt,
      ...(i.status === 'failed' && i.note ? { failureMessage: i.note } : {}),
    }));
  return {
    academy: ACADEMY,
    subscription: { ...sub, customer: { ...sub.customer, id: ACADEMY.id, name: ACADEMY.name } },
    plan,
    restricted: false,
    enforced: true,
    openChange,
    usage: usage(plan),
    features: FEATURES.map((f) => ({ key: f.key, label: f.label, included: plan.features.includes(f.key), enforcement: f.enforcement })),
    invoices: own,
    payments,
    plans: plans.filter((p) => p.status === 'active').sort((a, b) => a.order - b.order),
    checkoutAvailable: false,
    trialAvailable: !isLive(sub) && !trialUsed,
  };
}

/** What the plan lets the academy's staff use, as `GET /academy/plan` answers: an ended plan's features stay readable. */
function academyPlan(): AcademyPlan {
  const sub = source();
  const plan = planOf(sub.planId);
  const served = sub.status !== 'canceled' && sub.status !== 'expired' && sub.status !== 'paused';
  return {
    enforced: true,
    status: SERVER_STATE[sub.status],
    restricted: !served,
    plan: { id: plan.id, code: plan.code, name: plan.name },
    features: served ? [...plan.features] : [],
    lastFeatures: served ? [] : [...plan.features],
    ...(sub.status === 'trial' && sub.trialEndsAt ? { trialEndsAt: sub.trialEndsAt } : {}),
    ...(served && sub.status !== 'trial' ? { renewsAt: sub.renewsAt } : {}),
    academy: { name: 'ZuviloAI Demo Academy', slug: 'default' },
  };
}

/** The trial the API would start: once per academy, on a plan that has one, only when nothing is live. */
function startTrial(planId: string, cycle: BillingCycle) {
  const sub = source();
  if (isLive(sub)) throw new ServiceError('This academy already has a subscription.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
  if (trialUsed) throw new ServiceError('This academy has already had a free trial.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
  const plan = planOf(planId);
  if (plan.status !== 'active' || !plan.trialEnabled || plan.trialDays <= 0)
    throw new ServiceError(`${plan.name} has no free trial.`, 'conflict', 'PLAN_UNAVAILABLE');
  if (!plan.cycles.includes(cycle)) throw new ServiceError(`${plan.name} is not sold ${cycle}.`, 'conflict', 'PLAN_UNAVAILABLE');
  const now = mockNow();
  const ends = toIST(new Date(now.getTime() + plan.trialDays * 86_400_000));
  trial = {
    ...sub,
    id: 'demo-trial',
    planId,
    cycle,
    status: 'trial',
    amount: cycle === 'annual' ? plan.annualPrice : plan.monthlyPrice,
    startedAt: toIST(now),
    trialStartedAt: toIST(now),
    trialEndsAt: ends,
    renewsAt: ends,
    canceledAt: undefined,
    cancelReason: undefined,
    cancelAt: undefined,
  };
  own = {};
  openChange = null;
  trialUsed = true;
}

/** The demo academy's billing details, kept for the session. */
let billingDetails: BillingDetails | null = null;

export const tenantBillingService: TenantBillingService = {
  getBillingDetails: () => respond(() => billingDetails, 200),
  saveBillingDetails: (details) =>
    respond(() => {
      billingDetails = { ...details, country: details.country.toUpperCase() };
      return billingDetails;
    }, 300),
  summary: () => respond(summary, 420),
  academyPlan: () => respond(academyPlan, 260),
  startTrial: ({ planId, cycle }) => respond(() => startTrial(planId, cycle), 520),

  previewChange: ({ planId, cycle }) => respond(() => preview(planId, cycle), 420),

  requestChange: ({ planId, cycle }) =>
    respond((): PlanChangeQuote => {
      const p = preview(planId, cycle);
      const base = {
        id: `demo-change-${++changeSeq}`,
        toPlanId: planId,
        toPlanName: p.to.planName,
        toCycle: cycle,
        currency: CURRENCY,
        quotedAt: mockNowIso(),
      };
      if (p.when === 'period_end') {
        openChange = { ...base, direction: 'downgrade', status: 'scheduled', credit: 0, charge: 0, effectiveAt: p.appliesAt };
        return { change: openChange };
      }
      // An upgrade is taxed by the billing address: without one only a downgrade can be asked for, as on the server.
      if (p.needsBillingAddress) throw new ServiceError('Add the academy’s billing address before upgrading.', 'conflict');
      openChange = { ...base, direction: 'upgrade', status: 'pending_payment', credit: p.credit, charge: p.charge };
      const tax = calculateTax(p.charge, CURRENCY, [{ code: 'GST', label: 'GST', rateBps: 1800 }]);
      return { change: openChange, payable: { net: tax.net, tax: tax.tax, gross: tax.gross, currency: CURRENCY } };
    }, 600),

  cancel: ({ immediately, reason }) =>
    respond(() => {
      const sub = source();
      if (!['active', 'past-due', 'trial'].includes(sub.status))
        throw new ServiceError('Only a live subscription can be cancelled.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
      if (reason.trim().length < 3) throw new ServiceError('Give a reason of at least 3 characters.', 'conflict');
      own = {
        ...own,
        status: immediately ? 'canceled' : 'canceling',
        canceledAt: mockNowIso(),
        cancelReason: reason.trim(),
        cancelAt: immediately ? 'immediately' : 'period-end',
        ...(immediately ? { renewsAt: mockNowIso() } : {}),
      };
      openChange = null;
    }, 520),

  resume: () =>
    respond(() => {
      const sub = source();
      // A pause is the platform's: the academy cannot end it, as the API answers.
      if (sub.status === 'paused')
        throw new ServiceError('This subscription was paused by the platform team. Contact them to resume it.', 'forbidden', 'INVALID_SUBSCRIPTION_STATE');
      if (sub.status !== 'canceling') throw new ServiceError('There is no cancellation to withdraw.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
      own = { ...own, status: 'active', canceledAt: undefined, cancelReason: undefined, cancelAt: undefined };
    }, 480),

  withdrawChange: (id) =>
    respond(() => {
      if (!openChange || openChange.id !== id) throw new ServiceError('That plan change is no longer open.', 'conflict', 'INVALID_SUBSCRIPTION_STATE');
      openChange = null;
    }, 400),

  // The demo takes no payment: its page offers no checkout (`checkoutAvailable` is false).
  startFirstPurchase: () =>
    respond(() => {
      throw new ServiceError('Online payment is not available in the demo.', 'conflict', 'PAYMENT_REQUIRED');
    }, 300),
  startCheckout: () =>
    respond(() => {
      throw new ServiceError('Online payment is not available in the demo.', 'conflict', 'PAYMENT_REQUIRED');
    }, 300),
  confirmCheckout: () =>
    respond(() => {
      throw new ServiceError('Online payment is not available in the demo.', 'conflict', 'PAYMENT_REQUIRED');
    }, 300),

  getInvoice: (id) =>
    respond(() => {
      const invoice = ownInvoices().find((i) => i.id === id || i.number.toLowerCase() === id.toLowerCase());
      if (!invoice) throw new ServiceError('That invoice no longer exists.', 'not-found');
      return invoice;
    }, 320),
};
