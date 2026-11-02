import {
  capBandForRank,
  istHour,
  istPeriod,
  matchingOutcome,
  nextDate,
  periodBounds,
  programDayEnd,
  programDay,
  rankProgress,
  ranksReached,
  splitByHeadroom,
  tierByOrder,
  type AffiliateEarnings,
  type MemberRef,
  type MlmCommissionKind,
  type MlmCommissionRow,
  type MlmCommissionStatus,
  type MlmMatchingRunRow,
  type MlmPlanTerms,
  type MlmRankHistoryRow,
  type MlmRewardKind,
  type MlmRewardRow,
  type MlmRewardStatus,
  type MlmWalletEntryType,
  type Paged,
} from '@syniastrolms/domain';
import type { Prisma } from '@prisma/client';

import { recordAuditLog, type AuditActor } from '../audit.js';
import { db, type DbClient } from '../db.js';
import { badRequest, conflict, notFound } from '../errors.js';
import { notify } from '../notify.js';
import { observe } from '../observe.js';
import { tenant } from '../tenancy.js';
import { activeMlmPlan } from './plan.js';

/*
 * The affiliate program's earnings engine (docs/15 §6.5 to §6.8; MLM-004, MLM-005, MLM-007). The only writer of
 * MlmMatchingRun, MlmCommission, MlmRankHistory and MlmReward, and of wallet credits through `writeWalletEntry`.
 *
 * Money moves in one direction only: verified CV → a matching run → a commission → the ceiling → a wallet entry. Each step is
 * idempotent on its own unique key and runs inside a transaction, so a crash or a second run changes nothing. Nothing is
 * computed from a rank's name, and every figure comes from the active plan version recorded on the row.
 */

export const MLM_EARNING_AUDIT = {
  held: 'mlm.commission.held',
  matchingRun: 'mlm.matching.run',
  released: 'mlm.commission.released',
  writtenOff: 'mlm.commission.written_off',
  approved: 'mlm.reward.approved',
  funded: 'mlm.reward.funded',
  paid: 'mlm.reward.paid',
  rejected: 'mlm.reward.rejected',
  rankRecalculated: 'mlm.rank.recalculated',
} as const;

export const bigintToNumber = (value: bigint | null | undefined): number => {
  const n = Number(value ?? 0n);
  if (!Number.isSafeInteger(n)) throw new Error('An affiliate amount is too large to read exactly.');
  return n;
};

/* ─── The wallet ledger ─── */

/** One immutable entry and the balances it moves, in the caller's transaction. */
export async function writeWalletEntry(
  tx: DbClient,
  affiliateId: string,
  entry: {
    type: MlmWalletEntryType;
    availableDelta?: number;
    heldDelta?: number;
    paidDelta?: number;
    commissionId?: string;
    withdrawalId?: string;
    note?: string;
  },
): Promise<void> {
  const availableDelta = entry.availableDelta ?? 0;
  const heldDelta = entry.heldDelta ?? 0;
  const paidDelta = entry.paidDelta ?? 0;
  await tx.mlmWalletEntry.create({
    data: {
      ...tenant(),
      affiliateId,
      type: entry.type,
      availableDelta: BigInt(availableDelta),
      heldDelta: BigInt(heldDelta),
      paidDelta: BigInt(paidDelta),
      commissionId: entry.commissionId ?? null,
      withdrawalId: entry.withdrawalId ?? null,
      note: entry.note ?? null,
    },
  });
  await tx.mlmWallet.upsert({
    where: { affiliateId },
    create: { ...tenant(), affiliateId, available: BigInt(availableDelta), held: BigInt(heldDelta), paid: BigInt(paidDelta) },
    update: {
      available: { increment: BigInt(availableDelta) },
      held: { increment: BigInt(heldDelta) },
      paid: { increment: BigInt(paidDelta) },
      updatedAt: new Date(),
    },
  });
}

/* ─── The ceiling (§6.7) ─── */

/** The period's sales and what has accrued against them. Worked out from the ledgers, so there is no second count to drift. */
export async function periodFigures(client: DbClient, period: string): Promise<{ grossEligibleSales: number; accrued: number }> {
  const { from, to } = periodBounds(period);
  const [sales, accrued] = await Promise.all([
    client.mlmOrder.aggregate({ where: { status: 'eligible', eligibleAt: { gte: from, lt: to } }, _sum: { netAmount: true } }),
    client.mlmCommission.aggregate({ where: { period, status: 'paid_to_wallet' }, _sum: { amount: true } }),
  ]);
  return { grossEligibleSales: bigintToNumber(sales._sum.netAmount), accrued: bigintToNumber(accrued._sum.amount) };
}

const CREDIT_TYPE: Partial<Record<MlmCommissionKind, MlmWalletEntryType>> = { matching: 'matching_credit', rank_reward: 'reward_credit' };

