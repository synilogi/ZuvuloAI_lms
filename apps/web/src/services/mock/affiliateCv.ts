import {
  creditsAlongPath,
  type AffiliateFigures,
  type MlmCarryForwardRow,
  type MlmCvLedgerRow,
  type MlmCvQuery,
  type MlmLeg,
  type MlmLegFigures,
  type MlmOrderQuery,
  type MlmOrderRow,
  type MlmReversalReason,
} from '@syniastrolms/domain';
import { ServiceError, type CarryForwardResult, type CvLedgerResult, type OrderListResult } from '../contracts';
import { DEMO_ACADEMY, allNodes, byId, type MockNode } from './affiliateTree';
import { mockNowIso } from './clock';
import { courses } from './fixtures/catalog';

/*
 * The demo's sales (MLM-003): every active member of the demo genealogy bought the eligible course on the day they
 * activated, one suspended member's purchase was refunded, and one buyer outside the program bought it too. The
 * ledger is derived from those orders the way the API derives it — every ancestor credited in the leg the buyer
 * sits under — so the figures, the carry-forward pools and the ledger screens agree with the tree.
 */
const eligibleCourse = courses.find((c) => c.price && c.price.amount > 0) ?? courses[0];
const PRICE_MINOR = (eligibleCourse.price?.amount ?? 10_000) * 100;

interface MockOrder {
  id: string;
  purchaseId: string;
  buyer: MockNode | { id: null; name: string; email: string };
  sponsorCodeAtSale: string | null;
  status: MlmOrderRow['status'];
  paidAt: string;
  eligibleAt: string | null;
  reversedAt: string | null;
  reversalReason: MlmReversalReason | null;
  creditedAncestors: number;
}

const orders: MockOrder[] = [];
const ledger: MlmCvLedgerRow[] = [];

const legOf = (id: string): MlmLeg | null => byId(id).leg;

function credit(order: MockOrder, sign: 1 | -1, at: string): number {
  if (!('path' in order.buyer)) return 0;
  const buyer = order.buyer;
  const credits = creditsAlongPath(buyer.path, buyer.leg, legOf);
  for (const c of credits) {
    const a = byId(c.ancestorId);
    ledger.unshift({
      id: `cv-${ledger.length + 1}`,
      affiliate: { id: a.id, code: a.code, name: a.name },
      leg: c.leg,
      kind: sign > 0 ? 'sale' : 'reversal',
      amount: sign * PRICE_MINOR,
      order: { id: order.id, buyerName: buyer.name, courseTitle: eligibleCourse.title, status: sign > 0 ? 'eligible' : 'reversed' },
      createdAt: at,
    });
  }
  return credits.length;
}

function seeded(): MockOrder[] {
  if (orders.length) return orders;
  const nodes = allNodes();
  for (const n of nodes) {
    if (!n.activatedAt && n.status !== 'suspended') continue;
    const at = n.activatedAt ?? n.joinedAt;
    const order: MockOrder = {
      id: `ord-${orders.length + 1}`,
      purchaseId: `pur-${orders.length + 1}`,
      buyer: n,
      sponsorCodeAtSale: n.sponsorId ? byId(n.sponsorId).code : null,
      status: 'eligible',
      paidAt: at,
      eligibleAt: at,
      reversedAt: null,
      reversalReason: null,
      creditedAncestors: 0,
    };
    orders.push(order);
    order.creditedAncestors = credit(order, 1, at);
    if (n.status === 'suspended') {
      // Refunded a week after the sale: the credits were taken back.
      const later = new Date(Date.parse(at) + 7 * 86_400_000).toISOString();
      credit(order, -1, later);
      order.status = 'reversed';
      order.reversedAt = later;
      order.reversalReason = 'refund';
    }
  }
  // A learner outside the program: the sale counts, nobody is credited.
  const at = new Date(Date.parse(mockNowIso()) - 2 * 86_400_000).toISOString();
  orders.push({
    id: `ord-${orders.length + 1}`,
    purchaseId: `pur-${orders.length + 1}`,
    buyer: { id: null, name: 'Vikram Singh', email: 'vikram.singh@example.com' },
    sponsorCodeAtSale: null,
    status: 'eligible',
    paidAt: at,
    eligibleAt: at,
    reversedAt: null,
    reversalReason: null,
    creditedAncestors: 0,
  });
  ledger.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return orders;
}

const toRow = (o: MockOrder): MlmOrderRow => ({
  id: o.id,
  purchaseId: o.purchaseId,
  academy: DEMO_ACADEMY,
  buyer:
    'path' in o.buyer
      ? { studentId: `stu-${o.buyer.id}`, name: o.buyer.name, email: o.buyer.email, affiliateCode: o.buyer.code }
      : { studentId: 'stu-outside', name: o.buyer.name, email: o.buyer.email, affiliateCode: null },
  sponsorCodeAtSale: o.sponsorCodeAtSale,
  course: { id: eligibleCourse.id, title: eligibleCourse.title },
  netAmount: PRICE_MINOR,
  cv: PRICE_MINOR,
  currency: 'INR',
  status: o.status,
  planVersion: 1,
  paidAt: o.paidAt,
  eligibleAt: o.eligibleAt,
  reversedAt: o.reversedAt,
  reversalReason: o.reversalReason,
  creditedAncestors: o.creditedAncestors,
});

