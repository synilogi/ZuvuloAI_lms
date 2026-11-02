import { CheckCircle, Clock, MinusCircle, XCircle } from '@phosphor-icons/react';
import type { AnswerState, AttemptReview, LearnerQuizQuestion, QuizAnswers, QuizQuestion, ReviewedQuestion } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatMoment, plural } from '@/lib/format';
import { Input } from '@/components/ui/Field/Field';
import { ProgressRing } from '../progress/ProgressRing';
import { isAnswered } from './answerSaver';
import styles from './Quiz.module.css';

/*
 * The pieces a quiz is drawn with, shared by the author's preview (`QuizTaker`) and the learner's attempt
 * (`LearnerQuiz`): one question, the question palette, and a result as the review allows it.
 */

export const STATE_META: Record<AnswerState, { label: string; icon: JSX.Element }> = {
  correct: { label: 'Correct', icon: <CheckCircle size={16} weight="fill" /> },
  partial: { label: 'Partly correct', icon: <MinusCircle size={16} weight="fill" /> },
  incorrect: { label: 'Incorrect', icon: <XCircle size={16} weight="fill" /> },
  unanswered: { label: 'Not answered', icon: <MinusCircle size={16} /> },
};

const TYPE_HINT: Record<QuizQuestion['type'], string> = {
  single: 'Choose one answer',
  multiple: 'Choose all that apply',
  'true-false': 'True or false',
  short: 'Type a short answer',
};

/** Partial credit can leave thirds of a point, and negative marking takes points away; one decimal is enough to read. */
export const formatPoints = (n: number) => {
  const text = Number.isInteger(n) ? String(Math.abs(n)) : Math.abs(n).toFixed(1);
  return n < 0 ? `−${text}` : text;
};

export type AnyQuestion = QuizQuestion | LearnerQuizQuestion;
export const hasKey = (q: AnyQuestion): q is QuizQuestion => 'correct' in q;

/** Whether any question takes marks away for a wrong answer. */
export const hasNegativeMarking = (questions: readonly AnyQuestion[]) => questions.some((q) => (q.negativePoints ?? 0) > 0);

interface QuestionCardProps {
  question: AnyQuestion;
  value: QuizAnswers[string] | undefined;
  onChange: (next: string[] | string) => void;
  disabled?: boolean;
  /** An author checking a question: the key to mark the options with, and how the answer scored. */
  checked?: { key: QuizQuestion; state: AnswerState } | null;
}

/** One question: its prompt, what kind of answer it takes and what it is worth, and the answer controls. */
export function QuestionCard({ question, value, onChange, disabled, checked }: QuestionCardProps) {
  const key = checked?.key;
  return (
    <fieldset className={styles.question} disabled={disabled}>
      <legend className={styles.prompt}>
        <span className={styles.promptMeta}>
          {TYPE_HINT[question.type]} · {plural(question.points, 'point')}
          {question.negativePoints ? ` · −${formatPoints(question.negativePoints)} for a wrong answer` : ''}
          {!question.required && ' · optional'}
        </span>
        {question.prompt || 'Untitled question'}
      </legend>

      {question.type === 'short' ? (
        <Input
          aria-label="Your answer"
          value={typeof value === 'string' ? value : ''}
          onChange={(e) => onChange(e.target.value)}
          disabled={disabled || Boolean(checked)}
          placeholder="Type your answer"
          className={styles.shortInput}
          autoComplete="off"
          spellCheck={false}
        />
      ) : (
        <div className={styles.options}>
          {question.options.map((option) => {
            const picked = Array.isArray(value) && value.includes(option.id);
            const isRight = !!key?.correct.includes(option.id);
            return (
              <label
                key={option.id}
                className={cx(
                  styles.option,
                  picked && styles.optionPicked,
                  checked && isRight && styles.optionRight,
                  checked && picked && !isRight && styles.optionWrong,
                )}
              >
                <input
                  type={question.type === 'multiple' ? 'checkbox' : 'radio'}
                  name={question.id}
                  className={styles.optionInput}
                  checked={picked}
                  disabled={disabled || Boolean(checked)}
                  onChange={() => {
                    if (question.type === 'multiple') {
                      const current = Array.isArray(value) ? value : [];
                      onChange(picked ? current.filter((id) => id !== option.id) : [...current, option.id]);
                    } else onChange([option.id]);
                  }}
                />
                <span className={cx(styles.optionMark, question.type === 'multiple' && styles.optionMarkSquare)} aria-hidden="true" />
                <span className={styles.optionText}>{option.text || 'Untitled answer'}</span>
                {checked && isRight && <CheckCircle size={18} weight="fill" className={styles.optionIcon} aria-label="Correct answer" />}
                {checked && picked && !isRight && <XCircle size={18} weight="fill" className={styles.optionIcon} aria-label="Your answer, incorrect" />}
              </label>
            );
          })}
        </div>
      )}

      {checked && key && (
        <div className={cx(styles.feedback, styles[checked.state])} role="status">
          <span className={styles.reviewState}>
            {STATE_META[checked.state].icon} {STATE_META[checked.state].label}
          </span>
          {key.type === 'short' && checked.state !== 'correct' && (
            <p>
              Accepted: <strong>{key.acceptedAnswers.filter(Boolean).join(', ')}</strong>
            </p>
          )}
          {key.explanation && <p>{key.explanation}</p>}
        </div>
      )}
    </fieldset>
  );
}

