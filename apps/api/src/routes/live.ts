import { Router } from 'express';
import { validateLiveClass, deriveLiveClassPhase, canJoin, canStartRoom, type LiveClassInput, type LiveClassPhase } from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { tenant, currentTenantId, runAsPlatform, runInTenant } from '../lib/tenancy.js';
import { asyncHandler, badRequest, conflict, forbidden, notFound } from '../lib/errors.js';
import { requireAuth, requireRole, signGrant, verifyGrant } from '../lib/auth.js';
import { hasPermission, requireStaffPermission } from '../lib/permissions.js';
import { assertNotSuspended, assertCourseAccess, assertLiveAccess, instructorScope, requireStudent } from '../lib/scope.js';
import { settleExpiry } from '../lib/learning.js';
import { readJson, writeJson } from '../lib/json.js';
import { forLearner, mapLive } from '../lib/mapLive.js';
import { notifyLiveCancelled, notifyLiveRescheduled, notifyLiveScheduled, notifyLiveStarted, sendLiveReminder } from '../lib/liveEvents.js';
import { assertLiveRoomUsable, liveRoomConfig, liveRoomUsable, newRoomName, roomJoin } from '../lib/liveRoom.js';
import { endLiveClass, playableRecording } from '../lib/liveSessions.js';
import { getSettings } from '../lib/settings.js';
import { id as idSchema, optionalId, paging, parseBody, parseQuery, searchText, z } from '../lib/validate.js';

const liveSchema = z.object({
  courseId: idSchema,
  title: z.string().trim().min(1).max(160),
  instructorId: idSchema,
  // A moment, never a wall-clock time: an ISO date-time with its offset (`Z` or `+05:30`), so no server's zone decides it.
  startsAt: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,3})?)?(Z|[+-]\d{2}:\d{2})$/, 'Enter the start time with its time zone.')
    .refine((v) => !Number.isNaN(Date.parse(v)), 'Enter a valid start time.'),
  durationMin: z.number().int().min(1).max(1440),
  capacity: z.number().int().min(1).max(10_000).optional().nullable(),
  description: z.string().max(5000).optional().nullable(),
  agenda: z
    .array(z.object({ title: z.string().max(200), minutes: z.number().min(0).max(1440) }).passthrough())
    .max(50)
    .optional(),
  visibility: z.enum(['enrolled', 'cohort', 'public']).optional(),
  meeting: z
    .object({ kind: z.enum(['room', 'external']), url: z.string().max(500).optional(), link: z.string().trim().max(500).optional() })
    .passthrough()
    .optional(),
  reminders: z.array(z.number().int().min(0).max(43_200)).max(10).optional(),
  chapterId: idSchema.optional().nullable(),
  recording: z
    .object({ durationMin: z.number().min(0).max(1440), availableUntil: z.string() })
    .passthrough()
    .optional()
    .nullable(),
});

export const liveRouter = Router();

const CLOSE_GRACE_MS = 60 * 60_000;
/** When a class's room stops letting anyone in: when the host ended it, or an hour after its scheduled end. */
const closesAt = (row: { startsAt: Date; durationMin: number; endedAt?: Date | null }) =>
  row.endedAt ?? new Date(row.startsAt.getTime() + row.durationMin * 60_000 + CLOSE_GRACE_MS);

/**
 * Whether a learner may see and use a class: a `public` ("Any learner") class while its course is published, or a class
 * of a course they hold — an enrolment that has not expired and is not paused. A paid course is held only once bought,
 * so the class of a paid course is reached the same way its lessons are. Anything else is not theirs.
 */
