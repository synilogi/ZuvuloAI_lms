import type { BillingCycle, Plan } from '@syniastrolms/domain';
import { FEATURES, LIMIT_KEYS, LIMIT_LABEL, limitOf } from '@syniastrolms/domain';
import { limitText } from '@/pages/superadmin/subscriptions/subscriptionMeta';

/*
 * The pricing page's decisions (SAAS-027), apart from its markup. Every price is the server's (`GET /public/plans`);
 * these only decide what each card offers and how the comparison reads.
 */

export type PlanCta = { kind: 'start'; label: string; to: string } | { kind: 'switch'; label: string; cycle: BillingCycle };

/** What a plan's card offers on the cycle shown: start it (its trial, where it has one), or switch to the cycle it is sold on. */
export function planCta(plan: Plan, cycle: BillingCycle): PlanCta {
  if (!plan.cycles.includes(cycle)) {
    const other: BillingCycle = cycle === 'annual' ? 'monthly' : 'annual';
    return { kind: 'switch', label: `See ${other} pricing`, cycle: other };
  }
  const to = `/get-started?plan=${encodeURIComponent(plan.id)}&cycle=${cycle}`;
  return plan.trialEnabled && plan.trialDays > 0
    ? { kind: 'start', label: `Start ${plan.trialDays}-day free trial`, to }
    : { kind: 'start', label: `Get ${plan.name}`, to };
}

/** How much annual billing saves on a plan, in whole percent, when it is sold both ways. */
export function annualSaving(plan: Plan): number {
  if (!plan.cycles.includes('monthly') || !plan.cycles.includes('annual') || plan.monthlyPrice <= 0) return 0;
  const yearOfMonths = plan.monthlyPrice * 12;
  return Math.max(0, Math.floor(((yearOfMonths - plan.annualPrice) / yearOfMonths) * 100));
}

/** The largest annual saving across the plans, for the cycle toggle's label. */
export const bestAnnualSaving = (plans: Plan[]) => plans.reduce((best, p) => Math.max(best, annualSaving(p)), 0);

export interface CompareRow {
  label: string;
  /** One cell per plan, in the plans' order: text, or true/false for a feature. */
  cells: (string | boolean)[];
}

/** The comparison table: every limit, then every feature sold today, per plan. */
export function compareRows(plans: Plan[]): { limits: CompareRow[]; features: CompareRow[] } {
  return {
    limits: LIMIT_KEYS.map((key) => ({ label: LIMIT_LABEL[key], cells: plans.map((p) => limitText(key, limitOf(p.limits, key))) })),
    features: FEATURES.filter((f) => f.enforcement !== 'planned').map((f) => ({ label: f.label, cells: plans.map((p) => p.features.includes(f.key)) })),
  };
}

/** Plans in their display order. */
export const ordered = (plans: Plan[]) => [...plans].sort((a, b) => a.order - b.order);
