import type { ID, ISODateTime } from './catalog';
import { resultsVisibilityOf, type LearnerQuizQuestion, type QuizAnswers, type QuizQuestion, type QuizSettings } from './quiz';

/*
 * Quiz sessions (A2): a learner's attempt from the moment the server starts it.
 *
 * - Starting consumes an attempt. The server fixes the deadline when it starts the session and keeps it.
 * - Answers count only once the server has accepted them, and it accepts them only up to the deadline, by its own
 *   clock. Nothing a client says about time is trusted; a client's countdown is for display.
 * - A submission may still arrive up to `QUIZ_SUBMIT_GRACE_SEC` after the deadline and count as handed in on time —
 *   but it can only deliver what was already accepted: answers sent with it after the deadline are not taken.
 * - A session left open past its deadline and the grace is finalised by the server with the answers it accepted:
 *   the attempt is "expired", scored like any other. An untimed session stays open until it is submitted.
 */

/** How long after its deadline a submission may arrive and still count as handed in on time — for the network, never for answering. */
export const QUIZ_SUBMIT_GRACE_SEC = 60;

export type QuizSessionStatus = 'active' | 'submitted' | 'expired';

/** A session as the learner's app is sent it. */
export interface QuizSessionView {
  id: ID;
  quizId: ID;
  /** 1 for the learner's first attempt at this quiz, counting attempts made before sessions existed. */
  attemptNo: number;
  status: QuizSessionStatus;
  startedAt: ISODateTime;
  /** Absent for an untimed quiz. */
  deadlineAt?: ISODateTime;
  /** The server's clock when it answered: a countdown is drawn from `remainingSec`, never from the device's clock. */
  serverNow: ISODateTime;
  /** Whole seconds to the deadline by the server's clock, never below 0. Absent for an untimed quiz. */
  remainingSec?: number;
  /** The answers the server has accepted. */
  answers: QuizAnswers;
  /** The highest save number the server has accepted — a save with a lower one arrived late and is ignored. */
  answersSeq: number;
  savedAt?: ISODateTime;
  finishedAt?: ISODateTime;
  /** The scored attempt, once the session is finished. */
  attemptId?: ID;
}

/** What starting or resuming a session answers: the session and — only now — its questions, without their key. */
export interface QuizSessionStart {
  session: QuizSessionView;
  questions: LearnerQuizQuestion[];
  /** True when an open session was picked up again instead of a new attempt being started. */
  resumed: boolean;
}

/** Where a moment stands against a session's deadline. */
export type DeadlineWindow = 'open' | 'grace' | 'closed';

/** The deadline a session started at `startedAt` gets: none for an untimed quiz. */
export function quizDeadline(startedAt: Date, timeLimitMin?: number | null): Date | null {
  if (!timeLimitMin || timeLimitMin <= 0) return null;
  return new Date(startedAt.getTime() + timeLimitMin * 60_000);
}

/** `open` up to and at the deadline; `grace` for the transport grace after it; `closed` after that. Untimed: always open. */
export function deadlineWindow(deadline: Date | null, now: Date): DeadlineWindow {
  if (!deadline) return 'open';
  const t = now.getTime();
  if (t <= deadline.getTime()) return 'open';
  return t <= deadline.getTime() + QUIZ_SUBMIT_GRACE_SEC * 1000 ? 'grace' : 'closed';
}

/** Whole seconds left before the deadline, never below 0; undefined for an untimed quiz. */
export function remainingSec(deadline: Date | null, now: Date): number | undefined {
  if (!deadline) return undefined;
  return Math.max(0, Math.floor((deadline.getTime() - now.getTime()) / 1000));
}

/**
 * Attempts a learner has used at a quiz: every session started (each consumed one when it began), plus the attempts
 * made before sessions existed — those carry no session.
 */
export function attemptsUsed(sessions: readonly unknown[], attempts: readonly { sessionId?: string | null }[]): number {
  return sessions.length + attempts.filter((a) => !a.sessionId).length;
}

/**
 * The answers a save leaves stored: `incoming` over `saved`, for this session's questions only and only in the shape
 * each question type takes — a choice question's option ids that exist (one at most where one is allowed), a short
 * answer's text. An empty list or empty text clears an answer. Anything else is dropped, not stored.
 */
export function acceptAnswers(questions: readonly QuizQuestion[], saved: QuizAnswers, incoming: QuizAnswers): QuizAnswers {
  const out: QuizAnswers = { ...saved };
  const byId = new Map(questions.map((q) => [q.id, q]));
  for (const [id, value] of Object.entries(incoming)) {
    const q = byId.get(id);
    if (!q) continue;
    if (q.type === 'short') {
      if (typeof value !== 'string') continue;
      const text = value.slice(0, 2000);
      if (text.trim()) out[id] = text;
      else delete out[id];
      continue;
    }
    if (!Array.isArray(value)) continue;
    const options = new Set(q.options.map((o) => o.id));
    const picked = [...new Set(value.filter((v): v is string => typeof v === 'string' && options.has(v)))];
    const kept = q.type === 'multiple' ? picked : picked.slice(0, 1);
    if (kept.length) out[id] = kept;
    else delete out[id];
  }
  // Answers to questions the session does not hold never stay, whatever was stored before.
  for (const id of Object.keys(out)) if (!byId.has(id)) delete out[id];
  return out;
}

