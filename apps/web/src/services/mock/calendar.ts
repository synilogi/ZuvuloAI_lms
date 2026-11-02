import type { CalendarEvent, CalendarEventInput, CalendarEventType, Enrollment, LiveClass } from '@syniastrolms/domain';
import { CALENDAR_EVENT_TYPES, calendarEventEnd, deriveLiveClassPhase, validateCalendarEvent } from '@syniastrolms/domain';
import type { CalendarDetail, CalendarRow, CalendarService } from '../contracts';
import { ServiceError } from '../contracts';
import { mockNow } from './clock';
import { courseAssignments, submissions } from './fixtures/assignments';
import { calendarEvents, cohortPlan } from './fixtures/calendar';
import { courseById, courses, instructors } from './fixtures/catalog';
import { liveSchedule } from './fixtures/live';
import { enrollments, students } from './fixtures/people';
import { quizzes } from './fixtures/quizzes';
import { DAY_MS, dayKey } from './random';
import { respond, scenario } from './simulation';

const zeroCounts = () => Object.fromEntries(CALENDAR_EVENT_TYPES.map((t) => [t, 0])) as Record<CalendarEventType, number>;

const liveEvent = (cls: LiveClass): CalendarEvent => ({
  id: `live.${cls.id}`,
  type: 'live',
  title: cls.title,
  description: cls.description,
  timing: 'timed',
  startsAt: cls.startsAt,
  durationMin: cls.durationMin,
  courseId: cls.courseId,
  chapterId: cls.chapterId,
  instructorId: cls.instructorId,
  notifyMin: cls.reminders?.length ? Math.min(...cls.reminders) : undefined,
  cancelled: cls.cancelled,
  source: { kind: 'live-class', id: cls.id },
});

const current = (e: Enrollment) => e.status === 'active' || e.status === 'paused';

/** Learners in a cohort course's current intake — enrolled in the six weeks before it started, or its first week. */
function cohortLearners(courseId: string) {
  const course = courseById(courseId);
  const plan = course && cohortPlan(course);
  if (!plan) return enrollments.filter((e) => e.courseId === courseId && current(e));
  const start = new Date(`${plan.startsOn}T00:00:00+05:30`).getTime();
  return enrollments.filter((e) => {
    const t = new Date(e.enrolledAt).getTime();
    return e.courseId === courseId && current(e) && t >= start - 45 * DAY_MS && t < start + 7 * DAY_MS;
  });
}

interface Deadline {
  event: CalendarEvent;
  pool: Enrollment[];
  handedIn: Set<string>;
}

/** One shared deadline per published assignment: a fixed date, or its chapter's opening plus the allowed days in a cohort. */
function deadlines(): Deadline[] {
  const out: Deadline[] = [];
  for (const a of courseAssignments) {
    const course = courseById(a.courseId);
    if (a.status !== 'published' || !course) continue;
    let startsAt: string | undefined;
    if (a.due.kind === 'date') startsAt = a.due.dueAt;
    else if (a.due.kind === 'relative') {
      const plan = cohortPlan(course);
      const index = course.chapters.findIndex((c) => c.id === a.chapterId);
      if (plan && index >= 0)
        startsAt = `${dayKey(new Date(new Date(`${plan.releases[index]}T00:00:00+05:30`).getTime() + a.due.days * DAY_MS))}T23:59:00+05:30`;
    }
    if (!startsAt) continue;
    const pool = cohortLearners(course.id);
    const handedIn = new Set(
      submissions()
        .filter((s) => s.assignmentId === a.id)
        .map((s) => s.studentId),
    );
    out.push({
      event: {
        id: `due.${a.id}`,
        type: 'assignment',
        title: a.title,
        timing: 'moment',
        startsAt,
        courseId: course.id,
        chapterId: a.chapterId,
        instructorId: course.instructorIds[0],
        source: { kind: 'assignment', id: a.id },
      },
      pool,
      handedIn,
    });
  }
  return out;
}

const dueOf = (d: Deadline) => ({ learners: d.pool.length, submitted: d.pool.filter((e) => d.handedIn.has(e.studentId)).length });