async function assertLearnerMayUse(studentId: string, row: { courseId: string; visibility: string }) {
  if (row.visibility === 'public') {
    const course = await db.course.findUnique({ where: { id: row.courseId }, select: { status: true } });
    if (course?.status !== 'published') throw notFound('Live class not found.');
    return;
  }
  const enrollment = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId, courseId: row.courseId } } });
  if (!enrollment) throw forbidden('Enrol in this course to join its live classes.');
  const settled = await settleExpiry(enrollment);
  if (settled.status === 'expired') throw forbidden('Your access to this course has ended, so its live classes are closed to you.');
  if (settled.status === 'paused') throw forbidden('Your place in this course is paused. Contact support to continue.');
}

/**
 * The host must be an instructor of this academy who is not deactivated and teaches the course, and the course must not
 * be archived. Neither an unknown id nor a colleague from another course hosts a class.
 */
async function assertHostAndCourse(instructorId: string, courseId: string) {
  const [instructor, course, teaches] = await Promise.all([
    db.instructor.findUnique({ where: { id: instructorId }, select: { status: true, name: true } }),
    db.course.findUnique({ where: { id: courseId }, select: { status: true } }),
    db.courseInstructor.count({ where: { instructorId, courseId } }),
  ]);
  if (!course) throw notFound('Course not found.');
  if (course.status === 'archived')
    throw conflict('This course is archived. Restore it before scheduling classes for it.', [{ field: 'course', message: 'This course is archived.' }]);
  if (!instructor || instructor.status === 'inactive')
    throw conflict('Choose an active instructor to host the class.', [{ field: 'instructor', message: 'Choose an active instructor.' }]);
  if (!teaches)
    throw conflict(`${instructor.name} doesn’t teach this course. Add them to the course first, or choose one of its instructors.`, [
      { field: 'instructor', message: 'This instructor doesn’t teach the course.' },
    ]);
}

/**
 * No accidental duplicate: the same class — course, title, host and start — scheduled twice (a double submit, or two
 * tabs). `except` is the class being edited. A host may still run classes that overlap (two batches, say).
 */
async function assertNotDuplicate(input: { courseId: string; instructorId: string; title: string; startsAt: string }, except?: string) {
  const same = await db.liveClass.findFirst({
    where: {
      cancelled: false,
      courseId: input.courseId,
      instructorId: input.instructorId,
      title: input.title.trim(),
      startsAt: new Date(input.startsAt),
      ...(except ? { id: { not: except } } : {}),
    },
    select: { id: true },
  });
  if (same) throw conflict('This class is already scheduled.', [{ field: 'startsAt', message: 'This class is already scheduled at this time.' }]);
}

function viewFor(phase: LiveClassPhase, cancelled: boolean): 'upcoming' | 'live' | 'history' | 'cancelled' {
  if (cancelled) return 'cancelled';
  if (phase === 'live' || phase === 'starting-soon') return 'live';
  if (phase === 'upcoming') return 'upcoming';
  return 'history';
}

liveRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  asyncHandler(async (req, res) => {
    const { view, search, courseId, instructorId, page, pageSize } = parseQuery(
      req,
      z.object({ view: optionalId, search: searchText, courseId: optionalId, instructorId: optionalId, ...paging }),
    );
    // Instructors see the classes of the courses they teach, plus any they host.
    const scope = instructorScope(req);
    const classes = await db.liveClass.findMany({
      where: {
        ...(courseId ? { courseId } : {}),
        ...(instructorId ? { instructorId } : {}),
        ...(scope ? { OR: [{ instructorId: scope }, { course: { instructors: { some: { instructorId: scope } } } }] } : {}),
      },
      include: { course: true, instructor: true, registrations: true },
      orderBy: { startsAt: 'desc' },
    });
    const now = new Date();
    let rows = classes.map((c) => ({
      liveClass: mapLive(c),
      phase: deriveLiveClassPhase(mapLive(c), now),
      courseTitle: c.course.title,
      instructorName: c.instructor.name,
    }));

    const counts: Record<string, number> = { upcoming: 0, live: 0, history: 0, cancelled: 0 };
    for (const r of rows) counts[viewFor(r.phase, !!r.liveClass.cancelled)]++;

    if (search) rows = rows.filter((r) => r.liveClass.title.toLowerCase().includes(search.toLowerCase()));
    if (view) rows = rows.filter((r) => viewFor(r.phase, !!r.liveClass.cancelled) === view);
    // What is coming is listed soonest first; what is over (or called off), latest first.
    if (view === 'upcoming' || view === 'live') rows.sort((a, b) => a.liveClass.startsAt.localeCompare(b.liveClass.startsAt));

    res.json({ rows: rows.slice((page - 1) * pageSize, page * pageSize), total: rows.length, counts });
  }),
);

