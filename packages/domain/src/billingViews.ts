import type { Kpi } from './analytics';
import type { FeatureEnforcement, FeatureKey, LimitKey, PlanLimits } from './entitlement';
import type { SubscriptionState } from './lifecycle';
import type { PlanChangeKind } from './planChange';
import type { TaxComponent } from './tax';
import type { BillingCycle, Invoice, PaymentStatus, Plan, PlanStatus, Subscription, SubscriptionEvent, SubscriptionStatus } from './subscription';

/*
 * The shapes the subscription screens read (SAAS-015). The billing API builds them from its own records
 * and the web app shows them as they arrive, so both sides share one definition. Every amount is an
 * integer in the currency's minor unit, and every figure is the server's: a screen never recalculates
 * a price, a total or a count.
 */

/** The lifecycle state the API stores, as the screens name it. */
export const SUBSCRIPTION_STATUS_OF: Record<SubscriptionState, SubscriptionStatus> = {
  trialing: 'trial',
  active: 'active',
  past_due: 'past-due',
  paused: 'paused',
  canceling: 'canceling',
  canceled: 'canceled',
  expired: 'expired',
};

/* ─── Super Admin ────────────────────────────────────────────────────────── */

/** A plan with the figures the list and detail screens show beside it. */
export interface PlanRow {
  plan: Plan;
  /** Every subscription on this plan, whatever its state. */
  subscribers: number;
  /** Those still being billed — the figure the plan list leads with. */
  activeSubscribers: number;
  /** What those subscriptions are worth a month. */
  mrr: number;
}

export type PlanSort = 'name' | 'price' | 'subscribers' | 'updated';

export interface PlanQuery {
  search?: string;
  status?: PlanStatus | 'all';
  sort?: PlanSort;
}

export interface PlanListResult {
  rows: PlanRow[];
  counts: { all: number; active: number; draft: number; archived: number };
}

/** One point of a plan's history: how many were on it, how many joined, how many left. */
export interface PlanTrendPoint {
  /** Month label, e.g. "Apr". */
  label: string;
  detail: string;
  active: number;
  added: number;
  canceled: number;
}

export interface PlanDetail extends PlanRow {
  trend: PlanTrendPoint[];
  /** Subscriptions on this plan, newest first — the top few are listed on the detail page. */
  subscriptions: SubscriptionRow[];
  byStatus: { status: SubscriptionStatus; count: number }[];
  /**
   * Every version of the plan's terms, oldest first: each edit to a price, trial, feature or limit writes
   * the next one, and a subscription keeps the version it was sold. Read from `/superadmin/plans/:id`.
   */
  versions?: PlanVersion[];
}

/** The terms one version of a plan fixed. A price is null on a cycle that version did not sell. */
export interface PlanVersion {
  id: string;
  version: number;
  currency: string;
  monthlyPrice: number | null;
  annualPrice: number | null;
  cycles: BillingCycle[];
  trialDays: number;
  features: FeatureKey[];
  limits: PlanLimits;
  createdAt: string;
}

/** A subscription with the plan facts the row needs, so the list never has to join two calls. */
export interface SubscriptionRow {
  subscription: Subscription;
  planName: string;
  planCode: string;
}

export type SubscriberSort = 'renewal' | 'started' | 'customer' | 'amount';

export interface SubscriberQuery {
  search?: string;
  planId?: string;
  status?: SubscriptionStatus | 'all';
  cycle?: BillingCycle | 'all';
  payment?: PaymentStatus | 'all';
  /** Renewal date window, YYYY-MM-DD. */
  from?: string;
  to?: string;
  sort?: SubscriberSort;
  page?: number;
  pageSize?: number;
}

export interface SubscriberListResult {
  rows: SubscriptionRow[];
  total: number;
  /** Every status, counted before the status filter is applied, for the tab counts. */
  counts: Record<SubscriptionStatus | 'all', number>;
}

export interface SubscriptionDetail {
  subscription: Subscription;
  plan: Plan;
  /** Newest first. */
  events: SubscriptionEvent[];
  /** This subscription's invoices, newest first. */
  invoices: Invoice[];
  /** Plan changes asked for and not yet applied: an upgrade awaiting payment, a downgrade awaiting the period end. */
  openChanges?: SubscriptionPlanChange[];
  /** The payments taken against this subscription, newest first. */
  payments?: SubscriptionPayment[];
}

