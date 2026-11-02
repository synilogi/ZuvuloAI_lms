import { Router } from 'express';
import { deriveLiveClassPhase, validateCalendarEvent, type CalendarEvent, type CalendarEventInput, type CalendarEventType } from '@syniastrolms/domain';
import { mapLive } from '../lib/mapLive.js';
import { id as idSchema, parseBody, z } from '../lib/validate.js';

const eventInputSchema = z.object({
  type: z.enum(['quiz', 'milestone', 'reminder', 'live', 'assignment']),
  title: z.string().trim().max(160).default(''),
  description: z.string().max(2000).optional().nullable(),
  timing: z.enum(['timed', 'moment', 'all-day']),
  startsAt: z.string().refine((v) => !Number.isNaN(Date.parse(v)), 'Enter a valid date.'),
  durationMin: z.number().int().min(0).max(1440).optional().nullable(),
  courseId: idSchema.optional().nullable(),
  chapterId: idSchema.optional().nullable(),
  quizId: idSchema.optional().nullable(),
  milestone: z.enum(['cohort-starts', 'chapter-release', 'enrolment-closes', 'cohort-ends', 'course-launch']).optional().nullable(),
  audience: z.enum(['me', 'learners']).optional().nullable(),
  notifyMin: z.number().int().min(0).max(43_200).optional().nullable(),
});

/** Learners the event concerns: the course's (not paused), or every active learner for academy-wide events. */
async function audienceSizeFor(courseId: string | null) {
  if (courseId) return db.enrollment.count({ where: { courseId, status: { in: ['active', 'completed'] } } });
  return db.student.count({ where: { suspended: false } });
}

import { db } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { asyncHandler, conflict, notFound } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { canAccessCourse, instructorScope, requireUser, isAdminRole } from '../lib/scope.js';

export const calendarRouter = Router();

function mapEvent(row: {
  id: string;
  type: string;
  title: string;
  description: string | null;
  timing: string;
  startsAt: Date;
  durationMin: number | null;
  courseId: string | null;
  chapterId: string | null;
  instructorId: string | null;
  quizId: string | null;
  milestone: string | null;
  audience: string | null;
  ownerId: string | null;
  notifyMin: number | null;
  done: boolean;
  cancelled: boolean;
}): CalendarEvent {
  return {
    id: row.id,
    type: row.type as CalendarEventType,
    title: row.title,
    description: row.description ?? undefined,
    timing: row.timing as CalendarEvent['timing'],
    startsAt: row.startsAt.toISOString(),
    durationMin: row.durationMin ?? undefined,
    courseId: row.courseId ?? undefined,
    chapterId: row.chapterId ?? undefined,
    instructorId: row.instructorId ?? undefined,
    quizId: row.quizId ?? undefined,
    milestone: (row.milestone as CalendarEvent['milestone']) ?? undefined,
    audience: (row.audience as CalendarEvent['audience']) ?? undefined,
    ownerId: row.ownerId ?? undefined,
    notifyMin: row.notifyMin ?? undefined,
    done: row.done || undefined,
    cancelled: row.cancelled || undefined,
  };
}

