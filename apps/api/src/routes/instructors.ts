import { randomUUID } from 'node:crypto';
import { Router } from 'express';
import { validateInstructor, type AdminEvent, type InstructorInput, type InstructorStatus } from '@syniastrolms/domain';

import { db, type DbClient } from '../lib/db.js';
import { runAsPlatform, tenant } from '../lib/tenancy.js';
import { asyncHandler, conflict, notFound } from '../lib/errors.js';
import { hashPassword, requireAuth, requireRole } from '../lib/auth.js';
import { requirePermission, requireStaffPermission } from '../lib/permissions.js';
import { id as idSchema, parseBody, z, parseQuery, searchText, optionalId } from '../lib/validate.js';
import { coverImageOf, mapInstructor } from '../lib/mapCourse.js';
import { writeJson } from '../lib/json.js';
import { APP_URL, queueEmail } from '../lib/mail.js';
import { INVITE_TOKEN_TTL_MS, issuePasswordResetToken, revokePasswordResetTokens } from '../lib/passwordReset.js';
import { revokeAllSessions } from '../lib/sessions.js';
import { recordAuditLog } from '../lib/audit.js';
import {
  REQUEST_STATUSES,
  STAFF_ONLY,
  approveInstructorRequest,
  isRequestStatus,
  listInstructorRequests,
  rejectInstructorRequest,
} from '../lib/instructorRequests.js';

export const instructorsRouter = Router();
/** A self-registration is decided by approving or rejecting it, never by editing its status (D34). */
const DECIDE_FIRST = 'This instructor is a registration request. Approve or reject it first.';

/**
 * The shape the boundary insists on, before the domain rules in `validateInstructor` run. Without it
 * a body missing a field reached the validator and threw, which the error handler could only report
 * as a 500 — a malformed request is a 400.
 */
const instructorInputSchema = z.object({
  name: z.string().max(160),
  title: z.string().max(160),
  email: z.string().max(254),
  bio: z.string().max(4000),
  expertise: z.array(z.string().max(120)).max(50),
  status: z.enum(['active', 'invited', 'inactive']),
  city: z.string().max(120),
  languages: z.array(z.string().max(80)).max(50),
  courseIds: z.array(idSchema).max(200).default([]),
  phone: z.string().max(40).optional(),
  yearsTeaching: z.number().int().min(0).max(200).optional(),
  photo: z.unknown().optional(),
});

/** completed ÷ enrollments that are not paused, as a percentage; null without enrollments. */
function completionOf(enrollments: { status: string }[]): number | null {
  const settled = enrollments.filter((e) => e.status !== 'paused');
  if (!settled.length) return null;
  return Math.round((settled.filter((e) => e.status === 'completed').length / settled.length) * 100);
}

function weightedRating(courses: { rating: number | null; ratingCount: number | null; status: string }[]) {
  const published = courses.filter((c) => c.status === 'published');
  const count = published.reduce((n, c) => n + (c.ratingCount ?? 0), 0);
  const rating = count > 0 ? Math.round((published.reduce((n, c) => n + (c.rating ?? 0) * (c.ratingCount ?? 0), 0) / count) * 10) / 10 : null;
  return { rating, count };
}

const REVIEW_WINDOW_HOURS = 48;
const DAY_MS = 86_400_000;
const monthLabel = (d: Date) => d.toLocaleDateString('en-GB', { month: 'short', timeZone: 'Asia/Kolkata' });

/** Every staff account gets a link to choose their password; it doubles as the invitation. */
async function sendInvite(user: { id: string; email: string; name: string }, instructor: { title: string }) {
  const token = await issuePasswordResetToken(user.id, INVITE_TOKEN_TTL_MS);
  await queueEmail({
    to: user.email,
    name: user.name,
    subject: 'You have been invited to teach on ZuviloAI',
    templateKey: 'instructor-invite',
    text: [
      `Hi ${user.name.split(' ')[0]},`,
      '',
      `You have been added to ZuviloAI as an instructor (${instructor.title}). Choose a password to open your teaching workspace — the link works for seven days:`,
      `${APP_URL}/reset-password/${token}`,
      '',
      'If you were not expecting this, you can ignore this email.',
    ].join('\n'),
  });
}

