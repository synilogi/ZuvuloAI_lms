import { csvCell } from '../csv.js';
import {
  MLM_TREE_MAX_DEPTH,
  legUnderRoot,
  type AffiliateMemberQuery,
  type AffiliateMemberRow,
  type AffiliateStatus,
  type MlmLeg,
  type PlacementHistoryRow,
  type SponsorRow,
  type TeamPage,
  type TeamQuery,
  type TreeAncestor,
  type TreeNodeView,
} from '@syniastrolms/domain';
import type { Prisma } from '@prisma/client';

import { db } from '../db.js';
import { notFound } from '../errors.js';
import { readJson } from '../json.js';

/*
 * Reads of the genealogy (MLM-002): a subtree a few levels deep, the ancestors of a node, a member's whole team as a
 * flat page with counts, direct referrals, placement history, the Super Admin's member directory and the sponsor
 * view. Every descendant read uses the materialised ancestor path (`pathIdsJson`), so "everyone under X" is one query.
 * Nothing here writes.
 */

const NODE = {
  id: true,
  code: true,
  status: true,
  placementParentId: true,
  placementLeg: true,
  pathIdsJson: true,
  depth: true,
  sponsorId: true,
  currentRankOrder: true,
  activatedAt: true,
  createdAt: true,
  user: { select: { name: true } },
} satisfies Prisma.AffiliateSelect;
type NodeRow = Prisma.AffiliateGetPayload<{ select: typeof NODE }>;

const pathOf = (row: Pick<NodeRow, 'pathIdsJson'>): string[] => readJson<string[]>(row.pathIdsJson, []);

/** Every descendant of a node: those whose ancestor path names it. */
const descendantsOf = (rootId: string, extra: Prisma.AffiliateWhereInput = {}) =>
  db.affiliate.findMany({ where: { pathIdsJson: { contains: `"${rootId}"` }, ...extra }, select: NODE });

async function directReferralCounts(ids: string[]): Promise<Map<string, number>> {
  if (!ids.length) return new Map();
  const groups = await db.affiliate.groupBy({ by: ['sponsorId'], where: { sponsorId: { in: ids } }, _count: { _all: true } });
  return new Map(groups.map((g) => [g.sponsorId as string, g._count._all]));
}

/** A node and its subtree to `depth` levels (≤ MLM_TREE_MAX_DEPTH). Beyond that, `children` is null and `hasChildren` says what is there. */
export async function subtree(rootId: string, depth = 3): Promise<TreeNodeView> {
  const levels = Math.max(0, Math.min(MLM_TREE_MAX_DEPTH, depth));
  const root = await db.affiliate.findUnique({ where: { id: rootId }, select: NODE });
  if (!root) throw notFound('Affiliate not found.');
  const below = await descendantsOf(rootId, { depth: { lte: root.depth + levels + 1 } });
  const all = [root, ...below];
  const referrals = await directReferralCounts(all.map((n) => n.id));
  const byParent = new Map<string, Partial<Record<MlmLeg, NodeRow>>>();
  for (const n of below) {
    if (!n.placementParentId || !n.placementLeg) continue;
    const slots = byParent.get(n.placementParentId) ?? {};
    slots[n.placementLeg as MlmLeg] = n;
    byParent.set(n.placementParentId, slots);
  }
  const build = (n: NodeRow, remaining: number): TreeNodeView => {
    const slots = byParent.get(n.id) ?? {};
    return {
      id: n.id,
      code: n.code,
      name: n.user.name,
      status: n.status as AffiliateStatus,
      placementLeg: n.placementLeg as MlmLeg | null,
      depth: n.depth,
      currentRankOrder: n.currentRankOrder,
      activatedAt: n.activatedAt?.toISOString() ?? null,
      directReferrals: referrals.get(n.id) ?? 0,
      hasChildren: { A: Boolean(slots.A), B: Boolean(slots.B) },
      children: remaining > 0 ? { A: slots.A ? build(slots.A, remaining - 1) : null, B: slots.B ? build(slots.B, remaining - 1) : null } : null,
    };
  };
  return build(root, levels);
}

/** The ancestors of a node, root first. */
export async function ancestors(id: string): Promise<TreeAncestor[]> {
  const node = await db.affiliate.findUnique({ where: { id }, select: { pathIdsJson: true } });
  if (!node) throw notFound('Affiliate not found.');
  const ids = pathOf(node);
  if (!ids.length) return [];
  const rows = await db.affiliate.findMany({ where: { id: { in: ids } }, select: NODE });
  const byId = new Map(rows.map((r) => [r.id, r]));
  return ids.flatMap((i) => {
    const r = byId.get(i);
    return r ? [{ id: r.id, code: r.code, name: r.user.name, placementLeg: r.placementLeg as MlmLeg | null, depth: r.depth }] : [];
  });
}

