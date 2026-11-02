import {
  creditsAlongPath,
  cvOfSale,
  eligibleAtFor,
  type AffiliateFigures,
  type AffiliateOrderRow,
  type MlmCarryAdjustInput,
  type MlmCarryForwardRow,
  type MlmCvLedgerRow,
  type MlmCvQuery,
  type MlmLeg,
  type MlmLegFigures,
  type MlmOrderQuery,
  type MlmOrderRow,
  type MlmOrderStatus,
  type MlmReversalReason,
} from '@syniastrolms/domain';
import type { CoursePurchase, Prisma } from '@prisma/client';

import { recordAuditLog, type AuditActor, type AuditSource } from '../audit.js';
import { csvCell } from '../csv.js';
import { db, type DbClient } from '../db.js';
import { conflict, notFound } from '../errors.js';
import { readJson } from '../json.js';
import { observe } from '../observe.js';
import { onCoursePurchaseChargedBack, onCoursePurchasePaid, onCoursePurchaseRefunded, onCoursePurchaseSettled } from '../purchaseHooks.js';
import { runAsPlatform, tenant } from '../tenancy.js';
import { activateAffiliate, programFor } from './affiliates.js';
import { applyReversalEffects, evaluateRanks } from './earnings.js';
import { activeMlmPlan, getMlmPlanVersion } from './plan.js';

/*
 * Orders and commissionable volume (MLM-003; docs/15 §6.4, §6.8) — the writer of MlmOrder, MlmCvLedger and
 * MlmLegBalance.
 *
 * A course purchase that settles (the gateway's own account of the payment, inside the settlement transaction) becomes
 * an order when the program runs on that academy and the course is eligible. It activates the buyer's affiliate
 * account, if they have one. Its CV starts counting after the plan's delay (0 = at once): one immutable ledger row per
 * ancestor on the buyer's placement path, in the leg of that ancestor the buyer sits under, and the ancestor's running
 * pools grow. The buyer's own node gets nothing; a buyer outside the program, or not yet placed, credits nobody until
 * placed (the eligibility job waits). A reversal writes the same credits negated and shrinks the pools, never below
 * zero. Every write is idempotent: an order per purchase, a ledger row per (order, ancestor, kind).
 */

export const CV_AUDIT_ACTIONS = { reversed: 'mlm.order.reversed', carryAdjusted: 'mlm.carry.adjusted' } as const;

const amount = (value: bigint): number => {
  const n = Number(value);
  if (!Number.isSafeInteger(n)) throw new Error('An affiliate CV amount is too large to read exactly.');
  return n;
};

/* ─── The settlement hook ──────────────────────────────────────────────── */

/** Records the order for a settled purchase of an eligible course, and activates the buyer's affiliate account. */
export async function recordMlmOrder(tx: DbClient, purchase: CoursePurchase): Promise<string | null> {
  // A bundle earns no volume (docs/17): its courses' shares never become orders, whatever the plan names later.
  if (purchase.bundlePurchaseId) return null;
  const plan = await runAsPlatform('the program academy is named by the active plan', () => activeMlmPlan());
  if (!plan || plan.programTenantId !== purchase.tenantId || !plan.eligibleCourseIds.includes(purchase.courseId)) return null;
  const existing = await tx.mlmOrder.findUnique({ where: { purchaseId: purchase.id }, select: { id: true } });
  if (existing) {
    // Activation is idempotent, and a first attempt may have stopped short of it.
    await activateAffiliate(tx, purchase.studentId, purchase.id);
    return existing.id;
  }
  const buyer = await tx.affiliate.findUnique({ where: { studentId: purchase.studentId }, select: { id: true, sponsorId: true } });
  const paidAt = purchase.paidAt ?? new Date();
  const order = await tx.mlmOrder.create({
    data: {
      ...tenant(),
      purchaseId: purchase.id,
      buyerAffiliateId: buyer?.id ?? null,
      sponsorAffiliateIdAtSale: buyer?.sponsorId ?? null,
      planVersionId: plan.id,
      netAmount: BigInt(purchase.amount),
      cv: BigInt(cvOfSale(purchase.amount, plan.cvBasisPoints)),
      currency: purchase.currency,
      status: 'pending',
      paidAt,
      eligibleAt: null,
    },
    select: { id: true },
  });
  await activateAffiliate(tx, purchase.studentId, purchase.id);
  observe('mlm.order.recorded', { orderId: order.id, purchaseId: purchase.id, tenantId: purchase.tenantId });
  return order.id;
}

