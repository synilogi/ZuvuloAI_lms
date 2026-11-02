import { describe, expect, it } from 'vitest';
import {
  ALLOWED_STATUS_PAIRS,
  ENTITLED_STATES,
  INITIAL_STATES,
  SUBSCRIPTION_STATES,
  TERMINAL_STATES,
  TRANSITIONS,
  addBillingPeriod,
  addDays,
  isTerminal,
  lifecycleEventFor,
  nextStatus,
  type SubscriptionState,
  type TransitionName,
} from './lifecycle';

/** The table §6 draws, written out edge by edge: [from, transition, to]. Anything not listed is refused. */
const EDGES: [SubscriptionState, TransitionName, SubscriptionState][] = [
  ['trialing', 'payment_succeeded', 'active'],
  ['trialing', 'payment_failed', 'past_due'],
  ['trialing', 'trial_expired', 'expired'],
  ['trialing', 'cancel_now', 'canceled'],
  ['trialing', 'change_plan', 'trialing'],
  ['active', 'payment_succeeded', 'active'],
  ['active', 'payment_failed', 'past_due'],
  ['active', 'request_cancel', 'canceling'],
  ['active', 'cancel_now', 'canceled'],
  ['active', 'pause', 'paused'],
  ['active', 'change_plan', 'active'],
  ['active', 'extend', 'active'],
  ['past_due', 'payment_succeeded', 'active'],
  ['past_due', 'grace_started', 'past_due'],
  ['past_due', 'grace_expired', 'expired'],
  ['past_due', 'cancel_now', 'canceled'],
  ['canceling', 'resume', 'active'],
  ['canceling', 'period_ended', 'canceled'],
  ['canceling', 'cancel_now', 'canceled'],
  ['paused', 'resume', 'active'],
  ['paused', 'cancel_now', 'canceled'],
];

const NAMES = TRANSITIONS.map((t) => t.name);

describe('the subscription state machine', () => {
  it('allows exactly the documented edges', () => {
    for (const [from, name, to] of EDGES) expect(nextStatus(from, name), `${from} --${name}-->`).toBe(to);
    // Everything else — every other status × transition — is refused.
    const listed = new Set(EDGES.map(([from, name]) => `${from}:${name}`));
    let refused = 0;
    for (const from of SUBSCRIPTION_STATES) {
      for (const name of NAMES) {
        if (listed.has(`${from}:${name}`)) continue;
        expect(nextStatus(from, name), `${from} --${name}--> should be refused`).toBeNull();
        refused++;
      }
    }
    expect(refused + EDGES.length).toBe(SUBSCRIPTION_STATES.length * NAMES.length);
  });

  it('never leaves a terminal status', () => {
    expect([...TERMINAL_STATES]).toEqual(['canceled', 'expired']);
    for (const state of TERMINAL_STATES) {
      expect(isTerminal(state)).toBe(true);
      for (const name of NAMES) expect(nextStatus(state, name)).toBeNull();
    }
  });

  it('refuses the transitions people most often expect to work', () => {
    expect(nextStatus('canceled', 'resume')).toBeNull(); // a new subscription, not a revival (§12)
    expect(nextStatus('expired', 'payment_succeeded')).toBeNull();
    expect(nextStatus('paused', 'payment_failed')).toBeNull();
    expect(nextStatus('past_due', 'request_cancel')).toBeNull(); // cancel at period end needs a paid period
    expect(nextStatus('trialing', 'pause')).toBeNull();
    expect(nextStatus('canceling', 'change_plan')).toBeNull();
  });

  it('starts a subscription only as a trial or as active', () => {
    expect([...INITIAL_STATES]).toEqual(['trialing', 'active']);
  });

  it('reaches every status from a starting one', () => {
    const reached = new Set<SubscriptionState>(INITIAL_STATES);
    for (let round = 0; round < SUBSCRIPTION_STATES.length; round++) {
      for (const [from, , to] of EDGES) if (reached.has(from)) reached.add(to);
    }
    expect([...reached].sort()).toEqual([...SUBSCRIPTION_STATES].sort());
  });

  it('lists each status pair the database allows once', () => {
    const pairs = ALLOWED_STATUS_PAIRS.map(([a, b]) => `${a}>${b}`);
    expect(new Set(pairs).size).toBe(pairs.length);
    expect([...pairs].sort()).toEqual([...new Set(EDGES.map(([from, , to]) => `${from}>${to}`))].sort());
  });

  it('serves the plan while trialing, active, overdue or cancelling — never paused or over', () => {
    expect([...ENTITLED_STATES].sort()).toEqual(['active', 'canceling', 'past_due', 'trialing']);
  });
});

describe('lifecycle events (§19)', () => {
  it('names each row by what happened', () => {
    expect(lifecycleEventFor('create', null, 'trialing')).toBe('subscription.trial.started');
    expect(lifecycleEventFor('create', null, 'active')).toBe('subscription.activated');
    expect(lifecycleEventFor('payment_succeeded', 'trialing', 'active')).toBe('subscription.activated');
    expect(lifecycleEventFor('payment_succeeded', 'past_due', 'active')).toBe('subscription.activated');
    expect(lifecycleEventFor('payment_succeeded', 'active', 'active')).toBe('subscription.payment.succeeded');
    expect(lifecycleEventFor('payment_failed', 'active', 'past_due')).toBe('subscription.past_due');
    expect(lifecycleEventFor('request_cancel', 'active', 'canceling')).toBe('subscription.cancel.requested');
    expect(lifecycleEventFor('period_ended', 'canceling', 'canceled')).toBe('subscription.canceled');
    expect(lifecycleEventFor('grace_started', 'past_due', 'past_due')).toBe('subscription.past_due');
    expect(lifecycleEventFor('grace_expired', 'past_due', 'expired')).toBe('subscription.expired');
    expect(lifecycleEventFor('change_plan', 'active', 'active')).toBe('subscription.plan_changed');
  });
});

describe('billing periods', () => {
  it('adds a calendar month, or a year', () => {
    expect(addBillingPeriod(new Date('2026-09-21T10:30:00Z'), 'monthly').toISOString()).toBe('2026-10-21T10:30:00.000Z');
    expect(addBillingPeriod(new Date('2026-09-21T10:30:00Z'), 'annual').toISOString()).toBe('2027-09-21T10:30:00.000Z');
    expect(addBillingPeriod(new Date('2026-12-15T00:00:00Z'), 'monthly').toISOString()).toBe('2027-01-15T00:00:00.000Z');
  });

  it('lands on the last day of a shorter month rather than skipping it', () => {
    expect(addBillingPeriod(new Date('2027-01-31T08:00:00Z'), 'monthly').toISOString()).toBe('2027-02-28T08:00:00.000Z');
    expect(addBillingPeriod(new Date('2028-01-31T08:00:00Z'), 'monthly').toISOString()).toBe('2028-02-29T08:00:00.000Z');
    expect(addBillingPeriod(new Date('2028-02-29T08:00:00Z'), 'annual').toISOString()).toBe('2029-02-28T08:00:00.000Z');
  });

  it('counts a trial in whole days', () => {
    expect(addDays(new Date('2026-09-21T10:00:00Z'), 14).toISOString()).toBe('2026-10-05T10:00:00.000Z');
  });
});
