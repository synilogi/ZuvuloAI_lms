import type { ActivityDay, AttentionItem, CoursePerformance, DashboardScope, DashboardSnapshot, Enrollment, Kpi, TrendPoint } from '@syniastrolms/domain';
import { completionRate, deriveLiveClassPhase, deriveStudentStatus, needsReview, reviewOverdue } from '@syniastrolms/domain';
import { addDays, createRandom, DAY_MS, dayKey, hashSeed, toIST } from './random';
import { courseAssignments, submissions } from './fixtures/assignments';
import { courses, instructors } from './fixtures/catalog';
import { DEMO_NOW } from './fixtures/learner';
import { enrollments, students } from './fixtures/people';
import { academyEvents, academyLiveClasses } from './fixtures/schedule';

const NOW = new Date(DEMO_NOW);
const NOW_MS = NOW.getTime();

/** Parsed timestamps, computed once — the dashboard aggregates thousands of enrollments. */
const ms = (() => {
  const cache = new Map<string, number>();
  return (iso: string | undefined) => {
    if (!iso) return NaN;
    let v = cache.get(iso);
    if (v === undefined) {
      v = new Date(iso).getTime();
      cache.set(iso, v);
    }
    return v;
  };
})();

/** Submissions waiting per course, and how many of them are past the 48-hour review window. */
export function reviewQueue(): Record<string, { waiting: number; overdue: number }> {
  const courseOf = new Map(courseAssignments.map((a) => [a.id, a.courseId]));
  const queue: Record<string, { waiting: number; overdue: number }> = {};
  for (const s of submissions()) {
    if (!needsReview(s)) continue;
    const courseId = courseOf.get(s.assignmentId)!;
    queue[courseId] ??= { waiting: 0, overdue: 0 };
    queue[courseId].waiting += 1;
    if (reviewOverdue(s, NOW)) queue[courseId].overdue += 1;
  }
  return queue;
}

const monthEnds = (count: number) => Array.from({ length: count }, (_, i) => addDays(NOW, -30 * (count - 1 - i)));
const within = (iso: string | undefined, from: Date, to: Date) => {
  const v = ms(iso);
  return v > from.getTime() && v <= to.getTime();
};

function kpiFrom(at: (t: Date) => number, unit: Kpi['unit'] = 'count'): Kpi {
  const series = monthEnds(8).map(at);
  return { value: series[series.length - 1], previous: series[series.length - 2], series, unit };
}

/** Completion among enrollments that started at least 60 days before `t` — younger ones haven't had a fair chance. */
function completionAt(list: Enrollment[], t: Date) {
  const cutoff = addDays(t, -60);
  const eligible = list.filter((e) => ms(e.enrolledAt) <= cutoff.getTime() && e.status !== 'paused');
  if (eligible.length === 0) return 0;
  const done = eligible.filter((e) => ms(e.completedAt) <= t.getTime()).length;
  return Math.round((done / eligible.length) * 1000) / 10;
}

function weekly(list: (string | undefined)[], weeks: number): TrendPoint[] {
  return Array.from({ length: weeks }, (_, i) => {
    const end = addDays(NOW, -7 * (weeks - 1 - i));
    const start = addDays(end, -7);
    return { date: dayKey(addDays(start, 1)), value: list.filter((iso) => within(iso, start, end)).length };
  });
}

const WEEKDAY_FACTOR = [1.16, 0.93, 0.96, 1, 0.97, 0.84, 1.1]; // Sun … Sat — learners study more at weekends

function activityDays(scopeKey: string, weeklyActive: number): ActivityDay[] {
  return Array.from({ length: 28 }, (_, i) => {
    const day = addDays(NOW, -(27 - i));
    const rng = createRandom(hashSeed(`${scopeKey}-${dayKey(day)}`));
    const weekday = new Date(toIST(day).slice(0, 10)).getUTCDay();
    const growth = Math.pow(0.992, 27 - i);
    const partial = i === 27 ? 0.78 : 1; // today is not over yet
    const active = Math.round(weeklyActive * 0.43 * WEEKDAY_FACTOR[weekday] * growth * rng.between(0.93, 1.07) * partial);
    return { date: dayKey(day), activeLearners: active, lessonsCompleted: Math.round(active * rng.between(1.35, 1.85)) };
  });
}