liveRouter.get(
  '/learner',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = req.auth!.studentId;
    if (!studentId) throw badRequest('Only learners have live classes here.');
    // The learner's own live classes are a learner action, so a suspension applies here too.
    await assertNotSuspended(studentId);
    // Courses the learner holds now: not expired (by status or by date) and not paused.
    const now0 = new Date();
    const enrollments = await db.enrollment.findMany({
      where: { studentId, status: { in: ['active', 'completed'] }, OR: [{ expiresAt: null }, { expiresAt: { gt: now0 } }] },
      select: { courseId: true },
    });
    const courseIds = enrollments.map((e) => e.courseId);
    const classes = await db.liveClass.findMany({
      where: {
        OR: [
          { courseId: { in: courseIds }, course: { status: { not: 'archived' } } },
          // `public` ("Any learner") classes are open to every learner in the academy as a taster,
          // enrolled or not — but only while the course they belong to is published.
          { visibility: 'public', course: { status: 'published' } },
        ],
      },
      include: { course: true, instructor: true, registrations: { where: { studentId } } },
    });
    const now = new Date();
    const rows = classes.map((c) => ({
      liveClass: forLearner(mapLive(c)),
      phase: deriveLiveClassPhase(mapLive(c), now),
      courseTitle: c.course.title,
      instructorName: c.instructor.name,
      registered: c.registrations.length > 0,
      // Whether this learner went into the room — what their history shows.
      attended: c.registrations[0]?.attended ?? undefined,
    }));

    res.json({
      // `registered` stays on the classes a learner can still join: the room is theirs only once
      // they have taken a place, so the screen needs to know which it is.
      live: rows.filter((r) => r.phase === 'live'),
      upcoming: rows.filter((r) => r.phase === 'upcoming' || r.phase === 'starting-soon'),
      recordings: rows.filter((r) => r.phase === 'ended').map(({ registered: _registered, ...r }) => r),
      // Classes this learner was in or held a place for, once over: their attendance record.
      history: rows
        .filter((r) => (r.phase === 'ended' || r.phase === 'recording-expired') && r.attended !== undefined)
        .sort((a, b) => b.liveClass.startsAt.localeCompare(a.liveClass.startsAt))
        .slice(0, 20),
    });
  }),
);

