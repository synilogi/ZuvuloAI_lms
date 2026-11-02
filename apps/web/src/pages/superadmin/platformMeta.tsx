import type { ReactNode } from 'react';
import { useSearchParams } from 'react-router-dom';
import { ShieldStar } from '@phosphor-icons/react';
import { formatMoney, type Role } from '@syniastrolms/domain';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import type { FieldIssue } from '@/components/forms/Forms';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import type { AdminUpdate, PlatformAuditEntry, PlatformPermissionGroup, PlatformUserRow } from '@/services';
import styles from './Platform.module.css';

/** The eyebrow every platform page carries, so the area is never mistaken for the academy admin. */
export const PLATFORM_EYEBROW = (
  <>
    <ShieldStar size={13} weight="fill" aria-hidden="true" /> Platform
  </>
);

export const ROLE_LABEL: Record<Role, string> = { student: 'Student', instructor: 'Instructor', admin: 'Admin', superadmin: 'Platform owner' };

const ROLE_TONE: Record<Role, 'neutral' | 'info' | 'accent' | 'warn'> = { student: 'neutral', instructor: 'info', admin: 'accent', superadmin: 'warn' };

/** A role as a badge. An unknown value from the database is shown as it is rather than hidden. */
export function RoleBadge({ role }: { role: Role }) {
  return (
    <Badge size="sm" tone={ROLE_TONE[role] ?? 'neutral'}>
      {ROLE_LABEL[role] ?? role}
    </Badge>
  );
}

/** One page of a platform directory. The API caps `pageSize` at 500; this is what the screens ask for. */
export const PAGE_SIZE = 20;

/** The `page` in the URL. Anything that is not a page number — junk, zero, a negative — reads as the first. */
export const pageParam = (params: URLSearchParams) => Math.max(1, Number(params.get('page') ?? 1) || 1);

/** The current page and the way to move between them, for a platform list whose only filter is the page. */
export function usePageParam(): [number, (next: number) => void] {
  const [params, setParams] = useSearchParams();
  const goToPage = (next: number) => {
    const p = new URLSearchParams(params);
    if (next <= 1) p.delete('page');
    else p.set('page', String(next));
    setParams(p, { replace: true });
  };
  return [pageParam(params), goToPage];
}

/** Pages of `total` rows at `pageSize`, never fewer than one so the pager has something to show. */
export const pageCount = (total: number, pageSize: number) => Math.max(1, Math.ceil(total / Math.max(1, pageSize)));

/** "1–20 of 84" — the line beside the pager. */
export function rangeSummary(total: number, page: number, pageSize: number): string {
  if (total === 0) return 'No results';
  const first = (page - 1) * pageSize + 1;
  const last = Math.min(total, page * pageSize);
  return `${first.toLocaleString('en-IN')}–${last.toLocaleString('en-IN')} of ${total.toLocaleString('en-IN')}`;
}

const UNITS = ['B', 'KB', 'MB', 'GB', 'TB'];

/** Storage sizes for people: 0 B, 512 B, 1.4 MB, 2.1 GB. */
export function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return '0 B';
  const exponent = Math.min(UNITS.length - 1, Math.floor(Math.log(bytes) / Math.log(1024)));
  const value = bytes / 1024 ** exponent;
  return `${exponent === 0 ? Math.round(value) : value.toFixed(value < 10 ? 1 : 0)} ${UNITS[exponent]}`;
}

/** "3d 4h", "4h 12m", "12m", "48s" — how long the process has been up. */
export function formatUptime(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds < 0) return '—';
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (d) return `${d}d ${h}h`;
  if (h) return `${h}h ${m}m`;
  if (m) return `${m}m`;
  return `${Math.floor(seconds)}s`;
}

/**
 * An audit event's metadata as label/value pairs. The column is free-shaped, so anything that is not
 * a string, number or boolean is printed as JSON rather than as "[object Object]", and nothing is
 * rendered as markup.
 */
export function auditDetails(entry: PlatformAuditEntry): { label: string; value: string }[] {
  return Object.entries(entry.meta ?? {}).map(([label, value]) => ({
    label,
    value: value === null || value === undefined ? '—' : typeof value === 'object' ? JSON.stringify(value) : String(value),
  }));
}

