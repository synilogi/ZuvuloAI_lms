import { Router } from 'express';
import {
  deriveStudentStatus,
  type Student as StudentDomain,
  type Enrollment as EnrollmentDomain,
  type ActivityKind,
  type LearningEvent,
  type ReviewStatus,
} from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { asyncHandler, badRequest, notFound } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requirePermission, requireStaffPermission } from '../lib/permissions.js';
import { assertCourseAccess, assertStudentAccess, courseScopeWhere, scopedCourseIds, studentScopeWhere } from '../lib/scope.js';
import { notify } from '../lib/notify.js';
import { confirmEnrolment } from './learning.js';
import { addLearnerByAdmin, resendLearnerInvite } from '../lib/learners.js';
import { expiryFor, learnerRules } from '../lib/learning.js';
import { getSettings } from '../lib/settings.js';
import { nextLessonTitle, progressRowsFor, studyMinutes, studyWeeks } from '../lib/study.js';
import { email, id as idSchema, optionalId, paging, parseBody, parseQuery, queryInt, searchText, z } from '../lib/validate.js';

export const studentsRouter = Router();

function mapStudent(row: {
  id: string;
  phone: string | null;
  city: string;
  joinedAt: Date;
  lastActiveAt: Date;
  suspended: boolean;
  rankId: string | null;
  user: { name: string; email: string };
}): StudentDomain {
  return {
    id: row.id,
    name: row.user.name,
    email: row.user.email,
    phone: row.phone ?? undefined,
    city: row.city,
    joinedAt: row.joinedAt.toISOString(),
    lastActiveAt: row.lastActiveAt.toISOString(),
    suspended: row.suspended || undefined,
    rankId: row.rankId ?? '',
  };
}

function mapEnrollment(row: {
  id: string;
  studentId: string;
  courseId: string;
  enrolledAt: Date;
  status: string;
  progress: number;
  source: string;
  lastActiveAt: Date | null;
  completedAt: Date | null;
  lastLessonId: string | null;
}): EnrollmentDomain {
  return {
    id: row.id,
    studentId: row.studentId,
    courseId: row.courseId,
    enrolledAt: row.enrolledAt.toISOString(),
    status: row.status as EnrollmentDomain['status'],
    progress: row.progress,
    source: row.source as EnrollmentDomain['source'],
    lastActiveAt: row.lastActiveAt?.toISOString(),
    completedAt: row.completedAt?.toISOString(),
    lastLessonId: row.lastLessonId ?? undefined,
  };
}

studentsRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('learners.view'),
  asyncHandler(async (req, res) => {
    const { search, courseId, status, sort, page, pageSize } = parseQuery(
      req,
      z.object({ search: searchText, courseId: optionalId, status: optionalId, sort: optionalId, ...paging }),
    );
    // Instructors see only learners enrolled in a course they teach — and of each, only those courses: another
    // instructor's course, its progress and its status are not theirs to see (as on the learner's own page).
    const students = await db.student.findMany({
      where: studentScopeWhere(req),
      include: { user: true, enrollments: { where: { course: courseScopeWhere(req) }, include: { course: true } } },
    });
    const now = new Date();
    const { atRiskDays } = (await getSettings()).learning;

    let rows = students.map((s) => {
      const derivedStatus = deriveStudentStatus(mapStudent(s), s.enrollments.map(mapEnrollment), now, atRiskDays);
      const courses = s.enrollments
        .slice()
        .sort((a, b) => b.enrolledAt.getTime() - a.enrolledAt.getTime())
        .map((e) => ({ id: e.courseId, title: e.course.title, progress: e.progress, status: e.status as EnrollmentDomain['status'] }));
      const active = s.enrollments.filter((e) => e.status === 'active');
      const basis = active.length ? active : s.enrollments;
      const progress = basis.length ? Math.round(basis.reduce((n, e) => n + e.progress, 0) / basis.length) : 0;
      return { student: mapStudent(s), status: derivedStatus, courses, progress, _enrollments: s.enrollments };
    });

    if (courseId) rows = rows.filter((r) => r._enrollments.some((e) => e.courseId === courseId));
    if (search) {
      const q = search.toLowerCase();
      rows = rows.filter((r) => r.student.name.toLowerCase().includes(q) || r.student.email.toLowerCase().includes(q) || r.student.id.includes(q));
    }

    const counts: Record<string, number> = { all: rows.length, active: 0, 'at-risk': 0, inactive: 0, suspended: 0 };
    for (const r of rows) counts[r.status]++;
    if (status && status !== 'all') rows = rows.filter((r) => r.status === status);

    if (sort === 'name') rows.sort((a, b) => a.student.name.localeCompare(b.student.name));
    else if (sort === 'progress') rows.sort((a, b) => b.progress - a.progress);
    else if (sort === 'joined') rows.sort((a, b) => b.student.joinedAt.localeCompare(a.student.joinedAt));
    else rows.sort((a, b) => b.student.lastActiveAt.localeCompare(a.student.lastActiveAt));

    const page_rows = rows.slice((page - 1) * pageSize, page * pageSize).map(({ _enrollments, ...r }) => r);

    res.json({ rows: page_rows, total: rows.length, counts });
  }),
);

