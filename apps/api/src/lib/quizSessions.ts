import { randomInt } from 'node:crypto';
import {
  QUIZ_SUBMIT_GRACE_SEC,
  acceptAnswers,
  attemptsUsed,
  deadlineWindow,
  inSessionOrder,
  learnerQuestion,
  remainingSec,
  scoreAttempt,
  quizWindow,
  sessionDeadline,
  sessionOrder,
  type LearnerQuizQuestion,
  type QuizAnswers,
  type QuizOrder,
  type QuizQuestion,
  type QuizSessionStatus,
  type QuizSessionView,
  type QuizSettings,
} from '@syniastrolms/domain';

import { db, type DbClient } from './db.js';
import { ApiError, conflict, notFound } from './errors.js';
import { readJson, writeJson } from './json.js';
import { tenant } from './tenancy.js';

/*
 * Quiz sessions (A2) — the server's side of `packages/domain/src/quizSession.ts`.
 *
 * - Start: under the learner's enrolment-row lock (a write, so starts for the same learner and course queue), an
 *   open session is picked up again, or the attempt limit and retake wait are checked against every attempt used —
 *   sessions started and attempts made before sessions — and a new session is written. That write consumes the
 *   attempt. The deadline is the server's clock plus the time limit, stored with the session.
 * - Save: the learner's whole answer sheet, with a number that only grows. Stored only when the session is open, the
 *   deadline has not passed by the server's clock, and the number is higher than the last one stored — a save that
 *   arrives late, or out of order, changes nothing.
 * - Finish: one conditional update moves the session out of `active`; only the request that made it writes the
 *   scored attempt, so racing submissions finish it once and every later one reads the same result. A submission
 *   before the deadline may carry a final answer sheet; one in the grace after it delivers only what was stored.
 *   After the grace — or when the server's job finds the session there — it finishes as `expired`, scored on what was
 *   stored, like any other attempt.
 */

type SessionRow = NonNullable<Awaited<ReturnType<typeof db.quizSession.findUnique>>>;
type QuizRow = NonNullable<Awaited<ReturnType<typeof db.quiz.findUnique>>>;

const TX = { maxWait: 15_000, timeout: 15_000 };

/** A cryptographically random number in [0, 1), for the order a learner sees. */
const secureRandom = () => randomInt(0, 2 ** 32) / 2 ** 32;

/** Thrown when an answer arrives after the deadline, or at a session that is already finished. */
export const quizTimeUp = () => new ApiError(409, 'Time is up for this attempt. Answers sent after the deadline are not counted.', undefined, 'QUIZ_TIME_UP');
export const quizFinished = () => new ApiError(409, 'This attempt has already been handed in.', undefined, 'QUIZ_FINISHED');

/** A quiz outside its window. The dates are the server's; a client shows them in local time. */
export function assertQuizOpen(settings: Pick<QuizSettings, 'opensAt' | 'closesAt'>, now = new Date()) {
  const window = quizWindow(settings, now);
  if (window === 'upcoming') throw new ApiError(409, 'This quiz has not opened yet.', { opensAt: settings.opensAt }, 'TEST_NOT_OPEN');
  if (window === 'closed') throw new ApiError(409, 'This quiz has closed.', { closesAt: settings.closesAt }, 'TEST_CLOSED');
}

export function sessionView(row: SessionRow, now = new Date()): QuizSessionView {
  return {
    id: row.id,
    quizId: row.quizId,
    attemptNo: row.attemptNo,
    status: row.status as QuizSessionStatus,
    startedAt: row.startedAt.toISOString(),
    deadlineAt: row.deadlineAt?.toISOString(),
    serverNow: now.toISOString(),
    remainingSec: row.status === 'active' ? remainingSec(row.deadlineAt, now) : row.deadlineAt ? 0 : undefined,
    answers: readJson<QuizAnswers>(row.answersJson, {}),
    answersSeq: row.answersSeq,
    savedAt: row.answersSavedAt?.toISOString(),
    finishedAt: row.finishedAt?.toISOString(),
  };
}

