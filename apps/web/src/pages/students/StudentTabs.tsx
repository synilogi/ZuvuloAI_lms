import { Fragment, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowRight,
  BookOpen,
  Certificate,
  ClockCounterClockwise,
  DotsThree,
  Exam,
  GraduationCap,
  Pause,
  Play,
  SealCheck,
  Trash,
  UserPlus,
  WarningCircle,
} from '@phosphor-icons/react';
import type { ActivityKind } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { cx } from '@/lib/cx';
import { formatDate, formatDuration, formatLongDay, formatRelative, formatTime, pad2, plural } from '@/lib/format';
import { ColumnChart } from '@/components/charts/Charts';
import { SectionHeader } from '@/components/page/PageHeader';
import { Badge, IconChip } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, Select } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { ACTIVITY_KIND } from '@/components/lms/activity/LearningActivity';
import { Meter } from '@/components/lms/progress/Meters';
import { ProgressRing } from '@/components/lms/progress/ProgressRing';
import { services, type StudentEnrollment, type StudentProgress } from '@/services';
import { nudgeDraft, useStudentWorkspace } from './StudentLayout';
import { EnrollmentStatusBadge, SOURCE } from './studentMeta';
import styles from './Students.module.css';

/* ─── Overview ─────────────────────────────────────────────────────────── */

