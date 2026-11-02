import {
  BookOpenText,
  CalendarPlus,
  ChalkboardTeacher,
  CheckCircle,
  ClipboardText,
  GraduationCap,
  Plus,
  Sparkle,
  UserPlus,
  UsersThree,
} from '@phosphor-icons/react';
import { REVIEW_WINDOW_HOURS, deriveLiveClassPhase, type DashboardSnapshot } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useNow } from '@/hooks/useNow';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatCount, formatLongDay, greeting, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { IconChip } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useSession } from '@/providers/SessionProvider';
import { services } from '@/services';
import {
  CoursePerformance,
  LearningActivitySection,
  LiveThisWeek,
  NeedsAttention,
  QuickActions,
  RecentActivity,
  TopCourses,
  type Lookups,
} from './DashboardSections';
import { isNewAcademy, setupSteps, type SetupStepId } from './dashboardState';
import { StatCards, StatCardsSkeleton, type StatItem } from '@/components/data/StatCards';
import styles from './Dashboard.module.css';

/**
 * The platform command center, written for someone who is not technical: every figure says what it counts in plain words,
 * every change is a sentence, and the next thing to do is a button. `/admin` shows the whole academy; `/teach` shows
 * the same composition scoped to the signed-in instructor's courses and learners.
 */
