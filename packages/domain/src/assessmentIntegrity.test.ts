import { describe, expect, it } from 'vitest';

import { countWords, validateSubmission } from './assignment';
import { learnerQuiz, resultsVisibilityOf, reviewAttempt, scoreAttempt, type Quiz, type QuizAnswers } from './quiz';

const quiz: Quiz = {
  id: 'q1',
  courseId: 'c1',
  title: 'Nakshatras',
  instructions: '',
  status: 'published',
  createdAt: '2026-09-01T00:00:00.000Z',
  updatedAt: '2026-09-01T00:00:00.000Z',
  settings: { passMark: 50, attempts: 3, shuffleQuestions: false, shuffleOptions: false, showResults: 'score-and-answers' },
  questions: [
    {
      id: 'a',
      type: 'single',
      prompt: 'How many nakshatras?',
      options: [
        { id: 'a1', text: '12' },
        { id: 'a2', text: '27' },
      ],
      correct: ['a2'],
      acceptedAnswers: [],
      points: 1,
      explanation: 'Twenty-seven lunar mansions.',
      required: true,
    },
    { id: 'b', type: 'short', prompt: 'The first nakshatra?', options: [], correct: [], acceptedAnswers: ['Ashwini', ' '], points: 1, required: true },
  ],
};
const answers: QuizAnswers = { a: ['a1'], b: 'ashwini' };
const attempt = { id: 'att1', submittedAt: '2026-09-02T00:00:00.000Z', result: scoreAttempt(quiz, answers), answers };

describe('a learner never receives the answer key', () => {
  it('keeps only what is needed to answer', () => {
    const safe = learnerQuiz(quiz);
    const text = JSON.stringify(safe);
    expect(text).not.toMatch(/"correct"|"acceptedAnswers"|"explanation"/);
    expect(safe.questions[0]).toEqual({
      id: 'a',
      type: 'single',
      prompt: 'How many nakshatras?',
      options: quiz.questions[0].options,
      points: 1,
      required: true,
    });
    expect(safe.settings).toEqual(quiz.settings);
  });
});

describe('an attempt is reviewed as the quiz allows', () => {
  it('shows answers and explanations only for score-and-answers', () => {
    const review = reviewAttempt(quiz, attempt);
    expect(review).toMatchObject({ passed: true, percent: 50, points: 1, max: 2, passMark: 50, showResults: 'score-and-answers' });
    expect(review.questions?.a).toEqual({ state: 'incorrect', points: 0, answer: ['a1'], correct: ['a2'], explanation: 'Twenty-seven lunar mansions.' });
    expect(review.questions?.b).toEqual({ state: 'correct', points: 1, answer: 'ashwini', acceptedAnswers: ['Ashwini'] });
  });

  it('gives the score but no question detail for score-only', () => {
    const review = reviewAttempt({ ...quiz, settings: { ...quiz.settings, showResults: 'score-only' } }, attempt);
    expect(review).toMatchObject({ percent: 50, passed: true });
    expect(review.questions).toBeUndefined();
    expect(JSON.stringify(review)).not.toMatch(/correct"|acceptedAnswers|explanation/);
  });

  it('says only that it was received, for hidden — and reads the API’s older word for it', () => {
    for (const showResults of ['hidden', 'nothing']) {
      const review = reviewAttempt({ ...quiz, settings: { ...quiz.settings, showResults: showResults as 'hidden' } }, attempt);
      expect(review).toEqual({ attemptId: 'att1', submittedAt: attempt.submittedAt, showResults: 'hidden', passed: true });
    }
    expect(resultsVisibilityOf(undefined)).toBe('score-and-answers');
  });
});

describe('a hand-in fits its assignment', () => {
  const long = Array.from({ length: 60 }, () => 'word').join(' ');
  it('counts words as a reader does', () => {
    expect(countWords('  one two\nthree  ')).toBe(3);
    expect(countWords('')).toBe(0);
  });

  it('holds written work to text within its word limit', () => {
    expect(validateSubmission({ format: 'text', wordLimit: 50 }, { text: long, files: [] }).map((i) => i.field)).toEqual(['text']);
    expect(validateSubmission({ format: 'text' }, { text: '', files: [] })).toHaveLength(1);
    expect(validateSubmission({ format: 'text' }, { text: 'An answer.', files: [{}] }).map((i) => i.field)).toEqual(['files']);
    expect(validateSubmission({ format: 'text', wordLimit: 100 }, { text: long, files: [] })).toEqual([]);
  });

  it('needs one to three files for a file hand-in, and lets its note run long', () => {
    expect(validateSubmission({ format: 'file', wordLimit: 50 }, { text: long, files: [{}] })).toEqual([]);
    expect(validateSubmission({ format: 'file' }, { text: 'note', files: [] })).toHaveLength(1);
    expect(validateSubmission({ format: 'file' }, { text: '', files: [{}, {}, {}, {}] })).toHaveLength(1);
  });

  it('needs a chart for a chart hand-in, and refuses one anywhere else', () => {
    expect(validateSubmission({ format: 'chart' }, { text: 'reading', files: [] }).map((i) => i.field)).toEqual(['chart']);
    expect(validateSubmission({ format: 'chart' }, { text: 'reading', files: [], chart: {} })).toEqual([]);
    expect(validateSubmission({ format: 'text' }, { text: 'reading', files: [], chart: {} }).map((i) => i.field)).toEqual(['chart']);
  });
});
