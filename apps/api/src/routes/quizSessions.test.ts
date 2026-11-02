import { QUIZ_SUBMIT_GRACE_SEC, scoreAttempt, type QuizQuestion, type QuizSettings } from '@syniastrolms/domain';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { T, db, inAcademy } from '../test/db.js';
import { as, newStudent, unique, type Client } from '../test/helpers.js';
import { settleOverdueQuizSessions } from './learning.js';

/* A2 — a quiz is taken through a session the server starts, keeps and finishes.
 *
 * The questions come only with a session; the deadline is the server's; answers count only once the server has
 * accepted them before that deadline; a submission in the grace after it delivers only what was stored; starts and
 * submissions are safe to repeat and to race; and attempts made before sessions keep counting. Time passing is
 * simulated by moving a session's start and deadline back, which is what the clock does to it. */

const KEY_FIELDS = /"(correct|acceptedAnswers|explanation)"/;

let admin: Client;
let course: { id: string };
let quiz: { id: string; lessonId: string; questionsJson: string; settingsJson: string };
let learning: Record<string, unknown>;

type Q = { id: string; type: string; correct: string[]; acceptedAnswers: string[]; options: { id: string }[] };
const key = () => JSON.parse(quiz.questionsJson) as Q[];
const rightAnswers = () => Object.fromEntries(key().map((q) => [q.id, q.type === 'short' ? q.acceptedAnswers[0] : q.correct]));
const wrongAnswers = () => Object.fromEntries(key().map((q) => [q.id, q.type === 'short' ? 'definitely wrong' : []]));
const setQuiz = (over: Record<string, unknown>) =>
  db.quiz.update({ where: { id: quiz.id }, data: { settingsJson: JSON.stringify({ ...JSON.parse(quiz.settingsJson), ...over }) } });

const base = () => `/learning/courses/${course.id}/lessons/${quiz.lessonId}`;
const start = (c: Client, body: Record<string, unknown> = {}) => c.post(`${base()}/quiz-session`, body);
const current = (c: Client) => c.get(`${base()}/quiz-session`);
const save = (c: Client, id: string, answers: Record<string, unknown>, seq: number) => c.put(`${base()}/quiz-session/${id}/answers`, { answers, seq });
const submit = (c: Client, id: string, body: Record<string, unknown> = {}) => c.post(`${base()}/quiz-session/${id}/submit`, body);
const sessionsOf = (studentId: string) => db.quizSession.findMany({ where: { quizId: quiz.id, studentId } });
const attemptsOf = (studentId: string) => db.quizAttempt.findMany({ where: { quizId: quiz.id, studentId } });
/** Moves a session `seconds` into its past: its start and deadline are that much earlier. */
async function age(sessionId: string, seconds: number) {
  const row = await db.quizSession.findUniqueOrThrow({ where: { id: sessionId } });
  const back = (d: Date | null) => (d ? new Date(d.getTime() - seconds * 1000) : d);
  await db.quizSession.update({ where: { id: sessionId }, data: { startedAt: back(row.startedAt)!, deadlineAt: back(row.deadlineAt) } });
}

async function enrolled(name: string) {
  const learner = await newStudent(name);
  expect((await learner.post(`/learning/courses/${course.id}/enroll`)).status).toBe(200);
  return learner;
}

beforeAll(async () => {
  admin = await as('admin');
  learning = (await admin.get('/settings')).body.settings.learning;
  await admin.put('/settings/learning', { ...learning, chapterGate: false, retakeWaitHours: 0 });
  const row = await db.quiz.findFirstOrThrow({ where: { status: 'published', lessonId: { not: null } }, include: { course: true } });
  quiz = { id: row.id, lessonId: row.lessonId!, questionsJson: row.questionsJson, settingsJson: row.settingsJson };
  course = { id: row.courseId };
});

afterAll(async () => {
  await db.quiz.update({ where: { id: quiz.id }, data: { settingsJson: quiz.settingsJson } });
  await admin.put('/settings/learning', learning);
});

