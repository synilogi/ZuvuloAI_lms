import type { CalendarEvent, CalendarEventType } from '@syniastrolms/domain';

import type { CalendarDetail, CalendarRow, CalendarService } from '../contracts';
import { del, get, patch, post } from './client';

/* Owner and viewer are always the signed-in account on the API side, so those ids are not sent. */
export const httpCalendar: CalendarService = {
  list: ({ viewerId: _viewerId, ...query }) => get<{ rows: CalendarRow[]; counts: Record<CalendarEventType, number>; total: number }>('/calendar', query),
  get: (id, _viewerId, scopeInstructorId) => get<CalendarDetail>(`/calendar/${id}`, { scopeInstructorId }),
  create: (input) => post<CalendarEvent>('/calendar', { input }),
  update: (id, input) => patch<CalendarEvent>(`/calendar/${id}`, input),
  remove: (id) => del<void>(`/calendar/${id}`),
  setDone: (id, done) => post<CalendarEvent>(`/calendar/${id}/done`, { done }),
};