/**
 * An earning reaches the wallet as far as the period's ceiling allows. The excess is written as a held commission (the member
 * sees "held by payout policy") and nothing is ever silently dropped.
 */
export async function settleCommission(
  tx: DbClient,
  plan: MlmPlanTerms,
  input: { affiliateId: string; kind: 'matching' | 'rank_reward'; amount: number; runId?: string; rewardId?: string; now: Date },
): Promise<{ paid: number; held: number }> {
  const period = istPeriod(input.now);
  const { payNow, hold } = splitByHeadroom(input.amount, { ...(await periodFigures(tx, period)), ceilingBps: plan.payoutCeilingBps });
  const common = {
    ...tenant(),
    affiliateId: input.affiliateId,
    kind: input.kind,
    planVersionId: plan.id,
    runId: input.runId ?? null,
    rewardId: input.rewardId ?? null,
  };
  if (payNow > 0) {
    const row = await tx.mlmCommission.create({ data: { ...common, amount: BigInt(payNow), status: 'paid_to_wallet', period, settledAt: input.now } });
    await writeWalletEntry(tx, input.affiliateId, { type: CREDIT_TYPE[input.kind]!, availableDelta: payNow, commissionId: row.id });
  }
  if (hold > 0) {
    const row = await tx.mlmCommission.create({ data: { ...common, amount: BigInt(hold), status: 'held', holdReason: 'ceiling', heldPeriod: period } });
    await recordAuditLog(
      { type: 'system', job: 'mlm-ceiling' },
      { action: MLM_EARNING_AUDIT.held, targetType: 'mlm_commission', targetId: row.id, meta: { amount: hold, kind: input.kind, period } },
      tx,
    );
    observe('mlm.ceiling.hold', { affiliateId: input.affiliateId, kind: input.kind, held: hold, period });
  }
  return { paid: payNow, held: hold };
}

/**
 * Divides a held commission into two held rows with the same date, without changing any row's money: the original closes as
 * `split`. Returns the part first.
 */
async function splitHeld(
  tx: DbClient,
  row: {
    id: string;
    affiliateId: string;
    kind: string;
    amount: bigint;
    holdReason: string | null;
    heldPeriod: string | null;
    runId: string | null;
    rewardId: string | null;
    planVersionId: string;
    createdAt: Date;
  },
  part: number,
  now: Date,
): Promise<string> {
  const rest = bigintToNumber(row.amount) - part;
  await tx.mlmCommission.update({ where: { id: row.id }, data: { status: 'split', settledAt: now } });
  const held = {
    ...tenant(),
    affiliateId: row.affiliateId,
    kind: row.kind,
    status: 'held',
    holdReason: row.holdReason,
    heldPeriod: row.heldPeriod,
    runId: row.runId,
    rewardId: row.rewardId,
    planVersionId: row.planVersionId,
    splitFromId: row.id,
    createdAt: row.createdAt,
  };
  const first = await tx.mlmCommission.create({ data: { ...held, amount: BigInt(part) } });
  await tx.mlmCommission.create({ data: { ...held, amount: BigInt(rest) } });
  return first.id;
}

const RELEASE_BATCH = 200;

/**
 * Holds of active members, oldest first, for as long as this period's ceiling has room. A later hold never overtakes, and one
 * bigger than the room is divided so it cannot block the queue for months. A suspended member's holds wait without blocking anyone.
 */
export async function releaseHeldCommissions(now = new Date()): Promise<number> {
  const plan = await activeMlmPlan();
  if (!plan) return 0;
  const held = await db.mlmCommission.findMany({
    where: { status: 'held', affiliate: { status: 'active' } },
    orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    select: { id: true },
    take: RELEASE_BATCH,
  });
  let released = 0;
  for (const { id } of held) {
    const outcome = await db.$transaction(async (tx) => {
      const row = await tx.mlmCommission.findUnique({ where: { id } });
      if (!row || row.status !== 'held') return 'skipped' as const;
      const amount = bigintToNumber(row.amount);
      const { payNow } = splitByHeadroom(amount, { ...(await periodFigures(tx, istPeriod(now))), ceilingBps: plan.payoutCeilingBps });
      if (payNow <= 0) return 'full' as const;
      const target = payNow < amount ? await splitHeld(tx, row, payNow, now) : id;
      await releaseOne(tx, target, now);
      await recordAuditLog(
        { type: 'system', job: 'mlm-ceiling' },
        { action: MLM_EARNING_AUDIT.released, targetType: 'mlm_commission', targetId: target, meta: { automatic: true, amount: payNow } },
        tx,
      );
      return payNow < amount ? ('full' as const) : ('released' as const);
    });
    if (outcome === 'full') {
      released += 0;
      break;
    }
    if (outcome === 'released') released++;
  }
  return released;
}