/** The order one learner sees a session's questions and each question's options in, fixed when it starts. */
export interface QuizOrder {
  questions: ID[];
  options: Record<ID, ID[]>;
}

/** Fisher–Yates with the given source of randomness. */
function shuffled<T>(items: readonly T[], random: () => number): T[] {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

/** The order for a new session: shuffled as the quiz's settings ask, otherwise as authored. True/false keeps its order. */
export function sessionOrder(
  questions: readonly QuizQuestion[],
  settings: Pick<QuizSettings, 'shuffleQuestions' | 'shuffleOptions'>,
  random: () => number,
): QuizOrder {
  const authored = questions.map((q) => q.id);
  const ids = settings.shuffleQuestions ? shuffled(authored, random) : authored;
  const options: Record<ID, ID[]> = {};
  for (const q of questions) {
    const own = q.options.map((o) => o.id);
    options[q.id] = settings.shuffleOptions && q.type !== 'true-false' ? shuffled(own, random) : own;
  }
  return { questions: ids, options };
}

/** Questions in the session's order, each with its options in that order. Questions or options the order does not name keep their place after it. */
export function inSessionOrder<Q extends { id: ID; options: { id: ID }[] }>(questions: readonly Q[], order: QuizOrder): Q[] {
  const rank = (ids: ID[], id: ID) => {
    const i = ids.indexOf(id);
    return i === -1 ? Number.MAX_SAFE_INTEGER : i;
  };
  return [...questions]
    .sort((a, b) => rank(order.questions, a.id) - rank(order.questions, b.id))
    .map((q) => {
      const opts = order.options[q.id];
      return opts ? { ...q, options: [...q.options].sort((a, b) => rank(opts, a.id) - rank(opts, b.id)) } : q;
    });
}

/* ─── A quiz's window ─────────────────────────────────────────────────── */

/** Where a moment stands against a quiz's opening and closing times. */
export type QuizWindow = 'upcoming' | 'open' | 'closed';

const at = (iso: string | undefined) => (iso ? new Date(iso) : null);

export function quizWindow(settings: Pick<QuizSettings, 'opensAt' | 'closesAt'>, now: Date): QuizWindow {
  const opens = at(settings.opensAt);
  const closes = at(settings.closesAt);
  if (opens && now.getTime() < opens.getTime()) return 'upcoming';
  if (closes && now.getTime() >= closes.getTime()) return 'closed';
  return 'open';
}

/** A session's deadline: the time limit from its start, cut to the quiz's close; none when neither applies. */
export function sessionDeadline(startedAt: Date, settings: Pick<QuizSettings, 'timeLimitMin' | 'closesAt'>): Date | null {
  const limited = quizDeadline(startedAt, settings.timeLimitMin);
  const closes = at(settings.closesAt);
  if (!closes) return limited;
  return limited && limited.getTime() < closes.getTime() ? limited : closes;
}

/** Whether a quiz's results are out: at once (`on-submit`), or once it has closed (`after-close`; no close never holds them). */
export function resultsOut(settings: Pick<QuizSettings, 'resultsRelease' | 'closesAt'>, now: Date): boolean {
  if (settings.resultsRelease !== 'after-close') return true;
  const closes = at(settings.closesAt);
  return !closes || now.getTime() >= closes.getTime();
}

/** Whether a learner may see their score in a list or summary: results are out, and the quiz does not hide them. */
export function scoreShown(settings: Pick<QuizSettings, 'resultsRelease' | 'closesAt' | 'showResults'>, now: Date): boolean {
  return resultsOut(settings, now) && resultsVisibilityOf(settings.showResults) !== 'hidden';
}

/** Where a learner stands with one quiz: what they may do next. The server's start still decides. */
export interface QuizStanding {
  quizId: ID;
  serverNow: ISODateTime;
  window: QuizWindow;
  opensAt?: ISODateTime;
  closesAt?: ISODateTime;
  /** 0 means unlimited. Once the quiz is passed, more attempts are practice and not limited. */
  attemptsAllowed: number;
  /** Every attempt started, finished or not, and those made before sessions existed. */
  attemptsUsed: number;
  passed: boolean;
  /** The attempt still open, to resume — its questions come with `POST …/quiz-session`. */
  openSession?: QuizSessionView;
  /** True when an attempt is open to resume or a new one may start. */
  canStart: boolean;
  /** Why not, in the academy's words. */
  blockedReason?: string;
  /** While results are held until the quiz closes: when they are shown. */
  resultsAt?: ISODateTime;
}
