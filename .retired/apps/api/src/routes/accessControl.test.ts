import { BYTES_PER_GB, FEATURES, FEATURE_KEYS, type FeatureKey } from '@syniastrolms/domain';
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { setClock } from '../lib/clock.js';
import { forTenant } from '../lib/db.js';
import { GATED_FEATURES, setTenantPlanSource } from '../lib/entitlements.js';
import { setPaymentProvider } from '../lib/paymentProvider.js';
import { runAsPlatform } from '../lib/tenancy.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { expireTrial, recordPaymentFailed, startGracePeriod } from '../lib/subscriptions.js';
import { ACADEMY, platformDb } from '../test/db.js';
import { FakeProvider } from '../test/fakeProvider.js';
import { PASSWORD, anon, as, unique, type Client } from '../test/helpers.js';

/* SAAS-025. The six layers — authentication, tenant, permission, subscription, entitlement, usage — are separate,
 * and with ENTITLEMENT_ENFORCEMENT on each refuses on its own: a plan never grants or restores a permission, a
 * permission never bypasses a plan, a limit holds under both, and restricted mode never gives an academy more than
 * the plan it last had. */

const scheduler = { type: 'system' as const, job: 'access-control-tests' };
let platform: Client;
const plans: Record<'full' | 'noLive' | 'tight' | 'trial' | 'noReports', string> = {} as never;

const limits = {
  'learners.max': 100,
  'instructors.max': 10,
  'courses.max': 20,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 20,
  'admin_accounts.max': 5,
};
const ROUTED: FeatureKey[] = [
  'courses.manage',
  'assessments.manage',
  'certificates.manage',
  'live_classes',
  'reports.basic',
  'reports.advanced',
  'custom_branding',
];

