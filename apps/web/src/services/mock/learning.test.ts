import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { learningService as service } from './learning';
import { submissions } from './fixtures/assignments';
import { DEMO_NOW } from './fixtures/learner';
import { enrollments } from './fixtures/people';
import { quizzes } from './fixtures/quizzes';

// The mock clock reads the time once when it loads (clock.ts), so the demo date has to be in place before the
// imports run — otherwise the demo days drift by however long ago DEMO_NOW was on the real calendar.
vi.hoisted(() => {
  vi.useFakeTimers({ now: new Date('2026-09-15T18:52:00+05:30') });
});

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('learning mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers({ now: new Date(DEMO_NOW) });
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('opens the learner’s home with where to resume', async () => {
    const home = await settle(service.getHome());
    expect(home.courses.map((c) => c.course.id)).toEqual(['foundations-vedic', 'panchang', 'intro-jyotish']);
    const foundations = home.courses[0];
    expect(foundations.next).toMatchObject({ id: 'm3-l5', state: 'in-progress', lessonNumber: '3.5' });
    expect(home.recent[0].courseId).toBe('foundations-vedic');
    expect(home.upcoming.some((u) => u.kind === 'live')).toBe(true);
  });

  it('locks a chapter quiz until its lessons are done, and later chapters until the chapter is', async () => {
    const quiz = await settle(service.getLesson('foundations-vedic', 'm3-l8'));
    expect(quiz.access).toBe('locked');
    expect(quiz.lockedReason).toContain('other lessons');
    const later = await settle(service.getLesson('foundations-vedic', 'm4-l1'));
    expect(later.lockedReason).toContain('Understanding the Twelve Houses');
    const current = await settle(service.getLesson('foundations-vedic', 'm3-l5'));
    expect(current).toMatchObject({ access: 'open', state: 'in-progress', number: '3.5' });
    expect(current.note).toContain('yogakaraka');
  });

  it('completes lessons, unlocks the quiz and keeps the enrollment in step', async () => {
    await settle(service.completeLesson('foundations-vedic', 'm3-l5'));
    const result = await settle(service.completeLesson('foundations-vedic', 'm3-l6'));
    expect(result.snapshot.lessons['m3-l8']?.state).not.toBe('locked');
    const enrollment = enrollments.find((e) => e.studentId === 'u-ananya' && e.courseId === 'foundations-vedic')!;
    expect(enrollment.progress).toBe(result.progress.percent);
    // The learner's view has no key; the mock scores with it, as the server does.
    const view = await settle(service.getLesson('foundations-vedic', 'm3-l8'));
    expect(JSON.stringify(view.quiz)).not.toMatch(/"correct"|"acceptedAnswers"|"explanation"/);
    const key = quizzes.find((q) => q.lessonId === 'm3-l8')!;
    expect(view.quiz).toMatchObject({ questionCount: key.questions.length, attemptsUsed: 0, window: 'open' });
    // The attempt is a session: its questions come with it, without their key, and it is handed in with the sheet.
    const begun = await settle(service.startQuizSession('foundations-vedic', 'm3-l8', 'start-key-0001'));
    expect(JSON.stringify(begun.questions)).not.toMatch(/"correct"|"acceptedAnswers"|"explanation"/);
    const answers = Object.fromEntries(key.questions.map((q) => [q.id, q.type === 'short' ? q.acceptedAnswers[0] : q.correct]));
    const passed = await settle(service.submitQuizSession('foundations-vedic', 'm3-l8', begun.session.id, { answers, seq: 1 }));
    expect(passed.completion?.snapshot.lessons['m3-l8']?.state).toBe('completed');
    expect(passed.review).toMatchObject({ passed: true, percent: 100, attemptNo: 1 });
    const {
      attempts: [review],
      standing,
    } = await settle(service.quizAttempts('foundations-vedic', 'm3-l8'));
    expect(review).toMatchObject({ passed: true, percent: 100 });
    expect(standing).toMatchObject({ passed: true, attemptsUsed: 1, canStart: true });
  });

  it('submits an assignment into the review queue and completes its lesson', async () => {
    const before = submissions().length;
    const draft = {
      text: 'Aries lagna: Mars rules the 1st and 8th, Venus the 2nd and 7th, Mercury the 3rd and 6th, the Moon the 4th, the Sun the 5th, Jupiter the 9th and 12th, Saturn the 10th and 11th.',
      files: [{ id: 'f1', name: 'lordship.pdf', sizeMb: 0.4 }],
    };
    const refused = expect(service.submitAssignment('a-lordship', { text: '', files: [] })).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await refused;
    const la = await settle(service.submitAssignment('a-lordship', draft));
    expect(la.state).toBe('submitted');
    expect(submissions()).toHaveLength(before + 1);
    const lesson = await settle(service.getLesson('foundations-vedic', 'm3-l7'));
    expect(lesson.state).toBe('completed');
  });

  it('lists assignments and assessments with their states', async () => {
    const list = await settle(service.listAssignments());
    expect(list.find((a) => a.assignment.id === 'a-dignities')?.state).toBe('graded');
    expect(list.find((a) => a.assignment.id === 'a-navagraha')?.draft?.text).toBeTruthy();
    const quizzes = await settle(service.listAssessments());
    expect(quizzes.find((q) => q.lessonId === 'm1-l5')?.state).toBe('passed');
    expect(quizzes.find((q) => q.lessonId === 'm7-l3')?.state).toBe('locked');
  });

  it('enrolls in a saved course and starts it at the first lesson', async () => {
    const course = await settle(service.enroll('nakshatra-depth'));
    expect(course.next?.lessonNumber).toBe('1.1');
    const saved = await settle(service.listCourses());
    expect(saved.saved.map((s) => s.course.id)).not.toContain('nakshatra-depth');
  });
});
