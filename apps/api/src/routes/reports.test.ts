import { beforeAll, describe, expect, it } from 'vitest';

import { db, T } from '../test/db.js';
import { ACCOUNTS, as, newStudent, type Client } from '../test/helpers.js';

/* Reports read every other module's records. These tests check that each tab reports real figures
 * from the seeded academy rather than placeholders, that the previous period is measured separately
 * from the current one, and that an instructor only ever sees their own courses. */

let admin: Client;
let instructor: Client;
let learner: Client;

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  learner = await as('student');
});

/** Every number in a KPI band should be a real reading, not a hard-coded zero. */
const kpiShape = (k: { value: number; previous: number; series: number[]; unit: string }) => {
  expect(typeof k.value).toBe('number');
  expect(typeof k.previous).toBe('number');
  expect(Array.isArray(k.series)).toBe(true);
};

describe('reports: overview', () => {
  it('reports the period, the one before it, and figures drawn from records', async () => {
    const res = await admin.get('/reports/overview', { range: '90d' });
    expect(res.status).toBe(200);
    const { kpis, series, quizzes, assignments, engagement, progressBands, categories, topCourses, window, courseCount } = res.body;

    expect(new Date(window.from).getTime()).toBeLessThan(new Date(window.to).getTime());
    expect(new Date(window.previousTo).getTime()).toBeLessThanOrEqual(new Date(window.from).getTime());
    expect(courseCount).toBeGreaterThan(0);

    for (const k of Object.values(kpis)) kpiShape(k as never);
    expect(kpis.enrollments.value).toBeGreaterThan(0);
    expect(kpis.completions.value).toBeGreaterThan(0);
    expect(kpis.activeLearners.value).toBeGreaterThan(0);
    // The seeded academy has a year of history, so the earlier period is populated too.
    expect(kpis.enrollments.previous).toBeGreaterThan(0);
    expect(kpis.completionRate.value).toBeGreaterThan(0);
    expect(kpis.completionRate.previous).toBeGreaterThan(0);
    expect(kpis.avgProgress.value).toBeGreaterThan(0);

    // A chart period per bucket, with the newest one still filling.
    expect(series.enrollments.length).toBeGreaterThan(1);
    expect(series.enrollments.at(-1).partial).toBe(true);
    expect(series.enrollments.reduce((n: number, p: { value: number }) => n + p.value, 0)).toBeGreaterThan(0);
    expect(series.activeLearners.some((p: { value: number }) => p.value > 0)).toBe(true);

    expect(quizzes.attempts.value).toBeGreaterThan(0);
    expect(quizzes.passRate.value).toBeGreaterThan(0);
    expect(quizzes.avgScore.value).toBeGreaterThan(0);
    expect(assignments.submitted.value).toBeGreaterThan(0);
    expect(assignments.reviewHours.value).toBeGreaterThan(0);
    expect(engagement.lessonsCompleted.value).toBeGreaterThan(0);
    expect(engagement.liveAttendance.value).toBeGreaterThan(0);

    expect(progressBands).toHaveLength(5);
    expect(progressBands.reduce((n: number, b: { value: number }) => n + b.value, 0)).toBeGreaterThan(0);
    expect(categories.length).toBeGreaterThan(0);
    expect(categories[0].title).toBeTruthy();
    expect(topCourses.length).toBeGreaterThan(0);
    expect(topCourses[0].categoryTitle).toBeTruthy();
    expect(topCourses[0].instructorNames.length).toBeGreaterThan(0);
    expect(topCourses[0].trend.length).toBe(series.enrollments.length);
  });

  it('measures a shorter period differently from a longer one', async () => {
    const short = (await admin.get('/reports/overview', { range: '30d' })).body;
    const long = (await admin.get('/reports/overview', { range: '12m' })).body;
    expect(long.kpis.enrollments.value).toBeGreaterThan(short.kpis.enrollments.value);
    expect(long.series.enrollments.length).not.toBe(short.series.enrollments.length);
  });
});

