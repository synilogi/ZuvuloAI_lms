import { BYTES_PER_GB, type PlanLimits } from '@syniastrolms/domain';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { unique } from '../test/helpers.js';
import { BillingConfigError, assertBillingConfig, graceDays, repeatTrialsAllowed } from './billingConfig.js';
import { setClock } from './clock.js';
import { assertFeature, getTenantEntitlements } from './entitlements.js';
import { ApiError } from './errors.js';
import { createPlan, publishPlan } from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import {
  cancelNow,
  createSubscription,
  expireGrace,
  expireTrial,
  getSubscription,
  listLifecycle,
  recordPaymentFailed,
  recordPaymentSucceeded,
  startGracePeriod,
  type LifecycleActor,
} from './subscriptions.js';
import { runAsPlatform } from './tenancy.js';

/* SAAS-005: trials decided by the server alone, one trial per academy unless the platform allows more,
 * and a grace period whose length is configuration. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('trial and grace tests act as the platform', fn);
const provider: LifecycleActor = { type: 'provider', provider: 'testpay' };
const scheduler: LifecycleActor = { type: 'system', job: 'trial-grace-tests' };
let superAdmin: LifecycleActor & { type: 'user' };
let planId: string;

const LIMITS: PlanLimits = {
  'learners.max': 50,
  'instructors.max': 2,
  'courses.max': 5,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 2,
  'admin_accounts.max': 1,
};

const at = async <T>(iso: string, fn: () => Promise<T>): Promise<T> => {
  setClock(iso);
  return fn();
};

const refusal = async (promise: Promise<unknown>) => {
  const err = await promise.then(
    () => undefined,
    (e: unknown) => e,
  );
  expect(err, 'expected a refusal').toBeInstanceOf(Error);
  return err as ApiError;
};

const newAcademy = async () => (await platformDb.tenant.create({ data: { name: 'Trial Academy', slug: `trial-${unique()}` } })).id;

const start = (tenantId: string, how: 'trial' | 'active' = 'trial', extra: object = {}) =>
  asPlatform(() => createSubscription(superAdmin, { tenantId, planId, cycle: 'monthly', start: how, ...extra }));

/** An overdue subscription, fallen due at `iso`. */
async function overdue(iso = '2026-09-10T00:00:00Z') {
  const tenantId = await newAcademy();
  const sub = await at('2026-09-01T00:00:00Z', () => start(tenantId, 'active'));
  await at(iso, () => asPlatform(() => recordPaymentFailed(provider, sub.id, { reason: 'card_declined' })));
  return { tenantId, sub };
}

