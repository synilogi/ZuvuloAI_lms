import { describe, expect, it } from 'vitest';

import { safeNext } from './safeNext';

/* `?next=` is whatever the address bar says, so signing in must never carry someone off the site. */

const HOME = '/home';

describe('safeNext', () => {
  it('follows a path on this site', () => {
    expect(safeNext('/admin/reports', HOME)).toBe('/admin/reports');
    expect(safeNext('/learn/course-1?tab=notes', HOME)).toBe('/learn/course-1?tab=notes');
    expect(safeNext('/teach', HOME)).toBe('/teach');
  });

  it('falls back when there is nothing to go back to', () => {
    expect(safeNext(null, HOME)).toBe(HOME);
    expect(safeNext('', HOME)).toBe(HOME);
  });

  it('refuses anything that leads off the site', () => {
    // Absolute URLs.
    expect(safeNext('https://example.test', HOME)).toBe(HOME);
    expect(safeNext('javascript:alert(1)', HOME)).toBe(HOME);
    // Protocol-relative, in both spellings — a browser reads `/\` as `//`.
    expect(safeNext('//example.test', HOME)).toBe(HOME);
    expect(safeNext('/\\example.test', HOME)).toBe(HOME);
    expect(safeNext('/\\\\example.test', HOME)).toBe(HOME);
    // A backslash or a control character anywhere.
    expect(safeNext('/admin\\..\\example.test', HOME)).toBe(HOME);
    expect(safeNext('/admin\n/reports', HOME)).toBe(HOME);
    expect(safeNext('/admin\treports', HOME)).toBe(HOME);
    // Relative values that would resolve against the current page.
    expect(safeNext('admin', HOME)).toBe(HOME);
  });
});