async function releaseOne(tx: DbClient, id: string, now: Date): Promise<boolean> {
  const row = await tx.mlmCommission.findUnique({ where: { id } });
  if (!row || row.status !== 'held') return false;
  const amount = bigintToNumber(row.amount);
  await tx.mlmCommission.update({ where: { id }, data: { status: 'paid_to_wallet', period: istPeriod(now), settledAt: now } });
  await writeWalletEntry(tx, row.affiliateId, { type: CREDIT_TYPE[row.kind as MlmCommissionKind] ?? 'adjustment', availableDelta: amount, commissionId: id });
  return true;
}

/** The Super Admin releases one hold, even above the ceiling, with a reason. */
export async function releaseCommission(actor: AuditActor, id: string, reason: string, now = new Date()): Promise<void> {
  await db.$transaction(async (tx) => {
    if (!(await releaseOne(tx, id, now))) throw conflict('Only a held commission can be released.');
    await recordAuditLog(actor, { action: MLM_EARNING_AUDIT.released, targetType: 'mlm_commission', targetId: id, meta: { reason } }, tx);
  });
}

/** The Super Admin writes a hold off with a reason. The row stays, and the member can see it. */
export async function writeOffCommission(actor: AuditActor, id: string, reason: string, now = new Date()): Promise<void> {
  await db.$transaction(async (tx) => {
    const row = await tx.mlmCommission.findUnique({ where: { id } });
    if (!row) throw notFound('Commission not found.');
    if (row.status !== 'held') throw conflict('Only a held commission can be written off.');
    await tx.mlmCommission.update({ where: { id }, data: { status: 'written_off', settledAt: now } });
    await recordAuditLog(
      actor,
      { action: MLM_EARNING_AUDIT.writtenOff, targetType: 'mlm_commission', targetId: id, meta: { reason, amount: bigintToNumber(row.amount) } },
      tx,
    );
  });
}

async function requirePlan(): Promise<MlmPlanTerms> {
  const plan = await activeMlmPlan();
  if (!plan) throw conflict('No affiliate plan is active.');
  return plan;
}

/* ─── Ranks (§6.6) ─── */

/** New ranks for these members (or everyone with a balance): one history row per tier, ever, and its reward. Ranks are never lost. */
export async function evaluateRanks(affiliateIds?: string[], now = new Date()): Promise<number> {
  const plan = await activeMlmPlan();
  if (!plan) return 0;
  const balances = await db.mlmLegBalance.findMany({
    where: { ...(affiliateIds ? { affiliateId: { in: affiliateIds } } : {}), affiliate: { status: { not: 'terminated' } } },
    select: { affiliateId: true, lifetimeA: true, lifetimeB: true, affiliate: { select: { currentRankOrder: true } } },
  });
  let reached = 0;
  for (const b of balances) {
    // Most members have no new rank: decided from what is already read, so only a real change opens a transaction.
    const fresh = ranksReached(plan.tiers, bigintToNumber(b.lifetimeA), bigintToNumber(b.lifetimeB)).some((t) => t.order > b.affiliate.currentRankOrder);
    if (!fresh) continue;
    try {
      const out = await db.$transaction((tx) => evaluateOne(tx, plan, b.affiliateId, now));
      reached += out.count;
      if (out.notice)
        void notify({
          recipientUserId: out.notice.userId,
          category: 'system',
          title: `You reached ${out.notice.rank}`,
          summary: 'Your new rank is on your affiliate earnings page.',
          action: { label: 'See your earnings', to: '/affiliate/earnings' },
        }).catch(() => undefined);
    } catch (err) {
      observe('mlm.commission.failed', { affiliateId: b.affiliateId, job: 'mlm-ranks', error: (err as Error).message });
    }
  }
  return reached;
}

async function evaluateOne(
  tx: DbClient,
  plan: MlmPlanTerms,
  affiliateId: string,
  now: Date,
): Promise<{ count: number; notice?: { userId: string; rank: string } }> {
  const balance = await tx.mlmLegBalance.findUnique({ where: { affiliateId } });
  const affiliate = await tx.affiliate.findUniqueOrThrow({ where: { id: affiliateId }, select: { currentRankOrder: true, userId: true } });
  if (!balance) return { count: 0 };
  const [a, b] = [bigintToNumber(balance.lifetimeA), bigintToNumber(balance.lifetimeB)];
  const fresh = ranksReached(plan.tiers, a, b).filter((t) => t.order > affiliate.currentRankOrder);
  for (const tier of fresh) {
    const history = await tx.mlmRankHistory.create({
      data: {
        ...tenant(),
        affiliateId,
        tierOrder: tier.order,
        tierName: tier.name,
        lifetimeA: balance.lifetimeA,
        lifetimeB: balance.lifetimeB,
        planVersionId: plan.id,
        achievedAt: now,
      },
    });
    await tx.mlmReward.create({
      data: {
        ...tenant(),
        affiliateId,
        rankHistoryId: history.id,
        tierOrder: tier.order,
        tierName: tier.name,
        groupCv: BigInt(tier.groupCv),
        kind: tier.rewardKind,
        amount: BigInt(tier.rewardAmount),
        capAmount: tier.rewardCapAmount === null ? null : BigInt(tier.rewardCapAmount),
        vestingDays: tier.vestingDays,
      },
    });
  }
  if (!fresh.length) return { count: 0 };
  const top = fresh[fresh.length - 1];
  await tx.affiliate.update({ where: { id: affiliateId }, data: { currentRankOrder: top.order } });
  return { count: fresh.length, notice: { userId: affiliate.userId, rank: top.name } };
}

