import path from 'node:path';
import { Router, type NextFunction, type Request, type RequestHandler, type Response } from 'express';
import {
  isProgramDate,
  programDay,
  istPeriod,
  MLM_COMMISSION_STATUSES,
  MLM_KYC_STATUSES,
  MLM_REWARD_STATUSES,
  MLM_WITHDRAWAL_STATUSES,
} from '@syniastrolms/domain';

import { recordAuditLog } from '../lib/audit.js';
import { db } from '../lib/db.js';
import { asyncHandler, badRequest, conflict, notFound } from '../lib/errors.js';
import { contentDisposition, ensureUploadDir } from '../lib/media.js';
import {
  approveReward,
  evaluateRanks,
  fundReward,
  listCommissions,
  listMatchingRuns,
  listRankHistory,
  listRewards,
  payReward,
  rejectReward,
  releaseCommission,
  matchedThrough,
  MLM_EARNING_AUDIT,
  runMatchingThrough,
  writeOffCommission,
} from '../lib/mlm/earnings.js';
import { activeMlmPlan } from '../lib/mlm/plan.js';
import {
  adjustWallet,
  approveWithdrawal,
  closePayoutBatch,
  kycDocument,
  createPayoutBatch,
  liabilityCsv,
  liabilityReport,
  listKyc,
  listPayoutBatches,
  listWallets,
  listWithdrawals,
  markWithdrawalPaid,
  memberKyc,
  mlmDashboard,
  payoutBatchCsv,
  rejectWithdrawal,
  reviewKyc,
  walletEntries,
} from '../lib/mlm/wallet.js';
import { workspaceId } from '../lib/requestContext.js';
import { runInTenant } from '../lib/tenancy.js';
import { optionalEnum, paging, parseBody, parseQuery, searchText, z } from '../lib/validate.js';

/*
 * `/superadmin/affiliates/*`: the earnings half of the program's management (docs/15 §5.3; MLM-004 to MLM-008). Inside the
 * Super Admin router. Each route runs in the workspace, so the scoped ledgers read and stamp as everywhere else, while the
 * plan routes beside it keep their platform context. That is why this router has no router-wide middleware.
 */
export const superadminMlmEarningsRouter = Router();

const inWorkspace: RequestHandler = (_req: Request, _res: Response, next: NextFunction) => {
  workspaceId().then((id) => runInTenant(id, next), next);
};
const reasonBody = z.object({ reason: z.string().trim().min(3).max(500) }).strict();
const period = z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/);
const day = z.string().refine(isProgramDate, 'Enter a real date.');

const get = (path: string, handler: Parameters<typeof asyncHandler>[0]) => superadminMlmEarningsRouter.get(path, inWorkspace, asyncHandler(handler));
const post = (path: string, handler: Parameters<typeof asyncHandler>[0]) => superadminMlmEarningsRouter.post(path, inWorkspace, asyncHandler(handler));

get('/dashboard', async (_req, res) => {
  res.json(await mlmDashboard());
});

/* Matching and commissions. */
get('/matching/runs', async (req, res) => {
  res.json(await listMatchingRuns(parseQuery(req, z.object({ date: day.optional(), affiliateId: z.string().max(64).optional(), ...paging }))));
});
post('/matching/run', async (req, res) => {
  const { date } = parseBody(req, z.object({ date: day.optional() }).strict());
  const today = programDay(new Date());
  const target = date ?? today;
  if (target > today) throw badRequest('A matching run cannot be for a future date.');
  // A finished day is not run again by hand: a missed day is the only reason to go back.
  const through = await matchedThrough();
  if (target < today && through && target <= through) throw conflict('That day has already been run.');
  const totals = await runMatchingThrough(target);
  await recordAuditLog(req, { action: MLM_EARNING_AUDIT.matchingRun, targetType: 'mlm_matching', targetId: target, meta: totals });
  res.json(totals);
});
get('/commissions', async (req, res) => {
  res.json(
    await listCommissions(parseQuery(req, z.object({ status: optionalEnum(MLM_COMMISSION_STATUSES), affiliateId: z.string().max(64).optional(), ...paging }))),
  );
});
post('/commissions/:id/release', async (req, res) => {
  const { reason } = parseBody(req, reasonBody);
  await releaseCommission(req, req.params.id, reason);
  res.json({ ok: true });
});
post('/commissions/:id/write-off', async (req, res) => {
  const { reason } = parseBody(req, reasonBody);
  await writeOffCommission(req, req.params.id, reason);
  res.json({ ok: true });
});

/* Ranks and rewards. */
get('/ranks', async (_req, res) => {
  res.json((await activeMlmPlan())?.tiers ?? []);
});
get('/ranks/history', async (req, res) => {
  res.json(await listRankHistory(parseQuery(req, z.object({ affiliateId: z.string().max(64).optional(), ...paging }))));
});
post('/members/:id/rank/recalculate', async (req, res) => {
  if (!(await db.affiliate.findUnique({ where: { id: req.params.id }, select: { id: true } }))) throw notFound('Affiliate not found.');
  const reached = await evaluateRanks([req.params.id]);
  await recordAuditLog(req, { action: MLM_EARNING_AUDIT.rankRecalculated, targetType: 'affiliate', targetId: req.params.id, meta: { reached } });
  res.json({ reached });
});
get('/rewards', async (req, res) => {
  res.json(await listRewards(parseQuery(req, z.object({ status: optionalEnum(MLM_REWARD_STATUSES), affiliateId: z.string().max(64).optional(), ...paging }))));
});
post('/rewards/:id/approve', async (req, res) => {
  const { amount } = parseBody(req, z.object({ amount: z.number().int().min(1).max(Number.MAX_SAFE_INTEGER).optional() }).strict());
  await approveReward(req, req.params.id, amount);
  res.json({ ok: true });
});
post('/rewards/:id/fund', async (req, res) => {
  await fundReward(req, req.params.id);
  res.json({ ok: true });
});
post('/rewards/:id/pay', async (req, res) => {
  await payReward(req, req.params.id);
  res.json({ ok: true });
});
post('/rewards/:id/reject', async (req, res) => {
  const { reason } = parseBody(req, reasonBody);
  await rejectReward(req, req.params.id, reason);
  res.json({ ok: true });
});

