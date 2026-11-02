import type { CheckoutOutcome, TenantBilling } from '@syniastrolms/domain';

/*
 * What the academy's billing page offers, and what it says after a checkout (SAAS-009, SAAS-015). Pure, so
 * the rules are tested without a browser. The server enforces every one of them again: these only decide
 * which buttons appear.
 */

/**
 * What the plan list offers:
 *   - `purchase` — no live subscription (never subscribed, or it ended), online payment is on and the admin
 *     may change billing: each plan gets a Choose button that starts a first purchase;
 *   - `change` — a live subscription with no change already waiting, and the admin may change billing:
 *     each plan gets a button to ask for an upgrade or a downgrade;
 *   - `none` — look, don't touch: no permission, a change already waiting, or no way to pay for a first plan.
 * A trial is live: it converts by paying its own invoice, never through a first purchase.
 */
export function planActionMode(
  summary: Pick<TenantBilling, 'subscription' | 'openChange' | 'checkoutAvailable'>,
  canChange: boolean,
): 'purchase' | 'change' | 'none' {
  if (!canChange) return 'none';
  const s = summary.subscription;
  const live = Boolean(s && s.status !== 'canceled' && s.status !== 'expired');
  if (!live) return summary.checkoutAvailable ? 'purchase' : 'none';
  return summary.openChange ? 'none' : 'change';
}

export interface OutcomeMessage {
  kind: 'success' | 'error' | 'info';
  title: string;
  text: string;
}

/** What the page says once the server has read a finished checkout's payment from the provider. */
export function describeCheckoutOutcome(outcome: CheckoutOutcome): OutcomeMessage {
  if (outcome.status === 'paid' && (outcome.settled || outcome.applied)) return { kind: 'success', title: 'Payment received', text: outcome.message };
  if (outcome.status === 'paid') return { kind: 'info', title: 'Payment recorded', text: outcome.message };
  if (outcome.status === 'failed') return { kind: 'error', title: 'The payment did not go through', text: outcome.message };
  return { kind: 'info', title: 'Payment being confirmed', text: outcome.message };
}

/** A provider that has taken the payment but not settled it yet: the page waits for its word. */
export const isAwaitingProvider = (outcome: Pick<CheckoutOutcome, 'status'>) => outcome.status === 'pending' || outcome.status === 'authorized';

/** How long the page waits for the provider: every 5 seconds, 12 times — a minute. */
export const PROVIDER_POLL = { intervalMs: 5_000, attempts: 12 } as const;

/**
 * Asks `check` every `intervalMs`, up to `attempts` times, until it answers true. Resolves true when it did,
 * false when the attempts ran out or `signal` aborted (the page went away) — a check that fails counts as a
 * no and the waiting goes on.
 */
export async function pollUntil(
  check: () => Promise<boolean>,
  { intervalMs = PROVIDER_POLL.intervalMs, attempts = PROVIDER_POLL.attempts, signal }: { intervalMs?: number; attempts?: number; signal?: AbortSignal } = {},
): Promise<boolean> {
  for (let i = 0; i < attempts; i++) {
    const waited = await new Promise<boolean>((resolve) => {
      if (signal?.aborted) return resolve(false);
      const timer = setTimeout(() => {
        signal?.removeEventListener('abort', stop);
        resolve(true);
      }, intervalMs);
      const stop = () => {
        clearTimeout(timer);
        resolve(false);
      };
      signal?.addEventListener('abort', stop, { once: true });
    });
    if (!waited) return false;
    if (await check().catch(() => false)) return true;
    if (signal?.aborted) return false;
  }
  return false;
}
