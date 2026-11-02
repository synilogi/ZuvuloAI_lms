import { describe, expect, it } from 'vitest';
import { MAX_PAUSE_DAYS, classifyPlanChange, isImmediate, pauseEnd, pauseExtensionMs, prorate, quoteImmediateChange } from './planChange';

const DAY = 86_400_000;
const sep1 = new Date('2026-09-01T00:00:00Z');
const oct1 = new Date('2026-10-01T00:00:00Z'); // a 30-day period

describe('prorate — integer paise, rounded half up', () => {
  it('splits exactly when it can', () => {
    expect(prorate(399900, 15, 30)).toBe(199950);
    expect(prorate(899900, 15, 30)).toBe(449950);
    expect(prorate(100, 0, 30)).toBe(0);
    expect(prorate(100, 30, 30)).toBe(100);
  });

  it('rounds a half paisa up and anything less down', () => {
    expect(prorate(1, 1, 2)).toBe(1); // 0.5 → 1
    expect(prorate(1, 1, 3)).toBe(0); // 0.33 → 0
    expect(prorate(2, 1, 3)).toBe(1); // 0.67 → 1
    expect(prorate(399900, 1, 3)).toBe(133300);
    expect(prorate(399901, 1, 2)).toBe(199951); // 199950.5 → 199951
  });

  it('stays exact where a float would drift: large amounts over millisecond periods', () => {
    const annual = 24_999_000; // ₹2,49,990
    const year = 365 * DAY;
    const third = Math.floor(year / 3);
    expect(prorate(annual, third, year)).toBe(8_333_000);
    expect(Number.isInteger(prorate(annual, 12_345_678_901, year))).toBe(true);
    // The float product here is 1e17-scale; the BigInt path still answers exactly.
    expect(prorate(9_007_199_254_740_991, 1, 3)).toBe(3_002_399_751_580_330);
  });

  it('never goes negative or past the whole amount, and refuses nonsense', () => {
    expect(prorate(1000, -5, 10)).toBe(0);
    expect(prorate(1000, 50, 10)).toBe(1000);
    expect(() => prorate(10.5, 1, 2)).toThrow();
    expect(() => prorate(-1, 1, 2)).toThrow();
    expect(() => prorate(10, 1, 0)).toThrow();
  });
});

describe('classifying a change (docs/06 table)', () => {
  const cur = { planVersionId: 'v1', cycle: 'monthly' as const, amount: 399900 };
  it('calls a dearer plan on the same cycle an upgrade, and monthly → annual a cycle upgrade', () => {
    expect(classifyPlanChange(cur, { planVersionId: 'v2', cycle: 'monthly', amount: 899900 })).toBe('upgrade');
    expect(classifyPlanChange(cur, { planVersionId: 'v1', cycle: 'annual', amount: 3999000 })).toBe('cycle_upgrade');
    expect(classifyPlanChange(cur, { planVersionId: 'v2', cycle: 'annual', amount: 100 })).toBe('cycle_upgrade');
  });

  it('defers a cheaper plan, annual → monthly and a same-price switch to the boundary', () => {
    expect(classifyPlanChange(cur, { planVersionId: 'v2', cycle: 'monthly', amount: 149900 })).toBe('downgrade');
    expect(classifyPlanChange({ ...cur, cycle: 'annual', amount: 3999000 }, { planVersionId: 'v2', cycle: 'monthly', amount: 899900 })).toBe('downgrade');
    expect(classifyPlanChange(cur, { planVersionId: 'v2', cycle: 'monthly', amount: 399900 })).toBe('scheduled_change');
  });

  it('finds nothing to change on the same version and cycle', () => {
    expect(classifyPlanChange(cur, { ...cur })).toBeNull();
  });

  it('charges now only for the two upgrade kinds', () => {
    expect([isImmediate('upgrade'), isImmediate('cycle_upgrade'), isImmediate('downgrade'), isImmediate('scheduled_change')]).toEqual([
      true,
      true,
      false,
      false,
    ]);
  });
});

