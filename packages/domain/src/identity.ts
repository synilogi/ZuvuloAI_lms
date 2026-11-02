import type { ID } from './catalog';
import type { PermissionKey } from './permission';

export type Role = 'student' | 'instructor' | 'admin' | 'superadmin';

export interface UserProfile {
  id: ID;
  name: string;
  email: string;
  role: Role;
  /** Context under the name — "Beginner · Rank I", "Senior Maths Faculty", "Academy admin". */
  descriptor: string;
  /** Set when the user teaches — links the account to an instructor profile. */
  instructorId?: ID;
  /**
   * The academy permissions this account holds, read from the database on every session response.
   * Only an `admin` can hold any; every other role answers with an empty list. Absent means the
   * response did not carry them — treat that as none rather than as all.
   */
  permissions?: PermissionKey[];
}
