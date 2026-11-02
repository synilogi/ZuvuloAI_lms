import type { LiveClass, AgendaItem } from '@syniastrolms/domain';

import { readJson } from './json.js';

/** Only what a client may see of a recording — never the provider's download link or the kept file's name. */
function publicRecording(json: string | null): LiveClass['recording'] {
  const rec = readJson<{ durationMin?: number; availableUntil?: string; status?: 'processing' | 'ready' | 'failed' } | null>(json, null);
  if (!rec?.availableUntil || rec.status === 'failed') return undefined;
  // A recording with no status predates the kept file (sample data): listed, but there is nothing to play.
  return { durationMin: rec.durationMin ?? 0, availableUntil: rec.availableUntil, ...(rec.status ? { status: rec.status } : {}) };
}

export function mapLive(row: {
  id: string;
  courseId: string;
  title: string;
  instructorId: string;
  startsAt: Date;
  durationMin: number;
  capacity: number | null;
  cancelled: boolean;
  cancelReason: string | null;
  startedAt?: Date | null;
  endedAt?: Date | null;
  recordingJson: string | null;
  description: string | null;
  agendaJson: string;
  visibility: string;
  meetingJson: string;
  remindersJson: string;
  chapterId: string | null;
  registrations?: { attended: boolean | null }[];
}): LiveClass {
  return {
    id: row.id,
    courseId: row.courseId,
    title: row.title,
    instructorId: row.instructorId,
    startsAt: row.startsAt.toISOString(),
    durationMin: row.durationMin,
    capacity: row.capacity ?? undefined,
    registered: row.registrations?.length,
    // Joined so far, while the room is open; once it has ended the same people are `attended`.
    attending: row.startedAt && !row.endedAt ? (row.registrations?.filter((r) => r.attended === true).length ?? undefined) : undefined,
    attended: row.registrations?.filter((r) => r.attended === true).length,
    cancelled: row.cancelled || undefined,
    startedAt: row.startedAt?.toISOString(),
    endedAt: row.endedAt?.toISOString(),
    recording: publicRecording(row.recordingJson),
    description: row.description ?? undefined,
    agenda: readJson<AgendaItem[]>(row.agendaJson, []),
    visibility: row.visibility as LiveClass['visibility'],
    meeting: readJson(row.meetingJson, { kind: 'room' as const }),
    reminders: readJson<number[]>(row.remindersJson, []),
    cancelReason: row.cancelReason ?? undefined,
    chapterId: row.chapterId ?? undefined,
  };
}

/** The site an outside meeting is on, for a learner's screen; never the link itself. */
const hostOf = (link: string | undefined) => {
  try {
    return link ? new URL(link).hostname : undefined;
  } catch {
    return undefined;
  }
};

/**
 * A class as a learner may see it in a listing or on its page: everything but the outside meeting's link, which is
 * handed out only by `POST /live/:id/join` — to a learner allowed into the class, inside its join window.
 */
export function forLearner(live: LiveClass): LiveClass {
  if (live.meeting?.kind !== 'external') return { ...live, meeting: { kind: live.meeting?.kind ?? 'room' } };
  return { ...live, meeting: { kind: 'external', ...(hostOf(live.meeting.link) ? { linkHost: hostOf(live.meeting.link) } : {}) } };
}
