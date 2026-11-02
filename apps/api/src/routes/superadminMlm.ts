import { Router } from 'express';
import {
  MLM_CAP_OVERFLOW_POLICIES,
  MLM_CARRY_FORWARD_POLICIES,
  MLM_KYC_STATUSES,
  MLM_LIABILITY_PERIODS,
  MLM_MAX_CAP_BANDS,
  MLM_MAX_ELIGIBLE_COURSES,
  MLM_MAX_NOTE,
  MLM_MAX_TIERS,
  MLM_REWARD_KINDS,
  MLM_SPILLOVER_RULES,
  type MlmPlanTermsInput,
} from '@syniastrolms/domain';
import { AFFILIATE_STATUSES, MLM_LEGS, MLM_TREE_MAX_DEPTH, type AffiliateStatus, type MlmLeg } from '@syniastrolms/domain';
import { asyncHandler, notFound } from '../lib/errors.js';
import { db } from '../lib/db.js';
import { runInTenant } from '../lib/tenancy.js';
import { id, optionalEnum, optionalId, paging, parseBody, parseQuery, searchText, z } from '../lib/validate.js';
import { changeSponsor, manualPlacement, setAffiliateStatus } from '../lib/mlm/placement.js';
import { ancestors, listMembers, listSponsors, memberDetail, networkCsv, placementHistory, subtree, team } from '../lib/mlm/tree.js';
import { adjustCarryForward, cvLedgerCsv, listCarryForward, listCvLedger, listOrders, orderDetail, reverseMlmOrder } from '../lib/mlm/cv.js';
import { activeMlmPlan } from '../lib/mlm/plan.js';
import {
  activateMlmPlanVersion,
  createMlmPlanVersion,
  deleteMlmPlanDraft,
  getMlmPlanVersion,
  listMlmPlanVersions,
  listProgramCourses,
  mlmPlanOverview,
  retireMlmPlanVersion,
  setMlmEligibleCourses,
  updateMlmPlanVersion,
} from '../lib/mlm/plan.js';

/*
 * `/superadmin/affiliates/*` — the affiliate program's management surface (docs/15 §5.3). Mounted inside the Super
 * Admin router, so `requireAuth`, `requireSuperAdmin` and the platform context already apply to every route here.
 * MLM-000 brings the plan; later modules add members, network, orders, ledgers, matching, ranks, rewards, wallets,
 * withdrawals, payouts, KYC and reports to this same router.
 */
export const superadminMlmRouter = Router();

/** A 64-bit minor-unit amount as JSON carries it: a safe integer. */
const amount = z.number().int().min(0).max(Number.MAX_SAFE_INTEGER);
const positiveAmount = z.number().int().min(1).max(Number.MAX_SAFE_INTEGER);
const enumOf = <T extends string>(values: readonly T[]) => z.enum(values as unknown as [T, ...T[]]);

const capBandSchema = z.object({
  key: z.string().trim().max(24),
  label: z.string().trim().max(40),
  dailyCap: positiveAmount,
});

const tierSchema = z.object({
  order: z.number().int().min(1).max(MLM_MAX_TIERS),
  name: z.string().trim().max(40),
  groupCv: positiveAmount,
  rewardKind: enumOf(MLM_REWARD_KINDS),
  rewardAmount: amount,
  rewardCapAmount: positiveAmount.nullable(),
  capBandKey: z.string().trim().max(24),
  vestingDays: z.number().int().min(0).max(3650),
});

const termsSchema = z.object({
  programTenantId: id,
  eligibleCourseIds: z.array(id).max(MLM_MAX_ELIGIBLE_COURSES),
  currency: z.string().trim().toUpperCase().max(3),
  cvBasisPoints: z.number().int().min(0).max(10_000),
  matchingRateBps: z.number().int().min(0).max(10_000),
  payoutCeilingBps: z.number().int().min(0).max(10_000),
  normalPayoutBps: z.number().int().min(0).max(10_000),
  matchingRunHourIst: z.number().int().min(0).max(23),
  cvEligibilityDelayDays: z.number().int().min(0).max(90),
  capOverflowPolicy: enumOf(MLM_CAP_OVERFLOW_POLICIES),
  carryForwardPolicy: enumOf(MLM_CARRY_FORWARD_POLICIES),
  carryExpiryDays: z.number().int().min(1).max(365).nullable(),
  spilloverRule: enumOf(MLM_SPILLOVER_RULES),
  withdrawalMinAmount: amount,
  withdrawalRequiresKyc: z.boolean(),
  tdsBps: z.number().int().min(0).max(10_000),
  liabilityPeriod: enumOf(MLM_LIABILITY_PERIODS),
  note: z.string().max(MLM_MAX_NOTE),
  capBands: z.array(capBandSchema).max(MLM_MAX_CAP_BANDS),
  tiers: z.array(tierSchema).max(MLM_MAX_TIERS),
});