async function plan(features: FeatureKey[], over: Record<string, unknown> = {}): Promise<string> {
  const created = await platform.post('/superadmin/plans', {
    name: `Access Plan ${unique()}`,
    description: 'A plan for the access-control suite.',
    code: `AC${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly'],
    monthlyPrice: 100000,
    annualPrice: 0,
    trialEnabled: false,
    trialDays: 0,
    limits,
    features,
    ...over,
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  expect((await platform.post(`/superadmin/plans/${created.body.id}/publish`)).status).toBe(200);
  return created.body.id as string;
}

interface Academy {
  tenantId: string;
  subscriptionId?: string;
  admin: Client;
  adminId: string;
  levelId: string;
  categoryId: string;
  courseId: string;
  instructorId: string;
}

/** A new academy with an admin (every permission), one course and one active instructor, on `planId` — or none. */
async function academy(planId: string | null, start: 'active' | 'trial' = 'active'): Promise<Academy> {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Access Academy', slug: `ac-${unique()}`.toLowerCase() } })).id;
  let subscriptionId: string | undefined;
  if (planId) {
    const sub = await platform.post('/superadmin/subscriptions', { tenantId, planId, cycle: 'monthly', start });
    expect(sub.status, JSON.stringify(sub.body)).toBe(201);
    subscriptionId = sub.body.id;
  }
  const email = `ac-admin-${unique()}@example.com`;
  const made = await platform.post('/superadmin/admins', { name: 'Access Admin', email, password: PASSWORD, tenantId });
  expect(made.status, JSON.stringify(made.body)).toBe(201);
  const odb = forTenant(tenantId);
  const t = { tenantId };
  const level = await odb.level.create({ data: { ...t, name: 'Level', order: 1 } });
  const category = await odb.category.create({
    data: { ...t, name: `Category ${unique()}`, description: 'Access.', order: 1, status: 'active', glyph: 'sun' },
  });
  const course = await odb.course.create({
    data: { ...t, slug: `c-${unique()}`, title: `Course ${unique()}`, levelId: level.id, categoryId: category.id, format: 'self-paced', coverMotif: 'orbits' },
  });
  const instructor = await odb.instructor.create({
    data: { ...t, name: 'Access Teacher', title: 'Teacher', email: `ac-teacher-${unique()}@example.com`, status: 'active' },
  });
  // The host of a class teaches its course.
  await odb.courseInstructor.create({ data: { ...t, courseId: course.id, instructorId: instructor.id } });
  return {
    tenantId,
    subscriptionId,
    admin: await as({ email, password: PASSWORD }),
    adminId: made.body.id,
    levelId: level.id,
    categoryId: category.id,
    courseId: course.id,
    instructorId: instructor.id,
  };
}

const newCourse = (a: Academy) => a.admin.post('/courses', { title: `Course ${unique()}`, levelId: a.levelId, categoryId: a.categoryId });
const newLive = (a: Academy) =>
  a.admin.post('/live', {
    courseId: a.courseId,
    instructorId: a.instructorId,
    title: `Class ${unique()}`,
    startsAt: new Date(Date.now() + 3 * 86_400_000).toISOString(),
    durationMin: 60,
  });
const revoke = (a: Academy, key: string) => platform.delete(`/superadmin/admins/${a.adminId}/permissions/${key}`);
const grant = (a: Academy, key: string) => platform.post(`/superadmin/admins/${a.adminId}/permissions`, { key });
const permissionsOf = (a: Academy) =>
  platformDb.adminPermission.findMany({ where: { userId: a.adminId }, select: { key: true } }).then((r) => r.map((p) => p.key).sort());
const outcome = (r: { status: number; body: { code?: string } }) => (r.status < 300 ? 'ALLOW' : `${r.status} ${r.body.code ?? ''}`.trim());

beforeAll(async () => {
  const email = `ac-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Access Platform' });
  platform = await as({ email, password: PASSWORD });
  plans.full = await plan(ROUTED);
  plans.noLive = await plan(['courses.manage', 'assessments.manage', 'reports.basic']);
  plans.noReports = await plan(['courses.manage', 'assessments.manage']);
  plans.tight = await plan(ROUTED, { limits: { ...limits, 'courses.max': 1, 'live_classes.max': 1, 'instructors.max': 2 } });
  plans.trial = await plan(ROUTED, { trialEnabled: true, trialDays: 14 });
});

beforeEach(() => {
  process.env.ENTITLEMENT_ENFORCEMENT = 'on';
  process.env.SUBSCRIPTION_GRACE_DAYS = '7';
});

afterEach(() => {
  delete process.env.ENTITLEMENT_ENFORCEMENT;
  delete process.env.SUBSCRIPTION_GRACE_DAYS;
  setTenantPlanSource(null);
  setPaymentProvider(undefined);
  setClock(null);
});

afterAll(() => setClock(null));

describe('a permission and a plan are separate, and both must pass', () => {
  it('A — no live-class permission, plan includes live classes: PERMISSION_DENIED, and the plan changes no grant', async () => {
    const a = await academy(plans.full);
    await revoke(a, 'live.manage');
    const before = await permissionsOf(a);
    const res = await newLive(a);
    expect(outcome(res)).toBe('403 PERMISSION_DENIED');
    expect(await permissionsOf(a)).toEqual(before);
  });

  it('B — permission, plan without live classes: FEATURE_NOT_INCLUDED', async () => {
    const a = await academy(plans.noLive);
    expect(outcome(await newLive(a))).toBe('403 FEATURE_NOT_INCLUDED');
  });

  it('C — permission, plan includes it, usage available: allowed', async () => {
    const a = await academy(plans.full);
    expect(outcome(await newLive(a))).toBe('ALLOW');
  });

  it('D — permission, plan includes it, the limit reached: LIMIT_REACHED', async () => {
    const a = await academy(plans.tight);
    expect(outcome(await newLive(a))).toBe('ALLOW');
    expect(outcome(await newLive(a))).toBe('403 LIMIT_REACHED');
  });

  it('E — a permission revoked after the subscription started is refused on the very next request', async () => {
    const a = await academy(plans.full);
    expect(outcome(await newCourse(a))).toBe('ALLOW');
    await revoke(a, 'catalog.edit');
    expect(outcome(await newCourse(a))).toBe('403 PERMISSION_DENIED');
  });

  it('F — a permission granted later works only where the plan also allows it', async () => {
    const withLive = await academy(plans.full);
    const withoutLive = await academy(plans.noLive);
    for (const a of [withLive, withoutLive]) await revoke(a, 'live.manage');
    expect(outcome(await newLive(withLive))).toBe('403 PERMISSION_DENIED');
    for (const a of [withLive, withoutLive]) await grant(a, 'live.manage');
    expect(outcome(await newLive(withLive))).toBe('ALLOW');
    expect(outcome(await newLive(withoutLive))).toBe('403 FEATURE_NOT_INCLUDED');
  });
});

describe('buying a plan never grants a permission', () => {
  it('keeps a revoked permission revoked through a paid first purchase, until it is granted on its own', async () => {
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(null);
    await revoke(a, 'live.manage');
    const before = await permissionsOf(a);
    expect(outcome(await newLive(a))).toBe('403 PERMISSION_DENIED');
    await a.admin.put('/tenant/billing-profile', {
      legalName: 'Access Academy Pvt Ltd',
      email: 'accounts@access.example',
      addressLine1: '1 MG Road',
      city: 'Bengaluru',
      region: 'KA',
      postalCode: '560001',
      country: 'IN',
    });

    const checkout = await a.admin.post('/tenant/billing/purchase', { planId: plans.full, cycle: 'monthly' });
    expect(checkout.status, JSON.stringify(checkout.body)).toBe(201);
    const orderId = checkout.body.checkout.orderId as string;
    const paid = fake.pay(orderId, 'paid');
    const confirmed = await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: paid.paymentId, signature: paid.signature });
    expect(confirmed.status, JSON.stringify(confirmed.body)).toBe(200);
    expect((await platformDb.subscription.findFirstOrThrow({ where: { tenantId: a.tenantId } })).status).toBe('active');

    expect(await permissionsOf(a)).toEqual(before);
    expect((await a.admin.get('/auth/me')).body.user.permissions).not.toContain('live.manage');
    expect(outcome(await newLive(a))).toBe('403 PERMISSION_DENIED');

    await grant(a, 'live.manage');
    expect((await a.admin.get('/auth/me')).body.user.permissions).toContain('live.manage');
    expect(outcome(await newLive(a))).toBe('ALLOW');
  });
});

