/**
 * Plan changes and pauses (SAAS-006; decisions D7–D10; docs/06-BUSINESS-RULES.md › Plan changes).
 *
 * Pure rules shared by the API and the screens. Every amount is an integer count of paise, and every
 * proration is integer arithmetic — the products are formed in BigInt, so no fraction of a paisa ever
 * exists as a floating-point number. The API is the only caller that decides anything with these; a
 * screen may show a quote, never make one.
 */

import type { BillingCycle } from './subscription';

const DAY_MS = 86_400_000;

/** D9: the longest a single pause may run. */
export const MAX_PAUSE_DAYS = 30;

export type PlanChangeKind = 'upgrade' | 'cycle_upgrade' | 'downgrade' | 'scheduled_change';

/** Whether a change of this kind is charged now and applied on payment, or applied at the period boundary. */
export const isImmediate = (kind: PlanChangeKind): boolean => kind === 'upgrade' || kind === 'cycle_upgrade';

/**
 * `amount × part ÷ whole`, rounded half up to a whole paisa, in integers. `part` is clamped to
 * [0, whole], so a share is never negative and never more than the whole amount.
 */
export function prorate(amount: number, part: number, whole: number): number {
  if (!Number.isSafeInteger(amount) || amount < 0) throw new RangeError('prorate takes a non-negative whole amount of minor units.');
  if (!Number.isSafeInteger(whole) || whole <= 0) throw new RangeError('prorate needs a positive whole to divide by.');
  const share = BigInt(Math.min(Math.max(Math.trunc(part), 0), whole));
  const w = BigInt(whole);
  // (2·a·s + w) ÷ 2w is a·s ÷ w rounded half up.
  return Number((2n * BigInt(amount) * share + w) / (2n * w));
}

/**
 * What kind of change moving from `current` to `next` is (docs/06 table). `null` when nothing would change.
 * Upgrades are strictly more expensive on the same cycle, or monthly → annual; everything else waits
 * for the period boundary.
 */
export function classifyPlanChange(
  current: { planVersionId: string; cycle: BillingCycle; amount: number },
  next: { planVersionId: string; cycle: BillingCycle; amount: number },
): PlanChangeKind | null {
  if (current.cycle !== next.cycle) return current.cycle === 'monthly' && next.cycle === 'annual' ? 'cycle_upgrade' : 'downgrade';
  if (current.planVersionId === next.planVersionId) return null;
  if (next.amount > current.amount) return 'upgrade';
  if (next.amount < current.amount) return 'downgrade';
  return 'scheduled_change';
}

export interface ProrationQuote {
  /** The unused value of the current period, credited (D7, D8). */
  credit: number;
  /** Same cycle: the new plan's value for the rest of the period. Cycle upgrade: the full annual price. */
  newValue: number;
  /** What is charged: `newValue − credit`, never below zero. */
  charge: number;
  /** Credit a cycle change could not use — recorded, never paid out (D10: no refunds). */
  forfeited: number;
  /** The share of the period still to run, as the ms figures the amounts were prorated by. */
  remainingMs: number;
  periodMs: number;
}

/**
 * The prorated charge for an immediate change (D7, D8), priced at `at` against the current period.
 * Refuses a period that has already ended — there is nothing left to prorate.
 */
export function quoteImmediateChange(input: {
  kind: 'upgrade' | 'cycle_upgrade';
  currentAmount: number;
  newAmount: number;
  periodStart: Date;
  periodEnd: Date;
  at: Date;
}): ProrationQuote {
  const periodMs = input.periodEnd.getTime() - input.periodStart.getTime();
  const remainingMs = input.periodEnd.getTime() - input.at.getTime();
  if (periodMs <= 0) throw new RangeError('The billing period has no length.');
  if (remainingMs <= 0) throw new RangeError('The billing period has already ended.');
  const credit = prorate(input.currentAmount, remainingMs, periodMs);
  const newValue = input.kind === 'upgrade' ? prorate(input.newAmount, remainingMs, periodMs) : input.newAmount;
  const difference = newValue - credit;
  return { credit, newValue, charge: Math.max(0, difference), forfeited: Math.max(0, -difference), remainingMs, periodMs };
}

/** When a pause of `days` whole days ends, from `start`. Refuses anything but 1–30 days (D9). */
export function pauseEnd(start: Date, days: number): Date {
  if (!Number.isInteger(days) || days < 1 || days > MAX_PAUSE_DAYS) throw new RangeError(`A pause runs for 1 to ${MAX_PAUSE_DAYS} whole days.`);
  return new Date(start.getTime() + days * DAY_MS);
}

/**
 * How far a resume moves the period end (D9): the actual paused time, from the pause to the resume —
 * or to the planned resume date, if the resume comes after it — and never more than 30 days.
 */
export function pauseExtensionMs(pausedAt: Date, resumedAt: Date, plannedResume: Date | null): number {
  const end = plannedResume && resumedAt > plannedResume ? plannedResume : resumedAt;
  return Math.min(Math.max(0, end.getTime() - pausedAt.getTime()), MAX_PAUSE_DAYS * DAY_MS);
}
