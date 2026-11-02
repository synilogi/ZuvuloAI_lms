import type { MlmCapOverflowPolicy, MlmRankTier, MlmRewardKind } from './plan';
import { bpsOf, legCvOf, MLM_BPS } from './plan';

/*
 * What the affiliate program pays and when (docs/15 §6.5 to §6.9). The rules are pure, in integers of minor units, so the
 * API, the screens and the tests share one account of them. The API stores the results in immutable ledgers. Nothing here
 * estimates what anyone might earn: every function works from volume that has already been verified.
 */

/* ─── Matching (§6.5) ─── */

export interface MatchingOutcome {
  matchedCv: number;
  grossIncome: number;
  /** What the day's cap lets through. */
  cappedIncome: number;
  /** Matched volume above the cap removed from both pools under the `flush` policy. */
  flushedCv: number;
  carryAAfter: number;
  carryBAfter: number;
}

/**
 * One affiliate's day: match the weaker leg, pay the rate up to the cap. The stronger leg's excess always carries forward.
 * Volume above the cap is flushed from both legs or stays in both, as the plan says.
 */
export function matchingOutcome(input: {
  availableA: number;
  availableB: number;
  rateBps: number;
  dailyCap: number;
  overflow: MlmCapOverflowPolicy;
}): MatchingOutcome {
  const { availableA, availableB, rateBps, dailyCap, overflow } = input;
  const matchedCv = Math.max(0, Math.min(availableA, availableB));
  const grossIncome = bpsOf(matchedCv, rateBps);
  const cappedIncome = Math.min(grossIncome, Math.max(0, dailyCap));
  let overflowCv = 0;
  if (cappedIncome < grossIncome && rateBps > 0) overflowCv = Math.min(matchedCv, Math.round(((grossIncome - cappedIncome) * MLM_BPS) / rateBps));
  const consumed = overflow === 'flush' ? matchedCv : matchedCv - overflowCv;
  return {
    matchedCv,
    grossIncome,
    cappedIncome,
    flushedCv: overflow === 'flush' ? overflowCv : 0,
    carryAAfter: availableA - consumed,
    carryBAfter: availableB - consumed,
  };
}

/* ─── Ranks (§6.6): exact 50:50 ─── */

/** The ranks a member's lifetime legs satisfy: each leg must hold half the group CV on its own; excess on one leg never counts for the other. */
export function ranksReached<T extends Pick<MlmRankTier, 'order' | 'groupCv'>>(tiers: readonly T[], lifetimeA: number, lifetimeB: number): T[] {
  return [...tiers].sort((a, b) => a.order - b.order).filter((t) => lifetimeA >= legCvOf(t) && lifetimeB >= legCvOf(t));
}

export interface RankProgress {
  current: { order: number; name: string } | null;
  next: { order: number; name: string; legRequired: number; shortfallA: number; shortfallB: number } | null;
}

export function rankProgress(
  tiers: readonly Pick<MlmRankTier, 'order' | 'name' | 'groupCv'>[],
  rankOrder: number,
  lifetimeA: number,
  lifetimeB: number,
): RankProgress {
  const sorted = [...tiers].sort((a, b) => a.order - b.order);
  const current = sorted.find((t) => t.order === rankOrder);
  const next = sorted.find((t) => t.order > rankOrder);
  return {
    current: current ? { order: current.order, name: current.name } : null,
    next: next
      ? {
          order: next.order,
          name: next.name,
          legRequired: legCvOf(next),
          shortfallA: Math.max(0, legCvOf(next) - lifetimeA),
          shortfallB: Math.max(0, legCvOf(next) - lifetimeB),
        }
      : null,
  };
}

/* ─── The company ceiling (§6.7) ─── */

/** How much of an amount fits under the period's ceiling, and how much must wait. */
export function splitByHeadroom(
  amount: number,
  input: { grossEligibleSales: number; ceilingBps: number; accrued: number },
): { payNow: number; hold: number; headroom: number } {
  const headroom = Math.max(0, bpsOf(input.grossEligibleSales, input.ceilingBps) - input.accrued);
  const payNow = Math.min(amount, headroom);
  return { payNow, hold: amount - payNow, headroom };
}

/* ─── Dates: the program's day and month are India's (§6.5, D-MLM-17) ─── */

const IST_OFFSET_MS = 330 * 60_000;

