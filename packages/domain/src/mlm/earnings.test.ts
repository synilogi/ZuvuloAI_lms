import { describe, expect, it } from 'vitest';
import { defaultMlmPlanTerms } from './plan';
import {
  programDay,
  istHour,
  istPeriod,
  isIfsc,
  isPan,
  matchingOutcome,
  nextDate,
  periodBounds,
  rankProgress,
  ranksReached,
  splitByHeadroom,
  withdrawalIssue,
} from './earnings';

const lakh = (n: number) => n * 100_000 * 100;
const tiers = defaultMlmPlanTerms('t').tiers;

describe('matching (docs/15 §6.5)', () => {
  it('reproduces the plan’s example: A 40 lakh, B 30 lakh, Crown cap, flush', () => {
    const out = matchingOutcome({ availableA: lakh(40), availableB: lakh(30), rateBps: 1000, dailyCap: 65_000_00, overflow: 'flush' });
    expect(out).toMatchObject({ matchedCv: lakh(30), grossIncome: lakh(3), cappedIncome: 65_000_00, carryAAfter: lakh(10), carryBAfter: 0 });
    expect(out.flushedCv).toBe(23_500_000_00 / 10);
  });

  it('keeps volume above the cap in both legs under carry', () => {
    const out = matchingOutcome({ availableA: lakh(40), availableB: lakh(30), rateBps: 1000, dailyCap: 65_000_00, overflow: 'carry' });
    expect(out.flushedCv).toBe(0);
    expect(out.carryBAfter).toBe(2_350_000_00);
    expect(out.carryAAfter).toBe(lakh(10) + 2_350_000_00);
  });

  it('pays nothing on a zero leg and leaves the other leg alone', () => {
    expect(matchingOutcome({ availableA: 500, availableB: 0, rateBps: 1000, dailyCap: 100, overflow: 'flush' })).toMatchObject({
      matchedCv: 0,
      cappedIncome: 0,
      carryAAfter: 500,
      carryBAfter: 0,
    });
  });

  it('pays exactly the cap with nothing flushed when the income equals it', () => {
    expect(matchingOutcome({ availableA: 1000, availableB: 1000, rateBps: 1000, dailyCap: 100, overflow: 'flush' })).toMatchObject({
      cappedIncome: 100,
      flushedCv: 0,
      carryAAfter: 0,
      carryBAfter: 0,
    });
  });
});

describe('ranks (docs/15 §6.6): exact 50:50', () => {
  const associateLeg = tiers[0].groupCv / 2;

  it('needs half on each leg: excess on one leg never counts', () => {
    expect(ranksReached(tiers, tiers[0].groupCv * 100, associateLeg - 1)).toEqual([]);
    expect(ranksReached(tiers, associateLeg, associateLeg).map((t) => t.order)).toEqual([1]);
  });

  it('reaches every rank passed on the way, in order', () => {
    expect(ranksReached(tiers, tiers[2].groupCv / 2, tiers[2].groupCv / 2).map((t) => t.order)).toEqual([1, 2, 3]);
  });

  it('shows the shortfall per leg to the next rank', () => {
    const progress = rankProgress(tiers, 0, associateLeg, 0);
    expect(progress.current).toBeNull();
    expect(progress.next).toMatchObject({ order: 1, shortfallA: 0, shortfallB: associateLeg });
    expect(rankProgress(tiers, 18, 0, 0).next).toBeNull();
  });
});

describe('the ceiling (docs/15 §6.7)', () => {
  it('pays what fits and holds the rest', () => {
    expect(splitByHeadroom(300, { grossEligibleSales: 1000, ceilingBps: 2500, accrued: 100 })).toEqual({ payNow: 150, hold: 150, headroom: 150 });
  });
  it('holds everything when the period is over its ceiling', () => {
    expect(splitByHeadroom(300, { grossEligibleSales: 1000, ceilingBps: 2500, accrued: 900 })).toEqual({ payNow: 0, hold: 300, headroom: 0 });
  });
});

describe('the program’s calendar is India’s', () => {
  it('turns over at midnight IST', () => {
    expect(programDay(new Date('2026-10-31T18:29:00Z'))).toBe('2026-10-31');
    expect(programDay(new Date('2026-10-31T18:30:00Z'))).toBe('2026-11-01');
    expect(istPeriod(new Date('2026-10-31T18:30:00Z'))).toBe('2026-11');
    expect(istHour(new Date('2026-10-31T18:30:00Z'))).toBe(0);
    expect(nextDate('2026-12-31')).toBe('2027-01-01');
  });
  it('bounds a month in IST', () => {
    expect(periodBounds('2026-11').from.toISOString()).toBe('2026-10-31T18:30:00.000Z');
    expect(periodBounds('2026-12').to.toISOString()).toBe('2026-12-31T18:30:00.000Z');
  });
});

describe('withdrawal rules (docs/15 §6.9)', () => {
  const ok = { amount: 100000, available: 200000, minAmount: 50000, active: true, kycVerified: true, kycRequired: true, openRequest: false };
  it('allows a request that meets every rule', () => expect(withdrawalIssue(ok)).toBeUndefined());
  it.each([
    [{ active: false }, /active/],
    [{ kycVerified: false }, /KYC/],
    [{ openRequest: true }, /in progress/],
    [{ amount: 100 }, /smallest/],
    [{ amount: 300000 }, /more than/],
  ])('refuses %j', (patch, message) => expect(withdrawalIssue({ ...ok, ...patch })).toMatch(message));
  it('checks document shapes', () => {
    expect(isPan('ABCDE1234F')).toBe(true);
    expect(isPan('abcde1234f')).toBe(false);
    expect(isIfsc('HDFC0001234')).toBe(true);
    expect(isIfsc('HDFC1001234')).toBe(false);
  });
});
