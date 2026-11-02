import type { ID, ISODateTime } from './catalog';

export interface LiveClass {
  id: ID;
  courseId: ID;
  title: string;
  instructorId: ID;
  startsAt: ISODateTime;
  durationMin: number;
  capacity?: number;
  /** Learners who have registered for an upcoming class. */
  registered?: number;
  /** Learners who have joined the room so far, while the class is live. */
  attending?: number;
  cancelled?: boolean;
  /** When the host opened the built-in room. A room class is live only from this moment. */
  startedAt?: ISODateTime;
  /** When the host closed the room (or the platform closed one left open). */
  endedAt?: ISODateTime;
  /** `ready` once the video service has delivered the recording; `processing` until then. */
  recording?: { durationMin: number; availableUntil: ISODateTime; status?: 'processing' | 'ready' };
  description?: string;
  agenda?: AgendaItem[];
  /** enrolled — learners of the course · cohort — invited cohort only · public — open to any signed-in learner */
  visibility?: LiveVisibility;
  /** The academy's own room, or a link to an outside meeting. */
  /**
   * `link` is the outside meeting's address. Learners never get it in a class listing — only from joining, inside the
   * join window — and see `linkHost` (e.g. `zoom.us`) instead, to know where they will be taken.
   */
  meeting?: { kind: 'room' | 'external'; link?: string; linkHost?: string };
  /** Minutes before the start that registrants are reminded. */
  reminders?: number[];
  /** Learners who joined, once the class has ended. */
  attended?: number;
  cancelReason?: string;
  chapterId?: ID;
}

export type LiveVisibility = 'enrolled' | 'cohort' | 'public';

export interface AgendaItem {
  title: string;
  minutes: number;
}

export type LiveClassInput = Pick<
  LiveClass,
  | 'courseId'
  | 'title'
  | 'instructorId'
  | 'startsAt'
  | 'durationMin'
  | 'capacity'
  | 'description'
  | 'agenda'
  | 'visibility'
  | 'meeting'
  | 'reminders'
  | 'chapterId'
>;

export interface LiveClassIssue {
  field: 'title' | 'course' | 'instructor' | 'startsAt' | 'duration' | 'capacity' | 'meeting' | 'agenda';
  message: string;
}

/** What a schedulable class needs. `registered` guards shrinking capacity below the people already coming. */
export function validateLiveClass(input: LiveClassInput, now: Date, registered = 0): LiveClassIssue[] {
  const issues: LiveClassIssue[] = [];
  if (input.title.trim().length < 3) issues.push({ field: 'title', message: 'Give the class a title of at least 3 characters.' });
  if (!input.courseId) issues.push({ field: 'course', message: 'Choose the course this class belongs to.' });
  if (!input.instructorId) issues.push({ field: 'instructor', message: 'Choose who teaches the class.' });
  const start = new Date(input.startsAt).getTime();
  if (Number.isNaN(start)) issues.push({ field: 'startsAt', message: 'Choose a date and start time.' });
  else if (start <= now.getTime()) issues.push({ field: 'startsAt', message: 'The start time has already passed. Choose a later time.' });
  if (!(input.durationMin >= 15 && input.durationMin <= 240))
    issues.push({ field: 'duration', message: 'A class runs between 15 minutes and 4 hours — check the end time.' });
  // `null` (or left out) is no limit.
  if (input.capacity != null && input.capacity < Math.max(1, registered)) {
    issues.push({
      field: 'capacity',
      message: registered ? `${registered} learners have already registered — capacity can’t be lower.` : 'Capacity must be at least 1.',
    });
  }
  if (input.meeting?.kind === 'external' && !/^https:\/\/\S+\.\S+/.test(input.meeting.link ?? ''))
    issues.push({ field: 'meeting', message: 'Paste the full meeting link, starting with https://' });
  const agendaMinutes = (input.agenda ?? []).reduce((n, a) => n + (a.minutes || 0), 0);
  if (input.durationMin >= 15 && agendaMinutes > input.durationMin)
    issues.push({ field: 'agenda', message: `The agenda runs ${agendaMinutes} minutes — longer than the class.` });
  return issues;
}

export type LiveClassPhase = 'upcoming' | 'starting-soon' | 'live' | 'ended' | 'recording-expired' | 'cancelled';

/** Joining opens this many minutes before the start time; a host may open the room from then too. */
export const JOIN_WINDOW_MIN = 15;

/** A room the host forgot to close is treated as ended this long after its scheduled end. */
export const ROOM_OVERRUN_MIN = 60;

/**
 * Where a class stands. An outside meeting (Meet, Zoom…) runs on the clock, since the academy can't see
 * into it. The built-in room runs on the host: it is live from the moment they start it until they end
 * it, and "starting soon" while learners wait for them — never live on the clock alone.
 */
export function deriveLiveClassPhase(cls: LiveClass, now: Date): LiveClassPhase {
  if (cls.cancelled) return 'cancelled';
  const start = new Date(cls.startsAt).getTime();
  const end = start + cls.durationMin * 60_000;
  const t = now.getTime();
  const afterwards = (): LiveClassPhase => (!cls.recording || t > new Date(cls.recording.availableUntil).getTime() ? 'recording-expired' : 'ended');
  // Ended is the server's word, whatever the viewer's clock says: a device running behind must not keep
  // offering Join to a class its host has closed. The server only ever stamps the past.
  if (cls.endedAt) return afterwards();
  if (cls.meeting?.kind === 'room' || cls.startedAt) {
    if (cls.startedAt) return t < end + ROOM_OVERRUN_MIN * 60_000 ? 'live' : afterwards();
    if (t < start - JOIN_WINDOW_MIN * 60_000) return 'upcoming';
    // The host hasn't opened the room yet; until the scheduled end they still may.
    if (t < end) return 'starting-soon';
    return afterwards();
  }
  if (t < start - JOIN_WINDOW_MIN * 60_000) return 'upcoming';
  if (t < start) return 'starting-soon';
  if (t < end) return 'live';
  return afterwards();
}

/**
 * Whether a learner can go in. An outside link opens from the join window; the built-in room only once
 * the host has started it.
 */
export function canJoin(phase: LiveClassPhase, cls?: Pick<LiveClass, 'meeting' | 'startedAt'>) {
  if (cls?.meeting?.kind === 'room' && !cls.startedAt) return false;
  return phase === 'starting-soon' || phase === 'live';
}

/** Whether the host can open the built-in room: from the join window until the scheduled end, once. */
export function canStartRoom(cls: LiveClass, now: Date) {
  if (cls.cancelled || cls.startedAt || cls.endedAt || cls.meeting?.kind !== 'room') return false;
  const phase = deriveLiveClassPhase(cls, now);
  return phase === 'starting-soon';
}
