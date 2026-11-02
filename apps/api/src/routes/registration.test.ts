import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';

import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { FIRST_TENANT_ID } from '../lib/tenancy.js';
import { platformDb } from '../test/db.js';
import { PASSWORD, anon, as, unique, type Client } from '../test/helpers.js';

/* The platform's registration doors (docs/16, D-PLAT-06). A learner registers with a mobile number and an emailed code; an
 * instructor applies with a professional profile and waits for approval. Nothing that can sign in exists before the code,
 * the workspace and the role are never the request's, and the doors of the SaaS era serve the one workspace only. */

let owner: Client;

const codeSentTo = async (email: string) => {
  const mail = await platformDb.emailOutbox.findFirstOrThrow({
    where: { toEmail: email, templateKey: 'account-verification' },
    orderBy: { createdAt: 'desc' },
  });
  return /^\d{6}$/m.exec(mail.text)![0];
};
const verify = (verificationId: string, code: string) => anon().post('/public/verifications/verify', { verificationId, code });
const learner = (over: object = {}) => ({ name: 'Asha Verma', email: `reg-${unique()}@example.com`, phone: '+91 98765 43210', password: PASSWORD, ...over });
const applicant = (over: object = {}) => ({
  name: 'Ravi Shastri',
  email: `apply-${unique()}@example.com`,
  phone: '+91 98765 11111',
  password: PASSWORD,
  title: 'Mathematics teacher',
  bio: 'Twelve years teaching secondary mathematics, the last five online.',
  expertise: ['Algebra', 'Geometry'],
  yearsTeaching: 12,
  links: ['https://example.com/ravi'],
  ...over,
});