describe('quoting an immediate change (D7, D8)', () => {
  it('charges only the difference for the rest of the period: ₹3,999 → ₹8,999 halfway is ₹2,500', () => {
    const q = quoteImmediateChange({
      kind: 'upgrade',
      currentAmount: 399900,
      newAmount: 899900,
      periodStart: sep1,
      periodEnd: oct1,
      at: new Date('2026-09-16T00:00:00Z'),
    });
    expect(q).toMatchObject({ credit: 199950, newValue: 449950, charge: 250000, forfeited: 0 });
  });

  it('charges almost the full difference at the start and almost nothing at the end', () => {
    const early = quoteImmediateChange({
      kind: 'upgrade',
      currentAmount: 399900,
      newAmount: 899900,
      periodStart: sep1,
      periodEnd: oct1,
      at: new Date(sep1.getTime() + 1000),
    });
    expect(early.charge).toBeGreaterThan(499990);
    const late = quoteImmediateChange({
      kind: 'upgrade',
      currentAmount: 399900,
      newAmount: 899900,
      periodStart: sep1,
      periodEnd: oct1,
      at: new Date(oct1.getTime() - 1000),
    });
    expect(late.charge).toBeLessThanOrEqual(2);
    expect(late.charge).toBeGreaterThanOrEqual(0);
  });

  it('credits the unused month against the annual price (monthly → annual)', () => {
    const q = quoteImmediateChange({
      kind: 'cycle_upgrade',
      currentAmount: 399900,
      newAmount: 3999000,
      periodStart: sep1,
      periodEnd: oct1,
      at: new Date('2026-09-16T00:00:00Z'),
    });
    expect(q).toMatchObject({ credit: 199950, newValue: 3999000, charge: 3799050, forfeited: 0 });
  });

  it('never charges below zero, and records credit it could not use', () => {
    const q = quoteImmediateChange({ kind: 'cycle_upgrade', currentAmount: 900000, newAmount: 100000, periodStart: sep1, periodEnd: oct1, at: sep1 });
    expect(q).toMatchObject({ credit: 900000, charge: 0, forfeited: 800000 });
  });

  it('refuses a period that has ended or has no length', () => {
    expect(() => quoteImmediateChange({ kind: 'upgrade', currentAmount: 1, newAmount: 2, periodStart: sep1, periodEnd: oct1, at: oct1 })).toThrow(/ended/);
    expect(() => quoteImmediateChange({ kind: 'upgrade', currentAmount: 1, newAmount: 2, periodStart: oct1, periodEnd: oct1, at: sep1 })).toThrow(/no length/);
  });

  it('keeps every figure a whole number of paise', () => {
    for (const hours of [1, 7, 13, 250, 719]) {
      const q = quoteImmediateChange({
        kind: 'upgrade',
        currentAmount: 149900,
        newAmount: 399901,
        periodStart: sep1,
        periodEnd: oct1,
        at: new Date(sep1.getTime() + hours * 3_600_000),
      });
      for (const figure of [q.credit, q.newValue, q.charge]) expect(Number.isSafeInteger(figure)).toBe(true);
      expect(q.charge).toBe(q.newValue - q.credit);
    }
  });
});

describe('pauses (D9)', () => {
  it('ends a pause 1–30 whole days after it starts, and refuses anything else', () => {
    expect(pauseEnd(sep1, 30).toISOString()).toBe('2026-10-01T00:00:00.000Z');
    expect(pauseEnd(sep1, 1).toISOString()).toBe('2026-09-02T00:00:00.000Z');
    for (const days of [0, 31, 2.5, -1, Number.NaN]) expect(() => pauseEnd(sep1, days), String(days)).toThrow();
    expect(MAX_PAUSE_DAYS).toBe(30);
  });

  it('extends by the actual paused time, capped at the planned resume and at 30 days', () => {
    const paused = sep1;
    const planned = pauseEnd(paused, 10);
    expect(pauseExtensionMs(paused, new Date(paused.getTime() + 3 * DAY), planned)).toBe(3 * DAY); // resumed early
    expect(pauseExtensionMs(paused, new Date(paused.getTime() + 25 * DAY), planned)).toBe(10 * DAY); // resumed late
    expect(pauseExtensionMs(paused, new Date(paused.getTime() + 90 * DAY), null)).toBe(30 * DAY); // never more than 30
    expect(pauseExtensionMs(paused, new Date(paused.getTime() - DAY), planned)).toBe(0);
  });
});
