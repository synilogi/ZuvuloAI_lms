import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { categoryAdminService as service } from './categories';
import { categories, courses } from './fixtures/catalog';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

const orders = () => [...categories].sort((a, b) => a.order - b.order).map((c) => c.order);

describe('category admin mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('inserts at the requested position and keeps display order contiguous', async () => {
    const created = await settle(
      service.create({
        name: 'Jaimini Studies',
        description: 'Chara karakas and rashi drishti.',
        glyph: 'orbits',
        status: 'active',
        levelIds: ['advanced'],
        order: 2,
      }),
    );
    expect(created.order).toBe(2);
    expect(orders()).toEqual(categories.map((_, i) => i + 1));
  });

  it('rejects duplicate names regardless of case', async () => {
    const attempt = expect(
      service.create({ name: 'vedic foundations', description: 'x', glyph: 'sun', status: 'active', levelIds: ['beginner'], order: 1 }),
    ).rejects.toMatchObject({
      code: 'conflict',
    });
    await vi.runAllTimersAsync();
    await attempt;
  });

  it('will not delete a category in use without a destination, and moves courses when given one', async () => {
    const blocked = expect(service.remove('predictive')).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await blocked;

    const using = courses.filter((c) => c.categoryId === 'predictive').length;
    const result = await settle(service.remove('predictive', { moveCoursesTo: 'chart-interpretation' }));
    expect(result.moved).toBe(using);
    expect(courses.some((c) => c.categoryId === 'predictive')).toBe(false);
    expect(categories.some((c) => c.id === 'predictive')).toBe(false);
    expect(orders()).toEqual(categories.map((_, i) => i + 1));
  });
});
