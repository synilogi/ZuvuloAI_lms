import { beforeAll, describe, expect, it } from 'vitest';

import { getUsage } from '../lib/entitlements.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { platformDb } from '../test/db.js';
import { PASSWORD, anon, as, unique, type Client } from '../test/helpers.js';

/* D34: an instructor registers themselves into the academy a join link names, and waits for that academy's admin.
 * Pending or refused, the account cannot sign in or act; approved, it is ordinary staff. Everything is decided by
 * the server and scoped to the admin's own academy. */

let platform: Client;

interface Academy {
  tenantId: string;
  slug: string;
  admin: Client;
}

async function academy(): Promise<Academy> {
  const slug = `ir-${unique()}`;
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Requesting Academy', slug } })).id;
  const email = `ir-admin-${unique()}@example.com`;
  expect((await platform.post('/superadmin/admins', { name: 'Request Admin', email, password: PASSWORD, tenantId })).status).toBe(201);
  return { tenantId, slug, admin: await as({ email, password: PASSWORD }) };
}

const register = (slug: string, body: object) => anon().post(`/public/academies/${slug}/instructor-requests`, body);
const login = (email: string, password = PASSWORD) => anon().post('/auth/login', { email, password });
const person = (over: object = {}) => ({ name: 'Ravi Shastri', email: `ir-teacher-${unique()}@example.com`, password: PASSWORD, ...over });
const outbox = (to: string) => platformDb.emailOutbox.findMany({ where: { toEmail: to }, orderBy: { createdAt: 'asc' } });

