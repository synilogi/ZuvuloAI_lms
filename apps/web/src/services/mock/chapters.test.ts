import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { chapterAdminService as service } from './chapters';
import { courses } from './fixtures/catalog';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

const course = (id: string) => courses.find((c) => c.id === id)!;

describe('chapter admin mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('adds a draft chapter at the requested position', async () => {
    const chapter = await settle(service.create('dasha', { title: 'Yogini dasha', status: 'draft', estimatedMin: 90 }, 2));
    expect(course('dasha').chapters[1].id).toBe(chapter.id);
    expect(chapter.lessons).toHaveLength(0);
  });

  it('duplicates a chapter as a draft directly after the original, lessons included', async () => {
    const source = course('yogas').chapters[1];
    const copy = await settle(service.duplicate('yogas', source.id));
    const chapters = course('yogas').chapters;
    expect(chapters[chapters.findIndex((c) => c.id === source.id) + 1].id).toBe(copy.id);
    expect(copy.status).toBe('draft');
    expect(copy.lessons).toHaveLength(source.lessons.length);
    expect(copy.lessons.every((l) => l.status === 'draft' && !source.lessons.some((s) => s.id === l.id))).toBe(true);
  });

  it('keeps a published course from losing its last published chapter', async () => {
    const published = course('intro-jyotish');
    expect(published.status).toBe('published');
    await settle(service.remove('intro-jyotish', published.chapters[1].id));
    const attempt = expect(service.remove('intro-jyotish', published.chapters[0].id)).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await attempt;
  });

  it('reports chapter completion that never rises along the course', async () => {
    const stats = await settle(service.stats('foundations-vedic'));
    const rates = course('foundations-vedic').chapters.map((c) => stats.chapters[c.id].completionRate);
    expect(stats.enrolled).toBe(course('foundations-vedic').enrolledCount);
    expect(rates.every((r, i) => i === 0 || r <= rates[i - 1])).toBe(true);
  });
});