interface QuestionPaletteProps {
  questions: AnyQuestion[];
  answers: QuizAnswers;
  current: number;
  onSelect: (index: number) => void;
  /** Questions answered here that the server does not hold yet. */
  unsaved?: ReadonlySet<string>;
}

/** Every question as a numbered button: which are answered, which is open, and which answers are not saved yet. */
export function QuestionPalette({ questions, answers, current, onSelect, unsaved }: QuestionPaletteProps) {
  return (
    <nav className={styles.paletteWrap} aria-label="Questions">
      <ol className={styles.dots}>
        {questions.map((q, i) => {
          const done = isAnswered(answers[q.id]);
          const pending = unsaved?.has(q.id) ?? false;
          const state = [done ? 'answered' : 'not answered', pending ? 'not saved yet' : ''].filter(Boolean).join(', ');
          return (
            <li key={q.id}>
              <button
                type="button"
                className={cx(styles.dot, done && styles.dotDone, pending && styles.dotUnsaved, i === current && styles.dotCurrent)}
                aria-label={`Question ${i + 1}, ${state}`}
                aria-current={i === current ? 'step' : undefined}
                onClick={() => onSelect(i)}
              >
                {i + 1}
              </button>
            </li>
          );
        })}
      </ol>
      {unsaved && (
        <p className={styles.legend} aria-hidden="true">
          <span className={cx(styles.legendDot, styles.dotDone)} /> Answered
          <span className={cx(styles.legendDot, styles.dotDone, styles.dotUnsaved)} /> Answered, not saved yet
          <span className={styles.legendDot} /> Not answered
        </p>
      )}
    </nav>
  );
}

/** The right answer as the review states it, in the words of the question's own options. */
function correctText(q: AnyQuestion, r: ReviewedQuestion) {
  if (q.type === 'short') return (r.acceptedAnswers ?? []).join(' / ');
  return q.options
    .filter((o) => r.correct?.includes(o.id))
    .map((o) => o.text)
    .join(', ');
}

/** The learner's own answer, in words. */
function answerText(q: AnyQuestion, answer: ReviewedQuestion['answer']) {
  if (!isAnswered(answer)) return 'Not answered';
  if (typeof answer === 'string') return answer;
  return q.options
    .filter((o) => answer?.includes(o.id))
    .map((o) => o.text)
    .join(', ');
}

interface AttemptResultProps {
  review: AttemptReview;
  /** The attempt's questions, to show each one's outcome — only when the review carries them. */
  questions?: AnyQuestion[];
  /** The points available, when the review does not say. */
  totalPoints?: number;
  passMark: number;
}