export default function DashboardPage() {
  const { base, scope, isTeaching } = useWorkspace();
  const { user, role } = useSession();
  const { canOpen } = usePermissions();
  const now = useNow();
  const isAdmin = (role === 'admin' || role === 'superadmin') && !isTeaching;

  const query = useAsync(`dashboard:${base}`, () =>
    Promise.all([
      services.dashboard.getSnapshot(scope),
      services.catalog.listCourses(),
      services.catalog.listInstructors(),
      services.catalog.listLevels(),
      services.catalog.listCategories(),
    ]).then(([snapshot, courses, instructors, levels, categories]) => ({
      snapshot,
      lookups: {
        courses: new Map(courses.map((c) => [c.id, c])),
        instructors: new Map(instructors.map((i) => [i.id, i])),
        levels,
        categories: new Map(categories.map((c) => [c.id, c])),
      } satisfies Lookups,
    })),
  );

  const firstName = user.name.replace(/^(Dr\.|Acharya|Pt\.)\s+/, '').split(' ')[0];
  const title = isTeaching ? 'Teaching overview' : 'Dashboard';
  const actions = (
    <>
      {isTeaching ? (
        <LinkButton to={`${base}/assignments/review`} iconStart={<ClipboardText size={16} />}>
          Mark student work
        </LinkButton>
      ) : (
        <LinkButton to={`${base}/live/new`} iconStart={<CalendarPlus size={16} />} variant="secondary">
          Schedule a live class
        </LinkButton>
      )}
      <LinkButton to={`${base}/courses/new`} iconStart={<Plus size={16} />}>
        Add a course
      </LinkButton>
    </>
  );

  const data = query.data;
  const isEmpty = data && isNewAcademy(data.snapshot);
  const description =
    data && !isEmpty
      ? summarise(data.snapshot, data.lookups, isTeaching, firstName, now)
      : isTeaching
        ? 'Your courses, students and work to mark — all in one place.'
        : 'Everything happening on the platform — courses, students, live classes and what needs you today.';

  return (
    <div className={styles.page}>
      <div className={styles.inner}>
        <PageHeader eyebrow={formatLongDay(now)} title={title} description={description} actions={actions} />

        {query.status === 'error' && !data ? (
          <StateMessage
            kind="error"
            title="The dashboard didn’t load"
            actions={
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            }
          >
            {query.error.message} Your data is safe — nothing was changed.
          </StateMessage>
        ) : !data ? (
          <DashboardSkeleton teaching={isTeaching} />
        ) : isEmpty ? (
          isAdmin ? (
            <SetupChecklist base={base} courses={data.lookups.courses.size} instructors={data.lookups.instructors.size} />
          ) : (
            <DashboardEmpty base={base} teaching={isTeaching} />
          )
        ) : (
          <div className={styles.board}>
            <div className={styles.railTop}>
              <NeedsAttention items={data.snapshot.attention} />
              <QuickActions teaching={isTeaching} base={base} />
              <LiveThisWeek classes={data.snapshot.upcomingLive} lookups={data.lookups} now={now} base={base} />
            </div>
            <div className={styles.kpis}>
              <StatCards label="Key numbers" items={statItems(data.snapshot, data.lookups, isTeaching, base, canOpen)} />
            </div>
            <div className={styles.main}>
              <CoursePerformance snapshot={data.snapshot} lookups={data.lookups} base={base} />
              <LearningActivitySection snapshot={data.snapshot} />
              <RecentActivity events={data.snapshot.events} now={now} teaching={isTeaching} />
            </div>
            <div className={styles.railBottom}>
              <TopCourses snapshot={data.snapshot} lookups={data.lookups} base={base} />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function summarise(snapshot: DashboardSnapshot, lookups: Lookups, teaching: boolean, firstName: string, now: Date) {
  const liveNow = snapshot.upcomingLive.find((c) => deriveLiveClassPhase(c, now) === 'live');
  const liveCount = snapshot.upcomingLive.length;
  const upcoming = liveNow
    ? `${liveNow.title} is live right now.`
    : liveCount
      ? `${plural(liveCount, 'live class', 'live classes')} ${liveCount === 1 ? 'is' : 'are'} coming up this week.`
      : 'No live classes this week.';
  if (teaching) {
    const waiting = snapshot.kpis.third.value;
    const work = waiting
      ? `${plural(waiting, 'piece', 'pieces')} of student work ${waiting === 1 ? 'is' : 'are'} waiting for you to mark.`
      : 'No student work is waiting to be marked.';
    return `${greeting(now)}, ${firstName}. ${work} ${upcoming}`;
  }
  const attention = snapshot.attention.length;
  const todo = attention ? `${plural(attention, 'thing')} ${attention === 1 ? 'needs' : 'need'} your attention.` : 'Nothing needs your attention right now.';
  const top = [...snapshot.courses].sort((a, b) => sumLast(b.weeklyEnrollments) - sumLast(a.weeklyEnrollments))[0];
  const topTitle = top ? lookups.courses.get(top.courseId)?.title : undefined;
  const joined = top ? sumLast(top.weeklyEnrollments) : 0;
  const popular = topTitle && joined ? ` Most popular this month: ${topTitle} (${plural(joined, 'new student')}).` : '';
  return `${greeting(now)}, ${firstName}. ${todo} ${upcoming}${popular}`;
}

const sumLast = (values: number[]) => values.slice(-4).reduce((n, v) => n + v, 0);

function statItems(snapshot: DashboardSnapshot, lookups: Lookups, teaching: boolean, base: string, canOpen: (to: string) => boolean): StatItem[] {
  const { kpis } = snapshot;
  const scopedCourses = [...lookups.courses.values()].filter((c) => snapshot.scope.kind === 'academy' || c.instructorIds.includes(snapshot.scope.instructorId));
  const drafts = scopedCourses.filter((c) => c.status === 'draft').length;
  const invited = [...lookups.instructors.values()].filter((i) => i.status === 'invited').length;
  const joined = kpis.students.value - kpis.students.previous;
  // A card leads to its page only for an account that may open it; otherwise it is just a figure.
  const link = (to: string, linkLabel: string) => (canOpen(to) ? { to, linkLabel } : {});
  return [
    {
      id: 'courses',
      label: teaching ? 'My published courses' : 'Published courses',
      help: 'Courses students can see and join right now.',
      icon: <BookOpenText size={18} weight="duotone" />,
      hue: 'violet',
      kpi: kpis.courses,
      value: String(kpis.courses.value),
      since: 'last month',
      absolute: true,
      noun: ['course', 'courses'],
      note: drafts ? `${plural(drafts, 'draft')} not published yet` : 'No unfinished drafts',
      ...link(`${base}/courses`, 'Open courses'),
    },
    {
      id: 'students',
      label: teaching ? 'My students' : 'Students',
      help: teaching ? 'Students enrolled in at least one of your courses.' : 'Everyone who has joined the platform.',
      icon: <UsersThree size={18} weight="duotone" />,
      hue: 'blue',
      kpi: kpis.students,
      value: formatCount(kpis.students.value),
      since: 'last month',
      note: joined > 0 ? `${plural(joined, 'new student')} in the last 30 days` : 'No new students in the last 30 days',
      ...link(`${base}/students`, 'Open students'),
    },
    teaching
      ? {
          id: 'reviews',
          label: 'Work to mark',
          help: 'Assignments students handed in that still need your feedback.',
          icon: <ClipboardText size={18} weight="duotone" />,
          hue: 'orange',
          kpi: kpis.third,
          value: String(kpis.third.value),
          since: 'last week',
          good: 'down',
          absolute: true,
          note: kpis.third.value ? `Try to mark each one within ${REVIEW_WINDOW_HOURS} hours` : 'You’re all caught up',
          ...link(`${base}/assignments/review`, 'Open the marking queue'),
        }
      : {
          id: 'instructors',
          label: 'Instructors',
          help: 'Teachers who have accepted their invitation.',
          icon: <ChalkboardTeacher size={18} weight="duotone" />,
          hue: 'green',
          kpi: kpis.third,
          value: String(kpis.third.value),
          since: 'last month',
          absolute: true,
          noun: ['instructor', 'instructors'],
          note: invited ? `${plural(invited, 'invitation')} not accepted yet` : 'Every invitation accepted',
          ...link(`${base}/instructors`, 'Open instructors'),
        },
    {
      id: 'completion',
      label: 'Finished their course',
      help: 'Of students who enrolled 60 or more days ago, how many have finished.',
      icon: <GraduationCap size={18} weight="duotone" />,
      hue: 'gold',
      kpi: kpis.completionRate,
      value: `${Math.round(kpis.completionRate.value)}%`,
      since: 'last month',
      // Reports are an admin page; the teaching workspace has none to lead to.
      ...(teaching ? {} : link(`${base}/reports`, 'Open reports')),
    },
  ];
}

/* ─── States ───────────────────────────────────────────────────────────── */

function DashboardSkeleton({ teaching }: { teaching: boolean }) {
  return (
    <div className={styles.board} role="status" aria-label="Loading the dashboard">
      <div className={styles.railTop}>
        {[teaching ? 3 : 4, 4, 3].map((rows, s) => (
          <div key={s} className={styles.skeletonBlock}>
            <Skeleton width={140} height={16} radius="var(--r-xs)" />
            {Array.from({ length: rows }, (_, i) => (
              <div key={i} className={styles.skeletonRow}>
                <Skeleton width={36} height={36} radius="var(--r-sm)" />
                <span className={styles.skeletonLines}>
                  <Skeleton width="80%" height={10} />
                  <Skeleton width="55%" height={8} />
                </span>
              </div>
            ))}
          </div>
        ))}
      </div>
      <div className={styles.kpis}>
        <StatCardsSkeleton
          labels={[
            teaching ? 'My published courses' : 'Published courses',
            teaching ? 'My students' : 'Students',
            teaching ? 'Work to mark' : 'Instructors',
            'Finished their course',
          ]}
        />
      </div>
      <div className={styles.main}>
        <div className={`${styles.panel} ${styles.skeletonBlock}`}>
          <Skeleton width={180} height={16} radius="var(--r-xs)" />
          <Skeleton width={90} height={24} radius="var(--r-xs)" />
          <Skeleton width="100%" height={200} radius="var(--r-md)" />
          {Array.from({ length: 4 }, (_, i) => (
            <Skeleton key={i} width="100%" height={12} />
          ))}
        </div>
        <div className={`${styles.panel} ${styles.skeletonBlock}`}>
          <Skeleton width={200} height={16} radius="var(--r-xs)" />
          <Skeleton width="100%" height={160} radius="var(--r-md)" />
        </div>
      </div>
      <div className={styles.railBottom} />
    </div>
  );
}

function DashboardEmpty({ base, teaching }: { base: string; teaching: boolean }) {
  const steps = teaching
    ? [
        {
          title: 'Start your first course',
          text: 'Add chapters and lessons. Students can’t see it until an admin publishes it.',
          action: (
            <LinkButton to={`${base}/courses/new`} iconStart={<Plus size={16} />}>
              Add a course
            </LinkButton>
          ),
        },
        {
          title: 'Plan a live class',
          text: 'A welcome class helps new students settle in. They get a reminder 15 minutes before it starts.',
          action: (
            <LinkButton to={`${base}/live/new`} iconStart={<CalendarPlus size={16} />} variant="secondary">
              Schedule a live class
            </LinkButton>
          ),
        },
      ]
    : [];

  return (
    <section className={styles.onboarding} aria-labelledby="onboarding-title">
      <div className={styles.onboardingIntro}>
        <IconChip size="xl">
          <Sparkle size={26} />
        </IconChip>
        <h2 id="onboarding-title" className={styles.onboardingTitle}>
          {teaching ? 'No courses assigned to you yet' : 'The platform is ready for its first course'}
        </h2>
        <p className={styles.onboardingText}>
          Your numbers and charts show up here once a course is published and students join. These two steps get you started.
        </p>
      </div>
      <ol className={styles.steps}>
        {steps.map((step, i) => (
          <li key={step.title} className={styles.step}>
            <span className={styles.stepIndex} aria-hidden="true">
              {String(i + 1).padStart(2, '0')}
            </span>
            <span className={styles.stepText}>
              <h3 className={styles.stepTitle}>{step.title}</h3>
              <p className={styles.stepBody}>{step.text}</p>
            </span>
            <span className={styles.stepAction}>{step.action}</span>
          </li>
        ))}
      </ol>
    </section>
  );
}

const SETUP_COPY: Record<SetupStepId, { title: string; text: string; done: string }> = {
  course: {
    title: 'Create your first course',
    text: 'Add a course with its chapters and lessons. Only you can see it until you publish it.',
    done: 'Your first course is in the catalog.',
  },
  instructor: {
    title: 'Invite an instructor',
    text: 'Instructors add lessons, teach live classes and mark students’ work from their own login.',
    done: 'Your first instructor is on board.',
  },
};

/**
 * A new platform's dashboard: no learners and no enrolments yet, so no charts — the steps that get it going, ticked
 * off as they are taken.
 */
function SetupChecklist({ base, courses, instructors }: { base: string; courses: number; instructors: number }) {
  const steps = setupSteps({ courses, instructors });
  const left = steps.filter((s) => !s.done).length;
  const action = (id: SetupStepId) =>
    id === 'course' ? (
      <LinkButton to={`${base}/courses/new`} iconStart={<Plus size={16} />}>
        Add a course
      </LinkButton>
    ) : (
      <LinkButton to={`${base}/instructors/new`} iconStart={<UserPlus size={16} />}>
        Invite an instructor
      </LinkButton>
    );

  return (
    <section className={styles.onboarding} aria-labelledby="onboarding-title" data-testid="setup-checklist">
      <div className={styles.onboardingIntro}>
        <IconChip size="xl">
          <Sparkle size={26} />
        </IconChip>
        <h2 id="onboarding-title" className={styles.onboardingTitle}>
          Set up the platform
        </h2>
        <p className={styles.onboardingText}>
          Your numbers and charts show up here once students join.{' '}
          {left === 0 ? 'Every step is done — publish a course to welcome your first students.' : `${plural(left, 'step')} left.`}
        </p>
      </div>
      <ol className={styles.steps}>
        {steps.map((step, i) => (
          <li key={step.id} className={styles.step} data-done={step.done || undefined}>
            <span className={styles.stepIndex} aria-hidden="true">
              {step.done ? <CheckCircle size={26} weight="fill" /> : String(i + 1).padStart(2, '0')}
            </span>
            <span className={styles.stepText}>
              <h3 className={styles.stepTitle}>
                {SETUP_COPY[step.id].title}
                {step.done && <span className="sr-only"> (done)</span>}
              </h3>
              <p className={styles.stepBody}>{step.done ? SETUP_COPY[step.id].done : SETUP_COPY[step.id].text}</p>
            </span>
            {!step.done && <span className={styles.stepAction}>{action(step.id)}</span>}
          </li>
        ))}
      </ol>
    </section>
  );
}
