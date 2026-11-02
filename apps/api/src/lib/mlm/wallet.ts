import {
  bpsOf,
  isBankAccount,
  isIfsc,
  isPan,
  istPeriod,
  periodBounds,
  withdrawalIssue,
  type MemberRef,
  type MlmDashboard,
  type MlmKycInput,
  type MlmKycRow,
  type MlmKycStatus,
  type MlmKycView,
  type MlmLiabilityReport,
  type MlmPayoutBatchRow,
  type MlmWalletEntryRow,
  type MlmWalletEntryType,
  type MlmWalletRow,
  type MlmWithdrawalRow,
  type MlmWithdrawalStatus,
  type Paged,
} from '@syniastrolms/domain';
import type { Prisma } from '@prisma/client';

import { recordAuditLog, type AuditActor } from '../audit.js';
import { openCredentials, sealCredentials, vaultConfigured } from '../credentialVault.js';
import { csvCell } from '../csv.js';
import { db } from '../db.js';
import { ApiError, badRequest, conflict, notFound } from '../errors.js';
import { readJson } from '../json.js';
import { notify } from '../notify.js';
import { observe } from '../observe.js';
import { runAsPlatform, tenant } from '../tenancy.js';
import { bigintToNumber, periodFigures, writeWalletEntry } from './earnings.js';
import { activeMlmPlan } from './plan.js';

/*
 * Wallets, KYC, withdrawals, payout batches and the company's reports (docs/15 §6.9; MLM-006, MLM-008). Balances are sums of
 * immutable entries, and MlmWallet is a cache a nightly check compares with them. PAN and bank account are sealed with the
 * credential vault (AES-256-GCM) and shown masked; only the bank file opens them, for the Super Admin, and the export is audited.
 */

export const MLM_WALLET_AUDIT = {
  adjusted: 'mlm.wallet.adjusted',
  requested: 'mlm.withdrawal.requested',
  cancelled: 'mlm.withdrawal.cancelled',
  documentRead: 'mlm.kyc.document_read',
  kycSubmitted: 'mlm.kyc.submitted',
  kycVerified: 'mlm.kyc.verified',
  kycRejected: 'mlm.kyc.rejected',
  approved: 'mlm.withdrawal.approved',
  rejected: 'mlm.withdrawal.rejected',
  paid: 'mlm.withdrawal.paid',
  batch: 'mlm.payout.created',
  exported: 'mlm.payout.exported',
  closed: 'mlm.payout.closed',
} as const;

const MEMBER = { select: { id: true, code: true, user: { select: { name: true } } } } as const;
const refOf = (a: { id: string; code: string; user: { name: string } }): MemberRef => ({ id: a.id, code: a.code, name: a.user.name });
const pageOf = (q: { page?: number; pageSize?: number }) => {
  const pageSize = Math.min(200, Math.max(1, q.pageSize ?? 20));
  const page = Math.max(1, q.page ?? 1);
  return { page, pageSize, skip: (page - 1) * pageSize, take: pageSize };
};

/* ─── Wallets ─── */

export async function walletEntries(affiliateId: string, q: { page?: number; pageSize?: number } = {}): Promise<Paged<MlmWalletEntryRow>> {
  const { page, pageSize, skip, take } = pageOf(q);
  const where = { affiliateId };
  const [rows, total] = await Promise.all([
    db.mlmWalletEntry.findMany({ where, orderBy: { createdAt: 'desc' }, skip, take }),
    db.mlmWalletEntry.count({ where }),
  ]);
  return {
    rows: rows.map((r) => ({
      id: r.id,
      type: r.type as MlmWalletEntryType,
      availableDelta: bigintToNumber(r.availableDelta),
      heldDelta: bigintToNumber(r.heldDelta),
      paidDelta: bigintToNumber(r.paidDelta),
      note: r.note,
      createdAt: r.createdAt.toISOString(),
    })),
    total,
    page,
    pageSize,
  };
}

