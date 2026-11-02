import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { db } from '../test/db.js';
import { as, newStudent, type Client } from '../test/helpers.js';

/* The rules around a quiz session (quizSessions.test.ts covers the session itself): the quiz's window, results held
 * until it closes, apps built before sessions, paused and archived, what staff see, and what a learner may not forge. */

const KEY_FIELDS = /"(correct|acceptedAnswers|explanation)"/;

let admin: Client;
let quiz: { id: string; lessonId: string; courseId: string; questionsJson: string; settingsJson: string; status: string };
let learning: Record<string, unknown>;

type Q = { id: string; type: string; correct: string[]; acceptedAnswers: string[]; points: number };
const key = () => JSON.parse(quiz.questionsJson) as Q[];
const rightAnswers = () => Object.fromEntries(key().map((q) => [q.id, q.type === 'short' ? q.acceptedAnswers[0] : q.correct]));
const setQuiz = (over: Record<string, unknown>, extra: Record<string, unknown> = {}) =>
  db.quiz.update({ where: { id: quiz.id }, data: { settingsJson: JSON.stringify({ ...JSON.parse(quiz.settingsJson), ...over }), ...extra } });
const base = () => `/learning/courses/${quiz.courseId}/lessons/${quiz.lessonId}`;
const start = (c: Client) => c.post(`${base()}/quiz-session`, {});
const submit = (c: Client, id: string, body: Record<string, unknown> = {}) => c.post(`${base()}/quiz-session/${id}/submit`, body);
const standing = (c: Client) => c.get(`${base()}/quiz-attempts`);
const inMin = (m: number) => new Date(Date.now() + m * 60_000).toISOString();

async function enrolled(name: string) {
  const learner = await newStudent(name);
  expect((await learner.post(`/learning/courses/${quiz.courseId}/enroll`)).status).toBe(200);
  return learner;
}

beforeAll(async () => {
  admin = await as('admin');
  learning = (await admin.get('/settings')).body.settings.learning;
  await admin.put('/settings/learning', { ...learning, chapterGate: false, retakeWaitHours: 0 });
  const rows = await db.quiz.findMany({ where: { status: 'published', lessonId: { not: null } }, orderBy: { createdAt: 'asc' } });
  // Not the first one: quizSessions.test.ts works on that.
  const row = rows[rows.length - 1];
  quiz = { id: row.id, lessonId: row.lessonId!, courseId: row.courseId, questionsJson: row.questionsJson, settingsJson: row.settingsJson, status: row.status };
});

afterAll(async () => {
  await db.quiz.update({ where: { id: quiz.id }, data: { settingsJson: quiz.settingsJson, status: quiz.status, questionsJson: quiz.questionsJson } });
  await admin.put('/settings/learning', learning);
});

describe('a quiz’s window', () => {
  it('starts nothing before it opens or after it closes, and says so', async () => {
    const learner = await enrolled('Window Watcher');
    await setQuiz({ attempts: 0, timeLimitMin: null, opensAt: inMin(30), closesAt: inMin(90) });
    const early = await start(learner);
    expect(early.status).toBe(409);
    expect(early.body.code).toBe('TEST_NOT_OPEN');
    const before = (await standing(learner)).body.standing;
    expect(before).toMatchObject({ window: 'upcoming', canStart: false, blockedReason: 'This quiz has not opened yet.' });

    await setQuiz({ attempts: 0, opensAt: inMin(-90), closesAt: inMin(-30) });
    const late = await start(learner);
    expect(late.status).toBe(409);
    expect(late.body.code).toBe('TEST_CLOSED');
    expect(await db.quizSession.count({ where: { quizId: quiz.id, studentId: learner.studentId } })).toBe(0);
  });

  it('cuts an attempt’s deadline to the close, and shows the window on the learner’s list', async () => {
    const learner = await enrolled('Close Cutter');
    const closesAt = inMin(10);
    await setQuiz({ attempts: 0, timeLimitMin: 60, opensAt: inMin(-5), closesAt });
    const started = await start(learner);
    expect(started.status).toBe(201);
    expect(started.body.session.deadlineAt).toBe(new Date(closesAt).toISOString());
    const row = (await learner.get('/learning/assessments')).body.find((r: { id: string }) => r.id === quiz.id);
    expect(row).toMatchObject({ window: 'open', state: 'in-progress', deadlineAt: new Date(closesAt).toISOString() });
  });
});

