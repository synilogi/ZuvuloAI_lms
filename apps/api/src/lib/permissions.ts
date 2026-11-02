/* Academy admin permissions.
 *
 * Grants govern the `admin` role and nothing else: instructors keep the role-and-scope authorization
 * they have always had, and a super admin's reach comes from `requireSuperAdmin`, never from a grant
 * — there is no bypass in this file.
 *
 * Grants are read from the database on the request that needs them, never from the token. The token
 * is signed once and lives for days (`lib/auth.ts`); a permission taken away must take effect on the
 * next request, not on the next sign-in. */
import type { NextFunction, Request, Response } from 'express';
import { isPermissionKey, PERMISSION_KEYS, type PermissionKey, type Role } from '@syniastrolms/domain';

import { db, type DbClient } from './db.js';
import { badRequest, permissionDenied, unauthorized } from './errors.js';
import { runAsPlatform } from './tenancy.js';

/**
 * One lookup per request, not one per check: a handler that asks twice does not pay twice. Keyed on
 * the request object itself, so the entry dies with the request — nothing is shared between requests
 * and nothing survives a grant being changed.
 */
const perRequest = new WeakMap<Request, Map<string, Promise<AdminState>>>();

/** The keys a user holds, in catalogue order. Keys no longer in the catalogue are ignored, not returned. */
export async function permissionsFor(userId: string, client: DbClient = db): Promise<PermissionKey[]> {
  const rows = await client.adminPermission.findMany({ where: { userId }, select: { key: true } });
  const held = new Set(rows.map((r) => r.key));
  return PERMISSION_KEYS.filter((key) => held.has(key));
}

export async function hasPermission(userId: string, key: PermissionKey): Promise<boolean> {
  const rows = await db.adminPermission.findMany({ where: { userId }, select: { key: true } });
  return rows.some((r) => r.key === key);
}

interface AdminState {
  /** Set when a super admin closed the account. */
  deactivated: boolean;
  keys: Set<string>;
}

/**
 * The admin's grants and whether the account is still open, in one read. Both are taken from the
 * database on the request that needs them, so closing an account or taking a key away is refused on
 * the very next request rather than when the token happens to expire.
 */
async function adminState(req: Request, userId: string): Promise<AdminState> {
  let byUser = perRequest.get(req);
  if (!byUser) {
    byUser = new Map();
    perRequest.set(req, byUser);
  }
  let pending = byUser.get(userId);
  if (!pending) {
    pending = db.user
      .findUnique({ where: { id: userId }, select: { deactivatedAt: true, permissions: { select: { key: true } } } })
      .then((user) => ({ deactivated: Boolean(user?.deactivatedAt), keys: new Set(user?.permissions.map((p) => p.key) ?? []) }));
    byUser.set(userId, pending);
  }
  return pending;
}

export interface PermissionOptions {
  /**
   * Roles that pass on their role alone, without a grant. On a route shared with the teaching
   * workspace this is `['instructor']`: instructors are not part of the permission system, so the
   * grant gates the admin and leaves them as they were. Omit it and only a granted admin passes.
   */
  roles?: Role[];
}

/**
 * Requires an academy admin to hold `key`.
 *
 * Composes after the existing guards — `requireAuth, requireRole(…), requirePermission(…)` — and
 * replaces neither. A caller with no grant is refused with 403 `PERMISSION_DENIED`; a super admin is
 * refused like anyone else, because this helper is the academy's, not the platform's.
 *
 * **Nothing calls this yet.** Phase 9 builds the foundation; enforcement is Phase 10's to add.
 */
export function requirePermission(key: PermissionKey, options: PermissionOptions = {}) {
  return (req: Request, _res: Response, next: NextFunction) => {
    const auth = req.auth;
    if (!auth) return next(unauthorized());
    if (req.accountClosed) return next(permissionDenied(req.accountClosed));
    // Roles the route governs by role keep passing untouched.
    if (options.roles?.includes(auth.role)) return next();
    // The Super Admin owns the platform and holds every capability without a grant (docs/16, D-PLAT-03).
    if (auth.role === 'superadmin') return next();
    // Everyone else must be a staff admin holding the key.
    if (auth.role !== 'admin') return next(permissionDenied());
    adminState(req, auth.sub).then(
      // A deactivated account is refused here too, so closing one ends its reach across every
      // permission-gated endpoint at once instead of waiting for the token to expire.
      (state) => (state.deactivated ? next(permissionDenied('This account has been deactivated.')) : state.keys.has(key) ? next() : next(permissionDenied())),
      (error: unknown) => next(error),
    );
  };
}

