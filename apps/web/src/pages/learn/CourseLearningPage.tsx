import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { ArrowLeft, BookmarkSimple, Play, VideoCamera } from '@phosphor-icons/react';
import type { Assignment } from '@syniastrolms/domain';
import { chapterProgress } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatDuration, formatTime, plural } from '@/lib/format';
import { NOT_OPEN, saleDisplay } from '@/lib/coursePricing';
import { SectionHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CertificateStatus } from '@/components/lms/certificate/CertificateStatus';
import { AssignmentStatus } from '@/components/lms/coursework/AssignmentStatus';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { CourseCurriculum } from '@/components/lms/course/CourseCurriculum';
import { LearningJourney } from '@/components/lms/journey/LearningJourney';
import { ProgressRing } from '@/components/lms/progress/ProgressRing';
import { DateBlock, WorkList, WorkRow } from '@/components/lms/shared/WorkRow';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, ServiceError, type LearnerAssignment } from '@/services';
import { lessonTo } from './learnParts';
import { CoursePurchase } from './CoursePurchase';
import { CourseReviewPanel } from './CourseReviewPanel';
import { readCheckoutReturn } from './purchaseFlow';
import styles from './Learn.module.css';

/** The learner-facing shape the coursework components expect. */
export function asStatusAssignment(la: LearnerAssignment): Assignment {
  const s = la.submission;
  return {
    id: la.assignment.id,
    courseId: la.assignment.courseId,
    chapterId: la.assignment.chapterId ?? '',
    title: la.assignment.title,
    brief: la.assignment.instructions.split(/\n{2,}/)[0],
    dueAt: la.dueAt ?? '2099-01-01T00:00:00+05:30',
    state: la.state,
    submittedAt: s?.submittedAt,
    acceptsLate: la.assignment.acceptsLate,
    grade:
      s?.review.status === 'graded' && s.review.score !== undefined
        ? { score: s.review.score, max: la.assignment.maxScore, passMark: la.assignment.passMark, feedbackAvailable: Boolean(s.review.feedback) }
        : undefined,
  };
}

