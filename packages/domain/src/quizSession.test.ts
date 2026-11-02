import { describe, expect, it } from 'vitest';

import { defaultQuizSettings, learnerQuestion, scoreAttempt, validateQuiz, type QuizQuestion } from './quiz';
import {
  QUIZ_SUBMIT_GRACE_SEC,
  acceptAnswers,
  attemptsUsed,
  deadlineWindow,
  inSessionOrder,
  quizDeadline,
  quizWindow,
  remainingSec,
  resultsOut,
  sessionDeadline,
  sessionOrder,
} from './quizSession';

/* A2 — the rules a quiz session keeps on the server: its deadline, the grace for a late-arriving submission, which
 * answers it accepts, how attempts are counted, and the order each learner sees. */

const q = (id: string, type: QuizQuestion['type'], options: string[] = []): QuizQuestion => ({
  id,
  type,
  prompt: id,
  options: options.map((o) => ({ id: o, text: o })),
  correct: options.slice(0, 1),
  acceptedAnswers: type === 'short' ? ['x'] : [],
  points: 1,
  required: true,
});
const questions = [q('q1', 'single', ['a', 'b', 'c']), q('q2', 'multiple', ['a', 'b', 'c']), q('q3', 'true-false', ['true', 'false']), q('q4', 'short')];

describe('the deadline', () => {
  const start = new Date('2026-10-14T10:00:00Z');

  it('is the start plus the time limit, and there is none for an untimed quiz', () => {
    expect(quizDeadline(start, 30)?.toISOString()).toBe('2026-10-14T10:30:00.000Z');
    expect(quizDeadline(start, undefined)).toBeNull();
    expect(quizDeadline(start, 0)).toBeNull();
  });

  it('is open up to and at the deadline, then a grace for delivery, then closed', () => {
    const deadline = quizDeadline(start, 30)!;
    expect(deadlineWindow(deadline, new Date(deadline.getTime() - 1))).toBe('open');
    expect(deadlineWindow(deadline, deadline)).toBe('open');
    expect(deadlineWindow(deadline, new Date(deadline.getTime() + 1))).toBe('grace');
    expect(deadlineWindow(deadline, new Date(deadline.getTime() + QUIZ_SUBMIT_GRACE_SEC * 1000))).toBe('grace');
    expect(deadlineWindow(deadline, new Date(deadline.getTime() + QUIZ_SUBMIT_GRACE_SEC * 1000 + 1))).toBe('closed');
    expect(deadlineWindow(null, new Date('2099-01-01'))).toBe('open');
  });

  it('counts down in whole seconds by the clock it is given, never below zero', () => {
    const deadline = quizDeadline(start, 1)!;
    expect(remainingSec(deadline, start)).toBe(60);
    expect(remainingSec(deadline, new Date(start.getTime() + 59_500))).toBe(0);
    expect(remainingSec(deadline, new Date(start.getTime() + 600_000))).toBe(0);
    expect(remainingSec(null, start)).toBeUndefined();
  });
});

describe('attempts used', () => {
  it('counts every session started and every attempt made before sessions existed', () => {
    expect(attemptsUsed([], [])).toBe(0);
    // Two historical attempts, then two sessions — one finished (its attempt links to it), one still open.
    expect(attemptsUsed([{ id: 's1' }, { id: 's2' }], [{ sessionId: null }, {}, { sessionId: 's1' }])).toBe(4);
  });
});

describe('accepted answers', () => {
  it('keeps answers in the shape each question takes, and only for the session’s own questions', () => {
    const saved = acceptAnswers(questions, {}, { q1: ['a', 'b'], q2: ['c', 'a', 'a', 'zz'], q3: ['false'], q4: 'Hello', q9: ['a'] });
    expect(saved).toEqual({ q1: ['a'], q2: ['c', 'a'], q3: ['false'], q4: 'Hello' });
  });

  it('merges a save over what was stored, and an empty answer clears one', () => {
    const first = acceptAnswers(questions, {}, { q1: ['a'], q4: 'one' });
    expect(acceptAnswers(questions, first, { q1: [], q4: '  ', q2: ['b'] })).toEqual({ q2: ['b'] });
  });

  it('drops a value of the wrong kind instead of storing it', () => {
    expect(acceptAnswers(questions, { q1: ['b'] }, { q1: 'b' as never, q4: ['x'] as never })).toEqual({ q1: ['b'] });
    expect(acceptAnswers(questions, { gone: ['a'] }, {})).toEqual({});
  });
});

describe('the order a learner sees', () => {
  const settings = { shuffleQuestions: true, shuffleOptions: true };
  // A fixed sequence, so the shuffle is reproducible here; the server uses a secure random source.
  const seq = (values: number[]) => {
    let i = 0;
    return () => values[i++ % values.length];
  };

  it('keeps the authored order unless the quiz shuffles', () => {
    const order = sessionOrder(questions, { shuffleQuestions: false, shuffleOptions: false }, Math.random);
    expect(order.questions).toEqual(['q1', 'q2', 'q3', 'q4']);
    expect(order.options.q1).toEqual(['a', 'b', 'c']);
  });

  it('shuffles questions and options when asked, keeping every one and true/false as written', () => {
    const order = sessionOrder(questions, settings, seq([0.1, 0.7, 0.3, 0.9, 0.05]));
    expect([...order.questions].sort()).toEqual(['q1', 'q2', 'q3', 'q4']);
    expect(order.questions).not.toEqual(['q1', 'q2', 'q3', 'q4']);
    expect([...order.options.q1].sort()).toEqual(['a', 'b', 'c']);
    expect(order.options.q3).toEqual(['true', 'false']);
  });

  it('lays questions and options out in the stored order', () => {
    const laid = inSessionOrder(questions, { questions: ['q3', 'q1'], options: { q1: ['c', 'a', 'b'] } });
    expect(laid.map((x) => x.id)).toEqual(['q3', 'q1', 'q2', 'q4']);
    expect(laid[1].options.map((o) => o.id)).toEqual(['c', 'a', 'b']);
  });
});