beforeAll(async () => {
  const email = `ir-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Platform' });
  platform = await as({ email, password: PASSWORD });
});

describe('registering as an instructor', () => {
  it('creates a pending account in the link’s academy, signs nobody in, and tells both sides', async () => {
    const a = await academy();
    const me = person();
    const res = await register(a.slug, me);
    expect(res.status, JSON.stringify(res.body)).toBe(202);
    expect(res.body).toMatchObject({ status: 'pending' });
    expect(res.body.token).toBeUndefined();

    const user = await platformDb.user.findUniqueOrThrow({ where: { email: me.email }, include: { instructor: true } });
    expect(user).toMatchObject({ role: 'instructor', tenantId: a.tenantId });
    expect(user.instructor).toMatchObject({ status: 'pending', tenantId: a.tenantId, name: 'Ravi Shastri' });

    expect((await outbox(me.email)).map((m) => m.templateKey)).toEqual(['instructor-request-received']);
    const adminUser = await platformDb.user.findFirstOrThrow({ where: { tenantId: a.tenantId, role: 'admin' } });
    expect(await platformDb.appNotification.findFirst({ where: { recipientId: adminUser.id, title: 'New instructor request' } })).toBeTruthy();
  });

  it('cannot be pointed at another academy: a tenant in the body is ignored', async () => {
    const a = await academy();
    const b = await academy();
    const me = person({ tenantId: b.tenantId, accountId: b.tenantId, role: 'admin', status: 'active' });
    expect((await register(a.slug, me)).status).toBe(202);
    const user = await platformDb.user.findUniqueOrThrow({ where: { email: me.email }, include: { instructor: true } });
    expect(user.tenantId).toBe(a.tenantId);
    expect(user.role).toBe('instructor');
    expect(user.instructor?.status).toBe('pending');
  });

  it('refuses a taken email, a bad form, an unknown address and a suspended academy', async () => {
    const a = await academy();
    const me = person();
    await register(a.slug, me);
    expect((await register(a.slug, { ...person(), email: me.email })).status).toBe(409);
    expect((await register(a.slug, { name: 'R', email: 'nope', password: 'short' })).status).toBe(400);
    expect((await register('no-such-lms-anywhere', person())).status).toBe(404);
    await platformDb.tenant.update({ where: { id: a.tenantId }, data: { status: 'suspended' } });
    expect((await register(a.slug, person())).body).toMatchObject({ code: 'ACADEMY_SUSPENDED' });
  });
});

describe('before the admin decides', () => {
  it('sign-in is refused with the reason, only once the password is right', async () => {
    const a = await academy();
    const me = person();
    await register(a.slug, me);
    const wrong = await login(me.email, 'wrong-password');
    expect(wrong.status).toBe(401);
    const res = await login(me.email);
    expect(res.status).toBe(403);
    expect(res.body).toMatchObject({ code: 'INSTRUCTOR_PENDING' });
    expect(res.body.message).toContain('pending Admin approval');
    expect(res.body.token).toBeUndefined();
  });

  it('is not staff: not listed, not in the catalogue, and takes no seat', async () => {
    const a = await academy();
    const me = person();
    await register(a.slug, me);
    const staff = (await a.admin.get('/instructors')).body;
    expect(JSON.stringify(staff)).not.toContain(me.email);
    expect(await getUsage(a.tenantId, 'instructors.max')).toBe(0);
  });

  it('cannot be activated by editing its status — only by approving it', async () => {
    const a = await academy();
    const me = person();
    await register(a.slug, me);
    const { id } = (await a.admin.get('/instructors/requests')).body[0];
    expect((await a.admin.post(`/instructors/${id}/status`, { status: 'active' })).status).toBe(409);
    expect((await a.admin.post(`/instructors/${id}/resend-invite`)).status).toBe(409);
    expect((await login(me.email)).status).toBe(403);
  });
});

describe('the admin’s decision', () => {
  it('lists the request, approves it, and the instructor then signs in and works', async () => {
    const a = await academy();
    const me = person();
    await register(a.slug, me);

    const requests = (await a.admin.get('/instructors/requests')).body;
    expect(requests).toEqual([expect.objectContaining({ name: 'Ravi Shastri', email: me.email, status: 'pending', requestedAt: expect.any(String) })]);

    const approved = await a.admin.post(`/instructors/requests/${requests[0].id}/approve`);
    expect(approved.status).toBe(200);
    expect(approved.body).toMatchObject({ status: 'active' });
    expect((await a.admin.get('/instructors/requests')).body).toEqual([]);
    expect(JSON.stringify((await a.admin.get('/instructors')).body)).toContain(me.email);
    expect(await getUsage(a.tenantId, 'instructors.max')).toBe(1);
    expect((await outbox(me.email)).map((m) => m.templateKey)).toContain('instructor-request-approved');
    expect(await platformDb.auditLog.findFirst({ where: { action: 'instructor.request.approved', targetId: requests[0].id } })).toBeTruthy();

    const signedIn = await login(me.email);
    expect(signedIn.status).toBe(200);
    expect(signedIn.body.user).toMatchObject({ role: 'instructor', email: me.email });
    const instructor = await as({ email: me.email, password: PASSWORD });
    expect((await instructor.get('/auth/me')).status).toBe(200);
    expect((await instructor.get('/dashboard')).status).toBe(200);
    // Approving twice changes nothing more.
    expect((await a.admin.post(`/instructors/requests/${requests[0].id}/approve`)).status).toBe(404);
  });

  it('rejects one: the instructor still cannot sign in, and is told so', async () => {
    const a = await academy();
    const me = person();
    await register(a.slug, me);
    const { id } = (await a.admin.get('/instructors/requests')).body[0];

    expect((await a.admin.post(`/instructors/requests/${id}/reject`)).body).toMatchObject({ status: 'rejected' });
    const res = await login(me.email);
    expect(res.status).toBe(403);
    expect(res.body).toMatchObject({ code: 'INSTRUCTOR_REJECTED' });
    expect((await a.admin.get('/instructors/requests', { status: 'rejected' })).body).toEqual([expect.objectContaining({ id })]);
    expect((await outbox(me.email)).map((m) => m.templateKey)).toContain('instructor-request-rejected');
    expect((await a.admin.post(`/instructors/requests/${id}/reject`)).status).toBe(409);
  });

  it('is only staff with instructors.manage: instructors and learners cannot decide', async () => {
    const a = await academy();
    await register(a.slug, person());
    const { id } = (await a.admin.get('/instructors/requests')).body[0];
    for (const who of ['instructor', 'student'] as const) {
      const c = await as(who);
      expect((await c.get('/instructors/requests')).status).toBe(403);
      expect((await c.post(`/instructors/requests/${id}/approve`)).status).toBe(403);
    }
  });
});

describe('between academies', () => {
  it('admin A can neither see nor decide academy B’s request, nor B academy A’s', async () => {
    const a = await academy();
    const b = await academy();
    const forA = person();
    const forB = person();
    await register(a.slug, forA);
    await register(b.slug, forB);
    const idA = (await a.admin.get('/instructors/requests')).body[0].id;
    const idB = (await b.admin.get('/instructors/requests')).body[0].id;

    expect(JSON.stringify((await a.admin.get('/instructors/requests')).body)).not.toContain(forB.email);
    expect(JSON.stringify((await b.admin.get('/instructors/requests')).body)).not.toContain(forA.email);
    expect((await a.admin.post(`/instructors/requests/${idB}/approve`)).status).toBe(404);
    expect((await a.admin.post(`/instructors/requests/${idB}/reject`)).status).toBe(404);
    expect((await b.admin.post(`/instructors/requests/${idA}/approve`)).status).toBe(404);
    expect((await login(forA.email)).status).toBe(403);
    expect((await login(forB.email)).status).toBe(403);
    expect((await platformDb.instructor.findUniqueOrThrow({ where: { id: idB } })).status).toBe('pending');
  });
});
