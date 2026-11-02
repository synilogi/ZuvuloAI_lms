import type { Course, Enrollment, Kpi, LearnerSegment, Quiz, ReportFilters, ReportWindow, StudentStatus, Submission } from '@syniastrolms/domain';
import {
  AT_RISK_AFTER_DAYS,
  completionRate,
  courseLessons,
  INACTIVE_AFTER_DAYS,
  LEARNER_SEGMENTS,
  median,
  percentOf,
  reportBuckets,
  reportWindow,
} from '@syniastrolms/domain';
import type {
  CourseReport,
  CourseReportRow,
  EnrolmentReport,
  InstructorReport,
  InstructorReportRow,
  LearnerReport,
  LearnerReportRow,
  QuizStats,
  ReportContext,
  ReportOverview,
  ReportSeries,
  ReportsService,
} from '../contracts';
import { ServiceError } from '../contracts';
import { courseAssignments, submissions } from './fixtures/assignments';
import { categories, courses, instructors } from './fixtures/catalog';
import { DEMO_NOW } from './fixtures/learner';
import { liveSchedule } from './fixtures/live';
import { enrollments, students } from './fixtures/people';
import { quizzes } from './fixtures/quizzes';
import { statsFor } from './quizzes';
import { hashSeed } from './random';
import { setMockReviewStatus, staffMockReviews } from './reviews';
import { respond, scenario } from './simulation';

/*
 * Reports aggregate the same records every other screen reads. Each enrolment is treated as a
 * study span — from enrolling to finishing or last being seen — so any period can be measured
 * and compared with the one before it.
 */

const NOW = new Date(DEMO_NOW);
const DAY = 86_400_000;
const HOUR = 3_600_000;

const parsed = new Map<string, number>();
const ms = (iso: string | undefined) => {
  if (!iso) return NaN;
  let v = parsed.get(iso);
  if (v === undefined) {
    v = new Date(iso).getTime();
    parsed.set(iso, v);
  }
  return v;
};
const avg = (values: number[]) => (values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0);
const round1 = (n: number) => Math.round(n * 10) / 10;
const kpi = (value: number, previous: number, series: number[] = [], unit: Kpi['unit'] = 'count'): Kpi => ({ value, previous, series, unit });
/** Up to `count` evenly spaced items, always keeping the last. */
const sample = <T>(items: T[], count: number) =>
  items.length <= count ? items : Array.from({ length: count }, (_, i) => items[Math.round((i * (items.length - 1)) / (count - 1))]);

/* ─── Study spans ─── */

interface Span {
  e: Enrollment;
  start: number;
  end: number;
  done: number;
}

function spanOf(e: Enrollment): Span {
  const done = ms(e.completedAt);
  return { e, start: ms(e.enrolledAt), end: done || ms(e.lastActiveAt) || ms(e.enrolledAt) + 21 * DAY, done };
}

const activeIn = (s: Span, from: number, to: number) => s.start <= to && s.end > from;

function progressAt(s: Span, t: number) {
  if (t <= s.start) return 0;
  if (s.done && s.done <= t) return 100;
  const share = s.end <= s.start ? 1 : Math.min(1, (t - s.start) / (s.end - s.start));
  return Math.round(s.e.progress * share);
}

/** Finished, among enrolments at least 60 days old at that moment. */
function completionAt(spans: Span[], t: number) {
  let eligible = 0;
  let done = 0;
  for (const s of spans) {
    if (s.start > t - 60 * DAY || s.e.status === 'paused') continue;
    eligible += 1;
    if (s.done && s.done <= t) done += 1;
  }
  return eligible ? round1((done / eligible) * 100) : 0;
}

function activeLearners(spans: Span[], from: number, to: number) {
  const people = new Set<string>();
  for (const s of spans) if (activeIn(s, from, to)) people.add(s.e.studentId);
  return people.size;
}

function avgProgressAt(spans: Span[], from: number, to: number) {
  let sum = 0;
  let n = 0;
  for (const s of spans) {
    if (!activeIn(s, from, to)) continue;
    sum += progressAt(s, to);
    n += 1;
  }
  return n ? Math.round(sum / n) : 0;
}

const countIn = (values: number[], from: number, to: number) => values.reduce((n, v) => (v > from && v <= to ? n + 1 : n), 0);

