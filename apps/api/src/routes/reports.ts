import { courseScopeWhere } from '../lib/scope.js';
import { Router } from 'express';
import {
  LEARNER_SEGMENTS,
  REPORT_RANGES,
  REVIEW_STATUSES,
  median,
  percentOf,
  reportWindow,
  type EnrollmentSource,
  type Kpi,
  type LearnerSegment,
  type ReportFilters,
  type StudentStatus,
} from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { setReviewStatus, staffCourseReviews } from '../lib/courseReviews.js';
import { asyncHandler, notFound } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requirePermission, requireStaffPermission } from '../lib/permissions.js';
import { instructorScope } from '../lib/scope.js';
import { optionalEnum, optionalId, paging, parseQuery, searchText, z } from '../lib/validate.js';
import { getSettings } from '../lib/settings.js';
import { readJson } from '../lib/json.js';
import {
  activeIn,
  activeLearners,
  asPoints,
  assignmentFigures,
  avg,
  avgProgressAt,
  bucketCounts,
  bucketsFor,
  cohortsOf,
  completionAt,
  countIn,
  DAY,
  liveAttendance,
  onTimeShare,
  progressAt,
  lessonsFinishedIn,
  progressBands,
  progressIndex,
  quizFigures,
  reviewHoursIn,
  round1,
  scorePercent,
  spanOf,
  sparkEnds,
  statusAt,
  type AttemptRow,
  type Bucket,
  type LiveRow,
  type ProgressIndex,
  type Span,
  type SubmissionRow,
} from '../lib/reports.js';

export const reportsRouter = Router();

const kpi = (value: number, previous: number, series: number[] = [], unit: Kpi['unit'] = 'count'): Kpi => ({ value, previous, series, unit });

/* A period or segment the app does not know is a bad request, not a broken window. */
const filterQuery = z.object({
  range: optionalEnum(REPORT_RANGES),
  segment: optionalEnum(LEARNER_SEGMENTS),
  categoryId: optionalId,
  courseId: optionalId,
  instructorId: optionalId,
});

function filtersFrom(req: import('express').Request): ReportFilters {
  const query = parseQuery(req, filterQuery);
  // Instructors always report on their own courses; only admins may pick an instructor.
  const scope = instructorScope(req);
  return {
    range: query.range ?? '90d',
    categoryId: query.categoryId,
    courseId: query.courseId,
    instructorId: scope ?? query.instructorId,
    segment: query.segment,
  };
}

/* ─── Request context ─── */

interface CourseRow {
  id: string;
  title: string;
  status: string;
  categoryId: string;
  categoryTitle: string;
  instructorIds: string[];
  instructorNames: string[];
  rating: number | null;
  ratingCount: number | null;
}

interface Ctx {
  filters: ReportFilters;
  now: Date;
  from: number;
  to: number;
  pFrom: number;
  pTo: number;
  buckets: Bucket[];
  window: { from: string; to: string; previousFrom: string; previousTo: string };
  courses: CourseRow[];
  ids: Set<string>;
  spans: Span[];
  byCourse: Map<string, Span[]>;
  index: ProgressIndex;
  attempts: AttemptRow[];
  subs: SubmissionRow[];
  live: LiveRow[];
}

const groupByCourse = (spans: Span[]) => {
  const byCourse = new Map<string, Span[]>();
  for (const s of spans) {
    const list = byCourse.get(s.courseId);
    if (list) list.push(s);
    else byCourse.set(s.courseId, [s]);
  }
  return byCourse;
};