/** Loads a learner; for an instructor, only the enrollments and certificates of courses they teach are included. */
async function loadStudent(req: import('express').Request, id: string) {
  await assertStudentAccess(req, id);
  const courseIds = await scopedCourseIds(req);
  const s = await db.student.findUnique({
    where: { id },
    include: {
      user: true,
      rank: true,
      enrollments: { include: { course: { include: { instructors: { include: { instructor: true } }, level: true, category: true } } } },
      certificates: true,
    },
  });
  if (!s) throw notFound('Student not found.');
  if (courseIds) {
    const allowed = new Set(courseIds);
    s.enrollments = s.enrollments.filter((e) => allowed.has(e.courseId));
    s.certificates = s.certificates.filter((c) => allowed.has(c.courseId));
  }
  return { ...s, scopedCourseIds: courseIds };
}

studentsRouter.get(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('learners.view'),
  asyncHandler(async (req, res) => {
    const s = await loadStudent(req, req.params.id);
    const status = deriveStudentStatus(mapStudent(s), s.enrollments.map(mapEnrollment), new Date(), (await getSettings()).learning.atRiskDays);
    const quietDays = Math.max(0, Math.round((Date.now() - s.lastActiveAt.getTime()) / 86_400_000));
    const progressRows = await progressRowsFor(s.id, s.scopedCourseIds);

    const enrollments = await Promise.all(
      s.enrollments.map(async (e) => {
        const chapters = await db.chapter.findMany({ where: { courseId: e.courseId }, include: { lessons: true } });
        const published = chapters.map((c) => ({ ...c, lessons: c.lessons.filter((l) => l.status === 'published') }));
        const lessonIds = published.flatMap((c) => c.lessons.map((l) => l.id));
        const courseRows = progressRows.filter((p) => p.lesson.courseId === e.courseId);
        const completedIds = new Set(courseRows.filter((p) => p.state === 'completed' && lessonIds.includes(p.lessonId)).map((p) => p.lessonId));
        const doneCount = completedIds.size;
        const chaptersDone = published.filter((c) => c.lessons.length > 0 && c.lessons.every((l) => completedIds.has(l.id))).length;
        return {
          enrollment: mapEnrollment(e),
          courseTitle: e.course.title,
          levelTitle: e.course.level.name,
          categoryId: e.course.categoryId,
          instructorNames: e.course.instructors.map((i) => i.instructor.name),
          chapters: { done: chaptersDone, total: published.filter((c) => c.lessons.length > 0).length },
          lessons: { done: doneCount, total: lessonIds.length },
          lastLessonTitle: e.status === 'completed' ? undefined : nextLessonTitle(published, courseRows),
          certificateTitle: s.certificates.find((c) => c.courseId === e.courseId)?.title,
        };
      }),
    );

    const certificates = s.certificates
      .filter((c) => c.status === 'issued')
      .map((c) => ({
        id: c.id,
        courseId: c.courseId,
        courseTitle: c.title,
        title: c.title,
        issuedAt: c.issuedAt!.toISOString(),
        credentialId: c.credentialId,
      }));

    const submissions = await db.submission.findMany({
      where: { studentId: s.id, ...(s.scopedCourseIds ? { assignment: { courseId: { in: s.scopedCourseIds } } } : {}) },
      include: { assignment: { select: { maxScore: true } } },
    });
    const scored = submissions.filter((sub) => sub.score != null);

    res.json({
      student: mapStudent(s),
      status,
      quietDays,
      rank: s.rank
        ? { id: s.rank.id, title: s.rank.title, order: s.rank.order, descriptor: s.rank.descriptor }
        : { id: '', title: 'Unranked', order: 0, descriptor: '' },
      enrollments,
      certificates,
      summary: {
        enrolled: s.enrollments.length,
        active: s.enrollments.filter((e) => e.status === 'active').length,
        completed: s.enrollments.filter((e) => e.status === 'completed').length,
        avgProgress: s.enrollments.length ? Math.round(s.enrollments.reduce((n, e) => n + e.progress, 0) / s.enrollments.length) : 0,
        studyMinutes: studyMinutes(progressRows),
        submissions: submissions.length,
        // Mean of graded scores as a percentage of each assignment's maximum.
        avgScore: scored.length
          ? Math.round((scored.reduce((n, sub) => n + (sub.score ?? 0) / (sub.assignment.maxScore || 100), 0) / scored.length) * 100)
          : null,
      },
    });
  }),
);