function decorate(row: CalendarRow): CalendarRow {
  const course = row.event.courseId ? courseById(row.event.courseId) : undefined;
  const instructor = row.event.instructorId ? instructors.find((i) => i.id === row.event.instructorId) : undefined;
  return { ...row, courseTitle: course?.title, instructorName: instructor?.name };
}

function allRows(viewerId: string, scopeInstructorId?: string): CalendarRow[] {
  const now = mockNow();
  const allowed = new Set(courses.filter((c) => !scopeInstructorId || c.instructorIds.includes(scopeInstructorId)).map((c) => c.id));
  const rows: CalendarRow[] = [
    ...liveSchedule().map((cls) => ({ event: liveEvent(cls), phase: deriveLiveClassPhase(cls, now) })),
    ...deadlines().map((d) => ({ event: d.event, due: dueOf(d) })),
    ...calendarEvents()
      .filter((e) => e.type !== 'reminder' || e.ownerId === viewerId)
      .map((event) => ({ event })),
  ];
  return rows.filter((r) => (r.event.type === 'reminder' ? true : Boolean(r.event.courseId && allowed.has(r.event.courseId)))).map(decorate);
}

const teaches = (row: CalendarRow, instructorId: string) =>
  row.event.type === 'live'
    ? row.event.instructorId === instructorId
    : row.event.instructorId === instructorId || Boolean(row.event.courseId && courseById(row.event.courseId)?.instructorIds.includes(instructorId));

function findNative(id: string) {
  const event = calendarEvents().find((e) => e.id === id);
  if (!event) {
    const derived = id.startsWith('live.') || id.startsWith('due.');
    throw new ServiceError(
      derived ? 'This event comes from its own page — change it there.' : 'This event doesn’t exist or was deleted.',
      derived ? 'conflict' : 'not-found',
    );
  }
  return event;
}

function assertInput(input: CalendarEventInput) {
  const issues = validateCalendarEvent(input, mockNow());
  if (issues.length) throw new ServiceError(issues[0].message, 'conflict');
  const course = input.courseId ? courseById(input.courseId) : undefined;
  if (input.courseId && !course) throw new ServiceError('Choose the course this event belongs to.', 'conflict');
  if (input.quizId && !quizzes.some((q) => q.id === input.quizId && q.courseId === input.courseId))
    throw new ServiceError('Choose a quiz from this course.', 'conflict');
  if (input.chapterId && !course?.chapters.some((c) => c.id === input.chapterId)) throw new ServiceError('Choose a chapter from this course.', 'conflict');
  return course;
}

/** Only the fields that apply to the event's type are kept. */
function normalise(input: CalendarEventInput): CalendarEventInput {
  return {
    type: input.type,
    title: input.title.trim(),
    description: input.description?.trim() || undefined,
    timing: input.type === 'milestone' ? 'all-day' : input.timing,
    startsAt: input.startsAt,
    durationMin: input.timing === 'timed' && input.type !== 'milestone' ? input.durationMin : undefined,
    courseId: input.courseId || undefined,
    chapterId: input.type !== 'reminder' ? input.chapterId || undefined : undefined,
    quizId: input.type === 'quiz' ? input.quizId : undefined,
    milestone: input.type === 'milestone' ? input.milestone : undefined,
    audience: input.type === 'reminder' ? (input.audience ?? 'me') : undefined,
    notifyMin: input.notifyMin,
  };
}