describe('activating an instructor takes a seat, and cannot pass the limit', () => {
  // `tight` allows 2 instructors; each academy starts with one active.
  const addInstructor = (a: Academy, status: 'active' | 'invited' | 'inactive') =>
    a.admin.post('/instructors', {
      name: `Teacher ${unique()}`,
      title: 'Teacher',
      email: `ac-t-${unique()}@example.com`,
      bio: 'A mathematics teacher who takes learners from the first sum to confident problem solving.',
      expertise: ['Mathematics'],
      status,
      city: 'Pune',
      languages: ['English'],
    });
  const setStatus = (a: Academy, id: string, status: string) => a.admin.post(`/instructors/${id}/status`, { status });

  it('allows an activation while there is room, refuses one at the limit, and counts no inactive instructor', async () => {
    const a = await academy(plans.tight);
    const inactive = await addInstructor(a, 'inactive');
    expect(inactive.status).toBe(201); // 3. created inactive: allowed, takes no seat
    const second = await addInstructor(a, 'inactive');
    expect(outcome(await setStatus(a, inactive.body.id, 'active'))).toBe('ALLOW'); // 1. room for one more
    expect(outcome(await setStatus(a, second.body.id, 'active'))).toBe('403 LIMIT_REACHED'); // 2 and 4. at the limit
    expect((await platformDb.instructor.findUniqueOrThrow({ where: { id: second.body.id } })).status).toBe('inactive');
  });

  it('frees a seat on deactivation, and lets another in afterwards — through the status route or an edit', async () => {
    const a = await academy(plans.tight);
    const one = await addInstructor(a, 'active');
    const waiting = await addInstructor(a, 'inactive');
    expect(outcome(await setStatus(a, waiting.body.id, 'active'))).toBe('403 LIMIT_REACHED');
    expect(outcome(await setStatus(a, one.body.id, 'inactive'))).toBe('ALLOW'); // 5. frees capacity
    expect(outcome(await setStatus(a, waiting.body.id, 'active'))).toBe('ALLOW'); // 6. reactivation with room

    // An edit that moves one out of inactive is the same seat: refused at the limit.
    const edited = await a.admin.patch(`/instructors/${one.body.id}`, {
      name: 'Teacher Again',
      title: 'Teacher',
      email: one.body.email,
      bio: 'A mathematics teacher who takes learners from the first sum to confident problem solving.',
      expertise: ['Mathematics'],
      status: 'active',
      city: 'Pune',
      languages: ['English'],
    });
    expect(outcome(edited)).toBe('403 LIMIT_REACHED');
    expect((await platformDb.instructor.findUniqueOrThrow({ where: { id: one.body.id } })).status).toBe('inactive');
  });

  it('7 — lets exactly the room left through when several activations arrive at once', async () => {
    const a = await academy(plans.tight); // one active, room for one
    const waiting = await Promise.all([1, 2, 3, 4].map(() => addInstructor(a, 'inactive')));
    const results = await Promise.all(waiting.map((w) => setStatus(a, w.body.id, 'active')));
    expect(results.map(outcome).sort()).toEqual(['403 LIMIT_REACHED', '403 LIMIT_REACHED', '403 LIMIT_REACHED', 'ALLOW']);
    expect(await platformDb.instructor.count({ where: { tenantId: a.tenantId, status: { not: 'inactive' } } })).toBe(2);
  });

  it('refuses activating an instructor while the academy is served no plan, as adding one is', async () => {
    const a = await academy(null);
    const created = await a.admin.post('/instructors', {
      name: 'Blocked Teacher',
      title: 'Teacher',
      email: `ac-b-${unique()}@example.com`,
      bio: 'A mathematics teacher who takes learners from the first sum to confident problem solving.',
      expertise: ['Mathematics'],
      status: 'active',
      city: 'Pune',
      languages: ['English'],
    });
    expect(outcome(created)).toBe('402 SUBSCRIPTION_REQUIRED');
    expect(outcome(await setStatus(a, a.instructorId, 'inactive'))).toBe('ALLOW'); // taking one away is always open
    expect(outcome(await setStatus(a, a.instructorId, 'active'))).toBe('402 SUBSCRIPTION_REQUIRED');
  });
});