/** A new draft with no terms: where to start from (the active version, a named one, or the PDF's version 1). */
const startFromSchema = z.object({ fromVersionId: id.optional(), programTenantId: id.optional() });

/** A body that carries ranks is full terms; anything else says where to start from. Decided by shape, not by a union, so a bad term is a 400 that names it. */
const isTermsBody = (body: unknown): boolean => typeof body === 'object' && body !== null && 'tiers' in body;

superadminMlmRouter.get(
  '/plan',
  asyncHandler(async (_req, res) => {
    res.json(await mlmPlanOverview());
  }),
);

superadminMlmRouter.get(
  '/plan/versions',
  asyncHandler(async (_req, res) => {
    const rows = await listMlmPlanVersions();
    res.json({ rows, total: rows.length });
  }),
);

superadminMlmRouter.post(
  '/plan/versions',
  asyncHandler(async (req, res) => {
    const input = isTermsBody(req.body) ? (parseBody(req, termsSchema) as MlmPlanTermsInput) : parseBody(req, startFromSchema);
    res.status(201).json(await createMlmPlanVersion(req, input));
  }),
);

superadminMlmRouter.get(
  '/plan/versions/:id',
  asyncHandler(async (req, res) => {
    res.json(await getMlmPlanVersion(req.params.id));
  }),
);

superadminMlmRouter.put(
  '/plan/versions/:id',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, termsSchema);
    res.json(await updateMlmPlanVersion(req, req.params.id, input as MlmPlanTermsInput));
  }),
);

superadminMlmRouter.put(
  '/plan/versions/:id/courses',
  asyncHandler(async (req, res) => {
    const { eligibleCourseIds } = parseBody(req, z.object({ eligibleCourseIds: z.array(id).max(MLM_MAX_ELIGIBLE_COURSES) }));
    res.json(await setMlmEligibleCourses(req, req.params.id, eligibleCourseIds));
  }),
);

superadminMlmRouter.post(
  '/plan/versions/:id/activate',
  asyncHandler(async (req, res) => {
    res.json(await activateMlmPlanVersion(req, req.params.id));
  }),
);

superadminMlmRouter.post(
  '/plan/versions/:id/retire',
  asyncHandler(async (req, res) => {
    res.json(await retireMlmPlanVersion(req, req.params.id));
  }),
);

superadminMlmRouter.delete(
  '/plan/versions/:id',
  asyncHandler(async (req, res) => {
    await deleteMlmPlanDraft(req, req.params.id);
    res.status(204).end();
  }),
);

superadminMlmRouter.get(
  '/plan/courses',
  asyncHandler(async (req, res) => {
    const { tenantId } = parseQuery(req, z.object({ tenantId: id }));
    res.json({ rows: await listProgramCourses(tenantId) });
  }),
);

/* ─── Members, network, placements and sponsors (MLM-002) ────────────────── */

const legSchema = z.enum(MLM_LEGS as unknown as [MlmLeg, ...MlmLeg[]]);
const statusQuery = optionalEnum(AFFILIATE_STATUSES as readonly AffiliateStatus[]);

/** The academy an affiliate belongs to, so a write runs in its context. */
async function academyOf(affiliateId: string): Promise<string> {
  const row = await db.affiliate.findUnique({ where: { id: affiliateId }, select: { tenantId: true } });
  if (!row) throw notFound('Affiliate not found.');
  return row.tenantId;
}