/** Once the settlement has committed: with no delay, the order's CV counts at once (its ledger rows name the committed order). */
export async function creditSettledPurchase(purchase: CoursePurchase): Promise<void> {
  const order = await db.mlmOrder.findUnique({ where: { purchaseId: purchase.id }, select: { id: true, status: true } });
  if (!order || order.status !== 'pending') return;
  const plan = await runAsPlatform('the settled purchase reads the plan delay', () => activeMlmPlan());
  if (!plan || plan.cvEligibilityDelayDays !== 0) return;
  await db.$transaction((tx) => makeEligible(tx, order.id));
  await evaluateCredited(order.id);
}

/** Ranks are checked after each eligibility credit (§6.6). A failure here waits for the next run, which checks everyone. */
async function evaluateCredited(orderId: string): Promise<void> {
  const rows = await db.mlmCvLedger.findMany({ where: { orderId }, select: { affiliateId: true } });
  await evaluateRanks(rows.map((r) => r.affiliateId)).catch(() => undefined);
}

/** Registers the hook with course sales. Called once at boot (app.ts). */
export function installMlmPurchaseHook(): void {
  onCoursePurchasePaid((tx, purchase) => recordMlmOrder(tx, purchase).then(() => undefined));
  onCoursePurchaseSettled((purchase) => creditSettledPurchase(purchase));
  // A refunded sale takes its CV back (docs/16, D-PLAT-12): once, by the job rather than a person.
  onCoursePurchaseChargedBack(async (purchase, provider) => {
    const order = await orderOfPurchase(purchase.id);
    if (order && order.status !== 'reversed') await reverseMlmOrder({ type: 'provider', provider }, order.id, 'chargeback');
  });
  onCoursePurchaseRefunded(async (purchase) => {
    const order = await orderOfPurchase(purchase.id);
    if (order && order.status !== 'reversed') await reverseMlmOrder({ type: 'system', job: 'course-refund' }, order.id, 'refund');
  });
}

/* ─── Eligibility and credits ──────────────────────────────────────────── */

/** Volume a reversal could not take from a pool because it had already been matched, per member (§6.8). */
interface CreditResult {
  written: number;
  credited: string[];
  overMatched: { affiliateId: string; overMatchedCv: number }[];
}

/** Takes a sale's CV back from exactly who received it, on the leg it reached them, even if a member has moved since. */
async function debitFromLedger(tx: DbClient, orderId: string): Promise<CreditResult> {
  const sales = await tx.mlmCvLedger.findMany({ where: { orderId, kind: 'sale' }, select: { affiliateId: true, leg: true, amount: true } });
  const result: CreditResult = { written: 0, credited: [], overMatched: [] };
  for (const sale of sales) {
    const already = await tx.mlmCvLedger.findUnique({
      where: { orderId_affiliateId_kind: { orderId, affiliateId: sale.affiliateId, kind: 'reversal' } },
      select: { id: true },
    });
    if (already) continue;
    const cv = amount(sale.amount);
    await tx.mlmCvLedger.create({ data: { ...tenant(), affiliateId: sale.affiliateId, leg: sale.leg, orderId, kind: 'reversal', amount: BigInt(-cv) } });
    const balance = await tx.mlmLegBalance.findUniqueOrThrow({
      where: { affiliateId: sale.affiliateId },
      select: { lifetimeA: true, lifetimeB: true, unmatchedA: true, unmatchedB: true },
    });
    const lifetimeKey = sale.leg === 'A' ? 'lifetimeA' : 'lifetimeB';
    const unmatchedKey = sale.leg === 'A' ? 'unmatchedA' : 'unmatchedB';
    const pool = amount(balance[unmatchedKey]);
    result.overMatched.push({ affiliateId: sale.affiliateId, overMatchedCv: Math.max(0, cv - pool) });
    await tx.mlmLegBalance.update({
      where: { affiliateId: sale.affiliateId },
      data: {
        [lifetimeKey]: BigInt(Math.max(0, amount(balance[lifetimeKey]) - cv)),
        [unmatchedKey]: BigInt(Math.max(0, pool - cv)),
        version: { increment: 1 },
      },
    });
    result.credited.push(sale.affiliateId);
    result.written++;
  }
  return result;
}