/** Everything a report tab reads, gathered once: drafts never appear in a report. */
async function contextFor(filters: ReportFilters): Promise<Ctx> {
  const now = new Date();
  const w = reportWindow(filters.range, now);
  const courses = await db.course.findMany({
    where: {
      status: { not: 'draft' },
      ...(filters.categoryId ? { categoryId: filters.categoryId } : {}),
      ...(filters.courseId ? { id: filters.courseId } : {}),
      ...(filters.instructorId ? { instructors: { some: { instructorId: filters.instructorId } } } : {}),
    },
    include: { category: true, instructors: { include: { instructor: true } } },
  });
  const rows: CourseRow[] = courses.map((c) => ({
    id: c.id,
    title: c.title,
    status: c.status,
    categoryId: c.categoryId,
    categoryTitle: c.category.name,
    instructorIds: c.instructors.map((i) => i.instructorId),
    instructorNames: c.instructors.map((i) => i.instructor.name),
    rating: c.rating,
    ratingCount: c.ratingCount,
  }));
  const ids = new Set(rows.map((c) => c.id));
  const courseIds = [...ids];

  const enrollments = await db.enrollment.findMany({
    where: { courseId: { in: courseIds } },
    select: { studentId: true, courseId: true, status: true, source: true, progress: true, enrolledAt: true, lastActiveAt: true, completedAt: true },
  });
  const spans = enrollments.map(spanOf);

  const attemptRows = await db.quizAttempt.findMany({
    where: { quiz: { courseId: { in: courseIds } } },
    select: { createdAt: true, percent: true, passed: true, quiz: { select: { courseId: true } } },
  });
  const attempts: AttemptRow[] = attemptRows.map((a) => ({ courseId: a.quiz.courseId, createdAt: a.createdAt, percent: a.percent, passed: a.passed }));

  const subRows = await db.submission.findMany({
    where: { assignment: { courseId: { in: courseIds } } },
    include: { assignment: { select: { id: true, courseId: true, maxScore: true, passMark: true, rubricJson: true } } },
  });
  const subs: SubmissionRow[] = subRows.map((s) => {
    const rubric = readJson<{ points?: number }[]>(s.assignment.rubricJson, []);
    const max = rubric.length ? rubric.reduce((n, c) => n + (c.points ?? 0), 0) : s.assignment.maxScore;
    return {
      studentId: s.studentId,
      assignmentId: s.assignmentId,
      courseId: s.assignment.courseId,
      submittedAt: s.submittedAt,
      late: s.late,
      score: s.score,
      maxScore: max || 1,
      passMark: s.assignment.passMark,
      reviewStatus: s.reviewStatus,
      reviewerId: s.reviewerId,
      reviewUpdatedAt: s.reviewUpdatedAt,
    };
  });

  const liveRows = await db.liveClass.findMany({
    where: { courseId: { in: courseIds } },
    select: { courseId: true, instructorId: true, startsAt: true, durationMin: true, cancelled: true, registrations: { select: { attended: true } } },
  });
  const live: LiveRow[] = liveRows.map((l) => ({
    courseId: l.courseId,
    instructorId: l.instructorId,
    startsAt: l.startsAt,
    durationMin: l.durationMin,
    cancelled: l.cancelled,
    registered: l.registrations.length,
    attended: l.registrations.filter((r) => r.attended === true).length,
  }));

  return {
    filters,
    now,
    from: w.from.getTime(),
    to: w.to.getTime(),
    pFrom: w.previousFrom.getTime(),
    pTo: w.previousTo.getTime(),
    buckets: bucketsFor(filters.range, now),
    window: { from: w.from.toISOString(), to: w.to.toISOString(), previousFrom: w.previousFrom.toISOString(), previousTo: w.previousTo.toISOString() },
    courses: rows,
    ids,
    spans,
    byCourse: groupByCourse(spans),
    index: await progressIndex(courseIds),
    attempts,
    subs,
    live,
  };
}

/** The same period over a narrower set of courses — one course, or one instructor's. */
function narrow(ctx: Ctx, courses: CourseRow[]): Ctx {
  const ids = new Set(courses.map((c) => c.id));
  const spans = ctx.spans.filter((s) => ids.has(s.courseId));
  return {
    ...ctx,
    courses,
    ids,
    spans,
    byCourse: groupByCourse(spans),
    attempts: ctx.attempts.filter((a) => ids.has(a.courseId)),
    subs: ctx.subs.filter((s) => ids.has(s.courseId)),
    live: ctx.live.filter((l) => ids.has(l.courseId)),
  };
}

