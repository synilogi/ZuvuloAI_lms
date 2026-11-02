import { describe, expect, it } from 'vitest';
import { NOT_OPEN, PURCHASE_STATUS, priceSortKey, pricingSummary, purchaseAmount, saleDisplay } from './coursePricing';

/* A course's price reads one way everywhere: free never shows a price, and a price nobody chose is never "free". */

const inr = (amount: number) => ({ amount, currency: 'INR' as const });

describe('how a course’s price reads', () => {
  it('shows Free for a free course, even one that still carries an old price', () => {
    expect(saleDisplay({ pricing: 'free' })).toEqual({ kind: 'free', label: 'Free' });
    expect(saleDisplay({ pricing: 'free', price: inr(2999) }).label).toBe('Free');
    // A record from before pricing existed, with no price, was free.
    expect(saleDisplay({}).kind).toBe('free');
  });

  it('shows a paid course’s own price in whole rupees', () => {
    expect(saleDisplay({ pricing: 'paid', price: inr(1499) })).toEqual({ kind: 'paid', label: '₹1,499', amount: 1499 });
    expect(saleDisplay({ pricing: 'paid', price: inr(500000) }).label).toBe('₹5,00,000');
  });

  it('never shows an undecided or broken price as free', () => {
    expect(saleDisplay({ pricing: 'unset', price: inr(2999) })).toEqual({ kind: 'unavailable', label: NOT_OPEN });
    // From before pricing existed, with the academy default price on it: undecided.
    expect(saleDisplay({ price: inr(2999) }).kind).toBe('unavailable');
    expect(saleDisplay({ pricing: 'paid' }).kind).toBe('unavailable');
    expect(saleDisplay({ pricing: 'paid', price: inr(0) }).kind).toBe('unavailable');
    expect(saleDisplay({ pricing: 'paid', price: inr(14.5) }).kind).toBe('unavailable');
  });

  it('sorts free first, then by price, with courses nobody can join last', () => {
    const keys = [{ pricing: 'unset' as const }, { pricing: 'paid' as const, price: inr(900) }, { pricing: 'free' as const }].map(priceSortKey);
    expect(keys).toEqual([Number.POSITIVE_INFINITY, 900, 0]);
  });

  it('tells the admin what was chosen, and flags a course with no choice', () => {
    expect(pricingSummary({ pricing: 'free' })).toEqual({ label: 'Free', unset: false });
    expect(pricingSummary({ pricing: 'paid', price: inr(1499) })).toEqual({ label: 'Paid · ₹1,499', unset: false });
    expect(pricingSummary({ pricing: 'unset' })).toEqual({ label: 'Not chosen', unset: true });
  });

  it('shows a purchase’s amount (paise) as rupees, and every status by name', () => {
    expect(purchaseAmount({ amount: 149900, currency: 'INR' })).toBe('₹1,499');
    expect(Object.keys(PURCHASE_STATUS).sort()).toEqual(['created', 'expired', 'failed', 'paid']);
  });
});