export function StudentOverview() {
  const { profile, to, base, message, isTeaching, instructorId, enroll } = useStudentWorkspace();
  const now = useNow();
  const activity = useAsync(`student-activity-preview:${profile.student.id}:${profile.enrollments.length}`, () =>
    services.students.activity(profile.student.id, { limit: 6, scopeInstructorId: instructorId }),
  );
  const inProgress = profile.enrollments.filter((e) => e.enrollment.status === 'active');
  const shown = [...inProgress, ...profile.enrollments.filter((e) => e.enrollment.status !== 'active')].slice(0, 3);

  return (
    <div className={styles.tabBody}>
      {profile.status === 'at-risk' && (
        <InlineMessage
          kind="warn"
          title={`Quiet for ${plural(profile.quietDays, 'day')} with ${plural(inProgress.length, 'course')} in progress`}
          action={
            <Button size="sm" onClick={() => message(nudgeDraft(profile))}>
              Send a nudge
            </Button>
          }
        >
          Learners who return within three weeks usually finish. A short, personal note works better than a reminder.
        </InlineMessage>
      )}
      {profile.status === 'suspended' && (
        <InlineMessage kind="error" title="Access is suspended">
          {profile.student.name} can’t sign in or open lessons. Their progress and certificates are kept.
        </InlineMessage>
      )}

      <div className={styles.overviewGrid}>
        <div className={styles.column}>
          <section className={styles.panel} aria-labelledby="overview-courses">
            <SectionHeader
              id="overview-courses"
              title="Courses"
              count={profile.enrollments.length}
              actions={
                profile.enrollments.length > 3 ? (
                  <LinkButton size="sm" variant="ghost" to={`${to}/courses`} iconEnd={<ArrowRight size={14} />}>
                    All courses
                  </LinkButton>
                ) : undefined
              }
            />
            {shown.length === 0 ? (
              <StateMessage
                compact
                icon={<GraduationCap size={24} />}
                title="Not enrolled in a course"
                actions={
                  isTeaching ? undefined : (
                    <Button size="sm" iconStart={<UserPlus size={15} />} onClick={enroll}>
                      Enroll
                    </Button>
                  )
                }
              >
                Courses appear here once they enroll.
              </StateMessage>
            ) : (
              <ul className={styles.courseList}>
                {shown.map((e) => (
                  <CourseProgressRow key={e.enrollment.id} item={e} base={base} />
                ))}
              </ul>
            )}
          </section>

          <section className={styles.panel} aria-labelledby="overview-activity">
            <SectionHeader
              id="overview-activity"
              title="Recent activity"
              actions={
                <LinkButton size="sm" variant="ghost" to={`${to}/activity`} iconEnd={<ArrowRight size={14} />}>
                  All activity
                </LinkButton>
              }
            />
            {activity.status === 'error' && !activity.data ? (
              <InlineMessage
                kind="error"
                title="Activity didn’t load."
                action={
                  <Button size="sm" onClick={() => activity.run().catch(() => undefined)}>
                    Try again
                  </Button>
                }
              />
            ) : !activity.data ? (
              <div className={styles.skeletonList}>
                {Array.from({ length: 4 }, (_, i) => (
                  <Skeleton key={i} height={36} radius="var(--r-sm)" />
                ))}
              </div>
            ) : activity.data.events.length === 0 ? (
              <p className={styles.muted}>Nothing yet. Lessons, submissions and certificates appear here as they happen.</p>
            ) : (
              <ol className={styles.feed}>
                {activity.data.events.map((ev) => (
                  <li key={ev.id} className={styles.feedItem}>
                    <IconChip tone={ACTIVITY_KIND[ev.kind].tone}>{ACTIVITY_KIND[ev.kind].icon}</IconChip>
                    <span className={styles.feedText}>
                      <span>
                        {ACTIVITY_KIND[ev.kind].verb} <strong>{ev.title}</strong>
                      </span>
                      {ev.context && <span className={styles.cellMeta}>{ev.context}</span>}
                    </span>
                    <time className={styles.feedTime} dateTime={ev.at}>
                      {formatRelative(ev.at, now)}
                    </time>
                  </li>
                ))}
              </ol>
            )}
          </section>
        </div>

        <div className={styles.column}>
          <section className={styles.panel} aria-labelledby="overview-rank">
            <SectionHeader id="overview-rank" title="Rank" />
            <div className={styles.rank}>
              <span className={styles.rankOrbit} aria-hidden="true">
                {Array.from({ length: 4 }, (_, i) => (
                  <span key={i} className={cx(styles.orbit, i < profile.rank.order && styles.orbitOn)} style={{ inset: `${i * 9}px` }} />
                ))}
              </span>
              <div>
                <p className={styles.rankTitle}>{profile.rank.title}</p>
                <p className={styles.muted}>{profile.rank.descriptor}</p>
                {profile.rank.achievedAt && <p className={styles.cellMeta}>Reached {formatDate(profile.rank.achievedAt)}</p>}
              </div>
            </div>
          </section>

          <section className={styles.panel} aria-labelledby="overview-certs">
            <SectionHeader id="overview-certs" title="Certificates" count={profile.certificates.length || undefined} />
            {profile.certificates.length === 0 ? (
              <p className={styles.muted}>
                {inProgress.some((e) => e.certificateTitle)
                  ? `Working towards ${inProgress.find((e) => e.certificateTitle)!.certificateTitle}.`
                  : 'No certificates yet. They’re issued when a course with a certificate is completed.'}
              </p>
            ) : (
              <ul className={styles.certList}>
                {profile.certificates.map((c) => (
                  <li key={c.id} className={styles.cert}>
                    <IconChip tone="accent">
                      <Certificate size={18} />
                    </IconChip>
                    <span className={styles.feedText}>
                      <strong>{c.title}</strong>
                      <span className={styles.cellMeta}>
                        {formatDate(c.issuedAt)} · {c.credentialId}
                      </span>
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>
      </div>
    </div>
  );
}

function CourseProgressRow({ item, base }: { item: StudentEnrollment; base: string }) {
  const e = item.enrollment;
  return (
    <li className={styles.courseRow}>
      <div className={styles.courseRowHead}>
        <span className={styles.titleCell}>
          <Link to={`${base}/courses/${e.courseId}`} className={styles.cellTitle}>
            {item.courseTitle}
          </Link>
          <span className={styles.cellMeta}>
            {item.levelTitle} · {plural(item.chapters.done, 'chapter')} of {item.chapters.total} done
          </span>
        </span>
        <EnrollmentStatusBadge status={e.status} />
      </div>
      <Meter value={e.progress} size="sm" label={`${item.courseTitle}: ${e.progress}%`} />
      <span className={styles.courseRowFoot}>
        <span className="tabular">{e.progress}%</span>
        {e.status === 'active' && item.lastLessonTitle && <span className={styles.truncate}>Up next: {item.lastLessonTitle}</span>}
        {e.status === 'completed' && e.completedAt && <span>Completed {formatDate(e.completedAt)}</span>}
      </span>
    </li>
  );
}

/* ─── Courses ──────────────────────────────────────────────────────────── */

export function StudentCourses() {
  const { profile, base, isTeaching, refresh, enroll } = useStudentWorkspace();
  const toast = useToast();
  const now = useNow();
  const [removing, setRemoving] = useState<StudentEnrollment | null>(null);

  const setStatus = async (item: StudentEnrollment, status: 'active' | 'paused') => {
    try {
      await services.students.setEnrollmentStatus(item.enrollment.id, status);
      toast({ kind: 'success', title: status === 'paused' ? 'Enrollment paused' : 'Enrollment resumed', text: item.courseTitle });
      refresh();
    } catch (e) {
      toast({ kind: 'error', title: 'That didn’t work', text: (e as Error).message });
    }
  };

  const columns: Column<StudentEnrollment>[] = [
    {
      key: 'course',
      header: 'Course',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.titleCell}>
          <Link to={`${base}/courses/${r.enrollment.courseId}`} className={styles.cellTitle}>
            {r.courseTitle}
          </Link>
          <span className={styles.cellMeta}>
            {r.levelTitle} · {r.instructorNames.join(', ')}
          </span>
        </span>
      ),
    },
    {
      key: 'enrolled',
      header: 'Enrolled',
      width: '150px',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.titleCell}>
          <span>{formatDate(r.enrollment.enrolledAt)}</span>
          <span className={styles.cellMeta}>{SOURCE[r.enrollment.source]}</span>
        </span>
      ),
    },
    {
      key: 'progress',
      header: 'Progress',
      width: '200px',
      mobile: 'meta',
      render: (r) => (
        <span className={styles.progressCell}>
          <span className={styles.rateCell}>
            <Meter value={r.enrollment.progress} size="sm" label={`${r.courseTitle}: ${r.enrollment.progress}%`} />
            <span className="tabular">{r.enrollment.progress}%</span>
          </span>
          <span className={styles.cellMeta}>
            {r.lessons.done} of {plural(r.lessons.total, 'lesson')} · {r.chapters.done} of {plural(r.chapters.total, 'chapter')}
          </span>
        </span>
      ),
    },
    {
      key: 'active',
      header: 'Last active',
      width: '120px',
      mobile: 'detail',
      render: (r) => <span className={styles.nowrap}>{r.enrollment.lastActiveAt ? formatRelative(r.enrollment.lastActiveAt, now) : 'Not started'}</span>,
    },
    {
      key: 'certificate',
      header: 'Certificate',
      width: '130px',
      mobile: 'detail',
      render: (r) =>
        !r.certificateTitle ? (
          <span className={styles.muted}>None offered</span>
        ) : r.enrollment.status === 'completed' ? (
          <Badge size="sm" tone="accent" icon={<SealCheck size={13} weight="fill" />}>
            Issued
          </Badge>
        ) : (
          <span className={styles.muted}>At 80% and the final assessment</span>
        ),
    },
    { key: 'status', header: 'Status', width: '120px', mobile: 'status', render: (r) => <EnrollmentStatusBadge status={r.enrollment.status} /> },
    ...(isTeaching
      ? []
      : [
          {
            key: 'actions',
            header: 'Actions',
            width: '64px',
            align: 'end' as const,
            mobile: 'hidden' as const,
            render: (r: StudentEnrollment) => (
              <Menu
                align="end"
                width={210}
                trigger={(props) => <IconButton {...props} size="sm" label={`Actions for ${r.courseTitle}`} icon={<DotsThree size={18} weight="bold" />} />}
                sections={[
                  {
                    items: [
                      r.enrollment.status === 'paused'
                        ? { id: 'resume', label: 'Resume enrollment', icon: <Play size={17} />, onSelect: () => setStatus(r, 'active') }
                        : {
                            id: 'pause',
                            label: 'Pause enrollment',
                            icon: <Pause size={17} />,
                            disabled: r.enrollment.status === 'completed',
                            hint: r.enrollment.status === 'completed' ? 'Course completed' : undefined,
                            onSelect: () => setStatus(r, 'paused'),
                          },
                    ],
                  },
                  { items: [{ id: 'remove', label: 'Remove from course…', icon: <Trash size={17} />, tone: 'danger', onSelect: () => setRemoving(r) }] },
                ]}
              />
            ),
          },
        ]),
  ];

  return (
    <div className={styles.tabBody}>
      <SectionHeader
        title="Courses"
        count={profile.enrollments.length}
        description={
          isTeaching ? 'Courses you teach that this learner is enrolled in.' : 'Every enrollment, newest first. Pausing keeps progress and stops reminders.'
        }
        actions={
          !isTeaching && profile.status !== 'suspended' ? (
            <Button size="sm" iconStart={<UserPlus size={15} />} onClick={enroll}>
              Enroll in a course
            </Button>
          ) : undefined
        }
      />
      {profile.enrollments.length === 0 ? (
        <StateMessage
          icon={<GraduationCap size={26} />}
          title="Not enrolled in any course"
          actions={
            !isTeaching ? (
              <Button variant="primary" iconStart={<UserPlus size={16} />} onClick={enroll}>
                Enroll in a course
              </Button>
            ) : undefined
          }
        >
          Enroll them in a course to give them access straight away.
        </StateMessage>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable label="Courses" rows={profile.enrollments} columns={columns} rowKey={(r) => r.enrollment.id} rowLabel={(r) => r.courseTitle} />
        </div>
      )}
      {removing && (
        <ConfirmDialog
          open
          onClose={() => setRemoving(null)}
          onConfirm={async () => {
            await services.students.removeEnrollment(removing.enrollment.id);
            toast({ kind: 'success', title: 'Removed from course', text: `${profile.student.name} · ${removing.courseTitle}` });
            setRemoving(null);
            refresh();
          }}
          tone="danger"
          icon={<Trash size={20} />}
          title={`Remove ${profile.student.name} from ${removing.courseTitle}?`}
          confirmLabel="Remove from course"
          acknowledge={removing.enrollment.progress > 0 ? `I understand ${removing.enrollment.progress}% progress will be lost` : undefined}
        >
          <ul className={styles.impact}>
            <li>They lose access to the lessons, live classes and discussions straight away.</li>
            <li>Progress and draft submissions for this course are deleted. This can’t be undone.</li>
            {removing.enrollment.status === 'completed' && <li>Their certificate stays valid.</li>}
          </ul>
        </ConfirmDialog>
      )}
    </div>
  );
}

/* ─── Progress ─────────────────────────────────────────────────────────── */

export function StudentProgressTab() {
  const { profile, base, instructorId } = useStudentWorkspace();
  const progress = useAsync(`student-progress:${profile.student.id}:${profile.enrollments.length}`, () =>
    services.students.progress(profile.student.id, instructorId),
  );
  const [courseId, setCourseId] = useState<string | null>(null);

  if (progress.status === 'error' && !progress.data) {
    return (
      <StateMessage
        kind="error"
        title="Progress didn’t load"
        actions={
          <Button variant="primary" onClick={() => progress.run().catch(() => undefined)}>
            Try again
          </Button>
        }
      >
        {progress.error.message}
      </StateMessage>
    );
  }
  if (!progress.data) {
    return (
      <div className={styles.tabBody} aria-busy="true">
        <Skeleton height={280} radius="var(--r-lg)" />
        <Skeleton height={220} radius="var(--r-lg)" />
      </div>
    );
  }
  const p = progress.data;
  if (p.courses.length === 0) {
    return (
      <StateMessage icon={<BookOpen size={26} />} title="No progress to show">
        Progress appears once they’re enrolled in a course.
      </StateMessage>
    );
  }
  const current = p.courses.find((c) => c.courseId === courseId) ?? p.courses.find((c) => c.status === 'active') ?? p.courses[0];
  const studied = p.studyWeeks.reduce((n, w) => n + w.minutes, 0);

  return (
    <div className={styles.tabBody}>
      <section className={cx(styles.panel, styles.progressPanel)} aria-labelledby="progress-course">
        <SectionHeader id="progress-course" title="Course progress" description="Chapter by chapter, weighted by lesson length." />
        {p.courses.length <= 3 ? (
          <SegmentedControl
            size="sm"
            label="Course"
            value={current.courseId}
            onChange={setCourseId}
            segments={p.courses.map((c) => ({ value: c.courseId, label: c.courseTitle }))}
          />
        ) : (
          <Field label="Course" hideLabel className={styles.filter}>
            <Select value={current.courseId} onChange={(e) => setCourseId(e.target.value)}>
              {p.courses.map((c) => (
                <option key={c.courseId} value={c.courseId}>
                  {c.courseTitle}
                </option>
              ))}
            </Select>
          </Field>
        )}
        <div className={styles.progressLayout}>
          <div className={styles.ringBlock}>
            <ProgressRing
              value={current.progress}
              size="xl"
              label={`${current.courseTitle} progress`}
              segments={current.chapters.map((c) => c.percent / 100)}
            />
            <EnrollmentStatusBadge status={current.status} />
          </div>
          <ol className={styles.chapters}>
            {current.chapters.map((c, i) => (
              <li key={c.id} className={styles.chapter}>
                <span className={cx(styles.chapterNumber, c.percent === 100 && styles.chapterDone)}>{pad2(i + 1)}</span>
                <span className={styles.chapterText}>
                  <span className={styles.chapterTitle}>{c.title}</span>
                  <Meter value={c.percent} size="xs" label={`Chapter ${i + 1}: ${c.percent}%`} />
                </span>
                <span className={cx(styles.cellMeta, 'tabular')}>
                  {c.completed}/{c.total}
                </span>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className={styles.panel} aria-labelledby="progress-study">
        <SectionHeader
          id="progress-study"
          title="Study time"
          description={studied ? `${formatDuration(studied)} over the last 12 weeks, from lessons completed.` : 'No lessons completed in the last 12 weeks.'}
        />
        <ColumnChart
          data={p.studyWeeks.map((w) => ({ label: w.label, detail: w.detail, value: w.minutes }))}
          label="Study minutes per week"
          unit="minutes"
          height={180}
          partialIndex={p.studyWeeks.length - 1}
          partialNote="This week so far"
        />
      </section>

      <div className={styles.twoCol}>
        <QuizResults quizzes={p.quizzes} />
        <AssignmentResults assignments={p.assignments} base={base} />
      </div>
    </div>
  );
}

function QuizResults({ quizzes }: { quizzes: StudentProgress['quizzes'] }) {
  return (
    <section className={styles.panel} aria-labelledby="progress-quizzes">
      <SectionHeader id="progress-quizzes" title="Quizzes" count={quizzes.length || undefined} />
      {quizzes.length === 0 ? (
        <p className={styles.muted}>No quizzes taken yet.</p>
      ) : (
        <ul className={styles.resultList}>
          {quizzes.map((q) => (
            <li key={q.quizId} className={styles.result}>
              <IconChip tone="accent">
                <Exam size={16} />
              </IconChip>
              <span className={styles.feedText}>
                <span className={styles.cellStrong}>{q.title}</span>
                <span className={styles.cellMeta}>
                  {formatDate(q.lastAt)} · {plural(q.attempts, 'attempt')}
                </span>
              </span>
              <span className={styles.resultScore}>
                <strong className="tabular">{q.best}%</strong>
                <span className={styles.cellMeta}>pass {q.passMark}%</span>
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

function AssignmentResults({ assignments, base }: { assignments: StudentProgress['assignments']; base: string }) {
  return (
    <section className={styles.panel} aria-labelledby="progress-assignments">
      <SectionHeader id="progress-assignments" title="Assignments" count={assignments.length || undefined} />
      {assignments.length === 0 ? (
        <p className={styles.muted}>No assignments submitted yet.</p>
      ) : (
        <ul className={styles.resultList}>
          {assignments.map((a) => (
            <li key={a.submissionId} className={styles.result}>
              <IconChip
                tone={a.status === 'graded' ? (a.score !== undefined && a.score >= a.passMark ? 'accent' : 'warn') : a.status === 'returned' ? 'warn' : 'info'}
              >
                {a.status === 'graded' ? <SealCheck size={16} /> : a.status === 'returned' ? <WarningCircle size={16} /> : <ClockCounterClockwise size={16} />}
              </IconChip>
              <span className={styles.feedText}>
                <Link to={`${base}/assignments/${a.assignmentId}/submissions/${a.submissionId}`} className={styles.cellTitle}>
                  {a.title}
                </Link>
                <span className={styles.cellMeta}>
                  Submitted {formatDate(a.submittedAt)}
                  {a.late ? ' · late' : ''}
                </span>
              </span>
              <span className={styles.resultScore}>
                {a.status === 'graded' ? (
                  <>
                    <strong className="tabular">
                      {a.score} / {a.max}
                    </strong>
                    <span className={styles.cellMeta}>pass {a.passMark}</span>
                  </>
                ) : (
                  <span className={styles.cellMeta}>{a.status === 'returned' ? 'Resubmit' : 'In review'}</span>
                )}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

/* ─── Activity ─────────────────────────────────────────────────────────── */

const KIND_ORDER: ActivityKind[] = [
  'lesson-completed',
  'chapter-completed',
  'assessment-passed',
  'assignment-submitted',
  'live-attended',
  'certificate-issued',
  'enrolled',
];

export function StudentActivityTab() {
  const { profile, instructorId } = useStudentWorkspace();
  const [kind, setKind] = useState<ActivityKind | 'all'>('all');
  const [courseId, setCourseId] = useState('');
  const [limit, setLimit] = useState(30);
  const query = { kind, courseId: courseId || undefined, limit, scopeInstructorId: instructorId };
  const activity = useAsync(`student-activity:${profile.student.id}:${JSON.stringify(query)}`, () => services.students.activity(profile.student.id, query));
  const data = activity.data;

  const days: { day: string; events: NonNullable<typeof data>['events'] }[] = [];
  for (const ev of data?.events ?? []) {
    const day = ev.at.slice(0, 10);
    const last = days[days.length - 1];
    if (last?.day === day) last.events.push(ev);
    else days.push({ day, events: [ev] });
  }

  return (
    <div className={styles.tabBody}>
      <div className={styles.toolbar}>
        <Field label="Activity type" hideLabel className={styles.filter}>
          <Select
            value={kind}
            onChange={(e) => {
              setKind(e.target.value as ActivityKind | 'all');
              setLimit(30);
            }}
          >
            <option value="all">All activity{data?.counts.all !== undefined ? ` (${data.counts.all})` : ''}</option>
            {KIND_ORDER.filter((k) => data?.counts[k]).map((k) => (
              <option key={k} value={k}>
                {ACTIVITY_KIND[k].label} ({data?.counts[k]})
              </option>
            ))}
          </Select>
        </Field>
        {profile.enrollments.length > 1 && (
          <Field label="Course" hideLabel className={styles.filter}>
            <Select
              value={courseId}
              onChange={(e) => {
                setCourseId(e.target.value);
                setLimit(30);
              }}
            >
              <option value="">All courses</option>
              {profile.enrollments.map((e) => (
                <option key={e.enrollment.courseId} value={e.enrollment.courseId}>
                  {e.courseTitle}
                </option>
              ))}
            </Select>
          </Field>
        )}
      </div>

      {activity.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="Activity didn’t load"
          actions={
            <Button variant="primary" onClick={() => activity.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {activity.error.message}
        </StateMessage>
      ) : !data ? (
        <div className={styles.skeletonList} aria-busy="true">
          {Array.from({ length: 6 }, (_, i) => (
            <Skeleton key={i} height={44} radius="var(--r-sm)" />
          ))}
        </div>
      ) : data.events.length === 0 ? (
        <StateMessage icon={<ClockCounterClockwise size={26} />} title="No activity to show">
          {kind !== 'all' || courseId ? 'Nothing of this kind yet. Try all activity.' : 'Lessons, submissions and certificates appear here as they happen.'}
        </StateMessage>
      ) : (
        <section className={styles.panel} aria-label="Activity timeline">
          <ol className={styles.timeline}>
            {days.map((d) => (
              <Fragment key={d.day}>
                <li className={styles.timelineDay}>
                  <h3>{formatLongDay(`${d.day}T12:00:00+05:30`)}</h3>
                </li>
                {d.events.map((ev) => (
                  <li key={ev.id} className={styles.feedItem}>
                    <IconChip tone={ACTIVITY_KIND[ev.kind].tone}>{ACTIVITY_KIND[ev.kind].icon}</IconChip>
                    <span className={styles.feedText}>
                      <span>
                        {ACTIVITY_KIND[ev.kind].verb} <strong>{ev.title}</strong>
                      </span>
                      {ev.context && <span className={styles.cellMeta}>{ev.context}</span>}
                    </span>
                    <time className={styles.feedTime} dateTime={ev.at}>
                      {formatTime(ev.at)}
                    </time>
                  </li>
                ))}
              </Fragment>
            ))}
          </ol>
          {data.total > data.events.length && (
            <div className={styles.more}>
              <span className={styles.muted}>
                Showing {data.events.length} of {data.total}
              </span>
              <Button size="sm" loading={activity.status === 'loading'} onClick={() => setLimit((l) => l + 30)}>
                Show earlier activity
              </Button>
            </div>
          )}
        </section>
      )}
    </div>
  );
}
