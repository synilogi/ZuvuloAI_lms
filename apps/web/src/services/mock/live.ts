import type { LiveClass, LiveClassPhase } from '@syniastrolms/domain';
import { canJoin, canStartRoom, deriveLiveClassPhase, validateLiveClass } from '@syniastrolms/domain';
import type { LiveClassService, LiveClassWrite, LiveDetail, LiveRow, LiveView, RoomJoin } from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { mockNow, mockNowIso } from './clock';
import { courses, instructors } from './fixtures/catalog';
import { personas } from './fixtures/learner';
import { liveSchedule } from './fixtures/live';
import { enrollments, students } from './fixtures/people';
import { learnerLiveClass } from './liveLearner';
import { createRandom, hashSeed } from './random';
import { respond, scenario } from './simulation';

// Past sessions join the academy schedule as soon as the mock backend loads, so every screen counts them.
liveSchedule();

const ME = personas.student.id;
/** Classes the demo learner has registered for. */
const registrations = new Set(['lc-live', 'lc-soon', 'lc-upcoming', 'lc-ended']);

const viewOf = (phase: LiveClassPhase): LiveView =>
  phase === 'upcoming' || phase === 'starting-soon' ? 'upcoming' : phase === 'live' ? 'live' : phase === 'cancelled' ? 'cancelled' : 'history';

const allowedCourses = (scopeInstructorId?: string) =>
  new Set(courses.filter((c) => !scopeInstructorId || c.instructorIds.includes(scopeInstructorId)).map((c) => c.id));

/** Whether the demo session is a learner's: their view of a class carries no outside meeting link, as the API's doesn't. */
function asLearner() {
  try {
    return localStorage.getItem('syniastrolms:demo-role') === 'student';
  } catch {
    return false;
  }
}

function row(cls: LiveClass, now: Date, learner = false): LiveRow {
  return {
    liveClass: learner ? learnerLiveClass(cls) : cls,
    phase: deriveLiveClassPhase(cls, now),
    courseTitle: courses.find((c) => c.id === cls.courseId)?.title ?? '',
    instructorName: instructors.find((i) => i.id === cls.instructorId)?.name ?? '',
  };
}

function find(id: string, scopeInstructorId?: string) {
  const cls = liveSchedule().find((c) => c.id === id);
  if (!cls || !allowedCourses(scopeInstructorId).has(cls.courseId))
    throw new ServiceError('This live class doesn’t exist or isn’t in your courses.', 'not-found');
  return cls;
}

/** The API's checks, with its per-field issues (`ServiceError.issues`) so the editor can place them. */
function assertValid(input: LiveClassWrite, registered = 0) {
  const issues = validateLiveClass(
    { ...input, capacity: input.capacity ?? undefined, description: input.description ?? undefined, chapterId: input.chapterId ?? undefined },
    mockNow(),
    registered,
  );
  if (issues.length) throw new ServiceError('Check the class details before saving.', 'conflict', 'VALIDATION_FAILED', issues, 409);
  const course = courses.find((c) => c.id === input.courseId);
  if (!course) throw new ServiceError('Course not found.', 'not-found');
  if (!instructors.some((i) => i.id === input.instructorId))
    throw new ServiceError(
      'Choose an active instructor to host the class.',
      'conflict',
      undefined,
      [{ field: 'instructor', message: 'Choose an active instructor.' }],
      409,
    );
  if (!course.instructorIds.includes(input.instructorId))
    throw new ServiceError(
      'This instructor doesn’t teach the course.',
      'conflict',
      undefined,
      [{ field: 'instructor', message: 'This instructor doesn’t teach the course.' }],
      409,
    );
}

/** A write as the class it describes: a cleared (`null`) capacity, description or chapter is simply not set. */
function applyWrite(cls: LiveClass, input: LiveClassWrite) {
  const { capacity, description, chapterId, reminders, ...rest } = input;
  Object.assign(cls, rest, { title: input.title.trim() });
  if (capacity === null) delete cls.capacity;
  else if (capacity !== undefined) cls.capacity = capacity;
  if (description === null) delete cls.description;
  else if (description !== undefined) cls.description = description;
  if (chapterId === null) delete cls.chapterId;
  else if (chapterId !== undefined) cls.chapterId = chapterId;
  // Left out, the reminders stay as they are.
  if (reminders !== undefined) cls.reminders = reminders;
}