/**
 * Instructor and account emails are unique across the platform (D2), so a duplicate in any academy
 * counts. The lookup is targeted — it asks about this address only, and returns nothing but the match.
 */
const instructorEmailsTaken = (email: string, exceptInstructorId?: string) =>
  runAsPlatform('instructor emails are unique across the platform (D2)', async () =>
    (
      await db.instructor.findMany({
        where: { email: { in: [...new Set([email, email.trim().toLowerCase()])] }, ...(exceptInstructorId ? { id: { not: exceptInstructorId } } : {}) },
        select: { email: true },
      })
    ).map((i) => i.email),
  );

const accountWithEmail = (email: string) =>
  runAsPlatform('an email address is unique across the platform (D2)', () => db.user.findUnique({ where: { email }, select: { id: true } }));

/** The account linked to an instructor profile, created on demand for profiles seeded without one. */
async function accountFor(instructor: { id: string; name: string; email: string; title: string }) {
  const existing = await db.user.findFirst({ where: { instructorId: instructor.id } });
  if (existing) return existing;
  return db.user.create({
    data: {
      ...tenant(),
      name: instructor.name,
      email: instructor.email,
      passwordHash: await hashPassword(randomUUID()),
      role: 'instructor',
      descriptor: instructor.title,
      instructorId: instructor.id,
    },
  });
}

instructorsRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('instructors.view'),
  asyncHandler(async (req, res) => {
    const { search, status, expertise, sort } = parseQuery(req, z.object({ search: searchText, status: optionalId, expertise: searchText, sort: optionalId }));
    // Requests waiting for approval, or refused, are not staff (D34): they are listed under /requests.
    const instructors = await db.instructor.findMany({ where: STAFF_ONLY, include: { courses: { include: { course: true } } } });
    const submissions = await db.submission.findMany({ include: { assignment: true } });
    const enrollments = await db.enrollment.findMany({ select: { courseId: true, status: true } });

    let rows = instructors.map((ins) => {
      const courses = ins.courses.map((c) => ({
        id: c.course.id,
        title: c.course.title,
        status: c.course.status as import('@syniastrolms/domain').CourseStatus,
      }));
      const courseIds = new Set(ins.courses.map((c) => c.courseId));
      const published = ins.courses.map((c) => c.course).filter((c) => c.status === 'published');
      const students = ins.courses.reduce((n, c) => n + c.course.enrolledCount, 0);
      const ratingCount = published.reduce((n, c) => n + (c.ratingCount ?? 0), 0);
      const rating = ratingCount > 0 ? Math.round((published.reduce((n, c) => n + (c.rating ?? 0) * (c.ratingCount ?? 0), 0) / ratingCount) * 10) / 10 : null;
      const relevant = submissions.filter((s) => courseIds.has(s.assignment.courseId));
      const toReview = relevant.filter((s) => s.reviewStatus === 'waiting' || s.reviewStatus === 'in-review').length;
      const overdue = relevant.filter(
        (s) => (s.reviewStatus === 'waiting' || s.reviewStatus === 'in-review') && Date.now() - s.submittedAt.getTime() > 48 * 3_600_000,
      ).length;
      const completion = completionOf(enrollments.filter((e) => courseIds.has(e.courseId)));
      return { instructor: mapInstructor(ins), courses, students, rating, ratingCount, completion, toReview, overdue };
    });

    const counts: Record<InstructorStatus | 'all', number> = { all: rows.length, active: 0, invited: 0, inactive: 0 };
    for (const r of rows) counts[r.instructor.status]++;
    const expertiseSet = new Set<string>();
    for (const r of rows) r.instructor.expertise.forEach((e) => expertiseSet.add(e));

    if (search)
      rows = rows.filter(
        (r) => r.instructor.name.toLowerCase().includes(search.toLowerCase()) || r.instructor.title.toLowerCase().includes(search.toLowerCase()),
      );
    if (status && status !== 'all') rows = rows.filter((r) => r.instructor.status === status);
    if (expertise) rows = rows.filter((r) => r.instructor.expertise.includes(expertise));
    if (sort === 'students') rows.sort((a, b) => b.students - a.students);
    else if (sort === 'rating') rows.sort((a, b) => (b.rating ?? 0) - (a.rating ?? 0));
    else if (sort === 'joined') rows.sort((a, b) => b.instructor.joinedAt.localeCompare(a.instructor.joinedAt));
    else rows.sort((a, b) => a.instructor.name.localeCompare(b.instructor.name));

    res.json({ rows, counts, expertise: [...expertiseSet].sort() });
  }),
);

