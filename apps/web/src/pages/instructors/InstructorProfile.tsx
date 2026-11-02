import { createContext, useContext, useState, type ReactNode } from 'react';
import { Link, Outlet, useLocation, useParams } from 'react-router-dom';
import {
  ArrowLeft,
  ArrowRight,
  BookOpen,
  CalendarCheck,
  ChalkboardTeacher,
  ChartLineUp,
  CheckCircle,
  ClipboardText,
  DotsThree,
  EnvelopeSimple,
  Megaphone,
  PencilSimple,
  Power,
  SquaresFour,
  UserPlus,
  VideoCamera,
} from '@phosphor-icons/react';
import type { AdminEventKind } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatCount, formatDate, formatRelative, plural } from '@/lib/format';
import { ColumnChart } from '@/components/charts/Charts';
import { Figure } from '@/components/data/KpiStrip';
import { RouteTabs } from '@/components/page/RouteTabs';
import { SectionHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { IconChip } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { CourseStatusBadge } from '@/components/lms/course/CourseStatus';
import { Meter } from '@/components/lms/progress/Meters';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type InstructorCourse, type InstructorProfile as Profile } from '@/services';
import { StatusDialog } from './InstructorsPage';
import { Rating } from '@/components/lms/shared/Rating';
import { InstructorStatusBadge } from './instructorMeta';
import styles from './Instructors.module.css';

const ProfileContext = createContext<{ profile: Profile; to: string } | null>(null);
const useProfile = () => {
  const ctx = useContext(ProfileContext);
  if (!ctx) throw new Error('useProfile must be used inside InstructorLayout');
  return ctx;
};

const SUBPAGES: Record<string, string> = { courses: 'Courses', performance: 'Performance' };

