import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { mockNow } from './clock';
import { liveClassService as service } from './live';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('live class mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    // The mock clock counts from when it loaded, so fake timers keep real time as their start.
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('splits the schedule into upcoming, live, history and cancelled', async () => {
    const upcoming = await settle(service.list({ page: 1, pageSize: 50 }));
    expect(upcoming.counts.live).toBe(1);
    expect(upcoming.counts.history).toBeGreaterThan(30);
    expect(upcoming.counts.cancelled).toBeGreaterThan(0);
    expect(upcoming.rows[0].liveClass.startsAt <= upcoming.rows[1].liveClass.startsAt).toBe(true);
    const history = await settle(service.list({ view: 'history', page: 1, pageSize: 5 }));
    expect(history.rows.every((r) => r.phase === 'ended' || r.phase === 'recording-expired')).toBe(true);
    const teaching = await settle(service.list({ view: 'history', scopeInstructorId: 'meenakshi', page: 1, pageSize: 50 }));
    expect(teaching.total).toBeLessThan(history.total);
  });

  it('shows attendees, agenda and neighbouring sessions', async () => {
    const detail = await settle(service.get('lc-ended'));
    expect(detail.phase).toBe('ended');
    expect(detail.attendees.length).toBeGreaterThan(0);
    expect(detail.attendees.some((a) => a.attended !== undefined)).toBe(true);
    expect(detail.liveClass.agenda?.length).toBe(3);
    expect((detail.next?.startsAt ?? '') > detail.liveClass.startsAt).toBe(true);
  });

  it('schedules, refuses past times and protects registered seats', async () => {
    const input = {
      courseId: 'dasha',
      title: 'Pratyantardasha clinic',
      instructorId: 'vinod',
      startsAt: '2026-09-25T19:00:00+05:30',
      durationMin: 60,
      capacity: 80,
      meeting: { kind: 'room' as const },
    };
    const created = await settle(service.create(input));
    expect(created.registered).toBe(0);
    const past = expect(service.create({ ...input, startsAt: '2026-09-01T19:00:00+05:30' })).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await past;
    const shrink = expect(service.update('lc-dasha-antar', { ...input, capacity: 20 })).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await shrink;
    const cancelled = await settle(service.cancel(created.id, 'Moved into next week’s workshop instead.'));
    expect(cancelled.cancelled).toBe(true);
  });

  it('gives the learner live, upcoming and recordings, and toggles registration', async () => {
    const mine = await settle(service.forLearner());
    expect(mine.live.map((r) => r.liveClass.id)).toContain('lc-live');
    expect(mine.upcoming.find((r) => r.liveClass.id === 'lc-upcoming')?.registered).toBe(true);
    expect(mine.recordings.length).toBeGreaterThan(0);
    const off = await settle(service.register('lc-upcoming', false));
    expect(off.registered).toBe(false);
    // The state wanted, not a toggle: asking twice lands in the same place.
    expect((await settle(service.register('lc-upcoming', false))).registered).toBe(false);
    expect((await settle(service.register('lc-upcoming', true))).registered).toBe(true);
    expect((await settle(service.register('lc-upcoming', true))).registered).toBe(true);
    const full = expect(service.register('lc-muhurta-griha', true)).resolves.toBeTruthy();
    await vi.runAllTimersAsync();
    await full;
  });

  it('keeps an outside meeting’s link out of the learner’s data and hands it over only from join, inside the window', async () => {
    const soon = new Date(mockNow().getTime() + 10 * 60_000).toISOString();
    const later = new Date(mockNow().getTime() + 2 * 86_400_000).toISOString();
    const base = {
      courseId: 'foundations-vedic',
      title: 'Outside meeting check',
      instructorId: 'meenakshi',
      durationMin: 60,
      meeting: { kind: 'external' as const, link: 'https://zoom.us/j/123456' },
      visibility: 'public' as const,
    };
    const open = await settle(service.create({ ...base, startsAt: soon }));
    const closed = await settle(service.create({ ...base, title: 'Outside meeting, later', startsAt: later }));

    const mine = await settle(service.forLearner());
    const seen = [...mine.live, ...mine.upcoming].map((r) => r.liveClass).filter((c) => c.id === open.id || c.id === closed.id);
    expect(seen).toHaveLength(2);
    for (const c of seen) expect(c.meeting).toEqual({ kind: 'external', linkHost: 'zoom.us' });

    expect(await settle(service.join(open.id))).toEqual({ kind: 'external', link: 'https://zoom.us/j/123456' });
    const early = expect(service.join(closed.id)).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await early;
  });

  it('clears a capacity, description and chapter sent as null, and keeps them when left out', async () => {
    const input = {
      courseId: 'foundations-vedic',
      title: 'Clearing check',
      instructorId: 'meenakshi',
      startsAt: new Date(mockNow().getTime() + 3 * 86_400_000).toISOString(),
      durationMin: 60,
      capacity: 30,
      description: 'Bring your questions.',
      meeting: { kind: 'room' as const },
    };
    const created = await settle(service.create(input));
    const kept = await settle(service.update(created.id, { ...input, title: 'Clearing check, renamed', capacity: undefined, description: undefined }));
    expect(kept).toMatchObject({ capacity: 30, description: 'Bring your questions.' });
    const cleared = await settle(service.update(created.id, { ...input, capacity: null, description: null, chapterId: null }));
    expect(cleared.capacity).toBeUndefined();
    expect(cleared.description).toBeUndefined();
    expect(cleared.chapterId).toBeUndefined();
    // The moment comes back in UTC and is the one sent.
    expect(Date.parse(cleared.startsAt)).toBe(Date.parse(input.startsAt));
  });

  it('names the field when the server-side checks refuse a class', async () => {
    const refused = service.create({
      courseId: 'foundations-vedic',
      title: 'x',
      instructorId: 'meenakshi',
      startsAt: new Date(mockNow().getTime() + 86_400_000).toISOString(),
      durationMin: 60,
    });
    const check = expect(refused).rejects.toMatchObject({ code: 'conflict', issues: [{ field: 'title' }] });
    await vi.runAllTimersAsync();
    await check;
  });

  it('lists what is coming soonest first, and what is over latest first', async () => {
    const upcoming = (await settle(service.list({ view: 'upcoming', page: 1, pageSize: 50 }))).rows.map((r) => r.liveClass.startsAt);
    expect([...upcoming].sort()).toEqual(upcoming);
    const history = (await settle(service.list({ view: 'history', page: 1, pageSize: 50 }))).rows.map((r) => r.liveClass.startsAt);
    expect([...history].sort().reverse()).toEqual(history);
  });
});
