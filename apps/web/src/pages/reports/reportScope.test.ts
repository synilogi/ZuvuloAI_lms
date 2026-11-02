import { describe, expect, it } from 'vitest';
import { reportTabs } from './reportScope';

describe('reportTabs', () => {
  it('gives an instructor the overview and courses, under the teaching workspace', () => {
    expect(reportTabs('/teach', true)).toEqual([
      { key: 'overview', to: '/teach/reports' },
      { key: 'courses', to: '/teach/reports/courses' },
    ]);
  });

  it('gives an admin every tab, under the admin workspace', () => {
    expect(reportTabs('/admin', false).map((t) => t.to)).toEqual([
      '/admin/reports',
      '/admin/reports/courses',
      '/admin/reports/learners',
      '/admin/reports/instructors',
      '/admin/reports/enrolments',
    ]);
  });
});
