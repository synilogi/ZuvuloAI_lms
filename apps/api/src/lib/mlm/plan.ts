import {
  defaultMlmPlanTerms,
  mlmActivationIssues,
  validateMlmPlanTerms,
  type MlmCapBand,
  type MlmPlanIssue,
  type MlmPlanOverview,
  type MlmPlanStatus,
  type MlmPlanTerms,
  type MlmPlanTermsInput,
  type MlmPlanVersionSummary,
  type MlmProgramCourse,
  type MlmRankTier,
} from '@syniastrolms/domain';
import type { Prisma } from '@prisma/client';

import { recordAuditLog, type AuditActor } from '../audit.js';
import { db, type DbClient } from '../db.js';
import { badRequest, conflict, forbidden, notFound } from '../errors.js';
import { readJson } from '../json.js';
import { currentContext } from '../tenancy.js';

/*
 * The affiliate program's plan (MLM-000; docs/15 §4.2, §6) — the one module that writes MlmPlanVersion, MlmRankTier and
 * MlmCapBand.
 *
 * A plan is a version. Its terms are validated by the domain's `validateMlmPlanTerms`, the same function the Super
 * Admin's editor runs, so the screen and the server refuse the same things. A draft can be edited freely; activating it
 * retires the version that was active, in the same transaction, so there is always at most one active version and the
 * engines (CV, matching, ranks, ceiling) read `activeMlmPlan()` and record the version id they computed under.
 * Database triggers seal a version's ranks and bands once it leaves draft, and refuse any backward status move.
 *
 * Platform configuration: every write refuses to run in an academy's context, and a signed-in caller must be a super
 * admin. Nothing here reads affiliate ledgers; nothing here gates on a rank's name.
 */

export const MLM_PLAN_AUDIT_ACTIONS = {
  created: 'mlm.plan.created',
  updated: 'mlm.plan.updated',
  activated: 'mlm.plan.activated',
  retired: 'mlm.plan.retired',
  coursesChanged: 'mlm.plan.courses_changed',
} as const;

const WITH_TERMS = { tiers: { orderBy: { order: 'asc' } }, capBands: { orderBy: { order: 'asc' } } } satisfies Prisma.MlmPlanVersionInclude;
type VersionRow = Prisma.MlmPlanVersionGetPayload<{ include: typeof WITH_TERMS }>;

/** A stored 64-bit amount back as a number; group CV targets are far inside the safe range, so a failure here is corruption. */
function amount(value: bigint): number {
  const n = Number(value);
  if (!Number.isSafeInteger(n)) throw new Error('An affiliate plan amount is too large to read exactly.');
  return n;
}

const toBand = (row: VersionRow['capBands'][number]): MlmCapBand => ({ key: row.key, label: row.label, dailyCap: amount(row.dailyCap) });

const toTier = (row: VersionRow['tiers'][number]): MlmRankTier => ({
  order: row.order,
  name: row.name,
  groupCv: amount(row.groupCv),
  rewardKind: row.rewardKind as MlmRankTier['rewardKind'],
  rewardAmount: amount(row.rewardAmount),
  rewardCapAmount: row.rewardCapAmount === null ? null : amount(row.rewardCapAmount),
  capBandKey: row.capBandKey,
  vestingDays: row.vestingDays,
});

function toTerms(row: VersionRow): MlmPlanTerms {
  return {
    id: row.id,
    version: row.version,
    status: row.status as MlmPlanStatus,
    programTenantId: row.programTenantId,
    eligibleCourseIds: readJson<string[]>(row.eligibleCourseIdsJson, []),
    currency: row.currency,
    cvBasisPoints: row.cvBasisPoints,
    matchingRateBps: row.matchingRateBps,
    payoutCeilingBps: row.payoutCeilingBps,
    normalPayoutBps: row.normalPayoutBps,
    matchingRunHourIst: row.matchingRunHourIst,
    cvEligibilityDelayDays: row.cvEligibilityDelayDays,
    capOverflowPolicy: row.capOverflowPolicy as MlmPlanTerms['capOverflowPolicy'],
    carryForwardPolicy: row.carryForwardPolicy as MlmPlanTerms['carryForwardPolicy'],
    carryExpiryDays: row.carryExpiryDays,
    spilloverRule: row.spilloverRule as MlmPlanTerms['spilloverRule'],
    withdrawalMinAmount: amount(row.withdrawalMinAmount),
    withdrawalRequiresKyc: row.withdrawalRequiresKyc,
    tdsBps: row.tdsBps,
    liabilityPeriod: row.liabilityPeriod as MlmPlanTerms['liabilityPeriod'],
    note: row.note,
    capBands: row.capBands.map(toBand),
    tiers: row.tiers.map(toTier),
    createdAt: row.createdAt.toISOString(),
    activatedAt: row.activatedAt?.toISOString() ?? null,
    retiredAt: row.retiredAt?.toISOString() ?? null,
  };
}

