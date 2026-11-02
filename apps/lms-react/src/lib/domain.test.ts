import { FEATURE_KEYS, PERMISSION_KEYS, type PermissionKey, type Role } from '@syniastrolms/domain';
import { describe, expect, it } from 'vitest';

// REACT-000 acceptance: the shared domain package compiles and resolves in this app. Later modules rely on its
// catalogues instead of re-declaring permission, feature or limit keys.
describe('@syniastrolms/domain', () => {
  it('exposes the permission and feature catalogues', () => {
    const role: Role = 'admin';
    const key: PermissionKey = 'settings.view';
    expect(role).toBe('admin');
    expect(PERMISSION_KEYS).toContain(key);
    expect(PERMISSION_KEYS).toHaveLength(24);
    expect(FEATURE_KEYS).toContain('courses.manage');
  });
});
