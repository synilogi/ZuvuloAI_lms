import type {
  AcademyBillingSummary,
  BillingAcademy,
  BillingCycle,
  BillingDetails,
  CheckoutOutcome,
  Invoice,
  PaymentListResult,
  PaymentQuery,
  Plan,
  PlanChangeKind,
  PlanDetail,
  PlanInput,
  PlanListResult,
  PlanQuery,
  PlanStatus,
  PlanVersion,
  RefundResult,
  SubscriberListResult,
  SubscriberQuery,
  SubscriptionDetail,
  SubscriptionEvent,
  SubscriptionOverview,
  SubscriptionPayment,
  SubscriptionPlanChange,
  TaxRule,
  TenantBilling,
  WebhookListResult,
  WebhookQuery,
} from '@syniastrolms/domain';
import { reachablePlanStatuses } from '@syniastrolms/domain';
import { extensionSummary } from '@/lib/billingStates';
import { PlanStatusError, ServiceError, type CancelInput, type ChangePlanInput, type SubscriptionService } from '../contracts';
import { get, patch, post, put } from './client';

/*
 * The platform's subscription screens against the billing API (SAAS-015).
 *
 * Reads come from `/superadmin/billing-views/*`, which answers in exactly the shapes the screens use, with
 * every figure computed on the server. Changes go to the billing endpoints, which apply the platform's
 * rules: a plan's terms are versioned, a plan change is priced and timed by D7–D10, a pause runs 1–30
 * days (D9). After a change the screen reads the record again, so what it shows is what was stored.
 */

const VIEWS = '/superadmin/billing-views';

/** What the plan endpoints take: the terms and the allowance. Status moves only through its own steps. */
const planBody = (input: PlanInput) => ({
  name: input.name,
  description: input.description,
  code: input.code,
  currency: input.currency,
  cycles: input.cycles,
  monthlyPrice: input.monthlyPrice,
  annualPrice: input.annualPrice,
  trialEnabled: input.trialEnabled,
  trialDays: input.trialEnabled ? input.trialDays : 0,
  limits: input.limits,
  features: input.features,
  displayOrder: input.order,
});

const planView = async (id: string): Promise<Plan> => (await get<PlanDetail>(`${VIEWS}/plans/${id}`)).plan;

/** Refuses a status the plan cannot reach from `from` — before anything is sent, so nothing is half-saved. */
function assertReachable(from: PlanStatus | null, to: PlanStatus) {
  if (reachablePlanStatuses(from).includes(to)) return;
  // A plan that has been offered never goes back to draft: the API refuses it, and so does this.
  throw new ServiceError(
    to === 'draft' ? 'A plan that has been offered cannot go back to draft.' : `A ${from ?? 'new'} plan cannot be made ${to}.`,
    'conflict',
  );
}

/** Moves a plan from `from` to `to` through the named steps: publish, archive, restore. */
async function moveStatus(id: string, from: PlanStatus, to: PlanStatus) {
  if (from === to) return;
  if (to === 'active') await post(`/superadmin/plans/${id}/${from === 'archived' ? 'restore' : 'publish'}`);
  else await post(`/superadmin/plans/${id}/archive`);
}

/**
 * Moves the plan just saved to the status asked for. When the move is refused the terms are stored all the
 * same, so the error carries the plan as it now stands: the editor carries on from it instead of repeating a
 * create that would meet its own code.
 */
async function settleStatus(id: string, from: PlanStatus, to: PlanStatus): Promise<Plan> {
  try {
    await moveStatus(id, from, to);
  } catch (err) {
    throw new PlanStatusError((err as Error).message, await planView(id));
  }
  return planView(id);
}

/* ─── The raw billing records the views leave out ─── */

/** `/superadmin/subscriptions/:id` — the records behind the view: lifecycle, plan changes and payments. */
interface SubscriptionRecords {
  lifecycle?: { id: number; transition: string; event: string; meta: Record<string, unknown> }[];
  planChanges?: {
    id: string;
    kind: PlanChangeKind;
    status: string;
    to: { planId: string; cycle: BillingCycle; amount: number };
    currency: string;
    credit: number;
    charge: number;
    period: { start: string; end: string };
    quotedAt: string;
  }[];
  payments?: {
    id: string;
    invoiceId?: string;
    provider: string;
    providerPaymentId: string;
    amount: number;
    currency: string;
    status: SubscriptionPayment['status'];
    refunded: number;
    refundable: number;
    method?: { display: string };
    paidAt?: string;
    failedAt?: string;
    failureMessage?: string;
    createdAt: string;
  }[];
}

/**
 * The view's history names each lifecycle event `event-<id>`; an extension it does not word yet arrives as
 * its raw event name, so it is worded here from the record's own meta.
 */