describe('results held until the quiz closes', () => {
  it('tells the learner only that the attempt was received, and when results come', async () => {
    const learner = await enrolled('Patient Learner');
    const closesAt = inMin(60);
    await setQuiz({ attempts: 0, timeLimitMin: null, opensAt: undefined, closesAt, resultsRelease: 'after-close', showResults: 'score-and-answers' });
    const s = (await start(learner)).body.session;
    const done = await submit(learner, s.id, { answers: rightAnswers(), seq: 1 });
    expect(done.status).toBe(200);
    expect(done.body.review).toMatchObject({ showResults: 'hidden', resultsAt: new Date(closesAt).toISOString() });
    expect(done.body.review.percent).toBeUndefined();
    expect(JSON.stringify(done.body)).not.toMatch(KEY_FIELDS);
    const listed = (await learner.get('/learning/assessments')).body.find((r: { id: string }) => r.id === quiz.id);
    expect(listed.score).toBeUndefined();
    expect(listed.resultsAt).toBe(new Date(closesAt).toISOString());

    // Once it has closed, the result is out — and with no attempt left to use them on, the answers too.
    await setQuiz({ attempts: 0, closesAt: inMin(-1), resultsRelease: 'after-close', showResults: 'score-and-answers' });
    const after = (await standing(learner)).body;
    expect(after.attempts[0].percent).toBe(100);
    expect(after.attempts[0].keyWithheld).toBeUndefined();
    expect(JSON.stringify(after.attempts[0])).toMatch(/"correct"/);
  });
});

describe('apps built before quiz sessions', () => {
  it('still take an untimed quiz in one request — counted against the limit and scored on the server', async () => {
    const learner = await enrolled('Old App');
    await setQuiz({ attempts: 1, timeLimitMin: null, opensAt: undefined, closesAt: undefined, resultsRelease: undefined, passMark: 100 });
    // An untimed quiz with no window still lists its questions on the lesson, without the key.
    const lesson = (await learner.get(base())).body;
    expect(lesson.quiz.questions).toHaveLength(key().length);
    expect(JSON.stringify(lesson.quiz)).not.toMatch(KEY_FIELDS);

    const wrong = Object.fromEntries(key().map((q) => [q.id, q.type === 'short' ? 'nope' : []]));
    // A score, a pass and a duration sent by the app are not the app's to decide.
    const first = await learner.post(`${base()}/quiz-attempt`, { answers: wrong, durationSec: 1, percent: 100, passed: true });
    expect(first.status).toBe(200);
    expect(first.body).toBeNull();
    const attempts = await db.quizAttempt.findMany({ where: { quizId: quiz.id, studentId: learner.studentId } });
    expect(attempts).toHaveLength(1);
    expect(attempts[0]).toMatchObject({ percent: 0, passed: false });
    expect(attempts[0].sessionId).toBeTruthy();
    // The one attempt is used.
    const second = await learner.post(`${base()}/quiz-attempt`, { answers: rightAnswers() });
    expect(second.status).toBe(409);
    expect(second.body.message).toMatch(/used all 1 attempt/);
  });

  it('are told to update for a timed quiz, which they cannot keep the time of', async () => {
    const learner = await enrolled('Old App Timed');
    await setQuiz({ attempts: 0, timeLimitMin: 15, opensAt: undefined, closesAt: undefined });
    expect((await learner.get(base())).body.quiz.questions).toEqual([]);
    const res = await learner.post(`${base()}/quiz-attempt`, { answers: rightAnswers() });
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('QUIZ_SESSION_REQUIRED');
    expect(await db.quizAttempt.count({ where: { quizId: quiz.id, studentId: learner.studentId } })).toBe(0);
  });
});

describe('a learner whose place is paused or ended', () => {
  it('cannot start or answer, but still sees what they did', async () => {
    const learner = await enrolled('Paused Learner');
    await setQuiz({ attempts: 0, timeLimitMin: 30, opensAt: undefined, closesAt: undefined, resultsRelease: undefined });
    const s = (await start(learner)).body.session;
    const enrolment = await db.enrollment.findFirstOrThrow({ where: { studentId: learner.studentId, courseId: quiz.courseId } });

    await admin.patch(`/students/enrollments/${enrolment.id}`, { status: 'paused' });
    expect((await start(learner)).body.code).toBe('ENROLLMENT_PAUSED');
    expect((await learner.put(`${base()}/quiz-session/${s.id}/answers`, { answers: rightAnswers(), seq: 1 })).body.message).toMatch(/paused/);
    const paused = await standing(learner);
    expect(paused.status).toBe(200);
    // The screen is told before the learner taps: no resume, and why.
    expect(paused.body.standing).toMatchObject({ canStart: false, blockedReason: expect.stringMatching(/paused/) });
    expect(paused.body.standing.openSession).toBeDefined();

    await db.enrollment.update({ where: { id: enrolment.id }, data: { status: 'active', expiresAt: new Date(Date.now() - 60_000) } });
    const ended = await learner.put(`${base()}/quiz-session/${s.id}/answers`, { answers: rightAnswers(), seq: 2 });
    expect(ended.status).toBe(409);
    expect(ended.body.message).toMatch(/access to this course has ended/);
    const stored = await db.quizSession.findUniqueOrThrow({ where: { id: s.id } });
    expect(stored.answersSeq).toBe(0);
  });
});

