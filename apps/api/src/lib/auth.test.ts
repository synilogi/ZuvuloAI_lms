import express from 'express';
import { describe, expect, it } from 'vitest';
import request from 'supertest';

import { attachAuth, requireAuth, requireRole, requireSuperAdmin, signToken } from './auth.js';
import { errorHandler } from './errors.js';
import { tokenFor } from '../test/helpers.js';

/* Super Admin has no endpoints yet, so the guards are exercised through a probe app assembled the
 * way `createApp` assembles the real one: attachAuth in front, errorHandler behind. */
const probe = express();
probe.use(attachAuth);
probe.get('/probe/platform', requireSuperAdmin, (_req, res) => res.json({ ok: true }));
probe.get('/probe/teaching', requireAuth, requireRole('instructor'), (_req, res) => res.json({ ok: true }));
probe.get('/probe/academy', requireAuth, requireRole('admin'), (_req, res) => res.json({ ok: true }));
probe.use(errorHandler);

const call = (path: string, token?: string) => {
  const req = request(probe).get(path);
  return token ? req.set('Authorization', `Bearer ${token}`) : req;
};

/** Phase 3 provisions the real account; the guard reads the token alone, so a signed one is enough here. */
const superadminToken = () => signToken({ sub: 'superadmin-under-test', role: 'superadmin' });

describe('requireSuperAdmin', () => {
  it('refuses an anonymous caller with 401', async () => {
    const res = await call('/probe/platform');
    expect(res.status).toBe(401);
    expect(res.body.message).toBe('Sign in required');
  });

  it('refuses a token it cannot verify with 401', async () => {
    const res = await call('/probe/platform', 'not-a-real-token');
    expect(res.status).toBe(401);
  });

  // The point of the role: the academy admin is not quietly promoted to the platform.
  it('refuses the academy admin with 403', async () => {
    const res = await call('/probe/platform', await tokenFor('admin'));
    expect(res.status).toBe(403);
    expect(res.body.message).toBe('Not allowed');
  });

  it('refuses an instructor with 403', async () => {
    expect((await call('/probe/platform', await tokenFor('instructor'))).status).toBe(403);
  });

  it('refuses a student with 403', async () => {
    expect((await call('/probe/platform', await tokenFor('student'))).status).toBe(403);
  });

  it('lets a super admin through', async () => {
    const res = await call('/probe/platform', superadminToken());
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true });
  });
});

describe('requireRole is unchanged by the new role', () => {
  it('still lets the admin through an instructor-only guard', async () => {
    expect((await call('/probe/teaching', await tokenFor('admin'))).status).toBe(200);
    expect((await call('/probe/teaching', await tokenFor('instructor'))).status).toBe(200);
    expect((await call('/probe/teaching', await tokenFor('student'))).status).toBe(403);
    expect((await call('/probe/teaching')).status).toBe(401);
  });

  it('still keeps everyone but the admin out of an admin-only guard', async () => {
    expect((await call('/probe/academy', await tokenFor('admin'))).status).toBe(200);
    expect((await call('/probe/academy', await tokenFor('instructor'))).status).toBe(403);
    expect((await call('/probe/academy', await tokenFor('student'))).status).toBe(403);
  });

  // The platform's owner runs the workspace too (docs/16, D-PLAT-03): every role guard lets it through.
  it('lets a super admin through the workspace guards', async () => {
    expect((await call('/probe/teaching', superadminToken())).status).toBe(200);
    expect((await call('/probe/academy', superadminToken())).status).toBe(200);
  });
});
