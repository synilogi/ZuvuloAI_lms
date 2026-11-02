import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { db, T } from '../test/db.js';
import { anon, as, newStudent, type Client } from '../test/helpers.js';

/* SAAS-018. A learner is never sent a quiz's answer key: the server scores every attempt, and what the
 * learner may see afterwards is cut to the quiz's `showResults`. A hand-in fits its assignment's format
 * and word limit, and names only files the learner uploaded. */

const KEY_FIELDS = /"(correct|acceptedAnswers|explanation)"/;

let admin: Client;
let learner: Awaited<ReturnType<typeof newStudent>>;
let other: Awaited<ReturnType<typeof newStudent>>;
let course: { id: string; slug: string };
let quiz: { id: string; lessonId: string; questionsJson: string; settingsJson: string };
let learning: Record<string, unknown>;
let originalQuestions: string;
const made: string[] = [];

const key = () => JSON.parse(quiz.questionsJson) as { id: string; type: string; correct: string[]; acceptedAnswers: string[] }[];
const rightAnswers = () => Object.fromEntries(key().map((q) => [q.id, q.type === 'short' ? q.acceptedAnswers[0] : q.correct]));
const setShowResults = (showResults: string) =>
  db.quiz.update({ where: { id: quiz.id }, data: { settingsJson: JSON.stringify({ ...JSON.parse(quiz.settingsJson), attempts: 0, showResults }) } });

beforeAll(async () => {
  admin = await as('admin');
  learning = (await admin.get('/settings')).body.settings.learning;
  await admin.put('/settings/learning', { ...learning, chapterGate: false, retakeWaitHours: 0 });
  const row = await db.quiz.findFirstOrThrow({ where: { status: 'published', lessonId: { not: null } }, include: { course: true } });
  quiz = { id: row.id, lessonId: row.lessonId!, questionsJson: row.questionsJson, settingsJson: row.settingsJson };
  course = { id: row.courseId, slug: row.course.slug };
  originalQuestions = row.questionsJson;
  // An explanation on every question, so the test would see one leak.
  const explained = key().map((q) => ({ ...q, explanation: 'Because the text says so.' }));
  quiz.questionsJson = JSON.stringify(explained);
  await db.quiz.update({ where: { id: quiz.id }, data: { questionsJson: quiz.questionsJson } });

  learner = await newStudent('Integrity Learner');
  other = await newStudent('Other Learner');
  expect((await learner.post(`/learning/courses/${course.id}/enroll`)).status).toBe(200);
  expect((await other.post(`/learning/courses/${course.id}/enroll`)).status).toBe(200);
});

afterAll(async () => {
  await db.quiz.update({ where: { id: quiz.id }, data: { settingsJson: quiz.settingsJson, questionsJson: originalQuestions } });
  await db.courseAssignment.deleteMany({ where: { id: { in: made } } });
  await admin.put('/settings/learning', learning);
});

describe('no learner response carries the answer key', () => {
  it('walks every learner surface of a course with a quiz', async () => {
    const outline = await learner.get(`/learning/courses/${course.id}`);
    expect(outline.status).toBe(200);
    const lessons = (outline.body.course.chapters as { lessons: { id: string }[] }[]).flatMap((c) => c.lessons);
    const paths = [
      '/learning/home',
      '/learning/courses',
      `/learning/courses/${course.id}`,
      '/learning/assessments',
      '/learning/assignments',
      `/learning/courses/${course.id}/lessons/${quiz.lessonId}/quiz-attempts`,
      ...lessons.map((l) => `/learning/courses/${course.id}/lessons/${l.id}`),
    ];
    for (const path of paths) {
      const res = await learner.get(path);
      expect(res.status, path).toBe(200);
      expect(JSON.stringify(res.body), path).not.toMatch(KEY_FIELDS);
    }
    for (const path of ['/catalog/courses', `/catalog/courses/${course.slug}`]) {
      const res = await anon().get(path);
      expect(res.status, path).toBe(200);
      expect(JSON.stringify(res.body), path).not.toMatch(KEY_FIELDS);
    }
  });

  it('still gives the questions, their options and the settings needed to answer', async () => {
    const view = await learner.get(`/learning/courses/${course.id}/lessons/${quiz.lessonId}`);
    const first = view.body.quiz.questions[0];
    expect(Object.keys(first).sort()).toEqual(['id', 'options', 'points', 'prompt', 'required', 'type']);
    expect(view.body.quiz.questions).toHaveLength(key().length);
    expect(view.body.quiz.settings.passMark).toBeGreaterThan(0);
  });

  it('keeps the full quiz for staff, who author it', async () => {
    const res = await admin.get(`/quizzes/${quiz.id}`);
    expect(res.status).toBe(200);
    expect(JSON.stringify(res.body)).toMatch(/"correct"/);
  });
});

