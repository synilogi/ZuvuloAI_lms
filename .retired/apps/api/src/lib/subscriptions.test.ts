import { ALLOWED_STATUS_PAIRS, BYTES_PER_GB, SUBSCRIPTION_STATES, type PlanLimits, type SubscriptionState } from '@syniastrolms/domain';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { unique } from '../test/helpers.js';
import { ApiError } from './errors.js';
import { assertFeature, getTenantEntitlements } from './entitlements.js';
import { archivePlan, createPlan, publishPlan, updatePlan, type CreatePlanInput } from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import {
  cancelNow,
  createSubscription,
  endCancelledPeriod,
  expireGrace,
  expireTrial,
  getSubscription,
  listLifecycle,
  pauseSubscription,
  recordPaymentFailed,
  paidPeriodStart,
  recordPaymentSucceeded,
  requestCancellation,
  resumeSubscription,
  startGracePeriod,
  type LifecycleActor,
} from './subscriptions.js';
import { setClock } from './clock.js';
import { runAsPlatform, runInTenant } from './tenancy.js';

/* SAAS-004: subscriptions, the state machine and the lifecycle log. Every subscription here gets an
 * academy of its own — subscriptions are never deleted, so no test can tidy one away and none shares
 * one. The service is called the way its callers will call it: as the platform for a super admin, the
 * scheduler and a verified provider event, and inside the academy for the academy's own admin. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('subscription tests act as the platform', fn);

let superAdmin: LifecycleActor;
const provider: LifecycleActor = { type: 'provider', provider: 'testpay', reference: 'evt_1' };
const scheduler: LifecycleActor = { type: 'system', job: 'subscription-tests' };

const LIMITS: PlanLimits = {
  'learners.max': 100,
  'instructors.max': 5,
  'courses.max': 10,
  'storage.bytes': 10 * BYTES_PER_GB,
  'live_classes.max': 4,
  'admin_accounts.max': 2,
};

async function newPlan(over: Partial<CreatePlanInput> = {}): Promise<{ id: string; versionId: string }> {
  return asPlatform(async () => {
    const plan = await createPlan(superAdmin.type === 'user' ? { auth: superAdmin.auth } : {}, {
      name: 'Subscription test plan',
      description: 'A plan made for the subscription suite.',
      code: `S${unique().toUpperCase()}`.slice(0, 24),
      currency: 'INR',
      cycles: ['monthly', 'annual'],
      monthlyPrice: 399900,
      annualPrice: 3999000,
      trialEnabled: true,
      trialDays: 14,
      features: ['courses.manage', 'reports.basic'],
      limits: LIMITS,
      ...over,
    });
    await publishPlan({ auth: (superAdmin as { auth: { sub: string; role: 'superadmin' } }).auth }, plan.id);
    return { id: plan.id, versionId: plan.current.id };
  });
}

const newAcademy = async () => (await platformDb.tenant.create({ data: { name: 'Subscriber', slug: `sub-${unique()}` } })).id;

/** An academy with a subscription to a fresh plan, started as `start`. */
async function subscribed(start: 'trial' | 'active' = 'trial', at = '2026-09-01T09:00:00Z') {
  const tenantId = await newAcademy();
  const plan = await newPlan();
  setClock(at);
  const sub = await asPlatform(() => createSubscription(superAdmin, { tenantId, planId: plan.id, cycle: 'monthly', start }));
  return { tenantId, plan, sub };
}

/** Runs `fn` with the server's clock at `iso`. */
async function at<T>(iso: string, fn: () => Promise<T>): Promise<T> {
  setClock(iso);
  return fn();
}

const refusal = async (promise: Promise<unknown>) => {
  const err = await promise.then(
    () => undefined,
    (e: unknown) => e,
  );
  expect(err, 'expected a refusal').toBeInstanceOf(ApiError);
  return err as ApiError;
};

const events = (id: string) => asPlatform(() => listLifecycle(id));

afterEach(() => setClock(null));

