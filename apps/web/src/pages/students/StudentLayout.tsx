import { createContext, useContext, useState } from 'react';
import { Link, Outlet, useLocation, useParams } from 'react-router-dom';
import {
  ArrowLeft,
  ChatText,
  ClockCounterClockwise,
  DotsThree,
  GraduationCap,
  ListChecks,
  Prohibit,
  SquaresFour,
  Trophy,
  UserPlus,
} from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatDate, formatDuration, plural } from '@/lib/format';
import { Figure } from '@/components/data/KpiStrip';
import { RouteTabs } from '@/components/page/RouteTabs';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type StudentProfile } from '@/services';
import { EnrollDialog, MessageDialog, StudentStatusBadge } from './studentMeta';
import styles from './Students.module.css';

interface StudentWorkspace {
  profile: StudentProfile;
  base: string;
  isTeaching: boolean;
  /** Set in the teaching workspace; every read is limited to that instructor's courses. */
  instructorId?: string;
  to: string;
  refresh: () => void;
  message: (draft?: { subject: string; body: string }) => void;
  enroll: () => void;
}

const StudentContext = createContext<StudentWorkspace | null>(null);

export function useStudentWorkspace() {
  const ctx = useContext(StudentContext);
  if (!ctx) throw new Error('useStudentWorkspace must be used inside StudentLayout');
  return ctx;
}

const SUBPAGES: Record<string, string> = { courses: 'Courses', progress: 'Progress', activity: 'Activity' };

/** A nudge for someone who has gone quiet, written to be edited before sending. */
export function nudgeDraft(profile: StudentProfile) {
  const first = profile.student.name.split(' ')[0];
  const course = profile.enrollments.find((e) => e.enrollment.status === 'active');
  return {
    subject: course ? `Pick up ${course.courseTitle} where you left off` : 'We miss you at ZuviloAI',
    body: course
      ? `Hi ${first},\n\nIt’s been a little while since your last lesson in ${course.courseTitle}. You’re ${course.enrollment.progress}% of the way through${course.lastLessonTitle ? ` — next up is “${course.lastLessonTitle}”` : ''}.\n\nTwenty minutes this week is enough to get the rhythm back. Reply here if anything is getting in the way.\n\nWarmly,`
      : `Hi ${first},\n\nWe noticed you haven’t been in for a while. Reply here if we can help you find the right next course.\n\nWarmly,`,
  };
}

