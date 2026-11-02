import { useEffect, useLayoutEffect, useRef, useState, type KeyboardEvent } from 'react';
import { Link } from 'react-router-dom';
import { CalendarBlank, CaretDown, Plus } from '@phosphor-icons/react';
import { calendarEventEnd } from '@syniastrolms/domain';
import { plural } from '@/lib/format';
import { Badge } from '@/components/ui/Badge/Badge';
import { LinkButton } from '@/components/ui/Button/Button';
import type { CalendarRow } from '@/services';
import {
  addDays,
  addMonths,
  istKey,
  layoutOverlaps,
  longDayLabel,
  minuteOfDay,
  monthLabel,
  monthWeeks,
  sameMonth,
  startOfWeek,
  weekDays,
  weekdayLabel,
} from './calendarDates';
import { EventChip, EventRow, eventState, shortTime, timeText, TYPE_META } from './calendarMeta';
import styles from './Calendar.module.css';

export interface ViewProps {
  date: string;
  today: string;
  now: Date;
  rows: CalendarRow[];
  /** Link to an event, keeping the calendar's filters. */
  hrefFor: (row: CalendarRow) => string;
  /** Link to add an event on a day. */
  addHref: (day: string) => string;
  onSelectDay: (day: string) => void;
  busy?: boolean;
}

export function groupByDay(rows: CalendarRow[]) {
  const map = new Map<string, CalendarRow[]>();
  for (const r of rows) {
    const key = istKey(r.event.startsAt);
    const list = map.get(key);
    if (list) list.push(r);
    else map.set(key, [r]);
  }
  return map;
}

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/* ─── Month ─── */

export function MonthView({ date, today, now, rows, hrefFor, addHref, onSelectDay, busy }: ViewProps) {
  const weeks = monthWeeks(date);
  const byDay = groupByDay(rows);
  const gridRef = useRef<HTMLDivElement>(null);
  const focusNext = useRef<string | null>(null);

  useEffect(() => {
    if (!focusNext.current) return;
    gridRef.current?.querySelector<HTMLButtonElement>(`[data-day="${focusNext.current}"]`)?.focus();
    focusNext.current = null;
  }, [date]);

  const onKeyDown = (e: KeyboardEvent, key: string) => {
    const moves: Record<string, () => string> = {
      ArrowLeft: () => addDays(key, -1),
      ArrowRight: () => addDays(key, 1),
      ArrowUp: () => addDays(key, -7),
      ArrowDown: () => addDays(key, 7),
      Home: () => startOfWeek(key),
      End: () => addDays(startOfWeek(key), 6),
      PageUp: () => addMonths(key, -1),
      PageDown: () => addMonths(key, 1),
    };
    const move = moves[e.key];
    if (!move) return;
    e.preventDefault();
    focusNext.current = move();
    onSelectDay(focusNext.current);
  };

  const selected = byDay.get(date) ?? [];

  return (
    <div className={styles.monthLayout}>
      <section className={styles.month} aria-label={monthLabel(date)} aria-busy={busy || undefined} ref={gridRef}>
        <div className={styles.weekdays} aria-hidden="true">
          {WEEKDAYS.map((d) => (
            <span key={d}>{d}</span>
          ))}
        </div>
        {weeks.map((week) => (
          <div key={week[0]} className={styles.monthWeek}>
            {week.map((key) => {
              const events = byDay.get(key) ?? [];
              const shown = events.length > 3 ? events.slice(0, 2) : events;
              return (
                <div
                  key={key}
                  className={styles.day}
                  data-outside={!sameMonth(key, date) || undefined}
                  data-today={key === today || undefined}
                  data-selected={key === date || undefined}
                >
                  <button
                    type="button"
                    className={styles.dayNumber}
                    data-day={key}
                    tabIndex={key === date ? 0 : -1}
                    aria-pressed={key === date}
                    aria-current={key === today ? 'date' : undefined}
                    aria-label={`${longDayLabel(key)}${key === today ? ', today' : ''} · ${events.length ? plural(events.length, 'event') : 'no events'}`}
                    onClick={() => onSelectDay(key)}
                    onKeyDown={(e) => onKeyDown(e, key)}
                  >
                    {Number(key.slice(8))}
                  </button>
                  {events.length > 0 && (
                    <span className={styles.dots} aria-hidden="true">
                      {events.slice(0, 4).map((r) => (
                        <span key={r.event.id} className={styles.dot} data-type={r.event.type} data-state={eventState(r, now)} />
                      ))}
                    </span>
                  )}
                  <ul className={styles.chips}>
                    {shown.map((r) => (
                      <li key={r.event.id}>
                        <EventChip row={r} to={hrefFor(r)} now={now} />
                      </li>
                    ))}
                    {events.length > shown.length && (
                      <li>
                        <button type="button" className={styles.more} onClick={() => onSelectDay(key)}>
                          {events.length - shown.length} more
                          <span className="sr-only"> on {longDayLabel(key)}</span>
                        </button>
                      </li>
                    )}
                  </ul>
                </div>
              );
            })}
          </div>
        ))}
      </section>
      <DayPanel date={date} today={today} now={now} rows={selected} hrefFor={hrefFor} addHref={addHref} />
    </div>
  );
}

