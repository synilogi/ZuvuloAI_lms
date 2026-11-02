import { describe, expect, it } from 'vitest';

import { DELIVERY_BACKOFF_MIN, nextDeliveryAttempt, quietHoursEnd } from './notification';

// 16:30Z is 22:00 IST; 01:30Z is 07:00 IST.
const at = (iso: string) => new Date(iso);

describe('quiet hours', () => {
  const overnight = { enabled: true, from: '22:00', to: '07:00' };

  it('holds messages from the start of quiet hours until they end, across midnight, in IST', () => {
    expect(quietHoursEnd(overnight, at('2026-09-23T16:29:00Z'))).toBeNull();
    expect(quietHoursEnd(overnight, at('2026-09-23T16:30:00Z'))?.toISOString()).toBe('2026-09-24T01:30:00.000Z');
    expect(quietHoursEnd(overnight, at('2026-09-23T20:00:00Z'))?.toISOString()).toBe('2026-09-24T01:30:00.000Z');
    expect(quietHoursEnd(overnight, at('2026-09-24T01:29:00Z'))?.toISOString()).toBe('2026-09-24T01:30:00.000Z');
    expect(quietHoursEnd(overnight, at('2026-09-24T01:30:00Z'))).toBeNull();
  });

  it('handles a daytime window and ignores quiet hours that are off or empty', () => {
    const lunch = { enabled: true, from: '13:00', to: '14:00' }; // 07:30Z–08:30Z
    expect(quietHoursEnd(lunch, at('2026-09-23T07:45:00Z'))?.toISOString()).toBe('2026-09-23T08:30:00.000Z');
    expect(quietHoursEnd(lunch, at('2026-09-23T09:00:00Z'))).toBeNull();
    expect(quietHoursEnd({ ...overnight, enabled: false }, at('2026-09-23T20:00:00Z'))).toBeNull();
    expect(quietHoursEnd({ enabled: true, from: '10:00', to: '10:00' }, at('2026-09-23T04:30:00Z'))).toBeNull();
    expect(quietHoursEnd(undefined, at('2026-09-23T20:00:00Z'))).toBeNull();
  });
});

describe('delivery retries', () => {
  it('backs off after each failure and stops when the attempts are used', () => {
    const now = at('2026-09-23T10:00:00Z');
    expect(nextDeliveryAttempt(1, now)?.toISOString()).toBe('2026-09-23T10:01:00.000Z');
    expect(nextDeliveryAttempt(3, now)?.toISOString()).toBe('2026-09-23T10:30:00.000Z');
    expect(nextDeliveryAttempt(DELIVERY_BACKOFF_MIN.length, now)?.toISOString()).toBe('2026-09-23T22:00:00.000Z');
    expect(nextDeliveryAttempt(DELIVERY_BACKOFF_MIN.length + 1, now)).toBeNull();
  });
});
