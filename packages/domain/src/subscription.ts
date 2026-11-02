/**
 * Platform subscriptions: the plans an academy can be on, the subscriptions themselves, and the
 * billing record behind them.
 *
 * Nothing here enforces anything: a plan's limits and features are what it grants, and the gates
 * that read them belong to the entitlement service (SAAS-003) and usage enforcement (SAAS-011). Learner,
 * instructor and academy-admin access is decided by roles and permissions, and a subscription
 * state never changes it.
 *
 * Every amount in this module — prices, charges, invoice lines, recurring value — is an integer
 * count of the currency's minor unit (paise for INR). See `money.ts`.
 */

import type { ID, ISODateTime } from './catalog';
import { LIMIT_KEYS, LIMIT_LABEL, isFeatureKey, isLimitKey, type FeatureKey, type PlanLimits } from './entitlement';
import { currencyDigits, divideRounded, isCurrencyCode, isMinorAmount, minorPerMajor } from './money';
import { calculateTax } from './tax';

/* ─── Plans ─────────────────────────────────────────────────────────────── */

/** Draft is being written, active is offered, archived is kept for the subscriptions still on it. */
export type PlanStatus = 'draft' | 'active' | 'archived';

export type BillingCycle = 'monthly' | 'annual';

export const BILLING_CYCLES: readonly BillingCycle[] = ['monthly', 'annual'];

/*
 * A plan's features and limits come from the entitlement catalogue (`entitlement.ts`): `features` is
 * the set of `FeatureKey`s the plan grants, `limits` a `PlanLimits` with `null` for "no ceiling".
 */

