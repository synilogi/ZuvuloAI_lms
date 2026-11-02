import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { validateAssignment } from '@syniastrolms/domain';
import { assignmentAdminService as service } from './assignments';
import { reviewQueue } from './analytics';
import { courseAssignments, submissions } from './fixtures/assignments';
import { DEMO_NOW } from './fixtures/learner';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('assignment admin mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers({ now: new Date(DEMO_NOW) });
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('publishes only valid assignments, and links lesson assignments to their lessons', () => {
    for (const a of courseAssignments.filter((x) => x.status === 'published')) {
      expect(validateAssignment(a, new Date(DEMO_NOW)), a.id).toEqual([]);
    }
    expect(courseAssignments.filter((a) => a.lessonId)).toHaveLength(8);
  });

  it('opens with the review queue the dashboard reports', async () => {
    expect(reviewQueue()).toEqual({
      'foundations-vedic': { waiting: 11, overdue: 3 },
      muhurta: { waiting: 3, overdue: 0 },
      dasha: { waiting: 9, overdue: 6 },
      'nakshatra-depth': { waiting: 2, overdue: 1 },
      jaimini: { waiting: 1, overdue: 0 },
      navamsha: { waiting: 2, overdue: 2 },
    });
    expect((await settle(service.summary())).toReview).toBe(28);
    expect((await settle(service.summary('meenakshi'))).toReview).toBe(14);
  });

  it('lists submissions with counts, filters and learners who haven’t handed in', async () => {
    const all = await settle(service.submissions({ assignmentId: 'a-kendra', page: 1, pageSize: 20 }));
    expect(all.total).toBe(all.counts.all);
    expect(all.counts.all).toBe(all.counts['to-review'] + all.counts.graded + all.counts.returned);
    expect(all.counts.missing).toBeGreaterThan(0);
    const missing = await settle(service.submissions({ assignmentId: 'a-kendra', filter: 'missing', page: 1, pageSize: 5 }));
    expect(missing.rows.every((r) => !r.submission)).toBe(true);
    const queue = await settle(service.submissions({ filter: 'to-review', scopeInstructorId: 'meenakshi', page: 1, pageSize: 50 }));
    expect(queue.total).toBe(14);
    expect(queue.rows[0].submission!.submittedAt <= queue.rows[1].submission!.submittedAt).toBe(true);
  });

  it('grades against the rubric, applies the late penalty and clears the queue', async () => {
    const detail = await settle(service.submission('sub-a-sidereal-u-ananya'));
    expect(detail.submission.text).toContain('precession');
    expect(detail.queue.total).toBeGreaterThan(0);
    const refused = expect(service.review(detail.submission.id, { decision: 'graded', scores: { understanding: 7 }, feedback: 'Nice.' })).rejects.toMatchObject(
      { code: 'conflict' },
    );
    await vi.runAllTimersAsync();
    await refused;
    const graded = await settle(
      service.review(detail.submission.id, {
        decision: 'graded',
        scores: { understanding: 7, examples: 5, structure: 3, sources: 1 },
        feedback: 'A clear, personal reflection.',
      }),
    );
    expect(graded.review).toMatchObject({ status: 'graded', score: 16 });
    expect(reviewQueue()['foundations-vedic']).toEqual({ waiting: 10, overdue: 2 });
  });

  it('fills in generated responses and review breakdowns that add up', async () => {
    const graded = submissions().find((s) => s.assignmentId === 'a-navagraha' && s.review.status === 'graded')!;
    const detail = await settle(service.submission(graded.id));
    expect(detail.submission.chart?.nakshatra).toBeTruthy();
    const sum = Object.values(detail.submission.review.scores).reduce((n, v) => n + v, 0);
    expect(sum).toBe(graded.review.points);
    expect(detail.submission.review.feedback.length).toBeGreaterThan(20);
  });

  it('keeps lesson-delivered assignments but removes others with their submissions', async () => {
    const attempt = expect(service.remove('a-navagraha')).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await attempt;
    await settle(service.remove('a-journal'));
    expect(submissions().some((s) => s.assignmentId === 'a-journal')).toBe(false);
  });
});