liveRouter.get(
  '/:id',
  requireAuth,
  asyncHandler(async (req, res) => {
    // Learners open this page too (the class they just saw in their list). Staff get the teaching
    // view; a learner may read a class of a course they are enrolled in, or any `public` one, and
    // gets no attendee list — who else registered is not theirs to see.
    const studentId = req.auth!.studentId;
    if (!studentId) await assertLiveAccess(req, req.params.id);
    const row = await db.liveClass.findUnique({
      where: { id: req.params.id },
      include: { course: true, instructor: true, registrations: { include: { student: { include: { user: true } } } } },
    });
    if (!row) throw notFound('Live class not found.');
    if (studentId) {
      await assertNotSuspended(studentId);
      await assertLearnerMayUse(studentId, row);
    }
    const now = new Date();
    const live = studentId ? forLearner(mapLive(row)) : mapLive(row);
    const mine = studentId ? row.registrations.find((r) => r.studentId === studentId) : undefined;
    const siblings = await db.liveClass.findMany({ where: { courseId: row.courseId }, orderBy: { startsAt: 'asc' } });
    const idx = siblings.findIndex((s) => s.id === row.id);
    res.json({
      liveClass: live,
      phase: deriveLiveClassPhase(mapLive(row), now),
      courseTitle: row.course.title,
      instructorName: row.instructor.name,
      instructorTitle: row.instructor.title,
      ...(studentId
        ? { attendees: [], registered: !!mine, attended: mine?.attended ?? undefined }
        : {
            attendees: row.registrations.map((r) => ({
              id: r.studentId,
              name: r.student.user.name,
              city: r.student.city,
              attended: r.attended ?? undefined,
              joinedAt: r.joinedAt?.toISOString(),
            })),
            recordingViews: readJson<{ views?: number }>(row.recordingJson, {})?.views,
            // What the room can do here, so the host's screen promises only that.
            // `configured: false`: a production server without the video service; nobody can start the built-in room.
            room: {
              provider: roomConfig().provider,
              recording: roomConfig().recording,
              canStart: canStartRoom(live, now) && liveRoomUsable(roomConfig()),
              ...(liveRoomUsable(roomConfig()) ? {} : { configured: false }),
            },
          }),
      attendeeTotal: row.registrations.length,
      previous: idx > 0 ? { id: siblings[idx - 1].id, title: siblings[idx - 1].title, startsAt: siblings[idx - 1].startsAt.toISOString() } : undefined,
      next:
        idx >= 0 && idx < siblings.length - 1
          ? { id: siblings[idx + 1].id, title: siblings[idx + 1].title, startsAt: siblings[idx + 1].startsAt.toISOString() }
          : undefined,
    });
  }),
);

liveRouter.post(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('live.manage'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, liveSchema) as unknown as LiveClassInput;
    const issues = validateLiveClass(input, new Date());
    if (issues.length) throw conflict('Check the class details before scheduling.', issues);
    await assertCourseAccess(req, input.courseId);
    await assertHostAndCourse(input.instructorId, input.courseId);
    await assertNotDuplicate(input);
    const reminders = input.reminders ?? (await getSettings()).notifications.learner.liveReminderMinutes;
    // Counted in the month the class starts, against the plan's live classes a month.
    const row = await db.$transaction((tx) =>
      tx.liveClass.create({
        data: {
          ...tenant(),
          courseId: input.courseId,
          title: input.title,
          instructorId: input.instructorId,
          startsAt: new Date(input.startsAt),
          durationMin: input.durationMin,
          capacity: input.capacity,
          description: input.description,
          agendaJson: writeJson(input.agenda ?? []),
          visibility: input.visibility ?? 'enrolled',
          meetingJson: writeJson(input.meeting ?? { kind: 'room' }),
          remindersJson: writeJson(reminders),
          chapterId: input.chapterId,
        },
        include: { course: { select: { title: true } }, instructor: { select: { name: true } } },
      }),
    );
    // Learners of the course hear about it straight away.
    await notifyLiveScheduled(row, row.course.title, row.instructor.name);
    res.status(201).json(mapLive(row));
  }),
);