/* ─── Self-registration requests (D34): the academy's own admins approve or refuse them ─── */

instructorsRouter.get(
  '/requests',
  requireAuth,
  requireRole('admin'),
  requirePermission('instructors.manage'),
  asyncHandler(async (req, res) => {
    const { status } = parseQuery(req, z.object({ status: z.enum(REQUEST_STATUSES).optional() }));
    res.json(await listInstructorRequests(status));
  }),
);

instructorsRouter.post(
  '/requests/:id/approve',
  requireAuth,
  requireRole('admin'),
  requirePermission('instructors.manage'),
  asyncHandler(async (req, res) => {
    const approved = await approveInstructorRequest(req.params.id);
    await recordAuditLog(req, { action: 'instructor.request.approved', targetType: 'instructor', targetId: approved.id, meta: { email: approved.email } });
    res.json(approved);
  }),
);

instructorsRouter.post(
  '/requests/:id/reject',
  requireAuth,
  requireRole('admin'),
  requirePermission('instructors.manage'),
  asyncHandler(async (req, res) => {
    const rejected = await rejectInstructorRequest(req.params.id);
    await recordAuditLog(req, { action: 'instructor.request.rejected', targetType: 'instructor', targetId: rejected.id, meta: { email: rejected.email } });
    res.json(rejected);
  }),
);

