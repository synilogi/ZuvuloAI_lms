import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { moduleAccess } from '@syniastrolms/domain';
import { tenantBillingService as service } from './tenantBilling';

/*
 * The demo academy's plan as its staff see it, and its one free trial. Kept apart from the billing page's tests
 * because it ends the demo subscription to get there.
 */

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

/** Expects a refusal: the expectation is attached before the timers run, so the rejection is always handled. */
async function refused(promise: Promise<unknown>, match: object | RegExp) {
  const expectation = match instanceof RegExp ? expect(promise).rejects.toThrow(match) : expect(promise).rejects.toMatchObject(match);
  await vi.runAllTimersAsync();
  await expectation;
}

describe('the demo academy’s plan and free trial', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('reports the plan the way /academy/plan does: what it opens, and what it locks', async () => {
    const plan = await settle(service.academyPlan());
    expect(plan).toMatchObject({ enforced: true, status: 'active', restricted: false, plan: { name: 'Growth' }, lastFeatures: [] });
    expect(moduleAccess(plan, 'courses')).toBe('open');
    expect(moduleAccess(plan, 'branding')).toBe('locked');
    expect(plan.renewsAt).toBeTruthy();
  });

  it('refuses a trial while a subscription is live', async () => {
    expect((await settle(service.summary())).trialAvailable).toBe(false);
    await refused(service.startTrial({ planId: 'growth', cycle: 'monthly' }), { reason: 'INVALID_SUBSCRIPTION_STATE' });
  });

  it('keeps an ended plan’s modules readable, and offers the trial once nothing is live', async () => {
    await settle(service.cancel({ immediately: true, reason: 'Moving to a trial' }));
    const plan = await settle(service.academyPlan());
    expect(plan).toMatchObject({ status: 'canceled', restricted: true, features: [] });
    expect(moduleAccess(plan, 'courses')).toBe('read-only');
    expect((await settle(service.summary())).trialAvailable).toBe(true);
  });

  it('refuses a plan that is not on sale', async () => {
    await refused(service.startTrial({ planId: 'nope', cycle: 'monthly' }), { reason: 'PLAN_UNAVAILABLE' });
  });

  it('starts the trial with no payment, and only once', async () => {
    await settle(service.startTrial({ planId: 'professional', cycle: 'annual' }));
    const summary = await settle(service.summary());
    expect(summary.subscription).toMatchObject({ status: 'trial', planId: 'professional', cycle: 'annual' });
    expect(summary.trialAvailable).toBe(false);
    const plan = await settle(service.academyPlan());
    expect(plan).toMatchObject({ status: 'trialing', restricted: false, plan: { name: 'Professional' } });
    expect(plan.trialEndsAt).toBeTruthy();
    expect(moduleAccess(plan, 'branding')).toBe('open');

    await settle(service.cancel({ immediately: true, reason: 'Trying again' }));
    await refused(service.startTrial({ planId: 'growth', cycle: 'monthly' }), /already had a free trial/);
  });
});