/** A plan change still open on a subscription, as the platform sees it (`/superadmin/subscriptions/:id`). */
export interface SubscriptionPlanChange {
  id: string;
  kind: PlanChangeKind;
  status: 'pending_payment' | 'scheduled';
  toPlanId: string;
  toCycle: BillingCycle;
  /** What the new plan and cycle cost each period, minor units. */
  toAmount: number;
  currency: string;
  /** Minor units: the unused value credited, and what is charged now — both 0 for a scheduled change. */
  credit: number;
  charge: number;
  /** The end of the period the change was priced against: a scheduled change applies then. */
  periodEnd: string;
  quotedAt: string;
}

/** A payment against a subscription, with what has been refunded and what still can be. Minor units. */
export interface SubscriptionPayment {
  id: string;
  invoiceId?: string;
  /** The gateway that took it, or `offline` for one the platform recorded. */
  provider: string;
  providerPaymentId: string;
  amount: number;
  currency: string;
  status: 'pending' | 'paid' | 'failed' | 'refunded' | 'partially_refunded';
  refunded: number;
  refundable: number;
  /** "Visa •••• 4242", "Bank transfer" — never more. */
  method?: string;
  at: string;
  failureMessage?: string;
}

/** What asking for a refund answers with. An offline payment's refund succeeds at once; a gateway's may wait. */
export interface RefundResult {
  id: string;
  amount: number;
  currency: string;
  status: 'pending' | 'succeeded' | 'failed';
}

/** How a payment made outside the gateway was received. */
export type OfflinePaymentMethod = 'bank_transfer' | 'cheque' | 'cash' | 'upi' | 'other';

export const OFFLINE_PAYMENT_METHODS: readonly OfflinePaymentMethod[] = ['bank_transfer', 'cheque', 'cash', 'upi', 'other'];

/** A payment received outside the gateway, recorded against an open invoice for its full total. */
export interface OfflinePaymentInput {
  method: OfflinePaymentMethod;
  /** The bank, cheque or receipt reference: 3–100 characters. */
  reference: string;
  note?: string;
}

/** A tax rule as it is stored: the tax charged for a country, or a region of it, until it is retired. */
export interface TaxRule {
  id: string;
  name: string;
  country: string;
  region?: string;
  inclusive: boolean;
  components: TaxComponent[];
  createdAt: string;
  retiredAt?: string;
}

/** One provider webhook as it was received — its status and the ids it named, never its body. */
export interface WebhookReceipt {
  id: string;
  provider: string;
  providerEventId: string;
  eventType: string;
  status: 'received' | 'processed' | 'ignored' | 'failed';
  attempts: number;
  /** Why it was ignored, or what went wrong. */
  note?: string;
  reference: Record<string, string>;
  receivedAt: string;
  processedAt?: string;
}

export interface WebhookQuery {
  status?: WebhookReceipt['status'] | 'all';
  page?: number;
  pageSize?: number;
}

export interface WebhookListResult {
  rows: WebhookReceipt[];
  total: number;
  page: number;
  pageSize: number;
}

/** An academy on the platform, as the billing screens list it. */
export interface BillingAcademy {
  id: string;
  name: string;
  slug: string;
  status: string;
}

/** One academy's billing, for the Super Admin: its subscription (live or latest), plan and billing profile. */
export interface AcademyBillingSummary {
  academy: { id: string; name: string };
  /** The live subscription, or the most recent one; null when the academy has never subscribed. */
  subscription: Subscription | null;
  plan: Plan | null;
  /** Where its invoices are addressed; null until it is set. */
  profile: BillingDetails | null;
}

/** What starting an academy's subscription takes: a trial, or an agreement billed outside the gateway. */
export interface StartSubscriptionInput {
  tenantId: string;
  planId: string;
  cycle: BillingCycle;
  start: 'trial' | 'active';
}

