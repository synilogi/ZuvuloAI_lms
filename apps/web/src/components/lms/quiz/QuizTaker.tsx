import { useEffect, useMemo, useState } from 'react';
import { ArrowLeft, ArrowRight, Clock, Exam, Timer } from '@phosphor-icons/react';
import type { AttemptReview, Quiz, QuizAnswers, QuizQuestion } from '@syniastrolms/domain';
import { quizTotalPoints, reviewAttempt, scoreAttempt } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatClock } from '@/lib/format';
import { Button } from '@/components/ui/Button/Button';
import { Meter } from '../progress/Meters';
import { isAnswered } from './answerSaver';
import { AttemptResult, hasKey, hasNegativeMarking, QuestionCard, QuestionPalette, type AnyQuestion } from './QuizParts';
import { timerTone } from './quizClock';
import styles from './Quiz.module.css';

interface QuizTakerProps {
  /** The author's quiz, with its key: the preview is scored here, by the rule the server applies. */
  quiz: Pick<Quiz, 'title' | 'instructions' | 'settings'> & { questions: AnyQuestion[] };
  /** Show each question's result as soon as it is answered — for authors checking their questions. Needs the key. */
  revealAsYouGo?: boolean;
  /** Label for the context line above the title. */
  context?: string;
}

/**
 * The author's preview of a quiz: an introduction, one question at a time with progress and the time limit counted
 * down here, then the result cut to what the quiz's settings show learners. Nothing is recorded. A learner's attempt
 * runs on the server instead — `LearnerQuiz`.
 */