export async function listWallets(q: { search?: string; page?: number; pageSize?: number } = {}): Promise<Paged<MlmWalletRow>> {
  const { page, pageSize, skip, take } = pageOf(q);
  const search = q.search?.trim();
  const where: Prisma.MlmWalletWhereInput = search
    ? { affiliate: { OR: [{ code: { contains: search.toUpperCase() } }, { user: { name: { contains: search } } }] } }
    : {};
  const [rows, total] = await Promise.all([
    db.mlmWallet.findMany({ where, orderBy: { updatedAt: 'desc' }, skip, take, include: { affiliate: MEMBER } }),
    db.mlmWallet.count({ where }),
  ]);
  const held = await db.mlmCommission.groupBy({
    by: ['affiliateId'],
    where: { status: 'held', affiliateId: { in: rows.map((r) => r.affiliateId) } },
    _sum: { amount: true },
  });
  const heldOf = new Map(held.map((h) => [h.affiliateId, bigintToNumber(h._sum.amount)]));
  return {
    rows: rows.map((r) => ({
      affiliate: refOf(r.affiliate),
      available: bigintToNumber(r.available),
      held: bigintToNumber(r.held),
      paid: bigintToNumber(r.paid),
      heldByPolicy: heldOf.get(r.affiliateId) ?? 0,
    })),
    total,
    page,
    pageSize,
  };
}

/** A signed correction with a reason. It writes a new entry and edits nothing. */
export async function adjustWallet(actor: AuditActor, affiliateId: string, amount: number, reason: string): Promise<void> {
  if (!(await db.affiliate.findUnique({ where: { id: affiliateId }, select: { id: true } }))) throw notFound('Affiliate not found.');
  await db.$transaction(async (tx) => {
    await writeWalletEntry(tx, affiliateId, { type: 'adjustment', availableDelta: amount, note: reason });
    await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.adjusted, targetType: 'mlm_wallet', targetId: affiliateId, meta: { amount, reason } }, tx);
  });
}

/** The nightly check: every cached balance against the sum of its entries, every lifetime pool against its ledger. Reports; never repairs. */
export async function reconcileWallets(): Promise<number> {
  let mismatches = 0;
  const sums = new Map(
    (await db.mlmWalletEntry.groupBy({ by: ['affiliateId'], _sum: { availableDelta: true, heldDelta: true, paidDelta: true } })).map((s) => [
      s.affiliateId,
      s._sum,
    ]),
  );
  const wallets = await db.mlmWallet.findMany();
  for (const id of new Set([...sums.keys(), ...wallets.map((w) => w.affiliateId)])) {
    const s = sums.get(id);
    const w = wallets.find((row) => row.affiliateId === id);
    if ((w?.available ?? 0n) !== (s?.availableDelta ?? 0n) || (w?.held ?? 0n) !== (s?.heldDelta ?? 0n) || (w?.paid ?? 0n) !== (s?.paidDelta ?? 0n)) {
      mismatches++;
      observe('mlm.wallet.mismatch', { affiliateId: id, ledger: 'wallet' });
    }
  }
  const credited = await db.mlmCvLedger.groupBy({ by: ['affiliateId', 'leg'], _sum: { amount: true } });
  const balances = new Map(
    (await db.mlmLegBalance.findMany({ select: { affiliateId: true, lifetimeA: true, lifetimeB: true } })).map((b) => [b.affiliateId, b]),
  );
  for (const row of credited) {
    const balance = balances.get(row.affiliateId);
    const pool = row.leg === 'A' ? balance?.lifetimeA : balance?.lifetimeB;
    const sum = row._sum.amount ?? 0n;
    // A reversal floors a pool at zero, so a ledger sum below zero and a pool at zero agree.
    if ((pool ?? 0n) !== (sum < 0n ? 0n : sum)) {
      mismatches++;
      observe('mlm.wallet.mismatch', { affiliateId: row.affiliateId, ledger: 'cv', leg: row.leg });
    }
  }
  return mismatches;
}

/* ─── KYC ─── */