liveRouter.patch(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('live.manage'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, liveSchema) as unknown as LiveClassInput;
    const existing = await assertLiveAccess(req, req.params.id);
    // Once a class has started (or was cancelled) its details are history.
    if (existing.cancelled) throw conflict('This class was cancelled and can no longer be edited.');
    if (existing.startsAt <= new Date() || existing.startedAt) throw conflict('This class has already started and can no longer be edited.');
    if (input.courseId && input.courseId !== existing.courseId) await assertCourseAccess(req, input.courseId);
    const registered = await db.liveRegistration.count({ where: { liveClassId: req.params.id } });
    const issues = validateLiveClass(input, new Date(), registered);
    if (issues.length) throw conflict('Check the class details before saving.', issues);
    await assertHostAndCourse(input.instructorId, input.courseId);
    await assertNotDuplicate(input, existing.id);
    const row = await db.$transaction((tx) =>
      tx.liveClass.update({
        where: { id: req.params.id },
        data: {
          courseId: input.courseId,
          title: input.title,
          instructorId: input.instructorId,
          startsAt: new Date(input.startsAt),
          durationMin: input.durationMin,
          capacity: input.capacity,
          description: input.description,
          agendaJson: writeJson(input.agenda ?? []),
          visibility: input.visibility,
          meetingJson: writeJson(input.meeting ?? { kind: 'room' }),
          // Left out, the reminders stay as they are (they used to be wiped).
          ...(input.reminders !== undefined ? { remindersJson: writeJson(input.reminders) } : {}),
          chapterId: input.chapterId,
          // A new start time re-arms every reminder.
          ...(new Date(input.startsAt).getTime() !== existing.startsAt.getTime() ? { remindersSentJson: '[]' } : {}),
        },
        include: { course: { select: { title: true } } },
      }),
    );
    // A new time is news for everyone who was told about the class.
    if (row.startsAt.getTime() !== existing.startsAt.getTime()) await notifyLiveRescheduled(row, row.course.title, existing.startsAt);
    res.json(mapLive(row));
  }),
);

liveRouter.post(
  '/:id/cancel',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('live.manage'),
  asyncHandler(async (req, res) => {
    const { reason } = parseBody(req, z.object({ reason: z.string().trim().max(1000).default('') }));
    if (reason.length < 3) throw badRequest('A reason is required to cancel a class.');
    const existing = await assertLiveAccess(req, req.params.id);
    if (existing.cancelled) throw conflict('This class is already cancelled.');
    if (existing.endedAt || existing.startsAt.getTime() + existing.durationMin * 60_000 <= Date.now()) throw conflict('This class has already ended.');
    if (existing.startedAt) throw conflict('This class is under way. End it from the room instead.');
    const row = await db.liveClass.update({
      where: { id: existing.id },
      data: { cancelled: true, cancelReason: reason },
      include: { course: { select: { title: true } } },
    });
    await notifyLiveCancelled(row, row.course.title, reason);
    res.json(mapLive(row));
  }),
);

liveRouter.post(
  '/:id/remind',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('live.notify'),
  asyncHandler(async (req, res) => {
    const live = await assertLiveAccess(req, req.params.id);
    if (live.cancelled) throw conflict('This class was cancelled.');
    if (live.endedAt || live.startsAt.getTime() + live.durationMin * 60_000 <= Date.now()) throw conflict('This class has already ended.');
    const course = await db.course.findUnique({ where: { id: live.courseId }, select: { title: true } });
    const sender = await db.user.findUnique({ where: { id: req.auth!.sub }, select: { name: true } });
    const sent = await sendLiveReminder(live, course?.title ?? '', sender?.name);
    res.json({ sent });
  }),
);

liveRouter.patch(
  '/:id/reminders',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('live.notify'),
  asyncHandler(async (req, res) => {
    const { reminders } = parseBody(req, z.object({ reminders: z.array(z.number().int().min(0).max(43_200)).max(10) }));
    const live = await assertLiveAccess(req, req.params.id);
    if (live.cancelled || live.endedAt || live.startsAt <= new Date()) throw conflict('Reminders can only be set for a class that hasn’t started.');
    const row = await db.liveClass.update({ where: { id: req.params.id }, data: { remindersJson: writeJson(reminders) } });
    res.json(mapLive(row));
  }),
);

