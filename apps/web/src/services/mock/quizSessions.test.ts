import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import type { Quiz } from '@syniastrolms/domain';
import { defaultQuizSettings } from '@syniastrolms/domain';
import { mockNow } from './clock';
import { attemptRows, finishSession, latestSession, quizStanding, quizTaken, saveAnswers, startSession, submitSession } from './quizSessions';

/* The mock's quiz sessions keep the API's rules: a start consumes an attempt and fixes the deadline, saves are taken
 * in number order and only before it, a submission is idempotent, and the key stays withheld while the quiz can
 * still be taken for credit. */

const ACTIVE = { status: 'active' };
let serial = 0;

function quiz(over: Partial<Quiz['settings']> = {}, status: Quiz['status'] = 'published'): Quiz {
  serial += 1;
  return {
    id: `quiz-test-${serial}`,
    courseId: 'c',
    title: 'Integers check',
    instructions: '',
    status,
    questions: [
      {
        id: 'q1',
        type: 'single',
        prompt: '(−3) × (−4)?',
        options: [
          { id: 'a', text: '12' },
          { id: 'b', text: '−12' },
        ],
        correct: ['a'],
        acceptedAnswers: [],
        points: 10,
        required: true,
        explanation: 'Like signs give a positive.',
      },
      {
        id: 'q2',
        type: 'short',
        prompt: '3/4 as a percentage',
        options: [],
        correct: [],
        acceptedAnswers: ['75%'],
        points: 10,
        required: true,
        negativePoints: 2,
      },
    ],
    settings: { ...defaultQuizSettings, attempts: 2, shuffleOptions: false, ...over },
    createdAt: '2026-09-01T10:00:00+05:30',
    updatedAt: '2026-09-01T10:00:00+05:30',
  };
}