describe('a quiz’s window', () => {
  const opensAt = '2026-10-20T04:30:00.000Z';
  const closesAt = '2026-10-20T06:30:00.000Z';

  it('is upcoming before it opens, open in between, and closed from the closing moment', () => {
    expect(quizWindow({ opensAt, closesAt }, new Date('2026-10-20T04:29:59Z'))).toBe('upcoming');
    expect(quizWindow({ opensAt, closesAt }, new Date(opensAt))).toBe('open');
    expect(quizWindow({ opensAt, closesAt }, new Date('2026-10-20T06:29:59Z'))).toBe('open');
    expect(quizWindow({ opensAt, closesAt }, new Date(closesAt))).toBe('closed');
    expect(quizWindow({}, new Date('2099-01-01'))).toBe('open');
  });

  it('cuts an attempt’s deadline to the close, and keeps the time limit when that comes first', () => {
    expect(sessionDeadline(new Date('2026-10-20T06:00:00Z'), { timeLimitMin: 60, closesAt })?.toISOString()).toBe(closesAt);
    expect(sessionDeadline(new Date('2026-10-20T05:00:00Z'), { timeLimitMin: 30, closesAt })?.toISOString()).toBe('2026-10-20T05:30:00.000Z');
    expect(sessionDeadline(new Date('2026-10-20T05:00:00Z'), { closesAt })?.toISOString()).toBe(closesAt);
    expect(sessionDeadline(new Date('2026-10-20T05:00:00Z'), {})).toBeNull();
  });

  it('holds results until the close only when the quiz says so', () => {
    expect(resultsOut({}, new Date(opensAt))).toBe(true);
    expect(resultsOut({ resultsRelease: 'after-close', closesAt }, new Date('2026-10-20T06:29:59Z'))).toBe(false);
    expect(resultsOut({ resultsRelease: 'after-close', closesAt }, new Date(closesAt))).toBe(true);
  });
});

describe('negative marks', () => {
  const paper = [
    { ...q('n1', 'single', ['a', 'b']), points: 4, negativePoints: 1 },
    { ...q('n2', 'single', ['a', 'b']), points: 4, negativePoints: 1 },
    { ...q('n3', 'multiple', ['a', 'b', 'c']), correct: ['a', 'b'], points: 4, negativePoints: 1 },
  ];
  const settings = { passMark: 50, attempts: 0, shuffleQuestions: false, shuffleOptions: false, showResults: 'score-only' as const };

  it('takes marks off a wrong answer, never a blank one, and leaves partial credit alone', () => {
    const r = scoreAttempt({ questions: paper, settings }, { n1: ['b'], n3: ['a'] });
    expect(r.questions.n1).toEqual({ state: 'incorrect', points: -1 });
    expect(r.questions.n2).toEqual({ state: 'unanswered', points: 0 });
    expect(r.questions.n3).toEqual({ state: 'partial', points: 2 });
    expect(r.points).toBe(1);
  });

  it('can take the total below zero, but never the percentage', () => {
    const r = scoreAttempt({ questions: paper, settings }, { n1: ['b'], n2: ['b'] });
    expect(r.points).toBe(-2);
    expect(r.percent).toBe(0);
    expect(r.passed).toBe(false);
  });

  it('tells the learner the marking, not the answer', () => {
    expect(learnerQuestion(paper[0])).toEqual({
      id: 'n1',
      type: 'single',
      prompt: 'n1',
      options: paper[0].options,
      points: 4,
      required: true,
      negativePoints: 1,
    });
  });
});

describe('publishing rules for windows and marks', () => {
  const base = { title: 'Weekly test', questions: [q('v1', 'single', ['a', 'b'])], settings: { ...defaultQuizSettings } };
  const messages = (quiz: Parameters<typeof validateQuiz>[0]) => validateQuiz(quiz).map((i) => i.message);

  it('needs the close after the opening, and a close to hold results until it', () => {
    expect(messages({ ...base, settings: { ...base.settings, opensAt: '2026-10-20T06:00:00Z', closesAt: '2026-10-20T05:00:00Z' } })).toContain(
      'The quiz must close after it opens.',
    );
    expect(messages({ ...base, settings: { ...base.settings, resultsRelease: 'after-close' } })).toContain(
      'Set a closing time to show results once the quiz closes.',
    );
    expect(messages({ ...base, settings: { ...base.settings, opensAt: 'soon' } })).toContain('Enter the opening and closing times as dates.');
    expect(validateQuiz(base)).toEqual([]);
  });

  it('refuses negative marks above the question’s marks, and two questions with one id', () => {
    expect(messages({ ...base, questions: [{ ...base.questions[0], negativePoints: 2 }] })).toContain(
      'Negative marks must be between 0 and the question’s marks.',
    );
    expect(messages({ ...base, questions: [base.questions[0], base.questions[0]] })).toContain('Two questions share an id. Delete one and add it again.');
  });
});
