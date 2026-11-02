import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { lessonAdminService as service } from './lessons';
import { courses } from './fixtures/catalog';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

const foundations = () => courses.find((c) => c.id === 'foundations-vedic')!;

describe('lesson admin mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('fills in content for catalog lessons that have none', async () => {
    const detail = await settle(service.get('foundations-vedic', 'm3-l5'));
    expect(detail.lesson.content?.video?.file?.name).toBe('home-and-mother-the-fourth-house.mp4');
    expect(detail.lesson.settings?.completion).toBe('watched');
    expect(detail.chapterIndex).toBe(2);
    expect(detail.previous?.id).toBe('m3-l4');
  });

  it('refuses to publish a lesson without its content', async () => {
    const attempt = expect(
      service.create('foundations-vedic', 'm4', {
        title: 'Signs in the navamsha',
        type: 'reading',
        durationMin: 12,
        status: 'published',
        content: { article: { body: 'Too short.' } },
      }),
    ).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await attempt;
    const draft = await settle(
      service.create('foundations-vedic', 'm4', { title: 'Signs in the navamsha', type: 'reading', durationMin: 12, status: 'draft' }, 1),
    );
    expect(foundations().chapters[3].lessons[0].id).toBe(draft.id);
  });

  it('moves a lesson into another chapter at a position', async () => {
    const detail = await settle(service.move('foundations-vedic', 'm1-l4', 'm7', 2));
    expect(detail.chapterId).toBe('m7');
    expect(foundations().chapters[6].lessons[1].id).toBe('m1-l4');
    expect(foundations().chapters[0].lessons.some((l) => l.id === 'm1-l4')).toBe(false);
  });

  it('lists lessons with counts by type before the type filter', async () => {
    const result = await settle(service.list('foundations-vedic', { type: 'assessment' }));
    expect(result.rows.every((r) => r.lesson.type === 'assessment')).toBe(true);
    expect(result.counts.byType.video).toBeGreaterThan(result.rows.length);
  });
});
