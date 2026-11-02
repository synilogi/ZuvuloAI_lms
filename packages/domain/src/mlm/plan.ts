import { divideRounded, isCurrencyCode, isMinorAmount } from '../money';

/*
 * The affiliate program's plan (docs/15-MLM-AFFILIATE-ARCHITECTURE.md §4.2, §6): every compensation term as data, never
 * a constant in code. A plan is a *version*: the terms a commission, a rank or a matching run was computed under are
 * the version it names, and a change is always a new version. The rules for a valid version are here, so the Super
 * Admin's editor and the API refuse the same things.
 *
 * Money and CV are integer minor units (paise). Group CV targets reach ₹500 crore (5 × 10¹¹ paise), which is far past
 * 2³¹ but well inside JavaScript's safe integers; the API stores these columns as 64-bit integers.
 */

export type MlmLeg = 'A' | 'B';
export const MLM_LEGS: readonly MlmLeg[] = ['A', 'B'];

export type MlmPlanStatus = 'draft' | 'active' | 'retired';
export const MLM_PLAN_STATUSES: readonly MlmPlanStatus[] = ['draft', 'active', 'retired'];

/** What a rank's milestone reward is: a recognition record, a certificate, or money paid to the wallet. */
export type MlmRewardKind = 'recognition' | 'certificate' | 'cash';
export const MLM_REWARD_KINDS: readonly MlmRewardKind[] = ['recognition', 'certificate', 'cash'];

/** Matched volume the daily cap did not pay for: dropped from both legs, or kept in the pools for a later day (D-MLM-10). */
export type MlmCapOverflowPolicy = 'flush' | 'carry';
export const MLM_CAP_OVERFLOW_POLICIES: readonly MlmCapOverflowPolicy[] = ['flush', 'carry'];

/** Unmatched strong-leg CV: kept until matched (the PDF's rule), or aged out after `carryExpiryDays`. */
export type MlmCarryForwardPolicy = 'indefinite' | 'expire-days';
/** Only what the engine does: pools that age out are not built, so a plan cannot ask for them yet. */
export const MLM_CARRY_FORWARD_POLICIES: readonly MlmCarryForwardPolicy[] = ['indefinite'];

/** Where a referral goes when the sponsor's chosen position is taken (§6.3). */
export type MlmSpilloverRule = 'extreme-outer' | 'breadth-first';
export const MLM_SPILLOVER_RULES: readonly MlmSpilloverRule[] = ['extreme-outer', 'breadth-first'];

/** The period the company payout ceiling is measured over (§6.7). */
export type MlmLiabilityPeriod = 'month';
export const MLM_LIABILITY_PERIODS: readonly MlmLiabilityPeriod[] = ['month'];

/** One daily matching cap band; ranks point at a band by key. */
export interface MlmCapBand {
  /** Lowercase slug, unique within the version: `starter`, `crown`. */
  key: string;
  label: string;
  /** The most matching income a rank in this band earns in one day, in minor units. */
  dailyCap: number;
}

/** One of the rank tiers, in ascending order of the group CV it needs. */
export interface MlmRankTier {
  /** 1 for the first rank, then 2, 3, … with no gaps. */
  order: number;
  name: string;
  /** Lifetime eligible group CV the rank needs, in minor units. Half must come from each leg (`legCvOf`). */
  groupCv: number;
  rewardKind: MlmRewardKind;
  /** Minor units; 0 for a recognition or certificate reward. */
  rewardAmount: number;
  /** For an "up to" reward: the most the Super Admin may approve. Null when the reward is fixed. */
  rewardCapAmount: number | null;
  capBandKey: string;
  /** Days a cash reward vests after approval before it can be funded and paid. */
  vestingDays: number;
}

