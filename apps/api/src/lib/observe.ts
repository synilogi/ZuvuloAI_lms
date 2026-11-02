/*
 * Operational signals (subscriptions.md §48; SAAS-014): the things an operator must be able to see go
 * wrong — payment, refund and webhook failures, job failures, subscription state changes, entitlement
 * refusals and limit violations, and unexpected server faults.
 *
 * Every signal is one structured JSON line on the server's log, and the warnings and errors among them
 * are also kept in a small in-process window the Super Admin reads (`GET /superadmin/observability`).
 * The audit trail (`lib/audit.ts`) records what changed and who changed it; this records what an operator
 * needs to act on. Neither replaces the other.
 *
 * Nothing leaves here unredacted. `redact` runs over every field before it is written anywhere: values
 * under a sensitive key (password, token, secret, signature, authorization, card number, CVV…) are
 * replaced whole, and any string that looks like a card number, a JWT, a bearer credential or a provider
 * key is masked wherever it appears — so a provider's error message that quotes one is still safe to log.
 * Payment secrets, webhook secrets, raw card data, passwords and tokens are never logged (§48).
 */

export const SIGNALS = [
  'payment.failed',
  'payment.unmatched',
  'refund.failed',
  'webhook.failed',
  'job.failed',
  'subscription.state_changed',
  'entitlement.denied',
  'limit.reached',
  'request.failed',
  // Course sales (an academy selling its courses to its learners): a purchase paid, and the academy's sales settings.
  'course_purchase.paid',
  'course_purchase.refunded',
  'course_sales.changed',
  // The affiliate program (MLM-002 …): a manual placement by the Super Admin.
  'mlm.placement.manual',
  // An eligible course sale recorded for the program, and a reversal of one (MLM-003).
  'mlm.order.recorded',
  'mlm.reversal',
  // Earnings (MLM-004 to MLM-007): a run that failed for one member, a hold under the ceiling, a balance that disagrees with its ledger.
  'mlm.commission.failed',
  'mlm.ceiling.hold',
  'mlm.wallet.mismatch',
  'mlm.job.behind',
] as const;

export type Signal = (typeof SIGNALS)[number];

export type SignalLevel = 'info' | 'warn' | 'error';

export interface Observation {
  signal: Signal;
  level: SignalLevel;
  at: string;
  fields: Record<string, unknown>;
}

/** The level a signal is reported at unless the caller says otherwise. */
const DEFAULT_LEVEL: Record<Signal, SignalLevel> = {
  'payment.failed': 'warn',
  'payment.unmatched': 'warn',
  'refund.failed': 'warn',
  'webhook.failed': 'error',
  'job.failed': 'error',
  'subscription.state_changed': 'info',
  'entitlement.denied': 'info',
  'limit.reached': 'info',
  'request.failed': 'error',
  'course_purchase.paid': 'info',
  'course_purchase.refunded': 'warn',
  'course_sales.changed': 'info',
  'mlm.placement.manual': 'info',
  'mlm.order.recorded': 'info',
  'mlm.reversal': 'warn',
  'mlm.commission.failed': 'error',
  'mlm.ceiling.hold': 'warn',
  'mlm.wallet.mismatch': 'error',
  'mlm.job.behind': 'warn',
};

/* ─── Redaction ────────────────────────────────────────────────────────── */

export const REDACTED = '[redacted]';

/** A key whose value is never written, whatever it holds. */
const SENSITIVE_KEY =
  /pass(word|wd|phrase)?$|password|secret|token|authori[sz]ation|cookie|api[-_]?key|private[-_]?key|signature|card[-_]?number|^pan$|^cvv|^cvc|^otp$|^pin$|credential|hash$/i;

