import type { NextFunction, Request, Response } from 'express';

import { db } from './db.js';
import { ApiError } from './errors.js';
import { SUSPENDED_MESSAGE } from './scope.js';
import { sessionStands } from './sessions.js';
import { runAsPlatform, runInTenant, type TenantContext } from './tenancy.js';
import { PENDING_MESSAGE, REJECTED_MESSAGE } from './instructorRequests.js';

/*
 * Which workspace a request runs for. The platform is one learning platform (docs/16, D-PLAT-01): every request —
 * a visitor's, a learner's, an instructor's, a staff admin's, the Super Admin's — runs inside the one workspace,
 * the `Tenant` row named by `DEFAULT_TENANT_SLUG`. The tenancy layer underneath is unchanged and still scopes every
 * query to that row, so nothing can read across to the rows of an academy from the SaaS era, which are kept but
 * closed (D-PLAT-02).
 *
 * The workspace is never read from the body, the query or a header. The token carries a `tenantId` claim only to be
 * checked against the account's own row: a token whose claim no longer matches, a token for an account that no
 * longer exists, and a token for a non-platform account with no workspace are all treated as no session at all — so
 * a protected route answers 401 rather than running for the wrong account.
 */

/** The slug of the platform's workspace. */
const workspaceSlug = () => process.env.DEFAULT_TENANT_SLUG ?? 'default';

let cached: { slug: string; id: string } | undefined;

/** The platform's one workspace. Cached: it changes only when the configuration does. */
export async function workspaceId(): Promise<string> {
  const slug = workspaceSlug();
  if (cached?.slug === slug) return cached.id;
  const row = await runAsPlatform('resolving the platform workspace', () => db.tenant.findUnique({ where: { slug }, select: { id: true } }));
  if (!row) throw new Error(`DEFAULT_TENANT_SLUG is "${slug}", and no workspace has that slug. Run the migrations and \`npm run seed:platform\`.`);
  cached = { slug, id: row.id };
  return row.id;
}

/** The former name of `workspaceId`, kept for the scripts and tests that still use it. */
export const defaultTenantId = workspaceId;

/** Tests only: forgets the cached workspace (after a test re-created the row). */
export const forgetWorkspace = () => {
  cached = undefined;
};

export const WORKSPACE_CLOSED_MESSAGE = 'This account has been closed.';

/** The refusal an account outside the platform's workspace gets, with its stable code. */
export const workspaceClosed = () => new ApiError(403, WORKSPACE_CLOSED_MESSAGE, undefined, 'WORKSPACE_CLOSED');

/**
 * Why a signed-in account may no longer act, or `undefined` while it is open. The same states sign-in refuses
 * (`routes/auth.ts`), read on every request so closing an account ends the session it already holds rather than
 * waiting for its token to expire.
 */
function closedReason(account: { role: string; deactivatedAt: Date | null; student: { suspended: boolean } | null; instructor: { status: string } | null }) {
  if (account.deactivatedAt) return 'This account has been deactivated.';
  if (account.role === 'instructor' && account.instructor?.status === 'inactive') return 'This instructor account has been deactivated.';
  // Not yet approved, or refused (D34): no session it holds may act.
  if (account.role === 'instructor' && account.instructor?.status === 'pending') return PENDING_MESSAGE;
  if (account.role === 'instructor' && account.instructor?.status === 'rejected') return REJECTED_MESSAGE;
  if (account.student?.suspended) return SUSPENDED_MESSAGE;
  return undefined;
}

async function contextFor(req: Request): Promise<TenantContext> {
  const workspace = await workspaceId();
  const auth = req.auth;
  if (auth) {
    const account = await runAsPlatform("reading the signed-in account's row", () =>
      db.user.findUnique({
        where: { id: auth.sub },
        select: {
          role: true,
          tenantId: true,
          deactivatedAt: true,
          student: { select: { suspended: true } },
          instructor: { select: { status: true } },
          tokensValidAfter: true,
          sessions: auth.sid ? { where: { id: auth.sid }, select: { revokedAt: true } } : false,
        },
      }),
    );
    const claimMatches = auth.tenantId === undefined || auth.tenantId === (account?.tenantId ?? undefined);
    if (!account || account.role !== auth.role || !claimMatches || (account.role !== 'superadmin' && !account.tenantId) || !sessionStands(auth, account)) {
      // No account, a different role, a stale claim, a non-platform account without a workspace, or a session that
      // was ended (SAAS-020): none of these is a session this request can safely act on.
      delete req.auth;
    } else {
      // An account of an academy from the SaaS era: its rows are kept, closed (D-PLAT-02). Told so on every route.
      if (account.tenantId && account.tenantId !== workspace) throw workspaceClosed();
      // A closed account keeps its identity (so the refusal can say why), but every guard refuses it.
      req.accountClosed = closedReason(account);
      if (account.tenantId) auth.tenantId = account.tenantId;
    }
  }
  // Everyone — the Super Admin included — works in the workspace. The Super Admin router alone widens that to the
  // platform tables (`platformContext`), after its own guard.
  return { kind: 'tenant', tenantId: workspace };
}

/** Runs the rest of the request in the workspace. Mounted once, straight after `attachAuth`. */
export function tenantContext(req: Request, _res: Response, next: NextFunction) {
  contextFor(req).then((context) => (context.kind === 'tenant' ? runInTenant(context.tenantId, next) : next()), next);
}

/** Runs the rest of the request across the platform's tables. Only for a router already guarded by `requireSuperAdmin`. */
export const platformContext =
  (reason: string) =>
  (_req: Request, _res: Response, next: NextFunction): void => {
    void runAsPlatform(reason, next);
  };
