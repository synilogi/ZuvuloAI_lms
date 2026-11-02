import { SUBSCRIPTION_STATUS_OF, academySlugFrom, validateAcademySlug, type AcademyStatus } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';
import type { FieldIssue } from '@/components/forms/Forms';
import { Badge } from '@/components/ui/Badge/Badge';
import { formatShortDate } from '@/lib/format';
import type { AcademyInput, PlatformAcademy } from '@/services';
import { SUBSCRIPTION_STATE } from '../subscriptions/subscriptionMeta';

/** Every academy screen lives under one root. */
export const ACADEMIES_BASE = '/superadmin/academies';
export const NEW_ACADEMY_PATH = `${ACADEMIES_BASE}/new`;

/* ─── Status and plan ─── */

const ACADEMY_STATUS: Record<AcademyStatus, { label: string; tone: Tone }> = {
  active: { label: 'Active', tone: 'accent' },
  suspended: { label: 'Suspended', tone: 'warn' },
  archived: { label: 'Archived', tone: 'neutral' },
};

export function AcademyStatusBadge({ status }: { status: AcademyStatus }) {
  const meta = ACADEMY_STATUS[status] ?? { label: status, tone: 'neutral' as Tone };
  return (
    <Badge size="sm" tone={meta.tone} dot>
      {meta.label}
    </Badge>
  );
}

/**
 * One line for an academy's plan: "Growth · Free trial · ends 17 Oct", "Growth · Active", "No plan". The latest
 * subscription is the one shown — live, or the last to end.
 */
export function planSummary(subscription: PlatformAcademy['subscription']): { label: string; tone: Tone } {
  if (!subscription) return { label: 'No plan', tone: 'neutral' };
  const status = SUBSCRIPTION_STATUS_OF[subscription.status] ?? 'active';
  const state = SUBSCRIPTION_STATE[status];
  const plan = subscription.plan.name;
  if (status === 'trial')
    return { label: `${plan} · Free trial · ends ${formatShortDate(subscription.trialEndAt ?? subscription.currentPeriodEndAt)}`, tone: state.tone };
  if (status === 'canceling') return { label: `${plan} · Ends ${formatShortDate(subscription.currentPeriodEndAt)}`, tone: state.tone };
  return { label: `${plan} · ${state.label}`, tone: state.tone };
}

export function PlanSummaryBadge({ subscription }: { subscription: PlatformAcademy['subscription'] }) {
  const { label, tone } = planSummary(subscription);
  return (
    <Badge size="sm" tone={tone}>
      {label}
    </Badge>
  );
}

/* ─── The new-academy form ─── */

export interface AcademyForm {
  name: string;
  slug: string;
  /** Whether the address was typed, rather than suggested from the name. A typed one is left alone. */
  slugEdited: boolean;
  adminName: string;
  adminEmail: string;
  password: string;
}

export const emptyAcademyForm = (): AcademyForm => ({ name: '', slug: '', slugEdited: false, adminName: '', adminEmail: '', password: '' });

/** The form after the academy's name changes: the address follows the name until it is typed itself. */
export const withName = (form: AcademyForm, name: string): AcademyForm => ({ ...form, name, slug: form.slugEdited ? form.slug : academySlugFrom(name) });

/** The form after the address is typed: lowercased as it is typed, and no longer suggested from the name. */
export const withSlug = (form: AcademyForm, slug: string): AcademyForm => ({ ...form, slug: slug.toLowerCase().replace(/\s+/g, '-'), slugEdited: true });

/**
 * The checks `POST /superadmin/tenants` applies, run before sending so the dialog can answer at once — the address
 * by the very rule the server uses (`validateAcademySlug`). The server checks again, and alone knows what is taken.
 */
export function academyFormIssues(form: AcademyForm): FieldIssue[] {
  const issues: FieldIssue[] = [];
  if (form.name.trim().length < 2) issues.push({ field: 'academy-name', message: 'Give the LMS a name.' });
  const slugIssue = validateAcademySlug(form.slug.trim());
  if (slugIssue) issues.push({ field: 'academy-slug', message: form.slug.trim() ? slugIssue : 'Choose the LMS address.' });
  if (form.adminName.trim().length < 2) issues.push({ field: 'academy-admin-name', message: 'Enter the admin’s full name.' });
  if (!/^\S+@\S+\.\S+$/.test(form.adminEmail.trim())) issues.push({ field: 'academy-admin-email', message: 'Enter a valid email address.' });
  if (form.password.length < 8) issues.push({ field: 'academy-admin-password', message: 'The password must be at least 8 characters.' });
  return issues;
}

export const academyInput = (form: AcademyForm): AcademyInput => ({
  name: form.name.trim(),
  slug: form.slug.trim(),
  admin: { name: form.adminName.trim(), email: form.adminEmail.trim(), password: form.password },
});

/** Which field a refusal from the server is about, from its words, so it is shown where it belongs. */
export function serverIssueField(message: string): string {
  if (/address|slug/i.test(message)) return 'academy-slug';
  if (/email|account/i.test(message)) return 'academy-admin-email';
  if (/password/i.test(message)) return 'academy-admin-password';
  if (/admin.{0,4}s full name/i.test(message)) return 'academy-admin-name';
  return 'academy-name';
}

/* ─── Sign-in details ─── */

/** What the super admin hands the new academy's admin. The password is in it only while it is known — right after creation. */
export function signInDetails({ academy, email, password, loginUrl }: { academy: string; email: string; password?: string; loginUrl: string }): string {
  return [`LMS: ${academy}`, `Sign in at: ${loginUrl}`, `Email: ${email}`, ...(password ? [`Password: ${password}`] : [])].join('\n');
}

/** Where an academy's people sign in. */
export const loginUrl = () => (typeof window !== 'undefined' && window.location ? `${window.location.origin}/login` : '/login');
