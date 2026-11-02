import type { CoursePurchase } from '@syniastrolms/domain';
import { ServiceError, type CoursePurchaseConfirmation } from '@/services/contracts';

/*
 * Buying a paid course, as decisions apart from the screen. The browser never prices anything and never believes a
 * checkout on its own: the course opens only when the API answers `enrolled`. A redirect back from a hosted checkout
 * only tells this page which purchase to ask the API about.
 */

/** How often a purchase that is still being confirmed is asked about again, and for how long before the page stops. */
export const POLL_EVERY_MS = 3_000;
export const POLL_FOR_MS = 90_000;

export type PurchasePhase =
  | { kind: 'idle' }
  /** The order summary is open; nothing has been asked of the server yet. */
  | { kind: 'summary' }
  /** Opening the order and the checkout: the button is busy and nothing can be sent twice. */
  | { kind: 'starting' }
  /** The gateway's checkout window is open. */
  | { kind: 'checkout' }
  /** Paid in the checkout; the server is confirming it with the gateway. */
  | { kind: 'verifying'; purchaseId: string }
  /** Still unconfirmed after `POLL_FOR_MS`: the course opens once the payment is confirmed. */
  | { kind: 'slow'; purchaseId: string }
  /** The API says the learner has the course. */
  | { kind: 'success'; message: string }
  | { kind: 'failed'; message: string }
  | { kind: 'cancelled' }
  /** The course can't be bought here at all; retrying would not help. */
  | { kind: 'blocked'; title: string; message: string };

export const SLOW_MESSAGE = 'We’ll open the course as soon as the payment is confirmed. You can close this page — nothing more is needed from you.';
export const CANCELLED_MESSAGE = 'Payment cancelled. You weren’t charged.';
const FAILED_FALLBACK = 'The payment didn’t go through. Nothing was charged. You can try again.';

/** Whether the page is busy with a purchase and the buy button must not be pressed again. */
export const isBusy = (phase: PurchasePhase) => phase.kind === 'starting' || phase.kind === 'checkout' || phase.kind === 'verifying';

/**
 * What a refused start or confirmation means. `owned`: the learner already has the course — the page reloads it.
 */
export function refusalPhase(err: unknown): PurchasePhase | { kind: 'owned' } {
  if (!(err instanceof ServiceError)) return { kind: 'failed', message: err instanceof Error ? err.message : FAILED_FALLBACK };
  switch (err.reason) {
    case 'ALREADY_ENROLLED':
      return { kind: 'owned' };
    case 'PAYMENTS_NOT_SET_UP':
      return { kind: 'blocked', title: 'Online payment isn’t available yet.', message: err.message };
    case 'COURSE_NOT_FOR_SALE':
      return { kind: 'blocked', title: 'This course isn’t open for enrolment yet.', message: err.message };
    case 'PAYMENT_FAILED':
      return { kind: 'failed', message: err.message };
  }
  if (err.code === 'not-found') return { kind: 'blocked', title: 'This course isn’t available.', message: err.message };
  // A free course, or an LMS that enrols by approval or invitation: the server's own words.
  if (err.code === 'conflict' || err.code === 'forbidden') return { kind: 'blocked', title: 'You can’t buy this course here.', message: err.message };
  return { kind: 'failed', message: err.message || FAILED_FALLBACK };
}

/** What the server's answer to a finished checkout means. Only `enrolled` is a success. */
export function confirmationPhase(result: CoursePurchaseConfirmation): PurchasePhase {
  if (result.outcome.enrolled) return { kind: 'success', message: result.outcome.message };
  if (result.outcome.status === 'failed') return { kind: 'failed', message: result.outcome.message || FAILED_FALLBACK };
  return { kind: 'verifying', purchaseId: result.purchase.id };
}

/**
 * What a purchase read back from the API means: open (the learner has the course), failed, or — `null` — still being
 * confirmed. `failed` is the latest attempt's outcome, not the end: buying again reuses the same order. `declined`: the
 * page has just come back from a checkout that said it was declined.
 */
export function statusPhase(purchase: CoursePurchase, declined = false): PurchasePhase | null {
  if (purchase.enrolled) return { kind: 'success', message: 'Payment confirmed. The course is open.' };
  if (purchase.status === 'failed' || purchase.status === 'expired' || declined) return { kind: 'failed', message: purchase.failureMessage ?? FAILED_FALLBACK };
  return null;
}

/* ─── Coming back from a hosted checkout (the sandbox gateway's test page) ─── */

export type CheckoutOutcome = 'paid' | 'failed' | 'cancelled';

export interface CheckoutReturn {
  purchaseId: string;
  courseId: string;
  /** The page to come back to, when it is not the course's own (a bundle's). */
  path?: string;
}

const KEY = (orderId: string) => `syniastrolms:course-checkout:${orderId}`;

/** Remembers, for this tab, which purchase a hosted checkout's order belongs to. */
export function rememberCheckout(orderId: string, ret: CheckoutReturn, storage: Pick<Storage, 'setItem'> | undefined = safeSession()) {
  try {
    storage?.setItem(KEY(orderId), JSON.stringify(ret));
  } catch {
    /* storage refused: the checkout page falls back to the purchases list */
  }
}

/** The purchase an order was opened for, if this tab opened it. Removed once read. */
export function recallCheckout(orderId: string, storage: Pick<Storage, 'getItem' | 'removeItem'> | undefined = safeSession()): CheckoutReturn | null {
  try {
    const raw = storage?.getItem(KEY(orderId));
    if (!raw) return null;
    storage?.removeItem(KEY(orderId));
    const parsed = JSON.parse(raw) as Partial<CheckoutReturn>;
    return typeof parsed.purchaseId === 'string' && typeof parsed.courseId === 'string'
      ? { purchaseId: parsed.purchaseId, courseId: parsed.courseId, ...(typeof parsed.path === 'string' && parsed.path.startsWith('/') ? { path: parsed.path } : {}) }
      : null;
  } catch {
    return null;
  }
}

function safeSession(): Storage | undefined {
  try {
    return typeof window === 'undefined' ? undefined : window.sessionStorage;
  } catch {
    return undefined;
  }
}

/** Where a course purchase's hosted checkout sends the learner back to: the course page, which then asks the API. */
export const courseReturnPath = (ret: CheckoutReturn, outcome: CheckoutOutcome) =>
  `${ret.path ?? `/learn/${encodeURIComponent(ret.courseId)}`}?purchase=${encodeURIComponent(ret.purchaseId)}&checkout=${outcome}`;

/** The purchase a course page was sent back about, from its query string. */
export function readCheckoutReturn(search: string): { purchaseId: string; outcome: CheckoutOutcome } | null {
  const params = new URLSearchParams(search);
  const purchaseId = params.get('purchase');
  const outcome = params.get('checkout');
  if (!purchaseId || (outcome !== 'paid' && outcome !== 'failed' && outcome !== 'cancelled')) return null;
  return { purchaseId, outcome };
}
