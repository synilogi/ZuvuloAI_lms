import type { NotificationSettings } from '@syniastrolms/domain';

import type { NotificationDetail, NotificationPage, NotificationService } from '../contracts';
import { get, post, put } from './client';

/* The API always scopes notifications to the signed-in account (from the token), so the
 * recipient ids the contract carries for the mock implementation are not sent. */
export const httpNotifications: NotificationService = {
  list: ({ recipientId: _recipientId, ...query }) => get<NotificationPage>('/notifications', query),
  get: (id) => get<NotificationDetail>(`/notifications/${id}`),
  setRead: (ids, read) => post<void>('/notifications/read', { ids, read }),
  markAllRead: (_recipientId, category) => post<number>('/notifications/read-all', { category }),
  remove: (ids) => post<void>('/notifications/remove', { ids }),
  restore: (notifications) => post<void>('/notifications/restore', { notifications }),
  clear: (_recipientId, filter) => post<number>('/notifications/clear', { ...filter }),
  getSettings: () => get<NotificationSettings & { smsNumber: string }>('/notifications/settings/me'),
  saveSettings: (_recipientId, settings) => put<NotificationSettings>('/notifications/settings/me', settings),
};