async function creditAncestors(tx: DbClient, orderId: string, sign: 1 | -1): Promise<CreditResult> {
  const order = await tx.mlmOrder.findUniqueOrThrow({ where: { id: orderId }, select: { id: true, cv: true, buyerAffiliateId: true } });
  if (!order.buyerAffiliateId) return { written: 0, credited: [], overMatched: [] };
  const buyer = await tx.affiliate.findUniqueOrThrow({ where: { id: order.buyerAffiliateId }, select: { pathIdsJson: true, placementLeg: true } });
  const path = readJson<string[]>(buyer.pathIdsJson, []);
  const ancestors = path.length ? await tx.affiliate.findMany({ where: { id: { in: path } }, select: { id: true, placementLeg: true } }) : [];
  const legOf = new Map(ancestors.map((a) => [a.id, a.placementLeg as MlmLeg | null]));
  const credits = creditsAlongPath(path, buyer.placementLeg as MlmLeg | null, (id) => legOf.get(id) ?? null);
  const kind = sign > 0 ? 'sale' : 'reversal';
  const cv = amount(order.cv);
  let written = 0;
  const credited: string[] = [];
  const overMatched: CreditResult['overMatched'] = [];
  for (const { ancestorId, leg } of credits) {
    const already = await tx.mlmCvLedger.findUnique({ where: { orderId_affiliateId_kind: { orderId, affiliateId: ancestorId, kind } }, select: { id: true } });
    if (already) continue;
    await tx.mlmCvLedger.create({ data: { ...tenant(), affiliateId: ancestorId, leg, orderId, kind, amount: BigInt(sign * cv) } });
    const balance = await tx.mlmLegBalance.upsert({
      where: { affiliateId: ancestorId },
      create: { ...tenant(), affiliateId: ancestorId },
      update: {},
      select: { lifetimeA: true, lifetimeB: true, unmatchedA: true, unmatchedB: true },
    });
    const lifetimeKey = leg === 'A' ? 'lifetimeA' : 'lifetimeB';
    const unmatchedKey = leg === 'A' ? 'unmatchedA' : 'unmatchedB';
    const lifetime = Math.max(0, amount(balance[lifetimeKey]) + sign * cv);
    const unmatched = Math.max(0, amount(balance[unmatchedKey]) + sign * cv);
    if (sign < 0) overMatched.push({ affiliateId: ancestorId, overMatchedCv: Math.max(0, cv - amount(balance[unmatchedKey])) });
    credited.push(ancestorId);
    await tx.mlmLegBalance.update({
      where: { affiliateId: ancestorId },
      data: { [lifetimeKey]: BigInt(lifetime), [unmatchedKey]: BigInt(unmatched), version: { increment: 1 } },
    });
    written++;
  }
  return { written, credited, overMatched };
}

