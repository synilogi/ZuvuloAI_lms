import { describe, expect, it } from 'vitest';
import { hasReceipt, receiptFigures } from './receipt';

describe('receiptFigures', () => {
  it('reads the list price in whole rupees and every other amount in paise', () => {
    expect(receiptFigures({ listPrice: 1499, amount: 149_900 })).toEqual({ listPrice: 149_900, saleSaving: 0, couponSaving: 0, paid: 149_900 });
  });

  it('separates a coupon from a sale price', () => {
    // List ₹2,000, on sale at ₹1,500, ₹100 coupon: ₹1,400 charged.
    expect(receiptFigures({ listPrice: 2000, amount: 140_000, discountAmount: 10_000 })).toEqual({
      listPrice: 200_000,
      saleSaving: 50_000,
      couponSaving: 10_000,
      paid: 140_000,
    });
  });

  it('adds up to what was paid', () => {
    const f = receiptFigures({ listPrice: 999, amount: 79_950, discountAmount: 9_950 });
    expect(f.listPrice - f.saleSaving - f.couponSaving).toBe(f.paid);
  });

  it('never shows a negative saving', () => {
    expect(receiptFigures({ listPrice: 100, amount: 20_000 }).saleSaving).toBe(0);
  });
});

describe('hasReceipt', () => {
  it('is for a paid order only; a refunded one stays paid', () => {
    expect(hasReceipt({ status: 'paid' })).toBe(true);
    for (const status of ['created', 'failed', 'expired'] as const) expect(hasReceipt({ status })).toBe(false);
  });
});
