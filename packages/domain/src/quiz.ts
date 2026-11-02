import type { ID, ISODateTime } from './catalog';

export type QuestionType = 'single' | 'multiple' | 'true-false' | 'short';

export interface QuizOption {
  id: ID;
  text: string;
}

export interface QuizQuestion {
  id: ID;
  type: QuestionType;
  prompt: string;
  /** Choices for single, multiple and true/false questions. */
  options: QuizOption[];
  /** Ids of the correct options. */
  correct: ID[];
  /** Short-answer questions: answers accepted, compared without case or surrounding space. */
  acceptedAnswers: string[];
  points: number;
  /** Shown after the learner answers, when results allow it. */
  explanation?: string;
  required: boolean;
  /** Marks taken away for a wrong answer — never for leaving it blank. 0 or absent: none. */
  negativePoints?: number;
}

/**
 * When a learner sees a result: as soon as the attempt is handed in, or once the quiz has closed (`closesAt`) — for
 * everyone at the same moment. Until then a review says only that the attempt was received.
 */
export type ResultsRelease = 'on-submit' | 'after-close';

/** What a learner sees after submitting. */
export type ResultsVisibility = 'score-and-answers' | 'score-only' | 'hidden';

export interface QuizSettings {
  /** Percent of points needed to pass. */
  passMark: number;
  /** 0 means unlimited. */
  attempts: number;
  timeLimitMin?: number;
  shuffleQuestions: boolean;
  shuffleOptions: boolean;
  showResults: ResultsVisibility;
  /** Absent: `on-submit`, as every quiz before windows existed. `after-close` needs `closesAt`. */
  resultsRelease?: ResultsRelease;
  /** No attempt starts before this moment (ISO with offset). */
  opensAt?: ISODateTime;
  /** No attempt starts from this moment, and none runs past it: one under way is handed in with what was saved. */
  closesAt?: ISODateTime;
}

/** `archived` keeps the quiz and every result, but no learner starts it again. */
export type QuizStatus = 'draft' | 'published' | 'archived';

