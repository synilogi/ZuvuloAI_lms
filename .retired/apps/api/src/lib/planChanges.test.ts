import { BYTES_PER_GB, type FeatureKey, type PlanLimits } from '@syniastrolms/domain';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { forTenant } from './db.js';
import { platformDb } from '../test/db.js';
import { unique } from '../test/helpers.js';
import { setClock } from './clock.js';
import { canConsume, getTenantEntitlements } from './entitlements.js';
import { ApiError } from './errors.js';
import { applyDueScheduledChange, cancelPlanChange, confirmPlanChangePayment, getPlanChange, listPlanChanges, requestPlanChange } from './planChanges.js';
import { archivePlan, createPlan, publishPlan, type CreatePlanInput } from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import {
  cancelNow,
  createSubscription,
  getSubscription,
  listLifecycle,
  pauseSubscription,
  recordPaymentFailed,
  recordPaymentSucceeded,
  requestCancellation,
  resumeSubscription,
  type LifecycleActor,
} from './subscriptions.js';
import { runAsPlatform, runInTenant } from './tenancy.js';

/* SAAS-006 — decisions D7–D10, as written in docs/06 › Plan changes. Every subscription starts active on
 * 1 September 2026 at midnight UTC, so its first period is exactly 30 days, to 1 October. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('plan change tests act as the platform', fn);
const provider: LifecycleActor = { type: 'provider', provider: 'testpay', reference: 'pay_1' };
const scheduler: LifecycleActor = { type: 'system', job: 'plan-change-tests' };
let superAdmin: LifecycleActor & { type: 'user' };

const DAY = 86_400_000;
const SEP1 = '2026-09-01T00:00:00Z';

const LIMITS: PlanLimits = {
  'learners.max': 1000,
  'instructors.max': 20,
  'courses.max': 100,
  'storage.bytes': 100 * BYTES_PER_GB,
  'live_classes.max': 50,
  'admin_accounts.max': 5,
};

async function plan(name: string, monthly: number, annual: number, features: FeatureKey[], over: Partial<CreatePlanInput> = {}): Promise<string> {
  return asPlatform(async () => {
    const created = await createPlan(
      { auth: superAdmin.auth },
      {
        name,
        description: `The ${name} plan, for the plan change suite.`,
        code: `C${unique().toUpperCase()}`.slice(0, 24),
        currency: 'INR',
        cycles: ['monthly', 'annual'],
        monthlyPrice: monthly,
        annualPrice: annual,
        trialEnabled: true,
        trialDays: 14,
        features,
        limits: LIMITS,
        ...over,
      },
    );
    await publishPlan({ auth: superAdmin.auth }, created.id);
    return created.id;
  });
}

let STARTER: string; // ₹3,999 a month, ₹39,990 a year
let PRO: string; // ₹8,999 a month, ₹89,990 a year
let SMALL: string; // ₹1,499 a month, at most 1 learner
let SIDEWAYS: string; // ₹3,999 a month too, other features

const at = async <T>(iso: string, fn: () => Promise<T>): Promise<T> => {
  setClock(iso);
  return fn();
};

const refusal = async (promise: Promise<unknown>) => {
  const err = await promise.then(
    () => undefined,
    (e: unknown) => e,
  );
  expect(err, 'expected a refusal').toBeInstanceOf(ApiError);
  return err as ApiError;
};

const newAcademy = async () => (await platformDb.tenant.create({ data: { name: 'Changing Academy', slug: `chg-${unique()}` } })).id;

/** An academy with an active subscription on `planId`, started on 1 September. */
async function onPlan(planId = STARTER, cycle: 'monthly' | 'annual' = 'monthly') {
  const tenantId = await newAcademy();
  const sub = await at(SEP1, () => asPlatform(() => createSubscription(superAdmin, { tenantId, planId, cycle, start: 'active' })));
  return { tenantId, sub };
}