beforeAll(async () => {
  const email = `reg-owner-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Platform Owner' });
  owner = await as({ email, password: PASSWORD });
});

beforeEach(() => vi.stubEnv('SIGNUP_EMAIL_VERIFICATION', 'on'));
afterEach(() => vi.unstubAllEnvs());

describe('a learner registers', () => {
  it('creates nothing until the emailed code is confirmed, then signs them in with their number kept', async () => {
    const me = learner();
    const started = await anon().post('/public/register', me);
    expect(started.status, JSON.stringify(started.body)).toBe(202);
    expect(started.body).toMatchObject({ status: 'verify', email: me.email, role: 'student' });
    expect(await platformDb.user.findUnique({ where: { email: me.email } })).toBeNull();
    expect((await anon().post('/auth/login', { email: me.email, password: PASSWORD })).status).toBe(401);

    const done = await verify(started.body.verificationId, await codeSentTo(me.email));
    expect(done.status, JSON.stringify(done.body)).toBe(201);
    expect(done.body.token).toBeTruthy();
    const user = await platformDb.user.findUniqueOrThrow({ where: { email: me.email }, include: { student: true } });
    expect(user).toMatchObject({ role: 'student', tenantId: FIRST_TENANT_ID, phone: me.phone });
    expect(user.student?.phone).toBe(me.phone);
  });

  it('needs a real mobile number', async () => {
    for (const phone of [undefined, '', 'call me', '123']) {
      const res = await anon().post('/public/register', learner({ phone }));
      expect(res.status, String(phone)).toBe(400);
    }
  });

  it('takes no role or workspace from the request', async () => {
    const me = learner({ role: 'admin', tenantId: 'somewhere-else', workspace: 'somewhere-else' });
    const started = await anon().post('/public/register', me);
    const done = await verify(started.body.verificationId, await codeSentTo(me.email as string));
    expect(done.body.user.role).toBe('student');
    expect(await platformDb.user.findUniqueOrThrow({ where: { email: me.email as string } })).toMatchObject({ role: 'student', tenantId: FIRST_TENANT_ID });
  });

  it('refuses a wrong code, stops after too many, and works once', async () => {
    const me = learner();
    const { verificationId } = (await anon().post('/public/register', me)).body;
    const code = await codeSentTo(me.email);
    const wrong = code === '000000' ? '000001' : '000000';
    expect((await verify(verificationId, wrong)).status).toBe(400);
    expect((await verify(verificationId, code)).status).toBe(201);
    expect((await verify(verificationId, code)).status).toBe(404);

    const other = learner();
    const second = (await anon().post('/public/register', other)).body.verificationId as string;
    const right = await codeSentTo(other.email);
    const bad = right === '000000' ? '000001' : '000000';
    for (let i = 0; i < 5; i++) await verify(second, bad);
    expect((await verify(second, right)).status).toBe(429);
    expect(await platformDb.user.findUnique({ where: { email: other.email } })).toBeNull();
  });

  it('refuses an address that already has an account', async () => {
    const res = await anon().post('/public/register', learner({ email: 'ananya@syniastrolms.test' }));
    expect(res.status).toBe(409);
  });

  it('keeps taking the mobile app’s registration, with a workspace it ignores and no number', async () => {
    const me = { name: 'Older App', email: `app-${unique()}@example.com`, password: PASSWORD, workspace: 'default' };
    const started = await anon().post('/auth/register', me);
    expect(started.status, JSON.stringify(started.body)).toBe(202);
    expect((await verify(started.body.verificationId, await codeSentTo(me.email))).status).toBe(201);
  });
});

describe('an instructor applies', () => {
  const apply = async (over: object = {}) => {
    const me = applicant(over);
    const started = await anon().post('/public/instructor-applications', me);
    expect(started.status, JSON.stringify(started.body)).toBe(202);
    const done = await verify(started.body.verificationId, await codeSentTo(me.email as string));
    expect(done.status, JSON.stringify(done.body)).toBe(202);
    expect(done.body.status).toBe('pending');
    expect(done.body.token).toBeUndefined();
    return me as ReturnType<typeof applicant>;
  };

  it('keeps the profile, signs nobody in, and tells the owner and staff', async () => {
    const me = await apply();
    const row = await platformDb.instructor.findUniqueOrThrow({ where: { email: me.email } });
    expect(row).toMatchObject({ status: 'pending', tenantId: FIRST_TENANT_ID, title: me.title, bio: me.bio, yearsTeaching: 12, phone: me.phone });
    expect(JSON.parse(row.expertiseJson)).toEqual(me.expertise);
    expect(JSON.parse(row.linksJson)).toEqual(me.links);
    expect((await anon().post('/auth/login', { email: me.email, password: PASSWORD })).body.code).toBe('INSTRUCTOR_PENDING');

    const ownerRow = await platformDb.user.findFirstOrThrow({ where: { email: { startsWith: 'reg-owner-' } }, orderBy: { createdAt: 'desc' } });
    expect(await platformDb.appNotification.findFirst({ where: { recipientId: ownerRow.id, title: 'New instructor application' } })).toBeTruthy();
    const staff = await platformDb.user.findFirstOrThrow({ where: { role: 'admin', tenantId: FIRST_TENANT_ID } });
    expect(await platformDb.appNotification.findFirst({ where: { recipientId: staff.id, title: 'New instructor application' } })).toBeTruthy();
  });

  it('checks the application', async () => {
    for (const over of [
      { bio: 'Too short' },
      { expertise: [] },
      { yearsTeaching: -1 },
      { links: ['not a link'] },
      { links: ['javascript:alert(1)'] },
      { phone: 'x' },
      { title: '' },
    ]) {
      expect((await anon().post('/public/instructor-applications', applicant(over))).status, JSON.stringify(over)).toBe(400);
    }
  });

  it('is approved by the platform owner, who sees the whole application, and can then sign in', async () => {
    const me = await apply();
    const list = await owner.get('/instructors/requests');
    expect(list.status).toBe(200);
    const request = (list.body as { id: string; email: string }[]).find((r) => r.email === me.email);
    expect(request).toMatchObject({ title: me.title, bio: me.bio, phone: me.phone, expertise: me.expertise, yearsTeaching: 12, links: me.links });

    expect((await owner.post(`/instructors/requests/${request!.id}/approve`)).status).toBe(200);
    const signedIn = await anon().post('/auth/login', { email: me.email, password: PASSWORD });
    expect(signedIn.status).toBe(200);
    expect(signedIn.body.user.role).toBe('instructor');
  });

  it('can be rejected, and then cannot sign in', async () => {
    const me = await apply();
    const request = ((await owner.get('/instructors/requests')).body as { id: string; email: string }[]).find((r) => r.email === me.email);
    expect((await owner.post(`/instructors/requests/${request!.id}/reject`)).status).toBe(200);
    expect((await anon().post('/auth/login', { email: me.email, password: PASSWORD })).body.code).toBe('INSTRUCTOR_REJECTED');
  });

  it('is a decision a learner and an instructor cannot make', async () => {
    const me = await apply();
    const request = ((await owner.get('/instructors/requests')).body as { id: string; email: string }[]).find((r) => r.email === me.email);
    for (const client of [await as('student'), await as('instructor')]) {
      expect((await client.post(`/instructors/requests/${request!.id}/approve`)).status).toBe(403);
    }
  });
});

describe('the doors of the SaaS era', () => {
  it('answer for the workspace, and for no other tenant', async () => {
    const slug = `closed-${unique()}`;
    await platformDb.tenant.create({ data: { name: 'Closed Academy', slug } });
    expect((await anon().get('/public/academies/default')).status).toBe(200);
    expect((await anon().get(`/public/academies/${slug}`)).status).toBe(404);
    expect((await anon().post(`/public/academies/${slug}/register`, learner())).status).toBe(404);
    expect((await anon().post(`/public/academies/${slug}/instructor-requests`, applicant())).status).toBe(404);
  });

  it('are gone where they created academies or sold plans', async () => {
    expect((await anon().post('/signup/start', {})).status).toBe(404);
    expect((await anon().get('/public/plans')).status).toBe(404);
    expect((await owner.get('/superadmin/tenants')).status).toBe(404);
    expect((await owner.get('/superadmin/subscriptions')).status).toBe(404);
    expect((await (await as('admin')).get('/tenant/subscription')).status).toBe(404);
  });
});