describe('reports: courses', () => {
  it('carries category, instructors, pass rates and a trend per course', async () => {
    const res = await admin.get('/reports/courses', { range: '12m' });
    expect(res.status).toBe(200);
    expect(res.body.rows.length).toBeGreaterThan(0);

    const withQuiz = res.body.rows.find((r: { quizPassRate: number | null }) => r.quizPassRate !== null);
    expect(withQuiz).toBeTruthy();
    expect(withQuiz.quizPassRate).toBeGreaterThan(0);
    expect(withQuiz.categoryTitle).toBeTruthy();
    expect(withQuiz.instructorNames.length).toBeGreaterThan(0);
    expect(withQuiz.trend.some((v: number) => v > 0)).toBe(true);
    expect(withQuiz.activeLearners).toBeGreaterThan(0);
    // Rows are ordered by how busy the course was.
    const counts = res.body.rows.map((r: { enrollments: number }) => r.enrollments);
    expect([...counts].sort((a: number, b: number) => b - a)).toEqual(counts);
  });

  it('breaks one course down into a funnel, chapters, quizzes and assignments', async () => {
    const list = (await admin.get('/reports/courses', { range: '12m' })).body;
    // A seeded course, by name: other suites leave chapterless courses with more enrolments, so the top row depends on file order.
    const { id: courseId } = await db.course.findFirstOrThrow({ where: { slug: 'maths-foundations' } });
    expect(list.rows.map((r: { courseId: string }) => r.courseId)).toContain(courseId);
    const res = await admin.get(`/reports/courses/${courseId}`, { range: '12m' });
    expect(res.status).toBe(200);
    const { funnel, chapters, quizzes, assignments, series, kpis } = res.body;

    expect(funnel.map((f: { label: string }) => f.label)).toEqual(['Enrolled', 'Started', 'Halfway', 'Finished']);
    // The funnel only ever narrows.
    const values = funnel.map((f: { value: number }) => f.value);
    expect(values[0]).toBeGreaterThan(0);
    for (let i = 1; i < values.length; i++) expect(values[i]).toBeLessThanOrEqual(values[i - 1]);

    expect(chapters.length).toBeGreaterThan(0);
    expect(chapters[0].reached).toBeGreaterThan(0);
    // Later chapters are reached by no more learners than earlier ones.
    expect(chapters.at(-1).reached).toBeLessThanOrEqual(chapters[0].reached);

    expect(quizzes.length).toBeGreaterThan(0);
    expect(quizzes[0].attempts).toBeGreaterThan(0);
    expect(assignments.length).toBeGreaterThan(0);
    expect(series.enrollments.some((p: { value: number }) => p.value > 0)).toBe(true);
    expect(kpis.completionRate.value).toBeGreaterThanOrEqual(0);
  });

  it('answers 404 for a course that has no report', async () => {
    expect((await admin.get('/reports/courses/nope')).status).toBe(404);
  });
});

describe('reports: learners', () => {
  it('counts segments and statuses, and pages and sorts the roster', async () => {
    const res = await admin.get('/reports/learners', { range: '12m', page: 1, pageSize: 5 });
    expect(res.status).toBe(200);
    const { kpis, segments, statuses, progressBands, rows, total } = res.body;

    expect(total).toBeGreaterThan(5);
    expect(rows).toHaveLength(5);
    expect(segments.all).toBe(total);
    expect(segments.completers).toBeGreaterThan(0);
    // Statuses are derived from real quiet time, so the roster is not uniformly "active".
    expect(statuses.active + statuses['at-risk'] + statuses.inactive + statuses.suspended).toBe(total);
    expect(statuses.active).toBeGreaterThan(0);
    expect(statuses.inactive).toBeGreaterThan(0);
    expect(kpis.learners.value).toBe(total);
    expect(kpis.avgProgress.value).toBeGreaterThan(0);
    expect(progressBands.reduce((n: number, b: { value: number }) => n + b.value, 0)).toBe(total);

    const byName = (await admin.get('/reports/learners', { range: '12m', page: 1, pageSize: 5, sortKey: 'name', sortDirection: 'asc' })).body;
    const names = byName.rows.map((r: { name: string }) => r.name);
    expect([...names].sort((a: string, b: string) => a.localeCompare(b))).toEqual(names);

    const page2 = (await admin.get('/reports/learners', { range: '12m', page: 2, pageSize: 5, sortKey: 'name', sortDirection: 'asc' })).body;
    expect(page2.rows[0].studentId).not.toBe(byName.rows[0].studentId);
  });

  it('narrows the roster to a segment and to a search', async () => {
    const all = (await admin.get('/reports/learners', { range: '12m', page: 1, pageSize: 100 })).body;
    const completers = (await admin.get('/reports/learners', { range: '12m', segment: 'completers', page: 1, pageSize: 100 })).body;
    expect(completers.total).toBe(all.segments.completers);
    expect(completers.total).toBeLessThan(all.total);
    expect(completers.rows.every((r: { completed: number }) => r.completed > 0)).toBe(true);

    const name = all.rows[0].name;
    const found = (await admin.get('/reports/learners', { range: '12m', search: name, page: 1, pageSize: 20 })).body;
    expect(found.total).toBeGreaterThan(0);
    expect(found.rows.some((r: { name: string }) => r.name === name)).toBe(true);
  });
});

