import {
  affiliateCodeFrom,
  findFreePosition,
  legUnderRoot,
  pathUnder,
  rebasedPath,
  wouldCycle,
  type AffiliateMemberRow,
  type AffiliateStatus,
  type ManualPlacementInput,
  type MlmLeg,
  type PlacementHistoryRow,
  type PlacementReason,
  type SponsorRow,
  type TeamPage,
  type TeamQuery,
  type TeamRow,
  type TreeAncestor,
  type TreeNodeView,
} from '@syniastrolms/domain';
import { ServiceError } from '../contracts';
import { resetCv } from './affiliateCv';
import { mockNowIso } from './clock';

/*
 * The demo genealogy, shared by the learner's and the Super Admin's affiliate mocks: a small binary tree with a
 * sponsor at the root, kept in memory for the visit, placed and moved by the same rules as the API (the domain's
 * `findFreePosition`, `wouldCycle`, `rebasedPath`).
 */

export interface MockNode {
  id: string;
  code: string;
  name: string;
  email: string;
  status: AffiliateStatus;
  sponsorId: string | null;
  parentId: string | null;
  leg: MlmLeg | null;
  path: string[];
  preferredLeg: MlmLeg;
  requestedLeg: MlmLeg | null;
  activatedAt: string | null;
  joinedAt: string;
  kycStatus: string;
  currentRankOrder: number;
}

export const DEMO_ACADEMY = { id: 'acad-demo', name: 'Demo Academy', slug: 'demo' };

const nodes: MockNode[] = [];
const history: PlacementHistoryRow[] = [];

let seq = 0;
const codeAt = (n: number) => affiliateCodeFrom(() => (n * 0.37) % 1 || 0.11);

function add(
  name: string,
  sponsorId: string | null,
  status: AffiliateStatus,
  joinedDaysAgo: number,
  preferredLeg: MlmLeg = 'A',
  at?: { parentId: string; leg: MlmLeg },
  requestedLeg: MlmLeg | null = null,
): MockNode {
  const n = ++seq;
  const joined = new Date(Date.parse(mockNowIso()) - joinedDaysAgo * 86_400_000).toISOString();
  const node: MockNode = {
    id: `aff-${n}`,
    code: codeAt(n),
    name,
    email: `${name.toLowerCase().replace(/\s+/g, '.')}@example.com`,
    status,
    sponsorId,
    parentId: null,
    leg: null,
    path: [],
    preferredLeg,
    requestedLeg,
    activatedAt: status === 'active' ? joined : null,
    joinedAt: joined,
    kycStatus: status === 'active' ? 'verified' : 'none',
    currentRankOrder: status === 'active' ? n % 3 : 0,
  };
  nodes.push(node);
  if (at) {
    // A fixed demo shape: placed where the fixture says, recorded as the rule would have.
    const parent = byId(at.parentId);
    node.parentId = parent.id;
    node.leg = at.leg;
    node.path = pathUnder(parent.path, parent.id);
    record(node, null, at, at.parentId === sponsorId ? 'sponsor-direct' : 'spillover', 'system', null);
  } else place(node, sponsorId ? 'spillover' : 'root');
  return node;
}

const childOf = (parentId: string, leg: MlmLeg) => nodes.find((n) => n.parentId === parentId && n.leg === leg)?.id ?? null;

function record(
  node: MockNode,
  from: { parentId: string; leg: MlmLeg } | null,
  to: { parentId: string; leg: MlmLeg } | null,
  reason: PlacementReason,
  actor: 'system' | 'user',
  note: string | null,
) {
  const codeOf = (id: string) => nodes.find((n) => n.id === id)?.code ?? id;
  history.unshift({
    id: `ph-${history.length + 1}`,
    affiliate: { id: node.id, code: node.code, name: node.name },
    from: from ? { parentCode: codeOf(from.parentId), leg: from.leg } : null,
    to: to ? { parentCode: codeOf(to.parentId), leg: to.leg } : null,
    reason,
    actor: { type: actor, name: actor === 'user' ? 'Platform Team' : null },
    note,
    createdAt: mockNowIso(),
  });
}

function place(node: MockNode, reason: PlacementReason) {
  if (!node.sponsorId) {
    record(node, null, null, 'root', 'system', null);
    return;
  }
  const sponsor = byId(node.sponsorId);
  const position = findFreePosition('extreme-outer', sponsor.id, node.requestedLeg ?? sponsor.preferredLeg, childOf);
  const parent = byId(position.parentId);
  node.parentId = parent.id;
  node.leg = position.leg;
  node.path = pathUnder(parent.path, parent.id);
  record(node, null, position, position.parentId === sponsor.id ? 'sponsor-direct' : reason, 'system', null);
}

