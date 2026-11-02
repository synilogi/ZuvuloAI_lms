import { describe, expect, it } from 'vitest';

import { academySlugFrom, academyTransition, validateAcademySlug } from './academy';

describe('academy lifecycle', () => {
  it('moves only along the allowed transitions', () => {
    expect(academyTransition('active', 'suspend')).toBe('suspended');
    expect(academyTransition('suspended', 'reactivate')).toBe('active');
    expect(academyTransition('active', 'archive')).toBe('archived');
    expect(academyTransition('suspended', 'archive')).toBe('archived');
    expect(academyTransition('archived', 'reactivate')).toBe('active');
    expect(academyTransition('active', 'reactivate')).toBeNull();
    expect(academyTransition('suspended', 'suspend')).toBeNull();
    expect(academyTransition('archived', 'suspend')).toBeNull();
    expect(academyTransition('archived', 'archive')).toBeNull();
  });
});

describe('academy slugs', () => {
  it('accepts lowercase words joined by single hyphens', () => {
    expect(validateAcademySlug('jyotish-vidya')).toBeNull();
    expect(validateAcademySlug('kp2')).toBeNull();
  });

  it('refuses what cannot be an address, and the reserved names', () => {
    for (const bad of ['ab', 'Upper', 'two--hyphens', '-lead', 'trail-', 'space here', 'x'.repeat(41), 'superadmin', 'default']) {
      expect(validateAcademySlug(bad), bad).not.toBeNull();
    }
  });

  it('derives a slug from a name', () => {
    expect(academySlugFrom('Jyotish Vidya Peetham')).toBe('jyotish-vidya-peetham');
    expect(academySlugFrom('  KP & Nadi — Advanced!  ')).toBe('kp-nadi-advanced');
  });
});
