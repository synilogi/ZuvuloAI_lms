import { beforeAll, describe, expect, it } from 'vitest';

import { as, type Client } from '../test/helpers.js';

/* The staff landing screen. These tests check that its figures, events and attention items come from
 * records, that each KPI reads a real earlier value rather than itself, and that an instructor's
 * dashboard covers only their own courses. */

let admin: Client;
let instructor: Client;
let learner: Client;

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  learner = await as('student');
});

describe('dashboard: headline figures', () => {
  it('reads every KPI at the current moment and a month earlier', async () => {
    const res = await admin.get('/dashboard');
    expect(res.status).toBe(200);
    const { scope, kpis, enrollments, completions, activity, engagement } = res.body;

    expect(scope.kind).toBe('academy');
    for (const [name, k] of Object.entries(kpis)) {
      const kpi = k as { value: number; previous: number; series: number[] };
      expect(typeof kpi.value, name).toBe('number');
      expect(kpi.series.length, name).toBe(8);
      // The reading is the newest point in its own history, and the previous one the point before.
      expect(kpi.value, name).toBe(kpi.series[7]);
      expect(kpi.previous, name).toBe(kpi.series[6]);
    }
    expect(kpis.courses.value).toBeGreaterThan(0);
    expect(kpis.students.value).toBeGreaterThan(0);
    expect(kpis.third.value).toBeGreaterThan(0);
    expect(kpis.completionRate.unit).toBe('%');
    expect(kpis.completionRate.value).toBeGreaterThan(0);
    // The academy grew, so it had fewer learners a month ago than it has now.
    expect(kpis.students.previous).toBeLessThan(kpis.students.value);
    expect(kpis.students.series[0]).toBeLessThanOrEqual(kpis.students.series[7]);

    expect(enrollments).toHaveLength(12);
    expect(completions).toHaveLength(12);
    expect(enrollments.reduce((n: number, p: { value: number }) => n + p.value, 0)).toBeGreaterThan(0);
    expect(completions.reduce((n: number, p: { value: number }) => n + p.value, 0)).toBeGreaterThan(0);

    expect(activity).toHaveLength(28);
    expect(activity.some((d: { lessonsCompleted: number }) => d.lessonsCompleted > 0)).toBe(true);
    expect(activity.some((d: { activeLearners: number }) => d.activeLearners > 0)).toBe(true);

    // Engagement is a weekly count with the week before it to compare against.
    for (const [name, k] of Object.entries(engagement)) {
      const kpi = k as { value: number; previous: number; series: number[] };
      expect(kpi.series.length, name).toBe(4);
      expect(kpi.value, name).toBe(kpi.series[3]);
      expect(kpi.previous, name).toBe(kpi.series[2]);
    }
    expect(engagement.lessonsCompleted.value + engagement.lessonsCompleted.previous).toBeGreaterThan(0);
  });

  it('ranks published courses by how many learners they hold', async () => {
    const { courses } = (await admin.get('/dashboard')).body;
    expect(courses.length).toBeGreaterThan(0);
    const enrolled = courses.map((c: { enrolled: number }) => c.enrolled);
    expect([...enrolled].sort((a: number, b: number) => b - a)).toEqual(enrolled);

    const top = courses[0];
    expect(top.enrolled).toBeGreaterThan(0);
    expect(top.avgProgress).toBeGreaterThan(0);
    expect(top.weeklyEnrollments).toHaveLength(8);
    expect(top.active).toBeLessThanOrEqual(top.enrolled);
    expect(top.completionRate).toBeGreaterThanOrEqual(0);
  });
});