function wordEvents(events: SubscriptionEvent[], lifecycle: NonNullable<SubscriptionRecords['lifecycle']>): SubscriptionEvent[] {
  const extensions = new Map(lifecycle.filter((e) => e.transition === 'extend').map((e) => [`event-${e.id}`, e.meta]));
  return events.map((e) => {
    const meta = extensions.get(e.id);
    if (!meta) return e;
    return { ...e, kind: 'extended', summary: extensionSummary(Number(meta.days ?? 0), typeof meta.reason === 'string' ? meta.reason : undefined) };
  });
}

const OPEN_CHANGE = new Set(['pending_payment', 'scheduled']);

/** The subscription's view, with its open plan changes and payments from the records behind it. */
async function detail(id: string): Promise<SubscriptionDetail> {
  const [view, records] = await Promise.all([
    get<SubscriptionDetail>(`${VIEWS}/subscriptions/${id}`),
    get<SubscriptionRecords>(`/superadmin/subscriptions/${id}`),
  ]);
  const openChanges: SubscriptionPlanChange[] = (records.planChanges ?? [])
    .filter((c) => OPEN_CHANGE.has(c.status))
    .map((c) => ({
      id: c.id,
      kind: c.kind,
      status: c.status as SubscriptionPlanChange['status'],
      toPlanId: c.to.planId,
      toCycle: c.to.cycle,
      toAmount: c.to.amount,
      currency: c.currency,
      credit: c.credit,
      charge: c.charge,
      periodEnd: c.period.end,
      quotedAt: c.quotedAt,
    }));
  const payments: SubscriptionPayment[] = (records.payments ?? [])
    .map((p) => ({
      id: p.id,
      ...(p.invoiceId ? { invoiceId: p.invoiceId } : {}),
      provider: p.provider,
      providerPaymentId: p.providerPaymentId,
      amount: p.amount,
      currency: p.currency,
      status: p.status,
      refunded: p.refunded,
      refundable: p.refundable,
      ...(p.method ? { method: p.method.display } : {}),
      at: p.paidAt ?? p.failedAt ?? p.createdAt,
      ...(p.failureMessage ? { failureMessage: p.failureMessage } : {}),
    }))
    .sort((a, b) => b.at.localeCompare(a.at));
  return { ...view, events: wordEvents(view.events ?? [], records.lifecycle ?? []), openChanges, payments };
}

