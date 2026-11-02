import { createHmac } from 'node:crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import type { NextFunction, Request, Response } from 'express';
import type { Role } from '@syniastrolms/domain';

import { forbidden, unauthorized } from './errors.js';

const DEFAULT_DEV_SECRET = 'dev-secret-change-me';
const JWT_SECRET = process.env.JWT_SECRET ?? DEFAULT_DEV_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? '7d';

/**
 * Called once at boot. A production process must not run with the development secret (or a
 * trivially short one) — every token could be forged.
 */
export function assertProductionSecrets(env: NodeJS.ProcessEnv = process.env): void {
  if (env.NODE_ENV !== 'production') return;
  const secret = env.JWT_SECRET ?? '';
  if (!secret || secret === DEFAULT_DEV_SECRET || secret.length < 32) {
    throw new Error('JWT_SECRET must be set to a random string of at least 32 characters in production.');
  }
}

export interface AuthTokenPayload {
  sub: string; // user id
  role: Role;
  studentId?: string;
  instructorId?: string;
  /** The academy the account belongs to (D3). A claim only: `lib/requestContext.ts` checks it against the account's row on every request. */
  tenantId?: string;
  /** The session the token was issued with (SAAS-020); absent on tokens signed before sessions existed. */
  sid?: string;
  /** Issued at, in seconds — set by the signer. */
  iat?: number;
}

export const hashPassword = (password: string) => bcrypt.hash(password, 10);
export const verifyPassword = (password: string, hash: string) => bcrypt.compare(password, hash);

export function signToken(payload: AuthTokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN } as jwt.SignOptions);
}

export function verifyToken(token: string): AuthTokenPayload {
  return jwt.verify(token, JWT_SECRET) as AuthTokenPayload;
}

/**
 * A narrow, short-lived grant for one purpose (a recording link a `<video>` element can open without a header).
 * Signed under a key derived for that purpose, so it never passes `verifyToken` as a sign-in, nor one purpose's
 * grant as another's.
 */
const purposeKey = (purpose: string) => createHmac('sha256', JWT_SECRET).update(`grant:${purpose}`).digest();
export const signGrant = (purpose: string, payload: Record<string, string>, expiresIn: string) =>
  jwt.sign(payload, purposeKey(purpose), { expiresIn } as jwt.SignOptions);
export function verifyGrant<T extends Record<string, string>>(purpose: string, token: string): T | null {
  try {
    return jwt.verify(token, purposeKey(purpose)) as unknown as T;
  } catch {
    return null;
  }
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      auth?: AuthTokenPayload;
      /** Set by `lib/requestContext.ts` when the signed-in account has since been deactivated or suspended: why every guard refuses it. */
      accountClosed?: string;
    }
  }
}

/** Populates `req.auth` when a valid bearer token is present; never rejects by itself. */
export function attachAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (header?.startsWith('Bearer ')) {
    try {
      req.auth = verifyToken(header.slice(7));
    } catch {
      // Falls through to requireAuth (or stays anonymous) — an expired/invalid token is not a crash.
    }
  }
  next();
}

export function requireAuth(req: Request, _res: Response, next: NextFunction) {
  if (!req.auth) return next(unauthorized());
  if (req.accountClosed) return next(forbidden(req.accountClosed));
  next();
}

/** Admins may act as any role's endpoint that also serves instructors, matching the demo's workspace model. */
export function requireRole(...roles: Role[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.auth) return next(unauthorized());
    if (req.accountClosed) return next(forbidden(req.accountClosed));
    // A staff admin passes every role guard, as before; so does the Super Admin, who runs the whole platform and
    // manages courses, people and settings with the same routes staff use (docs/16, D-PLAT-03).
    if (!roles.includes(req.auth.role) && req.auth.role !== 'admin' && req.auth.role !== 'superadmin') return next(forbidden());
    next();
  };
}

/**
 * Platform-level access, kept apart from the academy. There is no bypass here: the academy admin is
 * refused like anyone else, because a super admin is a separate role and not a more powerful admin.
 */
export function requireSuperAdmin(req: Request, _res: Response, next: NextFunction) {
  if (!req.auth) return next(unauthorized());
  if (req.accountClosed) return next(forbidden(req.accountClosed));
  if (req.auth.role !== 'superadmin') return next(forbidden());
  next();
}