studentsRouter.get(
  '/:id/progress',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('learners.view'),
  asyncHandler(async (req, res) => {
    const s = await loadStudent(req, req.params.id);
    const courses = await Promise.all(
      s.enrollments.map(async (e) => {
        const chapters = await db.chapter.findMany({ where: { courseId: e.courseId }, orderBy: { position: 'asc' }, include: { lessons: true } });
        const chapterRows = await Promise.all(
          chapters.map(async (c) => {
            const done = await db.lessonProgress.count({ where: { studentId: s.id, lessonId: { in: c.lessons.map((l) => l.id) }, state: 'completed' } });
            return {
              id: c.id,
              title: c.title,
              percent: c.lessons.length ? Math.round((done / c.lessons.length) * 100) : 0,
              completed: done,
              total: c.lessons.length,
            };
          }),
        );
        return {
          courseId: e.courseId,
          courseTitle: e.course.title,
          progress: e.progress,
          status: e.status as EnrollmentDomain['status'],
          chapters: chapterRows,
        };
      }),
    );

    const attempts = await db.quizAttempt.findMany({
      where: { studentId: s.id, ...(s.scopedCourseIds ? { quiz: { courseId: { in: s.scopedCourseIds } } } : {}) },
      include: { quiz: { include: { course: { select: { title: true } } } } },
      orderBy: { createdAt: 'desc' },
    });
    const byQuiz = new Map<string, typeof attempts>();
    for (const a of attempts) byQuiz.set(a.quizId, [...(byQuiz.get(a.quizId) ?? []), a]);
    const quizzes = [...byQuiz.entries()].map(([quizId, list]) => {
      const settings = JSON.parse(list[0].quiz.settingsJson || '{}');
      return {
        quizId,
        title: list[0].quiz.title,
        courseTitle: list[0].quiz.course.title,
        attempts: list.length,
        best: Math.max(...list.map((a) => a.percent)),
        passMark: settings.passMark ?? 70,
        lastAt: list[0].createdAt.toISOString(),
      };
    });

    const submissions = await db.submission.findMany({
      where: { studentId: s.id, ...(s.scopedCourseIds ? { assignment: { courseId: { in: s.scopedCourseIds } } } : {}) },
      include: { assignment: { include: { course: true } } },
      orderBy: { submittedAt: 'desc' },
    });
    const assignments = submissions.map((sub) => ({
      submissionId: sub.id,
      assignmentId: sub.assignmentId,
      title: sub.assignment.title,
      courseTitle: sub.assignment.course.title,
      submittedAt: sub.submittedAt.toISOString(),
      status: sub.reviewStatus as ReviewStatus,
      score: sub.score ?? undefined,
      max: sub.assignment.maxScore,
      passMark: sub.assignment.passMark,
      late: sub.late,
    }));

    res.json({ courses, quizzes, assignments, studyWeeks: studyWeeks(await progressRowsFor(s.id, s.scopedCourseIds)) });
  }),
);

