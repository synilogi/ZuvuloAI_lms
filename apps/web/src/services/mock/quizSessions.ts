import type {
  AttemptResult,
  AttemptReview,
  LearnerQuizQuestion,
  Quiz,
  QuizAnswers,
  QuizOrder,
  QuizQuestion,
  QuizSessionStart,
  QuizSessionStatus,
  QuizSessionView,
  QuizSettings,
  QuizStanding,
} from '@syniastrolms/domain';
import {
  QUIZ_SUBMIT_GRACE_SEC,
  acceptAnswers,
  attemptsUsed,
  deadlineWindow,
  inSessionOrder,
  learnerQuestion,
  quizWindow,
  remainingSec,
  resultsOut,
  resultsVisibilityOf,
  reviewAttempt,
  scoreAttempt,
  sessionDeadline,
  sessionOrder,
} from '@syniastrolms/domain';
import type { QuizAttemptRow, QuizAttemptsView } from '../contracts';
import { ServiceError } from '../contracts';
import { mockNow } from './clock';
import { students } from './fixtures/people';
import { mockLearningRules } from './settings';

/*
 * Quiz sessions in the mock academy — the same rules as the API's `lib/quizSessions.ts` and `routes/learning.ts`,
 * run in memory so the demo behaves as the real product does:
 *
 * - a start consumes an attempt and fixes the deadline (the time limit from now, cut to the quiz's close); a start
 *   retried with the same key, or made while an attempt is open, answers with that attempt;
 * - a save stores the whole sheet only when its number is higher than the stored one, and only before the deadline;
 * - a submission is idempotent; one in the grace after the deadline delivers only what was stored; a session left
 *   past the grace is finished as `expired`, scored on what it stored;
 * - the answer key stays withheld while the learner can still take the quiz for credit, and every result is held
 *   while `resultsRelease: 'after-close'` waits for the close.
 */

interface SessionRow {
  id: string;
  quizId: string;
  studentId: string;
  attemptNo: number;
  status: QuizSessionStatus;
  startedAt: Date;
  deadlineAt: Date | null;
  questions: QuizQuestion[];
  settings: QuizSettings;
  order: QuizOrder;
  answers: QuizAnswers;
  answersSeq: number;
  savedAt?: Date;
  finishedAt?: Date;
  startKey?: string;
}

interface AttemptRow {
  id: string;
  quizId: string;
  studentId: string;
  sessionId?: string;
  createdAt: Date;
  percent: number;
  passed: boolean;
  answers: QuizAnswers;
  result: AttemptResult;
  durationSec: number;
}

const sessions: SessionRow[] = [];
const attempts: AttemptRow[] = [];
let serial = 0;
const nextId = (prefix: string) => `${prefix}-${Date.now().toString(36)}${(serial++).toString(36)}`;

export const ENROLMENT_PAUSED = 'Your place in this course is paused. Contact your LMS to continue.';

const conflict = (message: string, reason?: string) => new ServiceError(message, 'conflict', reason, undefined, 409);
export const quizTimeUp = () => conflict('Time is up for this attempt. Answers sent after the deadline are not counted.', 'QUIZ_TIME_UP');
export const quizFinished = () => conflict('This attempt has already been handed in.', 'QUIZ_FINISHED');

export interface Finished {
  attempt: AttemptRow;
  /** True for the one call that finished the session. */
  finishedNow: boolean;
  answersAccepted: boolean;
  row: SessionRow;
}

/** Called for every session the mock finishes with a pass, so the lesson completes as the API completes it. */
let passedHook: ((quizId: string, studentId: string, finished: Finished) => void) | null = null;
export const onQuizPassed = (hook: typeof passedHook) => {
  passedHook = hook;
};

const ofLearner = (quizId: string, studentId: string) => sessions.filter((s) => s.quizId === quizId && s.studentId === studentId);
const attemptsOf = (quizId: string, studentId: string) =>
  attempts.filter((a) => a.quizId === quizId && a.studentId === studentId).sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

export function sessionView(row: SessionRow, now = mockNow()): QuizSessionView {
  return {
    id: row.id,
    quizId: row.quizId,
    attemptNo: row.attemptNo,
    status: row.status,
    startedAt: row.startedAt.toISOString(),
    deadlineAt: row.deadlineAt?.toISOString(),
    serverNow: now.toISOString(),
    remainingSec: row.status === 'active' ? remainingSec(row.deadlineAt, now) : row.deadlineAt ? 0 : undefined,
    answers: structuredClone(row.answers),
    answersSeq: row.answersSeq,
    savedAt: row.savedAt?.toISOString(),
    finishedAt: row.finishedAt?.toISOString(),
    ...(row.status !== 'active' ? { attemptId: attempts.find((a) => a.sessionId === row.id)?.id } : {}),
  };
}

