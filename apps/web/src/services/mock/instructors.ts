import type { AdminEvent, Course, Enrollment, Instructor, InstructorInput } from '@syniastrolms/domain';
import { completionRate, needsReview, reviewOverdue, validateInstructor } from '@syniastrolms/domain';
import type { InstructorAdminService, InstructorCourse, InstructorProfile, InstructorRow } from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { mockNowIso } from './clock';
import { courseAssignments, submissions } from './fixtures/assignments';
import { courses, instructors, levels } from './fixtures/catalog';
import { DEMO_NOW } from './fixtures/learner';
import { enrollments, students } from './fixtures/people';
import { academyEvents, academyLiveClasses } from './fixtures/schedule';
import { createRandom, DAY_MS, hashSeed, toIST } from './random';
import { respond, scenario } from './simulation';
import { formatShortDate } from '@/lib/format';

const NOW = new Date(DEMO_NOW);
const HOUR = 3_600_000;

const teaching = (id: string) => courses.filter((c) => c.instructorIds.includes(id));

function byCourse() {
  const map = new Map<string, Enrollment[]>();
  for (const e of enrollments) {
    const list = map.get(e.courseId);
    if (list) list.push(e);
    else map.set(e.courseId, [e]);
  }
  return map;
}

function find(id: string) {
  const instructor = instructors.find((i) => i.id === id);
  if (!instructor) throw new ServiceError('This instructor doesn’t exist.', 'not-found');
  return instructor;
}

/** Ratings weighted by how many learners rated each course. */
function weightedRating(list: Course[]) {
  const rated = list.filter((c) => c.status === 'published' && c.rating && c.ratingCount);
  const count = rated.reduce((n, c) => n + (c.ratingCount ?? 0), 0);
  return { rating: count ? Math.round((rated.reduce((n, c) => n + (c.rating ?? 0) * (c.ratingCount ?? 0), 0) / count) * 10) / 10 : null, count };
}

function row(instructor: Instructor, enrollmentsByCourse: Map<string, Enrollment[]>): InstructorRow {
  const list = teaching(instructor.id);
  const ids = new Set(list.map((c) => c.id));
  const learners = new Set<string>();
  const own: Enrollment[] = [];
  for (const c of list)
    for (const e of enrollmentsByCourse.get(c.id) ?? []) {
      learners.add(e.studentId);
      own.push(e);
    }
  const queue = submissions().filter((s) => needsReview(s) && ids.has(courseAssignments.find((a) => a.id === s.assignmentId)?.courseId ?? ''));
  const { rating, count } = weightedRating(list);
  return {
    instructor,
    courses: list.map((c) => ({ id: c.id, title: c.title, status: c.status })),
    students: learners.size,
    rating,
    ratingCount: count,
    completion: own.length ? completionRate(own) : null,
    toReview: queue.length,
    overdue: queue.filter((s) => reviewOverdue(s, NOW)).length,
  };
}

function assertValid(input: InstructorInput, selfId?: string) {
  const taken = instructors.filter((i) => i.id !== selfId).map((i) => i.email);
  const issues = validateInstructor(input, taken);
  if (issues.length) throw new ServiceError(issues[0].message, 'conflict');
  const unknown = input.courseIds.find((id) => !courses.some((c) => c.id === id));
  if (unknown) throw new ServiceError('One of the assigned courses no longer exists.', 'conflict');
}

/** Keeps each course's instructor list in step with the courses assigned on the form. */
function assignCourses(instructorId: string, courseIds: string[]) {
  for (const course of courses) {
    const has = course.instructorIds.includes(instructorId);
    const wants = courseIds.includes(course.id);
    if (wants && !has) course.instructorIds = [...course.instructorIds, instructorId];
    if (!wants && has) {
      if (course.instructorIds.length === 1)
        throw new ServiceError(`${course.title} needs at least one instructor. Assign someone else before removing this one.`, 'conflict');
      course.instructorIds = course.instructorIds.filter((id) => id !== instructorId);
    }
  }
}

