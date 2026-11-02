import express from 'express';
import request from 'supertest';
import { BYTES_PER_GB, ENFORCEMENT_MATRIX, LIMIT_KEYS, type FeatureKey, type PlanLimits } from '@syniastrolms/domain';
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { forTenant } from './db.js';
import { ACADEMY, db, platformDb } from '../test/db.js';
import { as, unique, type Client } from '../test/helpers.js';
import { attachAuth, requireAuth, requireRole } from './auth.js';
import { GATED_FEATURES, canConsume, getLimit, getTenantEntitlements, getUsage, hasFeature, requireFeature, setTenantPlanSource } from './entitlements.js';
import { errorHandler } from './errors.js';
import { requireStaffPermission } from './permissions.js';
import { archivePlan, createPlan, publishPlan, type CreatePlanInput } from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { tenantContext } from './requestContext.js';
import { runAsPlatform, runInTenant } from './tenancy.js';

/* SAAS-003: the entitlement service, the §33 authorization order, and the error codes that tell a
 * missing permission from a missing entitlement. Until subscriptions exist (SAAS-004), the tests give
 * an academy its plan through `setTenantPlanSource`, the seam the subscription module will fill. */

const LIMITS: PlanLimits = {
  'learners.max': 500,
  'instructors.max': 10,
  'courses.max': 50,
  'storage.bytes': 100 * BYTES_PER_GB,
  'live_classes.max': 10,
  'admin_accounts.max': 5,
};

let operator: { auth: { sub: string; role: 'superadmin' } };

