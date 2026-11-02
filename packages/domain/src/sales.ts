/*
 * Course sales arithmetic and shapes (docs/16 §2.4), shared by the API and the web app. Money is integer paise throughout.
 *
 * Decisions (docs/16, D-PLAT-08 and D-PLAT-12):
 *   - a percentage is in basis points and rounds half up, to the paisa;
 *   - a coupon never takes an order below MIN_CHARGE: an order that charges nothing has no gateway payment to verify, and a
 *     free course is what `pricing: 'free'` is for;
 *   - a refund is of the whole order. A partial refund would need a rule for how much CV to take back, and the plan names none.
 */

/** The smallest charge an order may come to, in paise (₹1). */
export const MIN_CHARGE = 100;

export const COUPON_KINDS = ['percent', 'fixed'] as const;
export type CouponKind = (typeof COUPON_KINDS)[number];

export const COUPON_STATUSES = ['active', 'disabled'] as const;
export type CouponStatus = (typeof COUPON_STATUSES)[number];

export type CouponTerms = { kind: 'percent'; percentBps: number } | { kind: 'fixed'; amountOff: number };

/** What a coupon takes off a charge, in paise: never so much that less than `MIN_CHARGE` is left. Integers only. */
export function couponDiscount(charge: number, terms: CouponTerms): number {
  if (charge <= MIN_CHARGE) return 0;
  const wanted = terms.kind === 'percent' ? Math.floor((charge * terms.percentBps + 5000) / 10000) : terms.amountOff;
  return Math.max(0, Math.min(wanted, charge - MIN_CHARGE));
}

/** A coupon code as it is stored and compared: trimmed, upper case. */
export const normaliseCouponCode = (code: string) => code.trim().toUpperCase();

export const isCouponCode = (code: string) => /^[A-Z0-9][A-Z0-9_-]{2,31}$/.test(code);

export interface Coupon {
  id: string;
  code: string;
  description: string;
  kind: CouponKind;
  /** Basis points, for a percentage coupon: 1000 is 10%. */
  percentBps?: number;
  /** Paise, for a fixed coupon. */
  amountOff?: number;
  startsAt?: string;
  endsAt?: string;
  /** Null when there is no ceiling. */
  maxUses: number | null;
  perLearnerLimit: number;
  /** The one course it applies to; absent for every paid course. */
  course?: { id: string; title: string };
  status: CouponStatus;
  usedCount: number;
  createdAt: string;
}

export interface CouponInput {
  code: string;
  description?: string;
  kind: CouponKind;
  percentBps?: number;
  amountOff?: number;
  startsAt?: string | null;
  endsAt?: string | null;
  maxUses?: number | null;
  perLearnerLimit?: number;
  courseId?: string | null;
}

/** What may change on a coupon once it exists: its code and discount are fixed. */
export interface CouponUpdate {
  description?: string;
  startsAt?: string | null;
  endsAt?: string | null;
  maxUses?: number | null;
  perLearnerLimit?: number;
  status?: CouponStatus;
}

/** What a learner would pay, from the server, before any order exists. Paise, except `listPrice` in whole rupees. */
export interface CourseQuote {
  listPrice: number;
  /** The charge before a coupon: the sale price where there is one. */
  charge: number;
  discount: number;
  total: number;
  couponCode?: string;
}

export const REFUND_STATUSES = ['requested', 'pending', 'succeeded', 'failed'] as const;
export type RefundStatus = (typeof REFUND_STATUSES)[number];

export interface OrderRefund {
  id: string;
  amount: number;
  reason: string;
  note?: string;
  status: RefundStatus;
  failureMessage?: string;
  createdAt: string;
  settledAt?: string;
}

export type SalesOrderStatus = 'created' | 'paid' | 'failed' | 'expired' | 'refunded';

export interface SalesOrderRow {
  id: string;
  orderNumber: string;
  learner: { name: string; email: string };
  course: { id: string; title: string };
  status: SalesOrderStatus;
  amount: number;
  discountAmount: number;
  couponCode?: string;
  /** Whole rupees. */
  listPrice: number;
  currency: string;
  provider: string;
  environment: string;
  providerOrderId: string;
  providerPaymentId?: string;
  /** Money taken that opened nothing, to be looked at. */
  reviewReason?: string;
  createdAt: string;
  paidAt?: string;
  refundedAt?: string;
}

export interface SalesOrderDetail extends SalesOrderRow {
  refunds: OrderRefund[];
  /** What the affiliate program did with this sale, when it was an eligible course. */
  affiliateOrder?: { id: string; status: string };
  canRefund: boolean;
}

export interface SalesOrderQuery {
  status?: SalesOrderStatus;
  search?: string;
  page?: number;
  pageSize?: number;
}

export interface SalesOrderList {
  rows: SalesOrderRow[];
  total: number;
  page: number;
  pageSize: number;
  counts: Record<SalesOrderStatus | 'all', number>;
  /** Paise brought in by paid orders that were not refunded. */
  revenue: number;
}

export interface PaymentEventRow {
  id: string;
  provider: string;
  eventId: string;
  eventType: string;
  processed: boolean;
  receivedAt: string;
}

/** One course's enrolments and orders, for the people who teach it (docs/16, D-PLAT-10). Counts, never money. */
export interface CourseSalesRow {
  courseId: string;
  title: string;
  pricing: 'free' | 'paid';
  enrolled: number;
  paidOrders: number;
  refundedOrders: number;
}