/** A pending order's CV starts counting: credits every ancestor, once. Needs a placed buyer. */
export async function makeEligible(tx: DbClient, orderId: string): Promise<boolean> {
  const order = await tx.mlmOrder.findUniqueOrThrow({ where: { id: orderId }, select: { status: true, buyerAffiliateId: true } });
  if (order.status !== 'pending') return false;
  if (order.buyerAffiliateId) {
    const buyer = await tx.affiliate.findUniqueOrThrow({ where: { id: order.buyerAffiliateId }, select: { placementParentId: true, sponsorId: true } });
    // A buyer with a sponsor who is not placed yet: wait for the placement job, so the credits reach the right legs.
    if (!buyer.placementParentId && buyer.sponsorId) return false;
  }
  const { written } = await creditAncestors(tx, orderId, 1);
  await tx.mlmOrder.update({ where: { id: orderId }, data: { status: 'eligible', eligibleAt: new Date(), creditedAncestors: written } });
  return true;
}

/** The scheduler's job: every pending order of the current academy whose delay has passed. */
export async function settleEligibleOrders(now = new Date()): Promise<number> {
  const plan = await runAsPlatform('the eligibility job reads the plan', () => activeMlmPlan());
  if (!plan) return 0;
  // Buyers still waiting for a position cannot be credited yet, so they do not take up the batch.
  const pending = await db.mlmOrder.findMany({
    where: { status: 'pending', OR: [{ buyerAffiliateId: null }, { buyerAffiliate: { OR: [{ placementParentId: { not: null } }, { sponsorId: null }] } }] },
    select: { id: true, paidAt: true, planVersionId: true },
    orderBy: { paidAt: 'asc' },
    take: 500,
  });
  const delays = new Map<string, number>([[plan.id, plan.cvEligibilityDelayDays]]);
  let done = 0;
  for (const order of pending) {
    try {
      // The delay is the one the sale was made under.
      if (!delays.has(order.planVersionId)) {
        const terms = await runAsPlatform('the eligibility job reads the sale’s plan', () => getMlmPlanVersion(order.planVersionId));
        delays.set(order.planVersionId, terms.cvEligibilityDelayDays);
      }
      if (eligibleAtFor(order.paidAt, delays.get(order.planVersionId)!) > now) continue;
      if (await db.$transaction((tx) => makeEligible(tx, order.id))) {
        done++;
        await evaluateCredited(order.id);
      }
    } catch (err) {
      observe('mlm.commission.failed', { orderId: order.id, job: 'mlm-cv-eligibility', error: (err as Error).message });
    }
  }
  return done;
}

/**
 * The net under the hooks, which never let a failure roll back a payment: a refunded or disputed sale whose volume was not taken
 * back, and a recent paid sale of an eligible course with no order, are put right here.
 */
export async function repairOrders(now = new Date()): Promise<number> {
  let repaired = 0;
  const unreversed = await db.coursePurchase.findMany({
    where: { OR: [{ refundedAt: { not: null } }, { chargebackAt: { not: null } }], mlmOrder: { status: { not: 'reversed' } } },
    select: { chargebackAt: true, mlmOrder: { select: { id: true } } },
    take: 100,
  });
  for (const row of unreversed) {
    try {
      await reverseMlmOrder({ type: 'system', job: 'mlm-repair' }, row.mlmOrder!.id, row.chargebackAt ? 'chargeback' : 'refund', 'Retried by the repair job.');
      repaired++;
    } catch (err) {
      observe('mlm.commission.failed', { orderId: row.mlmOrder!.id, job: 'mlm-repair', error: (err as Error).message });
    }
  }
  const plan = await runAsPlatform('the repair job reads the plan', () => activeMlmPlan());
  if (!plan?.eligibleCourseIds.length || !plan.activatedAt) return repaired;
  // Only recent sales: this mends a failed hook, and must not give volume to sales made before a course became eligible.
  const since = new Date(Math.max(Date.parse(plan.activatedAt), now.getTime() - 86_400_000));
  const missing = await db.coursePurchase.findMany({
    where: { courseId: { in: plan.eligibleCourseIds }, status: 'paid', refundedAt: null, chargebackAt: null, mlmOrder: null, bundlePurchaseId: null, paidAt: { gte: since } },
    take: 100,
  });
  for (const purchase of missing) {
    try {
      await db.$transaction((tx) => recordMlmOrder(tx, purchase));
      await creditSettledPurchase(purchase);
      repaired++;
    } catch (err) {
      observe('mlm.commission.failed', { purchaseId: purchase.id, job: 'mlm-repair', error: (err as Error).message });
    }
  }
  return repaired;
}

