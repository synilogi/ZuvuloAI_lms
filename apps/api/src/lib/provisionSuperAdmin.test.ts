import { describe, expect, it } from 'vitest';

import { verifyPassword } from './auth.js';
// Accounts are found by email across the platform (D2); a super admin belongs to no academy.
import { platformDb as db } from '../test/db.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { ACCOUNTS, PASSWORD, anon, unique } from '../test/helpers.js';

/* Provisioning runs against the seeded test database. Each case uses its own address, so the suite
 * does not depend on the order it runs in. */
const freshEmail = () => `superadmin-${unique()}@example.com`;
const SECRET = 'provision-test-password';

describe('provisioning the Super Admin account', () => {
  it('creates the account when there is none, with the superadmin role and no learner or teaching profile', async () => {
    const email = freshEmail();
    const result = await provisionSuperAdmin({ email, password: SECRET, name: 'Platform Owner' });

    expect(result.status).toBe('created');
    expect(result.user).toMatchObject({ email, name: 'Platform Owner', role: 'superadmin' });

    const stored = await db.user.findUnique({ where: { email }, include: { student: true } });
    expect(stored?.role).toBe('superadmin');
    expect(stored?.student).toBeNull();
    expect(stored?.instructorId).toBeNull();
    expect(stored?.descriptor).toBe('Platform admin');
  });

  it('is safe to run again: no duplicate, no rewrite of the account that is already there', async () => {
    const email = freshEmail();
    const first = await provisionSuperAdmin({ email, password: SECRET });
    const before = await db.user.findUniqueOrThrow({ where: { email } });

    const second = await provisionSuperAdmin({ email, password: 'a-completely-different-password' });
    expect(second.status).toBe('unchanged');
    expect(second.user.id).toBe(first.user.id);

    expect(await db.user.count({ where: { email } })).toBe(1);
    const after = await db.user.findUniqueOrThrow({ where: { email } });
    expect(after.passwordHash).toBe(before.passwordHash);
    expect(after.role).toBe('superadmin');
  });

  it('stores a password the existing sign-in flow accepts', async () => {
    const email = freshEmail();
    await provisionSuperAdmin({ email, password: SECRET });

    const stored = await db.user.findUniqueOrThrow({ where: { email } });
    expect(stored.passwordHash).not.toContain(SECRET);
    expect(await verifyPassword(SECRET, stored.passwordHash)).toBe(true);

    // The real route, not just the hash: the account signs in and its token carries the new role.
    const res = await anon().post('/auth/login', { email, password: SECRET });
    expect(res.status).toBe(200);
    expect(res.body.user.role).toBe('superadmin');

    const me = await anon().get('/auth/me').set('Authorization', `Bearer ${res.body.token}`);
    expect(me.status).toBe(200);
    expect(me.body.user.email).toBe(email);
  });

  it('normalises the address the way sign-in does, so a capitalised entry still logs in', async () => {
    const email = freshEmail();
    const result = await provisionSuperAdmin({ email: `  ${email.toUpperCase()}  `, password: SECRET });
    expect(result.user.email).toBe(email);
    expect((await anon().post('/auth/login', { email, password: SECRET })).status).toBe(200);
  });

  it('refuses an address that belongs to somebody else and leaves that account untouched', async () => {
    const before = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.admin } });

    const result = await provisionSuperAdmin({ email: ACCOUNTS.admin, password: SECRET });
    expect(result.status).toBe('conflict');
    expect(result.user.role).toBe('admin');

    const after = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.admin } });
    expect(after.role).toBe('admin');
    expect(after.passwordHash).toBe(before.passwordHash);
    // The academy admin still signs in with the password it always had.
    const res = await anon().post('/auth/login', { email: ACCOUNTS.admin, password: PASSWORD });
    expect(res.status).toBe(200);
    expect(res.body.user.role).toBe('admin');
  });

  it('refuses details the sign-in flow could not work with, and writes nothing', async () => {
    const email = freshEmail();
    await expect(provisionSuperAdmin({ email, password: 'short' })).rejects.toThrow(/at least 8 characters/);
    await expect(provisionSuperAdmin({ email: 'not-an-email', password: SECRET })).rejects.toThrow(/not usable/);
    expect(await db.user.count({ where: { email } })).toBe(0);
  });
});