/** Every compensation term, as the editor sends it and the API stores it. */
export interface MlmPlanTermsInput {
  /** The academy whose learners are the affiliates and whose courses generate CV (D-MLM-01). */
  programTenantId: string;
  /** Courses of the program academy whose verified sale generates CV. May be empty in a draft; activation needs one. */
  eligibleCourseIds: string[];
  currency: string;
  /** CV as basis points of a sale's net amount: 10000 = the whole amount. */
  cvBasisPoints: number;
  /** Matching income as basis points of matched CV: 1000 = 10%. */
  matchingRateBps: number;
  /** The company-wide ceiling on field payout, as basis points of gross eligible sales: 2500 = 25%. */
  payoutCeilingBps: number;
  /** The planning figure reported against actuals: 1500 = 15%. Triggers nothing. */
  normalPayoutBps: number;
  /** The hour (IST, 0–23) after which the day's matching run happens. */
  matchingRunHourIst: number;
  /** Days a verified sale waits before its CV counts (0 = the next job tick). */
  cvEligibilityDelayDays: number;
  capOverflowPolicy: MlmCapOverflowPolicy;
  carryForwardPolicy: MlmCarryForwardPolicy;
  /** Required when the carry-forward policy is `expire-days`; null otherwise. */
  carryExpiryDays: number | null;
  spilloverRule: MlmSpilloverRule;
  /** Minor units. */
  withdrawalMinAmount: number;
  withdrawalRequiresKyc: boolean;
  /** Tax deducted at payout, in basis points; 0 until the company decides a rate. */
  tdsBps: number;
  liabilityPeriod: MlmLiabilityPeriod;
  /** Free text for the people who edit the plan: what changed and why. */
  note: string;
  capBands: MlmCapBand[];
  tiers: MlmRankTier[];
}

/** A stored version: its terms and where it stands. */
export interface MlmPlanTerms extends MlmPlanTermsInput {
  id: string;
  version: number;
  status: MlmPlanStatus;
  createdAt: string;
  activatedAt: string | null;
  retiredAt: string | null;
}

/** A row of the versions list. */
export interface MlmPlanVersionSummary {
  id: string;
  version: number;
  status: MlmPlanStatus;
  programTenantId: string;
  tierCount: number;
  eligibleCourseCount: number;
  createdAt: string;
  activatedAt: string | null;
  retiredAt: string | null;
  note: string;
}

/** Which version a program is on, and every version there has been. */
export interface MlmPlanOverview {
  active: MlmPlanTerms | null;
  versions: MlmPlanVersionSummary[];
}

/** A course of the program academy the Super Admin can mark eligible. */
export interface MlmProgramCourse {
  id: string;
  title: string;
  status: string;
  /** Whole rupees, or null when no admin has chosen a price (such a course cannot be sold). */
  priceAmount: number | null;
  currency: string;
}

export interface MlmPlanIssue {
  /** `tiers.3.groupCv` names the third tier's field; `tiers` names the list as a whole. */
  field: string;
  message: string;
}

export const MLM_BPS = 10_000;
export const MLM_MAX_TIERS = 40;
export const MLM_MAX_CAP_BANDS = 12;
export const MLM_MAX_ELIGIBLE_COURSES = 50;
export const MLM_MAX_NOTE = 2000;
const MAX_NAME = 40;
const CAP_BAND_KEY = /^[a-z][a-z0-9-]{1,23}$/;

/** Half the tier's group CV: what each leg must reach on its own (exact 50:50). */
export const legCvOf = (tier: Pick<MlmRankTier, 'groupCv'>): number => tier.groupCv / 2;

/** An amount's share in basis points, rounded half-up: `bpsOf(10_000_00, 1000)` is 10% of ₹10,000. */
export const bpsOf = (amount: number, bps: number): number => divideRounded(amount * bps, MLM_BPS);

/** The cap band of a rank: rank 0 (no rank yet) uses the first band. Throws when the version is inconsistent, which validation prevents. */
export function capBandForRank(terms: Pick<MlmPlanTermsInput, 'capBands' | 'tiers'>, rankOrder: number): MlmCapBand {
  if (rankOrder <= 0) {
    const first = terms.capBands[0];
    if (!first) throw new Error('The plan has no cap band.');
    return first;
  }
  const tier = terms.tiers.find((t) => t.order === rankOrder);
  if (!tier) throw new Error(`The plan has no rank ${rankOrder}.`);
  const band = terms.capBands.find((b) => b.key === tier.capBandKey);
  if (!band) throw new Error(`Rank ${tier.name} names a cap band the plan does not have.`);
  return band;
}

export const tierByOrder = (terms: Pick<MlmPlanTermsInput, 'tiers'>, order: number): MlmRankTier | undefined => terms.tiers.find((t) => t.order === order);

export const normaliseCapBandKey = (key: string): string => key.trim().toLowerCase();

const isIntIn = (value: unknown, min: number, max: number): value is number => isMinorAmount(value) && value >= min && value <= max;

/**
 * Every rule a version must meet before it can be stored. Drafts and active versions alike: a draft that fails here
 * is refused, so a plan on disk is always one the engines can run. Activation adds `mlmActivationIssues`.
 */
