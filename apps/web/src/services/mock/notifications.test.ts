import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { notificationService as service } from './notifications';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('notification mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('keeps each person’s notifications apart, newest first, with unread counts', async () => {
    const learner = await settle(service.list({ recipientId: 'u-ananya', limit: 50 }));
    expect(learner.rows.every((n) => n.recipientId === 'u-ananya')).toBe(true);
    expect(learner.rows.every((n, i) => i === 0 || learner.rows[i - 1].createdAt >= n.createdAt)).toBe(true);
    expect(learner.unread).toBeGreaterThan(0);
    expect(Object.values(learner.counts).reduce((a, b) => a + b, 0)).toBe(learner.total);

    const unreadLive = await settle(service.list({ recipientId: 'u-ananya', unreadOnly: true, category: 'live', limit: 50 }));
    expect(unreadLive.rows.every((n) => n.category === 'live' && !n.readAt)).toBe(true);
    const teaching = await settle(service.list({ recipientId: 'u-meenakshi', limit: 1 }));
    expect(teaching.rows).toHaveLength(1);
    expect(teaching.total).toBeGreaterThan(1);
  });

  it('reads, removes, restores and clears', async () => {
    const before = await settle(service.list({ recipientId: 'u-kavita', limit: 50 }));
    const first = before.rows.find((n) => !n.readAt)!;
    await settle(service.setRead([first.id], true));
    expect((await settle(service.list({ recipientId: 'u-kavita', limit: 50 }))).unread).toBe(before.unread - 1);

    await settle(service.remove([first.id]));
    expect((await settle(service.list({ recipientId: 'u-kavita', limit: 50 }))).total).toBe(before.total - 1);
    await settle(service.restore([first]));
    const detail = await settle(service.get(first.id, 'u-kavita'));
    expect(detail.notification.title).toBe(first.title);
    expect(detail.related.every((r) => r.category === first.category)).toBe(true);

    const marked = await settle(service.markAllRead('u-kavita'));
    expect(marked).toBeGreaterThan(0);
    const cleared = await settle(service.clear('u-kavita', { category: 'system' }));
    expect(cleared).toBeGreaterThan(0);
    expect((await settle(service.list({ recipientId: 'u-kavita', category: 'system', limit: 50 }))).total).toBe(0);
  });

  it('saves preferences and refuses switching off account notices', async () => {
    const settings = await settle(service.getSettings('u-ananya'));
    expect(settings.smsNumber).toMatch(/^\+91/);
    const { smsNumber: _number, ...rest } = settings;
    expect(_number).toBeTruthy();
    const next = {
      ...rest,
      emailDigest: 'weekly' as const,
      categories: rest.categories.map((c) => (c.category === 'quiz' ? { ...c, channels: { ...c.channels, sms: true } } : c)),
    };
    const saved = await settle(service.saveSettings('u-ananya', next));
    expect(saved.emailDigest).toBe('weekly');
    expect((await settle(service.get('ntf-l-07', 'u-ananya'))).channels.sms).toBe(true);

    const locked = { ...rest, categories: rest.categories.map((c) => (c.category === 'system' ? { ...c, channels: { ...c.channels, app: false } } : c)) };
    const refused = service.saveSettings('u-ananya', locked);
    const expectation = expect(refused).rejects.toThrow('Account and security');
    await vi.runAllTimersAsync();
    await expectation;
  });
});