/** The session's questions as the learner may see them: without their key, in the order fixed at the start. */
export function sessionQuestions(row: SessionRow): LearnerQuizQuestion[] {
  const questions = readJson<QuizQuestion[]>(row.questionsJson, []);
  return inSessionOrder(questions.map(learnerQuestion), readJson<QuizOrder>(row.orderJson, { questions: [], options: {} }));
}

export interface StartRules {
  /** The academy's default limit when the quiz sets none; 0 is unlimited. */
  quizAttempts: number;
  retakeWaitHours: number;
}

/**
 * Starts the learner's next attempt, or picks up the one still open. `startKey` makes a retried start answer with the
 * session the first one made. Refuses (409) when the attempts are used or the retake wait has not passed.
 */
export async function startSession(input: {
  quiz: QuizRow;
  studentId: string;
  enrollmentId: string;
  rules: StartRules;
  startKey?: string;
  now?: Date;
}): Promise<{ row: SessionRow; resumed: boolean }> {
  const { quiz, studentId, enrollmentId, rules, startKey } = input;
  const now = input.now ?? new Date();
  // A session left past its deadline is finished first, in its own transaction, so it counts as the attempt it was.
  await finishOverdue({ quizId: quiz.id, studentId }, now);
  const questions = readJson<QuizQuestion[]>(quiz.questionsJson, []);
  const settings = readJson<QuizSettings>(quiz.settingsJson, {} as QuizSettings);
  return db.$transaction(async (tx) => {
    // The lock: a write on the learner's own enrolment row, held until this transaction ends.
    await tx.enrollment.update({ where: { id: enrollmentId }, data: { lastActiveAt: now } });
    const sessions = await tx.quizSession.findMany({ where: { quizId: quiz.id, studentId }, orderBy: { attemptNo: 'asc' } });
    if (startKey) {
      const same = sessions.find((s) => s.startKey === startKey);
      if (same) return { row: same, resumed: true };
    }
    const open = sessions.find((s) => s.status === 'active' && deadlineWindow(s.deadlineAt, now) === 'open');
    if (open) return { row: open, resumed: true };
    // Past its deadline but inside the grace, the last attempt can still be handed in: it is not over, so no new one
    // starts — nor does the retake wait, which runs from when an attempt is handed in.
    if (sessions.some((s) => s.status === 'active')) {
      throw conflict('Your last attempt is still being handed in. Try again in a minute.');
    }
    // Nothing new starts outside the quiz's window; an attempt already running was picked up above.
    assertQuizOpen(settings, now);

    const attempts = await tx.quizAttempt.findMany({
      where: { quizId: quiz.id, studentId },
      orderBy: { createdAt: 'desc' },
      select: { passed: true, createdAt: true, sessionId: true },
    });
    const used = attemptsUsed(sessions, attempts);
    // Attempts are limited until the quiz is passed; afterwards retakes are practice and keep the best score.
    if (!attempts.some((a) => a.passed)) {
      const limit = settings.attempts ?? rules.quizAttempts;
      if (limit > 0 && used >= limit) throw conflict(`You have used all ${limit} attempts for this quiz.`);
      const last = attempts[0];
      if (last && rules.retakeWaitHours > 0) {
        const readyAt = last.createdAt.getTime() + rules.retakeWaitHours * 3_600_000;
        if (now.getTime() < readyAt) {
          const hours = Math.ceil((readyAt - now.getTime()) / 3_600_000);
          throw conflict(`You can try this quiz again in ${hours} hour${hours === 1 ? '' : 's'}.`);
        }
      }
    }
    if (!questions.length) throw conflict('This quiz has no questions yet.');
    const row = await tx.quizSession.create({
      data: {
        ...tenant(),
        quizId: quiz.id,
        studentId,
        attemptNo: used + 1,
        status: 'active',
        startedAt: now,
        // The time limit from now — cut to the quiz's close, so no attempt runs past it.
        deadlineAt: sessionDeadline(now, settings),
        questionsJson: writeJson(questions),
        settingsJson: writeJson(settings),
        orderJson: writeJson(sessionOrder(questions, settings, secureRandom)),
        startKey: startKey ?? null,
      },
    });
    return { row, resumed: false };
  }, TX);
}

