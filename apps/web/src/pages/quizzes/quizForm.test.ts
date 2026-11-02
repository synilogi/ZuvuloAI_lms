import { describe, expect, it } from 'vitest';
import type { QuizQuestion } from '@syniastrolms/domain';
import { defaultQuizSettings } from '@syniastrolms/domain';

import { applyWindow, builderIssues, formatTaken, windowDraft, windowIssues } from './quizForm';

/* The builder types a quiz's window in IST and sends it as a moment with its offset; it checks what the server checks
 * before publishing, and catches a half-typed window first. */

const question = (over: Partial<QuizQuestion> = {}): QuizQuestion => ({
  id: 'q1',
  type: 'single',
  prompt: 'What is (−3) × (−4)?',
  options: [
    { id: 'a', text: '12' },
    { id: 'b', text: '−12' },
  ],
  correct: ['a'],
  acceptedAnswers: [],
  points: 4,
  required: true,
  ...over,
});

describe('the quiz window', () => {
  it('reads a stored UTC moment as the IST date and time it is, and writes it back as the same moment with +05:30', () => {
    const draft = windowDraft({ opensAt: '2026-11-01T04:30:00.000Z', closesAt: '2026-11-01T18:45:00.000Z' });
    expect(draft).toEqual({ opensDate: '2026-11-01', opensTime: '10:00', closesDate: '2026-11-02', closesTime: '00:15' });
    const edited = applyWindow({ ...defaultQuizSettings }, { ...draft, opensTime: '10:30' });
    expect(edited.opensAt).toBe('2026-11-01T10:30:00+05:30');
    expect(Date.parse(edited.opensAt!)).toBe(Date.parse('2026-11-01T05:00:00Z'));
    expect(edited.closesAt).toBe('2026-11-02T00:15:00+05:30');
  });

  it('keeps an unchanged moment exactly as the server wrote it, and clears an edge left blank', () => {
    const settings = { ...defaultQuizSettings, opensAt: '2026-11-01T04:30:00.000Z', closesAt: '2026-11-03T04:30:00.000Z' };
    const same = applyWindow(settings, windowDraft(settings));
    expect(same).toEqual(settings);
    const cleared = applyWindow(settings, { ...windowDraft(settings), closesDate: '', closesTime: '' });
    expect(cleared.closesAt).toBeUndefined();
    expect('closesAt' in cleared).toBe(false);
    expect(cleared.opensAt).toBe(settings.opensAt);
  });

  it('stops a date without a time, or a time without a date', () => {
    expect(windowIssues({ opensDate: '2026-11-01', opensTime: '', closesDate: '', closesTime: '' })).toHaveLength(1);
    expect(windowIssues({ opensDate: '', opensTime: '', closesDate: '', closesTime: '09:00' })[0].message).toMatch(/closing time/);
    expect(windowIssues(windowDraft({}))).toEqual([]);
  });
});

describe('the checks before saving', () => {
  const draft = windowDraft({});
  const input = (over: Partial<typeof defaultQuizSettings> = {}, questions = [question()]) => ({
    title: 'Integers check',
    status: 'published' as const,
    questions,
    settings: { ...defaultQuizSettings, ...over },
  });

  it('passes a finished quiz', () => {
    expect(builderIssues(input(), draft)).toEqual([]);
  });

  it('mirrors the server: close after open, results after close need a close, negative marks within the question’s', () => {
    const messages = (i: ReturnType<typeof builderIssues>) => i.map((x) => x.message);
    expect(messages(builderIssues(input({ opensAt: '2026-11-02T10:00:00+05:30', closesAt: '2026-11-01T10:00:00+05:30' }), draft))).toContain(
      'The quiz must close after it opens.',
    );
    expect(messages(builderIssues(input({ resultsRelease: 'after-close' }), draft))).toContain('Set a closing time to show results once the quiz closes.');
    const tooMany = builderIssues(input({}, [question({ negativePoints: 5 })]), draft);
    expect(tooMany).toEqual([expect.objectContaining({ questionId: 'q1', field: 'points' })]);
    expect(builderIssues(input({}, [question({ negativePoints: 4 })]), draft)).toEqual([]);
    expect(messages(builderIssues(input({ timeLimitMin: 300 }), draft))).toContain('A time limit must be between 1 and 240 minutes.');
  });

  it('reads the time an attempt took', () => {
    expect(formatTaken(undefined)).toBe('—');
    expect(formatTaken(42)).toBe('42 s');
    expect(formatTaken(725)).toBe('12 min 05 s');
    expect(formatTaken(600)).toBe('10 min');
  });
});