liveRouter.post(
  '/:id/register',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await requireStudent(req);
    // `registered` says what the learner wants, so a double tap or a retry lands in the same place. Left out, it is
    // the old toggle.
    const { registered: wanted } = parseBody(req, z.object({ registered: z.boolean().optional() }));
    const live = await db.liveClass.findUnique({ where: { id: req.params.id } });
    if (!live) throw notFound('Live class not found.');
    await assertLearnerMayUse(studentId, live);
    if (live.cancelled) throw conflict('This class was cancelled.');
    if (live.endedAt || live.startsAt.getTime() + live.durationMin * 60_000 <= Date.now()) throw conflict('This class has already ended.');

    const key = { liveClassId_studentId: { liveClassId: live.id, studentId } };
    const spots = async () => {
      if (live.capacity == null) return 999;
      return Math.max(0, live.capacity - (await db.liveRegistration.count({ where: { liveClassId: live.id } })));
    };
    const existing = await db.liveRegistration.findUnique({ where: key });
    const want = wanted ?? !existing;
    if (!want) {
      if (!existing) return res.json({ registered: false, spotsLeft: await spots() });
      if (existing.attended != null) throw conflict('You have already joined this class, so your place stays.');
      await db.liveRegistration.deleteMany({ where: { liveClassId: live.id, studentId, attended: null } });
      return res.json({ registered: false, spotsLeft: await spots() });
    }
    if (existing) return res.json({ registered: true, spotsLeft: await spots() });
    if (live.capacity != null && (await db.liveRegistration.count({ where: { liveClassId: live.id } })) >= live.capacity) throw conflict('This class is full.');
    try {
      await db.liveRegistration.create({ data: { ...tenant(), liveClassId: live.id, studentId } });
    } catch (err) {
      // The same learner's other request took the place a moment ago: they are registered either way.
      if ((err as { code?: string }).code !== 'P2002') throw err;
    }
    // Two learners racing for the last place: whoever went over gives it back.
    if (live.capacity != null && (await db.liveRegistration.count({ where: { liveClassId: live.id } })) > live.capacity) {
      await db.liveRegistration.deleteMany({ where: { liveClassId: live.id, studentId, attended: null } });
      throw conflict('This class is full.');
    }
    res.json({ registered: true, spotsLeft: await spots() });
  }),
);

/** The video service, read per request so a test (or a restart with new keys) sees the current settings. */
const roomConfig = () => liveRoomConfig();

async function whoIs(userId: string) {
  // Read as the platform: a Super Admin hosts in the workspace but belongs to no academy.
  const user = await runAsPlatform('an account reading its own row, by the id its verified token names', () =>
    db.user.findUnique({ where: { id: userId }, select: { id: true, name: true, email: true } }),
  );
  if (!user) throw notFound('Account not found.');
  return user;
}

/**
 * `POST /live/:id/start` — the host opens the built-in room, from 15 minutes before the start until the
 * scheduled end. The class turns live, the course's learners are told, and the host gets their way in.
 * Starting an open room again is just rejoining it.
 */
liveRouter.post(
  '/:id/start',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('live.manage'),
  asyncHandler(async (req, res) => {
    const existing = await assertLiveAccess(req, req.params.id);
    const live = mapLive(existing);
    if (live.meeting?.kind !== 'room') throw conflict('This class runs on an outside meeting link. Start it in that meeting.');
    if (existing.cancelled) throw conflict('This class was cancelled.');
    if (existing.endedAt) throw conflict('This class has already ended.');
    // Before the class is stamped live and its learners told: a room that cannot run here must not look started.
    assertLiveRoomUsable(roomConfig());
    const now = new Date();
    let row = existing;
    if (!existing.startedAt) {
      if (!canStartRoom(live, now)) {
        throw conflict(
          now.getTime() < existing.startsAt.getTime()
            ? 'You can open the room from 15 minutes before the start time.'
            : 'The time for this class has passed. Schedule a new one.',
        );
      }
      // Only the first start stamps the class, however many hosts press it at once.
      await db.liveClass.updateMany({ where: { id: existing.id, startedAt: null }, data: { startedAt: now, roomName: existing.roomName ?? newRoomName() } });
      row = await db.liveClass.findUniqueOrThrow({ where: { id: existing.id } });
      if (row.startedAt?.getTime() === now.getTime()) {
        const ctx = await db.liveClass.findUniqueOrThrow({
          where: { id: row.id },
          select: { course: { select: { title: true } }, instructor: { select: { name: true } } },
        });
        await notifyLiveStarted(row, ctx.course.title, ctx.instructor.name);
      }
    }
    const user = await whoIs(req.auth!.sub);
    const full = await db.liveClass.findUniqueOrThrow({ where: { id: row.id }, include: { registrations: true } });
    const mapped = mapLive(full);
    res.json({
      liveClass: mapped,
      phase: deriveLiveClassPhase(mapped, new Date()),
      room: roomJoin(roomConfig(), { roomName: full.roomName!, subject: full.title, user, moderator: true, expiresAt: closesAt(full) }),
    });
  }),
);