const page = <T>(rows: T[], query: { page?: number; pageSize?: number } = {}, size = 20) => {
  const pageSize = query.pageSize ?? size;
  const current = query.page ?? 1;
  return { rows: rows.slice((current - 1) * pageSize, current * pageSize), total: rows.length, page: current, pageSize };
};

const inRange = (iso: string, from?: string, to?: string) => (!from || iso >= from) && (!to || iso.slice(0, 10) <= to.slice(0, 10));

export function listOrders(query: MlmOrderQuery = {}): OrderListResult {
  const all = seeded()
    .map(toRow)
    .sort((a, b) => b.paidAt.localeCompare(a.paidAt));
  const search = query.search?.trim().toLowerCase();
  const matching = all.filter(
    (o) =>
      (!search ||
        o.buyer.name.toLowerCase().includes(search) ||
        o.buyer.email.toLowerCase().includes(search) ||
        (o.buyer.affiliateCode ?? '').toLowerCase().includes(search)) &&
      inRange(o.paidAt, query.from, query.to),
  );
  const counts = { all: matching.length, pending: 0, eligible: 0, reversed: 0 };
  for (const o of matching) counts[o.status]++;
  return { ...page(query.status ? matching.filter((o) => o.status === query.status) : matching, query), counts };
}

export function getOrder(id: string): MlmOrderRow {
  const order = seeded().find((o) => o.id === id);
  if (!order) throw new ServiceError('Affiliate order not found.', 'not-found');
  return toRow(order);
}

export function reverseOrder(id: string, reason: MlmReversalReason): MlmOrderRow {
  const order = seeded().find((o) => o.id === id);
  if (!order) throw new ServiceError('Affiliate order not found.', 'not-found');
  if (order.status === 'reversed') throw new ServiceError('This order is already reversed.', 'conflict');
  const now = mockNowIso();
  if (order.status === 'eligible') credit(order, -1, now);
  order.status = 'reversed';
  order.reversedAt = now;
  order.reversalReason = reason;
  return toRow(order);
}

export function listCvLedger(query: MlmCvQuery = {}): CvLedgerResult {
  seeded();
  return page(
    ledger.filter(
      (r) =>
        (!query.affiliateId || r.affiliate.id === query.affiliateId) &&
        (!query.leg || r.leg === query.leg) &&
        (!query.kind || r.kind === query.kind) &&
        inRange(r.createdAt, query.from, query.to),
    ),
    query,
  );
}

export function cvCsv(query: MlmCvQuery = {}): string {
  const rows = listCvLedger({ ...query, pageSize: 10_000 }).rows;
  return (
    [
      'createdAt,affiliateCode,affiliateName,leg,kind,amount,orderId,buyer,course,orderStatus',
      ...rows.map((r) =>
        [r.createdAt, r.affiliate.code, r.affiliate.name, r.leg, r.kind, r.amount, r.order.id, r.order.buyerName, r.order.courseTitle, r.order.status].join(
          ',',
        ),
      ),
    ].join('\n') + '\n'
  );
}

/** An affiliate's pools from the ledger: nothing has been matched yet in the demo, so unmatched equals lifetime. */
export function legFigures(affiliateId: string): MlmLegFigures {
  seeded();
  const f: MlmLegFigures = { lifetimeA: 0, lifetimeB: 0, unmatchedA: 0, unmatchedB: 0, matchedLifetime: 0, lastMatchingRunDate: null };
  for (const r of ledger) {
    if (r.affiliate.id !== affiliateId) continue;
    if (r.leg === 'A') {
      f.lifetimeA += r.amount;
      f.unmatchedA += r.amount;
    } else {
      f.lifetimeB += r.amount;
      f.unmatchedB += r.amount;
    }
  }
  return f;
}

export function affiliateFigures(affiliateId: string): AffiliateFigures {
  const f = legFigures(affiliateId);
  const eligibleOrders = new Set(ledger.filter((r) => r.affiliate.id === affiliateId && r.order.status === 'eligible').map((r) => r.order.id)).size;
  return { ...f, eligibleOrders, matchable: Math.min(f.unmatchedA, f.unmatchedB), currency: 'INR' };
}

export function listCarryForward(query: { search?: string; page?: number; pageSize?: number } = {}): CarryForwardResult {
  seeded();
  const search = query.search?.trim().toLowerCase();
  const rows: MlmCarryForwardRow[] = allNodes()
    .filter((n) => !search || n.name.toLowerCase().includes(search) || n.code.toLowerCase().includes(search))
    .map((n) => ({ affiliate: { id: n.id, code: n.code, name: n.name, status: n.status }, ...legFigures(n.id) }))
    .filter((r) => r.lifetimeA || r.lifetimeB)
    .sort((a, b) => b.unmatchedA + b.unmatchedB - (a.unmatchedA + a.unmatchedB));
  return page(rows, query);
}

/** For tests, and whenever the tree is rebuilt: the orders are derived again from it. */
export function resetCv() {
  orders.length = 0;
  ledger.length = 0;
}