export const httpSubscriptions: SubscriptionService = {
  overview: () => get<SubscriptionOverview>(`${VIEWS}/overview`),

  listPlans: (query: PlanQuery = {}) => get<PlanListResult>(`${VIEWS}/plans`, query),
  /** The view, with the plan's version history from the plan record. */
  getPlan: async (id) => {
    const [view, record] = await Promise.all([get<PlanDetail>(`${VIEWS}/plans/${id}`), get<{ versions?: PlanVersion[] }>(`/superadmin/plans/${id}`)]);
    return { ...view, versions: record.versions ?? [] };
  },

  createPlan: async (input) => {
    assertReachable(null, input.status);
    const created = await post<{ id: string }>('/superadmin/plans', planBody(input));
    return settleStatus(created.id, 'draft', input.status);
  },

  updatePlan: async (id, input) => {
    const before = await planView(id);
    assertReachable(before.status, input.status);
    await patch(`/superadmin/plans/${id}`, planBody(input));
    return settleStatus(id, before.status, input.status);
  },

  /** A copy as a draft under the first free `CODE-n`, so the original keeps its subscribers and its code. */
  duplicatePlan: async (id) => {
    const [source, all] = await Promise.all([planView(id), get<PlanListResult>(`${VIEWS}/plans`)]);
    const taken = new Set(all.rows.map((r) => r.plan.code));
    let n = 2;
    while (taken.has(`${source.code}-${n}`)) n++;
    const created = await post<{ id: string }>(
      '/superadmin/plans',
      planBody({ ...source, name: `${source.name} (copy)`, code: `${source.code}-${n}`, status: 'draft', order: all.counts.all + 1 }),
    );
    return planView(created.id);
  },

  archivePlan: async (id) => {
    await post(`/superadmin/plans/${id}/archive`);
    return planView(id);
  },
  restorePlan: async (id) => {
    await post(`/superadmin/plans/${id}/restore`);
    return planView(id);
  },
  publishPlan: async (id) => {
    await post(`/superadmin/plans/${id}/publish`);
    return planView(id);
  },

  listSubscribers: (query: SubscriberQuery = {}) => get<SubscriberListResult>(`${VIEWS}/subscribers`, query),
  getSubscription: detail,

  changePlan: async (id, input: ChangePlanInput) => {
    await post(`/superadmin/subscriptions/${id}/plan-change`, { planId: input.planId, cycle: input.cycle });
    return detail(id);
  },
  pause: async (id, days) => {
    await post(`/superadmin/subscriptions/${id}/pause`, { days });
    return detail(id);
  },
  resume: async (id) => {
    await post(`/superadmin/subscriptions/${id}/resume`, {});
    return detail(id);
  },
  cancel: async (id, input: CancelInput) => {
    await post(`/superadmin/subscriptions/${id}/cancel`, { reason: input.reason, immediately: input.effective === 'immediately' });
    return detail(id);
  },

  /**
   * A cancellation still pending is withdrawn. A subscription that is over stays over — it is history — so
   * reactivating starts the academy a new one on the same plan and cycle, at the plan's current price.
   */
  reactivate: async (id) => {
    const current = await detail(id);
    const s = current.subscription;
    if (s.status === 'canceling') {
      await post(`/superadmin/subscriptions/${id}/resume`, {});
      return detail(id);
    }
    const started = await post<{ id: string }>('/superadmin/subscriptions', { tenantId: s.customer.id, planId: s.planId, cycle: s.cycle, start: 'active' });
    return detail(started.id);
  },

  extend: async (id, input) => {
    await post(`/superadmin/subscriptions/${id}/extend`, { days: input.days, reason: input.reason });
    return detail(id);
  },
  /** The price is the plan's; only the plan, the cycle and how it starts are named. */
  startSubscription: async (input) => {
    const started = await post<{ id: string }>('/superadmin/subscriptions', {
      tenantId: input.tenantId,
      planId: input.planId,
      cycle: input.cycle,
      start: input.start,
    });
    return detail(started.id);
  },

  listPayments: (query: PaymentQuery = {}) => get<PaymentListResult>(`${VIEWS}/payments`, query),
  getInvoice: (id) => get<Invoice>(`${VIEWS}/invoices/${encodeURIComponent(id)}`),
  // The amount is the invoice's total, never the caller's.
  recordInvoicePayment: (invoiceId, input) =>
    post<CheckoutOutcome>(`/superadmin/invoices/${encodeURIComponent(invoiceId)}/record-payment`, {
      method: input.method,
      reference: input.reference,
      ...(input.note ? { note: input.note } : {}),
    }),
  voidInvoice: async (invoiceId, reason) => {
    await post(`/superadmin/invoices/${encodeURIComponent(invoiceId)}/void`, { reason });
    return get<Invoice>(`${VIEWS}/invoices/${encodeURIComponent(invoiceId)}`);
  },
  refundPayment: (paymentId, input) =>
    post<RefundResult>(`/superadmin/payments/${encodeURIComponent(paymentId)}/refund`, {
      ...(input.amount !== undefined ? { amount: input.amount } : {}),
      reason: input.reason,
    }),

  listWebhooks: ({ status, page = 1, pageSize = 20 }: WebhookQuery = {}) =>
    get<WebhookListResult>('/superadmin/webhooks', { status: status === 'all' ? undefined : status, page, pageSize }),
  listTaxRules: async ({ includeRetired = false } = {}) =>
    (await get<{ rows: TaxRule[] }>('/superadmin/tax-rules', includeRetired ? { includeRetired: true } : undefined)).rows,
  createTaxRule: (input) =>
    post<TaxRule>('/superadmin/tax-rules', {
      name: input.name,
      country: input.country,
      ...(input.region ? { region: input.region } : {}),
      inclusive: Boolean(input.inclusive),
      components: input.components,
    }),
  retireTaxRule: (id) => post<TaxRule>(`/superadmin/tax-rules/${id}/retire`),

  listAcademies: async () => {
    const page = await get<{ rows: BillingAcademy[] }>('/superadmin/tenants');
    return page.rows.map((a) => ({ id: a.id, name: a.name, slug: a.slug, status: a.status }));
  },
  /** The academy's billing as its own admin sees it, and its billing profile — none yet is an answer. */
  getAcademyBilling: async (tenantId): Promise<AcademyBillingSummary> => {
    const [billing, profile] = await Promise.all([
      get<TenantBilling>(`/superadmin/tenants/${tenantId}/subscription`),
      get<BillingDetails>(`/superadmin/tenants/${tenantId}/billing-profile`).catch((err: unknown) => {
        if (err instanceof ServiceError && err.code === 'not-found') return null;
        throw err;
      }),
    ]);
    return { academy: billing.academy, subscription: billing.subscription, plan: billing.plan, profile };
  },
  saveAcademyBillingProfile: (tenantId, details) => put<BillingDetails>(`/superadmin/tenants/${tenantId}/billing-profile`, details),
};