/** Everyone under a node as a flat, filtered page, with the counts the dashboard shows. */
export async function team(rootId: string, query: TeamQuery = {}): Promise<TeamPage> {
  const root = await db.affiliate.findUnique({ where: { id: rootId }, select: NODE });
  if (!root) throw notFound('Affiliate not found.');
  const everyone = await descendantsOf(rootId);
  const legs = new Map(everyone.map((n) => [n.id, n.placementLeg as MlmLeg | null]));
  const legOf = (id: string) => legs.get(id) ?? null;
  const sponsorCodes = new Map<string, string>();
  const parentCodes = new Map<string, string>([[root.id, root.code]]);
  for (const n of everyone) parentCodes.set(n.id, n.code);
  const missingSponsors = [...new Set(everyone.map((n) => n.sponsorId).filter((s): s is string => Boolean(s) && !parentCodes.has(s as string)))];
  if (missingSponsors.length)
    for (const s of await db.affiliate.findMany({ where: { id: { in: missingSponsors } }, select: { id: true, code: true } })) sponsorCodes.set(s.id, s.code);
  const rows = everyone.map((n) => ({
    id: n.id,
    code: n.code,
    name: n.user.name,
    status: n.status as AffiliateStatus,
    leg: legUnderRoot(root.id, pathOf(n), n.placementLeg as MlmLeg | null, legOf),
    depth: n.depth - root.depth,
    sponsorCode: n.sponsorId ? (parentCodes.get(n.sponsorId) ?? sponsorCodes.get(n.sponsorId) ?? null) : null,
    parentCode: n.placementParentId ? (parentCodes.get(n.placementParentId) ?? null) : null,
    placementLeg: n.placementLeg as MlmLeg | null,
    joinedAt: n.createdAt.toISOString(),
    activatedAt: n.activatedAt?.toISOString() ?? null,
  }));
  const summary = {
    directReferrals:
      everyone.filter((n) => n.sponsorId === root.id).length +
      (await db.affiliate.count({ where: { sponsorId: root.id, NOT: { pathIdsJson: { contains: `"${root.id}"` } } } })),
    total: rows.length,
    byLeg: { A: rows.filter((r) => r.leg === 'A').length, B: rows.filter((r) => r.leg === 'B').length },
    active: rows.filter((r) => r.status === 'active').length,
    pending: rows.filter((r) => r.status === 'pending').length,
  };
  const search = query.search?.trim().toLowerCase();
  const filtered = rows
    .filter(
      (r) =>
        (!query.leg || r.leg === query.leg) &&
        (!query.status || r.status === query.status) &&
        (!search || r.name.toLowerCase().includes(search) || r.code.toLowerCase().includes(search)),
    )
    .sort((a, b) => a.depth - b.depth || a.joinedAt.localeCompare(b.joinedAt));
  const pageSize = Math.min(500, Math.max(1, query.pageSize ?? 50));
  const page = Math.max(1, query.page ?? 1);
  return { rows: filtered.slice((page - 1) * pageSize, page * pageSize), total: filtered.length, page, pageSize, summary };
}

/** The affiliates a sponsor referred, wherever they were placed. */
export async function directReferrals(sponsorId: string): Promise<TeamPage['rows']> {
  const rows = await db.affiliate.findMany({ where: { sponsorId }, select: NODE, orderBy: { createdAt: 'asc' } });
  const sponsor = await db.affiliate.findUnique({ where: { id: sponsorId }, select: { code: true, depth: true, id: true } });
  const parents = await db.affiliate.findMany({
    where: { id: { in: rows.map((r) => r.placementParentId).filter((p): p is string => Boolean(p)) } },
    select: { id: true, code: true },
  });
  const parentCode = new Map(parents.map((p) => [p.id, p.code]));
  return rows.map((n) => ({
    id: n.id,
    code: n.code,
    name: n.user.name,
    status: n.status as AffiliateStatus,
    leg: sponsor && pathOf(n).includes(sponsor.id) ? legUnderRoot(sponsor.id, pathOf(n), n.placementLeg as MlmLeg | null, () => null) : null,
    depth: sponsor ? n.depth - sponsor.depth : n.depth,
    sponsorCode: sponsor?.code ?? null,
    parentCode: n.placementParentId ? (parentCode.get(n.placementParentId) ?? null) : null,
    placementLeg: n.placementLeg as MlmLeg | null,
    joinedAt: n.createdAt.toISOString(),
    activatedAt: n.activatedAt?.toISOString() ?? null,
  }));
}