/* ─── Matching (§6.5) ─── */

async function matchOne(plan: MlmPlanTerms, affiliateId: string, runDate: string, now: Date): Promise<{ paid: number; held: number } | null> {
  return db.$transaction(async (tx) => {
    if (await tx.mlmMatchingRun.findUnique({ where: { affiliateId_runDate: { affiliateId, runDate } }, select: { id: true } })) return null;
    const balance = await tx.mlmLegBalance.findUniqueOrThrow({ where: { affiliateId } });
    const affiliate = await tx.affiliate.findUniqueOrThrow({ where: { id: affiliateId }, select: { status: true, currentRankOrder: true } });
    if (affiliate.status !== 'active') return null;
    const band = capBandForRank(plan, affiliate.currentRankOrder);
    if (!band) throw new Error('The active plan has no cap band for this rank.');
    // A past day in a catch-up sees only the volume that existed that day, so a missed day cannot pay caps for volume that came later.
    const later = { A: 0, B: 0 };
    const dayEnd = programDayEnd(runDate);
    if (dayEnd < now) {
      const arrived = await tx.mlmCvLedger.groupBy({ by: ['leg'], where: { affiliateId, createdAt: { gte: dayEnd } }, _sum: { amount: true } });
      for (const row of arrived) later[row.leg as 'A' | 'B'] = Math.max(0, bigintToNumber(row._sum.amount));
    }
    const availableA = Math.max(0, bigintToNumber(balance.unmatchedA) - later.A);
    const availableB = Math.max(0, bigintToNumber(balance.unmatchedB) - later.B);
    const out = matchingOutcome({ availableA, availableB, rateBps: plan.matchingRateBps, dailyCap: band.dailyCap, overflow: plan.capOverflowPolicy });
    if (out.matchedCv === 0) return null;
    const preview = splitByHeadroom(out.cappedIncome, { ...(await periodFigures(tx, istPeriod(now))), ceilingBps: plan.payoutCeilingBps });
    const run = await tx.mlmMatchingRun.create({
      data: {
        ...tenant(),
        affiliateId,
        runDate,
        planVersionId: plan.id,
        rankOrderAtRun: affiliate.currentRankOrder,
        capBandKey: band.key,
        availableA: BigInt(availableA),
        availableB: BigInt(availableB),
        matchedCv: BigInt(out.matchedCv),
        grossIncome: BigInt(out.grossIncome),
        dailyCap: BigInt(band.dailyCap),
        cappedIncome: BigInt(out.cappedIncome),
        flushedCv: BigInt(out.flushedCv),
        carryAAfter: BigInt(out.carryAAfter + later.A),
        carryBAfter: BigInt(out.carryBAfter + later.B),
        heldByCeiling: BigInt(preview.hold),
      },
    });
    // The balance's version guards against a credit landing between the read and this write.
    const moved = await tx.mlmLegBalance.updateMany({
      where: { affiliateId, version: balance.version },
      data: {
        unmatchedA: BigInt(out.carryAAfter + later.A),
        unmatchedB: BigInt(out.carryBAfter + later.B),
        // What actually left the pools: volume carried over the cap is matched on a later day, not counted twice.
        matchedLifetime: { increment: BigInt(availableA - out.carryAAfter) },
        lastMatchingRunDate: runDate,
        version: { increment: 1 },
      },
    });
    if (moved.count !== 1) throw conflict('The balance changed during the run. The next run picks it up.');
    return out.cappedIncome > 0
      ? settleCommission(tx, plan, { affiliateId, kind: 'matching', amount: out.cappedIncome, runId: run.id, now })
      : { paid: 0, held: 0 };
  });
}

