import { describe, expect, it } from 'vitest';
import {
  MLM_BPS,
  bpsOf,
  capBandForRank,
  defaultMlmPlanTerms,
  legCvOf,
  mlmActivationIssues,
  reachableMlmPlanStatuses,
  validateMlmPlanTerms,
  type MlmPlanTermsInput,
} from './plan';

const base = (): MlmPlanTermsInput => defaultMlmPlanTerms('tenant-1');
const fields = (input: MlmPlanTermsInput) => validateMlmPlanTerms(input).map((i) => i.field);

describe('the version-1 plan from the PDF', () => {
  const plan = base();

  it('is valid as written, and needs only an eligible course to activate', () => {
    expect(validateMlmPlanTerms(plan)).toEqual([]);
    expect(mlmActivationIssues(plan).map((i) => i.field)).toEqual(['eligibleCourseIds']);
    expect(mlmActivationIssues({ eligibleCourseIds: ['c1'] })).toEqual([]);
  });

  it('has the 18 ranks in ascending order, each split exactly in half', () => {
    expect(plan.tiers).toHaveLength(18);
    expect(plan.tiers.map((t) => t.name)).toEqual([
      'Associate',
      'Achiever',
      'Star',
      'Bronze',
      'Silver',
      'Gold',
      'Platinum',
      'Pearl',
      'Sapphire',
      'Ruby',
      'Emerald',
      'Diamond',
      'Blue Diamond',
      'Royal Diamond',
      'Crown Diamond',
      'Ambassador',
      'Global Ambassador',
      'Legacy Ambassador',
    ]);
    for (let i = 1; i < plan.tiers.length; i++) expect(plan.tiers[i].groupCv).toBeGreaterThan(plan.tiers[i - 1].groupCv);
    // ₹20K → each leg ₹10K; ₹500Cr → each leg ₹250Cr, in paise.
    expect(legCvOf(plan.tiers[0])).toBe(10_000 * 100);
    expect(legCvOf(plan.tiers[17])).toBe(250_00_00_000 * 100);
    expect(Number.isSafeInteger(plan.tiers[17].groupCv)).toBe(true);
  });

  it('carries the PDF rewards: recognition, certificate, ₹5K … ₹4Cr, and "up to ₹10Cr"', () => {
    expect(plan.tiers[0]).toMatchObject({ rewardKind: 'recognition', rewardAmount: 0 });
    expect(plan.tiers[1]).toMatchObject({ rewardKind: 'certificate', rewardAmount: 0 });
    expect(plan.tiers[2]).toMatchObject({ rewardKind: 'cash', rewardAmount: 5_000 * 100 });
    expect(plan.tiers[16]).toMatchObject({ rewardKind: 'cash', rewardAmount: 4_00_00_000 * 100 });
    expect(plan.tiers[17]).toMatchObject({ rewardKind: 'cash', rewardAmount: 0, rewardCapAmount: 10_00_00_000 * 100 });
  });

  it('maps every rank to a cap band, the unnamed ranks to the nearest named band below (D-MLM-10)', () => {
    expect(capBandForRank(plan, 0).key).toBe('starter');
    expect(capBandForRank(plan, 1).key).toBe('starter'); // Associate
    expect(capBandForRank(plan, 8).key).toBe('platinum'); // Pearl
    expect(capBandForRank(plan, 11).key).toBe('ruby'); // Emerald
    expect(capBandForRank(plan, 14).key).toBe('ruby'); // Royal Diamond
    expect(capBandForRank(plan, 15).dailyCap).toBe(65_000 * 100); // Crown Diamond
    expect(() => capBandForRank(plan, 19)).toThrow();
  });

  it('matches at 10% with a 25% ceiling and 15% planning payout', () => {
    expect(plan.matchingRateBps).toBe(1000);
    expect(plan.payoutCeilingBps).toBe(2500);
    expect(plan.normalPayoutBps).toBe(1500);
    expect(plan.cvBasisPoints).toBe(MLM_BPS);
  });
});

describe('basis-point arithmetic', () => {
  it('takes a share and rounds half-up', () => {
    expect(bpsOf(30_00_000 * 100, 1000)).toBe(3_00_000 * 100); // ₹30 lakh matched → ₹3 lakh
    expect(bpsOf(1_000_000, 10_000)).toBe(1_000_000);
    expect(bpsOf(5, 1000)).toBe(1); // 0.5 rounds up
    expect(bpsOf(4, 1000)).toBe(0);
  });
});