describe('archived quizzes', () => {
  it('start nothing new, let an attempt under way be handed in, and keep every result', async () => {
    const learner = await enrolled('Mid Archive');
    const late = await enrolled('After Archive');
    await setQuiz({ attempts: 0, timeLimitMin: 30, opensAt: undefined, closesAt: undefined });
    const s = (await start(learner)).body.session;

    const archived = await admin.patch(`/quizzes/${quiz.id}`, { status: 'archived' });
    expect(archived.status).toBe(200);
    expect(archived.body.status).toBe('archived');
    expect((await start(late)).status).toBe(404);
    expect((await late.get(base())).body.quiz).toBeUndefined();

    // The attempt started before the archive was taken on its own questions: it can still be finished.
    const done = await submit(learner, s.id, { answers: rightAnswers(), seq: 1 });
    expect(done.status).toBe(200);
    expect(done.body.session.status).toBe('submitted');
    expect((await standing(learner)).body.standing).toMatchObject({ canStart: false, blockedReason: 'This quiz is no longer open for attempts.' });

    // A quiz with results is archived, never deleted.
    const copy = await admin.post(`/quizzes/${quiz.id}/duplicate`);
    await db.quizAttempt.create({
      data: { tenantId: (await db.quiz.findUniqueOrThrow({ where: { id: copy.body.id } })).tenantId, quizId: copy.body.id, studentId: learner.studentId },
    });
    const del = await admin.delete(`/quizzes/${copy.body.id}`);
    expect(del.status).toBe(409);
    expect(del.body.message).toMatch(/Archive it instead/);
    expect(await db.quizAttempt.count({ where: { quizId: copy.body.id } })).toBe(1);
    await db.quiz.update({ where: { id: quiz.id }, data: { status: 'published' } });
  });
});

describe('what staff see', () => {
  it('lists every attempt — under way, handed in, closed by the server — with scores, to staff only', async () => {
    const learner = await enrolled('Listed Learner');
    await setQuiz({ attempts: 0, timeLimitMin: 5, opensAt: undefined, closesAt: undefined, showResults: 'hidden', resultsRelease: undefined });
    const first = (await start(learner)).body.session;
    await submit(learner, first.id, { answers: rightAnswers(), seq: 1 });
    const second = (await start(learner)).body.session;
    // Left past its deadline and the grace: the list finishes it before answering.
    await db.quizSession.update({
      where: { id: second.id },
      data: { startedAt: new Date(Date.now() - 20 * 60_000), deadlineAt: new Date(Date.now() - 10 * 60_000) },
    });

    const res = await admin.get(`/quizzes/${quiz.id}/attempts`);
    expect(res.status).toBe(200);
    const mine = res.body.rows.filter((r: { studentId: string }) => r.studentId === learner.studentId);
    expect(mine.map((r: { attemptNo: number; status: string }) => [r.attemptNo, r.status]).sort()).toEqual([
      [1, 'submitted'],
      [2, 'expired'],
    ]);
    // Staff see the score of a quiz that hides it from learners.
    expect(mine.find((r: { attemptNo: number }) => r.attemptNo === 1).percent).toBe(100);
    expect(mine.find((r: { attemptNo: number }) => r.attemptNo === 2).percent).toBe(0);

    expect((await learner.get(`/quizzes/${quiz.id}/attempts`)).status).toBe(403);
  });
});