/** One day's run for every active member with volume on both legs. A repeated run does nothing, and one member's failure stops only them. */
export async function runMatching(runDate: string, now = new Date()): Promise<{ matched: number; paid: number; held: number; failed: number }> {
  const plan = await activeMlmPlan();
  const totals = { matched: 0, paid: 0, held: 0, failed: 0 };
  if (!plan) return totals;
  const due = await db.mlmLegBalance.findMany({
    where: {
      unmatchedA: { gt: 0 },
      unmatchedB: { gt: 0 },
      affiliate: { status: 'active' },
      OR: [{ lastMatchingRunDate: null }, { lastMatchingRunDate: { lt: runDate } }],
    },
    select: { affiliateId: true },
  });
  for (const { affiliateId } of due) {
    try {
      const out = await matchOne(plan, affiliateId, runDate, now);
      if (out) {
        totals.matched++;
        totals.paid += out.paid;
        totals.held += out.held;
      }
    } catch (err) {
      totals.failed++;
      observe('mlm.commission.failed', { affiliateId, runDate, error: (err as Error).message });
    }
  }
  return totals;
}

/* The program's own progress, stored so a quiet day and a missed day cannot be confused. */
const MATCHED_THROUGH = 'matching-through';
const NIGHTLY = 'nightly-through';

async function readState(key: string): Promise<string | null> {
  const row = await db.mlmProgramState.findFirst({ where: { key }, select: { value: true } });
  return row?.value ?? null;
}

async function writeState(key: string, value: string): Promise<void> {
  const { tenantId } = tenant();
  await db.mlmProgramState.upsert({ where: { tenantId_key: { tenantId, key } }, create: { tenantId, key, value }, update: { value } });
}

export const matchedThrough = () => readState(MATCHED_THROUGH);

const CATCH_UP_DAYS = 30;

/**
 * Runs each day not yet completed, in order, up to `target`. The stored mark moves only over a day that finished for everyone,
 * so a member whose run failed is tried again, and a re-run of a finished day pays only members it missed.
 */
export async function runMatchingThrough(target: string, now = new Date()): Promise<{ matched: number; paid: number; held: number; failed: number }> {
  const totals = { matched: 0, paid: 0, held: 0, failed: 0 };
  await evaluateRanks(undefined, now);
  const through = await readState(MATCHED_THROUGH);
  const earliest = programDay(new Date(now.getTime() - CATCH_UP_DAYS * 86_400_000));
  let date = through && through < target ? nextDate(through) : target;
  if (date < earliest) date = earliest;
  for (; date <= target; date = nextDate(date)) {
    const out = await runMatching(date, now);
    totals.matched += out.matched;
    totals.paid += out.paid;
    totals.held += out.held;
    totals.failed += out.failed;
    if (out.failed > 0) break;
    if (!through || date > through) await writeState(MATCHED_THROUGH, date);
  }
  return totals;
}

/** The scheduler's job: once a day after the plan's hour, today's run and any days missed before it (§9). */
export async function runDueMatching(now = new Date()): Promise<number> {
  const plan = await activeMlmPlan();
  if (!plan || istHour(now) < plan.matchingRunHourIst) return 0;
  const today = programDay(now);
  const through = await readState(MATCHED_THROUGH);
  if (through === today) return 0;
  if (through && nextDate(through) < today) observe('mlm.job.behind', { job: 'mlm-matching', through, today });
  return (await runMatchingThrough(today, now)).matched;
}

/** Whether a nightly job has yet to run today; asking claims it, so it runs once a day. */
export async function claimNightly(now = new Date()): Promise<boolean> {
  const today = programDay(now);
  if ((await readState(NIGHTLY)) === today) return false;
  await writeState(NIGHTLY, today);
  return true;
}

/* ─── Reversals (§6.8) ─── */

/**
 * After a sale's CV is taken back. Volume that had already been matched cannot come out of the pool, so the income it earned is
 * taken back: at the rate this member actually received (income over matched volume, since a cap may have flushed volume that
 * paid nothing), first from holds that have not been paid, then from the wallet, which may go negative until later credits clear
 * it. It never exceeds what the member received. Unpaid rewards no longer earned are rejected, paid ones are flagged, and ranks
 * stay (D-MLM-11).
 */
