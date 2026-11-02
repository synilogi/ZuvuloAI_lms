import type { Role } from '@syniastrolms/domain';

import { homeFor } from './roleHome';

/** Learner-only areas; staff who wander in are sent to their own workspace. */
const LEARNER_PREFIXES = ['/home', '/my-learning', '/learn', '/assignments', '/assessments', '/certificates', '/live', '/purchases', '/affiliate'];

const startsWithAny = (path: string, prefixes: string[]) => prefixes.some((p) => path === p || path.startsWith(`${p}/`));

/**
 * Which workspace a path belongs to, and who may be in it. Returns where to send the account, or
 * `undefined` when it may stay.
 *
 * Each workspace names the roles it serves rather than excluding the ones it does not, so a role
 * added later is refused by default instead of quietly inheriting somebody else's screens. The
 * platform area is its own workspace: an academy admin is turned away from it exactly like a learner.
 */
export function workspaceRedirect(role: Role, path: string): string | undefined {
  // The platform's owner runs the workspace through the same screens as a staff admin (docs/16, D-PLAT-03).
  if (startsWithAny(path, ['/admin']) && role !== 'admin' && role !== 'superadmin') return homeFor(role);
  if (startsWithAny(path, ['/superadmin']) && role !== 'superadmin') return homeFor(role);
  // The teaching workspace is for the people who teach and the admins who oversee them.
  if (startsWithAny(path, ['/teach']) && role !== 'instructor' && role !== 'admin') return homeFor(role);
  if (startsWithAny(path, LEARNER_PREFIXES) && role !== 'student') return homeFor(role);
  return undefined;
}