/** The learner's latest session at the quiz — finishing it first when it is past its deadline and the grace. */
export async function latestSession(quizId: string, studentId: string, now = new Date()): Promise<SessionRow | null> {
  await finishOverdue({ quizId, studentId }, now);
  return db.quizSession.findFirst({ where: { quizId, studentId }, orderBy: { attemptNo: 'desc' } });
}

/** One of the learner's own sessions at this quiz, or 404 — another learner's session is never confirmed to exist. */
export async function ownSession(sessionId: string, quizId: string, studentId: string): Promise<SessionRow> {
  const row = await db.quizSession.findFirst({ where: { id: sessionId, quizId, studentId } });
  if (!row) throw notFound('Attempt not found.');
  return row;
}

/**
 * Stores the learner's whole answer sheet, numbered `seq`. Refused once the session is finished or past its deadline;
 * a sheet numbered no higher than the stored one arrived late and is ignored (the stored session is answered).
 */
export async function saveAnswers(row: SessionRow, answers: QuizAnswers, seq: number, now = new Date()): Promise<SessionRow> {
  if (row.status !== 'active') throw quizFinished();
  if (deadlineWindow(row.deadlineAt, now) !== 'open') throw quizTimeUp();
  const questions = readJson<QuizQuestion[]>(row.questionsJson, []);
  const sheet = acceptAnswers(questions, {}, answers);
  const stored = await db.quizSession.updateMany({
    where: { id: row.id, status: 'active', answersSeq: { lt: seq }, OR: [{ deadlineAt: null }, { deadlineAt: { gte: now } }] },
    data: { answersJson: writeJson(sheet), answersSeq: seq, answersSavedAt: now },
  });
  const fresh = await db.quizSession.findUniqueOrThrow({ where: { id: row.id } });
  if (stored.count === 0) {
    // Finished or past the deadline since it was read: say so. Otherwise the sheet was older than the stored one.
    if (fresh.status !== 'active') throw quizFinished();
    if (deadlineWindow(fresh.deadlineAt, now) !== 'open') throw quizTimeUp();
  }
  return fresh;
}

export interface Finished {
  row: SessionRow;
  attempt: { id: string; passed: boolean; percent: number };
  /** True for the one call that finished the session; false for every call that found it finished. */
  finishedNow: boolean;
  /** Whether a final answer sheet sent with the submission was taken (only before the deadline). */
  answersAccepted: boolean;
}

/**
 * Finishes a session: `submit` (the learner hands it in) or `expire` (the server closes one left past its deadline).
 * A final sheet (`answers`, `seq`) is taken only before the deadline. Safe to call any number of times, concurrently.
 */