const kycView = (row: {
  status: string;
  legalName: string;
  panLast4: string;
  bankAccountLast4: string;
  ifsc: string;
  accountHolder: string;
  upiId: string | null;
  rejectionReason: string | null;
  submittedAt: Date;
  reviewedAt: Date | null;
  documentIdsJson: string;
}): MlmKycView => ({
  status: row.status as MlmKycStatus,
  legalName: row.legalName,
  panLast4: row.panLast4,
  bankAccountLast4: row.bankAccountLast4,
  ifsc: row.ifsc,
  accountHolder: row.accountHolder,
  upiId: row.upiId,
  rejectionReason: row.rejectionReason,
  submittedAt: row.submittedAt.toISOString(),
  reviewedAt: row.reviewedAt?.toISOString() ?? null,
  documents: readJson<{ id: string; name: string }[]>(row.documentIdsJson, []),
});

const NO_KYC: MlmKycView = {
  status: 'none',
  legalName: '',
  panLast4: '',
  bankAccountLast4: '',
  ifsc: '',
  accountHolder: '',
  upiId: null,
  rejectionReason: null,
  submittedAt: null,
  reviewedAt: null,
  documents: [],
};

export async function ownKyc(affiliateId: string): Promise<MlmKycView> {
  const row = await db.mlmKyc.findUnique({ where: { affiliateId } });
  return row ? kycView(row) : NO_KYC;
}

/** Submit or resubmit. A change sends the record back for review, so a verified bank account cannot be swapped unseen. */
export async function submitKyc(actor: AuditActor, affiliateId: string, input: MlmKycInput): Promise<MlmKycView> {
  const pan = input.pan.trim().toUpperCase();
  const bankAccount = input.bankAccount.replace(/\s/g, '');
  const ifsc = input.ifsc.trim().toUpperCase();
  if (!isPan(pan)) throw badRequest('Enter your PAN as printed, such as ABCDE1234F.');
  if (!isBankAccount(bankAccount)) throw badRequest('Enter your bank account number, digits only.');
  if (!isIfsc(ifsc)) throw badRequest('Enter your bank’s IFSC, such as HDFC0001234.');
  if (!vaultConfigured()) throw new ApiError(503, 'Identity checks aren’t available yet. Please try again later.');
  const { cipher, keyId } = sealCredentials({ pan, bankAccount });
  // Only the member's own uploads, documents or images, can be attached.
  const { userId } = await db.affiliate.findUniqueOrThrow({ where: { id: affiliateId }, select: { userId: true } });
  const wanted = [...new Set(input.documentIds ?? [])];
  const assets = wanted.length
    ? await db.mediaAsset.findMany({
        where: { id: { in: wanted }, ownerUserId: userId, kind: { in: ['document', 'image'] } },
        select: { id: true, originalName: true },
      })
    : [];
  if (assets.length !== wanted.length) throw badRequest('Attach only files you uploaded yourself.');
  const data = {
    status: 'submitted',
    legalName: input.legalName.trim(),
    sealed: cipher,
    sealedKeyId: keyId,
    panLast4: pan.slice(-4),
    bankAccountLast4: bankAccount.slice(-4),
    ifsc,
    accountHolder: input.accountHolder.trim(),
    upiId: input.upiId?.trim() || null,
    documentIdsJson: JSON.stringify(assets.map((a) => ({ id: a.id, name: a.originalName }))),
    rejectionReason: null,
    submittedAt: new Date(),
    reviewedAt: null,
  };
  const row = await db.$transaction(async (tx) => {
    const saved = await tx.mlmKyc.upsert({ where: { affiliateId }, create: { ...tenant(), affiliateId, ...data }, update: data });
    await tx.affiliate.update({ where: { id: affiliateId }, data: { kycStatus: 'submitted' } });
    await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.kycSubmitted, targetType: 'mlm_kyc', targetId: affiliateId, meta: {} }, tx);
    return saved;
  });
  return kycView(row);
}

export async function listKyc(q: { status?: MlmKycStatus; page?: number; pageSize?: number } = {}): Promise<Paged<MlmKycRow>> {
  const { page, pageSize, skip, take } = pageOf(q);
  const where: Prisma.MlmKycWhereInput = q.status ? { status: q.status } : {};
  const [rows, total] = await Promise.all([
    db.mlmKyc.findMany({ where, orderBy: { submittedAt: 'asc' }, skip, take, include: { affiliate: MEMBER } }),
    db.mlmKyc.count({ where }),
  ]);
  return { rows: rows.map((r) => ({ ...kycView(r), affiliate: refOf(r.affiliate) })), total, page, pageSize };
}