export default function StudentLayout() {
  const { can } = usePermissions();
  const { studentId } = useParams();
  const { base, instructorId, isTeaching } = useWorkspace();
  const { pathname } = useLocation();
  const toast = useToast();
  const query = useAsync(`student:${studentId}`, () => services.students.get(studentId!, instructorId));
  const [messaging, setMessaging] = useState<null | { subject: string; body: string } | 'blank'>(null);
  const [enrolling, setEnrolling] = useState(false);
  const [suspending, setSuspending] = useState(false);
  const refresh = () => query.run().catch(() => undefined);

  const to = `${base}/students/${studentId}`;
  const segment = pathname
    .split('/')
    .filter(Boolean)
    .find((s) => SUBPAGES[s]);
  usePageCrumbs(
    query.data ? [{ label: query.data.student.name, to }, ...(segment ? [{ label: SUBPAGES[segment] }] : [])] : [{ label: isTeaching ? 'Learner' : 'Student' }],
  );

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? `${isTeaching ? 'Learner' : 'Student'} not found` : 'This profile didn’t load'}
          actions={
            notFound ? (
              <LinkButton to={`${base}/students`} iconStart={<ArrowLeft size={16} />}>
                Back to {isTeaching ? 'learners' : 'students'}
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={refresh}>
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
  if (!query.data || query.data.student.id !== studentId) {
    return (
      <div className={styles.page} role="status" aria-label="Loading profile">
        <div className={styles.profileHead}>
          <Skeleton width={72} height={72} radius="var(--r-pill)" />
          <div className={styles.profileText}>
            <Skeleton width={120} height={10} />
            <Skeleton width="40%" height={28} radius="var(--r-xs)" />
            <Skeleton width={260} height={10} />
          </div>
        </div>
        <Skeleton height={84} radius="var(--r-md)" />
        <Skeleton height={360} radius="var(--r-lg)" />
      </div>
    );
  }

  const profile = query.data;
  const { student, summary, rank } = profile;
  const value: StudentWorkspace = {
    profile,
    base,
    isTeaching,
    instructorId,
    to,
    refresh,
    message: (draft) => setMessaging(draft ?? 'blank'),
    enroll: () => setEnrolling(true),
  };

  return (
    <StudentContext.Provider value={value}>
      <div className={styles.page}>
        <Link to={`${base}/students`} className={styles.back}>
          <ArrowLeft size={14} aria-hidden="true" /> {isTeaching ? 'Learners' : 'Students'}
        </Link>
        <header className={styles.profileHead}>
          <Avatar name={student.name} size={72} className={styles.profileAvatar} />
          <div className={styles.profileText}>
            <span className={styles.eyebrow}>
              <Trophy size={13} aria-hidden="true" /> {rank.title}
            </span>
            <h1 className={styles.profileName}>{student.name}</h1>
            <div className={styles.profileMeta}>
              <StudentStatusBadge status={profile.status} size="md" />
              <span>{student.email}</span>
              <span>{student.city}</span>
              <span>Joined {formatDate(student.joinedAt)}</span>
              <Badge size="sm" tone="neutral" appearance="outline" className="tabular">
                {student.id}
              </Badge>
            </div>
          </div>
          <div className={styles.profileActions}>
            {can('learners.message') && (
              <Button
                variant={profile.status === 'at-risk' ? 'primary' : 'secondary'}
                iconStart={<ChatText size={16} />}
                onClick={() => setMessaging(profile.status === 'at-risk' ? nudgeDraft(profile) : 'blank')}
              >
                {profile.status === 'at-risk' ? 'Send a nudge' : 'Message'}
              </Button>
            )}
            {!isTeaching && (
              <>
                {can('learners.enroll') && (
                  <Button iconStart={<UserPlus size={16} />} onClick={() => setEnrolling(true)} disabled={profile.status === 'suspended'}>
                    Enroll
                  </Button>
                )}
                <Menu
                  align="end"
                  width={200}
                  trigger={(props) => <IconButton {...props} boxed label="More actions" icon={<DotsThree size={18} weight="bold" />} />}
                  sections={[
                    {
                      items: !can('learners.suspend')
                        ? []
                        : [
                            profile.status === 'suspended'
                              ? { id: 'restore', label: 'Restore access', icon: <Prohibit size={17} />, onSelect: () => setSuspending(true) }
                              : {
                                  id: 'suspend',
                                  label: 'Suspend access…',
                                  icon: <Prohibit size={17} />,
                                  tone: 'danger' as const,
                                  onSelect: () => setSuspending(true),
                                },
                          ],
                    },
                  ]}
                />
              </>
            )}
          </div>
        </header>

        <dl className={styles.figures}>
          <Figure label={summary.enrolled === 1 ? 'course' : 'courses'} value={String(summary.enrolled)}>
            <span className={styles.figureNote}>
              {summary.completed} completed · {summary.active} in progress
            </span>
          </Figure>
          <Figure label="average progress" value={`${summary.avgProgress}%`}>
            <span className={styles.figureNote}>{summary.active ? 'Across courses in progress' : 'Across all courses'}</span>
          </Figure>
          <Figure label="studied" value={formatDuration(summary.studyMinutes)}>
            <span className={styles.figureNote}>{profile.quietDays === 0 ? 'Active today' : `Last active ${plural(profile.quietDays, 'day')} ago`}</span>
          </Figure>
          <Figure label={profile.certificates.length === 1 ? 'certificate' : 'certificates'} value={String(profile.certificates.length)} />
          <Figure label="assignment average" value={summary.avgScore === null ? '—' : `${summary.avgScore}%`}>
            <span className={styles.figureNote}>{plural(summary.submissions, 'submission')}</span>
          </Figure>
        </dl>

        <RouteTabs
          label={`${student.name}’s profile`}
          tabs={[
            { to, label: 'Overview', icon: <SquaresFour size={16} />, end: true },
            { to: `${to}/courses`, label: 'Courses', icon: <GraduationCap size={16} />, count: summary.enrolled },
            { to: `${to}/progress`, label: 'Progress', icon: <ListChecks size={16} /> },
            { to: `${to}/activity`, label: 'Activity', icon: <ClockCounterClockwise size={16} /> },
          ]}
        />

        <Outlet />

        {messaging && (
          <MessageDialog
            open
            onClose={() => setMessaging(null)}
            recipients={[{ id: student.id, name: student.name }]}
            draft={messaging === 'blank' ? undefined : messaging}
          />
        )}
        {enrolling && (
          <EnrollDialog
            open
            onClose={() => setEnrolling(false)}
            student={{ id: student.id, name: student.name }}
            enrolledCourseIds={profile.enrollments.map((e) => e.enrollment.courseId)}
            onEnrolled={refresh}
          />
        )}
        {suspending && (
          <ConfirmDialog
            open
            onClose={() => setSuspending(false)}
            onConfirm={async () => {
              const restore = profile.status === 'suspended';
              await services.students.setSuspended(student.id, !restore);
              toast({ kind: 'success', title: restore ? 'Access restored' : 'Access suspended', text: student.name });
              setSuspending(false);
              refresh();
            }}
            tone={profile.status === 'suspended' ? 'default' : 'danger'}
            icon={<Prohibit size={20} />}
            title={profile.status === 'suspended' ? `Restore ${student.name}’s access?` : `Suspend ${student.name}?`}
            description={student.email}
            confirmLabel={profile.status === 'suspended' ? 'Restore access' : 'Suspend access'}
            acknowledge={profile.status === 'suspended' ? undefined : 'I’ve recorded the reason in the support ticket'}
          >
            <ul className={styles.impact}>
              {profile.status === 'suspended' ? (
                <li>They can sign in and continue their courses where they left off.</li>
              ) : (
                <>
                  <li>They can’t sign in or open lessons until access is restored.</li>
                  <li>Progress, submissions and {plural(profile.certificates.length, 'certificate')} are kept.</li>
                </>
              )}
            </ul>
          </ConfirmDialog>
        )}
      </div>
    </StudentContext.Provider>
  );
}
