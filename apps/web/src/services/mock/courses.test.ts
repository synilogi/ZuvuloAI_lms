import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import type { CourseInput } from '@syniastrolms/domain';
import { courseAdminService as service } from './courses';

/** Runs a mock call to completion under fake timers. */
async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

const input: CourseInput = {
  title: 'Reading the Navamsha',
  subtitle: 'Judge strength, marriage and dharma from the D9',
  description: 'A focused course on the ninth divisional chart, taught through real charts.',
  levelId: 'advanced',
  categoryId: 'chart-interpretation',
  instructorIds: ['rohan'],
  format: 'self-paced',
  language: 'English',
  coverMotif: 'houses',
  outcomes: ['Calculate the navamsha', 'Judge vargottama planets', 'Read marriage in the D9'],
  tags: ['Navamsha'],
  visibility: 'public',
  liveSessions: 2,
};

describe('course admin mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('creates drafts and rejects duplicate titles', async () => {
    const created = await settle(service.create(input));
    expect(created.status).toBe('draft');
    expect(created.slug).toBe('reading-the-navamsha');
    const duplicate = expect(service.create({ ...input, title: 'reading the navamsha ' })).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await duplicate;
  });

  it('refuses to publish a course without a description or an instructor', async () => {
    const created = await settle(service.create({ ...input, title: 'Draft with gaps', description: '', instructorIds: [] }));
    const attempt = expect(service.publish(created.id)).rejects.toThrow(/Not ready to publish: course description, at least one instructor\./);
    await vi.runAllTimersAsync();
    await attempt;
  });

  it('publishes with only a title, a description and an instructor, placing a blank category and level by default', async () => {
    const rest: CourseInput = { ...input, levelId: undefined, categoryId: undefined };
    const created = await settle(
      service.create({ ...rest, title: 'Bare minimum', subtitle: '', description: 'Fractions for Class 6.', outcomes: [], tags: [] }),
    );
    expect(created.levelId).toBeTruthy();
    expect(created.categoryId).toBeTruthy();
    expect((await settle(service.publish(created.id))).status).toBe('published');
  });

  it('archives, restores and reorders chapters', async () => {
    expect((await settle(service.archive('gochara'))).status).toBe('archived');
    expect((await settle(service.restore('gochara'))).status).toBe('draft');
    const course = await settle(service.get('dasha'));
    const reversed = [...course.chapters.map((c) => c.id)].reverse();
    const reordered = await settle(service.reorderChapters('dasha', reversed));
    expect(reordered.chapters.map((c) => c.id)).toEqual(reversed);
  });

  it('scopes lists to an instructor and reports counts before the status filter', async () => {
    const result = await settle(service.list({ scopeInstructorId: 'meenakshi', status: 'published', page: 1, pageSize: 20 }));
    expect(result.rows.every((c) => c.instructorIds.includes('meenakshi') && c.status === 'published')).toBe(true);
    expect(result.counts.all).toBeGreaterThanOrEqual(result.total);
    const hidden = expect(service.get('dasha', 'meenakshi')).rejects.toMatchObject({ code: 'not-found' });
    await vi.runAllTimersAsync();
    await hidden;
  });
});