/** A refund, chargeback or a Super Admin's hand: the order's credits are negated, once. Runs in the academy's context. */
export async function reverseMlmOrder(who: AuditActor | AuditSource, orderId: string, reason: MlmReversalReason, note = ''): Promise<void> {
  const found = await db.mlmOrder.findUnique({ where: { id: orderId }, select: { planVersionId: true } });
  if (!found) throw notFound('Affiliate order not found.');
  // The plan the sale was made under, whatever is active now.
  const plan = await runAsPlatform('the reversal reads the sale’s plan', () => getMlmPlanVersion(found.planVersionId));
  await db.$transaction(async (tx) => {
    // Read here, so an order that became eligible a moment ago is not reversed as if it never had.
    const order = await tx.mlmOrder.findUniqueOrThrow({ where: { id: orderId }, select: { id: true, status: true, cv: true } });
    if (order.status === 'reversed') throw conflict('This order is already reversed.');
    const reversal = order.status === 'eligible' ? await debitFromLedger(tx, orderId) : { written: 0, credited: [], overMatched: [] };
    await tx.mlmOrder.update({ where: { id: orderId }, data: { status: 'reversed', reversedAt: new Date(), reversalReason: reason } });
    await applyReversalEffects(tx, plan, orderId, reversal.overMatched, reversal.credited, new Date());
    await recordAuditLog(
      who,
      {
        action: CV_AUDIT_ACTIONS.reversed,
        targetType: 'mlm_order',
        targetId: orderId,
        meta: { reason, note, cv: amount(order.cv), reversedCredits: reversal.written },
      },
      tx,
    );
  });
  observe('mlm.reversal', { orderId, reason });
}

/** The order of a purchase, if any — for a refund webhook to find what to reverse. */
export const orderOfPurchase = (purchaseId: string) => db.mlmOrder.findUnique({ where: { purchaseId }, select: { id: true, status: true, tenantId: true } });

/* ─── Reads ────────────────────────────────────────────────────────────── */

const ORDER = {
  id: true,
  purchaseId: true,
  tenantId: true,
  netAmount: true,
  cv: true,
  currency: true,
  status: true,
  paidAt: true,
  eligibleAt: true,
  reversedAt: true,
  reversalReason: true,
  creditedAncestors: true,
  buyerAffiliate: { select: { code: true } },
  planVersion: { select: { version: true } },
  tenant: { select: { id: true, name: true, slug: true } },
  purchase: {
    select: { studentId: true, course: { select: { id: true, title: true } }, student: { select: { user: { select: { name: true, email: true } } } } },
  },
} satisfies Prisma.MlmOrderSelect;
type OrderRow = Prisma.MlmOrderGetPayload<{ select: typeof ORDER }>;

async function toOrderRows(rows: OrderRow[]): Promise<MlmOrderRow[]> {
  const sponsorIds = [...new Set(rows.map((r) => r.id))];
  const sponsors = await db.mlmOrder.findMany({
    where: { id: { in: sponsorIds }, sponsorAffiliateIdAtSale: { not: null } },
    select: { id: true, sponsorAffiliateIdAtSale: true },
  });
  const sponsorAffiliates = await db.affiliate.findMany({
    where: { id: { in: sponsors.map((s) => s.sponsorAffiliateIdAtSale as string) } },
    select: { id: true, code: true },
  });
  const sponsorCode = new Map(sponsors.map((s) => [s.id, sponsorAffiliates.find((a) => a.id === s.sponsorAffiliateIdAtSale)?.code ?? null]));
  return rows.map((r) => ({
    id: r.id,
    purchaseId: r.purchaseId,
    academy: r.tenant,
    buyer: {
      studentId: r.purchase.studentId,
      name: r.purchase.student.user.name,
      email: r.purchase.student.user.email,
      affiliateCode: r.buyerAffiliate?.code ?? null,
    },
    sponsorCodeAtSale: sponsorCode.get(r.id) ?? null,
    course: r.purchase.course,
    netAmount: amount(r.netAmount),
    cv: amount(r.cv),
    currency: r.currency,
    status: r.status as MlmOrderStatus,
    planVersion: r.planVersion.version,
    paidAt: r.paidAt.toISOString(),
    eligibleAt: r.eligibleAt?.toISOString() ?? null,
    reversedAt: r.reversedAt?.toISOString() ?? null,
    reversalReason: r.reversalReason as MlmReversalReason | null,
    creditedAncestors: r.creditedAncestors,
  }));
}

