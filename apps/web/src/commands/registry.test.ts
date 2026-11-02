import { describe, expect, it } from 'vitest';
import { foundationsCourse } from '@/services/mock/fixtures/catalog';
import { resolveCommands } from './registry';

describe('command registry', () => {
  it('offers students their next steps and staff their creation tools', () => {
    const student = resolveCommands('student', '').map((c) => c.id);
    const admin = resolveCommands('admin', '').map((c) => c.id);
    expect(student).toContain('join-live');
    expect(student).not.toContain('create-course');
    expect(admin).toContain('create-course');
    expect(admin).not.toContain('resume');
  });

  it('searches lessons and courses once a query is typed', () => {
    // The palette passes the catalog it loaded; against the real API nothing else is searched.
    const results = resolveCommands('student', 'nakshatra', [foundationsCourse]);
    expect(results.some((c) => c.group === 'Lessons' && c.label === 'Nakshatra lords and the Vimshottari link')).toBe(true);
    expect(
      results.every(
        (c, i, all) =>
          i === 0 ||
          ['Continue', 'Actions', 'Lessons', 'Courses', 'Go to', 'Preferences'].indexOf(all[i - 1].group) <=
            ['Continue', 'Actions', 'Lessons', 'Courses', 'Go to', 'Preferences'].indexOf(c.group),
      ),
    ).toBe(true);
  });

  it('offers a super admin the platform and the workspace it runs', () => {
    const ids = resolveCommands('superadmin', '').map((c) => c.id);
    expect(ids).toEqual([
      'go-platform',
      'go-workspace-courses',
      'go-workspace-students',
      'go-workspace-instructors',
      'go-workspace-reports',
      'go-workspace-reviews',
      'go-workspace-settings',
      'go-platform-admins',
      'go-platform-users',
      'go-platform-sales',
      'go-platform-affiliates',
      'go-platform-website',
      'go-platform-inbox',
      'go-platform-notifications',
      'go-platform-audit',
      'go-platform-system',
      'go-platform-branding',
    ]);
    expect(ids).not.toContain('resume');
  });

  it('searches nothing but a loaded catalog, and offers real learners their own pages', () => {
    expect(resolveCommands('student', 'course', []).filter((c) => c.group === 'Lessons' || c.group === 'Courses')).toEqual([]);
    const labels = resolveCommands('student', '')
      .filter((c) => c.group === 'Continue')
      .map((c) => `${c.label} ${c.hint ?? ''}`);
    expect(labels.join(' ')).not.toMatch(/house|navagraha|jyotish|chart|rulership|dignities/i);
  });

  it('never offers switching to the role already in use', () => {
    expect(resolveCommands('instructor', 'view as').map((c) => c.id)).not.toContain('role-instructor');
  });
});
