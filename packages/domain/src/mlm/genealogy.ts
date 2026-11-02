import type { AffiliateStatus } from './affiliate';
import type { MlmKycStatus } from './earnings';
import type { MlmLeg, MlmSpilloverRule } from './plan';

/*
 * The binary genealogy (docs/15 §4.3, §6.3): every affiliate has two positions, A/Left and B/Right, under one parent.
 * Sponsor and placement are separate: the sponsor is who referred someone, the placement parent is whose position
 * they fill. A referral goes to the sponsor's preferred leg; when that position is taken it spills over deeper in
 * the same leg by the plan's published rule. The rules here are pure; the API walks the stored tree with them.
 */

export type PlacementReason = 'sponsor-direct' | 'spillover' | 'manual' | 'root';
export const PLACEMENT_REASONS: readonly PlacementReason[] = ['sponsor-direct', 'spillover', 'manual', 'root'];

/** How many levels a tree read returns at once; deeper levels are read by drilling down. */
export const MLM_TREE_MAX_DEPTH = 6;

export const otherLeg = (leg: MlmLeg): MlmLeg => (leg === 'A' ? 'B' : 'A');

/** The ancestor path of a node placed under `parentId`, root first. */
export const pathUnder = (parentPath: readonly string[], parentId: string): string[] => [...parentPath, parentId];

/** Whether placing `nodeId` under `candidateId` would make a cycle: the candidate is the node, or sits in its subtree. */
export const wouldCycle = (nodeId: string, candidateId: string, candidatePath: readonly string[]): boolean =>
  candidateId === nodeId || candidatePath.includes(nodeId);

/** The ancestor path of a descendant after its ancestor `nodeId` moves to `newNodePath`: the part from the node on is kept. */
export function rebasedPath(oldPath: readonly string[], nodeId: string, newNodePath: readonly string[]): string[] {
  const at = oldPath.indexOf(nodeId);
  if (at < 0) throw new Error('The node is not an ancestor on this path.');
  return [...newNodePath, ...oldPath.slice(at)];
}

/**
 * The position a referral takes under `startId` on leg `leg`, by the plan's spillover rule, given how to read a
 * node's child. `extreme-outer` follows the leg outward (A keeps going A, B keeps going B) to the first free
 * position; `breadth-first` takes the first free position in that leg's subtree level by level, A before B.
 */
export function findFreePosition(
  rule: MlmSpilloverRule,
  startId: string,
  leg: MlmLeg,
  childOf: (parentId: string, leg: MlmLeg) => string | null,
): { parentId: string; leg: MlmLeg } {
  if (rule === 'extreme-outer') {
    let node = startId;
    for (;;) {
      const child = childOf(node, leg);
      if (!child) return { parentId: node, leg };
      node = child;
    }
  }
  const top = childOf(startId, leg);
  if (!top) return { parentId: startId, leg };
  const queue = [top];
  for (;;) {
    const node = queue.shift();
    if (!node) throw new Error('The breadth-first search ran out of nodes, which a binary tree cannot do.');
    for (const l of ['A', 'B'] as const) {
      const child = childOf(node, l);
      if (!child) return { parentId: node, leg: l };
      queue.push(child);
    }
  }
}

/** The leg of `rootId` a node sits under, from the node's ancestor path and the legs of the nodes on it. */
export function legUnderRoot(rootId: string, nodePath: readonly string[], nodeLeg: MlmLeg | null, legOf: (id: string) => MlmLeg | null): MlmLeg | null {
  const at = nodePath.indexOf(rootId);
  if (at < 0) return null;
  if (at === nodePath.length - 1) return nodeLeg;
  return legOf(nodePath[at + 1]);
}

/* ─── Views ────────────────────────────────────────────────────────────── */

/** One node of a tree read. `children` is null beyond the depth asked for; `hasChildren` says what is there. */
export interface TreeNodeView {
  id: string;
  code: string;
  name: string;
  status: AffiliateStatus;
  placementLeg: MlmLeg | null;
  depth: number;
  currentRankOrder: number;
  activatedAt: string | null;
  directReferrals: number;
  hasChildren: { A: boolean; B: boolean };
  children: { A: TreeNodeView | null; B: TreeNodeView | null } | null;
}

export interface TreeAncestor {
  id: string;
  code: string;
  name: string;
  placementLeg: MlmLeg | null;
  depth: number;
}

export interface TeamRow {
  id: string;
  code: string;
  name: string;
  status: AffiliateStatus;
  /** Which of the root's legs the member sits under. */
  leg: MlmLeg | null;
  /** Levels below the root. */
  depth: number;
  sponsorCode: string | null;
  parentCode: string | null;
  placementLeg: MlmLeg | null;
  joinedAt: string;
  activatedAt: string | null;
}

export interface TeamSummary {
  directReferrals: number;
  total: number;
  byLeg: { A: number; B: number };
  active: number;
  pending: number;
}

export interface TeamQuery {
  leg?: MlmLeg;
  status?: AffiliateStatus;
  search?: string;
  page?: number;
  pageSize?: number;
}

export interface TeamPage {
  rows: TeamRow[];
  total: number;
  page: number;
  pageSize: number;
  summary: TeamSummary;
}

export interface PlacementHistoryRow {
  id: string;
  affiliate: { id: string; code: string; name: string };
  from: { parentCode: string; leg: MlmLeg } | null;
  to: { parentCode: string; leg: MlmLeg } | null;
  reason: PlacementReason;
  actor: { type: 'system' | 'user'; name: string | null };
  note: string | null;
  createdAt: string;
}

/** A member as the Super Admin's list and detail show one. */
export interface AffiliateMemberRow {
  id: string;
  code: string;
  name: string;
  email: string;
  status: AffiliateStatus;
  academy: { id: string; name: string; slug: string };
  sponsor: { id: string; code: string; name: string } | null;
  placement: { parentId: string; parentCode: string; leg: MlmLeg; depth: number } | null;
  preferredLeg: MlmLeg;
  /** The leg of the sponsor that the link they joined through named, if any. */
  requestedLeg: MlmLeg | null;
  currentRankOrder: number;
  kycStatus: string;
  activatedAt: string | null;
  joinedAt: string;
  directReferrals: number;
  teamSize: number;
}

export interface AffiliateMemberQuery {
  tenantId?: string;
  status?: AffiliateStatus;
  /** The rank order held now; 0 is nobody's rank yet. */
  rank?: number;
  kyc?: MlmKycStatus;
  search?: string;
  page?: number;
  pageSize?: number;
}

export interface SponsorRow {
  id: string;
  code: string;
  name: string;
  status: AffiliateStatus;
  academy: { name: string; slug: string };
  directReferrals: number;
  activeReferrals: number;
}

export interface ManualPlacementInput {
  parentId: string;
  leg: MlmLeg;
  reason: string;
  /** Move the node with everything under it. Refused by default: ancestors' leg histories change (D-MLM-19). */
  moveSubtree?: boolean;
}