const ask = (subId: string, planId: string, cycle: 'monthly' | 'annual' = 'monthly', extra: object = {}) =>
  asPlatform(() => requestPlanChange(superAdmin, subId, { planId, cycle, ...extra }));

const confirm = (changeId: string) => asPlatform(() => confirmPlanChangePayment(provider, changeId));

beforeAll(async () => {
  const created = await provisionSuperAdmin({ email: `changes-${unique()}@example.com`, password: 'changes-suite-password', name: 'Billing' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
  STARTER = await plan('Starter', 399900, 3999000, ['courses.manage']);
  PRO = await plan('Pro', 899900, 8999000, ['courses.manage', 'reports.basic', 'custom_branding']);
  SMALL = await plan('Small', 149900, 1499000, ['courses.manage'], { limits: { ...LIMITS, 'learners.max': 1 } });
  SIDEWAYS = await plan('Sideways', 399900, 3999000, ['courses.manage', 'live_classes']);
});

afterEach(() => setClock(null));

describe('a prorated upgrade (D7)', () => {
  it('charges only the difference for the rest of the period: ₹3,999 → ₹8,999 halfway is ₹2,500', async () => {
    const { sub } = await onPlan();
    const change = await at('2026-09-16T00:00:00Z', () => ask(sub.id, PRO));
    expect(change).toMatchObject({
      kind: 'upgrade',
      status: 'pending_payment',
      from: { amount: 399900, cycle: 'monthly' },
      to: { amount: 899900, cycle: 'monthly' },
      credit: 199950,
      charge: 250000,
      forfeited: 0,
      period: { start: '2026-09-01T00:00:00.000Z', end: '2026-10-01T00:00:00.000Z' },
    });
  });

  it('does not activate the new plan until the payment is confirmed — and then keeps the renewal date', async () => {
    const { tenantId, sub } = await onPlan();
    const change = await at('2026-09-16T00:00:00Z', () => ask(sub.id, PRO));
    // Asked for and quoted, but not paid: still Starter, still Starter's features.
    expect((await asPlatform(() => getSubscription(sub.id))).amount).toBe(399900);
    expect((await getTenantEntitlements(tenantId)).features).toEqual(['courses.manage']);

    const moved = await at('2026-09-16T00:05:00Z', () => confirm(change.id));
    expect(moved).toMatchObject({
      amount: 899900,
      billingCycle: 'monthly',
      currentPeriodStartAt: '2026-09-01T00:00:00.000Z',
      currentPeriodEndAt: '2026-10-01T00:00:00.000Z',
    });
    expect((await getTenantEntitlements(tenantId)).features).toEqual(['courses.manage', 'reports.basic', 'custom_branding']);
    expect(await asPlatform(() => getPlanChange(change.id))).toMatchObject({ status: 'applied', appliedAt: '2026-09-16T00:05:00.000Z' });
    expect((await asPlatform(() => listLifecycle(sub.id))).at(-1)).toMatchObject({
      transition: 'change_plan',
      event: 'subscription.plan_changed',
      actor: { type: 'provider', source: 'testpay' },
      meta: { planChangeId: change.id, kind: 'upgrade', credit: 199950, charge: 250000, providerReference: 'pay_1' },
    });

    // The renewal that follows is at the new price, on the unchanged date.
    const renewed = await at('2026-10-01T00:00:00Z', () => asPlatform(() => recordPaymentSucceeded(provider, sub.id)));
    expect(renewed).toMatchObject({ amount: 899900, currentPeriodStartAt: '2026-10-01T00:00:00.000Z', currentPeriodEndAt: '2026-11-01T00:00:00.000Z' });
  });

  it('never takes a price from the request', async () => {
    const { sub } = await onPlan();
    const change = await at('2026-09-16T00:00:00Z', () => ask(sub.id, PRO, 'monthly', { charge: 1, credit: 9_999_999, amount: 5 }));
    expect(change).toMatchObject({ credit: 199950, charge: 250000, to: { amount: 899900 } });
  });

  it('is confirmed by a verified provider payment and nothing else — once', async () => {
    const { sub } = await onPlan();
    const change = await at('2026-09-16T00:00:00Z', () => ask(sub.id, PRO));
    expect((await refusal(asPlatform(() => confirmPlanChangePayment(superAdmin, change.id)))).status).toBe(403);
    expect((await refusal(asPlatform(() => confirmPlanChangePayment(scheduler, change.id)))).status).toBe(403);
    const results = await at('2026-09-16T01:00:00Z', () => Promise.allSettled([confirm(change.id), confirm(change.id)]));
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect((await asPlatform(() => listLifecycle(sub.id))).filter((e) => e.transition === 'change_plan')).toHaveLength(1);
  });

  it('expires a quote whose period ended before payment, and leaves the subscription alone', async () => {
    const { sub } = await onPlan();
    const change = await at('2026-09-30T00:00:00Z', () => ask(sub.id, PRO));
    expect(change.charge).toBe(prorateCheck(500000, 1, 30));
    expect((await refusal(at('2026-10-01T00:00:00Z', () => confirm(change.id)))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    expect(await asPlatform(() => getPlanChange(change.id))).toMatchObject({ status: 'expired' });
    expect((await asPlatform(() => getSubscription(sub.id))).amount).toBe(399900);
  });

  it('voids a quote when the subscription changed after it was priced', async () => {
    const { sub } = await onPlan();
    const change = await at('2026-09-10T00:00:00Z', () => ask(sub.id, PRO));
    // A pause and resume moved the period end: the quote was priced against a period that no longer is.
    await at('2026-09-11T00:00:00Z', () => asPlatform(() => pauseSubscription(superAdmin, sub.id, { days: 5 })));
    await at('2026-09-13T00:00:00Z', () => asPlatform(() => resumeSubscription(superAdmin, sub.id)));
    expect((await refusal(at('2026-09-14T00:00:00Z', () => confirm(change.id)))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    expect(await asPlatform(() => getPlanChange(change.id))).toMatchObject({ status: 'void' });
  });
});

/** The rounding the domain uses, restated: amount × part ÷ whole, half up. */
function prorateCheck(amount: number, part: number, whole: number) {
  return Math.floor((2 * amount * part + whole) / (2 * whole));
}

describe('monthly → annual with the unused month as credit (D8)', () => {
  it('credits the unused month against the annual price, and starts the year on the effective date', async () => {
    const { sub } = await onPlan();
    const change = await at('2026-09-16T00:00:00Z', () => ask(sub.id, STARTER, 'annual'));
    expect(change).toMatchObject({ kind: 'cycle_upgrade', credit: 199950, charge: 3799050, forfeited: 0, to: { amount: 3999000, cycle: 'annual' } });

    const moved = await at('2026-09-16T06:30:00Z', () => confirm(change.id));
    expect(moved).toMatchObject({
      billingCycle: 'annual',
      amount: 3999000,
      planVersionId: sub.planVersionId,
      currentPeriodStartAt: '2026-09-16T06:30:00.000Z',
      currentPeriodEndAt: '2027-09-16T06:30:00.000Z',
    });
    expect((await asPlatform(() => listLifecycle(sub.id))).at(-1)?.meta).toMatchObject({
      credit: 199950,
      charge: 3799050,
      period: { endMs: Date.parse('2027-09-16T06:30:00Z') },
    });
  });

  it('keeps the complete pricing and subscription history', async () => {
    const { sub } = await onPlan();
    const first = await at('2026-09-10T00:00:00Z', () => ask(sub.id, PRO));
    await at('2026-09-10T00:01:00Z', () => confirm(first.id));
    const second = await at('2026-09-20T00:00:00Z', () => ask(sub.id, PRO, 'annual'));
    await at('2026-09-20T00:01:00Z', () => confirm(second.id));
    const history = await asPlatform(() => listPlanChanges(sub.id));
    expect(history.map((c) => [c.kind, c.status, c.from.amount, c.to.amount])).toEqual([
      ['cycle_upgrade', 'applied', 899900, 8999000],
      ['upgrade', 'applied', 399900, 899900],
    ]);
    // Credit on the second is the unused 11 of 30 days (20 September to 1 October) of a ₹8,999 month.
    expect(second.credit).toBe(prorateCheck(899900, 11, 30));
    expect((await asPlatform(() => listLifecycle(sub.id))).map((e) => e.transition)).toEqual(['create', 'change_plan', 'change_plan']);
  });

  it('prices monthly → annual on another plan the same way', async () => {
    const { sub } = await onPlan();
    const change = await at('2026-09-01T00:00:00Z', () => ask(sub.id, PRO, 'annual'));
    // At the very start the whole month is unused.
    expect(change).toMatchObject({ kind: 'cycle_upgrade', credit: 399900, charge: 8999000 - 399900 });
  });
});

describe('a downgrade at the period boundary (D10)', () => {
  async function withLearners(tenantId: string, n: number) {
    const odb = forTenant(tenantId);
    for (let i = 0; i < n; i++) {
      const user = await odb.user.create({ data: { tenantId, email: `dl-${unique()}@example.com`, passwordHash: 'x', name: 'Learner', role: 'student' } });
      await odb.student.create({ data: { tenantId, userId: user.id } });
    }
  }

  it('waits for the boundary, keeps the current plan until then, refunds nothing, and reports the limit conflict', async () => {
    const { tenantId, sub } = await onPlan(PRO);
    await withLearners(tenantId, 2);
    const change = await at('2026-09-10T00:00:00Z', () => ask(sub.id, SMALL));
    expect(change).toMatchObject({
      kind: 'downgrade',
      status: 'scheduled',
      credit: 0,
      charge: 0,
      forfeited: 0,
      conflicts: [{ limit: 'learners.max', usage: 2, newLimit: 1 }],
    });

    // Until the period ends: Pro, and Pro's entitlements.
    expect((await getTenantEntitlements(tenantId)).features).toContain('custom_branding');
    expect((await refusal(at('2026-09-30T23:59:59Z', () => asPlatform(() => applyDueScheduledChange(scheduler, sub.id))))).code).toBe(
      'INVALID_SUBSCRIPTION_STATE',
    );

    const moved = await at('2026-10-01T00:00:00Z', () => asPlatform(() => applyDueScheduledChange(scheduler, sub.id)));
    expect(moved).toMatchObject({ amount: 149900, currentPeriodStartAt: '2026-09-01T00:00:00.000Z', currentPeriodEndAt: '2026-10-01T00:00:00.000Z' });
    expect((await getTenantEntitlements(tenantId)).features).toEqual(['courses.manage']);
    // The next period is billed at the new price.
    const renewed = await at('2026-10-01T00:00:01Z', () => asPlatform(() => recordPaymentSucceeded(provider, sub.id)));
    expect(renewed).toMatchObject({ amount: 149900, currentPeriodEndAt: '2026-11-01T00:00:00.000Z' });
  });

  it('keeps the data over the new limit and restricts new usage', async () => {
    const { tenantId, sub } = await onPlan(PRO);
    await withLearners(tenantId, 3);
    await at('2026-09-10T00:00:00Z', () => ask(sub.id, SMALL));
    await at('2026-10-01T00:00:00Z', () => asPlatform(() => applyDueScheduledChange(scheduler, sub.id)));
    // Nothing deleted: all three learners are still there.
    expect(await platformDb.student.count({ where: { tenantId } })).toBe(3);
    // And there is no room for a fourth — or even a second.
    expect(await runInTenant(tenantId, () => canConsume(tenantId, 'learners.max'))).toMatchObject({ allowed: false, limit: 1, usage: 3, remaining: 0 });
    // A limit it still fits is unaffected.
    expect((await runInTenant(tenantId, () => canConsume(tenantId, 'courses.max'))).allowed).toBe(true);
  });

  it('treats annual → monthly and a same-price switch as boundary changes, too', async () => {
    const annual = await onPlan(STARTER, 'annual');
    const toMonthly = await at('2026-09-10T00:00:00Z', () => ask(annual.sub.id, STARTER, 'monthly'));
    expect(toMonthly).toMatchObject({ kind: 'downgrade', status: 'scheduled', charge: 0, period: { end: '2027-09-01T00:00:00.000Z' } });

    const monthly = await onPlan();
    expect(await at('2026-09-10T00:00:00Z', () => ask(monthly.sub.id, SIDEWAYS))).toMatchObject({ kind: 'scheduled_change', status: 'scheduled', charge: 0 });
  });

  it('is applied only by the scheduler', async () => {
    const { sub } = await onPlan(PRO);
    await at('2026-09-10T00:00:00Z', () => ask(sub.id, SMALL));
    expect((await refusal(at('2026-10-01T00:00:00Z', () => asPlatform(() => applyDueScheduledChange(superAdmin, sub.id))))).status).toBe(403);
    expect((await refusal(at('2026-10-01T00:00:00Z', () => asPlatform(() => applyDueScheduledChange(provider, sub.id))))).status).toBe(403);
  });
});

describe('what a change needs', () => {
  it('holds one open change at a time; a withdrawn one frees the slot', async () => {
    const { sub } = await onPlan();
    const first = await at('2026-09-10T00:00:00Z', () => ask(sub.id, PRO));
    expect((await refusal(ask(sub.id, SMALL))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    const withdrawn = await asPlatform(() => cancelPlanChange(superAdmin, first.id, { reason: 'Changed our mind' }));
    expect(withdrawn).toMatchObject({ status: 'canceled', closedReason: 'Changed our mind' });
    expect((await at('2026-09-10T00:00:00Z', () => ask(sub.id, SMALL))).status).toBe('scheduled');
    // The database holds the same line.
    const open = await platformDb.planChange.findFirstOrThrow({ where: { subscriptionId: sub.id, status: 'scheduled' } });
    await expect(
      platformDb.$executeRawUnsafe(
        `INSERT INTO "PlanChange" ("id","tenantId","subscriptionId","kind","status","fromPlanVersionId","fromCycle","fromAmount","toPlanId","toPlanVersionId","toCycle","toAmount","currency","periodStartAt","periodEndAt","quotedAt") SELECT ?, "tenantId","subscriptionId","kind","status","fromPlanVersionId","fromCycle","fromAmount","toPlanId","toPlanVersionId","toCycle","toAmount","currency","periodStartAt","periodEndAt","quotedAt" FROM "PlanChange" WHERE "id" = ?`,
        `dup-${unique()}`,
        open.id,
      ),
    ).rejects.toThrow(/UNIQUE/);
  });

  it('refuses a trial, an overdue subscription, no change, a plan not on sale and another currency', async () => {
    const trialAcademy = await newAcademy();
    const trial = await at(SEP1, () =>
      asPlatform(() => createSubscription(superAdmin, { tenantId: trialAcademy, planId: STARTER, cycle: 'monthly', start: 'trial' })),
    );
    expect((await refusal(ask(trial.id, PRO))).message).toMatch(/trial/);

    const due = await onPlan();
    await asPlatform(() => recordPaymentFailed(provider, due.sub.id));
    expect((await refusal(ask(due.sub.id, PRO))).code).toBe('INVALID_SUBSCRIPTION_STATE');

    const { sub } = await onPlan();
    expect((await refusal(at('2026-09-10T00:00:00Z', () => ask(sub.id, STARTER)))).code).toBe('INVALID_SUBSCRIPTION_STATE');

    const retired = await plan('Retired', 999900, 9999000, ['courses.manage']);
    await asPlatform(() => archivePlan({ auth: superAdmin.auth }, retired));
    expect((await refusal(at('2026-09-10T00:00:00Z', () => ask(sub.id, retired)))).code).toBe('PLAN_UNAVAILABLE');

    const dollars = await plan('Dollars', 5000, 50000, ['courses.manage'], { currency: 'USD' });
    expect((await refusal(at('2026-09-10T00:00:00Z', () => ask(sub.id, dollars)))).code).toBe('PLAN_UNAVAILABLE');
  });

  it('refuses an upgrade once the period has ended, until it renews', async () => {
    const { sub } = await onPlan();
    expect((await refusal(at('2026-10-01T00:00:00Z', () => ask(sub.id, PRO)))).message).toMatch(/period has ended/);
  });

  it('is asked for by a super admin or the academy’s own admin, never anyone else', async () => {
    const { tenantId, sub } = await onPlan();
    const ownAdmin = await platformDb.user.create({ data: { tenantId, email: `own-${unique()}@example.com`, passwordHash: 'x', name: 'Own', role: 'admin' } });
    const own: LifecycleActor = { type: 'user', auth: { sub: ownAdmin.id, role: 'admin' } };
    const change = await at('2026-09-10T00:00:00Z', () => runInTenant(tenantId, () => requestPlanChange(own, sub.id, { planId: PRO, cycle: 'monthly' })));
    expect(change.charge).toBeGreaterThan(0);
    const audit = await platformDb.auditLog.findFirstOrThrow({ where: { targetId: sub.id, action: 'subscription.plan_change_requested' } });
    expect(audit).toMatchObject({ actorId: ownAdmin.id, actorRole: 'admin' });

    const elsewhere = await newAcademy();
    expect((await refusal(runInTenant(elsewhere, () => requestPlanChange(own, sub.id, { planId: SMALL, cycle: 'monthly' })))).status).toBe(404);
    const instructor: LifecycleActor = { type: 'user', auth: { sub: 'i', role: 'instructor' } };
    expect((await refusal(asPlatform(() => requestPlanChange(instructor, sub.id, { planId: SMALL, cycle: 'monthly' })))).status).toBe(403);
    expect((await refusal(asPlatform(() => requestPlanChange(provider, sub.id, { planId: SMALL, cycle: 'monthly' })))).status).toBe(403);
  });

  it('voids an open change when the subscription ends', async () => {
    const { sub } = await onPlan(PRO);
    const change = await at('2026-09-10T00:00:00Z', () => ask(sub.id, SMALL));
    await asPlatform(() => cancelNow(superAdmin, sub.id, { reason: 'Closing' }));
    expect(await asPlatform(() => getPlanChange(change.id))).toMatchObject({ status: 'void', closedReason: 'The subscription is canceled.' });
  });
});

describe('the database keeps quotes and period dates honest', () => {
  it('never alters a quote, moves its status only forward, and never deletes it', async () => {
    const { sub } = await onPlan();
    const change = await at('2026-09-16T00:00:00Z', () => ask(sub.id, PRO));
    await expect(platformDb.$executeRawUnsafe(`UPDATE "PlanChange" SET "charge" = 1 WHERE "id" = ?`, change.id)).rejects.toThrow(/never altered/);
    // Marked applied without the subscription's own change_plan event: refused.
    await expect(platformDb.$executeRawUnsafe(`UPDATE "PlanChange" SET "status" = 'applied' WHERE "id" = ?`, change.id)).rejects.toThrow(
      /change_plan transition/,
    );
    await at('2026-09-16T00:05:00Z', () => confirm(change.id));
    await expect(platformDb.$executeRawUnsafe(`UPDATE "PlanChange" SET "status" = 'pending_payment' WHERE "id" = ?`, change.id)).rejects.toThrow(/cannot move/);
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "PlanChange" WHERE "id" = ?`, change.id)).rejects.toThrow(/never deleted/);
  });

  it('refuses a downgrade that claims to move money', async () => {
    const { sub } = await onPlan(PRO);
    const change = await at('2026-09-10T00:00:00Z', () => ask(sub.id, SMALL));
    await asPlatform(() => cancelPlanChange(superAdmin, change.id));
    await expect(
      platformDb.$executeRawUnsafe(
        `INSERT INTO "PlanChange" ("id","tenantId","subscriptionId","kind","status","fromPlanVersionId","fromCycle","fromAmount","toPlanId","toPlanVersionId","toCycle","toAmount","currency","charge","periodStartAt","periodEndAt","quotedAt") SELECT ?, "tenantId","subscriptionId",'downgrade','scheduled',"fromPlanVersionId","fromCycle","fromAmount","toPlanId","toPlanVersionId","toCycle","toAmount","currency",500,"periodStartAt","periodEndAt","quotedAt" FROM "PlanChange" WHERE "id" = ?`,
        `bad-${unique()}`,
        change.id,
      ),
    ).rejects.toThrow(/starts awaiting payment/);
  });

  it('moves a renewal date only with a recorded transition', async () => {
    const { sub } = await onPlan();
    await expect(
      platformDb.$executeRawUnsafe(`UPDATE "Subscription" SET "currentPeriodEndAt" = "currentPeriodEndAt" + 86400000 WHERE "id" = ?`, sub.id),
    ).rejects.toThrow(/period dates/);
    await expect(platformDb.subscription.update({ where: { id: sub.id }, data: { currentPeriodStartAt: new Date('2020-01-01') } })).rejects.toThrow();
    expect((await asPlatform(() => getSubscription(sub.id))).currentPeriodEndAt).toBe('2026-10-01T00:00:00.000Z');
  });
});

describe('pauses (D9)', () => {
  it('extends the period by the time actually paused, when resumed early', async () => {
    const { sub } = await onPlan();
    const paused = await at('2026-09-05T00:00:00Z', () => asPlatform(() => pauseSubscription(superAdmin, sub.id, { days: 10 })));
    expect(paused).toMatchObject({ status: 'paused', pausedAt: '2026-09-05T00:00:00.000Z', resumesAt: '2026-09-15T00:00:00.000Z' });
    const back = await at('2026-09-08T00:00:00Z', () => asPlatform(() => resumeSubscription(superAdmin, sub.id)));
    expect(back).toMatchObject({ status: 'active', currentPeriodEndAt: '2026-10-04T00:00:00.000Z' });
    expect((await asPlatform(() => listLifecycle(sub.id))).at(-1)).toMatchObject({
      event: 'subscription.resumed',
      meta: { resumedFrom: 'paused', pausedAt: '2026-09-05T00:00:00.000Z', extensionMs: 3 * DAY, previousPeriodEndAt: '2026-10-01T00:00:00.000Z' },
    });
  });

  it('lets the scheduler resume only once the pause is due, and never extends past the pause planned', async () => {
    const { sub } = await onPlan();
    await at('2026-09-05T00:00:00Z', () => asPlatform(() => pauseSubscription(superAdmin, sub.id, { days: 10 })));
    expect((await refusal(at('2026-09-14T23:59:59Z', () => asPlatform(() => resumeSubscription(scheduler, sub.id))))).code).toBe('INVALID_SUBSCRIPTION_STATE');
    // Resumed five days late by the job: the academy is not charged for time it did not ask to pause, nor
    // given it — the extension is the planned ten days.
    const back = await at('2026-09-20T00:00:00Z', () => asPlatform(() => resumeSubscription(scheduler, sub.id)));
    expect(back.currentPeriodEndAt).toBe('2026-10-11T00:00:00.000Z');
  });

  it('allows at most 30 days, and takes no dates from the caller', async () => {
    const a = await onPlan();
    expect((await refusal(at('2026-09-05T00:00:00Z', () => asPlatform(() => pauseSubscription(superAdmin, a.sub.id, { days: 31 }))))).status).toBe(400);
    for (const days of [0, 2.5, -3])
      expect((await refusal(asPlatform(() => pauseSubscription(superAdmin, a.sub.id, { days })))).status, String(days)).toBe(400);
    const thirty = await at('2026-09-05T00:00:00Z', () => asPlatform(() => pauseSubscription(superAdmin, a.sub.id, { days: 30 })));
    expect(thirty.resumesAt).toBe('2026-10-05T00:00:00.000Z');
    const back = await at('2026-12-01T00:00:00Z', () => asPlatform(() => resumeSubscription(superAdmin, a.sub.id)));
    expect(back.currentPeriodEndAt).toBe('2026-10-31T00:00:00.000Z'); // + 30 days, however long it really took

    const b = await onPlan();
    const sneaky = await at('2026-09-05T00:00:00Z', () =>
      asPlatform(() =>
        pauseSubscription(superAdmin, b.sub.id, { days: 5, resumesAt: new Date('2027-01-01'), currentPeriodEndAt: new Date('2030-01-01') } as never),
      ),
    );
    expect(sneaky).toMatchObject({ resumesAt: '2026-09-10T00:00:00.000Z', currentPeriodEndAt: '2026-10-01T00:00:00.000Z' });
  });
});

describe('cancel and resume keep their records (§12)', () => {
  it('records the actor, time, reason and effective date of each', async () => {
    const { sub } = await onPlan();
    const actorId = superAdmin.auth.sub;

    const canceling = await at('2026-09-10T08:00:00Z', () => asPlatform(() => requestCancellation(superAdmin, sub.id, { reason: 'Budget review' })));
    expect(canceling).toMatchObject({ cancelAtPeriodEnd: true, cancelRequestedAt: '2026-09-10T08:00:00.000Z', cancellationReason: 'Budget review' });
    const resumed = await at('2026-09-12T09:00:00Z', () => asPlatform(() => resumeSubscription(superAdmin, sub.id, { reason: 'Budget approved' })));
    expect(resumed).toMatchObject({ status: 'active', cancelAtPeriodEnd: false });
    const closed = await at('2026-09-20T10:00:00Z', () => asPlatform(() => cancelNow(superAdmin, sub.id, { reason: 'Closing the academy' })));
    expect(closed).toMatchObject({ canceledAt: '2026-09-20T10:00:00.000Z', cancellationReason: 'Closing the academy' });

    const log = (await asPlatform(() => listLifecycle(sub.id))).slice(1);
    expect(log.map((e) => ({ transition: e.transition, at: e.at, actor: e.actor, reason: e.meta.reason, effectiveAt: e.meta.effectiveAt }))).toEqual([
      {
        transition: 'request_cancel',
        at: '2026-09-10T08:00:00.000Z',
        actor: { type: 'user', id: actorId },
        reason: 'Budget review',
        effectiveAt: '2026-10-01T00:00:00.000Z',
      },
      {
        transition: 'resume',
        at: '2026-09-12T09:00:00.000Z',
        actor: { type: 'user', id: actorId },
        reason: 'Budget approved',
        effectiveAt: '2026-09-12T09:00:00.000Z',
      },
      {
        transition: 'cancel_now',
        at: '2026-09-20T10:00:00.000Z',
        actor: { type: 'user', id: actorId },
        reason: 'Closing the academy',
        effectiveAt: '2026-09-20T10:00:00.000Z',
      },
    ]);
  });

  it('never lets the scheduler withdraw a cancellation', async () => {
    const { sub } = await onPlan();
    await asPlatform(() => requestCancellation(superAdmin, sub.id));
    expect((await refusal(asPlatform(() => resumeSubscription(scheduler, sub.id)))).status).toBe(403);
  });
});
