import type { FieldIssue } from '@/components/forms/Forms';
import type { CourseSaleRow, CourseSalesSettings, GatewayEnvironment } from '@/services/contracts';

/*
 * The pure parts of Settings › Course payments: the academy's own Razorpay keys, which the money for its courses
 * settles to. Nothing here ever holds a stored secret — the API returns flags and a masked key id only — and what the
 * admin types is sent once and dropped.
 */

/** Where the academy's Razorpay webhook points: this app's API address and the path the server gave. */
export const webhookAddress = (apiBase: string, webhookPath: string) => `${apiBase.replace(/\/+$/, '')}${webhookPath.startsWith('/') ? '' : '/'}${webhookPath}`;

export type KeyValues = Record<string, string>;

export const blankKeys = (settings: Pick<CourseSalesSettings, 'fields'>): KeyValues => Object.fromEntries(settings.fields.map((f) => [f.key, '']));

export const keyInputId = (environment: GatewayEnvironment, key: string) => `course-sales-${environment}-${key}`;

/**
 * The checks the API applies, run first so the form answers at once: every field where nothing is stored, a key id of
 * the environment being saved, and two different secrets. The server checks again regardless.
 */
export function keyIssues(settings: Pick<CourseSalesSettings, 'fields' | 'credentials'>, environment: GatewayEnvironment, values: KeyValues): FieldIssue[] {
  const issues: FieldIssue[] = [];
  const stored = settings.credentials[environment].configured;
  const typed = (key: string) => values[key]?.trim() ?? '';
  for (const field of settings.fields) {
    const value = typed(field.key);
    if (!value && !stored) issues.push({ field: keyInputId(environment, field.key), message: `Enter the ${field.label.toLowerCase()}.` });
    else if (value.length > 256) issues.push({ field: keyInputId(environment, field.key), message: `The ${field.label.toLowerCase()} is too long.` });
  }
  const keyId = typed('keyId');
  const prefix = environment === 'live' ? 'rzp_live_' : 'rzp_test_';
  if (keyId && !keyId.startsWith(prefix))
    issues.push({ field: keyInputId(environment, 'keyId'), message: `This isn’t a ${environment} key: Razorpay ${environment} key ids begin with ${prefix}.` });
  if (typed('keySecret') && typed('keySecret') === typed('webhookSecret'))
    issues.push({ field: keyInputId(environment, 'webhookSecret'), message: 'The webhook secret must be different from the key secret.' });
  return issues;
}

/** Only what was typed: a blank field keeps the stored value. */
export function keyPayload(values: KeyValues): { keyId?: string; keySecret?: string; webhookSecret?: string } {
  const out: Record<string, string> = {};
  for (const key of ['keyId', 'keySecret', 'webhookSecret']) {
    const value = values[key]?.trim();
    if (value) out[key] = value;
  }
  return out;
}

/** Why the environment cannot be chosen for new purchases with payments on, or null. */
export function environmentBlocker(settings: Pick<CourseSalesSettings, 'credentials'>, environment: GatewayEnvironment, enabled: boolean): string | null {
  if (enabled && !settings.credentials[environment].configured) return `Save your ${environment} keys before taking payments in ${environment} mode.`;
  return null;
}

export const SALE_STATUS: Record<CourseSaleRow['status'], { label: string; tone: 'accent' | 'info' | 'danger' | 'neutral' }> = {
  paid: { label: 'Paid', tone: 'accent' },
  created: { label: 'Awaiting payment', tone: 'info' },
  failed: { label: 'Payment failed', tone: 'danger' },
  expired: { label: 'Not completed', tone: 'neutral' },
};

/** How many sales need the academy's attention: money that arrived and opened nothing. */
export const needsReviewCount = (rows: CourseSaleRow[]) => rows.filter((r) => r.reviewReason).length;
