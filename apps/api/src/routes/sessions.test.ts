import request from 'supertest';
import jwt from 'jsonwebtoken';
import { beforeAll, describe, expect, it } from 'vitest';

import { createApp } from '../app.js';
import { pruneSessions, SESSION_RETENTION_DAYS } from '../lib/sessions.js';
import { issuePasswordResetToken } from '../lib/passwordReset.js';
import { runAsOwnerOf } from '../lib/tenancy.js';
import { platformDb } from '../test/db.js';
import { PASSWORD, anon, app, newStudent } from '../test/helpers.js';

/* SAAS-020. A token names its session; ending the session ends the token on the next request. Tokens from
 * before sessions still work until they expire, unless logout-all, a password change or a reset ended them. */

const signIn = async (email: string, password = PASSWORD, userAgent = 'QA device') => {
  const res = await request(app).post('/auth/login').set('User-Agent', userAgent).send({ email, password });
  expect(res.status, JSON.stringify(res.body)).toBe(200);
  return res.body.token as string;
};
const call = (token: string, method: 'get' | 'post' | 'patch' | 'delete', path: string, body?: unknown) => {
  const agent = request(app);
  return agent[method](path)
    .set('Authorization', `Bearer ${token}`)
    .send(body as object | undefined);
};

let learner: Awaited<ReturnType<typeof newStudent>>;

beforeAll(async () => {
  learner = await newStudent('Session Learner');
});

describe('a token names a session that the server keeps', () => {
  it('starts a session at sign-in and at sign-up', async () => {
    const token = await signIn(learner.email);
    const { sid } = jwt.decode(token) as { sid: string };
    const row = await platformDb.userSession.findUniqueOrThrow({ where: { id: sid } });
    expect(row).toMatchObject({ userId: learner.userId, revokedAt: null, userAgent: 'QA device' });
    expect(row.tenantId).not.toBeNull();
    expect((jwt.decode(learner.token) as { sid?: string }).sid).toBeDefined();
  });

  it('ends only this session on logout, on every route at once', async () => {
    const phone = await signIn(learner.email, PASSWORD, 'phone');
    const laptop = await signIn(learner.email, PASSWORD, 'laptop');
    const out = await call(phone, 'post', '/auth/logout');
    expect(out.body).toEqual({ revoked: 1 });
    for (const path of ['/auth/me', '/learning/home', '/notifications']) expect((await call(phone, 'get', path)).status, path).toBe(401);
    expect((await call(laptop, 'get', '/auth/me')).status).toBe(200);
    // Logging out twice changes nothing and is still answered.
    expect((await call(phone, 'post', '/auth/logout')).status).toBe(401);
    expect((await anon().post('/auth/logout')).status).toBe(401);
  });

  it('lists the account’s open sessions and ends one by id — only its own', async () => {
    const a = await signIn(learner.email, PASSWORD, 'tablet');
    const b = await signIn(learner.email, PASSWORD, 'desktop');
    const list = await call(a, 'get', '/auth/sessions');
    const sessions = list.body.sessions as { id: string; current: boolean; userAgent?: string }[];
    expect(sessions.filter((s) => s.current)).toHaveLength(1);
    const desktop = sessions.find((s) => s.userAgent === 'desktop')!;
    expect(JSON.stringify(list.body)).not.toMatch(/userId|tenantId/);

    const other = await newStudent('Someone Else');
    expect((await call(other.token, 'delete', `/auth/sessions/${desktop.id}`)).status).toBe(404);
    expect((await call(b, 'get', '/auth/me')).status).toBe(200);
    expect((await call(a, 'delete', `/auth/sessions/${desktop.id}`)).status).toBe(204);
    expect((await call(b, 'get', '/auth/me')).status).toBe(401);
    expect((await call(a, 'delete', `/auth/sessions/${desktop.id}`)).status).toBe(404);
  });

  it('ends every session, and every token from before sessions, on logout-all', async () => {
    const user = await newStudent('Everywhere Learner');
    const one = await signIn(user.email);
    const two = await signIn(user.email);
    // A token signed the way tokens were before sessions: no sid.
    const legacy = jwt.sign({ sub: user.userId, role: 'student', studentId: user.studentId }, process.env.JWT_SECRET!, { expiresIn: '1h' });
    expect((await call(legacy, 'get', '/auth/me')).status).toBe(200);

    const all = await call(one, 'post', '/auth/logout-all');
    expect(all.body.revoked).toBeGreaterThanOrEqual(3);
    for (const token of [one, two, legacy, user.token]) expect((await call(token, 'get', '/auth/me')).status).toBe(401);
    // Signing in again works as ever.
    expect((await call(await signIn(user.email), 'get', '/auth/me')).status).toBe(200);
  });

  it('keeps a token from before sessions working until something ends it', async () => {
    const user = await newStudent('Legacy Learner');
    const legacy = jwt.sign({ sub: user.userId, role: 'student', studentId: user.studentId }, process.env.JWT_SECRET!, { expiresIn: '1h' });
    expect((await call(legacy, 'get', '/learning/home')).status).toBe(200);
    expect((await call(legacy, 'post', '/auth/logout')).body).toEqual({ revoked: 0 });
    expect((await call(legacy, 'get', '/learning/home')).status).toBe(200);
  });

  it('refuses a token naming a session that does not exist', async () => {
    const forged = jwt.sign({ sub: learner.userId, role: 'student', studentId: learner.studentId, sid: 'no-such-session' }, process.env.JWT_SECRET!, {
      expiresIn: '1h',
    });
    expect((await call(forged, 'get', '/auth/me')).status).toBe(401);
  });
});

