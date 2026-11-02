/**
 * The subscription state machine (subscriptions.md §5, §6, §9). A subscription's status changes only
 * through one of the named transitions below, each with the statuses it may start from and the one it
 * ends in. Anything else is refused — by `nextStatus` here, by the API's subscription service, and by
 * the database itself, whose triggers carry the same table (the API tests check they agree).
 *
 * These are the server's statuses. The LMS-019 prototype screens still speak their own vocabulary
 * (`SubscriptionStatus` in `subscription.ts`: `trial`, `past-due`, …); SAAS-015 maps between the two.
 */

import type { BillingCycle } from './subscription';

export type SubscriptionState = 'trialing' | 'active' | 'past_due' | 'paused' | 'canceling' | 'canceled' | 'expired';

export const SUBSCRIPTION_STATES: readonly SubscriptionState[] = ['trialing', 'active', 'past_due', 'paused', 'canceling', 'canceled', 'expired'];

/** A subscription in one of these is over for good. It is never revived: the academy starts a new one (§12). */
export const TERMINAL_STATES: readonly SubscriptionState[] = ['canceled', 'expired'];

/** What a subscription may be created as. `active` only once a payment is confirmed, or for an agreement billed outside the provider. */
export const INITIAL_STATES: readonly SubscriptionState[] = ['trialing', 'active'];

export const isTerminal = (state: SubscriptionState): boolean => TERMINAL_STATES.includes(state);

export type TransitionName =
  | 'payment_succeeded'
  | 'payment_failed'
  | 'grace_started'
  | 'trial_expired'
  | 'request_cancel'
  | 'cancel_now'
  | 'resume'
  | 'pause'
  | 'period_ended'
  | 'grace_expired'
  | 'change_plan'
  | 'extend';

/** The lifecycle event each transition records (§19). */
export type LifecycleEvent =
  | 'subscription.created'
  | 'subscription.trial.started'
  | 'subscription.activated'
  | 'subscription.plan_changed'
  | 'subscription.payment.succeeded'
  | 'subscription.payment.failed'
  | 'subscription.past_due'
  | 'subscription.paused'
  | 'subscription.resumed'
  | 'subscription.cancel.requested'
  | 'subscription.canceled'
  | 'subscription.expired'
  | 'subscription.extended';

export interface Transition {
  name: TransitionName;
  from: readonly SubscriptionState[];
  /** `null` keeps the status it started in — a renewal, a plan change. */
  to: SubscriptionState | null;
  /** The lifecycle event it records; `lifecycleEventFor` refines it by the status it starts from. */
  event: LifecycleEvent;
  /** Who may cause it: a person, the scheduler, or a verified provider event. */
  by: readonly ('user' | 'system' | 'provider')[];
  description: string;
}

/**
 * Every allowed transition. This table *is* the documented business rule §6 asks for; the progress
 * record and docs/06 print it. Terminal statuses appear in no `from`.
 */
