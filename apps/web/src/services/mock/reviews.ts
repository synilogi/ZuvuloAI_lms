import type {
  CourseReview,
  CourseReviewInput,
  CourseReviewStatus,
  LearnerCourseReview,
  PublicCourseReviewPage,
  StaffCourseReview,
  StaffCourseReviewPage,
} from '@syniastrolms/domain';
import { reviewFirstName } from '@syniastrolms/domain';
import { ServiceError, type StaffReviewQuery } from '../contracts';
import { mockNowIso } from './clock';
import { courses } from './fixtures/catalog';
import { personas } from './fixtures/learner';
import { enrollments } from './fixtures/people';

/* The demo build's course reviews: the rules of lib/courseReviews.ts over rows held in memory, with a few to show. */

interface Row extends CourseReview {
  learnerId: string;
  learnerName: string;
}

const ME = personas.student.id;
const SAMPLE_AT = '2026-09-14T10:00:00+05:30';
const sampleCourse = courses.find((c) => c.status === 'published');

const rows: Row[] = sampleCourse
  ? [
      {
        id: 'review-demo-1',
        courseId: sampleCourse.id,
        rating: 5,
        comment: 'Patient, clear teaching. The worked charts made the method stick.',
        status: 'published',
        createdAt: SAMPLE_AT,
        updatedAt: SAMPLE_AT,
        learnerId: 'demo-learner-1',
        learnerName: 'Kavya Nair',
      },
      {
        id: 'review-demo-2',
        courseId: sampleCourse.id,
        rating: 4,
        comment: 'Good pace. I wanted more practice questions in the later chapters.',
        status: 'published',
        createdAt: SAMPLE_AT,
        updatedAt: SAMPLE_AT,
        learnerId: 'demo-learner-2',
        learnerName: 'Arjun Mehta',
      },
    ]
  : [];

const toReview = ({ learnerId: _learnerId, learnerName: _learnerName, ...review }: Row): CourseReview => review;
const titleOf = (courseId: string) => courses.find((c) => c.id === courseId)?.title ?? 'Course';
const toStaff = (row: Row): StaffCourseReview => ({ ...toReview(row), courseTitle: titleOf(row.courseId), learnerName: row.learnerName });

const eligible = (courseId: string) =>
  enrollments.some((e) => e.studentId === ME && e.courseId === courseId && (e.status === 'active' || e.status === 'completed'));

export function ownMockReview(courseId: string): LearnerCourseReview {
  const row = rows.find((r) => r.courseId === courseId && r.learnerId === ME);
  return { eligible: eligible(courseId), review: row ? toReview(row) : null };
}

export function saveMockReview(courseId: string, input: CourseReviewInput): CourseReview {
  if (!eligible(courseId)) throw new ServiceError('Only learners enrolled in this course can review it.', 'conflict');
  const comment = (input.comment ?? '').trim();
  const now = mockNowIso();
  const existing = rows.find((r) => r.courseId === courseId && r.learnerId === ME);
  if (existing) {
    Object.assign(existing, { rating: input.rating, comment, updatedAt: now });
    return toReview(existing);
  }
  const row: Row = {
    id: `review-demo-${rows.length + 1}`,
    courseId,
    rating: input.rating,
    comment,
    status: 'published',
    createdAt: now,
    updatedAt: now,
    learnerId: ME,
    learnerName: personas.student.name,
  };
  rows.unshift(row);
  return toReview(row);
}

export function publicMockReviews(slug: string, { page, pageSize }: { page: number; pageSize: number }): PublicCourseReviewPage {
  const course = courses.find((c) => c.slug === slug);
  if (!course) throw new ServiceError('Course not found', 'not-found');
  const published = rows.filter((r) => r.courseId === course.id && r.status === 'published');
  return {
    rows: published
      .slice((page - 1) * pageSize, page * pageSize)
      .map((r) => ({ firstName: reviewFirstName(r.learnerName), rating: r.rating, comment: r.comment })),
    total: published.length,
    page,
    pageSize,
  };
}

export function staffMockReviews({ status, courseId, scopeInstructorId, page, pageSize }: StaffReviewQuery): StaffCourseReviewPage {
  const inScope = rows.filter((r) => !scopeInstructorId || courses.find((c) => c.id === r.courseId)?.instructorIds.includes(scopeInstructorId));
  const matching = inScope.filter((r) => (!status || r.status === status) && (!courseId || r.courseId === courseId));
  return {
    rows: matching.slice((page - 1) * pageSize, page * pageSize).map(toStaff),
    total: matching.length,
    page,
    pageSize,
    courses: [...new Set(inScope.map((r) => r.courseId))].map((id) => ({ id, title: titleOf(id) })),
  };
}

export function setMockReviewStatus(id: string, status: CourseReviewStatus): StaffCourseReview {
  const row = rows.find((r) => r.id === id);
  if (!row) throw new ServiceError('Review not found.', 'not-found');
  row.status = status;
  return toStaff(row);
}
