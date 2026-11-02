import { Prisma } from '@prisma/client';
import { LIMIT_KEYS, LIMIT_LABEL, USAGE_STRATEGY, type LimitKey, type SubscriptionState } from '@syniastrolms/domain';

import { now } from './clock.js';
import { db, type DbClient } from './db.js';
import { EntitlementError, entitlementEnforcement, getTenantEntitlements, getUsage, notServed } from './entitlements.js';
import { currentContext } from './tenancy.js';

/*
 * Usage enforcement (subscriptions.md §21, §23; SAAS-011).
 *
 * `withinLimit` wraps every write that adds to a plan limit — a sign-up, a course, an upload, a live
 * class, an instructor, an admin. With enforcement on, the write runs in one transaction that first
 * takes the academy's guard row for that limit (`UsageGuard`). Taking it is a write, so it holds the
 * database's lock — SQLite's single writer, a row lock on PostgreSQL — until the transaction ends. Only
 * then is usage counted, live, inside the same transaction, compared with the plan's limit, and the
 * write made. A second request for the same academy and limit waits at the guard and counts what the
 * first one wrote: two requests can never both pass a check against the same figure and push the
 * academy over a hard limit.
 *
 * The strategy per metric is `USAGE_STRATEGY` (packages/domain): all live, so nothing drifts and there
 * is nothing to reconcile. With enforcement off (`ENTITLEMENT_ENFORCEMENT`, the default) the write runs
 * exactly as it did before this module existed.
 */

export interface LimitCheck {
  tenantId: string;
  limit: LimitKey;
  /** How much the write adds: 1 for a row, the file size for an upload, 0 for a write that adds nothing. */
  amount: number;
  /** For `live_classes.max`: the moment whose calendar month is counted — the class's start. */
  at?: Date;
  /**
   * What happens while the academy's subscription serves no plan (restricted mode, §21): `refuse` (the
   * default) answers with the renew/subscribe prompt; `allow` lets the write through unchecked — for an
   * edit the restricted-mode policy keeps open, or the platform acting for the academy.
   */
  whenRestricted?: 'refuse' | 'allow';
}

const figure = (limit: LimitKey, n: number) => (limit === 'storage.bytes' ? `${Math.round(n / 1_048_576)} MB` : String(n));

/**
 * Runs `write` in one transaction if the academy's plan has room for
 * `amount` more of `limit`. Refuses with `LIMIT_REACHED` when it has not, and with the restricted-mode
 * prompt when its subscription serves no plan. With enforcement off, or an unlimited plan, the write
 * simply runs.
 */
export async function withinLimit<T>(check: LimitCheck, write: (tx: DbClient) => Promise<T>): Promise<T> {
  const enforced = entitlementEnforcement();
  const granted = enforced ? await getTenantEntitlements(check.tenantId) : null;
  if (granted && !granted.planVersionId && check.whenRestricted !== 'allow') throw notServed(granted);
  const ceiling = granted?.planVersionId ? granted.limits[check.limit] : null;

  const run = () =>
    db.$transaction(
      async (tx) => {
        if (ceiling !== null && check.amount > 0) {
          // The guard first: nothing is counted until this transaction holds the academy's lock for the limit.
          // An update, not an upsert: an upsert reads before it writes, so two first requests could both find no
          // row and both insert. `ensureGuard` has created the row before the transaction began.
          await tx.usageGuard.update({
            where: { tenantId_limitKey: { tenantId: check.tenantId, limitKey: check.limit } },
            data: { touchedAt: now() },
          });
          const usage = await getUsage(check.tenantId, check.limit, check.at ?? now(), tx);
          if (usage + check.amount > ceiling) {
            throw new EntitlementError(
              'LIMIT_REACHED',
              `${LIMIT_LABEL[check.limit]}: the ${granted!.plan!.name} plan allows ${figure(check.limit, ceiling)}, and this LMS uses ${figure(check.limit, usage)}.`,
            );
          }
        }
        return write(tx);
      },
      // Requests for the same academy and limit queue at the guard; give them time to.
      { maxWait: 15_000, timeout: 15_000 },
    );
  // The write runs in the caller's own context: an academy's request inside that academy, the platform
  // as itself (so a super admin's audit entry still finds its actor). An academy never guards another's.
  const context = currentContext();
  if (context?.kind === 'tenant' && context.tenantId !== check.tenantId) throw new Error('An LMS cannot write against another LMS’s limits.');
  if (ceiling !== null && check.amount > 0) await ensureGuard(check.tenantId, check.limit);
  return run();
}

/**
 * Creates the academy's guard row for `limit` if it has none yet. Two first requests may race here: the one
 * that loses gets the unique-key refusal, which means the row now exists — exactly what it needed.
 */
async function ensureGuard(tenantId: string, limit: LimitKey) {
  const where = { tenantId_limitKey: { tenantId, limitKey: limit } };
  if (await db.usageGuard.findUnique({ where, select: { tenantId: true } })) return;
  try {
    await db.usageGuard.create({ data: { tenantId, limitKey: limit } });
  } catch (err) {
    if (!(err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002')) throw err;
  }
}

export interface UsageLine {
  limit: LimitKey;
  label: string;
  used: number;
  /** The plan's limit: a number, null for unlimited, 0 when no plan is served. */
  allowed: number | null;
  /** Room left, or null for unlimited. */
  remaining: number | null;
  /** How the figure is measured (`USAGE_STRATEGY`). */
  counts: string;
}

/**
 * What an academy uses against each limit of its plan (§24), and whether it is in restricted mode —
 * the Tenant Admin's usage page. Live figures, counted as the limits count them.
 */
export async function usageSummary(
  tenantId: string,
): Promise<{ status: SubscriptionState | null; restricted: boolean; plan: { id: string; code: string; name: string } | null; lines: UsageLine[] }> {
  const granted = await getTenantEntitlements(tenantId);
  const lines = await Promise.all(
    LIMIT_KEYS.map(async (limit) => {
      const used = await getUsage(tenantId, limit, now());
      const allowed = granted.limits[limit];
      return {
        limit,
        label: LIMIT_LABEL[limit],
        used,
        allowed,
        remaining: allowed === null ? null : Math.max(0, allowed - used),
        counts: USAGE_STRATEGY[limit].counts,
      };
    }),
  );
  return { status: granted.status, restricted: !granted.planVersionId, plan: granted.plan, lines };
}