export default function InstructorLayout() {
  const { instructorId } = useParams();
  const { pathname } = useLocation();
  const toast = useToast();
  const query = useAsync(`instructor:${instructorId}`, () => services.instructors.get(instructorId!));
  const [changing, setChanging] = useState(false);
  const to = `/admin/instructors/${instructorId}`;
  const segment = pathname
    .split('/')
    .filter(Boolean)
    .find((s) => SUBPAGES[s]);
  usePageCrumbs(query.data ? [{ label: query.data.instructor.name, to }, ...(segment ? [{ label: SUBPAGES[segment] }] : [])] : [{ label: 'Instructor' }]);

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'Instructor not found' : 'This profile didn’t load'}
          actions={
            notFound ? (
              <LinkButton to="/admin/instructors" iconStart={<ArrowLeft size={16} />}>
                Back to instructors
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!query.data || query.data.instructor.id !== instructorId) {
    return (
      <div className={styles.page} role="status" aria-label="Loading profile">
        <div className={styles.profileHead}>
          <Skeleton width={80} height={80} radius="var(--r-pill)" />
          <div className={styles.profileText}>
            <Skeleton width={140} height={10} />
            <Skeleton width="40%" height={28} radius="var(--r-xs)" />
            <Skeleton width={280} height={10} />
          </div>
        </div>
        <Skeleton height={84} radius="var(--r-md)" />
        <Skeleton height={360} radius="var(--r-lg)" />
      </div>
    );
  }

  const profile = query.data;
  const { instructor, performance, reach, courses } = profile;
  const published = courses.filter((c) => c.status === 'published').length;

  const resend = async () => {
    try {
      const { sentTo } = await services.instructors.resendInvite(instructor.id);
      toast({ kind: 'success', title: 'Invitation sent again', text: sentTo });
    } catch (e) {
      toast({ kind: 'error', title: 'The invitation wasn’t sent', text: (e as Error).message });
    }
  };

  return (
    <ProfileContext.Provider value={{ profile, to }}>
      <div className={styles.page}>
        <Link to="/admin/instructors" className={styles.back}>
          <ArrowLeft size={14} aria-hidden="true" /> Instructors
        </Link>
        <header className={styles.profileHead}>
          <Avatar name={instructor.name} size={80} className={instructor.photo ? styles.hasPhoto : undefined} />
          <div className={styles.profileText}>
            <span className={styles.eyebrow}>{instructor.title}</span>
            <h1 className={styles.profileName}>{instructor.name}</h1>
            <div className={styles.profileMeta}>
              <InstructorStatusBadge status={instructor.status} size="md" />
              <span>{instructor.email}</span>
              <span>{instructor.city}</span>
              {instructor.yearsTeaching !== undefined && <span>{plural(instructor.yearsTeaching, 'year')} teaching</span>}
              <span>
                {instructor.status === 'invited' ? 'Invited' : 'Joined'} {formatDate(instructor.joinedAt)}
              </span>
            </div>
          </div>
          <div className={styles.profileActions}>
            {instructor.status === 'invited' && (
              <Button iconStart={<EnvelopeSimple size={16} />} onClick={resend}>
                Resend invitation
              </Button>
            )}
            <LinkButton to={`${to}/edit`} variant={instructor.status === 'invited' ? 'secondary' : 'primary'} iconStart={<PencilSimple size={16} />}>
              Edit
            </LinkButton>
            <Menu
              align="end"
              width={220}
              trigger={(props) => <IconButton {...props} boxed label="More actions" icon={<DotsThree size={18} weight="bold" />} />}
              sections={[
                {
                  items: [
                    instructor.status === 'inactive'
                      ? { id: 'reactivate', label: 'Reactivate', icon: <Power size={17} />, onSelect: () => setChanging(true) }
                      : {
                          id: 'deactivate',
                          label: instructor.status === 'invited' ? 'Withdraw invitation…' : 'Deactivate…',
                          icon: <Power size={17} />,
                          tone: 'danger',
                          onSelect: () => setChanging(true),
                        },
                  ],
                },
              ]}
            />
          </div>
        </header>

        <dl className={styles.figures}>
          <Figure label={courses.length === 1 ? 'course' : 'courses'} value={String(courses.length)}>
            <span className={styles.figureNote}>{published} published</span>
          </Figure>
          <Figure label="students reached" value={formatCount(reach.students)}>
            <span className={styles.figureNote}>{formatCount(reach.newThisMonth)} new in 30 days</span>
          </Figure>
          <Figure label="rating" value={performance.rating ? performance.rating.toFixed(1) : '—'}>
            <span className={styles.figureNote}>
              {performance.ratingCount ? `${performance.ratingCount.toLocaleString('en-IN')} ratings` : 'No ratings yet'}
            </span>
          </Figure>
          <Figure label="completion" value={performance.completion === null ? '—' : `${performance.completion}%`}>
            <span className={styles.figureNote}>platform average {performance.academyCompletion}%</span>
          </Figure>
          <Figure label="reviews waiting" value={String(performance.toReview)}>
            <span className={styles.figureNote}>{performance.reviewsOnTime === null ? 'No reviews yet' : `${performance.reviewsOnTime}% inside 48 hours`}</span>
          </Figure>
        </dl>

        <RouteTabs
          label={`${instructor.name}’s profile`}
          tabs={[
            { to, label: 'Overview', icon: <SquaresFour size={16} />, end: true },
            { to: `${to}/courses`, label: 'Courses', icon: <BookOpen size={16} />, count: courses.length },
            { to: `${to}/performance`, label: 'Performance', icon: <ChartLineUp size={16} /> },
          ]}
        />

        <Outlet />

        {changing && (
          <StatusDialog
            row={{ instructor, courses: courses.map((c) => ({ id: c.id, title: c.title, status: c.status })) }}
            onClose={() => setChanging(false)}
            onDone={() => {
              setChanging(false);
              query.run().catch(() => undefined);
            }}
          />
        )}
      </div>
    </ProfileContext.Provider>
  );
}

/* ─── Overview ─────────────────────────────────────────────────────────── */

const EVENT: Record<AdminEventKind, { icon: ReactNode; tone: Tone }> = {
  enrollment: { icon: <UserPlus size={16} />, tone: 'info' },
  'course-published': { icon: <Megaphone size={16} />, tone: 'accent' },
  'course-updated': { icon: <PencilSimple size={16} />, tone: 'neutral' },
  submission: { icon: <ClipboardText size={16} />, tone: 'info' },
  certificate: { icon: <CheckCircle size={16} />, tone: 'accent' },
  instructor: { icon: <ChalkboardTeacher size={16} />, tone: 'info' },
  review: { icon: <CheckCircle size={16} />, tone: 'accent' },
  'live-scheduled': { icon: <VideoCamera size={16} />, tone: 'info' },
};

