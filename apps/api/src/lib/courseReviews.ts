import type { Request } from 'express';
import {
  reviewFirstName,
  roundRating,
  type CourseReview,
  type CourseReviewInput,
  type CourseReviewStatus,
  type LearnerCourseReview,
  type PublicCourseReviewPage,
  type StaffCourseReview,
  type StaffCourseReviewPage,
} from '@syniastrolms/domain';

import { recordAuditLog } from './audit.js';
import { db, type DbClient } from './db.js';
import { forbidden, notFound } from './errors.js';
import { settleExpiry } from './learning.js';
import { courseScopeWhere } from './scope.js';
import { getSettings } from './settings.js';
import { tenant } from './tenancy.js';

/*
 * Course reviews (docs/16, D-PLAT-11). `Course.rating` and `ratingCount` are recomputed from the published reviews in
 * the transaction of any change here.
 *
 * Seeded and imported rating values: nothing rewrites them. Only a change to a course's reviews recomputes, so a course
 * with no review keeps what it holds, and its first review replaces that value outright. A course whose every review
 * is hidden or gone then has no rating, rather than the old value coming back.
 */

const AUDIT = {
  created: 'course.review.created',
  updated: 'course.review.updated',
  hidden: 'course.review.hidden',
  shown: 'course.review.shown',
} as const;

type ReviewRow = { id: string; courseId: string; rating: number; comment: string; status: string; createdAt: Date; updatedAt: Date };

const toReview = (row: ReviewRow): CourseReview => ({
  id: row.id,
  courseId: row.courseId,
  rating: row.rating,
  comment: row.comment,
  status: row.status as CourseReviewStatus,
  createdAt: row.createdAt.toISOString(),
  updatedAt: row.updatedAt.toISOString(),
});

/** Sets a course's rating from its published reviews. `updatedAt` stays: a review is not an edit of the course. */
export async function recomputeCourseRating(client: DbClient, courseId: string): Promise<void> {
  const figures = await client.courseReview.aggregate({ where: { courseId, status: 'published' }, _avg: { rating: true }, _count: { _all: true } });
  const course = await client.course.findUnique({ where: { id: courseId }, select: { updatedAt: true } });
  if (!course) return;
  const count = figures._count._all;
  await client.course.update({
    where: { id: courseId },
    data: { rating: count ? roundRating(figures._avg.rating ?? 0) : null, ratingCount: count || null, updatedAt: course.updatedAt },
  });
}

/** The learner's standing on a course: "not found" for a course they could not open anyway. Settles a lapsed enrolment first. */
async function standing(studentId: string, courseId: string): Promise<{ eligible: boolean }> {
  const course = await db.course.findUnique({ where: { id: courseId }, select: { status: true } });
  if (!course) throw notFound('Course not found.');
  const row = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId, courseId } } });
  if (!row && course.status !== 'published') throw notFound('Course not found.');
  if (!row) return { eligible: false };
  const enrollment = await settleExpiry(row);
  return { eligible: enrollment.status === 'active' || enrollment.status === 'completed' };
}

export async function ownCourseReview(studentId: string, courseId: string): Promise<LearnerCourseReview> {
  const { eligible } = await standing(studentId, courseId);
  const row = await db.courseReview.findUnique({ where: { studentId_courseId: { studentId, courseId } } });
  return { eligible, review: row ? toReview(row) : null };
}

/** Creates or edits the learner's review. An edit keeps the review's status, so editing cannot undo a hide. */
export async function saveCourseReview(req: Request, studentId: string, courseId: string, input: Required<CourseReviewInput>): Promise<CourseReview> {
  const { eligible } = await standing(studentId, courseId);
  if (!eligible) throw forbidden('Only learners enrolled in this course can review it.');
  return db.$transaction(async (tx) => {
    const key = { studentId_courseId: { studentId, courseId } };
    const existing = await tx.courseReview.findUnique({ where: key, select: { id: true, rating: true } });
    const row = await tx.courseReview.upsert({
      where: key,
      create: { ...tenant(), studentId, courseId, rating: input.rating, comment: input.comment },
      update: { rating: input.rating, comment: input.comment },
    });
    await recomputeCourseRating(tx, courseId);
    await recordAuditLog(
      req,
      {
        action: existing ? AUDIT.updated : AUDIT.created,
        targetType: 'course_review',
        targetId: row.id,
        meta: { courseId, rating: input.rating, ...(existing ? { previousRating: existing.rating } : {}) },
      },
      tx,
    );
    return toReview(row);
  });
}