describe('the questions come only with a session', () => {
  it('sends the lesson without questions, saying what the quiz is', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 20 });
    const learner = await enrolled('Lesson Reader');
    const view = await learner.get(base());
    expect(view.status).toBe(200);
    expect(view.body.quiz.questions).toEqual([]);
    expect(view.body.quiz.questionCount).toBe(key().length);
    expect(view.body.quiz.totalPoints).toBeGreaterThan(0);
    expect(view.body.quiz.attemptsUsed).toBe(0);
    expect(view.body.quiz.settings.timeLimitMin).toBe(20);
    // Nothing is started by reading the lesson.
    expect(await sessionsOf(learner.studentId)).toHaveLength(0);
  });

  it('starts a session with a server deadline and sends the questions without their key', async () => {
    const learner = await enrolled('Starter');
    const before = Date.now();
    // Whatever a client says about time or identity is not read.
    const res = await start(learner, { deadlineAt: '2099-01-01T00:00:00Z', studentId: 'someone-else', startedAt: '2000-01-01T00:00:00Z' });
    expect(res.status).toBe(201);
    expect(res.body.resumed).toBe(false);
    expect(res.body.questions).toHaveLength(key().length);
    expect(JSON.stringify(res.body)).not.toMatch(KEY_FIELDS);
    const deadline = new Date(res.body.session.deadlineAt).getTime();
    expect(deadline).toBeGreaterThanOrEqual(before + 20 * 60_000 - 1000);
    expect(deadline).toBeLessThanOrEqual(Date.now() + 20 * 60_000 + 1000);
    expect(res.body.session.remainingSec).toBeGreaterThan(19 * 60);
    const [stored] = await sessionsOf(learner.studentId);
    expect(stored.studentId).toBe(learner.studentId);
    expect(stored.deadlineAt?.toISOString()).toBe(res.body.session.deadlineAt);
  });

  it('refuses an app that submits without a session, and gives nobody but an enrolled learner a session', async () => {
    const learner = await enrolled('Old App');
    const old = await learner.post(`${base()}/quiz-attempt`, { answers: rightAnswers() });
    expect(old.status).toBe(409);
    expect(old.body.code).toBe('QUIZ_SESSION_REQUIRED');
    expect(await attemptsOf(learner.studentId)).toHaveLength(0);

    const outsider = await newStudent('Not Enrolled');
    expect((await start(outsider)).status).toBe(403);
    expect((await current(outsider)).status).toBe(403);
    // Staff have no learning workspace to take a quiz in.
    expect((await start(admin)).status).toBe(400);
  });
});

