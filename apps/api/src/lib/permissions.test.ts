import express from 'express';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { PERMISSION_KEYS } from '@syniastrolms/domain';

import { attachAuth, requireAuth, requireRole, signToken } from './auth.js';
import { tenantContext } from './requestContext.js';
import { T, db, inAcademy, platformDb } from '../test/db.js';
import { errorHandler } from './errors.js';
import { backfillAdminPermissions, grantAllPermissions, hasPermission, permissionsFor, requirePermission, unknownPermissionsFor } from './permissions.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { ACCOUNTS, PASSWORD, anon, as, tokenFor, unique, type Client } from '../test/helpers.js';

/* The permission foundation. Nothing in the application reads these grants yet — these tests cover
 * the store, the helpers and the guard that Phase 10 will compose onto routes. */

const SECRET = 'permissions-suite-password';
const PASSWORD_FOR_NEW_ADMIN = 'a-new-admin-password';

/* A probe app, assembled the way `createApp` assembles the real one. */
const probe = express();
probe.use(attachAuth);
probe.use(tenantContext);
probe.get('/probe/publish', requireAuth, requirePermission('catalog.publish'), (_req, res) => res.json({ ok: true }));
probe.get('/probe/shared', requireAuth, requireRole('instructor', 'admin'), requirePermission('catalog.publish', { roles: ['instructor'] }), (_req, res) =>
  res.json({ ok: true }),
);
probe.use(errorHandler);

const call = (path: string, token?: string) => {
  const req = request(probe).get(path);
  return token ? req.set('Authorization', `Bearer ${token}`) : req;
};

let platform: Client;
let seededAdminId: string;
/* Accounts this file creates, removed afterwards: the suite shares one database, and a directory
 * page left full of test admins is a trap for the next file. */
const created: string[] = [];

/** A fresh academy admin, created the way the platform creates one. */
async function newAdmin(name = 'Permission Subject') {
  const res = await platform.post('/superadmin/admins', {
    name,
    email: `perm-admin-${unique()}@example.com`,
    password: PASSWORD_FOR_NEW_ADMIN,
    tenantId: 'tenant-1',
  });
  expect(res.status).toBe(201);
  created.push(res.body.id as string);
  return res.body.id as string;
}

