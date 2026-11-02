/*
 * Course reviews (docs/16, D-PLAT-11), shared by the API and the web app. A learner holds one review per course; the
 * public sees a published one as first name, rating and comment and nothing else. Comments are plain text everywhere.
 */

export const REVIEW_STATUSES = ['published', 'hidden'] as const;
export type CourseReviewStatus = (typeof REVIEW_STATUSES)[number];

export const REVIEW_RATING_MIN = 1;
export const REVIEW_RATING_MAX = 5;
export const REVIEW_COMMENT_MAX = 2000;

export interface CourseReviewInput {
  rating: number;
  comment?: string;
}

/** The learner's own review. */
export interface CourseReview {
  id: string;
  courseId: string;
  rating: number;
  comment: string;
  status: CourseReviewStatus;
  createdAt: string;
  updatedAt: string;
}

/** Whether the learner may write a review now (an active or completed enrolment), and the one they already wrote. */
export interface LearnerCourseReview {
  eligible: boolean;
  review: CourseReview | null;
}

/** A review as a visitor reads it: exactly these fields. */
export interface PublicCourseReview {
  firstName: string;
  rating: number;
  comment: string;
}

export interface PublicCourseReviewPage {
  rows: PublicCourseReview[];
  total: number;
  page: number;
  pageSize: number;
}

/** A review as staff read it. */
export interface StaffCourseReview extends CourseReview {
  courseTitle: string;
  learnerName: string;
}

export interface StaffCourseReviewPage {
  rows: StaffCourseReview[];
  total: number;
  page: number;
  pageSize: number;
  /** The courses in the caller's scope that have a review, for the filter. */
  courses: { id: string; title: string }[];
}

/** The first word of a person's name, which is all of it a visitor is shown. */
export const reviewFirstName = (name: string): string => name.trim().split(/\s+/)[0] || 'Learner';

/** A course's rating from its average: one decimal, as the seeded values and the reports read. */
export const roundRating = (average: number): number => Math.round(average * 10) / 10;