function sumKpi(days: ActivityDay[], pick: (d: ActivityDay) => number, factor: number): Kpi {
  const week = (offset: number) => Math.round(days.slice(days.length - 7 - offset, days.length - offset).reduce((n, d) => n + pick(d), 0) * factor);
  return { value: week(0), previous: week(7), series: [week(21), week(14), week(7), week(0)], unit: 'count' };
}

const snapshots = new Map<string, DashboardSnapshot>();

/** Drops cached snapshots — call after a mock mutation changes courses or enrollments. */
export function invalidateAnalytics() {
  snapshots.clear();
}

export function buildDashboard(scope: DashboardScope, empty = false): DashboardSnapshot {
  const key = `${scope.kind === 'academy' ? 'academy' : scope.instructorId}:${empty}`;
  const cached = snapshots.get(key);
  if (cached) return cached;
  const snapshot = computeDashboard(scope, empty);
  snapshots.set(key, snapshot);
  return snapshot;
}

function computeDashboard(scope: DashboardScope, empty: boolean): DashboardSnapshot {
  const scopedCourses = empty ? [] : scope.kind === 'academy' ? courses : courses.filter((c) => c.instructorIds.includes(scope.instructorId));
  const ids = new Set(scopedCourses.map((c) => c.id));
  const scoped = enrollments.filter((e) => ids.has(e.courseId));
  const learnerIds = new Set(scoped.map((e) => e.studentId));
  const firstEnrollment = new Map<string, number>();
  for (const e of scoped) firstEnrollment.set(e.studentId, Math.min(firstEnrollment.get(e.studentId) ?? Infinity, ms(e.enrolledAt)));

  const liveAt = (t: Date) =>
    scopedCourses.filter((c) => c.publishedAt && new Date(c.publishedAt) <= t && (c.status !== 'archived' || new Date(c.updatedAt) > t)).length;
  const learnersAt = (t: Date) =>
    scope.kind === 'academy'
      ? empty
        ? 0
        : students.filter((s) => ms(s.joinedAt) <= t.getTime()).length
      : [...firstEnrollment.values()].filter((v) => v <= t.getTime()).length;

  const reviews = Object.entries(reviewQueue()).filter(([courseId]) => ids.has(courseId));
  const waiting = reviews.reduce((n, [, q]) => n + q.waiting, 0);

  const third: Kpi =
    scope.kind === 'academy'
      ? kpiFrom((t) =>
          empty ? 0 : instructors.filter((i) => i.status !== 'invited' && new Date(i.joinedAt) <= t && (i.status === 'active' || t < addDays(NOW, -80))).length,
        )
      : { value: waiting, previous: Math.round(waiting * 0.64), series: [6, 8, 11, 7, 9, 12, Math.round(waiting * 0.64), waiting], unit: 'count' };

  const weeklyActive = scoped.filter((e) => e.status === 'active' && within(e.lastActiveAt, addDays(NOW, -7), NOW)).length;
  const activity = activityDays(scope.kind === 'academy' ? 'academy' : scope.instructorId, weeklyActive);

  const coursesPerf: CoursePerformance[] = scopedCourses
    .filter((c) => c.status === 'published')
    .map((c) => {
      const list = scoped.filter((e) => e.courseId === c.id);
      const inFlight = list.filter((e) => e.status === 'active' || e.status === 'completed');
      return {
        courseId: c.id,
        enrolled: list.length,
        active: list.filter((e) => e.status === 'active' && within(e.lastActiveAt, addDays(NOW, -14), NOW)).length,
        completionRate: completionRate(list),
        avgProgress: inFlight.length ? Math.round(inFlight.reduce((n, e) => n + e.progress, 0) / inFlight.length) : 0,
        rating: c.rating,
        weeklyEnrollments: weekly(
          list.map((e) => e.enrolledAt),
          8,
        ).map((p) => p.value),
      };
    })
    .sort((a, b) => b.enrolled - a.enrolled);

  const upcomingLive = academyLiveClasses
    .filter((c) => ids.has(c.courseId))
    .filter((c) => {
      const phase = deriveLiveClassPhase(c, NOW);
      return (phase === 'live' || phase === 'starting-soon' || phase === 'upcoming') && new Date(c.startsAt) < addDays(NOW, 8);
    })
    .sort((a, b) => a.startsAt.localeCompare(b.startsAt));

  const byStudent = new Map<string, Enrollment[]>();
  for (const e of scoped) byStudent.set(e.studentId, [...(byStudent.get(e.studentId) ?? []), e]);
  const atRisk = students.filter((s) => learnerIds.has(s.id) && deriveStudentStatus(s, byStudent.get(s.id) ?? [], NOW) === 'at-risk').length;

  const attention: AttentionItem[] = [];
  if (empty) {
    // A new academy has nothing to triage.
  } else {
    const overdue = reviews.reduce((n, [, q]) => n + q.overdue, 0);
    const worst = [...reviews].sort((a, b) => b[1].overdue - a[1].overdue)[0];
    if (overdue > 0 && worst) {
      attention.push({
        id: 'reviews',
        kind: 'reviews',
        title: `${overdue} submissions past the 48-hour review window`,
        detail: `${courses.find((c) => c.id === worst[0])?.title} has ${worst[1].overdue} of them · ${waiting} waiting in total`,
        count: overdue,
        severity: 'high',
        to: scope.kind === 'academy' ? '/admin/assignments/review' : '/teach/assignments/review',
      });
    }
    if (atRisk > 0) {
      attention.push({
        id: 'at-risk',
        kind: 'at-risk',
        title: `${atRisk.toLocaleString('en-IN')} learners at risk of dropping out`,
        detail: 'Quiet for 10 days or more with a course in progress',
        count: atRisk,
        severity: 'medium',
        to: scope.kind === 'academy' ? '/admin/students?status=at-risk' : '/teach/students?status=at-risk',
      });
    }
    const nearlyFull = upcomingLive.find((c) => c.capacity && c.registered && c.registered / c.capacity >= 0.9);
    if (nearlyFull) {
      attention.push({
        id: 'capacity',
        kind: 'capacity',
        title: `${nearlyFull.title} is ${Math.round((nearlyFull.registered! / nearlyFull.capacity!) * 100)}% full`,
        detail: `${nearlyFull.capacity! - nearlyFull.registered!} seats left · consider raising capacity or adding a repeat`,
        severity: 'medium',
        to: `${scope.kind === 'academy' ? '/admin' : '/teach'}/live/${nearlyFull.id}`,
      });
    }
    const stale = scopedCourses.find((c) => c.status === 'draft' && NOW_MS - ms(c.updatedAt) > 40 * DAY_MS);
    if (stale) {
      const weeks = Math.floor((NOW_MS - ms(stale.updatedAt)) / (7 * DAY_MS));
      attention.push({
        id: 'stale-draft',
        kind: 'stale-draft',
        title: `${stale.title} hasn’t been edited in ${weeks} weeks`,
        detail: `Draft · ${stale.outcomes.length ? `${stale.outcomes.length} of 3 outcomes` : 'no outcomes yet'} · ${stale.chapters.length} ${stale.chapters.length === 1 ? 'chapter' : 'chapters'}`,
        severity: 'low',
        to: `/admin/courses/${stale.id}`,
      });
    }
    if (ids.has('gochara')) {
      attention.push({
        id: 'captions',
        kind: 'accessibility',
        title: '9 videos in Transits and Gochara have no captions',
        detail: 'Learners who study with sound off can’t follow them',
        count: 9,
        severity: 'low',
        to: '/admin/courses/gochara/lessons',
      });
    }
  }

  return {
    scope,
    generatedAt: DEMO_NOW,
    kpis: {
      courses: kpiFrom(liveAt),
      students: kpiFrom(learnersAt),
      third,
      completionRate: kpiFrom((t) => completionAt(scoped, t), '%'),
    },
    enrollments: weekly(
      scoped.map((e) => e.enrolledAt),
      12,
    ),
    completions: weekly(
      scoped.map((e) => e.completedAt),
      12,
    ),
    courses: coursesPerf,
    activity: empty ? activity.map((d) => ({ ...d, activeLearners: 0, lessonsCompleted: 0 })) : activity,
    engagement: {
      lessonsCompleted: sumKpi(activity, (d) => d.lessonsCompleted, empty ? 0 : 1),
      quizAttempts: sumKpi(activity, (d) => d.activeLearners, empty ? 0 : 0.31),
      submissions: sumKpi(activity, (d) => d.activeLearners, empty ? 0 : 0.12),
      liveAttendance: sumKpi(activity, (d) => d.activeLearners, empty ? 0 : 0.22),
    },
    upcomingLive,
    attention,
    events: empty ? [] : academyEvents.filter((e) => scope.kind === 'academy' || (e.courseId && ids.has(e.courseId))),
  };
}
