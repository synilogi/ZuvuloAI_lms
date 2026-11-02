import { beforeAll, describe, expect, it } from 'vitest';

import { db, inAcademy } from '../test/db.js';
import { notifyOverdueReviews, sendAssignmentDueReminders, sendDailyEnrolments, sendDigests, sendInactivityNudges } from '../lib/notificationJobs.js';
import { as, newStudent, unique, type Client } from '../test/helpers.js';

let admin: Client;
let instructor: Client;
let courseId: string;
let settings: Record<string, unknown>;
let notificationSettings: Record<string, unknown>;

/** A moment past 08:00 IST that is not earlier than now, so rows created by the test are inside the window. */
const morningIST = () =>
  new Date(Math.max(Date.now(), new Date(`${new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' })}T10:00:00+05:30`).getTime()));

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  courseId = (await instructor.get('/courses', { status: 'published', pageSize: 5 })).body.rows[0].id;
  settings = (await admin.get('/settings')).body.settings;
  notificationSettings = settings.notifications as Record<string, unknown>;
});

describe('notification engine', () => {
  it('confirms enrolments unless the academy switch is off, and reports real channels on the detail', async () => {
    const learnerCfg = (notificationSettings as { learner: Record<string, unknown> }).learner;
    await admin.put('/settings/notifications', { ...notificationSettings, learner: { ...learnerCfg, enrolmentConfirmation: false } });
    const quiet = await newStudent('No Confirmation');
    await quiet.post(`/learning/courses/${courseId}/enroll`);
    expect((await quiet.get('/notifications', { limit: 10 })).body.rows.filter((n: { category: string }) => n.category === 'enrollment')).toHaveLength(0);

    await admin.put('/settings/notifications', { ...notificationSettings, learner: { ...learnerCfg, enrolmentConfirmation: true } });
    const learner = await newStudent('Confirmed');
    await learner.post(`/learning/courses/${courseId}/enroll`);
    const notes = await learner.get('/notifications', { limit: 10 });
    const confirmation = notes.body.rows.find((n: { category: string }) => n.category === 'enrollment');
    expect(confirmation.title).toMatch(/enrolled/);

    // channels on the detail follow the learner's preferences
    const prefs = (await learner.get('/notifications/settings/me')).body;
    prefs.categories = prefs.categories.map((c: { category: string; channels: Record<string, boolean> }) =>
      c.category === 'enrollment' ? { ...c, channels: { ...c.channels, email: false } } : c,
    );
    await learner.put('/notifications/settings/me', prefs);
    const detail = await learner.get(`/notifications/${confirmation.id}`);
    expect(detail.body.channels).toMatchObject({ app: true, email: false, sms: false });
    await admin.put('/settings/notifications', notificationSettings);
  });

  it('holds emails for a daily digest and sends one digest email listing them', async () => {
    const learner = await newStudent('Digest Reader');
    const prefs = (await learner.get('/notifications/settings/me')).body;
    await learner.put('/notifications/settings/me', { ...prefs, emailDigest: 'daily' });
    await admin.post('/students/message', {
      ids: [learner.studentId],
      subject: 'Digest me',
      body: 'This message should wait for the digest email.',
      channels: ['app', 'email'],
    });
    expect(await db.emailOutbox.count({ where: { toEmail: learner.email } })).toBe(0);
    expect((await learner.get('/notifications', { limit: 5 })).body.rows[0].title).toBe('Digest me');

    const sent = await inAcademy(() => sendDigests(morningIST()));
    expect(sent).toBeGreaterThanOrEqual(1);
    const digest = await db.emailOutbox.findFirst({ where: { toEmail: learner.email, templateKey: 'digest-daily' } });
    expect(digest?.text).toContain('Digest me');
    await inAcademy(() => sendDigests(morningIST()));
    expect(await db.emailOutbox.count({ where: { toEmail: learner.email, templateKey: 'digest-daily' } })).toBe(1);
  });

  it('tells instructors once about overdue reviews', async () => {
    const created = await admin.post('/assignments', {
      courseId,
      title: `Overdue ${unique()}`,
      instructions: 'Write a full solution to the sample problem covering the equation, its solution and the check in three paragraphs.',
      attachments: [],
      format: 'text',
      due: { kind: 'none' },
      rubric: [],
      maxScore: 20,
      passMark: 12,
      status: 'published',
    });
    const learner = await newStudent('Waiting Learner');
    await learner.post(`/learning/courses/${courseId}/enroll`);
    const sub = await learner.post(`/learning/assignments/${created.body.id}/submit`, { text: 'Submitted three days ago, still waiting.', files: [] });
    await db.submission.update({ where: { id: sub.body.submission.id }, data: { submittedAt: new Date(Date.now() - 3 * 86_400_000) } });

    const before = (await instructor.get('/notifications', { limit: 50 })).body.total as number;
    expect(await inAcademy(() => notifyOverdueReviews())).toBeGreaterThanOrEqual(1);
    const after = await instructor.get('/notifications', { limit: 50 });
    expect(after.body.total).toBeGreaterThan(before);
    expect(after.body.rows[0].title).toMatch(/Review overdue/);
    expect(await inAcademy(() => notifyOverdueReviews())).toBe(0);
  });

  it('asks admins to review a course when an instructor wants to publish under review-before-publish', async () => {
    const courses = settings.courses as Record<string, unknown>;
    await admin.put('/settings/courses', { ...courses, requireReview: true });
    const mine = (await instructor.get('/courses', { status: 'published', pageSize: 5 })).body.rows[0];
    // A request asked earlier today (another suite) holds the next one back: start from none.
    await db.appNotification.deleteMany({ where: { title: `${mine.title} is ready for review` } });
    const before = (await admin.get('/notifications', { limit: 50 })).body.total as number;
    expect((await instructor.post(`/courses/${mine.id}/publish`)).status).toBe(403);
    const after = await admin.get('/notifications', { limit: 50 });
    expect(after.body.total).toBe(before + 1);
    expect(after.body.rows[0].title).toMatch(/ready for review/);
    // Pressing Publish again the same day tells the instructor, and asks no admin twice.
    const again = await instructor.post(`/courses/${mine.id}/publish`);
    expect(again.status).toBe(403);
    expect(again.body.message).toMatch(/asked to review it today/);
    expect((await admin.get('/notifications', { limit: 50 })).body.total).toBe(before + 1);
    await admin.put('/settings/courses', courses);
  });

  it("nudges quiet learners, reminds about due assignments and summarises yesterday's enrolments", async () => {
    const learner = await newStudent('Gone Quiet');
    await learner.post(`/learning/courses/${courseId}/enroll`);
    await db.student.update({ where: { id: learner.studentId }, data: { lastActiveAt: new Date(Date.now() - 20 * 86_400_000) } });
    expect(await inAcademy(() => sendInactivityNudges())).toBeGreaterThanOrEqual(1);
    expect((await learner.get('/notifications', { limit: 5 })).body.rows[0].title).toMatch(/Pick up/);
    const nudgedTotal = (await learner.get('/notifications', { limit: 50 })).body.total as number;
    await inAcademy(() => sendInactivityNudges());
    expect((await learner.get('/notifications', { limit: 50 })).body.total).toBe(nudgedTotal);

    const soon = new Date(Date.now() + 86_400_000).toISOString();
    const due = await admin.post('/assignments', {
      courseId,
      title: `Due soon ${unique()}`,
      instructions: 'Hand in a short solution to the sample problem with the equation, its solution and the check covered in full.',
      attachments: [],
      format: 'text',
      due: { kind: 'date', dueAt: soon },
      rubric: [],
      maxScore: 20,
      passMark: 12,
      status: 'published',
    });
    expect(due.status).toBe(201);
    expect(await inAcademy(() => sendAssignmentDueReminders())).toBeGreaterThanOrEqual(1);
    expect((await learner.get('/notifications', { limit: 5 })).body.rows[0].title).toMatch(/due in/);
    const afterDue = (await learner.get('/notifications', { limit: 50 })).body.total as number;
    await inAcademy(() => sendAssignmentDueReminders());
    expect((await learner.get('/notifications', { limit: 50 })).body.total).toBe(afterDue);

    const staffCfg = (notificationSettings as { staff: Record<string, unknown> }).staff;
    await admin.put('/settings/notifications', { ...notificationSettings, staff: { ...staffCfg, dailyEnrolments: true } });
    await db.enrollment.update({
      where: { studentId_courseId: { studentId: learner.studentId, courseId } },
      data: { enrolledAt: new Date(Date.now() - 86_400_000) },
    });
    expect(await inAcademy(() => sendDailyEnrolments(morningIST()))).toBeGreaterThanOrEqual(1);
    expect((await admin.get('/notifications', { limit: 5 })).body.rows[0].title).toMatch(/new enrolment/);
    expect(await inAcademy(() => sendDailyEnrolments(morningIST()))).toBe(0);
    await admin.put('/settings/notifications', notificationSettings);
  });
});
