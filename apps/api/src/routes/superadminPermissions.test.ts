import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { PERMISSION_GROUPS, PERMISSION_KEYS, PERMISSIONS } from '@syniastrolms/domain';

import { T, db, inAcademy, platformDb } from '../test/db.js';
import { permissionsFor } from '../lib/permissions.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { ACCOUNTS, anon, app, as, unique, type Client } from '../test/helpers.js';

/* Granting and revoking one admin's permissions, from the platform side. */

const SECRET = 'permission-editor-password';
const ADMIN_PASSWORD = 'a-managed-admin-password';

let platform: Client;
let admin: Client;
let targetId = '';
let targetEmail = '';
const created: string[] = [];

const pathFor = (id: string) => `/superadmin/admins/${id}/permissions`;
const auditFor = (id: string, action: string) => db.auditLog.findMany({ where: { targetId: id, action } });

async function newAdmin(name = 'Managed Admin') {
  const email = `managed-${unique()}@example.com`;
  const res = await platform.post('/superadmin/admins', { name, email, password: ADMIN_PASSWORD, tenantId: 'tenant-1' });
  expect(res.status).toBe(201);
  created.push(res.body.id as string);
  return { id: res.body.id as string, email };
}

beforeAll(async () => {
  const email = `platform-editor-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: SECRET, name: 'Platform Owner' });
  platform = await as({ email, password: SECRET });
  admin = await as('admin');
  const target = await newAdmin();
  targetId = target.id;
  targetEmail = target.email;
});

afterAll(async () => {
  if (created.length) await db.user.deleteMany({ where: { id: { in: created } } });
});

describe('only the super admin may edit an admin’s permissions', () => {
  it('refuses everyone else on read, grant and revoke', async () => {
    const calls: [string, (c: Client) => Promise<{ status: number }>][] = [
      ['read', (c) => c.get(pathFor(targetId))],
      ['grant', (c) => c.post(pathFor(targetId), { key: 'settings.edit' })],
      ['revoke', (c) => c.delete(`${pathFor(targetId)}/settings.edit`)],
    ];
    const instructor = await as('instructor');
    const student = await as('student');

    for (const [name, call] of calls) {
      expect((await call(anon())).status, `anonymous ${name}`).toBe(401);
      expect((await request(app).get(pathFor(targetId)).set('Authorization', 'Bearer not-a-real-token')).status).toBe(401);
      expect((await call(admin)).status, `academy admin ${name}`).toBe(403);
      expect((await call(instructor)).status, `instructor ${name}`).toBe(403);
      expect((await call(student)).status, `student ${name}`).toBe(403);
    }
    // None of that touched the grants.
    expect(await inAcademy(() => permissionsFor(targetId))).toEqual(PERMISSION_KEYS);
  });

  it('will not edit anything that is not an academy admin', async () => {
    const learner = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.student }, select: { id: true } });
    const instructor = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.instructor }, select: { id: true } });
    const superadmin = await platformDb.user.findFirstOrThrow({ where: { role: 'superadmin' }, select: { id: true } });

    for (const user of [learner, instructor, superadmin, { id: 'does-not-exist' }]) {
      expect((await platform.get(pathFor(user.id))).status, user.id).toBe(404);
      expect((await platform.post(pathFor(user.id), { key: 'settings.edit' })).status, user.id).toBe(404);
      expect((await platform.delete(`${pathFor(user.id)}/settings.edit`)).status, user.id).toBe(404);
      expect(await db.adminPermission.count({ where: { userId: user.id } }), user.id).toBe(0);
    }
  });
});

describe('reading what an admin may do', () => {
  it('answers with the whole catalogue, grouped, with what is held marked', async () => {
    const res = await platform.get(pathFor(targetId));
    expect(res.status).toBe(200);
    expect(res.body.admin).toMatchObject({ id: targetId, email: targetEmail, role: 'admin' });
    expect(res.body.admin).not.toHaveProperty('passwordHash');

    expect(res.body.groups.map((g: { group: string }) => g.group)).toEqual(PERMISSION_GROUPS);
    const flat = res.body.groups.flatMap((g: { permissions: unknown[] }) => g.permissions) as {
      key: string;
      label: string;
      description: string;
      granted: boolean;
    }[];
    expect(flat.map((p) => p.key)).toEqual(PERMISSION_KEYS);
    // Every key arrives with what it means, so the editor never has to invent a label.
    for (const entry of flat) {
      expect(entry.label).toBe(PERMISSIONS[entry.key as keyof typeof PERMISSIONS].label);
      expect(entry.description).toBe(PERMISSIONS[entry.key as keyof typeof PERMISSIONS].description);
      expect(entry.granted).toBe(true);
    }
    expect(res.body.granted).toEqual(PERMISSION_KEYS);
    expect(res.body.unknown).toEqual([]);
  });

  it('shows a key the catalogue no longer knows without letting it count as granted', async () => {
    await db.adminPermission.create({ data: { ...T, userId: targetId, key: 'catalog.telepathy' } });
    const res = await platform.get(pathFor(targetId));
    expect(res.body.unknown).toEqual(['catalog.telepathy']);
    expect(res.body.granted).not.toContain('catalog.telepathy');
    await db.adminPermission.deleteMany({ where: { userId: targetId, key: 'catalog.telepathy' } });
  });
});

describe('granting and revoking', () => {
  it('takes a permission away, gives it back, and records each real change once', async () => {
    const target = await newAdmin('Toggled Admin');

    const revoked = await platform.delete(`${pathFor(target.id)}/settings.edit`);
    expect(revoked.status).toBe(200);
    expect(revoked.body.granted).not.toContain('settings.edit');
    expect(await inAcademy(() => permissionsFor(target.id))).not.toContain('settings.edit');
    expect(await auditFor(target.id, 'admin.permissions.revoked')).toHaveLength(1);

    const granted = await platform.post(pathFor(target.id), { key: 'settings.edit' });
    expect(granted.status).toBe(200);
    expect(granted.body.granted).toContain('settings.edit');
    expect(await inAcademy(() => permissionsFor(target.id))).toContain('settings.edit');
    expect(await auditFor(target.id, 'admin.permissions.granted')).toHaveLength(1);
  });

  it('is idempotent both ways, and writes no second event', async () => {
    const target = await newAdmin('Repeated Admin');

    // Granting what is already held.
    const again = await platform.post(pathFor(target.id), { key: 'catalog.publish' });
    expect(again.status).toBe(200);
    expect(again.body.granted).toContain('catalog.publish');
    expect(await db.adminPermission.count({ where: { userId: target.id, key: 'catalog.publish' } })).toBe(1);
    expect(await auditFor(target.id, 'admin.permissions.granted')).toHaveLength(0);

    // Revoking twice.
    await platform.delete(`${pathFor(target.id)}/catalog.publish`);
    const twice = await platform.delete(`${pathFor(target.id)}/catalog.publish`);
    expect(twice.status).toBe(200);
    expect(twice.body.granted).not.toContain('catalog.publish');
    expect(await auditFor(target.id, 'admin.permissions.revoked')).toHaveLength(1);
  });

  it('leaves every other key alone', async () => {
    const target = await newAdmin('Narrowed Admin');
    await platform.delete(`${pathFor(target.id)}/certificates.revoke`);
    const after = await inAcademy(() => permissionsFor(target.id));
    expect(after).not.toContain('certificates.revoke');
    expect(after).toEqual(PERMISSION_KEYS.filter((k) => k !== 'certificates.revoke'));
  });

  it('can strip an admin down to nothing, one key at a time', async () => {
    const target = await newAdmin('Stripped Admin');
    for (const key of PERMISSION_KEYS) expect((await platform.delete(`${pathFor(target.id)}/${key}`)).status, key).toBe(200);
    expect(await inAcademy(() => permissionsFor(target.id))).toEqual([]);
    expect(
      (await platform.get(pathFor(target.id))).body.groups
        .flatMap((g: { permissions: { granted: boolean }[] }) => g.permissions)
        .every((p: { granted: boolean }) => !p.granted),
    ).toBe(true);
    expect(await auditFor(target.id, 'admin.permissions.revoked')).toHaveLength(PERMISSION_KEYS.length);
  });
});

describe('only a real permission is a permission', () => {
  const rubbish = ['', ' ', 'nonsense', 'platform.fake', 'superadmin.all', 'role.admin', 'tenant.manage', 'catalog.*', 'CATALOG.VIEW', 'toString', '__proto__'];

  it('refuses anything the catalogue does not name, on grant and on revoke', async () => {
    const before = await db.adminPermission.count({ where: { userId: targetId } });
    for (const key of rubbish) {
      expect((await platform.post(pathFor(targetId), { key })).status, `grant ${JSON.stringify(key)}`).toBe(400);
      if (key.trim()) expect((await platform.delete(`${pathFor(targetId)}/${encodeURIComponent(key)}`)).status, `revoke ${key}`).toBe(400);
    }
    expect((await platform.post(pathFor(targetId), {})).status).toBe(400);
    expect((await platform.post(pathFor(targetId), { key: 42 })).status).toBe(400);
    expect(await db.adminPermission.count({ where: { userId: targetId } })).toBe(before);
  });

  it('records nothing for a refused request', async () => {
    const before = await db.auditLog.count();
    await platform.post(pathFor(targetId), { key: 'tenant.manage' });
    await platform.delete(`${pathFor(targetId)}/tenant.manage`);
    await admin.post(pathFor(targetId), { key: 'settings.edit' });
    expect(await db.auditLog.count()).toBe(before);
  });
});

describe('the trail says who did it', () => {
  it('attributes the change to the signed-in super admin, whatever the body claims', async () => {
    const target = await newAdmin('Audited Admin');
    const platformUser = await platformDb.user.findFirstOrThrow({ where: { email: { startsWith: 'platform-editor-' } } });

    await platform.delete(`${pathFor(target.id)}/learners.suspend`);
    await platform.post(pathFor(target.id), {
      key: 'learners.suspend',
      // None of this is read: the actor comes from the token and the target from the URL.
      actorId: 'someone-else',
      actorEmail: 'forged@example.com',
      actorRole: 'admin',
      userId: targetId,
      role: 'superadmin',
    });

    const events = await db.auditLog.findMany({ where: { targetId: target.id }, orderBy: { createdAt: 'asc' } });
    expect(events.map((e) => e.action)).toEqual(['admin.created', 'admin.permissions.revoked', 'admin.permissions.granted']);
    for (const event of events.slice(1)) {
      expect(event.actorId).toBe(platformUser.id);
      expect(event.actorEmail).toBe(platformUser.email);
      expect(event.actorRole).toBe('superadmin');
      expect(event.targetType).toBe('admin');
      expect(JSON.parse(event.metaJson).key).toBe('learners.suspend');
      expect(event.metaJson).not.toMatch(/password|\$2[aby]\$|token|forged/i);
    }
    // And the target is still an admin, with no role touched.
    expect((await db.user.findUniqueOrThrow({ where: { id: target.id } })).role).toBe('admin');
  });

  it('shows up on the audit page the platform already has', async () => {
    const listed = await platform.get('/superadmin/audit', { pageSize: 100 });
    const actions = (listed.body.rows as { action: string; meta: Record<string, unknown> }[]).map((r) => r.action);
    expect(actions).toContain('admin.permissions.granted');
    expect(actions).toContain('admin.permissions.revoked');
    const entry = (listed.body.rows as { action: string; meta: Record<string, unknown> }[]).find((r) => r.action === 'admin.permissions.revoked');
    expect(typeof entry?.meta.key).toBe('string');
  });
});

describe('a change takes effect at once', () => {
  it('closes and reopens a protected endpoint on the same token', async () => {
    const target = await newAdmin('Live Admin');
    const client = await as({ email: target.email, password: ADMIN_PASSWORD });
    const categoryBody = { name: `Live ${unique()}`, glyph: 'sun' };

    expect((await client.post('/categories', categoryBody)).status).toBe(201);

    await platform.delete(`${pathFor(target.id)}/catalog.categories.manage`);
    expect((await client.post('/categories', { ...categoryBody, name: `Blocked ${unique()}` })).status).toBe(403);
    // The session reflects it too, without signing in again.
    expect((await client.get('/auth/me')).body.user.permissions).not.toContain('catalog.categories.manage');

    await platform.post(pathFor(target.id), { key: 'catalog.categories.manage' });
    expect((await client.post('/categories', { ...categoryBody, name: `Allowed ${unique()}` })).status).toBe(201);
    expect((await client.get('/auth/me')).body.user.permissions).toContain('catalog.categories.manage');

    await db.categoryLevel.deleteMany({ where: { category: { name: { startsWith: 'Live ' } } } });
    await db.category.deleteMany({ where: { name: { startsWith: 'Live ' } } });
    await db.category.deleteMany({ where: { name: { startsWith: 'Allowed ' } } });
  });

  it('keeps permissions and account status apart', async () => {
    const target = await newAdmin('Deactivated Admin');
    await platform.post(`/superadmin/admins/${target.id}/deactivate`);

    // Deactivating changes no grant, and a deactivated admin is still manageable.
    expect(await inAcademy(() => permissionsFor(target.id))).toEqual(PERMISSION_KEYS);
    expect((await platform.get(pathFor(target.id))).status).toBe(200);
    expect((await platform.delete(`${pathFor(target.id)}/settings.edit`)).status).toBe(200);
    expect(await inAcademy(() => permissionsFor(target.id))).not.toContain('settings.edit');

    await platform.post(`/superadmin/admins/${target.id}/reactivate`);
    // Reactivating restores the account, not the permission that was taken away.
    expect(await inAcademy(() => permissionsFor(target.id))).not.toContain('settings.edit');
  });
});
