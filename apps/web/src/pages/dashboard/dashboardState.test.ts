import { describe, expect, it } from 'vitest';
import { isNewAcademy, setupSteps } from './dashboardState';

const kpi = (value: number) => ({ value, previous: 0, series: [] });
const snapshot = (students: number, enrolments: number[]) => ({
  kpis: { courses: kpi(0), students: kpi(students), third: kpi(0), completionRate: kpi(0) },
  enrollments: enrolments.map((value, i) => ({ date: `2026-0${i + 1}-01`, value })),
});

describe('a brand-new academy’s dashboard', () => {
  it('shows the way to get started, not charts of zeros, until someone enrols', () => {
    expect(isNewAcademy(snapshot(0, [0, 0, 0]))).toBe(true);
    expect(isNewAcademy(snapshot(0, []))).toBe(true);
    expect(isNewAcademy(snapshot(3, [0, 1, 2]))).toBe(false);
    expect(isNewAcademy(snapshot(0, [0, 1]))).toBe(false);
  });

  it('ticks off the setup steps as the platform takes them', () => {
    expect(setupSteps({ courses: 0, instructors: 0 })).toEqual([
      { id: 'course', done: false },
      { id: 'instructor', done: false },
    ]);
    expect(setupSteps({ courses: 1, instructors: 2 }).every((s) => s.done)).toBe(true);
  });
});