export async function listOrders(
  query: MlmOrderQuery = {},
): Promise<{ rows: MlmOrderRow[]; total: number; page: number; pageSize: number; counts: Record<MlmOrderStatus | 'all', number> }> {
  const search = query.search?.trim();
  const where: Prisma.MlmOrderWhereInput = {
    ...(query.tenantId ? { tenantId: query.tenantId } : {}),
    ...(query.status ? { status: query.status } : {}),
    ...(query.from || query.to ? { paidAt: { ...(query.from ? { gte: new Date(query.from) } : {}), ...(query.to ? { lte: new Date(query.to) } : {}) } } : {}),
    ...(search
      ? {
          OR: [
            { buyerAffiliate: { code: { contains: search.toUpperCase() } } },
            { purchase: { student: { user: { name: { contains: search } } } } },
            { purchase: { course: { title: { contains: search } } } },
          ],
        }
      : {}),
  };
  const pageSize = Math.min(500, Math.max(1, query.pageSize ?? 20));
  const page = Math.max(1, query.page ?? 1);
  const [rows, total, groups] = await Promise.all([
    db.mlmOrder.findMany({ where, select: ORDER, orderBy: { paidAt: 'desc' }, skip: (page - 1) * pageSize, take: pageSize }),
    db.mlmOrder.count({ where }),
    db.mlmOrder.groupBy({ by: ['status'], where: query.tenantId ? { tenantId: query.tenantId } : {}, _count: { _all: true } }),
  ]);
  const counts = { all: 0, pending: 0, eligible: 0, reversed: 0 } as Record<MlmOrderStatus | 'all', number>;
  for (const g of groups) {
    counts[g.status as MlmOrderStatus] = g._count._all;
    counts.all += g._count._all;
  }
  return { rows: await toOrderRows(rows), total, page, pageSize, counts };
}

export async function orderDetail(id: string): Promise<MlmOrderRow> {
  const row = await db.mlmOrder.findUnique({ where: { id }, select: ORDER });
  if (!row) throw notFound('Affiliate order not found.');
  return (await toOrderRows([row]))[0];
}

export async function listCvLedger(query: MlmCvQuery = {}): Promise<{ rows: MlmCvLedgerRow[]; total: number; page: number; pageSize: number }> {
  const where: Prisma.MlmCvLedgerWhereInput = {
    ...(query.affiliateId ? { affiliateId: query.affiliateId } : {}),
    ...(query.tenantId ? { tenantId: query.tenantId } : {}),
    ...(query.leg ? { leg: query.leg } : {}),
    ...(query.kind ? { kind: query.kind } : {}),
    ...(query.from || query.to
      ? { createdAt: { ...(query.from ? { gte: new Date(query.from) } : {}), ...(query.to ? { lte: new Date(query.to) } : {}) } }
      : {}),
  };
  const pageSize = Math.min(500, Math.max(1, query.pageSize ?? 50));
  const page = Math.max(1, query.page ?? 1);
  const [rows, total] = await Promise.all([
    db.mlmCvLedger.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * pageSize,
      take: pageSize,
      select: {
        id: true,
        leg: true,
        kind: true,
        amount: true,
        createdAt: true,
        affiliate: { select: { id: true, code: true, user: { select: { name: true } } } },
        order: {
          select: {
            id: true,
            status: true,
            purchase: { select: { course: { select: { title: true } }, student: { select: { user: { select: { name: true } } } } } },
          },
        },
      },
    }),
    db.mlmCvLedger.count({ where }),
  ]);
  return {
    rows: rows.map((r) => ({
      id: r.id,
      affiliate: { id: r.affiliate.id, code: r.affiliate.code, name: r.affiliate.user.name },
      leg: r.leg as MlmLeg,
      kind: r.kind as MlmCvLedgerRow['kind'],
      amount: amount(r.amount),
      order: {
        id: r.order.id,
        buyerName: r.order.purchase.student.user.name,
        courseTitle: r.order.purchase.course.title,
        status: r.order.status as MlmOrderStatus,
      },
      createdAt: r.createdAt.toISOString(),
    })),
    total,
    page,
    pageSize,
  };
}