/**
 * `POST /live/:id/join` — the way into a class that is on. A learner is taken into the room (a place is
 * taken for them if there is one) and marked present; staff who can teach the class rejoin as host. For an
 * outside meeting the answer is its link, and opening it is what counts as joining.
 */
liveRouter.post(
  '/:id/join',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = req.auth!.studentId;
    if (!studentId) {
      if (req.auth!.role !== 'instructor' && req.auth!.role !== 'admin' && req.auth!.role !== 'superadmin')
        throw forbidden('Only learners and staff can join a class.');
      // An admin hosts only with the permission to run live classes; instructors go by what they teach.
      if (req.auth!.role === 'admin' && !(await hasPermission(req.auth!.sub, 'live.manage'))) throw forbidden('You don’t have permission to run live classes.');
      const existing = await assertLiveAccess(req, req.params.id);
      const live = mapLive(existing);
      if (existing.cancelled) throw conflict('This class was cancelled.');
      if (live.meeting?.kind !== 'room') return res.json({ kind: 'external', link: live.meeting?.link });
      assertLiveRoomUsable(roomConfig());
      if (!existing.startedAt) throw conflict('The room is not open yet. Start the class first.');
      if (deriveLiveClassPhase(live, new Date()) !== 'live') throw conflict('This class has ended.');
      const user = await whoIs(req.auth!.sub);
      return res.json({
        kind: 'room',
        room: roomJoin(roomConfig(), { roomName: existing.roomName!, subject: existing.title, user, moderator: true, expiresAt: closesAt(existing) }),
      });
    }

    await requireStudent(req);
    const row = await db.liveClass.findUnique({ where: { id: req.params.id }, include: { registrations: true } });
    if (!row) throw notFound('Live class not found.');
    await assertLearnerMayUse(studentId, row);
    const live = mapLive(row);
    const phase = deriveLiveClassPhase(live, new Date());
    if (row.cancelled) throw conflict('This class was cancelled.');
    if (live.meeting?.kind === 'room' && !row.startedAt) {
      if (phase === 'upcoming' || phase === 'starting-soon')
        throw conflict('The host hasn’t started the class yet. Stay on this page — you can join as soon as they do.');
    }
    if (!canJoin(phase, live)) throw conflict('This class has ended.');

    const mine = row.registrations.find((r) => r.studentId === studentId);
    const now = new Date();
    // What the platform can vouch for: this learner was handed the way into the built-in room while it was open. An outside
    // meeting happens where the platform can't see, so opening its link takes a place but records no attendance.
    const inRoom = live.meeting?.kind === 'room';
    // The way in is made before anything is recorded: a room that cannot run, or a token that cannot be signed, leaves
    // no learner marked present.
    let room: ReturnType<typeof roomJoin> | undefined;
    if (inRoom) {
      assertLiveRoomUsable(roomConfig());
      const user = await whoIs(req.auth!.sub);
      room = roomJoin(roomConfig(), { roomName: row.roomName!, subject: row.title, user, moderator: false, expiresAt: closesAt(row) });
    }
    if (!mine) {
      if (row.capacity != null && row.registrations.length >= row.capacity) throw conflict('This class is full.');
      try {
        await db.liveRegistration.create({ data: { ...tenant(), liveClassId: row.id, studentId, ...(inRoom ? { attended: true } : {}), joinedAt: now } });
      } catch (err) {
        if ((err as { code?: string }).code !== 'P2002') throw err;
      }
    } else {
      await db.liveRegistration.update({
        where: { liveClassId_studentId: { liveClassId: row.id, studentId } },
        data: { ...(inRoom ? { attended: true } : {}), joinedAt: mine.joinedAt ?? now },
      });
    }
    if (!inRoom) return res.json({ kind: 'external', link: live.meeting?.link });
    res.json({ kind: 'room', room });
  }),
);

