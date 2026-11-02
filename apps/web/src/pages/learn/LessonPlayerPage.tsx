import { useCallback, useEffect, useRef, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  ArrowLeft,
  ArrowRight,
  BookmarkSimple,
  BookOpenText,
  CaretLeft,
  CaretRight,
  Certificate,
  CheckCircle,
  Confetti,
  Lock,
  NotePencil,
  SealCheck,
} from '@phosphor-icons/react';
import type { ProgressState } from '@syniastrolms/domain';
import { readingMinutes } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { cx } from '@/lib/cx';
import { formatRelative, pad2, plural } from '@/lib/format';

import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Field, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { AdaptivePanel } from '@/components/overlays/AdaptivePanel';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { CourseCurriculum } from '@/components/lms/course/CourseCurriculum';
import { lessonTypeMeta } from '@/components/lms/course/CourseIdentity';
import { Meter } from '@/components/lms/progress/Meters';
import { LearnerQuiz } from '@/components/lms/quiz/LearnerQuiz';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type CompletionResult, type LessonView } from '@/services';
import { ArticleBody } from '@/components/lms/content/ArticleBody';
import { AssignmentWork } from './AssignmentWork';
import { lessonTo } from './learnParts';
import { DocumentLesson, LiveLesson, VideoLesson } from './LessonViews';
import styles from './Learn.module.css';

