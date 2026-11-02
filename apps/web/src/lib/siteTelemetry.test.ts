import { describe, expect, it } from 'vitest';
import { asksNotToBeTracked, firstReport } from './siteTelemetry';

describe('what the website reports', () => {
  it('respects a browser that asks not to be tracked', () => {
    expect(asksNotToBeTracked({ doNotTrack: '1' })).toBe(true);
    expect(asksNotToBeTracked({ globalPrivacyControl: true })).toBe(true);
    expect(asksNotToBeTracked({ doNotTrack: '0' })).toBe(false);
    expect(asksNotToBeTracked({})).toBe(false);
  });

  it('reports each error once, and only a few from one page', () => {
    const seen = new Set<string>();
    expect(firstReport('a', seen, 2)).toBe(true);
    expect(firstReport('a', seen, 2)).toBe(false);
    expect(firstReport('b', seen, 2)).toBe(true);
    expect(firstReport('c', seen, 2)).toBe(false);
  });
});