describe('validation', () => {
  it('refuses rates and hours outside their bounds', () => {
    expect(fields({ ...base(), cvBasisPoints: 0 })).toContain('cvBasisPoints');
    expect(fields({ ...base(), matchingRateBps: 5001 })).toContain('matchingRateBps');
    expect(fields({ ...base(), payoutCeilingBps: 10_001 })).toContain('payoutCeilingBps');
    expect(fields({ ...base(), normalPayoutBps: 3000 })).toContain('normalPayoutBps');
    expect(fields({ ...base(), matchingRunHourIst: 24 })).toContain('matchingRunHourIst');
    expect(fields({ ...base(), cvEligibilityDelayDays: -1 })).toContain('cvEligibilityDelayDays');
    expect(fields({ ...base(), tdsBps: 5001 })).toContain('tdsBps');
    expect(fields({ ...base(), currency: 'rupees' })).toContain('currency');
    expect(fields({ ...base(), withdrawalMinAmount: 10.5 })).toContain('withdrawalMinAmount');
  });

  it('ties carry-forward expiry to its policy', () => {
    expect(fields({ ...base(), carryForwardPolicy: 'indefinite', carryExpiryDays: 30 })).toContain('carryExpiryDays');
  });

  it('wants a sensible list of cap bands with unique keys', () => {
    expect(fields({ ...base(), capBands: [] })).toContain('capBands');
    const dup = base();
    dup.capBands[1] = { ...dup.capBands[1], key: 'starter' };
    expect(fields(dup)).toContain('capBands.1.key');
    const bad = base();
    bad.capBands[0] = { ...bad.capBands[0], key: 'Starter Band', dailyCap: 0 };
    expect(fields(bad)).toEqual(expect.arrayContaining(['capBands.0.key', 'capBands.0.dailyCap']));
  });

  it('keeps ranks numbered, named, even, ascending and pointed at a real band', () => {
    const plan = base();
    plan.tiers[2] = { ...plan.tiers[2], order: 5 };
    expect(fields(plan)).toContain('tiers.2.order');

    const sameName = base();
    sameName.tiers[3] = { ...sameName.tiers[3], name: 'star' };
    expect(fields(sameName)).toContain('tiers.3.name');

    const odd = base();
    odd.tiers[0] = { ...odd.tiers[0], groupCv: 2_000_001 };
    expect(fields(odd)).toContain('tiers.0.groupCv');

    const flat = base();
    flat.tiers[1] = { ...flat.tiers[1], groupCv: flat.tiers[0].groupCv };
    expect(fields(flat)).toContain('tiers.1.groupCv');

    const band = base();
    band.tiers[0] = { ...band.tiers[0], capBandKey: 'gold' };
    expect(fields(band)).toContain('tiers.0.capBandKey');

    expect(fields({ ...base(), tiers: [] })).toContain('tiers');
  });

  it('allows a cash reward to be fixed, or "up to" an amount, but never nothing', () => {
    const plan = base();
    plan.tiers[2] = { ...plan.tiers[2], rewardAmount: 0, rewardCapAmount: null };
    expect(fields(plan)).toContain('tiers.2.rewardAmount');

    const recognitionWithMoney = base();
    recognitionWithMoney.tiers[0] = { ...recognitionWithMoney.tiers[0], rewardAmount: 100 };
    expect(fields(recognitionWithMoney)).toContain('tiers.0.rewardAmount');

    const capBelow = base();
    capBelow.tiers[2] = { ...capBelow.tiers[2], rewardCapAmount: 1 };
    expect(fields(capBelow)).toContain('tiers.2.rewardCapAmount');

    const capOnRecognition = base();
    capOnRecognition.tiers[0] = { ...capOnRecognition.tiers[0], rewardCapAmount: 100 };
    expect(fields(capOnRecognition)).toContain('tiers.0.rewardCapAmount');
  });

  it('wants the program academy and a clean course list', () => {
    expect(fields({ ...base(), programTenantId: ' ' })).toContain('programTenantId');
    expect(fields({ ...base(), eligibleCourseIds: ['a', 'a'] })).toContain('eligibleCourseIds');
    expect(fields({ ...base(), eligibleCourseIds: ['a', ''] })).toContain('eligibleCourseIds');
    expect(fields({ ...base(), note: 'x'.repeat(2001) })).toContain('note');
  });
});

describe('status moves', () => {
  it('go draft → active → retired and nowhere else', () => {
    expect(reachableMlmPlanStatuses('draft')).toEqual(['active']);
    expect(reachableMlmPlanStatuses('active')).toEqual(['retired']);
    expect(reachableMlmPlanStatuses('retired')).toEqual([]);
  });
});