async function derivedEvents(from: Date, to: Date, courseId?: string, instructorId?: string, scope?: string) {
  const courseScope = scope ? { course: { instructors: { some: { instructorId: scope } } } } : {};
  const liveClasses = await db.liveClass.findMany({
    where: {
      startsAt: { gte: from, lte: to },
      ...(courseId ? { courseId } : {}),
      ...(instructorId ? { instructorId } : {}),
      ...(scope ? { OR: [{ instructorId: scope }, courseScope] } : {}),
    },
    include: { course: true, instructor: true, registrations: true },
  });
  const now = new Date();
  const liveRows = liveClasses.map((l) => ({
    phase: deriveLiveClassPhase(mapLive(l), now),
    event: {
      id: `live-${l.id}`,
      type: 'live' as CalendarEventType,
      title: l.title,
      timing: 'timed' as const,
      startsAt: l.startsAt.toISOString(),
      durationMin: l.durationMin,
      courseId: l.courseId,
      instructorId: l.instructorId,
      cancelled: l.cancelled || undefined,
      source: { kind: 'live-class' as const, id: l.id },
    },
    courseTitle: l.course.title,
    instructorName: l.instructor.name,
  }));

  const assignments = await db.courseAssignment.findMany({
    where: { status: 'published', ...(courseId ? { courseId } : {}), ...courseScope },
    include: { course: true, submissions: { select: { studentId: true } } },
  });
  const enrolledCounts = new Map<string, number>();
  for (const a of assignments) if (!enrolledCounts.has(a.courseId)) enrolledCounts.set(a.courseId, await audienceSizeFor(a.courseId));
  const dueRows = assignments
    .map((a) => {
      const due = JSON.parse(a.dueJson) as { kind: string; dueAt?: string };
      if (due.kind !== 'date' || !due.dueAt) return null;
      const at = new Date(due.dueAt);
      if (at < from || at > to) return null;
      return {
        event: {
          id: `assignment-${a.id}`,
          type: 'assignment' as CalendarEventType,
          title: a.title,
          timing: 'moment' as const,
          startsAt: at.toISOString(),
          courseId: a.courseId,
          source: { kind: 'assignment' as const, id: a.id },
        },
        courseTitle: a.course.title,
        due: { learners: enrolledCounts.get(a.courseId) ?? 0, submitted: new Set(a.submissions.map((s) => s.studentId)).size },
      };
    })
    .filter((r): r is NonNullable<typeof r> => r !== null);

  return [...liveRows, ...dueRows];
}

/** Only the account that added an event (or an admin) may change it. 404 hides other people's ids. */
async function assertOwner(req: Parameters<typeof requireUser>[0], eventId: string) {
  const row = await db.calendarEvent.findUnique({ where: { id: eventId }, select: { ownerId: true } });
  if (!row) throw notFound('Event not found.');
  if (!isAdminRole(req.auth!.role) && row.ownerId !== req.auth!.sub) throw notFound('Event not found.');
}

calendarRouter.get(
  '/',
  requireAuth,
  requireRole('instructor'),
  asyncHandler(async (req, res) => {
    const viewerId = requireUser(req);
    const scope = instructorScope(req);
    const { from, to, types, courseId, instructorId } = req.query as Record<string, string>;
    const fromDate = new Date(`${from}T00:00:00+05:30`);
    const toDate = new Date(`${to}T23:59:59+05:30`);
    const typeList = types ? (Array.isArray(types) ? types : [types]) : undefined;

    const stored = await db.calendarEvent.findMany({
      where: {
        startsAt: { gte: fromDate, lte: toDate },
        type: { not: 'live' },
        ...(courseId ? { courseId } : {}),
        ...(instructorId ? { instructorId } : {}),
        // Instructors: their own events plus those on their courses; admins: everything but other people's personal reminders.
        ...(scope
          ? { OR: [{ ownerId: viewerId }, { instructorId: scope }, { course: { instructors: { some: { instructorId: scope } } } }] }
          : { OR: [{ audience: { not: 'me' } }, { ownerId: viewerId }] }),
      },
      include: { course: true, instructor: true },
    });
    const storedRows = stored.map((e) => ({ event: mapEvent(e), courseTitle: e.course?.title, instructorName: e.instructor?.name }));

    const derived = await derivedEvents(fromDate, toDate, courseId, instructorId, scope);
    let rows = [...storedRows, ...derived] as {
      event: CalendarEvent;
      courseTitle?: string;
      instructorName?: string;
      phase?: string;
      due?: { learners: number; submitted: number };
    }[];

    const counts: Record<CalendarEventType, number> = { live: 0, assignment: 0, quiz: 0, milestone: 0, reminder: 0 };
    for (const r of rows) counts[r.event.type]++;
    const total = rows.length;

    if (typeList) rows = rows.filter((r) => typeList.includes(r.event.type));
    rows.sort((a, b) => a.event.startsAt.localeCompare(b.event.startsAt));

    res.json({ rows, counts, total });
  }),
);

