import type { Request } from 'express';
import type { Prisma } from '@prisma/client';

import { db } from './db.js';
import { forbidden, notFound, unauthorized } from './errors.js';

/**
 * Server-derived access scope. Never read a role, instructor id or student id from the request body
 * or query — the token is the only source. Instructors are confined to the courses they teach;
 * learners to their own enrollments and records. Out-of-scope ids answer 404 so they cannot be
 * enumerated.
 */

/** Roles that see the whole workspace: the staff admin and the platform's owner (docs/16, D-PLAT-03). */
export const isAdminRole = (role: string | undefined) => role === 'admin' || role === 'superadmin';

/** `undefined` means unscoped (admin); otherwise the instructor id every staff query must filter by. */
export function instructorScope(req: Request): string | undefined {
  const auth = req.auth;
  if (!auth) throw unauthorized();
  if (isAdminRole(auth.role)) return undefined;
  if (auth.role === 'instructor') {
    if (!auth.instructorId) throw forbidden('This account is not linked to an instructor profile.');
    return auth.instructorId;
  }
  throw forbidden();
}

/** What a learner is told when their access is paused. The wording the enrolment check already used. */
export const SUSPENDED_MESSAGE = 'This account is suspended. Contact your admin to continue.';

/**
 * Refuses a learner whose access an admin has paused. Read on the request rather than taken from the
 * token, so a suspension applies to the session the learner already has, not only the next one.
 */
export async function assertNotSuspended(studentId: string): Promise<void> {
  const student = await db.student.findUnique({ where: { id: studentId }, select: { suspended: true } });
  if (student?.suspended) throw forbidden(SUSPENDED_MESSAGE);
}

/** The caller's student id; only learners have one, and only while their access is not paused. */
export async function requireStudent(req: Request): Promise<string> {
  const auth = req.auth;
  if (!auth) throw unauthorized();
  if (!auth.studentId) throw forbidden('Only learners can do this.');
  await assertNotSuspended(auth.studentId);
  return auth.studentId;
}

/** The caller's user id. */
export function requireUser(req: Request): string {
  if (!req.auth) throw unauthorized();
  return req.auth.sub;
}

/** Prisma `where` fragment restricting courses to the caller's scope (empty for admins). */
export function courseScopeWhere(req: Request): Prisma.CourseWhereInput {
  const scope = instructorScope(req);
  return scope ? { instructors: { some: { instructorId: scope } } } : {};
}

/** Ids of the courses the caller may work on, or `undefined` for an admin (everything). */
export async function scopedCourseIds(req: Request): Promise<string[] | undefined> {
  const scope = instructorScope(req);
  if (!scope) return undefined;
  const rows = await db.courseInstructor.findMany({ where: { instructorId: scope }, select: { courseId: true } });
  return rows.map((r) => r.courseId);
}

/** True when the caller may work on `courseId` (admin, or an instructor who teaches it). */
export async function canAccessCourse(req: Request, courseId: string): Promise<boolean> {
  const scope = instructorScope(req);
  if (!scope) return true;
  const link = await db.courseInstructor.findUnique({ where: { courseId_instructorId: { courseId, instructorId: scope } } });
  return !!link;
}

/**
 * Ensures the caller may work on `courseId`. Admins always may; instructors only when they teach it.
 * Responds 404 (not 403) so instructors cannot enumerate other people's course ids.
 */
export async function assertCourseAccess(req: Request, courseId: string, what = 'Course'): Promise<void> {
  if (!(await canAccessCourse(req, courseId))) throw notFound(`${what} not found.`);
  // An admin passes the scope check for any id, so confirm the course is one this academy has: a
  // course of another academy (or none) is the same 404 an instructor gets, not an empty 200.
  if (!instructorScope(req) && !(await db.course.findUnique({ where: { id: courseId }, select: { id: true } }))) throw notFound(`${what} not found.`);
}

export async function assertQuizAccess(req: Request, quizId: string) {
  const quiz = await db.quiz.findUnique({ where: { id: quizId } });
  if (!quiz) throw notFound('Quiz not found.');
  await assertCourseAccess(req, quiz.courseId, 'Quiz');
  return quiz;
}

export async function assertAssignmentAccess(req: Request, assignmentId: string) {
  const assignment = await db.courseAssignment.findUnique({ where: { id: assignmentId } });
  if (!assignment) throw notFound('Assignment not found.');
  await assertCourseAccess(req, assignment.courseId, 'Assignment');
  return assignment;
}

export async function assertSubmissionAccess(req: Request, submissionId: string) {
  const submission = await db.submission.findUnique({ where: { id: submissionId }, include: { assignment: true } });
  if (!submission) throw notFound('Submission not found.');
  await assertCourseAccess(req, submission.assignment.courseId, 'Submission');
  return submission;
}

/** A live class is in scope when the caller teaches its course or is the class's instructor. */
export async function assertLiveAccess(req: Request, liveClassId: string) {
  const live = await db.liveClass.findUnique({ where: { id: liveClassId } });
  if (!live) throw notFound('Live class not found.');
  const scope = instructorScope(req);
  if (scope && live.instructorId !== scope && !(await canAccessCourse(req, live.courseId))) throw notFound('Live class not found.');
  return live;
}

export async function assertCertificateAccess(req: Request, certificateId: string) {
  const cert = await db.issuedCertificate.findUnique({ where: { id: certificateId } });
  if (!cert) throw notFound('Certificate not found.');
  await assertCourseAccess(req, cert.courseId, 'Certificate');
  return cert;
}

/** An instructor may see a learner only when that learner is enrolled in one of their courses. */
export async function assertStudentAccess(req: Request, studentId: string): Promise<void> {
  const scope = instructorScope(req);
  if (!scope) return;
  const link = await db.enrollment.findFirst({
    where: { studentId, course: { instructors: { some: { instructorId: scope } } } },
    select: { id: true },
  });
  if (!link) throw notFound('Student not found.');
}

/** Prisma `where` fragment for students visible to the caller (empty for admins). */
export function studentScopeWhere(req: Request): Prisma.StudentWhereInput {
  const scope = instructorScope(req);
  return scope ? { enrollments: { some: { course: { instructors: { some: { instructorId: scope } } } } } } : {};
}

/* ─── Learner ownership ───────────────────────────────────────────────── */

/** The learner's enrollment in `courseId`, or 403 when they are not enrolled. */
export async function requireEnrollment(studentId: string, courseId: string) {
  const enrollment = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId, courseId } } });
  if (!enrollment) throw forbidden('Enrol in this course to continue.');
  return enrollment;
}

/**
 * Learners may work on a lesson when enrolled in its course, or when the lesson is a published free
 * preview. Returns the enrollment (null for a preview without enrollment).
 */
export async function requireLessonAccess(studentId: string, courseId: string, lessonId: string) {
  const lesson = await db.lesson.findFirst({ where: { id: lessonId, courseId }, select: { isPreview: true, status: true } });
  if (!lesson) throw notFound('Lesson not found.');
  const enrollment = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId, courseId } } });
  if (enrollment) return enrollment;
  if (lesson.isPreview && lesson.status === 'published') return null;
  throw forbidden('Enrol in this course to continue.');
}
