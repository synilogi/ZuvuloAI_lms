import type { QuizAnswers, QuizSessionView } from '@syniastrolms/domain';

/*
 * Autosave for a quiz attempt. Every save carries the whole answer sheet and a number (`seq`) that only grows; the
 * server stores a sheet only when its number is higher than the one it holds, and only before the deadline. So:
 *
 * - one save is in flight at a time, the latest sheet goes next, and changes made meanwhile wait for it;
 * - an answer is "saved" only once the server has answered that it stores the number that sheet was sent with —
 *   never because the request was sent;
 * - an answer that is older than the latest one acknowledged (a late or repeated response) changes nothing;
 * - a dropped connection or a server error is retried with a growing wait, and at once when the browser is back online;
 * - "time is up" or "already handed in" stops saving for good: the attempt is over and its result is what is left.
 */

export type SaveState =
  /** Nothing changed since the attempt was opened. */
  | 'idle'
  /** Changed here, waiting for the pause in typing before it is sent. */
  | 'pending'
  | 'saving'
  /** The server holds every change made here. */
  | 'saved'
  /** Not saved yet: the connection or the server failed, and it is being tried again. */
  | 'retrying'
  /** Refused for a reason trying again on its own will not fix. */
  | 'failed'
  /** The attempt is over: time is up, or it was handed in. */
  | 'closed';

export interface SaverSnapshot {
  state: SaveState;
  /** The sheet the server last confirmed it holds. */
  saved: QuizAnswers;
  /** The number of that sheet. */
  savedSeq: number;
  savedAt?: string;
  /** Why the last save failed, in the API's words. */
  error?: string;
  /** While retrying: how long until the next try. */
  retryInMs?: number;
}

export type ClosedReason = 'time-up' | 'finished';

interface Timers {
  set: (fn: () => void, ms: number) => unknown;
  clear: (id: unknown) => void;
}

export interface AnswerSaverOptions {
  /** The session as the server sent it: its stored sheet and number. */
  session: Pick<QuizSessionView, 'answers' | 'answersSeq' | 'savedAt'>;
  save: (answers: QuizAnswers, seq: number) => Promise<QuizSessionView>;
  onChange: (snapshot: SaverSnapshot) => void;
  /** Every answer from the server, for the countdown to set itself by. */
  onServer?: (view: QuizSessionView) => void;
  onClosed: (reason: ClosedReason) => void;
  debounceMs?: number;
  timers?: Timers;
}

const BROWSER_TIMERS: Timers = {
  set: (fn, ms) => globalThis.setTimeout(fn, ms),
  clear: (id) => globalThis.clearTimeout(id as ReturnType<typeof setTimeout>),
};

/** A failure worth trying again: no connection, or the server failing rather than refusing. */
export function isTransient(err: unknown): boolean {
  const e = err as { code?: string; status?: number } | null;
  if (!e) return false;
  if (e.code === 'network') return true;
  if (typeof e.status === 'number') return e.status >= 500 || e.status === 408 || e.status === 429;
  return e.code === 'unknown';
}

/** The API's code for a refusal that ends the attempt, if this is one. */
export function closedReason(err: unknown): ClosedReason | null {
  const reason = (err as { reason?: string } | null)?.reason;
  return reason === 'QUIZ_TIME_UP' ? 'time-up' : reason === 'QUIZ_FINISHED' ? 'finished' : null;
}

/** The wait before the `n`th try again: 1 s, 2 s, 4 s … up to 30 s. */
export const backoffMs = (n: number) => Math.min(30_000, 1000 * 2 ** Math.max(0, n - 1));

/** Whether a question has an answer: a choice picked, or text that is not blank. */
export const isAnswered = (value: QuizAnswers[string] | undefined) =>
  Array.isArray(value) ? value.length > 0 : typeof value === 'string' && value.trim() !== '';

/** Whether two answers say the same — a blank one and a missing one alike, the order of picked choices aside. */
export function sameAnswer(a: QuizAnswers[string] | undefined, b: QuizAnswers[string] | undefined): boolean {
  if (!isAnswered(a) && !isAnswered(b)) return true;
  if (Array.isArray(a) && Array.isArray(b)) return a.length === b.length && [...a].sort().join('\u0000') === [...b].sort().join('\u0000');
  return typeof a === 'string' && typeof b === 'string' && a === b;
}

/** The questions answered (or cleared) here whose answer the server does not hold yet. */
export const unsavedQuestions = (local: QuizAnswers, saved: QuizAnswers) =>
  [...new Set([...Object.keys(local), ...Object.keys(saved)])].filter((id) => !sameAnswer(local[id], saved[id]));