studentsRouter.get(
  '/:id/activity',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('learners.view'),
  asyncHandler(async (req, res) => {
    const s = await loadStudent(req, req.params.id);
    const { kind, courseId, limit } = parseQuery(req, z.object({ kind: optionalId, courseId: optionalId, limit: queryInt(1, 500, 200) }));

    const events: (LearningEvent & { courseId?: string })[] = [];
    for (const e of s.enrollments) {
      events.push({ id: `enr-${e.id}`, kind: 'enrolled', title: `Enrolled in ${e.course.title}`, at: e.enrolledAt.toISOString(), courseId: e.courseId });
    }
    const scopeCourse = s.scopedCourseIds ? { courseId: { in: s.scopedCourseIds } } : {};
    const completions = await db.lessonProgress.findMany({
      where: { studentId: s.id, state: 'completed', completedAt: { not: null }, lesson: scopeCourse },
      include: { lesson: true },
    });
    for (const c of completions) {
      events.push({ id: `lp-${c.id}`, kind: 'lesson-completed', title: c.lesson.title, at: c.completedAt!.toISOString(), courseId: c.lesson.courseId });
    }
    const submissions = await db.submission.findMany({ where: { studentId: s.id, assignment: scopeCourse }, include: { assignment: true } });
    for (const sub of submissions) {
      events.push({
        id: `sub-${sub.id}`,
        kind: 'assignment-submitted',
        title: sub.assignment.title,
        at: sub.submittedAt.toISOString(),
        courseId: sub.assignment.courseId,
      });
    }
    const attempts = await db.quizAttempt.findMany({ where: { studentId: s.id, passed: true, quiz: scopeCourse }, include: { quiz: true } });
    for (const a of attempts) {
      events.push({ id: `qa-${a.id}`, kind: 'assessment-passed', title: a.quiz.title, at: a.createdAt.toISOString(), courseId: a.quiz.courseId });
    }
    for (const c of s.certificates.filter((c) => c.issuedAt)) {
      events.push({ id: `cert-${c.id}`, kind: 'certificate-issued', title: c.title, at: c.issuedAt!.toISOString(), courseId: c.courseId });
    }

    events.sort((a, b) => b.at.localeCompare(a.at));
    const counts: Record<string, number> = { all: events.length };
    for (const e of events) counts[e.kind] = (counts[e.kind] ?? 0) + 1;

    let filtered = events;
    if (kind && kind !== 'all') filtered = filtered.filter((e) => e.kind === (kind as ActivityKind));
    if (courseId) filtered = filtered.filter((e) => e.courseId === courseId);

    res.json({ events: filtered.slice(0, limit), total: filtered.length, counts });
  }),
);

const messageSchema = z.object({
  ids: z.array(idSchema).min(1).max(500),
  subject: z.string().trim().min(1).max(200),
  body: z.string().trim().min(10).max(5000),
  channels: z.array(z.enum(['email', 'app'])).min(1),
});

studentsRouter.post(
  '/message',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('learners.message'),
  asyncHandler(async (req, res) => {
    const { ids, subject, body, channels } = parseBody(req, messageSchema);
    // Only learners the caller may see receive the message; ids outside the scope are silently dropped.
    const recipients = await db.student.findMany({ where: { id: { in: ids }, ...studentScopeWhere(req) }, select: { userId: true } });
    const sender = await db.user.findUnique({ where: { id: req.auth!.sub }, select: { name: true } });
    const paragraphs = body
      .split(/\n\s*\n/)
      .map((p) => p.trim())
      .filter(Boolean);
    let sent = 0;
    for (const r of recipients) {
      const result = await notify({
        recipientUserId: r.userId,
        category: 'course',
        title: subject,
        summary: paragraphs[0].length > 160 ? `${paragraphs[0].slice(0, 157)}…` : paragraphs[0],
        body: paragraphs,
        actor: sender?.name,
        action: { label: 'Go to my learning', to: '/my-learning' },
        channels: { app: channels.includes('app'), email: channels.includes('email') },
      });
      if (result.app || result.email) sent++;
    }
    res.json({ sent });
  }),
);

