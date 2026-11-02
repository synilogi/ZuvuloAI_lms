import { useCallback } from 'react';
import { useMatch, useNavigate, useSearchParams } from 'react-router-dom';
import { CalendarBlank, CalendarDots, CaretLeft, CaretRight, ListBullets, Plus, Rows } from '@phosphor-icons/react';
import type { CalendarEventType } from '@syniastrolms/domain';
import { CALENDAR_EVENT_TYPES } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { useSession } from '@/providers/SessionProvider';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Field, Select } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { services, type CalendarDetail, type CalendarRow } from '@/services';
import { isDayKey, istKey, monthLabel, stepDate, viewRange, weekLabel, type CalendarView } from './calendarDates';
import { ListView, MonthView, WeekView } from './CalendarViews';
import { EventPanel } from './EventPanel';
import { TypeIcon, TYPE_META } from './calendarMeta';
import styles from './Calendar.module.css';

const isType = (value: string): value is CalendarEventType => (CALENDAR_EVENT_TYPES as string[]).includes(value);

export default function CalendarPage() {
  const { base, instructorId, isTeaching } = useWorkspace();
  const { user } = useSession();
  const { isMobile } = useViewport();
  const now = useNow();
  const navigate = useNavigate();
  const today = istKey(now);
  const [params, setParams] = useSearchParams();
  const match = useMatch(`${base}/calendar/:eventId`);
  const eventId = match?.params.eventId;

  const requested = params.get('view');
  const view: CalendarView = requested === 'month' || requested === 'list' || (requested === 'week' && !isMobile) ? requested : isMobile ? 'list' : 'month';
  const date = isDayKey(params.get('date')) ? params.get('date')! : today;
  const typesParam = params.get('types');
  const types = typesParam === null ? undefined : typesParam.split(',').filter(isType);
  const courseId = params.get('course') ?? '';
  const teacher = params.get('instructor') ?? '';
  const keep = params.toString() ? `?${params.toString()}` : '';

  const update = useCallback(
    (next: Record<string, string | undefined>) => {
      setParams(
        (current) => {
          const p = new URLSearchParams(current);
          for (const [k, v] of Object.entries(next)) {
            if (v === undefined || v === '') p.delete(k);
            else p.set(k, v);
          }
          return p;
        },
        { replace: true },
      );
    },
    [setParams],
  );

  const range = viewRange(view, date);
  const query = { ...range, types, courseId: courseId || undefined, instructorId: teacher || undefined, scopeInstructorId: instructorId, viewerId: user.id };
  const list = useAsync(`calendar:${JSON.stringify(query)}`, () => services.calendar.list(query));
  const courses = useAsync(`calendar-courses:${instructorId}`, () => services.courses.list({ scopeInstructorId: instructorId, page: 1, pageSize: 100 }));
  const people = useAsync('calendar-instructors', () => services.catalog.listInstructors(), { immediate: !isTeaching });
  const data = list.data;
  const busy = list.status === 'loading';
  const filtered = Boolean(types || courseId || teacher);
  const periodLabel = view === 'week' ? weekLabel(date) : monthLabel(date);
  const unit = view === 'week' ? 'week' : 'month';

  const hrefFor = (row: CalendarRow) => `${base}/calendar/${row.event.id}${keep}`;
  const addHref = (day: string) => `${base}/calendar/new?date=${day}`;
  const selectDay = (day: string) => update({ date: day === today ? undefined : day });

  const toggleType = (type: CalendarEventType) => {
    const on = types ?? CALENDAR_EVENT_TYPES;
    const next = on.includes(type) ? on.filter((t) => t !== type) : [...on, type];
    update({ types: next.length === CALENDAR_EVENT_TYPES.length ? undefined : next.join(',') || 'none' });
  };
  const clearFilters = () => update({ types: undefined, course: undefined, instructor: undefined });

  // A shared link to an event opens the calendar on the event's date.
  const onLoaded = useCallback(
    (detail: CalendarDetail) => {
      if (!params.has('date') && istKey(detail.event.startsAt) !== today) update({ date: istKey(detail.event.startsAt) });
    },
    [params, today, update],
  );

  const viewProps = { date, today, now, rows: data?.rows ?? [], hrefFor, addHref, onSelectDay: selectDay, busy };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Calendar"
        description={
          isTeaching
            ? 'Your live classes, the deadlines and milestones in your courses, and your own reminders.'
            : 'Live classes, assignment deadlines, quizzes and course milestones across the platform — with your own reminders.'
        }
        actions={
          <LinkButton to={addHref(date >= today ? date : today)} variant="primary" iconStart={<Plus size={16} />}>
            Add event
          </LinkButton>
        }
      />

      <div className={styles.controls}>
        <div className={styles.toolbar}>
          <div className={styles.period}>
            <Button size="sm" onClick={() => update({ date: undefined })} disabled={date === today}>
              Today
            </Button>
            <IconButton label={`Previous ${unit}`} size="sm" icon={<CaretLeft size={16} />} onClick={() => update({ date: stepDate(view, date, -1) })} />
            <IconButton label={`Next ${unit}`} size="sm" icon={<CaretRight size={16} />} onClick={() => update({ date: stepDate(view, date, 1) })} />
            <h2 className={styles.periodLabel} aria-live="polite">
              {periodLabel}
            </h2>
          </div>
          <SegmentedControl<CalendarView>
            label="Calendar view"
            size="sm"
            value={view}
            onChange={(v) => update({ view: v })}
            segments={[
              { value: 'month', label: 'Month', icon: <CalendarDots size={15} /> },
              ...(isMobile ? [] : [{ value: 'week' as const, label: 'Week', icon: <Rows size={15} /> }]),
              { value: 'list', label: 'List', icon: <ListBullets size={15} /> },
            ]}
          />
        </div>

        <div className={styles.filters}>
          <div className={styles.typeFilters} role="group" aria-label="Show event types">
            {CALENDAR_EVENT_TYPES.map((t) => {
              const on = !types || types.includes(t);
              return (
                <button key={t} type="button" className={styles.typeFilter} data-type={t} aria-pressed={on} onClick={() => toggleType(t)}>
                  <span className={styles.typeCheck} aria-hidden="true" />
                  <TypeIcon type={t} size={15} />
                  {TYPE_META[t].plural}
                  <span className={styles.typeCount}>{data ? data.counts[t] : '–'}</span>
                </button>
              );
            })}
          </div>
          <div className={styles.selects}>
            <Field label="Course" hideLabel className={styles.filter}>
              <Select value={courseId} onChange={(e) => update({ course: e.target.value })}>
                <option value="">All courses</option>
                {courses.data?.rows
                  .filter((c) => c.status !== 'archived')
                  .map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.title}
                    </option>
                  ))}
              </Select>
            </Field>
            {!isTeaching && (
              <Field label="Instructor" hideLabel className={styles.filter}>
                <Select value={teacher} onChange={(e) => update({ instructor: e.target.value })}>
                  <option value="">All instructors</option>
                  {people.data
                    ?.filter((i) => i.status !== 'invited')
                    .map((i) => (
                      <option key={i.id} value={i.id}>
                        {i.name}
                      </option>
                    ))}
                </Select>
              </Field>
            )}
          </div>
        </div>
      </div>

      {list.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="The calendar didn’t load"
          actions={
            <Button variant="primary" onClick={() => list.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {list.error.message}
        </StateMessage>
      ) : !data ? (
        <div className={styles.skeletons} aria-busy="true">
          <Skeleton height={view === 'list' ? 72 : 520} radius="var(--r-lg)" />
          {view === 'list' && <Skeleton height={72} radius="var(--r-lg)" />}
        </div>
      ) : (
        <div className={styles.calendarArea}>
          {data.total === 0 && !filtered ? (
            view === 'list' ? (
              <StateMessage
                icon={<CalendarBlank size={26} />}
                title={`Nothing scheduled in ${periodLabel}`}
                actions={
                  <>
                    <LinkButton to={addHref(date >= today ? date : today)} variant="primary" iconStart={<Plus size={16} />}>
                      Add an event
                    </LinkButton>
                    <LinkButton to={`${base}/live/new`}>Schedule a live class</LinkButton>
                  </>
                }
              >
                Live classes, deadlines and milestones in {isTeaching ? 'your courses' : 'the platform'} appear here as they’re scheduled. Add a reminder or a
                milestone of your own.
              </StateMessage>
            ) : (
              <InlineMessage kind="info" title={`Nothing scheduled in ${periodLabel}.`}>
                Live classes, deadlines and milestones appear as they’re scheduled.
              </InlineMessage>
            )
          ) : (
            data.rows.length === 0 && (
              <InlineMessage
                kind="info"
                title={types?.length === 0 ? 'Every event type is hidden.' : `No events match these filters in ${periodLabel}.`}
                action={
                  <Button size="sm" onClick={clearFilters}>
                    Show everything
                  </Button>
                }
              >
                {data.total} {data.total === 1 ? 'event is' : 'events are'} hidden by the filters.
              </InlineMessage>
            )
          )}
          {!(view === 'list' && data.total === 0 && !filtered) &&
            (view === 'month' ? (
              <MonthView {...viewProps} />
            ) : view === 'week' ? (
              <WeekView {...viewProps} />
            ) : data.rows.length > 0 || !filtered ? (
              <ListView key={date.slice(0, 7)} {...viewProps} />
            ) : null)}
        </div>
      )}

      {eventId && eventId !== 'new' && (
        <EventPanel
          eventId={eventId}
          base={base}
          viewerId={user.id}
          scopeInstructorId={instructorId}
          onClose={() => navigate(`${base}/calendar${keep}`)}
          onChanged={() => list.run().catch(() => undefined)}
          onLoaded={onLoaded}
        />
      )}
    </div>
  );
}
