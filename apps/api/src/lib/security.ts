import helmet from 'helmet';
import { rateLimit, type RateLimitRequestHandler } from 'express-rate-limit';

export interface RateLimitOptions {
  /** Requests per window per client for the whole API. */
  global: number;
  /** Requests per window per client for `/auth/*` (credential guessing). */
  auth: number;
  /** Registrations an hour per email address, from any client: each one emails that address a code. */
  email: number;
  /** Failed sign-ins per window per account, from any client: a password guessed from many addresses still stops. */
  account: number;
  windowMs: number;
}

const int = (value: string | undefined, fallback: number) => {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? n : fallback;
};

/** Defaults come from the environment so a deployment can tune them without a code change. */
export function rateLimitOptionsFromEnv(): RateLimitOptions {
  return {
    global: int(process.env.RATE_LIMIT_MAX, 1000),
    auth: int(process.env.RATE_LIMIT_AUTH_MAX, 30),
    email: int(process.env.RATE_LIMIT_EMAIL_MAX, 10),
    account: int(process.env.RATE_LIMIT_ACCOUNT_MAX, 10),
    windowMs: int(process.env.RATE_LIMIT_WINDOW_MS, 15 * 60 * 1000),
  };
}

export function makeLimiter(limit: number, windowMs: number, message: string, options: { skipGet?: boolean } = {}): RateLimitRequestHandler {
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    message: { message },
    // The auth budget is for credential attempts; reading the session (GET /auth/me on every page load) is free.
    skip: options.skipGet ? (req) => req.method === 'GET' : undefined,
  });
}

/**
 * Limits registrations by the email address they name, whatever client sends them — the per-client budget cannot stop
 * many clients mailing codes to one address. Requests that name no address (and reads) pass through to the per-client
 * limit. In memory, like the other limits: one API process (docs/10-DEPLOYMENT.md).
 */
export function emailLimiter(limit: number, message: string): RateLimitRequestHandler {
  return rateLimit({
    windowMs: 60 * 60_000,
    limit,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    message: { message },
    skip: (req) => req.method !== 'POST' || typeof req.body?.email !== 'string' || !req.body.email.trim(),
    keyGenerator: (req) => `email:${String(req.body.email).trim().toLowerCase()}`,
  });
}

/**
 * Limits failed password checks by the account they name, whatever client sends them: the per-client budget alone lets
 * a password be guessed from many addresses. Only failures count (a correct password never uses the budget), so the
 * owner signing in is not slowed, and once it is spent even the right password waits — the same answer either way.
 */
export function accountSignInLimiter(limit: number, windowMs: number): RateLimitRequestHandler {
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    skipSuccessfulRequests: true,
    message: { message: 'Too many failed sign-ins for this account. Wait 15 minutes, or reset your password.' },
    skip: (req) => req.method !== 'POST' || typeof req.body?.email !== 'string' || !req.body.email.trim(),
    keyGenerator: (req) => `account:${String(req.body.email).trim().toLowerCase()}`,
  });
}

/**
 * Security headers. The API only returns JSON (and, later, uploaded media the web origin embeds), so
 * the cross-origin resource policy is relaxed to `cross-origin`; everything else keeps helmet's defaults.
 */
export const securityHeaders = helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  contentSecurityPolicy: false,
});
