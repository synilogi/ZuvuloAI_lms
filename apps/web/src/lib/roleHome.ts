import type { Role } from '@syniastrolms/domain';

/**
 * Where each role lands when the app has to send it "home".
 *
 * Exhaustive over `Role` on purpose: a role that fell through to the learner home would be bounced
 * straight back out by the workspace guards in the router, looping forever (docs/11 §18.3). The
 * Super Admin workspace itself is not built yet — `/superadmin` resolves to the shell's not-found
 * page, which is a dead end rather than another redirect.
 */
export const ROLE_HOME: Record<Role, string> = {
  student: '/home',
  instructor: '/teach',
  admin: '/admin',
  superadmin: '/superadmin',
};

export const homeFor = (role: Role) => ROLE_HOME[role];
