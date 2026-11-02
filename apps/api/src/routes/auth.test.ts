import request from 'supertest';
import { describe, expect, it } from 'vitest';

import { createApp } from '../app.js';
import { db } from '../test/db.js';
import { assertProductionSecrets } from '../lib/auth.js';
import { anon, newStudent, PASSWORD, unique } from '../test/helpers.js';

const resetLink = (text: string) => text.match(/\/reset-password\/([a-f0-9]{64})/)?.[1];

async function latestResetEmail(to: string) {
  return db.emailOutbox.findFirst({ where: { toEmail: to, templateKey: 'password-reset' }, orderBy: { createdAt: 'desc' } });
}

describe('auth: forgot / reset password', () => {
  it('queues a reset email for a known account and answers identically for an unknown one', async () => {
    const learner = await newStudent();
    const known = await anon().post('/auth/forgot-password', { email: learner.email });
    const unknown = await anon().post('/auth/forgot-password', { email: `nobody-${unique()}@example.com` });
    expect(known.status).toBe(200);
    expect(unknown.status).toBe(200);
    expect(known.body).toEqual(unknown.body);

    const mail = await latestResetEmail(learner.email);
    expect(mail).not.toBeNull();
    expect(resetLink(mail!.text)).toBeDefined();
    const count = await db.emailOutbox.count({ where: { toEmail: `nobody-${unique()}@example.com` } });
    expect(count).toBe(0);
  });

  it('resets the password once, then refuses the same link', async () => {
    const learner = await newStudent();
    await anon().post('/auth/forgot-password', { email: learner.email });
    const token = resetLink((await latestResetEmail(learner.email))!.text)!;

    const check = await anon().get(`/auth/reset-password/${token}`);
    expect(check.body).toMatchObject({ valid: true, lms: expect.any(String) });

    const reset = await anon().post('/auth/reset-password', { token, password: 'brand-new-pass-1' });
    expect(reset.status).toBe(200);

    const oldLogin = await anon().post('/auth/login', { email: learner.email, password: PASSWORD });
    expect(oldLogin.status).toBe(401);
    const newLogin = await anon().post('/auth/login', { email: learner.email, password: 'brand-new-pass-1' });
    expect(newLogin.status).toBe(200);

    const again = await anon().post('/auth/reset-password', { token, password: 'another-pass-22' });
    expect(again.status).toBe(409);
    const recheck = await anon().get(`/auth/reset-password/${token}`);
    expect(recheck.body).toEqual({ valid: false });
  });

  it('lets one of two submissions of the same link at the same moment through, and only one', async () => {
    const learner = await newStudent();
    await anon().post('/auth/forgot-password', { email: learner.email });
    const token = resetLink((await latestResetEmail(learner.email))!.text)!;
    const [a, b] = await Promise.all([
      anon().post('/auth/reset-password', { token, password: 'racing-pass-one-1' }),
      anon().post('/auth/reset-password', { token, password: 'racing-pass-two-2' }),
    ]);
    expect([a.status, b.status].sort()).toEqual([200, 409]);
    const winner = a.status === 200 ? 'racing-pass-one-1' : 'racing-pass-two-2';
    expect((await anon().post('/auth/login', { email: learner.email, password: winner })).status).toBe(200);
  });

  it('refuses an unknown email and a wrong password with the same answer', async () => {
    const learner = await newStudent();
    const unknown = await anon().post('/auth/login', { email: `nobody-${unique()}@example.com`, password: 'whatever-pass-1' });
    const wrong = await anon().post('/auth/login', { email: learner.email, password: 'not-the-password-1' });
    expect(unknown.status).toBe(401);
    expect(wrong.status).toBe(401);
    expect(unknown.body).toEqual(wrong.body);
  });

  it('invalidates an earlier link when a newer one is requested, and rejects expired ones', async () => {
    const learner = await newStudent();
    await anon().post('/auth/forgot-password', { email: learner.email });
    const first = resetLink((await latestResetEmail(learner.email))!.text)!;
    await anon().post('/auth/forgot-password', { email: learner.email });
    const second = resetLink((await latestResetEmail(learner.email))!.text)!;
    expect(second).not.toBe(first);

    expect((await anon().post('/auth/reset-password', { token: first, password: 'irrelevant-pass' })).status).toBe(409);

    await db.passwordResetToken.updateMany({ where: { userId: learner.userId, usedAt: null }, data: { expiresAt: new Date(Date.now() - 1000) } });
    expect((await anon().post('/auth/reset-password', { token: second, password: 'irrelevant-pass' })).status).toBe(409);
  });

  it('validates the new password and the token shape', async () => {
    const short = await anon().post('/auth/reset-password', { token: 'a'.repeat(64), password: 'short' });
    expect(short.status).toBe(400);
    const garbage = await anon().post('/auth/reset-password', { token: 'not-a-token', password: 'long-enough-pass' });
    expect(garbage.status).toBe(409);
    const badEmail = await anon().post('/auth/forgot-password', { email: 'nope' });
    expect(badEmail.status).toBe(400);
  });
});

describe('auth: reset links are budgeted per address', () => {
  it('stops mailing one address after its budget, from any client, whether or not it has an account', async () => {
    const limited = createApp({ rateLimits: { email: 2 } });
    const learner = await newStudent();
    for (const email of [learner.email, `nobody-${unique()}@example.com`]) {
      expect((await request(limited).post('/auth/forgot-password').send({ email })).status).toBe(200);
      expect((await request(limited).post('/auth/forgot-password').send({ email })).status).toBe(200);
      const third = await request(limited).post('/auth/forgot-password').send({ email: email.toUpperCase() });
      expect(third.status).toBe(429);
      expect(third.body.message).toMatch(/reset links/);
    }
    // Another address keeps its own budget.
    expect(
      (
        await request(limited)
          .post('/auth/forgot-password')
          .send({ email: `other-${unique()}@example.com` })
      ).status,
    ).toBe(200);
  });
});

describe('auth: production secret check', () => {
  it('refuses the development secret in production and accepts a strong one', () => {
    expect(() => assertProductionSecrets({ NODE_ENV: 'production', JWT_SECRET: 'dev-secret-change-me' })).toThrow();
    expect(() => assertProductionSecrets({ NODE_ENV: 'production', JWT_SECRET: 'short' })).toThrow();
    expect(() => assertProductionSecrets({ NODE_ENV: 'production' })).toThrow();
    expect(() => assertProductionSecrets({ NODE_ENV: 'production', JWT_SECRET: 'x'.repeat(48) })).not.toThrow();
    expect(() => assertProductionSecrets({ NODE_ENV: 'development' })).not.toThrow();
  });
});
