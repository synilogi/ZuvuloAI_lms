import { describe, expect, it } from 'vitest';
import { BYTES_PER_GB, type Plan } from '@syniastrolms/domain';
import { cyclePer, headlinePrice, limitText, methodText, money, moneyCompact, rangeSummary } from './subscriptionMeta';

const plan = (over: Partial<Plan> = {}): Plan =>
  ({
    id: 'growth',
    name: 'Growth',
    monthlyPrice: 399900,
    annualPrice: 3999000,
    currency: 'INR',
    cycles: ['monthly', 'annual'],
    ...over,
  }) as Plan;

describe('money', () => {
  it('reads paise and writes rupees in the Indian grouping', () => {
    expect(money(24999000)).toBe('₹2,49,990');
    expect(money(0)).toBe('₹0');
  });

  it('shows the paise when there are any, rather than rounding them away', () => {
    expect(money(399950)).toBe('₹3,999.50');
  });

  it('honours another currency without hard-coding a symbol', () => {
    expect(money(120000, 'USD')).toContain('1,200');
  });

  it('compacts large figures for axes and headlines', () => {
    expect(moneyCompact(180_000_000)).toBe('₹18L');
  });
});

describe('plan pricing', () => {
  it('leads with the monthly price where one is offered', () => {
    expect(headlinePrice(plan())).toEqual({ amount: 399900, cycle: 'monthly' });
  });

  it('falls back to the annual price on a plan sold by the year only', () => {
    expect(headlinePrice(plan({ cycles: ['annual'] }))).toEqual({ amount: 3999000, cycle: 'annual' });
  });

  it('reads a cycle as the tail of a price', () => {
    expect(cyclePer('monthly')).toBe('a month');
    expect(cyclePer('annual')).toBe('a year');
  });
});

describe('limitText', () => {
  it('says Unlimited rather than showing nothing or a zero', () => {
    expect(limitText('learners.max', null)).toBe('Unlimited');
    expect(limitText('storage.bytes', null)).toBe('Unlimited');
  });

  it('reads storage in bytes and writes it in the unit that reads best', () => {
    expect(limitText('storage.bytes', 150 * BYTES_PER_GB)).toBe('150 GB');
    expect(limitText('storage.bytes', 2000 * BYTES_PER_GB)).toBe('2 TB');
    expect(limitText('storage.bytes', 2500 * BYTES_PER_GB)).toBe('2.5 TB');
  });

  it('groups counts the Indian way', () => {
    expect(limitText('learners.max', 250000)).toBe('2,50,000');
  });
});

describe('methodText', () => {
  it('never shows more than a brand and four digits', () => {
    expect(methodText({ kind: 'card', brand: 'Visa', last4: '4242' })).toBe('Visa •••• 4242');
    expect(methodText({ kind: 'netbanking', brand: 'HDFC Bank', last4: '9981' })).toBe('HDFC Bank •••• 9981');
  });

  it('shows a mandate or an invoice arrangement without inventing digits', () => {
    expect(methodText({ kind: 'upi', brand: 'UPI autopay' })).toBe('UPI autopay');
    expect(methodText({ kind: 'invoice', brand: 'Bank transfer' })).toBe('Bank transfer · invoiced');
  });
});

describe('rangeSummary', () => {
  it('describes the window the pager is showing', () => {
    expect(rangeSummary(148, 1, 20, 'payments')).toBe('1–20 of 148');
    expect(rangeSummary(148, 8, 20, 'payments')).toBe('141–148 of 148');
  });

  it('says what is missing rather than showing 0–0 of 0', () => {
    expect(rangeSummary(0, 1, 20, 'payments')).toBe('No payments');
  });
});