const sessionQuestions = (row: SessionRow): LearnerQuizQuestion[] => inSessionOrder(row.questions.map(learnerQuestion), row.order);

/** Finishes a session: by the learner (`submit`) or by the server at the deadline (`expire`). Safe to repeat. */
export function finishSession(sessionId: string, mode: 'submit' | 'expire', final?: { answers: QuizAnswers; seq: number }, now = mockNow()): Finished {
  const row = sessions.find((s) => s.id === sessionId);
  if (!row) throw new ServiceError('Attempt not found.', 'not-found', undefined, undefined, 404);
  if (row.status !== 'active') {
    const attempt = attempts.find((a) => a.sessionId === row.id)!;
    return { attempt, finishedNow: false, answersAccepted: false, row };
  }
  const window = deadlineWindow(row.deadlineAt, now);
  if (mode === 'expire' && window !== 'closed') throw conflict('This attempt is still open.');
  let answersAccepted = false;
  // A final sheet counts only if it arrives by the deadline — the grace is for delivering what was already stored.
  if (final && window === 'open' && final.seq > row.answersSeq) {
    row.answers = acceptAnswers(row.questions, {}, final.answers);
    row.answersSeq = final.seq;
    row.savedAt = now;
    answersAccepted = true;
  }
  row.status = mode === 'submit' && window !== 'closed' ? 'submitted' : 'expired';
  row.finishedAt = now;
  const result = scoreAttempt({ questions: row.questions, settings: row.settings }, row.answers);
  // Time taken by the server's clock, up to the deadline at most.
  const end = row.deadlineAt && now > row.deadlineAt ? row.deadlineAt : now;
  const attempt: AttemptRow = {
    id: nextId('att'),
    quizId: row.quizId,
    studentId: row.studentId,
    sessionId: row.id,
    createdAt: now,
    percent: result.percent,
    passed: result.passed,
    answers: structuredClone(row.answers),
    result,
    durationSec: Math.max(0, Math.round((end.getTime() - row.startedAt.getTime()) / 1000)),
  };
  attempts.push(attempt);
  const finished = { attempt, finishedNow: true, answersAccepted, row };
  if (result.passed) passedHook?.(row.quizId, row.studentId, finished);
  return finished;
}

/** Finishes every open session past its deadline and the grace, as the API's every-minute job does. */
export function settleOverdue(where: { quizId?: string; studentId?: string } = {}, now = mockNow()) {
  const cutoff = now.getTime() - QUIZ_SUBMIT_GRACE_SEC * 1000;
  for (const s of sessions) {
    if (s.status !== 'active' || !s.deadlineAt || s.deadlineAt.getTime() >= cutoff) continue;
    if ((where.quizId && s.quizId !== where.quizId) || (where.studentId && s.studentId !== where.studentId)) continue;
    finishSession(s.id, 'expire', undefined, now);
  }
}

/** Starts the learner's next attempt, or picks up the one still open. */
export function startSession(quiz: Quiz, studentId: string, startKey?: string, now = mockNow()): QuizSessionStart {
  if (quiz.status !== 'published') throw new ServiceError('This quiz is not available yet.', 'not-found', undefined, undefined, 404);
  settleOverdue({ quizId: quiz.id, studentId }, now);
  const mine = ofLearner(quiz.id, studentId).sort((a, b) => a.attemptNo - b.attemptNo);
  const same = startKey ? mine.find((s) => s.startKey === startKey) : undefined;
  const open = same ?? mine.find((s) => s.status === 'active' && deadlineWindow(s.deadlineAt, now) === 'open');
  if (open) return { session: sessionView(open, now), questions: open.status === 'active' ? sessionQuestions(open) : [], resumed: true };
  if (mine.some((s) => s.status === 'active')) throw conflict('Your last attempt is still being handed in. Try again in a minute.');
  const window = quizWindow(quiz.settings, now);
  if (window === 'upcoming') throw new ServiceError('This quiz has not opened yet.', 'conflict', 'TEST_NOT_OPEN', undefined, 409);
  if (window === 'closed') throw new ServiceError('This quiz has closed.', 'conflict', 'TEST_CLOSED', undefined, 409);
  const rules = mockLearningRules();
  const taken = attemptsOf(quiz.id, studentId);
  const used = attemptsUsed(mine, taken);
  if (!taken.some((a) => a.passed)) {
    const limit = quiz.settings.attempts ?? rules.quizAttempts;
    if (limit > 0 && used >= limit) throw conflict(`You have used all ${limit} attempts for this quiz.`);
    const wait = retakeWait(taken[0], rules.retakeWaitHours, now);
    if (wait) throw conflict(wait);
  }
  if (!quiz.questions.length) throw conflict('This quiz has no questions yet.');
  const row: SessionRow = {
    id: nextId('qs'),
    quizId: quiz.id,
    studentId,
    attemptNo: used + 1,
    status: 'active',
    startedAt: now,
    deadlineAt: sessionDeadline(now, quiz.settings),
    questions: structuredClone(quiz.questions),
    settings: structuredClone(quiz.settings),
    order: sessionOrder(quiz.questions, quiz.settings, Math.random),
    answers: {},
    answersSeq: 0,
    startKey,
  };
  sessions.push(row);
  return { session: sessionView(row, now), questions: sessionQuestions(row), resumed: false };
}

