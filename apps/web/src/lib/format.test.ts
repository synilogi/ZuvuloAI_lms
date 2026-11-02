import { describe, expect, it } from 'vitest';
import { formatClock, formatDuration, formatRelative, initials, roman } from './format';

describe('format', () => {
  it('formats durations the way the curriculum reads them', () => {
    expect(formatDuration(17)).toBe('17 min');
    expect(formatDuration(60)).toBe('1h');
    expect(formatDuration(935)).toBe('15h 35m');
    expect(formatDuration(62)).toBe('1h 02m');
  });

  it('formats playback positions', () => {
    expect(formatClock(561)).toBe('9:21');
    expect(formatClock(3725)).toBe('1:02:05');
  });

  it('describes time relative to now', () => {
    const now = new Date('2026-09-15T18:52:00+05:30');
    expect(formatRelative('2026-09-15T19:00:00+05:30', now)).toBe('in 8 minutes');
    expect(formatRelative('2026-09-17T19:00:00+05:30', now)).toBe('in 2 days');
  });

  it('builds initials without honorifics, and roman rank numerals', () => {
    expect(initials('Dr. Meenakshi Iyer')).toBe('MI');
    expect(initials('Acharya Vinod Shastri')).toBe('VS');
    expect(roman(4)).toBe('IV');
  });
});
