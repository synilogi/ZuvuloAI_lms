import { Prisma } from '@prisma/client';
import type { NextFunction, Request, RequestHandler, Response } from 'express';

import { describeError, observe } from './observe.js';

/**
 * The stable, machine-readable reasons a request is refused, where a client needs to tell them apart
 * (subscriptions.md §34). A refusal for lack of permission and one for lack of entitlement are always
 * different codes, so a screen can show "ask your admin" for one and "upgrade your plan" for the other.
 */
export type ErrorCode =
  | 'UNAUTHENTICATED'
  | 'VALIDATION_FAILED'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'INTERNAL_ERROR'
  | 'PERMISSION_DENIED'
  | 'SUBSCRIPTION_REQUIRED'
  | 'SUBSCRIPTION_PAST_DUE'
  | 'SUBSCRIPTION_EXPIRED'
  | 'FEATURE_NOT_INCLUDED'
  | 'LIMIT_REACHED'
  | 'PAYMENT_REQUIRED'
  | 'PAYMENT_FAILED'
  | 'PLAN_UNAVAILABLE'
  | 'INVALID_SUBSCRIPTION_STATE'
  /** The server has no PAYMENT_CREDENTIALS_KEY, so gateway credentials cannot be stored or read (SAAS-017). */
  | 'SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED'
  /** The signed-in account's academy has been suspended or archived by the platform (SAAS-019). */
  | 'ACADEMY_SUSPENDED'
  | 'ACADEMY_ARCHIVED'
  | 'WORKSPACE_CLOSED'
  | 'COUPON_INVALID'
  /** An invitation link that is malformed, unknown, used, withdrawn or expired — one answer for all of them. */
  | 'INVITE_INVALID'
  /** An instructor who registered themselves and is waiting for, or was refused, the academy admin's approval. */
  | 'INSTRUCTOR_PENDING'
  | 'INSTRUCTOR_REJECTED'
  /** The academy adds learners by invitation only: its join and course links take no self-registration. */
  | 'INVITATION_REQUIRED'
  /** A self-registration's email code: wrong, expired, used up, or the registration is no longer open. */
  | 'VERIFICATION_FAILED'
  /** A paid course is joined by buying it: enrolling for free is refused. */
  | 'COURSE_PURCHASE_REQUIRED'
  /** The course's price has not been decided by the academy, or it is not open for enrolment: neither free nor for sale. */
  | 'COURSE_NOT_FOR_SALE'
  /** The academy has not set up online payments, so its paid courses cannot be bought yet. */
  | 'PAYMENTS_NOT_SET_UP'
  /** The learner already has the course: nothing to buy. */
  | 'ALREADY_ENROLLED'
  /** A timed quiz submitted all at once by an app built before quizzes started on the server: it must update. */
  | 'QUIZ_SESSION_REQUIRED'
  /** An answer sent after the attempt's deadline, by the server's clock. */
  | 'QUIZ_TIME_UP'
  /** An answer sent to an attempt already handed in. */
  | 'QUIZ_FINISHED'
  /** A quiz started before it opens, or after it closes. */
  | 'TEST_NOT_OPEN'
  | 'TEST_CLOSED'
  /** The learner's place in the course has ended, or staff paused it: nothing new is started or answered. */
  | 'ENROLLMENT_EXPIRED'
  | 'ENROLLMENT_PAUSED'
  /** A production server without the live-class video service (JaaS): the built-in room cannot run. */
  | 'LIVE_ROOM_NOT_CONFIGURED'
  /** An affiliate referral code that is malformed, unknown, or whose sponsor is gone (MLM-001). */
  | 'REFERRAL_INVALID'
  /** A learner who has not joined the affiliate program. */
  | 'NOT_AN_AFFILIATE'
  /** An affiliate who has not bought the eligible course, or is suspended. */
  | 'AFFILIATE_NOT_ACTIVE'
  /** A manual placement that would put an affiliate under itself or its own team (MLM-002). */
  | 'PLACEMENT_CYCLE'
  /** A position already filled. */
  | 'POSITION_TAKEN'
  /** A placement refused for another reason the message gives. */
  | 'PLACEMENT_INVALID';

/** Thrown by route handlers; `errorHandler` turns it into the matching HTTP response. */
export class ApiError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly issues?: unknown,
    /** Sent as `code` in the body when set. */
    public readonly code?: ErrorCode,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export const notFound = (message = 'Not found') => new ApiError(404, message);
/** `issues` is usually the array a domain `validate*` function returned. */
export const conflict = (message: string, issues?: unknown) => new ApiError(409, message, issues);
export const badRequest = (message: string, issues?: unknown) => new ApiError(400, message, issues);
export const unauthorized = (message = 'Sign in required') => new ApiError(401, message);
export const forbidden = (message = 'Not allowed') => new ApiError(403, message);
/** The account lacks the permission a route needs — distinct from the academy lacking an entitlement. */
export const permissionDenied = (message = 'Not allowed') => new ApiError(403, message, undefined, 'PERMISSION_DENIED');

/** Every code a billing endpoint can answer with (docs/05 › Error codes). */
export const BILLING_ERROR_CODES: readonly ErrorCode[] = [
  'UNAUTHENTICATED',
  'VALIDATION_FAILED',
  'NOT_FOUND',
  'CONFLICT',
  'INTERNAL_ERROR',
  'PERMISSION_DENIED',
  'SUBSCRIPTION_REQUIRED',
  'SUBSCRIPTION_PAST_DUE',
  'SUBSCRIPTION_EXPIRED',
  'FEATURE_NOT_INCLUDED',
  'LIMIT_REACHED',
  'PAYMENT_REQUIRED',
  'PAYMENT_FAILED',
  'PLAN_UNAVAILABLE',
  'INVALID_SUBSCRIPTION_STATE',
  'SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED',
  'ACADEMY_SUSPENDED',
  'ACADEMY_ARCHIVED',
  'WORKSPACE_CLOSED',
];