const MEMBER = {
  ...NODE,
  tenantId: true,
  preferredLeg: true,
  requestedLeg: true,
  kycStatus: true,
  user: { select: { name: true, email: true } },
  sponsor: { select: { id: true, code: true, user: { select: { name: true } } } },
  placementParent: { select: { id: true, code: true } },
  tenant: { select: { id: true, name: true, slug: true } },
} satisfies Prisma.AffiliateSelect;
type MemberRow = Prisma.AffiliateGetPayload<{ select: typeof MEMBER }>;

async function toMember(rows: MemberRow[]): Promise<AffiliateMemberRow[]> {
  const referrals = await directReferralCounts(rows.map((r) => r.id));
  const sizes = await Promise.all(rows.map((r) => db.affiliate.count({ where: { pathIdsJson: { contains: `"${r.id}"` } } })));
  return rows.map((r, i) => ({
    id: r.id,
    code: r.code,
    name: r.user.name,
    email: r.user.email,
    status: r.status as AffiliateStatus,
    academy: r.tenant,
    sponsor: r.sponsor ? { id: r.sponsor.id, code: r.sponsor.code, name: r.sponsor.user.name } : null,
    placement:
      r.placementParent && r.placementLeg
        ? { parentId: r.placementParent.id, parentCode: r.placementParent.code, leg: r.placementLeg as MlmLeg, depth: r.depth }
        : null,
    preferredLeg: r.preferredLeg as MlmLeg,
    requestedLeg: r.requestedLeg as MlmLeg | null,
    currentRankOrder: r.currentRankOrder,
    kycStatus: r.kycStatus,
    activatedAt: r.activatedAt?.toISOString() ?? null,
    joinedAt: r.createdAt.toISOString(),
    directReferrals: referrals.get(r.id) ?? 0,
    teamSize: sizes[i],
  }));
}

/** The Super Admin's member directory, across academies unless one is named. */
export async function listMembers(
  query: AffiliateMemberQuery = {},
): Promise<{ rows: AffiliateMemberRow[]; total: number; page: number; pageSize: number; counts: Record<AffiliateStatus | 'all', number> }> {
  const search = query.search?.trim();
  const where: Prisma.AffiliateWhereInput = {
    ...(query.tenantId ? { tenantId: query.tenantId } : {}),
    ...(query.status ? { status: query.status } : {}),
    ...(query.rank !== undefined ? { currentRankOrder: query.rank } : {}),
    ...(query.kyc ? { kycStatus: query.kyc } : {}),
    ...(search
      ? { OR: [{ code: { contains: search.toUpperCase() } }, { user: { name: { contains: search } } }, { user: { email: { contains: search } } }] }
      : {}),
  };
  const pageSize = Math.min(500, Math.max(1, query.pageSize ?? 20));
  const page = Math.max(1, query.page ?? 1);
  const [rows, total, groups] = await Promise.all([
    db.affiliate.findMany({ where, select: MEMBER, orderBy: { createdAt: 'desc' }, skip: (page - 1) * pageSize, take: pageSize }),
    db.affiliate.count({ where }),
    db.affiliate.groupBy({ by: ['status'], where: query.tenantId ? { tenantId: query.tenantId } : {}, _count: { _all: true } }),
  ]);
  const counts = { all: 0, pending: 0, active: 0, suspended: 0, terminated: 0 } as Record<AffiliateStatus | 'all', number>;
  for (const g of groups) {
    counts[g.status as AffiliateStatus] = g._count._all;
    counts.all += g._count._all;
  }
  return { rows: await toMember(rows), total, page, pageSize, counts };
}

export async function memberDetail(id: string): Promise<AffiliateMemberRow> {
  const row = await db.affiliate.findUnique({ where: { id }, select: MEMBER });
  if (!row) throw notFound('Affiliate not found.');
  return (await toMember([row]))[0];
}

