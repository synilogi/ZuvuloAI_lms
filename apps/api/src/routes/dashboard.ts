import { Router } from 'express';
import {
  deriveLiveClassPhase,
  REVIEW_WINDOW_HOURS,
  type ActivityDay,
  type AdminEvent,
  type AttentionItem,
  type CoursePerformance,
  type DashboardScope,
  type Kpi,
  type TrendPoint,
} from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { asyncHandler } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requireStaffPermission } from '../lib/permissions.js';
import { instructorScope } from '../lib/scope.js';
import { optionalEnum, optionalId, parseQuery, z } from '../lib/validate.js';
import { getSettings } from '../lib/settings.js';
import { mapLive } from '../lib/mapLive.js';
import { readJson } from '../lib/json.js';
import { completionAt, DAY, spanOf, statusAt, type Span } from '../lib/reports.js';
import { STAFF_ONLY } from '../lib/instructorRequests.js';

export const dashboardRouter = Router();

/*
 * The staff landing screen. Every figure is read from records, and each KPI carries what it read a
 * month earlier so the screen can show a real change. Counts that describe a state — courses live,
 * learners reached, reviews waiting — are rebuilt at each past moment from the timestamps that made
 * them true, rather than compared against themselves.
 */

/** Eight month-ends, oldest → now: the moments a state figure is read at. */
const monthEnds = (now: Date, count = 8) => Array.from({ length: count }, (_, i) => new Date(now.getTime() - 30 * DAY * (count - 1 - i)));

/** A KPI from a function that can answer "what did this read at moment t?". */
function kpiAt(now: Date, at: (t: Date) => number, unit: Kpi['unit'] = 'count'): Kpi {
  const series = monthEnds(now).map(at);
  return { value: series[series.length - 1], previous: series[series.length - 2], series, unit };
}

/** Twelve weekly buckets ending now, oldest → newest. */
function weekly(moments: number[], now: Date, weeks = 12): TrendPoint[] {
  return Array.from({ length: weeks }, (_, i) => {
    const end = now.getTime() - 7 * DAY * (weeks - 1 - i);
    const start = end - 7 * DAY;
    return { date: new Date(start + DAY).toISOString().slice(0, 10), value: moments.filter((m) => m > start && m <= end).length };
  });
}

/** A weekly count: this week, the week before, and four weeks of history. */
function weekKpi(moments: number[], now: Date): Kpi {
  const week = (offset: number) => {
    const end = now.getTime() - offset * 7 * DAY;
    const start = end - 7 * DAY;
    return moments.filter((m) => m > start && m <= end).length;
  };
  return { value: week(0), previous: week(1), series: [week(3), week(2), week(1), week(0)], unit: 'count' };
}

const plural = (n: number, one: string, many = `${one}s`) => `${n} ${n === 1 ? one : many}`;

dashboardRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('reports.view'),
  asyncHandler(async (req, res) => {
    const { scope: scopeKind, instructorId } = parseQuery(req, z.object({ scope: optionalEnum(['academy', 'instructor'] as const), instructorId: optionalId }));
    // An instructor's dashboard is always their own; an admin may look at the academy or any instructor.
    const own = instructorScope(req);
    const scope: DashboardScope = own
      ? { kind: 'instructor', instructorId: own }
      : scopeKind === 'instructor' && instructorId
        ? { kind: 'instructor', instructorId }
        : { kind: 'academy' };
    const base = scope.kind === 'instructor' ? '/teach' : '/admin';
    const courseWhere = scope.kind === 'instructor' ? { instructors: { some: { instructorId: scope.instructorId } } } : {};
    const now = new Date();
    const nowMs = now.getTime();

    const courses = await db.course.findMany({ where: courseWhere, include: { chapters: { select: { id: true } } } });
    const courseIds = courses.map((c) => c.id);
    const titleOf = new Map(courses.map((c) => [c.id, c.title]));

    const enrollmentRows = await db.enrollment.findMany({
      where: { courseId: { in: courseIds } },
      select: {
        id: true,
        studentId: true,
        courseId: true,
        status: true,
        source: true,
        progress: true,
        enrolledAt: true,
        lastActiveAt: true,
        completedAt: true,
      },
    });
    const spans: Span[] = enrollmentRows.map(spanOf);
    const byCourse = new Map<string, Span[]>();
    for (const s of spans) byCourse.set(s.courseId, [...(byCourse.get(s.courseId) ?? []), s]);

    /* ─── Headline figures, each read again a month back ─── */

    // A course counts as live once it was published, until it was archived.
    const liveAt = (t: Date) => courses.filter((c) => c.publishedAt && c.publishedAt <= t && (c.status !== 'archived' || c.updatedAt > t)).length;

    const firstEnrollment = new Map<string, number>();
    for (const s of spans) firstEnrollment.set(s.studentId, Math.min(firstEnrollment.get(s.studentId) ?? Infinity, s.start));
    const allStudents = scope.kind === 'academy' ? await db.student.findMany({ select: { joinedAt: true } }) : [];
    const learnersAt = (t: Date) =>
      scope.kind === 'academy' ? allStudents.filter((s) => s.joinedAt <= t).length : [...firstEnrollment.values()].filter((v) => v <= t.getTime()).length;

    const submissions = await db.submission.findMany({
      where: { assignment: { courseId: { in: courseIds } } },
      include: { assignment: { select: { courseId: true, title: true } }, student: { select: { user: { select: { name: true } } } } },
    });
    // A submission was waiting at t if it had been handed in and had not yet been answered.
    const waitingAt = (t: Date) => submissions.filter((s) => s.submittedAt <= t && (!s.reviewUpdatedAt || s.reviewUpdatedAt > t)).length;

    const staff = scope.kind === 'academy' ? await db.instructor.findMany({ where: STAFF_ONLY, select: { joinedAt: true, status: true } }) : [];
    const instructorsAt = (t: Date) => staff.filter((i) => i.status !== 'invited' && i.joinedAt <= t).length;

    /* ─── Daily learning activity, from lesson progress ─── */

    const lessonProgress = await db.lessonProgress.findMany({
      where: { lesson: { courseId: { in: courseIds } } },
      select: { studentId: true, state: true, completedAt: true, lastAccessedAt: true },
    });
    const midnight = new Date(now).setHours(0, 0, 0, 0);
    const activity: ActivityDay[] = Array.from({ length: 28 }, (_, i) => {
      const dayStart = midnight - (27 - i) * DAY;
      const dayEnd = dayStart + DAY;
      const touched = lessonProgress.filter((p) => {
        const seen = p.completedAt?.getTime() ?? p.lastAccessedAt?.getTime();
        return seen !== undefined && seen >= dayStart && seen < dayEnd;
      });
      return {
        date: new Date(dayStart).toISOString().slice(0, 10),
        activeLearners: new Set(touched.map((p) => p.studentId)).size,
        lessonsCompleted: touched.filter(
          (p) => p.state === 'completed' && p.completedAt && p.completedAt.getTime() >= dayStart && p.completedAt.getTime() < dayEnd,
        ).length,
      };
    });

    /* ─── Live classes ─── */

    const liveRows = await db.liveClass.findMany({
      where: { courseId: { in: courseIds } },
      include: { registrations: { select: { attended: true, registeredAt: true } }, instructor: { select: { name: true } } },
    });
    const liveClasses = liveRows.map((row) => ({ row, live: mapLive(row) }));
    const upcomingLive = liveClasses
      .filter(({ live }) => {
        const phase = deriveLiveClassPhase(live, now);
        return (phase === 'live' || phase === 'starting-soon' || phase === 'upcoming') && new Date(live.startsAt).getTime() < nowMs + 8 * DAY;
      })
      .sort((a, b) => a.live.startsAt.localeCompare(b.live.startsAt))
      .map(({ live }) => live);

    // Attendance is counted when a class that someone was marked present at has finished.
    const attendances: number[] = [];
    for (const { row } of liveClasses) {
      const ended = row.startsAt.getTime() + row.durationMin * 60_000;
      if (ended >= nowMs || row.cancelled) continue;
      for (const reg of row.registrations) if (reg.attended === true) attendances.push(ended);
    }

    /* ─── Course performance ─── */

    const coursePerf: CoursePerformance[] = courses
      .filter((c) => c.status === 'published')
      .map((c) => {
        const list = byCourse.get(c.id) ?? [];
        const inFlight = list.filter((s) => s.status === 'active' || s.status === 'completed');
        return {
          courseId: c.id,
          enrolled: list.length,
          active: list.filter((s) => s.status === 'active' && s.end > nowMs - 14 * DAY).length,
          completionRate: completionAt(list, nowMs),
          avgProgress: inFlight.length ? Math.round(inFlight.reduce((n, s) => n + s.progress, 0) / inFlight.length) : 0,
          rating: c.rating ?? undefined,
          weeklyEnrollments: weekly(
            list.map((s) => s.start),
            now,
            8,
          ).map((p) => p.value),
        };
      })
      .sort((a, b) => b.enrolled - a.enrolled);

    /* ─── Needs attention ─── */

    const { atRiskDays } = (await getSettings()).learning;
    const overdueMs = REVIEW_WINDOW_HOURS * 3_600_000;
    const waiting = submissions.filter((s) => s.reviewStatus === 'waiting' || s.reviewStatus === 'in-review');
    const overdue = waiting.filter((s) => nowMs - s.submittedAt.getTime() > overdueMs);
    const overdueByCourse = new Map<string, number>();
    for (const s of overdue) overdueByCourse.set(s.assignment.courseId, (overdueByCourse.get(s.assignment.courseId) ?? 0) + 1);
    const worst = [...overdueByCourse.entries()].sort((a, b) => b[1] - a[1])[0];

    const learnerIds = [...new Set(spans.map((s) => s.studentId))];
    const learners = await db.student.findMany({ where: { id: { in: learnerIds } }, select: { id: true, suspended: true, lastActiveAt: true } });
    const openWork = new Set(spans.filter((s) => s.status === 'active').map((s) => s.studentId));
    const atRisk = learners.filter((s) => !s.suspended && statusAt(s.lastActiveAt.getTime(), openWork.has(s.id), nowMs, atRiskDays) === 'at-risk').length;

    const attention: AttentionItem[] = [];
    if (overdue.length && worst) {
      attention.push({
        id: 'reviews',
        kind: 'reviews',
        title: `${plural(overdue.length, 'submission')} past the ${REVIEW_WINDOW_HOURS}-hour review window`,
        detail: `${titleOf.get(worst[0]) ?? 'A course'} has ${worst[1]} of them · ${waiting.length} waiting in total`,
        count: overdue.length,
        severity: 'high',
        to: `${base}/assignments/review`,
      });
    }
    if (atRisk > 0) {
      attention.push({
        id: 'at-risk',
        kind: 'at-risk',
        title: `${atRisk.toLocaleString('en-IN')} learners at risk of dropping out`,
        detail: `Quiet for ${atRiskDays} days or more with a course in progress`,
        count: atRisk,
        severity: 'medium',
        to: `${base}/students?status=at-risk`,
      });
    }
    const nearlyFull = upcomingLive.find((c) => c.capacity && c.registered && c.registered / c.capacity >= 0.9);
    if (nearlyFull) {
      attention.push({
        id: 'capacity',
        kind: 'capacity',
        title: `${nearlyFull.title} is ${Math.round((nearlyFull.registered! / nearlyFull.capacity!) * 100)}% full`,
        detail: `${plural(nearlyFull.capacity! - nearlyFull.registered!, 'seat')} left · consider raising capacity or adding a repeat`,
        severity: 'medium',
        to: `${base}/live/${nearlyFull.id}`,
      });
    }
    const stale = courses
      .filter((c) => c.status === 'draft' && nowMs - c.updatedAt.getTime() > 42 * DAY)
      .sort((a, b) => a.updatedAt.getTime() - b.updatedAt.getTime())[0];
    if (stale) {
      const weeks = Math.floor((nowMs - stale.updatedAt.getTime()) / (7 * DAY));
      const outcomes = readJson<string[]>(stale.outcomesJson, []);
      attention.push({
        id: 'stale-draft',
        kind: 'stale-draft',
        title: `${stale.title} hasn’t been edited in ${weeks} weeks`,
        detail: `Draft · ${outcomes.length ? `${outcomes.length} of 3 outcomes` : 'no outcomes yet'} · ${plural(stale.chapters.length, 'chapter')}`,
        severity: 'low',
        to: `${base}/courses/${stale.id}`,
      });
    }
    // Learners who study with the sound off cannot follow a video that has no captions.
    const videoLessons = await db.lesson.findMany({
      where: { courseId: { in: courseIds }, type: 'video', status: 'published' },
      select: { courseId: true, contentJson: true },
    });
    const uncaptioned = new Map<string, number>();
    for (const lesson of videoLessons) {
      const content = readJson<{ video?: { captions?: boolean } }>(lesson.contentJson, {});
      if (content.video && content.video.captions !== true) uncaptioned.set(lesson.courseId, (uncaptioned.get(lesson.courseId) ?? 0) + 1);
    }
    const worstCaptions = [...uncaptioned.entries()].sort((a, b) => b[1] - a[1])[0];
    if (worstCaptions) {
      attention.push({
        id: 'captions',
        kind: 'accessibility',
        title: `${plural(worstCaptions[1], 'video')} in ${titleOf.get(worstCaptions[0]) ?? 'a course'} have no captions`,
        detail: 'Learners who study with sound off can’t follow them',
        count: worstCaptions[1],
        severity: 'low',
        to: `${base}/courses/${worstCaptions[0]}/lessons`,
      });
    }

    /* ─── What has been happening ─── */

    const events: AdminEvent[] = [];
    const push = (e: AdminEvent) => events.push(e);

    const recentEnrollments = await db.enrollment.findMany({
      where: { courseId: { in: courseIds } },
      orderBy: { enrolledAt: 'desc' },
      take: 8,
      select: { id: true, courseId: true, source: true, enrolledAt: true, student: { select: { user: { select: { name: true } } } } },
    });
    const SOURCE_LABEL: Record<string, string> = {
      self: 'Self-enrolled',
      admin: 'Added by an admin',
      cohort: 'Cohort intake',
      scholarship: 'Scholarship place',
    };
    for (const e of recentEnrollments) {
      push({
        id: `enr-${e.id}`,
        kind: 'enrollment',
        actor: e.student.user.name,
        summary: `enrolled in ${titleOf.get(e.courseId) ?? 'a course'}`,
        context: SOURCE_LABEL[e.source] ?? undefined,
        courseId: e.courseId,
        at: e.enrolledAt.toISOString(),
        to: `${base}/courses/${e.courseId}`,
      });
    }

    const published = await db.course.findMany({
      where: { ...courseWhere, status: 'published', publishedAt: { not: null } },
      orderBy: { publishedAt: 'desc' },
      take: 4,
      include: { instructors: { include: { instructor: { select: { name: true } } } } },
    });
    for (const c of published) {
      push({
        id: `pub-${c.id}`,
        kind: 'course-published',
        actor: c.instructors[0]?.instructor.name ?? 'ZuviloAI',
        summary: `published ${c.title}`,
        courseId: c.id,
        at: c.publishedAt!.toISOString(),
        to: `${base}/courses/${c.id}`,
      });
    }

    for (const s of [...submissions].sort((a, b) => b.submittedAt.getTime() - a.submittedAt.getTime()).slice(0, 6)) {
      push({
        id: `sub-${s.id}`,
        kind: 'submission',
        actor: s.student.user.name,
        summary: `handed in ${s.assignment.title}`,
        context: s.late ? 'Late' : undefined,
        courseId: s.assignment.courseId,
        at: s.submittedAt.toISOString(),
        to: `${base}/assignments/${s.assignmentId}/submissions/${s.id}`,
      });
    }

    const reviewers = new Map((await db.instructor.findMany({ select: { id: true, name: true } })).map((i) => [i.id, i.name]));
    for (const s of submissions
      .filter((x) => x.reviewUpdatedAt && (x.reviewStatus === 'graded' || x.reviewStatus === 'returned'))
      .sort((a, b) => b.reviewUpdatedAt!.getTime() - a.reviewUpdatedAt!.getTime())
      .slice(0, 6)) {
      push({
        id: `rev-${s.id}`,
        kind: 'review',
        actor: (s.reviewerId && reviewers.get(s.reviewerId)) || 'An instructor',
        summary: `reviewed ${s.student.user.name}’s ${s.assignment.title}`,
        context: s.score != null ? `Scored ${s.score}` : undefined,
        courseId: s.assignment.courseId,
        at: s.reviewUpdatedAt!.toISOString(),
        to: `${base}/assignments/${s.assignmentId}/submissions/${s.id}`,
      });
    }

    const certificates = await db.issuedCertificate.findMany({
      where: { courseId: { in: courseIds }, issuedAt: { not: null } },
      orderBy: { issuedAt: 'desc' },
      take: 4,
      select: { id: true, courseId: true, issuedAt: true, student: { select: { user: { select: { name: true } } } } },
    });
    for (const c of certificates) {
      push({
        id: `cert-${c.id}`,
        kind: 'certificate',
        actor: c.student.user.name,
        summary: `earned a certificate in ${titleOf.get(c.courseId) ?? 'a course'}`,
        courseId: c.courseId,
        at: c.issuedAt!.toISOString(),
        to: scope.kind === 'academy' ? `/admin/certificates/${c.id}` : undefined,
      });
    }

    for (const { row, live } of liveClasses
      .filter(({ row }) => row.startsAt.getTime() > nowMs)
      .sort((a, b) => b.row.startsAt.getTime() - a.row.startsAt.getTime())
      .slice(0, 4)) {
      push({
        id: `live-${row.id}`,
        kind: 'live-scheduled',
        actor: row.instructor.name,
        summary: `scheduled ${row.title}`,
        context: live.registered ? `${plural(live.registered, 'learner')} registered` : undefined,
        courseId: row.courseId,
        // The class itself is in the future; the entry records that it was put in the diary.
        at: new Date(Math.min(nowMs, row.startsAt.getTime())).toISOString(),
        to: `${base}/live/${row.id}`,
      });
    }

    if (scope.kind === 'academy') {
      const joined = await db.instructor.findMany({
        where: { status: { notIn: ['invited', 'pending', 'rejected'] } },
        orderBy: { joinedAt: 'desc' },
        take: 3,
        select: { id: true, name: true, title: true, joinedAt: true },
      });
      for (const i of joined) {
        push({
          id: `ins-${i.id}`,
          kind: 'instructor',
          actor: i.name,
          summary: `joined the platform as ${i.title}`,
          at: i.joinedAt.toISOString(),
          to: `/admin/instructors/${i.id}`,
        });
      }
    }

    events.sort((a, b) => b.at.localeCompare(a.at));

    /* ─── Engagement, counted over the last seven days ─── */

    const quizAttempts = await db.quizAttempt.findMany({ where: { quiz: { courseId: { in: courseIds } } }, select: { createdAt: true } });
    const lessonCompletions = lessonProgress.filter((p) => p.state === 'completed' && p.completedAt).map((p) => p.completedAt!.getTime());

    res.json({
      scope,
      generatedAt: now.toISOString(),
      kpis: {
        courses: kpiAt(now, liveAt),
        students: kpiAt(now, learnersAt),
        third: scope.kind === 'academy' ? kpiAt(now, instructorsAt) : kpiAt(now, waitingAt),
        completionRate: kpiAt(now, (t) => completionAt(spans, t.getTime()), '%'),
      },
      enrollments: weekly(
        spans.map((s) => s.start),
        now,
      ),
      completions: weekly(
        spans.filter((s) => s.done).map((s) => s.done),
        now,
      ),
      courses: coursePerf,
      activity,
      engagement: {
        lessonsCompleted: weekKpi(lessonCompletions, now),
        quizAttempts: weekKpi(
          quizAttempts.map((a) => a.createdAt.getTime()),
          now,
        ),
        submissions: weekKpi(
          submissions.map((s) => s.submittedAt.getTime()),
          now,
        ),
        liveAttendance: weekKpi(attendances, now),
      },
      upcomingLive,
      attention,
      events: events.slice(0, 12),
    });
  }),
);