describe('passwords end other sessions', () => {
  it('needs the current password to change it, ends every session, and gives this device a fresh token', async () => {
    const user = await newStudent('Changing Learner');
    const here = await signIn(user.email);
    const elsewhere = await signIn(user.email);
    expect((await call(here, 'post', '/auth/change-password', { currentPassword: 'wrong-password', newPassword: 'new-password-1' })).status).toBe(403);
    expect((await call(here, 'post', '/auth/change-password', { currentPassword: PASSWORD, newPassword: 'short' })).status).toBe(400);
    expect((await call(here, 'post', '/auth/change-password', { currentPassword: PASSWORD, newPassword: PASSWORD })).status).toBe(409);

    const changed = await call(here, 'post', '/auth/change-password', { currentPassword: PASSWORD, newPassword: 'new-password-1' });
    expect(changed.status).toBe(200);
    expect(changed.body.user.email).toBe(user.email);
    for (const token of [here, elsewhere]) expect((await call(token, 'get', '/auth/me')).status).toBe(401);
    expect((await call(changed.body.token, 'get', '/auth/me')).status).toBe(200);
    expect((await anon().post('/auth/login', { email: user.email, password: PASSWORD })).status).toBe(401);
    expect((await anon().post('/auth/login', { email: user.email, password: 'new-password-1' })).status).toBe(200);
  });

  it('ends every session when the password is reset from an emailed link', async () => {
    const user = await newStudent('Resetting Learner');
    const token = await signIn(user.email);
    const owner = await platformDb.user.findUniqueOrThrow({ where: { id: user.userId } });
    const link = await runAsOwnerOf(owner, () => issuePasswordResetToken(user.userId));
    expect((await anon().post('/auth/reset-password', { token: link, password: 'reset-password-1' })).status).toBe(200);
    expect((await call(token, 'get', '/auth/me')).status).toBe(401);
    expect((await call(user.token, 'get', '/auth/me')).status).toBe(401);
  });
});

describe('the signed-in account’s own profile', () => {
  it('changes the display name only — never the email, role or academy', async () => {
    const user = await newStudent('Profile Learner');
    const before = await platformDb.user.findUniqueOrThrow({ where: { id: user.userId } });
    const res = await call(user.token, 'patch', '/auth/me', { name: 'Renamed Learner', email: 'taken@example.com', role: 'admin', tenantId: 'x' });
    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({ name: 'Renamed Learner', email: user.email, role: 'student' });
    const after = await platformDb.user.findUniqueOrThrow({ where: { id: user.userId } });
    expect(after).toMatchObject({ name: 'Renamed Learner', email: before.email, role: 'student', tenantId: before.tenantId });
    expect((await call(user.token, 'patch', '/auth/me', { name: 'x' })).status).toBe(400);
    expect((await anon().patch('/auth/me', { name: 'Nobody Here' })).status).toBe(401);
  });

  it('keeps an instructor’s public profile in step with the account name', async () => {
    const instructor = await platformDb.user.findFirstOrThrow({ where: { email: 'vinod@syniastrolms.test' } });
    const token = await signIn(instructor.email);
    expect((await call(token, 'patch', '/auth/me', { name: 'Acharya Vinod S.' })).status).toBe(200);
    expect((await platformDb.instructor.findUniqueOrThrow({ where: { id: instructor.instructorId! } })).name).toBe('Acharya Vinod S.');
    await call(token, 'patch', '/auth/me', { name: instructor.name });
  });
});

describe('expired sessions are pruned', () => {
  it('removes sessions long past expiry and keeps the rest', async () => {
    const user = await newStudent('Old Sessions');
    const old = await platformDb.userSession.create({
      data: {
        tenantId: (await platformDb.user.findUniqueOrThrow({ where: { id: user.userId } })).tenantId,
        userId: user.userId,
        expiresAt: new Date(Date.now() - (SESSION_RETENTION_DAYS + 1) * 86_400_000),
      },
    });
    const removed = await pruneSessions();
    expect(removed).toBeGreaterThanOrEqual(1);
    expect(await platformDb.userSession.findUnique({ where: { id: old.id } })).toBeNull();
    expect((await call(user.token, 'get', '/auth/me')).status).toBe(200);
  });
});

describe('the new account endpoints sit behind the sign-in rate limit', () => {
  it('refuses repeated attempts at changing a password or logging out', async () => {
    const limited = createApp({ rateLimits: { auth: 2 } });
    const token = learner.token;
    const statuses: number[] = [];
    for (let i = 0; i < 3; i++) {
      statuses.push(
        (
          await request(limited)
            .post('/auth/change-password')
            .set('Authorization', `Bearer ${token}`)
            .send({ currentPassword: 'guess-' + i, newPassword: 'new-password-9' })
        ).status,
      );
    }
    expect(statuses).toEqual([403, 403, 429]);
    expect((await request(limited).post('/auth/logout').set('Authorization', `Bearer ${token}`)).status).toBe(429);
  });
});