export const calendarService: CalendarService = {
  list: ({ from, to, types, courseId, instructorId, scopeInstructorId, viewerId }) =>
    respond(() => {
      const counts = zeroCounts();
      if (scenario() === 'empty') return { rows: [], counts, total: 0 };
      const start = new Date(`${from}T00:00:00+05:30`).getTime();
      const end = new Date(`${to}T00:00:00+05:30`).getTime() + DAY_MS;
      const inRange = allRows(viewerId, scopeInstructorId).filter((r) => {
        const s = new Date(r.event.startsAt).getTime();
        return s < end && Math.max(calendarEventEnd(r.event).getTime(), s + 1) > start;
      });
      const filtered = inRange.filter((r) => (!courseId || r.event.courseId === courseId) && (!instructorId || teaches(r, instructorId)));
      for (const r of filtered) counts[r.event.type] += 1;
      const rows = filtered
        .filter((r) => !types || types.includes(r.event.type))
        .sort(
          (a, b) => a.event.startsAt.localeCompare(b.event.startsAt) || CALENDAR_EVENT_TYPES.indexOf(a.event.type) - CALENDAR_EVENT_TYPES.indexOf(b.event.type),
        );
      return { rows, counts, total: inRange.length };
    }, 420),

  get: (id, viewerId, scopeInstructorId) =>
    respond((): CalendarDetail => {
      const row = allRows(viewerId, scopeInstructorId).find((r) => r.event.id === id);
      if (!row) throw new ServiceError('This event doesn’t exist, was deleted, or isn’t in your courses.', 'not-found');
      const e = row.event;
      const course = e.courseId ? courseById(e.courseId) : undefined;
      const instructor = e.instructorId ? instructors.find((i) => i.id === e.instructorId) : undefined;
      const detail: CalendarDetail = {
        ...row,
        chapterTitle: course?.chapters.find((c) => c.id === e.chapterId)?.title,
        instructorTitle: instructor?.title,
        editable: !e.source,
      };
      if (e.source?.kind === 'live-class') {
        const cls = liveSchedule().find((c) => c.id === e.source!.id);
        if (cls) detail.live = { registered: cls.registered ?? 0, capacity: cls.capacity, attended: cls.attended };
      }
      if (e.source?.kind === 'assignment') {
        const d = deadlines().find((x) => x.event.id === e.id);
        if (d) {
          // Learners who still owe the work come first — they're the ones to follow up.
          detail.learnersDue = d.pool
            .map((en) => ({ id: en.studentId, name: students.find((s) => s.id === en.studentId)?.name ?? 'Learner', submitted: d.handedIn.has(en.studentId) }))
            .sort((a, b) => Number(a.submitted) - Number(b.submitted) || a.name.localeCompare(b.name))
            .slice(0, 8);
        }
      }
      if (e.quizId) {
        const quiz = quizzes.find((q) => q.id === e.quizId);
        if (quiz)
          detail.quiz = {
            id: quiz.id,
            title: quiz.title,
            status: quiz.status,
            questions: quiz.questions.length,
            timeLimitMin: quiz.settings.timeLimitMin,
            attempts: quiz.settings.attempts,
            passMark: quiz.settings.passMark,
          };
      }
      if (e.courseId && (e.type === 'quiz' || e.type === 'milestone' || (e.type === 'reminder' && e.audience === 'learners'))) {
        detail.audienceSize = course?.status === 'draft' ? 0 : cohortLearners(e.courseId).length;
      }
      return detail;
    }, 380),

  create: (input, ownerId) =>
    respond(() => {
      const clean = normalise(input);
      const course = assertInput(clean);
      const event: CalendarEvent = {
        ...clean,
        id: `ce-${Date.now().toString(36)}`,
        instructorId: clean.type === 'reminder' ? undefined : course?.instructorIds[0],
        ownerId: clean.type === 'reminder' ? ownerId : undefined,
      };
      calendarEvents().push(event);
      return event;
    }, 700),

  update: (id, input) =>
    respond(() => {
      const event = findNative(id);
      if (calendarEventEnd(event).getTime() <= mockNow().getTime())
        throw new ServiceError('This event has already happened, so it can’t be changed.', 'conflict');
      const clean = normalise({ ...input, type: event.type });
      const course = assertInput(clean);
      for (const key of Object.keys(clean) as (keyof CalendarEventInput)[]) if (clean[key] === undefined) delete event[key];
      Object.assign(event, clean, { instructorId: event.type === 'reminder' ? undefined : course?.instructorIds[0] });
      return event;
    }, 650),

  remove: (id) =>
    respond(() => {
      const event = findNative(id);
      const list = calendarEvents();
      list.splice(list.indexOf(event), 1);
    }, 500),

  setDone: (id, done) =>
    respond(() => {
      const event = findNative(id);
      if (event.type !== 'reminder') throw new ServiceError('Only reminders can be marked as done.', 'conflict');
      event.done = done;
      return event;
    }, 350),
};
