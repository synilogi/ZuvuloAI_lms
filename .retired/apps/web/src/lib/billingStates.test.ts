import { describe, expect, it } from 'vitest';
import type { Subscription } from '@syniastrolms/domain';
import { BILLING_PAGE, BILLING_STATES, billingNotice, extensionSummary } from './billingStates';

/* The academy's standing, said once on every page before anything is refused (§34). */

const NOW = new Date('2026-10-03T06:00:00.000Z');
const inDays = (n: number) => new Date(NOW.getTime() + n * 86_400_000).toISOString();
const sub = (over: Partial<Subscription>) => ({ id: 's1', status: 'active', renewsAt: inDays(20), ...over }) as Subscription;
const notice = (s: Subscription | null, enforced = true) => billingNotice({ subscription: s, enforced }, NOW);

describe('the billing banner on load', () => {
  it('says nothing about a healthy subscription', () => {
    expect(notice(sub({}))).toBeNull();
  });

  it('names a free trial for as long as it runs, with the days left and the way to choose a plan', () => {
    const early = notice(sub({ status: 'trial', trialEndsAt: inDays(12) }))!;
    expect(early).toMatchObject({ tone: 'info', title: 'Free trial · 12 days left', action: { label: 'Choose a plan', to: BILLING_PAGE } });
    expect(notice(sub({ status: 'trial', trialEndsAt: inDays(1) }))!.title).toBe('Free trial · 1 day left');
    expect(notice(sub({ status: 'trial', trialEndsAt: inDays(0) }))!.title).toBe('Free trial · ends today');
  });

  it('warns of an overdue payment with the date the grace period ends, and points at the invoice', () => {
    const n = notice(sub({ status: 'past-due', graceEndsAt: inDays(4) }))!;
    expect(n.tone).toBe('danger');
    expect(n.title.startsWith(BILLING_STATES.SUBSCRIPTION_PAST_DUE.title)).toBe(true);
    expect(n.title).toContain('pay by');
    expect(n.body).toContain('4 days');
    expect(n.action).toEqual({ label: 'Pay invoice', to: BILLING_PAGE });
  });

  it('names a trial ending within a week, a pause by the platform, and a cancellation under way', () => {
    const ending = notice(sub({ status: 'trial', trialEndsAt: inDays(3) }))!;
    expect(ending.title).toBe('Free trial · 3 days left');
    expect(ending.tone).toBe('warn');
    expect(notice(sub({ status: 'paused', resumesAt: inDays(9) }))!.title).toMatch(/^Paused by the platform team until /);
    expect(notice(sub({ status: 'canceling' }))!.title).toMatch(/^The subscription ends on /);
  });

  it('says an ended subscription has ended, in the refusal’s own words', () => {
    for (const status of ['canceled', 'expired'] as const) expect(notice(sub({ status }))!.title).toBe(BILLING_STATES.SUBSCRIPTION_EXPIRED.title);
  });

  it('warns of no plan only where plans are enforced', () => {
    expect(notice(null)!.title).toBe(BILLING_STATES.SUBSCRIPTION_REQUIRED.title);
    expect(notice(null, false)).toBeNull();
  });

  it('changes its key when the situation changes, so a dismissed banner returns for a new one', () => {
    expect(notice(sub({ status: 'past-due', graceEndsAt: inDays(4) }))!.key).not.toBe(notice(sub({ status: 'past-due', graceEndsAt: inDays(5) }))!.key);
  });
});

describe('the history’s wording for complimentary days', () => {
  it('reads as days added, with the reason', () => {
    expect(extensionSummary(1)).toBe('Complimentary days added (1 day).');
    expect(extensionSummary(14, 'Goodwill after the outage.')).toBe('Complimentary days added (14 days) — Goodwill after the outage.');
  });
});
