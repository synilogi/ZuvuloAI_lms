import { MLM_KYC_MAX_DOCUMENTS } from '@syniastrolms/domain';
import { affiliateEarnings, listCommissions, listMatchingRuns, listRankHistory, listRewards } from '../lib/mlm/earnings.js';
import { cancelWithdrawal, listWithdrawals, ownKyc, requestWithdrawal, submitKyc, walletEntries } from '../lib/mlm/wallet.js';
import { Router } from 'express';
import { MLM_LEGS, type MlmLeg } from '@syniastrolms/domain';
import { requireAuth, requireRole } from '../lib/auth.js';
import { asyncHandler, forbidden } from '../lib/errors.js';
import { parseBody, z } from '../lib/validate.js';
import { MLM_TREE_MAX_DEPTH, AFFILIATE_STATUSES, type AffiliateStatus } from '@syniastrolms/domain';
import { optionalEnum, paging, parseQuery, searchText } from '../lib/validate.js';
import { affiliateActivation, affiliateMe, enrolAffiliate, requireAffiliate, setPreferredLeg } from '../lib/mlm/affiliates.js';
import { db } from '../lib/db.js';
import { notFound } from '../lib/errors.js';
import { directReferrals, subtree, team } from '../lib/mlm/tree.js';
import { affiliateFigures, affiliateOrders, listCvLedger } from '../lib/mlm/cv.js';

/*
 * `/affiliate/*` — the signed-in affiliate's own records (docs/15 §5.2). A learner's surface: staff are refused, and
 * every read is of the caller's own row. MLM-001 brings identity, referral and activation; later modules add the
 * dashboard, tree, team, ledgers, ranks, rewards, wallet, KYC and withdrawals here.
 */
export const affiliateRouter = Router();

// A learner's surface: `requireRole` lets an academy admin through everywhere else, but an admin is not an affiliate.
affiliateRouter.use(requireAuth, requireRole('student'), (req, _res, next) =>
  next(req.auth!.role === 'student' ? undefined : forbidden('Only a learner can be an affiliate.')),
);

const referralCode = z.string().trim().max(16).optional();
const leg = z.enum(MLM_LEGS as unknown as [MlmLeg, ...MlmLeg[]]);

/** The caller's affiliate record — `{ affiliate: null }` for a learner who has not joined the program (a probe, not an error). */
affiliateRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    res.json({ affiliate: await affiliateMe(req.auth!) });
  }),
);

/** A learner already in the academy opts in, with a sponsor's code or none. */
affiliateRouter.post(
  '/enrol',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ referralCode, preferredLeg: leg.optional(), requestedLeg: leg.optional() }));
    res.status(201).json(await enrolAffiliate(req as never, input));
  }),
);

affiliateRouter.patch(
  '/preferred-leg',
  asyncHandler(async (req, res) => {
    const { leg: chosen } = parseBody(req, z.object({ leg }));
    res.json(await setPreferredLeg(req as never, chosen));
  }),
);

/** The eligible course(s) and where the affiliate stands with each. */
affiliateRouter.get(
  '/activation',
  asyncHandler(async (req, res) => {
    res.json(await affiliateActivation(req.auth!));
  }),
);

/* ─── The affiliate's network (MLM-002) ──────────────────────────────────── */

/** A node in the caller's own team (themselves, or someone under them), or not found. */
async function ownNode(auth: { sub: string }, rootId: string | undefined) {
  const me = await requireAffiliate(auth);
  if (!rootId || rootId === me.id) return me.id;
  const node = await db.affiliate.findUnique({ where: { id: rootId }, select: { id: true, pathIdsJson: true } });
  if (!node || !node.pathIdsJson.includes(`"${me.id}"`)) throw notFound('That affiliate is not in your team.');
  return node.id;
}

/** The caller's subtree, or a downline member's, a few levels at a time. */
affiliateRouter.get(
  '/tree',
  asyncHandler(async (req, res) => {
    const { root, depth } = parseQuery(
      req,
      z.object({ root: z.string().trim().max(64).optional(), depth: z.coerce.number().int().min(1).max(MLM_TREE_MAX_DEPTH).default(3) }),
    );
    res.json(await subtree(await ownNode(req.auth!, root), depth));
  }),
);