export interface SubscriptionOverview {
  kpis: {
    active: Kpi;
    trial: Kpi;
    pastDue: Kpi;
    canceling: Kpi;
    mrr: Kpi;
    arr: Kpi;
  };
  /** Month by month: who joined, who moved up, who moved down, who left. */
  growth: { label: string; detail: string; added: number; upgrades: number; downgrades: number; cancellations: number }[];
  /** Monthly recurring revenue, oldest → newest. */
  revenue: { label: string; detail: string; value: number }[];
  byPlan: { planId: string; planName: string; subscribers: number; mrr: number }[];
  statusCounts: Record<SubscriptionStatus, number>;
  /** Subscriptions whose trial or grace period ends soonest — the overview's watch list. */
  attention: SubscriptionRow[];
  currency: string;
  generatedAt: string;
}

export interface PaymentQuery {
  search?: string;
  status?: PaymentStatus | 'all';
  planId?: string;
  page?: number;
  pageSize?: number;
}

export interface PaymentListResult {
  rows: Invoice[];
  total: number;
  counts: Record<PaymentStatus | 'all', number>;
  /** Collected and outstanding across everything that matches, not just this page. */
  totals: { collected: number; outstanding: number; refunded: number; currency: string };
}

/* ─── Tenant Admin ───────────────────────────────────────────────────────── */

/** One limit of the academy's plan against what it uses now. `allowed` null is unlimited. */
export interface UsageLine {
  limit: LimitKey;
  label: string;
  used: number;
  allowed: number | null;
  remaining: number | null;
}

/**
 * A plan change the academy asked for that has not happened yet: an upgrade waiting for its payment
 * (D7, D8), or a downgrade waiting for the period to end (D10).
 */
export interface OpenPlanChange {
  id: string;
  direction: 'upgrade' | 'downgrade';
  status: 'pending_payment' | 'scheduled';
  toPlanId: string;
  toPlanName: string;
  toCycle: BillingCycle;
  /** Minor units: the unused value credited, and what is charged now — both 0 for a downgrade. */
  credit: number;
  charge: number;
  currency: string;
  /** A downgrade applies when the period ends; an upgrade when its payment is confirmed. */
  effectiveAt?: string;
  quotedAt: string;
}

/** A payment as the academy sees it: amount, outcome, and the masked method. */
export interface TenantPayment {
  id: string;
  invoiceNumber?: string;
  amount: number;
  currency: string;
  status: 'pending' | 'paid' | 'failed' | 'refunded' | 'partially_refunded';
  refunded: number;
  /** "Visa •••• 4242", "UPI" — never more. */
  method?: string;
  at: string;
  failureMessage?: string;
}

/** Everything the academy's billing page shows (§24). */
export interface TenantBilling {
  academy: { id: string; name: string };
  /** The live subscription, or the most recent one; null when the academy has never subscribed. */
  subscription: Subscription | null;
  /** The plan as the academy is served it: its own version's prices, features and limits. */
  plan: Plan | null;
  /** No plan is served: the academy keeps and edits what it has and cannot add to it until it renews (§21). */
  restricted: boolean;
  /**
   * Whether the platform enforces plans yet (`ENTITLEMENT_ENFORCEMENT`, §50). While it does not, nothing is
   * refused for a limit, a feature or a missing plan — the page says so rather than warn of a block.
   */
  enforced: boolean;
  openChange: OpenPlanChange | null;
  usage: UsageLine[];
  /** `enforcement` says how each is delivered: `planned` is sold but not built yet; `service` is a service level (SAAS-025). */
  features: { key: FeatureKey; label: string; included: boolean; enforcement: FeatureEnforcement }[];
  invoices: Invoice[];
  payments: TenantPayment[];
  /** The plans on sale that the academy could move to. */
  plans: Plan[];
  /** Whether online payment is connected. Until it is, an upgrade can be quoted but not paid. */
  checkoutAvailable: boolean;
  /**
   * Whether the academy may start a free trial itself now (`POST /tenant/billing/trial`): it has no live
   * subscription and has not had a trial. The onboarding offer for a new academy.
   */
  trialAvailable: boolean;
  /** The plan and cycle the owner chose while registering (SAAS-026) — offered first until a plan is chosen. */
  signupChoice?: { planId: string; cycle: BillingCycle } | null;
}