/** One member's KYC for the Super Admin, masked as everywhere: the sealed PAN and account stay sealed. 404 when they submitted none. */
export async function memberKyc(affiliateId: string): Promise<MlmKycRow> {
  const row = await db.mlmKyc.findUnique({ where: { affiliateId }, include: { affiliate: MEMBER } });
  if (!row) throw notFound('This member has not submitted an identity check.');
  return { ...kycView(row), affiliate: refOf(row.affiliate) };
}

/** A document attached to a member's KYC, for the review. Anything else answers the same 404 as no file. */
export async function kycDocument(actor: AuditActor, affiliateId: string, assetId: string) {
  const row = await db.mlmKyc.findUnique({ where: { affiliateId }, select: { documentIdsJson: true } });
  const attached = readJson<{ id: string }[]>(row?.documentIdsJson ?? '[]', []).some((d) => d.id === assetId);
  if (!attached) throw notFound('File not found.');
  const asset = await db.mediaAsset.findUnique({ where: { id: assetId } });
  if (!asset) throw notFound('File not found.');
  await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.documentRead, targetType: 'mlm_kyc', targetId: affiliateId, meta: { assetId } });
  return asset;
}

export async function reviewKyc(actor: AuditActor, affiliateId: string, decision: { verified: true } | { verified: false; reason: string }): Promise<void> {
  const notice = await db.$transaction(async (tx) => {
    const row = await tx.mlmKyc.findUnique({ where: { affiliateId }, include: { affiliate: { select: { userId: true } } } });
    if (!row) throw notFound('This member has not submitted KYC.');
    if (row.status !== 'submitted') throw conflict('Only a submitted record can be reviewed.');
    const status = decision.verified ? 'verified' : 'rejected';
    await tx.mlmKyc.update({ where: { affiliateId }, data: { status, rejectionReason: decision.verified ? null : decision.reason, reviewedAt: new Date() } });
    await tx.affiliate.update({ where: { id: affiliateId }, data: { kycStatus: status } });
    await recordAuditLog(
      actor,
      {
        action: decision.verified ? MLM_WALLET_AUDIT.kycVerified : MLM_WALLET_AUDIT.kycRejected,
        targetType: 'mlm_kyc',
        targetId: affiliateId,
        meta: decision.verified ? {} : { reason: decision.reason },
      },
      tx,
    );
    return { userId: row.affiliate.userId, verified: decision.verified };
  });
  void notify({
    recipientUserId: notice.userId,
    category: 'system',
    title: notice.verified ? 'Your identity check is verified' : 'Your identity check needs changes',
    summary: notice.verified ? 'You can now request withdrawals.' : 'Open your KYC page to see what to change.',
    action: { label: 'Open KYC', to: '/affiliate/kyc' },
  }).catch(() => undefined);
}

/* ─── Withdrawals ─── */

const withdrawalRow = (r: Prisma.MlmWithdrawalGetPayload<{ include: { affiliate: typeof MEMBER } }>): MlmWithdrawalRow => ({
  id: r.id,
  affiliate: refOf(r.affiliate),
  amount: bigintToNumber(r.amount),
  tdsAmount: bigintToNumber(r.tdsAmount),
  netAmount: bigintToNumber(r.netAmount),
  status: r.status as MlmWithdrawalStatus,
  bank: readJson(r.bankSnapshotJson, { accountLast4: '', ifsc: '', accountHolder: '', upiId: null }),
  payoutBatchId: r.payoutBatchId,
  reference: r.reference,
  rejectionReason: r.rejectionReason,
  createdAt: r.createdAt.toISOString(),
  decidedAt: r.decidedAt?.toISOString() ?? null,
  paidAt: r.paidAt?.toISOString() ?? null,
});