export async function applyReversalEffects(
  tx: DbClient,
  plan: MlmPlanTerms,
  orderId: string,
  overMatched: { affiliateId: string; overMatchedCv: number }[],
  allCredited: string[],
  now: Date,
): Promise<void> {
  for (const { affiliateId, overMatchedCv } of overMatched) {
    if (overMatchedCv <= 0) continue;
    const runs = await tx.mlmMatchingRun.aggregate({ where: { affiliateId }, _sum: { cappedIncome: true, matchedCv: true } });
    const matched = bigintToNumber(runs._sum.matchedCv);
    if (matched <= 0) continue;
    let owed = Math.round((overMatchedCv * bigintToNumber(runs._sum.cappedIncome)) / matched);
    // Holds first: income that has not reached the wallet simply never will.
    const holds = await tx.mlmCommission.findMany({
      where: { affiliateId, kind: 'matching', status: 'held' },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    });
    for (const hold of holds) {
      if (owed <= 0) break;
      const size = bigintToNumber(hold.amount);
      const take = Math.min(size, owed);
      const target = take < size ? await splitHeld(tx, hold, take, now) : hold.id;
      await tx.mlmCommission.update({ where: { id: target }, data: { status: 'written_off', settledAt: now } });
      await recordAuditLog(
        { type: 'system', job: 'mlm-reversal' },
        {
          action: MLM_EARNING_AUDIT.writtenOff,
          targetType: 'mlm_commission',
          targetId: target,
          meta: { orderId, amount: take, reason: 'A sale was reversed.' },
        },
        tx,
      );
      owed -= take;
    }
    const net = await tx.mlmCommission.aggregate({
      where: { affiliateId, status: 'paid_to_wallet', kind: { in: ['matching', 'reversal'] } },
      _sum: { amount: true },
    });
    const income = Math.min(owed, Math.max(0, bigintToNumber(net._sum.amount)));
    if (income <= 0) continue;
    const row = await tx.mlmCommission.create({
      data: {
        ...tenant(),
        affiliateId,
        kind: 'reversal',
        amount: BigInt(-income),
        status: 'paid_to_wallet',
        period: istPeriod(now),
        orderId,
        planVersionId: plan.id,
        settledAt: now,
      },
    });
    await writeWalletEntry(tx, affiliateId, { type: 'reversal_debit', availableDelta: -income, commissionId: row.id, note: 'A sale was reversed.' });
  }
  for (const affiliateId of allCredited) {
    const balance = await tx.mlmLegBalance.findUnique({ where: { affiliateId }, select: { lifetimeA: true, lifetimeB: true } });
    if (!balance) continue;
    const [a, b] = [bigintToNumber(balance.lifetimeA), bigintToNumber(balance.lifetimeB)];
    const rewards = await tx.mlmReward.findMany({ where: { affiliateId, status: { not: 'rejected' } }, select: { id: true, status: true, groupCv: true } });
    for (const reward of rewards) {
      const leg = bigintToNumber(reward.groupCv) / 2;
      if (a >= leg && b >= leg) continue;
      if (reward.status === 'paid')
        await tx.mlmReward.update({
          where: { id: reward.id },
          data: { needsReview: true, note: 'Paid, but a reversal took the volume back below this rank.', updatedAt: now },
        });
      else
        await tx.mlmReward.update({
          where: { id: reward.id },
          data: { status: 'rejected', note: 'A reversal took the volume back below this rank.', updatedAt: now },
        });
    }
  }
}

/* ─── The reward workflow (§6.6) ─── */

const rewardOr404 = async (tx: DbClient, id: string) => {
  const row = await tx.mlmReward.findUnique({ where: { id }, include: { affiliate: { select: { userId: true } } } });
  if (!row) throw notFound('Reward not found.');
  return row;
};

/** Approval. Recognition and certificates finish here; cash vests for the tier's days. The amount of an "up to" reward is decided now. */
export async function approveReward(actor: AuditActor, id: string, chosen: number | undefined, now = new Date()) {
  await db.$transaction(async (tx) => {
    const row = await rewardOr404(tx, id);
    if (row.status !== 'qualified') throw conflict('Only a reward awaiting approval can be approved.');
    const cap = row.capAmount === null ? null : bigintToNumber(row.capAmount);
    let amount = bigintToNumber(row.amount);
    if (row.kind === 'cash' && cap !== null) {
      if (chosen === undefined || chosen < 1 || chosen > cap) throw badRequest('Enter the amount for this reward, up to its limit.');
      amount = chosen;
    } else if (chosen !== undefined) throw badRequest('This reward’s amount is fixed by the plan.');
    const cash = row.kind === 'cash';
    const vestsAt = cash && row.vestingDays > 0 ? new Date(now.getTime() + row.vestingDays * 86_400_000) : null;
    const status: MlmRewardStatus = !cash ? 'paid' : vestsAt ? 'vesting' : 'approved';
    await tx.mlmReward.update({ where: { id }, data: { status, amount: BigInt(amount), vestsAt, updatedAt: now } });
    await recordAuditLog(
      actor,
      { action: MLM_EARNING_AUDIT.approved, targetType: 'mlm_reward', targetId: id, meta: { amount, vestsAt: vestsAt?.toISOString() ?? null } },
      tx,
    );
  });
}