studentsRouter.post(
  '/:id/enroll',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('learners.enroll'),
  asyncHandler(async (req, res) => {
    const { courseId, source } = parseBody(req, z.object({ courseId: idSchema, source: z.enum(['self', 'admin', 'cohort', 'scholarship']).default('admin') }));
    await assertCourseAccess(req, courseId);
    const student = await db.student.findUnique({ where: { id: req.params.id }, select: { id: true } });
    if (!student) throw notFound('Student not found.');
    const existing = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId: req.params.id, courseId } } });
    if (existing) return res.json(mapEnrollment(existing));
    // Staff may add anyone to a paid course (paid offline, a scholarship), but never as a self-enrolment: only a
    // verified purchase or a staff decision opens a paid course, and the record says which.
    if (source === 'self' && (await db.course.findUnique({ where: { id: courseId }, select: { pricing: true } }))?.pricing === 'paid')
      throw badRequest('This is a paid course. Add the learner as admin, cohort or scholarship.', [
        { field: 'source', message: 'A paid course isn’t joined as a self-enrolment.' },
      ]);
    const rules = await learnerRules();
    const row = await db.enrollment.create({
      data: { ...tenant(), studentId: req.params.id, courseId, source, expiresAt: expiryFor(new Date(), rules.accessMonths) },
    });
    await db.course.update({ where: { id: courseId }, data: { enrolledCount: { increment: 1 } } });
    await confirmEnrolment(req.params.id, courseId, source);
    res.status(201).json(mapEnrollment(row));
  }),
);

studentsRouter.patch(
  '/enrollments/:enrollmentId',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('learners.enroll'),
  asyncHandler(async (req, res) => {
    const { status } = parseBody(req, z.object({ status: z.enum(['active', 'paused']) }));
    const existing = await db.enrollment.findUnique({ where: { id: req.params.enrollmentId } });
    if (!existing) throw notFound('Enrollment not found.');
    await assertCourseAccess(req, existing.courseId, 'Enrollment');
    const row = await db.enrollment.update({ where: { id: existing.id }, data: { status } });
    res.json(mapEnrollment(row));
  }),
);

studentsRouter.delete(
  '/enrollments/:enrollmentId',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('learners.enroll'),
  asyncHandler(async (req, res) => {
    const enrollment = await db.enrollment.findUnique({ where: { id: req.params.enrollmentId } });
    if (!enrollment) throw notFound('Enrollment not found.');
    await assertCourseAccess(req, enrollment.courseId, 'Enrollment');
    await db.enrollment.delete({ where: { id: enrollment.id } });
    await db.course.update({ where: { id: enrollment.courseId }, data: { enrolledCount: { decrement: 1 } } });
    res.status(204).end();
  }),
);

/**
 * An academy admin adds a learner (SAAS-028): the account joins the admin's own academy (D3), is counted against
 * `learners.max` and refused in restricted mode, and the learner is emailed a link to choose a password. Audited.
 */
studentsRouter.post(
  '/',
  requireAuth,
  requireRole('admin'),
  requirePermission('learners.enroll'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ name: z.string().trim().min(2, 'Enter the learner’s full name.').max(120), email }));
    const user = await addLearnerByAdmin(req, input);
    const row = await db.student.findUniqueOrThrow({ where: { id: user.student!.id }, include: { user: true } });
    res.status(201).json(mapStudent(row));
  }),
);

/** Sends a learner's invitation again. Another academy's learner is simply not found. */
studentsRouter.post(
  '/:id/resend-invite',
  requireAuth,
  requireRole('admin'),
  requirePermission('learners.enroll'),
  asyncHandler(async (req, res) => {
    res.json(await resendLearnerInvite(req.params.id));
  }),
);

studentsRouter.post(
  '/:id/suspend',
  requireAuth,
  requireRole('admin'),
  requirePermission('learners.suspend'),
  asyncHandler(async (req, res) => {
    const { suspended, reason } = parseBody(req, z.object({ suspended: z.boolean(), reason: z.string().trim().max(500).optional() }));
    const row = await db.student.update({ where: { id: req.params.id }, data: { suspended, suspendReason: reason }, include: { user: true } });
    res.json(mapStudent(row));
  }),
);