instructorsRouter.get(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('instructors.view'),
  asyncHandler(async (req, res) => {
    const ins = await db.instructor.findUnique({
      where: { id: req.params.id },
      include: {
        courses: {
          include: {
            course: {
              include: { level: true, instructors: { include: { instructor: true } }, chapters: { include: { lessons: { select: { status: true } } } } },
            },
          },
        },
      },
    });
    if (!ins) throw notFound('Instructor not found.');
    const now = new Date();
    const courseIds = ins.courses.map((c) => c.courseId);
    const fourteenDaysAgo = new Date(now.getTime() - 14 * DAY_MS);

    const enrollments = await db.enrollment.findMany({ where: { courseId: { in: courseIds } }, include: { student: true } });
    const byCourse = (courseId: string) => enrollments.filter((e) => e.courseId === courseId);

    const courses = ins.courses.map((c) => {
      const ce = byCourse(c.courseId);
      return {
        id: c.course.id,
        title: c.course.title,
        status: c.course.status as import('@syniastrolms/domain').CourseStatus,
        levelTitle: c.course.level.name,
        coverMotif: c.course.coverMotif as import('@syniastrolms/domain').Course['coverMotif'],
        ...coverImageOf(c.course),
        role: (c.course.instructors[0]?.instructorId === ins.id ? 'lead' : 'co') as 'lead' | 'co',
        coInstructors: c.course.instructors.filter((i) => i.instructorId !== ins.id).map((i) => i.instructorId),
        enrolled: ce.length,
        activeLearners: ce.filter((e) => e.status === 'active' && (e.lastActiveAt ?? e.enrolledAt) >= fourteenDaysAgo).length,
        rating: c.course.rating ?? undefined,
        ratingCount: c.course.ratingCount ?? undefined,
        completion: completionOf(ce),
        lessons: c.course.chapters.reduce((n, ch) => n + ch.lessons.filter((l) => l.status === 'published').length, 0),
        updatedAt: c.course.updatedAt.toISOString(),
      };
    });

    const students = new Set(enrollments.map((e) => e.studentId)).size;
    const active = new Set(enrollments.filter((e) => e.status === 'active').map((e) => e.studentId)).size;
    const completed = enrollments.filter((e) => e.status === 'completed').length;
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const newThisMonth = enrollments.filter((e) => e.enrolledAt >= monthStart).length;
    const cities = new Map<string, number>();
    for (const e of enrollments) if (e.student.city) cities.set(e.student.city, (cities.get(e.student.city) ?? 0) + 1);

    // Ratings and completion against the whole academy
    const allCourses = await db.course.findMany({ select: { rating: true, ratingCount: true, status: true } });
    const academyEnrollments = await db.enrollment.findMany({ select: { status: true } });
    const own = weightedRating(ins.courses.map((c) => c.course));
    const academy = weightedRating(allCourses);

    // Reviews: turnaround for submissions in the instructor's courses that they graded or returned
    const submissions = await db.submission.findMany({
      where: { assignment: { courseId: { in: courseIds } } },
      include: { assignment: { select: { title: true } } },
    });
    const reviewed = submissions.filter((s) => (s.reviewStatus === 'graded' || s.reviewStatus === 'returned') && s.reviewUpdatedAt);
    const hours = reviewed.map((s) => (s.reviewUpdatedAt!.getTime() - s.submittedAt.getTime()) / 3_600_000).sort((a, b) => a - b);
    const toReview = submissions.filter((s) => s.reviewStatus === 'waiting' || s.reviewStatus === 'in-review').length;

    // Live classes hosted by the instructor
    const liveClasses = await db.liveClass.findMany({ where: { instructorId: ins.id }, include: { registrations: true } });
    const delivered = liveClasses.filter((l) => l.startsAt < now && !l.cancelled);
    const attendanceRows = delivered.flatMap((l) => l.registrations).filter((r) => r.attended !== null);
    const attendance = attendanceRows.length ? Math.round((attendanceRows.filter((r) => r.attended).length / attendanceRows.length) * 100) : null;

    // Enrollments per month, eight months ending this month
    const enrollmentsByMonth = Array.from({ length: 8 }, (_, i) => {
      const start = new Date(now.getFullYear(), now.getMonth() - (7 - i), 1);
      const end = i === 7 ? new Date(now.getTime() + 1) : new Date(now.getFullYear(), now.getMonth() - (6 - i), 1);
      const value = enrollments.filter((e) => e.enrolledAt >= start && e.enrolledAt < end).length;
      const label = monthLabel(start);
      return { label, detail: i === 7 ? `${label} so far` : `${label} ${start.getFullYear()}`, value };
    });

    // Activity: what this person's work implies, newest first
    const events: AdminEvent[] = [];
    const base = req.auth!.role === 'instructor' ? '/teach' : '/admin';
    for (const c of ins.courses.map((c) => c.course)) {
      if (c.publishedAt)
        events.push({
          id: `pub-${c.id}`,
          kind: 'course-published',
          actor: ins.name,
          summary: `published ${c.title}`,
          courseId: c.id,
          at: c.publishedAt.toISOString(),
          to: `${base}/courses/${c.id}`,
        });
      if (!c.publishedAt || c.updatedAt.getTime() - c.publishedAt.getTime() > 60_000)
        events.push({
          id: `upd-${c.id}`,
          kind: 'course-updated',
          actor: ins.name,
          summary: `updated ${c.title}`,
          context: `${c.chapters.length} chapter${c.chapters.length === 1 ? '' : 's'}`,
          courseId: c.id,
          at: c.updatedAt.toISOString(),
          to: `${base}/courses/${c.id}/curriculum`,
        });
    }
    const byDay = new Map<string, typeof reviewed>();
    for (const sub of reviewed) {
      if (now.getTime() - sub.reviewUpdatedAt!.getTime() > 21 * DAY_MS) continue;
      const day = sub.reviewUpdatedAt!.toISOString().slice(0, 10);
      byDay.set(day, [...(byDay.get(day) ?? []), sub]);
    }
    for (const [day, list] of byDay) {
      const latest = list
        .map((sub) => sub.reviewUpdatedAt!.toISOString())
        .sort()
        .at(-1)!;
      events.push({
        id: `rev-${ins.id}-${day}`,
        kind: 'review',
        actor: ins.name,
        summary: `reviewed ${list.length === 1 ? 'a submission' : `${list.length} submissions`}`,
        context: list[0].assignment.title,
        at: latest,
        to: `${base}/assignments/review`,
      });
    }
    for (const l of liveClasses) {
      const ended = l.startsAt < now;
      events.push({
        id: `live-${l.id}`,
        kind: 'live-scheduled',
        actor: ins.name,
        summary: l.cancelled ? `cancelled ${l.title}` : ended ? `hosted ${l.title}` : `scheduled ${l.title}`,
        context: l.registrations.length ? `${l.registrations.length} registered` : undefined,
        courseId: l.courseId,
        at: ended ? l.startsAt.toISOString() : new Date(Math.min(now.getTime(), l.startsAt.getTime() - 7 * DAY_MS)).toISOString(),
        to: `${base}/live/${l.id}`,
      });
    }
    if (ins.status === 'invited') {
      const admin = await db.user.findFirst({ where: { role: 'admin' }, select: { name: true } });
      events.push({
        id: `inv-${ins.id}`,
        kind: 'instructor',
        actor: admin?.name ?? 'Admin',
        summary: `invited ${ins.name}`,
        context: ins.email,
        at: ins.joinedAt.toISOString(),
      });
    }
    const activity = events
      .filter((e) => new Date(e.at) <= now)
      .sort((a, b) => b.at.localeCompare(a.at))
      .slice(0, 12);

    res.json({
      instructor: mapInstructor(ins),
      courses,
      reach: {
        students,
        active,
        completed,
        newThisMonth,
        cities: [...cities.entries()]
          .map(([city, count]) => ({ city, count }))
          .sort((a, b) => b.count - a.count)
          .slice(0, 5),
      },
      performance: {
        rating: own.rating,
        ratingCount: own.count,
        academyRating: academy.rating ?? 0,
        completion: completionOf(enrollments),
        academyCompletion: completionOf(academyEnrollments) ?? 0,
        reviewHoursMedian: hours.length ? Math.round(hours[Math.floor(hours.length / 2)]) : null,
        reviewsOnTime: hours.length ? Math.round((hours.filter((h) => h <= REVIEW_WINDOW_HOURS).length / hours.length) * 100) : null,
        reviewed: reviewed.length,
        toReview,
        liveDelivered: delivered.length,
        liveUpcoming: liveClasses.filter((l) => l.startsAt >= now && !l.cancelled).length,
        attendance,
        enrollmentsByMonth,
      },
      activity,
    });
  }),
);