beforeAll(async () => {
  const created = await provisionSuperAdmin({ email: `trials-${unique()}@example.com`, password: 'trials-suite-password', name: 'Billing' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
  planId = await asPlatform(async () => {
    const plan = await createPlan(
      { auth: superAdmin.auth },
      {
        name: 'Trial test plan',
        description: 'A plan with a fourteen-day trial.',
        code: `T${unique().toUpperCase()}`.slice(0, 24),
        currency: 'INR',
        cycles: ['monthly'],
        monthlyPrice: 149900,
        annualPrice: 0,
        trialEnabled: true,
        trialDays: 14,
        features: ['courses.manage'],
        limits: LIMITS,
      },
    );
    await publishPlan({ auth: superAdmin.auth }, plan.id);
    return plan.id;
  });
});

afterEach(() => {
  setClock(null);
  delete process.env.SUBSCRIPTION_GRACE_DAYS;
  delete process.env.SUBSCRIPTION_REPEAT_TRIALS;
});

describe('changing the client clock cannot extend a trial', () => {
  it('sets a trial from the plan and the server’s clock, whatever the request says', async () => {
    const tenantId = await newAcademy();
    // Everything a client might send to lengthen its trial: a clock, an end date, a longer trial.
    const sub = await at('2026-09-01T10:00:00Z', () =>
      start(tenantId, 'trial', { now: new Date('2027-01-01'), trialEndAt: new Date('2030-01-01'), trialDays: 90 }),
    );
    expect(sub).toMatchObject({
      trialStartAt: '2026-09-01T10:00:00.000Z',
      trialEndAt: '2026-09-15T10:00:00.000Z',
      currentPeriodEndAt: '2026-09-15T10:00:00.000Z',
    });
  });

  it('expires the trial by the server’s clock alone, at exactly its end', async () => {
    const tenantId = await newAcademy();
    const sub = await at('2026-09-01T10:00:00Z', () => start(tenantId));
    expect((await refusal(at('2026-09-15T09:59:59.999Z', () => asPlatform(() => expireTrial(scheduler, sub.id))))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    const expired = await at('2026-09-15T10:00:00Z', () => asPlatform(() => expireTrial(scheduler, sub.id)));
    expect(expired.status).toBe('expired');
    expect((await asPlatform(() => listLifecycle(sub.id))).at(-1)).toMatchObject({
      event: 'subscription.expired',
      meta: { trialEndedAt: '2026-09-15T10:00:00.000Z' },
    });
    // Once over, the trial serves nothing.
    expect(await refusal(assertFeature(tenantId, 'courses.manage'))).toMatchObject({ code: 'SUBSCRIPTION_EXPIRED' });
  });

  it('fixes a trial’s dates in the database, so no write can move them', async () => {
    const tenantId = await newAcademy();
    const sub = await start(tenantId);
    await expect(platformDb.$executeRawUnsafe(`UPDATE "Subscription" SET "trialEndAt" = "trialEndAt" + 86400000 WHERE "id" = ?`, sub.id)).rejects.toThrow(
      /fixed when it starts/,
    );
    await expect(platformDb.subscription.update({ where: { id: sub.id }, data: { trialStartAt: new Date('2020-01-01') } })).rejects.toThrow();
    expect((await asPlatform(() => getSubscription(sub.id))).trialEndAt).toBe(sub.trialEndAt);
  });
});

describe('a tenant cannot start a second trial unless the rule allows it', () => {
  it('refuses a second trial after the first expired, converted or was cancelled', async () => {
    for (const end of ['expired', 'converted and cancelled', 'cancelled'] as const) {
      const tenantId = await newAcademy();
      const first = await at('2026-09-01T00:00:00Z', () => start(tenantId));
      if (end === 'expired') await at('2026-10-01T00:00:00Z', () => asPlatform(() => expireTrial(scheduler, first.id)));
      if (end !== 'expired') {
        if (end === 'converted and cancelled') await asPlatform(() => recordPaymentSucceeded(provider, first.id));
        await asPlatform(() => cancelNow(superAdmin, first.id));
      }
      const err = await refusal(start(tenantId));
      expect(err.code, end).toBe('INVALID_SUBSCRIPTION_STATE');
      expect(err.message).toBe('This LMS has already had its free trial.');
      // A paid start is still open to it.
      expect((await start(tenantId, 'active')).status, end).toBe('active');
    }
  });

  it('gives a first trial to every academy, one each', async () => {
    const [a, b] = [await newAcademy(), await newAcademy()];
    expect((await start(a)).status).toBe('trialing');
    expect((await start(b)).status).toBe('trialing');
  });

  it('allows a repeat trial only when the platform switches it on', async () => {
    const tenantId = await newAcademy();
    const first = await start(tenantId);
    await asPlatform(() => cancelNow(superAdmin, first.id));
    process.env.SUBSCRIPTION_REPEAT_TRIALS = 'on';
    expect((await start(tenantId)).status).toBe('trialing');
    expect(repeatTrialsAllowed({ SUBSCRIPTION_REPEAT_TRIALS: 'yes' })).toBe(false);
    expect(repeatTrialsAllowed({})).toBe(false);
  });
});

describe('grace duration is configuration, not a constant in code', () => {
  it('reads the length from SUBSCRIPTION_GRACE_DAYS, and has no default', () => {
    expect(graceDays({ SUBSCRIPTION_GRACE_DAYS: '7' })).toBe(7);
    expect(graceDays({ SUBSCRIPTION_GRACE_DAYS: '0' })).toBe(0);
    for (const bad of [undefined, '', 'seven', '-1', '91', '2.5']) {
      expect(() => graceDays(bad === undefined ? {} : { SUBSCRIPTION_GRACE_DAYS: bad }), String(bad)).toThrow(BillingConfigError);
    }
  });

  it('starts grace for the configured number of days, and stores when and why', async () => {
    const { sub } = await overdue('2026-09-10T00:00:00Z');
    const due = await asPlatform(() => getSubscription(sub.id));
    expect(due).toMatchObject({ status: 'past_due', pastDueAt: '2026-09-10T00:00:00.000Z', pastDueReason: 'card_declined' });

    process.env.SUBSCRIPTION_GRACE_DAYS = '7';
    const grace = await at('2026-09-13T06:00:00Z', () => asPlatform(() => startGracePeriod(scheduler, sub.id, { reason: 'retries_exhausted' })));
    expect(grace).toMatchObject({ status: 'past_due', gracePeriodStartAt: '2026-09-13T06:00:00.000Z', gracePeriodEndAt: '2026-09-20T06:00:00.000Z' });
    expect((await asPlatform(() => listLifecycle(sub.id))).at(-1)).toMatchObject({
      transition: 'grace_started',
      event: 'subscription.past_due',
      meta: { reason: 'retries_exhausted', graceDays: 7, graceEndsAt: '2026-09-20T06:00:00.000Z' },
    });
  });

  it('follows the configuration, and fixes each grace period’s end when it starts', async () => {
    const first = await overdue();
    const second = await overdue();
    process.env.SUBSCRIPTION_GRACE_DAYS = '3';
    const three = await at('2026-09-12T00:00:00Z', () => asPlatform(() => startGracePeriod(scheduler, first.sub.id, { reason: 'retries_exhausted' })));
    process.env.SUBSCRIPTION_GRACE_DAYS = '10';
    const ten = await at('2026-09-12T00:00:00Z', () => asPlatform(() => startGracePeriod(scheduler, second.sub.id, { reason: 'retries_exhausted' })));
    expect(three.gracePeriodEndAt).toBe('2026-09-15T00:00:00.000Z');
    expect(ten.gracePeriodEndAt).toBe('2026-09-22T00:00:00.000Z');
    // Changing the configuration later leaves the first grace period where it was.
    expect((await asPlatform(() => getSubscription(first.sub.id))).gracePeriodEndAt).toBe('2026-09-15T00:00:00.000Z');
  });

  it('starts no grace while no length is configured — and the academy keeps its access', async () => {
    const { tenantId, sub } = await overdue();
    const before = (await asPlatform(() => listLifecycle(sub.id))).length;
    expect(await refusal(asPlatform(() => startGracePeriod(scheduler, sub.id, { reason: 'retries_exhausted' })))).toBeInstanceOf(BillingConfigError);
    expect(await asPlatform(() => listLifecycle(sub.id))).toHaveLength(before);
    expect((await getTenantEntitlements(tenantId)).features).toContain('courses.manage');
  });

  it('opens a grace window only through the transition, once per overdue episode', async () => {
    const { sub } = await overdue();
    process.env.SUBSCRIPTION_GRACE_DAYS = '5';
    await asPlatform(() => startGracePeriod(scheduler, sub.id, { reason: 'retries_exhausted' }));
    expect((await refusal(asPlatform(() => startGracePeriod(scheduler, sub.id, { reason: 'again' })))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    // Extending it by a direct write is refused by the database.
    await expect(
      platformDb.$executeRawUnsafe(`UPDATE "Subscription" SET "gracePeriodEndAt" = "gracePeriodEndAt" + 86400000 WHERE "id" = ?`, sub.id),
    ).rejects.toThrow(/only by the grace_started transition/);
    // Nor can a person or a subscription that is not overdue start one.
    expect((await refusal(asPlatform(() => startGracePeriod(superAdmin, sub.id, { reason: 'x' })))).status).toBe(403);
    const active = await start(await newAcademy(), 'active');
    expect((await refusal(asPlatform(() => startGracePeriod(scheduler, active.id, { reason: 'x' })))).code).toBe('INVALID_SUBSCRIPTION_STATE');
  });
});

describe('start-up refuses billing terms that would leave a non-paying academy with access for ever', () => {
  it('needs the overdue terms once enforcement is on, and checks any term that is set', () => {
    expect(() => assertBillingConfig({})).not.toThrow();
    expect(() => assertBillingConfig({ ENTITLEMENT_ENFORCEMENT: 'on' })).toThrow(/SUBSCRIPTION_RETRY_DAYS and SUBSCRIPTION_GRACE_DAYS/);
    expect(() => assertBillingConfig({ ENTITLEMENT_ENFORCEMENT: 'on', SUBSCRIPTION_RETRY_DAYS: '3' })).toThrow(/needs SUBSCRIPTION_GRACE_DAYS:/);
    expect(() => assertBillingConfig({ ENTITLEMENT_ENFORCEMENT: 'on', SUBSCRIPTION_RETRY_DAYS: '3', SUBSCRIPTION_GRACE_DAYS: '7' })).not.toThrow();
    expect(() => assertBillingConfig({ SUBSCRIPTION_GRACE_DAYS: '120' })).toThrow(BillingConfigError);
    expect(() => assertBillingConfig({ SUBSCRIPTION_INVOICE_LEAD_DAYS: 'soon' })).toThrow(BillingConfigError);
  });
});

describe('the grace path (§8)', () => {
  it('past_due → retry succeeds → active, with the episode closed', async () => {
    const { sub } = await overdue('2026-09-10T00:00:00Z');
    process.env.SUBSCRIPTION_GRACE_DAYS = '5';
    await asPlatform(() => startGracePeriod(scheduler, sub.id, { reason: 'retries_exhausted' }));
    const recovered = await at('2026-09-12T00:00:00Z', () => asPlatform(() => recordPaymentSucceeded(provider, sub.id)));
    expect(recovered.status).toBe('active');
    for (const field of ['pastDueAt', 'pastDueReason', 'gracePeriodStartAt', 'gracePeriodEndAt'] as const) expect(recovered[field], field).toBeUndefined();
    // The history keeps every step of the episode.
    expect((await asPlatform(() => listLifecycle(sub.id))).map((e) => e.transition)).toEqual([
      'create',
      'payment_failed',
      'grace_started',
      'payment_succeeded',
    ]);
    // A later failure is a new episode, with its own grace.
    await asPlatform(() => recordPaymentFailed(provider, sub.id, { reason: 'insufficient_funds' }));
    expect((await asPlatform(() => startGracePeriod(scheduler, sub.id, { reason: 'retries_exhausted' }))).gracePeriodEndAt).toBeDefined();
  });

  it('past_due → retries exhausted → grace → expired, only once the grace has run out', async () => {
    const { tenantId, sub } = await overdue('2026-09-10T00:00:00Z');
    process.env.SUBSCRIPTION_GRACE_DAYS = '7';
    await at('2026-09-13T00:00:00Z', () => asPlatform(() => startGracePeriod(scheduler, sub.id, { reason: 'retries_exhausted' })));
    // Throughout grace the academy keeps its plan.
    expect((await getTenantEntitlements(tenantId)).features).toContain('courses.manage');
    expect((await refusal(at('2026-09-19T23:59:59Z', () => asPlatform(() => expireGrace(scheduler, sub.id))))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    const expired = await at('2026-09-20T00:00:00Z', () => asPlatform(() => expireGrace(scheduler, sub.id)));
    expect(expired.status).toBe('expired');
    expect((await asPlatform(() => listLifecycle(sub.id))).at(-1)).toMatchObject({ event: 'subscription.expired', meta: { pastDueReason: 'card_declined' } });
    expect(await refusal(assertFeature(tenantId, 'courses.manage'))).toMatchObject({ status: 402, code: 'SUBSCRIPTION_EXPIRED' });
  });
});
