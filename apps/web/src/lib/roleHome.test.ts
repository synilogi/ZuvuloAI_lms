import { describe, expect, it } from 'vitest';
import type { Role } from '@syniastrolms/domain';
import { homeFor, ROLE_HOME } from './roleHome';

const ROLES: Role[] = ['student', 'instructor', 'admin', 'superadmin'];

describe('role home', () => {
  it('leaves the three existing workspaces where they were', () => {
    expect(homeFor('student')).toBe('/home');
    expect(homeFor('instructor')).toBe('/teach');
    expect(homeFor('admin')).toBe('/admin');
  });

  it('gives a super admin a home of its own, not another role’s workspace', () => {
    expect(homeFor('superadmin')).toBe('/superadmin');
    expect(['/home', '/teach', '/admin']).not.toContain(homeFor('superadmin'));
  });

  // The router sends a role away from a workspace it does not own; a role with no home of its own
  // would be sent back to the learner home and bounce between the two forever (docs/11 §18.3).
  it('answers for every role, so no role can fall through to another’s home', () => {
    expect(Object.keys(ROLE_HOME).sort()).toEqual([...ROLES].sort());
    expect(new Set(ROLES.map(homeFor)).size).toBe(ROLES.length);
  });
});