export default function LessonPlayerPage() {
  const { courseId, lessonId } = useParams();
  const query = useAsync(`lesson:${courseId}:${lessonId}`, () => services.learning.getLesson(courseId!, lessonId!));
  usePageCrumbs(query.data ? [{ label: query.data.course.title, to: `/learn/${courseId}` }, { label: `Lesson ${query.data.number}` }] : [{ label: 'Lesson' }]);

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          icon={notFound ? <BookOpenText size={26} /> : undefined}
          title={notFound ? 'This lesson isn’t available' : 'The lesson didn’t load'}
          actions={
            notFound ? (
              <LinkButton to={courseId ? `/learn/${courseId}` : '/my-learning'} iconStart={<ArrowLeft size={16} />}>
                Back to the course
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {notFound ? 'It may have been moved or removed from the course.' : query.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!query.data || query.data.lesson.id !== lessonId) {
    return (
      <div className={styles.player} aria-busy="true" aria-label="Loading lesson">
        <Skeleton width={260} height={12} />
        <div className={styles.playerGrid}>
          <div className={styles.canvas}>
            <div className={styles.canvasInner}>
              <Skeleton width={180} height={10} />
              <Skeleton width="70%" height={32} radius="var(--r-xs)" />
              <Skeleton height={320} radius="var(--r-md)" />
              <Skeleton height={14} />
              <Skeleton width="80%" height={14} />
            </div>
          </div>
          <Skeleton height={520} radius="var(--r-lg)" className={styles.sideSkeleton} />
        </div>
      </div>
    );
  }
  return <Player key={query.data.lesson.id} view={query.data} refresh={() => query.run().catch(() => undefined)} />;
}

function Player({ view, refresh }: { view: LessonView; refresh: () => void }) {
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const { course, lesson } = view;
  const [snapshot, setSnapshot] = useState(view.snapshot);
  const [state, setState] = useState<ProgressState>(view.state);
  const [percent, setPercent] = useState(view.progress.percent);
  const [result, setResult] = useState<CompletionResult | null>(null);
  const [completing, setCompleting] = useState(false);
  const [watched, setWatched] = useState(view.state === 'completed' ? 1 : (view.lessonProgress?.fraction ?? 0));
  const [bookmarked, setBookmarked] = useState(view.bookmarked);
  const [panel, setPanel] = useState(false);
  const [note, setNote] = useState(view.note);
  const [noteSaved, setNoteSaved] = useState<string | null>(null);
  const noteTimer = useRef<number>();
  const onWatched = useCallback((f: number) => setWatched((w) => Math.max(w, f)), []);

  const chapter = course.chapters[view.chapterIndex];
  const chapterLessons = chapter.lessons.filter((l) => l.status === 'published');
  const rule = lesson.settings?.completion ?? 'opened';
  const done = state === 'completed';

  useEffect(() => () => window.clearTimeout(noteTimer.current), []);

  // A refresh after submitting work or passing a quiz brings the lesson's new state.
  useEffect(() => {
    setState(view.state);
    setSnapshot(view.snapshot);
    setPercent(view.progress.percent);
  }, [view]);

  const applyResult = (r: CompletionResult | null) => {
    if (!r) return;
    setResult(r);
    setSnapshot(r.snapshot);
    setState('completed');
    setPercent(r.progress.percent);
    if (!r.chapterCompleted && !r.courseCompleted) toast({ kind: 'success', title: 'Lesson complete', text: `${course.title} · ${r.progress.percent}%` });
  };

  const complete = async () => {
    setCompleting(true);
    try {
      applyResult(await services.learning.completeLesson(course.id, lesson.id));
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t mark it complete', text: (e as Error).message });
    } finally {
      setCompleting(false);
    }
  };

  const toggleBookmark = async () => {
    const r = await services.learning.toggleBookmark(course.id, lesson.id).catch(() => null);
    if (!r) return;
    setBookmarked(r.bookmarked);
    toast({ kind: 'info', title: r.bookmarked ? 'Bookmarked' : 'Bookmark removed', text: lesson.title });
  };

  const changeNote = (text: string) => {
    setNote(text);
    setNoteSaved(null);
    window.clearTimeout(noteTimer.current);
    noteTimer.current = window.setTimeout(() => {
      services.learning
        .saveNote(course.id, lesson.id, text)
        .then((r) => setNoteSaved(r.savedAt))
        .catch(() => undefined);
    }, 800);
  };

  // What finishing this lesson takes, by its completion rule.
  const gate =
    done || view.access !== 'open' || !view.enrolled
      ? null
      : lesson.type === 'assignment'
        ? 'Submit the assignment to complete this lesson.'
        : lesson.type === 'assessment'
          ? `Pass the quiz (${view.quiz?.settings.passMark ?? 70}%) to complete this lesson.`
          : rule === 'watched' && watched < 0.9
            ? `Watch to the end to complete · ${Math.round(watched * 100)}% watched`
            : lesson.type === 'practice' && note.trim().length < 20
              ? 'Write your working in the notes to complete the exercise.'
              : '';
  const canComplete = gate === '';

  const completeButton = (compact = false) =>
    done ? (
      <Button variant="secondary" iconStart={<CheckCircle size={16} weight="fill" />} disabled>
        Completed
      </Button>
    ) : view.access === 'open' && view.enrolled && lesson.type !== 'assignment' && lesson.type !== 'assessment' ? (
      <Button variant="primary" iconStart={<CheckCircle size={16} />} loading={completing} disabled={!canComplete} onClick={complete}>
        {compact ? 'Complete' : 'Mark complete'}
      </Button>
    ) : null;

  const nextLink = view.next && (
    <LinkButton
      to={lessonTo(course.id, view.next.id)}
      variant={done ? 'primary' : 'secondary'}
      iconEnd={<CaretRight size={16} />}
      aria-label={`Next lesson: ${view.next.title}${view.next.locked ? ' (locked)' : ''}`}
    >
      {isMobile ? 'Next' : 'Next lesson'}
    </LinkButton>
  );
  const prevLink = view.previous && (
    <LinkButton
      to={lessonTo(course.id, view.previous.id)}
      variant="ghost"
      iconStart={<CaretLeft size={16} />}
      aria-label={`Previous lesson: ${view.previous.title}`}
    >
      {isMobile ? 'Back' : 'Previous'}
    </LinkButton>
  );

  const curriculum = (
    <CourseCurriculum
      course={course}
      snapshot={view.enrolled ? snapshot : undefined}
      enrolled={view.enrolled}
      currentLessonId={lesson.id}
      onSelectLesson={(l) => {
        setPanel(false);
        navigate(lessonTo(course.id, l.id));
      }}
    />
  );

  return (
    <div className={styles.player} data-density="immersive">
      <div className={styles.playerTop}>
        <Link to={`/learn/${course.id}`} className={styles.back}>
          <ArrowLeft size={14} aria-hidden="true" /> {course.title}
        </Link>
        {view.enrolled && (
          <span className={styles.topProgress}>
            <Meter value={percent} size="sm" label={`${course.title}: ${percent}% complete`} />
            <span className="tabular">{percent}%</span>
          </span>
        )}
        <span className={styles.topTools}>
          {view.enrolled && (
            <IconButton
              label={bookmarked ? 'Remove bookmark' : 'Bookmark this lesson'}
              aria-pressed={bookmarked}
              icon={<BookmarkSimple size={18} weight={bookmarked ? 'fill' : 'regular'} />}
              onClick={toggleBookmark}
            />
          )}
          <Button size="sm" className={styles.curriculumTrigger} iconStart={<BookOpenText size={16} />} onClick={() => setPanel(true)}>
            Lessons
          </Button>
        </span>
      </div>

      <div className={styles.playerGrid}>
        <article className={styles.canvas} aria-labelledby="lesson-title">
          <div className={styles.canvasInner}>
            <div className={styles.lessonHead}>
              <span className={styles.eyebrow}>
                Chapter {pad2(view.chapterIndex + 1)} · Lesson {view.lessonIndex + 1} of {chapterLessons.length}
              </span>
              <span className={styles.typeTag}>
                {lessonTypeMeta[lesson.type].icon} {lessonTypeMeta[lesson.type].label} · {lesson.durationMin} min
                {done && (
                  <Badge size="sm" tone="accent" icon={<CheckCircle size={12} weight="fill" />}>
                    Completed
                  </Badge>
                )}
              </span>
            </div>
            <h1 id="lesson-title" className={styles.lessonTitle}>
              {lesson.title}
            </h1>
            {lesson.description && <p className={styles.lede}>{lesson.description}</p>}

            {view.access === 'locked' ? (
              <div className={styles.gate}>
                <Lock size={28} aria-hidden="true" />
                <p className={styles.gateTitle}>This lesson is locked</p>
                <p className={styles.muted}>{view.lockedReason}</p>
                {view.previous && (
                  <LinkButton to={lessonTo(course.id, view.previous.id)} variant="primary">
                    Go to {view.previous.title}
                  </LinkButton>
                )}
              </div>
            ) : view.access === 'not-enrolled' ? (
              <div className={styles.gate}>
                <Lock size={28} aria-hidden="true" />
                <p className={styles.gateTitle}>Enroll to open this lesson</p>
                <p className={styles.muted}>Free preview lessons open without enrolling. This one is part of the full course.</p>
                <LinkButton to={`/learn/${course.id}`} variant="primary">
                  See the course
                </LinkButton>
              </div>
            ) : view.access === 'unavailable' ? (
              <div className={styles.gate}>
                <BookOpenText size={28} aria-hidden="true" />
                <p className={styles.gateTitle}>This lesson isn’t available yet</p>
                <p className={styles.muted}>Your instructor is still preparing it. It appears in the curriculum as soon as it’s published.</p>
              </div>
            ) : (
              <>
                {!view.enrolled && (
                  <InlineMessage kind="info" title="Free preview">
                    You can open this lesson before enrolling. Progress is saved once you enroll.
                  </InlineMessage>
                )}

                {lesson.type === 'video' && <VideoLesson view={view} onWatched={onWatched} />}
                {(lesson.type === 'reading' || lesson.type === 'practice') && lesson.content?.article?.body && (
                  <div className={styles.reading}>
                    <span className={styles.muted}>{readingMinutes(lesson.content.article.body)} min read</span>
                    <ArticleBody body={lesson.content.article.body} />
                  </div>
                )}
                {lesson.type === 'document' && <DocumentLesson view={view} onOpened={() => undefined} />}
                {lesson.type === 'live' && view.live && <LiveLesson live={view.live} instructorName={view.instructorNames[0]} />}
                {lesson.type === 'assessment' && view.quiz && (
                  <div className={styles.quiz}>
                    {done && view.quizBest !== undefined && (
                      <InlineMessage kind="success" title={`Passed with ${view.quizBest}%`}>
                        You can take it again to practise — your best score is kept.
                      </InlineMessage>
                    )}
                    <LearnerQuiz
                      courseId={course.id}
                      lessonId={lesson.id}
                      quiz={view.quiz}
                      enrolled={view.enrolled}
                      context={`${course.title} · Chapter ${view.chapterIndex + 1}`}
                      onCompleted={applyResult}
                      onFinished={(r) => {
                        // A pass is celebrated by the lesson's completion; a result held back says nothing yet.
                        if (!r.review || r.review.passed || r.review.showResults === 'hidden' || r.review.resultsAt) return;
                        toast({
                          kind: 'info',
                          title: r.review.percent !== undefined ? `You scored ${r.review.percent}%` : 'Not passed yet',
                          text: `The pass mark is ${view.quiz!.settings.passMark}%.${r.standing.canStart ? ' You can try again.' : ''}`,
                        });
                      }}
                    />
                  </div>
                )}
                {lesson.type === 'assessment' && !view.quiz && <p className={styles.muted}>This quiz is being prepared by your instructor.</p>}
                {lesson.type === 'assignment' && view.assignment && (
                  <AssignmentWork
                    item={view.assignment}
                    onSubmitted={() => {
                      refresh();
                    }}
                  />
                )}
                {lesson.type === 'assignment' && !view.assignment && lesson.content?.assignment && (
                  <div className={styles.reading}>
                    <p>{lesson.content.assignment.brief}</p>
                  </div>
                )}

                {result && (result.chapterCompleted || result.courseCompleted) && (
                  <div className={styles.celebrate} role="status">
                    {result.courseCompleted ? <Certificate size={30} aria-hidden="true" /> : <Confetti size={30} aria-hidden="true" />}
                    <div>
                      <p className={styles.gateTitle}>
                        {result.courseCompleted ? `You’ve completed ${course.title}` : `Chapter complete: ${result.chapterCompleted}`}
                      </p>
                      <p className={styles.muted}>
                        {result.courseCompleted
                          ? course.certificateTitle
                            ? 'Your certificate is being prepared — you’ll find it in Certificates.'
                            : 'Every lesson is done. Well earned.'
                          : `${result.progress.percent}% of the course done. The next chapter is open.`}
                      </p>
                    </div>
                    {result.courseCompleted && course.certificateTitle ? (
                      <LinkButton to="/certificates" variant="primary" iconStart={<SealCheck size={16} />}>
                        Certificates
                      </LinkButton>
                    ) : (
                      result.nextLessonId && (
                        <LinkButton to={lessonTo(course.id, result.nextLessonId)} variant="primary" iconEnd={<ArrowRight size={16} />}>
                          Start the next chapter
                        </LinkButton>
                      )
                    )}
                  </div>
                )}

                {lesson.objectives && lesson.objectives.length > 0 && (
                  <section className={styles.lessonSection} aria-labelledby="objectives-title">
                    <h2 id="objectives-title" className={styles.sectionTitle}>
                      By the end of this lesson
                    </h2>
                    <ul className={styles.objectives}>
                      {lesson.objectives.map((o) => (
                        <li key={o}>
                          <CheckCircle size={16} aria-hidden="true" /> {o}
                        </li>
                      ))}
                    </ul>
                  </section>
                )}

                {view.enrolled && lesson.type !== 'assignment' && lesson.type !== 'assessment' && (
                  <section className={styles.lessonSection} aria-labelledby="notes-title">
                    <h2 id="notes-title" className={styles.sectionTitle}>
                      <NotePencil size={18} aria-hidden="true" /> {lesson.type === 'practice' ? 'Your working' : 'Your notes'}
                    </h2>
                    <Field
                      label={lesson.type === 'practice' ? 'Your working' : 'Notes'}
                      hideLabel
                      hint={noteSaved ? `Saved ${formatRelative(noteSaved, now)}` : 'Only you can see these. They save as you type.'}
                    >
                      <Textarea
                        rows={4}
                        value={note}
                        onChange={(e) => changeNote(e.target.value)}
                        placeholder={lesson.type === 'practice' ? 'Work through the exercise here…' : 'Jot down what you want to remember…'}
                      />
                    </Field>
                  </section>
                )}
              </>
            )}

            <div className={styles.lessonFooter}>
              <span className={styles.footerSide}>{prevLink}</span>
              <span className={styles.footerCenter}>
                {gate && <span className={styles.gateHint}>{gate}</span>}
                {!isMobile && completeButton()}
              </span>
              <span className={cx(styles.footerSide, styles.footerEnd)}>{nextLink}</span>
            </div>
            {isMobile && gate && <p className={styles.gateHint}>{gate}</p>}
            {view.next?.locked && !done && <p className={cx(styles.muted, styles.nextLocked)}>The next lesson opens when this one is complete.</p>}
            <p className={styles.position}>
              Lesson {view.position.index} of {plural(view.position.total, 'lesson')} in {course.title}
            </p>
          </div>
        </article>

        <aside className={styles.side} aria-label="Curriculum">
          {curriculum}
        </aside>
      </div>

      <AdaptivePanel open={panel} onClose={() => setPanel(false)} eyebrow={course.title} title="Lessons">
        {curriculum}
      </AdaptivePanel>

      {isMobile && view.access === 'open' && (
        <StickyActionBar
          mobile={
            <div className={styles.mobileBar}>
              {prevLink}
              {completeButton(true)}
              {nextLink}
            </div>
          }
        >
          <span />
        </StickyActionBar>
      )}
    </div>
  );
}
