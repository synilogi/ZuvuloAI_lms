import { beforeAll, describe, expect, it } from 'vitest';

import { db, T } from '../test/db.js';
import { anon, as, newStudent, type Client } from '../test/helpers.js';

/* SAAS-024. The routes the endpoint audit found with no test of their own: each is exercised here for what it does,
 * who may do it, and what it refuses. */

let admin: Client;
let instructor: Client;

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
});

describe('duplicating course content', () => {
  it('copies a chapter and a lesson as drafts, in place, in the caller’s course only', async () => {
    const lesson = await db.lesson.findFirstOrThrow({ where: { status: 'published' } });
    const before = await db.chapter.count({ where: { courseId: lesson.courseId } });
    const chapter = await admin.post(`/courses/${lesson.courseId}/chapters/${lesson.chapterId}/duplicate`);
    expect(chapter.status, JSON.stringify(chapter.body)).toBeLessThan(300);
    expect(await db.chapter.count({ where: { courseId: lesson.courseId } })).toBe(before + 1);

    const copy = await admin.post(`/courses/${lesson.courseId}/lessons/${lesson.id}/duplicate`);
    expect(copy.status).toBeLessThan(300);
    const stored = await db.lesson.findFirstOrThrow({ where: { chapterId: lesson.chapterId, title: `${lesson.title} (copy)` } });
    expect(stored.status).toBe('draft');

    expect((await admin.post(`/courses/${lesson.courseId}/lessons/no-such-lesson/duplicate`)).status).toBe(404);
    // Leave the seeded course as it was: other suites read its chapters by position.
    await db.lesson.delete({ where: { id: stored.id } });
    await db.chapter.delete({ where: { id: chapter.body.id } });
    const learner = await newStudent('Duplicate Learner');
    expect((await learner.post(`/courses/${lesson.courseId}/lessons/${lesson.id}/duplicate`)).status).toBe(403);
  });

  it('copies a quiz and an assignment as drafts, and refuses one out of scope', async () => {
    const quiz = await db.quiz.findFirstOrThrow({ where: { status: 'published' } });
    const quizCopy = await admin.post(`/quizzes/${quiz.id}/duplicate`);
    expect(quizCopy.status).toBeLessThan(300);
    const storedQuiz = await db.quiz.findUniqueOrThrow({ where: { id: quizCopy.body.id } });
    expect(storedQuiz).toMatchObject({ status: 'draft', courseId: quiz.courseId, lessonId: null });

    const assignment = await db.courseAssignment.findFirstOrThrow({ where: { status: 'published' } });
    const copy = await admin.post(`/assignments/${assignment.id}/duplicate`);
    expect(copy.status).toBeLessThan(300);
    expect((await db.courseAssignment.findUniqueOrThrow({ where: { id: copy.body.id } })).status).toBe('draft');
    await db.quiz.delete({ where: { id: quizCopy.body.id } });
    await db.courseAssignment.delete({ where: { id: copy.body.id } });

    // An instructor who does not teach the course: as far as they can tell, it does not exist.
    const outside = await db.quiz.findFirst({ where: { course: { instructors: { none: { instructor: { email: 'meenakshi@syniastrolms.test' } } } } } });
    if (outside) expect((await instructor.post(`/quizzes/${outside.id}/duplicate`)).status).toBe(404);
    expect((await admin.post('/quizzes/no-such-quiz/duplicate')).status).toBe(404);
  });
});

describe('a learner’s bookmarks and notifications', () => {
  it('toggles a bookmark on an enrolled course’s lesson, and refuses one not enrolled', async () => {
    const learner = await newStudent('Bookmark Learner');
    // In a free course, which a learner enrols in themselves (a paid one is bought).
    const lesson = await db.lesson.findFirstOrThrow({
      where: { status: 'published', isPreview: false, chapter: { course: { status: 'published', visibility: 'public', pricing: 'free' } } },
    });
    const path = `/learning/courses/${lesson.courseId}/lessons/${lesson.id}/bookmark`;
    expect((await learner.post(path)).status).toBe(403);
    expect((await learner.post(`/learning/courses/${lesson.courseId}/enroll`)).status).toBe(200);
    expect((await learner.post(path)).body).toEqual({ bookmarked: true });
    expect(await db.lessonBookmark.count({ where: { studentId: learner.studentId, lessonId: lesson.id } })).toBe(1);
    expect((await learner.post(path)).body).toEqual({ bookmarked: false });
  });

  it('removes, restores and clears only the caller’s own notifications', async () => {
    const learner = await newStudent('Tidy Learner');
    const other = await newStudent('Other Learner');
    const make = (recipientId: string) =>
      db.appNotification.create({ data: { ...T, recipientId, category: 'course', title: 'Hello', summary: 'A note.', bodyJson: '["A note."]' } });
    const mine = await make(learner.userId);
    const theirs = await make(other.userId);

    expect((await learner.post('/notifications/remove', { ids: [mine.id, theirs.id] })).status).toBe(204);
    expect(await db.appNotification.count({ where: { id: mine.id } })).toBe(0);
    expect(await db.appNotification.count({ where: { id: theirs.id } })).toBe(1);

    const restored = await learner.post('/notifications/restore', {
      notifications: [{ id: mine.id, category: 'course', title: 'Hello', summary: 'A note.', createdAt: mine.createdAt.toISOString() }],
    });
    expect(restored.status).toBeLessThan(300);
    expect((await db.appNotification.findUniqueOrThrow({ where: { id: mine.id } })).recipientId).toBe(learner.userId);
    expect((await learner.post('/notifications/restore', { notifications: [] })).status).toBe(400);

    const cleared = await learner.post('/notifications/clear', {});
    expect(cleared.status).toBe(200);
    expect(cleared.body).toBeGreaterThanOrEqual(1);
    expect(await db.appNotification.count({ where: { recipientId: learner.userId } })).toBe(0);
    expect(await db.appNotification.count({ where: { id: theirs.id } })).toBe(1);
    expect((await anon().post('/notifications/clear', {})).status).toBe(401);
  });
});

describe('the Help Centre', () => {
  it('lists categories and articles for visitors, opens one by slug, and answers 404 for an unknown one', async () => {
    const categories = await anon().get('/help/categories');
    expect(categories.status).toBe(200);
    expect(categories.body.length).toBeGreaterThan(0);
    const articles = await anon().get('/help/articles');
    expect(articles.status).toBe(200);
    const article = await anon().get('/help/articles/welcome-to-syniastrolms');
    expect(article.status).toBe(200);
    expect(JSON.stringify(article.body)).toContain('Welcome to ZuviloAI');
    expect((await anon().get('/help/articles/no-such-article')).status).toBe(404);
  });
});
