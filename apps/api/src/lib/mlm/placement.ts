import {
  pathUnder,
  rebasedPath,
  wouldCycle,
  type AffiliateStatus,
  type ManualPlacementInput,
  type MlmLeg,
  type MlmSpilloverRule,
  type PlacementReason,
} from '@syniastrolms/domain';
import { Prisma } from '@prisma/client';

import { recordAuditLog, type AuditActor } from '../audit.js';
import { db, type DbClient } from '../db.js';
import { ApiError, conflict, notFound } from '../errors.js';
import { readJson } from '../json.js';
import { observe } from '../observe.js';
import { currentTenantId, runInTenant, tenant } from '../tenancy.js';
import { activeMlmPlan } from './plan.js';

/*
 * Binary placement (MLM-002; docs/15 §6.3) — the writer of an affiliate's `placementParentId`, `placementLeg`,
 * `pathIdsJson`, `depth` and of `MlmPlacementHistory`.
 *
 * A referral is placed as soon as it exists: on the leg the sponsor's link named, else the sponsor's preferred leg, when
 * that position is free, else deeper in that leg by the active plan's spillover rule. The member's own `preferredLeg` says
 * where their referrals go and plays no part in their own position. A learner who opted in with no sponsor is a root (a forest is
 * allowed). Two referrals of one sponsor arriving together cannot take the same position: the database's unique
 * (parent, leg) index is the final guard, and a loser searches again. Placement never fails a registration: the
 * scheduler's `mlm-placement` job places anyone left unplaced.
 *
 * A manual move (Super Admin, with a reason) is refused when it would make a cycle, take a position that is used, or
 * move a node that has a downline — unless the mover says so (`moveSubtree`), in which case every descendant's path
 * is rebuilt. Every placement writes one immutable history row; a manual one is audited too.
 */

export const PLACEMENT_AUDIT_ACTIONS = {
  manual: 'mlm.placement.manual',
  sponsorChanged: 'mlm.sponsor.changed',
  statusChanged: 'mlm.affiliate.status_changed',
} as const;

const positionTaken = () => new ApiError(409, 'That position is already filled.', undefined, 'POSITION_TAKEN');
const placementCycle = () => new ApiError(409, 'An affiliate cannot be placed under itself or under someone in its own team.', undefined, 'PLACEMENT_CYCLE');
const placementInvalid = (message: string) => new ApiError(409, message, undefined, 'PLACEMENT_INVALID');

type Node = {
  id: string;
  tenantId: string;
  placementParentId: string | null;
  placementLeg: string | null;
  pathIdsJson: string;
  depth: number;
  sponsorId: string | null;
  preferredLeg: string;
  status: string;
};

const pathOf = (node: Pick<Node, 'pathIdsJson'>): string[] => readJson<string[]>(node.pathIdsJson, []);

async function childOf(client: DbClient, parentId: string, leg: MlmLeg): Promise<string | null> {
  const row = await client.affiliate.findUnique({
    where: { placementParentId_placementLeg: { placementParentId: parentId, placementLeg: leg } },
    select: { id: true },
  });
  return row?.id ?? null;
}

/** The position a referral takes under `startId` on `leg`, walking the stored tree by the rule (the domain's `findFreePosition`, asynchronously). */
async function findPosition(client: DbClient, rule: MlmSpilloverRule, startId: string, leg: MlmLeg): Promise<{ parentId: string; leg: MlmLeg }> {
  if (rule === 'extreme-outer') {
    let node = startId;
    for (;;) {
      const child = await childOf(client, node, leg);
      if (!child) return { parentId: node, leg };
      node = child;
    }
  }
  const top = await childOf(client, startId, leg);
  if (!top) return { parentId: startId, leg };
  const queue = [top];
  for (;;) {
    const node = queue.shift();
    if (!node) throw new Error('The breadth-first search ran out of nodes.');
    for (const l of ['A', 'B'] as const) {
      const child = await childOf(client, node, l);
      if (!child) return { parentId: node, leg: l };
      queue.push(child);
    }
  }
}

async function spilloverRule(): Promise<MlmSpilloverRule> {
  const plan = await activeMlmPlan();
  return plan?.spilloverRule ?? 'extreme-outer';
}

async function history(
  client: DbClient,
  row: {
    affiliateId: string;
    from: { parentId: string; leg: MlmLeg } | null;
    to: { parentId: string; leg: MlmLeg } | null;
    reason: PlacementReason;
    actor?: { id: string } | null;
    note?: string | null;
  },
) {
  await client.mlmPlacementHistory.create({
    data: {
      ...tenant(),
      affiliateId: row.affiliateId,
      fromParentId: row.from?.parentId ?? null,
      fromLeg: row.from?.leg ?? null,
      toParentId: row.to?.parentId ?? null,
      toLeg: row.to?.leg ?? null,
      reason: row.reason,
      actorType: row.actor ? 'user' : 'system',
      actorId: row.actor?.id ?? null,
      note: row.note ?? null,
    },
  });
}

