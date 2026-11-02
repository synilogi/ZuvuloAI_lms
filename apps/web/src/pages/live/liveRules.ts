import type { LiveClass, LiveClassPhase, PermissionKey } from '@syniastrolms/domain';
import { canJoin } from '@syniastrolms/domain';
import type { LiveDetail, LiveJoin } from '@/services/contracts';

/*
 * What the live-class screens offer, decided the way the API decides it (apps/api/src/routes/live.ts), so a button is
 * shown only when pressing it can work. Kept apart from the pages so the rules can be tested.
 */

const startMs = (c: Pick<LiveClass, 'startsAt'>) => new Date(c.startsAt).getTime();
const endMs = (c: Pick<LiveClass, 'startsAt' | 'durationMin'>) => startMs(c) + c.durationMin * 60_000;

/** A class can be edited until its start time, unless it was cancelled or its room was opened early. */
export const canEditLiveClass = (c: LiveClass, now: Date) => !c.cancelled && !c.startedAt && !c.endedAt && startMs(c) > now.getTime();

/** Cancelling: any class not cancelled, not started and not over yet. */
export const canCancelLiveClass = (c: LiveClass, now: Date) => !c.cancelled && !c.startedAt && !c.endedAt && endMs(c) > now.getTime();

/** Reminder times can be changed only before the class starts. */
export const canSetReminders = (c: LiveClass, now: Date) => canEditLiveClass(c, now);

/** A reminder can be sent until the class ends. */
export const canSendReminder = (c: LiveClass, now: Date) => !c.cancelled && !c.endedAt && endMs(c) > now.getTime();

export interface StaffLiveActions {
  edit: boolean;
  cancel: boolean;
  /** Open the built-in room (or rejoin it). */
  start: boolean;
  rejoin: boolean;
  end: boolean;
  /** Open an outside meeting's link. */
  openMeeting: boolean;
  reminders: boolean;
  remind: boolean;
  /** Schedule another class from this one (cancelled), or a follow-up (over). */
  scheduleAgain: boolean;
}

/**
 * The teaching view's actions for a class. `can` is `usePermissions().can`: an academy admin needs `live.manage` to run
 * classes and `live.notify` for reminders; an instructor passes by role, as the API lets them.
 */
export function staffLiveActions(d: Pick<LiveDetail, 'liveClass' | 'phase' | 'room'>, can: (key: PermissionKey) => boolean, now: Date): StaffLiveActions {
  const c = d.liveClass;
  const manage = can('live.manage');
  const notify = can('live.notify');
  const builtIn = c.meeting?.kind !== 'external';
  const roomOpen = builtIn && d.phase === 'live' && !!c.startedAt;
  const over = d.phase === 'ended' || d.phase === 'recording-expired';
  return {
    edit: manage && canEditLiveClass(c, now),
    cancel: manage && (d.phase === 'upcoming' || d.phase === 'starting-soon') && canCancelLiveClass(c, now),
    start: manage && builtIn && !!d.room?.canStart,
    rejoin: manage && roomOpen,
    end: manage && roomOpen,
    openMeeting: manage && !builtIn && !!c.meeting?.link && (d.phase === 'live' || d.phase === 'starting-soon'),
    reminders: notify && canSetReminders(c, now),
    remind: notify && canSendReminder(c, now) && (d.phase === 'upcoming' || d.phase === 'starting-soon'),
    scheduleAgain: manage && (over || d.phase === 'cancelled'),
  };
}

/** What a learner can do with a class right now. */
export type LearnerLiveAction = 'join-room' | 'join-external' | 'wait-for-host' | 'register' | 'watch' | 'none';

export function learnerLiveAction(phase: LiveClassPhase, c: LiveClass): LearnerLiveAction {
  if (canJoin(phase, c)) return c.meeting?.kind === 'external' ? 'join-external' : 'join-room';
  if (phase === 'starting-soon' && c.meeting?.kind === 'room' && !c.startedAt) return 'wait-for-host';
  if (phase === 'upcoming') return 'register';
  if (phase === 'ended' && c.recording?.status === 'ready') return 'watch';
  return 'none';
}

/** The outside meeting's link from a join answer, or why there is none to open. */
export function externalLinkOf(join: LiveJoin): string {
  if (join.kind !== 'external') throw new Error('This class runs in the built-in room. Join it from the class page.');
  if (!join.link || !/^https:\/\//.test(join.link)) throw new Error('This class has no meeting link yet. Ask your instructor for it.');
  return join.link;
}

/** "Opens on zoom.us", from the host the API names in place of an outside meeting's link. */
export const meetingHostNote = (c: Pick<LiveClass, 'meeting'>) =>
  c.meeting?.kind === 'external' ? (c.meeting.linkHost ? `Opens on ${c.meeting.linkHost}` : 'Opens in an outside meeting') : undefined;
