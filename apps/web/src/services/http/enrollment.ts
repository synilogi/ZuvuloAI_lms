import type { EnrollmentService } from '../contracts';
import { post } from './client';

export const httpEnrollment: EnrollmentService = {
  enroll: async (courseId) => {
    const result = await post<{ enrollment: { enrolledAt: string } }>(`/learning/courses/${courseId}/enroll`);
    return { courseId, enrolledAt: result.enrollment.enrolledAt };
  },
};
