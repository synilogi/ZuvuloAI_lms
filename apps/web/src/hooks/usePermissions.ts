import { useCallback, useMemo } from 'react';
import type { PermissionKey } from '@syniastrolms/domain';
import { useSession } from '@/providers/SessionProvider';
import { allows, pagePermission, permissionsOf } from '@/lib/adminPermissions';

/**
 * What the signed-in account may do, from the session the app already holds — the permissions the
 * API put on `/auth/me`, read once per render rather than fetched again.
 *
 * `can` answers for the academy admin workspace only; every other role gets `true`, because their
 * access comes from their role and scope. Hiding is UX: the API refuses the call regardless.
 */
export function usePermissions() {
  const { user, role } = useSession();
  const permissions = useMemo(() => permissionsOf(user), [user]);
  const can = useCallback((key?: PermissionKey) => allows(role, permissions, key), [role, permissions]);
  const canOpen = useCallback((pathname: string) => can(pagePermission(pathname)), [can]);
  return { permissions, can, canOpen };
}
