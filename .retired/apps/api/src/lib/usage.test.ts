import request from 'supertest';
import { BYTES_PER_GB, RESTRICTED_MODE_POLICY, type FeatureKey, type PlanLimits } from '@syniastrolms/domain';
import { afterEach, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { forTenant } from './db.js';
import { ACADEMY, platformDb } from '../test/db.js';
import { app, as, unique, type Client } from '../test/helpers.js';
import { hashPassword } from './auth.js';
import { setTenantPlanSource } from './entitlements.js';
import { createPlan, publishPlan } from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { cancelNow, createSubscription, type LifecycleActor } from './subscriptions.js';
import { runAsPlatform } from './tenancy.js';

/* SAAS-011: usage limits enforced on the routes that add to them, concurrency-safe, and restricted mode
 * for an academy whose subscription serves no plan. Every academy here is new and on a real
 * subscription, so its usage starts from what the test gives it. Enforcement is on throughout. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('usage tests act as the platform', fn);
let superAdmin: LifecycleActor & { type: 'user' };
let platform: Client;

const PNG = Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex'); // 16 bytes
const PASSWORD = 'usage-suite-password';

const ALL: FeatureKey[] = [
  'courses.manage',
  'assessments.manage',
  'certificates.manage',
  'live_classes',
  'reports.basic',
  'reports.advanced',
  'custom_branding',
];

async function planWith(limits: Partial<PlanLimits>): Promise<string> {
  return asPlatform(async () => {
    const p = await createPlan(
      { auth: superAdmin.auth },
      {
        name: 'Usage plan',
        description: 'A plan with small limits, for the usage suite.',
        code: `U${unique().toUpperCase()}`.slice(0, 24),
        currency: 'INR',
        cycles: ['monthly'],
        monthlyPrice: 100000,
        annualPrice: 0,
        trialEnabled: false,
        trialDays: 0,
        features: ALL,
        limits: {
          'learners.max': 100,
          'instructors.max': 10,
          'courses.max': 10,
          'storage.bytes': BYTES_PER_GB,
          'live_classes.max': 10,
          'admin_accounts.max': 5,
          ...limits,
        },
      },
    );
    await publishPlan({ auth: superAdmin.auth }, p.id);
    return p.id;
  });
}

interface Academy {
  tenantId: string;
  subscriptionId: string;
  admin: Client;
  learner: Client;
  levelId: string;
  categoryId: string;
  courseId: string;
  instructorId: string;
}

/** A new academy on a plan with `limits`, with an admin, a learner, one course and one instructor. */
async function academyOn(limits: Partial<PlanLimits>): Promise<Academy> {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Usage Academy', slug: `use-${unique()}` } })).id;
  const planId = await planWith(limits);
  const sub = await asPlatform(() => createSubscription(superAdmin, { tenantId, planId, cycle: 'monthly', start: 'active' }));
  const email = `use-admin-${unique()}@example.com`;
  expect((await platform.post('/superadmin/admins', { name: 'Usage Admin', email, password: PASSWORD, tenantId })).status).toBe(201);
  const t = { tenantId };
  const odb = forTenant(tenantId);
  const learnerEmail = `use-learner-${unique()}@example.com`;
  const lu = await odb.user.create({ data: { ...t, email: learnerEmail, passwordHash: await hashPassword(PASSWORD), name: 'Usage Learner', role: 'student' } });
  await odb.student.create({ data: { ...t, userId: lu.id } });
  const level = await odb.level.create({ data: { ...t, name: 'Level', order: 1 } });
  const category = await odb.category.create({ data: { ...t, name: `Category ${unique()}`, description: 'Usage.', order: 1, status: 'active', glyph: 'sun' } });
  const course = await odb.course.create({
    data: {
      ...t,
      slug: `c-${unique()}`,
      title: `Seed course ${unique()}`,
      levelId: level.id,
      categoryId: category.id,
      format: 'self-paced',
      coverMotif: 'sun',
    },
  });
  const instructor = await odb.instructor.create({
    data: { ...t, name: 'Usage Teacher', title: 'Teacher', email: `use-teacher-${unique()}@example.com`, status: 'active' },
  });
  // The host of a class teaches its course.
  await odb.courseInstructor.create({ data: { ...t, courseId: course.id, instructorId: instructor.id } });
  return {
    tenantId,
    subscriptionId: sub.id,
    admin: await as({ email, password: PASSWORD }),
    learner: await as({ email: learnerEmail, password: PASSWORD }),
    levelId: level.id,
    categoryId: category.id,
    courseId: course.id,
    instructorId: instructor.id,
  };
}

const newCourse = (a: Academy) => a.admin.post('/courses', { title: `Course ${unique()}`, levelId: a.levelId, categoryId: a.categoryId });
const liveAt = (a: Academy, startsAt: string) =>
  a.admin.post('/live', {
    courseId: a.courseId,
    title: `Class ${unique()}`,
    instructorId: a.instructorId,
    startsAt,
    durationMin: 60,
    capacity: 10,
    meeting: { kind: 'room' },
    reminders: [],
  });
const instructorBody = () => ({
  name: 'New Teacher',
  title: 'Teacher',
  email: `new-teacher-${unique()}@example.com`,
  bio: 'Teaches reasoning and quantitative aptitude to exam aspirants, with years of practice.',
  expertise: ['Reasoning'],
  status: 'invited',
  city: 'Pune',
  languages: ['English'],
  courseIds: [],
});
const uploadAs = (client: Client, name = `note-${unique()}.png`) =>
  client.upload('/media/upload').attach('file', PNG, { filename: name, contentType: 'image/png' });

const codes = (results: { status: number; body: { code?: string } }[]) =>
  results.map((r) => (r.status < 300 ? 'ok' : (r.body.code ?? String(r.status)))).sort();

beforeAll(async () => {
  const email = `usage-su-${unique()}@example.com`;
  const created = await provisionSuperAdmin({ email, password: PASSWORD, name: 'Platform' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
  platform = await as({ email, password: PASSWORD });
});

beforeEach(() => {
  process.env.ENTITLEMENT_ENFORCEMENT = 'on';
});

afterEach(() => {
  delete process.env.ENTITLEMENT_ENFORCEMENT;
  setTenantPlanSource(null);
});

describe('a concurrency test cannot exceed a hard limit', () => {
  it('lets exactly the room left through when eight courses are created at once', async () => {
    const a = await academyOn({ 'courses.max': 3 }); // one course already exists: room for two
    const results = await Promise.all(Array.from({ length: 8 }, () => newCourse(a)));
    expect(codes(results)).toEqual(['LIMIT_REACHED', 'LIMIT_REACHED', 'LIMIT_REACHED', 'LIMIT_REACHED', 'LIMIT_REACHED', 'LIMIT_REACHED', 'ok', 'ok']);
    expect(await platformDb.course.count({ where: { tenantId: a.tenantId, status: { not: 'archived' } } })).toBe(3);
    const refused = results.find((r) => r.status === 403)!;
    expect(refused.body.message).toBe('Courses: the Usage plan plan allows 3, and this LMS uses 3.');
  });

  it('holds for sign-ups too: five learners race for two seats', async () => {
    // The seeded academy signs learners up (it is the one this host serves); give it a plan whose
    // learner limit leaves exactly two seats, through the plan source the subscription normally fills.
    const seats = (await platformDb.student.count({ where: { tenantId: ACADEMY } })) + 2;
    const version = await asPlatform(async () => {
      const id = await planWith({ 'learners.max': seats });
      return (await platformDb.planVersion.findFirstOrThrow({ where: { planId: id } })).id;
    });
    setTenantPlanSource(async (tenantId) => (tenantId === ACADEMY ? { planVersionId: version, status: 'active' } : null));
    const sign = () =>
      request(app)
        .post('/auth/register')
        .send({ name: 'Racing Learner', email: `race-${unique()}@example.com`, password: 'racing-learner-1' });
    const results = await Promise.all(Array.from({ length: 5 }, sign));
    expect(codes(results)).toEqual(['LIMIT_REACHED', 'LIMIT_REACHED', 'LIMIT_REACHED', 'ok', 'ok']);
    expect(await platformDb.student.count({ where: { tenantId: ACADEMY } })).toBe(seats);
  });
});

describe('usage enforcement on every route that adds to a limit', () => {
  it('courses: creating and restoring count; an archived course frees its place', async () => {
    const a = await academyOn({ 'courses.max': 2 });
    const second = await newCourse(a);
    expect(second.status).toBe(201);
    expect((await newCourse(a)).body.code).toBe('LIMIT_REACHED');
    expect((await a.admin.post(`/courses/${second.body.id}/archive`)).status).toBe(200);
    const third = await newCourse(a);
    expect(third.status).toBe(201);
    // Restoring the archived one would make three.
    expect((await a.admin.post(`/courses/${second.body.id}/restore`)).body.code).toBe('LIMIT_REACHED');
  });

  it('instructors: an invited one takes a seat', async () => {
    const a = await academyOn({ 'instructors.max': 2 }); // one exists
    expect((await a.admin.post('/instructors', instructorBody())).status).toBe(201);
    expect((await a.admin.post('/instructors', instructorBody())).body.code).toBe('LIMIT_REACHED');
  });

  it('storage: a staff upload counts by its size; a learner’s hand-in is never refused', async () => {
    const a = await academyOn({ 'storage.bytes': 40 });
    expect((await uploadAs(a.admin)).status).toBe(201); // 16
    expect((await uploadAs(a.admin)).status).toBe(201); // 32
    const over = await uploadAs(a.admin); // 48 > 40
    expect(over.status).toBe(403);
    expect(over.body.code).toBe('LIMIT_REACHED');
    // A learner hand-in still goes through, and counts.
    expect((await uploadAs(a.learner)).status).toBe(201);
    expect((await platformDb.mediaAsset.aggregate({ where: { tenantId: a.tenantId }, _sum: { sizeBytes: true } }))._sum.sizeBytes).toBe(48);
  });

  it('live classes: counted in the month each class starts, including a class moved into a full month', async () => {
    const a = await academyOn({ 'live_classes.max': 1 });
    const now = new Date();
    const month = (m: number, day = 15) => new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + m, day, 10)).toISOString();
    expect((await liveAt(a, month(1))).status).toBe(201);
    expect((await liveAt(a, month(1, 20))).body.code).toBe('LIMIT_REACHED');
    const other = await liveAt(a, month(2));
    expect(other.status).toBe(201); // another month has its own allowance
    const moved = await a.admin.patch(`/live/${other.body.id}`, {
      courseId: a.courseId,
      title: 'Moved',
      instructorId: a.instructorId,
      startsAt: month(1, 22),
      durationMin: 60,
      capacity: 10,
      meeting: { kind: 'room' },
      reminders: [],
    });
    expect(moved.body.code).toBe('LIMIT_REACHED');
  });

  it('admin accounts: creating and reactivating take a seat', async () => {
    const a = await academyOn({ 'admin_accounts.max': 2 }); // one admin exists
    const second = await platform.post('/superadmin/admins', {
      name: 'Second Admin',
      email: `second-${unique()}@example.com`,
      password: PASSWORD,
      tenantId: a.tenantId,
    });
    expect(second.status).toBe(201);
    const third = await platform.post('/superadmin/admins', {
      name: 'Third Admin',
      email: `third-${unique()}@example.com`,
      password: PASSWORD,
      tenantId: a.tenantId,
    });
    expect(third.body.code).toBe('LIMIT_REACHED');
    await platform.post(`/superadmin/admins/${second.body.id}/deactivate`);
    expect(
      (await platform.post('/superadmin/admins', { name: 'Third Admin', email: `third-${unique()}@example.com`, password: PASSWORD, tenantId: a.tenantId }))
        .status,
    ).toBe(201);
    expect((await platform.post(`/superadmin/admins/${second.body.id}/reactivate`)).body.code).toBe('LIMIT_REACHED');
    // The audit trail still names the super admin who acted.
    const audit = await platformDb.auditLog.findFirstOrThrow({ where: { targetId: second.body.id, action: 'admin.created' } });
    expect(audit.actorId).toBe(superAdmin.auth.sub);
  });

  it('changes nothing while enforcement is off — the shipped default', async () => {
    const a = await academyOn({ 'courses.max': 1 });
    delete process.env.ENTITLEMENT_ENFORCEMENT;
    expect((await newCourse(a)).status).toBe(201);
    expect((await newCourse(a)).status).toBe(201);
  });
});

describe('restricted mode blocks creation without destroying access to existing data', () => {
  async function restricted() {
    const a = await academyOn({});
    await asPlatform(() => cancelNow(superAdmin, a.subscriptionId, { reason: 'Stopped paying' }));
    return a;
  }

  it('keeps every read, and everything learners do', async () => {
    const a = await restricted();
    for (const path of ['/courses', `/courses/${a.courseId}`, '/dashboard', '/reports/overview', '/settings', '/instructors', '/students']) {
      expect((await a.admin.get(path)).status, path).toBe(200);
    }
    expect((await a.learner.get('/learning/courses')).status).toBe(200);
    // A learner's hand-in upload is serving learners.
    expect((await uploadAs(a.learner)).status).toBe(201);
  });

  it('keeps editing and withdrawing what exists', async () => {
    const a = await restricted();
    expect((await a.admin.patch(`/courses/${a.courseId}`, { subtitle: 'Still editable' })).status).toBe(200);
    expect((await a.admin.post(`/courses/${a.courseId}/archive`)).status).toBe(200);
  });

  it('refuses anything new, with the renew prompt, and removes nothing', async () => {
    const a = await restricted();
    const before = await platformDb.course.count({ where: { tenantId: a.tenantId } });
    const refusals = [
      await newCourse(a),
      await a.admin.post(`/courses/${a.courseId}/publish`),
      await liveAt(a, new Date(Date.now() + 5 * 86_400_000).toISOString()),
      await uploadAs(a.admin),
      await a.admin.post('/instructors', instructorBody()),
      await a.admin.get('/reports/instructors'),
      await a.admin.put('/settings/appearance', {}),
    ];
    for (const r of refusals) {
      expect(r.status).toBe(402);
      expect(r.body).toMatchObject({ code: 'SUBSCRIPTION_EXPIRED', message: 'This LMS’s subscription has ended. Renew it to use this.' });
    }
    expect(await platformDb.course.count({ where: { tenantId: a.tenantId } })).toBe(before);
    expect(await platformDb.student.count({ where: { tenantId: a.tenantId } })).toBe(1);
  });

  it('refuses new sign-ups to a restricted academy', async () => {
    setTenantPlanSource(async (tenantId) => (tenantId === ACADEMY ? { planVersionId: null, status: 'expired' } : null));
    const res = await request(app)
      .post('/auth/register')
      .send({ name: 'Too Late', email: `late-${unique()}@example.com`, password: 'too-late-learner' });
    expect(res.status).toBe(402);
    expect(res.body.code).toBe('SUBSCRIPTION_EXPIRED');
  });

  it('leaves the platform able to act for a restricted academy', async () => {
    const a = await restricted();
    const res = await platform.post('/superadmin/admins', {
      name: 'Recovery Admin',
      email: `rec-${unique()}@example.com`,
      password: PASSWORD,
      tenantId: a.tenantId,
    });
    expect(res.status).toBe(201);
  });

  it('follows the written policy exactly', () => {
    expect(
      Object.entries(RESTRICTED_MODE_POLICY)
        .filter(([, p]) => p.allowed)
        .map(([op]) => op)
        .sort(),
    ).toEqual(['read', 'serve_learners', 'update', 'withdraw']);
  });
});