const isUniqueViolation = (err: unknown) => err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002';

/**
 * Places one affiliate who has a sponsor and no position yet. Idempotent: an affiliate already placed is left alone.
 * Runs in the affiliate's academy context.
 */
export async function placeAffiliate(affiliateId: string): Promise<{ parentId: string; leg: MlmLeg } | null> {
  const node = await db.affiliate.findUnique({ where: { id: affiliateId } });
  if (!node || node.placementParentId) return null;
  if (!node.sponsorId) {
    // A root: no parent, an empty path. Recorded once so the history says when the tree started here.
    const already = await db.mlmPlacementHistory.findFirst({ where: { affiliateId, reason: 'root' }, select: { id: true } });
    if (!already) await history(db, { affiliateId, from: null, to: null, reason: 'root' });
    return null;
  }
  const rule = await spilloverRule();
  for (let attempt = 0; attempt < 4; attempt++) {
    const sponsor = await db.affiliate.findUniqueOrThrow({ where: { id: node.sponsorId }, select: { id: true, preferredLeg: true, pathIdsJson: true } });
    const leg = (node.requestedLeg ?? sponsor.preferredLeg) as MlmLeg;
    const position = await findPosition(db, rule, sponsor.id, leg);
    const parent = await db.affiliate.findUniqueOrThrow({ where: { id: position.parentId }, select: { id: true, pathIdsJson: true, depth: true } });
    const path = pathUnder(pathOf(parent), parent.id);
    try {
      await db.$transaction(async (tx) => {
        await tx.affiliate.update({
          where: { id: affiliateId },
          data: { placementParentId: position.parentId, placementLeg: position.leg, pathIdsJson: JSON.stringify(path), depth: path.length },
        });
        await history(tx, { affiliateId, from: null, to: position, reason: position.parentId === sponsor.id ? 'sponsor-direct' : 'spillover' });
      });
      return position;
    } catch (err) {
      // Another referral took the position between the search and the write: search again from where the tree now stands.
      if (!isUniqueViolation(err)) throw err;
    }
  }
  observe('job.failed', { job: 'mlm-placement', affiliateId, reason: 'no free position after retries' });
  return null;
}

/** Every affiliate of the current academy with a sponsor and no position, oldest first; the scheduler's catch-up. */
export async function placePendingAffiliates(): Promise<number> {
  const waiting = await db.affiliate.findMany({
    where: { placementParentId: null, sponsorId: { not: null } },
    select: { id: true },
    orderBy: { createdAt: 'asc' },
  });
  let placed = 0;
  for (const { id } of waiting) if (await placeAffiliate(id)) placed++;
  return placed;
}

/** Placement in the affiliate's own academy, wherever the caller runs. */
export const placeInOwnAcademy = (affiliate: { id: string; tenantId: string }) => runInTenant(affiliate.tenantId, () => placeAffiliate(affiliate.id));

async function loadNode(client: DbClient, id: string): Promise<Node> {
  const row = await client.affiliate.findUnique({
    where: { id },
    select: {
      id: true,
      tenantId: true,
      placementParentId: true,
      placementLeg: true,
      pathIdsJson: true,
      depth: true,
      sponsorId: true,
      preferredLeg: true,
      status: true,
    },
  });
  if (!row) throw notFound('Affiliate not found.');
  return row;
}