calendarRouter.get(
  '/:id',
  requireAuth,
  requireRole('instructor'),
  asyncHandler(async (req, res) => {
    const viewerId = requireUser(req);
    if (req.params.id.startsWith('live-')) {
      const live = await db.liveClass.findUnique({ where: { id: req.params.id.slice(5) }, include: { course: true, instructor: true, registrations: true } });
      if (!live) throw notFound('Event not found.');
      const scope = instructorScope(req);
      if (scope && live.instructorId !== scope && !(await canAccessCourse(req, live.courseId))) throw notFound('Event not found.');
      res.json({
        event: {
          id: req.params.id,
          type: 'live',
          title: live.title,
          timing: 'timed',
          startsAt: live.startsAt.toISOString(),
          durationMin: live.durationMin,
          courseId: live.courseId,
          instructorId: live.instructorId,
          source: { kind: 'live-class', id: live.id },
        },
        courseTitle: live.course.title,
        instructorName: live.instructor.name,
        instructorTitle: live.instructor.title,
        phase: deriveLiveClassPhase(mapLive(live), new Date()),
        editable: false,
        live: {
          registered: live.registrations.length,
          capacity: live.capacity ?? undefined,
          // Only the built-in room can say who came; an outside meeting's attendance is not known to the LMS.
          attended:
            mapLive(live).meeting?.kind === 'room' && live.registrations.some((r) => r.attended !== null)
              ? live.registrations.filter((r) => r.attended).length
              : undefined,
        },
        audienceSize: await audienceSizeFor(live.courseId),
      });
      return;
    }
    if (req.params.id.startsWith('assignment-')) {
      const a = await db.courseAssignment.findUnique({
        where: { id: req.params.id.slice(11) },
        include: { course: true, submissions: { select: { studentId: true } } },
      });
      if (!a) throw notFound('Event not found.');
      if (!(await canAccessCourse(req, a.courseId))) throw notFound('Event not found.');
      const due = JSON.parse(a.dueJson) as { dueAt?: string };
      const submitted = new Set(a.submissions.map((s) => s.studentId));
      const enrolled = await db.enrollment.findMany({
        where: { courseId: a.courseId, status: { in: ['active', 'completed'] } },
        include: { student: { include: { user: { select: { name: true } } } } },
        orderBy: { enrolledAt: 'asc' },
      });
      const chapter = a.chapterId ? await db.chapter.findUnique({ where: { id: a.chapterId }, select: { title: true } }) : null;
      res.json({
        event: {
          id: req.params.id,
          type: 'assignment',
          title: a.title,
          timing: 'moment',
          startsAt: due.dueAt,
          courseId: a.courseId,
          source: { kind: 'assignment', id: a.id },
        },
        courseTitle: a.course.title,
        chapterTitle: chapter?.title,
        editable: false,
        due: { learners: enrolled.length, submitted: submitted.size },
        // Those who still owe the work come first.
        learnersDue: enrolled
          .map((e) => ({ id: e.studentId, name: e.student.user.name, submitted: submitted.has(e.studentId) }))
          .sort((a, b) => Number(a.submitted) - Number(b.submitted))
          .slice(0, 8),
      });
      return;
    }
    const row = await db.calendarEvent.findUnique({ where: { id: req.params.id }, include: { course: true, instructor: true } });
    if (!row) throw notFound('Event not found.');
    const scope = instructorScope(req);
    if (scope && row.ownerId !== viewerId && row.instructorId !== scope && !(row.courseId && (await canAccessCourse(req, row.courseId))))
      throw notFound('Event not found.');
    const chapterTitle = row.chapterId ? (await db.chapter.findUnique({ where: { id: row.chapterId }, select: { title: true } }))?.title : undefined;
    const audienceSize = row.audience === 'me' ? undefined : await audienceSizeFor(row.courseId);
    if (row.type === 'quiz' && row.quizId) {
      const quiz = await db.quiz.findUnique({ where: { id: row.quizId } });
      const settings = quiz ? JSON.parse(quiz.settingsJson) : {};
      const questions = quiz ? JSON.parse(quiz.questionsJson) : [];
      res.json({
        event: mapEvent(row),
        courseTitle: row.course?.title,
        chapterTitle,
        audienceSize,
        editable: row.ownerId === viewerId || isAdminRole(req.auth!.role),
        quiz: quiz
          ? {
              id: quiz.id,
              title: quiz.title,
              status: quiz.status,
              questions: questions.length,
              timeLimitMin: settings.timeLimitMin,
              attempts: settings.attempts,
              passMark: settings.passMark,
            }
          : undefined,
      });
      return;
    }
    res.json({
      event: mapEvent(row),
      courseTitle: row.course?.title,
      chapterTitle,
      instructorName: row.instructor?.name,
      instructorTitle: row.instructor?.title,
      audienceSize,
      editable: row.ownerId === viewerId || isAdminRole(req.auth!.role),
    });
  }),
);

