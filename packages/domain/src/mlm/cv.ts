import type { MlmLeg } from './plan';
import { bpsOf } from './plan';

/*
 * Commissionable volume (docs/15 §6.4): a verified sale of an eligible course generates CV, which is credited to every
 * ancestor on the buyer's placement path, in the leg of that ancestor the buyer sits under. The buyer's own node gets
 * nothing. A reversal (refund, chargeback, a Super Admin's hand) writes the same credits negated. The rules are pure;
 * the API stores the ledger and the balances.
 */

export type MlmOrderStatus = 'pending' | 'eligible' | 'reversed';
export const MLM_ORDER_STATUSES: readonly MlmOrderStatus[] = ['pending', 'eligible', 'reversed'];

export type MlmReversalReason = 'refund' | 'chargeback' | 'manual';
export const MLM_REVERSAL_REASONS: readonly MlmReversalReason[] = ['refund', 'chargeback', 'manual'];

export type MlmCvKind = 'sale' | 'reversal';

/** The CV a sale generates: basis points of its net amount, rounded half-up. */
export const cvOfSale = (netAmount: number, cvBasisPoints: number): number => bpsOf(netAmount, cvBasisPoints);

/**
 * For each ancestor on a buyer's path (root first), the leg of that ancestor the buyer sits under: the leg of the next
 * node on the path, or the buyer's own leg for the parent. `legOf` reads a node's placement leg.
 */
export function creditsAlongPath(
  path: readonly string[],
  buyerLeg: MlmLeg | null,
  legOf: (id: string) => MlmLeg | null,
): { ancestorId: string; leg: MlmLeg }[] {
  const credits: { ancestorId: string; leg: MlmLeg }[] = [];
  for (let i = 0; i < path.length; i++) {
    const leg = i === path.length - 1 ? buyerLeg : legOf(path[i + 1]);
    if (leg) credits.push({ ancestorId: path[i], leg });
  }
  return credits;
}

/** When a pending order's CV starts counting: the sale's moment plus the plan's delay. */
export const eligibleAtFor = (paidAt: Date, delayDays: number): Date => new Date(paidAt.getTime() + delayDays * 86_400_000);

/* ─── Views ────────────────────────────────────────────────────────────── */

export interface MlmOrderRow {
  id: string;
  purchaseId: string;
  academy: { id: string; name: string; slug: string };
  buyer: { studentId: string; name: string; email: string; affiliateCode: string | null };
  sponsorCodeAtSale: string | null;
  course: { id: string; title: string };
  netAmount: number;
  cv: number;
  currency: string;
  status: MlmOrderStatus;
  planVersion: number;
  paidAt: string;
  eligibleAt: string | null;
  reversedAt: string | null;
  reversalReason: MlmReversalReason | null;
  /** How many ancestors were credited (0 for a buyer outside the program or not yet placed). */
  creditedAncestors: number;
}

export interface MlmOrderQuery {
  tenantId?: string;
  status?: MlmOrderStatus;
  search?: string;
  from?: string;
  to?: string;
  page?: number;
  pageSize?: number;
}

export interface MlmCvLedgerRow {
  id: string;
  affiliate: { id: string; code: string; name: string };
  leg: MlmLeg;
  kind: MlmCvKind;
  amount: number;
  order: { id: string; buyerName: string; courseTitle: string; status: MlmOrderStatus };
  createdAt: string;
}

export interface MlmCvQuery {
  affiliateId?: string;
  tenantId?: string;
  leg?: MlmLeg;
  kind?: MlmCvKind;
  from?: string;
  to?: string;
  page?: number;
  pageSize?: number;
}

/** An affiliate's leg pools: lifetime eligible CV per leg (ranks) and what is still unmatched (carry-forward). */
export interface MlmLegFigures {
  lifetimeA: number;
  lifetimeB: number;
  unmatchedA: number;
  unmatchedB: number;
  matchedLifetime: number;
  lastMatchingRunDate: string | null;
}

export interface MlmCarryForwardRow extends MlmLegFigures {
  affiliate: { id: string; code: string; name: string; status: string };
}

/** A signed correction to one leg's carry-forward, in minor units of CV. It moves the unmatched pool only: ranks are earned from sales. */
export interface MlmCarryAdjustInput {
  leg: MlmLeg;
  amount: number;
  reason: string;
}

/** The figures the affiliate's home shows (MLM-003: the volumes; later modules add income, rank and wallet). */
export interface AffiliateFigures extends MlmLegFigures {
  eligibleOrders: number;
  /** The weaker leg's unmatched CV: what the next matching run can pay on. */
  matchable: number;
  currency: string;
}
