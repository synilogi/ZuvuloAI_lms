import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { instructorAdminService as service } from './instructors';
import { courses, instructors } from './fixtures/catalog';
import { DEMO_NOW } from './fixtures/learner';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('instructor admin mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers({ now: new Date(DEMO_NOW) });
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('lists instructors with reach, rating and review load', async () => {
    const { rows, counts, expertise } = await settle(service.list({}));
    expect(counts).toMatchObject({ all: 9, invited: 1, inactive: 1 });
    const meenakshi = rows.find((r) => r.instructor.id === 'meenakshi')!;
    expect(meenakshi.courses.map((c) => c.id)).toContain('foundations-vedic');
    expect(meenakshi.students).toBeGreaterThan(2000);
    expect(meenakshi.toReview).toBe(14);
    expect(expertise).toContain('Muhurta');
    const byRating = await settle(service.list({ sort: 'rating', status: 'active' }));
    expect(byRating.rows[0].rating! >= byRating.rows[1].rating!).toBe(true);
  });

  it('builds a profile with portfolio, reach, performance and activity', async () => {
    const profile = await settle(service.get('vinod'));
    expect(profile.courses.length).toBeGreaterThan(1);
    expect(profile.reach.cities).toHaveLength(5);
    expect(profile.performance.enrollmentsByMonth).toHaveLength(8);
    expect(profile.performance.reviewsOnTime).not.toBeNull();
    expect(profile.activity.length).toBeGreaterThan(0);
    expect(profile.activity[0].at >= profile.activity[profile.activity.length - 1].at).toBe(true);
  });

  it('creates an instructor, assigns courses and rejects a taken email', async () => {
    const input = {
      name: 'Dr. Lalitha Raman',
      title: 'Prashna specialist',
      email: 'lalitha.raman@zuviloai.com',
      bio: '',
      expertise: ['Prashna'],
      status: 'invited' as const,
      city: 'Madurai',
      languages: ['Tamil', 'English'],
      courseIds: ['prashna'],
    };
    const created = await settle(service.create(input));
    expect(created.id).toBe('lalitha');
    expect(courses.find((c) => c.id === 'prashna')!.instructorIds).toContain('lalitha');
    const again = expect(service.create({ ...input, name: 'Lalitha R' })).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await again;
    await settle(service.update('lalitha', { ...input, courseIds: [] }));
    expect(courses.find((c) => c.id === 'prashna')!.instructorIds).not.toContain('lalitha');
    expect(instructors.some((i) => i.id === 'lalitha')).toBe(true);
  });

  it('won’t deactivate the only instructor on a published course', async () => {
    const sole = courses.find((c) => c.status === 'published' && c.instructorIds.length === 1)!;
    const attempt = expect(service.setStatus(sole.instructorIds[0], 'inactive')).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await attempt;
    const resend = await settle(service.resendInvite('kiran'));
    expect(resend.sentTo).toContain('@');
  });
});