const reportContext = (ctx: Ctx) => ({ window: ctx.window, courseCount: ctx.courses.length });

function seriesFor(ctx: Ctx) {
  const starts = ctx.spans.map((s) => s.start);
  const dones = ctx.spans.filter((s) => s.done).map((s) => s.done);
  return {
    enrollments: asPoints(ctx.buckets, bucketCounts(ctx.buckets, starts)),
    completions: asPoints(ctx.buckets, bucketCounts(ctx.buckets, dones)),
    activeLearners: asPoints(
      ctx.buckets,
      ctx.buckets.map((b) => activeLearners(ctx.spans, b.from.getTime(), b.to.getTime())),
    ),
  };
}

/** Lessons finished inside the period, across the selected courses. */
const lessonsCompleted = (ctx: Ctx, from: number, to: number) => lessonsFinishedIn(ctx.index, ctx.spans, from, to);

/* ─── Course rows ─── */

function courseRow(ctx: Ctx, course: CourseRow) {
  const spans = ctx.byCourse.get(course.id) ?? [];
  const one = narrow(ctx, [course]);
  const quiz = quizFigures(one.attempts, ctx.from, ctx.to);
  const asg = assignmentFigures(one.subs, ctx.from, ctx.to);
  const starts = spans.map((s) => s.start);
  const handed = one.subs.filter((s) => s.submittedAt.getTime() > ctx.from && s.submittedAt.getTime() <= ctx.to);
  return {
    courseId: course.id,
    title: course.title,
    categoryTitle: course.categoryTitle,
    instructorNames: course.instructorNames,
    status: course.status,
    enrollments: countIn(starts, ctx.from, ctx.to),
    previousEnrollments: countIn(starts, ctx.pFrom, ctx.pTo),
    completions: countIn(
      spans.map((s) => s.done),
      ctx.from,
      ctx.to,
    ),
    completionRate: completionAt(spans, ctx.to),
    activeLearners: activeLearners(spans, ctx.from, ctx.to),
    avgProgress: avgProgressAt(ctx.index, spans, ctx.from, ctx.to),
    quizPassRate: quiz.attempts ? quiz.passRate : null,
    assignmentPassRate: handed.length ? asg.passRate : null,
    rating: course.status === 'published' && course.rating != null ? course.rating : undefined,
    trend: bucketCounts(ctx.buckets, starts),
  };
}

const courseRows = (ctx: Ctx) =>
  ctx.courses
    .filter((c) => ctx.byCourse.has(c.id))
    .map((c) => courseRow(ctx, c))
    .sort((a, b) => b.enrollments - a.enrollments);

/* ─── Learners ─── */

interface Person {
  id: string;
  spans: Span[];
  status: StudentStatus;
  segments: Set<LearnerSegment>;
  name: string;
  email: string;
  city: string;
  lastActiveAt: Date;
}

