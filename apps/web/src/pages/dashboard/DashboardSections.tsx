import { useMemo, useState, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowRight,
  CalendarPlus,
  CaretRight,
  Certificate,
  ChalkboardTeacher,
  ChartLineUp,
  CheckCircle,
  ClipboardText,
  ClosedCaptioning,
  Exam,
  FolderSimplePlus,
  HourglassMedium,
  NotePencil,
  PencilSimpleLine,
  Plus,
  RocketLaunch,
  SealCheck,
  UserPlus,
  UsersThree,
  VideoCamera,
} from '@phosphor-icons/react';
import type { AdminEvent, AttentionItem, Category, Course, DashboardSnapshot, Instructor, Level, LiveClass } from '@syniastrolms/domain';
import { deriveLiveClassPhase } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';
import { formatCount, formatDay, formatRelative, formatShortDate, formatTimeRange, plural } from '@/lib/format';
import { ColumnChart, Sparkline, TrendChart } from '@/components/charts/Charts';
import { Figure } from '@/components/data/KpiStrip';
import { SectionHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { IconChip } from '@/components/ui/Badge/Badge';
import { LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { Meter } from '@/components/lms/progress/Meters';
import { ProgressRing } from '@/components/lms/progress/ProgressRing';
import { DateBlock, WorkList, WorkRow } from '@/components/lms/shared/WorkRow';
import { StatusBadge, StatusLabel } from '@/components/lms/status/Status';
import { Rating } from '@/components/lms/shared/Rating';
import { Change } from '@/components/data/StatCards';
import styles from './Dashboard.module.css';

export interface Lookups {
  courses: Map<string, Course>;
  instructors: Map<string, Instructor>;
  levels: Level[];
  categories: Map<string, Category>;
}

const sum = (values: number[]) => values.reduce((n, v) => n + v, 0);

/* ─── Course performance ───────────────────────────────────────────────── */

export function CoursePerformance({ snapshot, lookups, base }: { snapshot: DashboardSnapshot; lookups: Lookups; base: string }) {
  const [metric, setMetric] = useState<'enrollments' | 'completions'>('enrollments');
  const series = metric === 'enrollments' ? snapshot.enrollments : snapshot.completions;
  const recent = sum(series.slice(-4).map((p) => p.value));
  const before = sum(series.slice(-8, -4).map((p) => p.value));
  const data = series.map((p) => ({ label: formatShortDate(p.date), detail: `Week of ${formatShortDate(p.date)}`, value: p.value }));
  const noun = metric === 'enrollments' ? 'new students' : 'students who finished a course';
  const figureLabel = metric === 'enrollments' ? 'students joined a course in the last 4 weeks' : 'students finished a course in the last 4 weeks';

  const columns: Column<DashboardSnapshot['courses'][number]>[] = [
    {
      key: 'course',
      header: 'Course',
      mobile: 'primary',
      render: (row) => {
        const course = lookups.courses.get(row.courseId)!;
        const level = lookups.levels.find((l) => l.id === course.levelId);
        return (
          <span className={styles.courseCell}>
            <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.courseThumb} />
            <span className={styles.courseCellText}>
              <Link to={`${base}/courses/${course.id}`} className={styles.courseLink}>
                {course.title}
              </Link>
              <span className={styles.courseCellMeta}>
                {level?.name} · {lookups.categories.get(course.categoryId)?.name}
              </span>
            </span>
          </span>
        );
      },
    },
    {
      key: 'learners',
      header: 'Students',
      align: 'end',
      width: '118px',
      mobile: 'hidden',
      render: (row) => (
        <span className={styles.learnersCell}>
          <span className="tabular">{formatCount(row.enrolled)}</span>
          <span className={styles.subtle} title="Opened the course in the last 2 weeks">
            {formatCount(row.active)} studying now
          </span>
        </span>
      ),
    },
    {
      key: 'completion',
      header: 'Finished',
      width: '132px',
      mobile: 'status',
      render: (row) => (
        <span className={styles.completionCell}>
          <Meter value={row.completionRate} size="sm" label={`${lookups.courses.get(row.courseId)?.title}: ${row.completionRate}% of students finished`} />
          <span className="tabular">{row.completionRate}%</span>
        </span>
      ),
    },
    {
      key: 'rating',
      header: 'Rating',
      width: '84px',
      mobile: 'hidden',
      render: (row) => (row.rating ? <Rating value={row.rating} /> : <span className={styles.subtle}>Not rated yet</span>),
    },
    {
      key: 'summary',
      header: 'Students',
      mobile: 'meta',
      listOnly: true,
      render: (row) => (
        <span className={styles.listSummary}>
          <span className="tabular">
            {plural(row.enrolled, 'student')} · {formatCount(row.active)} studying now
          </span>
          {row.rating && <Rating value={row.rating} />}
        </span>
      ),
    },
    {
      key: 'trend',
      header: 'Trend',
      width: '96px',
      mobile: 'hidden',
      render: (row) => (
        <span title={`New students each week, last 8 weeks: ${row.weeklyEnrollments.slice(-8).join(', ')}`}>
          <Sparkline values={row.weeklyEnrollments} width={80} height={22} />
        </span>
      ),
    },
  ];

  return (
    <section className={`${styles.panel} ${styles.perf}`} aria-labelledby="perf-title">
      <SectionHeader
        id="perf-title"
        title="How your courses are doing"
        description="Each point on the chart is one week. Switch to see new students or students who finished."
        actions={
          <SegmentedControl
            size="sm"
            label="Show"
            value={metric}
            onChange={setMetric}
            segments={[
              { value: 'enrollments', label: 'New students' },
              { value: 'completions', label: 'Finished' },
            ]}
          />
        }
      />
      <div className={styles.perfFigure}>
        <Figure value={formatCount(recent)} label={figureLabel}>
          <Change kpi={{ value: recent, previous: before, unit: 'count' }} since="the 4 weeks before" />
        </Figure>
      </div>
      <TrendChart data={data} label={`${noun[0].toUpperCase()}${noun.slice(1)} each week, last 12 weeks`} unit={noun} height={210} />

      <div className={styles.perfTable}>
        <DataTable
          label="Courses with the most students"
          rows={snapshot.courses.slice(0, 5)}
          columns={columns}
          rowKey={(r) => r.courseId}
          rowLabel={(r) => lookups.courses.get(r.courseId)?.title ?? r.courseId}
        />
      </div>
      <div className={styles.panelFoot}>
        <span className={styles.subtle}>
          Your {Math.min(5, snapshot.courses.length)} biggest of {plural(snapshot.courses.length, 'published course')}
        </span>
        <LinkButton to={`${base}/courses`} variant="ghost" size="sm" iconEnd={<ArrowRight size={14} />}>
          See all courses
        </LinkButton>
      </div>
    </section>
  );
}

/* ─── Needs attention ──────────────────────────────────────────────────── */

/** Each kind of item: its icon, what area it is about, and the button that does something about it. */
const ATTENTION: Record<AttentionItem['kind'], { icon: ReactNode; label: string; action: string }> = {
  reviews: { icon: <ClipboardText size={18} />, label: 'Student work', action: 'Mark now' },
  'at-risk': { icon: <UsersThree size={18} />, label: 'Students', action: 'See students' },
  capacity: { icon: <VideoCamera size={18} />, label: 'Live classes', action: 'Open class' },
  'stale-draft': { icon: <PencilSimpleLine size={18} />, label: 'Unfinished course', action: 'Finish it' },
  accessibility: { icon: <ClosedCaptioning size={18} />, label: 'Captions', action: 'Add captions' },
};
const SEVERITY: Record<AttentionItem['severity'], { tone: Tone; label: string }> = {
  high: { tone: 'danger', label: 'Do today' },
  medium: { tone: 'warn', label: 'This week' },
  low: { tone: 'info', label: 'When you can' },
};

export function NeedsAttention({ items }: { items: AttentionItem[] }) {
  return (
    <section className={`${styles.panel} ${styles.attention}`} aria-labelledby="attention-title">
      <SectionHeader
        id="attention-title"
        title="Needs your attention"
        count={items.length || undefined}
        description={items.length ? 'Most urgent first. Tap one to deal with it.' : undefined}
      />
      {items.length === 0 ? (
        <p className={styles.allClear}>
          <CheckCircle size={20} aria-hidden="true" />
          You’re all caught up — nothing needs you right now.
        </p>
      ) : (
        <ul className={styles.attentionList}>
          {items.map((item) => (
            <li key={item.id}>
              <Link to={item.to} className={styles.attentionItem}>
                <IconChip tone={SEVERITY[item.severity].tone}>{ATTENTION[item.kind].icon}</IconChip>
                <span className={styles.attentionText}>
                  <span className={styles.attentionTitle}>{item.title}</span>
                  <span className={styles.attentionDetail}>{item.detail}</span>
                  <span className={styles.attentionFoot}>
                    <span className={styles.attentionSeverity} data-severity={item.severity}>
                      {SEVERITY[item.severity].label}
                    </span>
                    <span className={styles.attentionKind}>{ATTENTION[item.kind].label}</span>
                    <span className={styles.attentionAction}>
                      {ATTENTION[item.kind].action}
                      <CaretRight size={12} weight="bold" aria-hidden="true" />
                    </span>
                  </span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

/* ─── Live this week ───────────────────────────────────────────────────── */

export function LiveThisWeek({ classes, lookups, now, base }: { classes: LiveClass[]; lookups: Lookups; now: Date; base: string }) {
  return (
    <section className={`${styles.panel} ${styles.live}`} aria-labelledby="live-title">
      <SectionHeader
        id="live-title"
        title="Upcoming live classes"
        count={classes.length || undefined}
        description="The next 7 days"
        actions={
          <LinkButton to={`${base}/live`} variant="ghost" size="sm" iconEnd={<ArrowRight size={14} />}>
            See all
          </LinkButton>
        }
      />
      {classes.length === 0 ? (
        <div className={styles.emptyAction}>
          <p className={styles.allClear}>
            <CalendarPlus size={20} aria-hidden="true" />
            No live classes in the next 7 days.
          </p>
          <LinkButton to={`${base}/live/new`} iconStart={<CalendarPlus size={16} />} variant="secondary" size="sm">
            Schedule a live class
          </LinkButton>
        </div>
      ) : (
        <WorkList label="Live classes in the next seven days">
          {classes.slice(0, 5).map((c) => {
            const phase = deriveLiveClassPhase(c, now);
            const seats = c.capacity ? (phase === 'live' ? c.attending : c.registered) : undefined;
            return (
              <WorkRow
                key={c.id}
                lead={<DateBlock iso={c.startsAt} highlight={phase === 'live'} />}
                emphasis={phase === 'live' ? 'live' : undefined}
                title={
                  <Link to={`${base}/live/${c.id}`} className={styles.rowLink}>
                    {c.title}
                  </Link>
                }
                meta={
                  <>
                    {formatTimeRange(c.startsAt, c.durationMin)} · {lookups.instructors.get(c.instructorId)?.name}
                  </>
                }
                status={
                  <span className={styles.liveStatus}>
                    {phase === 'live' ? (
                      <StatusBadge status="live" size="sm" />
                    ) : phase === 'starting-soon' ? (
                      <StatusBadge status="starting-soon" size="sm" label={`Starts ${formatRelative(c.startsAt, now)}`} />
                    ) : (
                      <StatusLabel status="upcoming" label={`Starts ${formatRelative(c.startsAt, now)}`} />
                    )}
                    {seats !== undefined && c.capacity && (
                      <span className={styles.seats}>
                        <Meter
                          value={(seats / c.capacity) * 100}
                          size="xs"
                          tone={seats / c.capacity >= 0.9 ? 'warn' : 'accent'}
                          label={`${seats} of ${c.capacity} seats ${phase === 'live' ? 'in the class now' : 'booked'}`}
                        />
                        <span className={styles.seatsText}>
                          {seats} of {c.capacity} {phase === 'live' ? 'in class now' : 'seats booked'}
                        </span>
                      </span>
                    )}
                  </span>
                }
              />
            );
          })}
        </WorkList>
      )}
    </section>
  );
}

/* ─── Learning activity ────────────────────────────────────────────────── */

export function LearningActivitySection({ snapshot }: { snapshot: DashboardSnapshot }) {
  const days = snapshot.activity.map((d) => ({
    label: formatShortDate(d.date),
    detail: formatDay(`${d.date}T12:00:00+05:30`),
    value: d.activeLearners,
  }));
  const { engagement } = snapshot;
  const figures = [
    { id: 'lessons', label: 'Lessons finished', kpi: engagement.lessonsCompleted },
    { id: 'quiz', label: 'Quizzes taken', kpi: engagement.quizAttempts },
    { id: 'submissions', label: 'Assignments handed in', kpi: engagement.submissions },
    { id: 'live', label: 'Live class attendance', kpi: engagement.liveAttendance },
  ];

  return (
    <section className={`${styles.panel} ${styles.activity}`} aria-labelledby="activity-title">
      <SectionHeader
        id="activity-title"
        title="How students are learning"
        description="What students did this week, and how many studied each day over the last 4 weeks."
      />
      <p className={styles.engagementCaption}>This week</p>
      <dl className={styles.engagement} aria-label="This week">
        {figures.map((f) => (
          <div key={f.id} className={styles.engagementItem}>
            <dt className={styles.engagementLabel}>{f.label}</dt>
            <dd className={styles.engagementValue}>{formatCount(f.kpi.value)}</dd>
            <dd>
              <Change kpi={f.kpi} since="last week" />
            </dd>
          </div>
        ))}
      </dl>
      <p className={styles.engagementCaption}>Students who studied each day</p>
      <ColumnChart
        data={days}
        label="Students who opened a lesson each day, last 28 days"
        unit="students studied"
        height={180}
        partialIndex={days.length - 1}
        partialNote="Today so far"
      />
    </section>
  );
}

/* ─── Quick actions ────────────────────────────────────────────────────── */

interface QuickAction {
  id: string;
  label: string;
  hint: string;
  icon: ReactNode;
  to: string;
}

export function QuickActions({ teaching, base }: { teaching: boolean; base: string }) {
  const actions: QuickAction[] = teaching
    ? [
        { id: 'reviews', label: 'Mark student work', hint: 'Give marks and feedback', icon: <ClipboardText size={18} />, to: `${base}/assignments/review` },
        {
          id: 'lesson',
          label: 'Add a lesson',
          hint: 'A video, article, PDF or quiz',
          icon: <NotePencil size={18} />,
          to: `${base}/courses`,
        },
        {
          id: 'live',
          label: 'Schedule a live class',
          hint: 'Students get a reminder',
          icon: <CalendarPlus size={18} />,
          to: `${base}/live/new`,
        },
        { id: 'quiz', label: 'Create a quiz', hint: 'Check what students learned', icon: <Exam size={18} />, to: `${base}/quizzes/new` },
      ]
    : [
        { id: 'course', label: 'Add a course', hint: 'Private until you publish', icon: <Plus size={18} />, to: `${base}/courses/new` },
        {
          id: 'category',
          label: 'Add a category',
          hint: 'Group courses by subject',
          icon: <FolderSimplePlus size={18} />,
          to: `${base}/categories/new`,
        },
        {
          id: 'live',
          label: 'Schedule a live class',
          hint: 'Students get a reminder',
          icon: <CalendarPlus size={18} />,
          to: `${base}/live/new`,
        },
        { id: 'quiz', label: 'Create a quiz', hint: 'Check what students learned', icon: <Exam size={18} />, to: `${base}/quizzes/new` },
        { id: 'instructor', label: 'Invite an instructor', hint: 'Add a teacher', icon: <UserPlus size={18} />, to: `${base}/instructors/new` },
        {
          id: 'reports',
          label: 'View reports',
          hint: 'Students, results, progress',
          icon: <ChartLineUp size={18} />,
          to: `${base}/reports`,
        },
      ];

  return (
    <nav className={`${styles.panel} ${styles.quick}`} aria-labelledby="quick-title">
      <SectionHeader id="quick-title" title="Quick actions" description="Common jobs, one tap away." />
      <ul className={styles.quickList}>
        {actions.map((a) => {
          return (
            <li key={a.id}>
              {
                <Link to={a.to} className={styles.quickItem}>
                  <span className={styles.quickIcon} aria-hidden="true">
                    {a.icon}
                  </span>
                  <span className={styles.quickLabel}>
                    {a.label}
                    <span className={styles.quickHint}>{a.hint}</span>
                  </span>
                </Link>
              }
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

/* ─── Recent activity ──────────────────────────────────────────────────── */

const EVENT: Record<AdminEvent['kind'], { icon: ReactNode; tone: Tone }> = {
  enrollment: { icon: <UserPlus size={16} />, tone: 'info' },
  'course-published': { icon: <RocketLaunch size={16} />, tone: 'accent' },
  'course-updated': { icon: <PencilSimpleLine size={16} />, tone: 'neutral' },
  submission: { icon: <ClipboardText size={16} />, tone: 'info' },
  certificate: { icon: <SealCheck size={16} />, tone: 'accent' },
  instructor: { icon: <ChalkboardTeacher size={16} />, tone: 'neutral' },
  review: { icon: <CheckCircle size={16} />, tone: 'accent' },
  'live-scheduled': { icon: <VideoCamera size={16} />, tone: 'danger' },
};

export function RecentActivity({ events, now, teaching }: { events: AdminEvent[]; now: Date; teaching?: boolean }) {
  return (
    <section className={`${styles.panel} ${styles.feed}`} aria-labelledby="feed-title">
      <SectionHeader
        id="feed-title"
        title="Recent activity"
        description={`The latest things that happened in your ${teaching ? 'courses' : 'platform'}, newest first.`}
      />
      {events.length === 0 ? (
        <p className={styles.allClear}>
          <HourglassMedium size={20} aria-hidden="true" />
          Updates show up here as students join courses and your team publishes.
        </p>
      ) : (
        <ol className={styles.feedList}>
          {events.slice(0, 8).map((e) => (
            <li key={e.id} className={styles.event}>
              {e.kind === 'enrollment' || e.kind === 'submission' || e.kind === 'review' ? (
                <span className={styles.eventAvatar}>
                  <Avatar name={e.actor} size={32} />
                  <span className={styles.eventBadge} data-tone={EVENT[e.kind].tone} aria-hidden="true">
                    {EVENT[e.kind].icon}
                  </span>
                </span>
              ) : (
                <IconChip tone={EVENT[e.kind].tone} className={styles.eventChip}>
                  {EVENT[e.kind].icon}
                </IconChip>
              )}
              <span className={styles.eventBody}>
                <span className={styles.eventText}>
                  <strong>{e.actor}</strong>{' '}
                  {e.to ? (
                    <Link to={e.to} className={styles.eventLink}>
                      {e.summary}
                    </Link>
                  ) : (
                    e.summary
                  )}
                </span>
                {e.context && <span className={styles.eventContext}>{e.context}</span>}
              </span>
              <time className={styles.eventTime} dateTime={e.at}>
                {formatRelative(e.at, now)}
              </time>
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}

/* ─── Top courses ──────────────────────────────────────────────────────── */

export function TopCourses({ snapshot, lookups, base }: { snapshot: DashboardSnapshot; lookups: Lookups; base: string }) {
  const top = useMemo(
    () =>
      [...snapshot.courses]
        .map((p) => ({ ...p, recent: sum(p.weeklyEnrollments.slice(-4)) }))
        .sort((a, b) => b.recent - a.recent)
        .slice(0, 4),
    [snapshot.courses],
  );

  return (
    <section className={`${styles.panel} ${styles.top}`} aria-labelledby="top-title">
      <SectionHeader id="top-title" title="Most popular courses" description="Courses with the most new students in the last 4 weeks." />
      {top.length === 0 ? (
        <p className={styles.allClear}>
          <Certificate size={20} aria-hidden="true" />
          This list starts once a course is published.
        </p>
      ) : (
        <ol className={styles.topList}>
          {top.map((p, i) => {
            const course = lookups.courses.get(p.courseId)!;
            return (
              <li key={p.courseId} className={styles.topItem}>
                <span className={styles.topRank} aria-hidden="true">
                  {i + 1}
                </span>
                <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.topCover} />
                <span className={styles.topText}>
                  <Link to={`${base}/courses/${course.id}`} className={styles.topTitle}>
                    {course.title}
                  </Link>
                  <span className={styles.topMeta}>
                    <span className="tabular">{p.recent ? `+${plural(p.recent, 'new student')}` : 'No new students yet'}</span>
                    {p.rating && <Rating value={p.rating} />}
                  </span>
                </span>
                <span className={styles.topFinished}>
                  <ProgressRing value={p.completionRate} size="sm" label={`${course.title}: ${p.completionRate}% of students finished`} />
                  <span className={styles.topFinishedLabel} aria-hidden="true">
                    finished
                  </span>
                </span>
              </li>
            );
          })}
        </ol>
      )}
    </section>
  );
}
