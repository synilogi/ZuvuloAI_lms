import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { calendarService as service } from './calendar';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

const SEPTEMBER = { from: '2026-09-01', to: '2026-09-30' };

describe('calendar mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('brings every kind of event together, with reminders only for their owner', async () => {
    const admin = await settle(service.list({ ...SEPTEMBER, viewerId: 'u-kavita' }));
    expect(Object.values(admin.counts).every((n) => n > 0)).toBe(true);
    expect(admin.total).toBe(admin.rows.length);
    expect(admin.rows.filter((r) => r.event.type === 'reminder').every((r) => r.event.ownerId === 'u-kavita')).toBe(true);
    expect(admin.rows.every((r, i) => i === 0 || admin.rows[i - 1].event.startsAt <= r.event.startsAt)).toBe(true);

    const teaching = await settle(service.list({ ...SEPTEMBER, viewerId: 'u-meenakshi', scopeInstructorId: 'meenakshi' }));
    expect(teaching.total).toBeLessThan(admin.total);
    expect(teaching.rows.some((r) => r.event.ownerId === 'u-kavita')).toBe(false);
    expect(teaching.rows.filter((r) => r.event.type === 'live').every((r) => r.courseTitle)).toBe(true);
  });

  it('counts types before the type filter so hidden events stay visible in the chips', async () => {
    const live = await settle(service.list({ ...SEPTEMBER, viewerId: 'u-kavita', types: ['live'] }));
    const all = await settle(service.list({ ...SEPTEMBER, viewerId: 'u-kavita' }));
    expect(live.rows.every((r) => r.event.type === 'live')).toBe(true);
    expect(live.counts).toEqual(all.counts);
    const none = await settle(service.list({ ...SEPTEMBER, viewerId: 'u-kavita', types: [] }));
    expect(none.rows).toHaveLength(0);
    expect(none.total).toBe(all.total);
  });

  it('explains deadlines with who is due and who has handed in', async () => {
    const detail = await settle(service.get('due.asg-dasha-c3-l4', 'u-kavita'));
    expect(detail.editable).toBe(false);
    expect(detail.due!.learners).toBeGreaterThan(detail.due!.submitted);
    expect(detail.learnersDue?.[0].submitted).toBe(false);
    const quiz = await settle(service.get('sit-foundations-ch3', 'u-kavita'));
    expect(quiz.quiz?.questions).toBeGreaterThan(0);
    expect(quiz.editable).toBe(true);
  });

  it('adds, completes, changes and deletes a reminder, and leaves derived events alone', async () => {
    const input = {
      type: 'reminder' as const,
      title: 'Plan the Diwali break',
      timing: 'all-day' as const,
      startsAt: '2026-10-15T00:00:00+05:30',
      audience: 'me' as const,
    };
    const created = await settle(service.create(input, 'u-kavita'));
    expect(created.ownerId).toBe('u-kavita');
    expect((await settle(service.setDone(created.id, true))).done).toBe(true);
    const updated = await settle(
      service.update(created.id, { ...input, title: 'Plan the Diwali break rota', timing: 'moment', startsAt: '2026-10-15T11:00:00+05:30' }),
    );
    expect(updated.title).toBe('Plan the Diwali break rota');
    expect(updated.timing).toBe('moment');

    const october = { from: '2026-10-01', to: '2026-10-31' };
    expect((await settle(service.list({ ...october, viewerId: 'u-meenakshi' }))).rows.some((r) => r.event.id === created.id)).toBe(false);
    await settle(service.remove(created.id));
    expect((await settle(service.list({ ...october, viewerId: 'u-kavita' }))).rows.some((r) => r.event.id === created.id)).toBe(false);

    const refused = service.update('live.lc-upcoming', input);
    const expectation = expect(refused).rejects.toThrow('its own page');
    await vi.runAllTimersAsync();
    await expectation;
    const past = service.create({ ...input, startsAt: '2026-09-01T00:00:00+05:30' }, 'u-kavita');
    const pastExpectation = expect(past).rejects.toThrow('already passed');
    await vi.runAllTimersAsync();
    await pastExpectation;
  });
});