export async function listWithdrawals(
  q: { affiliateId?: string; status?: MlmWithdrawalStatus; page?: number; pageSize?: number } = {},
): Promise<Paged<MlmWithdrawalRow>> {
  const { page, pageSize, skip, take } = pageOf(q);
  const where: Prisma.MlmWithdrawalWhereInput = { ...(q.affiliateId ? { affiliateId: q.affiliateId } : {}), ...(q.status ? { status: q.status } : {}) };
  const [rows, total] = await Promise.all([
    db.mlmWithdrawal.findMany({ where, orderBy: { createdAt: 'desc' }, skip, take, include: { affiliate: MEMBER } }),
    db.mlmWithdrawal.count({ where }),
  ]);
  return { rows: rows.map(withdrawalRow), total, page, pageSize };
}

/** The amount moves to held in the same transaction as the request. The bank details at this moment are what the bank file pays. */
export async function requestWithdrawal(actor: AuditActor, affiliateId: string, amount: number): Promise<MlmWithdrawalRow> {
  const plan = await activeMlmPlan();
  if (!plan) throw conflict('No affiliate plan is active.');
  return db.$transaction(async (tx) => {
    const [affiliate, kyc, wallet, open] = await Promise.all([
      tx.affiliate.findUniqueOrThrow({ where: { id: affiliateId }, select: { status: true } }),
      tx.mlmKyc.findUnique({ where: { affiliateId } }),
      tx.mlmWallet.findUnique({ where: { affiliateId } }),
      tx.mlmWithdrawal.count({ where: { affiliateId, status: { in: ['requested', 'approved', 'processing'] } } }),
    ]);
    const issue = withdrawalIssue({
      amount,
      available: bigintToNumber(wallet?.available),
      minAmount: plan.withdrawalMinAmount,
      active: affiliate.status === 'active',
      kycVerified: kyc?.status === 'verified',
      kycRequired: plan.withdrawalRequiresKyc,
      openRequest: open > 0,
    });
    if (issue) throw conflict(issue);
    if (!kyc) throw conflict('Add your bank details on the KYC page first.');
    const tds = bpsOf(amount, plan.tdsBps);
    const row = await tx.mlmWithdrawal.create({
      data: {
        ...tenant(),
        affiliateId,
        amount: BigInt(amount),
        tdsAmount: BigInt(tds),
        netAmount: BigInt(amount - tds),
        bankSnapshotJson: JSON.stringify({ accountLast4: kyc.bankAccountLast4, ifsc: kyc.ifsc, accountHolder: kyc.accountHolder, upiId: kyc.upiId }),
        sealed: kyc.sealed,
        sealedKeyId: kyc.sealedKeyId,
      },
      include: { affiliate: MEMBER },
    });
    await writeWalletEntry(tx, affiliateId, { type: 'withdrawal_hold', availableDelta: -amount, heldDelta: amount, withdrawalId: row.id });
    await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.requested, targetType: 'mlm_withdrawal', targetId: row.id, meta: { amount, tds } }, tx);
    return withdrawalRow(row);
  });
}

async function release(tx: Prisma.TransactionClient, row: { id: string; affiliateId: string; amount: bigint }, note: string) {
  const amount = bigintToNumber(row.amount);
  await writeWalletEntry(tx as never, row.affiliateId, { type: 'withdrawal_released', availableDelta: amount, heldDelta: -amount, withdrawalId: row.id, note });
}

/** Only the member, and only while nobody has decided it. */
export async function cancelWithdrawal(actor: AuditActor, affiliateId: string, id: string): Promise<void> {
  await db.$transaction(async (tx) => {
    const row = await tx.mlmWithdrawal.findFirst({ where: { id, affiliateId } });
    if (!row) throw notFound('Withdrawal not found.');
    if (row.status !== 'requested') throw conflict('This withdrawal has already been reviewed, so it can’t be cancelled here.');
    await tx.mlmWithdrawal.update({ where: { id }, data: { status: 'cancelled', decidedAt: new Date() } });
    await release(tx as never, row, 'Cancelled by the member.');
    await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.cancelled, targetType: 'mlm_withdrawal', targetId: id, meta: {} }, tx);
  });
}

