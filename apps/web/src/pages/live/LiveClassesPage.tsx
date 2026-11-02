import { Fragment } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { CalendarBlank, MagnifyingGlass, PencilSimple, Plus, VideoCamera } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatDate, formatDuration, formatLongDay, formatTimeRange, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { Meter } from '@/components/lms/progress/Meters';
import { DateBlock } from '@/components/lms/shared/WorkRow';
import { services, type LiveRow, type LiveView } from '@/services';
import { PhaseBadge, seatsText } from './liveMeta';
import styles from './Live.module.css';

const PAGE_SIZE = 20;

export default function LiveClassesPage() {
  const { can } = usePermissions();
  const { base, instructorId, isTeaching } = useWorkspace();
  const { isMobile } = useViewport();
  const [params, setParams] = useSearchParams();
  const view = (params.get('view') as LiveView | null) ?? 'upcoming';
  const search = params.get('q') ?? '';
  const courseId = params.get('course') ?? '';
  const teacher = params.get('instructor') ?? '';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const update = (next: Record<string, string | undefined>, keepPage = false) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || (k === 'view' && v === 'upcoming')) p.delete(k);
      else p.set(k, v);
    }
    if (!keepPage) p.delete('page');
    setParams(p, { replace: true });
  };

  const query = {
    view,
    search,
    courseId: courseId || undefined,
    instructorId: teacher || undefined,
    scopeInstructorId: instructorId,
    page,
    pageSize: PAGE_SIZE,
  };
  const list = useAsync(`live:${JSON.stringify(query)}`, () => services.live.list(query));
  const courses = useAsync(`live-courses:${instructorId}`, () => services.courses.list({ scopeInstructorId: instructorId, page: 1, pageSize: 100 }));
  const people = useAsync('live-instructors', () => services.catalog.listInstructors(), { immediate: !isTeaching });
  const data = list.data;
  const rows = data?.rows ?? [];
  const filtered = Boolean(search || courseId || teacher);
  const to = (r: LiveRow) => `${base}/live/${r.liveClass.id}`;

  const days: { day: string; rows: LiveRow[] }[] = [];
  for (const r of rows) {
    const day = formatLongDay(r.liveClass.startsAt);
    const last = days[days.length - 1];
    if (last?.day === day) last.rows.push(r);
    else days.push({ day, rows: [r] });
  }

  const action = (r: LiveRow) =>
    r.phase === 'live' || r.phase === 'starting-soon' ? (
      <LinkButton size="sm" variant="primary" to={to(r)} iconStart={<VideoCamera size={15} />}>
        {r.phase === 'live' ? 'Open room' : 'Get ready'}
      </LinkButton>
    ) : r.phase === 'upcoming' && can('live.manage') ? (
      <LinkButton size="sm" to={`${to(r)}/edit`} iconStart={<PencilSimple size={15} />}>
        Edit
      </LinkButton>
    ) : r.phase === 'upcoming' ? (
      <LinkButton size="sm" to={to(r)}>
        Details
      </LinkButton>
    ) : (
      <LinkButton size="sm" to={to(r)}>
        {r.phase === 'ended' && r.liveClass.recording ? 'Recording' : 'Details'}
      </LinkButton>
    );

  const historyColumns: Column<LiveRow>[] = [
    {
      key: 'title',
      header: 'Class',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <Link to={to(r)} className={styles.cellTitle}>
            {r.liveClass.title}
          </Link>
          <span className={styles.cellMeta}>{r.courseTitle}</span>
        </span>
      ),
    },
    {
      key: 'instructor',
      header: 'Instructor',
      width: '190px',
      mobile: 'meta',
      render: (r) => (
        <span className={styles.person}>
          <Avatar name={r.instructorName} size={24} />
          <span className={styles.truncate}>{r.instructorName}</span>
        </span>
      ),
    },
    { key: 'date', header: 'Date', width: '130px', mobile: 'detail', render: (r) => <span className={styles.nowrap}>{formatDate(r.liveClass.startsAt)}</span> },
    { key: 'duration', header: 'Duration', width: '90px', mobile: 'detail', render: (r) => formatDuration(r.liveClass.durationMin) },
    {
      key: 'attendance',
      header: 'Joined',
      width: '150px',
      mobile: 'detail',
      // Only the built-in room records who joined (from the platform); an outside meeting has nothing to count.
      render: (r) =>
        r.liveClass.meeting?.kind !== 'external' && r.liveClass.attended !== undefined && r.liveClass.registered ? (
          <span className={styles.rateCell}>
            <Meter
              value={(r.liveClass.attended / r.liveClass.registered) * 100}
              size="sm"
              label={`${r.liveClass.attended} of ${r.liveClass.registered} joined`}
            />
            <span className="tabular">
              {r.liveClass.attended}/{r.liveClass.registered}
            </span>
          </span>
        ) : (
          <span className={styles.muted}>—</span>
        ),
    },
    { key: 'status', header: 'Status', width: '150px', mobile: 'status', render: (r) => <PhaseBadge phase={r.phase} liveClass={r.liveClass} /> },
    { key: 'action', header: 'Action', width: '110px', align: 'end', mobile: 'hidden', render: action },
  ];

  const counts = data?.counts;
  const emptyCopy: Record<LiveView, { title: string; body: string }> = {
    upcoming: { title: 'Nothing scheduled', body: 'Schedule a live class for a course — learners are reminded a day, an hour and 15 minutes before.' },
    live: { title: 'No class is live right now', body: 'Classes appear here from the moment they start until they end.' },
    history: { title: 'No past sessions yet', body: 'Classes move here when they end, with who joined the built-in room.' },
    cancelled: { title: 'No cancelled classes', body: 'Cancelled classes stay here so you can see what learners were told.' },
  };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Live classes"
        description={
          isTeaching
            ? 'Classes you’ve scheduled, the one you’re teaching now, and past classes.'
            : 'Every live class across the platform — schedule, who’s registered, and how past sessions went.'
        }
        actions={
          can('live.manage') && (
            <LinkButton to={`${base}/live/new`} iconStart={<Plus size={16} />}>
              Schedule a class
            </LinkButton>
          )
        }
      />

      <div className={styles.controls}>
        <SegmentedControl<LiveView>
          label="Live classes"
          value={view}
          onChange={(v) => update({ view: v })}
          segments={[
            { value: 'upcoming', label: 'Upcoming', count: counts?.upcoming },
            { value: 'live', label: 'Live now', count: counts?.live },
            { value: 'history', label: 'History', count: counts?.history },
            { value: 'cancelled', label: 'Cancelled', count: counts?.cancelled },
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search classes" aria-label="Search live classes" />
          </div>
          <Field label="Course" hideLabel className={styles.filter}>
            <Select value={courseId} onChange={(e) => update({ course: e.target.value })}>
              <option value="">All courses</option>
              {courses.data?.rows
                .filter((c) => c.liveSessions > 0)
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

      {list.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="Live classes didn’t load"
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
          {Array.from({ length: 4 }, (_, i) => (
            <Skeleton key={i} height={76} radius="var(--r-md)" />
          ))}
        </div>
      ) : rows.length === 0 ? (
        filtered ? (
          <StateMessage
            icon={<MagnifyingGlass size={26} />}
            title="No classes match"
            actions={<Button onClick={() => update({ q: undefined, course: undefined, instructor: undefined })}>Clear filters</Button>}
          >
            Try another title, course or instructor.
          </StateMessage>
        ) : (
          <StateMessage
            icon={<CalendarBlank size={26} />}
            title={emptyCopy[view].title}
            actions={
              view === 'upcoming' && can('live.manage') ? (
                <LinkButton to={`${base}/live/new`} iconStart={<Plus size={16} />}>
                  Schedule a class
                </LinkButton>
              ) : undefined
            }
          >
            {emptyCopy[view].body}
          </StateMessage>
        )
      ) : view === 'history' && !isMobile ? (
        <div className={styles.tablePanel}>
          <DataTable label="Past live classes" rows={rows} columns={historyColumns} rowKey={(r) => r.liveClass.id} rowLabel={(r) => r.liveClass.title} />
        </div>
      ) : (
        <ol className={styles.timeline} aria-label={view === 'history' ? 'Past live classes' : 'Live classes'}>
          {days.map((d) => (
            <Fragment key={d.day}>
              <li className={styles.dayHeading}>
                <h2>{d.day}</h2>
              </li>
              {d.rows.map((r) => {
                const c = r.liveClass;
                const full = c.capacity !== undefined && (c.registered ?? 0) >= c.capacity;
                return (
                  <li key={c.id} className={styles.session} data-phase={r.phase}>
                    <DateBlock iso={c.startsAt} highlight={r.phase === 'live' || r.phase === 'starting-soon'} />
                    <div className={styles.sessionMain}>
                      <span className={styles.sessionTime}>
                        {formatTimeRange(c.startsAt, c.durationMin)} · {formatDuration(c.durationMin)}
                      </span>
                      <Link to={to(r)} className={styles.sessionTitle}>
                        {c.title}
                      </Link>
                      <span className={styles.sessionMeta}>
                        <Avatar name={r.instructorName} size={20} /> {r.instructorName} · {r.courseTitle}
                      </span>
                    </div>
                    <div className={styles.sessionSeats}>
                      {r.phase === 'cancelled' ? (
                        <span className={styles.muted}>{c.cancelReason}</span>
                      ) : (
                        <>
                          <span className={full ? styles.full : undefined}>
                            {r.phase === 'live' && c.attending !== undefined ? `${c.attending} joined` : seatsText(c.registered, c.capacity)}
                          </span>
                          {c.capacity !== undefined && (
                            <Meter
                              value={((c.registered ?? 0) / c.capacity) * 100}
                              size="xs"
                              tone={full ? 'warn' : 'accent'}
                              label={`${seatsText(c.registered, c.capacity)} taken`}
                            />
                          )}
                        </>
                      )}
                    </div>
                    <div className={styles.sessionStatus}>
                      <PhaseBadge phase={r.phase} liveClass={r.liveClass} />
                    </div>
                    <div className={styles.sessionAction}>{action(r)}</div>
                  </li>
                );
              })}
            </Fragment>
          ))}
        </ol>
      )}

      {data && data.total > PAGE_SIZE && (
        <Pagination
          page={page}
          pageCount={Math.ceil(data.total / PAGE_SIZE)}
          onChange={(p) => update({ page: String(p) }, true)}
          summary={`${((page - 1) * PAGE_SIZE + 1).toLocaleString('en-IN')}–${Math.min(page * PAGE_SIZE, data.total).toLocaleString('en-IN')} of ${plural(data.total, 'class', 'classes')}`}
        />
      )}
      {view === 'upcoming' && data && rows.length > 0 && (
        <p className={styles.muted}>Times are India Standard Time. Rooms open 15 minutes before each class.</p>
      )}
    </div>
  );
}