export interface Quiz {
  id: ID;
  courseId: ID;
  chapterId?: ID;
  /** The lesson that delivers the quiz, when it is part of the curriculum. */
  lessonId?: ID;
  title: string;
  instructions: string;
  status: QuizStatus;
  questions: QuizQuestion[];
  settings: QuizSettings;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export type QuizInput = Pick<Quiz, 'courseId' | 'chapterId' | 'title' | 'instructions' | 'status' | 'questions' | 'settings'> & {
  /** The assessment lesson that delivers this quiz, when created from a lesson. */
  lessonId?: ID;
};

export const defaultQuizSettings: QuizSettings = {
  passMark: 70,
  attempts: 2,
  timeLimitMin: undefined,
  shuffleQuestions: false,
  shuffleOptions: true,
  showResults: 'score-and-answers',
};

export const quizTotalPoints = (quiz: { questions: { points: number }[] }) => quiz.questions.reduce((n, q) => n + (q.points || 0), 0);

export interface QuizIssue {
  /** Undefined for quiz-level issues. */
  questionId?: ID;
  field: 'title' | 'questions' | 'prompt' | 'options' | 'correct' | 'answers' | 'points' | 'settings';
  message: string;
}

export function validateQuestion(q: QuizQuestion): QuizIssue[] {
  const issues: QuizIssue[] = [];
  const at = (field: QuizIssue['field'], message: string) => issues.push({ questionId: q.id, field, message });
  if (!q.prompt.trim()) at('prompt', 'Write the question.');
  if (!Number.isInteger(q.points) || q.points < 1 || q.points > 100) at('points', 'Points must be a whole number from 1 to 100.');
  const options = q.options ?? [];
  const correct = q.correct ?? [];
  const optionIds = new Set(options.map((o) => o.id));
  if (q.type === 'single' || q.type === 'multiple') {
    if (options.length < 2) at('options', 'Add at least two answers to choose from.');
    else if (options.some((o) => !o.text.trim())) at('options', 'Every answer needs text.');
    if (q.type === 'single' && correct.length !== 1) at('correct', 'Mark the one correct answer.');
    if (q.type === 'multiple' && correct.length < 1) at('correct', 'Mark at least one correct answer.');
  }
  if (q.type === 'true-false' && correct.length !== 1) at('correct', 'Choose whether the statement is true or false.');
  if (q.type !== 'short') {
    if (optionIds.size !== options.length) at('options', 'Two answers share an id. Delete one and add it again.');
    // A key naming an answer that is not on offer, or the same answer twice, makes full marks unreachable.
    if (correct.some((id) => !optionIds.has(id)) || new Set(correct).size !== correct.length) at('correct', 'Mark the correct answer again.');
  }
  if (q.type === 'short' && !(q.acceptedAnswers ?? []).some((a) => a.trim())) at('answers', 'Add at least one accepted answer.');
  if (q.negativePoints !== undefined && (!(q.negativePoints >= 0) || q.negativePoints > q.points)) {
    at('points', 'Negative marks must be between 0 and the question’s marks.');
  }
  return issues;
}

/** Everything that would stop the quiz from being published. */
export function validateQuiz(quiz: Pick<Quiz, 'title' | 'questions' | 'settings'>): QuizIssue[] {
  const issues: QuizIssue[] = [];
  if (quiz.title.trim().length < 3) issues.push({ field: 'title', message: 'Give the quiz a title of at least 3 characters.' });
  if (quiz.questions.length === 0) issues.push({ field: 'questions', message: 'Add at least one question.' });
  const s = quiz.settings;
  // A quiz without a pass mark could never be passed: its lesson, the course and the certificate would never complete.
  if (!Number.isInteger(s.passMark) || s.passMark < 1 || s.passMark > 100)
    issues.push({ field: 'settings', message: 'The pass mark must be between 1% and 100%.' });
  if (s.timeLimitMin != null && (!Number.isInteger(s.timeLimitMin) || s.timeLimitMin < 1 || s.timeLimitMin > 240))
    issues.push({ field: 'settings', message: 'A time limit must be between 1 and 240 minutes.' });
  if (s.attempts != null && (!Number.isInteger(s.attempts) || s.attempts < 0 || s.attempts > 99))
    issues.push({ field: 'settings', message: 'Attempts must be a whole number from 0 (unlimited) to 99.' });
  const opens = s.opensAt ? Date.parse(s.opensAt) : undefined;
  const closes = s.closesAt ? Date.parse(s.closesAt) : undefined;
  if (Number.isNaN(opens) || Number.isNaN(closes)) issues.push({ field: 'settings', message: 'Enter the opening and closing times as dates.' });
  else if (opens !== undefined && closes !== undefined && closes <= opens) issues.push({ field: 'settings', message: 'The quiz must close after it opens.' });
  if (s.resultsRelease === 'after-close' && !s.closesAt)
    issues.push({ field: 'settings', message: 'Set a closing time to show results once the quiz closes.' });
  if (new Set(quiz.questions.map((q) => q.id)).size !== quiz.questions.length)
    issues.push({ field: 'questions', message: 'Two questions share an id. Delete one and add it again.' });
  return [...issues, ...quiz.questions.flatMap(validateQuestion)];
}

export type AnswerState = 'correct' | 'incorrect' | 'partial' | 'unanswered';
/** Option ids for choice questions, typed text for short answers. */
export type QuizAnswers = Record<ID, ID[] | string>;

export interface AttemptResult {
  points: number;
  max: number;
  percent: number;
  passed: boolean;
  questions: Record<ID, { state: AnswerState; points: number }>;
}

const normalise = (text: string) => text.trim().toLowerCase().replace(/\s+/g, ' ');

/**
 * Scores an attempt. Multiple-choice questions earn partial credit: correct picks minus wrong
 * picks, never below zero, as a share of the correct answers. A wrong answer loses the question's negative marks, if
 * it has any; a blank one never does, and a partly right one keeps its partial credit. The total may fall below zero;
 * the percentage never does.
 */
export function scoreAttempt(quiz: Pick<Quiz, 'questions' | 'settings'>, answers: QuizAnswers): AttemptResult {
  const max = quizTotalPoints(quiz);
  let points = 0;
  const questions: AttemptResult['questions'] = {};
  for (const q of quiz.questions) {
    const answer = answers[q.id];
    let earned = 0;
    let state: AnswerState;
    if (answer === undefined || (Array.isArray(answer) && answer.length === 0) || (typeof answer === 'string' && !answer.trim())) {
      state = 'unanswered';
    } else if (q.type === 'short') {
      const ok = q.acceptedAnswers.some((a) => normalise(a) === normalise(String(answer)));
      earned = ok ? q.points : 0;
      state = ok ? 'correct' : 'incorrect';
    } else if (q.type === 'multiple') {
      const picked = answer as ID[];
      const right = picked.filter((id) => q.correct.includes(id)).length;
      const wrong = picked.length - right;
      const share = Math.max(0, right - wrong) / q.correct.length;
      earned = Math.round(q.points * share * 100) / 100;
      state = share === 1 && wrong === 0 ? 'correct' : share > 0 ? 'partial' : 'incorrect';
    } else {
      const ok = (answer as ID[])[0] === q.correct[0];
      earned = ok ? q.points : 0;
      state = ok ? 'correct' : 'incorrect';
    }
    if (state === 'incorrect' && q.negativePoints) earned = -q.negativePoints;
    points += earned;
    questions[q.id] = { state, points: earned };
  }
  // Rounded down, so 69.5% never shows as 70% nor passes a 70% mark; the epsilon absorbs float error (0.29 × 100).
  const percent = max === 0 ? 0 : Math.max(0, Math.floor((points / max) * 100 + 1e-9));
  return { points: Math.round(points * 100) / 100, max, percent, passed: percent >= quiz.settings.passMark, questions };
}

/**
 * The score a learner is credited with: the best of their attempts up to and including the first that passed. Retakes
 * after a pass are practice — unlimited, and taken with the answers already shown — so they never raise it.
 */
export function creditedPercent(attempts: { percent: number; passed: boolean; createdAt: Date | string }[]): number | undefined {
  if (!attempts.length) return undefined;
  const ordered = [...attempts].sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
  const firstPass = ordered.findIndex((a) => a.passed);
  return Math.max(...(firstPass === -1 ? ordered : ordered.slice(0, firstPass + 1)).map((a) => a.percent));
}

/* ─── What a learner may see ──────────────────────────────────────────── */

/** A question as a learner receives it: everything needed to answer, nothing that gives the answer away. */
export type LearnerQuizQuestion = Pick<QuizQuestion, 'id' | 'type' | 'prompt' | 'options' | 'points' | 'required' | 'negativePoints'>;

/** A quiz as a learner receives it before answering. The key stays on the server, which scores every attempt. */
export type LearnerQuiz = Omit<Quiz, 'questions'> & { questions: LearnerQuizQuestion[] };

/** Picks the answerable fields by name, so a field added to `QuizQuestion` later is withheld until someone decides otherwise. */
export const learnerQuestion = (q: QuizQuestion): LearnerQuizQuestion => ({
  id: q.id,
  type: q.type,
  prompt: q.prompt,
  options: q.options.map((o) => ({ id: o.id, text: o.text })),
  points: q.points,
  required: q.required,
  // How the paper is marked is the learner's to know; the answer is not.
  ...(q.negativePoints ? { negativePoints: q.negativePoints } : {}),
});

export const learnerQuiz = (quiz: Quiz): LearnerQuiz => ({ ...quiz, questions: quiz.questions.map(learnerQuestion) });

/**
 * `hidden` is the domain's word; `nothing` is what the API accepted before it took the domain's. Both mean
 * the learner is told only that the attempt was received.
 */
export const resultsReleaseOf = (value: unknown): ResultsRelease => (value === 'after-close' ? 'after-close' : 'on-submit');

export const resultsVisibilityOf = (value: unknown): ResultsVisibility =>
  value === 'score-only' ? 'score-only' : value === 'hidden' || value === 'nothing' ? 'hidden' : 'score-and-answers';

/** One question of a reviewed attempt: always its outcome, and the answer only when the quiz shows answers. */
export interface ReviewedQuestion {
  state: AnswerState;
  points: number;
  /** The learner's own answer, as submitted. */
  answer?: ID[] | string;
  correct?: ID[];
  acceptedAnswers?: string[];
  explanation?: string;
}

/**
 * An attempt as the learner may see it after submitting, cut to the quiz's `showResults`:
 * - `score-and-answers` — score, each question's outcome and the correct answers;
 * - `score-only` — the score, and nothing about individual questions;
 * - `hidden` — only that it was received and whether it passed, which completion reveals anyway.
 */
export interface AttemptReview {
  attemptId: ID;
  submittedAt: ISODateTime;
  showResults: ResultsVisibility;
  passed: boolean;
  percent?: number;
  points?: number;
  max?: number;
  passMark?: number;
  questions?: Record<ID, ReviewedQuestion>;
  /**
   * Set while the learner can still take the quiz for credit — not passed, attempts left, or one open: the review is
   * cut to the score so one attempt does not hand the answers to the next.
   */
  keyWithheld?: boolean;
  /** Set while `resultsRelease: after-close` holds the result back: when it will be shown. */
  resultsAt?: ISODateTime;
  /** 1 for the learner's first attempt; absent on attempts made before attempts were numbered. */
  attemptNo?: number;
  /** `expired`: the server handed it in at the deadline, with the answers saved by then. */
  finish?: 'submitted' | 'expired';
}

export function reviewAttempt(
  quiz: Pick<Quiz, 'questions' | 'settings'>,
  attempt: { id: ID; submittedAt: ISODateTime; result: AttemptResult; answers: QuizAnswers },
): AttemptReview {
  const showResults = resultsVisibilityOf(quiz.settings.showResults);
  const base = { attemptId: attempt.id, submittedAt: attempt.submittedAt, showResults, passed: attempt.result.passed };
  if (showResults === 'hidden') return base;
  const score = { ...base, percent: attempt.result.percent, points: attempt.result.points, max: attempt.result.max, passMark: quiz.settings.passMark };
  if (showResults === 'score-only') return score;
  const questions: Record<ID, ReviewedQuestion> = {};
  for (const q of quiz.questions) {
    // An attempt recorded without its per-question outcomes (sample data, older rows) reads as unanswered, never fails.
    const outcome = attempt.result.questions?.[q.id] ?? { state: 'unanswered' as const, points: 0 };
    questions[q.id] = {
      ...outcome,
      answer: attempt.answers[q.id],
      ...(q.type === 'short' ? { acceptedAnswers: q.acceptedAnswers.filter((a) => a.trim()) } : { correct: q.correct }),
      ...(q.explanation ? { explanation: q.explanation } : {}),
    };
  }
  return { ...score, questions };
}
