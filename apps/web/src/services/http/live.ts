import type { LiveClass } from '@syniastrolms/domain';

import type { LearnerLive, LiveClassService, LiveDetail, LiveJoin, LiveRow, LiveView, RoomJoin } from '../contracts';
import type { LiveClassPhase } from '@syniastrolms/domain';
import { API_BASE_URL, get, patch, post } from './client';

export const httpLive: LiveClassService = {
  list: (query) => get<{ rows: LiveRow[]; total: number; counts: Record<LiveView, number> }>('/live', query),
  get: (id, scopeInstructorId) => get<LiveDetail>(`/live/${id}`, { scopeInstructorId }),
  create: (input) => post<LiveClass>('/live', input),
  update: (id, input) => patch<LiveClass>(`/live/${id}`, input),
  cancel: (id, reason) => post<LiveClass>(`/live/${id}/cancel`, { reason }),
  sendReminder: (id) => post<{ sent: number }>(`/live/${id}/remind`),
  setReminders: (id, reminders) => patch<LiveClass>(`/live/${id}/reminders`, { reminders }),
  forLearner: () => get<LearnerLive>('/live/learner'),
  register: (id, registered) => post<{ registered: boolean; spotsLeft: number }>(`/live/${id}/register`, { registered }),
  start: (id) => post<{ liveClass: LiveClass; phase: LiveClassPhase; room: RoomJoin }>(`/live/${id}/start`),
  join: (id) => post<LiveJoin>(`/live/${id}/join`),
  end: (id) => post<{ liveClass: LiveClass; phase: LiveClassPhase }>(`/live/${id}/end`),
  recordingLink: async (id) => {
    const { url } = await post<{ url: string }>(`/live/${id}/recording/link`);
    return { url: `${API_BASE_URL}${url}` };
  },
};