export const TRANSITIONS: readonly Transition[] = [
  {
    name: 'payment_succeeded',
    from: ['trialing', 'active', 'past_due'],
    to: 'active',
    event: 'subscription.payment.succeeded',
    by: ['provider', 'system'],
    description: 'A payment is confirmed: a trial converts, a period renews, or an overdue subscription recovers.',
  },
  {
    name: 'payment_failed',
    from: ['trialing', 'active'],
    to: 'past_due',
    event: 'subscription.past_due',
    by: ['provider', 'system'],
    description: 'A charge failed: the subscription falls due and retries begin, with access kept (§8).',
  },
  {
    name: 'grace_started',
    from: ['past_due'],
    to: null,
    event: 'subscription.past_due',
    by: ['provider', 'system'],
    description: 'Payment retries are exhausted: the grace period starts, with its end fixed by the platform’s configured length (§8).',
  },
  {
    name: 'trial_expired',
    from: ['trialing'],
    to: 'expired',
    event: 'subscription.expired',
    by: ['system'],
    description: 'The trial ran out without converting.',
  },
  {
    name: 'request_cancel',
    from: ['active'],
    to: 'canceling',
    event: 'subscription.cancel.requested',
    by: ['user'],
    description: 'Cancel at the end of the paid period; access runs until then.',
  },
  {
    name: 'cancel_now',
    from: ['trialing', 'active', 'past_due', 'paused', 'canceling'],
    to: 'canceled',
    event: 'subscription.canceled',
    by: ['user', 'provider'],
    description: 'Cancel immediately.',
  },
  {
    name: 'resume',
    from: ['canceling', 'paused'],
    to: 'active',
    event: 'subscription.resumed',
    by: ['user', 'system'],
    description: 'Withdraw a pending cancellation, or end a pause.',
  },
  {
    name: 'pause',
    from: ['active'],
    to: 'paused',
    event: 'subscription.paused',
    by: ['user'],
    description: 'Suspend the subscription for a while.',
  },
  {
    name: 'period_ended',
    from: ['canceling'],
    to: 'canceled',
    event: 'subscription.canceled',
    by: ['system'],
    description: 'The paid period of a cancelling subscription is over.',
  },
  {
    name: 'grace_expired',
    from: ['past_due'],
    to: 'expired',
    event: 'subscription.expired',
    by: ['system'],
    description: 'Retries and the grace period are exhausted with nothing paid.',
  },
  {
    name: 'change_plan',
    from: ['trialing', 'active'],
    to: null,
    event: 'subscription.plan_changed',
    by: ['user', 'provider', 'system'],
    description: 'Move to another plan version, keeping the status.',
  },
  {
    name: 'extend',
    from: ['active'],
    to: null,
    event: 'subscription.extended',
    by: ['user'],
    description: 'Give complimentary days: the current period ends later, at no charge.',
  },
];

/** The most complimentary days one extension gives. */
export const MAX_EXTENSION_DAYS = 90;

export const transitionNamed = (name: TransitionName): Transition => TRANSITIONS.find((t) => t.name === name)!;

/** Where `transition` takes a subscription in `from`, or `null` when it may not happen. */
export function nextStatus(from: SubscriptionState, transition: TransitionName): SubscriptionState | null {
  const rule = transitionNamed(transition);
  if (!rule.from.includes(from)) return null;
  return rule.to ?? from;
}

/**
 * The §19 event a lifecycle row records. Creating a subscription starts a trial or activates it; a
 * payment that converts a trial or recovers an overdue subscription activates it, and one on an active
 * subscription is a renewal. `subscription.created` is the audit trail's word for the creation, and the
 * payment events proper belong to the payment records (SAAS-008).
 */
export function lifecycleEventFor(transition: TransitionName | 'create', from: SubscriptionState | null, to: SubscriptionState): LifecycleEvent {
  if (transition === 'create') return to === 'trialing' ? 'subscription.trial.started' : 'subscription.activated';
  if (transition === 'payment_succeeded' && from !== 'active') return 'subscription.activated';
  return transitionNamed(transition).event;
}

/** Every status pair some transition connects — the set the database's trigger allows. */
export const ALLOWED_STATUS_PAIRS: readonly (readonly [SubscriptionState, SubscriptionState])[] = [
  ...new Map(TRANSITIONS.flatMap((t) => t.from.map((from) => [`${from}>${t.to ?? from}`, [from, t.to ?? from] as const]))).values(),
];

/** Statuses in which the academy is served its plan. Paused, cancelled and expired subscriptions grant nothing. */
export const ENTITLED_STATES: readonly SubscriptionState[] = ['trialing', 'active', 'past_due', 'canceling'];

/* ─── Billing periods ───────────────────────────────────────────────────── */

/**
 * The end of a billing period that starts at `start`: a calendar month or year later, in UTC. A start on
 * a day the next month does not have lands on that month's last day — 31 January is followed by 28 or
 * 29 February — so periods never skip a month. A new cycle adds a case here.
 */
export function addBillingPeriod(start: Date, cycle: BillingCycle): Date {
  const months = cycle === 'annual' ? 12 : 1;
  const y = start.getUTCFullYear();
  const m = start.getUTCMonth() + months;
  const lastDay = new Date(Date.UTC(y, m + 1, 0)).getUTCDate();
  return new Date(
    Date.UTC(y, m, Math.min(start.getUTCDate(), lastDay), start.getUTCHours(), start.getUTCMinutes(), start.getUTCSeconds(), start.getUTCMilliseconds()),
  );
}

/** `days` whole days after `start` — a trial's end. */
export const addDays = (start: Date, days: number): Date => new Date(start.getTime() + days * 86_400_000);