export function validateMlmPlanTerms(input: MlmPlanTermsInput): MlmPlanIssue[] {
  const issues: MlmPlanIssue[] = [];
  const add = (field: string, message: string) => issues.push({ field, message });

  if (typeof input.programTenantId !== 'string' || !input.programTenantId.trim()) add('programTenantId', 'Choose the LMS whose learners are the affiliates.');
  if (!Array.isArray(input.eligibleCourseIds)) add('eligibleCourseIds', 'Eligible courses must be a list.');
  else {
    if (input.eligibleCourseIds.length > MLM_MAX_ELIGIBLE_COURSES) add('eligibleCourseIds', `At most ${MLM_MAX_ELIGIBLE_COURSES} courses can be eligible.`);
    if (new Set(input.eligibleCourseIds).size !== input.eligibleCourseIds.length) add('eligibleCourseIds', 'A course is listed twice.');
    if (input.eligibleCourseIds.some((id) => typeof id !== 'string' || !id.trim())) add('eligibleCourseIds', 'A course id is missing.');
  }
  if (!isCurrencyCode(input.currency)) add('currency', 'The currency must be a three-letter ISO code, such as INR.');
  if (!isIntIn(input.cvBasisPoints, 1, MLM_BPS)) add('cvBasisPoints', 'CV must be between 0.01% and 100% of the sale.');
  if (!isIntIn(input.matchingRateBps, 1, 5000)) add('matchingRateBps', 'The matching rate must be between 0.01% and 50%.');
  if (!isIntIn(input.payoutCeilingBps, 1, MLM_BPS)) add('payoutCeilingBps', 'The payout ceiling must be between 0.01% and 100% of sales.');
  if (!isIntIn(input.normalPayoutBps, 0, MLM_BPS)) add('normalPayoutBps', 'The normal payout figure must be between 0% and 100%.');
  else if (isIntIn(input.payoutCeilingBps, 1, MLM_BPS) && input.normalPayoutBps > input.payoutCeilingBps)
    add('normalPayoutBps', 'The normal payout figure cannot be above the ceiling.');
  if (!isIntIn(input.matchingRunHourIst, 0, 23)) add('matchingRunHourIst', 'The matching run hour is 0–23 (IST).');
  if (!isIntIn(input.cvEligibilityDelayDays, 0, 90)) add('cvEligibilityDelayDays', 'The CV eligibility delay is 0–90 days.');
  if (!MLM_CAP_OVERFLOW_POLICIES.includes(input.capOverflowPolicy)) add('capOverflowPolicy', 'Choose what happens to matched volume above the daily cap.');
  if (!MLM_CARRY_FORWARD_POLICIES.includes(input.carryForwardPolicy)) add('carryForwardPolicy', 'Choose a carry-forward policy.');
  else if (input.carryForwardPolicy === 'expire-days') {
    if (!isIntIn(input.carryExpiryDays, 1, 365)) add('carryExpiryDays', 'Carry-forward expiry is 1–365 days.');
  } else if (input.carryExpiryDays !== null) add('carryExpiryDays', 'Carry-forward expiry applies only when carry-forward expires.');
  if (!MLM_SPILLOVER_RULES.includes(input.spilloverRule)) add('spilloverRule', 'Choose a spillover rule.');
  if (!isIntIn(input.withdrawalMinAmount, 0, Number.MAX_SAFE_INTEGER)) add('withdrawalMinAmount', 'The minimum withdrawal is a whole amount of zero or more.');
  if (typeof input.withdrawalRequiresKyc !== 'boolean') add('withdrawalRequiresKyc', 'Say whether withdrawals need verified KYC.');
  if (!isIntIn(input.tdsBps, 0, 5000)) add('tdsBps', 'TDS is between 0% and 50%.');
  if (!MLM_LIABILITY_PERIODS.includes(input.liabilityPeriod)) add('liabilityPeriod', 'Choose the period the payout ceiling is measured over.');
  if (typeof input.note !== 'string' || input.note.length > MLM_MAX_NOTE) add('note', `The note is at most ${MLM_MAX_NOTE} characters.`);

  // Cap bands.
  const bandKeys = new Set<string>();
  if (!Array.isArray(input.capBands) || input.capBands.length === 0) add('capBands', 'Add at least one daily cap band.');
  else {
    if (input.capBands.length > MLM_MAX_CAP_BANDS) add('capBands', `At most ${MLM_MAX_CAP_BANDS} cap bands.`);
    input.capBands.forEach((band, i) => {
      const at = `capBands.${i}`;
      if (typeof band.key !== 'string' || !CAP_BAND_KEY.test(band.key))
        add(`${at}.key`, 'A band key is 2–24 lowercase letters, digits or hyphens, starting with a letter.');
      else if (bandKeys.has(band.key)) add(`${at}.key`, `The band key ${band.key} is used twice.`);
      else bandKeys.add(band.key);
      if (typeof band.label !== 'string' || !band.label.trim() || band.label.trim().length > MAX_NAME)
        add(`${at}.label`, `A band label is 1–${MAX_NAME} characters.`);
      if (!isIntIn(band.dailyCap, 1, Number.MAX_SAFE_INTEGER)) add(`${at}.dailyCap`, 'A daily cap is a whole amount above zero.');
    });
  }

  // Tiers.
  if (!Array.isArray(input.tiers) || input.tiers.length === 0) add('tiers', 'Add at least one rank.');
  else {
    if (input.tiers.length > MLM_MAX_TIERS) add('tiers', `At most ${MLM_MAX_TIERS} ranks.`);
    const names = new Set<string>();
    let previousCv = 0;
    input.tiers.forEach((tier, i) => {
      const at = `tiers.${i}`;
      if (tier.order !== i + 1) add(`${at}.order`, `Ranks are numbered 1, 2, 3 … in order; rank ${i + 1} is numbered ${tier.order}.`);
      const name = typeof tier.name === 'string' ? tier.name.trim() : '';
      if (!name || name.length > MAX_NAME) add(`${at}.name`, `A rank name is 1–${MAX_NAME} characters.`);
      else if (names.has(name.toLowerCase())) add(`${at}.name`, `The rank name ${name} is used twice.`);
      else names.add(name.toLowerCase());
      if (!isIntIn(tier.groupCv, 2, Number.MAX_SAFE_INTEGER)) add(`${at}.groupCv`, 'A rank needs a whole group CV above zero.');
      else {
        if (tier.groupCv % 2 !== 0) add(`${at}.groupCv`, 'Group CV must split exactly in half between the A and B legs, so it must be even.');
        if (tier.groupCv <= previousCv) add(`${at}.groupCv`, 'Each rank needs more group CV than the one before it.');
        previousCv = tier.groupCv;
      }
      if (!MLM_REWARD_KINDS.includes(tier.rewardKind)) add(`${at}.rewardKind`, 'Choose a reward kind.');
      else if (tier.rewardKind === 'cash') {
        if (!isIntIn(tier.rewardAmount, 0, Number.MAX_SAFE_INTEGER)) add(`${at}.rewardAmount`, 'A cash reward is a whole amount of zero or more.');
        // A reward with neither a fixed amount nor an "up to" amount pays nothing: that is not a cash reward.
        else if (tier.rewardAmount === 0 && tier.rewardCapAmount === null)
          add(`${at}.rewardAmount`, 'A cash reward needs an amount, or an "up to" amount decided at approval.');
      } else if (tier.rewardAmount !== 0) add(`${at}.rewardAmount`, 'Only a cash reward carries an amount.');
      if (tier.rewardCapAmount !== null) {
        if (!isIntIn(tier.rewardCapAmount, 1, Number.MAX_SAFE_INTEGER)) add(`${at}.rewardCapAmount`, 'An "up to" amount is a whole amount above zero.');
        else if (tier.rewardKind !== 'cash') add(`${at}.rewardCapAmount`, 'Only a cash reward can have an "up to" amount.');
        else if (isMinorAmount(tier.rewardAmount) && tier.rewardCapAmount < tier.rewardAmount)
          add(`${at}.rewardCapAmount`, 'The "up to" amount cannot be below the reward.');
      }
      if (typeof tier.capBandKey !== 'string' || !bandKeys.has(tier.capBandKey)) add(`${at}.capBandKey`, 'Each rank must name one of the cap bands.');
      if (!isIntIn(tier.vestingDays, 0, 3650)) add(`${at}.vestingDays`, 'Vesting is 0–3650 days.');
    });
  }
  return issues;
}