describe('what a learner cannot forge or see early', () => {
  it('ignores a score or a deadline in the body, and keeps the key out of every learner response', async () => {
    const learner = await enrolled('Forger');
    await setQuiz({ attempts: 2, timeLimitMin: 10, showResults: 'score-and-answers', passMark: 100, opensAt: undefined, closesAt: undefined });
    const started = await learner.post(`${base()}/quiz-session`, { deadlineAt: inMin(600), attemptNo: 99 });
    expect(started.status).toBe(201);
    expect(started.body.session.attemptNo).toBe(1);
    expect(Date.parse(started.body.session.deadlineAt) - Date.now()).toBeLessThanOrEqual(10 * 60_000 + 1000);
    expect(JSON.stringify(started.body)).not.toMatch(KEY_FIELDS);

    const wrong = Object.fromEntries(key().map((q) => [q.id, q.type === 'short' ? 'nope' : []]));
    const done = await submit(learner, started.body.session.id, { answers: wrong, seq: 1, percent: 100, passed: true, score: 100 });
    expect(done.body.review).toMatchObject({ percent: 0, passed: false, keyWithheld: true });
    // One attempt left: the right answers are not handed to it.
    expect(JSON.stringify(done.body)).not.toMatch(KEY_FIELDS);
    expect(JSON.stringify((await standing(learner)).body)).not.toMatch(KEY_FIELDS);
  });

  it('refuses a window without its time zone, and a quiz that closes before it opens', async () => {
    const noZone = await admin.patch(`/quizzes/${quiz.id}`, { settings: { ...JSON.parse(quiz.settingsJson), opensAt: '2026-11-01T10:00' } });
    expect(noZone.status).toBe(400);
    const backwards = await admin.patch(`/quizzes/${quiz.id}`, {
      settings: { ...JSON.parse(quiz.settingsJson), opensAt: '2026-11-01T10:00:00+05:30', closesAt: '2026-11-01T09:00:00+05:30' },
    });
    expect(backwards.status).toBe(409);
    expect(JSON.stringify(backwards.body.issues)).toMatch(/close after it opens/);
    // A window given in India time is kept as the moment it names.
    const ok = await admin.patch(`/quizzes/${quiz.id}`, {
      settings: { ...JSON.parse(quiz.settingsJson), opensAt: '2026-11-01T10:00:00+05:30', closesAt: '2026-11-01T12:00:00+05:30' },
    });
    expect(ok.status).toBe(200);
    expect(ok.body.settings).toMatchObject({ opensAt: '2026-11-01T04:30:00.000Z', closesAt: '2026-11-01T06:30:00.000Z' });
  });

  it('marks negative marks on the server, and tells the learner the marking but not the answer', async () => {
    const learner = await enrolled('Negative Marks');
    const paper = key().map((q) => ({ ...q, negativePoints: 1 }));
    await setQuiz(
      { attempts: 0, timeLimitMin: null, opensAt: undefined, closesAt: undefined, showResults: 'score-only', passMark: 50 },
      { questionsJson: JSON.stringify(paper) },
    );
    // Said on the lesson before the start uses an attempt.
    expect((await learner.get(base())).body.quiz.negativeMarking).toBe(true);
    const started = (await start(learner)).body;
    expect(started.questions.every((q: { negativePoints?: number }) => q.negativePoints === 1)).toBe(true);
    // Every answer wrong: the points fall below zero, the percentage stops at it.
    const wrong = Object.fromEntries(
      paper.map((q) => [
        q.id,
        q.type === 'short'
          ? 'nope'
          : q.type === 'multiple'
            ? started.questions
                .find((x: { id: string }) => x.id === q.id)
                .options.filter((o: { id: string }) => !q.correct.includes(o.id))
                .map((o: { id: string }) => o.id)
                .slice(0, 1)
            : started.questions
                .find((x: { id: string }) => x.id === q.id)
                .options.filter((o: { id: string }) => !q.correct.includes(o.id))
                .map((o: { id: string }) => o.id)
                .slice(0, 1),
      ]),
    );
    const done = await submit(learner, started.session.id, { answers: wrong, seq: 1 });
    expect(done.body.review.points).toBe(-paper.length);
    expect(done.body.review.percent).toBe(0);
    await db.quiz.update({ where: { id: quiz.id }, data: { questionsJson: quiz.questionsJson } });
  });
});

describe('attempts recorded without their details', () => {
  it('still list and review — the score from the row, the questions as unanswered — instead of failing', async () => {
    const learner = await enrolled('Sample History');
    await setQuiz({ attempts: 3, timeLimitMin: 5, opensAt: undefined, closesAt: undefined, showResults: 'score-and-answers', passMark: 70 });
    const tenantId = (await db.quiz.findUniqueOrThrow({ where: { id: quiz.id } })).tenantId;
    // As the demo seed writes them: a score, and empty answers and result.
    await db.quizAttempt.create({
      data: { tenantId, quizId: quiz.id, studentId: learner.studentId, percent: 83, passed: true, answersJson: '{}', resultJson: '{}' },
    });
    const res = await standing(learner);
    expect(res.status).toBe(200);
    expect(res.body.attempts[0]).toMatchObject({ attemptNo: 1, percent: 83, passed: true });
    expect(res.body.standing).toMatchObject({ attemptsUsed: 1, passed: true });
  });
});

