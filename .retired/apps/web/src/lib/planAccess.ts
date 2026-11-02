import type { AcademyPlan, FeatureKey, LimitKey, Plan, PlanAccess, TenantBilling, WorkspaceModule } from '@syniastrolms/domain';
import { FEATURES, LIMIT_LABEL, MODULE_FEATURE } from '@syniastrolms/domain';
import { BILLING_PAGE, trialLine } from './billingStates';

/*
 * The words and figures the plan-aware workspace shows: what each module is called, why an action is not
 * available, which plans include a feature, and how much of a limit is left. One place, so the sidebar, the gated
 * pages, the create buttons and the dashboard never word the same thing two ways.
 */

/** Where an academy that has never had a plan chooses its first one. */
export const WELCOME_PAGE = '/admin/welcome';

/**
 * The academy has never had a plan it can keep anything from: it has never subscribed, or it is restricted with
 * nothing kept. Such an academy is offered its first plan — forced to choose one only where plans are enforced
 * (`needsPlanChoice`), offered it beside the dashboard where they are not.
 */
export const hasNoPlanYet = (plan: Pick<AcademyPlan, 'status' | 'restricted' | 'lastFeatures'>) =>
  plan.status === null || (plan.restricted && plan.lastFeatures.length === 0);

/** What each plan-gated module is called on screen — the sidebar's own labels. */
export const MODULE_LABEL: Record<WorkspaceModule, string> = {
  courses: 'Courses',
  quizzes: 'Quizzes',
  assignments: 'Assignments',
  certificates: 'Certificates',
  live: 'Live classes',
  reports: 'Reports',
  branding: 'Custom branding',
};

/** The module's name inside a sentence: "nothing new can be added to quizzes". */
export const MODULE_NOUN: Record<WorkspaceModule, string> = {
  courses: 'courses',
  quizzes: 'quizzes',
  assignments: 'assignments',
  certificates: 'certificates',
  live: 'live classes',
  reports: 'reports',
  branding: 'the LMS’s branding',
};

export const featureMeta = (key: FeatureKey) => FEATURES.find((f) => f.key === key)!;

/** The feature a gated area is sold under, with its catalogue label and description. */
export function gateFeature(module?: WorkspaceModule, feature?: FeatureKey) {
  const key = feature ?? MODULE_FEATURE[module ?? 'courses'];
  const meta = featureMeta(key);
  return { key, title: feature ? meta.label : MODULE_LABEL[module!], description: meta.description };
}

/** The plans on sale that include `feature`, cheapest first, as they are ordered for sale. */
export const plansWith = (plans: Plan[], feature: FeatureKey) =>
  plans.filter((p) => p.status === 'active' && p.features.includes(feature)).sort((a, b) => a.order - b.order);

/** "Courses are", "Custom branding is" — the verb a module's name takes. */
export const isOrAre = (title: string) => (/s$/i.test(title) ? 'are' : 'is');

/** Why an action in a module is not available, in one sentence — for a disabled button's title and its screen-reader text. */
export function blockedReason(access: PlanAccess, module: WorkspaceModule): string | null {
  if (access === 'read-only') return `Your plan has ended, so nothing new can be added to ${MODULE_NOUN[module]}. Renew to add more.`;
  if (access === 'locked') return `${MODULE_LABEL[module]} ${isOrAre(MODULE_LABEL[module])} not included in your plan.`;
  return null;
}

/** Where a limit stands: what the plan allows, what is used, what is left. Null when there is no ceiling to show. */
export interface Capacity {
  limit: LimitKey;
  label: string;
  used: number;
  allowed: number;
  remaining: number;
  reached: boolean;
}

/**
 * How much of a limit is left, from the academy's billing summary. Only when plans are enforced and the plan sets
 * a ceiling — an unlimited plan, or a platform that does not enforce plans yet, has nothing to count down.
 */
export function capacityOf(billing: Pick<TenantBilling, 'usage' | 'enforced'> | undefined, limit: LimitKey): Capacity | null {
  if (!billing?.enforced) return null;
  const line = billing.usage.find((u) => u.limit === limit);
  if (!line || line.allowed === null) return null;
  const remaining = Math.max(0, line.allowed - line.used);
  return { limit, label: LIMIT_LABEL[limit], used: line.used, allowed: line.allowed, remaining, reached: remaining === 0 };
}

/** "3 of 10 left" beside a create button; at the limit, what was reached. */
export function capacityText(capacity: Capacity): string {
  const noun = capacity.label.toLowerCase();
  if (capacity.reached) return `All ${capacity.allowed} ${noun} in your plan are used`;
  return `${capacity.remaining} of ${capacity.allowed} ${noun} left`;
}

/** The sentence a disabled create button gives at its limit. */
export const limitReason = (capacity: Capacity) =>
  `Your plan allows ${capacity.allowed} ${capacity.label.toLowerCase()}, and all of them are in use. Upgrade, or free one up, to add another.`;

export { BILLING_PAGE, trialLine };