export function InstructorOverview() {
  const { profile, to } = useProfile();
  const now = useNow();
  const { instructor, courses, reach, activity } = profile;
  const maxCity = Math.max(1, ...reach.cities.map((c) => c.count));

  return (
    <div className={styles.overviewGrid}>
      <div className={styles.column}>
        <section className={styles.panel} aria-labelledby="about-title">
          <SectionHeader id="about-title" title="About" />
          {instructor.bio ? (
            <p className={styles.bio}>{instructor.bio}</p>
          ) : (
            <p className={styles.muted}>No bio yet. It’s shown on every course page they teach.</p>
          )}
          <div className={styles.aboutRow}>
            <span className={styles.aboutLabel}>Expertise</span>
            <span className={styles.chips}>
              {instructor.expertise.map((x) => (
                <span key={x} className={styles.chip}>
                  {x}
                </span>
              ))}
            </span>
          </div>
          <div className={styles.aboutRow}>
            <span className={styles.aboutLabel}>Teaches in</span>
            <span>{instructor.languages.join(', ')}</span>
          </div>
        </section>

        <section className={styles.panel} aria-labelledby="portfolio-title">
          <SectionHeader
            id="portfolio-title"
            title="Course portfolio"
            count={courses.length}
            actions={
              courses.length > 4 ? (
                <LinkButton size="sm" variant="ghost" to={`${to}/courses`} iconEnd={<ArrowRight size={14} />}>
                  All courses
                </LinkButton>
              ) : undefined
            }
          />
          {courses.length === 0 ? (
            <StateMessage
              compact
              icon={<BookOpen size={24} />}
              title="No courses assigned"
              actions={
                <LinkButton size="sm" to={`${to}/edit`}>
                  Assign courses
                </LinkButton>
              }
            >
              Assign a course so they can build lessons, run live classes and review work.
            </StateMessage>
          ) : (
            <ul className={styles.portfolio}>
              {courses.slice(0, 4).map((c) => (
                <li key={c.id} className={styles.portfolioCard}>
                  <CourseCover motif={c.coverMotif} imageUrl={c.coverImageUrl} className={styles.portfolioCover} />
                  <div className={styles.portfolioText}>
                    <Link to={`/admin/courses/${c.id}`} className={styles.cellTitle}>
                      {c.title}
                    </Link>
                    <span className={styles.cellMeta}>
                      {c.role === 'lead' ? 'Lead instructor' : 'Co-instructor'} · {c.levelTitle}
                    </span>
                    <span className={styles.portfolioFacts}>
                      {c.status === 'published' ? <Rating value={c.rating} /> : <CourseStatusBadge status={c.status} />}
                      <span>{formatCount(c.enrolled)} learners</span>
                    </span>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>

      <div className={styles.column}>
        <section className={styles.panel} aria-labelledby="reach-title">
          <SectionHeader id="reach-title" title="Student reach" description="Unique learners across their courses." />
          <dl className={styles.reach}>
            <div>
              <dt>Learning now</dt>
              <dd className="tabular">{formatCount(reach.active)}</dd>
            </div>
            <div>
              <dt>Completed a course</dt>
              <dd className="tabular">{formatCount(reach.completed)}</dd>
            </div>
          </dl>
          {reach.cities.length > 0 && (
            <ul className={styles.cities} aria-label="Top cities">
              {reach.cities.map((c) => (
                <li key={c.city}>
                  <span className={styles.cityName}>{c.city}</span>
                  <span className={styles.cityBar} aria-hidden="true">
                    <span style={{ width: `${(c.count / maxCity) * 100}%` }} />
                  </span>
                  <span className={styles.cityCount}>{formatCount(c.count)}</span>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className={styles.panel} aria-labelledby="inst-activity-title">
          <SectionHeader id="inst-activity-title" title="Recent activity" />
          {activity.length === 0 ? (
            <p className={styles.muted}>{instructor.status === 'invited' ? 'Activity starts once they accept the invitation.' : 'Nothing recent.'}</p>
          ) : (
            <ol className={styles.feed}>
              {activity.slice(0, 8).map((e) => (
                <li key={e.id} className={styles.feedItem}>
                  <IconChip tone={EVENT[e.kind].tone}>{EVENT[e.kind].icon}</IconChip>
                  <span className={styles.feedText}>
                    <span>{e.summary.charAt(0).toUpperCase() + e.summary.slice(1)}</span>
                    {e.context && <span className={styles.cellMeta}>{e.context}</span>}
                  </span>
                  <time className={styles.feedTime} dateTime={e.at}>
                    {formatRelative(e.at, now)}
                  </time>
                </li>
              ))}
            </ol>
          )}
        </section>
      </div>
    </div>
  );
}

/* ─── Courses ──────────────────────────────────────────────────────────── */

export function InstructorCourses() {
  const { profile, to } = useProfile();
  const now = useNow();
  const columns: Column<InstructorCourse>[] = [
    {
      key: 'course',
      header: 'Course',
      mobile: 'primary',
      render: (c) => (
        <span className={styles.courseCell}>
          <CourseCover motif={c.coverMotif} imageUrl={c.coverImageUrl} className={styles.courseThumb} />
          <span className={styles.stack}>
            <Link to={`/admin/courses/${c.id}`} className={styles.cellTitle}>
              {c.title}
            </Link>
            <span className={styles.cellMeta}>
              {c.levelTitle} · {plural(c.lessons, 'lesson')}
            </span>
          </span>
        </span>
      ),
    },
    {
      key: 'role',
      header: 'Role',
      width: '160px',
      mobile: 'meta',
      render: (c) => (
        <span className={styles.stack}>
          <span>{c.role === 'lead' ? 'Lead' : 'Co-instructor'}</span>
          {c.coInstructors.length > 0 && <span className={styles.cellMeta}>With {c.coInstructors.join(', ')}</span>}
        </span>
      ),
    },
    {
      key: 'learners',
      header: 'Learners',
      width: '110px',
      align: 'end',
      mobile: 'detail',
      render: (c) => (
        <span className={styles.stack}>
          <span className="tabular">{formatCount(c.enrolled)}</span>
          <span className={styles.cellMeta}>{formatCount(c.activeLearners)} active</span>
        </span>
      ),
    },
    {
      key: 'rating',
      header: 'Rating',
      width: '130px',
      mobile: 'detail',
      render: (c) => (c.status === 'published' ? <Rating value={c.rating} count={c.ratingCount} /> : <span className={styles.muted}>—</span>),
    },
    {
      key: 'completion',
      header: 'Completion',
      width: '140px',
      mobile: 'detail',
      render: (c) =>
        c.completion === null ? (
          <span className={styles.muted}>No learners</span>
        ) : (
          <span className={styles.rateCell}>
            <Meter value={c.completion} size="sm" label={`${c.title}: ${c.completion}% completion`} />
            <span className="tabular">{c.completion}%</span>
          </span>
        ),
    },
    {
      key: 'updated',
      header: 'Updated',
      width: '110px',
      mobile: 'detail',
      render: (c) => <span className={styles.nowrap}>{formatRelative(c.updatedAt, now)}</span>,
    },
    { key: 'status', header: 'Status', width: '110px', mobile: 'status', render: (c) => <CourseStatusBadge status={c.status} /> },
  ];

  return (
    <div className={styles.tabBody}>
      <SectionHeader
        title="Courses"
        count={profile.courses.length}
        description="The first instructor listed on a course leads it."
        actions={
          <LinkButton size="sm" to={`${to}/edit`} iconStart={<PencilSimple size={15} />}>
            Change courses
          </LinkButton>
        }
      />
      {profile.courses.length === 0 ? (
        <StateMessage
          icon={<BookOpen size={26} />}
          title="No courses assigned"
          actions={
            <LinkButton to={`${to}/edit`} variant="primary">
              Assign courses
            </LinkButton>
          }
        >
          Assigned instructors can edit a course, run its live classes and review submissions.
        </StateMessage>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable label="Courses" rows={profile.courses} columns={columns} rowKey={(c) => c.id} rowLabel={(c) => c.title} />
        </div>
      )}
    </div>
  );
}

/* ─── Performance ──────────────────────────────────────────────────────── */

/** "0.2 above the academy’s 4.6" — for a rating, or percentage points for a rate. */
function compare(value: number | null, academy: number, kind: 'rating' | 'percent') {
  if (value === null) return 'Not enough data yet';
  const digits = kind === 'rating' ? 1 : 0;
  const diff = Math.round((value - academy) * 10 ** digits) / 10 ** digits;
  const base = kind === 'rating' ? academy.toFixed(1) : `${academy}%`;
  if (diff === 0) return `Level with the platform’s ${base}`;
  const amount = kind === 'rating' ? Math.abs(diff).toFixed(1) : plural(Math.abs(diff), 'point');
  return `${amount} ${diff > 0 ? 'above' : 'below'} the platform’s ${base}`;
}

export function InstructorPerformance() {
  const { profile } = useProfile();
  const p = profile.performance;
  const published = profile.courses.filter((c) => c.status === 'published');

  if (published.length === 0 && p.reviewed === 0) {
    return (
      <StateMessage icon={<ChartLineUp size={26} />} title="No performance data yet">
        Ratings, completion and review speed appear once one of their courses is published and learners enroll.
      </StateMessage>
    );
  }

  return (
    <div className={styles.tabBody}>
      <div className={styles.perfGrid}>
        <section className={styles.perfCard} aria-labelledby="perf-rating">
          <h2 id="perf-rating" className={styles.perfLabel}>
            Learner rating
          </h2>
          <Rating value={p.rating} count={p.ratingCount || undefined} size="lg" />
          <p className={styles.muted}>{compare(p.rating, p.academyRating, 'rating')}</p>
        </section>
        <section className={styles.perfCard} aria-labelledby="perf-completion">
          <h2 id="perf-completion" className={styles.perfLabel}>
            Completion
          </h2>
          <span className={styles.perfValue}>{p.completion === null ? '—' : `${p.completion}%`}</span>
          {p.completion !== null && <Meter value={p.completion} threshold={p.academyCompletion} size="sm" label="Completion against the platform average" />}
          <p className={styles.muted}>{compare(p.completion, p.academyCompletion, 'percent')}</p>
        </section>
        <section className={styles.perfCard} aria-labelledby="perf-reviews">
          <h2 id="perf-reviews" className={styles.perfLabel}>
            Review speed
          </h2>
          <span className={styles.perfValue}>
            {p.reviewHoursMedian === null
              ? '—'
              : p.reviewHoursMedian < 48
                ? plural(p.reviewHoursMedian, 'hour')
                : plural(Math.round(p.reviewHoursMedian / 24), 'day')}
          </span>
          <p className={styles.muted}>
            {p.reviewsOnTime === null
              ? 'No reviews yet.'
              : `Median time to return feedback · ${p.reviewsOnTime}% of ${formatCount(p.reviewed)} reviews inside 48 hours · ${p.toReview} waiting`}
          </p>
        </section>
        <section className={styles.perfCard} aria-labelledby="perf-live">
          <h2 id="perf-live" className={styles.perfLabel}>
            Live teaching
          </h2>
          <span className={styles.perfValue}>
            <CalendarCheck size={20} aria-hidden="true" className={styles.perfIcon} /> {p.liveDelivered}
          </span>
          <p className={styles.muted}>
            classes delivered{p.attendance !== null ? ` · ${p.attendance}% average attendance` : ''} · {p.liveUpcoming} upcoming
          </p>
        </section>
      </div>

      <section className={styles.panel} aria-labelledby="perf-enrollments">
        <SectionHeader id="perf-enrollments" title="New enrollments" description="Across their courses, month by month." />
        <ColumnChart
          data={p.enrollmentsByMonth}
          label="New enrollments per month"
          unit="enrollments"
          height={200}
          partialIndex={p.enrollmentsByMonth.length - 1}
          partialNote="This month so far"
        />
      </section>

      {published.length > 0 && (
        <section className={styles.panel} aria-labelledby="perf-courses">
          <SectionHeader id="perf-courses" title="By course" description="Published courses, highest rated first." />
          <ul className={styles.courseBars}>
            {[...published]
              .sort((a, b) => (b.rating ?? 0) - (a.rating ?? 0))
              .map((c) => (
                <li key={c.id} className={styles.courseBar}>
                  <span className={styles.stack}>
                    <Link to={`/admin/courses/${c.id}`} className={styles.cellTitle}>
                      {c.title}
                    </Link>
                    <span className={styles.cellMeta}>{formatCount(c.enrolled)} learners</span>
                  </span>
                  <Rating value={c.rating} count={c.ratingCount} />
                  <span className={styles.rateCell}>
                    <Meter value={c.completion ?? 0} size="sm" label={`${c.title}: ${c.completion ?? 0}% completion`} />
                    <span className="tabular">{c.completion ?? 0}%</span>
                  </span>
                </li>
              ))}
          </ul>
        </section>
      )}
    </div>
  );
}