/* Wallets. */
get('/wallets', async (req, res) => {
  res.json(await listWallets(parseQuery(req, z.object({ search: searchText, ...paging }))));
});
get('/wallets/:affiliateId', async (req, res) => {
  res.json(await walletEntries(req.params.affiliateId, parseQuery(req, z.object({ ...paging }))));
});
post('/wallets/:affiliateId/adjust', async (req, res) => {
  const { amount, reason } = parseBody(
    req,
    z
      .object({
        amount: z
          .number()
          .int()
          .min(-1e12)
          .max(1e12)
          .refine((n) => n !== 0, 'Enter an amount.'),
        reason: z.string().trim().min(3).max(500),
      })
      .strict(),
  );
  await adjustWallet(req, req.params.affiliateId, amount, reason);
  res.json({ ok: true });
});

/* KYC. */
get('/kyc', async (req, res) => {
  res.json(await listKyc(parseQuery(req, z.object({ status: optionalEnum(MLM_KYC_STATUSES), ...paging }))));
});
get('/kyc/:affiliateId', async (req, res) => {
  res.json(await memberKyc(req.params.affiliateId));
});
get('/kyc/:affiliateId/documents/:assetId', async (req, res) => {
  const asset = await kycDocument(req, req.params.affiliateId, req.params.assetId);
  await new Promise<void>((resolve, reject) =>
    res.sendFile(
      path.join(ensureUploadDir(), asset.storageName),
      {
        headers: {
          'Content-Type': asset.mime,
          'Content-Disposition': contentDisposition(asset.originalName),
          'X-Content-Type-Options': 'nosniff',
          'Cache-Control': 'no-store',
        },
        dotfiles: 'deny',
      },
      (err) => (err ? reject(err) : resolve()),
    ),
  ).catch((err: NodeJS.ErrnoException) => {
    if (err.code === 'ENOENT') throw notFound('File not found.');
    if (!res.headersSent) throw err;
  });
});
post('/kyc/:affiliateId/verify', async (req, res) => {
  await reviewKyc(req, req.params.affiliateId, { verified: true });
  res.json({ ok: true });
});
post('/kyc/:affiliateId/reject', async (req, res) => {
  const { reason } = parseBody(req, reasonBody);
  await reviewKyc(req, req.params.affiliateId, { verified: false, reason });
  res.json({ ok: true });
});

/* Withdrawals and payouts. */
get('/withdrawals', async (req, res) => {
  res.json(await listWithdrawals(parseQuery(req, z.object({ status: optionalEnum(MLM_WITHDRAWAL_STATUSES), ...paging }))));
});
post('/withdrawals/:id/approve', async (req, res) => {
  await approveWithdrawal(req, req.params.id);
  res.json({ ok: true });
});
post('/withdrawals/:id/reject', async (req, res) => {
  const { reason, notPaidConfirmed } = parseBody(
    req,
    z.object({ reason: z.string().trim().min(3).max(500), notPaidConfirmed: z.boolean().optional() }).strict(),
  );
  await rejectWithdrawal(req, req.params.id, reason, notPaidConfirmed);
  res.json({ ok: true });
});
post('/withdrawals/:id/paid', async (req, res) => {
  const { reference } = parseBody(req, z.object({ reference: z.string().trim().min(3).max(120) }).strict());
  await markWithdrawalPaid(req, req.params.id, reference);
  res.json({ ok: true });
});
get('/payouts', async (_req, res) => {
  res.json(await listPayoutBatches());
});
post('/payouts', async (req, res) => {
  const { withdrawalIds } = parseBody(req, z.object({ withdrawalIds: z.array(z.string().min(1).max(64)).min(1).max(500) }).strict());
  res.status(201).json(await createPayoutBatch(req, [...new Set(withdrawalIds)]));
});
get('/payouts/:id/export.csv', async (req, res) => {
  const csv = await payoutBatchCsv(req, req.params.id);
  res.type('text/csv').set('Content-Disposition', 'attachment; filename="payout-batch.csv"').set('Cache-Control', 'no-store').send(csv);
});
post('/payouts/:id/close', async (req, res) => {
  await closePayoutBatch(req, req.params.id);
  res.json({ ok: true });
});

/* Reports. */
get('/reports/liability', async (req, res) => {
  const q = parseQuery(req, z.object({ period: period.optional() }));
  res.json(await liabilityReport(q.period ?? istPeriod(new Date())));
});
get('/reports/export.csv', async (req, res) => {
  const q = parseQuery(req, z.object({ period: period.optional() }));
  res
    .type('text/csv')
    .set('Content-Disposition', 'attachment; filename="affiliate-liability.csv"')
    .send(liabilityCsv(await liabilityReport(q.period ?? istPeriod(new Date()))));
});
