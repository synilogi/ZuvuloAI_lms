import request from 'supertest';
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { createApp } from '../app.js';
import { prunePendingRegistrations } from '../lib/pendingAccounts.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { CODE_MAX_ATTEMPTS, CODE_MAX_SENDS } from '../lib/verificationCode.js';
import { ACADEMY, platformDb } from '../test/db.js';
import { anon, as, unique, type Client } from '../test/helpers.js';

/* Learners and instructors who register themselves verify their email before any account exists — through every door:
 * the academy's join link, an invitation, a course link, the host's sign-up and an instructor's request. The academy is
 * always the link's; the code is hashed, expires, allows a few tries and a few resends; and nothing is created, and no
 * seat is taken, until it is confirmed. */

const PASSWORD = 'verification-password-1';
let platform: Client;

async function newAcademy() {
  const slug = `ev-${unique()}`;
  const email = `ev-admin-${unique()}@example.com`;
  const res = await platform.post('/superadmin/tenants', { name: `Verify Academy ${slug}`, slug, admin: { name: 'Verify Admin', email, password: PASSWORD } });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return { tenantId: res.body.id as string, slug, adminEmail: email, admin: await as({ email, password: PASSWORD }) };
}

const person = (over: object = {}) => ({ name: 'Verifying Person', email: `ev-${unique()}@example.com`, password: 'person-password-1', ...over });

/** The code from the latest verification email to the address — what the registrant reads in their inbox. */
async function codeFor(email: string): Promise<string> {
  const mail = await platformDb.emailOutbox.findFirst({ where: { toEmail: email, templateKey: 'account-verification' }, orderBy: { createdAt: 'desc' } });
  const code = mail?.text.match(/\b(\d{6})\b/)?.[1];
  if (!code) throw new Error(`No verification code was emailed to ${email}`);
  return code;
}

const wrong = (code: string) => String((Number(code) + 1) % 1_000_000).padStart(6, '0');
const verify = (verificationId: string, code: string) => anon().post('/public/verifications/verify', { verificationId, code });
const userOf = (email: string) => platformDb.user.findUnique({ where: { email } });

/** Makes the registration's last code look sent long enough ago that another may be sent. */
const coolDown = (id: string) => platformDb.pendingAccount.update({ where: { id }, data: { lastSentAt: new Date(Date.now() - 10 * 60_000) } });

