import type { CourseSalesRow, StaffCourseReview, StaffCourseReviewPage } from '@syniastrolms/domain';
import type {
  CourseReport,
  CourseReportRow,
  EnrolmentReport,
  InstructorReport,
  LearnerReport,
  ReportContext,
  ReportOverview,
  ReportsService,
} from '../contracts';
import { get, post } from './client';

export const httpReports: ReportsService = {
  courseSales: () => get<CourseSalesRow[]>('/reports/course-sales'),
  overview: (filters) => get<ReportOverview>(`/reports/overview`, filters as unknown as Record<string, unknown>),
  courses: (filters) => get<ReportContext & { rows: CourseReportRow[] }>('/reports/courses', filters as unknown as Record<string, unknown>),
  course: (courseId, filters) => get<CourseReport>(`/reports/courses/${courseId}`, filters as unknown as Record<string, unknown>),
  // `sort` is an object, which a query string cannot carry — send it as two plain parameters.
  learners: ({ sort, ...filters }) =>
    get<LearnerReport>('/reports/learners', { ...filters, sortKey: sort?.key, sortDirection: sort?.direction } as unknown as Record<string, unknown>),
  instructors: (filters) => get<InstructorReport>('/reports/instructors', filters as unknown as Record<string, unknown>),
  enrolments: (filters) => get<EnrolmentReport>('/reports/enrolments', filters as unknown as Record<string, unknown>),
  reviews: ({ scopeInstructorId: _scope, ...query }) => get<StaffCourseReviewPage>('/reports/reviews', query),
  hideReview: (id) => post<StaffCourseReview>(`/reports/reviews/${encodeURIComponent(id)}/hide`),
  showReview: (id) => post<StaffCourseReview>(`/reports/reviews/${encodeURIComponent(id)}/show`),
};