superadminMlmRouter.get(
  '/members',
  asyncHandler(async (req, res) => {
    const query = parseQuery(
      req,
      z.object({
        tenantId: optionalId,
        status: statusQuery,
        // An empty value is how the page clears a filter; rank 0 is a real one (nobody's rank yet).
        rank: z.preprocess((v) => (v === '' ? undefined : v), z.coerce.number().int().min(0).max(MLM_MAX_TIERS).optional()),
        kyc: z.preprocess((v) => (v === '' ? undefined : v), optionalEnum(MLM_KYC_STATUSES)),
        search: searchText,
        ...paging,
      }),
    );
    res.json(await listMembers(query));
  }),
);

superadminMlmRouter.get(
  '/members/:id',
  asyncHandler(async (req, res) => {
    res.json(await memberDetail(req.params.id));
  }),
);

/** Suspend, reactivate or terminate. Activation itself comes from the eligible purchase, never from here. */
superadminMlmRouter.patch(
  '/members/:id',
  asyncHandler(async (req, res) => {
    const { status, note } = parseBody(req, z.object({ status: z.enum(['active', 'suspended', 'terminated']), note: z.string().trim().max(500).default('') }));
    const tenantId = await academyOf(req.params.id);
    await runInTenant(tenantId, () => setAffiliateStatus(req, req.params.id, status, note));
    res.json(await memberDetail(req.params.id));
  }),
);

superadminMlmRouter.get(
  '/members/:id/tree',
  asyncHandler(async (req, res) => {
    const { depth } = parseQuery(req, z.object({ depth: z.coerce.number().int().min(1).max(MLM_TREE_MAX_DEPTH).default(3) }));
    res.json(await subtree(req.params.id, depth));
  }),
);

superadminMlmRouter.get(
  '/members/:id/ancestors',
  asyncHandler(async (req, res) => {
    res.json({ rows: await ancestors(req.params.id) });
  }),
);

superadminMlmRouter.get(
  '/members/:id/team',
  asyncHandler(async (req, res) => {
    const query = parseQuery(req, z.object({ leg: legSchema.optional(), status: statusQuery, search: searchText, ...paging }));
    res.json(await team(req.params.id, query));
  }),
);

/** A manual placement or move, with a reason. Refused for a cycle, a filled position, or a node with a team unless `moveSubtree`. */
superadminMlmRouter.post(
  '/members/:id/placement',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ parentId: id, leg: legSchema, reason: z.string().trim().min(3).max(500), moveSubtree: z.boolean().optional() }));
    const tenantId = await academyOf(req.params.id);
    await runInTenant(tenantId, () => manualPlacement(req, req.params.id, input));
    res.json(await memberDetail(req.params.id));
  }),
);

superadminMlmRouter.patch(
  '/members/:id/sponsor',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ sponsorId: id.nullable(), reason: z.string().trim().min(3).max(500) }));
    const tenantId = await academyOf(req.params.id);
    await runInTenant(tenantId, () => changeSponsor(req, req.params.id, input.sponsorId, input.reason));
    res.json(await memberDetail(req.params.id));
  }),
);

superadminMlmRouter.get(
  '/placements',
  asyncHandler(async (req, res) => {
    const query = parseQuery(req, z.object({ affiliateId: optionalId, tenantId: optionalId, ...paging }));
    res.json(await placementHistory(query));
  }),
);

superadminMlmRouter.get(
  '/sponsors',
  asyncHandler(async (req, res) => {
    const query = parseQuery(req, z.object({ tenantId: optionalId, search: searchText, ...paging }));
    res.json(await listSponsors(query));
  }),
);

superadminMlmRouter.get(
  '/network/export.csv',
  asyncHandler(async (req, res) => {
    const { root } = parseQuery(req, z.object({ root: id }));
    const csv = await networkCsv(root);
    res.type('text/csv').set('Content-Disposition', `attachment; filename="network-${root}.csv"`).send(csv);
  }),
);

/* ─── Products, orders, the CV ledger and carry-forward (MLM-003) ───────── */