/** `YYYY-MM-DD` in IST. */
export const programDay = (at: Date): string => new Date(at.getTime() + IST_OFFSET_MS).toISOString().slice(0, 10);
/** `YYYY-MM` in IST. */
export const istPeriod = (at: Date): string => programDay(at).slice(0, 7);
/** The hour of the day in IST, 0 to 23. */
export const istHour = (at: Date): number => new Date(at.getTime() + IST_OFFSET_MS).getUTCHours();
/** The UTC instants a `YYYY-MM` period runs between, in IST. */
export function periodBounds(period: string): { from: Date; to: Date } {
  const [y, m] = period.split('-').map(Number);
  return { from: new Date(Date.UTC(y, m - 1, 1) - IST_OFFSET_MS), to: new Date(Date.UTC(y, m, 1) - IST_OFFSET_MS) };
}
/** Whether text is a real `YYYY-MM-DD` date: `2026-02-31` is not, though its shape is right. */
export function isProgramDate(date: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return false;
  const at = new Date(`${date}T00:00:00Z`);
  return !Number.isNaN(at.getTime()) && at.toISOString().slice(0, 10) === date;
}
/** The instant a program day ends, in IST. */
export const programDayEnd = (date: string): Date => new Date(Date.parse(`${date}T00:00:00+05:30`) + 86_400_000);
/** The day after a `YYYY-MM-DD`. */
export const nextDate = (date: string): string => new Date(Date.parse(`${date}T00:00:00Z`) + 86_400_000).toISOString().slice(0, 10);

/* ─── Withdrawals (§6.9) ─── */

/** Why a withdrawal cannot be requested, in words, or undefined. */
export function withdrawalIssue(input: {
  amount: number;
  available: number;
  minAmount: number;
  active: boolean;
  kycVerified: boolean;
  kycRequired: boolean;
  openRequest: boolean;
}): string | undefined {
  if (!input.active) return 'Your affiliate account must be active to withdraw.';
  if (input.kycRequired && !input.kycVerified) return 'Your identity check (KYC) must be verified before you can withdraw.';
  if (input.openRequest) return 'You already have a withdrawal in progress.';
  if (!Number.isInteger(input.amount) || input.amount <= 0) return 'Enter an amount to withdraw.';
  if (input.amount < input.minAmount) return 'That is below the smallest withdrawal the plan allows.';
  if (input.amount > input.available) return 'That is more than your available balance.';
  return undefined;
}

/** Indian PAN, IFSC and a plain bank account number: the shapes the KYC form accepts. */
export const isPan = (v: string): boolean => /^[A-Z]{5}[0-9]{4}[A-Z]$/.test(v);
export const isIfsc = (v: string): boolean => /^[A-Z]{4}0[A-Z0-9]{6}$/.test(v);
export const isBankAccount = (v: string): boolean => /^[0-9]{6,18}$/.test(v);

/* ─── Vocabulary and views ─── */

export type MlmCommissionKind = 'matching' | 'rank_reward' | 'reversal';
export type MlmCommissionStatus = 'paid_to_wallet' | 'held' | 'written_off' | 'split';
export type MlmRewardStatus = 'qualified' | 'approved' | 'vesting' | 'funded' | 'paid' | 'rejected';
export type MlmWalletEntryType =
  'matching_credit' | 'reward_credit' | 'reversal_debit' | 'withdrawal_hold' | 'withdrawal_paid' | 'withdrawal_released' | 'tds_debit' | 'adjustment';
export type MlmKycStatus = 'none' | 'submitted' | 'verified' | 'rejected';
export type MlmWithdrawalStatus = 'requested' | 'approved' | 'processing' | 'paid' | 'rejected' | 'cancelled';

export const MLM_COMMISSION_STATUSES: readonly MlmCommissionStatus[] = ['paid_to_wallet', 'held', 'written_off', 'split'];
export const MLM_REWARD_STATUSES: readonly MlmRewardStatus[] = ['qualified', 'approved', 'vesting', 'funded', 'paid', 'rejected'];
export const MLM_KYC_STATUSES: readonly MlmKycStatus[] = ['none', 'submitted', 'verified', 'rejected'];
export const MLM_WITHDRAWAL_STATUSES: readonly MlmWithdrawalStatus[] = ['requested', 'approved', 'processing', 'paid', 'rejected', 'cancelled'];

export const MLM_COMMISSION_KIND_LABEL: Record<MlmCommissionKind, string> = { matching: 'Matching', rank_reward: 'Rank reward', reversal: 'Reversal' };
export const MLM_COMMISSION_STATUS_LABEL: Record<MlmCommissionStatus, string> = {
  paid_to_wallet: 'In wallet',
  held: 'Held by payout policy',
  written_off: 'Written off',
  split: 'Divided',
};
export const MLM_REWARD_STATUS_LABEL: Record<MlmRewardStatus, string> = {
  qualified: 'Awaiting approval',
  approved: 'Approved',
  vesting: 'Vesting',
  funded: 'Funded',
  paid: 'Paid',
  rejected: 'Rejected',
};
export const MLM_WALLET_ENTRY_LABEL: Record<MlmWalletEntryType, string> = {
  matching_credit: 'Matching income',
  reward_credit: 'Rank reward',
  reversal_debit: 'Reversal',
  withdrawal_hold: 'Withdrawal requested',
  withdrawal_paid: 'Withdrawal paid',
  withdrawal_released: 'Withdrawal released',
  tds_debit: 'Tax deducted',
  adjustment: 'Adjustment',
};
export const MLM_KYC_STATUS_LABEL: Record<MlmKycStatus, string> = {
  none: 'Not submitted',
  submitted: 'Under review',
  verified: 'Verified',
  rejected: 'Needs changes',
};
export const MLM_WITHDRAWAL_STATUS_LABEL: Record<MlmWithdrawalStatus, string> = {
  requested: 'Requested',
  approved: 'Approved',
  processing: 'In a payout batch',
  paid: 'Paid',
  rejected: 'Rejected',
  cancelled: 'Cancelled',
};