const endsAt = (cls: LiveClass) => new Date(cls.startsAt).getTime() + cls.durationMin * 60_000;

/** The mock room: the public Jitsi server, named per class — mock mode has no server to mint a name. */
const mockRoom = (cls: LiveClass, moderator: boolean): RoomJoin => ({
  provider: 'jitsi',
  domain: 'meet.jit.si',
  room: `shubh-mock-${cls.id}`,
  subject: cls.title,
  displayName: moderator ? (instructors.find((i) => i.id === cls.instructorId)?.name ?? 'Host') : (students.find((s) => s.id === ME)?.name ?? 'Learner'),
  moderator,
  recording: false,
});

export const liveClassService: LiveClassService = {
  list: ({ view = 'upcoming', search = '', courseId, instructorId, scopeInstructorId, page, pageSize }) =>
    respond(() => {
      const counts: Record<LiveView, number> = { upcoming: 0, live: 0, history: 0, cancelled: 0 };
      if (scenario() === 'empty') return { rows: [], total: 0, counts };
      const now = mockNow();
      const allowed = allowedCourses(scopeInstructorId);
      const q = search.trim().toLowerCase();
      const matching = liveSchedule()
        .filter((c) => allowed.has(c.courseId) && (!courseId || c.courseId === courseId) && (!instructorId || c.instructorId === instructorId))
        .map((c) => row(c, now))
        .filter((r) => !q || `${r.liveClass.title} ${r.courseTitle} ${r.instructorName}`.toLowerCase().includes(q));
      for (const r of matching) counts[viewOf(r.phase)] += 1;
      const rows = matching
        .filter((r) => viewOf(r.phase) === view)
        .sort((a, b) =>
          view === 'upcoming' || view === 'live'
            ? a.liveClass.startsAt.localeCompare(b.liveClass.startsAt)
            : b.liveClass.startsAt.localeCompare(a.liveClass.startsAt),
        );
      return { rows: rows.slice((page - 1) * pageSize, page * pageSize), total: rows.length, counts };
    }, 480),

  get: (id, scopeInstructorId) =>
    respond((): LiveDetail => {
      const cls = find(id, scopeInstructorId);
      const now = mockNow();
      const learner = asLearner();
      const base = row(cls, now, learner);
      const instructor = instructors.find((i) => i.id === cls.instructorId);
      const rng = createRandom(hashSeed(`attendees:${cls.id}`));
      const pool = enrollments.filter((e) => e.courseId === cls.courseId && e.status !== 'paused');
      const total = cls.cancelled ? 0 : Math.min(cls.registered ?? 0, pool.length);
      const picked = rng.shuffle(pool).slice(0, Math.min(total, 12));
      if (registrations.has(cls.id) && !picked.some((e) => e.studentId === ME) && pool.some((e) => e.studentId === ME))
        picked.unshift(pool.find((e) => e.studentId === ME)!);
      const ended = base.phase === 'ended' || base.phase === 'recording-expired';
      const attendRate = cls.attended && cls.registered ? cls.attended / cls.registered : 0.7;
      const siblings = liveSchedule()
        .filter((c) => c.courseId === cls.courseId && c.id !== cls.id && !c.cancelled)
        .sort((a, b) => a.startsAt.localeCompare(b.startsAt));
      const previous = [...siblings].reverse().find((c) => c.startsAt < cls.startsAt);
      const next = siblings.find((c) => c.startsAt > cls.startsAt);
      if (learner)
        return {
          ...base,
          instructorTitle: instructor?.title ?? '',
          attendees: [],
          attendeeTotal: total,
          registered: registrations.has(cls.id),
          previous: previous && { id: previous.id, title: previous.title, startsAt: previous.startsAt },
          next: next && { id: next.id, title: next.title, startsAt: next.startsAt },
        };
      return {
        ...base,
        instructorTitle: instructor?.title ?? '',
        attendees: picked.slice(0, 12).map((e) => {
          const s = students.find((x) => x.id === e.studentId);
          return { id: e.studentId, name: s?.name ?? 'Learner', city: s?.city ?? '', attended: ended ? rng.next() < attendRate : undefined };
        }),
        attendeeTotal: total,
        recordingViews: cls.recording ? Math.round((cls.attended ?? 20) * 1.6 + (hashSeed(cls.id) % 40)) : undefined,
        room: { provider: 'jitsi', recording: false, canStart: canStartRoom(cls, now) },
        previous: previous && { id: previous.id, title: previous.title, startsAt: previous.startsAt },
        next: next && { id: next.id, title: next.title, startsAt: next.startsAt },
      };
    }, 520),

  create: (input) =>
    respond(() => {
      assertValid(input);
      const duplicate = liveSchedule().some(
        (c) =>
          !c.cancelled &&
          c.courseId === input.courseId &&
          c.instructorId === input.instructorId &&
          c.title === input.title.trim() &&
          Date.parse(c.startsAt) === Date.parse(input.startsAt),
      );
      if (duplicate)
        throw new ServiceError(
          'This class is already scheduled.',
          'conflict',
          undefined,
          [{ field: 'startsAt', message: 'This class is already scheduled at this time.' }],
          409,
        );
      const cls: LiveClass = {
        id: `lc-${Date.now().toString(36)}`,
        courseId: input.courseId,
        title: '',
        instructorId: '',
        startsAt: '',
        durationMin: 0,
        registered: 0,
      };
      applyWrite(cls, { ...input, reminders: input.reminders ?? [1440, 60, 15] });
      // The API answers with the moment, in UTC — never the offset the editor sent.
      cls.startsAt = new Date(input.startsAt).toISOString();
      liveSchedule().push(cls);
      invalidateAnalytics();
      return cls;
    }, 850),

  update: (id, input) =>
    respond(() => {
      const cls = find(id);
      if (cls.cancelled) throw new ServiceError('This class was cancelled and can no longer be edited.', 'conflict');
      if (Date.parse(cls.startsAt) <= mockNow().getTime() || cls.startedAt)
        throw new ServiceError('This class has already started and can no longer be edited.', 'conflict');
      assertValid(input, cls.registered ?? 0);
      applyWrite(cls, input);
      cls.startsAt = new Date(input.startsAt).toISOString();
      invalidateAnalytics();
      return cls;
    }, 800),

  cancel: (id, reason) =>
    respond(() => {
      const cls = find(id);
      if (reason.trim().length < 3) throw new ServiceError('A reason is required to cancel a class.', 'conflict');
      if (cls.cancelled) throw new ServiceError('This class is already cancelled.', 'conflict');
      if (cls.endedAt || endsAt(cls) <= mockNow().getTime()) throw new ServiceError('This class has already ended.', 'conflict');
      if (cls.startedAt) throw new ServiceError('This class is under way. End it from the room instead.', 'conflict');
      cls.cancelled = true;
      cls.cancelReason = reason.trim();
      invalidateAnalytics();
      return cls;
    }, 800),

  sendReminder: (id) =>
    respond(() => {
      const cls = find(id);
      if (cls.cancelled) throw new ServiceError('This class was cancelled.', 'conflict');
      if (cls.endedAt || endsAt(cls) <= mockNow().getTime()) throw new ServiceError('This class has already ended.', 'conflict');
      if (!cls.registered) throw new ServiceError('Nobody has registered yet.', 'conflict');
      return { sent: cls.registered };
    }, 700),

  setReminders: (id, reminders) =>
    respond(() => {
      const cls = find(id);
      if (cls.cancelled || cls.endedAt || Date.parse(cls.startsAt) <= mockNow().getTime())
        throw new ServiceError('Reminders can only be set for a class that hasn’t started.', 'conflict');
      cls.reminders = [...reminders].sort((a, b) => b - a);
      return cls;
    }, 400),

  forLearner: () =>
    respond(() => {
      if (scenario() === 'empty') return { live: [], upcoming: [], recordings: [] };
      const now = mockNow();
      const mine = new Set(enrollments.filter((e) => e.studentId === ME && e.status !== 'expired').map((e) => e.courseId));
      const rows = liveSchedule()
        .filter((c) => mine.has(c.courseId) || c.visibility === 'public')
        .map((c) => row(c, now, true));
      return {
        live: rows
          .filter((r) => r.phase === 'live')
          .sort((a, b) => a.liveClass.startsAt.localeCompare(b.liveClass.startsAt))
          .map((r) => ({ ...r, registered: registrations.has(r.liveClass.id) })),
        upcoming: rows
          .filter((r) => r.phase === 'upcoming' || r.phase === 'starting-soon' || (r.phase === 'cancelled' && r.liveClass.startsAt > mockNowIso()))
          .sort((a, b) => a.liveClass.startsAt.localeCompare(b.liveClass.startsAt))
          .map((r) => ({ ...r, registered: registrations.has(r.liveClass.id) })),
        recordings: rows.filter((r) => r.phase === 'ended').sort((a, b) => b.liveClass.startsAt.localeCompare(a.liveClass.startsAt)),
        history: rows
          .filter((r) => (r.phase === 'ended' || r.phase === 'recording-expired') && registrations.has(r.liveClass.id))
          .map((r) => ({ ...r, attended: true })),
      };
    }, 480),

  register: (id, wanted) =>
    respond(() => {
      const cls = find(id);
      if (cls.cancelled) throw new ServiceError('This class was cancelled.', 'conflict');
      if (cls.endedAt || endsAt(cls) <= mockNow().getTime()) throw new ServiceError('This class has already ended.', 'conflict');
      // The state wanted, as the API takes it: asking twice lands in the same place.
      const spots = () => (cls.capacity === undefined ? 999 : Math.max(0, cls.capacity - (cls.registered ?? 0)));
      if (!wanted) {
        if (registrations.delete(id)) cls.registered = Math.max(0, (cls.registered ?? 1) - 1);
        return { registered: false, spotsLeft: spots() };
      }
      if (registrations.has(id)) return { registered: true, spotsLeft: spots() };
      if (cls.capacity !== undefined && (cls.registered ?? 0) >= cls.capacity) throw new ServiceError('This class is full.', 'conflict');
      registrations.add(id);
      cls.registered = (cls.registered ?? 0) + 1;
      return { registered: true, spotsLeft: spots() };
    }, 600),

  start: (id) =>
    respond(() => {
      const cls = find(id);
      if (cls.meeting?.kind !== 'room') throw new ServiceError('This class runs on an outside meeting link. Start it in that meeting.', 'conflict');
      if (cls.endedAt) throw new ServiceError('This class has already ended.', 'conflict');
      if (!cls.startedAt) {
        if (!canStartRoom(cls, mockNow())) throw new ServiceError('You can open the room from 15 minutes before the start time.', 'conflict');
        cls.startedAt = mockNowIso();
        cls.attending = 0;
      }
      return { liveClass: cls, phase: deriveLiveClassPhase(cls, mockNow()), room: mockRoom(cls, true) };
    }, 600),

  join: (id) =>
    respond(() => {
      const cls = find(id);
      const phase = deriveLiveClassPhase(cls, mockNow());
      if (cls.cancelled) throw new ServiceError('This class was cancelled.', 'conflict');
      if (cls.meeting?.kind === 'room' && !cls.startedAt && (phase === 'upcoming' || phase === 'starting-soon'))
        throw new ServiceError('The host hasn’t started the class yet. Stay on this page — you can join as soon as they do.', 'conflict');
      // The outside meeting's link is handed over only inside the join window, as the API does.
      if (!canJoin(phase, cls))
        throw new ServiceError(phase === 'upcoming' ? 'You can join from 15 minutes before the start.' : 'This class has ended.', 'conflict');
      const learner = asLearner();
      // A learner joining takes a place if there is one; staff rejoin as the host.
      if (learner && !registrations.has(id)) {
        if (cls.capacity !== undefined && (cls.registered ?? 0) >= cls.capacity) throw new ServiceError('This class is full.', 'conflict');
        registrations.add(id);
        cls.registered = (cls.registered ?? 0) + 1;
      }
      if (cls.meeting?.kind === 'external') return { kind: 'external' as const, link: cls.meeting.link };
      return { kind: 'room' as const, room: mockRoom(cls, !learner) };
    }, 500),

  end: (id) =>
    respond(() => {
      const cls = find(id);
      if (!cls.startedAt) throw new ServiceError('This class hasn’t started, so there is nothing to end.', 'conflict');
      if (cls.endedAt) throw new ServiceError('This class has already ended.', 'conflict');
      cls.endedAt = mockNowIso();
      cls.attended = cls.attending ?? 0;
      cls.attending = undefined;
      invalidateAnalytics();
      return { liveClass: cls, phase: deriveLiveClassPhase(cls, mockNow()) };
    }, 600),

  recordingLink: () =>
    respond(() => {
      throw new ServiceError('Recordings play from the academy’s video service, which mock mode doesn’t have.', 'not-found');
    }, 300),
};