/** Learners the period covers: anyone studying during it, plus anyone who joined during it. */
async function peopleIn(ctx: Ctx, atRiskDays: number): Promise<Person[]> {
  const byStudent = new Map<string, Span[]>();
  for (const s of ctx.spans) {
    const list = byStudent.get(s.studentId);
    if (list) list.push(s);
    else byStudent.set(s.studentId, [s]);
  }
  const students = await db.student.findMany({
    where: { id: { in: [...byStudent.keys()] } },
    select: { id: true, city: true, suspended: true, lastActiveAt: true, user: { select: { name: true, email: true } } },
  });
  const now = ctx.now.getTime();

  const people: Person[] = [];
  for (const student of students) {
    const spans = byStudent.get(student.id) ?? [];
    const first = Math.min(...spans.map((s) => s.start));
    if (!spans.some((s) => activeIn(s, ctx.from, ctx.to)) && first <= ctx.from) continue;
    const open = spans.some((s) => s.status === 'active');
    const status: StudentStatus = student.suspended ? 'suspended' : statusAt(student.lastActiveAt.getTime(), open, now, atRiskDays);
    const segments = new Set<LearnerSegment>(['all']);
    if (first > ctx.from && first <= ctx.to) segments.add('new');
    if (status !== 'suspended') segments.add(status);
    if (spans.some((s) => s.done > ctx.from && s.done <= ctx.to)) segments.add('completers');
    people.push({
      id: student.id,
      spans,
      status,
      segments,
      name: student.user.name,
      email: student.user.email,
      city: student.city,
      lastActiveAt: student.lastActiveAt,
    });
  }
  return people;
}

function atRiskAt(people: Person[], t: number, atRiskDays: number) {
  let n = 0;
  for (const p of people) {
    const seen = p.lastActiveAt.getTime();
    const open = p.spans.some((s) => s.start <= t && !(s.done && s.done <= t) && s.status !== 'expired');
    if (statusAt(Math.min(seen, t), open, t, atRiskDays) === 'at-risk') n += 1;
  }
  return n;
}

/* ─── Overview ─── */

reportsRouter.get(
  '/overview',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('reports.view'),
  asyncHandler(async (req, res) => {
    const ctx = await contextFor(filtersFrom(req));
    const { spans, from, to, pFrom, pTo, index } = ctx;
    const series = seriesFor(ctx);
    const ends = sparkEnds(ctx.buckets);
    const now = ctx.now.getTime();

    const q = quizFigures(ctx.attempts, from, to);
    const qPrev = quizFigures(ctx.attempts, pFrom, pTo);
    const a = assignmentFigures(ctx.subs, from, to);
    const aPrev = assignmentFigures(ctx.subs, pFrom, pTo);
    const active = activeLearners(spans, from, to);
    const activePrev = activeLearners(spans, pFrom, pTo);
    const lessons = lessonsCompleted(ctx, from, to);
    const lessonsPrev = lessonsCompleted(ctx, pFrom, pTo);
    const live = liveAttendance(ctx.live, from, to, now);
    const livePrev = liveAttendance(ctx.live, pFrom, pTo, now);
    const starts = spans.map((s) => s.start);
    const dones = spans.map((s) => s.done);

    const byCategory = new Map<string, Span[]>();
    const categoryOf = new Map(ctx.courses.map((c) => [c.id, c.categoryId]));
    const categoryTitle = new Map(ctx.courses.map((c) => [c.categoryId, c.categoryTitle]));
    for (const s of spans) {
      const cat = categoryOf.get(s.courseId);
      if (!cat) continue;
      const list = byCategory.get(cat);
      if (list) list.push(s);
      else byCategory.set(cat, [s]);
    }

    res.json({
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
          avgProgressAt(index, spans, from, to),
          avgProgressAt(index, spans, pFrom, pTo),
          ends.map((t) => avgProgressAt(index, spans, t - 28 * DAY, t)),
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
      progressBands: progressBands(spans.filter((s) => activeIn(s, from, to)).map((s) => progressAt(index, s, to))),
      categories: [...byCategory.entries()]
        .map(([categoryId, list]) => ({
          categoryId,
          title: categoryTitle.get(categoryId) ?? '',
          enrollments: countIn(
            list.map((s) => s.start),
            from,
            to,
          ),
          completionRate: completionAt(list, to),
        }))
        .filter((c) => c.enrollments > 0)
        .sort((x, y) => y.enrollments - x.enrollments),
      topCourses: courseRows(ctx).slice(0, 5),
    });
  }),
);

/* ─── Reviews ─── */

