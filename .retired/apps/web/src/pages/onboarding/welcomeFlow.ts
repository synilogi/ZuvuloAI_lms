import type { BillingCycle, Plan, TenantBilling } from '@syniastrolms/domain';

/*
 * The first-plan page's decisions, apart from its markup: what each plan offers to do, and what starting a free
 * trial does. Kept pure so each can be checked on its own.
 */

/** Whether a plan can be started as a free trial on this cycle, for this academy, by this admin. */
export function canTrial(plan: Plan, cycle: BillingCycle, billing: Pick<TenantBilling, 'trialAvailable'>, canChange: boolean): boolean {
  return canChange && billing.trialAvailable && plan.trialEnabled && plan.trialDays > 0 && plan.cycles.includes(cycle);
}

/** Whether a plan can be bought now on this cycle: online payment is connected and the admin may change billing. */
export function canBuy(plan: Plan, cycle: BillingCycle, billing: Pick<TenantBilling, 'checkoutAvailable'>, canChange: boolean): boolean {
  return canChange && billing.checkoutAvailable && plan.cycles.includes(cycle);
}

/** The cycles any plan on sale is offered on — the toggle shows only when there is a choice. */
export const offeredCycles = (plans: Plan[]): BillingCycle[] => (['monthly', 'annual'] as const).filter((c) => plans.some((p) => p.cycles.includes(c)));

/** Where "Buy now" goes: the billing page, which takes the billing details and opens the checkout. */
export const buyPath = (plan: Plan, cycle: BillingCycle) => `/admin/billing?plan=${encodeURIComponent(plan.id)}&cycle=${cycle}`;

export type TrialOutcome = { ok: true } | { ok: false; message: string };

/**
 * Starts the trial, then reads the billing summary and the academy's plan again so the sidebar, the banner and the
 * dashboard all follow at once. A failed refresh is not a failed trial: the trial started, and the next read catches up.
 */
export async function startFreeTrial(
  deps: { start: (input: { planId: string; cycle: BillingCycle }) => Promise<void>; refresh: () => Promise<unknown>[] },
  input: { planId: string; cycle: BillingCycle },
): Promise<TrialOutcome> {
  try {
    await deps.start(input);
  } catch (err) {
    return { ok: false, message: err instanceof Error ? err.message : 'The trial could not be started.' };
  }
  await Promise.allSettled(deps.refresh());
  return { ok: true };
}
