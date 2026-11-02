import type { Instructor, InstructorStatus } from '@syniastrolms/domain';

import type { InstructorAdminService, InstructorProfile, InstructorRequest, InstructorRow } from '../contracts';
import { get, patch, post } from './client';

export const httpInstructors: InstructorAdminService = {
  list: (query) => get<{ rows: InstructorRow[]; counts: Record<InstructorStatus | 'all', number>; expertise: string[] }>('/instructors', query),
  get: (id) => get<InstructorProfile>(`/instructors/${id}`),
  create: (input) => post<Instructor>('/instructors', input),
  update: (id, input) => patch<Instructor>(`/instructors/${id}`, input),
  setStatus: (id, status) => post<Instructor>(`/instructors/${id}/status`, { status }),
  resendInvite: (id) => post<{ sentTo: string }>(`/instructors/${id}/resend-invite`),
  requests: (status) => get<InstructorRequest[]>('/instructors/requests', status ? { status } : undefined),
  approveRequest: (id) => post<{ id: string; status: 'active' }>(`/instructors/requests/${encodeURIComponent(id)}/approve`),
  rejectRequest: (id) => post<InstructorRequest>(`/instructors/requests/${encodeURIComponent(id)}/reject`),
};
