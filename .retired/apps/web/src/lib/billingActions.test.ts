import { describe, expect, it, vi } from 'vitest';
import type { CheckoutOutcome, OpenPlanChange, Subscription } from '@syniastrolms/domain';
import { describeCheckoutOutcome, isAwaitingProvider, planActionMode, pollUntil } from './billingActions';

/* SAAS-009/015: which plan actions the academy's billing page offers, and what it says after a checkout. */

const sub = (status: Subscription['status']) => ({ status }) as Subscription;
const change = { id: 'c1' } as OpenPlanChange;
const view = (subscription: Subscription | null, opts: { openChange?: OpenPlanChange | null; checkoutAvailable?: boolean } = {}) => ({
  subscription,
  openChange: opts.openChange ?? null,
  checkoutAvailable: opts.checkoutAvailable ?? true,
});

describe('Choose Plan appears only when a first purchase is possible', () => {
  it('offers a first purchase to an academy with no subscription, or one whose subscription ended', () => {
    expect(planActionMode(view(null), true)).toBe('purchase');
    expect(planActionMode(view(sub('canceled')), true)).toBe('purchase');
    expect(planActionMode(view(sub('expired')), true)).toBe('purchase');
  });

  it('never offers one to a live subscription — a trial, a paused or overdue one included — which changes plan instead', () => {
    for (const status of ['active', 'trial', 'past-due', 'paused', 'canceling'] as const) {
      expect(planActionMode(view(sub(status)), true), status).toBe('change');
    }
    expect(planActionMode(view(sub('active'), { openChange: change }), true)).toBe('none');
  });

  it('offers nothing without permission to change billing, or with no way to pay online', () => {
    expect(planActionMode(view(null), false)).toBe('none');
    expect(planActionMode(view(sub('active')), false)).toBe('none');
    expect(planActionMode(view(null, { checkoutAvailable: false }), true)).toBe('none');
  });
});

describe('what the page says after a checkout', () => {
  const outcome = (over: Partial<CheckoutOutcome>): CheckoutOutcome => ({
    status: 'paid',
    settled: true,
    applied: true,
    message: 'Paid. The subscription is active.',
    ...over,
  });

  it('success: the provider confirmed the payment and the subscription moved', () => {
    expect(describeCheckoutOutcome(outcome({}))).toEqual({ kind: 'success', title: 'Payment received', text: 'Paid. The subscription is active.' });
  });

  it('a payment already recorded is said so, not celebrated twice', () => {
    expect(describeCheckoutOutcome(outcome({ settled: false, applied: false, message: 'This payment is already recorded.' }))).toMatchObject({
      kind: 'info',
      title: 'Payment recorded',
    });
  });

  it('failure: the provider refused it, and its reason is shown', () => {
    expect(describeCheckoutOutcome(outcome({ status: 'failed', settled: false, applied: false, message: 'Card declined' }))).toEqual({
      kind: 'error',
      title: 'The payment did not go through',
      text: 'Card declined',
    });
  });

  it('pending: not complete yet, and nothing is claimed', () => {
    for (const status of ['pending', 'authorized'] as const) {
      expect(describeCheckoutOutcome(outcome({ status, settled: false, applied: false, message: 'Not complete yet.' }))).toMatchObject({
        kind: 'info',
        title: 'Payment being confirmed',
      });
    }
  });
});

describe('waiting for the payment provider', () => {
  it('waits only on a payment the provider has not settled', () => {
    expect(isAwaitingProvider({ status: 'pending' })).toBe(true);
    expect(isAwaitingProvider({ status: 'authorized' })).toBe(true);
    expect(isAwaitingProvider({ status: 'paid' })).toBe(false);
    expect(isAwaitingProvider({ status: 'failed' })).toBe(false);
  });

  it('asks every interval until the answer is yes', async () => {
    vi.useFakeTimers();
    const answers = [false, false, true];
    const check = vi.fn(() => Promise.resolve(answers.shift() ?? false));
    const done = pollUntil(check, { intervalMs: 5000, attempts: 12 });
    await vi.advanceTimersByTimeAsync(15_000);
    expect(await done).toBe(true);
    expect(check).toHaveBeenCalledTimes(3);
    vi.useRealTimers();
  });

  it('gives up after its attempts, counting a failed check as a no', async () => {
    vi.useFakeTimers();
    const check = vi.fn().mockRejectedValueOnce(new Error('offline')).mockResolvedValue(false);
    const done = pollUntil(check, { intervalMs: 5000, attempts: 12 });
    await vi.advanceTimersByTimeAsync(60_000);
    expect(await done).toBe(false);
    expect(check).toHaveBeenCalledTimes(12);
    vi.useRealTimers();
  });

  it('stops at once when the page goes away', async () => {
    vi.useFakeTimers();
    const controller = new AbortController();
    const check = vi.fn(() => Promise.resolve(false));
    const done = pollUntil(check, { signal: controller.signal });
    await vi.advanceTimersByTimeAsync(5_000);
    controller.abort();
    expect(await done).toBe(false);
    await vi.advanceTimersByTimeAsync(60_000);
    expect(check).toHaveBeenCalledTimes(1);
    vi.useRealTimers();
  });
});