export function QuizTaker({ quiz, revealAsYouGo, context }: QuizTakerProps) {
  const [phase, setPhase] = useState<'intro' | 'taking' | 'done'>('intro');
  const [index, setIndex] = useState(0);
  const [answers, setAnswers] = useState<QuizAnswers>({});
  const [checked, setChecked] = useState<Set<string>>(new Set());
  const [secondsLeft, setSecondsLeft] = useState<number | null>(null);

  // A shuffled quiz still shows a stable order within one preview.
  const questions = useMemo(
    () => (quiz.settings.shuffleQuestions ? [...quiz.questions].sort((a, b) => spread(a.id) - spread(b.id)) : quiz.questions),
    [quiz.questions, quiz.settings.shuffleQuestions],
  );
  const total = quizTotalPoints(quiz);
  const keyed = quiz.questions.every(hasKey) ? (quiz.questions as QuizQuestion[]) : null;
  // The author's preview is cut by the same rule the server applies to a learner's review.
  const result: AttemptReview | null =
    phase === 'done' && keyed
      ? {
          ...reviewAttempt(
            { questions: keyed, settings: quiz.settings },
            { id: 'preview', submittedAt: '', result: scoreAttempt({ questions: keyed, settings: quiz.settings }, answers), answers },
          ),
          finish: secondsLeft === 0 ? 'expired' : 'submitted',
        }
      : null;
  const question = questions[index];
  const answered = questions.filter((q) => isAnswered(answers[q.id])).length;

  useEffect(() => {
    if (phase !== 'taking' || secondsLeft === null) return;
    if (secondsLeft <= 0) {
      setPhase('done');
      return;
    }
    const id = window.setTimeout(() => setSecondsLeft((s) => (s === null ? s : s - 1)), 1000);
    return () => window.clearTimeout(id);
  }, [phase, secondsLeft]);

  const start = () => {
    setAnswers({});
    setChecked(new Set());
    setIndex(0);
    setSecondsLeft(quiz.settings.timeLimitMin ? quiz.settings.timeLimitMin * 60 : null);
    setPhase('taking');
  };

  if (questions.length === 0) {
    return (
      <div className={styles.taker}>
        <p className={styles.empty}>
          <Exam size={24} /> This quiz has no questions yet. Add a question to preview it.
        </p>
      </div>
    );
  }

  if (phase === 'intro') {
    return (
      <div className={styles.taker}>
        <div className={styles.intro}>
          {context && <span className={styles.context}>{context}</span>}
          <h2 className={styles.title}>{quiz.title || 'Untitled quiz'}</h2>
          {quiz.instructions && <p className={styles.instructions}>{quiz.instructions}</p>}
          <dl className={styles.facts}>
            <div>
              <dt>Questions</dt>
              <dd>{questions.length}</dd>
            </div>
            <div>
              <dt>Points</dt>
              <dd>{total}</dd>
            </div>
            <div>
              <dt>Pass mark</dt>
              <dd>{quiz.settings.passMark}%</dd>
            </div>
            <div>
              <dt>Time limit</dt>
              <dd>{quiz.settings.timeLimitMin ? `${quiz.settings.timeLimitMin} min` : 'None'}</dd>
            </div>
            <div>
              <dt>Attempts</dt>
              <dd>{quiz.settings.attempts || 'Unlimited'}</dd>
            </div>
          </dl>
          {hasNegativeMarking(questions) && <p className={styles.note}>Wrong answers lose marks. A question left blank never does.</p>}
          <Button variant="primary" size="lg" onClick={start} iconEnd={<ArrowRight size={16} />}>
            Start quiz
          </Button>
        </div>
      </div>
    );
  }

  if (phase === 'done') {
    return (
      <div className={styles.taker}>
        {result ? (
          <AttemptResult review={result} questions={questions} totalPoints={total} passMark={quiz.settings.passMark} />
        ) : (
          <p className={styles.empty}>Every question needs its answer key to be scored in the preview.</p>
        )}
        <div className={styles.navRow}>
          <Button onClick={() => setPhase('intro')}>Back to the start</Button>
          <Button variant="primary" onClick={start}>
            Try again
          </Button>
        </div>
      </div>
    );
  }

  const value = answers[question.id];
  const keyedQuestion = hasKey(question) ? question : null;
  const isChecked = !!keyedQuestion && revealAsYouGo && checked.has(question.id);
  const questionResult =
    isChecked && keyedQuestion
      ? scoreAttempt({ questions: [keyedQuestion], settings: quiz.settings }, { [question.id]: value ?? [] }).questions[question.id]
      : null;

  return (
    <div className={styles.taker}>
      <div className={styles.progressRow}>
        <span className={styles.progressText}>
          Question {index + 1} of {questions.length}
        </span>
        <Meter value={(answered / questions.length) * 100} size="sm" label={`${answered} of ${questions.length} answered`} />
        {secondsLeft !== null && (
          <span className={cx(styles.timer, styles[`timer-${timerTone(secondsLeft)}`])} role="timer" aria-label="Time left">
            <Timer size={15} aria-hidden="true" /> {formatClock(secondsLeft)}
          </span>
        )}
      </div>

      <QuestionPalette questions={questions} answers={answers} current={index} onSelect={setIndex} />

      <QuestionCard
        key={question.id}
        question={question}
        value={value}
        onChange={(next) => setAnswers((a) => ({ ...a, [question.id]: next }))}
        checked={questionResult && keyedQuestion ? { key: keyedQuestion, state: questionResult.state } : null}
      />

      <div className={styles.navRow}>
        <Button variant="ghost" iconStart={<ArrowLeft size={16} />} disabled={index === 0} onClick={() => setIndex((i) => i - 1)}>
          Previous
        </Button>
        <span className={styles.navSpacer} />
        {revealAsYouGo && keyedQuestion && !isChecked && (
          <Button onClick={() => setChecked((s) => new Set(s).add(question.id))} disabled={value === undefined}>
            Check answer
          </Button>
        )}
        {index < questions.length - 1 ? (
          <Button variant="primary" iconEnd={<ArrowRight size={16} />} onClick={() => setIndex((i) => i + 1)}>
            Next
          </Button>
        ) : (
          <Button variant="primary" iconStart={<Clock size={16} />} onClick={() => setPhase('done')}>
            Submit answers
          </Button>
        )}
      </div>
    </div>
  );
}

/** A stable pseudo-random rank for an id. */
function spread(id: string) {
  let h = 2166136261;
  for (let i = 0; i < id.length; i++) h = Math.imul(h ^ id.charCodeAt(i), 16777619);
  return h >>> 0;
}
