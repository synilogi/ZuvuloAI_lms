import type { Enrollment, Student } from '@syniastrolms/domain';

import type { StudentActivity, StudentAdminService, StudentListResult, StudentProfile, StudentProgress } from '../contracts';
import { del, get, patch, post } from './client';

export const httpStudents: StudentAdminService = {
  list: (query) => get<StudentListResult>('/students', query),
  get: (id, scopeInstructorId) => get<StudentProfile>(`/students/${id}`, { scopeInstructorId }),
  progress: (id, scopeInstructorId) => get<StudentProgress>(`/students/${id}/progress`, { scopeInstructorId }),
  activity: (id, query) => get<StudentActivity>(`/students/${id}/activity`, query),
  message: (ids, message) => post<{ sent: number }>('/students/message', { ids, ...message }),
  enroll: (id, courseId, source) => post<Enrollment>(`/students/${id}/enroll`, { courseId, source }),
  setEnrollmentStatus: (enrollmentId, status) => patch<Enrollment>(`/students/enrollments/${enrollmentId}`, { status }),
  removeEnrollment: (enrollmentId) => del<void>(`/students/enrollments/${enrollmentId}`),
  setSuspended: (id, suspended, reason) => post<Student>(`/students/${id}/suspend`, { suspended, reason }),
  create: (input) => post<Student>('/students', input),
  resendInvite: (id) => post<{ sentTo: string }>(`/students/${id}/resend-invite`),
};