/** A published plan granting `features`, and the id of its version. */
async function planWith(features: FeatureKey[], limits: Partial<PlanLimits> = {}): Promise<string> {
  const input: CreatePlanInput = {
    name: 'Entitlement test plan',
    description: 'A plan made for the entitlement suite.',
    code: `E${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly'],
    monthlyPrice: 100000,
    annualPrice: 0,
    trialEnabled: false,
    trialDays: 0,
    features,
    limits: { ...LIMITS, ...limits },
  };
  return runAsPlatform('entitlement tests set up plans', async () => {
    const plan = await createPlan(operator, input);
    await publishPlan(operator, plan.id);
    return plan.current.id;
  });
}

/** Puts the seeded academy on `versionId` (or on no plan), the way a subscription will. */
const onPlan = (versionId: string | null) =>
  setTenantPlanSource(async (tenantId) => (tenantId === ACADEMY && versionId ? { planVersionId: versionId, status: 'active' } : null));

const enforce = (on: boolean) => {
  if (on) process.env.ENTITLEMENT_ENFORCEMENT = 'on';
  else delete process.env.ENTITLEMENT_ENFORCEMENT;
};

beforeAll(async () => {
  const created = await provisionSuperAdmin({ email: `entitlements-${unique()}@example.com`, password: 'entitlements-suite-password', name: 'Plan Owner' });
  operator = { auth: { sub: created.user.id, role: 'superadmin' } };
});

afterEach(() => {
  setTenantPlanSource(null);
  enforce(false);
});

describe('the entitlement service', () => {
  it('grants nothing to an academy that has never subscribed', async () => {
    // A new academy: the seeded one may be on a plan (TEST_ACADEMY_PLAN, SAAS-025).
    const never = (await platformDb.tenant.create({ data: { name: 'Never Subscribed', slug: `never-${unique()}` } })).id;
    const granted = await getTenantEntitlements(never);
    expect(granted).toMatchObject({ tenantId: never, status: null, planVersionId: null, plan: null, features: [], lastFeatures: [] });
    expect(LIMIT_KEYS.every((key) => granted.limits[key] === 0)).toBe(true);
    expect(await hasFeature(never, 'courses.manage')).toBe(false);
    expect(await getLimit(never, 'learners.max')).toBe(0);
  });

  it('reads what the academy’s plan version grants', async () => {
    const version = await planWith(['courses.manage', 'reports.basic'], { 'courses.max': null });
    onPlan(version);
    const granted = await getTenantEntitlements(ACADEMY);
    expect(granted.planVersionId).toBe(version);
    expect(granted.plan?.name).toBe('Entitlement test plan');
    expect(granted.features).toEqual(['courses.manage', 'reports.basic']);
    expect(await hasFeature(ACADEMY, 'courses.manage')).toBe(true);
    expect(await hasFeature(ACADEMY, 'custom_branding')).toBe(false);
    expect(await getLimit(ACADEMY, 'courses.max')).toBeNull();
    expect(await getLimit(ACADEMY, 'storage.bytes')).toBe(100 * BYTES_PER_GB);
  });

  it('keeps an academy’s entitlements when its plan is archived: it holds the version, not the plan', async () => {
    const version = await planWith(['live_classes']);
    onPlan(version);
    const { planId } = await platformDb.planVersion.findUniqueOrThrow({ where: { id: version }, select: { planId: true } });
    await runAsPlatform('archive for the test', () => archivePlan(operator, planId));
    expect(await hasFeature(ACADEMY, 'live_classes')).toBe(true);
  });
});

describe('usage', () => {
  /* A private academy with known rows, so every count is exact however many other suites are writing
   * to the seeded academy at the same time. */
  let other: string;
  const now = new Date();

  beforeAll(async () => {
    other = (await platformDb.tenant.create({ data: { name: 'Usage Academy', slug: `usage-${unique()}` } })).id;
    const t = { tenantId: other };
    const odb = forTenant(other);
    const person = (role: 'student' | 'admin', deactivatedAt: Date | null = null) =>
      odb.user.create({ data: { ...t, email: `usage-${unique()}@example.com`, passwordHash: 'x', name: 'Usage Person', role, deactivatedAt } });
    // Learners: 2.
    for (let i = 0; i < 2; i++) await odb.student.create({ data: { ...t, userId: (await person('student')).id } });
    // Admins: 1 active, 1 deactivated → 1.
    const admin = await person('admin');
    await person('admin', new Date());
    // Instructors: active and invited count, inactive does not → 2.
    const instructors = [];
    for (const status of ['active', 'invited', 'inactive']) {
      instructors.push(
        await odb.instructor.create({ data: { ...t, name: `Usage ${status}`, title: 'Teacher', email: `usage-${unique()}@example.com`, status } }),
      );
    }
    // Courses: a draft and an archived one → 1.
    const level = await odb.level.create({ data: { ...t, name: 'Usage level', order: 1 } });
    const category = await odb.category.create({ data: { ...t, name: 'Usage category', description: 'Usage.', order: 1, status: 'active', glyph: 'sun' } });
    const course = (status: string) =>
      odb.course.create({
        data: {
          ...t,
          slug: `usage-${unique()}`,
          title: 'Usage course',
          levelId: level.id,
          categoryId: category.id,
          format: 'self-paced',
          coverMotif: 'sun',
          status,
        },
      });
    const draft = await course('draft');
    await course('archived');
    // Live classes: one this month, one cancelled this month, one next month → 1.
    const nextMonth = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 2));
    for (const [startsAt, cancelled] of [
      [now, false],
      [now, true],
      [nextMonth, false],
    ] as const) {
      await odb.liveClass.create({
        data: { ...t, courseId: draft.id, instructorId: instructors[0].id, title: 'Usage class', startsAt, durationMin: 60, cancelled },
      });
    }
    // Storage: 1,000 + 2,500 bytes → 3,500.
    for (const sizeBytes of [1000, 2500]) {
      await odb.mediaAsset.create({
        data: {
          ...t,
          ownerUserId: admin.id,
          kind: 'document',
          originalName: 'usage.pdf',
          mime: 'application/pdf',
          sizeBytes,
          storageName: `usage-${unique()}`,
        },
      });
    }
  });

  afterAll(async () => {
    const where = { tenantId: other };
    for (const table of ['liveClass', 'mediaAsset', 'course', 'category', 'level', 'instructor', 'student', 'user'] as const) {
      await (platformDb[table] as unknown as { deleteMany: (a: object) => Promise<unknown> }).deleteMany({ where });
    }
    await platformDb.tenant.delete({ where: { id: other } });
  });

  it('counts each limit from the academy’s own rows, live, by its stated definition', async () => {
    const usage = Object.fromEntries(await Promise.all(LIMIT_KEYS.map(async (key) => [key, await getUsage(other, key, now)])));
    expect(usage).toEqual({ 'learners.max': 2, 'instructors.max': 2, 'courses.max': 1, 'storage.bytes': 3500, 'live_classes.max': 1, 'admin_accounts.max': 1 });
  });

  it('never counts another academy’s rows, from whatever context it is asked', async () => {
    // The seeded academy has far more learners; none of them leak in, and none of these leak out.
    expect(await runAsPlatform('usage from the platform', () => getUsage(other, 'learners.max'))).toBe(2);
    expect(await runInTenant(ACADEMY, () => getUsage(other, 'learners.max'))).toBe(2);
    expect(await getUsage(ACADEMY, 'learners.max')).toBeGreaterThan(2);
  });

  it('answers whether more fits, and how much room is left', async () => {
    const version = await planWith(['courses.manage'], { 'learners.max': 4, 'courses.max': null });
    setTenantPlanSource(async (tenantId) => (tenantId === other ? { planVersionId: version, status: 'active' } : null));
    expect(await canConsume(other, 'learners.max')).toEqual({ allowed: true, limit: 4, usage: 2, remaining: 2 });
    expect((await canConsume(other, 'learners.max', 2)).allowed).toBe(true);
    expect((await canConsume(other, 'learners.max', 3)).allowed).toBe(false);
    expect(await canConsume(other, 'courses.max', 1000)).toMatchObject({ allowed: true, limit: null, remaining: null });
    // No plan: no room at all.
    setTenantPlanSource(null);
    expect(await canConsume(other, 'learners.max')).toMatchObject({ allowed: false, limit: 0, usage: 2, remaining: 0 });
  });
});

describe('the authorization order (§33): permission, then entitlement', () => {
  /* A probe route composed the way a real one is: auth → role → permission → entitlement → handler. */
  const probe = express();
  probe.use(attachAuth);
  probe.use(tenantContext);
  probe.post('/probe', requireAuth, requireRole('instructor', 'admin'), requireStaffPermission('catalog.edit'), requireFeature('courses.manage'), (_req, res) =>
    res.json({ ok: true }),
  );
  probe.use(errorHandler);

  let admin: Client;
  let bareAdmin: Client;
  let instructor: Client;

  beforeAll(async () => {
    admin = await as('admin');
    instructor = await as('instructor');
    // An academy admin with no grants: every permission-gated route refuses it.
    const email = `entitle-bare-${unique()}@example.com`;
    const platform = await (async () => {
      const su = `entitle-su-${unique()}@example.com`;
      await provisionSuperAdmin({ email: su, password: 'entitlements-suite-password', name: 'Platform' });
      return as({ email: su, password: 'entitlements-suite-password' });
    })();
    const created = await platform.post('/superadmin/admins', { name: 'Bare Admin', email, password: 'a-bare-admin-password', tenantId: 'tenant-1' });
    await db.adminPermission.deleteMany({ where: { userId: created.body.id as string } });
    bareAdmin = await as({ email, password: 'a-bare-admin-password' });
  });

  const call = (client: Client) => request(probe).post('/probe').set('Authorization', `Bearer ${client.token}`);

  beforeEach(() => enforce(true));

  it('lets a request through when permission and entitlement both pass', async () => {
    onPlan(await planWith(['courses.manage']));
    expect((await call(admin)).status).toBe(200);
    // An instructor passes the permission on their role, and is still subject to the academy's plan.
    expect((await call(instructor)).status).toBe(200);
  });

  it('refuses a missing permission as PERMISSION_DENIED, even when the plan allows it', async () => {
    onPlan(await planWith(['courses.manage']));
    const res = await call(bareAdmin);
    expect(res.status).toBe(403);
    expect(res.body.code).toBe('PERMISSION_DENIED');
  });

  it('refuses a missing entitlement as FEATURE_NOT_INCLUDED, even when the permission is held', async () => {
    onPlan(await planWith(['reports.basic']));
    for (const client of [admin, instructor]) {
      const res = await call(client);
      expect(res.status).toBe(403);
      expect(res.body).toMatchObject({ code: 'FEATURE_NOT_INCLUDED', message: 'Course management is not included in the Entitlement test plan plan.' });
    }
  });

  it('checks the permission first when both are missing — the plan is never consulted for a caller without permission', async () => {
    onPlan(await planWith(['reports.basic']));
    expect((await call(bareAdmin)).body.code).toBe('PERMISSION_DENIED');
  });

  it('refuses an academy on no plan as SUBSCRIPTION_REQUIRED (402)', async () => {
    onPlan(null);
    const res = await call(admin);
    expect(res.status).toBe(402);
    expect(res.body.code).toBe('SUBSCRIPTION_REQUIRED');
  });

  it('changes nothing while enforcement is off — the shipped default', async () => {
    enforce(false);
    onPlan(null);
    expect((await call(admin)).status).toBe(200);
  });
});

describe('the gates on the real routes', () => {
  let admin: Client;
  let student: Client;

  beforeAll(async () => {
    admin = await as('admin');
    student = await as('student');
  });

  beforeEach(() => enforce(true));

  it('gates authoring on the plan, and refuses without writing anything', async () => {
    onPlan(await planWith(['reports.basic']));
    const before = await db.course.count();
    const res = await admin.post('/courses', { title: `Gated course ${unique()}` });
    expect(res.status).toBe(403);
    expect(res.body.code).toBe('FEATURE_NOT_INCLUDED');
    expect(await db.course.count()).toBe(before);
  });

  it('separates basic from advanced reports', async () => {
    onPlan(await planWith(['reports.basic']));
    expect((await admin.get('/reports/overview')).status).toBe(200);
    const advanced = await admin.get('/reports/instructors');
    expect(advanced.status).toBe(403);
    expect(advanced.body.code).toBe('FEATURE_NOT_INCLUDED');
    onPlan(await planWith(['reports.basic', 'reports.advanced']));
    expect((await admin.get('/reports/instructors')).status).toBe(200);
  });

  it('gates only the appearance section of settings on branding', async () => {
    onPlan(await planWith(['reports.basic']));
    const current = (await admin.get('/settings')).body.settings;
    expect((await admin.put('/settings/appearance', current.appearance)).body.code).toBe('FEATURE_NOT_INCLUDED');
    expect((await admin.put('/settings/general', current.general)).status).toBe(200);
  });

  it('never gates the dashboard, withdrawing content, or what a learner already has', async () => {
    onPlan(await planWith(['reports.basic']));
    expect((await admin.get('/dashboard')).status).toBe(200);
    // Archiving and restoring a course is withdrawing it, not authoring: no feature needed.
    const course = await db.course.findFirstOrThrow({ where: { status: 'published' }, select: { id: true } });
    const archived = await admin.post(`/courses/${course.id}/archive`);
    expect(archived.body.code).not.toBe('FEATURE_NOT_INCLUDED');
    if (archived.status === 200) await admin.post(`/courses/${course.id}/restore`);
    // A learner reading their courses is untouched by the academy's plan.
    expect((await student.get('/learning/courses')).status).toBe(200);
  });

  it('gates every catalogue feature that has a route, somewhere', () => {
    const routeless = ENFORCEMENT_MATRIX.filter((r) => r.feature && r.note?.match(/No route yet|not a route/)).map((r) => r.feature);
    const expected = new Set(ENFORCEMENT_MATRIX.map((r) => r.feature).filter((f): f is FeatureKey => Boolean(f) && !routeless.includes(f)));
    for (const feature of expected) expect(GATED_FEATURES.has(feature), feature).toBe(true);
  });
});
