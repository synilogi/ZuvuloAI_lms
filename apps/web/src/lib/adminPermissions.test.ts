import { describe, expect, it } from 'vitest';
import { PERMISSION_KEYS, type PermissionKey, type Role } from '@syniastrolms/domain';
import { ADMIN_PAGE_PERMISSIONS, allows, pagePermission, permissionsOf } from './adminPermissions';

describe('what the admin workspace may show', () => {
  it('treats a profile with no permissions field as holding none — never as holding all', () => {
    expect(permissionsOf({})).toEqual([]);
    expect(permissionsOf({ permissions: undefined })).toEqual([]);
    expect(permissionsOf({ permissions: [] })).toEqual([]);
    expect(permissionsOf({ permissions: ['catalog.view'] })).toEqual(['catalog.view']);
    // The dangerous reading: an admin with nothing must be allowed nothing configurable.
    expect(allows('admin', permissionsOf({}), 'catalog.view')).toBe(false);
  });

  it('asks for a key only from an academy admin', () => {
    const none: PermissionKey[] = [];
    expect(allows('admin', none, 'catalog.view')).toBe(false);
    expect(allows('admin', ['catalog.view'], 'catalog.view')).toBe(true);
    // Every other role is governed by its own rules, not by this system.
    for (const role of ['instructor', 'student', 'superadmin'] as Role[]) {
      expect(allows(role, none, 'catalog.view'), role).toBe(true);
      expect(allows(role, none, 'settings.edit'), role).toBe(true);
    }
  });

  it('allows anything that is not permission-controlled', () => {
    expect(allows('admin', [], undefined)).toBe(true);
  });

  it('never grants one key because a neighbouring one is held', () => {
    const viewer: PermissionKey[] = ['catalog.view', 'assessment.view', 'learners.view', 'settings.view', 'instructors.view'];
    for (const key of [
      'catalog.edit',
      'catalog.publish',
      'catalog.archive',
      'assessment.edit',
      'assessment.grade',
      'learners.enroll',
      'learners.suspend',
      'learners.message',
      'settings.edit',
      'instructors.manage',
      'instructors.status',
    ] as PermissionKey[]) {
      expect(allows('admin', viewer, key), key).toBe(false);
    }
  });
});

describe('the page map', () => {
  it('names only keys the catalogue defines', () => {
    for (const { key } of ADMIN_PAGE_PERMISSIONS) expect(PERMISSION_KEYS, key).toContain(key);
  });

  it('opens each module with its own read key', () => {
    expect(pagePermission('/admin/courses')).toBe('catalog.view');
    expect(pagePermission('/admin/courses/abc/edit')).toBe('catalog.view');
    expect(pagePermission('/admin/categories')).toBe('catalog.view');
    expect(pagePermission('/admin/quizzes')).toBe('assessment.view');
    expect(pagePermission('/admin/assignments/new')).toBe('assessment.view');
    expect(pagePermission('/admin/students/s1/progress')).toBe('learners.view');
    expect(pagePermission('/admin/instructors')).toBe('instructors.view');
    expect(pagePermission('/admin/settings/general')).toBe('settings.view');
    // The academy's subscription is read with the settings key, as the API reads it (SAAS-015).
    expect(pagePermission('/admin')).toBe('reports.view');
  });

  it('reads the instructor report through its own key, not the general one', () => {
    expect(pagePermission('/admin/reports')).toBe('reports.view');
    expect(pagePermission('/admin/reports/learners')).toBe('reports.view');
    // The longer prefix wins, so this page needs the key the API asks for.
    expect(pagePermission('/admin/reports/instructors')).toBe('reports.instructors.view');
  });

  it('leaves the pages the API governs by role alone unmapped', () => {
    // No calendar, notification, help or account key exists, and reading certificates and live
    // classes is role-based on the API too — so none of these is filtered here.
    for (const path of ['/admin/calendar', '/admin/notifications', '/admin/help', '/admin/certificates', '/admin/certificates/templates', '/admin/live']) {
      expect(pagePermission(path), path).toBeUndefined();
    }
  });

  it('says nothing about the workspaces this system does not govern', () => {
    for (const path of ['/teach', '/teach/courses', '/home', '/superadmin', '/superadmin/admins', '/notifications']) {
      expect(pagePermission(path), path).toBeUndefined();
    }
  });
});