export class AnswerSaver {
  private sheet: QuizAnswers;
  /** Bumped on every change here. */
  private version = 0;
  /** The newest change the server has confirmed. */
  private savedVersion = 0;
  /** The highest number sent or seen: the next save goes out above it. */
  private lastSeq: number;
  private snap: SaverSnapshot;
  private inFlight = false;
  private timer: unknown = null;
  private failures = 0;
  private stopped = false;
  private readonly debounceMs: number;
  private readonly timers: Timers;

  constructor(private readonly opts: AnswerSaverOptions) {
    this.sheet = opts.session.answers;
    this.lastSeq = opts.session.answersSeq;
    this.debounceMs = opts.debounceMs ?? 800;
    this.timers = opts.timers ?? BROWSER_TIMERS;
    this.snap = { state: 'idle', saved: opts.session.answers, savedSeq: opts.session.answersSeq, savedAt: opts.session.savedAt };
  }

  get snapshot() {
    return this.snap;
  }

  /** Whether a change made here is not on the server yet. */
  get unsaved() {
    return this.version > this.savedVersion;
  }

  /** A change of answers here: saved once typing pauses. */
  change(sheet: QuizAnswers) {
    if (this.stopped) return;
    this.sheet = sheet;
    this.version += 1;
    // A save in flight is followed by the latest sheet when it answers; a retry already waiting keeps its wait.
    if (this.inFlight || this.snap.state === 'retrying') return;
    this.emit({ state: 'pending', error: undefined });
    this.schedule(this.debounceMs);
  }

  /** Sends what is waiting now, without the pause. */
  flush() {
    if (this.stopped) return;
    this.clearTimer();
    void this.send();
  }

  /** "Try again" — and the browser coming back online. */
  retry() {
    if (this.stopped || !this.unsaved) return;
    this.failures = 0;
    this.flush();
  }

  /** The number for a final sheet sent with the submission: above every save. Stops saving. */
  takeFinalSeq() {
    this.stop();
    this.lastSeq += 1;
    return this.lastSeq;
  }

  /** No more saves: the attempt is being handed in, or the page is going. */
  stop() {
    this.stopped = true;
    this.clearTimer();
  }

  private emit(patch: Partial<SaverSnapshot>) {
    this.snap = { ...this.snap, ...patch };
    if (patch.state !== 'retrying') delete this.snap.retryInMs;
    this.opts.onChange(this.snap);
  }

  private schedule(ms: number) {
    this.clearTimer();
    this.timer = this.timers.set(() => {
      this.timer = null;
      void this.send();
    }, ms);
  }

  private clearTimer() {
    if (this.timer !== null) this.timers.clear(this.timer);
    this.timer = null;
  }

  private async send() {
    if (this.stopped || this.inFlight || !this.unsaved) return;
    const version = this.version;
    const sheet = this.sheet;
    this.lastSeq += 1;
    const seq = this.lastSeq;
    this.inFlight = true;
    this.emit({ state: 'saving' });
    let view: QuizSessionView;
    try {
      view = await this.opts.save(sheet, seq);
    } catch (err) {
      this.inFlight = false;
      if (this.stopped) return;
      const closed = closedReason(err);
      if (closed) {
        this.stop();
        this.emit({ state: 'closed', error: (err as Error).message });
        this.opts.onClosed(closed);
        return;
      }
      if (isTransient(err)) {
        this.failures += 1;
        const wait = backoffMs(this.failures);
        this.emit({ state: 'retrying', error: (err as Error).message, retryInMs: wait });
        this.schedule(wait);
        return;
      }
      this.emit({ state: 'failed', error: (err as Error).message });
      return;
    }
    this.inFlight = false;
    if (this.stopped) return;
    this.failures = 0;
    this.opts.onServer?.(view);
    // Another device may have saved a higher number: the next save from here goes out above it.
    this.lastSeq = Math.max(this.lastSeq, view.answersSeq);
    // A response older than one already applied says nothing new.
    if (view.answersSeq >= this.snap.savedSeq) this.snap = { ...this.snap, saved: view.answers, savedSeq: view.answersSeq, savedAt: view.savedAt };
    // Kept only if the stored number is ours; a higher one is a sheet from elsewhere (another tab), a lower one an
    // answer that arrived out of order — either way ours goes again, numbered above what the server holds.
    const kept = view.answersSeq === seq;
    if (kept) this.savedVersion = Math.max(this.savedVersion, version);
    if (this.unsaved) {
      this.emit({ state: 'pending', error: undefined });
      this.schedule(kept ? this.debounceMs : 0);
    } else this.emit({ state: 'saved', error: undefined });
  }
}