export async function approveWithdrawal(actor: AuditActor, id: string): Promise<void> {
  await db.$transaction(async (tx) => {
    const row = await tx.mlmWithdrawal.findUnique({ where: { id } });
    if (!row) throw notFound('Withdrawal not found.');
    if (row.status !== 'requested') throw conflict('Only a requested withdrawal can be approved.');
    await tx.mlmWithdrawal.update({ where: { id }, data: { status: 'approved', decidedAt: new Date() } });
    await recordAuditLog(
      actor,
      { action: MLM_WALLET_AUDIT.approved, targetType: 'mlm_withdrawal', targetId: id, meta: { amount: bigintToNumber(row.amount) } },
      tx,
    );
  });
}

export async function rejectWithdrawal(actor: AuditActor, id: string, reason: string, notPaidConfirmed = false): Promise<void> {
  const userId = await db.$transaction(async (tx) => {
    const row = await tx.mlmWithdrawal.findUnique({ where: { id }, include: { affiliate: { select: { userId: true } } } });
    if (!row) throw notFound('Withdrawal not found.');
    if (!['requested', 'approved', 'processing'].includes(row.status)) throw conflict('This withdrawal is already closed.');
    if (row.payoutBatchId) {
      const batch = await tx.mlmPayoutBatch.findUniqueOrThrow({ where: { id: row.payoutBatchId } });
      if (batch.closedAt) throw conflict('Its payout batch is closed.');
      // Once the bank has the file, giving the money back could pay it twice: someone must have checked with the bank.
      if (batch.exportedAt && !notPaidConfirmed)
        throw conflict('This withdrawal is in a bank file that was exported. Check with the bank that it was not paid, then confirm.');
      await tx.mlmPayoutBatch.update({ where: { id: batch.id }, data: { count: { decrement: 1 }, total: { decrement: row.netAmount } } });
    }
    await tx.mlmWithdrawal.update({ where: { id }, data: { status: 'rejected', rejectionReason: reason, decidedAt: new Date(), payoutBatchId: null } });
    await release(tx as never, row, reason);
    await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.rejected, targetType: 'mlm_withdrawal', targetId: id, meta: { reason, notPaidConfirmed } }, tx);
    return row.affiliate.userId;
  });
  void notify({
    recipientUserId: userId,
    category: 'system',
    title: 'Your withdrawal was not approved',
    summary: 'The amount is back in your available balance.',
    action: { label: 'Open wallet', to: '/affiliate/wallet' },
  }).catch(() => undefined);
}

/** The company paid it by hand and enters the bank reference (D-MLM-16). There is no payout API. */
export async function markWithdrawalPaid(actor: AuditActor, id: string, reference: string): Promise<void> {
  const userId = await db.$transaction(async (tx) => {
    const row = await tx.mlmWithdrawal.findUnique({ where: { id }, include: { affiliate: { select: { userId: true } } } });
    if (!row) throw notFound('Withdrawal not found.');
    if (row.status !== 'approved' && row.status !== 'processing') throw conflict('Only an approved withdrawal can be marked paid.');
    const [net, tds] = [bigintToNumber(row.netAmount), bigintToNumber(row.tdsAmount)];
    await tx.mlmWithdrawal.update({ where: { id }, data: { status: 'paid', reference, paidAt: new Date() } });
    await writeWalletEntry(tx as never, row.affiliateId, { type: 'withdrawal_paid', heldDelta: -net, paidDelta: net, withdrawalId: id, note: reference });
    if (tds > 0) await writeWalletEntry(tx as never, row.affiliateId, { type: 'tds_debit', heldDelta: -tds, withdrawalId: id });
    await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.paid, targetType: 'mlm_withdrawal', targetId: id, meta: { reference, net, tds } }, tx);
    return row.affiliate.userId;
  });
  void notify({
    recipientUserId: userId,
    category: 'system',
    title: 'Your withdrawal was paid',
    summary: `Bank reference ${reference}.`,
    action: { label: 'Open wallet', to: '/affiliate/wallet' },
  }).catch(() => undefined);
}

/* ─── Payout batches ─── */

const batchRow = (b: { id: string; reference: string; count: number; total: bigint; createdAt: Date; closedAt: Date | null }): MlmPayoutBatchRow => ({
  id: b.id,
  reference: b.reference,
  count: b.count,
  total: bigintToNumber(b.total),
  createdAt: b.createdAt.toISOString(),
  closedAt: b.closedAt?.toISOString() ?? null,
});