export function byId(id: string): MockNode {
  const n = nodes.find((x) => x.id === id);
  if (!n) throw new ServiceError('Affiliate not found.', 'not-found');
  return n;
}

export const byCode = (code: string): MockNode | undefined => seedTree().find((n) => n.code === code);

export function seedTree(): MockNode[] {
  if (nodes.length) return nodes;
  // The demo shape, nine people (free positions: Rohit B, Rohan A/B, Deepak A/B, Anjali B, Kiran A/B, Meera A/B):
  //   Priya ─A─ Rahul ─A─ Seema ─A─ Deepak
  //         │          │        └B─ Kiran
  //         │          └B─ Rohan
  //         └B─ Rohit ─A─ Anjali ─A─ Meera
  const priya = add('Priya Sharma', null, 'active', 120, 'A');
  const rahul = add('Rahul Verma', priya.id, 'active', 90, 'A', { parentId: priya.id, leg: 'A' });
  const rohit = add('Rohit Mehta', priya.id, 'active', 85, 'B', { parentId: priya.id, leg: 'B' });
  const seema = add('Seema Iyer', priya.id, 'active', 70, 'A', { parentId: rahul.id, leg: 'A' });
  add('Rohan Das', rahul.id, 'pending', 40, 'A', { parentId: rahul.id, leg: 'B' });
  add('Deepak Nair', rahul.id, 'active', 30, 'A', { parentId: seema.id, leg: 'A' });
  const anjali = add('Anjali Rao', rohit.id, 'active', 20, 'B', { parentId: rohit.id, leg: 'A' });
  add('Kiran Patel', seema.id, 'pending', 10, 'A', { parentId: seema.id, leg: 'B' });
  add('Meera Joshi', priya.id, 'suspended', 5, 'A', { parentId: anjali.id, leg: 'A' });
  return nodes;
}

export const demoSponsor = (): MockNode => seedTree()[0];

/** Adds the visiting learner to the tree, as the API would. */
export function addMember(name: string, sponsorCode: string | undefined, preferredLeg: MlmLeg, requestedLeg: MlmLeg | null = null): MockNode {
  seedTree();
  const sponsor = sponsorCode ? byCode(sponsorCode) : undefined;
  if (sponsorCode && !sponsor) throw new ServiceError('This referral link isn’t valid.', 'not-found', 'REFERRAL_INVALID');
  return add(name, sponsor?.id ?? null, 'pending', 0, preferredLeg, undefined, sponsor ? requestedLeg : null);
}

export function resetTree() {
  nodes.length = 0;
  history.length = 0;
  seq = 0;
  resetCv();
}

/* ─── Reads ────────────────────────────────────────────────────────────── */

const descendantsOf = (rootId: string) => nodes.filter((n) => n.path.includes(rootId));
const directReferrals = (id: string) => nodes.filter((n) => n.sponsorId === id).length;

export function subtree(rootId: string, depth = 3): TreeNodeView {
  const root = byId(rootId);
  const build = (n: MockNode, remaining: number): TreeNodeView => {
    const a = childOf(n.id, 'A');
    const b = childOf(n.id, 'B');
    return {
      id: n.id,
      code: n.code,
      name: n.name,
      status: n.status,
      placementLeg: n.leg,
      depth: n.path.length,
      currentRankOrder: n.currentRankOrder,
      activatedAt: n.activatedAt,
      directReferrals: directReferrals(n.id),
      hasChildren: { A: Boolean(a), B: Boolean(b) },
      children: remaining > 0 ? { A: a ? build(byId(a), remaining - 1) : null, B: b ? build(byId(b), remaining - 1) : null } : null,
    };
  };
  return build(root, Math.max(0, Math.min(6, depth)));
}

export const ancestorsOf = (id: string): TreeAncestor[] =>
  byId(id)
    .path.map((p) => byId(p))
    .map((n) => ({ id: n.id, code: n.code, name: n.name, placementLeg: n.leg, depth: n.path.length }));

const toTeamRow = (root: MockNode, n: MockNode): TeamRow => ({
  id: n.id,
  code: n.code,
  name: n.name,
  status: n.status,
  leg: legUnderRoot(root.id, n.path, n.leg, (id) => byId(id).leg),
  depth: n.path.length - root.path.length,
  sponsorCode: n.sponsorId ? byId(n.sponsorId).code : null,
  parentCode: n.parentId ? byId(n.parentId).code : null,
  placementLeg: n.leg,
  joinedAt: n.joinedAt,
  activatedAt: n.activatedAt,
});

