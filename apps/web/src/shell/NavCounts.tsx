import { createContext, useContext, useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import type { Role } from '@syniastrolms/domain';
import { services } from '@/services';
import { personas } from '@/services/mock/fixtures/learner';
import { API_MODE } from '@/lib/apiMode';
import type { NavItem } from './navigation';

type LiveCounts = Record<string, { count?: string; label: string; value?: number; overdue?: number }>;

export const NavCountsContext = createContext<LiveCounts>({});

const REFRESH = 'astro:nav-counts';
/** Call after an action that changes a count, so badges update without waiting for navigation. */
export const refreshNavCounts = () => window.dispatchEvent(new Event(REFRESH));

/**
 * Counts that change as people work — submissions waiting for review, classes live right now — read from the
 * services and refreshed on every navigation, so grading a submission updates the badge. A count that doesn't load
 * shows nothing: the nav never guesses.
 */
export function useLiveNavCounts(role: Role): LiveCounts {
  const { pathname } = useLocation();
  const [counts, setCounts] = useState<LiveCounts>({});
  useEffect(() => {
    let cancelled = false;
    // In http mode the API scopes these from the token; the mock needs the persona's id.
    const mine = role === 'instructor' && API_MODE === 'mock' ? personas.instructor.instructorId : undefined;
    const load = () => {
      // Learners have no review queue, and the owner's sidebar has no live entry to mark.
      const reviews = role === 'student' ? Promise.resolve(undefined) : services.assignments.summary(mine).catch(() => undefined);
      const live =
        role === 'superadmin'
          ? Promise.resolve(0)
          : (role === 'student'
              ? services.live.forLearner().then((l) => l.live.length)
              : services.live.list({ view: 'live', scopeInstructorId: mine, page: 1, pageSize: 1 }).then((l) => l.counts.live)
            ).catch(() => 0);
      return Promise.all([reviews, live]).then(([s, liveNow]) => {
        if (cancelled) return;
        setCounts({
          ...(s
            ? { assignments: { count: s.toReview ? String(s.toReview) : undefined, label: `${s.toReview} to review`, value: s.toReview, overdue: s.overdue } }
            : {}),
          ...(liveNow ? { live: { count: 'Live', label: liveNow === 1 ? 'A class is live now' : `${liveNow} classes are live now`, value: liveNow } } : {}),
        });
      });
    };
    load();
    window.addEventListener(REFRESH, load);
    return () => {
      cancelled = true;
      window.removeEventListener(REFRESH, load);
    };
  }, [role, pathname]);
  return counts;
}

/** A nav item's badge, from real data only: nothing until there is a count to show. */
export function useNavItemCount(item: NavItem) {
  const live = useContext(NavCountsContext)[item.id];
  return { count: live?.count, label: live?.label };
}
