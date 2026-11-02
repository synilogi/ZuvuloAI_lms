import request from 'supertest';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { anon, app, as, unique, type Client } from '../test/helpers.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';

/* Learners joining an academy (SAAS-028): added by the academy's own admin, or through the academy's join link —
 * always into that academy only, counted against its plan. */

const PASSWORD = 'learner-join-password';
let platform: Client;
let tinyPlanId: string;

async function newAcademy() {
  const slug = `lj-${unique()}`;
  const email = `lj-admin-${unique()}@example.com`;
  const res = await platform.post('/superadmin/tenants', { name: `Join Academy ${slug}`, slug, admin: { name: 'Join Admin', email, password: PASSWORD } });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return { tenantId: res.body.id as string, slug, adminEmail: email, admin: await as({ email, password: PASSWORD }) };
}

const inviteToken = async (email: string) => {
  const mail = await platformDb.emailOutbox.findFirstOrThrow({ where: { toEmail: email, templateKey: 'learner-invite' }, orderBy: { createdAt: 'desc' } });
  return mail.text.match(/reset-password\/([^\s]+)/)![1];
};

beforeAll(async () => {
  const email = `lj-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Join Platform' });
  platform = await as({ email, password: PASSWORD });
  const plan = await platform.post('/superadmin/plans', {
    name: 'Tiny',
    description: 'One learner.',
    code: `TINY${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly'],
    monthlyPrice: 49900,
    annualPrice: 0,
    trialEnabled: true,
    trialDays: 7,
    limits: { 'learners.max': 1, 'instructors.max': 1, 'courses.max': 1, 'storage.bytes': 1_000_000, 'live_classes.max': 1, 'admin_accounts.max': 1 },
    features: ['courses.manage'],
  });
  expect(plan.status, JSON.stringify(plan.body)).toBe(201);
  await platform.post(`/superadmin/plans/${plan.body.id}/publish`);
  tinyPlanId = plan.body.id;
});

afterEach(() => {
  delete process.env.ENTITLEMENT_ENFORCEMENT;
});