/** What opening a checkout answers with: the provider's checkout parameters, and the invoice being paid. */
export interface CheckoutStart {
  /**
   * Publishable only — never a secret. `provider` is the gateway the server chose for this payment; the
   * browser follows it and never picks one. `keyId` is the provider's publishable key, for a gateway whose
   * checkout opens in the page (Razorpay); `redirectUrl` is the hosted page of a gateway that takes the
   * payer away to pay.
   */
  checkout: { provider: string; keyId?: string; orderId: string; amount: number; currency: string; redirectUrl?: string };
  invoice: { id: string; number: string; total: number; currency: string };
}

/** What the server found when it read a finished checkout's payment back from the provider. */
export interface CheckoutOutcome {
  status: 'pending' | 'authorized' | 'paid' | 'failed' | 'refunded';
  settled: boolean;
  applied: boolean;
  message: string;
}

/** What the browser hands back when the provider's checkout completes. Proves nothing until the server checks it. */
export interface CheckoutCompletion {
  orderId: string;
  paymentId: string;
  signature: string;
}

/**
 * What a plan change would do, before it is asked for (`/tenant/subscription/preview`): its kind, when it
 * applies, the prorated credit and charge with tax, and the limits the academy already exceeds on the new
 * plan. Nothing is written.
 */
export interface PlanChangePreview {
  kind: PlanChangeKind;
  /** Charged and applied once paid, or applied when the period ends. */
  when: 'on_payment' | 'period_end';
  appliesAt: string;
  to: { planId: string; planName: string; cycle: BillingCycle; amount: number };
  currency: string;
  credit: number;
  charge: number;
  /** Credit that could not be used. */
  forfeited: number;
  /** The charge with tax at the academy's billing address; null with no address yet, or nothing to pay. */
  payable: { net: number; tax: number; gross: number } | null;
  /** An upgrade is taxed by the billing address: without one it cannot be priced or asked for. */
  needsBillingAddress: boolean;
  conflicts: { limit: LimitKey; usage: number; newLimit: number }[];
}

/** What asking for a plan change answers with: the change, and for an upgrade what is payable, tax included. */
export interface PlanChangeQuote {
  change: OpenPlanChange;
  payable?: { net: number; tax: number; gross: number; currency: string };
}

/* ─── The academy's billing details ───────────────────────────────────── */

/**
 * Where an academy's invoices are addressed (`/tenant/billing-profile`). A first purchase needs them: tax is worked
 * out from the country and region. The server validates them again and is the authority.
 */
export interface BillingDetails {
  legalName: string;
  email: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  /** A short region code, e.g. `KA` for Karnataka. */
  region?: string;
  postalCode: string;
  /** ISO 3166-1 alpha-2, e.g. `IN`. */
  country: string;
  taxRegistration?: string;
}

export type BillingDetailsField = keyof BillingDetails;

export const emptyBillingDetails = (): BillingDetails => ({ legalName: '', email: '', addressLine1: '', city: '', region: '', postalCode: '', country: 'IN' });

/** The same checks the server makes, so a form can say what is missing before it is sent. */
export function billingDetailsIssues(d: BillingDetails): { field: BillingDetailsField; message: string }[] {
  const issues: { field: BillingDetailsField; message: string }[] = [];
  const region = d.region?.trim();
  const tax = d.taxRegistration?.trim().replace(/\s+/g, '');
  if (d.legalName.trim().length < 2) issues.push({ field: 'legalName', message: 'Give the name the academy bills under.' });
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(d.email.trim())) issues.push({ field: 'email', message: 'Give an email address for invoices.' });
  if (d.addressLine1.trim().length < 3) issues.push({ field: 'addressLine1', message: 'Give the street address.' });
  if (d.city.trim().length < 2) issues.push({ field: 'city', message: 'Give the city.' });
  if (d.postalCode.trim().length < 2) issues.push({ field: 'postalCode', message: 'Give the postal code.' });
  if (!/^[A-Za-z]{2}$/.test(d.country.trim())) issues.push({ field: 'country', message: 'Choose the country by its two-letter code, e.g. IN.' });
  if (region && !/^[A-Za-z0-9-]{1,10}$/.test(region)) issues.push({ field: 'region', message: 'A region is a short code, e.g. KA.' });
  if (tax && !/^[A-Za-z0-9-]{3,32}$/.test(tax)) issues.push({ field: 'taxRegistration', message: 'A tax registration is 3–32 letters, digits or hyphens.' });
  return issues;
}