const figuresOf = (
  b: { lifetimeA: bigint; lifetimeB: bigint; unmatchedA: bigint; unmatchedB: bigint; matchedLifetime: bigint; lastMatchingRunDate: string | null } | null,
): MlmLegFigures => ({
  lifetimeA: b ? amount(b.lifetimeA) : 0,
  lifetimeB: b ? amount(b.lifetimeB) : 0,
  unmatchedA: b ? amount(b.unmatchedA) : 0,
  unmatchedB: b ? amount(b.unmatchedB) : 0,
  matchedLifetime: b ? amount(b.matchedLifetime) : 0,
  lastMatchingRunDate: b?.lastMatchingRunDate ?? null,
});

export async function legFigures(affiliateId: string): Promise<MlmLegFigures> {
  return figuresOf(await db.mlmLegBalance.findUnique({ where: { affiliateId } }));
}

/** The affiliate's own volumes for the home page. */
export async function affiliateFigures(affiliateId: string): Promise<AffiliateFigures> {
  const [figures, eligibleOrders, plan] = await Promise.all([
    legFigures(affiliateId),
    db.mlmCvLedger.count({ where: { affiliateId, kind: 'sale' } }),
    runAsPlatform('the affiliate figures name the plan currency', () => activeMlmPlan()),
  ]);
  return { ...figures, eligibleOrders, matchable: Math.min(figures.unmatchedA, figures.unmatchedB), currency: plan?.currency ?? 'INR' };
}

export async function listCarryForward(
  query: { tenantId?: string; search?: string; page?: number; pageSize?: number } = {},
): Promise<{ rows: MlmCarryForwardRow[]; total: number; page: number; pageSize: number }> {
  const search = query.search?.trim();
  const where: Prisma.MlmLegBalanceWhereInput = {
    ...(query.tenantId ? { tenantId: query.tenantId } : {}),
    ...(search ? { affiliate: { OR: [{ code: { contains: search.toUpperCase() } }, { user: { name: { contains: search } } }] } } : {}),
  };
  const pageSize = Math.min(500, Math.max(1, query.pageSize ?? 20));
  const page = Math.max(1, query.page ?? 1);
  const [rows, total] = await Promise.all([
    db.mlmLegBalance.findMany({
      where,
      orderBy: { updatedAt: 'desc' },
      skip: (page - 1) * pageSize,
      take: pageSize,
      include: { affiliate: { select: { id: true, code: true, status: true, user: { select: { name: true } } } } },
    }),
    db.mlmLegBalance.count({ where }),
  ]);
  return {
    rows: rows.map((b) => ({
      ...figuresOf(b),
      affiliate: { id: b.affiliate.id, code: b.affiliate.code, name: b.affiliate.user.name, status: b.affiliate.status },
    })),
    total,
    page,
    pageSize,
  };
}

/**
 * A Super Admin's signed correction to one leg's carry-forward (docs/15 §5.3). The CV ledger needs an order, so this moves
 * the unmatched pool and the audit row is the record: before, after, who and why, written together or not at all. Refused
 * below zero. `lifetime` is left alone: ranks are earned from sales, and the nightly check holds it to the ledger.
 * Runs in the affiliate's academy context.
 */
