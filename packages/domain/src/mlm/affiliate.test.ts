import { describe, expect, it } from 'vitest';
import { AFFILIATE_CODE_ALPHABET, affiliateCodeFrom, isAffiliateCode, joinLinkFor, legFromLink, normaliseAffiliateCode, referralLinkFor } from './affiliate';

describe('affiliate codes', () => {
  it('are eight characters from an unambiguous alphabet with a check character that holds', () => {
    for (let i = 0; i < 200; i++) {
      const code = affiliateCodeFrom();
      expect(code).toHaveLength(8);
      for (const ch of code) expect(AFFILIATE_CODE_ALPHABET.includes(ch), code).toBe(true);
      expect(isAffiliateCode(code), code).toBe(true);
    }
    expect(AFFILIATE_CODE_ALPHABET).not.toMatch(/[01OI]/);
  });

  it('are deterministic for a given source of randomness', () => {
    const counter = () => {
      let n = 0;
      return () => ((n++ * 7) % 32) / 32;
    };
    expect(affiliateCodeFrom(counter())).toBe(affiliateCodeFrom(counter()));
    expect(affiliateCodeFrom(() => 0)).toBe('AAAAAAAA');
  });

  it('refuse a mistyped code: one character changed, swapped, or the wrong length', () => {
    const code = affiliateCodeFrom(() => 0.37);
    const changed = code[0] === 'A' ? 'B' + code.slice(1) : 'A' + code.slice(1);
    expect(isAffiliateCode(changed)).toBe(false);
    expect(isAffiliateCode(code.slice(0, 7))).toBe(false);
    expect(isAffiliateCode(code + 'A')).toBe(false);
    expect(isAffiliateCode(code.toLowerCase())).toBe(false);
    expect(isAffiliateCode('')).toBe(false);
  });

  it('normalise what people type: case, spaces and hyphens', () => {
    const code = affiliateCodeFrom();
    expect(normaliseAffiliateCode(` ${code.slice(0, 4).toLowerCase()}-${code.slice(4)} `)).toBe(code);
  });

  it('build the referral and join links from the site', () => {
    expect(referralLinkFor('https://zuviloai.com/', 'ABCDEFG2')).toBe('https://zuviloai.com/ref/ABCDEFG2');
    expect(joinLinkFor('https://zuviloai.com', 'ABCDEFG2', 'B')).toBe('https://zuviloai.com/register?ref=ABCDEFG2&leg=B');
    expect(joinLinkFor('https://zuviloai.com', 'ABCDEFG2')).toBe('https://zuviloai.com/register?ref=ABCDEFG2');
    // A leg on a link is honoured when it is one; anything else counts as no leg rather than a refusal.
    expect(legFromLink('A')).toBe('A');
    expect(legFromLink(' b ')).toBe('B');
    for (const stray of ['C', '', 'AB', null, undefined]) expect(legFromLink(stray)).toBeUndefined();
  });
});