describe('starting is counted once, under any race', () => {
  it('gives two starts sent together one session, and one attempt', async () => {
    await setQuiz({ attempts: 2, timeLimitMin: 20 });
    const learner = await enrolled('Double Starter');
    const [a, b] = await Promise.all([start(learner), start(learner)]);
    expect([a.status, b.status].sort()).toEqual([200, 201]);
    expect(a.body.session.id).toBe(b.body.session.id);
    expect(await sessionsOf(learner.studentId)).toHaveLength(1);
  });

  it('answers a retried start with the session the first one made, even once it is finished', async () => {
    const learner = await enrolled('Retried Start');
    const startKey = `start-${unique()}`;
    const first = await start(learner, { startKey });
    expect((await submit(learner, first.body.session.id, { answers: wrongAnswers(), seq: 1 })).status).toBe(200);
    const again = await start(learner, { startKey });
    expect(again.status).toBe(200);
    expect(again.body.session.id).toBe(first.body.session.id);
    expect(again.body.session.status).toBe('submitted');
    expect(again.body.questions).toEqual([]);
    expect(await sessionsOf(learner.studentId)).toHaveLength(1);
  });

  it('consumes an attempt at the start, and refuses a start past the limit — six at once included', async () => {
    await setQuiz({ attempts: 2, timeLimitMin: 20 });
    const learner = await enrolled('Limited Starter');
    const one = await start(learner);
    await submit(learner, one.body.session.id, { answers: wrongAnswers(), seq: 1 });
    // The second attempt is used the moment it starts, before anything is answered.
    const two = await start(learner);
    expect(two.status).toBe(201);
    expect((await learner.get(base())).body.quiz.attemptsUsed).toBe(2);
    await submit(learner, two.body.session.id, {});
    const racing = await Promise.all(Array.from({ length: 6 }, () => start(learner)));
    for (const res of racing) {
      expect(res.status).toBe(409);
      expect(res.body.message).toMatch(/all 2 attempts/);
    }
    expect(await sessionsOf(learner.studentId)).toHaveLength(2);
  });

  it('counts attempts made before sessions existed', async () => {
    await setQuiz({ attempts: 2, timeLimitMin: undefined });
    const learner = await enrolled('Historical Learner');
    // Two attempts from before A2, written as the old one-shot submission wrote them: no session behind them.
    const result = scoreAttempt({ questions: key() as unknown as QuizQuestion[], settings: JSON.parse(quiz.settingsJson) as QuizSettings }, wrongAnswers());
    for (let i = 0; i < 2; i++) {
      await db.quizAttempt.create({
        data: {
          ...T,
          quizId: quiz.id,
          studentId: learner.studentId,
          percent: result.percent,
          passed: false,
          answersJson: JSON.stringify(wrongAnswers()),
          resultJson: JSON.stringify(result),
        },
      });
    }
    const refused = await start(learner);
    expect(refused.status).toBe(409);
    expect((await learner.get(base())).body.quiz.attemptsUsed).toBe(2);
    // They are still reviewed as they always were.
    const reviews = await learner.get(`${base()}/quiz-attempts`);
    expect(reviews.status).toBe(200);
    expect(reviews.body.attempts).toHaveLength(2);
  });
});

