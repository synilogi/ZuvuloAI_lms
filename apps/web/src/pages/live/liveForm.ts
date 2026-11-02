import type { LiveClass, LiveClassInput, LiveClassIssue } from '@syniastrolms/domain';
import { pad2 } from '@/lib/format';
import type { LiveClassWrite } from '@/services/contracts';

/*
 * The live-class editor's rules, kept apart from the page so they can be tested: reading a class's start as an IST
 * date and time, writing them back as the same moment, and building the body the API takes.
 */

/** The academy's zone. Every class is scheduled in it, whatever the device's own zone. */
export const IST = 'Asia/Kolkata';
const DAY_MS = 86_400_000;

const istParts = new Intl.DateTimeFormat('en-CA', {
  timeZone: IST,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  hourCycle: 'h23',
});

/** A moment as the date and time a wall clock in India shows — `{ date: 'YYYY-MM-DD', time: 'HH:MM' }`. */
export function istWallClock(at: string | Date): { date: string; time: string } {
  const parts = Object.fromEntries(istParts.formatToParts(new Date(at)).map((p) => [p.type, p.value]));
  return { date: `${parts.year}-${parts.month}-${parts.day}`, time: `${parts.hour}:${parts.minute}` };
}

/** An IST date and time as the moment the API takes: an ISO date-time with its `+05:30` offset. */
export const istIso = (date: string, time: string) => `${date}T${time}:00+05:30`;

/** The IST date `days` after `now`. */
export const istDateAfter = (now: Date, days: number) => istWallClock(new Date(now.getTime() + days * DAY_MS)).date;

export const toMinutes = (hhmm: string) => {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
};
export const fromMinutes = (total: number) => `${pad2(Math.floor(total / 60) % 24)}:${pad2(total % 60)}`;

export type MeetingKind = 'room' | 'external';
export type Visibility = NonNullable<LiveClass['visibility']>;

export interface LiveForm {
  title: string;
  description: string;
  courseId: string;
  chapterId: string;
  instructorId: string;
  date: string;
  start: string;
  end: string;
  meetingKind: MeetingKind;
  link: string;
  capacity: string;
  visibility: Visibility;
  agenda: { title: string; minutes: number }[];
  reminders: number[];
}

const DEFAULT_AGENDA = [
  { title: 'Welcome and questions from last week', minutes: 10 },
  { title: '', minutes: 35 },
  { title: 'Open questions', minutes: 15 },
];

/**
 * The form for a class: the class being edited, or a new one — blank, or copied from `template` (a cancelled class
 * being run again) with a fresh date. A copy never keeps the "cohort" setting, which nothing enforces.
 */
export function toLiveForm(liveClass: LiveClass | null, opts: { now: Date; courseId: string; instructorId: string; template?: LiveClass | null }): LiveForm {
  const source = liveClass ?? opts.template ?? null;
  const at = source ? istWallClock(source.startsAt) : null;
  const start = at?.time ?? '19:00';
  return {
    title: source?.title ?? '',
    description: source?.description ?? '',
    courseId: source?.courseId ?? opts.courseId,
    chapterId: source?.chapterId ?? '',
    instructorId: source?.instructorId ?? opts.instructorId,
    // A new class starts tomorrow by default (in IST).
    date: liveClass && at ? at.date : istDateAfter(opts.now, 1),
    start,
    end: fromMinutes(toMinutes(start) + (source?.durationMin ?? 60)),
    meetingKind: source?.meeting?.kind ?? 'room',
    link: source?.meeting?.link ?? '',
    capacity: source ? (source.capacity !== undefined ? String(source.capacity) : '') : '80',
    visibility: liveClass?.visibility ?? (source?.visibility === 'public' ? 'public' : 'enrolled'),
    agenda: source?.agenda?.length ? source.agenda.map((a) => ({ title: a.title, minutes: a.minutes })) : DEFAULT_AGENDA,
    reminders: source?.reminders ?? [1440, 60, 15],
  };
}

/**
 * The body the API takes. On an edit a field emptied out is sent as `null`, which clears it — left out, the API keeps
 * what was there, so a removed description or capacity would never be saved.
 */
export function buildLivePayload(form: LiveForm, editing: boolean): LiveClassWrite {
  const cleared = editing ? null : undefined;
  return {
    title: form.title.trim(),
    description: form.description.trim() || cleared,
    courseId: form.courseId,
    chapterId: form.chapterId || cleared,
    instructorId: form.instructorId,
    startsAt: istIso(form.date, form.start),
    durationMin: toMinutes(form.end) - toMinutes(form.start),
    capacity: form.capacity.trim() === '' ? cleared : Number(form.capacity),
    visibility: form.visibility,
    meeting: form.meetingKind === 'room' ? { kind: 'room' } : { kind: 'external', link: form.link.trim() },
    agenda: form.agenda.filter((a) => a.title.trim()).map((a) => ({ title: a.title.trim(), minutes: a.minutes })),
    reminders: form.reminders,
  };
}

/** The same body as the shared validator reads it: a cleared field is simply not set. */
export const forValidation = (payload: LiveClassWrite): LiveClassInput => ({
  ...payload,
  description: payload.description ?? undefined,
  chapterId: payload.chapterId ?? undefined,
  capacity: payload.capacity ?? undefined,
});

/** The editor's input id for each field the validator (or the server) names. */
export const LIVE_FIELD: Record<LiveClassIssue['field'], string> = {
  title: 'live-title',
  course: 'live-course',
  instructor: 'live-instructor',
  startsAt: 'live-date',
  duration: 'live-end',
  capacity: 'live-capacity',
  meeting: 'live-link',
  agenda: 'live-agenda',
};

/** The server's per-field issues (`ServiceError.issues`), placed beside the editor's inputs. Unknown fields are dropped. */
export function serverFieldIssues(err: unknown): { field: string; message: string }[] {
  const issues = (err as { issues?: { field: string; message: string }[] } | null)?.issues ?? [];
  return issues.flatMap((i) => (i.field in LIVE_FIELD ? [{ field: LIVE_FIELD[i.field as LiveClassIssue['field']], message: i.message }] : []));
}