/** A Super Admin's manual placement or move. Runs in the affiliate's academy context. */
export async function manualPlacement(actor: AuditActor, affiliateId: string, input: ManualPlacementInput): Promise<void> {
  const node = await loadNode(db, affiliateId);
  if (node.tenantId !== currentTenantId()) throw notFound('Affiliate not found.');
  const parent = await loadNode(db, input.parentId);
  if (parent.tenantId !== node.tenantId) throw notFound('Affiliate not found.');
  const parentPath = pathOf(parent);
  if (wouldCycle(node.id, parent.id, parentPath)) throw placementCycle();
  if (node.placementParentId === parent.id && node.placementLeg === input.leg) throw placementInvalid('The affiliate is already in that position.');
  const occupant = await childOf(db, parent.id, input.leg);
  if (occupant && occupant !== node.id) throw positionTaken();
  const descendants = await db.affiliate.findMany({ where: { pathIdsJson: { contains: `"${node.id}"` } }, select: { id: true, pathIdsJson: true } });
  if (descendants.length && !input.moveSubtree)
    throw placementInvalid(
      `${descendants.length} affiliate(s) sit under this one. Moving them changes every ancestor's leg history; say so explicitly to move the whole team.`,
    );
  // Volume already counted stays on the ancestors who received it, so a move would leave their legs telling a false story.
  const counted = await db.mlmOrder.count({ where: { status: 'eligible', buyerAffiliateId: { in: [node.id, ...descendants.map((d) => d.id)] } } });
  if (counted > 0) throw placementInvalid(`${counted} verified sale(s) already count through this position, so it can no longer be moved.`);
  const newPath = pathUnder(parentPath, parent.id);
  const from = node.placementParentId && node.placementLeg ? { parentId: node.placementParentId, leg: node.placementLeg as MlmLeg } : null;
  const to = { parentId: parent.id, leg: input.leg };
  try {
    await db.$transaction(async (tx) => {
      // Vacate first, so a move within the same parent (A → B) never trips the unique index.
      await tx.affiliate.update({ where: { id: node.id }, data: { placementParentId: null, placementLeg: null } });
      await tx.affiliate.update({
        where: { id: node.id },
        data: { placementParentId: to.parentId, placementLeg: to.leg, pathIdsJson: JSON.stringify(newPath), depth: newPath.length },
      });
      for (const d of descendants) {
        const path = rebasedPath(readJson<string[]>(d.pathIdsJson, []), node.id, newPath);
        await tx.affiliate.update({ where: { id: d.id }, data: { pathIdsJson: JSON.stringify(path), depth: path.length } });
      }
      await history(tx, { affiliateId: node.id, from, to, reason: 'manual', actor: actor.auth ? { id: actor.auth.sub } : null, note: input.reason });
      await recordAuditLog(
        actor,
        {
          action: PLACEMENT_AUDIT_ACTIONS.manual,
          targetType: 'affiliate',
          targetId: node.id,
          meta: { from, to, reason: input.reason, descendantsMoved: descendants.length },
        },
        tx,
      );
    });
  } catch (err) {
    if (isUniqueViolation(err)) throw positionTaken();
    throw err;
  }
  observe('mlm.placement.manual', { affiliateId: node.id, descendantsMoved: descendants.length });
}

/**
 * Corrects who referred an affiliate. CV already attributed stays as it was; placement does not change. A leg the old
 * sponsor's link named means nothing under the new one, so it is dropped and a member still unplaced follows the new sponsor. Audited.
 */
export async function changeSponsor(actor: AuditActor, affiliateId: string, sponsorId: string | null, reason: string): Promise<void> {
  const node = await loadNode(db, affiliateId);
  if (node.tenantId !== currentTenantId()) throw notFound('Affiliate not found.');
  if (sponsorId) {
    const sponsor = await loadNode(db, sponsorId);
    if (sponsor.tenantId !== node.tenantId) throw notFound('Affiliate not found.');
    if (sponsor.id === node.id || pathOf(sponsor).includes(node.id)) throw placementCycle();
  }
  if (node.sponsorId === sponsorId) return;
  await db.$transaction(async (tx) => {
    await tx.affiliate.update({ where: { id: node.id }, data: { sponsorId, requestedLeg: null } });
    await recordAuditLog(
      actor,
      { action: PLACEMENT_AUDIT_ACTIONS.sponsorChanged, targetType: 'affiliate', targetId: node.id, meta: { from: node.sponsorId, to: sponsorId, reason } },
      tx,
    );
  });
}

/** Suspends, reactivates or terminates an affiliate. The position stays (§6.2); termination is final (trigger). Audited. */
export async function setAffiliateStatus(actor: AuditActor, affiliateId: string, status: Exclude<AffiliateStatus, 'pending'>, note: string): Promise<void> {
  const node = await loadNode(db, affiliateId);
  if (node.tenantId !== currentTenantId()) throw notFound('Affiliate not found.');
  if (node.status === 'terminated') throw conflict('A terminated affiliate cannot change.');
  if (status === 'active' && node.status === 'pending') throw conflict('An affiliate is activated by the eligible purchase, not by hand.');
  if (node.status === status) return;
  await db.$transaction(async (tx) => {
    await tx.affiliate.update({ where: { id: node.id }, data: { status } });
    await recordAuditLog(
      actor,
      { action: PLACEMENT_AUDIT_ACTIONS.statusChanged, targetType: 'affiliate', targetId: node.id, meta: { from: node.status, to: status, note } },
      tx,
    );
  });
}