function DayPanel({ date, today, now, rows, hrefFor, addHref }: Pick<ViewProps, 'date' | 'today' | 'now' | 'rows' | 'hrefFor' | 'addHref'>) {
  return (
    <section className={styles.dayPanel} aria-labelledby="calendar-day-title" aria-live="polite">
      <header className={styles.dayPanelHead}>
        <h3 id="calendar-day-title" className={styles.dayPanelTitle}>
          {longDayLabel(date)}
        </h3>
        {date === today && (
          <Badge tone="accent" size="sm">
            Today
          </Badge>
        )}
        <span className={styles.muted}>{rows.length ? plural(rows.length, 'event') : ''}</span>
      </header>
      {rows.length === 0 ? (
        <div className={styles.dayEmpty}>
          <CalendarBlank size={22} aria-hidden="true" />
          <p>{date < today ? 'Nothing happened on this day.' : 'Nothing on this day yet.'}</p>
          {date >= today && (
            <LinkButton size="sm" to={addHref(date)} iconStart={<Plus size={14} />}>
              Add an event
            </LinkButton>
          )}
        </div>
      ) : (
        <>
          <ol className={styles.rows}>
            {rows.map((r) => (
              <EventRow key={r.event.id} row={r} to={hrefFor(r)} now={now} />
            ))}
          </ol>
          {date >= today && (
            <Link to={addHref(date)} className={styles.addLink}>
              <Plus size={14} aria-hidden="true" /> Add an event on this day
            </Link>
          )}
        </>
      )}
    </section>
  );
}

/* ─── Week ─── */

const HOUR_PX = 48;
const FIRST_HOUR = 6;
const LAST_HOUR = 24;
const MOMENT_PX = 24;