export async function adjustCarryForward(actor: AuditActor, affiliateId: string, input: MlmCarryAdjustInput): Promise<MlmLegFigures> {
  const key = input.leg === 'A' ? 'unmatchedA' : 'unmatchedB';
  await db.$transaction(async (tx) => {
    const balance = await tx.mlmLegBalance.upsert({
      where: { affiliateId },
      create: { ...tenant(), affiliateId },
      update: {},
      select: { unmatchedA: true, unmatchedB: true, version: true },
    });
    const before = amount(balance[key]);
    const after = before + input.amount;
    if (after < 0) throw conflict(`Leg ${input.leg} holds ${(before / 100).toLocaleString('en-IN')} CV, so that correction would take it below zero.`);
    // The version guards against a credit or a matching run landing between the read and this write.
    const moved = await tx.mlmLegBalance.updateMany({
      where: { affiliateId, version: balance.version },
      data: { [key]: BigInt(after), version: { increment: 1 } },
    });
    if (moved.count !== 1) throw conflict('This member’s volume just changed. Check the figures and try again.');
    await recordAuditLog(
      actor,
      {
        action: CV_AUDIT_ACTIONS.carryAdjusted,
        targetType: 'affiliate',
        targetId: affiliateId,
        meta: { leg: input.leg, cvChange: input.amount, before, after, reason: input.reason },
      },
      tx,
    );
  });
  return legFigures(affiliateId);
}

/** A member's own paid purchases of eligible courses, newest first: those the active plan names, and any that made an order under an earlier list. */
export async function affiliateOrders(
  affiliate: { studentId: string; tenantId: string },
  query: { page?: number; pageSize?: number } = {},
): Promise<{ rows: AffiliateOrderRow[]; total: number; page: number; pageSize: number }> {
  const plan = await programFor(affiliate.tenantId);
  const where: Prisma.CoursePurchaseWhereInput = {
    studentId: affiliate.studentId,
    status: 'paid',
    OR: [{ courseId: { in: plan?.eligibleCourseIds ?? [] } }, { mlmOrder: { isNot: null } }],
  };
  const pageSize = Math.min(100, Math.max(1, query.pageSize ?? 20));
  const page = Math.max(1, query.page ?? 1);
  const [rows, total] = await Promise.all([
    db.coursePurchase.findMany({
      where,
      orderBy: { paidAt: 'desc' },
      skip: (page - 1) * pageSize,
      take: pageSize,
      select: {
        id: true,
        orderNumber: true,
        amount: true,
        currency: true,
        paidAt: true,
        status: true,
        refundedAt: true,
        chargebackAt: true,
        course: { select: { id: true, title: true } },
      },
    }),
    db.coursePurchase.count({ where }),
  ]);
  return {
    rows: rows.map((r) => ({
      id: r.id,
      course: r.course,
      orderNumber: r.orderNumber,
      amount: r.amount,
      currency: r.currency,
      paidAt: r.paidAt?.toISOString() ?? null,
      status: r.status,
      refunded: r.refundedAt !== null,
      chargedBack: r.chargebackAt !== null,
    })),
    total,
    page,
    pageSize,
  };
}

/** The ledger as CSV, for the Super Admin's export. */
export async function cvLedgerCsv(query: MlmCvQuery = {}): Promise<string> {
  const rows: MlmCvLedgerRow[] = [];
  for (let page = 1; ; page++) {
    const chunk = await listCvLedger({ ...query, page, pageSize: 500 });
    rows.push(...chunk.rows);
    if (rows.length >= chunk.total || chunk.rows.length === 0) break;
  }
  const lines = ['affiliateCode,affiliateName,leg,kind,amountPaise,orderId,buyer,course,orderStatus,createdAt'];
  for (const r of rows)
    lines.push(
      [r.affiliate.code, r.affiliate.name, r.leg, r.kind, r.amount, r.order.id, r.order.buyerName, r.order.courseTitle, r.order.status, r.createdAt]
        .map(csvCell)
        .join(','),
    );
  return lines.join('\n') + '\n';
}
