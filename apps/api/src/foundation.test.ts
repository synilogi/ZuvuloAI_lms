import { describe, expect, it } from 'vitest';
import request from 'supertest';

import { createApp } from './app.js';
import { ACCOUNTS, PASSWORD, anon, as, decodeToken, newStudent } from './test/helpers.js';

describe('foundation: error handling', () => {
  it('returns 400 for malformed JSON without leaking parser details', async () => {
    const res = await request(createApp()).post('/auth/login').set('Content-Type', 'application/json').send('{"email": ');
    expect(res.status).toBe(400);
    expect(res.body).toEqual({ message: 'The request body is not valid JSON.' });
  });

  it('returns 404 JSON for unknown routes', async () => {
    const res = await anon().get('/no-such-route');
    expect(res.status).toBe(404);
    expect(res.body.message).toBe('Not found.');
  });

  it('maps a missing record update to 404 instead of a 500', async () => {
    const admin = await as('admin');
    const res = await admin.post('/calendar/does-not-exist/done', { done: true });
    expect(res.status).toBe(404);
  });

  it('returns validation issues as a 400 with paths', async () => {
    const res = await anon().post('/auth/register', { name: 'A', email: 'nope', password: 'short' });
    expect(res.status).toBe(400);
    const paths = (res.body.issues as { path: string }[]).map((i) => i.path).sort();
    expect(paths).toEqual(['email', 'name', 'password']);
  });

  it('sets security headers and hides x-powered-by', async () => {
    const res = await anon().get('/health');
    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });
});

describe('foundation: auth hardening', () => {
  it('never lets public registration choose a staff role', async () => {
    const res = await anon().post('/auth/register', { name: 'Sneaky Person', email: `sneaky-${Date.now()}@example.com`, password: PASSWORD, role: 'admin' });
    expect(res.status).toBe(201);
    expect(res.body.user.role).toBe('student');
    expect(decodeToken(res.body.token).role).toBe('student');
  });

  it('rate limits repeated sign-in attempts', async () => {
    const limited = createApp({ rateLimits: { auth: 3 } });
    const attempt = () => request(limited).post('/auth/login').send({ email: ACCOUNTS.student, password: 'wrong-password' });
    for (let i = 0; i < 3; i++) expect((await attempt()).status).toBe(401);
    const blocked = await attempt();
    expect(blocked.status).toBe(429);
    expect(blocked.body.message).toMatch(/too many/i);
    // Reading the session is not a credential attempt and never counts against the budget.
    for (let i = 0; i < 5; i++) expect((await request(limited).get('/auth/me')).status).toBe(401);
  });

  it('limits failed sign-ins per account, whatever client they come from, and never counts a right password', async () => {
    const limited = createApp({ rateLimits: { auth: 1000, account: 3 } });
    const login = (email: string, password: string) => request(limited).post('/auth/login').send({ email, password });
    for (let i = 0; i < 5; i++) expect((await login(ACCOUNTS.instructor, PASSWORD)).status).toBe(200);
    for (let i = 0; i < 3; i++) expect((await login(ACCOUNTS.student, 'wrong-password')).status).toBe(401);
    // Spent: even the right password waits, so a guess that lands tells the guesser nothing.
    const blocked = await login(` ${ACCOUNTS.student.toUpperCase()} `, PASSWORD);
    expect(blocked.status).toBe(429);
    expect(blocked.body.message).toMatch(/too many failed sign-ins/i);
    expect((await login(ACCOUNTS.instructor, PASSWORD)).status).toBe(200);
  });

  it('signs staff in with their instructor id in the token', async () => {
    const instructor = await as('instructor');
    const payload = decodeToken(instructor.token);
    expect(payload.role).toBe('instructor');
    expect(typeof payload.instructorId).toBe('string');
  });
});

describe('foundation: notifications are keyed on the account, not on a learner row', () => {
  it('lets an admin (who has no Student row) read and save preferences', async () => {
    const admin = await as('admin');
    const list = await admin.get('/notifications', { recipientId: 'ignored-by-server', limit: 5 });
    expect(list.status).toBe(200);
    expect(list.body).toMatchObject({ rows: expect.any(Array), unread: expect.any(Number) });

    const settings = await admin.get('/notifications/settings/me');
    expect(settings.status).toBe(200);
    const saved = await admin.put('/notifications/settings/me', { ...settings.body, emailDigest: 'daily' });
    expect(saved.status).toBe(200);
    expect(saved.body.emailDigest).toBe('daily');
  });

  it("only returns and mutates the caller's own notifications", async () => {
    const ananya = await as('student');
    const mine = await ananya.get('/notifications', { limit: 50 });
    expect(mine.status).toBe(200);
    expect(mine.body.rows.length).toBeGreaterThan(0);
    const someId = mine.body.rows[0].id as string;

    const other = await newStudent();
    const theirs = await other.get('/notifications', { limit: 50 });
    expect(theirs.body.rows).toEqual([]);

    const detail = await other.get(`/notifications/${someId}`);
    expect(detail.status).toBe(404);

    await other.post('/notifications/remove', { ids: [someId] });
    const stillThere = await ananya.get(`/notifications/${someId}`);
    expect(stillThere.status).toBe(200);
  });
});

describe('foundation: calendar ownership comes from the token', () => {
  const in30Days = () => new Date(Date.now() + 30 * 86_400_000).toISOString();

  it('stores the creator as owner and blocks other users from editing', async () => {
    const meenakshi = await as('instructor');
    const created = await meenakshi.post('/calendar', {
      input: { type: 'reminder', title: 'Prepare slides', timing: 'moment', startsAt: in30Days(), audience: 'me', notifyMin: 30 },
      ownerId: 'ignored-by-server',
    });
    expect(created.status).toBe(201);
    expect(created.body.ownerId).toBe(decodeToken(meenakshi.token).sub);

    const vinod = await as('instructor2');
    const stolen = await vinod.post(`/calendar/${created.body.id}/done`, { done: true });
    expect(stolen.status).toBe(404);

    const admin = await as('admin');
    const byAdmin = await admin.post(`/calendar/${created.body.id}/done`, { done: true });
    expect(byAdmin.status).toBe(200);

    const removed = await meenakshi.delete(`/calendar/${created.body.id}`);
    expect(removed.status).toBe(204);
  });

  it('keeps learners out of the staff calendar', async () => {
    const student = await as('student');
    const res = await student.get('/calendar', { from: '2026-09-01', to: '2026-09-30' });
    expect(res.status).toBe(403);
  });
});