const toSummary = (row: VersionRow): MlmPlanVersionSummary => ({
  id: row.id,
  version: row.version,
  status: row.status as MlmPlanStatus,
  programTenantId: row.programTenantId,
  tierCount: row.tiers.length,
  eligibleCourseCount: readJson<string[]>(row.eligibleCourseIdsJson, []).length,
  createdAt: row.createdAt.toISOString(),
  activatedAt: row.activatedAt?.toISOString() ?? null,
  retiredAt: row.retiredAt?.toISOString() ?? null,
  note: row.note,
});

/** The columns a version stores for its terms (everything but status and timestamps). */
const columnsOf = (input: MlmPlanTermsInput) => ({
  programTenantId: input.programTenantId,
  eligibleCourseIdsJson: JSON.stringify(input.eligibleCourseIds),
  currency: input.currency,
  cvBasisPoints: input.cvBasisPoints,
  matchingRateBps: input.matchingRateBps,
  payoutCeilingBps: input.payoutCeilingBps,
  normalPayoutBps: input.normalPayoutBps,
  matchingRunHourIst: input.matchingRunHourIst,
  cvEligibilityDelayDays: input.cvEligibilityDelayDays,
  capOverflowPolicy: input.capOverflowPolicy,
  carryForwardPolicy: input.carryForwardPolicy,
  carryExpiryDays: input.carryExpiryDays,
  spilloverRule: input.spilloverRule,
  withdrawalMinAmount: BigInt(input.withdrawalMinAmount),
  withdrawalRequiresKyc: input.withdrawalRequiresKyc,
  tdsBps: input.tdsBps,
  liabilityPeriod: input.liabilityPeriod,
  note: input.note.trim(),
});

const bandRows = (input: MlmPlanTermsInput) =>
  input.capBands.map((b, i) => ({ key: b.key, label: b.label.trim(), dailyCap: BigInt(b.dailyCap), order: i + 1 }));

const tierRows = (input: MlmPlanTermsInput) =>
  input.tiers.map((t) => ({
    order: t.order,
    name: t.name.trim(),
    groupCv: BigInt(t.groupCv),
    rewardKind: t.rewardKind,
    rewardAmount: BigInt(t.rewardAmount),
    rewardCapAmount: t.rewardCapAmount === null ? null : BigInt(t.rewardCapAmount),
    capBandKey: t.capBandKey,
    vestingDays: t.vestingDays,
  }));

/* ─── Guards ───────────────────────────────────────────────────────────── */

function assertPlatformWriter(actor: AuditActor, what: string) {
  if (currentContext()?.kind !== 'platform') throw forbidden(`Only the platform can ${what}.`);
  if (actor.auth && actor.auth.role !== 'superadmin') throw forbidden(`Only a super admin can ${what}.`);
}

function refuse(issues: MlmPlanIssue[]): never {
  throw badRequest(issues[0].message, issues);
}

/**
 * The terms must be valid in themselves, name an academy that exists, and name only that academy's own courses. The
 * course check is done here rather than by the domain because it needs the database.
 */
async function assertStorable(client: DbClient, input: MlmPlanTermsInput): Promise<void> {
  const issues = validateMlmPlanTerms(input);
  if (issues.length) refuse(issues);
  const tenant = await client.tenant.findUnique({ where: { id: input.programTenantId }, select: { id: true, status: true } });
  if (!tenant) refuse([{ field: 'programTenantId', message: 'That workspace does not exist.' }]);
  if (tenant.status === 'archived') refuse([{ field: 'programTenantId', message: 'That workspace is closed.' }]);
  if (input.eligibleCourseIds.length) {
    const found = await client.course.findMany({ where: { id: { in: input.eligibleCourseIds }, tenantId: input.programTenantId }, select: { id: true } });
    if (found.length !== input.eligibleCourseIds.length)
      refuse([{ field: 'eligibleCourseIds', message: 'Every eligible course must be a course of the program.' }]);
  }
}

async function loadVersion(client: DbClient, id: string): Promise<VersionRow> {
  const row = await client.mlmPlanVersion.findUnique({ where: { id }, include: WITH_TERMS });
  if (!row) throw notFound('Affiliate plan version not found.');
  return row;
}

