import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { studentAdminService as service } from './students';
import { DEMO_NOW } from './fixtures/learner';
import { enrollments, students } from './fixtures/people';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('student admin mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers({ now: new Date(DEMO_NOW) });
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('lists the whole roster with status counts that add up', async () => {
    const all = await settle(service.list({ page: 1, pageSize: 25 }));
    expect(all.total).toBe(students.length);
    const { all: total, ...byStatus } = all.counts;
    expect(Object.values(byStatus).reduce((n, v) => n + v, 0)).toBe(total);
    const atRisk = await settle(service.list({ status: 'at-risk', page: 1, pageSize: 25 }));
    expect(atRisk.total).toBe(all.counts['at-risk']);
    expect(atRisk.rows.every((r) => r.status === 'at-risk')).toBe(true);
    const found = await settle(service.list({ search: 'ananya.rao', page: 1, pageSize: 25 }));
    expect(found.rows[0].student.id).toBe('u-ananya');
  });

  it('scopes learners to an instructor’s courses', async () => {
    const teaching = await settle(service.list({ scopeInstructorId: 'meenakshi', page: 1, pageSize: 10 }));
    expect(teaching.total).toBeGreaterThan(0);
    expect(teaching.total).toBeLessThan(students.length);
    const outsider = students.find(
      (s) => !enrollments.some((e) => e.studentId === s.id && ['foundations-vedic', 'intro-jyotish', 'muhurta'].includes(e.courseId)),
    )!;
    const attempt = expect(service.get(outsider.id, 'meenakshi')).rejects.toMatchObject({ code: 'not-found' });
    await vi.runAllTimersAsync();
    await attempt;
  });

  it('builds a profile with enrollments, certificates and a rank', async () => {
    const profile = await settle(service.get('u-ananya'));
    expect(profile.enrollments.map((e) => e.enrollment.courseId).sort()).toEqual(['foundations-vedic', 'intro-jyotish', 'panchang']);
    expect(profile.summary.completed).toBe(2);
    expect(profile.rank.title).toBe('Beginner');
    const foundations = profile.enrollments.find((e) => e.enrollment.courseId === 'foundations-vedic')!;
    expect(foundations.chapters.done).toBeGreaterThan(0);
    expect(foundations.chapters.done).toBeLessThan(foundations.chapters.total);
    expect(profile.summary.submissions).toBe(4);
  });

  it('derives progress and a newest-first activity timeline', async () => {
    const progress = await settle(service.progress('u-ananya'));
    expect(progress.courses).toHaveLength(3);
    expect(progress.studyWeeks).toHaveLength(12);
    expect(progress.assignments.map((a) => a.assignmentId)).toContain('a-kendra');
    const activity = await settle(service.activity('u-ananya', { limit: 10 }));
    expect(activity.events).toHaveLength(10);
    expect(activity.events[0].at >= activity.events[9].at).toBe(true);
    const enrolled = await settle(service.activity('u-ananya', { kind: 'enrolled', limit: 10 }));
    expect(enrolled.total).toBe(3);
  });

  it('enrolls, pauses and removes an enrollment', async () => {
    const before = enrollments.length;
    const created = await settle(service.enroll('u-ananya', 'nakshatra-depth', 'admin'));
    expect(enrollments).toHaveLength(before + 1);
    const duplicate = expect(service.enroll('u-ananya', 'nakshatra-depth', 'admin')).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await duplicate;
    expect((await settle(service.setEnrollmentStatus(created.id, 'paused'))).status).toBe('paused');
    await settle(service.removeEnrollment(created.id));
    expect(enrollments).toHaveLength(before);
  });
});