function retakeWait(last: AttemptRow | undefined, hours: number, now: Date) {
  if (!last || hours <= 0) return undefined;
  const readyAt = last.createdAt.getTime() + hours * 3_600_000;
  if (now.getTime() >= readyAt) return undefined;
  const left = Math.ceil((readyAt - now.getTime()) / 3_600_000);
  return `You can try this quiz again in ${left} hour${left === 1 ? '' : 's'}.`;
}

/** The learner's latest session: the open one with its questions, a finished one without. */
export function latestSession(quiz: Quiz, studentId: string, now = mockNow()) {
  settleOverdue({ quizId: quiz.id, studentId }, now);
  const row = ofLearner(quiz.id, studentId).sort((a, b) => b.attemptNo - a.attemptNo)[0];
  return { session: row ? sessionView(row, now) : null, questions: row?.status === 'active' ? sessionQuestions(row) : [] };
}

/** The learner's own session at this quiz, or "not found" — another learner's is never confirmed to exist. */
function ownSession(sessionId: string, quizId: string, studentId: string) {
  const row = sessions.find((s) => s.id === sessionId && s.quizId === quizId && s.studentId === studentId);
  if (!row) throw new ServiceError('Attempt not found.', 'not-found', undefined, undefined, 404);
  return row;
}

/** Autosave: stored only while the session is open, before its deadline, and with a number above the stored one. */
export function saveAnswers(quiz: Quiz, sessionId: string, studentId: string, answers: QuizAnswers, seq: number, now = mockNow()): QuizSessionView {
  if (!Number.isInteger(seq) || seq < 1)
    throw new ServiceError('The save number must be a whole number from 1.', 'conflict', 'VALIDATION_FAILED', undefined, 400);
  const row = ownSession(sessionId, quiz.id, studentId);
  if (row.status !== 'active') throw quizFinished();
  if (deadlineWindow(row.deadlineAt, now) !== 'open') throw quizTimeUp();
  if (seq > row.answersSeq) {
    row.answers = acceptAnswers(row.questions, {}, answers);
    row.answersSeq = seq;
    row.savedAt = now;
  }
  return sessionView(row, now);
}

/** Hands the attempt in. Answers with the same result however often it is repeated. */
export function submitSession(
  quiz: Quiz,
  sessionId: string,
  studentId: string,
  enrollment: { status: string },
  final?: { answers: QuizAnswers; seq: number },
  now = mockNow(),
) {
  ownSession(sessionId, quiz.id, studentId);
  const finished = finishSession(sessionId, 'submit', final, now);
  const { attempts: reviews, standing } = quizStanding(quiz, studentId, enrollment, now);
  return {
    finished,
    session: { ...sessionView(finished.row, now), attemptId: finished.attempt.id },
    answersAccepted: finished.answersAccepted,
    review: reviews.find((r) => r.attemptId === finished.attempt.id) ?? null,
    standing,
  };
}