/** A person confirms the money is set aside. A vesting reward cannot be funded before its date. */
export async function fundReward(actor: AuditActor, id: string, now = new Date()) {
  await db.$transaction(async (tx) => {
    const row = await rewardOr404(tx, id);
    if (row.status !== 'approved' && row.status !== 'vesting') throw conflict('Only an approved reward can be funded.');
    if (row.vestsAt && row.vestsAt > now) throw conflict('This reward is still vesting.');
    await tx.mlmReward.update({ where: { id }, data: { status: 'funded', updatedAt: now } });
    await recordAuditLog(actor, { action: MLM_EARNING_AUDIT.funded, targetType: 'mlm_reward', targetId: id, meta: {} }, tx);
  });
}

/** Paid: a commission and a wallet credit, under the ceiling like every other earning. */
export async function payReward(actor: AuditActor, id: string, now = new Date()) {
  const plan = await requirePlan();
  await db.$transaction(async (tx) => {
    const row = await rewardOr404(tx, id);
    if (row.status !== 'funded') throw conflict('Only a funded reward can be paid.');
    const amount = bigintToNumber(row.amount);
    await settleCommission(tx, plan, { affiliateId: row.affiliateId, kind: 'rank_reward', amount, rewardId: id, now });
    await tx.mlmReward.update({ where: { id }, data: { status: 'paid', updatedAt: now } });
    await recordAuditLog(actor, { action: MLM_EARNING_AUDIT.paid, targetType: 'mlm_reward', targetId: id, meta: { amount } }, tx);
  });
}

export async function rejectReward(actor: AuditActor, id: string, reason: string, now = new Date()) {
  await db.$transaction(async (tx) => {
    const row = await rewardOr404(tx, id);
    if (row.status === 'paid' || row.status === 'rejected') throw conflict('This reward can no longer be rejected.');
    await tx.mlmReward.update({ where: { id }, data: { status: 'rejected', note: reason, updatedAt: now } });
    await recordAuditLog(actor, { action: MLM_EARNING_AUDIT.rejected, targetType: 'mlm_reward', targetId: id, meta: { reason } }, tx);
  });
}

/* ─── Reads ─── */

const MEMBER = { select: { id: true, code: true, user: { select: { name: true } } } } as const;
const refOf = (a: { id: string; code: string; user: { name: string } }): MemberRef => ({ id: a.id, code: a.code, name: a.user.name });
const pageOf = (q: { page?: number; pageSize?: number }) => {
  const pageSize = Math.min(200, Math.max(1, q.pageSize ?? 20));
  const page = Math.max(1, q.page ?? 1);
  return { page, pageSize, skip: (page - 1) * pageSize, take: pageSize };
};

export async function listMatchingRuns(q: { affiliateId?: string; date?: string; page?: number; pageSize?: number } = {}): Promise<Paged<MlmMatchingRunRow>> {
  const { page, pageSize, skip, take } = pageOf(q);
  const where: Prisma.MlmMatchingRunWhereInput = { ...(q.affiliateId ? { affiliateId: q.affiliateId } : {}), ...(q.date ? { runDate: q.date } : {}) };
  const [rows, total] = await Promise.all([
    db.mlmMatchingRun.findMany({ where, orderBy: [{ runDate: 'desc' }, { createdAt: 'desc' }], skip, take, include: { affiliate: MEMBER } }),
    db.mlmMatchingRun.count({ where }),
  ]);
  return {
    rows: rows.map((r) => ({
      id: r.id,
      affiliate: refOf(r.affiliate),
      runDate: r.runDate,
      rankOrderAtRun: r.rankOrderAtRun,
      availableA: bigintToNumber(r.availableA),
      availableB: bigintToNumber(r.availableB),
      matchedCv: bigintToNumber(r.matchedCv),
      grossIncome: bigintToNumber(r.grossIncome),
      dailyCap: bigintToNumber(r.dailyCap),
      cappedIncome: bigintToNumber(r.cappedIncome),
      flushedCv: bigintToNumber(r.flushedCv),
      carryAAfter: bigintToNumber(r.carryAAfter),
      carryBAfter: bigintToNumber(r.carryBAfter),
      heldByCeiling: bigintToNumber(r.heldByCeiling),
      createdAt: r.createdAt.toISOString(),
    })),
    total,
    page,
    pageSize,
  };
}

export async function listCommissions(
  q: { affiliateId?: string; status?: MlmCommissionStatus; page?: number; pageSize?: number } = {},
): Promise<Paged<MlmCommissionRow>> {
  const { page, pageSize, skip, take } = pageOf(q);
  const where: Prisma.MlmCommissionWhereInput = { ...(q.affiliateId ? { affiliateId: q.affiliateId } : {}), ...(q.status ? { status: q.status } : {}) };
  const [rows, total] = await Promise.all([
    db.mlmCommission.findMany({ where, orderBy: { createdAt: 'desc' }, skip, take, include: { affiliate: MEMBER } }),
    db.mlmCommission.count({ where }),
  ]);
  return {
    rows: rows.map((r) => ({
      id: r.id,
      affiliate: refOf(r.affiliate),
      kind: r.kind as MlmCommissionKind,
      amount: bigintToNumber(r.amount),
      status: r.status as MlmCommissionStatus,
      holdReason: r.holdReason,
      period: r.period,
      createdAt: r.createdAt.toISOString(),
      settledAt: r.settledAt?.toISOString() ?? null,
    })),
    total,
    page,
    pageSize,
  };
}