/** Reviews in the caller's scope: an instructor reads the courses they teach, hidden reviews included. */
reportsRouter.get(
  '/reviews',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('reports.view'),
  asyncHandler(async (req, res) => {
    res.json(await staffCourseReviews(req, parseQuery(req, z.object({ status: optionalEnum(REVIEW_STATUSES), courseId: optionalId, ...paging }))));
  }),
);

/* Hiding a review changes what the public page says, so it takes the key that governs what is in front of learners. */
reportsRouter.post(
  '/reviews/:id/hide',
  requireAuth,
  requireRole('admin'),
  requirePermission('catalog.publish'),
  asyncHandler(async (req, res) => {
    res.json(await setReviewStatus(req, req.params.id, 'hidden'));
  }),
);

reportsRouter.post(
  '/reviews/:id/show',
  requireAuth,
  requireRole('admin'),
  requirePermission('catalog.publish'),
  asyncHandler(async (req, res) => {
    res.json(await setReviewStatus(req, req.params.id, 'published'));
  }),
);

/* ─── Courses ─── */

/** Enrolments and orders per course: an instructor sees only their own courses (docs/16, D-PLAT-10). Counts, never money. */
reportsRouter.get(
  '/course-sales',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('reports.view'),
  asyncHandler(async (req, res) => {
    const courses = await db.course.findMany({
      where: { ...courseScopeWhere(req), status: { not: 'archived' } },
      select: { id: true, title: true, pricing: true, _count: { select: { enrollments: { where: { status: { not: 'expired' } } } } } },
      orderBy: { title: 'asc' },
    });
    const orders = await db.coursePurchase.groupBy({
      by: ['courseId', 'refundedAt'],
      where: { courseId: { in: courses.map((c) => c.id) }, status: 'paid' },
      _count: { _all: true },
    });
    const count = (courseId: string, refunded: boolean) =>
      orders.filter((o) => o.courseId === courseId && (o.refundedAt !== null) === refunded).reduce((n, o) => n + o._count._all, 0);
    res.json(
      courses.map((c) => ({
        courseId: c.id,
        title: c.title,
        pricing: c.pricing === 'paid' ? 'paid' : 'free',
        enrolled: c._count.enrollments,
        paidOrders: count(c.id, false),
        refundedOrders: count(c.id, true),
      })),
    );
  }),
);

reportsRouter.get(
  '/courses',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('reports.view'),
  asyncHandler(async (req, res) => {
    const ctx = await contextFor(filtersFrom(req));
    res.json({ ...reportContext(ctx), rows: courseRows(ctx) });
  }),
);