export interface Plan {
  id: ID;
  name: string;
  /** One line on what the plan is for, shown under its name. */
  description: string;
  /** The code billing systems would key on — uppercase letters, digits and hyphens. */
  code: string;
  /** In the currency's minor unit — 399900 is ₹3,999. */
  monthlyPrice: number;
  /** In the currency's minor unit. */
  annualPrice: number;
  /** ISO 4217, e.g. "INR". Prototype data is priced in one currency. */
  currency: string;
  /** Which cycles may be bought. A plan must offer at least one. */
  cycles: BillingCycle[];
  trialEnabled: boolean;
  /** Days of trial when `trialEnabled`; ignored otherwise. */
  trialDays: number;
  /** One value per catalogue limit; `null` is unlimited. Storage is in bytes. */
  limits: PlanLimits;
  /** The catalogue features this plan grants. */
  features: FeatureKey[];
  status: PlanStatus;
  /** Display order in the plans list and the change-plan picker. */
  order: number;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export type PlanInput = Omit<Plan, 'id' | 'createdAt' | 'updatedAt'>;

/**
 * The statuses a plan can be saved as from where it stands (`null`: not created yet). A new plan or a
 * draft is kept as a draft or published; an active plan stays on sale or is archived; an archived plan
 * stays archived or is restored. A plan that has been offered never goes back to draft — the API refuses
 * it, so the editor never offers it.
 */
export function reachablePlanStatuses(from: PlanStatus | null): PlanStatus[] {
  if (from === 'active') return ['active', 'archived'];
  if (from === 'archived') return ['archived', 'active'];
  return ['draft', 'active'];
}

/**
 * Who a plan is and what it costs. `validatePlanAllowance` checks the rest — its limits and features.
 */
export type PlanTermsInput = Pick<
  PlanInput,
  'name' | 'description' | 'code' | 'monthlyPrice' | 'annualPrice' | 'currency' | 'cycles' | 'trialEnabled' | 'trialDays'
>;

export interface PlanIssue {
  field: 'name' | 'description' | 'code' | 'monthlyPrice' | 'annualPrice' | 'currency' | 'cycles' | 'trialDays' | 'limits' | 'features';
  message: string;
}

const CODE_PATTERN = /^[A-Z0-9][A-Z0-9-]{1,23}$/;

/** The highest price a plan may carry, in major units: 1,00,00,000 of the currency. */
const MAX_PRICE_MAJOR = 10_000_000;

/** A plan code as it is stored and compared: trimmed and in capitals. */
export const normalisePlanCode = (code: string): string => code.trim().toUpperCase();

/** A plan priced per year should not cost more than paying month by month. */
export const annualSavingPercent = (plan: Pick<Plan, 'monthlyPrice' | 'annualPrice'>): number =>
  plan.monthlyPrice <= 0 ? 0 : Math.max(0, Math.round((1 - plan.annualPrice / (plan.monthlyPrice * 12)) * 100));

/**
 * What a saveable plan needs. `takenCodes` are the codes already in use by *other* plans, so the
 * editor can refuse a duplicate before it is sent.
 */
export function validatePlan(input: PlanInput, takenCodes: readonly string[] = []): PlanIssue[] {
  return [...validatePlanTerms(input, takenCodes), ...validatePlanAllowance(input)];
}

/**
 * The name, code and commercial terms of a plan. The API runs exactly this on every plan it saves, so
 * the editor and the server can never disagree about what a valid price is. A price must be a whole
 * number of the currency's minor unit.
 */
export function validatePlanTerms(input: PlanTermsInput, takenCodes: readonly string[] = []): PlanIssue[] {
  const issues: PlanIssue[] = [];
  if (input.name.trim().length < 3) issues.push({ field: 'name', message: 'Give the plan a name of at least 3 characters.' });
  if (input.description.trim().length < 10) issues.push({ field: 'description', message: 'Describe the plan in a sentence — at least 10 characters.' });

  const code = normalisePlanCode(input.code);
  if (!CODE_PATTERN.test(code)) {
    issues.push({ field: 'code', message: 'The plan code is 2–24 characters: capitals, digits and hyphens, starting with a letter or digit.' });
  } else if (takenCodes.some((c) => normalisePlanCode(c) === code)) {
    issues.push({ field: 'code', message: `The code ${code} already belongs to another plan.` });
  }

  const currencyKnown = isCurrencyCode(input.currency);
  if (!currencyKnown) issues.push({ field: 'currency', message: 'Choose a currency by its three-letter code, e.g. INR.' });

  const cycles = input.cycles ?? [];
  if (cycles.length === 0) issues.push({ field: 'cycles', message: 'Offer at least one billing cycle.' });

  for (const [field, price, cycle] of [
    ['monthlyPrice', input.monthlyPrice, 'monthly'],
    ['annualPrice', input.annualPrice, 'annual'],
  ] as const) {
    if (!cycles.includes(cycle)) continue;
    if (!isMinorAmount(price) || price < 0) {
      issues.push({
        field,
        message: currencyKnown ? `Enter a price above zero, to at most ${currencyDigits(input.currency)} decimal places.` : 'Enter a price above zero.',
      });
    } else if (price === 0) {
      // A cycle on sale is paid through the gateway, which cannot charge nothing. Free access is a Super
      // Admin trial or a complimentary period, never a ₹0 price.
      issues.push({ field, message: `Enter a price above zero for the ${cycle} cycle, or stop offering it.` });
    } else if (currencyKnown && price > MAX_PRICE_MAJOR * minorPerMajor(input.currency)) {
      issues.push({ field, message: 'That price looks wrong — keep it under 1,00,00,000.' });
    }
  }
  if (cycles.includes('monthly') && cycles.includes('annual') && input.monthlyPrice > 0 && input.annualPrice > input.monthlyPrice * 12) {
    issues.push({ field: 'annualPrice', message: 'A year costs more than twelve months at the monthly price. Lower it, or drop the annual cycle.' });
  }

  if (input.trialEnabled && !(Number.isInteger(input.trialDays) && input.trialDays >= 1 && input.trialDays <= 90)) {
    issues.push({ field: 'trialDays', message: 'A trial runs between 1 and 90 days.' });
  }
  return issues;
}

/**
 * What a plan allows: a value for every catalogue limit — a whole number of at least 1, or `null` for
 * unlimited — and at least one catalogue feature, none twice.
 */
export function validatePlanAllowance(input: Pick<PlanInput, 'limits' | 'features'>): PlanIssue[] {
  const issues: PlanIssue[] = [];
  const limits = (input.limits ?? {}) as Partial<Record<string, unknown>>;
  for (const key of LIMIT_KEYS) {
    const value = limits[key];
    if (value === null) continue;
    if (value === undefined) {
      issues.push({ field: 'limits', message: `Set ${LIMIT_LABEL[key].toLowerCase()} to a number, or to unlimited.` });
      break;
    }
    if (typeof value !== 'number' || !Number.isSafeInteger(value) || value < 1) {
      issues.push({ field: 'limits', message: `${LIMIT_LABEL[key]} must be a whole number of at least 1, or left unlimited.` });
      break;
    }
  }
  const unknownLimit = Object.keys(limits).find((key) => !isLimitKey(key));
  if (unknownLimit) issues.push({ field: 'limits', message: `${unknownLimit} is not a limit a plan can set.` });

  const features = input.features ?? [];
  if (features.length === 0) issues.push({ field: 'features', message: 'Turn on at least one feature.' });
  const unknownFeature = features.find((key) => !isFeatureKey(key));
  if (unknownFeature) issues.push({ field: 'features', message: `${unknownFeature} is not a feature a plan can grant.` });
  else if (new Set(features).size !== features.length) issues.push({ field: 'features', message: 'A feature is listed twice.' });
  return issues;
}

/* ─── Subscriptions ─────────────────────────────────────────────────────── */

/**
 * Where a subscription stands.
 *
 * trial — inside a free trial · active — paying and current · past-due — a payment failed and
 * retries are running · canceling — cancelled but paid to the end of the period · canceled —
 * over · paused — suspended with a resume date · expired — a trial or term ran out unpaid.
 */
export type SubscriptionStatus = 'trial' | 'active' | 'past-due' | 'canceling' | 'canceled' | 'paused' | 'expired';

export const SUBSCRIPTION_STATUSES: readonly SubscriptionStatus[] = ['trial', 'active', 'past-due', 'canceling', 'canceled', 'paused', 'expired'];

/** How an invoice stands. `void`: withdrawn by the platform before it was paid, kept as history. */
export type PaymentStatus = 'paid' | 'pending' | 'failed' | 'refunded' | 'void';

export const PAYMENT_STATUSES: readonly PaymentStatus[] = ['paid', 'pending', 'failed', 'refunded', 'void'];

/** The customer on a subscription — one academy on the platform. */
export interface SubscriptionCustomer {
  id: ID;
  /** The academy's name, as it bills. */
  name: string;
  email: string;
  /** City and country, for the billing address block. */
  city: string;
  country: string;
  /** Learners the academy currently has — shown against the plan's ceiling. */
  learners: number;
}

/** A card or mandate, only ever as much of it as is safe to print. */
export interface PaymentMethod {
  kind: 'card' | 'upi' | 'netbanking' | 'mandate' | 'invoice';
  /** "Visa", "HDFC Bank", "UPI" — the brand shown beside the masked identifier. */
  brand: string;
  /** Last four digits, or a masked handle. Never a full number. */
  last4?: string;
  expiry?: string;
}

export interface Subscription {
  id: ID;
  customer: SubscriptionCustomer;
  planId: ID;
  status: SubscriptionStatus;
  cycle: BillingCycle;
  /** What this subscription is charged each cycle, in the currency's minor unit. */
  amount: number;
  currency: string;
  startedAt: ISODateTime;
  /** When the current period ends — the renewal date, or the last day of a cancelling subscription. */
  renewsAt: ISODateTime;
  trialStartedAt?: ISODateTime;
  trialEndsAt?: ISODateTime;
  canceledAt?: ISODateTime;
  cancelReason?: string;
  /** Whether cancellation takes effect now or when the period ends. */
  cancelAt?: 'immediately' | 'period-end';
  pausedAt?: ISODateTime;
  resumesAt?: ISODateTime;
  paymentMethod: PaymentMethod;
  lastPaymentAt?: ISODateTime;
  lastPaymentStatus?: PaymentStatus;
  /** Past-due only: what is owed (minor units) and when the next retry runs. */
  amountDue?: number;
  nextRetryAt?: ISODateTime;
  /** Past-due only: when access closes if nothing is paid. */
  graceEndsAt?: ISODateTime;
  retriesUsed?: number;
  notes?: string;
}

export type SubscriptionEventKind =
  | 'created'
  | 'trial-started'
  | 'trial-converted'
  | 'plan-changed'
  | 'payment-received'
  | 'payment-failed'
  | 'cancellation-requested'
  | 'cancellation-completed'
  | 'paused'
  | 'resumed'
  | 'reactivated'
  | 'extended';

export interface SubscriptionEvent {
  id: ID;
  subscriptionId: ID;
  kind: SubscriptionEventKind;
  at: ISODateTime;
  /** One line describing what happened, written for a human reading the history. */
  summary: string;
  /** Who or what did it: "Platform admin", "Billing", "Customer". */
  actor: string;
}

/* ─── Billing ───────────────────────────────────────────────────────────── */

export interface InvoiceLine {
  description: string;
  quantity: number;
  /** In the currency's minor unit. */
  unitAmount: number;
}

export interface Invoice {
  id: ID;
  /** Human-facing number, e.g. "INV-2026-0148". */
  number: string;
  subscriptionId: ID;
  customerId: ID;
  customerName: string;
  planName: string;
  cycle: BillingCycle;
  issuedAt: ISODateTime;
  /** The service window this invoice covers. */
  periodStart: ISODateTime;
  periodEnd: ISODateTime;
  lines: InvoiceLine[];
  /** Per cent of the subtotal, e.g. 18 for GST. */
  taxPercent: number;
  currency: string;
  status: PaymentStatus;
  paidAt?: ISODateTime;
  method: PaymentMethod;
  /** Why a payment failed or was refunded — shown in place of a paid date. */
  note?: string;
  billingAddress: string[];
  /**
   * The figures the server fixed when it issued the invoice, in minor units. Present on every invoice the
   * billing API serves: a screen shows these and never recalculates them (tax may be inclusive, and
   * several components each round). Absent only on the demo's invented invoices, which are computed.
   */
  amounts?: { subtotal: number; tax: number; total: number };
}

type InvoiceFigures = Pick<Invoice, 'lines' | 'taxPercent'> & Partial<Pick<Invoice, 'amounts'>>;

export const invoiceSubtotal = (invoice: Pick<Invoice, 'lines'> & Partial<Pick<Invoice, 'amounts'>>): number =>
  invoice.amounts?.subtotal ?? invoice.lines.reduce((sum, line) => sum + line.quantity * line.unitAmount, 0);

/** The tax on an invoice: the server's figure, or for a demo invoice its percentage as basis points, in integers (`tax.ts`). */
export const invoiceTax = (invoice: InvoiceFigures): number =>
  invoice.amounts?.tax ?? calculateTax(invoiceSubtotal(invoice), 'INR', [{ code: 'TAX', label: 'Tax', rateBps: Math.round(invoice.taxPercent * 100) }]).tax;

export const invoiceTotal = (invoice: InvoiceFigures): number => invoice.amounts?.total ?? invoiceSubtotal(invoice) + invoiceTax(invoice);

/* ─── Derived figures ───────────────────────────────────────────────────── */

/** A subscription that is being billed right now: trials and dead subscriptions contribute nothing. */
export const isBilling = (status: SubscriptionStatus): boolean => status === 'active' || status === 'past-due' || status === 'canceling';

/** What a subscription contributes each month. An annual subscription is spread over twelve. */
export const monthlyValue = (s: Pick<Subscription, 'amount' | 'cycle' | 'status'>): number =>
  !isBilling(s.status) ? 0 : s.cycle === 'annual' ? divideRounded(s.amount, 12) : s.amount;

/** Whole days from `now` until `iso`, never below zero — "4 days left", "0 days left" on the last day. */
export function daysUntil(iso: ISODateTime | undefined, now: Date): number {
  if (!iso) return 0;
  const ms = new Date(iso).getTime() - now.getTime();
  return Math.max(0, Math.ceil(ms / 86_400_000));
}

export interface PlanChangeEffect {
  /** What the subscription pays now, per its current cycle. */
  currentAmount: number;
  /** What it would pay on the new plan and cycle. */
  newAmount: number;
  /** newAmount − currentAmount: positive is an upgrade, negative a downgrade. */
  difference: number;
  direction: 'upgrade' | 'downgrade' | 'same';
}

/** What changing plan costs. Both sides are quoted on the cycle being moved to, so they compare. */
export function planChangeEffect(current: number, plan: Plan, cycle: BillingCycle): PlanChangeEffect {
  const newAmount = cycle === 'annual' ? plan.annualPrice : plan.monthlyPrice;
  const difference = newAmount - current;
  return {
    currentAmount: current,
    newAmount,
    difference,
    direction: difference > 0 ? 'upgrade' : difference < 0 ? 'downgrade' : 'same',
  };
}
