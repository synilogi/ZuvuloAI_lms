import { describe, expect, it } from 'vitest';
import { categories, courses, instructors } from './catalog';
import { enrollments, students } from './people';
import { academyLiveClasses } from './schedule';
import { buildDashboard } from '../analytics';

describe('mock academy integrity', () => {
  it('generates enrollments that add up to each course’s learner count', () => {
    for (const course of courses) {
      expect(enrollments.filter((e) => e.courseId === course.id).length, course.id).toBe(course.enrolledCount);
    }
  });

  it('references only records that exist', () => {
    const studentIds = new Set(students.map((s) => s.id));
    const courseIds = new Set(courses.map((c) => c.id));
    expect(enrollments.every((e) => studentIds.has(e.studentId) && courseIds.has(e.courseId))).toBe(true);
    expect(courses.every((c) => categories.some((cat) => cat.id === c.categoryId))).toBe(true);
    expect(courses.every((c) => c.instructorIds.every((id) => instructors.some((i) => i.id === id)))).toBe(true);
    expect(academyLiveClasses.every((c) => courseIds.has(c.courseId))).toBe(true);
  });

  it('keeps student names and enrollment ids unique', () => {
    expect(new Set(students.map((s) => s.name)).size).toBe(students.length);
    expect(new Set(enrollments.map((e) => e.id)).size).toBe(enrollments.length);
  });

  it('never dates activity before enrollment or after the demo clock', () => {
    const now = new Date('2026-09-15T18:52:00+05:30').getTime();
    for (const e of enrollments) {
      expect(new Date(e.enrolledAt).getTime()).toBeLessThanOrEqual(now);
      if (e.lastActiveAt) expect(new Date(e.lastActiveAt).getTime()).toBeGreaterThanOrEqual(new Date(e.enrolledAt).getTime() - 1000);
      if (e.status === 'completed') expect(e.progress).toBe(100);
    }
  });

  it('builds academy and instructor dashboards from the same data', () => {
    const academy = buildDashboard({ kind: 'academy' });
    const teaching = buildDashboard({ kind: 'instructor', instructorId: 'meenakshi' });
    expect(academy.kpis.courses.value).toBe(courses.filter((c) => c.status === 'published').length);
    expect(teaching.kpis.students.value).toBeLessThan(academy.kpis.students.value);
    expect(teaching.courses.every((p) => courses.find((c) => c.id === p.courseId)!.instructorIds.includes('meenakshi'))).toBe(true);
    const empty = buildDashboard({ kind: 'academy' }, true);
    expect(empty.courses).toHaveLength(0);
    expect(empty.kpis.students.value).toBe(0);
  });
});