/** A result as the quiz lets the learner see it: received only, the score, or the score and every answer. */
export function AttemptResult({ review, questions, totalPoints, passMark }: AttemptResultProps) {
  const reviewed = review.questions;
  const expired = review.finish === 'expired';
  return (
    <>
      {/* Held until the quiz closes: received, and when the result comes — not even whether it passed. */}
      {review.showResults === 'hidden' || review.resultsAt ? (
        <div className={styles.resultHead}>
          <CheckCircle size={40} weight="duotone" className={styles.resultIcon} />
          <div>
            <h2 className={styles.title}>Submitted</h2>
            <p className={styles.instructions}>
              {review.resultsAt
                ? `Results for this quiz are released when it closes, on ${formatMoment(review.resultsAt)}.`
                : 'Your instructor will release results once reviews are complete.'}
            </p>
          </div>
        </div>
      ) : (
        <div className={styles.resultHead}>
          <ProgressRing
            value={review.percent ?? 0}
            size="lg"
            label="Your score"
            threshold={review.passMark ?? passMark}
            tone={review.passed ? 'accent' : 'danger'}
          />
          <div>
            <span className={cx(styles.verdict, review.passed ? styles.passed : styles.failed)}>
              {review.passed ? <CheckCircle size={16} weight="fill" /> : <XCircle size={16} weight="fill" />}
              {review.passed ? 'Passed' : 'Not passed yet'}
            </span>
            <h2 className={styles.title}>
              {formatPoints(review.points ?? 0)} of {review.max ?? totalPoints ?? 0} points
            </h2>
            <p className={styles.instructions}>
              {review.percent ?? 0}% · pass mark {review.passMark ?? passMark}%
              {reviewed && ` · ${plural(Object.values(reviewed).filter((q) => q.state === 'correct').length, 'question')} fully correct`}
            </p>
          </div>
        </div>
      )}
      {expired && (
        <p className={styles.note}>
          <Clock size={16} aria-hidden="true" /> Time ran out. The answers saved by then were marked.
        </p>
      )}
      {review.keyWithheld && <p className={styles.note}>The correct answers appear once you pass, or once you have no attempts left.</p>}
      {reviewed && questions && (
        <ol className={styles.review} aria-label="Your answers">
          {questions.map((q, i) => {
            const r = reviewed[q.id];
            if (!r) return null;
            return (
              <li key={q.id} className={cx(styles.reviewItem, styles[r.state])}>
                <span className={styles.reviewState}>
                  {STATE_META[r.state].icon}
                  {STATE_META[r.state].label} · {formatPoints(r.points)}/{q.points}
                </span>
                <p className={styles.reviewPrompt}>
                  {i + 1}. {q.prompt}
                </p>
                {'answer' in r && (
                  <p className={styles.reviewAnswer}>
                    Your answer: <strong>{answerText(q, r.answer)}</strong>
                  </p>
                )}
                {(r.correct || r.acceptedAnswers) && (
                  <p className={styles.reviewAnswer}>
                    Correct answer: <strong>{correctText(q, r)}</strong>
                  </p>
                )}
                {r.explanation && <p className={styles.explanation}>{r.explanation}</p>}
              </li>
            );
          })}
        </ol>
      )}
    </>
  );
}

/** The learner's attempts, newest first: when, how it ended, and the score where it may be seen. */
export function AttemptHistory({ attempts }: { attempts: AttemptReview[] }) {
  if (!attempts.length) return null;
  return (
    <section className={styles.history} aria-labelledby="attempt-history-title">
      <h3 id="attempt-history-title" className={styles.historyTitle}>
        Your attempts
      </h3>
      <ol className={styles.historyList}>
        {attempts.map((a, i) => (
          <li key={a.attemptId} className={styles.historyItem}>
            <span className={styles.historyNo}>Attempt {a.attemptNo ?? attempts.length - i}</span>
            <span className={styles.historyWhen}>
              <time dateTime={a.submittedAt}>{formatMoment(a.submittedAt)}</time>
              {a.finish === 'expired' && ' · time ran out'}
            </span>
            <span className={styles.historyScore}>
              {a.showResults === 'hidden' || a.resultsAt
                ? a.resultsAt
                  ? `Result on ${formatMoment(a.resultsAt)}`
                  : 'Result not shown yet'
                : `${a.percent ?? 0}% · ${a.passed ? 'Passed' : 'Not passed'}`}
            </span>
          </li>
        ))}
      </ol>
    </section>
  );
}
