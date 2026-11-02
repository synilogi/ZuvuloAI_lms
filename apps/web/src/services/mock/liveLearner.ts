import type { LiveClass } from '@syniastrolms/domain';

/** The site an outside meeting is on, for a learner's screen; never the link itself. */
function hostOf(link: string | undefined) {
  try {
    return link ? new URL(link).hostname : undefined;
  } catch {
    return undefined;
  }
}

/**
 * A class as a learner may see it, the way the API's `forLearner` shapes it (apps/api/src/lib/mapLive.ts): everything
 * but an outside meeting's link, which only `join` hands over, inside the join window. `linkHost` says where it opens.
 */
export function learnerLiveClass(live: LiveClass): LiveClass {
  if (live.meeting?.kind !== 'external') return { ...live, meeting: { kind: live.meeting?.kind ?? 'room' } };
  const linkHost = hostOf(live.meeting.link);
  return { ...live, meeting: { kind: 'external', ...(linkHost ? { linkHost } : {}) } };
}
