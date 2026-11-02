import { describe, expect, it } from 'vitest';
import type { LiveClass, LiveClassPhase, PermissionKey } from '@syniastrolms/domain';
import { deriveLiveClassPhase } from '@syniastrolms/domain';
import { allows } from '@/lib/adminPermissions';
import { canEditLiveClass, externalLinkOf, learnerLiveAction, meetingHostNote, staffLiveActions } from './liveRules';

const now = new Date('2026-11-02T13:00:00.000Z');
const at = (minutes: number) => new Date(now.getTime() + minutes * 60_000).toISOString();
const cls = (over: Partial<LiveClass> = {}): LiveClass => ({
  id: 'lc-1',
  courseId: 'c1',
  title: 'Ratios',
  instructorId: 'i1',
  startsAt: at(120),
  durationMin: 60,
  meeting: { kind: 'room' },
  ...over,
});
const detail = (c: LiveClass, room = { provider: 'jitsi' as const, recording: false, canStart: false }) => ({
  liveClass: c,
  phase: deriveLiveClassPhase(c, now),
  room,
});

/** `usePermissions().can` for an academy admin holding `keys`, and for an instructor (who passes by role). */
const adminWith =
  (...keys: PermissionKey[]) =>
  (key: PermissionKey) =>
    allows('admin', keys, key);
const instructor = (key: PermissionKey) => allows('instructor', [], key);

describe('editing', () => {
  it('is offered until the start time, and never for a cancelled or started class', () => {
    expect(canEditLiveClass(cls(), now)).toBe(true);
    // Inside the join window but before the start: the API still takes an edit.
    expect(canEditLiveClass(cls({ startsAt: at(10) }), now)).toBe(true);
    expect(canEditLiveClass(cls({ startsAt: at(-5) }), now)).toBe(false);
    expect(canEditLiveClass(cls({ cancelled: true }), now)).toBe(false);
    expect(canEditLiveClass(cls({ startsAt: at(10), startedAt: at(-1) }), now)).toBe(false);
  });
});

describe('the teaching view’s actions', () => {
  it('lets an instructor do everything their role allows', () => {
    const a = staffLiveActions(detail(cls()), instructor, now);
    expect(a).toMatchObject({ edit: true, cancel: true, reminders: true, remind: true, start: false, end: false, scheduleAgain: false });
  });

  it('shows an admin without live.manage no Edit, Cancel, Start or End, and without live.notify no reminders', () => {
    const none = staffLiveActions(detail(cls({ startsAt: at(5) }), { provider: 'jitsi', recording: false, canStart: true }), adminWith(), now);
    expect(Object.values(none).every((v) => v === false)).toBe(true);
    const notifyOnly = staffLiveActions(detail(cls()), adminWith('live.notify'), now);
    expect(notifyOnly).toMatchObject({ edit: false, cancel: false, reminders: true, remind: true });
    const manageOnly = staffLiveActions(detail(cls()), adminWith('live.manage'), now);
    expect(manageOnly).toMatchObject({ edit: true, cancel: true, reminders: false, remind: false });
  });

  it('offers Start only when the API says the room can open, and End while it is open', () => {
    const ready = staffLiveActions(detail(cls({ startsAt: at(5) }), { provider: 'jitsi', recording: false, canStart: true }), instructor, now);
    expect(ready.start).toBe(true);
    const open = staffLiveActions(detail(cls({ startsAt: at(-5), startedAt: at(-6) })), instructor, now);
    expect(open).toMatchObject({ rejoin: true, end: true, edit: false, cancel: false });
  });

  it('offers a cancelled class only a new one copied from it', () => {
    const a = staffLiveActions(detail(cls({ cancelled: true, cancelReason: 'Ill' })), instructor, now);
    expect(a).toMatchObject({ scheduleAgain: true, edit: false, cancel: false, reminders: false, remind: false });
  });

  it('sets no reminders once the start time has passed', () => {
    const late = staffLiveActions(detail(cls({ startsAt: at(-2) })), instructor, now);
    expect(late.reminders).toBe(false);
  });
});

describe('a learner’s next step', () => {
  const phase = (c: LiveClass): LiveClassPhase => deriveLiveClassPhase(c, now);

  it('joins an outside meeting from the join window, through the API', () => {
    const soon = cls({ startsAt: at(10), meeting: { kind: 'external', linkHost: 'zoom.us' } });
    expect(learnerLiveAction(phase(soon), soon)).toBe('join-external');
    const later = cls({ meeting: { kind: 'external', linkHost: 'zoom.us' } });
    expect(learnerLiveAction(phase(later), later)).toBe('register');
  });

  it('waits for the host of a built-in room, then joins it', () => {
    const waiting = cls({ startsAt: at(10) });
    expect(learnerLiveAction(phase(waiting), waiting)).toBe('wait-for-host');
    const started = cls({ startsAt: at(-5), startedAt: at(-6) });
    expect(learnerLiveAction(phase(started), started)).toBe('join-room');
  });

  it('watches only a recording that is ready', () => {
    const ready = cls({ startsAt: at(-180), endedAt: at(-120), recording: { durationMin: 55, availableUntil: at(60_000), status: 'ready' } });
    expect(learnerLiveAction(phase(ready), ready)).toBe('watch');
    const processing = { ...ready, recording: { ...ready.recording!, status: 'processing' as const } };
    expect(learnerLiveAction(phase(processing), processing)).toBe('none');
  });

  it('opens only an https link the join hands over', () => {
    expect(externalLinkOf({ kind: 'external', link: 'https://zoom.us/j/1' })).toBe('https://zoom.us/j/1');
    expect(() => externalLinkOf({ kind: 'external' })).toThrow(/no meeting link/);
    expect(() => externalLinkOf({ kind: 'external', link: 'javascript:alert(1)' })).toThrow(/no meeting link/);
  });

  it('says where an outside meeting opens', () => {
    expect(meetingHostNote({ meeting: { kind: 'external', linkHost: 'zoom.us' } })).toBe('Opens on zoom.us');
    expect(meetingHostNote({ meeting: { kind: 'external' } })).toBe('Opens in an outside meeting');
    expect(meetingHostNote({ meeting: { kind: 'room' } })).toBeUndefined();
  });
});