const CODE_FOR_STATUS: Record<number, ErrorCode> = {
  400: 'VALIDATION_FAILED',
  401: 'UNAUTHENTICATED',
  403: 'PERMISSION_DENIED',
  404: 'NOT_FOUND',
  409: 'CONFLICT',
  413: 'VALIDATION_FAILED',
};

/**
 * Error middleware for the billing routers (SAAS-013, subscriptions.md §34): every refusal leaves with a
 * stable code from `BILLING_ERROR_CODES`. A refusal that already has one keeps it; any other takes the
 * generic code for its status; a database outcome is answered in plain words with its code, and anything
 * else is an `INTERNAL_ERROR` whose details stay in the server log. No provider or database text ever
 * reaches the body. Place it at the end of the router; it hands on to `errorHandler`.
 */
export function stableCodes(err: unknown, req: Request, res: Response, next: NextFunction) {
  if (err instanceof ApiError) {
    if (err.code) return next(err);
    return next(new ApiError(err.status, err.message, err.issues, CODE_FOR_STATUS[err.status] ?? 'CONFLICT'));
  }
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2025') return next(new ApiError(404, 'Not found.', undefined, 'NOT_FOUND'));
    if (err.code === 'P2002') return next(new ApiError(409, 'That already exists.', undefined, 'CONFLICT'));
    return next(new ApiError(409, 'That could not be saved as it is.', undefined, 'CONFLICT'));
  }
  if (err instanceof Prisma.PrismaClientValidationError)
    return next(new ApiError(400, 'The request contained values the server could not use.', undefined, 'VALIDATION_FAILED'));
  if (isBodyParserError(err)) return next(err);
  // Anything else is a fault: reported (redacted) without its details reaching the client.
  reportFault(req, err);
  res.status(500).json({ message: 'Something went wrong.', code: 'INTERNAL_ERROR' });
}

/** The path without its query string — a query can carry a token (a reset link, a signed URL). */
const pathOf = (req: Request) => req.originalUrl.split('?')[0];

/** An unexpected fault, on the operator's log: method, path, the academy, and the error redacted (§48). */
function reportFault(req: Request, err: unknown) {
  observe('request.failed', { method: req.method, path: pathOf(req), tenantId: req.auth?.tenantId ?? undefined, error: describeError(err) });
}

/** The refusals §48 tracks: an academy stopped by its subscription, its plan's features, or a limit. */
const ENTITLEMENT_REFUSALS = new Set<string>(['SUBSCRIPTION_REQUIRED', 'SUBSCRIPTION_PAST_DUE', 'SUBSCRIPTION_EXPIRED', 'FEATURE_NOT_INCLUDED']);

function reportRefusal(req: Request, code: string) {
  if (code !== 'LIMIT_REACHED' && !ENTITLEMENT_REFUSALS.has(code)) return;
  observe(code === 'LIMIT_REACHED' ? 'limit.reached' : 'entitlement.denied', {
    code,
    method: req.method,
    path: pathOf(req),
    tenantId: req.auth?.tenantId ?? undefined,
    role: req.auth?.role,
  });
}

/** Wraps an async route handler so a rejected promise reaches the error middleware. */
export function asyncHandler(fn: (req: Request, res: Response, next: NextFunction) => Promise<unknown>): RequestHandler {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
}

/** Express' body parser attaches `type` to the errors it throws. */
function isBodyParserError(err: unknown): err is { type: string; status?: number } {
  return typeof err === 'object' && err !== null && 'type' in err && typeof (err as { type: unknown }).type === 'string';
}

/**
 * Central error → response mapping. Clients receive a message and, for validation failures, an
 * `issues` array; they never receive stack traces, SQL, file paths or library error text.
 */
export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  if (res.headersSent) return;

  if (err instanceof ApiError) {
    if (err.code) reportRefusal(req, err.code);
    res.status(err.status).json({ message: err.message, issues: err.issues, ...(err.code ? { code: err.code } : {}) });
    return;
  }

  if (isBodyParserError(err)) {
    if (err.type === 'entity.parse.failed') return void res.status(400).json({ message: 'The request body is not valid JSON.' });
    if (err.type === 'entity.too.large') return void res.status(413).json({ message: 'The request body is too large.' });
    if (err.type === 'encoding.unsupported') return void res.status(415).json({ message: 'Unsupported request encoding.' });
  }

  if (err instanceof Error && err.name === 'MulterError') {
    const code = (err as Error & { code?: string }).code;
    if (code === 'LIMIT_FILE_SIZE') return void res.status(413).json({ message: 'The file is too large.' });
    return void res.status(400).json({ message: 'The upload could not be read. Send one file in the `file` field.' });
  }

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    // Known database outcomes map to ordinary HTTP results instead of a 500.
    if (err.code === 'P2025') return void res.status(404).json({ message: 'Not found.' });
    if (err.code === 'P2002') return void res.status(409).json({ message: 'A record with the same unique value already exists.' });
    if (err.code === 'P2003') return void res.status(409).json({ message: 'A related record does not exist.' });
  }
  if (err instanceof Prisma.PrismaClientValidationError) {
    return void res.status(400).json({ message: 'The request contained values the server could not use.' });
  }

  // Everything else is a server fault: report it (method + path only, never the body) and hide the details.
  reportFault(req, err);
  res.status(500).json({ message: 'Something went wrong.' });
}