/** What the actions the platform records mean, in everyday words. An action not listed falls back to `actionLabel`. */
const ACTION_WORDS: Record<string, string> = {
  'academy.created': 'New Admin added',
  'academy.self_registered': 'Admin signed up on the website',
  'academy.updated': 'Workspace details changed',
  'academy.suspended': 'Workspace access paused',
  'academy.archived': 'Workspace closed',
  'academy.reactivated': 'Workspace reactivated',
  'course.review.created': 'Course review written',
  'course.review.updated': 'Course review edited',
  'course.review.hidden': 'Course review hidden',
  'course.review.shown': 'Course review shown again',
  'notification.broadcast.started': 'Notification broadcast started',
  'notification.broadcast.sent': 'Notification broadcast sent',
  'admin.created': 'Admin login added',
  'admin.updated': 'Admin login changed',
  'admin.deactivated': 'Admin login turned off',
  'admin.reactivated': 'Admin login turned back on',
  'account.deleted': 'Account deleted',
  'branding.updated': 'Logo or icon changed',
  'branding.restored': 'Default logo restored',
  'billing.profile_updated': 'Billing address changed',
  'subscription.created': 'Subscription started',
  'subscription.plan_change_requested': 'Plan change requested',
  'entitlement.changed': 'Plan features changed',
  'invoice.created': 'Invoice created',
  'payment.succeeded': 'Payment received',
  'payment.recorded_offline': 'Payment recorded by hand',
  'payment.refunded': 'Payment refunded',
  'payment.refund_requested': 'Refund requested',
  'tax.rule_set': 'Tax rule added',
  'tax.rule_retired': 'Tax rule stopped',
  'inquiry.created': 'New inbox request',
  'inquiry.updated': 'Inbox request updated',
  'learner.created': 'Student added',
  'invitation.created': 'Invitation sent',
  'invitation.revoked': 'Invitation cancelled',
  'instructor.request.approved': 'Instructor request approved',
  'instructor.request.rejected': 'Instructor request turned down',
  'mlm.affiliate.enrolled': 'Affiliate joined the program',
  'mlm.affiliate.activated': 'Affiliate activated by a purchase',
  'mlm.affiliate.preferred_leg_changed': 'Affiliate changed their preferred leg',
  'mlm.affiliate.status_changed': 'Affiliate status changed',
  'mlm.placement.manual': 'Affiliate moved by hand',
  'mlm.sponsor.changed': 'Affiliate sponsor changed',
  'mlm.order.reversed': 'Affiliate order reversed',
  'mlm.carry.adjusted': 'Carry-forward corrected',
  'mlm.matching.run': 'Matching run started by hand',
  'mlm.commission.held': 'Commission put on hold',
  'mlm.commission.released': 'Commission released',
  'mlm.commission.written_off': 'Commission written off',
  'mlm.rank.recalculated': 'Rank checked by hand',
  'mlm.reward.approved': 'Reward approved',
  'mlm.reward.funded': 'Reward funded',
  'mlm.reward.paid': 'Reward paid',
  'mlm.reward.rejected': 'Reward rejected',
  'mlm.wallet.adjusted': 'Wallet corrected',
  'mlm.kyc.submitted': 'Identity details submitted',
  'mlm.kyc.verified': 'Identity verified',
  'mlm.kyc.rejected': 'Identity details sent back',
  'mlm.kyc.document_read': 'Identity document opened',
  'mlm.withdrawal.requested': 'Withdrawal requested',
  'mlm.withdrawal.cancelled': 'Withdrawal cancelled',
  'mlm.withdrawal.approved': 'Withdrawal approved',
  'mlm.withdrawal.rejected': 'Withdrawal rejected',
  'mlm.withdrawal.paid': 'Withdrawal paid',
  'mlm.payout.created': 'Payout batch created',
  'mlm.payout.exported': 'Bank file exported',
  'mlm.payout.closed': 'Payout batch closed',
  'mlm.plan.created': 'Affiliate plan draft created',
  'mlm.plan.updated': 'Affiliate plan draft changed',
  'mlm.plan.activated': 'Affiliate plan activated',
  'mlm.plan.retired': 'Affiliate plan retired',
  'mlm.plan.courses_changed': 'Affiliate plan courses changed',
};

const PREFIX_WORDS: Record<string, string> = { 'mlm.': 'Affiliate program' };

