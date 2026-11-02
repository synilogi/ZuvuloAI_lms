import type { ID, ISODateTime } from './catalog';

/** What a calendar entry represents. Live classes and assignment deadlines come from their own records. */
export type CalendarEventType = 'live' | 'assignment' | 'quiz' | 'milestone' | 'reminder';

export const CALENDAR_EVENT_TYPES: CalendarEventType[] = ['live', 'assignment', 'quiz', 'milestone', 'reminder'];

/** timed — a start and a length · moment — a point in time, such as a deadline · all-day — the whole date */
export type CalendarTiming = 'timed' | 'moment' | 'all-day';

export type MilestoneKind = 'cohort-starts' | 'chapter-release' | 'enrolment-closes' | 'cohort-ends' | 'course-launch';

/** me — only the person who set it · learners — the course's learners are reminded too */
export type ReminderAudience = 'me' | 'learners';

export interface CalendarEvent {
  id: ID;
  type: CalendarEventType;
  title: string;
  description?: string;
  timing: CalendarTiming;
  startsAt: ISODateTime;
  /** Timed events only. */
  durationMin?: number;
  courseId?: ID;
  chapterId?: ID;
  instructorId?: ID;
  /** Quiz events: the quiz learners take. */
  quizId?: ID;
  milestone?: MilestoneKind;
  /** Reminders only. */
  audience?: ReminderAudience;
  /** Reminders belong to the person who set them. */
  ownerId?: ID;
  /** Minutes before the start that a notification goes out; undefined for none. */
  notifyMin?: number;
  done?: boolean;
  cancelled?: boolean;
  /** Derived events are changed where they live, not in the calendar. */
  source?: { kind: 'live-class' | 'assignment'; id: ID };
}

export type CalendarEventInput = Pick<
  CalendarEvent,
  'type' | 'title' | 'description' | 'timing' | 'startsAt' | 'durationMin' | 'courseId' | 'chapterId' | 'quizId' | 'milestone' | 'audience' | 'notifyMin'
>;

export interface CalendarEventIssue {
  field: 'type' | 'title' | 'course' | 'quiz' | 'milestone' | 'chapter' | 'startsAt' | 'duration';
  message: string;
}

const IST_OFFSET_MS = 330 * 60_000;
/** The IST calendar date of a moment, YYYY-MM-DD. */
export const istDate = (at: Date | string) => new Date(new Date(at).getTime() + IST_OFFSET_MS).toISOString().slice(0, 10);

/** When the event is over: the end of a timed event, the moment itself, or the end of the day. */
export function calendarEventEnd(event: Pick<CalendarEvent, 'timing' | 'startsAt' | 'durationMin'>) {
  const start = new Date(event.startsAt).getTime();
  if (event.timing === 'timed') return new Date(start + (event.durationMin ?? 0) * 60_000);
  if (event.timing === 'all-day') return new Date(new Date(`${istDate(event.startsAt)}T00:00:00+05:30`).getTime() + 86_400_000);
  return new Date(start);
}

/** What an event added in the calendar needs. */
export function validateCalendarEvent(input: CalendarEventInput, now: Date): CalendarEventIssue[] {
  const issues: CalendarEventIssue[] = [];
  if (input.type === 'live') issues.push({ field: 'type', message: 'Live classes are scheduled from Live classes.' });
  if (input.type === 'assignment') issues.push({ field: 'type', message: 'Assignment deadlines are set on the assignment.' });
  if (input.title.trim().length < 3) issues.push({ field: 'title', message: 'Give the event a title of at least 3 characters.' });
  const needsCourse = input.type === 'quiz' || input.type === 'milestone' || (input.type === 'reminder' && input.audience === 'learners');
  if (needsCourse && !input.courseId) {
    issues.push({
      field: 'course',
      message: input.type === 'reminder' ? 'Choose the course whose learners you’re reminding.' : 'Choose the course this event belongs to.',
    });
  }
  if (input.type === 'quiz' && !input.quizId) issues.push({ field: 'quiz', message: 'Choose the quiz learners take.' });
  if (input.type === 'milestone' && !input.milestone) issues.push({ field: 'milestone', message: 'Choose what kind of milestone this is.' });
  if (input.type === 'milestone' && input.milestone === 'chapter-release' && !input.chapterId)
    issues.push({ field: 'chapter', message: 'Choose the chapter that opens.' });

  const start = new Date(input.startsAt).getTime();
  if (Number.isNaN(start)) {
    issues.push({ field: 'startsAt', message: input.timing === 'all-day' ? 'Choose a date.' : 'Choose a date and time.' });
  } else if (input.timing === 'all-day' ? istDate(input.startsAt) < istDate(now) : start <= now.getTime()) {
    issues.push({
      field: 'startsAt',
      message: input.timing === 'all-day' ? 'That date has already passed. Choose a later one.' : 'That time has already passed. Choose a later time.',
    });
  }
  if (input.timing === 'timed' && !(input.durationMin !== undefined && input.durationMin >= 5 && input.durationMin <= 720)) {
    issues.push({ field: 'duration', message: 'An event runs between 5 minutes and 12 hours — check the end time.' });
  }
  return issues;
}