describe('mock quiz sessions', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('starts an attempt with its questions and no key, and resumes it instead of starting another', () => {
    const q = quiz({ timeLimitMin: 15 });
    const first = startSession(q, 'learner-1', 'key-aaaaaaaa');
    expect(first.resumed).toBe(false);
    expect(first.session).toMatchObject({ attemptNo: 1, status: 'active', answersSeq: 0, remainingSec: 900 });
    expect(JSON.stringify(first.questions)).not.toMatch(/"correct"|"acceptedAnswers"|"explanation"/);
    expect(first.questions[1].negativePoints).toBe(2);
    // The same press retried, or a fresh press while it is open: the same attempt, not a second one.
    expect(startSession(q, 'learner-1', 'key-aaaaaaaa').session.id).toBe(first.session.id);
    expect(startSession(q, 'learner-1', 'key-bbbbbbbb')).toMatchObject({ resumed: true, session: { id: first.session.id } });
    expect(quizStanding(q, 'learner-1', ACTIVE).standing).toMatchObject({ attemptsUsed: 1, canStart: true, openSession: { id: first.session.id } });
  });

  it('takes saves in number order, only before the deadline', () => {
    const q = quiz({ timeLimitMin: 1 });
    const { session } = startSession(q, 'learner-2');
    expect(saveAnswers(q, session.id, 'learner-2', { q1: ['b'] }, 2)).toMatchObject({ answersSeq: 2, answers: { q1: ['b'] } });
    // A late save with a lower number changes nothing; the stored sheet comes back.
    expect(saveAnswers(q, session.id, 'learner-2', { q1: ['a'] }, 1)).toMatchObject({ answersSeq: 2, answers: { q1: ['b'] } });
    // Answers to questions it does not hold, or in the wrong shape, are dropped.
    expect(saveAnswers(q, session.id, 'learner-2', { q1: ['zz'], q9: ['a'], q2: '75%' }, 3).answers).toEqual({ q2: '75%' });
    expect(() => saveAnswers(q, session.id, 'someone-else', { q1: ['a'] }, 4)).toThrow(expect.objectContaining({ code: 'not-found' }));
    vi.advanceTimersByTime(61_000);
    expect(() => saveAnswers(q, session.id, 'learner-2', { q1: ['a'] }, 4)).toThrow(expect.objectContaining({ reason: 'QUIZ_TIME_UP' }));
    // In the grace a submission still counts as handed in, but brings only what was stored.
    const done = submitSession(q, session.id, 'learner-2', ACTIVE, { answers: { q1: ['a'], q2: '75%' }, seq: 9 });
    expect(done).toMatchObject({ answersAccepted: false, session: { status: 'submitted', answersSeq: 3 } });
    expect(done.review).toMatchObject({ points: 10, max: 20, percent: 50, finish: 'submitted' });
    expect(() => saveAnswers(q, session.id, 'learner-2', { q1: ['a'] }, 10)).toThrow(expect.objectContaining({ reason: 'QUIZ_FINISHED' }));
  });

  it('finishes an attempt left past the grace as expired, scored on what it stored', () => {
    const q = quiz({ timeLimitMin: 2 });
    const { session } = startSession(q, 'learner-3');
    saveAnswers(q, session.id, 'learner-3', { q1: ['a'], q2: '80%' }, 1);
    vi.advanceTimersByTime(2 * 60_000 + 61_000);
    const latest = latestSession(q, 'learner-3');
    expect(latest).toMatchObject({ session: { status: 'expired', remainingSec: 0 }, questions: [] });
    const [review] = quizStanding(q, 'learner-3', ACTIVE).attempts;
    // A wrong short answer loses its negative marks; the total may fall, the percentage never below 0.
    expect(review).toMatchObject({ finish: 'expired', points: 8, percent: 40, attemptNo: 1 });
  });

  it('hands an attempt in once, however often it is submitted', () => {
    const q = quiz();
    const { session } = startSession(q, 'learner-4');
    const first = submitSession(q, session.id, 'learner-4', ACTIVE, { answers: { q1: ['a'] }, seq: 1 });
    const again = submitSession(q, session.id, 'learner-4', ACTIVE, { answers: { q1: ['b'] }, seq: 2 });
    expect(first.answersAccepted).toBe(true);
    expect(again.answersAccepted).toBe(false);
    expect(again.review?.attemptId).toBe(first.review?.attemptId);
    expect(quizStanding(q, 'learner-4', ACTIVE).attempts).toHaveLength(1);
    expect(finishSession(session.id, 'submit').finishedNow).toBe(false);
  });

  it('withholds the key while the quiz can still be taken for credit, and stops at the attempt limit', () => {
    const q = quiz({ attempts: 2 });
    const one = startSession(q, 'learner-5');
    const failed = submitSession(q, one.session.id, 'learner-5', ACTIVE, { answers: { q1: ['b'] }, seq: 1 });
    expect(failed.review).toMatchObject({ showResults: 'score-only', keyWithheld: true, passed: false });
    expect(failed.review?.questions).toBeUndefined();
    // The academy's retake wait applies between attempts; past it, the second (and last) attempt may start.
    expect(failed.standing).toMatchObject({ canStart: false, blockedReason: expect.stringMatching(/try this quiz again in/) });
    vi.advanceTimersByTime(49 * 3_600_000);
    const two = startSession(q, 'learner-5');
    expect(two.session.attemptNo).toBe(2);
    const last = submitSession(q, two.session.id, 'learner-5', ACTIVE, { answers: { q1: ['b'] }, seq: 1 });
    // No attempt left: the answers are shown now.
    expect(last.review).toMatchObject({ showResults: 'score-and-answers', passed: false });
    expect(last.review?.keyWithheld).toBeUndefined();
    expect(last.review?.questions?.q1).toMatchObject({ correct: ['a'], explanation: 'Like signs give a positive.' });
    expect(last.standing).toMatchObject({ canStart: false, blockedReason: 'You have used all 2 attempts for this quiz.' });
    expect(() => startSession(q, 'learner-5')).toThrow(expect.objectContaining({ code: 'conflict', message: 'You have used all 2 attempts for this quiz.' }));
  });

  it('keeps to the quiz’s window, and holds results until it closes when asked to', () => {
    const now = mockNow().getTime();
    const later = quiz({ opensAt: new Date(now + 3_600_000).toISOString() });
    expect(quizStanding(later, 'learner-6', ACTIVE).standing).toMatchObject({
      window: 'upcoming',
      canStart: false,
      blockedReason: 'This quiz has not opened yet.',
    });
    expect(() => startSession(later, 'learner-6')).toThrow(expect.objectContaining({ reason: 'TEST_NOT_OPEN' }));

    const closesAt = new Date(now + 600_000).toISOString();
    const held = quiz({ timeLimitMin: 30, closesAt, resultsRelease: 'after-close' });
    const { session } = startSession(held, 'learner-6');
    // The deadline is cut to the close.
    expect(session.deadlineAt).toBe(closesAt);
    const done = submitSession(held, session.id, 'learner-6', ACTIVE, { answers: { q1: ['a'] }, seq: 1 });
    expect(done.review).toMatchObject({ showResults: 'hidden', resultsAt: closesAt });
    expect(done.review?.percent).toBeUndefined();
    vi.advanceTimersByTime(601_000);
    expect(quizStanding(held, 'learner-6', ACTIVE).attempts[0]).toMatchObject({ percent: 50 });
    expect(() => startSession(held, 'learner-6')).toThrow(expect.objectContaining({ reason: 'TEST_CLOSED' }));
  });

  it('refuses to resume or start on a paused place, and starts nothing on an archived quiz', () => {
    const q = quiz();
    startSession(q, 'learner-7');
    expect(quizStanding(q, 'learner-7', { status: 'paused' }).standing).toMatchObject({ canStart: false, blockedReason: expect.stringMatching(/paused/) });
    const archived = quiz({}, 'archived');
    expect(() => startSession(archived, 'learner-7')).toThrow(expect.objectContaining({ code: 'not-found' }));
    expect(quizStanding(archived, 'learner-7', ACTIVE).standing).toMatchObject({ canStart: false, blockedReason: 'This quiz is no longer open for attempts.' });
  });

  it('lists every attempt for staff, newest first, and marks the quiz as taken', () => {
    const q = quiz({ timeLimitMin: 10 });
    expect(quizTaken(q.id)).toBe(false);
    const a = startSession(q, 'u-ananya');
    submitSession(q, a.session.id, 'u-ananya', ACTIVE, { answers: { q1: ['a'] }, seq: 1 });
    vi.advanceTimersByTime(1000);
    startSession(q, 'learner-8');
    const rows = attemptRows(q.id);
    expect(rows.map((r) => r.status)).toEqual(['active', 'submitted']);
    expect(rows[1]).toMatchObject({ name: 'Ananya Rao', attemptNo: 1, percent: 50, passed: false });
    expect(rows[0].percent).toBeUndefined();
    expect(quizTaken(q.id)).toBe(true);
  });
});
