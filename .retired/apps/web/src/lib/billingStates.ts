/*
 * The subscription refusals the API answers with (subscriptions.md §34), as the states the screens show.
 *
 * The API gives each refusal a stable code. The HTTP client reads it, replaces the server's message with
 * the state's own words (`describeRefusal`) and keeps the code on the `ServiceError`, so every toast,
 * dialog and page that shows an error message shows a real state — "Your plan's limit is reached",
 * with what to do next — never a raw message. Screens that want more (a banner, a link) read the code
 * through `billingStateOf`.
 */

import type { TenantBilling } from '@syniastrolms/domain';
import { daysUntil } from '@syniastrolms/domain';
import type { ServiceError } from '@/services/contracts';
import { formatDate } from './format';

export const BILLING_REFUSAL_CODES = [
  'SUBSCRIPTION_REQUIRED',
  'SUBSCRIPTION_PAST_DUE',
  'SUBSCRIPTION_EXPIRED',
  'FEATURE_NOT_INCLUDED',
  'LIMIT_REACHED',
  'PAYMENT_REQUIRED',
  'PAYMENT_FAILED',
  'PLAN_UNAVAILABLE',
  'INVALID_SUBSCRIPTION_STATE',
] as const;

export type BillingRefusalCode = (typeof BILLING_REFUSAL_CODES)[number];

export const isBillingRefusal = (code: unknown): code is BillingRefusalCode => (BILLING_REFUSAL_CODES as readonly unknown[]).includes(code);

export interface BillingState {
  code: BillingRefusalCode;
  tone: 'warn' | 'danger' | 'info';
  title: string;
  /** What it means and what to do, for the person who met it. */
  body: string;
  /** Where the academy's admin resolves it, when there is somewhere to go. */
  action?: { label: string; to: string };
  /** Whether the whole academy is affected (a banner), rather than one action (a message where it happened). */
  academyWide: boolean;
}

/** Where an academy's admin sees and changes the subscription. */
export const BILLING_PAGE = '/admin/billing';

export const BILLING_STATES: Record<BillingRefusalCode, Omit<BillingState, 'code'>> = {
  SUBSCRIPTION_REQUIRED: {
    tone: 'warn',
    title: 'No active subscription',
    body: 'This LMS is not on a plan, so nothing new can be added. Everything it already has stays readable and editable. An admin can choose a plan to continue.',
    action: { label: 'Choose a plan', to: BILLING_PAGE },
    academyWide: true,
  },
  SUBSCRIPTION_PAST_DUE: {
    tone: 'warn',
    title: 'A payment is overdue',
    body: 'The last payment for this LMS did not go through. Access continues for now; an admin should settle the invoice before the grace period ends.',
    action: { label: 'See billing', to: BILLING_PAGE },
    academyWide: true,
  },
  SUBSCRIPTION_EXPIRED: {
    tone: 'danger',
    title: 'The subscription has ended',
    body: 'This LMS’s subscription expired, so nothing new can be added. Courses, learners and records are all kept. An admin can renew to carry on.',
    action: { label: 'Renew', to: BILLING_PAGE },
    academyWide: true,
  },
  FEATURE_NOT_INCLUDED: {
    tone: 'info',
    title: 'Not included in this plan',
    body: 'The LMS’s current plan does not include this. An admin can compare plans and upgrade.',
    action: { label: 'Compare plans', to: BILLING_PAGE },
    academyWide: false,
  },
  LIMIT_REACHED: {
    tone: 'warn',
    title: 'The plan’s limit is reached',
    body: 'The LMS is using everything its plan allows here. Nothing was changed. An admin can upgrade for more, or free some up.',
    action: { label: 'See usage', to: BILLING_PAGE },
    academyWide: false,
  },
  PAYMENT_REQUIRED: {
    tone: 'warn',
    title: 'Payment needed first',
    body: 'This change is charged, and it takes effect once the payment is confirmed. Nothing has changed yet.',
    action: { label: 'See billing', to: BILLING_PAGE },
    academyWide: false,
  },
  PAYMENT_FAILED: {
    tone: 'danger',
    title: 'The payment did not go through',
    body: 'The provider refused the payment and nothing was charged. Try another method, or try again later.',
    action: { label: 'See billing', to: BILLING_PAGE },
    academyWide: false,
  },
  PLAN_UNAVAILABLE: {
    tone: 'info',
    title: 'That plan is not available',
    body: 'The plan is not on sale, is archived, or is not offered on that billing cycle. Choose another.',
    academyWide: false,
  },
  INVALID_SUBSCRIPTION_STATE: {
    tone: 'info',
    title: 'Not possible right now',
    body: 'The subscription is not in a state that allows this. Reload to see where it stands.',
    academyWide: false,
  },
};

/**
 * The words a refusal is shown in. For the two whose reason is specific to the request — which plan is
 * unavailable, why the state refuses — the server's own sentence follows the state's title.
 */