/** `POST /live/:id/end` — the host closes the room. Learners who held a place and never came are marked absent. */
liveRouter.post(
  '/:id/end',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('live.manage'),
  asyncHandler(async (req, res) => {
    const existing = await assertLiveAccess(req, req.params.id);
    if (!existing.startedAt) throw conflict('This class hasn’t started, so there is nothing to end.');
    if (existing.endedAt) throw conflict('This class has already ended.');
    await endLiveClass(existing.id);
    const row = await db.liveClass.findUniqueOrThrow({ where: { id: existing.id }, include: { registrations: true } });
    const mapped = mapLive(row);
    res.json({ liveClass: mapped, phase: deriveLiveClassPhase(mapped, new Date()) });
  }),
);

/** Whether the caller may watch this class's recording: staff who can teach it, or a learner who may see the class. */
async function assertRecordingAccess(req: Parameters<typeof assertLiveAccess>[0], id: string) {
  const studentId = req.auth!.studentId;
  if (!studentId) await assertLiveAccess(req, id);
  const row = await db.liveClass.findUnique({ where: { id }, select: { id: true, courseId: true, visibility: true, recordingJson: true } });
  if (!row) throw notFound('Live class not found.');
  if (studentId) {
    await assertNotSuspended(studentId);
    await assertLearnerMayUse(studentId, row);
  }
  const file = playableRecording(row.recordingJson);
  if (!file) throw notFound('There is no recording to watch for this class.');
  return file;
}

function sendRecording(res: Parameters<Parameters<typeof asyncHandler>[0]>[1], file: string) {
  res.setHeader('Cache-Control', 'private, no-store');
  res.sendFile(file, { headers: { 'Content-Type': 'video/mp4' }, dotfiles: 'deny' }, (err) => {
    if (err && !res.headersSent) res.status(404).json({ message: 'The recording file is missing.' });
  });
}

/** `GET /live/:id/recording` — the kept recording, streamed with ranges so a player can seek (the app sends its token). */
liveRouter.get(
  '/:id/recording',
  requireAuth,
  asyncHandler(async (req, res) => sendRecording(res, await assertRecordingAccess(req, req.params.id))),
);

/**
 * `POST /live/:id/recording/link` — a link to the same file a browser's `<video>` can open without a header:
 * valid two hours, for this person and this class only.
 */
liveRouter.post(
  '/:id/recording/link',
  requireAuth,
  asyncHandler(async (req, res) => {
    await assertRecordingAccess(req, req.params.id);
    const grant = signGrant('live-recording', { lid: req.params.id, sub: req.auth!.sub, tid: currentTenantId() }, '2h');
    res.json({ url: `/live/recording-files/${grant}` });
  }),
);

liveRouter.get(
  '/recording-files/:grant',
  asyncHandler(async (req, res) => {
    const grant = verifyGrant<{ lid: string; sub: string; tid: string }>('live-recording', req.params.grant);
    if (!grant) throw notFound('This recording link has expired. Open the recording again.');
    const file = await runInTenant(grant.tid, async () => {
      const row = await db.liveClass.findUnique({ where: { id: grant.lid }, select: { recordingJson: true } });
      return row ? playableRecording(row.recordingJson) : null;
    });
    if (!file) throw notFound('There is no recording to watch for this class.');
    sendRecording(res, file);
  }),
);
