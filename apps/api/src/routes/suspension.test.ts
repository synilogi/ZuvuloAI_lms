import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { db } from '../test/db.js';
import { ACCOUNTS, PASSWORD, anon, as, newStudent, type Client } from '../test/helpers.js';

/* What suspending a learner actually stops.
 *
 * The policy: a suspension pauses the academy for that learner — sign-in, the session read and every
 * learner action are refused while it stands. Staff accounts are untouched; the flag lives on the
 * learner profile and only learner seams consult it. */

let learner: Awaited<ReturnType<typeof newStudent>>;
let admin: Client;

const suspend = (studentId: string, suspended: boolean) => db.student.update({ where: { id: studentId }, data: { suspended } });

beforeAll(async () => {
  admin = await as('admin');
  learner = await newStudent('Suspendable Learner');
});

afterAll(async () => {
  if (learner?.studentId) await suspend(learner.studentId, false);
});

describe('an active learner is untouched', () => {
  it('signs in, reads its session and uses the learner workspace', async () => {
    expect((await anon().post('/auth/login', { email: learner.email, password: PASSWORD })).status).toBe(200);
    expect((await learner.get('/auth/me')).status).toBe(200);
    for (const path of ['/learning/home', '/learning/courses', '/learning/assignments', '/learning/certificates', '/learning/rank-ladder']) {
      expect((await learner.get(path)).status, path).toBe(200);
    }
  });
});

describe('a suspended learner is paused', () => {
  beforeAll(async () => {
    await suspend(learner.studentId, true);
  });

  it('cannot sign in', async () => {
    const refused = await anon().post('/auth/login', { email: learner.email, password: PASSWORD });
    expect(refused.status).toBe(403);
    expect(refused.body.message).toMatch(/suspended/i);
  });

  it('cannot read its session, so an open tab drops to signed out', async () => {
    expect((await learner.get('/auth/me')).status).toBe(403);
  });

  // The token it already holds stays valid, so the check has to be on the action, not only on login.
  it('cannot perform a learner action with the token it already had', async () => {
    for (const path of [
      '/learning/home',
      '/learning/courses',
      '/learning/assignments',
      '/learning/assessments',
      '/learning/certificates',
      '/learning/activity',
    ]) {
      const res = await learner.get(path);
      expect(res.status, path).toBe(403);
      expect(res.body.message, path).toMatch(/suspended/i);
    }
  });

  it('cannot write anything either', async () => {
    const course = await db.course.findFirstOrThrow({ where: { status: 'published' }, select: { id: true } });
    expect((await learner.post(`/learning/courses/${course.id}/enroll`)).status).toBe(403);
    expect((await learner.post(`/learning/courses/${course.id}/save`, { saved: true })).status).toBe(403);
    expect((await learner.get('/live/learner')).status).toBe(403);
  });

  it('is refused outside the learning workspace too: notifications, settings and uploads', async () => {
    for (const path of ['/notifications', '/notifications/settings/me']) {
      const res = await learner.get(path);
      expect(res.status, path).toBe(403);
      expect(res.body.message, path).toMatch(/suspended/i);
    }
    expect((await learner.post('/notifications/read-all')).status).toBe(403);
    expect((await learner.upload('/media/upload').attach('file', Buffer.from('%PDF-1.4'), 'notes.pdf')).status).toBe(403);
  });

  it('keeps its records — a suspension pauses access, it does not delete anything', async () => {
    const row = await db.student.findUniqueOrThrow({ where: { id: learner.studentId } });
    expect(row.suspended).toBe(true);
    expect(await db.user.count({ where: { id: learner.userId } })).toBe(1);
  });

  it('leaves every other learner working', async () => {
    const other = await as('student');
    expect((await other.get('/learning/home')).status).toBe(200);
    expect((await other.get('/auth/me')).status).toBe(200);
  });

  it('leaves staff alone: the flag lives on the learner profile, and staff have none', async () => {
    const instructor = await as('instructor');
    expect((await admin.get('/auth/me')).status).toBe(200);
    expect((await admin.get('/students')).status).toBe(200);
    expect((await instructor.get('/auth/me')).status).toBe(200);
    expect((await instructor.get('/courses')).status).toBe(200);
    expect((await anon().post('/auth/login', { email: ACCOUNTS.admin, password: PASSWORD })).status).toBe(200);
    expect((await anon().post('/auth/login', { email: ACCOUNTS.instructor, password: PASSWORD })).status).toBe(200);
  });
});

describe('lifting a suspension restores everything', () => {
  it('signs in and works again', async () => {
    await suspend(learner.studentId, false);
    const signedIn = await anon().post('/auth/login', { email: learner.email, password: PASSWORD });
    expect(signedIn.status).toBe(200);
    expect((await learner.get('/auth/me')).status).toBe(200);
    expect((await learner.get('/learning/home')).status).toBe(200);
    expect((await learner.get('/notifications')).status).toBe(200);
  });
});