describe('categories follow the restricted-mode policy explicitly', () => {
  it('lets a subscribed academy manage categories on permission alone — no plan feature governs them', async () => {
    const a = await academy(plans.noReports);
    const made = await a.admin.post('/categories', { name: `Category ${unique()}`, glyph: 'sun', levelIds: [a.levelId] });
    expect(outcome(made)).toBe('ALLOW');
    expect(outcome(await a.admin.patch(`/categories/${made.body.id}`, { name: `Renamed ${unique()}` }))).toBe('ALLOW');
    expect(outcome(await a.admin.delete(`/categories/${made.body.id}`))).toBe('ALLOW');
  });

  it('refuses a new category with no plan, and keeps editing and deleting existing ones open', async () => {
    for (const a of [
      await academy(null),
      await (async () => {
        const x = await academy(plans.full);
        await platform.post(`/superadmin/subscriptions/${x.subscriptionId}/cancel`, { immediately: true, reason: 'Ended for the test' });
        return x;
      })(),
    ]) {
      const refused = await a.admin.post('/categories', { name: `Category ${unique()}`, glyph: 'sun' });
      expect(['402 SUBSCRIPTION_REQUIRED', '402 SUBSCRIPTION_EXPIRED']).toContain(outcome(refused));
      expect(outcome(await a.admin.patch(`/categories/${a.categoryId}`, { name: `Kept ${unique()}` }))).toBe('ALLOW');
      const empty = await forTenant(a.tenantId).category.create({
        data: { tenantId: a.tenantId, name: `Empty ${unique()}`, description: 'Empty.', order: 9, status: 'active', glyph: 'sun' },
      });
      expect(outcome(await a.admin.delete(`/categories/${empty.id}`))).toBe('ALLOW');
    }
  });

  it('still needs the permission, whatever the plan', async () => {
    const a = await academy(plans.full);
    await revoke(a, 'catalog.categories.manage');
    expect(outcome(await a.admin.post('/categories', { name: `Category ${unique()}`, glyph: 'sun' }))).toBe('403 PERMISSION_DENIED');
  });
});

