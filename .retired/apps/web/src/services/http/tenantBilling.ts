import type {
  AcademyPlan,
  BillingDetails,
  CheckoutOutcome,
  CheckoutStart,
  Invoice,
  PlanChangePreview,
  PlanChangeQuote,
  TenantBilling,
} from '@syniastrolms/domain';
import { ServiceError, type TenantBillingService } from '../contracts';
import { get, post, put } from './client';

/*
 * The academy's own billing page against `/tenant/*` (§24; SAAS-015). The academy is the signed-in
 * account's — nothing here names one — and every figure, quote and date is the server's.
 */
export const httpTenantBilling: TenantBillingService = {
  summary: () => get<TenantBilling>('/tenant/billing'),
  // Admins and instructors alike: which modules the plan opens, never what it costs.
  academyPlan: () => get<AcademyPlan>('/academy/plan'),
  // No payment and no billing address: the trial starts at once, and the screen reads the summary again.
  startTrial: async (input) => {
    await post('/tenant/billing/trial', { planId: input.planId, cycle: input.cycle });
  },
  // A preview writes nothing: what the change would cost and when, with tax, before it is asked for.
  previewChange: (input) => post<PlanChangePreview>('/tenant/subscription/preview', { planId: input.planId, cycle: input.cycle }),
  requestChange: (input) => post<PlanChangeQuote>('/tenant/subscription/change', { planId: input.planId, cycle: input.cycle }),
  cancel: async (input) => {
    await post('/tenant/subscription/cancel', { immediately: input.immediately, reason: input.reason });
  },
  resume: async () => {
    await post('/tenant/subscription/resume', {});
  },
  withdrawChange: async (id) => {
    await post(`/tenant/subscription/plan-changes/${id}/cancel`, {});
  },
  getInvoice: (id) => get<Invoice>(`/tenant/billing/invoices/${encodeURIComponent(id)}`),
  startFirstPurchase: (input) => post<CheckoutStart>('/tenant/billing/purchase', { planId: input.planId, cycle: input.cycle }),
  startCheckout: (target) =>
    post<CheckoutStart>('/tenant/billing/checkout', target.planChangeId ? { planChangeId: target.planChangeId } : { invoiceId: target.invoiceId }),
  getBillingDetails: async () => {
    try {
      return await get<BillingDetails>('/tenant/billing-profile');
    } catch (err) {
      // No profile yet is an answer, not a failure.
      if (err instanceof ServiceError && err.code === 'not-found') return null;
      throw err;
    }
  },
  saveBillingDetails: (details) => put<BillingDetails>('/tenant/billing-profile', details),
  confirmCheckout: (completion) =>
    post<CheckoutOutcome>('/tenant/billing/checkout/confirm', {
      orderId: completion.orderId,
      paymentId: completion.paymentId,
      signature: completion.signature,
    }),
};
