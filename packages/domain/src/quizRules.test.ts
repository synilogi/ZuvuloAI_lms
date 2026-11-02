import { describe, expect, it } from 'vitest';

import { creditedPercent, defaultQuizSettings, scoreAttempt, validateQuiz, type QuizQuestion } from './quiz';
import { scoreShown } from './quizSession';

const single = (over: Partial<QuizQuestion> = {}): QuizQuestion => ({
  id: 'q1',
  type: 'single',
  prompt: 'Pick one',
  options: [
    { id: 'a', text: 'A' },
    { id: 'b', text: 'B' },
  ],
  correct: ['a'],
  acceptedAnswers: [],
  points: 1,
  required: true,
  ...over,
});
const quiz = (questions: QuizQuestion[], settings: Partial<typeof defaultQuizSettings> = {}) => ({
  title: 'A quiz',
  questions,
  settings: { ...defaultQuizSettings, ...settings },
});
const fields = (q: ReturnType<typeof quiz>) => validateQuiz(q).map((i) => i.field);

describe('validateQuiz', () => {
  it('refuses a quiz with no pass mark, which nobody could ever pass', () => {
    expect(fields(quiz([single()], { passMark: undefined as unknown as number }))).toContain('settings');
    expect(validateQuiz(quiz([single()]))).toEqual([]);
  });

  it('refuses a key that names an answer not on offer, or the same answer twice', () => {
    expect(fields(quiz([single({ correct: ['x'] })]))).toContain('correct');
    const multiple = single({ type: 'multiple', correct: ['a', 'a'] });
    expect(fields(quiz([multiple]))).toContain('correct');
  });

  it('refuses two answers with the same id', () => {
    const twins = single({
      options: [
        { id: 'a', text: 'A' },
        { id: 'a', text: 'Also A' },
      ],
    });
    expect(fields(quiz([twins]))).toContain('options');
  });

  it('checks a true/false key against its two answers', () => {
    const tf = single({
      type: 'true-false',
      options: [
        { id: 'true', text: 'True' },
        { id: 'false', text: 'False' },
      ],
      correct: ['maybe'],
    });
    expect(fields(quiz([tf]))).toContain('correct');
    expect(validateQuiz(quiz([{ ...tf, correct: ['true'] }]))).toEqual([]);
  });

  it('reports a short answer without accepted answers rather than throwing', () => {
    const short = { ...single({ type: 'short', options: [], correct: [] }), acceptedAnswers: undefined } as unknown as QuizQuestion;
    expect(() => validateQuiz(quiz([short]))).not.toThrow();
    expect(fields(quiz([short]))).toContain('answers');
  });
});

describe('scoreAttempt rounding', () => {
  it('rounds the percentage down, so 69.5% neither shows as 70 nor passes a 70% mark', () => {
    const qs = Array.from({ length: 200 }, (_, i) => single({ id: `q${i}` }));
    const answers = Object.fromEntries(qs.slice(0, 139).map((q) => [q.id, ['a']]));
    const result = scoreAttempt(quiz(qs, { passMark: 70 }), answers);
    expect(result.percent).toBe(69);
    expect(result.passed).toBe(false);
  });

  it('does not lose a point to float error', () => {
    const qs = Array.from({ length: 100 }, (_, i) => single({ id: `q${i}` }));
    const answers = Object.fromEntries(qs.slice(0, 29).map((q) => [q.id, ['a']]));
    expect(scoreAttempt(quiz(qs), answers).percent).toBe(29);
  });
});

describe('creditedPercent', () => {
  const at = (day: number) => new Date(Date.UTC(2026, 9, day));
  it('is the best attempt up to the first pass; practice afterwards never raises it', () => {
    expect(
      creditedPercent([
        { percent: 100, passed: true, createdAt: at(5) },
        { percent: 40, passed: false, createdAt: at(1) },
        { percent: 75, passed: true, createdAt: at(2) },
      ]),
    ).toBe(75);
  });
  it('is the best attempt while none has passed, and undefined without attempts', () => {
    expect(
      creditedPercent([
        { percent: 40, passed: false, createdAt: at(1) },
        { percent: 55, passed: false, createdAt: at(2) },
      ]),
    ).toBe(55);
    expect(creditedPercent([])).toBeUndefined();
  });
});

describe('scoreShown', () => {
  const now = new Date('2026-10-28T00:00:00Z');
  it('hides the score when the quiz hides results, or until they are released', () => {
    expect(scoreShown({ showResults: 'hidden' }, now)).toBe(false);
    expect(scoreShown({ showResults: 'score-only', resultsRelease: 'after-close', closesAt: '2026-10-29T00:00:00Z' }, now)).toBe(false);
    expect(scoreShown({ showResults: 'score-only' }, now)).toBe(true);
  });
});