/** What a draft needs beyond valid terms before it can run: something to sell. */
export function mlmActivationIssues(input: Pick<MlmPlanTermsInput, 'eligibleCourseIds'>): MlmPlanIssue[] {
  return input.eligibleCourseIds.length === 0 ? [{ field: 'eligibleCourseIds', message: 'Name at least one eligible course before activating the plan.' }] : [];
}

/** Which statuses a version can move to from where it stands. */
export function reachableMlmPlanStatuses(from: MlmPlanStatus): MlmPlanStatus[] {
  if (from === 'draft') return ['active'];
  if (from === 'active') return ['retired'];
  return [];
}

const rupees = (amount: number): number => amount * 100;
const lakh = (n: number): number => rupees(n * 100_000);
const crore = (n: number): number => rupees(n * 10_000_000);

/**
 * Version 1, from *AI Course 2-Leg MLM Plan — Corrected 50:50 Balance Edition* (docs/specs). The seed writes it as a
 * draft; the editor starts a new program from it. The cap-band mapping of the ranks the PDF's cap table does not name
 * follows decision D-MLM-10: the band of the nearest named rank below.
 */
export function defaultMlmPlanTerms(programTenantId: string): MlmPlanTermsInput {
  const capBands: MlmCapBand[] = [
    { key: 'starter', label: 'Starter / Achiever', dailyCap: rupees(5_000) },
    { key: 'star', label: 'Star / Bronze', dailyCap: rupees(10_000) },
    { key: 'silver', label: 'Silver / Gold', dailyCap: rupees(20_000) },
    { key: 'platinum', label: 'Platinum / Sapphire', dailyCap: rupees(35_000) },
    { key: 'ruby', label: 'Ruby / Diamond', dailyCap: rupees(50_000) },
    { key: 'crown', label: 'Crown / Ambassador+', dailyCap: rupees(65_000) },
  ];
  const tier = (
    order: number,
    name: string,
    groupCv: number,
    reward: { kind: MlmRewardKind; amount?: number; upTo?: number },
    capBandKey: string,
  ): MlmRankTier => ({
    order,
    name,
    groupCv,
    rewardKind: reward.kind,
    rewardAmount: reward.amount ?? 0,
    rewardCapAmount: reward.upTo ?? null,
    capBandKey,
    vestingDays: order >= 7 ? 90 : 0,
  });
  const cash = (amount: number) => ({ kind: 'cash' as const, amount });
  const tiers: MlmRankTier[] = [
    tier(1, 'Associate', rupees(20_000), { kind: 'recognition' }, 'starter'),
    tier(2, 'Achiever', lakh(1), { kind: 'certificate' }, 'starter'),
    tier(3, 'Star', lakh(3), cash(rupees(5_000)), 'star'),
    tier(4, 'Bronze', lakh(7.5), cash(rupees(15_000)), 'star'),
    tier(5, 'Silver', lakh(15), cash(rupees(30_000)), 'silver'),
    tier(6, 'Gold', lakh(30), cash(rupees(60_000)), 'silver'),
    tier(7, 'Platinum', lakh(60), cash(lakh(1.25)), 'platinum'),
    tier(8, 'Pearl', crore(1.2), cash(lakh(2.5)), 'platinum'),
    tier(9, 'Sapphire', crore(2.5), cash(lakh(5)), 'platinum'),
    tier(10, 'Ruby', crore(5), cash(lakh(10)), 'ruby'),
    tier(11, 'Emerald', crore(10), cash(lakh(20)), 'ruby'),
    tier(12, 'Diamond', crore(20), cash(lakh(35)), 'ruby'),
    tier(13, 'Blue Diamond', crore(35), cash(lakh(60)), 'ruby'),
    tier(14, 'Royal Diamond', crore(50), cash(crore(1)), 'ruby'),
    tier(15, 'Crown Diamond', crore(75), cash(crore(1.5)), 'crown'),
    tier(16, 'Ambassador', crore(100), cash(crore(2)), 'crown'),
    tier(17, 'Global Ambassador', crore(200), cash(crore(4)), 'crown'),
    // "Up to ₹10 crore": the amount is decided at approval, within the cap.
    tier(18, 'Legacy Ambassador', crore(500), { kind: 'cash', amount: 0, upTo: crore(10) }, 'crown'),
  ];
  return {
    programTenantId,
    eligibleCourseIds: [],
    currency: 'INR',
    cvBasisPoints: MLM_BPS,
    matchingRateBps: 1000,
    payoutCeilingBps: 2500,
    normalPayoutBps: 1500,
    matchingRunHourIst: 2,
    cvEligibilityDelayDays: 0,
    capOverflowPolicy: 'flush',
    carryForwardPolicy: 'indefinite',
    carryExpiryDays: null,
    spilloverRule: 'extreme-outer',
    withdrawalMinAmount: rupees(500),
    withdrawalRequiresKyc: true,
    tdsBps: 0,
    liabilityPeriod: 'month',
    note: 'Version 1: the corrected 50:50 edition of the AI Course 2-Leg plan.',
    capBands,
    tiers,
  };
}