/** What a `?prefix=` filter on the activity log covers, in words; an unknown one is shown as it is, never hidden. */
export const auditPrefixLabel = (prefix: string): string => PREFIX_WORDS[prefix] ?? prefix;

/** An action as a person would say it: "LMS access paused" for `academy.suspended`. */
export const describeAction = (action: string): string => ACTION_WORDS[action] ?? actionLabel(action);

const TARGET_WORDS: Record<string, string> = {
  academy: 'Workspace',
  tenant: 'Workspace',
  admin: 'Admin login',
  user: 'Account',
  subscription: 'Subscription',
  invoice: 'Invoice',
  payment: 'Payment',
  plan: 'Plan',
  tax_rule: 'Tax rule',
  inquiry: 'Inbox request',
  branding: 'Branding',
  mlm_plan: 'Affiliate plan',
  affiliate: 'Affiliate',
  mlm_order: 'Affiliate order',
  mlm_matching: 'Matching run',
  mlm_commission: 'Commission',
  mlm_reward: 'Reward',
  mlm_wallet: 'Wallet',
  mlm_kyc: 'Identity check',
  mlm_withdrawal: 'Withdrawal',
  mlm_payout: 'Payout batch',
  student: 'Student',
  instructor: 'Instructor',
};

/** What kind of thing was changed, in words: "LMS" for `academy`. An unknown kind is tidied, never hidden. */
export const targetLabel = (type: string): string => TARGET_WORDS[type] ?? actionLabel(type);

/** Who did it: the platform owner, an Admin, or an automatic job. */
export const actorRoleLabel = (role: string): string => (role === 'system' ? 'Automatic' : (ROLE_LABEL[role as Role] ?? actionLabel(role)));

const DETAIL_WORDS: Record<string, string> = {
  tenantId: 'Workspace',
  subscriptionId: 'Subscription',
  planCode: 'Plan',
  planVersion: 'Plan version',
  from: 'From',
  to: 'To',
  cvChange: 'Change',
};

/** The figures in a carry-forward correction are CV in minor units, not money. */
const CV_DETAILS = new Set(['cvChange', 'before', 'after']);
const cvFigure = (minor: number): string => `${(minor / 100).toLocaleString('en-IN')} CV`;

/** `planVersion` → "Plan version", `billing_cycle` → "Billing cycle". */
const humanKey = (key: string): string => DETAIL_WORDS[key] ?? actionLabel(key.replace(/([a-z])([A-Z])/g, '$1 $2').toLowerCase());

/** An LMS's status as the Access panel names it. */
const ACADEMY_STATUS_WORDS: Record<string, string> = { active: 'Open', suspended: 'Paused', archived: 'Closed' };

function humanValue(value: unknown, words: Record<string, string> = {}): string {
  if (value === null || value === undefined || value === '') return '—';
  if (typeof value === 'string' && words[value]) return words[value];
  if (typeof value === 'boolean') return value ? 'Yes' : 'No';
  if (typeof value === 'number') return value.toLocaleString('en-IN');
  if (Array.isArray(value)) return value.length ? value.map((v) => humanValue(v, words)).join(', ') : '—';
  if (typeof value === 'object') {
    const record = value as Record<string, unknown>;
    // A change recorded as { from, to } reads as "Off → On".
    if ('from' in record && 'to' in record) return `${humanValue(record.from, words)} → ${humanValue(record.to, words)}`;
    const parts = Object.entries(record).map(([k, v]) => `${humanKey(k)}: ${humanValue(v, words)}`);
    return parts.length ? parts.join('; ') : '—';
  }
  return String(value);
}

/**
 * An audit event's metadata for people to read: plain labels, Yes/No instead of true/false, "from → to" for a change,
 * an `amount` (stored in minor units) shown as money, and record ids left out. `auditDetails` keeps the exact values;
 * this is only for display.
 */