reportsRouter.get(
  '/courses/:courseId',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('reports.view'),
  asyncHandler(async (req, res) => {
    const filters = filtersFrom(req);
    // The tab reports on one course, but the caller's scope still decides whether they may see it.
    const base = await contextFor({ range: filters.range, instructorId: filters.instructorId });
    const course = base.courses.find((c) => c.id === req.params.courseId);
    if (!course) throw notFound('There’s no report for this course — it may still be a draft.');

    const ctx = narrow(base, [course]);
    const { spans, from, to, pFrom, pTo, index } = ctx;
    const row = courseRow(ctx, course);
    const series = seriesFor(ctx);
    const ends = sparkEnds(ctx.buckets);
    const intake = spans.filter((s) => s.start > from && s.start <= to);
    const working = spans.filter((s) => activeIn(s, from, to));

    // A learner has reached a chapter once their progress passes where that chapter opens.
    const chapters = await db.chapter.findMany({
      where: { courseId: course.id },
      orderBy: { position: 'asc' },
      select: { id: true, title: true, lessons: { where: { status: 'published' }, select: { durationMin: true } } },
    });
    const totalMin = chapters.reduce((n, ch) => n + ch.lessons.reduce((m, l) => m + l.durationMin, 0), 0) || 1;
    let before = 0;
    const chapterRows = chapters.map((ch) => {
      const startPct = (before / totalMin) * 100;
      before += ch.lessons.reduce((m, l) => m + l.durationMin, 0);
      const reached = working.filter((s) => progressAt(index, s, to) > Math.max(startPct, 2)).length;
      return { chapterId: ch.id, title: ch.title, reached: percentOf(reached, working.length) ?? 0 };
    });

    const quizzes = await db.quiz.findMany({ where: { courseId: course.id, status: 'published' }, select: { id: true, title: true, attempts: true } });
    const quizRows = quizzes.map((quiz) => {
      const inPeriod = quiz.attempts.filter((x) => x.createdAt.getTime() > from && x.createdAt.getTime() <= to);
      return {
        quizId: quiz.id,
        title: quiz.title,
        attempts: inPeriod.length,
        passRate: percentOf(inPeriod.filter((x) => x.passed).length, inPeriod.length) ?? 0,
        avgScore: inPeriod.length ? Math.round(avg(inPeriod.map((x) => x.percent))) : 0,
      };
    });

    const assignments = await db.courseAssignment.findMany({ where: { courseId: course.id, status: { not: 'draft' } }, select: { id: true, title: true } });
    const assignmentRows = assignments.map((a) => {
      const handed = ctx.subs.filter((s) => s.assignmentId === a.id && s.submittedAt.getTime() > from && s.submittedAt.getTime() <= to);
      const graded = handed.filter((s) => (s.reviewStatus === 'graded' || s.reviewStatus === 'returned') && s.score != null);
      return {
        assignmentId: a.id,
        title: a.title,
        submitted: handed.length,
        passRate: percentOf(graded.filter((s) => (s.score ?? 0) >= s.passMark).length, graded.length),
        avgScore: graded.length ? Math.round(avg(graded.map(scorePercent))) : null,
        onTime: percentOf(handed.filter((s) => !s.late).length, handed.length),
      };
    });

    res.json({
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
          avgProgressAt(index, spans, pFrom, pTo),
          ends.map((t) => avgProgressAt(index, spans, t - 28 * DAY, t)),
          '%',
        ),
      },
      series,
      funnel: [
        { label: 'Enrolled', value: intake.length },
        { label: 'Started', value: intake.filter((s) => progressAt(index, s, to) >= 3).length },
        { label: 'Halfway', value: intake.filter((s) => progressAt(index, s, to) >= 50).length },
        { label: 'Finished', value: intake.filter((s) => s.done && s.done <= to).length },
      ],
      chapters: chapterRows,
      quizzes: quizRows,
      assignments: assignmentRows,
    });
  }),
);

/* ─── Learners ─── */