export function describeRefusal(code: BillingRefusalCode, serverMessage?: string): string {
  const state = BILLING_STATES[code];
  const specific = (code === 'PLAN_UNAVAILABLE' || code === 'INVALID_SUBSCRIPTION_STATE') && serverMessage ? serverMessage : state.body;
  return `${state.title}. ${specific}`;
}

/** The state behind an error, when it is a subscription refusal. */
export function billingStateOf(error: unknown): BillingState | null {
  const reason = (error as Partial<ServiceError> | null)?.reason;
  return isBillingRefusal(reason) ? { code: reason, ...BILLING_STATES[reason] } : null;
}

/* ─── History wording ─── */

/**
 * How complimentary days read on a subscription's history — "Complimentary days added (14 days) — goodwill
 * after the outage." — the same words in the demo and against the API, whose view does not word them yet.
 */
export function extensionSummary(days: number, reason?: string): string {
  const why = reason?.trim().replace(/[.!]+$/, '');
  return `Complimentary days added (${days} ${days === 1 ? 'day' : 'days'})${why ? ` — ${why}` : ''}.`;
}

/* ─── The academy's standing, on every page ─── */

/** A trial this close to its end is said as a warning rather than a note. */
export const TRIAL_NOTICE_DAYS = 7;

/** "Free trial · 5 days left" — the shell's trial banner, and the dashboard's. */
export function trialLine(trialEndsAt: string, now: Date): string {
  const left = daysUntil(trialEndsAt, now);
  if (left <= 0) return 'Free trial · ends today';
  return `Free trial · ${daysText(left)} left`;
}

export interface BillingNotice {
  /** Changes when the situation does, so a dismissed notice comes back for a new one. */
  key: string;
  tone: 'warn' | 'danger' | 'info';
  title: string;
  body: string;
  action: { label: string; to: string };
}

/**
 * What the shell says about the academy's subscription on load, before anything is refused: an overdue payment
 * and its grace period, a pause, a cancellation under way, a subscription that has ended, a free trial and how
 * long it has left, or no plan where plans are enforced. Null when there is nothing to say. Worded with the refusal states above, so
 * a banner and a refusal never disagree.
 */
export function billingNotice(summary: Pick<TenantBilling, 'subscription' | 'enforced'>, now: Date): BillingNotice | null {
  const s = summary.subscription;
  if (!s) {
    if (!summary.enforced) return null;
    const state = BILLING_STATES.SUBSCRIPTION_REQUIRED;
    return { key: 'none', tone: state.tone, title: state.title, body: state.body, action: { label: 'Choose a plan', to: BILLING_PAGE } };
  }
  switch (s.status) {
    case 'past-due': {
      const state = BILLING_STATES.SUBSCRIPTION_PAST_DUE;
      return {
        key: `past-due:${s.graceEndsAt ?? s.renewsAt}`,
        tone: 'danger',
        title: s.graceEndsAt ? `${state.title} — pay by ${formatDate(s.graceEndsAt)}` : state.title,
        body: s.graceEndsAt
          ? `The last payment did not go through. Access continues during the grace period, which ends in ${daysText(daysUntil(s.graceEndsAt, now))}.`
          : state.body,
        action: { label: 'Pay invoice', to: BILLING_PAGE },
      };
    }
    case 'paused':
      return {
        key: `paused:${s.resumesAt ?? ''}`,
        tone: 'info',
        title: s.resumesAt ? `Paused by the platform team until ${formatDate(s.resumesAt)}` : 'Paused by the platform team',
        body: 'Nothing new can be added while the subscription is paused. Everything the LMS has stays as it is.',
        action: { label: 'See billing', to: BILLING_PAGE },
      };
    case 'canceling':
      return {
        key: `canceling:${s.renewsAt}`,
        tone: 'warn',
        title: `The subscription ends on ${formatDate(s.renewsAt)}`,
        body: 'It was cancelled and stays open until then. An admin can keep it from the billing page.',
        action: { label: 'Keep the subscription', to: BILLING_PAGE },
      };
    case 'canceled':
    case 'expired': {
      const state = BILLING_STATES.SUBSCRIPTION_EXPIRED;
      return { key: `ended:${s.id}`, tone: state.tone, title: state.title, body: state.body, action: { label: 'Renew', to: BILLING_PAGE } };
    }
    case 'trial': {
      // The whole trial, not only its last week: an academy on a trial is told so on every page, with the way on.
      if (!s.trialEndsAt) return null;
      const left = daysUntil(s.trialEndsAt, now);
      return {
        key: `trial:${s.trialEndsAt}`,
        tone: left <= TRIAL_NOTICE_DAYS ? 'warn' : 'info',
        title: trialLine(s.trialEndsAt, now),
        body:
          left <= TRIAL_NOTICE_DAYS
            ? `It ends on ${formatDate(s.trialEndsAt)}. Choose a plan so nothing stops when it ends.`
            : `Everything in the plan is open until ${formatDate(s.trialEndsAt)}. Choose a plan whenever you are ready.`,
        action: { label: 'Choose a plan', to: BILLING_PAGE },
      };
    }
    default:
      return null;
  }
}

const daysText = (n: number) => `${n} ${n === 1 ? 'day' : 'days'}`;