/** A learner's status as it would have read at a moment. Activity after that moment counts as not quiet. */
function statusAt(lastSeen: number, open: boolean, t: number): StudentStatus {
  const quiet = (t - Math.min(lastSeen, t)) / DAY;
  if (quiet >= INACTIVE_AFTER_DAYS) return 'inactive';
  if (quiet >= AT_RISK_AFTER_DAYS) return open ? 'at-risk' : 'inactive';
  return 'active';
}

/* ─── Request context ─── */

const assignmentsById = new Map(courseAssignments.map((a) => [a.id, a]));
const maxScoreOf = (assignmentId: string) => {
  const a = assignmentsById.get(assignmentId);
  return a ? (a.rubric.length ? a.rubric.reduce((n, c) => n + c.points, 0) : a.maxScore) || 1 : 1;
};
const lessonCount = new Map(courses.map((c) => [c.id, courseLessons(c).length]));
const categoryOf = new Map(courses.map((c) => [c.id, c.categoryId]));

const statsCache = new Map<string, QuizStats>();
const quizStats = (quiz: Quiz) => {
  const key = `${quiz.id}:${quiz.updatedAt}:${quiz.status}:${quiz.questions.length}`;
  let s = statsCache.get(key);
  if (!s) {
    s = statsFor(quiz);
    statsCache.set(key, s);
  }
  return s;
};

interface Ctx {
  filters: ReportFilters;
  w: ReportWindow;
  from: number;
  to: number;
  pFrom: number;
  pTo: number;
  courses: Course[];
  ids: Set<string>;
  spans: Span[];
  byCourse: Map<string, Span[]>;
  /** Submissions in the selected courses. */
  subs: Submission[];
}

function contextFor(filters: ReportFilters): Ctx {
  const w = reportWindow(filters.range, NOW);
  const empty = scenario() === 'empty';
  const selected = empty
    ? []
    : courses.filter(
        (c) =>
          c.status !== 'draft' &&
          (!filters.courseId || c.id === filters.courseId) &&
          (!filters.categoryId || c.categoryId === filters.categoryId) &&
          (!filters.instructorId || c.instructorIds.includes(filters.instructorId)),
      );
  const ids = new Set(selected.map((c) => c.id));
  const spans = empty ? [] : enrollments.filter((e) => ids.has(e.courseId)).map(spanOf);
  const byCourse = new Map<string, Span[]>();
  for (const s of spans) {
    const list = byCourse.get(s.e.courseId);
    if (list) list.push(s);
    else byCourse.set(s.e.courseId, [s]);
  }
  const subs = empty ? [] : submissions().filter((s) => ids.has(assignmentsById.get(s.assignmentId)?.courseId ?? ''));
  return {
    filters,
    w,
    from: w.from.getTime(),
    to: w.to.getTime(),
    pFrom: w.previousFrom.getTime(),
    pTo: w.previousTo.getTime(),
    courses: selected,
    ids,
    spans,
    byCourse,
    subs,
  };
}

/** A narrower context for one course or one learner segment, sharing the period. */
function narrow(ctx: Ctx, spans: Span[], courseList = ctx.courses): Ctx {
  const ids = new Set(courseList.map((c) => c.id));
  const byCourse = new Map<string, Span[]>();
  for (const s of spans) {
    const list = byCourse.get(s.e.courseId);
    if (list) list.push(s);
    else byCourse.set(s.e.courseId, [s]);
  }
  return { ...ctx, courses: courseList, ids, spans, byCourse, subs: ctx.subs.filter((s) => ids.has(assignmentsById.get(s.assignmentId)?.courseId ?? '')) };
}

const reportContext = (ctx: Ctx): ReportContext => ({
  window: {
    from: ctx.w.from.toISOString(),
    to: ctx.w.to.toISOString(),
    previousFrom: ctx.w.previousFrom.toISOString(),
    previousTo: ctx.w.previousTo.toISOString(),
  },
  courseCount: ctx.courses.length,
});

function seriesFor(ctx: Ctx): ReportSeries {
  const buckets = reportBuckets(ctx.filters.range, NOW);
  const first = buckets[0].from.getTime();
  const size = buckets[0].to.getTime() - first;
  const enrolled = new Array(buckets.length).fill(0);
  const finished = new Array(buckets.length).fill(0);
  const index = (v: number) => (v > first && v <= ctx.to ? Math.min(buckets.length - 1, Math.ceil((v - first) / size) - 1) : -1);
  for (const s of ctx.spans) {
    const i = index(s.start);
    if (i >= 0) enrolled[i] += 1;
    const j = s.done ? index(s.done) : -1;
    if (j >= 0) finished[j] += 1;
  }
  const point = (values: number[]) =>
    buckets.map((b, i) => ({ from: b.from.toISOString(), to: b.to.toISOString(), value: values[i], partial: b.partial || undefined }));
  return {
    enrollments: point(enrolled),
    completions: point(finished),
    activeLearners: point(buckets.map((b) => activeLearners(ctx.spans, b.from.getTime(), b.to.getTime()))),
  };
}