/** Everyone under the caller, flat, with counts; filtered by leg, status or a name/code search. */
affiliateRouter.get(
  '/team',
  asyncHandler(async (req, res) => {
    const query = parseQuery(
      req,
      z.object({ leg: leg.optional(), status: optionalEnum(AFFILIATE_STATUSES as readonly AffiliateStatus[]), search: searchText, ...paging }),
    );
    const me = await requireAffiliate(req.auth!);
    res.json(await team(me.id, query));
  }),
);

/** The people the caller referred, wherever they were placed. */
affiliateRouter.get(
  '/referrals',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json({ rows: await directReferrals(me.id) });
  }),
);

/* ─── Volumes (MLM-003) ─────────────────────────────────────────────────── */

/** The caller's leg pools: lifetime and unmatched CV per leg, and what the next matching run can pay on. */
affiliateRouter.get(
  '/figures',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await affiliateFigures(me.id));
  }),
);

/** The caller's CV ledger: every credit and reversal, newest first. */
affiliateRouter.get(
  '/cv',
  asyncHandler(async (req, res) => {
    const query = parseQuery(req, z.object({ leg: leg.optional(), kind: optionalEnum(['sale', 'reversal'] as const), ...paging }));
    const me = await requireAffiliate(req.auth!);
    res.json(await listCvLedger({ ...query, affiliateId: me.id }));
  }),
);

/* ─── Earnings (MLM-004 to MLM-006): the caller's own records only ─── */

const pageQuery = z.object({ page: z.coerce.number().int().min(1).optional(), pageSize: z.coerce.number().int().min(1).max(100).optional() });

/** The caller's own paid purchases of eligible courses. The buyer comes from the session, never from the request. */
affiliateRouter.get(
  '/orders',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await affiliateOrders(me, parseQuery(req, pageQuery)));
  }),
);

affiliateRouter.get(
  '/earnings',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await affiliateEarnings(me.id));
  }),
);

affiliateRouter.get(
  '/matching',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await listMatchingRuns({ ...parseQuery(req, pageQuery), affiliateId: me.id }));
  }),
);

affiliateRouter.get(
  '/commissions',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await listCommissions({ ...parseQuery(req, pageQuery), affiliateId: me.id }));
  }),
);

affiliateRouter.get(
  '/ranks',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await listRankHistory({ ...parseQuery(req, pageQuery), affiliateId: me.id }));
  }),
);

affiliateRouter.get(
  '/rewards',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await listRewards({ ...parseQuery(req, pageQuery), affiliateId: me.id }));
  }),
);

affiliateRouter.get(
  '/wallet',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await walletEntries(me.id, parseQuery(req, pageQuery)));
  }),
);

affiliateRouter.get(
  '/kyc',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await ownKyc(me.id));
  }),
);

affiliateRouter.put(
  '/kyc',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    const input = parseBody(
      req,
      z
        .object({
          legalName: z.string().trim().min(2).max(120),
          pan: z.string().trim().min(10).max(10),
          bankAccount: z.string().trim().min(6).max(24),
          ifsc: z.string().trim().min(11).max(11),
          accountHolder: z.string().trim().min(2).max(120),
          upiId: z.string().trim().max(80).optional(),
          documentIds: z.array(z.string().min(1).max(64)).max(MLM_KYC_MAX_DOCUMENTS).optional(),
        })
        .strict(),
    );
    res.json(await submitKyc(req as never, me.id, input));
  }),
);

affiliateRouter.get(
  '/withdrawals',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    res.json(await listWithdrawals({ ...parseQuery(req, pageQuery), affiliateId: me.id }));
  }),
);

affiliateRouter.post(
  '/withdrawals',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    const { amount } = parseBody(req, z.object({ amount: z.number().int().min(1).max(Number.MAX_SAFE_INTEGER) }).strict());
    res.status(201).json(await requestWithdrawal(req as never, me.id, amount));
  }),
);

affiliateRouter.post(
  '/withdrawals/:id/cancel',
  asyncHandler(async (req, res) => {
    const me = await requireAffiliate(req.auth!);
    await cancelWithdrawal(req as never, me.id, req.params.id);
    res.json({ ok: true });
  }),
);
