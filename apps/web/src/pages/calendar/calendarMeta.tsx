import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { BellSimple, CheckCircle, ClipboardText, Exam, FlagBanner, Timer, VideoCamera, type Icon } from '@phosphor-icons/react';
import type { CalendarEvent, CalendarEventType, MilestoneKind } from '@syniastrolms/domain';
import { calendarEventEnd } from '@syniastrolms/domain';
import { formatTime } from '@/lib/format';
import { Badge } from '@/components/ui/Badge/Badge';
import { StatusBadge } from '@/components/lms/status/Status';
import type { CalendarRow } from '@/services';
import styles from './Calendar.module.css';

export const TYPE_META: Record<CalendarEventType, { label: string; plural: string; icon: Icon }> = {
  live: { label: 'Live class', plural: 'Live classes', icon: VideoCamera },
  assignment: { label: 'Assignment due', plural: 'Assignments', icon: ClipboardText },
  quiz: { label: 'Quiz', plural: 'Quizzes', icon: Exam },
  milestone: { label: 'Milestone', plural: 'Milestones', icon: FlagBanner },
  reminder: { label: 'Reminder', plural: 'Reminders', icon: BellSimple },
};

export const MILESTONE_LABEL: Record<MilestoneKind, string> = {
  'cohort-starts': 'Cohort starts',
  'chapter-release': 'Chapter opens',
  'enrolment-closes': 'Enrolment closes',
  'cohort-ends': 'Cohort wraps up',
  'course-launch': 'Course launch',
};

export const NOTIFY_OPTIONS: { minutes: number; label: string }[] = [
  { minutes: 0, label: 'At the time' },
  { minutes: 15, label: '15 minutes before' },
  { minutes: 60, label: 'An hour before' },
  { minutes: 1440, label: 'A day before' },
];

export const notifyLabel = (minutes?: number) =>
  minutes === undefined ? 'No notification' : (NOTIFY_OPTIONS.find((o) => o.minutes === minutes)?.label ?? `${minutes} minutes before`);

/** "7 PM", "7:30 PM" */
export const shortTime = (iso: string) => formatTime(iso).replace(':00', '');

/** How the event's time reads in a list: a range, a deadline, a moment, or the whole day. */
export function timeText(event: Pick<CalendarEvent, 'type' | 'timing' | 'startsAt' | 'durationMin'>) {
  if (event.timing === 'all-day') return 'All day';
  if (event.timing === 'timed') return `${formatTime(event.startsAt)} – ${formatTime(calendarEventEnd(event).toISOString())}`;
  if (event.type === 'assignment') return `Due ${formatTime(event.startsAt)}`;
  if (event.type === 'quiz') return `Closes ${formatTime(event.startsAt)}`;
  return formatTime(event.startsAt);
}

export type EventState = 'live' | 'starting-soon' | 'cancelled' | 'done' | 'due-soon' | 'past' | 'upcoming';

export function eventState(row: CalendarRow, now: Date): EventState {
  const e = row.event;
  if (e.cancelled || row.phase === 'cancelled') return 'cancelled';
  if (row.phase === 'live' || row.phase === 'starting-soon') return row.phase;
  if (e.type === 'reminder' && e.done) return 'done';
  const start = new Date(e.startsAt).getTime();
  if (calendarEventEnd(e).getTime() <= now.getTime()) return 'past';
  if ((e.type === 'assignment' || (e.type === 'quiz' && e.timing === 'moment')) && start - now.getTime() < 3 * 86_400_000) return 'due-soon';
  return 'upcoming';
}

/** The one badge worth showing next to an event; nothing for ordinary upcoming ones. */
export function EventBadge({ row, now }: { row: CalendarRow; now: Date }) {
  const state = eventState(row, now);
  if (state === 'live') return <StatusBadge status="live" size="sm" />;
  if (state === 'starting-soon') return <StatusBadge status="starting-soon" size="sm" />;
  if (state === 'cancelled') return <StatusBadge status="cancelled" size="sm" />;
  if (state === 'done')
    return (
      <Badge tone="accent" size="sm" icon={<CheckCircle size={12} weight="fill" />}>
        Done
      </Badge>
    );
  if (state === 'due-soon')
    return (
      <Badge tone="warn" size="sm" icon={<Timer size={12} weight="fill" />}>
        {row.event.type === 'quiz' ? 'Closes soon' : 'Due soon'}
      </Badge>
    );
  if (state === 'past' && row.due) {
    return (
      <span className={styles.rowFigure}>
        {row.due.submitted}/{row.due.learners} handed in
      </span>
    );
  }
  return null;
}

export function TypeIcon({ type, size = 14 }: { type: CalendarEventType; size?: number }) {
  const Glyph = TYPE_META[type].icon;
  return <Glyph size={size} weight="duotone" aria-hidden="true" />;
}

/** Event type as icon and words, in the type's colour — never colour alone. */
export function TypeTag({ event, children }: { event: Pick<CalendarEvent, 'type' | 'milestone'>; children?: ReactNode }) {
  return (
    <span className={styles.typeTag} data-type={event.type}>
      <TypeIcon type={event.type} />
      {event.type === 'milestone' && event.milestone ? MILESTONE_LABEL[event.milestone] : TYPE_META[event.type].label}
      {children}
    </span>
  );
}

/** A compact event in a month cell. */
export function EventChip({ row, to, now }: { row: CalendarRow; to: string; now: Date }) {
  const e = row.event;
  const state = eventState(row, now);
  return (
    <Link to={to} className={styles.chip} data-type={e.type} data-timing={e.timing} data-state={state} title={`${timeText(e)} · ${e.title}`}>
      <span className={styles.chipMark} aria-hidden="true" />
      {e.timing !== 'all-day' && <span className={styles.chipTime}>{e.timing === 'moment' && e.type !== 'reminder' ? 'Due' : shortTime(e.startsAt)}</span>}
      <span className={styles.chipTitle}>
        {e.title}
        <span className="sr-only">
          {' '}
          · {TYPE_META[e.type].label}
          {state === 'cancelled' ? ' · cancelled' : state === 'done' ? ' · done' : state === 'live' ? ' · live now' : ''}
        </span>
      </span>
    </Link>
  );
}

/** An event in the day panel and the list view. The title link covers the row. */
export function EventRow({ row, to, now }: { row: CalendarRow; to: string; now: Date }) {
  const e = row.event;
  const state = eventState(row, now);
  return (
    <li className={styles.row} data-type={e.type} data-state={state}>
      <span className={styles.rowTime}>{timeText(e)}</span>
      <span className={styles.rowBar} aria-hidden="true" />
      <span className={styles.rowMain}>
        <Link to={to} className={styles.rowTitle}>
          {e.title}
        </Link>
        <span className={styles.rowMeta}>
          <TypeTag event={e} />
          {row.courseTitle && <span className={styles.rowCourse}>{row.courseTitle}</span>}
          {e.type === 'live' && row.instructorName && <span className={styles.rowCourse}>{row.instructorName}</span>}
          {e.type === 'reminder' && e.audience === 'learners' && <span className={styles.rowCourse}>Sent to learners</span>}
        </span>
      </span>
      <span className={styles.rowStatus}>
        <EventBadge row={row} now={now} />
      </span>
    </li>
  );
}