describe('answers are kept as the server accepted them', () => {
  it('saves the answer sheet, resumes it with the same questions in the same order, and ignores a late older save', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 20, shuffleQuestions: true, shuffleOptions: true });
    const learner = await enrolled('Resumer');
    const started = await start(learner);
    const id = started.body.session.id as string;
    const first = key()[0];
    const pick = first.type === 'short' ? 'typed' : [first.options[0].id];
    const saved = await save(learner, id, { [first.id]: pick }, 2);
    expect(saved.status).toBe(200);
    expect(saved.body.answers).toEqual({ [first.id]: pick });
    // An older save that arrives after a newer one changes nothing.
    const stale = await save(learner, id, {}, 1);
    expect(stale.status).toBe(200);
    expect(stale.body.answers).toEqual({ [first.id]: pick });
    expect(stale.body.answersSeq).toBe(2);

    // Coming back — after a reload, a lost connection, a restart — picks the same attempt up.
    const resumed = await current(learner);
    expect(resumed.body.session.id).toBe(id);
    expect(resumed.body.session.answers).toEqual({ [first.id]: pick });
    expect(resumed.body.questions.map((q: { id: string }) => q.id)).toEqual(started.body.questions.map((q: { id: string }) => q.id));
    const again = await start(learner);
    expect(again.status).toBe(200);
    expect(again.body.resumed).toBe(true);
    expect(again.body.session.id).toBe(id);
    expect((await learner.get(base())).body.quiz.openSession.id).toBe(id);
    expect((await learner.get('/learning/assessments')).body.find((r: { id: string }) => r.id === quiz.id).state).toBe('in-progress');
    await setQuiz({ shuffleQuestions: false, shuffleOptions: false });
  });

  it('never takes an answer after the deadline — not by save, and not with a submission in the grace', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 1 });
    const learner = await enrolled('Late Answerer');
    const id = (await start(learner)).body.session.id as string;
    expect((await save(learner, id, wrongAnswers(), 1)).status).toBe(200);
    // One minute and ten seconds later: past the deadline, inside the grace.
    await age(id, 70);
    const late = await save(learner, id, rightAnswers(), 2);
    expect(late.status).toBe(409);
    expect(late.body.code).toBe('QUIZ_TIME_UP');
    // The grace delivers what was stored — the right answers sent with it now are not taken.
    const handedIn = await submit(learner, id, { answers: rightAnswers(), seq: 3 });
    expect(handedIn.status).toBe(200);
    expect(handedIn.body.answersAccepted).toBe(false);
    expect(handedIn.body.session.status).toBe('submitted');
    expect(handedIn.body.completion).toBeNull();
    const [attempt] = await attemptsOf(learner.studentId);
    expect(attempt.passed).toBe(false);
    // Time taken is the server's, and stops at the deadline.
    expect(attempt.durationSec).toBe(60);
  });

  it('takes a final answer sheet sent with a submission before the deadline', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 5 });
    const learner = await enrolled('On Time');
    const id = (await start(learner)).body.session.id as string;
    const res = await submit(learner, id, { answers: rightAnswers(), seq: 1 });
    expect(res.body.answersAccepted).toBe(true);
    expect(res.body.completion).not.toBeNull();
    expect((await attemptsOf(learner.studentId))[0].passed).toBe(true);
  });

  it('closes an attempt handed in after the grace as expired, scored on what was stored', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 1 });
    const learner = await enrolled('Very Late');
    const id = (await start(learner)).body.session.id as string;
    await save(learner, id, rightAnswers(), 1);
    await age(id, 60 + QUIZ_SUBMIT_GRACE_SEC + 5);
    const res = await submit(learner, id, { answers: wrongAnswers(), seq: 2 });
    expect(res.status).toBe(200);
    expect(res.body.session.status).toBe('expired');
    expect(res.body.answersAccepted).toBe(false);
    // The stored sheet was right: the expired attempt passes on it.
    expect((await attemptsOf(learner.studentId))[0].passed).toBe(true);
  });
});

describe('handing in is safe to repeat and to race', () => {
  it('scores an attempt once, however many submissions arrive, and answers each the same', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 20 });
    const learner = await enrolled('Racing Submitter');
    const id = (await start(learner)).body.session.id as string;
    await save(learner, id, rightAnswers(), 1);
    const results = await Promise.all(Array.from({ length: 5 }, () => submit(learner, id)));
    for (const r of results) {
      expect(r.status).toBe(200);
      expect(r.body.session.status).toBe('submitted');
    }
    expect(await attemptsOf(learner.studentId)).toHaveLength(1);
    const later = await submit(learner, id, { answers: wrongAnswers(), seq: 9 });
    expect(later.body.session.status).toBe('submitted');
    expect(later.body.answersAccepted).toBe(false);
    expect((await attemptsOf(learner.studentId))[0].passed).toBe(true);
    expect((await save(learner, id, wrongAnswers(), 10)).body.code).toBe('QUIZ_FINISHED');
  });

  it('finishes an attempt left open past its deadline without the learner, and completes the lesson on a pass', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 1 });
    const learner = await enrolled('Walked Away');
    const id = (await start(learner)).body.session.id as string;
    await save(learner, id, rightAnswers(), 1);
    await age(id, 60 + QUIZ_SUBMIT_GRACE_SEC + 5);
    expect(await inAcademy(() => settleOverdueQuizSessions())).toBeGreaterThanOrEqual(1);
    const row = await db.quizSession.findUniqueOrThrow({ where: { id } });
    expect(row.status).toBe('expired');
    const attempts = await attemptsOf(learner.studentId);
    expect(attempts).toHaveLength(1);
    expect(attempts[0].sessionId).toBe(id);
    const view = await learner.get(base());
    expect(view.body.state).toBe('completed');
    // Running again finds nothing to do.
    await inAcademy(() => settleOverdueQuizSessions());
    expect(await attemptsOf(learner.studentId)).toHaveLength(1);
  });
});