export function readableAuditDetails(entry: PlatformAuditEntry): { label: string; value: string }[] {
  const meta = entry.meta ?? {};
  const currency = typeof meta.currency === 'string' ? meta.currency : 'INR';
  // An LMS's own status change reads as the Access panel says it: "Paused → Open", not "suspended → active".
  const words = entry.action.startsWith('academy.') ? ACADEMY_STATUS_WORDS : {};
  if (entry.action.startsWith('academy.') && typeof meta.from === 'string' && typeof meta.to === 'string') {
    const { from, to, ...rest } = meta;
    return [{ label: 'Change', value: `${humanValue(from, words)} → ${humanValue(to, words)}` }, ...readableAuditDetails({ ...entry, action: '', meta: rest })];
  }
  // Record ids (`tenantId`, `subscriptionId`, …) mean nothing to a reader; the row keeps its target's id on hover.
  return Object.entries(meta)
    .filter(([key]) => key !== 'currency' && !/Id$/.test(key))
    .map(([key, value]) => ({
      label: humanKey(key),
      value:
        key === 'amount' && typeof value === 'number'
          ? formatMoney(value, currency)
          : entry.action === 'mlm.carry.adjusted' && CV_DETAILS.has(key) && typeof value === 'number'
            ? cvFigure(value)
            : humanValue(value, words),
    }));
}

/** Turns `admin.created` into "Admin created", leaving an unfamiliar shape alone. */
export function actionLabel(action: string): string {
  const words = action.replace(/[._-]/g, ' ').trim();
  return words ? words[0].toUpperCase() + words.slice(1) : action;
}

/* ─── Admin management ─── */

/** Whether an admin account is open. Only admins carry a `deactivatedAt`, so everyone else reads active. */
export const isActive = (row: Pick<PlatformUserRow, 'deactivatedAt'>) => !row.deactivatedAt;

/** What the create and edit dialogs hold. There is no role here, because a role is not the UI's to set. */
export interface AdminForm {
  name: string;
  email: string;
  password: string;
  confirm: string;
}

export const emptyAdminForm = (): AdminForm => ({ name: '', email: '', password: '', confirm: '' });

/**
 * The same checks the API applies, run early so the dialog can answer without a round trip. The
 * server validates again regardless — this only saves the person a failed request.
 */
export function adminFormIssues(form: AdminForm, mode: 'create' | 'edit'): FieldIssue[] {
  const issues: FieldIssue[] = [];
  if (form.name.trim().length < 2) issues.push({ field: 'admin-name', message: 'Enter the admin’s full name.' });
  if (!/\S+@\S+\.\S+/.test(form.email.trim())) issues.push({ field: 'admin-email', message: 'Enter a valid email address.' });
  if (mode === 'create') {
    if (form.password.length < 8) issues.push({ field: 'admin-password', message: 'The password must be at least 8 characters.' });
    else if (form.confirm !== form.password) issues.push({ field: 'admin-confirm', message: 'Both passwords must match.' });
  }
  return issues;
}

/** Only what actually changed, so an untouched dialog sends nothing and the API records no event. */
export function adminChanges(form: AdminForm, original: PlatformUserRow): AdminUpdate {
  const name = form.name.trim();
  const email = form.email.trim().toLowerCase();
  return { ...(name && name !== original.name ? { name } : {}), ...(email && email !== original.email ? { email } : {}) };
}

/** How many of a group's permissions an admin holds — the "3 of 5" beside a group heading. */
export const grantedInGroup = (group: PlatformPermissionGroup) => group.permissions.filter((p) => p.granted).length;

/** One figure. `hint` carries the breakdown under it, never a second unexplained number. */
export function StatCard({ label, value, hint }: { label: string; value: ReactNode; hint?: ReactNode }) {
  return (
    <div className={styles.stat}>
      <dt className={styles.statLabel}>{label}</dt>
      <dd className={styles.statValue}>{value}</dd>
      {hint && <p className={styles.statHint}>{hint}</p>}
    </div>
  );
}

export function StatGroup({ label, children }: { label: string; children: ReactNode }) {
  return (
    <section className={styles.group} aria-label={label}>
      <h2 className={styles.groupTitle}>{label}</h2>
      <dl className={styles.stats}>{children}</dl>
    </section>
  );
}

/**
 * What a failed platform call looks like. A 401 never reaches here — the client clears the token and
 * the session drops to signed-out — so this is a lost connection, a refusal, or a server fault, and
 * every one of them offers the same way forward: try again.
 */
export function PlatformError({ title, error, onRetry }: { title: string; error?: Error; onRetry: () => void }) {
  return (
    <StateMessage kind="error" title={title} actions={<Button onClick={onRetry}>Try again</Button>}>
      {error?.message ?? 'The platform API could not be reached.'}
    </StateMessage>
  );
}