/** The program's eligible courses on the active version, beside every course of the program academy. */
superadminMlmRouter.get(
  '/products',
  asyncHandler(async (_req, res) => {
    const plan = await activeMlmPlan();
    const courses = plan ? await listProgramCourses(plan.programTenantId) : [];
    res.json({
      active: plan ? { id: plan.id, version: plan.version, programTenantId: plan.programTenantId, eligibleCourseIds: plan.eligibleCourseIds } : null,
      courses,
    });
  }),
);

superadminMlmRouter.put(
  '/products',
  asyncHandler(async (req, res) => {
    const { eligibleCourseIds } = parseBody(req, z.object({ eligibleCourseIds: z.array(id).max(50) }));
    const plan = await activeMlmPlan();
    if (!plan) throw notFound('No affiliate plan version is active.');
    const updated = await setMlmEligibleCourses(req, plan.id, eligibleCourseIds);
    res.json({
      active: { id: updated.id, version: updated.version, programTenantId: updated.programTenantId, eligibleCourseIds: updated.eligibleCourseIds },
      courses: await listProgramCourses(updated.programTenantId),
    });
  }),
);

superadminMlmRouter.get(
  '/orders',
  asyncHandler(async (req, res) => {
    const query = parseQuery(
      req,
      z.object({
        tenantId: optionalId,
        status: optionalEnum(['pending', 'eligible', 'reversed'] as const),
        search: searchText,
        from: z.string().max(40).optional(),
        to: z.string().max(40).optional(),
        ...paging,
      }),
    );
    res.json(await listOrders(query));
  }),
);

superadminMlmRouter.get(
  '/orders/:id',
  asyncHandler(async (req, res) => {
    res.json(await orderDetail(req.params.id));
  }),
);

/** A reversal by hand: a refund made in the academy's gateway dashboard, or a chargeback. The credits are negated once. */
superadminMlmRouter.post(
  '/orders/:id/reverse',
  asyncHandler(async (req, res) => {
    const { reason, note } = parseBody(req, z.object({ reason: z.enum(['refund', 'chargeback', 'manual']), note: z.string().trim().max(500).default('') }));
    const order = await db.mlmOrder.findUnique({ where: { id: req.params.id }, select: { tenantId: true } });
    if (!order) throw notFound('Affiliate order not found.');
    await runInTenant(order.tenantId, () => reverseMlmOrder(req, req.params.id, reason, note));
    res.json(await orderDetail(req.params.id));
  }),
);

superadminMlmRouter.get(
  '/cv',
  asyncHandler(async (req, res) => {
    const query = parseQuery(
      req,
      z.object({
        affiliateId: optionalId,
        tenantId: optionalId,
        leg: legSchema.optional(),
        kind: optionalEnum(['sale', 'reversal'] as const),
        from: z.string().max(40).optional(),
        to: z.string().max(40).optional(),
        ...paging,
      }),
    );
    res.json(await listCvLedger(query));
  }),
);

superadminMlmRouter.get(
  '/cv/export.csv',
  asyncHandler(async (req, res) => {
    const query = parseQuery(
      req,
      z.object({
        affiliateId: optionalId,
        tenantId: optionalId,
        leg: legSchema.optional(),
        from: z.string().max(40).optional(),
        to: z.string().max(40).optional(),
      }),
    );
    res
      .type('text/csv')
      .set('Content-Disposition', 'attachment; filename="cv-ledger.csv"')
      .send(await cvLedgerCsv(query));
  }),
);

superadminMlmRouter.get(
  '/carry-forward',
  asyncHandler(async (req, res) => {
    const query = parseQuery(req, z.object({ tenantId: optionalId, search: searchText, ...paging }));
    res.json(await listCarryForward(query));
  }),
);

/** A signed correction to one leg's carry-forward, with a reason; the audit row is its record. Refused below zero. */
superadminMlmRouter.post(
  '/members/:id/carry-forward/adjust',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z
        .object({
          leg: legSchema,
          amount: z
            .number()
            .int()
            .min(-1e15)
            .max(1e15)
            .refine((n) => n !== 0, 'Enter an amount.'),
          reason: z.string().trim().min(3).max(500),
        })
        .strict(),
    );
    const tenantId = await academyOf(req.params.id);
    res.json(await runInTenant(tenantId, () => adjustCarryForward(req, req.params.id, input)));
  }),
);
