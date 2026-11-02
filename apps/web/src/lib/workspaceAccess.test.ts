import { describe, expect, it } from 'vitest';
import type { Role } from '@syniastrolms/domain';
import { workspaceRedirect } from './workspaceAccess';

const SUPERADMIN_PATHS = [
  '/superadmin',
  '/superadmin/admins',
  '/superadmin/users',
  '/superadmin/audit',
  '/superadmin/system',
  // The platform's subscription screens: a Tenant Admin never reaches them (SAAS-015).
  '/superadmin/subscriptions',
  '/superadmin/subscriptions/plans',
  '/superadmin/subscriptions/plans/new',
  '/superadmin/subscriptions/subscribers',
  '/superadmin/subscriptions/subscribers/s1',
  '/superadmin/subscriptions/billing',
  '/superadmin/subscriptions/academies',
  '/superadmin/subscriptions/academies/t1',
  '/superadmin/subscriptions/tax-rules',
  '/superadmin/subscriptions/webhooks',
];
const OTHER_ROLES: Role[] = ['student', 'instructor', 'admin'];

const allowed = (role: Role, path: string) => workspaceRedirect(role, path) === undefined;

describe('the platform workspace', () => {
  it('lets a super admin into every one of its pages', () => {
    for (const path of SUPERADMIN_PATHS) expect(allowed('superadmin', path), path).toBe(true);
  });

  it('turns every academy role away, the academy admin included', () => {
    for (const path of SUPERADMIN_PATHS) {
      expect(workspaceRedirect('admin', path), path).toBe('/admin');
      expect(workspaceRedirect('instructor', path), path).toBe('/teach');
      expect(workspaceRedirect('student', path), path).toBe('/home');
    }
  });

  it('lets the platform owner run the workspace at /admin, and keeps it out of the teaching and learner areas (docs/16, D-PLAT-03)', () => {
    for (const path of ['/admin', '/admin/settings/general']) expect(workspaceRedirect('superadmin', path), path).toBeUndefined();
    for (const path of ['/teach', '/teach/courses', '/home', '/my-learning', '/certificates']) {
      expect(workspaceRedirect('superadmin', path), path).toBe('/superadmin');
    }
  });

  it('does not confuse /superadmin with /admin', () => {
    expect(allowed('admin', '/admin')).toBe(true);
    expect(allowed('superadmin', '/superadmin')).toBe(true);
    expect(workspaceRedirect('admin', '/superadmin')).toBe('/admin');
  });
});

describe('the academy workspaces are unchanged', () => {
  it('keeps the admin everywhere it already was', () => {
    for (const path of ['/admin', '/admin/courses', '/admin/settings', '/admin/reports/learners', '/teach', '/teach/students']) {
      expect(allowed('admin', path), path).toBe(true);
    }
  });

  it('keeps the instructor in the teaching workspace and out of the rest', () => {
    expect(allowed('instructor', '/teach')).toBe(true);
    expect(allowed('instructor', '/teach/assignments')).toBe(true);
    expect(workspaceRedirect('instructor', '/admin')).toBe('/teach');
    expect(workspaceRedirect('instructor', '/home')).toBe('/teach');
  });

  it('keeps the learner in the learner areas and out of the rest', () => {
    for (const path of ['/home', '/my-learning/in-progress', '/learn/course-1', '/assignments', '/assessments', '/certificates', '/live']) {
      expect(allowed('student', path), path).toBe(true);
    }
    expect(workspaceRedirect('student', '/admin')).toBe('/home');
    expect(workspaceRedirect('student', '/teach')).toBe('/home');
  });

  it('leaves the shared pages open to everyone signed in', () => {
    for (const role of [...OTHER_ROLES, 'superadmin' as const]) {
      expect(allowed(role, '/notifications'), role).toBe(true);
      expect(allowed(role, '/help'), role).toBe(true);
      expect(allowed(role, '/explore'), role).toBe(true);
    }
  });
});
