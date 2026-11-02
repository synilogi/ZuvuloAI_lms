import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { QuizAnswers, QuizSessionView } from '@syniastrolms/domain';

import { ServiceError } from '@/services/contracts';
import { AnswerSaver, backoffMs, isTransient, sameAnswer, unsavedQuestions, type SaveState } from './answerSaver';

/* Autosave sends the whole sheet with a number that only grows, calls an answer "saved" only once the server says it
 * holds it, ignores answers older than one already applied, and retries what failed. */

const session = (over: Partial<QuizSessionView> = {}): QuizSessionView => ({
  id: 's1',
  quizId: 'q',
  attemptNo: 1,
  status: 'active',
  startedAt: '2026-10-26T07:46:37.229Z',
  serverNow: '2026-10-26T07:46:37.236Z',
  answers: {},
  answersSeq: 0,
  ...over,
});

/** A save the test answers by hand. */
function deferredSaves() {
  const calls: { answers: QuizAnswers; seq: number; resolve: (v: QuizSessionView) => void; reject: (e: unknown) => void }[] = [];
  const save = (answers: QuizAnswers, seq: number) =>
    new Promise<QuizSessionView>((resolve, reject) => {
      calls.push({ answers, seq, resolve, reject });
    });
  return { calls, save };
}

/** What the server would answer after storing `seq` (or keeping a higher one). */
const stored = (answers: QuizAnswers, seq: number) => session({ answers, answersSeq: seq, savedAt: '2026-10-26T07:47:00.000Z' });

function setup(initial = session()) {
  const { calls, save } = deferredSaves();
  const states: SaveState[] = [];
  const closed: string[] = [];
  const saver = new AnswerSaver({ session: initial, save, onChange: (s) => states.push(s.state), onClosed: (r) => closed.push(r), debounceMs: 800 });
  return { saver, calls, states, closed };
}

const flush = () => vi.advanceTimersByTimeAsync(0);

