import { describe, expect, it } from 'vitest';
import { allocateByWeight, DEFAULT_SITE_CONTENT, HOME_SECTIONS, isLive, orderedSections } from './site';

describe('sharing a bundle’s charge across its courses', () => {
  it('always adds up to exactly the charge', () => {
    for (const [total, weights] of [
      [99_900, [1000, 2000, 3333]],
      [100, [1, 1, 1]],
      [1, [5, 5]],
      [150_000, [999, 1]],
    ] as const) {
      const shares = allocateByWeight(total, weights);
      expect(shares.reduce((sum, s) => sum + s, 0)).toBe(total);
      expect(shares.every((s) => Number.isInteger(s) && s >= 0)).toBe(true);
    }
  });

  it('is in proportion, and gives what rounding leaves to the largest remainders', () => {
    expect(allocateByWeight(300, [100, 200])).toEqual([100, 200]);
    expect(allocateByWeight(100, [1, 1, 1])).toEqual([34, 33, 33]);
  });

  it('shares equally when no course has a price, and handles nothing to share', () => {
    expect(allocateByWeight(10, [0, 0])).toEqual([5, 5]);
    expect(allocateByWeight(10, [])).toEqual([]);
  });
});

describe('the home page’s sections', () => {
  it('keeps the saved order and adds any it did not know, shown', () => {
    const saved = orderedSections([
      { id: 'faq', visible: false },
      { id: 'stats', visible: true },
    ]);
    expect(saved.slice(0, 2)).toEqual([
      { id: 'faq', visible: false },
      { id: 'stats', visible: true },
    ]);
    expect(saved.map((s) => s.id).sort()).toEqual([...HOME_SECTIONS].sort());
    expect(saved.slice(2).every((s) => s.visible)).toBe(true);
  });

  it('copes with an older document, an unknown section and a repeat', () => {
    expect(orderedSections(undefined)).toHaveLength(HOME_SECTIONS.length);
    const odd = orderedSections([{ id: 'gone', visible: true } as never, { id: 'cta', visible: true }, { id: 'cta', visible: false }]);
    expect(odd).toHaveLength(HOME_SECTIONS.length);
    expect(odd[0]).toEqual({ id: 'cta', visible: true });
  });
});

describe('scheduled content', () => {
  const now = new Date('2026-11-02T12:00:00Z');

  it('shows by default, and hides what is off, not yet due or over', () => {
    expect(isLive({}, now)).toBe(true);
    expect(isLive({ published: false }, now)).toBe(false);
    expect(isLive({ publishAt: '2026-11-03T00:00:00Z' }, now)).toBe(false);
    expect(isLive({ publishAt: '2026-11-01T00:00:00Z' }, now)).toBe(true);
    expect(isLive({ endsAt: '2026-11-01T00:00:00Z' }, now)).toBe(false);
    expect(isLive({ publishAt: '', endsAt: '' }, now)).toBe(true);
  });
});

describe('the default document', () => {
  it('invents no testimonials, banners or social accounts', () => {
    expect(DEFAULT_SITE_CONTENT.testimonials).toEqual([]);
    expect(DEFAULT_SITE_CONTENT.banners).toEqual([]);
    expect(DEFAULT_SITE_CONTENT.socials).toEqual([]);
  });
});