export function WeekView({ date, today, now, rows, hrefFor, onSelectDay, busy }: ViewProps) {
  const days = weekDays(date);
  const byDay = groupByDay(rows);
  const scrollRef = useRef<HTMLDivElement>(null);
  const scrolledWeek = useRef<string | null>(null);
  const bodyHeight = (LAST_HOUR - FIRST_HOUR) * HOUR_PX;
  const y = (minute: number) => ((minute - FIRST_HOUR * 60) / 60) * HOUR_PX;
  const allDay = days.map((d) => (byDay.get(d) ?? []).filter((r) => r.event.timing === 'all-day'));
  const hasAllDay = allDay.some((list) => list.length > 0);

  // Open each week at its first event (or 8 AM), once per week rather than on every refresh.
  useLayoutEffect(() => {
    if (!scrollRef.current || scrolledWeek.current === days[0]) return;
    const minutes = rows.filter((r) => r.event.timing !== 'all-day').map((r) => minuteOfDay(r.event.startsAt));
    const first = minutes.length ? Math.min(...minutes) : 8 * 60;
    scrollRef.current.scrollTop = Math.max(0, y(Math.floor(Math.min(first, 17 * 60) / 60) * 60) - 12);
    if (!busy) scrolledWeek.current = days[0];
  });

  const nowMinute = minuteOfDay(now.toISOString());

  return (
    <section className={styles.weekFrame} aria-label={`Week of ${longDayLabel(days[0])}`} aria-busy={busy || undefined}>
      <div className={styles.weekInner}>
        <div className={styles.weekHead}>
          <span />
          {days.map((d) => (
            <button
              key={d}
              type="button"
              className={styles.weekDayHead}
              data-today={d === today || undefined}
              data-selected={d === date || undefined}
              aria-pressed={d === date}
              onClick={() => onSelectDay(d)}
            >
              <span className={styles.weekDayName}>{weekdayLabel(d)}</span>
              <span className={styles.weekDayNumber}>{Number(d.slice(8))}</span>
              <span className="sr-only"> · {plural((byDay.get(d) ?? []).length, 'event')}</span>
            </button>
          ))}
        </div>
        {hasAllDay && (
          <div className={styles.allDayRow}>
            <span className={styles.gutterLabel}>All day</span>
            {allDay.map((list, i) => (
              <ul key={days[i]} className={styles.allDayCell}>
                {list.map((r) => (
                  <li key={r.event.id}>
                    <EventChip row={r} to={hrefFor(r)} now={now} />
                  </li>
                ))}
              </ul>
            ))}
          </div>
        )}
        <div className={styles.weekScroll} ref={scrollRef}>
          <div className={styles.weekBody} style={{ height: bodyHeight }}>
            <div className={styles.hours} aria-hidden="true">
              {Array.from({ length: LAST_HOUR - FIRST_HOUR }, (_, i) => (
                <span key={i} style={{ top: i * HOUR_PX }}>
                  {i === 0 ? '' : shortTime(`2026-01-01T${String(FIRST_HOUR + i).padStart(2, '0')}:00:00+05:30`)}
                </span>
              ))}
            </div>
            {days.map((d) => {
              const timed = (byDay.get(d) ?? []).filter((r) => r.event.timing !== 'all-day');
              const placed = layoutOverlaps(
                timed.map((r) => {
                  const start = minuteOfDay(r.event.startsAt);
                  const end =
                    r.event.timing === 'timed'
                      ? start + Math.max(20, (calendarEventEnd(r.event).getTime() - new Date(r.event.startsAt).getTime()) / 60_000)
                      : start + 30;
                  return { item: r, start, end };
                }),
              );
              return (
                <div key={d} className={styles.weekColumn} data-today={d === today || undefined}>
                  {placed.map(({ item: r, start, end, column, columns }) => {
                    const moment = r.event.timing === 'moment';
                    const top = Math.min(Math.max(0, y(start)), bodyHeight - MOMENT_PX);
                    const height = moment ? MOMENT_PX : Math.max(MOMENT_PX, y(end) - y(start) - 2);
                    const size = height < 36 ? 'xs' : height < 64 ? 'sm' : 'lg';
                    return (
                      <Link
                        key={r.event.id}
                        to={hrefFor(r)}
                        className={styles.block}
                        data-type={r.event.type}
                        data-timing={r.event.timing}
                        data-size={size}
                        data-state={eventState(r, now)}
                        style={{ top, height, left: `calc(${(column / columns) * 100}% + 2px)`, width: `calc(${100 / columns}% - 4px)` }}
                      >
                        <span className={styles.blockTitle}>{r.event.title}</span>
                        <span className={styles.blockTime}>
                          {timeText(r.event)}
                          <span className="sr-only"> · {TYPE_META[r.event.type].label}</span>
                        </span>
                      </Link>
                    );
                  })}
                  {d === today && nowMinute >= FIRST_HOUR * 60 && <span className={styles.nowLine} style={{ top: y(nowMinute) }} aria-hidden="true" />}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}

/* ─── List ─── */

export function ListView({ date, today, now, rows, hrefFor, addHref, busy }: ViewProps) {
  const [showEarlier, setShowEarlier] = useState(false);
  const byDay = groupByDay(rows);
  const current = sameMonth(date, today);
  if (current && !byDay.has(today)) byDay.set(today, []);
  const days = [...byDay.keys()].sort();
  const earlier = current ? days.filter((d) => d < today) : [];
  const visible = showEarlier ? days : days.filter((d) => !earlier.includes(d));
  const earlierEvents = earlier.reduce((n, d) => n + (byDay.get(d)?.length ?? 0), 0);

  return (
    <section className={styles.list} aria-label={`Events in ${monthLabel(date)}`} aria-busy={busy || undefined}>
      {earlier.length > 0 && !showEarlier && (
        <button type="button" className={styles.earlier} onClick={() => setShowEarlier(true)}>
          <CaretDown size={14} aria-hidden="true" />
          Show earlier this month · {plural(earlierEvents, 'event')}
        </button>
      )}
      <ol className={styles.agenda}>
        {visible.map((d) => {
          const list = byDay.get(d) ?? [];
          return (
            <li key={d} className={styles.agendaDay} data-today={d === today || undefined} data-past={d < today || undefined}>
              <h3 className={styles.agendaDayTitle}>
                {longDayLabel(d)}
                {d === today && (
                  <Badge tone="accent" size="sm">
                    Today
                  </Badge>
                )}
              </h3>
              {list.length === 0 ? (
                <p className={styles.agendaEmpty}>
                  Nothing scheduled today.{' '}
                  <Link to={addHref(d)} className={styles.inlineLink}>
                    Add an event
                  </Link>
                </p>
              ) : (
                <ol className={styles.rows}>
                  {list.map((r) => (
                    <EventRow key={r.event.id} row={r} to={hrefFor(r)} now={now} />
                  ))}
                </ol>
              )}
            </li>
          );
        })}
      </ol>
      {current && visible.every((d) => d <= today && (byDay.get(d)?.length ?? 0) === 0) && (
        <p className={styles.agendaEmpty}>Nothing else is scheduled this month.</p>
      )}
    </section>
  );
}