export async function finishSession(
  sessionId: string,
  mode: 'submit' | 'expire',
  final?: { answers: QuizAnswers; seq: number },
  now = new Date(),
): Promise<Finished> {
  return db.$transaction(async (tx) => {
    // Twice at most: an autosave that lands between reading the session and claiming it changes its save number, and
    // the claim — which names that number — then reads the session again rather than score a sheet it never saw.
    for (let pass = 0; pass < 2; pass++) {
      const row = await tx.quizSession.findUnique({ where: { id: sessionId } });
      if (!row) throw notFound('Attempt not found.');
      if (row.status !== 'active') return finishedAlready(tx, row);

      const quiz = await tx.quiz.findUnique({ where: { id: row.quizId } });
      if (!quiz) throw notFound('This quiz is not available.');
      const window = deadlineWindow(row.deadlineAt, now);
      if (mode === 'expire' && window !== 'closed') throw conflict('This attempt is still open.');
      const questions = readJson<QuizQuestion[]>(row.questionsJson, []);
      let answers = readJson<QuizAnswers>(row.answersJson, {});
      let seq = row.answersSeq;
      let answersAccepted = false;
      // A final sheet counts only if it arrives by the deadline — the grace is for delivering what was already stored.
      if (final && window === 'open' && final.seq > row.answersSeq) {
        answers = acceptAnswers(questions, {}, final.answers);
        seq = final.seq;
        answersAccepted = true;
      }
      const status: QuizSessionStatus = mode === 'submit' && window !== 'closed' ? 'submitted' : 'expired';
      // The claim: only the request that moves the session out of `active`, from the sheet it read, scores it.
      const claimed = await tx.quizSession.updateMany({
        where: { id: row.id, status: 'active', answersSeq: row.answersSeq },
        data: { status, finishedAt: now, answersJson: writeJson(answers), answersSeq: seq, ...(answersAccepted ? { answersSavedAt: now } : {}) },
      });
      if (claimed.count === 0) continue;

      // Scored against the settings the attempt started with: a pass mark changed meanwhile does not move it.
      const settings = { ...readJson<QuizSettings>(quiz.settingsJson, {} as QuizSettings), ...readJson<Partial<QuizSettings>>(row.settingsJson, {}) };
      const result = scoreAttempt({ questions, settings }, answers);
      // Time taken by the server's clock, up to the deadline at most: nothing a client reports about time is used.
      const end = row.deadlineAt && now > row.deadlineAt ? row.deadlineAt : now;
      const attempt = await tx.quizAttempt.create({
        data: {
          ...tenant(),
          quizId: row.quizId,
          studentId: row.studentId,
          sessionId: row.id,
          percent: result.percent,
          passed: result.passed,
          answersJson: writeJson(answers),
          resultJson: writeJson(result),
          durationSec: Math.max(0, Math.round((end.getTime() - row.startedAt.getTime()) / 1000)),
        },
        select: { id: true, passed: true, percent: true },
      });
      const done = await tx.quizSession.findUniqueOrThrow({ where: { id: row.id } });
      return { row: done, attempt, finishedNow: true, answersAccepted };
    }
    // Still changing under it after a second read: whatever finished it is answered; otherwise ask for a retry.
    const latest = await tx.quizSession.findUniqueOrThrow({ where: { id: sessionId } });
    if (latest.status !== 'active') return finishedAlready(tx, latest);
    throw conflict('This attempt is being saved. Try handing it in again.');
  }, TX);
}

async function finishedAlready(tx: DbClient, row: SessionRow): Promise<Finished> {
  const attempt = await tx.quizAttempt.findUnique({ where: { sessionId: row.id }, select: { id: true, passed: true, percent: true } });
  if (!attempt) throw conflict('This attempt is being handed in. Try again in a moment.');
  return { row, attempt, finishedNow: false, answersAccepted: false };
}

/**
 * Finishes every open session matched by `where` that is past its deadline and the grace, as `expired`. Returns the
 * sessions this call finished — a caller completes the lesson of any that passed.
 */
export async function finishOverdue(where: { quizId?: string; studentId?: string } = {}, now = new Date()): Promise<Finished[]> {
  const cutoff = new Date(now.getTime() - QUIZ_SUBMIT_GRACE_SEC * 1000);
  const overdue = await db.quizSession.findMany({ where: { ...where, status: 'active', deadlineAt: { lt: cutoff } }, select: { id: true } });
  const out: Finished[] = [];
  for (const { id } of overdue) {
    const finished = await finishSession(id, 'expire', undefined, now);
    if (finished.finishedNow) out.push(finished);
  }
  return out;
}
