import request from 'supertest';
import { describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { PASSWORD, app, as, newStudent } from '../test/helpers.js';

/* A learner deletes their own account (Google Play account-deletion policy): password-confirmed, anonymised in
 * place, every session ended, and the email address free to register again. */

const remove = (token: string, body: object) => request(app).post('/auth/delete-account').set('Authorization', `Bearer ${token}`).send(body);

describe('deleting your own account', () => {
  it('needs the password, and changes nothing without it', async () => {
    const learner = await newStudent('Careful Learner');
    expect((await remove(learner.token, {})).status).toBe(400);
    expect((await remove(learner.token, { password: 'not-my-password' })).status).toBe(403);
    expect((await learner.get('/auth/me')).status).toBe(200);
  });

  it('anonymises the learner, removes what only served them, and ends every session', async () => {
    const learner = await newStudent('Leaving Learner');
    const second = (await request(app).post('/auth/login').send({ email: learner.email, password: PASSWORD })).body.token as string;
    const lesson = await platformDb.lesson.findFirstOrThrow({ where: { status: 'published', isPreview: false } });
    await learner.post(`/learning/courses/${lesson.courseId}/enroll`);
    await learner.post(`/learning/courses/${lesson.courseId}/lessons/${lesson.id}/bookmark`);
    expect(await platformDb.lessonBookmark.count({ where: { studentId: learner.studentId } })).toBe(1);

    const res = await remove(learner.token, { password: PASSWORD });
    expect(res.status, JSON.stringify(res.body)).toBe(200);

    const row = await platformDb.user.findUniqueOrThrow({ where: { id: learner.userId } });
    expect(row.email).not.toBe(learner.email);
    expect(row.name).toBe('Deleted learner');
    expect(row.deactivatedAt).not.toBeNull();
    expect(await platformDb.lessonBookmark.count({ where: { studentId: learner.studentId } })).toBe(0);
    expect(await platformDb.userSession.count({ where: { userId: learner.userId, revokedAt: null } })).toBe(0);
    expect(await platformDb.auditLog.count({ where: { action: 'account.deleted', targetId: learner.userId } })).toBe(1);

    for (const token of [learner.token, second]) {
      expect((await request(app).get('/auth/me').set('Authorization', `Bearer ${token}`)).status).toBe(401);
    }
    expect((await request(app).post('/auth/login').send({ email: learner.email, password: PASSWORD })).status).toBe(401);
    // The address is free again.
    expect((await request(app).post('/auth/register').send({ name: 'Returning Learner', email: learner.email, password: PASSWORD })).status).toBe(201);
  });

  it('refuses staff, whose accounts their academy closes', async () => {
    const instructor = await as('instructor');
    expect((await instructor.post('/auth/delete-account', { password: PASSWORD })).status).toBe(403);
    expect((await instructor.get('/auth/me')).status).toBe(200);
  });

  it('refuses an anonymous caller', async () => {
    expect((await request(app).post('/auth/delete-account').send({ password: PASSWORD })).status).toBe(401);
  });
});