export default function CourseLearningPage() {
  const { courseId } = useParams();
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const query = useAsync(`learn-course:${courseId}`, () => services.learning.getCourse(courseId!));
  const [busy, setBusy] = useState(false);
  // Back from a hosted checkout (`?purchase=…&checkout=…`): kept for this course, and taken out of the address.
  const [params, setParams] = useSearchParams();
  const [resume] = useState(() => {
    const ret = readCheckoutReturn(params.toString());
    return ret ? { ...ret, courseId } : null;
  });
  useEffect(() => {
    if (params.has('purchase') || params.has('checkout')) setParams({}, { replace: true });
  }, [params, setParams]);
  usePageCrumbs(query.data ? [{ label: query.data.course.title }] : [{ label: 'Course' }]);

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'This course isn’t available' : 'The course didn’t load'}
          actions={
            notFound ? (
              <LinkButton to="/my-learning" iconStart={<ArrowLeft size={16} />}>
                Back to my learning
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
  if (!query.data || query.data.course.id !== courseId) {
    return (
      <div className={styles.page} aria-busy="true" aria-label="Loading course">
        <Skeleton height={200} radius="var(--r-lg)" />
        <div className={styles.courseLayout}>
          <Skeleton height={480} radius="var(--r-lg)" />
          <Skeleton height={300} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }

  const d = query.data;
  const { course, progress, next, snapshot, enrolled } = d;
  const remaining = progress.remainingMin;
  const upcomingLive = d.live.filter((c) => new Date(c.startsAt).getTime() + c.durationMin * 60_000 > now.getTime()).slice(0, 3);
  const openAssignments = d.assignments.filter((a) => a.state !== 'graded').slice(0, 4);

  const enroll = async () => {
    setBusy(true);
    try {
      const enrolledCourse = await services.learning.enroll(course.id);
      toast({ kind: 'success', title: `You’re enrolled in ${course.title}` });
      if (enrolledCourse.next) navigate(lessonTo(course.id, enrolledCourse.next.id));
      else query.run().catch(() => undefined);
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t enroll', text: (e as Error).message });
      // The course's pricing changed since the page loaded: show what joining it takes now.
      const reason = e instanceof ServiceError ? e.reason : undefined;
      if (reason === 'COURSE_PURCHASE_REQUIRED' || reason === 'COURSE_NOT_FOR_SALE') query.run().catch(() => undefined);
    } finally {
      setBusy(false);
    }
  };
  const sale = saleDisplay(course);
  const firstLesson = course.chapters.flatMap((c) => c.lessons)[0];
  const toggleSave = async () => {
    const r = await services.learning.toggleSaved(course.id).catch(() => null);
    if (r) toast({ kind: 'info', title: r.saved ? 'Saved for later' : 'Removed from saved', text: course.title });
    query.run().catch(() => undefined);
  };

  const saveButton = (
    <Button size="lg" iconStart={<BookmarkSimple size={16} weight={d.saved ? 'fill' : 'regular'} />} onClick={toggleSave}>
      {d.saved ? 'Saved' : 'Save for later'}
    </Button>
  );

  const chapters = course.chapters.filter((c) => c.lessons.length > 0);
  const steps = chapters.map((c, i) => {
    const p = chapterProgress(c, snapshot);
    const locked = enrolled && c.lessons.every((l) => snapshot.lessons[l.id]?.state === 'locked');
    return {
      id: c.id,
      title: c.title,
      state: locked ? ('locked' as const) : p.state,
      percent: p.percent,
      meta: `${p.completed} of ${plural(p.total, 'lesson')}`,
      lockedReason: locked && i > 0 ? `Opens after ${chapters[i - 1].title}` : undefined,
    };
  });
  const currentChapter = next ? chapters[next.chapterIndex]?.id : undefined;

  return (
    <div className={styles.page}>
      <Link to="/my-learning" className={styles.back}>
        <ArrowLeft size={14} aria-hidden="true" /> My courses
      </Link>
      <header className={styles.courseHero}>
        <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.heroCover} />
        <div className={styles.heroText}>
          <span className={styles.eyebrow}>
            {d.levelTitle} · {d.instructorNames.join(' & ')}
          </span>
          <h1 className={styles.heroTitle}>{course.title}</h1>
          <p className={styles.lede}>{course.subtitle}</p>
          {(enrolled || sale.kind !== 'paid') && (
            <div className={styles.heroActions}>
              {enrolled ? (
                next ? (
                  <LinkButton size="lg" variant="primary" to={lessonTo(course.id, next.id)} iconStart={<Play size={16} weight="fill" />}>
                    {next.state === 'in-progress'
                      ? `Resume ${next.lessonNumber}`
                      : progress.completed
                        ? `Continue with ${next.lessonNumber}`
                        : 'Start the course'}
                  </LinkButton>
                ) : firstLesson ? (
                  <LinkButton size="lg" to={lessonTo(course.id, firstLesson.id)}>
                    Review from the start
                  </LinkButton>
                ) : (
                  // Enrolled (bought, perhaps) before any lesson was published: nothing to open yet.
                  <p>
                    This course has no lessons to open yet. <Link to="/contact?topic=support">Contact support</Link> if you were expecting them.
                  </p>
                )
              ) : sale.kind === 'free' ? (
                <>
                  <Button size="lg" variant="primary" loading={busy} onClick={enroll}>
                    Enroll for free
                  </Button>
                  {saveButton}
                </>
              ) : sale.kind === 'unavailable' ? (
                <>
                  <Button size="lg" variant="primary" disabled>
                    {NOT_OPEN}
                  </Button>
                  {saveButton}
                </>
              ) : null}
            </div>
          )}
          {!enrolled && sale.kind === 'paid' && (
            <CoursePurchase
              course={course}
              amount={sale.amount}
              resume={resume && resume.courseId === course.id ? resume : undefined}
              onOwned={() => query.run().catch(() => undefined)}
              extra={saveButton}
            />
          )}
          {!enrolled && sale.kind === 'unavailable' && (
            <p className={styles.muted}>The platform hasn’t opened this course to learners yet. Save it, and check back later.</p>
          )}
        </div>
        {enrolled && (
          <div className={styles.heroProgress}>
            <ProgressRing value={progress.percent} size="lg" label={`${course.title} progress`} />
            <dl className={styles.heroStats}>
              <div>
                <dt>Lessons</dt>
                <dd className="tabular">
                  {progress.completed}/{progress.total}
                </dd>
              </div>
              <div>
                <dt>Time left</dt>
                <dd>{remaining ? formatDuration(remaining) : 'Done'}</dd>
              </div>
            </dl>
          </div>
        )}
      </header>

      <div className={styles.courseLayout}>
        <div className={styles.column}>
          {enrolled && (
            <section className={styles.panel} aria-labelledby="journey-title">
              <SectionHeader
                id="journey-title"
                title="Your path"
                description="Chapters open one after another. A chapter’s quiz opens once you’ve finished its lessons."
              />
              <LearningJourney
                steps={steps}
                label={`${course.title} chapters`}
                currentId={currentChapter}
                currentAction={
                  next && (
                    <LinkButton size="sm" variant="primary" to={lessonTo(course.id, next.id)}>
                      {next.state === 'in-progress' ? 'Resume' : 'Continue'}: {next.title}
                    </LinkButton>
                  )
                }
              />
            </section>
          )}
          <section className={styles.panel} aria-labelledby="curriculum-title" data-density="balanced">
            <SectionHeader
              id="curriculum-title"
              title="Lessons"
              description={enrolled ? undefined : 'Lessons marked Free preview can be opened before you join.'}
            />
            <CourseCurriculum
              course={course}
              snapshot={enrolled ? snapshot : undefined}
              enrolled={enrolled}
              currentLessonId={next?.id}
              onSelectLesson={(lesson) => navigate(lessonTo(course.id, lesson.id))}
            />
          </section>
        </div>

        <aside className={styles.column} aria-label="Course details">
          {d.certificate && enrolled && (
            <section className={styles.panel} aria-labelledby="cert-title">
              <SectionHeader id="cert-title" title="Certificate" />
              <CertificateStatus record={d.certificate} onView={() => navigate('/certificates')} />
            </section>
          )}
          {enrolled && openAssignments.length > 0 && (
            <section className={styles.panel} aria-labelledby="course-assignments">
              <SectionHeader
                id="course-assignments"
                title="Assignments"
                actions={
                  <LinkButton size="sm" variant="ghost" to="/assignments">
                    All
                  </LinkButton>
                }
              />
              <WorkList label="Assignments to do">
                {openAssignments.map((la) => (
                  <AssignmentStatus
                    key={la.assignment.id}
                    assignment={asStatusAssignment(la)}
                    chapterTitle={la.chapterTitle}
                    now={now}
                    onOpen={() => navigate(`/assignments/${la.assignment.id}`)}
                  />
                ))}
              </WorkList>
            </section>
          )}
          {enrolled && <CourseReviewPanel courseId={course.id} />}
          <section className={styles.panel} aria-labelledby="course-live">
            <SectionHeader id="course-live" title="Live classes" />
            {upcomingLive.length === 0 ? (
              <p className={styles.muted}>No live classes scheduled for this course right now.</p>
            ) : (
              <WorkList label="Live classes">
                {upcomingLive.map((c) => (
                  <WorkRow
                    key={c.id}
                    lead={<DateBlock iso={c.startsAt} />}
                    eyebrow={
                      <>
                        <VideoCamera size={14} /> {formatTime(c.startsAt)} · {c.durationMin} min
                      </>
                    }
                    title={c.title}
                    meta={c.capacity ? `${c.registered ?? c.attending ?? 0} of ${c.capacity} places taken` : undefined}
                  />
                ))}
              </WorkList>
            )}
          </section>
          <section className={styles.panel} aria-labelledby="course-about">
            <SectionHeader id="course-about" title="What you’ll learn" />
            <ul className={styles.outcomes}>
              {course.outcomes.map((o) => (
                <li key={o}>{o}</li>
              ))}
            </ul>
          </section>
        </aside>
      </div>
    </div>
  );
}
