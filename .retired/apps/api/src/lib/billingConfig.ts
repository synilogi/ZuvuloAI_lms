/*
 * Billing configuration: the platform's terms that are not a plan's (subscriptions.md §7, §8). Read
 * from the environment on every use, never baked into code, and documented in apps/api/.env.example and
 * docs/10-DEPLOYMENT.md.
 */

/** Billing is configured wrongly or not at all. Not an ApiError: a request never causes it, and it is logged as a fault. */
export class BillingConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'BillingConfigError';
  }
}

/**
 * How many days of access an overdue academy keeps once payment retries are exhausted
 * (`SUBSCRIPTION_GRACE_DAYS`, 0–90). There is no default: until it is set, a grace period cannot start,
 * so an overdue academy simply keeps its access (§8 — a failed payment does not destroy access unless
 * a rule says so). Set it before switching entitlement enforcement on.
 */
export function graceDays(env: NodeJS.ProcessEnv = process.env): number {
  const raw = env.SUBSCRIPTION_GRACE_DAYS;
  if (raw === undefined || raw.trim() === '') throw new BillingConfigError('SUBSCRIPTION_GRACE_DAYS is not set, so no grace period can start.');
  const days = Number(raw);
  if (!Number.isInteger(days) || days < 0 || days > 90) throw new BillingConfigError('SUBSCRIPTION_GRACE_DAYS must be a whole number of days from 0 to 90.');
  return days;
}

/**
 * How many days an overdue academy has to pay before payment retries count as exhausted and the grace
 * period starts (`SUBSCRIPTION_RETRY_DAYS`, 1–30; §8, §44). There is no default, as for the grace period:
 * until it is set, retries never run out, and an overdue academy stays past due with its access.
 */
export function retryDays(env: NodeJS.ProcessEnv = process.env): number | null {
  const raw = env.SUBSCRIPTION_RETRY_DAYS;
  if (raw === undefined || raw.trim() === '') return null;
  const days = Number(raw);
  if (!Number.isInteger(days) || days < 1 || days > 30) throw new BillingConfigError('SUBSCRIPTION_RETRY_DAYS must be a whole number of days from 1 to 30.');
  return days;
}

/**
 * How many days before a period ends its renewal invoice is issued (`SUBSCRIPTION_INVOICE_LEAD_DAYS`, 0–31,
 * default 7), so the academy can pay before the boundary. A default is safe here: it moves no money and
 * changes no access, only when an invoice appears.
 */
export function invoiceLeadDays(env: NodeJS.ProcessEnv = process.env): number {
  const raw = env.SUBSCRIPTION_INVOICE_LEAD_DAYS;
  if (raw === undefined || raw.trim() === '') return 7;
  const days = Number(raw);
  if (!Number.isInteger(days) || days < 0 || days > 31)
    throw new BillingConfigError('SUBSCRIPTION_INVOICE_LEAD_DAYS must be a whole number of days from 0 to 31.');
  return days;
}

/** Whether a grace period can start: `SUBSCRIPTION_GRACE_DAYS` is set and valid. */
export function graceConfigured(env: NodeJS.ProcessEnv = process.env): boolean {
  try {
    graceDays(env);
    return true;
  } catch {
    return false;
  }
}

/**
 * Whether an academy may start a free trial after it has had one (`SUBSCRIPTION_REPEAT_TRIALS=on`).
 * Off unless set: repeated trials are prevented unless the platform explicitly allows them (§7).
 */
export const repeatTrialsAllowed = (env: NodeJS.ProcessEnv = process.env): boolean => env.SUBSCRIPTION_REPEAT_TRIALS === 'on';

/**
 * Checked at start-up. Any term that is set must be valid, and with enforcement on, the overdue terms must be
 * set: enforcement without them would leave an academy that never pays past due, with its access, for ever.
 * Fails loudly at start-up rather than quietly at the first overdue academy.
 */
export function assertBillingConfig(env: NodeJS.ProcessEnv = process.env) {
  const set = (key: string) => Boolean(env[key]?.trim());
  if (set('SUBSCRIPTION_GRACE_DAYS')) graceDays(env);
  retryDays(env);
  invoiceLeadDays(env);
  // Enforced explicitly, or by default in production (\`entitlementEnforcement\`).
  if (env.ENTITLEMENT_ENFORCEMENT === 'on' || (env.ENTITLEMENT_ENFORCEMENT !== 'off' && env.NODE_ENV === 'production')) {
    const missing = ['SUBSCRIPTION_RETRY_DAYS', 'SUBSCRIPTION_GRACE_DAYS'].filter((k) => !set(k));
    if (missing.length)
      throw new BillingConfigError(
        `Plan enforcement needs ${missing.join(' and ')}: without ${missing.length === 1 ? 'it' : 'them'} an LMS that never pays keeps its access for ever.`,
      );
  }
}
