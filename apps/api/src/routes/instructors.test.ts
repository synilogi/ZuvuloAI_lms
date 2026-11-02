import { beforeAll, describe, expect, it } from 'vitest';

import { db } from '../test/db.js';
import { anon, as, unique, type Client } from '../test/helpers.js';

let admin: Client;
let meenakshiId: string;

beforeAll(async () => {
  admin = await as('admin');
  const list = await admin.get('/instructors');
  meenakshiId = list.body.rows.find((r: { instructor: { email: string } }) => r.instructor.email === 'meenakshi@syniastrolms.test').instructor.id;
});

describe('instructors: performance figures', () => {
  it('computes completion on the list and real profile figures', async () => {
    const list = await admin.get('/instructors');
    const row = list.body.rows.find((r: { instructor: { id: string } }) => r.instructor.id === meenakshiId);
    expect(typeof row.completion).toBe('number');

    const res = await admin.get(`/instructors/${meenakshiId}`);
    expect(res.status).toBe(200);
    const { courses, reach, performance, activity } = res.body;
    expect(courses.length).toBeGreaterThan(0);
    for (const c of courses) expect(c.levelTitle.length).toBeGreaterThan(0);
    expect(courses.some((c: { lessons: number }) => c.lessons > 0)).toBe(true);
    expect(reach.students).toBeGreaterThan(0);
    expect(performance.academyRating).toBeGreaterThan(0);
    expect(typeof performance.completion).toBe('number');
    expect(performance.academyCompletion).toBeGreaterThan(0);
    expect(performance.enrollmentsByMonth).toHaveLength(8);
    expect(performance.enrollmentsByMonth[7].detail).toMatch(/so far$/);
    expect(performance.enrollmentsByMonth.reduce((n: number, m: { value: number }) => n + m.value, 0)).toBeGreaterThan(0);
    expect(activity.length).toBeGreaterThan(0);
    expect(activity.every((e: { at: string }) => new Date(e.at) <= new Date())).toBe(true);
    expect(typeof performance.reviewHoursMedian === 'number' || performance.reviewHoursMedian === null).toBe(true);
  });
});