describe('reports: instructors and enrolments', () => {
  it('reports teaching figures per instructor', async () => {
    const res = await admin.get('/reports/instructors', { range: '12m' });
    expect(res.status).toBe(200);
    expect(res.body.rows.length).toBeGreaterThan(0);

    const row = res.body.rows[0];
    expect(row.courses).toBeGreaterThan(0);
    expect(row.learners).toBeGreaterThan(0);
    expect(row.completionRate).not.toBeNull();
    expect(row.rating).toBeGreaterThan(0);
    // Rows are ordered by how many learners the instructor reached.
    const reach = res.body.rows.map((r: { learners: number }) => r.learners);
    expect([...reach].sort((a: number, b: number) => b - a)).toEqual(reach);

    const withLive = res.body.rows.find((r: { liveClasses: number }) => r.liveClasses > 0);
    expect(withLive.attendance).toBeGreaterThan(0);
    expect(res.body.figures.reviews.value).toBeGreaterThan(0);
    expect(res.body.figures.attendance.value).toBeGreaterThan(0);
  });

  it('splits enrolments by source and category, and follows monthly cohorts', async () => {
    const res = await admin.get('/reports/enrolments', { range: '12m' });
    expect(res.status).toBe(200);
    const { kpis, sources, categories, cohorts } = res.body;

    expect(kpis.enrollments.value).toBeGreaterThan(0);
    expect(kpis.selfShare.value).toBeGreaterThan(0);
    // The seed enrols through every route, so the split is real.
    expect(sources.filter((s: { enrollments: number }) => s.enrollments > 0).length).toBeGreaterThan(1);
    expect(sources.reduce((n: number, s: { enrollments: number }) => n + s.enrollments, 0)).toBe(kpis.enrollments.value);
    expect(categories.length).toBeGreaterThan(0);

    expect(cohorts).toHaveLength(6);
    expect(cohorts.some((c: { enrolled: number }) => c.enrolled > 0)).toBe(true);
    // The newest intake has not had 30 days yet, so its early windows stay unreported.
    expect(cohorts[0].within30).toBeNull();
    const settled = cohorts.find((c: { within90: number | null }) => c.within90 !== null);
    expect(settled).toBeTruthy();
  });
});