/**
 * A capability the academy shares between the teaching workspace and the admin workspace.
 *
 * The instructor passes on their role, exactly as they always have — they are not part of the
 * permission system and their scope rules are untouched. The academy admin must hold `key`. A
 * learner and the platform super admin are refused here as they already are by `requireRole`.
 */
export const requireStaffPermission = (key: PermissionKey) => requirePermission(key, { roles: ['instructor'] });

/**
 * Gives `userId` every key in the catalogue it does not already hold, and answers with the keys it
 * actually added. Idempotent: a second call finds nothing missing and writes nothing.
 *
 * This is what keeps the introduction of permissions invisible — an admin that holds everything can
 * do everything it could before.
 */
/**
 * The academy a grant belongs to: the admin's own. Read from the account rather than the context so a
 * super admin (who acts as the platform) and an academy request write the same row. Only an academy
 * admin can hold a grant, so a platform account is refused.
 */
async function grantTenant(userId: string, client: DbClient): Promise<string> {
  const user = await client.user.findUnique({ where: { id: userId }, select: { tenantId: true } });
  if (!user?.tenantId) throw badRequest('Permissions are granted to admins only.');
  return user.tenantId;
}

export async function grantAllPermissions(
  userId: string,
  { grantedBy, client = db }: { grantedBy?: string; client?: DbClient } = {},
): Promise<PermissionKey[]> {
  const existing = await client.adminPermission.findMany({ where: { userId }, select: { key: true } });
  const held = new Set(existing.map((r) => r.key));
  const missing = PERMISSION_KEYS.filter((key) => !held.has(key));
  if (!missing.length) return missing;
  const tenantId = await grantTenant(userId, client);
  await client.adminPermission.createMany({ data: missing.map((key) => ({ tenantId, userId, key, grantedBy })) });
  return missing;
}

/**
 * Gives `userId` one key. Answers `true` when the grant is new and `false` when it was already
 * held — the caller writes an audit event for the first and nothing for the second.
 */
export async function grantPermission(
  userId: string,
  key: PermissionKey,
  { grantedBy, client = db }: { grantedBy?: string; client?: DbClient } = {},
): Promise<boolean> {
  const existing = await client.adminPermission.findUnique({ where: { userId_key: { userId, key } }, select: { id: true } });
  if (existing) return false;
  await client.adminPermission.create({ data: { tenantId: await grantTenant(userId, client), userId, key, grantedBy } });
  return true;
}

/** Takes one key away. Answers `true` when something was actually removed. */
export async function revokePermission(userId: string, key: PermissionKey, { client = db }: { client?: DbClient } = {}): Promise<boolean> {
  const { count } = await client.adminPermission.deleteMany({ where: { userId, key } });
  return count > 0;
}

/** Keys held by a user that the catalogue no longer knows — reported, never silently deleted. */
export async function unknownPermissionsFor(userId: string): Promise<string[]> {
  const rows = await db.adminPermission.findMany({ where: { userId }, select: { key: true } });
  return rows.map((r) => r.key).filter((key) => !isPermissionKey(key));
}

export interface BackfillResult {
  admins: number;
  granted: number;
  /** Admins that already held everything — the whole result on a second run. */
  unchanged: number;
}

/**
 * Brings every existing academy admin up to the full catalogue, so introducing permissions changes
 * nobody's capabilities. Safe to run as often as you like; only `role: 'admin'` accounts are touched,
 * so no learner, instructor or super admin ever receives a grant.
 */
export async function backfillAdminPermissions(grantedBy?: string): Promise<BackfillResult> {
  // Every academy's admins: an operator task that runs across the platform. Each grant still lands in
  // its admin's own academy (`grantTenant`).
  return runAsPlatform("backfilling every academy's admin permissions", () => backfill(grantedBy));
}

async function backfill(grantedBy?: string): Promise<BackfillResult> {
  const admins = await db.user.findMany({ where: { role: 'admin' }, select: { id: true } });
  let granted = 0;
  let unchanged = 0;
  for (const admin of admins) {
    const added = await grantAllPermissions(admin.id, { grantedBy });
    granted += added.length;
    if (!added.length) unchanged += 1;
  }
  return { admins: admins.length, granted, unchanged };
}