export async function listPayoutBatches(): Promise<MlmPayoutBatchRow[]> {
  return (await db.mlmPayoutBatch.findMany({ orderBy: { createdAt: 'desc' }, take: 200 })).map(batchRow);
}

export async function createPayoutBatch(actor: AuditActor, withdrawalIds: string[]): Promise<MlmPayoutBatchRow> {
  return db.$transaction(async (tx) => {
    const rows = await tx.mlmWithdrawal.findMany({ where: { id: { in: withdrawalIds }, status: 'approved', payoutBatchId: null } });
    if (rows.length !== withdrawalIds.length) throw conflict('Every withdrawal in a batch must be approved and in no other batch.');
    const total = rows.reduce((sum, r) => sum + bigintToNumber(r.netAmount), 0);
    const batch = await tx.mlmPayoutBatch.create({
      data: {
        ...tenant(),
        reference: `PAYOUT-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Date.now().toString(36).toUpperCase()}`,
        count: rows.length,
        total: BigInt(total),
      },
    });
    await tx.mlmWithdrawal.updateMany({ where: { id: { in: withdrawalIds } }, data: { status: 'processing', payoutBatchId: batch.id } });
    await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.batch, targetType: 'mlm_payout', targetId: batch.id, meta: { count: rows.length, total } }, tx);
    return batchRow(batch);
  });
}

/** The bank file: the one place full account numbers are opened. Each export is audited. */
export async function payoutBatchCsv(actor: AuditActor, id: string): Promise<string> {
  const batch = await db.mlmPayoutBatch.findUnique({ where: { id } });
  if (!batch) throw notFound('Payout batch not found.');
  // Only what is still to pay: a row already paid in a second download would be a second payment.
  const rows = await db.mlmWithdrawal.findMany({ where: { payoutBatchId: id, status: 'processing' }, include: { affiliate: MEMBER } });
  const lines = ['batch,withdrawalId,memberCode,accountHolder,accountNumber,ifsc,upiId,netAmountRupees,tdsRupees,status'];
  for (const r of rows) {
    const bank = readJson<{ accountHolder?: string; ifsc?: string; upiId?: string | null }>(r.bankSnapshotJson, {});
    const account = openCredentials(r.sealed, r.sealedKeyId).bankAccount;
    lines.push(
      [
        batch.reference,
        r.id,
        r.affiliate.code,
        bank.accountHolder ?? '',
        account,
        bank.ifsc ?? '',
        bank.upiId ?? '',
        (bigintToNumber(r.netAmount) / 100).toFixed(2),
        (bigintToNumber(r.tdsAmount) / 100).toFixed(2),
        r.status,
      ]
        .map(csvCell)
        .join(','),
    );
  }
  await db.$transaction(async (tx) => {
    await tx.mlmPayoutBatch.update({ where: { id }, data: { exportedAt: new Date() } });
    await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.exported, targetType: 'mlm_payout', targetId: id, meta: { count: rows.length } }, tx);
  });
  return lines.join('\n') + '\n';
}

export async function closePayoutBatch(actor: AuditActor, id: string): Promise<void> {
  await db.$transaction(async (tx) => {
    const batch = await tx.mlmPayoutBatch.findUnique({ where: { id } });
    if (!batch) throw notFound('Payout batch not found.');
    if (batch.closedAt) throw conflict('This batch is already closed.');
    if (await tx.mlmWithdrawal.count({ where: { payoutBatchId: id, status: { not: 'paid' } } }))
      throw conflict('Mark every withdrawal in this batch paid or rejected first.');
    await tx.mlmPayoutBatch.update({ where: { id }, data: { closedAt: new Date() } });
    await recordAuditLog(actor, { action: MLM_WALLET_AUDIT.closed, targetType: 'mlm_payout', targetId: id, meta: {} }, tx);
  });
}

/* ─── Reports and the dashboard (§7.1) ─── */

