import { beforeAll, describe, expect, it } from 'vitest';

import { db } from '../test/db.js';
import { as, newStudent, type Client } from '../test/helpers.js';

let admin: Client;
let instructor: Client;
let ananyaId: string;

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  const list = await admin.get('/students', { search: 'ananya', pageSize: 5 });
  ananyaId = list.body.rows[0].student.id;
});

describe('students: profile and progress figures', () => {
  it('reports real study time, next lesson and quiet days on the profile', async () => {
    const res = await admin.get(`/students/${ananyaId}`);
    expect(res.status).toBe(200);
    expect(res.body.summary.studyMinutes).toBeGreaterThan(0);
    expect(res.body.quietDays).toBeGreaterThanOrEqual(0);
    const active = res.body.enrollments.find((e: { enrollment: { status: string } }) => e.enrollment.status === 'active');
    expect(active).toBeDefined();
    expect(typeof active.lastLessonTitle).toBe('string');
    expect(active.lessons.done).toBeGreaterThan(0);
    expect(active.lessons.total).toBeGreaterThan(active.lessons.done);
  });

  it('returns quiz course titles and twelve study weeks on the progress tab', async () => {
    const res = await admin.get(`/students/${ananyaId}/progress`);
    expect(res.status).toBe(200);
    expect(res.body.quizzes.length).toBeGreaterThan(0);
    for (const q of res.body.quizzes as { courseTitle: string }[]) expect(q.courseTitle.length).toBeGreaterThan(0);
    expect(res.body.studyWeeks).toHaveLength(12);
    expect(res.body.studyWeeks[11].label).toBe('This week');
    const total = (res.body.studyWeeks as { minutes: number }[]).reduce((n, w) => n + w.minutes, 0);
    expect(total).toBeGreaterThan(0);
  });

  it("shows an instructor only the learner's enrollments in courses they teach", async () => {
    const asAdmin = await admin.get(`/students/${ananyaId}`);
    const asInstructor = await instructor.get(`/students/${ananyaId}`);
    expect(asInstructor.status).toBe(200);
    const mine = (await instructor.get('/courses', { pageSize: 100 })).body.rows.map((c: { id: string }) => c.id);
    for (const e of asInstructor.body.enrollments as { enrollment: { courseId: string } }[]) expect(mine).toContain(e.enrollment.courseId);
    expect(asInstructor.body.enrollments.length).toBeLessThanOrEqual(asAdmin.body.enrollments.length);
  });
});

describe('students: messages', () => {
  it('delivers a message as an in-app notification and an email, only to learners in scope', async () => {
    const learner = await newStudent('Message Target');
    const before = (await learner.get('/notifications', { limit: 50 })).body.total as number;

    const res = await admin.post('/students/message', {
      ids: [learner.studentId, 'not-a-student'],
      subject: 'A note from the academy',
      body: 'Hello there.\n\nThis is the second paragraph of the message.',
      channels: ['app', 'email'],
    });
    expect(res.status).toBe(200);
    expect(res.body.sent).toBe(1);

    const after = await learner.get('/notifications', { limit: 50 });
    expect(after.body.total).toBe(before + 1);
    const note = after.body.rows[0];
    expect(note.title).toBe('A note from the academy');
    expect(note.actor).toBe('Kavita Menon');
    expect(note.body).toEqual(['Hello there.', 'This is the second paragraph of the message.']);

    const mail = await db.emailOutbox.findFirst({ where: { toEmail: learner.email, templateKey: 'notification-course' } });
    expect(mail?.subject).toBe('A note from the academy');

    // an instructor who does not teach this learner reaches nobody
    const foreign = await instructor.post('/students/message', { ids: [learner.studentId], subject: 'x', body: 'long enough body', channels: ['app'] });
    expect(foreign.status).toBe(200);
    expect(foreign.body.sent).toBe(0);
  });

  it("respects the learner's channel preferences and validates the body", async () => {
    const learner = await newStudent('Quiet Learner');
    const settings = (await learner.get('/notifications/settings/me')).body;
    settings.categories = settings.categories.map((c: { category: string; channels: Record<string, boolean> }) =>
      c.category === 'course' ? { ...c, channels: { ...c.channels, email: false } } : c,
    );
    expect((await learner.put('/notifications/settings/me', settings)).status).toBe(200);

    const res = await admin.post('/students/message', {
      ids: [learner.studentId],
      subject: 'Email off',
      body: 'This one should stay in the app only.',
      channels: ['app', 'email'],
    });
    expect(res.body.sent).toBe(1);
    expect(await db.emailOutbox.count({ where: { toEmail: learner.email } })).toBe(0);
    expect((await learner.get('/notifications', { limit: 5 })).body.rows[0].title).toBe('Email off');

    const bad = await admin.post('/students/message', { ids: [], subject: '', body: 'short', channels: [] });
    expect(bad.status).toBe(400);
  });
});
