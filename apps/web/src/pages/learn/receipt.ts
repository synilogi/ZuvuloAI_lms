import type { CoursePurchase } from '@syniastrolms/domain';

/** A receipt exists for an order the gateway took money for, whatever happened afterwards. */
export const hasReceipt = (p: Pick<CoursePurchase, 'status'>) => p.status === 'paid';

export interface ReceiptFigures {
  /** Paise. `listPrice` is held in whole rupees, unlike every other amount on an order. */
  listPrice: number;
  /** What a course's sale price took off the list price, in paise. */
  saleSaving: number;
  /** What a coupon took off, in paise. */
  couponSaving: number;
  paid: number;
}

/**
 * The lines of a receipt, in paise. The coupon comes off the sale price, so what is left between the list price and the
 * amount charged is the sale saving. Never negative: a course's price can only have been at or below the list price.
 */
export function receiptFigures(p: Pick<CoursePurchase, 'listPrice' | 'discountAmount' | 'amount'>): ReceiptFigures {
  const listPrice = p.listPrice * 100;
  const couponSaving = p.discountAmount ?? 0;
  return { listPrice, saleSaving: Math.max(0, listPrice - couponSaving - p.amount), couponSaving, paid: p.amount };
}