beforeAll(async () => {
  const email = `platform-perms-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: SECRET, name: 'Platform Owner' });
  platform = await as({ email, password: SECRET });
  seededAdminId = (await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.admin }, select: { id: true } })).id;
});

afterAll(async () => {
  // Grants go with the account (onDelete: Cascade); the seeded academy is left exactly as found.
  await db.user.deleteMany({ where: { id: { in: created } } });
});

describe('the grant store', () => {
  it('holds nothing for an account nobody has granted', async () => {
    const learner = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.student }, select: { id: true } });
    expect(await inAcademy(() => permissionsFor(learner.id))).toEqual([]);
    expect(await inAcademy(() => hasPermission(learner.id, 'catalog.publish'))).toBe(false);
  });

  it('cannot hold the same key twice for one account', async () => {
    const userId = await newAdmin();
    await expect(db.adminPermission.create({ data: { ...T, userId, key: 'catalog.view' } })).rejects.toMatchObject({ code: 'P2002' });
    expect(await db.adminPermission.count({ where: { userId, key: 'catalog.view' } })).toBe(1);
  });

  it('answers with the keys an account holds, in catalogue order', async () => {
    const userId = await newAdmin();
    await db.adminPermission.deleteMany({ where: { userId } });
    await db.adminPermission.createMany({
      data: [
        { ...T, userId, key: 'settings.edit' },
        { ...T, userId, key: 'catalog.view' },
      ],
    });

    expect(await inAcademy(() => permissionsFor(userId))).toEqual(['catalog.view', 'settings.edit']);
    expect(await inAcademy(() => hasPermission(userId, 'catalog.view'))).toBe(true);
    expect(await inAcademy(() => hasPermission(userId, 'catalog.publish'))).toBe(false);
  });

  it('ignores a key the catalogue no longer knows, without deleting it', async () => {
    const userId = await newAdmin();
    await db.adminPermission.create({ data: { ...T, userId, key: 'catalog.telepathy' } });
    expect(await inAcademy(() => permissionsFor(userId))).not.toContain('catalog.telepathy');
    expect(await inAcademy(() => unknownPermissionsFor(userId))).toEqual(['catalog.telepathy']);
    expect(await db.adminPermission.count({ where: { userId, key: 'catalog.telepathy' } })).toBe(1);
  });

  it('grants the whole catalogue once, and adds nothing on a second call', async () => {
    const userId = await newAdmin();
    await db.adminPermission.deleteMany({ where: { userId } });

    const first = await inAcademy(() => grantAllPermissions(userId));
    expect(first).toEqual(PERMISSION_KEYS);
    expect(await inAcademy(() => permissionsFor(userId))).toEqual(PERMISSION_KEYS);

    const second = await inAcademy(() => grantAllPermissions(userId));
    expect(second).toEqual([]);
    expect(await db.adminPermission.count({ where: { userId } })).toBe(PERMISSION_KEYS.length);
  });
});

describe('requirePermission', () => {
  it('refuses an anonymous caller and an unusable token', async () => {
    expect((await call('/probe/publish')).status).toBe(401);
    expect((await call('/probe/publish', 'not-a-real-token')).status).toBe(401);
  });

  it('lets an admin holding the key through, and refuses one without it', async () => {
    const userId = await newAdmin('Granted Admin');
    const email = (await db.user.findUniqueOrThrow({ where: { id: userId }, select: { email: true } })).email;
    const token = await tokenFor({ email, password: PASSWORD_FOR_NEW_ADMIN });
    // Created with the whole catalogue.
    expect((await call('/probe/publish', token)).status).toBe(200);

    await db.adminPermission.deleteMany({ where: { userId, key: 'catalog.publish' } });
    expect((await call('/probe/publish', token)).status).toBe(403);
    // Another key it still holds is unaffected.
    expect(await inAcademy(() => hasPermission(userId, 'catalog.view'))).toBe(true);
  });

  it('gives no access to a learner or an instructor, and every capability to the super admin', async () => {
    for (const account of ['student', 'instructor'] as const) {
      expect((await call('/probe/publish', await tokenFor(account))).status, account).toBe(403);
    }
    // The platform's owner holds every capability without a grant (docs/16, D-PLAT-03).
    expect((await call('/probe/publish', platform.token)).status).toBe(200);
    // A signed token naming no account is no session at all: refused as unauthenticated before any role check.
    expect((await call('/probe/publish', signToken({ sub: 'nobody', role: 'superadmin' }))).status).toBe(401);
  });

  it('cannot be satisfied by a grant on some other account', async () => {
    const granted = await newAdmin('Holds Everything');
    expect(await inAcademy(() => hasPermission(granted, 'catalog.publish'))).toBe(true);
    // A learner with a row in the table — which nothing creates — still gets nowhere.
    const learner = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.student }, select: { id: true } });
    await db.adminPermission.create({ data: { ...T, userId: learner.id, key: 'catalog.publish' } });
    expect((await call('/probe/publish', await tokenFor('student'))).status).toBe(403);
    await db.adminPermission.deleteMany({ where: { userId: learner.id } });
  });

  it('leaves a role the route governs by role untouched', async () => {
    // The instructor passes on its role and is never asked for a grant.
    expect((await call('/probe/shared', await tokenFor('instructor'))).status).toBe(200);
    const instructorUser = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.instructor }, select: { id: true } });
    expect(await inAcademy(() => permissionsFor(instructorUser.id))).toEqual([]);

    // The admin on the same route still needs the key.
    const userId = await newAdmin('Shared Route Admin');
    const email = (await db.user.findUniqueOrThrow({ where: { id: userId }, select: { email: true } })).email;
    const token = await tokenFor({ email, password: PASSWORD_FOR_NEW_ADMIN });
    expect((await call('/probe/shared', token)).status).toBe(200);
    await db.adminPermission.deleteMany({ where: { userId, key: 'catalog.publish' } });
    expect((await call('/probe/shared', token)).status).toBe(403);
  });
});

describe('backfilling the admins that already existed', () => {
  it('gives every admin the whole catalogue and nobody else anything', async () => {
    await db.adminPermission.deleteMany({ where: { userId: seededAdminId } });
    const result = await backfillAdminPermissions();

    // The backfill is an operator task across the platform: every academy's admins, not just this one's.
    expect(result.admins).toBe(await platformDb.user.count({ where: { role: 'admin' } }));
    expect(await inAcademy(() => permissionsFor(seededAdminId))).toEqual(PERMISSION_KEYS);

    for (const role of ['student', 'instructor', 'superadmin'] as const) {
      const holders = await db.adminPermission.count({ where: { user: { role } } });
      expect(holders, role).toBe(0);
    }
  });

  it('adds nothing the second time', async () => {
    await backfillAdminPermissions();
    const before = await db.adminPermission.count();
    const again = await backfillAdminPermissions();
    expect(again.granted).toBe(0);
    expect(again.unchanged).toBe(again.admins);
    expect(await db.adminPermission.count()).toBe(before);
  });
});

describe('nothing about the academy has changed', () => {
  it('starts a new admin with every permission, so it can do what an admin always could', async () => {
    const userId = await newAdmin('Brand New Admin');
    expect(await inAcademy(() => permissionsFor(userId))).toEqual(PERMISSION_KEYS);
  });

  it('gives a super admin no grants when one is provisioned', async () => {
    const email = `no-grants-${unique()}@example.com`;
    const created = await provisionSuperAdmin({ email, password: SECRET, name: 'No Grants' });
    expect(await db.adminPermission.count({ where: { userId: created.user.id } })).toBe(0);
  });

  it('leaves the seeded admin signing in and working exactly as before', async () => {
    const signedIn = await anon().post('/auth/login', { email: ACCOUNTS.admin, password: PASSWORD });
    expect(signedIn.status).toBe(200);
    expect(signedIn.body.user.role).toBe('admin');
    // The session response now carries the grants it reads from the database (Phase 10).
    expect(signedIn.body.user.permissions).toEqual(PERMISSION_KEYS);

    const admin = await as('admin');
    expect((await admin.get('/auth/me')).body.user.permissions).toEqual(PERMISSION_KEYS);
    for (const path of ['/courses', '/students', '/settings', '/dashboard', '/instructors', '/reports/overview', '/categories']) {
      expect((await admin.get(path)).status, path).toBe(200);
    }
  });

  it('leaves an admin with no grants only what stayed role-based', async () => {
    const userId = await newAdmin('Stripped Admin');
    const email = (await db.user.findUniqueOrThrow({ where: { id: userId }, select: { email: true } })).email;
    await db.adminPermission.deleteMany({ where: { userId } });
    expect(await inAcademy(() => permissionsFor(userId))).toEqual([]);

    const stripped = await as({ email, password: PASSWORD_FOR_NEW_ADMIN });
    // Since Phase 12 these answer to a key, and this account holds none.
    for (const path of ['/courses', '/students', '/settings', '/dashboard', '/instructors']) {
      expect((await stripped.get(path)).status, path).toBe(403);
    }
    // Reading certificates and live classes has no key, so it is still governed by role alone.
    expect((await stripped.get('/certificates')).status).toBe(200);
    expect((await stripped.get('/live')).status).toBe(200);

    // Put it back, so the account is left as the create endpoint made it.
    await inAcademy(() => grantAllPermissions(userId));
  });
});
