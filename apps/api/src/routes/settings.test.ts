import { beforeAll, describe, expect, it } from 'vitest';

import { db, inAcademy } from '../test/db.js';
import { archiveInactiveCourses, sendInactivityNudges } from '../lib/notificationJobs.js';
import { as, newStudent, unique, type Client } from '../test/helpers.js';

let admin: Client;
let instructor: Client;
let settings: Record<string, Record<string, unknown>>;

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  settings = (await admin.get('/settings')).body.settings;
});

describe('settings: saving', () => {
  it('records who saved a section by name, validates, and keeps instructors read-only', async () => {
    const saved = await admin.put('/settings/general', { ...settings.general, academyName: 'ZuviloAI' });
    expect(saved.status).toBe(200);
    expect(saved.body.updatedBy.general).toBe('Kavita Menon');
    expect((await admin.put('/settings/nope', {})).status).toBe(400);
    expect((await admin.put('/settings/general', [])).status).toBe(400);
    expect((await admin.put('/settings/learning', { ...settings.learning, completionThreshold: 5 })).status).toBe(409);
    expect((await instructor.put('/settings/general', settings.general)).status).toBe(403);
    expect((await instructor.get('/settings')).status).toBe(200);
  });
});

describe('settings: enforced across modules', () => {
  it('at-risk days change learner statuses', async () => {
    const learner = await newStudent('Quiet For A Week');
    const courseId = (await instructor.get('/courses', { status: 'published', pageSize: 1 })).body.rows[0].id;
    await learner.post(`/learning/courses/${courseId}/enroll`);
    await db.student.update({ where: { id: learner.studentId }, data: { lastActiveAt: new Date(Date.now() - 7 * 86_400_000) } });
    await admin.put('/settings/learning', { ...settings.learning, atRiskDays: 10 });
    expect((await admin.get(`/students/${learner.studentId}`)).body.status).toBe('active');
    await admin.put('/settings/learning', { ...settings.learning, atRiskDays: 5 });
    expect((await admin.get(`/students/${learner.studentId}`)).body.status).toBe('at-risk');
    await admin.put('/settings/learning', settings.learning);
  });

  it('lesson defaults and rating thresholds come from settings; the default price is never applied by itself', async () => {
    const levelId = (await admin.get('/catalog/levels')).body[0].id;
    const categoryId = (await admin.get('/catalog/categories')).body[0].id;
    await admin.put('/settings/courses', { ...settings.courses, defaultPrice: 4999 });
    await admin.put('/settings/general', {
      ...settings.general,
      lessonDefaults: {
        ...(settings.general.lessonDefaults as object),
        durationMin: 25,
        completion: 'view',
        allowComments: false,
        allowDownloads: true,
        previewFirstLesson: true,
      },
    });
    const course = await admin.post('/courses', { title: `Defaults ${unique()}`, levelId, categoryId, coverMotif: 'orbits', instructorIds: [] });
    // An admin chooses free or paid (2026-10-23): the default price only prefills the editor, so a course created
    // without a price is free and carries none.
    expect(course.body.pricing).toBe('free');
    expect(course.body.price).toBeUndefined();
    const chapter = await admin.post(`/courses/${course.body.id}/chapters`, { input: { title: 'One' } });
    const lesson = await admin.post(`/courses/${course.body.id}/lessons`, { chapterId: chapter.body.id, input: { title: 'Welcome video', type: 'video' } });
    expect(lesson.body.durationMin).toBe(25);
    expect(lesson.body.isPreview).toBe(true);
    expect(lesson.body.settings).toMatchObject({ completion: 'opened', discussion: false, resourcesDownloadable: true });
    await admin.put('/settings/general', settings.general);
    await admin.put('/settings/courses', settings.courses);

    // ratings stay hidden in the public catalog until the academy's minimum is met
    const rated = (await admin.get('/catalog/courses')).body.find((c: { ratingCount?: number }) => (c.ratingCount ?? 0) > 0);
    if (rated) {
      const off = await admin.put('/settings/courses', { ...settings.courses, showRatings: false });
      expect(off.status).toBe(200);
      expect((await admin.get('/catalog/courses')).body.find((c: { id: string }) => c.id === rated.id).rating).toBeUndefined();
      // a threshold above the course's count hides it too (kept inside the setting's validated range)
      const threshold = await admin.put('/settings/courses', { ...settings.courses, showRatings: true, minRatings: Math.min(rated.ratingCount + 1, 50) });
      if (threshold.status === 200 && rated.ratingCount + 1 <= 50) {
        expect((await admin.get('/catalog/courses')).body.find((c: { id: string }) => c.id === rated.id).rating).toBeUndefined();
      }
      await admin.put('/settings/courses', settings.courses);
      expect((await admin.get('/catalog/courses')).body.find((c: { id: string }) => c.id === rated.id).rating).toBeDefined();
    }
  });

  it('archives courses inactive for the configured months and lets study reminders be switched off', async () => {
    const levelId = (await admin.get('/catalog/levels')).body[0].id;
    const categoryId = (await admin.get('/catalog/categories')).body[0].id;
    const stale = await admin.post('/courses', { title: `Stale ${unique()}`, levelId, categoryId, coverMotif: 'orbits', instructorIds: [] });
    await db.course.update({ where: { id: stale.body.id }, data: { status: 'published', updatedAt: new Date(Date.now() - 400 * 86_400_000) } });
    await admin.put('/settings/courses', { ...settings.courses, archiveInactiveMonths: 12 });
    expect(await inAcademy(() => archiveInactiveCourses())).toBeGreaterThanOrEqual(1);
    expect((await admin.get(`/courses/${stale.body.id}`)).body.status).toBe('archived');
    expect((await admin.get('/notifications', { limit: 5 })).body.rows[0].title).toMatch(/archived/);
    await admin.put('/settings/courses', settings.courses);

    await admin.put('/settings/learning', {
      ...settings.learning,
      learnerPreferences: { ...(settings.learning.learnerPreferences as object), studyReminders: false },
    });
    expect(await inAcademy(() => sendInactivityNudges())).toBe(0);
    await admin.put('/settings/learning', settings.learning);
  });
});