/* ─── Reads ────────────────────────────────────────────────────────────── */

/** The version the engines run under, or null when the program has none (nothing earns, nothing is placed by rule). */
export async function activeMlmPlan(client: DbClient = db): Promise<MlmPlanTerms | null> {
  const row = await client.mlmPlanVersion.findFirst({ where: { status: 'active' }, include: WITH_TERMS });
  return row ? toTerms(row) : null;
}

export async function getMlmPlanVersion(id: string): Promise<MlmPlanTerms> {
  return toTerms(await loadVersion(db, id));
}

export async function listMlmPlanVersions(): Promise<MlmPlanVersionSummary[]> {
  const rows = await db.mlmPlanVersion.findMany({ orderBy: { version: 'desc' }, include: WITH_TERMS });
  return rows.map(toSummary);
}

export async function mlmPlanOverview(): Promise<MlmPlanOverview> {
  const [active, versions] = await Promise.all([activeMlmPlan(), listMlmPlanVersions()]);
  return { active, versions };
}

/** The courses of an academy the Super Admin may mark eligible, with whether each can be sold at all. */
export async function listProgramCourses(tenantId: string): Promise<MlmProgramCourse[]> {
  const rows = await db.course.findMany({
    where: { tenantId, status: { not: 'archived' } },
    orderBy: { title: 'asc' },
    select: { id: true, title: true, status: true, pricing: true, priceAmount: true, priceCurrency: true },
  });
  // Only a `paid` course charges its price; any other pricing cannot be sold, so it generates no CV.
  return rows.map((c) => ({
    id: c.id,
    title: c.title,
    status: c.status,
    priceAmount: c.pricing === 'paid' ? (c.priceAmount ?? null) : null,
    currency: c.priceCurrency,
  }));
}

/** The academy the program starts on when none is named: the one signed-out visitors see (D-MLM-01). */
async function defaultProgramTenantId(client: DbClient): Promise<string> {
  const slug = process.env.DEFAULT_TENANT_SLUG || 'default';
  const tenant = await client.tenant.findUnique({ where: { slug }, select: { id: true } });
  if (!tenant) throw conflict(`The workspace (${slug}) does not exist; name the program.`);
  return tenant.id;
}

/* ─── Writes ───────────────────────────────────────────────────────────── */

/**
 * A new draft version: from the terms given, or — with none — from the active version (so a change starts from what
 * runs today), or from the PDF's version 1 bound to the academy named. Always a draft; activation is its own step.
 */
export async function createMlmPlanVersion(
  actor: AuditActor,
  input: MlmPlanTermsInput | { fromVersionId?: string; programTenantId?: string },
): Promise<MlmPlanTerms> {
  assertPlatformWriter(actor, 'create an affiliate plan version');
  let terms: MlmPlanTermsInput;
  if ('tiers' in input) terms = input;
  else if (input.fromVersionId) {
    const from = toTerms(await loadVersion(db, input.fromVersionId));
    terms = { ...from, note: '' };
  } else {
    const active = await activeMlmPlan();
    terms = active ? { ...active, note: '' } : defaultMlmPlanTerms(input.programTenantId ?? (await defaultProgramTenantId(db)));
  }
  await assertStorable(db, terms);

  const id = await db.$transaction(async (tx) => {
    const latest = await tx.mlmPlanVersion.aggregate({ _max: { version: true } });
    const version = (latest._max.version ?? 0) + 1;
    const row = await tx.mlmPlanVersion.create({
      data: { version, status: 'draft', ...columnsOf(terms), capBands: { create: bandRows(terms) }, tiers: { create: tierRows(terms) } },
      select: { id: true },
    });
    await recordAuditLog(actor, { action: MLM_PLAN_AUDIT_ACTIONS.created, targetType: 'mlm_plan', targetId: row.id, meta: { version } }, tx);
    return row.id;
  });
  return getMlmPlanVersion(id);
}

/** Replaces a draft's terms, ranks and bands. An active or retired version is refused: add a new version instead. */
export async function updateMlmPlanVersion(actor: AuditActor, id: string, input: MlmPlanTermsInput): Promise<MlmPlanTerms> {
  assertPlatformWriter(actor, 'edit an affiliate plan version');
  const current = await loadVersion(db, id);
  if (current.status !== 'draft') throw conflict('Only a draft version can be edited. Create a new version to change the plan.');
  await assertStorable(db, input);
  await db.$transaction(async (tx) => {
    await tx.mlmCapBand.deleteMany({ where: { planVersionId: id } });
    await tx.mlmRankTier.deleteMany({ where: { planVersionId: id } });
    await tx.mlmPlanVersion.update({
      where: { id },
      data: { ...columnsOf(input), capBands: { create: bandRows(input) }, tiers: { create: tierRows(input) } },
    });
    await recordAuditLog(actor, { action: MLM_PLAN_AUDIT_ACTIONS.updated, targetType: 'mlm_plan', targetId: id, meta: { version: current.version } }, tx);
  });
  return getMlmPlanVersion(id);
}