export interface Paged<T> {
  rows: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface MemberRef {
  id: string;
  code: string;
  name: string;
}

export interface MlmMatchingRunRow {
  id: string;
  affiliate: MemberRef;
  runDate: string;
  rankOrderAtRun: number;
  availableA: number;
  availableB: number;
  matchedCv: number;
  grossIncome: number;
  dailyCap: number;
  cappedIncome: number;
  flushedCv: number;
  carryAAfter: number;
  carryBAfter: number;
  heldByCeiling: number;
  createdAt: string;
}

export interface MlmCommissionRow {
  id: string;
  affiliate: MemberRef;
  kind: MlmCommissionKind;
  amount: number;
  status: MlmCommissionStatus;
  holdReason: string | null;
  period: string | null;
  createdAt: string;
  settledAt: string | null;
}

export interface MlmRankHistoryRow {
  id: string;
  affiliate: MemberRef;
  tierOrder: number;
  tierName: string;
  lifetimeA: number;
  lifetimeB: number;
  achievedAt: string;
}

export interface MlmRewardRow {
  id: string;
  affiliate: MemberRef;
  tierOrder: number;
  tierName: string;
  kind: MlmRewardKind;
  /** Decided at approval for an "up to" reward. */
  amount: number;
  capAmount: number | null;
  status: MlmRewardStatus;
  vestsAt: string | null;
  note: string | null;
  needsReview: boolean;
  createdAt: string;
}

export interface MlmWalletBalances {
  available: number;
  held: number;
  paid: number;
  /** Commissions waiting under the company's payout ceiling: not yet in the wallet. */
  heldByPolicy: number;
  currency: string;
}

export interface MlmWalletEntryRow {
  id: string;
  type: MlmWalletEntryType;
  availableDelta: number;
  heldDelta: number;
  paidDelta: number;
  note: string | null;
  createdAt: string;
}

export interface MlmWalletRow extends Omit<MlmWalletBalances, 'currency'> {
  affiliate: MemberRef;
}

export interface MlmKycView {
  status: MlmKycStatus;
  legalName: string;
  panLast4: string;
  bankAccountLast4: string;
  ifsc: string;
  accountHolder: string;
  upiId: string | null;
  rejectionReason: string | null;
  submittedAt: string | null;
  reviewedAt: string | null;
  /** The identity documents the member uploaded. */
  documents: { id: string; name: string }[];
}

export interface MlmKycInput {
  legalName: string;
  pan: string;
  bankAccount: string;
  ifsc: string;
  accountHolder: string;
  upiId?: string;
  /** The member's own uploads: a PAN card, a cancelled cheque. */
  documentIds?: string[];
}

export const MLM_KYC_MAX_DOCUMENTS = 4;

export interface MlmKycRow extends MlmKycView {
  affiliate: MemberRef;
}

export interface MlmWithdrawalRow {
  id: string;
  affiliate: MemberRef;
  amount: number;
  tdsAmount: number;
  netAmount: number;
  status: MlmWithdrawalStatus;
  /** Masked: the account's last digits, the IFSC, the holder. */
  bank: { accountLast4: string; ifsc: string; accountHolder: string; upiId: string | null };
  payoutBatchId: string | null;
  reference: string | null;
  rejectionReason: string | null;
  createdAt: string;
  decidedAt: string | null;
  paidAt: string | null;
}

export interface MlmPayoutBatchRow {
  id: string;
  reference: string;
  count: number;
  total: number;
  createdAt: string;
  closedAt: string | null;
}

export interface MlmLiabilityReport {
  period: string;
  grossEligibleSales: number;
  ceilingAmount: number;
  /** The plan's planning figure; it triggers nothing. */
  normalAmount: number;
  matchingPaid: number;
  rewardsPaid: number;
  reversals: number;
  fieldPayout: number;
  /** Field payout as basis points of gross eligible sales. */
  payoutRatioBps: number;
  heldAmount: number;
  headroom: number;
  withdrawalsPaid: number;
  walletLiability: number;
  currency: string;
}

export interface MlmJobHealth {
  job: string;
  lastRunAt: string | null;
  lastOutcome: string | null;
}

export interface MlmDashboard {
  /** The program's scheduled jobs and how each last ended. */
  jobs: MlmJobHealth[];
  members: { total: number; active: number; pending: number; suspended: number };
  queues: { kyc: number; rewards: number; withdrawals: number; heldCommissions: number };
  period: MlmLiabilityReport;
  lastMatchingDate: string | null;
}

export interface AffiliateEarnings {
  wallet: MlmWalletBalances;
  progress: RankProgress;
  lifetimeA: number;
  lifetimeB: number;
  matchingIncome: number;
  rewardIncome: number;
}