calendarRouter.post(
  '/',
  requireAuth,
  requireRole('instructor'),
  asyncHandler(async (req, res) => {
    const ownerId = requireUser(req);
    const { input } = parseBody(req, z.object({ input: eventInputSchema })) as unknown as { input: CalendarEventInput };
    const issues = validateCalendarEvent(input, new Date());
    if (input.courseId && !(await canAccessCourse(req, input.courseId))) throw notFound('Course not found.');
    if (issues.length) throw conflict('Check the event before saving.', issues);
    const row = await db.calendarEvent.create({
      data: {
        ...tenant(),
        type: input.type,
        title: input.title,
        description: input.description,
        timing: input.timing,
        startsAt: new Date(input.startsAt),
        durationMin: input.durationMin,
        courseId: input.courseId,
        chapterId: input.chapterId,
        quizId: input.quizId,
        milestone: input.milestone,
        audience: input.audience,
        ownerId,
        notifyMin: input.notifyMin,
      },
    });
    res.status(201).json(mapEvent(row));
  }),
);

calendarRouter.patch(
  '/:id',
  requireAuth,
  requireRole('instructor'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, eventInputSchema) as unknown as CalendarEventInput;
    const issues = validateCalendarEvent(input, new Date());
    if (issues.length) throw conflict('Check the event before saving.', issues);
    await assertOwner(req, req.params.id);
    if (input.courseId && !(await canAccessCourse(req, input.courseId))) throw notFound('Course not found.');
    const row = await db.calendarEvent.update({
      where: { id: req.params.id },
      data: {
        title: input.title,
        description: input.description,
        timing: input.timing,
        startsAt: new Date(input.startsAt),
        durationMin: input.durationMin,
        courseId: input.courseId,
        chapterId: input.chapterId,
        quizId: input.quizId,
        milestone: input.milestone,
        audience: input.audience,
        notifyMin: input.notifyMin,
        // A changed time or lead re-arms the reminder.
        notifiedAt: null,
      },
    });
    res.json(mapEvent(row));
  }),
);

calendarRouter.delete(
  '/:id',
  requireAuth,
  requireRole('instructor'),
  asyncHandler(async (req, res) => {
    await assertOwner(req, req.params.id);
    await db.calendarEvent.delete({ where: { id: req.params.id } });
    res.status(204).end();
  }),
);

calendarRouter.post(
  '/:id/done',
  requireAuth,
  requireRole('instructor'),
  asyncHandler(async (req, res) => {
    const { done } = parseBody(req, z.object({ done: z.boolean() }));
    await assertOwner(req, req.params.id);
    const row = await db.calendarEvent.update({ where: { id: req.params.id }, data: { done } });
    res.json(mapEvent(row));
  }),
);