export async function placementHistory(
  query: { affiliateId?: string; tenantId?: string; page?: number; pageSize?: number } = {},
): Promise<{ rows: PlacementHistoryRow[]; total: number; page: number; pageSize: number }> {
  const where: Prisma.MlmPlacementHistoryWhereInput = {
    ...(query.affiliateId ? { affiliateId: query.affiliateId } : {}),
    ...(query.tenantId ? { tenantId: query.tenantId } : {}),
  };
  const pageSize = Math.min(500, Math.max(1, query.pageSize ?? 50));
  const page = Math.max(1, query.page ?? 1);
  const [rows, total] = await Promise.all([
    db.mlmPlacementHistory.findMany({ where, orderBy: { createdAt: 'desc' }, skip: (page - 1) * pageSize, take: pageSize }),
    db.mlmPlacementHistory.count({ where }),
  ]);
  const ids = [...new Set(rows.flatMap((r) => [r.affiliateId, r.fromParentId, r.toParentId]).filter((x): x is string => Boolean(x)))];
  const actorIds = [...new Set(rows.map((r) => r.actorId).filter((x): x is string => Boolean(x)))];
  const [nodes, actors] = await Promise.all([
    ids.length ? db.affiliate.findMany({ where: { id: { in: ids } }, select: { id: true, code: true, user: { select: { name: true } } } }) : [],
    actorIds.length ? db.user.findMany({ where: { id: { in: actorIds } }, select: { id: true, name: true } }) : [],
  ]);
  const node = new Map(nodes.map((n) => [n.id, n]));
  const actor = new Map(actors.map((a) => [a.id, a.name]));
  return {
    rows: rows.map((r) => {
      const a = node.get(r.affiliateId);
      return {
        id: r.id,
        affiliate: { id: r.affiliateId, code: a?.code ?? '', name: a?.user.name ?? '' },
        from: r.fromParentId && r.fromLeg ? { parentCode: node.get(r.fromParentId)?.code ?? r.fromParentId, leg: r.fromLeg as MlmLeg } : null,
        to: r.toParentId && r.toLeg ? { parentCode: node.get(r.toParentId)?.code ?? r.toParentId, leg: r.toLeg as MlmLeg } : null,
        reason: r.reason as PlacementHistoryRow['reason'],
        actor: { type: r.actorType as 'system' | 'user', name: r.actorId ? (actor.get(r.actorId) ?? null) : null },
        note: r.note,
        createdAt: r.createdAt.toISOString(),
      };
    }),
    total,
    page,
    pageSize,
  };
}

/** Sponsors with how many they referred and how many of those are active. */
export async function listSponsors(
  query: { tenantId?: string; search?: string; page?: number; pageSize?: number } = {},
): Promise<{ rows: SponsorRow[]; total: number; page: number; pageSize: number }> {
  const search = query.search?.trim();
  const where: Prisma.AffiliateWhereInput = {
    referrals: { some: {} },
    ...(query.tenantId ? { tenantId: query.tenantId } : {}),
    ...(search ? { OR: [{ code: { contains: search.toUpperCase() } }, { user: { name: { contains: search } } }] } : {}),
  };
  const pageSize = Math.min(500, Math.max(1, query.pageSize ?? 20));
  const page = Math.max(1, query.page ?? 1);
  const [rows, total] = await Promise.all([
    db.affiliate.findMany({
      where,
      select: {
        id: true,
        code: true,
        status: true,
        user: { select: { name: true } },
        tenant: { select: { name: true, slug: true } },
        _count: { select: { referrals: true } },
        referrals: { select: { status: true } },
      },
      orderBy: { referrals: { _count: 'desc' } },
      skip: (page - 1) * pageSize,
      take: pageSize,
    }),
    db.affiliate.count({ where }),
  ]);
  return {
    rows: rows.map((r) => ({
      id: r.id,
      code: r.code,
      name: r.user.name,
      status: r.status as AffiliateStatus,
      academy: r.tenant,
      directReferrals: r._count.referrals,
      activeReferrals: r.referrals.filter((x) => x.status === 'active').length,
    })),
    total,
    page,
    pageSize,
  };
}

/** The genealogy under a node as CSV: one row per member, every page. */
export async function networkCsv(rootId: string): Promise<string> {
  const rows: TeamPage['rows'] = [];
  for (let page = 1; ; page++) {
    const chunk = await team(rootId, { pageSize: 500, page });
    rows.push(...chunk.rows);
    if (rows.length >= chunk.total || chunk.rows.length === 0) break;
  }
  const lines = ['code,name,status,leg,depth,sponsorCode,parentCode,placementLeg,joinedAt,activatedAt'];
  for (const r of rows)
    lines.push([r.code, r.name, r.status, r.leg, r.depth, r.sponsorCode, r.parentCode, r.placementLeg, r.joinedAt, r.activatedAt].map(csvCell).join(','));
  return lines.join('\n') + '\n';
}