/** Moments to sample a rate at for a sparkline. */
const sparkEnds = (ctx: Ctx) => sample(reportBuckets(ctx.filters.range, NOW), 10).map((b) => b.to.getTime());

/* ─── Assessments and engagement ─── */

/** A small, stable wobble so a rate reads differently from one period to the next. */
const wobble = (key: string, spread: number) => ((hashSeed(key) % 1000) / 1000 - 0.5) * 2 * spread;

function quizFigures(ctx: Ctx, from: number, to: number) {
  let attempts = 0;
  let passWeighted = 0;
  let scoreWeighted = 0;
  const rows: CourseReport['quizzes'] = [];
  const share = new Map<string, number>();
  for (const quiz of quizzes) {
    if (!ctx.ids.has(quiz.courseId) || quiz.status !== 'published') continue;
    const stats = quizStats(quiz);
    if (!share.has(quiz.courseId)) {
      const list = ctx.byCourse.get(quiz.courseId) ?? [];
      share.set(quiz.courseId, list.length ? list.filter((s) => activeIn(s, from, to)).length / list.length : 0);
    }
    const n = Math.round(stats.attempts * share.get(quiz.courseId)! * 0.6);
    const key = `${quiz.id}:${Math.round(to / DAY)}`;
    const passRate = Math.max(0, Math.min(100, Math.round(stats.passRate + wobble(`p${key}`, 3))));
    const avgScore = Math.max(0, Math.min(100, Math.round(stats.avgScore + wobble(`s${key}`, 2))));
    attempts += n;
    passWeighted += passRate * n;
    scoreWeighted += avgScore * n;
    rows.push({ quizId: quiz.id, title: quiz.title, attempts: n, passRate, avgScore });
  }
  return { attempts, passRate: attempts ? Math.round(passWeighted / attempts) : 0, avgScore: attempts ? Math.round(scoreWeighted / attempts) : 0, rows };
}

function assignmentFigures(subs: Submission[], from: number, to: number) {
  let submitted = 0;
  let onTime = 0;
  let graded = 0;
  let passed = 0;
  const hours: number[] = [];
  for (const s of subs) {
    const at = ms(s.submittedAt);
    if (at > from && at <= to) {
      submitted += 1;
      if (!s.late) onTime += 1;
      if (s.review.status === 'graded' && s.review.score !== undefined) {
        graded += 1;
        if (s.review.score >= (assignmentsById.get(s.assignmentId)?.passMark ?? 0)) passed += 1;
      }
    }
    const reviewed = ms(s.review.updatedAt);
    if (s.review.status === 'graded' && reviewed > from && reviewed <= to) hours.push((reviewed - at) / HOUR);
  }
  return { submitted, passRate: percentOf(passed, graded) ?? 0, onTime: percentOf(onTime, submitted) ?? 0, reviewHours: Math.round(median(hours) ?? 0) };
}

function liveAttendance(ctx: Ctx, from: number, to: number, instructorId?: string) {
  let classes = 0;
  let registered = 0;
  let attended = 0;
  for (const c of liveSchedule()) {
    const at = ms(c.startsAt);
    if (
      !ctx.ids.has(c.courseId) ||
      c.cancelled ||
      (instructorId && c.instructorId !== instructorId) ||
      at <= from ||
      at > to ||
      at + c.durationMin * 60_000 >= NOW.getTime()
    )
      continue;
    classes += 1;
    registered += c.registered ?? 0;
    attended += c.attended ?? 0;
  }
  return { classes, rate: percentOf(attended, registered) };
}

function lessonsCompleted(spans: Span[], from: number, to: number) {
  let total = 0;
  for (const s of spans) if (activeIn(s, from, to)) total += ((progressAt(s, to) - progressAt(s, from)) / 100) * (lessonCount.get(s.e.courseId) ?? 0);
  return Math.round(total);
}

