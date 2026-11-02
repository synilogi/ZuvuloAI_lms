import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useBlocker } from 'react-router-dom';
import { ArrowLeft, ArrowRight, CheckCircle, ListChecks, Timer, WarningCircle, WifiSlash } from '@phosphor-icons/react';
import type { AttemptReview, LearnerQuizQuestion, QuizAnswers, QuizSessionView, QuizStanding } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatClock, formatMoment, plural } from '@/lib/format';
import { Button } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { services, type CompletionResult, type LessonQuiz, type QuizSubmitResult } from '@/services';
import { Meter } from '../progress/Meters';
import { AnswerSaver, backoffMs, isAnswered, isTransient, unsavedQuestions, type SaverSnapshot } from './answerSaver';
import { AttemptHistory, AttemptResult, hasNegativeMarking, QuestionCard, QuestionPalette } from './QuizParts';
import { deadlineFrom, monotonicNow, newStartKey, secondsLeft, timerTone, warningPassed } from './quizClock';
import styles from './Quiz.module.css';

/*
 * A learner taking a lesson's quiz. The attempt is the server's (a "session"): it starts it, fixes its deadline, keeps
 * the answers it accepted, and scores what it stored. This screen:
 *
 * - reads where the learner stands (`quizAttempts`) and resumes an open attempt straight away — after a refresh too;
 * - starts one with a key made per press of Start, so a retried start never uses a second attempt;
 * - shows only the questions the session sent, in its order;
 * - counts down from the server's figure on the monotonic clock, set again by every answer from the server;
 * - saves the whole sheet as the learner goes (`AnswerSaver`), and says plainly what is saved and what is not;
 * - hands the attempt in once, retrying the same submission through a dropped connection, and shows one result.
 */

type Phase = 'loading' | 'intro' | 'taking' | 'review' | 'submitting' | 'result';

interface LearnerQuizProps {
  courseId: string;
  lessonId: string;
  quiz: LessonQuiz;
  context?: string;
  /** Not enrolled (a free preview): the quiz is described, never started. */
  enrolled: boolean;
  /** A pass: what completing the lesson changed. */
  onCompleted: (completion: CompletionResult) => void;
  /** Any finished attempt, for the page to follow up (a "not passed" note). */
  onFinished?: (result: QuizSubmitResult) => void;
}

const sleep = (ms: number) => new Promise((r) => window.setTimeout(r, ms));
const WARNING_TEXT: Record<number, string> = { 300: '5 minutes left.', 60: '1 minute left.' };