describe('restricted mode never gives an academy more than the plan it last had', () => {
  const cancel = (a: Academy) => platform.post(`/superadmin/subscriptions/${a.subscriptionId}/cancel`, { immediately: true, reason: 'Ended for the test' });

  it('refuses basic reports to an academy that never subscribed — as the plan without them does', async () => {
    const never = await academy(null);
    const starter = await academy(plans.noReports);
    expect(outcome(await never.admin.get('/reports/overview'))).toBe('402 SUBSCRIPTION_REQUIRED');
    expect(outcome(await starter.admin.get('/reports/overview'))).toBe('403 FEATURE_NOT_INCLUDED');
    // Reads no plan feature governs stay open to both.
    for (const a of [never, starter]) expect(outcome(await a.admin.get('/courses'))).toBe('ALLOW');
  });

  it('keeps reading basic reports after a plan that had them ends, and not after one that did not', async () => {
    const had = await academy(plans.noLive);
    const hadNot = await academy(plans.noReports);
    await cancel(had);
    await cancel(hadNot);
    expect(outcome(await had.admin.get('/reports/overview'))).toBe('ALLOW');
    expect(outcome(await hadNot.admin.get('/reports/overview'))).toBe('402 SUBSCRIPTION_EXPIRED');
  });

  it('keeps editing what exists under a plan that had the feature, and adds nothing', async () => {
    const had = await academy(plans.full);
    await cancel(had);
    expect(outcome(await had.admin.patch(`/courses/${had.courseId}`, { subtitle: 'Edited after the plan ended' }))).toBe('ALLOW');
    expect(outcome(await newCourse(had))).toBe('402 SUBSCRIPTION_EXPIRED');
    const never = await academy(null);
    expect(outcome(await never.admin.patch(`/courses/${never.courseId}`, { subtitle: 'No plan ever' }))).toBe('402 SUBSCRIPTION_REQUIRED');
    expect(outcome(await never.admin.get(`/courses/${never.courseId}`))).toBe('ALLOW');
  });
});

describe('the access matrix, enforcement on', () => {
  it('answers every row as the layers say', async () => {
    const full = await academy(plans.full);
    const noPerm = await academy(plans.full);
    await revoke(noPerm, 'catalog.edit');
    await revoke(noPerm, 'live.manage');
    const noLive = await academy(plans.noLive);
    const expired = await academy(plans.trial, 'trial');
    setClock(new Date(Date.now() + 15 * 86_400_000));
    await runAsPlatform('test: expire the trial', () => expireTrial(scheduler, expired.subscriptionId!));
    setClock(null);
    const paused = await academy(plans.full);
    expect((await platform.post(`/superadmin/subscriptions/${paused.subscriptionId}/pause`, { days: 10 })).status).toBe(200);
    const none = await academy(null);

    const rows: [string, () => Promise<{ status: number; body: { code?: string } }>, string][] = [
      ['Course create — permission, feature, room', () => newCourse(full), 'ALLOW'],
      ['Course create — no permission', () => newCourse(noPerm), '403 PERMISSION_DENIED'],
      ['Live class — permission, feature, room', () => newLive(full), 'ALLOW'],
      ['Live class — no permission', () => newLive(noPerm), '403 PERMISSION_DENIED'],
      ['Live class — no feature', () => newLive(noLive), '403 FEATURE_NOT_INCLUDED'],
      ['Report — permission, feature', () => full.admin.get('/reports/overview'), 'ALLOW'],
      ['Expired subscription — course create', () => newCourse(expired), '402 SUBSCRIPTION_EXPIRED'],
      ['Paused subscription — course create', () => newCourse(paused), '402 SUBSCRIPTION_REQUIRED'],
      ['No subscription — course create', () => newCourse(none), '402 SUBSCRIPTION_REQUIRED'],
      ['No subscription — course list (a read no feature governs)', () => none.admin.get('/courses'), 'ALLOW'],
    ];
    const got = [];
    for (const [label, run, expected] of rows) got.push([label, outcome(await run()), expected]);
    expect(got.filter(([, actual, expected]) => actual !== expected)).toEqual([]);
  });

  it('answers learner sign-up by the default academy’s plan: room lets one in, a full plan refuses', async () => {
    // Sign-up joins the academy this host serves; its plan comes through the entitlement service's own seam.
    const learners = await platformDb.student.count({ where: { tenantId: ACADEMY } });
    const roomy = await plan(ROUTED, { limits: { ...limits, 'learners.max': learners + 5 } });
    const full = await platformDb.planVersion.findFirstOrThrow({ where: { planId: roomy } });
    const register = () => anon().post('/auth/register', { name: 'Matrix Learner', email: `ac-l-${unique()}@example.com`, password: PASSWORD });
    setTenantPlanSource(async (tenantId) => (tenantId === ACADEMY ? { planVersionId: full.id, status: 'active' } : null));
    expect(outcome(await register())).toBe('ALLOW');
    // A plan whose learner seats are all taken refuses the next sign-up.
    const fullPlan = await plan(ROUTED, { limits: { ...limits, 'learners.max': learners + 1 } });
    const fullVersion = await platformDb.planVersion.findFirstOrThrow({ where: { planId: fullPlan } });
    setTenantPlanSource(async (tenantId) => (tenantId === ACADEMY ? { planVersionId: fullVersion.id, status: 'active' } : null));
    expect(outcome(await register())).toBe('403 LIMIT_REACHED');
  });
});

