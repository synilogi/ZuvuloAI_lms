import { useMemo } from 'react';
import { useLocation } from 'react-router-dom';
import type { DashboardScope } from '@syniastrolms/domain';
import { API_MODE } from '@/lib/apiMode';
import { useSession } from '@/providers/SessionProvider';
import { personas } from '@/services/mock/fixtures/learner';

export type WorkspaceBase = '/admin' | '/teach';

/**
 * Management screens serve two workspaces from one set of components: the academy admin
 * (`/admin`, everything) and the teaching workspace (`/teach`, scoped to the signed-in instructor).
 * In http mode the instructor id is the signed-in account's; the API derives the real scope from the
 * token regardless, so this id only labels the workspace.
 */
export function useWorkspace() {
  const { pathname } = useLocation();
  const { user } = useSession();
  const sessionInstructorId = user.instructorId;
  return useMemo(() => {
    const base: WorkspaceBase = pathname === '/teach' || pathname.startsWith('/teach/') ? '/teach' : '/admin';
    const instructorId = API_MODE === 'http' ? (sessionInstructorId ?? '') : personas.instructor.instructorId!;
    const scope: DashboardScope = base === '/teach' ? { kind: 'instructor', instructorId } : { kind: 'academy' };
    return {
      base,
      scope,
      isTeaching: base === '/teach',
      /** Instructor whose work the workspace is limited to, if any. */
      instructorId: base === '/teach' ? instructorId : undefined,
      to: (path: string) => `${base}${path.startsWith('/') ? path : `/${path}`}`,
    };
  }, [pathname, sessionInstructorId]);
}