const BANDS: { label: string; test: (p: number) => boolean }[] = [
  { label: '0–24%', test: (p) => p < 25 },
  { label: '25–49%', test: (p) => p >= 25 && p < 50 },
  { label: '50–74%', test: (p) => p >= 50 && p < 75 },
  { label: '75–99%', test: (p) => p >= 75 && p < 100 },
  { label: 'Finished', test: (p) => p >= 100 },
];
const progressBands = (values: number[]) => BANDS.map((b) => ({ label: b.label, value: values.filter(b.test).length }));

/* ─── Courses ─── */

function courseRow(ctx: Ctx, course: Course): CourseReportRow {
  const spans = ctx.byCourse.get(course.id) ?? [];
  const one = narrow(ctx, spans, [course]);
  const quiz = quizFigures(one, ctx.from, ctx.to);
  const asg = assignmentFigures(one.subs, ctx.from, ctx.to);
  const starts = spans.map((s) => s.start);
  return {
    courseId: course.id,
    title: course.title,
    categoryTitle: categories.find((c) => c.id === course.categoryId)?.name ?? '',
    instructorNames: course.instructorIds.map((id) => instructors.find((i) => i.id === id)?.name ?? '').filter(Boolean),
    status: course.status,
    enrollments: countIn(starts, ctx.from, ctx.to),
    previousEnrollments: countIn(starts, ctx.pFrom, ctx.pTo),
    completions: countIn(
      spans.map((s) => s.done),
      ctx.from,
      ctx.to,
    ),
    completionRate: Math.round(completionAt(spans, ctx.to)),
    activeLearners: activeLearners(spans, ctx.from, ctx.to),
    avgProgress: avgProgressAt(spans, ctx.from, ctx.to),
    quizPassRate: quiz.attempts ? quiz.passRate : null,
    assignmentPassRate: asg.submitted ? asg.passRate : null,
    rating: course.status === 'published' ? course.rating : undefined,
    trend: seriesFor(one).enrollments.map((p) => p.value),
  };
}

const courseRows = (ctx: Ctx) =>
  ctx.courses
    .filter((c) => ctx.byCourse.has(c.id))
    .map((c) => courseRow(ctx, c))
    .sort((a, b) => b.enrollments - a.enrollments);

/* ─── Learners ─── */

const studentsById = new Map(students.map((s) => [s.id, s]));

interface Person {
  id: string;
  spans: Span[];
  status: StudentStatus;
  segments: Set<LearnerSegment>;
}

function peopleIn(ctx: Ctx): Person[] {
  const byStudent = new Map<string, Span[]>();
  for (const s of ctx.spans) {
    const list = byStudent.get(s.e.studentId);
    if (list) list.push(s);
    else byStudent.set(s.e.studentId, [s]);
  }
  const people: Person[] = [];
  for (const [id, spans] of byStudent) {
    const student = studentsById.get(id);
    if (!student) continue;
    const first = Math.min(...spans.map((s) => s.start));
    if (!spans.some((s) => activeIn(s, ctx.from, ctx.to)) && first <= ctx.from) continue;
    const open = spans.some((s) => s.e.status === 'active');
    const status: StudentStatus = student.suspended ? 'suspended' : statusAt(ms(student.lastActiveAt), open, NOW.getTime());
    const segments = new Set<LearnerSegment>(['all']);
    if (first > ctx.from && first <= ctx.to) segments.add('new');
    if (status !== 'suspended') segments.add(status);
    if (spans.some((s) => s.done > ctx.from && s.done <= ctx.to)) segments.add('completers');
    people.push({ id, spans, status, segments });
  }
  return people;
}

function atRiskAt(people: { id: string; spans: Span[] }[], t: number) {
  let n = 0;
  for (const p of people) {
    const seen = ms(studentsById.get(p.id)?.lastActiveAt);
    const open = p.spans.some((s) => s.start <= t && !(s.done && s.done <= t) && s.e.status !== 'expired');
    if (statusAt(seen > t ? t : seen, open, t) === 'at-risk') n += 1;
  }
  return n;
}

function segmentSpans(ctx: Ctx, segment: LearnerSegment | undefined) {
  if (!segment || segment === 'all') return ctx.spans;
  const ids = new Set(
    peopleIn(ctx)
      .filter((p) => p.segments.has(segment))
      .map((p) => p.id),
  );
  return ctx.spans.filter((s) => ids.has(s.e.studentId));
}

/* ─── Service ─── */