describe('the learner’s list of quizzes', () => {
  it('offers to resume an attempt under way, even a practice one after a pass', async () => {
    const learner = await enrolled('Practising');
    await setQuiz({ attempts: 0, timeLimitMin: 10, opensAt: undefined, closesAt: undefined, passMark: 50 });
    const first = (await start(learner)).body.session;
    await submit(learner, first.id, { answers: rightAnswers(), seq: 1 });
    const row = () => learner.get('/learning/assessments').then((r) => r.body.find((x: { id: string }) => x.id === quiz.id));
    expect((await row()).state).toBe('passed');
    await start(learner);
    expect(await row()).toMatchObject({ state: 'in-progress', passed: true });
  });
});

describe('practice after a pass, hidden scores and final sheets (2026-10-28)', () => {
  const wrongAnswers = () => Object.fromEntries(key().map((q) => [q.id, q.type === 'short' ? 'no such answer' : ['nope']]));
  const sat = async (c: Client, answers: Record<string, unknown>) => {
    const s = (await start(c)).body.session;
    const done = await submit(c, s.id, { answers, seq: 1 });
    expect(done.status).toBe(200);
    return done.body;
  };
  const listed = async (c: Client) => (await c.get('/learning/assessments')).body.find((r: { id: string }) => r.id === quiz.id);

  it('credits the attempts up to the first pass: a retake with the answers shown never raises the score', async () => {
    const learner = await enrolled('Practice Retaker');
    await setQuiz({
      attempts: 0,
      timeLimitMin: null,
      opensAt: undefined,
      closesAt: undefined,
      resultsRelease: undefined,
      showResults: 'score-and-answers',
      passMark: 1,
    });
    const half = Object.fromEntries(
      key().map((q, i) => [q.id, i === 0 ? (q.type === 'short' ? q.acceptedAnswers[0] : q.correct) : q.type === 'short' ? 'x' : ['nope']]),
    );
    const first = await sat(learner, half);
    expect(first.review.passed).toBe(true);
    const credited = first.review.percent as number;
    expect(credited).toBeLessThan(100);
    const practice = await sat(learner, rightAnswers());
    expect(practice.review.percent).toBe(100);
    expect((await listed(learner)).score).toBe(credited);
  });

  it('never lists a score the quiz hides', async () => {
    const learner = await enrolled('Hidden Scorer');
    await setQuiz({ attempts: 0, timeLimitMin: null, showResults: 'hidden', passMark: 70 });
    await sat(learner, wrongAnswers());
    const row = await listed(learner);
    expect(row.score).toBeUndefined();
    const lesson = await learner.get(`${base()}`);
    expect(lesson.body.quizBest).toBeUndefined();
  });

  it('refuses a final sheet without its save number, rather than dropping it', async () => {
    const learner = await enrolled('Numberless Sheet');
    await setQuiz({ attempts: 0, timeLimitMin: null, showResults: 'score-and-answers' });
    const s = (await start(learner)).body.session;
    const bare = await submit(learner, s.id, { answers: rightAnswers() });
    expect(bare.status).toBe(400);
    expect((await db.quizSession.findUniqueOrThrow({ where: { id: s.id } })).status).toBe('active');
  });

  it('refuses to publish a quiz with no pass mark, or a key naming an answer not on offer', async () => {
    const { body: draft } = await admin.post('/quizzes', { courseId: quiz.courseId, title: 'Unpassable quiz', questions: key(), settings: { attempts: 1 } });
    const noMark = await admin.patch(`/quizzes/${draft.id}`, { status: 'published' });
    expect(noMark.status).toBe(409);
    expect(JSON.stringify(noMark.body)).toMatch(/pass mark/);
    const choice = key().find((q) => q.type === 'single');
    if (choice) {
      const broken = key().map((q) => (q.id === choice.id ? { ...q, correct: ['not-an-option'] } : q));
      const badKey = await admin.patch(`/quizzes/${draft.id}`, { status: 'published', questions: broken, settings: { passMark: 50 } });
      expect(badKey.status).toBe(409);
    }
    const shortNoAnswers = await admin.patch(`/quizzes/${draft.id}`, {
      status: 'published',
      settings: { passMark: 50 },
      questions: [{ id: 's1', type: 'short', prompt: 'Name it', points: 1, options: [], correct: [] }],
    });
    expect(shortNoAnswers.status).toBe(409);
    await db.quiz.delete({ where: { id: draft.id } });
  });
});