beforeAll(async () => {
  const email = `ev-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Verify Platform' });
  platform = await as({ email, password: PASSWORD });
});

beforeEach(() => {
  // The suite's fixtures register in one step (vitest.config.ts); this suite is about the code, so it is on.
  delete process.env.SIGNUP_EMAIL_VERIFICATION;
});

afterAll(() => {
  process.env.SIGNUP_EMAIL_VERIFICATION = 'off';
});

describe('a learner joining through the academy’s link', () => {
  it('creates nothing until the code is confirmed, then signs the learner in to that academy only', async () => {
    const a = await newAcademy();
    const who = person();
    const res = await anon().post(`/public/academies/${a.slug}/register`, { ...who, tenantId: ACADEMY, role: 'admin' });
    expect(res.status, JSON.stringify(res.body)).toBe(202);
    expect(res.body).toMatchObject({ status: 'verify', email: who.email, role: 'student' });
    expect(res.body.token).toBeUndefined();
    expect(await userOf(who.email)).toBeNull();

    // The row is the link's academy's; the code and the password are stored only as hashes.
    const row = await platformDb.pendingAccount.findUniqueOrThrow({ where: { id: res.body.verificationId } });
    const code = await codeFor(who.email);
    expect(row).toMatchObject({ tenantId: a.tenantId, role: 'student', email: who.email });
    expect(row.codeHash).not.toContain(code);
    expect(row.passwordHash).not.toContain(who.password);
    // Sign-in is refused: there is no account yet.
    expect((await anon().post('/auth/login', { email: who.email, password: who.password })).status).toBe(401);

    const done = await verify(res.body.verificationId, code);
    expect(done.status, JSON.stringify(done.body)).toBe(201);
    expect(done.body).toMatchObject({ status: 'created', user: { role: 'student', email: who.email } });
    expect(done.body.token).toEqual(expect.any(String));
    expect(await userOf(who.email)).toMatchObject({ tenantId: a.tenantId, role: 'student' });

    // Used once.
    const again = await verify(res.body.verificationId, code);
    expect(again.status).toBe(404);
    expect(again.body.code).toBe('VERIFICATION_FAILED');
  });

  it('counts wrong codes, stops at the limit, and refuses an expired code', async () => {
    const a = await newAcademy();
    const who = person();
    const id = (await anon().post(`/public/academies/${a.slug}/register`, who)).body.verificationId as string;
    const code = await codeFor(who.email);

    const first = await verify(id, wrong(code));
    expect(first.status).toBe(400);
    expect(first.body.issues).toEqual([{ field: 'code', message: expect.stringContaining(`${CODE_MAX_ATTEMPTS - 1} tries left`) }]);
    for (let i = 1; i < CODE_MAX_ATTEMPTS; i++) await verify(id, wrong(code));
    // Even the right code is refused once the tries are used up.
    expect((await verify(id, code)).status).toBe(429);
    expect(await userOf(who.email)).toBeNull();

    // A new code starts a new count; once it expires, it is refused too.
    await coolDown(id);
    expect((await anon().post('/public/verifications/resend', { verificationId: id })).status).toBe(200);
    const fresh = await codeFor(who.email);
    await platformDb.pendingAccount.update({ where: { id }, data: { expiresAt: new Date(Date.now() - 1000) } });
    expect((await verify(id, fresh)).status).toBe(410);
    expect(await userOf(who.email)).toBeNull();
  });

  it('compares no more guesses than the limit, however many arrive at once', async () => {
    const a = await newAcademy();
    const who = person();
    const id = (await anon().post(`/public/academies/${a.slug}/register`, who)).body.verificationId as string;
    const code = await codeFor(who.email);

    const burst = await Promise.all(Array.from({ length: CODE_MAX_ATTEMPTS * 4 }, () => verify(id, wrong(code))));
    // Only the guesses that spent an attempt were checked; the rest were refused unchecked.
    expect(burst.filter((r) => r.status === 400).length).toBeLessThanOrEqual(CODE_MAX_ATTEMPTS);
    expect(burst.every((r) => r.status === 400 || r.status === 429)).toBe(true);
    expect((await platformDb.pendingAccount.findUniqueOrThrow({ where: { id } })).attempts).toBe(CODE_MAX_ATTEMPTS);
    expect((await verify(id, code)).status).toBe(429);
    expect(await userOf(who.email)).toBeNull();
  });

  it('holds resends to a cooldown and a cap, and only the latest code confirms', async () => {
    const a = await newAcademy();
    const who = person();
    const started = await anon().post(`/public/academies/${a.slug}/register`, who);
    const id = started.body.verificationId as string;
    const old = await codeFor(who.email);
    expect(new Date(started.body.resendAvailableAt).getTime()).toBeGreaterThan(Date.now());

    const tooSoon = await anon().post('/public/verifications/resend', { verificationId: id });
    expect(tooSoon.status).toBe(429);
    expect(tooSoon.body.message).toMatch(/Wait \d+ seconds/);

    for (let sent = 1; sent < CODE_MAX_SENDS; sent++) {
      await coolDown(id);
      expect((await anon().post('/public/verifications/resend', { verificationId: id })).status).toBe(200);
    }
    await coolDown(id);
    expect((await anon().post('/public/verifications/resend', { verificationId: id })).status).toBe(429);

    const latest = await codeFor(who.email);
    if (latest !== old) expect((await verify(id, old)).status).toBe(400);
    expect((await verify(id, latest)).status).toBe(201);
  });

  it('refuses a taken address before sending anything, and an unknown or suspended academy', async () => {
    const a = await newAcademy();
    const taken = await anon().post(`/public/academies/${a.slug}/register`, person({ email: 'ananya@syniastrolms.test' }));
    expect(taken.status).toBe(409);
    expect(taken.body.issues).toEqual([{ field: 'email', message: expect.any(String) }]);
    expect((await anon().post('/public/academies/no-such-lms-anywhere/register', person())).status).toBe(404);
    expect((await anon().post(`/public/academies/${a.slug}/register`, { ...person(), password: 'short' })).status).toBe(400);
  });

  it('re-checks the address at confirmation: one taken meanwhile creates nothing and releases the code', async () => {
    const a = await newAcademy();
    const b = await newAcademy();
    const who = person();
    const idA = (await anon().post(`/public/academies/${a.slug}/register`, who)).body.verificationId as string;
    const codeA = await codeFor(who.email);
    const idB = (await anon().post(`/public/academies/${b.slug}/register`, who)).body.verificationId as string;
    const codeB = await codeFor(who.email);
    expect((await verify(idB, codeB)).status).toBe(201);
    const late = await verify(idA, codeA);
    expect(late.status).toBe(409);
    // One account, in B only.
    expect(await userOf(who.email)).toMatchObject({ tenantId: b.tenantId });
  });
});

describe('an academy that adds learners by invitation only', () => {
  it('takes no learner through its join link, but an invitation still works', async () => {
    const a = await newAcademy();
    const settings = (await a.admin.get('/settings')).body.settings;
    expect((await a.admin.put('/settings/general', { ...settings.general, enrollment: 'invite' })).status).toBe(200);

    expect((await anon().get(`/public/academies/${a.slug}`)).body).toMatchObject({ open: true, invitationOnly: true });
    const closed = await anon().post(`/public/academies/${a.slug}/register`, person());
    expect(closed.status).toBe(403);
    expect(closed.body.code).toBe('INVITATION_REQUIRED');

    const made = await a.admin.post('/invitations', {});
    const token = (made.body.url as string).match(/\/invite\/([a-f0-9]{64})$/)![1];
    const who = person();
    const started = await anon().post(`/public/invitations/${token}/register`, who);
    expect(started.status, JSON.stringify(started.body)).toBe(202);
    const done = await verify(started.body.verificationId, await codeFor(who.email));
    expect(done.status, JSON.stringify(done.body)).toBe(201);
    expect(await userOf(who.email)).toMatchObject({ tenantId: a.tenantId, role: 'student' });
  });
});

describe('a learner accepting an invitation', () => {
  it('uses the invitation only when the code is confirmed, and keeps its address', async () => {
    const a = await newAcademy();
    const invited = `ev-inv-${unique()}@example.com`;
    const made = await a.admin.post('/invitations', { email: invited });
    const token = (made.body.url as string).match(/\/invite\/([a-f0-9]{64})$/)![1];

    expect((await anon().post(`/public/invitations/${token}/register`, person())).status).toBe(403);
    const started = await anon().post(`/public/invitations/${token}/register`, person({ email: invited }));
    expect(started.status).toBe(202);
    // Not used yet: the link still opens.
    expect((await anon().get(`/public/invitations/${token}`)).status).toBe(200);

    const done = await verify(started.body.verificationId, await codeFor(invited));
    expect(done.status, JSON.stringify(done.body)).toBe(201);
    const row = await platformDb.invitation.findFirstOrThrow({ where: { id: made.body.invitation.id } });
    expect(row.usedAt).not.toBeNull();
    expect(row.usedByUserId).toBe((await userOf(invited))!.id);
    expect((await anon().get(`/public/invitations/${token}`)).status).toBe(404);
  });

  it('creates nothing when the invitation is withdrawn while the code waits', async () => {
    const a = await newAcademy();
    const made = await a.admin.post('/invitations', {});
    const token = (made.body.url as string).match(/\/invite\/([a-f0-9]{64})$/)![1];
    const who = person();
    const started = await anon().post(`/public/invitations/${token}/register`, who);
    await a.admin.post(`/invitations/${made.body.invitation.id}/revoke`, {});
    const done = await verify(started.body.verificationId, await codeFor(who.email));
    expect(done.status).toBe(404);
    expect(done.body.code).toBe('INVITE_INVALID');
    expect(await userOf(who.email)).toBeNull();
  });
});

describe('a learner joining from a course link', () => {
  it('is enrolled once the code is confirmed', async () => {
    const course = await platformDb.course.findFirstOrThrow({ where: { tenantId: ACADEMY, status: 'published', visibility: { not: 'private' } } });
    const who = person();
    const started = await anon().post(`/public/courses/${course.id}/enroll`, who);
    expect(started.status, JSON.stringify(started.body)).toBe(202);
    expect(await userOf(who.email)).toBeNull();
    const done = await verify(started.body.verificationId, await codeFor(who.email));
    expect(done.status, JSON.stringify(done.body)).toBe(201);
    expect(done.body).toHaveProperty('enrolled');
    expect(await userOf(who.email)).toMatchObject({ tenantId: ACADEMY });
  });
});

describe('the host’s own sign-up', () => {
  it('verifies the email too, and joins the workspace the app names', async () => {
    const a = await newAcademy();
    const who = person();
    const started = await anon().post('/auth/register', { ...who, workspace: a.slug });
    expect(started.status, JSON.stringify(started.body)).toBe(202);
    expect(started.body.lms).toEqual(expect.any(String));
    const done = await verify(started.body.verificationId, await codeFor(who.email));
    expect(done.status).toBe(201);
    expect(await userOf(who.email)).toMatchObject({ tenantId: a.tenantId });
  });
});

describe('an instructor asking to teach', () => {
  it('reaches the academy’s admins only once the email is verified, and stays pending', async () => {
    const a = await newAcademy();
    const who = person({ title: 'Physics teacher' });
    const started = await anon().post(`/public/academies/${a.slug}/instructor-requests`, { ...who, role: 'admin', tenantId: ACADEMY });
    expect(started.status, JSON.stringify(started.body)).toBe(202);
    expect(started.body).toMatchObject({ status: 'verify', role: 'instructor' });
    expect(await userOf(who.email)).toBeNull();
    expect((await a.admin.get('/instructors/requests')).body.rows ?? []).toHaveLength(0);

    const done = await verify(started.body.verificationId, await codeFor(who.email));
    expect(done.status, JSON.stringify(done.body)).toBe(202);
    expect(done.body).toMatchObject({ status: 'pending' });
    expect(done.body.token).toBeUndefined();
    expect(await userOf(who.email)).toMatchObject({ tenantId: a.tenantId, role: 'instructor' });
    const profile = await platformDb.instructor.findFirstOrThrow({ where: { email: who.email } });
    expect(profile).toMatchObject({ status: 'pending', title: 'Physics teacher', tenantId: a.tenantId });
    // Still waiting on the admin.
    const login = await anon().post('/auth/login', { email: who.email, password: who.password });
    expect(login.status).toBe(403);
    expect(login.body.code).toBe('INSTRUCTOR_PENDING');
  });
});

describe('limits and housekeeping', () => {
  it('caps the codes sent to one address, from any client', async () => {
    const limited = createApp({ rateLimits: { email: 2 } });
    const a = await newAcademy();
    const who = person();
    expect((await request(limited).post(`/public/academies/${a.slug}/register`).send(who)).status).toBe(202);
    expect((await request(limited).post(`/public/academies/${a.slug}/register`).send(who)).status).toBe(202);
    const third = await request(limited)
      .post(`/public/academies/${a.slug}/register`)
      .send({ ...who, email: who.email.toUpperCase() });
    expect(third.status).toBe(429);
    // Another address is unaffected.
    expect((await request(limited).post(`/public/academies/${a.slug}/register`).send(person())).status).toBe(202);
  });

  it('keeps the academy, role and address of a registration fixed', async () => {
    const a = await newAcademy();
    const who = person();
    const id = (await anon().post(`/public/academies/${a.slug}/register`, who)).body.verificationId as string;
    await expect(platformDb.pendingAccount.update({ where: { id }, data: { tenantId: ACADEMY } })).rejects.toThrow();
    await expect(platformDb.pendingAccount.update({ where: { id }, data: { role: 'admin' } })).rejects.toThrow();
    await expect(platformDb.pendingAccount.update({ where: { id }, data: { email: 'other@example.com' } })).rejects.toThrow();
  });

  it('prunes registrations whose code expired long ago, and keeps open ones', async () => {
    const a = await newAcademy();
    const stale = person();
    const open = person();
    const staleId = (await anon().post(`/public/academies/${a.slug}/register`, stale)).body.verificationId as string;
    const openId = (await anon().post(`/public/academies/${a.slug}/register`, open)).body.verificationId as string;
    await platformDb.pendingAccount.update({ where: { id: staleId }, data: { expiresAt: new Date(Date.now() - 2 * 86_400_000) } });
    expect(await prunePendingRegistrations()).toBeGreaterThanOrEqual(1);
    expect(await platformDb.pendingAccount.findUnique({ where: { id: staleId } })).toBeNull();
    expect(await platformDb.pendingAccount.findUnique({ where: { id: openId } })).not.toBeNull();
    // A pruned registration reads as closed, and so does an id that was never one.
    expect((await anon().get(`/public/verifications/${staleId}`)).status).toBe(404);
    expect((await anon().get(`/public/verifications/${'x'.repeat(300)}`)).status).toBe(404);
    expect((await anon().get(`/public/verifications/${openId}`)).body).toMatchObject({ status: 'verify', role: 'student' });
  });
});

describe('the static test code (lib/testOtp.ts)', () => {
  const env = (over: Record<string, string>) => Object.assign(process.env, over);
  afterEach(() => {
    process.env.TEST_OTP_EMAIL = '';
    process.env.TEST_OTP_CODE = '';
    process.env.NODE_ENV = 'test';
  });

  /** Registers, then sets the static code to one that is not the emailed code. */
  async function registered(email: string) {
    const a = await newAcademy();
    const res = await anon().post(`/public/academies/${a.slug}/register`, person({ email }));
    expect(res.status, JSON.stringify(res.body)).toBe(202);
    const emailed = await codeFor(email);
    const testCode = wrong(emailed);
    env({ TEST_OTP_EMAIL: email.toUpperCase(), TEST_OTP_CODE: testCode });
    return { id: res.body.verificationId as string, emailed, testCode, started: res.body };
  }

  it('confirms the test account when its email does not arrive, and the emailed code is still sent and still works', async () => {
    const email = `ev-qa-${unique()}@example.com`;
    const { id, testCode, started } = await registered(email);
    // The real code went out as always; nothing about the static code reaches the client.
    expect(JSON.stringify(started)).not.toContain(testCode);
    const done = await verify(id, testCode);
    expect(done.status, JSON.stringify(done.body)).toBe(201);
    expect(JSON.stringify(done.body)).not.toContain(testCode);
    expect(await userOf(email)).toMatchObject({ role: 'student' });

    const other = `ev-qa-${unique()}@example.com`;
    const second = await registered(other);
    expect((await verify(second.id, second.emailed)).status).toBe(201);
  });

  it('confirms no other account', async () => {
    const a = await newAcademy();
    const who = person();
    const id = (await anon().post(`/public/academies/${a.slug}/register`, who)).body.verificationId as string;
    const testCode = wrong(await codeFor(who.email));
    env({ TEST_OTP_EMAIL: `ev-qa-${unique()}@example.com`, TEST_OTP_CODE: testCode });
    const res = await verify(id, testCode);
    expect(res.status).toBe(400);
    expect(JSON.stringify(res.body)).not.toContain(testCode);
    expect(await userOf(who.email)).toBeNull();
  });

  it('is no way round the attempt limit or the expiry', async () => {
    const { id, emailed, testCode } = await registered(`ev-qa-${unique()}@example.com`);
    // A code that is neither the emailed one nor the static one.
    const neither = ['000000', '000001', '000002'].find((c) => c !== emailed && c !== testCode)!;
    for (let i = 0; i < CODE_MAX_ATTEMPTS; i++) await verify(id, neither);
    expect((await verify(id, testCode)).status).toBe(429);

    const late = await registered(`ev-qa-${unique()}@example.com`);
    await platformDb.pendingAccount.update({ where: { id: late.id }, data: { expiresAt: new Date(Date.now() - 1000) } });
    expect((await verify(late.id, late.testCode)).status).toBe(410);
  });

  it('is refused by a production process even with it set', async () => {
    const email = `ev-qa-${unique()}@example.com`;
    const { id, emailed, testCode } = await registered(email);
    process.env.NODE_ENV = 'production';
    try {
      const res = await verify(id, testCode);
      expect(res.status).toBe(400);
      expect(JSON.stringify(res.body)).not.toContain(testCode);
    } finally {
      process.env.NODE_ENV = 'test';
    }
    expect(await userOf(email)).toBeNull();
    // The emailed code is unaffected.
    expect((await verify(id, emailed)).status).toBe(201);
  });
});