reportsRouter.get(
  '/learners',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('reports.view'),
  asyncHandler(async (req, res) => {
    const filters = filtersFrom(req);
    const {
      search = '',
      sortKey = 'progress',
      sortDirection = 'desc',
      page,
      pageSize,
    } = parseQuery(
      req,
      z.object({
        search: searchText,
        sortKey: optionalEnum(['name', 'courses', 'progress', 'assignments', 'lastActive'] as const),
        sortDirection: optionalEnum(['asc', 'desc'] as const),
        ...paging,
      }),
    );
    const ctx = await contextFor(filters);
    const { atRiskDays } = (await getSettings()).learning;
    const people = await peopleIn(ctx, atRiskDays);

    const segment = filters.segment ?? 'all';
    const segments = Object.fromEntries(LEARNER_SEGMENTS.map((s) => [s, people.filter((p) => p.segments.has(s)).length])) as Record<LearnerSegment, number>;
    const chosen = people.filter((p) => p.segments.has(segment));
    const statuses: Record<StudentStatus, number> = { active: 0, 'at-risk': 0, inactive: 0, suspended: 0 };
    for (const p of chosen) statuses[p.status] += 1;

    const scores = new Map<string, number[]>();
    for (const s of ctx.subs) {
      if (!((s.reviewStatus === 'graded' || s.reviewStatus === 'returned') && s.score != null)) continue;
      const list = scores.get(s.studentId) ?? [];
      list.push(scorePercent(s));
      scores.set(s.studentId, list);
    }

    const q = search.trim().toLowerCase();
    const rows = chosen
      .filter((p) => !q || `${p.name} ${p.city} ${p.email}`.toLowerCase().includes(q))
      .map((p) => ({
        studentId: p.id,
        name: p.name,
        city: p.city,
        status: p.status,
        courses: p.spans.length,
        completed: p.spans.filter((s) => s.status === 'completed').length,
        avgProgress: Math.round(avg(p.spans.map((s) => s.progress))),
        assignmentAvg: scores.has(p.id) ? Math.round(avg(scores.get(p.id)!)) : null,
        lastActiveAt: p.lastActiveAt.toISOString(),
      }));

    const dir = sortDirection === 'asc' ? 1 : -1;
    const valueOf = (r: (typeof rows)[number]): number | string =>
      sortKey === 'name'
        ? r.name
        : sortKey === 'courses'
          ? r.courses
          : sortKey === 'assignments'
            ? (r.assignmentAvg ?? -1)
            : sortKey === 'lastActive'
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
    const earlier = people.filter((p) => p.spans.some((s) => activeIn(s, ctx.pFrom, ctx.pTo)));
    const activeBefore = earlier.filter((p) => p.lastActiveAt.getTime() > ctx.pTo - atRiskDays * DAY).length;

    res.json({
      ...reportContext(ctx),
      kpis: {
        learners: kpi(chosen.length, earlier.length),
        active: kpi(statuses.active, activeBefore),
        atRisk: kpi(statuses['at-risk'], atRiskAt(earlier, ctx.pTo, atRiskDays)),
        avgProgress: kpi(avgProgressAt(ctx.index, spans, ctx.from, ctx.to), avgProgressAt(ctx.index, spans, ctx.pFrom, ctx.pTo), [], '%'),
      },
      segments,
      statuses,
      progressBands: progressBands(chosen.map((person) => Math.round(avg(person.spans.map((s) => s.progress))))),
      rows: rows.slice((page - 1) * pageSize, page * pageSize),
      total: rows.length,
    });
  }),
);

/* ─── Instructors ─── */

reportsRouter.get(
  '/instructors',
  requireAuth,
  requireRole('admin'),
  requirePermission('reports.instructors.view'),
  asyncHandler(async (req, res) => {
    const filters = filtersFrom(req);
    const ctx = await contextFor(filters);
    const now = ctx.now.getTime();
    const instructors = await db.instructor.findMany({
      where: { status: { notIn: ['invited', 'pending', 'rejected'] } },
      select: { id: true, name: true, title: true },
    });

    const rows = instructors
      .filter((i) => !filters.instructorId || i.id === filters.instructorId)
      .map((i) => {
        const theirs = ctx.courses.filter((c) => c.instructorIds.includes(i.id));
        const one = narrow(ctx, theirs);
        const hours = reviewHoursIn(
          one.subs.filter((s) => s.reviewerId === i.id),
          ctx.from,
          ctx.to,
        );
        const rated = theirs.filter((c) => c.status === 'published' && c.rating && c.ratingCount);
        const ratingCount = rated.reduce((n, c) => n + (c.ratingCount ?? 0), 0);
        const live = liveAttendance(one.live, ctx.from, ctx.to, now, i.id);
        return {
          instructorId: i.id,
          name: i.name,
          title: i.title,
          courses: theirs.length,
          learners: activeLearners(one.spans, ctx.from, ctx.to),
          completionRate: one.spans.length ? completionAt(one.spans, ctx.to) : null,
          rating: ratingCount ? round1(rated.reduce((n, c) => n + (c.rating ?? 0) * (c.ratingCount ?? 0), 0) / ratingCount) : null,
          reviews: hours.length,
          reviewHours: hours.length ? Math.round(median(hours)!) : null,
          onTime: onTimeShare(hours),
          liveClasses: live.classes,
          attendance: live.rate,
        };
      })
      .filter((r) => r.courses > 0)
      .sort((a, b) => b.learners - a.learners);

    const teaching = new Set(rows.map((r) => r.instructorId));
    const mine = ctx.subs.filter((s) => s.reviewerId && teaching.has(s.reviewerId));
    const cur = reviewHoursIn(mine, ctx.from, ctx.to);
    const prev = reviewHoursIn(mine, ctx.pFrom, ctx.pTo);
    const liveNow = liveAttendance(ctx.live, ctx.from, ctx.to, now);
    const livePrev = liveAttendance(ctx.live, ctx.pFrom, ctx.pTo, now);

    res.json({
      ...reportContext(ctx),
      rows,
      figures: {
        reviews: kpi(cur.length, prev.length),
        reviewHours: kpi(Math.round(median(cur) ?? 0), Math.round(median(prev) ?? 0)),
        onTime: kpi(onTimeShare(cur) ?? 0, onTimeShare(prev) ?? 0, [], '%'),
        attendance: kpi(liveNow.rate ?? 0, livePrev.rate ?? 0, [], '%'),
      },
    });
  }),
);