const slug = (name: string) =>
  name
    .toLowerCase()
    .replace(/^(dr|pt|acharya)\.?\s+/, '')
    .replace(/[^a-z]+/g, '-')
    .replace(/^-|-$/g, '')
    .split('-')[0];

export const instructorAdminService: InstructorAdminService = {
  list: ({ search = '', status = 'all', expertise, sort = 'name' }) =>
    respond(() => {
      if (scenario() === 'empty') return { rows: [], counts: { all: 0, active: 0, invited: 0, inactive: 0 }, expertise: [] };
      const q = search.trim().toLowerCase();
      const map = byCourse();
      const matching = instructors
        .filter((i) => !q || `${i.name} ${i.title} ${i.email} ${i.expertise.join(' ')}`.toLowerCase().includes(q))
        .filter((i) => !expertise || i.expertise.includes(expertise))
        .map((i) => row(i, map));
      const counts = { all: matching.length, active: 0, invited: 0, inactive: 0 };
      for (const r of matching) counts[r.instructor.status] += 1;
      const rows = matching.filter((r) => status === 'all' || r.instructor.status === status);
      const name = (i: Instructor) => i.name.replace(/^(Dr\.|Pt\.|Acharya)\s+/, '');
      rows.sort((a, b) =>
        sort === 'students'
          ? b.students - a.students
          : sort === 'rating'
            ? (b.rating ?? 0) - (a.rating ?? 0)
            : sort === 'joined'
              ? b.instructor.joinedAt.localeCompare(a.instructor.joinedAt)
              : name(a.instructor).localeCompare(name(b.instructor)),
      );
      return { rows, counts, expertise: [...new Set(instructors.flatMap((i) => i.expertise))].sort() };
    }, 480),

  get: (id) =>
    respond((): InstructorProfile => {
      const instructor = find(id);
      const list = teaching(id);
      const map = byCourse();
      const ids = new Set(list.map((c) => c.id));
      const rng = createRandom(hashSeed(`instructor:${id}`));

      const courseRows: InstructorCourse[] = list.map((c) => {
        const own = map.get(c.id) ?? [];
        return {
          id: c.id,
          title: c.title,
          status: c.status,
          levelTitle: levels.find((l) => l.id === c.levelId)?.name ?? '',
          coverMotif: c.coverMotif,
          coverImageUrl: c.coverImageUrl,
          role: c.instructorIds[0] === id ? 'lead' : 'co',
          coInstructors: c.instructorIds.filter((x) => x !== id).map((x) => instructors.find((i) => i.id === x)?.name ?? ''),
          enrolled: own.length,
          activeLearners: own.filter((e) => e.status === 'active').length,
          rating: c.status === 'published' ? c.rating : undefined,
          ratingCount: c.status === 'published' ? c.ratingCount : undefined,
          completion: own.length ? completionRate(own) : null,
          lessons: c.chapters.reduce((n, ch) => n + ch.lessons.length, 0),
          updatedAt: c.updatedAt,
        };
      });

      // Reach
      const learners = new Map<string, Enrollment[]>();
      for (const c of list) for (const e of map.get(c.id) ?? []) learners.set(e.studentId, [...(learners.get(e.studentId) ?? []), e]);
      const cityCounts = new Map<string, number>();
      for (const sid of learners.keys()) {
        const city = students.find((s) => s.id === sid)?.city;
        if (city) cityCounts.set(city, (cityCounts.get(city) ?? 0) + 1);
      }
      const monthAgo = NOW.getTime() - 30 * DAY_MS;
      const all = [...learners.values()].flat();

      // Reviews by this instructor
      const reviewed = submissions().filter(
        (s) => s.review.reviewerId === id && (s.review.status === 'graded' || s.review.status === 'returned') && s.review.updatedAt,
      );
      const hours = reviewed.map((s) => (new Date(s.review.updatedAt!).getTime() - new Date(s.submittedAt).getTime()) / HOUR).sort((a, b) => a - b);
      const queue = submissions().filter((s) => needsReview(s) && ids.has(courseAssignments.find((a) => a.id === s.assignmentId)?.courseId ?? ''));

      // Live classes
      const live = academyLiveClasses.filter((l) => l.instructorId === id && !l.cancelled);
      const delivered = live.filter((l) => new Date(l.startsAt).getTime() + l.durationMin * 60_000 < NOW.getTime());
      const pastSessions = delivered.length + Math.round(list.reduce((n, c) => n + (c.status === 'published' ? c.liveSessions : 0), 0) * 0.7);

      // Enrollments per month, eight months ending this month
      const enrollmentsByMonth = Array.from({ length: 8 }, (_, i) => {
        const end = new Date(NOW.getFullYear(), NOW.getMonth() - (6 - i), 1);
        const start = new Date(NOW.getFullYear(), NOW.getMonth() - (7 - i), 1);
        const value = all.filter((e) => {
          const t = new Date(e.enrolledAt).getTime();
          return t >= start.getTime() && t < (i === 7 ? NOW.getTime() + 1 : end.getTime());
        }).length;
        const label = formatShortDate(start).split(' ')[1] ?? '';
        return { label, detail: i === 7 ? `${label} so far` : `${label} ${start.getFullYear()}`, value };
      });

      const academy = weightedRating(courses);
      const { rating, count } = weightedRating(list);

      // Activity: the academy feed for this person, plus what their work implies
      const events: AdminEvent[] = academyEvents.filter((e) => e.actor === instructor.name);
      for (const c of list) {
        if (c.publishedAt)
          events.push({
            id: `pub-${c.id}`,
            kind: 'course-published',
            actor: instructor.name,
            summary: `published ${c.title}`,
            courseId: c.id,
            at: c.publishedAt,
            to: `/admin/courses/${c.id}`,
          });
        if (c.updatedAt !== c.publishedAt)
          events.push({
            id: `upd-${c.id}`,
            kind: 'course-updated',
            actor: instructor.name,
            summary: `updated ${c.title}`,
            context: `${c.chapters.length} chapters`,
            courseId: c.id,
            at: c.updatedAt,
            to: `/admin/courses/${c.id}/curriculum`,
          });
      }
      const byDay = new Map<string, typeof reviewed>();
      for (const s of reviewed) {
        if (NOW.getTime() - new Date(s.review.updatedAt!).getTime() > 21 * DAY_MS) continue;
        const day = s.review.updatedAt!.slice(0, 10);
        byDay.set(day, [...(byDay.get(day) ?? []), s]);
      }
      for (const [day, list] of byDay) {
        const latest = list
          .map((s) => s.review.updatedAt!)
          .sort()
          .at(-1)!;
        const title = courseAssignments.find((a) => a.id === list[0].assignmentId)?.title;
        events.push({
          id: `rev-${id}-${day}`,
          kind: 'review',
          actor: instructor.name,
          summary: `reviewed ${list.length === 1 ? 'a submission' : `${list.length} submissions`}`,
          context: title,
          at: latest,
          to: '/admin/assignments',
        });
      }
      for (const l of live) {
        const ended = new Date(l.startsAt).getTime() < NOW.getTime();
        events.push({
          id: `live-${l.id}`,
          kind: 'live-scheduled',
          actor: instructor.name,
          summary: ended ? `hosted ${l.title}` : `scheduled ${l.title}`,
          context: l.registered ? `${l.registered} registered` : undefined,
          courseId: l.courseId,
          at: ended ? l.startsAt : toIST(new Date(new Date(l.startsAt).getTime() - (4 + rng.int(0, 9)) * DAY_MS)),
          to: '/admin/live',
        });
      }
      if (instructor.status === 'invited')
        events.push({
          id: `inv-${id}`,
          kind: 'instructor',
          actor: 'Kavita Menon',
          summary: `invited ${instructor.name}`,
          context: instructor.email,
          at: instructor.joinedAt,
        });
      const seen = new Set<string>();
      const activity = events
        .filter((e) => new Date(e.at).getTime() <= NOW.getTime() && !seen.has(e.id) && seen.add(e.id))
        .sort((a, b) => b.at.localeCompare(a.at))
        .slice(0, 12);

      return {
        instructor,
        courses: courseRows,
        reach: {
          students: learners.size,
          active: new Set(all.filter((e) => e.status === 'active').map((e) => e.studentId)).size,
          completed: new Set(all.filter((e) => e.status === 'completed').map((e) => e.studentId)).size,
          newThisMonth: new Set(all.filter((e) => new Date(e.enrolledAt).getTime() > monthAgo).map((e) => e.studentId)).size,
          cities: [...cityCounts.entries()]
            .sort((a, b) => b[1] - a[1])
            .slice(0, 5)
            .map(([city, n]) => ({ city, count: n })),
        },
        performance: {
          rating,
          ratingCount: count,
          academyRating: academy.rating ?? 0,
          completion: all.length ? completionRate(all) : null,
          academyCompletion: completionRate(enrollments),
          reviewHoursMedian: hours.length ? Math.round(hours[Math.floor(hours.length / 2)]) : null,
          reviewsOnTime: hours.length ? Math.round((hours.filter((h) => h <= 48).length / hours.length) * 100) : null,
          reviewed: reviewed.length,
          toReview: queue.length,
          liveDelivered: pastSessions,
          liveUpcoming: live.length - delivered.length,
          attendance: pastSessions ? Math.round(rng.between(58, 84)) : null,
          enrollmentsByMonth,
        },
        activity,
      };
    }, 560),

  create: (input) =>
    respond(() => {
      assertValid(input);
      const base = slug(input.name) || 'instructor';
      const id = instructors.some((i) => i.id === base) ? `${base}-${Date.now().toString(36).slice(-4)}` : base;
      const { courseIds, ...fields } = input;
      const instructor: Instructor = { ...fields, id, name: input.name.trim(), email: input.email.trim().toLowerCase(), joinedAt: mockNowIso() };
      instructors.push(instructor);
      assignCourses(id, courseIds);
      invalidateAnalytics();
      return instructor;
    }, 850),

  update: (id, input) =>
    respond(() => {
      const current = find(id);
      assertValid(input, id);
      assignCourses(id, input.courseIds);
      const fields: Partial<InstructorInput> = { ...input };
      delete fields.courseIds;
      Object.assign(current, { ...fields, name: input.name.trim(), email: input.email.trim().toLowerCase() });
      invalidateAnalytics();
      return current;
    }, 800),

  setStatus: (id, status) =>
    respond(() => {
      const instructor = find(id);
      if (status === 'inactive') {
        const sole = teaching(id).filter((c) => c.status === 'published' && c.instructorIds.length === 1);
        if (sole.length)
          throw new ServiceError(
            `${instructor.name} is the only instructor on ${sole.map((c) => c.title).join(' and ')}. Assign another instructor first.`,
            'conflict',
          );
      }
      instructor.status = status;
      invalidateAnalytics();
      return instructor;
    }, 650),

  resendInvite: (id) =>
    respond(() => {
      const instructor = find(id);
      if (instructor.status !== 'invited') throw new ServiceError(`${instructor.name} has already accepted their invitation.`, 'conflict');
      return { sentTo: instructor.email };
    }, 700),
  // The demo has no self-registrations; the HTTP service reads the academy's own (D34).
  requests: () => respond(() => []),
  approveRequest: () =>
    respond(() => {
      throw new ServiceError('Instructor request not found.', 'not-found');
    }),
  rejectRequest: () =>
    respond(() => {
      throw new ServiceError('Instructor request not found.', 'not-found');
    }),
};