describe('dashboard: attention and what has been happening', () => {
  it('raises real triage items with the records behind them', async () => {
    const { attention } = (await admin.get('/dashboard')).body;
    expect(attention.length).toBeGreaterThan(0);
    for (const item of attention) {
      expect(item.title).toBeTruthy();
      expect(item.detail).toBeTruthy();
      expect(['high', 'medium', 'low']).toContain(item.severity);
      expect(item.to.startsWith('/admin')).toBe(true);
      // Nothing is raised about nothing.
      if (item.count !== undefined) expect(item.count).toBeGreaterThan(0);
    }
    // The seeded academy has learners who have gone quiet.
    const atRisk = attention.find((i: { kind: string }) => i.kind === 'at-risk');
    expect(atRisk).toBeTruthy();
    expect(atRisk.count).toBeGreaterThan(0);
  });

  it('reports named people and real courses, newest first', async () => {
    const { events } = (await admin.get('/dashboard')).body;
    expect(events.length).toBeGreaterThan(0);
    expect(events.length).toBeLessThanOrEqual(12);

    const times = events.map((e: { at: string }) => e.at);
    expect([...times].sort((a: string, b: string) => b.localeCompare(a))).toEqual(times);
    for (const e of events) {
      expect(e.actor).toBeTruthy();
      expect(e.actor).not.toBe('A learner');
      expect(e.summary).toBeTruthy();
      expect(new Date(e.at).getTime()).toBeLessThanOrEqual(Date.now() + 1000);
    }
    // The feed is not one kind of thing repeated.
    expect(new Set(events.map((e: { kind: string }) => e.kind)).size).toBeGreaterThan(1);
    const enrolment = events.find((e: { kind: string }) => e.kind === 'enrollment');
    expect(enrolment.summary).toMatch(/^enrolled in .+/);

    // A submission or review event must link to a route the router actually has — the submission
    // review page is nested under its assignment (`/assignments/:assignmentId/submissions/:id`),
    // not a flat `/assignments/submissions/:id`.
    for (const e of events.filter((x: { kind: string }) => x.kind === 'submission' || x.kind === 'review')) {
      expect(e.to).toMatch(/\/assignments\/[^/]+\/submissions\/[^/]+$/);
    }
  });

  it('lists only live classes that are still to come', async () => {
    const { upcomingLive } = (await admin.get('/dashboard')).body;
    for (const c of upcomingLive) {
      expect(c.cancelled).toBeUndefined();
      // Within the next eight days, and not already finished.
      expect(new Date(c.startsAt).getTime() + c.durationMin * 60_000).toBeGreaterThan(Date.now());
      expect(new Date(c.startsAt).getTime()).toBeLessThan(Date.now() + 8 * 86_400_000);
    }
  });
});

describe('dashboard: scope', () => {
  it('gives an instructor their own courses and counts their review queue', async () => {
    const academy = (await admin.get('/dashboard')).body;
    const mine = (await instructor.get('/dashboard')).body;

    expect(mine.scope).toEqual({ kind: 'instructor', instructorId: expect.any(String) });
    expect(mine.courses.length).toBeGreaterThan(0);
    expect(mine.courses.length).toBeLessThan(academy.courses.length);
    const academyIds = new Set(academy.courses.map((c: { courseId: string }) => c.courseId));
    for (const c of mine.courses) expect(academyIds.has(c.courseId)).toBe(true);
    for (const item of mine.attention) expect(item.to.startsWith('/teach') || item.to.startsWith('/admin/certificates')).toBe(true);

    // An admin sees the teaching staff in the third slot; an instructor sees what they owe learners.
    expect(mine.kpis.third.value).toBeGreaterThanOrEqual(0);
    expect(mine.kpis.students.value).toBeLessThanOrEqual(academy.kpis.students.value);

    // An instructor cannot widen the scope by naming the academy or someone else.
    const spoofed = (await instructor.get('/dashboard', { scope: 'academy' })).body;
    expect(spoofed.scope).toEqual(mine.scope);
    expect(spoofed.courses.length).toBe(mine.courses.length);
  });

  it('lets an admin look at one instructor, and keeps learners out', async () => {
    const academy = (await admin.get('/dashboard')).body;
    const instructorId = (await instructor.get('/dashboard')).body.scope.instructorId;
    const scoped = (await admin.get('/dashboard', { scope: 'instructor', instructorId })).body;
    expect(scoped.scope).toEqual({ kind: 'instructor', instructorId });
    expect(scoped.courses.length).toBeLessThan(academy.courses.length);

    expect((await learner.get('/dashboard')).status).toBe(403);
  });
});