describe('answer autosave', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('waits for a pause, sends the whole sheet numbered from the session’s, and says saved only once the server holds it', async () => {
    const { saver, calls } = setup(session({ answers: { q1: ['a'] }, answersSeq: 4 }));
    saver.change({ q1: ['a'], q2: ['true'] });
    saver.change({ q1: ['b'], q2: ['true'] });
    expect(saver.snapshot.state).toBe('pending');
    await vi.advanceTimersByTimeAsync(799);
    expect(calls).toHaveLength(0);
    await vi.advanceTimersByTimeAsync(1);
    expect(calls).toHaveLength(1);
    expect(calls[0]).toMatchObject({ answers: { q1: ['b'], q2: ['true'] }, seq: 5 });
    expect(saver.snapshot.state).toBe('saving');
    expect(saver.unsaved).toBe(true);
    calls[0].resolve(stored(calls[0].answers, 5));
    await flush();
    expect(saver.snapshot).toMatchObject({ state: 'saved', savedSeq: 5, saved: { q1: ['b'], q2: ['true'] } });
    expect(saver.unsaved).toBe(false);
  });

  it('keeps one save in flight and sends the latest sheet after it, with a higher number', async () => {
    const { saver, calls } = setup();
    saver.change({ q1: ['a'] });
    await vi.advanceTimersByTimeAsync(800);
    saver.change({ q1: ['c'] });
    await vi.advanceTimersByTimeAsync(2000);
    expect(calls).toHaveLength(1);
    calls[0].resolve(stored({ q1: ['a'] }, 1));
    await flush();
    // The first is saved, but the change made meanwhile is not: still not "saved".
    expect(saver.snapshot.state).toBe('pending');
    await vi.advanceTimersByTimeAsync(800);
    expect(calls[1]).toMatchObject({ answers: { q1: ['c'] }, seq: 2 });
    calls[1].resolve(stored({ q1: ['c'] }, 2));
    await flush();
    expect(saver.snapshot).toMatchObject({ state: 'saved', savedSeq: 2 });
  });

  it('ignores an answer older than one already applied', async () => {
    const { saver, calls } = setup();
    saver.change({ q1: ['a'] });
    await vi.advanceTimersByTimeAsync(800);
    // The server already holds number 3 (another tab saved it): our 1 was ignored and it answers with its own sheet.
    calls[0].resolve(stored({ q1: ['z'] }, 3));
    await flush();
    expect(saver.snapshot).toMatchObject({ savedSeq: 3, saved: { q1: ['z'] } });
    // Ours was not kept, so it goes again — above the number the server holds.
    expect(saver.unsaved).toBe(true);
    await flush();
    expect(calls[1]).toMatchObject({ answers: { q1: ['a'] }, seq: 4 });
    calls[1].resolve(stored({ q1: ['a'] }, 4));
    await flush();
    expect(saver.snapshot).toMatchObject({ state: 'saved', savedSeq: 4, saved: { q1: ['a'] } });
  });

  it('never lets a late answer with a lower number replace the sheet it holds', async () => {
    const { saver, calls } = setup();
    saver.change({ q1: ['a'] });
    await vi.advanceTimersByTimeAsync(800);
    calls[0].resolve(stored({ q1: ['a'] }, 7));
    await flush();
    saver.change({ q1: ['b'] });
    await vi.advanceTimersByTimeAsync(800);
    // A stale echo of an old save arrives for the second request.
    calls[1].resolve(stored({ q1: ['old'] }, 2));
    await flush();
    expect(saver.snapshot.saved).toEqual({ q1: ['a'] });
    expect(saver.snapshot.savedSeq).toBe(7);
    expect(saver.unsaved).toBe(true);
  });

  it('retries a dropped connection with a growing wait, and at once when asked', async () => {
    const { saver, calls } = setup();
    saver.change({ q1: ['a'] });
    await vi.advanceTimersByTimeAsync(800);
    calls[0].reject(new ServiceError('Could not reach the server.', 'network'));
    await flush();
    expect(saver.snapshot).toMatchObject({ state: 'retrying', retryInMs: 1000 });
    await vi.advanceTimersByTimeAsync(1000);
    expect(calls).toHaveLength(2);
    calls[1].reject(new ServiceError('Something went wrong.', 'unknown', undefined, undefined, 503));
    await flush();
    expect(saver.snapshot).toMatchObject({ state: 'retrying', retryInMs: 2000 });
    // Back online: no waiting.
    saver.retry();
    await flush();
    expect(calls).toHaveLength(3);
    expect(calls[2].seq).toBeGreaterThan(calls[1].seq);
    calls[2].resolve(stored({ q1: ['a'] }, calls[2].seq));
    await flush();
    expect(saver.snapshot.state).toBe('saved');
  });

  it('stops at a refusal it cannot fix by itself, until the learner tries again', async () => {
    const { saver, calls } = setup();
    saver.change({ q1: ['a'] });
    await vi.advanceTimersByTimeAsync(800);
    calls[0].reject(new ServiceError('Your place in this course is paused.', 'conflict', undefined, undefined, 409));
    await flush();
    expect(saver.snapshot).toMatchObject({ state: 'failed', error: 'Your place in this course is paused.' });
    await vi.advanceTimersByTimeAsync(60_000);
    expect(calls).toHaveLength(1);
    saver.retry();
    await flush();
    expect(calls).toHaveLength(2);
  });

  it('stops for good when time is up or the attempt was handed in', async () => {
    for (const [reason, expected] of [
      ['QUIZ_TIME_UP', 'time-up'],
      ['QUIZ_FINISHED', 'finished'],
    ] as const) {
      const { saver, calls, closed } = setup();
      saver.change({ q1: ['a'] });
      await vi.advanceTimersByTimeAsync(800);
      calls[0].reject(new ServiceError('No.', 'conflict', reason, undefined, 409));
      await flush();
      expect(saver.snapshot.state).toBe('closed');
      expect(closed).toEqual([expected]);
      saver.change({ q1: ['b'] });
      await vi.advanceTimersByTimeAsync(5000);
      expect(calls).toHaveLength(1);
    }
  });

  it('gives a final sheet a number above every save, and saves nothing after it', async () => {
    const { saver, calls } = setup(session({ answersSeq: 9 }));
    saver.change({ q1: ['a'] });
    await vi.advanceTimersByTimeAsync(800);
    saver.change({ q1: ['b'] });
    expect(saver.takeFinalSeq()).toBe(11);
    calls[0].resolve(stored({ q1: ['a'] }, 10));
    await vi.advanceTimersByTimeAsync(5000);
    expect(calls).toHaveLength(1);
  });
});

describe('what counts as saved', () => {
  it('compares answers as the server stores them', () => {
    expect(sameAnswer(['a', 'b'], ['b', 'a'])).toBe(true);
    expect(sameAnswer('', undefined)).toBe(true);
    expect(sameAnswer([], undefined)).toBe(true);
    expect(sameAnswer('75%', '75%')).toBe(true);
    expect(sameAnswer('75', '75%')).toBe(false);
    expect(unsavedQuestions({ q1: ['a'], q2: '75%', q3: [] }, { q1: ['a'], q2: '75' })).toEqual(['q2']);
    // A cleared answer the server still holds is not saved yet.
    expect(unsavedQuestions({ q1: [] }, { q1: ['a'] })).toEqual(['q1']);
  });

  it('treats a dropped connection or a failing server as worth retrying, and a refusal as not', () => {
    expect(isTransient(new ServiceError('x', 'network'))).toBe(true);
    expect(isTransient(new ServiceError('x', 'unknown', undefined, undefined, 502))).toBe(true);
    expect(isTransient(new ServiceError('x', 'conflict', undefined, undefined, 409))).toBe(false);
    expect(isTransient(new ServiceError('x', 'not-found', undefined, undefined, 404))).toBe(false);
    expect([1, 2, 3, 4, 5, 6, 7].map(backoffMs)).toEqual([1000, 2000, 4000, 8000, 16000, 30000, 30000]);
  });
});
