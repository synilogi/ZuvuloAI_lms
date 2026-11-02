import type { AppNotification, NotificationCategory, NotificationSettings } from '@syniastrolms/domain';
import { NOTIFICATION_CATEGORIES, validateNotificationSettings } from '@syniastrolms/domain';
import type { NotificationService } from '../contracts';
import { ServiceError } from '../contracts';
import { mockNowIso } from './clock';
import { notificationStore, saveSettingsFor, settingsFor, SMS_NUMBERS } from './fixtures/notifications';
import { respond, scenario } from './simulation';

const zeroCounts = () => Object.fromEntries(NOTIFICATION_CATEGORIES.map((c) => [c, 0])) as Record<NotificationCategory, number>;
const mine = (recipientId: string) => notificationStore().filter((n) => n.recipientId === recipientId);
const clone = (s: NotificationSettings): NotificationSettings => JSON.parse(JSON.stringify(s));
/** Copies, as an API would return — later changes to the store don’t leak into screens. */
const copy = (n: AppNotification): AppNotification => ({ ...n, body: [...n.body], facts: n.facts?.map((f) => ({ ...f })) });

export const notificationService: NotificationService = {
  list: ({ recipientId, unreadOnly, category, limit }) =>
    respond(() => {
      const counts = zeroCounts();
      if (scenario() === 'empty') return { rows: [], total: 0, unread: 0, counts };
      const all = mine(recipientId);
      const pool = all.filter((n) => !unreadOnly || !n.readAt);
      for (const n of pool) counts[n.category] += 1;
      const matching = pool.filter((n) => !category || n.category === category);
      return { rows: matching.slice(0, limit).map(copy), total: matching.length, unread: all.filter((n) => !n.readAt).length, counts };
    }, 380),

  get: (id, recipientId) =>
    respond(() => {
      const notification = mine(recipientId).find((n) => n.id === id);
      if (!notification) throw new ServiceError('This notification doesn’t exist or was removed.', 'not-found');
      const related = mine(recipientId)
        .filter((n) => n.category === notification.category && n.id !== id)
        .slice(0, 3);
      const channels = settingsFor(recipientId).categories.find((c) => c.category === notification.category)!.channels;
      return { notification: copy(notification), related: related.map(copy), channels: { ...channels } };
    }, 320),

  setRead: (ids, read) =>
    respond(() => {
      const at = mockNowIso();
      for (const n of notificationStore()) if (ids.includes(n.id)) n.readAt = read ? (n.readAt ?? at) : undefined;
    }, 200),

  markAllRead: (recipientId, category) =>
    respond(() => {
      const at = mockNowIso();
      const unread = mine(recipientId).filter((n) => !n.readAt && (!category || n.category === category));
      for (const n of unread) n.readAt = at;
      return unread.length;
    }, 350),

  remove: (ids) =>
    respond(() => {
      const store = notificationStore();
      for (let i = store.length - 1; i >= 0; i--) if (ids.includes(store[i].id)) store.splice(i, 1);
    }, 250),

  restore: (items: AppNotification[]) =>
    respond(() => {
      const store = notificationStore();
      for (const n of items) if (!store.some((x) => x.id === n.id)) store.push(copy(n));
      store.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    }, 250),

  clear: (recipientId, filter = {}) =>
    respond(() => {
      const store = notificationStore();
      let removed = 0;
      for (let i = store.length - 1; i >= 0; i--) {
        const n = store[i];
        if (n.recipientId === recipientId && (!filter.category || n.category === filter.category) && (!filter.unreadOnly || !n.readAt)) {
          store.splice(i, 1);
          removed += 1;
        }
      }
      return removed;
    }, 500),

  getSettings: (recipientId) => respond(() => ({ ...clone(settingsFor(recipientId)), smsNumber: SMS_NUMBERS[recipientId] ?? '' }), 420),

  saveSettings: (recipientId, next) =>
    respond(() => {
      const issues = validateNotificationSettings(next);
      if (issues.length) throw new ServiceError(issues[0].message, 'conflict');
      const saved = clone(next);
      if (saved.pausedUntil && saved.pausedUntil <= mockNowIso()) delete saved.pausedUntil;
      saveSettingsFor(recipientId, saved);
      return clone(saved);
    }, 650),
};