export function LearnerQuiz({ courseId, lessonId, quiz, context, enrolled, onCompleted, onFinished }: LearnerQuizProps) {
  const [phase, setPhase] = useState<Phase>(enrolled ? 'loading' : 'intro');
  const [standing, setStanding] = useState<QuizStanding | null>(null);
  const [history, setHistory] = useState<AttemptReview[]>([]);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [session, setSession] = useState<QuizSessionView | null>(null);
  const [questions, setQuestions] = useState<LearnerQuizQuestion[]>([]);
  const [answers, setAnswers] = useState<QuizAnswers>({});
  const [index, setIndex] = useState(0);
  const [save, setSave] = useState<SaverSnapshot | null>(null);
  const [endsAt, setEndsAt] = useState<number | null>(null);
  const [left, setLeft] = useState<number | null>(null);
  const [announce, setAnnounce] = useState('');
  const [starting, setStarting] = useState(false);
  const [startError, setStartError] = useState<string | null>(null);
  const [submitError, setSubmitError] = useState<{ message: string; retrying: boolean } | null>(null);
  const [result, setResult] = useState<QuizSubmitResult | null>(null);
  const [online, setOnline] = useState(() => (typeof navigator === 'undefined' ? true : navigator.onLine));

  const saver = useRef<AnswerSaver | null>(null);
  const answersRef = useRef<QuizAnswers>({});
  const sessionRef = useRef<QuizSessionView | null>(null);
  // One key per press of Start, kept for a retry of that press.
  const startKey = useRef<string | null>(null);
  // The one submission of this attempt: the timer, the button and a closed save all lead here.
  const submitting = useRef<Promise<void> | null>(null);
  const finalSheet = useRef<{ answers: QuizAnswers; seq: number } | undefined>(undefined);
  const mounted = useRef(true);
  const onCompletedRef = useRef(onCompleted);
  onCompletedRef.current = onCompleted;
  const onFinishedRef = useRef(onFinished);
  onFinishedRef.current = onFinished;

  useEffect(
    () => () => {
      mounted.current = false;
      saver.current?.stop();
    },
    [],
  );

  const settings = quiz.settings;
  const timed = endsAt !== null;
  const active = phase === 'taking' || phase === 'review' || phase === 'submitting';
  const timeUp = timed && left === 0;
  const opensAt = standing?.opensAt ?? settings.opensAt;
  const closesAt = standing?.closesAt ?? settings.closesAt;

  /* ─── Standing and resuming ─── */

  const loadStanding = useCallback(async () => {
    const view = await services.learning.quizAttempts(courseId, lessonId);
    if (!mounted.current) return view;
    setStanding(view.standing);
    setHistory(view.attempts);
    return view;
  }, [courseId, lessonId]);

  const enter = useCallback(
    (view: QuizSessionView, served: LearnerQuizQuestion[], arrivedAt: number) => {
      saver.current?.stop();
      sessionRef.current = view;
      submitting.current = null;
      finalSheet.current = undefined;
      answersRef.current = view.answers;
      setSession(view);
      setQuestions(served);
      setAnswers(view.answers);
      setIndex(0);
      setResult(null);
      setSubmitError(null);
      setAnnounce('');
      const ends = deadlineFrom(view, arrivedAt);
      setEndsAt(ends);
      setLeft(ends === null ? null : secondsLeft(ends, arrivedAt));
      const next = new AnswerSaver({
        session: view,
        save: (sheet, seq) => services.learning.saveQuizAnswers(courseId, lessonId, view.id, sheet, seq),
        onChange: (snap) => mounted.current && setSave(snap),
        // Every answer from the server sets the countdown again, from the server's own figure.
        onServer: (v) => mounted.current && setEndsAt(deadlineFrom(v, monotonicNow())),
        // Time is up, or it was handed in elsewhere: what is left is its result.
        onClosed: () => void handIn(),
      });
      saver.current = next;
      setSave(next.snapshot);
      setPhase('taking');
    },
    // `handIn` is stable for the life of the attempt; see below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [courseId, lessonId],
  );

  useEffect(() => {
    if (!enrolled) return;
    let cancelled = false;
    (async () => {
      try {
        const view = await loadStanding();
        if (cancelled) return;
        // An attempt still open is picked up again — after a refresh, or on coming back to the lesson.
        if (view.standing.openSession && view.standing.canStart) {
          const latest = await services.learning.getQuizSession(courseId, lessonId);
          const arrivedAt = monotonicNow();
          if (cancelled) return;
          if (latest.session?.status === 'active' && latest.questions.length) {
            enter(latest.session, latest.questions, arrivedAt);
            return;
          }
          await loadStanding();
        }
        if (!cancelled) setPhase('intro');
      } catch (e) {
        if (cancelled) return;
        setLoadError((e as Error).message);
        setPhase('intro');
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [enrolled, courseId, lessonId, loadStanding, enter]);

  /* ─── Starting ─── */

  const start = async () => {
    if (starting) return;
    startKey.current ??= newStartKey();
    setStarting(true);
    setStartError(null);
    try {
      const begun = await services.learning.startQuizSession(courseId, lessonId, startKey.current);
      const arrivedAt = monotonicNow();
      startKey.current = null;
      if (!mounted.current) return;
      if (begun.session.status === 'active' && begun.questions.length) enter(begun.session, begun.questions, arrivedAt);
      else await loadStanding();
    } catch (e) {
      // A lost answer may have started it: the same key asks again. A refusal is final for this press.
      if (!isTransient(e)) startKey.current = null;
      if (!mounted.current) return;
      setStartError((e as Error).message);
      if (!isTransient(e)) await loadStanding().catch(() => undefined);
    } finally {
      if (mounted.current) setStarting(false);
    }
  };

  /* ─── Answering ─── */

  const answer = (questionId: string, next: string[] | string) => {
    if (phase !== 'taking' || timeUp) return;
    const sheet = { ...answersRef.current, [questionId]: next };
    answersRef.current = sheet;
    setAnswers(sheet);
    saver.current?.change(sheet);
  };

  /* ─── Handing in ─── */

  // Stable for the life of the component: it reads the attempt from refs, so the timer, the button and a closed save
  // all reach the same submission.
  const handIn = useCallback(() => {
    if (submitting.current) return submitting.current;
    const current = sessionRef.current;
    if (!current) return Promise.resolve();
    const s = saver.current;
    // The latest sheet goes with the submission when the server does not hold it yet; it counts only before the deadline.
    if (s && s.unsaved && s.snapshot.state !== 'closed') finalSheet.current ??= { answers: answersRef.current, seq: s.takeFinalSeq() };
    else s?.stop();
    setPhase('submitting');
    setSubmitError(null);
    const run = async () => {
      for (let attempt = 1; ; attempt++) {
        try {
          const done = await services.learning.submitQuizSession(courseId, lessonId, current.id, finalSheet.current);
          if (!mounted.current) return;
          setResult((prev) => prev ?? done);
          setStanding(done.standing);
          setSession(done.session);
          setSubmitError(null);
          setPhase('result');
          loadStanding().catch(() => undefined);
          // While results are held until the close, nothing — a completion included — says how it went.
          if (done.completion && !done.review?.resultsAt) onCompletedRef.current(done.completion);
          onFinishedRef.current?.(done);
          return;
        } catch (e) {
          if (!mounted.current) return;
          // Handing in is safe to repeat: a dropped connection is simply tried again, with the same sheet.
          if (isTransient(e)) {
            setSubmitError({ message: (e as Error).message, retrying: true });
            await sleep(backoffMs(attempt));
            if (!mounted.current) return;
            continue;
          }
          setSubmitError({ message: (e as Error).message, retrying: false });
          submitting.current = null;
          return;
        }
      }
    };
    submitting.current = run();
    return submitting.current;
  }, [courseId, lessonId, loadStanding]);

  /* ─── The countdown ─── */

  useEffect(() => {
    if (!active || endsAt === null) return;
    const tick = () => {
      const now = secondsLeft(endsAt, monotonicNow());
      setLeft((before) => {
        const warning = warningPassed(before, now);
        if (warning) setAnnounce(WARNING_TEXT[warning]);
        return now;
      });
    };
    tick();
    const id = window.setInterval(tick, 250);
    return () => window.clearInterval(id);
  }, [active, endsAt]);

  // Time is up by the server's figure: answering stops and the attempt is handed in with what was saved.
  useEffect(() => {
    if (left === 0 && (phase === 'taking' || phase === 'review')) {
      setAnnounce('Time is up. Your attempt is being handed in.');
      void handIn();
    }
  }, [left, phase, handIn]);

  /* ─── Connection ─── */

  useEffect(() => {
    const up = () => {
      setOnline(true);
      saver.current?.retry();
    };
    const down = () => setOnline(false);
    window.addEventListener('online', up);
    window.addEventListener('offline', down);
    return () => {
      window.removeEventListener('online', up);
      window.removeEventListener('offline', down);
    };
  }, []);

  /* ─── Leaving ─── */

  const unsavedNow = phase === 'submitting' || (active && (saver.current?.unsaved ?? false));
  useEffect(() => {
    if (!unsavedNow) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [unsavedNow]);
  // In-app links ask first while the learner is answering; the dialog is drawn by the answering screens.
  const answering = phase === 'taking' || phase === 'review';
  const blocker = useBlocker(({ currentLocation, nextLocation }) => answering && currentLocation.pathname !== nextLocation.pathname);

  /* ─── What is saved ─── */

  const unsaved = useMemo(() => new Set(save ? unsavedQuestions(answers, save.saved) : []), [answers, save]);
  const answeredCount = questions.filter((q) => isAnswered(answers[q.id])).length;
  const blank = questions.map((q, i) => ({ q, i })).filter(({ q }) => !isAnswered(answers[q.id]));

  /* ─── Screens ─── */

  if (phase === 'loading') {
    return (
      <div className={styles.taker} aria-busy="true" aria-label="Loading the quiz">
        <Skeleton width={160} height={10} />
        <Skeleton width="60%" height={28} radius="var(--r-xs)" />
        <Skeleton height={72} radius="var(--r-md)" />
      </div>
    );
  }

  const liveRegion = (
    <p className="sr-only" aria-live="assertive">
      {announce}
    </p>
  );

  if (phase === 'intro') {
    const open = standing?.openSession;
    const blocked = enrolled && standing ? !standing.canStart : false;
    const used = standing?.attemptsUsed ?? quiz.attemptsUsed;
    const allowed = standing?.attemptsAllowed ?? settings.attempts;
    return (
      <div className={styles.taker}>
        <div className={styles.intro}>
          {context && <span className={styles.context}>{context}</span>}
          <h2 className={styles.title}>{quiz.title || 'Untitled quiz'}</h2>
          {quiz.instructions && <p className={styles.instructions}>{quiz.instructions}</p>}
          <dl className={styles.facts}>
            <div>
              <dt>Questions</dt>
              <dd>{quiz.questionCount}</dd>
            </div>
            <div>
              <dt>Points</dt>
              <dd>{quiz.totalPoints}</dd>
            </div>
            <div>
              <dt>Pass mark</dt>
              <dd>{settings.passMark}%</dd>
            </div>
            <div>
              <dt>Time limit</dt>
              <dd>{settings.timeLimitMin ? `${settings.timeLimitMin} min` : 'None'}</dd>
            </div>
            <div>
              <dt>{allowed ? 'Attempts used' : 'Attempts'}</dt>
              <dd>{allowed ? `${used} of ${allowed}` : used ? `${used} · no limit` : 'No limit'}</dd>
            </div>
          </dl>
          {(opensAt || closesAt) && (
            <ul className={styles.window} aria-label="When you can take this quiz">
              {opensAt && (
                <li>
                  {quizWindowWord(standing?.window ?? quiz.window, 'opens')} <time dateTime={opensAt}>{formatMoment(opensAt)}</time>
                </li>
              )}
              {closesAt && (
                <li>
                  {quizWindowWord(standing?.window ?? quiz.window, 'closes')} <time dateTime={closesAt}>{formatMoment(closesAt)}</time>
                  {settings.timeLimitMin ? ' — an attempt still running then is handed in with what was saved' : ''}
                </li>
              )}
            </ul>
          )}
          {settings.resultsRelease === 'after-close' && closesAt && (
            <p className={styles.note}>Results are shown to everyone once the quiz closes, on {formatMoment(closesAt)}.</p>
          )}
          {(quiz.negativeMarking ?? hasNegativeMarking(quiz.questions)) && (
            <p className={styles.note}>Wrong answers lose marks. A question left blank never does.</p>
          )}
          {settings.timeLimitMin ? (
            <p className={styles.note}>
              <Timer size={16} aria-hidden="true" /> The clock starts when you press Start and keeps running if you leave. Your answers save as you go.
            </p>
          ) : null}
          {loadError && (
            <InlineMessage
              kind="error"
              title="We couldn’t check your attempts."
              action={
                <Button
                  size="sm"
                  onClick={() =>
                    loadStanding().then(
                      () => setLoadError(null),
                      (e: Error) => setLoadError(e.message),
                    )
                  }
                >
                  Try again
                </Button>
              }
            >
              {loadError}
            </InlineMessage>
          )}
          {!enrolled ? (
            <p className={styles.note}>Enroll in the course to take this quiz.</p>
          ) : blocked ? (
            <p className={styles.blocked} role="status">
              <WarningCircle size={18} aria-hidden="true" /> {standing?.blockedReason ?? 'You can’t take this quiz right now.'}
            </p>
          ) : null}
          <Button
            variant="primary"
            size="lg"
            onClick={start}
            loading={starting}
            disabled={!enrolled || blocked || !standing}
            iconEnd={<ArrowRight size={16} />}
          >
            {open && !blocked ? `Resume attempt ${open.attemptNo}` : used ? 'Start a new attempt' : 'Start quiz'}
          </Button>
          {startError && (
            <p className={styles.blocked} role="alert">
              <WarningCircle size={18} aria-hidden="true" /> {startError}
            </p>
          )}
        </div>
        <AttemptHistory attempts={history} />
      </div>
    );
  }

  if (phase === 'result' || (phase === 'submitting' && result)) {
    const review = result?.review;
    return (
      <div className={styles.taker}>
        {review ? (
          <AttemptResult review={review} questions={questions} totalPoints={quiz.totalPoints} passMark={settings.passMark} />
        ) : (
          <InlineMessage kind="info" title="Your attempt was handed in.">
            Its result couldn’t be read just now. Refresh the page to see it.
          </InlineMessage>
        )}
        {standing && !standing.canStart && standing.blockedReason && (!standing.passed || review?.resultsAt) && (
          <p className={styles.note}>{standing.blockedReason}</p>
        )}
        <div className={styles.navRow}>
          {standing?.canStart && (
            <Button variant="primary" onClick={start} loading={starting} iconEnd={<ArrowRight size={16} />}>
              {review?.resultsAt ? 'Start a new attempt' : standing.passed ? 'Practise again' : 'Try again'}
            </Button>
          )}
        </div>
        {startError && (
          <p className={styles.blocked} role="alert">
            <WarningCircle size={18} aria-hidden="true" /> {startError}
          </p>
        )}
        <AttemptHistory attempts={history} />
        {liveRegion}
      </div>
    );
  }

  const question = questions[index];
  const disabled = phase !== 'taking' || timeUp;
  const timer =
    left !== null ? (
      <span className={cx(styles.timer, styles[`timer-${timerTone(left)}`])} role="timer" aria-label={`Time left ${formatClock(left)}`}>
        <Timer size={15} aria-hidden="true" /> {formatClock(left)}
      </span>
    ) : null;

  const header = (
    <>
      {!online && (
        <InlineMessage kind="warn" title="You’re offline.">
          Your answers stay on this page and are saved when the connection is back.{timed ? ' The clock keeps running.' : ''}
        </InlineMessage>
      )}
      {timeUp && phase !== 'submitting' && (
        <InlineMessage kind="warn" title="Time is up.">
          Your attempt is being handed in with the answers saved.
        </InlineMessage>
      )}
      <div className={styles.attemptBar}>
        <span className={styles.progressText}>Attempt {session?.attemptNo}</span>
        <SaveStatus save={save} unsavedCount={unsaved.size} onRetry={() => saver.current?.retry()} />
        {timer}
      </div>
    </>
  );

  if (phase === 'submitting') {
    return (
      <div className={styles.taker} aria-busy={!submitError || submitError.retrying}>
        {header}
        <div className={styles.resultHead}>
          <CheckCircle size={40} weight="duotone" className={styles.resultIcon} />
          <div>
            <h2 className={styles.title}>{submitError && !submitError.retrying ? 'Not handed in yet' : 'Handing in your answers…'}</h2>
            <p className={styles.instructions} role="status">
              {!submitError
                ? 'Your answers are being marked.'
                : submitError.retrying
                  ? `Not sent yet — trying again. ${submitError.message}`
                  : submitError.message}
            </p>
          </div>
        </div>
        {submitError && !submitError.retrying && (
          <div className={styles.navRow}>
            <Button variant="primary" onClick={() => void handIn()}>
              Try again
            </Button>
          </div>
        )}
        {liveRegion}
      </div>
    );
  }

  if (phase === 'review') {
    return (
      <div className={styles.taker}>
        {header}
        <div className={styles.intro}>
          <h2 className={styles.title}>Check before you submit</h2>
          <p className={styles.instructions}>
            You’ve answered {answeredCount} of {plural(questions.length, 'question')}.{blank.length === 0 ? ' Every question has an answer.' : ''}
          </p>
        </div>
        {blank.length > 0 && (
          <section className={styles.unanswered} aria-labelledby="unanswered-title">
            <h3 id="unanswered-title" className={styles.historyTitle}>
              {plural(blank.length, 'question')} not answered
            </h3>
            <ul className={styles.unansweredList}>
              {blank.map(({ q, i }) => (
                <li key={q.id}>
                  <button
                    type="button"
                    className={styles.summaryLink}
                    onClick={() => {
                      setIndex(i);
                      setPhase('taking');
                    }}
                  >
                    Question {i + 1}: {q.prompt.length > 80 ? `${q.prompt.slice(0, 80)}…` : q.prompt}
                  </button>
                  {q.required && <span className={styles.muted}> · required</span>}
                </li>
              ))}
            </ul>
          </section>
        )}
        {unsaved.size > 0 && <p className={styles.note}>Your latest answers are sent with your submission.</p>}
        <p className={styles.note}>Once you submit, this attempt is marked and can’t be changed.</p>
        <div className={styles.navRow}>
          <Button variant="ghost" iconStart={<ArrowLeft size={16} />} onClick={() => setPhase('taking')}>
            Back to the questions
          </Button>
          <span className={styles.navSpacer} />
          <Button variant="primary" iconStart={<CheckCircle size={16} />} disabled={timeUp} onClick={() => void handIn()}>
            Submit answers
          </Button>
        </div>
        {liveRegion}
        <LeaveDialog blocker={blocker} timed={timed} onLeave={() => saver.current?.flush()} />
      </div>
    );
  }

  return (
    <div className={styles.taker}>
      {header}
      <div className={styles.progressRow}>
        <span className={styles.progressText}>
          Question {index + 1} of {questions.length}
        </span>
        <Meter value={(answeredCount / Math.max(1, questions.length)) * 100} size="sm" label={`${answeredCount} of ${questions.length} answered`} />
      </div>
      {hasNegativeMarking(questions) && <p className={styles.note}>Wrong answers lose marks. A question left blank never does.</p>}

      <QuestionPalette questions={questions} answers={answers} current={index} onSelect={setIndex} unsaved={unsaved} />

      {question && (
        <QuestionCard key={question.id} question={question} value={answers[question.id]} onChange={(next) => answer(question.id, next)} disabled={disabled} />
      )}

      <div className={styles.navRow}>
        <Button variant="ghost" iconStart={<ArrowLeft size={16} />} disabled={index === 0} onClick={() => setIndex((i) => i - 1)}>
          Previous
        </Button>
        <span className={styles.navSpacer} />
        {index < questions.length - 1 ? (
          <>
            <Button iconStart={<ListChecks size={16} />} onClick={() => setPhase('review')} disabled={disabled}>
              Review and submit
            </Button>
            <Button variant="primary" iconEnd={<ArrowRight size={16} />} onClick={() => setIndex((i) => i + 1)}>
              Next
            </Button>
          </>
        ) : (
          <Button variant="primary" iconStart={<ListChecks size={16} />} onClick={() => setPhase('review')} disabled={disabled}>
            Review answers
          </Button>
        )}
      </div>
      {liveRegion}
      <LeaveDialog blocker={blocker} timed={timed} onLeave={() => saver.current?.flush()} />
    </div>
  );
}

/** "Opens" or "Opened", "Closes" or "Closed", by where the quiz stands. */
function quizWindowWord(window: QuizStanding['window'], edge: 'opens' | 'closes') {
  if (edge === 'opens') return window === 'upcoming' ? 'Opens' : 'Opened';
  return window === 'closed' ? 'Closed' : 'Closes';
}

/** What the server holds of the answers, in words, as it changes. */
function SaveStatus({ save, unsavedCount, onRetry }: { save: SaverSnapshot | null; unsavedCount: number; onRetry: () => void }) {
  const state = save?.state ?? 'idle';
  const text =
    state === 'saving' || state === 'pending'
      ? 'Saving…'
      : state === 'saved'
        ? 'Saved'
        : state === 'retrying'
          ? 'Not saved yet — retrying'
          : state === 'failed'
            ? 'Couldn’t save'
            : state === 'closed'
              ? 'Saving has stopped'
              : save?.savedAt
                ? 'Saved'
                : 'Answers save as you go';
  return (
    <span className={cx(styles.saveStatus, (state === 'retrying' || state === 'failed') && styles.saveStatusBad, state === 'saved' && styles.saveStatusGood)}>
      <span role="status" aria-live="polite">
        {state === 'retrying' || state === 'failed' ? (
          <WifiSlash size={14} aria-hidden="true" />
        ) : state === 'saved' ? (
          <CheckCircle size={14} aria-hidden="true" />
        ) : null}{' '}
        {text}
        {(state === 'retrying' || state === 'failed') && unsavedCount > 0 && (
          <span className={styles.muted}> · {plural(unsavedCount, 'answer')} only on this page</span>
        )}
      </span>
      {state === 'failed' && save?.error && <span className={styles.muted}> {save.error}</span>}
      {(state === 'retrying' || state === 'failed') && (
        <Button size="sm" variant="ghost" onClick={onRetry}>
          {state === 'failed' ? 'Try again' : 'Retry now'}
        </Button>
      )}
    </span>
  );
}

/** The confirm shown when the learner follows a link away mid-attempt. */
function LeaveDialog({ blocker, timed, onLeave }: { blocker: ReturnType<typeof useBlocker>; timed: boolean; onLeave: () => void }) {
  return (
    <Modal
      open={blocker.state === 'blocked'}
      onClose={() => blocker.reset?.()}
      title="Leave this attempt?"
      description={
        timed
          ? 'The clock keeps running while you’re away. Your saved answers stay, and you can carry on from this lesson until the time is up.'
          : 'Your saved answers stay, and you can carry on from this lesson later.'
      }
      footer={
        <>
          <Button onClick={() => blocker.reset?.()}>Stay</Button>
          <Button
            variant="danger"
            onClick={() => {
              onLeave();
              blocker.proceed?.();
            }}
          >
            Leave
          </Button>
        </>
      }
    />
  );
}