/** The one edit an active version allows (D-MLM-05): which courses of the program academy generate CV. */
export async function setMlmEligibleCourses(actor: AuditActor, id: string, eligibleCourseIds: string[]): Promise<MlmPlanTerms> {
  assertPlatformWriter(actor, 'change the affiliate program’s courses');
  const current = toTerms(await loadVersion(db, id));
  if (current.status === 'retired') throw conflict('A retired version cannot change.');
  const next = { ...current, eligibleCourseIds };
  await assertStorable(db, next);
  if (current.status === 'active' && eligibleCourseIds.length === 0) refuse(mlmActivationIssues(next));
  await db.$transaction(async (tx) => {
    await tx.mlmPlanVersion.update({ where: { id }, data: { eligibleCourseIdsJson: JSON.stringify(eligibleCourseIds) } });
    await recordAuditLog(
      actor,
      { action: MLM_PLAN_AUDIT_ACTIONS.coursesChanged, targetType: 'mlm_plan', targetId: id, meta: { from: current.eligibleCourseIds, to: eligibleCourseIds } },
      tx,
    );
  });
  return getMlmPlanVersion(id);
}

/**
 * Makes a draft the version the program runs under. The version that was active is retired in the same transaction;
 * the database refuses two active versions, so a race ends with one of them refused.
 */
export async function activateMlmPlanVersion(actor: AuditActor, id: string): Promise<MlmPlanTerms> {
  assertPlatformWriter(actor, 'activate an affiliate plan version');
  const current = toTerms(await loadVersion(db, id));
  if (current.status !== 'draft')
    throw conflict(
      current.status === 'active' ? 'This version is already active.' : 'A retired version cannot be activated again. Create a new version from it.',
    );
  const issues = [...validateMlmPlanTerms(current), ...mlmActivationIssues(current)];
  if (issues.length) refuse(issues);
  await assertStorable(db, current);
  const now = new Date();
  await db.$transaction(async (tx) => {
    const previous = await tx.mlmPlanVersion.findFirst({ where: { status: 'active' }, select: { id: true, version: true } });
    if (previous) {
      await tx.mlmPlanVersion.update({ where: { id: previous.id }, data: { status: 'retired', retiredAt: now } });
      await recordAuditLog(
        actor,
        {
          action: MLM_PLAN_AUDIT_ACTIONS.retired,
          targetType: 'mlm_plan',
          targetId: previous.id,
          meta: { version: previous.version, replacedBy: current.version },
        },
        tx,
      );
    }
    await tx.mlmPlanVersion.update({ where: { id }, data: { status: 'active', activatedAt: now } });
    await recordAuditLog(actor, { action: MLM_PLAN_AUDIT_ACTIONS.activated, targetType: 'mlm_plan', targetId: id, meta: { version: current.version } }, tx);
  });
  return getMlmPlanVersion(id);
}

/** Stops the program: no version is active until another is activated. Nothing earned is touched. */
export async function retireMlmPlanVersion(actor: AuditActor, id: string): Promise<MlmPlanTerms> {
  assertPlatformWriter(actor, 'retire an affiliate plan version');
  const current = await loadVersion(db, id);
  if (current.status !== 'active')
    throw conflict(current.status === 'draft' ? 'A draft is not active; delete or keep it.' : 'This version is already retired.');
  await db.$transaction(async (tx) => {
    await tx.mlmPlanVersion.update({ where: { id }, data: { status: 'retired', retiredAt: new Date() } });
    await recordAuditLog(actor, { action: MLM_PLAN_AUDIT_ACTIONS.retired, targetType: 'mlm_plan', targetId: id, meta: { version: current.version } }, tx);
  });
  return getMlmPlanVersion(id);
}

/** Removes a draft that was never used. Anything that has been active is kept for good (trigger). */
export async function deleteMlmPlanDraft(actor: AuditActor, id: string): Promise<void> {
  assertPlatformWriter(actor, 'delete an affiliate plan draft');
  const current = await loadVersion(db, id);
  if (current.status !== 'draft') throw conflict('Only a draft can be deleted.');
  await db.mlmPlanVersion.delete({ where: { id } });
}