/**
 * A listed course's published reviews, newest first, as a visitor reads them. Switching ratings off in the settings
 * withdraws these too, since each one carries a rating. Below `minRatings` they show while the course's average stays
 * hidden (`publicCourse`): the threshold is about an average from too few people, not about what one person wrote.
 */
export async function publicCourseReviews(slug: string, page: number, pageSize: number): Promise<PublicCourseReviewPage> {
  const course = await db.course.findFirst({ where: { slug, status: 'published', visibility: { in: ['public', 'unlisted'] } }, select: { id: true } });
  if (!course) throw notFound('Course not found.');
  const { courses } = await getSettings();
  if (!courses.showRatings) return { rows: [], total: 0, page, pageSize };
  const where = { courseId: course.id, status: 'published' };
  const [rows, total] = await Promise.all([
    db.courseReview.findMany({
      where,
      select: { rating: true, comment: true, student: { select: { user: { select: { name: true } } } } },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip: (page - 1) * pageSize,
      take: pageSize,
    }),
    db.courseReview.count({ where }),
  ]);
  return { rows: rows.map((r) => ({ firstName: reviewFirstName(r.student.user.name), rating: r.rating, comment: r.comment })), total, page, pageSize };
}

const STAFF_INCLUDE = { course: { select: { title: true } }, student: { select: { user: { select: { name: true } } } } };

const toStaffReview = (row: ReviewRow & { course: { title: string }; student: { user: { name: string } } }): StaffCourseReview => ({
  ...toReview(row),
  courseTitle: row.course.title,
  learnerName: row.student.user.name,
});

/** Reviews in the caller's scope: an admin's, every course; an instructor's, the courses they teach. Hidden ones included. */
export async function staffCourseReviews(
  req: Request,
  query: { status?: CourseReviewStatus; courseId?: string; page: number; pageSize: number },
): Promise<StaffCourseReviewPage> {
  const scope = courseScopeWhere(req);
  const where = { course: scope, ...(query.status ? { status: query.status } : {}), ...(query.courseId ? { courseId: query.courseId } : {}) };
  const [rows, total, courses] = await Promise.all([
    db.courseReview.findMany({
      where,
      include: STAFF_INCLUDE,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
    }),
    db.courseReview.count({ where }),
    db.course.findMany({ where: { ...scope, reviews: { some: {} } }, select: { id: true, title: true }, orderBy: { title: 'asc' } }),
  ]);
  return { rows: rows.map(toStaffReview), total, page: query.page, pageSize: query.pageSize, courses };
}

/** Hides or shows a review. Asking for the state it is already in writes nothing, so the trail holds real changes only. */
export async function setReviewStatus(req: Request, id: string, status: CourseReviewStatus): Promise<StaffCourseReview> {
  return db.$transaction(async (tx) => {
    const current = await tx.courseReview.findUnique({ where: { id }, include: STAFF_INCLUDE });
    if (!current) throw notFound('Review not found.');
    if (current.status === status) return toStaffReview(current);
    const row = await tx.courseReview.update({ where: { id }, data: { status }, include: STAFF_INCLUDE });
    await recomputeCourseRating(tx, row.courseId);
    await recordAuditLog(
      req,
      {
        action: status === 'hidden' ? AUDIT.hidden : AUDIT.shown,
        targetType: 'course_review',
        targetId: id,
        meta: { courseId: row.courseId, rating: row.rating },
      },
      tx,
    );
    return toStaffReview(row);
  });
}

/**
 * An account being deleted takes its reviews with it: the name goes and so must what the person wrote, or the public
 * page would quote "Deleted". Runs in the deletion's transaction, whose audit event records the act.
 */
export async function removeStudentReviews(tx: DbClient, studentId: string): Promise<void> {
  const rows = await tx.courseReview.findMany({ where: { studentId }, select: { courseId: true } });
  if (rows.length === 0) return;
  await tx.courseReview.deleteMany({ where: { studentId } });
  for (const { courseId } of rows) await recomputeCourseRating(tx, courseId);
}
