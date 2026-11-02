import { describe, expect, it } from 'vitest';
import { isPermissionKey, PERMISSION_GROUPS, PERMISSION_GROUP_LABEL, PERMISSION_KEYS, PERMISSIONS, permissionsInGroup, type PermissionKey } from './permission';

describe('the permission catalogue', () => {
  it('describes every key it offers', () => {
    // The Record is exhaustive over PermissionKey, so this also fails if a key is ever added without
    // somewhere to explain it.
    for (const key of PERMISSION_KEYS) {
      const meta = PERMISSIONS[key];
      expect(meta.label.length, key).toBeGreaterThan(2);
      expect(meta.description.length, key).toBeGreaterThan(10);
      expect(PERMISSION_GROUPS, key).toContain(meta.group);
    }
    expect(new Set(PERMISSION_KEYS).size).toBe(PERMISSION_KEYS.length);
    expect(PERMISSION_KEYS).toHaveLength(24);
  });

  it('names every group it puts a key in', () => {
    for (const group of PERMISSION_GROUPS) {
      expect(PERMISSION_GROUP_LABEL[group].length, group).toBeGreaterThan(2);
      expect(permissionsInGroup(group).length, group).toBeGreaterThan(0);
    }
    expect(PERMISSION_KEYS.flatMap((k) => (PERMISSION_GROUPS.includes(PERMISSIONS[k].group) ? [] : [k]))).toEqual([]);
  });

  it('covers the capabilities the audit identified, and only those', () => {
    expect(PERMISSION_KEYS).toEqual([
      'catalog.view',
      'catalog.edit',
      'catalog.publish',
      'catalog.archive',
      'catalog.categories.manage',
      'assessment.view',
      'assessment.edit',
      'assessment.grade',
      'learners.view',
      'learners.enroll',
      'learners.suspend',
      'learners.message',
      'instructors.view',
      'instructors.manage',
      'instructors.status',
      'certificates.issue',
      'certificates.revoke',
      'certificates.templates.manage',
      'live.manage',
      'live.notify',
      'reports.view',
      'reports.instructors.view',
      'settings.view',
      'settings.edit',
    ]);
  });

  // The academy's vocabulary only: nothing here may describe the platform, another tenant, or a
  // capability the application does not have.
  it('offers no key for anything out of scope', () => {
    const forbidden = /(^|\.)(tenant|organisation|organization|academy|subscription|billing|plan|role|delete|export|superadmin|platform|impersonate)(\.|$)/;
    for (const key of PERMISSION_KEYS) expect(forbidden.test(key), key).toBe(false);
  });

  it('recognises its own keys and nothing else', () => {
    expect(isPermissionKey('catalog.publish')).toBe(true);
    expect(isPermissionKey('catalog.destroy')).toBe(false);
    expect(isPermissionKey('toString')).toBe(false);
    const fromDatabase: string = 'settings.edit';
    if (isPermissionKey(fromDatabase)) {
      const narrowed: PermissionKey = fromDatabase;
      expect(PERMISSIONS[narrowed].group).toBe('settings');
    }
  });
});