describe('an attempt is reviewed only as the quiz allows', () => {
  const attempt = () => learner.post(`/learning/courses/${course.id}/lessons/${quiz.lessonId}/quiz-attempt`, { answers: rightAnswers() });
  const latest = async () => (await learner.get(`/learning/courses/${course.id}/lessons/${quiz.lessonId}/quiz-attempts`)).body.attempts[0];

  it('shows the score, each outcome and the answers for score-and-answers', async () => {
    await setShowResults('score-and-answers');
    expect((await attempt()).status).toBe(200);
    const review = await latest();
    expect(review).toMatchObject({ showResults: 'score-and-answers', passed: true, percent: 100 });
    const q = key()[0];
    expect(review.questions[q.id].state).toBe('correct');
    expect(review.questions[q.id].explanation).toBe('Because the text says so.');
  });

  it('shows only the score for score-only', async () => {
    await setShowResults('score-only');
    await attempt();
    const review = await latest();
    expect(review).toMatchObject({ showResults: 'score-only', percent: 100, passed: true });
    expect(JSON.stringify(review)).not.toMatch(KEY_FIELDS);
    expect(review.questions).toBeUndefined();
  });

  it('shows only that it was received for hidden, and reads the older value nothing the same way', async () => {
    for (const value of ['hidden', 'nothing']) {
      await setShowResults(value);
      await attempt();
      const review = await latest();
      // Which attempt it was and how it ended say nothing about the result.
      expect(Object.keys(review).sort(), value).toEqual(['attemptId', 'attemptNo', 'finish', 'passed', 'showResults', 'submittedAt']);
      expect(review.showResults).toBe('hidden');
    }
  });

  it('never shows one learner another’s attempts', async () => {
    const res = await other.get(`/learning/courses/${course.id}/lessons/${quiz.lessonId}/quiz-attempts`);
    expect(res.status).toBe(200);
    expect(res.body.attempts).toEqual([]);
    const outsider = await newStudent('Not Enrolled');
    // Not enrolled: the learning workspace's usual answer, "Enrol in this course to continue".
    expect((await outsider.get(`/learning/courses/${course.id}/lessons/${quiz.lessonId}/quiz-attempts`)).status).toBe(403);
  });

  it('lets an author choose hidden results — the value the builder sends — and stores the domain’s word', async () => {
    const current = await admin.get(`/quizzes/${quiz.id}`);
    for (const value of ['hidden', 'nothing']) {
      const saved = await admin.patch(`/quizzes/${quiz.id}`, { settings: { ...current.body.settings, showResults: value } });
      expect(saved.status, value).toBe(200);
      expect(JSON.parse((await db.quiz.findUniqueOrThrow({ where: { id: quiz.id } })).settingsJson).showResults).toBe('hidden');
    }
  });
});

describe('a hand-in fits its assignment', () => {
  const assignment = async (format: 'text' | 'file' | 'chart', wordLimit?: number) => {
    const row = await db.courseAssignment.create({
      data: { ...T, courseId: course.id, title: `Integrity ${format} ${made.length}`, instructions: 'Answer.', format, wordLimit, status: 'published' },
    });
    made.push(row.id);
    return row.id;
  };
  const upload = (client: Client, name = 'work.pdf') => client.upload('/media/upload').attach('file', Buffer.from('%PDF-1.4 hand-in'), name);

  it('holds written work to its word limit, on the server', async () => {
    const id = await assignment('text', 50);
    const tooLong = Array.from({ length: 51 }, () => 'word').join(' ');
    const refused = await learner.post(`/learning/assignments/${id}/submit`, { text: tooLong, files: [] });
    expect(refused.status).toBe(409);
    expect(refused.body.message).toMatch(/50 words/);
    expect((await learner.post(`/learning/assignments/${id}/submit`, { text: 'A short answer.', files: [] })).status).toBe(200);
  });

  it('refuses files on a written assignment and a missing chart on a chart assignment', async () => {
    const text = await assignment('text');
    const own = await upload(learner);
    expect((await learner.post(`/learning/assignments/${text}/submit`, { text: 'Answer', files: [{ id: own.body.id, name: 'x', sizeMb: 1 }] })).status).toBe(
      409,
    );
    const chart = await assignment('chart');
    expect((await learner.post(`/learning/assignments/${chart}/submit`, { text: 'My reading', files: [] })).status).toBe(409);
  });

  it('takes only the learner’s own uploads, and reads their name and size from the stored file', async () => {
    const id = await assignment('file');
    const theirs = await upload(other, 'someone-else.pdf');
    expect(theirs.status).toBe(201);
    for (const files of [
      [{ id: theirs.body.id, name: 'mine.pdf', sizeMb: 1 }],
      [{ id: 'f-made-up', name: 'x.pdf', sizeMb: 1 }],
      [{ name: 'no-id.pdf', sizeMb: 1 }],
    ]) {
      expect((await learner.put(`/learning/assignments/${id}/draft`, { text: '', files })).status).toBe(409);
      expect((await learner.post(`/learning/assignments/${id}/submit`, { text: '', files })).status).toBe(409);
    }
    const own = await upload(learner, 'my-work.pdf');
    const submitted = await learner.post(`/learning/assignments/${id}/submit`, { text: '', files: [{ id: own.body.id, name: 'renamed.exe', sizeMb: 999 }] });
    expect(submitted.status).toBe(200);
    const stored = await db.submission.findFirstOrThrow({ where: { assignmentId: id, studentId: learner.studentId } });
    expect(JSON.parse(stored.filesJson)).toEqual([{ id: own.body.id, name: 'my-work.pdf', sizeMb: 0.1 }]);
  });
});
