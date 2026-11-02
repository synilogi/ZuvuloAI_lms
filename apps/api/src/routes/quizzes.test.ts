import { beforeAll, describe, expect, it } from 'vitest';

import { db } from '../test/db.js';
import { as, newStudent, type Client } from '../test/helpers.js';

let admin: Client;

beforeAll(async () => {
  admin = await as('admin');
});

describe('quizzes: list metadata and validation', () => {
  it('shows the chapter a quiz belongs to and refuses malformed bodies', async () => {
    const list = await admin.get('/quizzes');
    expect(list.status).toBe(200);
    const linked = list.body.rows.find((r: { quiz: { lessonId?: string } }) => r.quiz.lessonId);
    expect(linked).toBeDefined();
    expect(typeof linked.chapterTitle).toBe('string');
    expect(linked.chapterTitle.length).toBeGreaterThan(0);

    expect((await admin.post('/quizzes', { title: '' })).status).toBe(400);
    expect((await admin.post('/quizzes', { courseId: linked.quiz.courseId, title: 'Bad status', status: 'live' })).status).toBe(400);
    const moved = await admin.patch(`/quizzes/${linked.quiz.id}`, { courseId: 'another-course' });
    expect(moved.status).toBe(409);
  });
});

describe('quizzes: results from stored attempts', () => {
  it('reports median time and the most common wrong option once learners attempt it', async () => {
    const catalog = (await admin.get('/catalog/courses')).body as {
      id: string;
      slug: string;
      chapters: { lessons: { id: string; type: string; status: string }[] }[];
    }[];
    const course = catalog.find((c) => c.slug.includes('foundations')) ?? catalog[0];
    const quizLesson = course.chapters[0].lessons.find((l) => l.type === 'assessment' && l.status === 'published')!;
    const learning = (await admin.get('/settings')).body.settings.learning;
    await admin.put('/settings/learning', { ...learning, chapterGate: false, retakeWaitHours: 0 });

    const learner = await newStudent('Quiz Taker');
    await learner.post(`/learning/courses/${course.id}/enroll`);
    const view = await learner.get(`/learning/courses/${course.id}/lessons/${quizLesson.id}`);
    // The learner's view carries no key (SAAS-018): the test reads it from the quiz, as its author would.
    const stored = await db.quiz.findUniqueOrThrow({ where: { id: view.body.quiz.id as string } });
    const quiz = {
      id: stored.id,
      questions: JSON.parse(stored.questionsJson) as { id: string; type: string; options: { id: string }[]; correct: string[]; acceptedAnswers?: string[] }[],
    };
    const choice = quiz.questions.find((q) => q.type === 'single' || q.type === 'true-false' || q.type === 'multiple')!;
    const wrongOption = choice.options.find((o) => !choice.correct.includes(o.id))!.id;
    const answers = Object.fromEntries(
      quiz.questions.map((q) => [q.id, q.id === choice.id ? [wrongOption] : q.type === 'short' ? (q.acceptedAnswers?.[0] ?? '') : q.correct]),
    );

    const attempt = await learner.post(`/learning/courses/${course.id}/lessons/${quizLesson.id}/quiz-attempt`, { answers, durationSec: 420 });
    expect(attempt.status).toBe(200);

    const stats = await admin.get(`/quizzes/${quiz.id}/stats`);
    expect(stats.status).toBe(200);
    expect(stats.body.attempts).toBeGreaterThan(0);
    expect(stats.body.medianMinutes).toBeGreaterThan(0);
    expect(stats.body.distribution).toHaveLength(10);
    const stat = stats.body.questions.find((q: { questionId: string }) => q.questionId === choice.id);
    expect(stat.commonWrongOptionId).toBe(wrongOption);
    expect(stat.correctRate).toBeLessThan(100);
    await admin.put('/settings/learning', learning);
  });
});