/**
 * Whether a status change takes a seat on the plan (SAAS-025). `instructors.max` counts every instructor not marked
 * inactive — an invited one can accept — so moving out of `inactive` takes one, and every other move takes none.
 */
const takesSeat = (from: string, to: string) => from === 'inactive' && to !== 'inactive';

/**
 * Writes a status change that takes a seat inside `withinLimit`: the academy's guard is held, usage is counted and
 * compared with the plan in the same transaction as the write, so concurrent activations cannot pass the limit
 * together. Refused in restricted mode, like adding an instructor. A change that takes no seat is written directly.
 */
function seatedWrite<T>(from: string, to: string, write: (tx: DbClient) => Promise<T>): Promise<T> {
  return takesSeat(from, to) ? db.$transaction(write) : write(db);
}

instructorsRouter.post(
  '/',
  requireAuth,
  requireRole('admin'),
  requirePermission('instructors.manage'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, instructorInputSchema) as InstructorInput;
    const issues = validateInstructor(input, await instructorEmailsTaken(input.email));
    if (issues.length) throw conflict('Check the instructor details.', issues);
    if (await accountWithEmail(input.email.trim().toLowerCase())) throw conflict('An account with this email already exists.');

    // An instructor takes a seat unless added as inactive; counted against the plan, refused in restricted mode.
    const row = await db.$transaction((tx) =>
      tx.instructor.create({
        data: {
          ...tenant(),
          name: input.name,
          title: input.title,
          yearsTeaching: input.yearsTeaching,
          email: input.email.trim().toLowerCase(),
          bio: input.bio,
          expertiseJson: writeJson(input.expertise),
          status: input.status,
          city: input.city,
          languagesJson: writeJson(input.languages),
          phone: input.phone,
          courses: { create: input.courseIds.map((courseId) => ({ ...tenant(), courseId })) },
        },
      }),
    );

    // Every instructor gets a sign-in account; an invitation email lets them choose their password.
    const user = await accountFor(row);
    if (input.status === 'invited') await sendInvite(user, row);
    res.status(201).json(mapInstructor(row));
  }),
);

