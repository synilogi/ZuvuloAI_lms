import type { QuizSessionView } from '@syniastrolms/domain';

/*
 * A quiz attempt's countdown. The server fixes the deadline and keeps the only clock that counts; the screen draws the
 * time left from what the server said was left when it answered, measured against the browser's monotonic clock
 * (`performance.now()`) from the moment that answer arrived. The device's wall clock never enters into it, so a phone
 * set an hour wrong — or moved while the quiz is open — still shows the server's time.
 */

/** Milliseconds on a clock no change of the device's time moves. */
export const monotonicNow = () => (typeof performance !== 'undefined' && typeof performance.now === 'function' ? performance.now() : Date.now());

/**
 * When, on the monotonic clock, the attempt's time runs out — from a server answer that arrived at `arrivedAt`.
 * `deadlineAt − serverNow` (both the server's) is the precise figure; `remainingSec` is the whole-second fallback.
 * `null` for an untimed attempt.
 */
export function deadlineFrom(view: Pick<QuizSessionView, 'remainingSec' | 'deadlineAt' | 'serverNow'>, arrivedAt: number): number | null {
  if (view.remainingSec === undefined && !view.deadlineAt) return null;
  const precise = view.deadlineAt && view.serverNow ? Date.parse(view.deadlineAt) - Date.parse(view.serverNow) : Number.NaN;
  const ms = Number.isFinite(precise) ? precise : (view.remainingSec ?? 0) * 1000;
  return arrivedAt + Math.max(0, ms);
}

/** Whole seconds left before `endsAt`, rounded up — so `0` means the time is over, never that a fraction is left. */
export const secondsLeft = (endsAt: number, now: number) => Math.max(0, Math.ceil((endsAt - now) / 1000));

/** The moments the countdown is announced to screen readers, in seconds left. */
export const TIME_WARNINGS = [300, 60] as const;

/** The warning a tick from `before` to `after` seconds left passes, if any — each is said once, as the clock reaches it. */
export function warningPassed(before: number | null, after: number): (typeof TIME_WARNINGS)[number] | null {
  if (before === null) return null;
  for (const at of TIME_WARNINGS) if (before > at && after <= at && after > 0) return at;
  return null;
}

/** How the countdown looks: calm, then a warning in the last five minutes, then urgent in the last one. */
export const timerTone = (seconds: number): 'calm' | 'warn' | 'low' => (seconds <= 60 ? 'low' : seconds <= 300 ? 'warn' : 'calm');

/**
 * A new key for one press of "Start". The server answers a start retried with the same key with the session the first
 * one made, so a lost answer or a double press never uses a second attempt.
 */
export function newStartKey(): string {
  const c = globalThis.crypto;
  if (typeof c?.randomUUID === 'function') return c.randomUUID();
  const bytes = c.getRandomValues(new Uint8Array(16));
  return Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
}
