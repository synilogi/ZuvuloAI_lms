import type { AssignmentStatus, CourseAssignment, Submission } from '@syniastrolms/domain';

import type { AssignmentAdminService, AssignmentRow, ReviewSummary, SubmissionDetail, SubmissionListResult } from '../contracts';
import { del, get, patch, post } from './client';

export const httpAssignments: AssignmentAdminService = {
  list: (query) => get<{ rows: AssignmentRow[]; counts: Record<AssignmentStatus | 'all', number> }>('/assignments', query),
  get: (id) => get<CourseAssignment>(`/assignments/${id}`),
  create: (input) => post<CourseAssignment>('/assignments', input),
  update: (id, input) => patch<CourseAssignment>(`/assignments/${id}`, input),
  duplicate: (id) => post<CourseAssignment>(`/assignments/${id}/duplicate`),
  remove: (id) => del<void>(`/assignments/${id}`),
  submissions: (query) =>
    query.assignmentId
      ? get<SubmissionListResult>(`/assignments/${query.assignmentId}/submissions`, query)
      : get<SubmissionListResult>('/assignments/submissions', query),
  submission: (id, scopeInstructorId) => get<SubmissionDetail>(`/assignments/submissions/${id}`, { scopeInstructorId }),
  review: (id, input) => post<Submission>(`/assignments/submissions/${id}/review`, input),
  remind: (assignmentId, studentIds) => post<{ sent: number }>(`/assignments/${assignmentId}/remind`, { studentIds }),
  summary: (scopeInstructorId) => get<ReviewSummary>('/assignments/review', { scopeInstructorId }),
};