export const reportsService: ReportsService = {
  courseSales: () => respond([]),
  reviews: (query) => respond(() => staffMockReviews(query)),
  hideReview: (id) => respond(() => setMockReviewStatus(id, 'hidden')),
  showReview: (id) => respond(() => setMockReviewStatus(id, 'published')),
  overview: (filters) =>
    respond((): ReportOverview => {
      const ctx = contextFor(filters);
      const { spans, from, to, pFrom, pTo } = ctx;
      const series = seriesFor(ctx);
      const ends = sparkEnds(ctx);
      const q = quizFigures(ctx, from, to);
      const qPrev = quizFigures(ctx, pFrom, pTo);
      const a = assignmentFigures(ctx.subs, from, to);
      const aPrev = assignmentFigures(ctx.subs, pFrom, pTo);
      const active = activeLearners(spans, from, to);
      const activePrev = activeLearners(spans, pFrom, pTo);
      const lessons = lessonsCompleted(spans, from, to);
      const lessonsPrev = lessonsCompleted(spans, pFrom, pTo);
      const live = liveAttendance(ctx, from, to);
      const livePrev = liveAttendance(ctx, pFrom, pTo);
      const starts = spans.map((s) => s.start);
      const dones = spans.map((s) => s.done);
      const byCategory = new Map<string, Span[]>();
      for (const s of spans) {
        const cat = categoryOf.get(s.e.courseId)!;
        const list = byCategory.get(cat);
        if (list) list.push(s);
        else byCategory.set(cat, [s]);
      }
      return {
        ...reportContext(ctx),
        kpis: {
          enrollments: kpi(
            countIn(starts, from, to),
            countIn(starts, pFrom, pTo),
            series.enrollments.map((p) => p.value),
          ),
          completions: kpi(
            countIn(dones, from, to),
            countIn(dones, pFrom, pTo),
            series.completions.map((p) => p.value),
          ),
          completionRate: kpi(
            completionAt(spans, to),
            completionAt(spans, pTo),
            ends.map((t) => completionAt(spans, t)),
            '%',
          ),
          activeLearners: kpi(
            active,
            activePrev,
            series.activeLearners.map((p) => p.value),
          ),
          avgProgress: kpi(
            avgProgressAt(spans, from, to),
            avgProgressAt(spans, pFrom, pTo),
            ends.map((t) => avgProgressAt(spans, t - 28 * DAY, t)),
            '%',
          ),
        },
        series,
        quizzes: {
          attempts: kpi(q.attempts, qPrev.attempts),
          passRate: kpi(q.passRate, qPrev.passRate, [], '%'),
          avgScore: kpi(q.avgScore, qPrev.avgScore, [], '%'),
        },
        assignments: {
          submitted: kpi(a.submitted, aPrev.submitted),
          passRate: kpi(a.passRate, aPrev.passRate, [], '%'),
          onTime: kpi(a.onTime, aPrev.onTime, [], '%'),
          reviewHours: kpi(a.reviewHours, aPrev.reviewHours),
        },
        engagement: {
          lessonsCompleted: kpi(lessons, lessonsPrev),
          lessonsPerLearner: kpi(round1(active ? lessons / active : 0), round1(activePrev ? lessonsPrev / activePrev : 0)),
          liveAttendance: kpi(live.rate ?? 0, livePrev.rate ?? 0, [], '%'),
        },
        progressBands: progressBands(spans.filter((s) => activeIn(s, from, to)).map((s) => progressAt(s, to))),
        categories: categories
          .map((cat) => {
            const list = byCategory.get(cat.id) ?? [];
            return {
              categoryId: cat.id,
              title: cat.name,
              enrollments: countIn(
                list.map((s) => s.start),
                from,
                to,
              ),
              completionRate: completionRate(list.map((s) => s.e)),
            };
          })
          .filter((c) => c.enrollments > 0)
          .sort((x, y) => y.enrollments - x.enrollments),
        topCourses: courseRows(ctx).slice(0, 5),
      };
    }, 700),

  courses: (filters) =>
    respond(() => {
      const ctx = contextFor(filters);
      return { ...reportContext(ctx), rows: courseRows(ctx) };
    }, 650),

  course: (courseId, filters) =>
    respond((): CourseReport => {
      const course = courses.find((c) => c.id === courseId);
      if (!course || course.status === 'draft') throw new ServiceError('There’s no report for this course — it may still be a draft.', 'not-found');
      const base = contextFor({ range: filters.range });
      const ctx = narrow(base, base.byCourse.get(courseId) ?? [], scenario() === 'empty' ? [] : [course]);
      const { spans, from, to, pFrom, pTo } = ctx;
      const row = courseRow({ ...ctx, courses: [course] }, course);
      const series = seriesFor(ctx);
      const ends = sparkEnds(ctx);
      const intake = spans.filter((s) => s.start > from && s.start <= to);
      const working = spans.filter((s) => activeIn(s, from, to));
      const minutes = (ch: Course['chapters'][number]) => ch.lessons.reduce((m, l) => m + l.durationMin, 0);
      const total = course.chapters.reduce((n, ch) => n + minutes(ch), 0) || 1;
      let before = 0;
      const chapters = course.chapters.map((ch) => {
        const startPct = (before / total) * 100;
        before += minutes(ch);
        const reached = working.filter((s) => progressAt(s, to) > Math.max(startPct, 2)).length;
        return { chapterId: ch.id, title: ch.title, reached: percentOf(reached, working.length) ?? 0 };
      });
      const assignments = courseAssignments
        .filter((a) => a.courseId === courseId && a.status !== 'draft')
        .map((a) => {
          const subs = ctx.subs.filter((x) => x.assignmentId === a.id && ms(x.submittedAt) > from && ms(x.submittedAt) <= to);
          const graded = subs.filter((x) => x.review.status === 'graded' && x.review.score !== undefined);
          return {
            assignmentId: a.id,
            title: a.title,
            submitted: subs.length,
            passRate: percentOf(graded.filter((x) => x.review.score! >= a.passMark).length, graded.length),
            avgScore: graded.length ? Math.round(avg(graded.map((x) => (x.review.score! / maxScoreOf(a.id)) * 100))) : null,
            onTime: percentOf(subs.filter((x) => !x.late).length, subs.length),
          };
        });
      return {
        ...reportContext(ctx),
        row,
        kpis: {
          enrollments: kpi(
            row.enrollments,
            row.previousEnrollments,
            series.enrollments.map((p) => p.value),
          ),
          completionRate: kpi(
            completionAt(spans, to),
            completionAt(spans, pTo),
            ends.map((t) => completionAt(spans, t)),
            '%',
          ),
          activeLearners: kpi(
            row.activeLearners,
            activeLearners(spans, pFrom, pTo),
            series.activeLearners.map((p) => p.value),
          ),
          avgProgress: kpi(
            row.avgProgress,
            avgProgressAt(spans, pFrom, pTo),
            ends.map((t) => avgProgressAt(spans, t - 28 * DAY, t)),
            '%',
          ),
        },
        series,
        funnel: [
          { label: 'Enrolled', value: intake.length },
          { label: 'Started', value: intake.filter((s) => progressAt(s, to) >= 3).length },
          { label: 'Halfway', value: intake.filter((s) => progressAt(s, to) >= 50).length },
          { label: 'Finished', value: intake.filter((s) => s.done && s.done <= to).length },
        ],
        chapters,
        quizzes: quizFigures(ctx, from, to).rows,
        assignments,
      };
    }, 650),

  learners: ({ search = '', sort = { key: 'progress', direction: 'desc' }, page, pageSize, ...filters }) =>
    respond((): LearnerReport => {
      const ctx = contextFor(filters);
      const people = peopleIn(ctx);
      const segment = filters.segment ?? 'all';
      const segments = Object.fromEntries(LEARNER_SEGMENTS.map((s) => [s, people.filter((p) => p.segments.has(s)).length])) as LearnerReport['segments'];
      const chosen = people.filter((p) => p.segments.has(segment));
      const statuses: LearnerReport['statuses'] = { active: 0, 'at-risk': 0, inactive: 0, suspended: 0 };
      for (const p of chosen) statuses[p.status] += 1;

      const scores = new Map<string, number[]>();
      for (const s of ctx.subs) {
        if (s.review.status !== 'graded' || s.review.score === undefined) continue;
        const list = scores.get(s.studentId) ?? [];
        list.push((s.review.score / maxScoreOf(s.assignmentId)) * 100);
        scores.set(s.studentId, list);
      }
      const q = search.trim().toLowerCase();
      const rows: LearnerReportRow[] = [];
      for (const p of chosen) {
        const student = studentsById.get(p.id)!;
        if (q && !`${student.name} ${student.city} ${student.email}`.toLowerCase().includes(q)) continue;
        rows.push({
          studentId: p.id,
          name: student.name,
          city: student.city,
          status: p.status,
          courses: p.spans.length,
          completed: p.spans.filter((s) => s.e.status === 'completed').length,
          avgProgress: Math.round(avg(p.spans.map((s) => s.e.progress))),
          assignmentAvg: scores.has(p.id) ? Math.round(avg(scores.get(p.id)!)) : null,
          lastActiveAt: student.lastActiveAt,
        });
      }
      const dir = sort.direction === 'asc' ? 1 : -1;
      const valueOf = (r: LearnerReportRow): number | string =>
        sort.key === 'name'
          ? r.name
          : sort.key === 'courses'
            ? r.courses
            : sort.key === 'assignments'
              ? (r.assignmentAvg ?? -1)
              : sort.key === 'lastActive'
                ? r.lastActiveAt
                : r.avgProgress;
      rows.sort((x, y) => {
        const a = valueOf(x);
        const b = valueOf(y);
        const order = typeof a === 'string' ? a.localeCompare(b as string) : a - (b as number);
        return order * dir || x.name.localeCompare(y.name);
      });

      // Earlier figures come from the same people as they stood at the end of the previous period.
      const spans = segment === 'all' ? ctx.spans : chosen.flatMap((p) => p.spans);
      const before = new Map<string, Span[]>();
      for (const s of spans) {
        if (!activeIn(s, ctx.pFrom, ctx.pTo)) continue;
        const list = before.get(s.e.studentId) ?? [];
        list.push(s);
        before.set(s.e.studentId, list);
      }
      const earlier = [...before.entries()].map(([id, list]) => ({ id, spans: list }));
      const activeBefore = earlier.filter((p) => ms(studentsById.get(p.id)?.lastActiveAt) > ctx.pTo - AT_RISK_AFTER_DAYS * DAY).length;

      return {
        ...reportContext(ctx),
        kpis: {
          learners: kpi(chosen.length, earlier.length),
          active: kpi(statuses.active, activeBefore),
          atRisk: kpi(statuses['at-risk'], atRiskAt(earlier, ctx.pTo)),
          avgProgress: kpi(avgProgressAt(spans, ctx.from, ctx.to), avgProgressAt(spans, ctx.pFrom, ctx.pTo), [], '%'),
        },
        segments,
        statuses,
        progressBands: progressBands(chosen.map((p) => Math.round(avg(p.spans.map((s) => s.e.progress))))),
        rows: rows.slice((page - 1) * pageSize, page * pageSize),
        total: rows.length,
      };
    }, 700),

  instructors: (filters) =>
    respond((): InstructorReport => {
      const ctx = contextFor(filters);
      const graded = ctx.subs.filter((s) => s.review.status === 'graded' && s.review.reviewerId && s.review.updatedAt);
      const hoursIn = (list: Submission[], from: number, to: number) =>
        list.filter((s) => ms(s.review.updatedAt) > from && ms(s.review.updatedAt) <= to).map((s) => (ms(s.review.updatedAt) - ms(s.submittedAt)) / HOUR);
      const rows: InstructorReportRow[] = instructors
        .filter((i) => i.status !== 'invited' && (!filters.instructorId || i.id === filters.instructorId))
        .map((i) => {
          const theirs = ctx.courses.filter((c) => c.instructorIds.includes(i.id));
          const spans = theirs.flatMap((c) => ctx.byCourse.get(c.id) ?? []);
          const hours = hoursIn(
            graded.filter((s) => s.review.reviewerId === i.id),
            ctx.from,
            ctx.to,
          );
          const rated = theirs.filter((c) => c.status === 'published' && c.rating && c.ratingCount);
          const count = rated.reduce((n, c) => n + (c.ratingCount ?? 0), 0);
          const live = liveAttendance(narrow(ctx, spans, theirs), ctx.from, ctx.to, i.id);
          return {
            instructorId: i.id,
            name: i.name,
            title: i.title,
            courses: theirs.length,
            learners: activeLearners(spans, ctx.from, ctx.to),
            completionRate: spans.length ? Math.round(completionAt(spans, ctx.to)) : null,
            rating: count ? round1(rated.reduce((n, c) => n + (c.rating ?? 0) * (c.ratingCount ?? 0), 0) / count) : null,
            reviews: hours.length,
            reviewHours: hours.length ? Math.round(median(hours)!) : null,
            onTime: percentOf(hours.filter((h) => h <= 48).length, hours.length),
            liveClasses: live.classes,
            attendance: live.rate,
          };
        })
        .filter((r) => r.courses > 0)
        .sort((a, b) => b.learners - a.learners);
      const teaching = new Set(rows.map((r) => r.instructorId));
      const mine = graded.filter((s) => teaching.has(s.review.reviewerId!));
      const cur = hoursIn(mine, ctx.from, ctx.to);
      const prev = hoursIn(mine, ctx.pFrom, ctx.pTo);
      const liveNow = liveAttendance(ctx, ctx.from, ctx.to);
      const livePrev = liveAttendance(ctx, ctx.pFrom, ctx.pTo);
      return {
        ...reportContext(ctx),
        rows,
        figures: {
          reviews: kpi(cur.length, prev.length),
          reviewHours: kpi(Math.round(median(cur) ?? 0), Math.round(median(prev) ?? 0)),
          onTime: kpi(percentOf(cur.filter((h) => h <= 48).length, cur.length) ?? 0, percentOf(prev.filter((h) => h <= 48).length, prev.length) ?? 0, [], '%'),
          attendance: kpi(liveNow.rate ?? 0, livePrev.rate ?? 0, [], '%'),
        },
      };
    }, 650),

  enrolments: (filters) =>
    respond((): EnrolmentReport => {
      const base = contextFor(filters);
      const ctx = narrow(base, segmentSpans(base, filters.segment));
      const { spans, from, to, pFrom, pTo } = ctx;
      const series = seriesFor(ctx);
      const ends = sparkEnds(ctx);
      const current = spans.filter((s) => s.start > from && s.start <= to);
      const previous = spans.filter((s) => s.start > pFrom && s.start <= pTo);
      const selfShare = (list: Span[]) => percentOf(list.filter((s) => s.e.source === 'self').length, list.length) ?? 0;
      const dones = spans.map((s) => s.done);
      const sources = (['self', 'purchase', 'cohort', 'admin', 'scholarship'] as const).map((source) => {
        const inPeriod = current.filter((s) => s.e.source === source).length;
        return {
          source,
          enrollments: inPeriod,
          share: percentOf(inPeriod, current.length) ?? 0,
          completionRate: completionRate(spans.filter((s) => s.e.source === source).map((s) => s.e)),
        };
      });
      const categoryRows = categories
        .map((cat) => {
          const list = spans.filter((s) => categoryOf.get(s.e.courseId) === cat.id);
          const starts = list.map((s) => s.start);
          return {
            categoryId: cat.id,
            title: cat.name,
            enrollments: countIn(starts, from, to),
            previousEnrollments: countIn(starts, pFrom, pTo),
            completionRate: completionRate(list.map((s) => s.e)),
          };
        })
        .filter((c) => c.enrollments + c.previousEnrollments > 0)
        .sort((a, b) => b.enrollments - a.enrollments);
      const monthFmt = new Intl.DateTimeFormat('en-IN', { month: 'short', year: 'numeric', timeZone: 'Asia/Kolkata' });
      const ist = new Date(NOW.getTime() + 330 * 60_000);
      const monthStart = (offset: number) =>
        new Date(`${new Date(Date.UTC(ist.getUTCFullYear(), ist.getUTCMonth() + offset, 1)).toISOString().slice(0, 7)}-01T00:00:00+05:30`).getTime();
      const cohorts = Array.from({ length: 6 }, (_, i) => {
        const start = monthStart(-6 + i);
        const end = monthStart(-5 + i);
        const intake = spans.filter((s) => s.start >= start && s.start < end);
        const within = (days: number) =>
          end + days * DAY > NOW.getTime() ? null : (percentOf(intake.filter((s) => s.done && s.done - s.start <= days * DAY).length, intake.length) ?? 0);
        return {
          month: monthFmt.format(new Date(start)).replace('Sept', 'Sep'),
          enrolled: intake.length,
          within30: within(30),
          within60: within(60),
          within90: within(90),
          toDate: percentOf(intake.filter((s) => s.done).length, intake.length) ?? 0,
        };
      }).reverse();
      return {
        ...reportContext(ctx),
        kpis: {
          enrollments: kpi(
            current.length,
            previous.length,
            series.enrollments.map((p) => p.value),
          ),
          completions: kpi(
            countIn(dones, from, to),
            countIn(dones, pFrom, pTo),
            series.completions.map((p) => p.value),
          ),
          completionRate: kpi(
            completionAt(spans, to),
            completionAt(spans, pTo),
            ends.map((t) => completionAt(spans, t)),
            '%',
          ),
          selfShare: kpi(selfShare(current), selfShare(previous), [], '%'),
        },
        series,
        sources,
        categories: categoryRows,
        cohorts,
      };
    }, 650),
};