/** Patterns masked wherever they appear inside a string. Order matters: the most specific first. */
const SENSITIVE_TEXT: [RegExp, string][] = [
  // A JSON Web Token: three base64url segments, the first a JSON header.
  [/eyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}/g, '[redacted-token]'],
  // A bearer or basic credential in a header value.
  [/\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]{8,}/gi, '$1 [redacted]'],
  // Provider keys and webhook secrets: Stripe (sk_/rk_/pk_/whsec_), Razorpay (rzp_…).
  [/\b(?:sk|rk|pk)_(?:live|test)_[A-Za-z0-9]{8,}/g, '[redacted-key]'],
  [/\bwhsec_[A-Za-z0-9]{8,}/g, '[redacted-key]'],
  [/\brzp_(?:live|test)_[A-Za-z0-9]{8,}/g, '[redacted-key]'],
  // A one-time token in a URL: reset and invite links, `?token=…`.
  [/([?&](?:token|code|key|signature|sig)=)[^&\s"']+/gi, '$1[redacted]'],
  [/(\/(?:reset-password|invite|accept-invite|verify-email)\/)[A-Za-z0-9._~-]{12,}/gi, '$1[redacted]'],
  // A secret written out as `name=value` or `name: value` in free text, e.g. an error that quotes its config.
  [/((?:password|passwd|secret|api[-_]?key|token)["']?\s*[=:]\s*["']?)[^\s&,;"']+/gi, '$1[redacted]'],
  // A card number: 13–19 digits, optionally grouped by spaces or dashes.
  [/\b\d(?:[ -]?\d){12,18}\b/g, '[redacted-card]'],
];

export function redactText(text: string): string {
  let out = text;
  for (const [pattern, replacement] of SENSITIVE_TEXT) out = out.replace(pattern, replacement);
  return out;
}

/** A deep copy of `value` that is safe to log: sensitive keys dropped to `[redacted]`, sensitive text masked. */
export function redact(value: unknown, depth = 0): unknown {
  if (depth > 6) return '[truncated]';
  if (typeof value === 'string') return redactText(value);
  if (value === null || typeof value !== 'object') return value;
  if (value instanceof Date) return value.toISOString();
  if (value instanceof Error) return describeError(value);
  if (Array.isArray(value)) return value.slice(0, 50).map((v) => redact(v, depth + 1));
  const out: Record<string, unknown> = {};
  for (const [key, v] of Object.entries(value)) out[key] = SENSITIVE_KEY.test(key) ? REDACTED : redact(v, depth + 1);
  return out;
}

/** An error as it may be logged: its name and a redacted message. Never its stack in production, never its cause's data. */
export function describeError(err: unknown): { name: string; message: string; stack?: string } {
  if (!(err instanceof Error)) return { name: 'Error', message: redactText(String(err)) };
  return {
    name: err.name,
    message: redactText(err.message),
    ...(process.env.NODE_ENV !== 'production' && err.stack ? { stack: redactText(err.stack) } : {}),
  };
}

/* ─── Emitting ─────────────────────────────────────────────────────────── */

const WINDOW = 200;
const recent: Observation[] = [];
const counts = new Map<Signal, number>();
const startedAt = new Date().toISOString();

type Sink = (line: string, observation: Observation) => void;

/** Written to the server log, one JSON line per signal. Quiet under the test runner unless a test installs a sink. */
const consoleSink: Sink = (line, o) => {
  if (process.env.NODE_ENV === 'test' && process.env.OBSERVABILITY_LOG !== 'on') return;
  if (o.level === 'error') console.error(line);
  else if (o.level === 'warn') console.warn(line);
  else console.log(line);
};

let sink: Sink = consoleSink;

/** Replaces where signal lines go — tests capture them; `undefined` restores the server log. */
export function setObservationSink(next: Sink | undefined) {
  sink = next ?? consoleSink;
}

/**
 * Reports one signal. Fields are redacted before anything is written or kept. Never throws: failing to
 * report a failure must not turn into a second one.
 */
export function observe(signal: Signal, fields: Record<string, unknown> = {}, level: SignalLevel = DEFAULT_LEVEL[signal]): Observation {
  const observation: Observation = { signal, level, at: new Date().toISOString(), fields: redact(fields) as Record<string, unknown> };
  counts.set(signal, (counts.get(signal) ?? 0) + 1);
  if (level !== 'info') {
    recent.push(observation);
    if (recent.length > WINDOW) recent.shift();
  }
  try {
    sink(JSON.stringify({ observability: signal, level, at: observation.at, ...observation.fields }), observation);
  } catch {
    // A sink that fails is not the caller's problem.
  }
  return observation;
}

/**
 * Runs a background job and makes its failure visible: a `job.failed` signal naming the job, with the
 * error redacted. The error is rethrown so the caller decides whether the run continues.
 */
export async function watchJob<T>(job: string, fn: () => Promise<T>, fields: Record<string, unknown> = {}): Promise<T> {
  try {
    return await fn();
  } catch (err) {
    observe('job.failed', { job, ...fields, error: describeError(err) });
    throw err;
  }
}

/**
 * A provider webhook that could not be accepted or processed: a bad signature, an unknown event, a
 * handler that threw. The webhook endpoint (SAAS-010) reports every refusal and failure through this.
 */
export const webhookFailed = (provider: string, reason: string, fields: Record<string, unknown> = {}) =>
  observe('webhook.failed', { provider, reason, ...fields });

/** What the Super Admin sees: counts per signal since the process started, and the latest warnings and errors. */
export function observabilitySnapshot(opts: { limit?: number; signal?: Signal } = {}) {
  const limit = Math.min(Math.max(opts.limit ?? 50, 1), WINDOW);
  const failures = recent
    .filter((o) => !opts.signal || o.signal === opts.signal)
    .slice(-limit)
    .reverse();
  return { since: startedAt, counts: Object.fromEntries(counts), failures };
}

/** Clears the window and the counts. Tests only. */
export function resetObservations() {
  recent.length = 0;
  counts.clear();
}