/* ─── Enrolments ─── */

reportsRouter.get(
  '/enrolments',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('reports.view'),
  asyncHandler(async (req, res) => {
    const filters = filtersFrom(req);
    const base = await contextFor(filters);

    // The segment picker narrows which learners' enrolments the tab counts.
    let ctx = base;
    if (filters.segment && filters.segment !== 'all') {
      const { atRiskDays } = (await getSettings()).learning;
      const people = await peopleIn(base, atRiskDays);
      const ids = new Set(people.filter((p) => p.segments.has(filters.segment!)).map((p) => p.id));
      const spans = base.spans.filter((s) => ids.has(s.studentId));
      ctx = { ...base, spans, byCourse: groupByCourse(spans) };
    }

    const { spans, from, to, pFrom, pTo } = ctx;
    const series = seriesFor(ctx);
    const ends = sparkEnds(ctx.buckets);
    const current = spans.filter((s) => s.start > from && s.start <= to);
    const previous = spans.filter((s) => s.start > pFrom && s.start <= pTo);
    const dones = spans.map((s) => s.done);
    const selfShare = (list: Span[]) => percentOf(list.filter((s) => s.source === 'self').length, list.length) ?? 0;

    const sources = (['self', 'purchase', 'cohort', 'admin', 'scholarship'] as EnrollmentSource[]).map((source) => {
      const inPeriod = current.filter((s) => s.source === source).length;
      return {
        source,
        enrollments: inPeriod,
        share: percentOf(inPeriod, current.length) ?? 0,
        completionRate: completionAt(
          spans.filter((s) => s.source === source),
          to,
        ),
      };
    });

    const categoryOf = new Map(ctx.courses.map((c) => [c.id, c.categoryId]));
    const categoryTitle = new Map(ctx.courses.map((c) => [c.categoryId, c.categoryTitle]));
    const byCategory = new Map<string, Span[]>();
    for (const s of spans) {
      const cat = categoryOf.get(s.courseId);
      if (!cat) continue;
      const list = byCategory.get(cat);
      if (list) list.push(s);
      else byCategory.set(cat, [s]);
    }

    res.json({
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
      categories: [...byCategory.entries()]
        .map(([categoryId, list]) => {
          const starts = list.map((s) => s.start);
          return {
            categoryId,
            title: categoryTitle.get(categoryId) ?? '',
            enrollments: countIn(starts, from, to),
            previousEnrollments: countIn(starts, pFrom, pTo),
            completionRate: completionAt(list, to),
          };
        })
        .filter((c) => c.enrollments + c.previousEnrollments > 0)
        .sort((a, b) => b.enrollments - a.enrollments),
      cohorts: cohortsOf(spans, ctx.now),
    });
  }),
);