export async function listRankHistory(q: { affiliateId?: string; page?: number; pageSize?: number } = {}): Promise<Paged<MlmRankHistoryRow>> {
  const { page, pageSize, skip, take } = pageOf(q);
  const where: Prisma.MlmRankHistoryWhereInput = q.affiliateId ? { affiliateId: q.affiliateId } : {};
  const [rows, total] = await Promise.all([
    db.mlmRankHistory.findMany({ where, orderBy: { achievedAt: 'desc' }, skip, take, include: { affiliate: MEMBER } }),
    db.mlmRankHistory.count({ where }),
  ]);
  return {
    rows: rows.map((r) => ({
      id: r.id,
      affiliate: refOf(r.affiliate),
      tierOrder: r.tierOrder,
      tierName: r.tierName,
      lifetimeA: bigintToNumber(r.lifetimeA),
      lifetimeB: bigintToNumber(r.lifetimeB),
      achievedAt: r.achievedAt.toISOString(),
    })),
    total,
    page,
    pageSize,
  };
}

export async function listRewards(q: { affiliateId?: string; status?: MlmRewardStatus; page?: number; pageSize?: number } = {}): Promise<Paged<MlmRewardRow>> {
  const { page, pageSize, skip, take } = pageOf(q);
  const where: Prisma.MlmRewardWhereInput = { ...(q.affiliateId ? { affiliateId: q.affiliateId } : {}), ...(q.status ? { status: q.status } : {}) };
  const [rows, total] = await Promise.all([
    db.mlmReward.findMany({ where, orderBy: { createdAt: 'desc' }, skip, take, include: { affiliate: MEMBER } }),
    db.mlmReward.count({ where }),
  ]);
  return {
    rows: rows.map((r) => ({
      id: r.id,
      affiliate: refOf(r.affiliate),
      tierOrder: r.tierOrder,
      tierName: r.tierName,
      kind: r.kind as MlmRewardKind,
      amount: bigintToNumber(r.amount),
      capAmount: r.capAmount === null ? null : bigintToNumber(r.capAmount),
      status: r.status as MlmRewardStatus,
      vestsAt: r.vestsAt?.toISOString() ?? null,
      note: r.note,
      needsReview: r.needsReview,
      createdAt: r.createdAt.toISOString(),
    })),
    total,
    page,
    pageSize,
  };
}

/** The member's own earnings page: real figures to date, and the volume the next rank still needs. Never a projection. */
export async function affiliateEarnings(affiliateId: string): Promise<AffiliateEarnings> {
  const [plan, balance, affiliate, wallet, held, matching, rewards] = await Promise.all([
    activeMlmPlan(),
    db.mlmLegBalance.findUnique({ where: { affiliateId }, select: { lifetimeA: true, lifetimeB: true } }),
    db.affiliate.findUniqueOrThrow({ where: { id: affiliateId }, select: { currentRankOrder: true } }),
    db.mlmWallet.findUnique({ where: { affiliateId } }),
    db.mlmCommission.aggregate({ where: { affiliateId, status: 'held' }, _sum: { amount: true } }),
    db.mlmCommission.aggregate({ where: { affiliateId, status: 'paid_to_wallet', kind: { in: ['matching', 'reversal'] } }, _sum: { amount: true } }),
    db.mlmCommission.aggregate({ where: { affiliateId, status: 'paid_to_wallet', kind: 'rank_reward' }, _sum: { amount: true } }),
  ]);
  const [a, b] = [bigintToNumber(balance?.lifetimeA), bigintToNumber(balance?.lifetimeB)];
  return {
    wallet: {
      available: bigintToNumber(wallet?.available),
      held: bigintToNumber(wallet?.held),
      paid: bigintToNumber(wallet?.paid),
      heldByPolicy: bigintToNumber(held._sum.amount),
      currency: plan?.currency ?? 'INR',
    },
    progress: rankProgress(plan?.tiers ?? [], affiliate.currentRankOrder, a, b),
    lifetimeA: a,
    lifetimeB: b,
    matchingIncome: bigintToNumber(matching._sum.amount),
    rewardIncome: bigintToNumber(rewards._sum.amount),
  };
}

/** The rank definitions of the active version, for the Super Admin. */
export const activeTierOf = (plan: MlmPlanTerms, order: number) => tierByOrder(plan, order);
