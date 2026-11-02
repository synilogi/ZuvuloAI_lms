import { beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';

import { db, platformDb } from '../test/db.js';
import { verifyPassword } from '../lib/auth.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { ACCOUNTS, PASSWORD, anon, app, as, unique, type Client } from '../test/helpers.js';

/* Admin management: the only writes on the platform router. Each case works on an admin it created
 * itself, so the seeded academy admin the rest of the suite signs in as is never touched. */

const SECRET = 'admin-management-suite';
const NEW_PASSWORD = 'a-brand-new-admin-password';

let platform: Client;
let admin: Client;

const newAdminBody = (name = 'Created Admin') => ({ name, email: `admin-${unique()}@example.com`, password: NEW_PASSWORD, tenantId: 'tenant-1' });

async function createAdmin(name?: string) {
  const body = newAdminBody(name);
  const res = await platform.post('/superadmin/admins', body);
  expect(res.status).toBe(201);
  return { ...body, id: res.body.id as string, row: res.body };
}

const auditFor = (targetId: string) => db.auditLog.findMany({ where: { targetId }, orderBy: { createdAt: 'asc' } });

beforeAll(async () => {
  const email = `platform-admins-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: SECRET, name: 'Platform Owner' });
  platform = await as({ email, password: SECRET });
  admin = await as('admin');
});

describe('only a super admin may manage admins', () => {
  it('refuses everyone else on every write', async () => {
    const target = await createAdmin();
    const writes: [string, string, unknown][] = [
      ['post', '/superadmin/admins', newAdminBody()],
      ['patch', `/superadmin/admins/${target.id}`, { name: 'Renamed' }],
      ['post', `/superadmin/admins/${target.id}/deactivate`, {}],
      ['post', `/superadmin/admins/${target.id}/reactivate`, {}],
    ];
    const instructor = await as('instructor');
    const student = await as('student');

    for (const [method, path, body] of writes) {
      const call = (client: Client) => (method === 'patch' ? client.patch(path, body) : client.post(path, body));
      expect((await call(anon())).status, path).toBe(401);
      expect((await request(app).post(path).set('Authorization', 'Bearer not-a-real-token').send({})).status).toBe(401);
      expect((await call(admin)).status, `admin ${path}`).toBe(403);
      expect((await call(instructor)).status, `instructor ${path}`).toBe(403);
      expect((await call(student)).status, `student ${path}`).toBe(403);
    }
    // Nothing above changed the account.
    const untouched = await db.user.findUniqueOrThrow({ where: { id: target.id } });
    expect(untouched.name).toBe('Created Admin');
    expect(untouched.deactivatedAt).toBeNull();
  });
});

describe('POST /superadmin/admins', () => {
  it('creates an academy admin that can sign in, and never echoes the password', async () => {
    const body = newAdminBody('Kavita Two');
    const res = await platform.post('/superadmin/admins', body);
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ name: 'Kavita Two', email: body.email, role: 'admin' });
    expect(res.body).not.toHaveProperty('passwordHash');
    expect(res.body).not.toHaveProperty('password');
    expect(JSON.stringify(res.body)).not.toContain(body.password);

    const stored = await db.user.findUniqueOrThrow({ where: { email: body.email } });
    expect(stored.role).toBe('admin');
    expect(stored.deactivatedAt).toBeNull();
    // Hashed with the project's own helper, never stored in the clear.
    expect(stored.passwordHash).not.toContain(body.password);
    expect(await verifyPassword(body.password, stored.passwordHash)).toBe(true);

    // No learner or teaching profile came with it, exactly like the seeded admin.
    const full = await db.user.findUniqueOrThrow({ where: { id: stored.id }, include: { student: true } });
    expect(full.student).toBeNull();
    expect(full.instructorId).toBeNull();

    const signedIn = await anon().post('/auth/login', { email: body.email, password: body.password });
    expect(signedIn.status).toBe(200);
    expect(signedIn.body.user.role).toBe('admin');
  });

  it('refuses an address that is already in use', async () => {
    const res = await platform.post('/superadmin/admins', { name: 'Impostor', email: ACCOUNTS.student, password: NEW_PASSWORD, tenantId: 'tenant-1' });
    expect(res.status).toBe(409);
    // The learner is still a learner.
    expect((await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.student } })).role).toBe('student');
  });

  it('ignores a role sent by the client', async () => {
    const body = { ...newAdminBody('Sneaky'), role: 'superadmin' };
    const res = await platform.post('/superadmin/admins', body);
    expect(res.status).toBe(201);
    expect(res.body.role).toBe('admin');
    expect((await db.user.findUniqueOrThrow({ where: { email: body.email } })).role).toBe('admin');
  });

  it('checks the details before writing anything', async () => {
    expect((await platform.post('/superadmin/admins', { name: 'A', email: 'not-an-email', password: 'short' })).status).toBe(400);
    expect((await platform.post('/superadmin/admins', {})).status).toBe(400);
  });

  it('places every admin in the workspace, whether or not the body names one (docs/16, D-PLAT-03)', async () => {
    const body: Partial<ReturnType<typeof newAdminBody>> = newAdminBody('Unplaced Admin');
    delete body.tenantId;
    const res = await platform.post('/superadmin/admins', body);
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body.tenant?.id).toBe('tenant-1');
    const named = await platform.post('/superadmin/admins', { ...newAdminBody('Misplaced Admin'), tenantId: 'no-such-workspace' });
    expect(named.status, JSON.stringify(named.body)).toBe(201);
    expect(named.body.tenant?.id).toBe('tenant-1');
  });
});

describe('PATCH /superadmin/admins/:id', () => {
  it('renames an admin and moves it to another address', async () => {
    const target = await createAdmin('Before Rename');
    const email = `moved-${unique()}@example.com`;
    const res = await platform.patch(`/superadmin/admins/${target.id}`, { name: 'After Rename', email });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ id: target.id, name: 'After Rename', email, role: 'admin' });
    expect(res.body).not.toHaveProperty('passwordHash');

    // The account still signs in, at its new address, with the password it always had.
    expect((await anon().post('/auth/login', { email, password: NEW_PASSWORD })).status).toBe(200);
    expect((await anon().post('/auth/login', { email: target.email, password: NEW_PASSWORD })).status).toBe(401);
  });

  it('cannot change a role, however the body asks', async () => {
    const target = await createAdmin();
    const res = await platform.patch(`/superadmin/admins/${target.id}`, { name: 'Still An Admin', role: 'superadmin', deactivatedAt: null, passwordHash: 'x' });
    expect(res.status).toBe(200);
    expect(res.body.role).toBe('admin');
    const stored = await db.user.findUniqueOrThrow({ where: { id: target.id } });
    expect(stored.role).toBe('admin');
    expect(stored.passwordHash).not.toBe('x');
  });

  it('refuses a target that is not an academy admin', async () => {
    const learner = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.student } });
    const instructor = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.instructor } });
    const superadmin = await platformDb.user.findFirstOrThrow({ where: { role: 'superadmin' } });

    for (const user of [learner, instructor, superadmin]) {
      expect((await platform.patch(`/superadmin/admins/${user.id}`, { name: 'Hijacked' })).status, user.role).toBe(404);
      expect((await platformDb.user.findUniqueOrThrow({ where: { id: user.id } })).name, user.role).not.toBe('Hijacked');
    }
    expect((await platform.patch('/superadmin/admins/does-not-exist', { name: 'Ghost' })).status).toBe(404);
    // An id of any shape is an id that matches nothing — never an unhandled error.
    const overLong = 'x'.repeat(100);
    expect((await platform.patch(`/superadmin/admins/${overLong}`, { name: 'Ghost' })).status).toBe(404);
    expect((await platform.post(`/superadmin/admins/${overLong}/deactivate`)).status).toBe(404);
    expect((await platform.post(`/superadmin/admins/${overLong}/reactivate`)).status).toBe(404);
  });

  it('refuses an address another account already holds', async () => {
    const target = await createAdmin();
    const res = await platform.patch(`/superadmin/admins/${target.id}`, { email: ACCOUNTS.student });
    expect(res.status).toBe(409);
    expect((await db.user.findUniqueOrThrow({ where: { id: target.id } })).email).toBe(target.email);
  });
});

describe('deactivating and reactivating an admin', () => {
  it('closes the account without deleting it, and lets it back in again', async () => {
    const target = await createAdmin('Comes And Goes');

    const off = await platform.post(`/superadmin/admins/${target.id}/deactivate`);
    expect(off.status).toBe(200);
    expect(typeof off.body.deactivatedAt).toBe('string');
    // The row is still there — deactivation is not deletion.
    expect(await db.user.count({ where: { id: target.id } })).toBe(1);

    const refused = await anon().post('/auth/login', { email: target.email, password: NEW_PASSWORD });
    expect(refused.status).toBe(403);
    expect(refused.body.message).toMatch(/deactivated/i);

    const on = await platform.post(`/superadmin/admins/${target.id}/reactivate`);
    expect(on.status).toBe(200);
    expect(on.body.deactivatedAt).toBeUndefined();
    expect((await anon().post('/auth/login', { email: target.email, password: NEW_PASSWORD })).status).toBe(200);
  });

  it('ends an open session on the next session read', async () => {
    const target = await createAdmin('Signed In Already');
    const signedIn = await anon().post('/auth/login', { email: target.email, password: NEW_PASSWORD });
    const token = signedIn.body.token as string;
    expect((await request(app).get('/auth/me').set('Authorization', `Bearer ${token}`)).status).toBe(200);

    await platform.post(`/superadmin/admins/${target.id}/deactivate`);
    expect((await request(app).get('/auth/me').set('Authorization', `Bearer ${token}`)).status).toBe(403);
  });

  // A closed account must stay closed: resetting the password is not a way back in.
  it('cannot be reopened through the forgot-password flow', async () => {
    const target = await createAdmin('Tries The Back Door');
    await platform.post(`/superadmin/admins/${target.id}/deactivate`);

    const asked = await anon().post('/auth/forgot-password', { email: target.email });
    expect(asked.status).toBe(200);
    const sent = await db.emailOutbox.findFirst({ where: { toEmail: target.email }, orderBy: { createdAt: 'desc' } });
    const token = sent?.text.match(/reset-password\/([A-Za-z0-9_-]+)/)?.[1];
    expect(token).toBeTruthy();

    const chosen = await anon().post('/auth/reset-password', { token, password: 'a-freshly-chosen-password' });
    // Whether or not the reset itself is accepted, the account still cannot sign in.
    expect([200, 400, 403, 409]).toContain(chosen.status);
    const refused = await anon().post('/auth/login', { email: target.email, password: 'a-freshly-chosen-password' });
    expect(refused.status).toBe(403);
    expect(refused.body.message).toMatch(/deactivated/i);
  });

  it('takes a repeated call safely, and records it only once', async () => {
    const target = await createAdmin();
    const first = await platform.post(`/superadmin/admins/${target.id}/deactivate`);
    const again = await platform.post(`/superadmin/admins/${target.id}/deactivate`);
    expect(again.status).toBe(200);
    expect(again.body.deactivatedAt).toBe(first.body.deactivatedAt);
    expect((await auditFor(target.id)).filter((e) => e.action === 'admin.deactivated')).toHaveLength(1);

    await platform.post(`/superadmin/admins/${target.id}/reactivate`);
    const reactivatedAgain = await platform.post(`/superadmin/admins/${target.id}/reactivate`);
    expect(reactivatedAgain.status).toBe(200);
    expect((await auditFor(target.id)).filter((e) => e.action === 'admin.reactivated')).toHaveLength(1);
  });

  it('refuses a learner, an instructor or another super admin', async () => {
    const learner = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.student } });
    const instructor = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.instructor } });
    const superadmin = await platformDb.user.findFirstOrThrow({ where: { role: 'superadmin' } });

    for (const user of [learner, instructor, superadmin]) {
      expect((await platform.post(`/superadmin/admins/${user.id}/deactivate`)).status, user.role).toBe(404);
      expect((await platform.post(`/superadmin/admins/${user.id}/reactivate`)).status, user.role).toBe(404);
      expect((await platformDb.user.findUniqueOrThrow({ where: { id: user.id } })).deactivatedAt, user.role).toBeNull();
    }
    // The super admin running this suite can still read its own surface.
    expect((await platform.get('/superadmin/overview')).status).toBe(200);
  });
});

describe('every successful change is on the audit trail', () => {
  it('records the four actions, attributed to the super admin, with no credential in sight', async () => {
    const target = await createAdmin('Audited Admin');
    await platform.patch(`/superadmin/admins/${target.id}`, { name: 'Audited Twice' });
    await platform.post(`/superadmin/admins/${target.id}/deactivate`);
    await platform.post(`/superadmin/admins/${target.id}/reactivate`);

    const events = await auditFor(target.id);
    expect(events.map((e) => e.action)).toEqual(['admin.created', 'admin.updated', 'admin.deactivated', 'admin.reactivated']);
    for (const event of events) {
      expect(event.targetType).toBe('admin');
      expect(event.actorRole).toBe('superadmin');
      expect(event.actorEmail).toContain('platform-admins-');
      expect(event.metaJson).not.toMatch(/password|passwordHash|\$2[aby]\$|token|secret/i);
    }
    expect(JSON.parse(events[1].metaJson)).toEqual({ name: { from: 'Audited Admin', to: 'Audited Twice' } });

    // The trail is readable where the platform reads it, newest first.
    const listed = await platform.get('/superadmin/audit', { pageSize: 100 });
    expect(listed.body.rows.some((r: { action: string }) => r.action === 'admin.created')).toBe(true);
  });

  it('writes nothing when the change is refused', async () => {
    const before = await db.auditLog.count();
    await platform.post('/superadmin/admins', { name: 'A', email: 'nope', password: 'short' });
    await platform.patch('/superadmin/admins/does-not-exist', { name: 'Ghost' });
    await admin.post('/superadmin/admins', newAdminBody());
    expect(await db.auditLog.count()).toBe(before);
  });
});

describe('the academy is unaffected', () => {
  it('leaves the seeded admin signing in and working exactly as before', async () => {
    const signedIn = await anon().post('/auth/login', { email: ACCOUNTS.admin, password: PASSWORD });
    expect(signedIn.status).toBe(200);
    expect(signedIn.body.user.role).toBe('admin');
    for (const path of ['/courses', '/students', '/settings', '/dashboard', '/instructors']) {
      expect((await admin.get(path)).status, path).toBe(200);
    }
  });

  it('lets the super admin run the workspace through the same endpoints (docs/16, D-PLAT-03)', async () => {
    for (const path of ['/courses', '/students', '/settings', '/dashboard']) {
      expect((await platform.get(path)).status, path).toBe(200);
    }
  });

  it('leaves learners and instructors signing in as before', async () => {
    expect((await anon().post('/auth/login', { email: ACCOUNTS.student, password: PASSWORD })).status).toBe(200);
    expect((await anon().post('/auth/login', { email: ACCOUNTS.instructor, password: PASSWORD })).status).toBe(200);
  });
});