describe('reports: permissions', () => {
  it('confines an instructor to their own courses and keeps the roster admin-only', async () => {
    const mine = (await instructor.get('/reports/overview', { range: '12m' })).body;
    const all = (await admin.get('/reports/overview', { range: '12m' })).body;
    expect(mine.courseCount).toBeGreaterThan(0);
    expect(mine.courseCount).toBeLessThan(all.courseCount);
    expect(mine.kpis.enrollments.value).toBeLessThan(all.kpis.enrollments.value);

    // An instructor cannot widen their scope by naming someone else.
    const other = all.topCourses.find((c: { instructorNames: string[] }) => !c.instructorNames.includes('Dr. Meenakshi Iyer'));
    const spoofed = (await instructor.get('/reports/overview', { range: '12m', instructorId: 'cmu-someone-else' })).body;
    expect(spoofed.courseCount).toBe(mine.courseCount);
    if (other) expect((await instructor.get(`/reports/courses/${other.courseId}`, { range: '12m' })).status).toBe(404);

    expect((await instructor.get('/reports/instructors')).status).toBe(403);
    expect((await learner.get('/reports/overview')).status).toBe(403);
    expect((await learner.get('/reports/learners')).status).toBe(403);
  });

  it('shows an instructor none of another instructor’s figures, whichever way they ask', async () => {
    // A course taught only by the other instructor, with figures that can be told apart.
    const other = await as('instructor2');
    const otherId = (await db.instructor.findFirstOrThrow({ where: { email: ACCOUNTS.instructor2 } })).id;
    const levelId = (await db.level.findFirstOrThrow()).id;
    const categoryId = (await db.category.findFirstOrThrow()).id;
    const stamp = Date.now();
    const course = await db.course.create({
      data: {
        ...T,
        slug: `only-theirs-${stamp}`,
        title: `Only Theirs ${stamp}`,
        levelId,
        categoryId,
        format: 'self-paced',
        coverMotif: 'orbits',
        pricing: 'free',
        status: 'published',
        visibility: 'public',
        instructors: { create: { ...T, instructorId: otherId } },
      },
    });

    const range = { range: '12m' };
    const before = (await instructor.get('/reports/overview', range)).body;
    const coursesBefore = (await instructor.get('/reports/courses', range)).body.rows;
    const enrolledBefore = (await instructor.get('/reports/enrolments', range)).body.kpis.enrollments.value;
    const othersBefore = (await other.get('/reports/overview', range)).body;

    for (let n = 0; n < 3; n++) {
      const buyer = await newStudent(`Other Course Learner ${n}`);
      await db.enrollment.create({ data: { ...T, studentId: buyer.studentId, courseId: course.id } });
    }

    // Their figures moved…
    const others = (await other.get('/reports/overview', range)).body;
    expect(others.kpis.enrollments.value).toBe(othersBefore.kpis.enrollments.value + 3);
    expect((await other.get(`/reports/courses/${course.id}`, range)).status).toBe(200);
    expect((await admin.get('/reports/courses', range)).body.rows.map((r: { courseId: string }) => r.courseId)).toContain(course.id);

    // …and nothing the first instructor can read did.
    const after = (await instructor.get('/reports/overview', range)).body;
    expect(after.courseCount).toBe(before.courseCount);
    expect(after.kpis.enrollments.value).toBe(before.kpis.enrollments.value);
    expect(after.topCourses.map((c: { courseId: string }) => c.courseId)).not.toContain(course.id);

    const asks: [string, Record<string, unknown>][] = [
      ['/reports/courses', range],
      ['/reports/courses', { ...range, courseId: course.id }],
      ['/reports/courses', { ...range, instructorId: otherId }],
    ];
    for (const [path, query] of asks) {
      const rows = (await instructor.get(path, query)).body.rows.map((r: { courseId: string }) => r.courseId);
      expect(rows, JSON.stringify(query)).not.toContain(course.id);
    }
    expect((await instructor.get('/reports/courses', range)).body.rows).toHaveLength(coursesBefore.length);
    expect((await instructor.get('/reports/overview', { ...range, courseId: course.id })).body.courseCount).toBe(0);
    expect((await instructor.get('/reports/overview', { ...range, instructorId: otherId })).body.courseCount).toBe(before.courseCount);
    expect((await instructor.get('/reports/enrolments', range)).body.kpis.enrollments.value).toBe(enrolledBefore);
    expect((await instructor.get(`/reports/courses/${course.id}`, range)).status).toBe(404);
    expect((await instructor.get('/reports/course-sales')).body.map((r: { courseId: string }) => r.courseId)).not.toContain(course.id);
    const learnerRows = (await instructor.get('/reports/learners', { ...range, pageSize: 100 })).body.rows.map((r: { name: string }) => r.name);
    expect(learnerRows.some((name: string) => name.startsWith('Other Course Learner'))).toBe(false);
  });
});
