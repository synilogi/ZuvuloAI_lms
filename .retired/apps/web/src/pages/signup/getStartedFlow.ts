import type { BillingCycle, Plan } from '@syniastrolms/domain';
import { academySlugFrom, isSignupCode, validateAcademySlug } from '@syniastrolms/domain';

/*
 * Get started (SAAS-026), apart from its markup: the steps, what each form needs before it is sent, and where a
 * new admin goes once their academy exists. The server decides everything that matters — these checks only spare
 * the visitor a round trip.
 */

export type GetStartedStep = 'plan' | 'account' | 'verify';

/** The steps the wizard shows, the last one being the admin workspace's own plan page. */
export const STEPS: { id: GetStartedStep | 'activate'; label: string }[] = [
  { id: 'plan', label: 'Choose a plan' },
  { id: 'account', label: 'Your account' },
  { id: 'verify', label: 'Verify email' },
  { id: 'activate', label: 'Activate' },
];

export interface PlanChoice {
  planId: string;
  cycle: BillingCycle;
}

/** The plan the pricing page sent the visitor with, when it is one on sale on that cycle. */
export function choiceFromQuery(params: URLSearchParams, plans: Plan[]): PlanChoice | null {
  const wanted = params.get('plan');
  if (!wanted) return null;
  const plan = plans.find((p) => p.id === wanted || p.code === wanted.toUpperCase());
  if (!plan) return null;
  const asked = params.get('cycle') === 'annual' ? 'annual' : 'monthly';
  const cycle = plan.cycles.includes(asked) ? asked : plan.cycles[0];
  return cycle ? { planId: plan.id, cycle } : null;
}

export interface AccountForm {
  academyName: string;
  slug: string;
  /** False until the visitor edits the address themselves: until then it follows the name. */
  slugEdited: boolean;
  name: string;
  email: string;
  password: string;
  confirm: string;
  agree: boolean;
}

export const EMPTY_ACCOUNT: AccountForm = { academyName: '', slug: '', slugEdited: false, name: '', email: '', password: '', confirm: '', agree: false };

/** The address that will be used: the edited one, or the one the name gives. */
export const effectiveSlug = (form: AccountForm) => (form.slugEdited ? form.slug.trim().toLowerCase() : academySlugFrom(form.academyName));

/** What is wrong with the account form, by field; empty when it can be sent. */
export function accountIssues(form: AccountForm): Partial<Record<keyof AccountForm, string>> {
  const issues: Partial<Record<keyof AccountForm, string>> = {};
  if (form.academyName.trim().length < 2) issues.academyName = 'Enter your organisation’s name.';
  const slugIssue = validateAcademySlug(effectiveSlug(form));
  if (form.academyName.trim().length >= 2 && slugIssue) issues.slug = slugIssue;
  if (form.name.trim().length < 2) issues.name = 'Enter your full name.';
  if (!/^\S+@\S+\.\S+$/.test(form.email.trim())) issues.email = 'Enter a valid email address.';
  if (form.password.length < 8) issues.password = 'Password must be at least 8 characters.';
  if (!form.confirm || form.confirm !== form.password) issues.confirm = 'Passwords must match.';
  if (!form.agree) issues.agree = 'Agree to the Terms of Service and Privacy Policy to continue.';
  return issues;
}

export const codeIssue = (code: string) => (isSignupCode(code) ? undefined : 'Enter the 6-digit code from the email.');

/** Seconds until a new code may be asked for (0 when it may now). */
export const resendWait = (resendAvailableAt: string, now = Date.now()) => Math.max(0, Math.ceil((Date.parse(resendAvailableAt) - now) / 1000));

/** Where an open registration is remembered in this tab, so a refresh carries on at the code step. Never the code. */
const OPEN_SIGNUP_KEY = 'syniastrolms:open-signup';

export function rememberSignup(signupId: string | null, storage: Pick<Storage, 'setItem' | 'removeItem'> | undefined = safeSession()) {
  try {
    if (signupId) storage?.setItem(OPEN_SIGNUP_KEY, signupId);
    else storage?.removeItem(OPEN_SIGNUP_KEY);
  } catch {
    /* storage unavailable: the registration simply does not survive a refresh */
  }
}

export function rememberedSignup(storage: Pick<Storage, 'getItem'> | undefined = safeSession()): string | null {
  try {
    return storage?.getItem(OPEN_SIGNUP_KEY) ?? null;
  } catch {
    return null;
  }
}

function safeSession(): Storage | undefined {
  try {
    return typeof sessionStorage === 'undefined' ? undefined : sessionStorage;
  } catch {
    return undefined;
  }
}

/** Where the new admin lands: their academy's plan page, with the plan they chose first and marked. */
export function activatePath(choice: PlanChoice | null): string {
  if (!choice) return '/admin/welcome';
  return `/admin/welcome?plan=${encodeURIComponent(choice.planId)}&cycle=${choice.cycle}`;
}