export function teamOf(rootId: string, query: TeamQuery = {}): TeamPage {
  const root = byId(rootId);
  const rows = descendantsOf(rootId).map((n) => toTeamRow(root, n));
  const search = query.search?.trim().toLowerCase();
  const filtered = rows.filter(
    (r) =>
      (!query.leg || r.leg === query.leg) &&
      (!query.status || r.status === query.status) &&
      (!search || r.name.toLowerCase().includes(search) || r.code.toLowerCase().includes(search)),
  );
  const pageSize = query.pageSize ?? 50;
  const page = query.page ?? 1;
  return {
    rows: filtered.slice((page - 1) * pageSize, page * pageSize),
    total: filtered.length,
    page,
    pageSize,
    summary: {
      directReferrals: directReferrals(rootId),
      total: rows.length,
      byLeg: { A: rows.filter((r) => r.leg === 'A').length, B: rows.filter((r) => r.leg === 'B').length },
      active: rows.filter((r) => r.status === 'active').length,
      pending: rows.filter((r) => r.status === 'pending').length,
    },
  };
}

export const referralsOf = (id: string): TeamRow[] => nodes.filter((n) => n.sponsorId === id).map((n) => toTeamRow(byId(id), n));

export const toMember = (n: MockNode): AffiliateMemberRow => ({
  id: n.id,
  code: n.code,
  name: n.name,
  email: n.email,
  status: n.status,
  academy: DEMO_ACADEMY,
  sponsor: n.sponsorId ? { id: n.sponsorId, code: byId(n.sponsorId).code, name: byId(n.sponsorId).name } : null,
  placement: n.parentId && n.leg ? { parentId: n.parentId, parentCode: byId(n.parentId).code, leg: n.leg, depth: n.path.length } : null,
  preferredLeg: n.preferredLeg,
  requestedLeg: n.requestedLeg,
  currentRankOrder: n.currentRankOrder,
  kycStatus: n.kycStatus,
  activatedAt: n.activatedAt,
  joinedAt: n.joinedAt,
  directReferrals: directReferrals(n.id),
  teamSize: descendantsOf(n.id).length,
});

export const allNodes = (): MockNode[] => seedTree();
export const placementRows = (): PlacementHistoryRow[] => history;

export const sponsorRows = (): SponsorRow[] =>
  seedTree()
    .filter((n) => directReferrals(n.id) > 0)
    .map((n) => ({
      id: n.id,
      code: n.code,
      name: n.name,
      status: n.status,
      academy: { name: DEMO_ACADEMY.name, slug: DEMO_ACADEMY.slug },
      directReferrals: directReferrals(n.id),
      activeReferrals: nodes.filter((x) => x.sponsorId === n.id && x.status === 'active').length,
    }))
    .sort((a, b) => b.directReferrals - a.directReferrals);

/* ─── Writes ───────────────────────────────────────────────────────────── */

export function moveNode(id: string, input: ManualPlacementInput): MockNode {
  const node = byId(id);
  const parent = byId(input.parentId);
  if (wouldCycle(node.id, parent.id, parent.path))
    throw new ServiceError('An affiliate cannot be placed under itself or under someone in its own team.', 'conflict', 'PLACEMENT_CYCLE');
  const occupant = childOf(parent.id, input.leg);
  if (occupant && occupant !== node.id) throw new ServiceError('That position is already filled.', 'conflict', 'POSITION_TAKEN');
  const below = descendantsOf(node.id);
  if (below.length && !input.moveSubtree)
    throw new ServiceError(`${below.length} affiliate(s) sit under this one. Say so explicitly to move the whole team.`, 'conflict', 'PLACEMENT_INVALID');
  const from = node.parentId && node.leg ? { parentId: node.parentId, leg: node.leg } : null;
  const newPath = pathUnder(parent.path, parent.id);
  for (const d of below) d.path = rebasedPath(d.path, node.id, newPath);
  node.parentId = parent.id;
  node.leg = input.leg;
  node.path = newPath;
  record(node, from, { parentId: parent.id, leg: input.leg }, 'manual', 'user', input.reason);
  return node;
}

export function setSponsor(id: string, sponsorId: string | null): MockNode {
  const node = byId(id);
  if (sponsorId) {
    const sponsor = byId(sponsorId);
    if (sponsor.id === node.id || sponsor.path.includes(node.id))
      throw new ServiceError('An affiliate cannot sponsor themselves or someone above them.', 'conflict', 'PLACEMENT_CYCLE');
  }
  node.sponsorId = sponsorId;
  return node;
}

export function setStatus(id: string, status: 'active' | 'suspended' | 'terminated'): MockNode {
  const node = byId(id);
  if (node.status === 'terminated') throw new ServiceError('A terminated affiliate cannot change.', 'conflict');
  if (status === 'active' && node.status === 'pending') throw new ServiceError('An affiliate is activated by the eligible purchase, not by hand.', 'conflict');
  node.status = status;
  return node;
}