describe('instructors: accounts and invitations', () => {
  const input = (email: string, status: 'invited' | 'active' = 'invited') => ({
    name: 'Invited Teacher',
    title: 'Visiting Teacher',
    email,
    bio: 'Teaches reasoning and quantitative aptitude to exam aspirants, with twelve years of coaching practice.',
    expertise: ['Reasoning'],
    status,
    city: 'Pune',
    languages: ['English'],
    courseIds: [],
  });

  it('creates an account and emails a set-password link that signs the instructor in', async () => {
    const email = `teacher-${unique()}@example.com`;
    const created = await admin.post('/instructors', input(email));
    expect(created.status).toBe(201);

    const user = await db.user.findUnique({ where: { email } });
    expect(user?.role).toBe('instructor');
    expect(user?.instructorId).toBe(created.body.id);

    const mail = await db.emailOutbox.findFirst({ where: { toEmail: email, templateKey: 'instructor-invite' }, orderBy: { createdAt: 'desc' } });
    const token = mail?.text.match(/reset-password\/([a-f0-9]{64})/)?.[1];
    expect(token).toBeDefined();
    expect((await anon().post('/auth/reset-password', { token, password: 'teacher-pass-123' })).status).toBe(200);
    const login = await anon().post('/auth/login', { email, password: 'teacher-pass-123' });
    expect(login.status).toBe(200);
    expect(login.body.user.role).toBe('instructor');
    expect(login.body.user.instructorId).toBe(created.body.id);

    // resending issues a new link
    const resend = await admin.post(`/instructors/${created.body.id}/resend-invite`);
    expect(resend.body.sentTo).toBe(email);
    expect(await db.emailOutbox.count({ where: { toEmail: email, templateKey: 'instructor-invite' } })).toBe(2);
  });

  it('refuses an email that any account already uses', async () => {
    const dup = await admin.post('/instructors', input('ananya@syniastrolms.test'));
    expect(dup.status).toBe(409);
  });

  it('keeps the account in sync on edit and blocks deactivated instructors from signing in', async () => {
    const email = `teacher-${unique()}@example.com`;
    const created = await admin.post('/instructors', input(email, 'active'));
    if (created.status !== 201) console.log('create failed', created.status, JSON.stringify(created.body));
    expect(created.status).toBe(201);
    const token = (await db.emailOutbox.findFirst({ where: { toEmail: email }, orderBy: { createdAt: 'desc' } }))?.text.match(
      /reset-password\/([a-f0-9]{64})/,
    )?.[1];
    expect(token).toBeUndefined(); // active profiles are not invited automatically
    await admin.post(`/instructors/${created.body.id}/resend-invite`);
    const link = (await db.emailOutbox.findFirst({ where: { toEmail: email }, orderBy: { createdAt: 'desc' } }))!.text.match(
      /reset-password\/([a-f0-9]{64})/,
    )![1];
    await anon().post('/auth/reset-password', { token: link, password: 'teacher-pass-456' });

    const newEmail = `renamed-${unique()}@example.com`;
    const edited = await admin.patch(`/instructors/${created.body.id}`, { ...input(newEmail, 'active'), name: 'Renamed Teacher' });
    expect(edited.status).toBe(200);
    expect((await db.user.findFirst({ where: { instructorId: created.body.id } }))?.email).toBe(newEmail);
    expect((await anon().post('/auth/login', { email: newEmail, password: 'teacher-pass-456' })).status).toBe(200);

    await admin.post(`/instructors/${created.body.id}/status`, { status: 'inactive' });
    expect((await anon().post('/auth/login', { email: newEmail, password: 'teacher-pass-456' })).status).toBe(403);
  });

  it('kills the set-password link mailed to the old address when the admin corrects the email', async () => {
    const typo = `typo-${unique()}@example.com`;
    const created = await admin.post('/instructors', input(typo));
    expect(created.status).toBe(201);
    const link = (await db.emailOutbox.findFirst({ where: { toEmail: typo, templateKey: 'instructor-invite' }, orderBy: { createdAt: 'desc' } }))!.text.match(
      /reset-password\/([a-f0-9]{64})/,
    )![1];
    const corrected = `real-${unique()}@example.com`;
    expect((await admin.patch(`/instructors/${created.body.id}`, input(corrected))).status).toBe(200);
    expect((await anon().post('/auth/reset-password', { token: link, password: 'hijacked-pass-1' })).status).toBe(409);
    expect((await anon().post('/auth/login', { email: corrected, password: 'hijacked-pass-1' })).status).toBe(401);
  });

  it('closes the session a deactivated instructor already holds, and reopens it on reactivation', async () => {
    const email = `held-${unique()}@example.com`;
    const created = await admin.post('/instructors', input(email, 'active'));
    expect(created.status).toBe(201);
    await admin.post(`/instructors/${created.body.id}/resend-invite`);
    const link = (await db.emailOutbox.findFirst({ where: { toEmail: email }, orderBy: { createdAt: 'desc' } }))!.text.match(
      /reset-password\/([a-f0-9]{64})/,
    )![1];
    await anon().post('/auth/reset-password', { token: link, password: 'teacher-pass-789' });
    const teacher = await as({ email, password: 'teacher-pass-789' });
    expect((await teacher.get('/courses')).status).toBe(200);

    await admin.post(`/instructors/${created.body.id}/status`, { status: 'inactive' });
    // Same token, no new sign-in: the session read, learner data and authoring are all refused.
    for (const path of ['/auth/me', '/courses', '/students', '/calendar', '/live']) {
      const res = await teacher.get(path);
      expect(res.status, path).toBe(403);
      expect(res.body.message, path).toMatch(/deactivated/i);
    }

    await admin.post(`/instructors/${created.body.id}/status`, { status: 'active' });
    expect((await teacher.get('/courses')).status).toBe(200);
  });
});