describe('a session is the learner’s own', () => {
  it('answers 404 for another learner’s session, and changes nothing', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 20 });
    const owner = await enrolled('Owner');
    const other = await enrolled('Other');
    const id = (await start(owner)).body.session.id as string;
    expect((await save(other, id, wrongAnswers(), 1)).status).toBe(404);
    expect((await submit(other, id)).status).toBe(404);
    expect((await db.quizSession.findUniqueOrThrow({ where: { id } })).status).toBe('active');
  });
});

describe('findings of the A1/A2 security review', () => {
  it('withholds the answer key from reviews while a counted attempt remains or is open, and gives it after a pass', async () => {
    await setQuiz({ attempts: 3, timeLimitMin: 20, showResults: 'score-and-answers' });
    const learner = await enrolled('Key Seeker');
    const first = (await start(learner)).body.session.id as string;
    await submit(learner, first, { answers: wrongAnswers(), seq: 1 });
    const reviews = () => learner.get(`${base()}/quiz-attempts`);
    let res = await reviews();
    expect(res.status).toBe(200);
    expect(JSON.stringify(res.body)).not.toMatch(KEY_FIELDS);
    expect(res.body.attempts[0]).toMatchObject({ passed: false, keyWithheld: true });
    expect(res.body.attempts[0].percent).toBeDefined();

    // With the next attempt open, still nothing.
    const second = (await start(learner)).body.session.id as string;
    expect(JSON.stringify((await reviews()).body)).not.toMatch(KEY_FIELDS);

    await submit(learner, second, { answers: rightAnswers(), seq: 1 });
    res = await reviews();
    expect(JSON.stringify(res.body)).toMatch(/"correct"|"acceptedAnswers"/);
  });

  it('does not let a new attempt start while the last one is in its grace — the retake wait still holds', async () => {
    await setQuiz({ attempts: 3, timeLimitMin: 1 });
    await admin.put('/settings/learning', { ...learning, chapterGate: false, retakeWaitHours: 24 });
    try {
      const learner = await enrolled('Grace Restarter');
      const id = (await start(learner)).body.session.id as string;
      await age(id, 70);
      const again = await start(learner);
      expect(again.status).toBe(409);
      expect(await sessionsOf(learner.studentId)).toHaveLength(1);
      // Handed in, the wait applies.
      await submit(learner, id);
      expect((await start(learner)).status).toBe(409);
      expect(await sessionsOf(learner.studentId)).toHaveLength(1);
    } finally {
      await admin.put('/settings/learning', { ...learning, chapterGate: false, retakeWaitHours: 0 });
    }
  });

  it('takes no final answer sheet once the learner’s access has ended', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 20 });
    const learner = await enrolled('Expired Learner');
    const id = (await start(learner)).body.session.id as string;
    await save(learner, id, wrongAnswers(), 1);
    await db.enrollment.updateMany({ where: { studentId: learner.studentId, courseId: course.id }, data: { expiresAt: new Date(Date.now() - 60_000) } });
    const res = await submit(learner, id, { answers: rightAnswers(), seq: 2 });
    expect(res.status).toBe(409);
    expect(await attemptsOf(learner.studentId)).toHaveLength(0);
  });

  it('scores against the pass mark the attempt started with', async () => {
    await setQuiz({ attempts: 0, timeLimitMin: 20, passMark: 70 });
    const learner = await enrolled('Moved Goalposts');
    const id = (await start(learner)).body.session.id as string;
    // The pass mark is lowered to nothing while the attempt is open.
    await setQuiz({ passMark: 0 });
    await submit(learner, id, { answers: wrongAnswers(), seq: 1 });
    expect((await attemptsOf(learner.studentId))[0].passed).toBe(false);
    await setQuiz({ passMark: JSON.parse(quiz.settingsJson).passMark });
  });
});
