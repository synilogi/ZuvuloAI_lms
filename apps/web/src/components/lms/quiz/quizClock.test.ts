import { describe, expect, it } from 'vitest';

import { deadlineFrom, newStartKey, secondsLeft, timerTone, warningPassed } from './quizClock';

/* The countdown is the server's figure measured on the monotonic clock from when its answer arrived — never the
 * device's wall clock, which may be set wrong. */

const view = (over: Partial<{ remainingSec: number; deadlineAt: string; serverNow: string }> = {}) => ({
  serverNow: '2026-10-26T07:46:37.236Z',
  deadlineAt: '2026-10-26T08:01:37.229Z',
  remainingSec: 899,
  ...over,
});

describe('the quiz countdown', () => {
  it('runs out where the server says, from the moment its answer arrived', () => {
    // 899.993 s by the server's own two clocks, from a monotonic 5000 ms.
    const ends = deadlineFrom(view(), 5000)!;
    expect(ends).toBeCloseTo(5000 + 899_993, 0);
    expect(secondsLeft(ends, 5000)).toBe(900);
    expect(secondsLeft(ends, 5000 + 60_000)).toBe(840);
    expect(secondsLeft(ends, ends - 1)).toBe(1);
    expect(secondsLeft(ends, ends)).toBe(0);
    expect(secondsLeft(ends, ends + 10_000)).toBe(0);
  });

  it('ignores the device clock: a device an hour fast reads the same time left', () => {
    const realNow = Date.now;
    try {
      Date.now = () => realNow() + 3_600_000;
      expect(secondsLeft(deadlineFrom(view(), 1000)!, 1000)).toBe(900);
    } finally {
      Date.now = realNow;
    }
  });

  it('falls back to the whole seconds left when the moments are missing, and is absent for an untimed attempt', () => {
    expect(deadlineFrom({ remainingSec: 42, serverNow: '2026-10-26T07:46:37.236Z' }, 100)).toBe(42_100);
    expect(deadlineFrom({ serverNow: '2026-10-26T07:46:37.236Z' }, 100)).toBeNull();
    // A deadline already past by the server's clock is no time at all, never negative.
    expect(deadlineFrom(view({ deadlineAt: '2026-10-26T07:40:00.000Z', remainingSec: 0 }), 100)).toBe(100);
  });

  it('is set again by a later answer: the newest server figure wins', () => {
    const first = deadlineFrom(view(), 0)!;
    // Thirty seconds later on this clock, the server says 860 s are left (the tab slept): the countdown follows it.
    const later = deadlineFrom(view({ serverNow: '2026-10-26T07:47:17.229Z', remainingSec: 860 }), 30_000)!;
    expect(secondsLeft(first, 30_000)).toBe(870);
    expect(secondsLeft(later, 30_000)).toBe(860);
  });

  it('announces five minutes and one minute left once each, as the clock passes them', () => {
    expect(warningPassed(301, 300)).toBe(300);
    expect(warningPassed(300, 299)).toBeNull();
    expect(warningPassed(61, 60)).toBe(60);
    expect(warningPassed(400, 250)).toBe(300);
    expect(warningPassed(null, 60)).toBeNull();
    expect(warningPassed(2, 0)).toBeNull();
    expect(timerTone(900)).toBe('calm');
    expect(timerTone(300)).toBe('warn');
    expect(timerTone(60)).toBe('low');
  });
});

describe('start keys', () => {
  it('are new for every press and fit what the API accepts (8 to 100 characters)', () => {
    const keys = Array.from({ length: 50 }, newStartKey);
    expect(new Set(keys).size).toBe(keys.length);
    for (const key of keys) {
      expect(key.length).toBeGreaterThanOrEqual(8);
      expect(key.length).toBeLessThanOrEqual(100);
    }
  });
});
