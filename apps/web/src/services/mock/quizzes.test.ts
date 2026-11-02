import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { defaultQuizSettings, scoreAttempt } from '@syniastrolms/domain';
import { quizAdminService as service } from './quizzes';
import { quizzes } from './fixtures/quizzes';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('quiz admin mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('delivers a valid quiz for every assessment lesson', () => {
    const lessonQuizzes = quizzes.filter((q) => q.lessonId);
    expect(lessonQuizzes.length).toBe(14);
    for (const quiz of lessonQuizzes) {
      expect(quiz.questions.length).toBeGreaterThan(0);
      const perfect = Object.fromEntries(quiz.questions.map((q) => [q.id, q.type === 'short' ? q.acceptedAnswers[0] : q.correct]));
      expect(scoreAttempt(quiz, perfect).percent).toBe(100);
    }
  });

  it('scopes the list to the courses an instructor teaches', async () => {
    const all = await settle(service.list({}));
    const teaching = await settle(service.list({ scopeInstructorId: 'meenakshi' }));
    expect(teaching.counts.all).toBeGreaterThan(0);
    expect(teaching.counts.all).toBeLessThan(all.counts.all);
    const drafts = await settle(service.list({ status: 'draft' }));
    expect(drafts.rows.every((r) => r.quiz.status === 'draft')).toBe(true);
    expect(drafts.counts.all).toBe(all.counts.all);
  });

  it('refuses to publish a quiz with unfinished questions', async () => {
    const input = {
      courseId: 'foundations-vedic',
      title: 'Chapter 4 check: Zodiac signs',
      instructions: '',
      status: 'published' as const,
      questions: [{ id: 'q-new', type: 'single' as const, prompt: '', options: [], correct: [], acceptedAnswers: [], points: 1, required: true }],
      settings: { ...defaultQuizSettings },
    };
    const attempt = expect(service.create(input)).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await attempt;
    const draft = await settle(service.create({ ...input, status: 'draft' }));
    expect(quizzes[0].id).toBe(draft.id);
  });

  it('duplicates a quiz as a draft with its own question and option ids', async () => {
    const source = quizzes.find((q) => q.id === 'quiz-m3-l8')!;
    const copy = await settle(service.duplicate(source.id));
    const again = await settle(service.duplicate(source.id));
    expect(again.id).not.toBe(copy.id);
    expect(copy).toMatchObject({ status: 'draft', lessonId: undefined, title: `Copy of ${source.title}` });
    const truth = copy.questions.find((q) => q.type === 'true-false');
    expect(truth?.options.map((o) => o.id)).toEqual([`${truth?.id}-true`, `${truth?.id}-false`]);
    for (const q of copy.questions) {
      expect(q.correct.every((id) => q.options.some((o) => o.id === id))).toBe(true);
    }
    const perfect = Object.fromEntries(copy.questions.map((q) => [q.id, q.type === 'short' ? q.acceptedAnswers[0] : q.correct]));
    expect(scoreAttempt(copy, perfect).percent).toBe(100);
  });

  it('keeps lesson-delivered quizzes but deletes standalone ones', async () => {
    const attempt = expect(service.remove('quiz-m3-l8')).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await attempt;
    await settle(service.remove('quiz-nakshatra-drill'));
    expect(quizzes.some((q) => q.id === 'quiz-nakshatra-drill')).toBe(false);
  });

  it('reports results with a distribution that adds up to the attempts', async () => {
    const stats = await settle(service.stats('quiz-m3-l8'));
    expect(stats.distribution.reduce((sum, band) => sum + band.value, 0)).toBe(stats.attempts);
    expect(stats.questions).toHaveLength(quizzes.find((q) => q.id === 'quiz-m3-l8')!.questions.length);
  });
});