describe('every subscription state, enforcement on', () => {
  it('serves the plan while trialing, active, past due (grace included) or cancelling, and not while paused, expired or cancelled', async () => {
    const states: Record<string, string> = {};
    const trial = await academy(plans.trial, 'trial');
    states.trialing = outcome(await newCourse(trial));

    const active = await academy(plans.full);
    states.active = outcome(await newCourse(active));

    const pastDue = await academy(plans.full);
    await runAsPlatform('test: a failed charge', () => recordPaymentFailed(scheduler, pastDue.subscriptionId!, { reason: 'card_declined' }));
    states.past_due = outcome(await newCourse(pastDue));
    await runAsPlatform('test: retries exhausted', () => startGracePeriod(scheduler, pastDue.subscriptionId!, { reason: 'retries exhausted' }));
    expect((await platformDb.subscription.findUniqueOrThrow({ where: { id: pastDue.subscriptionId } })).gracePeriodEndAt).not.toBeNull();
    states['past_due (grace)'] = outcome(await newCourse(pastDue));

    const canceling = await academy(plans.full);
    expect(
      (await platform.post(`/superadmin/subscriptions/${canceling.subscriptionId}/cancel`, { immediately: false, reason: 'Leaving at period end' })).status,
    ).toBe(200);
    states.canceling = outcome(await newCourse(canceling));

    const paused = await academy(plans.full);
    await platform.post(`/superadmin/subscriptions/${paused.subscriptionId}/pause`, { days: 10 });
    states.paused = outcome(await newCourse(paused));

    const expired = await academy(plans.trial, 'trial');
    setClock(new Date(Date.now() + 15 * 86_400_000));
    await runAsPlatform('test: expire the trial', () => expireTrial(scheduler, expired.subscriptionId!));
    setClock(null);
    states.expired = outcome(await newCourse(expired));

    const canceled = await academy(plans.full);
    await platform.post(`/superadmin/subscriptions/${canceled.subscriptionId}/cancel`, { immediately: true, reason: 'Ended now' });
    states.canceled = outcome(await newCourse(canceled));

    states['no subscription'] = outcome(await newCourse(await academy(null)));

    expect(states).toEqual({
      trialing: 'ALLOW',
      active: 'ALLOW',
      past_due: 'ALLOW',
      'past_due (grace)': 'ALLOW',
      canceling: 'ALLOW',
      paused: '402 SUBSCRIPTION_REQUIRED',
      expired: '402 SUBSCRIPTION_EXPIRED',
      canceled: '402 SUBSCRIPTION_EXPIRED',
      'no subscription': '402 SUBSCRIPTION_REQUIRED',
    });
  });
});

describe('the feature catalogue says how each feature is delivered', () => {
  it('gates every route feature, and marks analytics as planned and priority support as a service level', () => {
    const byKey = Object.fromEntries(FEATURES.map((f) => [f.key, f.enforcement]));
    expect(byKey['analytics.advanced']).toBe('planned');
    expect(byKey.priority_support).toBe('service');
    for (const key of FEATURE_KEYS) {
      if (byKey[key] === 'route') expect(GATED_FEATURES.has(key), key).toBe(true);
      // Nothing pretends to gate what is not built or is not a route.
      else expect(GATED_FEATURES.has(key), key).toBe(false);
    }
  });

  it('tells the academy which of its features are planned or a service level', async () => {
    const a = await academy(plans.full);
    const billing = await a.admin.get('/tenant/billing');
    const features = billing.body.features as { key: string; enforcement: string }[];
    expect(features.find((f) => f.key === 'analytics.advanced')?.enforcement).toBe('planned');
    expect(features.find((f) => f.key === 'priority_support')?.enforcement).toBe('service');
    expect(features.find((f) => f.key === 'live_classes')?.enforcement).toBe('route');
  });
});