instructorsRouter.patch(
  '/:id',
  requireAuth,
  requireRole('admin'),
  requirePermission('instructors.manage'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, instructorInputSchema) as InstructorInput;
    const existing = await db.instructor.findUnique({ where: { id: req.params.id } });
    if (!existing) throw notFound('Instructor not found.');
    if (isRequestStatus(existing.status)) throw conflict(DECIDE_FIRST);
    const issues = validateInstructor(input, await instructorEmailsTaken(input.email, existing.id));
    if (issues.length) throw conflict('Check the instructor details.', issues);

    const email = input.email.trim().toLowerCase();
    const account = await db.user.findFirst({ where: { instructorId: existing.id } });
    const clash = await accountWithEmail(email);
    if (clash && clash.id !== account?.id) throw conflict('An account with this email already exists.');

    const row = await seatedWrite(existing.status, input.status, async (tx) => {
      if (input.courseIds) await tx.courseInstructor.deleteMany({ where: { instructorId: existing.id } });
      return tx.instructor.update({
        where: { id: existing.id },
        data: {
          name: input.name,
          title: input.title,
          yearsTeaching: input.yearsTeaching,
          email: input.email.trim().toLowerCase(),
          bio: input.bio,
          expertiseJson: writeJson(input.expertise),
          status: input.status,
          city: input.city,
          languagesJson: writeJson(input.languages),
          phone: input.phone,
          courses: { create: input.courseIds.map((courseId) => ({ ...tenant(), courseId })) },
        },
      });
    });
    if (account) {
      await db.user.update({ where: { id: account.id }, data: { name: row.name, email: row.email, descriptor: row.title } });
      // A new address: the set-password link and the sessions belong to whoever held the old one (a typo corrected).
      if (account.email !== row.email) {
        await revokePasswordResetTokens(account.id);
        await revokeAllSessions(account, 'revoked');
      }
    }
    res.json(mapInstructor(row));
  }),
);

instructorsRouter.post(
  '/:id/status',
  requireAuth,
  requireRole('admin'),
  requirePermission('instructors.status'),
  asyncHandler(async (req, res) => {
    const { status } = parseBody(req, z.object({ status: z.enum(['active', 'invited', 'inactive']) }));
    const existing = await db.instructor.findUnique({ where: { id: req.params.id }, select: { status: true } });
    if (!existing) throw notFound('Instructor not found.');
    if (isRequestStatus(existing.status)) throw conflict(DECIDE_FIRST);
    const row = await seatedWrite(existing.status, status, (tx) => tx.instructor.update({ where: { id: req.params.id }, data: { status } }));
    res.json(mapInstructor(row));
  }),
);

instructorsRouter.post(
  '/:id/resend-invite',
  requireAuth,
  requireRole('admin'),
  requirePermission('instructors.manage'),
  asyncHandler(async (req, res) => {
    const row = await db.instructor.findUnique({ where: { id: req.params.id } });
    if (!row) throw notFound('Instructor not found.');
    if (isRequestStatus(row.status)) throw conflict(DECIDE_FIRST);
    const user = await accountFor(row);
    await sendInvite(user, row);
    res.json({ sentTo: row.email });
  }),
);