describe('an admin adds a learner', () => {
  it('creates the learner in the admin’s own academy and invites them to choose a password', async () => {
    const a = await newAcademy();
    const email = `added-${unique()}@example.com`;
    const res = await a.admin.post('/students', { name: 'Meera Das', email, tenantId: 'tenant-1', role: 'admin' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body).toMatchObject({ name: 'Meera Das', email });

    const user = await platformDb.user.findUniqueOrThrow({ where: { email } });
    expect(user).toMatchObject({ role: 'student', tenantId: a.tenantId });
    expect((await a.admin.get('/students')).body.rows.map((r: { student: { email: string } }) => r.student.email)).toContain(email);
    expect(await platformDb.auditLog.findFirst({ where: { action: 'learner.created', actorEmail: a.adminEmail } })).toBeTruthy();

    // The invitation sets a password; the learner signs in to this academy.
    const token = await inviteToken(email);
    expect((await anon().post('/auth/reset-password', { token, password: 'learner-new-password' })).status).toBe(200);
    const login = await anon().post('/auth/login', { email, password: 'learner-new-password' });
    expect(login.status).toBe(200);
    expect(login.body.user.role).toBe('student');
  });

  it('refuses a duplicate email, and anyone but an admin', async () => {
    const a = await newAcademy();
    expect((await a.admin.post('/students', { name: 'Dup', email: 'ananya@syniastrolms.test' })).status).toBe(409);
    expect((await a.admin.post('/students', { name: 'X', email: 'nope' })).status).toBe(400);
    expect((await (await as('instructor')).post('/students', { name: 'Someone', email: `i-${unique()}@example.com` })).status).toBe(403);
    expect((await (await as('student')).post('/students', { name: 'Someone', email: `s-${unique()}@example.com` })).status).toBe(403);
    expect((await anon().post('/students', { name: 'Someone', email: `a-${unique()}@example.com` })).status).toBe(401);
  });

  it('needs the learners.enroll permission', async () => {
    const a = await newAcademy();
    const adminId = (await platformDb.user.findUniqueOrThrow({ where: { email: a.adminEmail } })).id;
    expect((await platform.delete(`/superadmin/admins/${adminId}/permissions/learners.enroll`)).status).toBe(200);
    const res = await a.admin.post('/students', { name: 'Blocked', email: `blocked-${unique()}@example.com` });
    expect(res.status).toBe(403);
    expect(res.body.code).toBe('PERMISSION_DENIED');
  });

  it('never reaches another academy’s learners', async () => {
    const a = await newAcademy();
    const b = await newAcademy();
    const res = await a.admin.post('/students', { name: 'Only A', email: `only-a-${unique()}@example.com` });
    const studentId = res.body.id;
    expect((await b.admin.post(`/students/${studentId}/resend-invite`)).status).toBe(404);
    expect((await b.admin.get(`/students/${studentId}`)).status).toBe(404);
    expect((await b.admin.post(`/students/${studentId}/suspend`, { suspended: true })).status).toBe(404);
    expect((await b.admin.get('/students')).body.rows).toHaveLength(0);
    // Admin A can send the invitation again.
    expect((await a.admin.post(`/students/${studentId}/resend-invite`)).body).toMatchObject({ sentTo: res.body.email });
  });

  it('stops at the plan’s learner limit, and is refused without a plan, under enforcement', async () => {
    process.env.ENTITLEMENT_ENFORCEMENT = 'on';
    const a = await newAcademy();
    const none = await a.admin.post('/students', { name: 'No Plan', email: `np-${unique()}@example.com` });
    expect(none.status).toBe(402);
    expect(none.body.code).toBe('SUBSCRIPTION_REQUIRED');

    expect((await a.admin.post('/tenant/billing/trial', { planId: tinyPlanId, cycle: 'monthly' })).status).toBe(201);
    expect((await a.admin.post('/students', { name: 'First', email: `first-${unique()}@example.com` })).status).toBe(201);
    const full = await a.admin.post('/students', { name: 'Second', email: `second-${unique()}@example.com` });
    expect(full.status).toBe(403);
    expect(full.body.code).toBe('LIMIT_REACHED');
    // The join link counts against the same limit.
    const joined = await request(app)
      .post(`/public/academies/${a.slug}/register`)
      .send({ name: 'Third', email: `third-${unique()}@example.com`, password: PASSWORD });
    expect(joined.body.code).toBe('LIMIT_REACHED');
  });
});

describe('the academy’s join link', () => {
  it('names the academy, and signs a learner up into that academy only', async () => {
    const a = await newAcademy();
    const info = await request(app).get(`/public/academies/${a.slug}`);
    expect(info.status).toBe(200);
    expect(info.body).toEqual({ name: `Join Academy ${a.slug}`, slug: a.slug, open: true, invitationOnly: false });

    const email = `joined-${unique()}@example.com`;
    const res = await request(app)
      .post(`/public/academies/${a.slug}/register`)
      .send({ name: 'Rahul Verma', email, password: PASSWORD, tenantId: 'tenant-1', role: 'admin' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body.user).toMatchObject({ email, role: 'student' });
    expect((await platformDb.user.findUniqueOrThrow({ where: { email } })).tenantId).toBe(a.tenantId);

    const me = await request(app).get('/auth/me').set('Authorization', `Bearer ${res.body.token}`);
    expect(me.status).toBe(200);
    expect((await a.admin.get('/students')).body.rows.map((r: { student: { email: string } }) => r.student.email)).toContain(email);
    // The demo academy never sees them.
    const seeded = await (await as('admin')).get('/students', { search: email });
    expect(seeded.body.rows).toHaveLength(0);
  });

  it('is not found for an unknown or archived academy, and closed for a suspended one', async () => {
    expect((await request(app).get('/public/academies/no-such-academy')).status).toBe(404);

    const s = await newAcademy();
    expect((await platform.post(`/superadmin/tenants/${s.tenantId}/suspend`, { reason: 'Unpaid' })).status).toBe(200);
    expect((await request(app).get(`/public/academies/${s.slug}`)).body.open).toBe(false);
    const refused = await request(app)
      .post(`/public/academies/${s.slug}/register`)
      .send({ name: 'Late', email: `late-${unique()}@example.com`, password: PASSWORD });
    expect(refused.status).toBe(403);

    const z = await newAcademy();
    expect((await platform.post(`/superadmin/tenants/${z.tenantId}/archive`, { reason: 'Closed' })).status).toBe(200);
    expect((await request(app).get(`/public/academies/${z.slug}`)).status).toBe(404);
  });

  it('refuses an email that already has an account anywhere', async () => {
    const a = await newAcademy();
    const res = await request(app).post(`/public/academies/${a.slug}/register`).send({ name: 'Taken', email: 'ananya@syniastrolms.test', password: PASSWORD });
    expect(res.status).toBe(409);
  });
});

describe('the original sign-up', () => {
  it('still joins the academy this host serves, as the mobile app expects', async () => {
    const email = `host-${unique()}@example.com`;
    const res = await anon().post('/auth/register', { name: 'Host Learner', email, password: PASSWORD });
    expect(res.status).toBe(201);
    expect(res.body.user.role).toBe('student');
    expect((await platformDb.user.findUniqueOrThrow({ where: { email } })).tenantId).toBe('tenant-1');
  });

  it('joins the Admin named by the workspace address, when the app sends one', async () => {
    const a = await newAcademy();
    const email = `app-${unique()}@example.com`;
    const res = await anon().post('/auth/register', { name: 'App Learner', email, password: PASSWORD, workspace: a.slug, tenantId: 'tenant-1' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect((await platformDb.user.findUniqueOrThrow({ where: { email } })).tenantId).toBe(a.tenantId);
    expect(
      (await anon().post('/auth/register', { name: 'Lost', email: `lost-${unique()}@example.com`, password: PASSWORD, workspace: 'no-such-workspace' })).status,
    ).toBe(404);
  });
});
