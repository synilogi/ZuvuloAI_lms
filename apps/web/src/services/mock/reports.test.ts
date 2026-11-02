import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { reportsService as service } from './reports';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('reports mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('measures a period against the one before, with charts that add up', async () => {
    const o = await settle(service.overview({ range: '90d' }));
    expect(o.series.enrollments).toHaveLength(13);
    expect(o.series.enrollments.reduce((n, p) => n + p.value, 0)).toBe(o.kpis.enrollments.value);
    expect(o.series.enrollments.at(-1)?.partial).toBe(true);
    expect(o.kpis.completionRate.unit).toBe('%');
    expect(o.topCourses.length).toBeLessThanOrEqual(5);
    expect(o.progressBands.reduce((n, b) => n + b.value, 0)).toBeGreaterThan(0);
    const year = await settle(service.overview({ range: '12m' }));
    expect(year.kpis.enrollments.value).toBeGreaterThan(o.kpis.enrollments.value);
  });

  it('narrows by course, category and instructor', async () => {
    const all = await settle(service.courses({ range: '90d' }));
    const teaching = await settle(service.courses({ range: '90d', instructorId: 'meenakshi' }));
    expect(teaching.rows.length).toBeLessThan(all.rows.length);
    expect(teaching.rows.every((r) => r.instructorNames.includes('Dr. Meenakshi Iyer'))).toBe(true);
    const none = await settle(service.courses({ range: '90d', categoryId: 'remedies', instructorId: 'meenakshi' }));
    expect(none.rows).toHaveLength(0);

    const course = await settle(service.course('foundations-vedic', { range: '90d' }));
    const [enrolled, started, halfway, finished] = course.funnel.map((f) => f.value);
    expect(enrolled).toBeGreaterThanOrEqual(started);
    expect(started).toBeGreaterThanOrEqual(halfway);
    expect(halfway).toBeGreaterThanOrEqual(finished);
    expect(course.chapters[0].reached).toBeGreaterThanOrEqual(course.chapters.at(-1)!.reached);
  });

  it('segments, searches, sorts and pages learners', async () => {
    const all = await settle(service.learners({ range: '90d', page: 1, pageSize: 10 }));
    expect(all.rows).toHaveLength(10);
    expect(all.segments.new).toBeLessThan(all.segments.all);
    const risk = await settle(service.learners({ range: '90d', segment: 'at-risk', page: 1, pageSize: 500, sort: { key: 'name', direction: 'asc' } }));
    expect(risk.total).toBe(all.segments['at-risk']);
    expect(risk.rows.every((r) => r.status === 'at-risk')).toBe(true);
    expect(risk.rows.every((r, i) => i === 0 || risk.rows[i - 1].name.localeCompare(r.name) <= 0)).toBe(true);
    const found = await settle(service.learners({ range: '90d', search: all.rows[0].name, page: 1, pageSize: 10 }));
    expect(found.rows.some((r) => r.studentId === all.rows[0].studentId)).toBe(true);
  });

  it('reports instructors and monthly intakes', async () => {
    const i = await settle(service.instructors({ range: '90d' }));
    expect(i.rows.length).toBeGreaterThan(3);
    expect(i.rows.every((r) => r.onTime === null || (r.onTime >= 0 && r.onTime <= 100))).toBe(true);
    const e = await settle(service.enrolments({ range: '90d' }));
    expect(e.cohorts).toHaveLength(6);
    expect(e.cohorts[0].within30).toBeNull();
    expect(e.sources.reduce((n, s) => n + s.enrollments, 0)).toBe(e.kpis.enrollments.value);
  });
});