export async function liabilityReport(period: string): Promise<MlmLiabilityReport> {
  const plan = await activeMlmPlan();
  const { from, to } = periodBounds(period);
  const [{ grossEligibleSales, accrued }, kinds, held, paidOut, wallets] = await Promise.all([
    periodFigures(db, period),
    db.mlmCommission.groupBy({ by: ['kind'], where: { period, status: 'paid_to_wallet' }, _sum: { amount: true } }),
    db.mlmCommission.aggregate({ where: { status: 'held' }, _sum: { amount: true } }),
    db.mlmWithdrawal.aggregate({ where: { status: 'paid', paidAt: { gte: from, lt: to } }, _sum: { netAmount: true } }),
    db.mlmWallet.aggregate({ _sum: { available: true, held: true } }),
  ]);
  const sumOf = (kind: string) => bigintToNumber(kinds.find((k) => k.kind === kind)?._sum.amount);
  const ceilingAmount = bpsOf(grossEligibleSales, plan?.payoutCeilingBps ?? 0);
  return {
    period,
    grossEligibleSales,
    ceilingAmount,
    normalAmount: bpsOf(grossEligibleSales, plan?.normalPayoutBps ?? 0),
    matchingPaid: sumOf('matching'),
    rewardsPaid: sumOf('rank_reward'),
    reversals: sumOf('reversal'),
    fieldPayout: accrued,
    payoutRatioBps: grossEligibleSales > 0 ? Math.round((accrued * 10_000) / grossEligibleSales) : 0,
    heldAmount: bigintToNumber(held._sum.amount),
    headroom: Math.max(0, ceilingAmount - accrued),
    withdrawalsPaid: bigintToNumber(paidOut._sum.netAmount),
    walletLiability: bigintToNumber(wallets._sum.available) + bigintToNumber(wallets._sum.held),
    currency: plan?.currency ?? 'INR',
  };
}

export function liabilityCsv(r: MlmLiabilityReport): string {
  const rows: [string, number | string][] = [
    ['period', r.period],
    ['grossEligibleSalesPaise', r.grossEligibleSales],
    ['ceilingAmountPaise', r.ceilingAmount],
    ['normalPlanningAmountPaise', r.normalAmount],
    ['matchingPaidPaise', r.matchingPaid],
    ['rewardsPaidPaise', r.rewardsPaid],
    ['reversalsPaise', r.reversals],
    ['fieldPayoutPaise', r.fieldPayout],
    ['payoutRatioBps', r.payoutRatioBps],
    ['heldPaise', r.heldAmount],
    ['headroomPaise', r.headroom],
    ['withdrawalsPaidPaise', r.withdrawalsPaid],
    ['walletLiabilityPaise', r.walletLiability],
  ];
  return 'figure,value\n' + rows.map(([k, v]) => `${k},${csvCell(v)}`).join('\n') + '\n';
}

export async function mlmDashboard(now = new Date()): Promise<MlmDashboard> {
  const jobs = await runAsPlatform('the dashboard reads job health', () =>
    db.jobLease.findMany({ where: { job: { startsWith: 'mlm-' } }, orderBy: { job: 'asc' } }),
  );
  const [groups, kyc, rewards, withdrawals, heldCommissions, last, period] = await Promise.all([
    db.affiliate.groupBy({ by: ['status'], _count: { _all: true } }),
    db.mlmKyc.count({ where: { status: 'submitted' } }),
    db.mlmReward.count({ where: { status: { in: ['qualified', 'approved', 'vesting', 'funded'] } } }),
    db.mlmWithdrawal.count({ where: { status: { in: ['requested', 'approved', 'processing'] } } }),
    db.mlmCommission.count({ where: { status: 'held' } }),
    db.mlmMatchingRun.aggregate({ _max: { runDate: true } }),
    liabilityReport(istPeriod(now)),
  ]);
  const count = (status: string) => groups.find((g) => g.status === status)?._count._all ?? 0;
  return {
    jobs: jobs.map((j) => ({ job: j.job, lastRunAt: j.lastRunAt?.toISOString() ?? null, lastOutcome: j.lastOutcome })),
    members: { total: groups.reduce((n, g) => n + g._count._all, 0), active: count('active'), pending: count('pending'), suspended: count('suspended') },
    queues: { kyc, rewards, withdrawals, heldCommissions },
    period,
    lastMatchingDate: last._max.runDate ?? null,
  };
}
