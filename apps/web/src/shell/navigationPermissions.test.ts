import { describe, expect, it } from 'vitest';
import type { PermissionKey } from '@syniastrolms/domain';
import { firstOpenDestination, navigation, visibleNavigation } from './navigation';
import { allows, pagePermission } from '@/lib/adminPermissions';

/** The predicate the shell builds, for an admin holding exactly `keys`. */
const canOpen = (keys: PermissionKey[]) => (to: string) => allows('admin', keys, pagePermission(to));
const destinations = (keys: PermissionKey[]) => visibleNavigation('admin', canOpen(keys)).flatMap((g) => g.items.map((i) => i.to));
const groups = (keys: PermissionKey[]) => visibleNavigation('admin', canOpen(keys)).map((g) => g.id);

describe('the admin sidebar follows the permissions', () => {
  it('shows an admin with nothing only what is not permission-controlled', () => {
    expect(destinations([])).toEqual(['/admin/live', '/admin/certificates', '/admin/calendar', '/admin/help']);
    expect(groups([])).toEqual(['catalog', 'insight']);
  });

  it('shows one module for one key', () => {
    expect(destinations(['learners.view'])).toContain('/admin/students');
    expect(destinations(['learners.view'])).not.toContain('/admin/courses');
    expect(destinations(['learners.view'])).not.toContain('/admin/settings');
  });

  it('combines keys without granting anything extra', () => {
    const shown = destinations(['catalog.view', 'reports.view']);
    expect(shown).toContain('/admin/courses');
    expect(shown).toContain('/admin/reports');
    expect(shown).toContain('/admin');
    expect(shown).not.toContain('/admin/students');
    expect(shown).not.toContain('/admin/instructors');
    expect(shown).not.toContain('/admin/settings');
  });

  it('keeps a parent when a child is still reachable, and drops it when none is', () => {
    const withCatalog = visibleNavigation('admin', canOpen(['catalog.view'])).flatMap((g) => g.items);
    const courses = withCatalog.find((i) => i.id === 'courses');
    expect(courses?.children?.map((c) => c.to)).toEqual(['/admin/courses', '/admin/categories']);

    // Settings' children all need settings.view, so without it the destination goes entirely.
    expect(destinations([])).not.toContain('/admin/settings');
    expect(destinations(['settings.view'])).toContain('/admin/settings');
  });

  it('drops a group once nothing in it is reachable', () => {
    expect(groups(['learners.view'])).toContain('people');
    expect(groups([])).not.toContain('people');
  });

  it('gives a fully permissioned admin exactly the navigation it always had', () => {
    const everything = [
      'catalog.view',
      'assessment.view',
      'learners.view',
      'instructors.view',
      'reports.view',
      'reports.instructors.view',
      'settings.view',
    ] as PermissionKey[];
    expect(destinations(everything)).toEqual(navigation.admin.flatMap((g) => g.items.map((i) => i.to)));
  });
});

describe('the other workspaces are untouched', () => {
  it('never filters an instructor, a learner or a super admin', () => {
    // The predicate would hide everything if it were applied — it is not.
    const hideAll = () => false;
    for (const role of ['instructor', 'student', 'superadmin'] as const) {
      expect(visibleNavigation(role, hideAll), role).toEqual(navigation[role]);
    }
  });
});

describe('an admin who may not open the dashboard lands somewhere they can', () => {
  const landing = (keys: PermissionKey[]) => firstOpenDestination(visibleNavigation('admin', canOpen(keys)), canOpen(keys), '/admin');

  it('opens the first destination their keys allow', () => {
    expect(landing(['catalog.view'])).toBe('/admin/courses');
    expect(landing(['learners.view'])).toBe('/admin/live');
  });

  it('never answers the dashboard itself', () => {
    expect(landing(['reports.view'])).not.toBe('/admin');
  });
});