beforeAll(async () => {
  const created = await provisionSuperAdmin({ email: `subscriptions-${unique()}@example.com`, password: 'subscriptions-suite-password', name: 'Billing' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
});

describe('creating a subscription', () => {
  it('starts a trial on the server’s clock, at the version’s price', async () => {
    const { tenantId, plan, sub } = await subscribed('trial', '2026-09-01T09:00:00Z');
    expect(sub).toMatchObject({
      tenantId,
      planId: plan.id,
      planVersionId: plan.versionId,
      status: 'trialing',
      billingCycle: 'monthly',
      currency: 'INR',
      amount: 399900,
      trialStartAt: '2026-09-01T09:00:00.000Z',
      trialEndAt: '2026-09-15T09:00:00.000Z',
      currentPeriodStartAt: '2026-09-01T09:00:00.000Z',
      currentPeriodEndAt: '2026-09-15T09:00:00.000Z',
    });
    const log = await events(sub.id);
    expect(log).toHaveLength(1);
    expect(log[0]).toMatchObject({
      event: 'subscription.trial.started',
      transition: 'create',
      toStatus: 'trialing',
      actor: { type: 'user', id: superAdmin.type === 'user' ? superAdmin.auth.sub : '' },
    });
    const audit = await platformDb.auditLog.findFirst({ where: { targetId: sub.id, action: 'subscription.created' } });
    expect(audit).not.toBeNull();
  });

  it('takes the amount from the plan version and nothing else — a price in the request is ignored', async () => {
    const tenantId = await newAcademy();
    const plan = await newPlan();
    const sub = await asPlatform(() =>
      createSubscription(superAdmin, { tenantId, planId: plan.id, cycle: 'annual', start: 'active', amount: 1, currency: 'USD' } as never),
    );
    expect(sub).toMatchObject({ status: 'active', amount: 3999000, currency: 'INR', billingCycle: 'annual' });
    expect(new Date(sub.currentPeriodEndAt).getUTCFullYear()).toBe(new Date(sub.currentPeriodStartAt).getUTCFullYear() + 1);
  });

  it('refuses a plan that is not on sale, a trial the plan does not offer, and a second live subscription', async () => {
    const tenantId = await newAcademy();
    const archived = await newPlan();
    await asPlatform(() => archivePlan({ auth: (superAdmin as { auth: { sub: string; role: 'superadmin' } }).auth }, archived.id));
    expect((await refusal(asPlatform(() => createSubscription(superAdmin, { tenantId, planId: archived.id, cycle: 'monthly', start: 'trial' })))).code).toBe(
      'PLAN_UNAVAILABLE',
    );

    const noTrial = await newPlan({ trialEnabled: false, trialDays: 0 });
    expect((await refusal(asPlatform(() => createSubscription(superAdmin, { tenantId, planId: noTrial.id, cycle: 'monthly', start: 'trial' })))).code).toBe(
      'PLAN_UNAVAILABLE',
    );

    const plan = await newPlan();
    await asPlatform(() => createSubscription(superAdmin, { tenantId, planId: plan.id, cycle: 'monthly', start: 'trial' }));
    expect((await refusal(asPlatform(() => createSubscription(superAdmin, { tenantId, planId: plan.id, cycle: 'monthly', start: 'active' })))).code).toBe(
      'INVALID_SUBSCRIPTION_STATE',
    );
  });

  it('holds at most one live subscription per academy in the database too', async () => {
    const { tenantId, plan } = await subscribed();
    const insert = () =>
      platformDb.$executeRawUnsafe(
        `INSERT INTO "Subscription" ("id", "tenantId", "planId", "planVersionId", "status", "billingCycle", "currency", "amount", "currentPeriodStartAt", "currentPeriodEndAt", "updatedAt")
         VALUES (?, ?, ?, ?, 'active', 'monthly', 'INR', 1, 1, 2, 3)`,
        `raw-${unique()}`,
        tenantId,
        plan.id,
        plan.versionId,
      );
    await expect(insert()).rejects.toThrow(/UNIQUE/);
  });

  it('lets an academy start again once its subscription is over — as a new subscription, not a revival', async () => {
    const { tenantId, plan, sub } = await subscribed('active');
    await asPlatform(() => cancelNow(superAdmin, sub.id, { reason: 'Moving on' }));
    const again = await asPlatform(() => createSubscription(superAdmin, { tenantId, planId: plan.id, cycle: 'monthly', start: 'active' }));
    expect(again.id).not.toBe(sub.id);
    expect((await asPlatform(() => getSubscription(sub.id))).status).toBe('canceled');
  });

  it('lets only the platform write a subscription into being', async () => {
    const tenantId = await newAcademy();
    const plan = await newPlan();
    const academyAdmin: LifecycleActor = { type: 'user', auth: { sub: 'someone', role: 'admin' } };
    expect(
      (await refusal(runInTenant(tenantId, () => createSubscription(academyAdmin, { tenantId, planId: plan.id, cycle: 'monthly', start: 'active' })))).status,
    ).toBe(403);
    // A super admin working inside an academy is not the platform.
    expect(
      (await refusal(runInTenant(tenantId, () => createSubscription(superAdmin, { tenantId, planId: plan.id, cycle: 'monthly', start: 'trial' })))).status,
    ).toBe(403);
    expect((await refusal(asPlatform(() => createSubscription(scheduler, { tenantId, planId: plan.id, cycle: 'monthly', start: 'active' })))).status).toBe(403);
    // A verified provider event may: the payment is what makes it active.
    expect((await asPlatform(() => createSubscription(provider, { tenantId, planId: plan.id, cycle: 'monthly', start: 'active' }))).status).toBe('active');
  });
});

describe('the lifecycle, walked edge by edge', () => {
  it('converts a trial, falls due, recovers, cancels at period end, resumes, pauses and cancels — one event per move', async () => {
    const { sub } = await subscribed('trial');
    setClock('2026-09-10T00:00:00Z');
    const steps: [string, () => Promise<{ status: SubscriptionState }>, SubscriptionState, string][] = [
      ['convert', () => recordPaymentSucceeded(provider, sub.id), 'active', 'subscription.activated'],
      ['renew', () => recordPaymentSucceeded(provider, sub.id), 'active', 'subscription.payment.succeeded'],
      ['fail', () => recordPaymentFailed(provider, sub.id, { reason: 'card_declined' }), 'past_due', 'subscription.past_due'],
      ['recover', () => recordPaymentSucceeded(provider, sub.id), 'active', 'subscription.activated'],
      ['request cancel', () => requestCancellation(superAdmin, sub.id, { reason: 'Too expensive' }), 'canceling', 'subscription.cancel.requested'],
      ['resume', () => resumeSubscription(superAdmin, sub.id), 'active', 'subscription.resumed'],
      ['pause', () => pauseSubscription(superAdmin, sub.id, { days: 10 }), 'paused', 'subscription.paused'],
      ['unpause', () => resumeSubscription(superAdmin, sub.id), 'active', 'subscription.resumed'],
      ['cancel now', () => cancelNow(superAdmin, sub.id, { reason: 'Closing the academy' }), 'canceled', 'subscription.canceled'],
    ];
    let expected = 1;
    for (const [label, step, status, event] of steps) {
      expect((await asPlatform(step)).status, label).toBe(status);
      const log = await events(sub.id);
      expect(log, label).toHaveLength(++expected);
      expect(log.at(-1), label).toMatchObject({ event, toStatus: status });
    }
  });

  it('keeps billing periods continuous: a conversion starts one when the trial ends, a renewal and a recovery carry on from the last', async () => {
    const { sub } = await subscribed('trial', '2026-09-01T09:00:00Z');
    // Paid with five trial days left: the trial runs out first, and the paid month starts when it ends.
    const converted = await at('2026-09-10T12:00:00Z', () => asPlatform(() => recordPaymentSucceeded(provider, sub.id)));
    expect(converted).toMatchObject({ status: 'active', currentPeriodStartAt: '2026-09-15T09:00:00.000Z', currentPeriodEndAt: '2026-10-15T09:00:00.000Z' });
    const renewed = await at('2026-10-14T00:00:00Z', () => asPlatform(() => recordPaymentSucceeded(provider, sub.id)));
    expect(renewed).toMatchObject({ currentPeriodStartAt: '2026-10-15T09:00:00.000Z', currentPeriodEndAt: '2026-11-15T09:00:00.000Z' });
    await at('2026-11-15T09:00:00Z', () => asPlatform(() => recordPaymentFailed(provider, sub.id)));
    const recovered = await at('2026-11-20T00:00:00Z', () => asPlatform(() => recordPaymentSucceeded(provider, sub.id)));
    expect(recovered).toMatchObject({ currentPeriodStartAt: '2026-11-15T09:00:00.000Z', currentPeriodEndAt: '2026-12-15T09:00:00.000Z' });
  });

  it('starts a fresh period for a recovery paid after the whole next period was over, rather than leaving it overdue again', async () => {
    const { sub } = await subscribed('active', '2026-09-01T09:00:00Z');
    await at('2026-10-01T09:00:00Z', () => asPlatform(() => recordPaymentFailed(provider, sub.id)));
    const recovered = await at('2026-11-20T00:00:00Z', () => asPlatform(() => recordPaymentSucceeded(provider, sub.id)));
    expect(recovered).toMatchObject({ status: 'active', currentPeriodStartAt: '2026-11-20T00:00:00.000Z', currentPeriodEndAt: '2026-12-20T00:00:00.000Z' });
  });

  it('converts a trial paid after its end from the moment of payment', () => {
    const sub = { status: 'trialing', billingCycle: 'monthly', currentPeriodEndAt: new Date('2026-09-15T09:00:00Z') };
    expect(paidPeriodStart(sub, new Date('2026-09-16T00:00:00Z'))).toEqual(new Date('2026-09-16T00:00:00Z'));
  });

  it('expires a trial only once its end has passed on the server’s clock', async () => {
    const { sub } = await subscribed('trial', '2026-09-01T09:00:00Z');
    expect((await refusal(at('2026-09-15T08:59:59Z', () => asPlatform(() => expireTrial(scheduler, sub.id))))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    expect((await at('2026-09-15T09:00:00Z', () => asPlatform(() => expireTrial(scheduler, sub.id)))).status).toBe('expired');
    expect((await events(sub.id)).at(-1)).toMatchObject({ event: 'subscription.expired', actor: { type: 'system', source: 'subscription-tests' } });
  });

  it('ends a cancelling subscription only when its paid period is over', async () => {
    const { sub } = await subscribed('active', '2026-09-01T09:00:00Z');
    await asPlatform(() => requestCancellation(superAdmin, sub.id, { reason: 'Seasonal' }));
    expect((await refusal(at('2026-09-30T00:00:00Z', () => asPlatform(() => endCancelledPeriod(scheduler, sub.id))))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    const ended = await at('2026-10-01T09:00:00Z', () => asPlatform(() => endCancelledPeriod(scheduler, sub.id)));
    expect(ended).toMatchObject({ status: 'canceled', cancelAtPeriodEnd: true, cancellationReason: 'Seasonal' });
  });

  it('expires an overdue subscription only once its grace period has run out', async () => {
    const { sub } = await subscribed('active');
    await asPlatform(() => recordPaymentFailed(provider, sub.id));
    // No grace period has started: there is nothing to run out.
    expect((await refusal(asPlatform(() => expireGrace(scheduler, sub.id)))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    process.env.SUBSCRIPTION_GRACE_DAYS = '5';
    await at('2026-09-15T00:00:00Z', () => asPlatform(() => startGracePeriod(scheduler, sub.id, { reason: 'retries_exhausted' })));
    delete process.env.SUBSCRIPTION_GRACE_DAYS;
    expect((await at('2026-09-20T00:00:00Z', () => asPlatform(() => expireGrace(scheduler, sub.id)))).status).toBe('expired');
  });

  it('cancels immediately from every live status', async () => {
    const prepare: Record<string, (id: string) => Promise<unknown>> = {
      trialing: async () => undefined,
      past_due: (id) => asPlatform(() => recordPaymentFailed(provider, id)),
      paused: async (id) => {
        await asPlatform(() => recordPaymentSucceeded(provider, id));
        await asPlatform(() => pauseSubscription(superAdmin, id, { days: 10 }));
      },
      canceling: async (id) => {
        await asPlatform(() => recordPaymentSucceeded(provider, id));
        await asPlatform(() => requestCancellation(superAdmin, id));
      },
    };
    for (const [status, reach] of Object.entries(prepare)) {
      const { sub } = await subscribed('trial');
      await reach(sub.id);
      expect((await asPlatform(() => getSubscription(sub.id))).status, status).toBe(status);
      expect((await asPlatform(() => cancelNow(superAdmin, sub.id))).status, status).toBe('canceled');
    }
  });

  it('refuses a move the machine does not allow, and writes nothing for it', async () => {
    const { sub } = await subscribed('trial');
    for (const attempt of [
      () => requestCancellation(superAdmin, sub.id), // a trial has no paid period to run out
      () => pauseSubscription(superAdmin, sub.id, { days: 10 }),
      () => resumeSubscription(superAdmin, sub.id),
      () => endCancelledPeriod(scheduler, sub.id),
      () => expireGrace(scheduler, sub.id),
    ]) {
      expect((await refusal(asPlatform(attempt))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    }
    await asPlatform(() => cancelNow(superAdmin, sub.id));
    // Nothing moves a subscription that is over.
    expect((await refusal(asPlatform(() => resumeSubscription(superAdmin, sub.id)))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    expect((await refusal(asPlatform(() => recordPaymentSucceeded(provider, sub.id)))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    expect(await events(sub.id)).toHaveLength(2);
  });

  it('lets each move be caused only by who the machine names', async () => {
    const { sub } = await subscribed('trial');
    // A person cannot declare a payment: only a verified provider event or the scheduler can.
    expect((await refusal(asPlatform(() => recordPaymentSucceeded(superAdmin, sub.id)))).status).toBe(403);
    // The scheduler cannot decide to cancel on someone's behalf.
    expect((await refusal(asPlatform(() => cancelNow(scheduler, sub.id)))).status).toBe(403);
    // Nor an instructor, anywhere.
    const instructor: LifecycleActor = { type: 'user', auth: { sub: 'x', role: 'instructor' } };
    expect((await refusal(asPlatform(() => cancelNow(instructor, sub.id)))).status).toBe(403);
    expect(await events(sub.id)).toHaveLength(1);
  });

  it('lets an academy’s own admin act on its subscription from inside it, and no other academy at all', async () => {
    const { tenantId, sub } = await subscribed('active');
    const ownAdmin: LifecycleActor = {
      type: 'user',
      auth: {
        sub: (await platformDb.user.create({ data: { tenantId, email: `own-${unique()}@example.com`, passwordHash: 'x', name: 'Own Admin', role: 'admin' } }))
          .id,
        role: 'admin',
      },
    };
    const canceling = await runInTenant(tenantId, () => requestCancellation(ownAdmin, sub.id, { reason: 'Budget' }));
    expect(canceling.status).toBe('canceling');
    expect((await events(sub.id)).at(-1)?.actor).toMatchObject({ type: 'user', id: (ownAdmin as { auth: { sub: string } }).auth.sub });

    // Another academy cannot even find it.
    const elsewhere = await newAcademy();
    expect((await refusal(runInTenant(elsewhere, () => resumeSubscription(ownAdmin, sub.id)))).status).toBe(404);
    expect((await refusal(runInTenant(elsewhere, () => getSubscription(sub.id)))).status).toBe(404);
  });

  it('lets exactly one of two concurrent moves through', async () => {
    const { sub } = await subscribed('active');
    const results = await Promise.allSettled([
      asPlatform(() => pauseSubscription(superAdmin, sub.id, { days: 10 })),
      asPlatform(() => cancelNow(superAdmin, sub.id)),
    ]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect(await events(sub.id)).toHaveLength(2);
  });
});

describe('the database holds the same rules', () => {
  it('refuses a status written directly, with no lifecycle event', async () => {
    const { sub } = await subscribed('active');
    await expect(platformDb.$executeRawUnsafe(`UPDATE "Subscription" SET "status" = 'canceled' WHERE "id" = ?`, sub.id)).rejects.toThrow(/recorded transition/);
    await expect(platformDb.subscription.update({ where: { id: sub.id }, data: { status: 'expired' } })).rejects.toThrow();
    expect((await asPlatform(() => getSubscription(sub.id))).status).toBe('active');
  });

  it('refuses a status that does not match the latest event, so an old event cannot be replayed', async () => {
    const { sub } = await subscribed('active');
    await asPlatform(() => pauseSubscription(superAdmin, sub.id, { days: 10 }));
    await asPlatform(() => resumeSubscription(superAdmin, sub.id));
    // The log holds active → paused, but the latest event is paused → active: pausing again needs a new event.
    await expect(platformDb.$executeRawUnsafe(`UPDATE "Subscription" SET "status" = 'paused' WHERE "id" = ?`, sub.id)).rejects.toThrow(/recorded transition/);
  });

  it('refuses a subscription created in a later status', async () => {
    const tenantId = await newAcademy();
    const plan = await newPlan();
    await expect(
      platformDb.$executeRawUnsafe(
        `INSERT INTO "Subscription" ("id", "tenantId", "planId", "planVersionId", "status", "billingCycle", "currency", "amount", "currentPeriodStartAt", "currentPeriodEndAt", "updatedAt") VALUES (?, ?, ?, ?, 'past_due', 'monthly', 'INR', 1, 1, 2, 3)`,
        `raw-${unique()}`,
        tenantId,
        plan.id,
        plan.versionId,
      ),
    ).rejects.toThrow(/starts as trialing or active/);
  });

  it('refuses a price, plan or cycle change without a matching plan-change event', async () => {
    const { sub } = await subscribed('active');
    const other = await newPlan({ monthlyPrice: 100, annualPrice: 1000 });
    for (const set of [`"amount" = 1`, `"currency" = 'USD'`, `"billingCycle" = 'annual'`, `"planId" = '${other.id}', "planVersionId" = '${other.versionId}'`]) {
      await expect(platformDb.$executeRawUnsafe(`UPDATE "Subscription" SET ${set} WHERE "id" = ?`, sub.id), set).rejects.toThrow(/plan change|does not belong/);
    }
    // And a version must belong to the plan named beside it.
    await expect(platformDb.$executeRawUnsafe(`UPDATE "Subscription" SET "planVersionId" = ? WHERE "id" = ?`, other.versionId, sub.id)).rejects.toThrow(
      /plan change|does not belong/,
    );
    expect((await asPlatform(() => getSubscription(sub.id))).amount).toBe(399900);
  });

  it('keeps the lifecycle log append-only, and never deletes a subscription', async () => {
    const { sub } = await subscribed('trial');
    await expect(platformDb.$executeRawUnsafe(`UPDATE "SubscriptionEvent" SET "event" = 'x' WHERE "subscriptionId" = ?`, sub.id)).rejects.toThrow(/immutable/);
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "SubscriptionEvent" WHERE "subscriptionId" = ?`, sub.id)).rejects.toThrow(/never deleted/);
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "Subscription" WHERE "id" = ?`, sub.id)).rejects.toThrow(/never deleted/);
  });

  it('allows exactly the status pairs the domain allows — every pair, from every status', async () => {
    /* One subscription in each status, then every (from → to) event tried against it inside a
     * transaction that is always rolled back, so the probe leaves nothing behind. */
    const inStatus: Partial<Record<SubscriptionState, string>> = {};
    const reach: Record<SubscriptionState, (id: string) => Promise<unknown>> = {
      trialing: async () => undefined,
      active: (id) => asPlatform(() => recordPaymentSucceeded(provider, id)),
      past_due: (id) => asPlatform(() => recordPaymentFailed(provider, id)),
      paused: async (id) => {
        await reach.active(id);
        await asPlatform(() => pauseSubscription(superAdmin, id, { days: 10 }));
      },
      canceling: async (id) => {
        await reach.active(id);
        await asPlatform(() => requestCancellation(superAdmin, id));
      },
      canceled: (id) => asPlatform(() => cancelNow(superAdmin, id)),
      expired: (id) => at('2030-01-01T00:00:00Z', () => asPlatform(() => expireTrial(scheduler, id))),
    };
    for (const status of SUBSCRIPTION_STATES) {
      const { sub } = await subscribed('trial');
      await reach[status](sub.id);
      inStatus[status] = sub.id;
    }
    const allowed = new Set(ALLOWED_STATUS_PAIRS.map(([a, b]) => `${a}>${b}`));
    class Rollback extends Error {}
    let checked = 0;
    for (const from of SUBSCRIPTION_STATES) {
      const id = inStatus[from]!;
      const { tenantId } = await platformDb.subscription.findUniqueOrThrow({ where: { id }, select: { tenantId: true } });
      for (const to of SUBSCRIPTION_STATES) {
        const accepted = await platformDb
          .$transaction(async (tx) => {
            await tx.$executeRawUnsafe(
              `INSERT INTO "SubscriptionEvent" ("tenantId", "subscriptionId", "event", "transition", "fromStatus", "toStatus", "actorType", "source") VALUES (?, ?, 'probe', 'probe', ?, ?, 'system', 'probe')`,
              tenantId,
              id,
              from,
              to,
            );
            throw new Rollback();
          })
          .catch((e: unknown) => e instanceof Rollback);
        expect(accepted, `${from} → ${to}`).toBe(allowed.has(`${from}>${to}`));
        checked++;
      }
    }
    expect(checked).toBe(49);
    // And an event must start from where the subscription actually is.
    const activeId = inStatus.active!;
    const { tenantId } = await platformDb.subscription.findUniqueOrThrow({ where: { id: activeId }, select: { tenantId: true } });
    await expect(
      platformDb.$executeRawUnsafe(
        `INSERT INTO "SubscriptionEvent" ("tenantId", "subscriptionId", "event", "transition", "fromStatus", "toStatus", "actorType", "source") VALUES (?, ?, 'x', 'x', 'past_due', 'active', 'system', 'x')`,
        tenantId,
        activeId,
      ),
    ).rejects.toThrow(/not an allowed/);
  });
});

describe('what a subscription grants', () => {
  it('serves its plan version while trialing, active, overdue or cancelling', async () => {
    const { tenantId, plan, sub } = await subscribed('trial');
    expect(await getTenantEntitlements(tenantId)).toMatchObject({
      status: 'trialing',
      planVersionId: plan.versionId,
      features: ['courses.manage', 'reports.basic'],
    });
    await asPlatform(() => recordPaymentFailed(provider, sub.id));
    expect((await getTenantEntitlements(tenantId)).features).toContain('courses.manage');
    await asPlatform(() => recordPaymentSucceeded(provider, sub.id));
    await asPlatform(() => requestCancellation(superAdmin, sub.id));
    expect(await getTenantEntitlements(tenantId)).toMatchObject({ status: 'canceling', planVersionId: plan.versionId });
  });

  it('keeps the version it was sold when the plan is edited, and the price with it', async () => {
    const { tenantId, plan, sub } = await subscribed('active');
    const edited = await asPlatform(() =>
      updatePlan({ auth: (superAdmin as { auth: { sub: string; role: 'superadmin' } }).auth }, plan.id, {
        monthlyPrice: 999900,
        features: ['custom_branding'],
      }),
    );
    expect(edited.current.id).not.toBe(plan.versionId);
    expect((await asPlatform(() => getSubscription(sub.id))).amount).toBe(399900);
    expect(await getTenantEntitlements(tenantId)).toMatchObject({ planVersionId: plan.versionId, features: ['courses.manage', 'reports.basic'] });
  });

  it('grants nothing while paused, and says so; and says an ended subscription has ended', async () => {
    const { tenantId, sub } = await subscribed('active');
    await asPlatform(() => pauseSubscription(superAdmin, sub.id, { days: 10 }));
    expect(await getTenantEntitlements(tenantId)).toMatchObject({ status: 'paused', planVersionId: null, features: [] });
    const paused = await refusal(assertFeature(tenantId, 'courses.manage'));
    expect(paused).toMatchObject({ status: 402, code: 'SUBSCRIPTION_REQUIRED' });

    await asPlatform(() => cancelNow(superAdmin, sub.id));
    const ended = await refusal(assertFeature(tenantId, 'courses.manage'));
    expect(ended).toMatchObject({ status: 402, code: 'SUBSCRIPTION_EXPIRED' });
  });

  it('refuses an academy that has never subscribed as needing a subscription', async () => {
    const tenantId = await newAcademy();
    expect(await refusal(assertFeature(tenantId, 'courses.manage'))).toMatchObject({ status: 402, code: 'SUBSCRIPTION_REQUIRED' });
  });
});