/** Where the learner stands with a quiz, and their attempts cut to what they may see — the API's `quizStanding`. */
export function quizStanding(quiz: Quiz, studentId: string, enrollment: { status: string }, now = mockNow()): QuizAttemptsView {
  settleOverdue({ quizId: quiz.id, studentId }, now);
  const rules = mockLearningRules();
  const settings = quiz.settings;
  const mine = ofLearner(quiz.id, studentId).sort((a, b) => b.attemptNo - a.attemptNo);
  const taken = attemptsOf(quiz.id, studentId);
  const limit = settings.attempts ?? rules.quizAttempts;
  const used = attemptsUsed(mine, taken);
  const passed = taken.some((a) => a.passed);
  const open = mine.find((s) => s.status === 'active');
  const window = quizWindow(settings, now);
  const out = resultsOut(settings, now);

  let blockedReason: string | undefined;
  // A paused or ended place refuses a resume as much as a new start.
  if (enrollment.status === 'expired') blockedReason = 'Your access to this course has ended.';
  else if (enrollment.status === 'paused') blockedReason = ENROLMENT_PAUSED;
  else if (!open) {
    if (quiz.status !== 'published') blockedReason = 'This quiz is no longer open for attempts.';
    else if (window === 'upcoming') blockedReason = 'This quiz has not opened yet.';
    else if (window === 'closed') blockedReason = 'This quiz has closed.';
    else if (!quiz.questions.length) blockedReason = 'This quiz has no questions yet.';
    else if (!passed && limit > 0 && used >= limit) blockedReason = `You have used all ${limit} attempts for this quiz.`;
    else if (!passed) blockedReason = retakeWait(taken[0], rules.retakeWaitHours, now);
  }

  const keyWithheld = Boolean(open) || (!passed && (limit === 0 || used < limit) && window !== 'closed' && quiz.status === 'published');
  const visibility = resultsVisibilityOf(settings.showResults);
  const shown: QuizSettings = !out
    ? { ...settings, showResults: 'hidden' }
    : keyWithheld && visibility === 'score-and-answers'
      ? { ...settings, showResults: 'score-only' }
      : settings;
  const reviews: AttemptReview[] = taken.map((a) => {
    const session = mine.find((s) => s.id === a.sessionId);
    const review = reviewAttempt(
      { questions: session?.questions ?? quiz.questions, settings: shown },
      { id: a.id, submittedAt: a.createdAt.toISOString(), result: a.result, answers: a.answers },
    );
    return {
      ...review,
      attemptNo: session?.attemptNo,
      finish: session?.status === 'expired' ? 'expired' : 'submitted',
      ...(keyWithheld && out && visibility === 'score-and-answers' ? { keyWithheld: true } : {}),
      ...(!out && settings.closesAt ? { resultsAt: settings.closesAt } : {}),
    };
  });
  const standing: QuizStanding = {
    quizId: quiz.id,
    serverNow: now.toISOString(),
    window,
    ...(settings.opensAt ? { opensAt: settings.opensAt } : {}),
    ...(settings.closesAt ? { closesAt: settings.closesAt } : {}),
    attemptsAllowed: limit,
    attemptsUsed: used,
    passed,
    ...(open ? { openSession: sessionView(open, now) } : {}),
    canStart: !blockedReason,
    ...(blockedReason ? { blockedReason } : {}),
    ...(!out && settings.closesAt ? { resultsAt: settings.closesAt } : {}),
  };
  return { attempts: reviews, standing };
}

/** Attempts used, and the attempt open, for the lesson and the tests list. */
export function learnerQuizState(quizId: string, studentId: string) {
  const mine = ofLearner(quizId, studentId);
  const taken = attemptsOf(quizId, studentId);
  return {
    used: attemptsUsed(mine, taken),
    open: mine.find((s) => s.status === 'active'),
    taken,
    best: taken.length ? Math.max(...taken.map((a) => a.percent)) : undefined,
    passed: taken.some((a) => a.passed),
  };
}

/** Whether anyone has started the quiz — a quiz that has been taken is archived, never deleted. */
export const quizTaken = (quizId: string) => sessions.some((s) => s.quizId === quizId) || attempts.some((a) => a.quizId === quizId);

/** Every attempt at the quiz for staff, newest first — the API's `GET /quizzes/:id/attempts`. */
export function attemptRows(quizId: string, now = mockNow()): QuizAttemptRow[] {
  settleOverdue({ quizId }, now);
  const learner = (studentId: string) => {
    const s = students.find((x) => x.id === studentId);
    return { studentId, name: s?.name ?? 'Learner', email: s?.email ?? '' };
  };
  return sessions
    .filter((s) => s.quizId === quizId)
    .map((s) => {
      const a = attempts.find((x) => x.sessionId === s.id);
      return {
        ...learner(s.studentId),
        attemptId: a?.id,
        sessionId: s.id,
        attemptNo: s.attemptNo,
        status: s.status,
        startedAt: s.startedAt.toISOString(),
        deadlineAt: s.deadlineAt?.toISOString(),
        submittedAt: (s.finishedAt ?? a?.createdAt)?.toISOString(),
        percent: a?.percent,
        passed: a?.passed,
        durationSec: a?.durationSec,
      };
    })
    .sort((x, y) => (y.submittedAt ?? y.startedAt ?? '').localeCompare(x.submittedAt ?? x.startedAt ?? ''));
}
