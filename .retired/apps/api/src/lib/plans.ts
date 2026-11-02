import {
  BILLING_CYCLES,
  FEATURE_KEYS,
  LIMIT_KEYS,
  normalisePlanCode,
  validatePlanAllowance,
  validatePlanTerms,
  type BillingCycle,
  type FeatureKey,
  type PlanInput,
  type PlanIssue,
  type PlanLimits,
  type PlanStatus,
  type PlanTermsInput,
} from '@syniastrolms/domain';
import type { Prisma } from '@prisma/client';

import { recordAuditLog, type AuditActor } from './audit.js';
import { db, type DbClient } from './db.js';
import { ApiError, badRequest, conflict, forbidden, notFound } from './errors.js';
import { currentContext } from './tenancy.js';

/*
 * Platform plans (subscriptions.md §4) — the one module that writes the Plan and PlanVersion tables.
 *
 * A plan is two things kept apart on purpose:
 *   - the Plan row: who the plan is — code, name, description, status, place in the list. Editable.
 *   - its PlanVersion rows: what it costs and what it grants — currency, the price of each cycle
 *     sold, trial length, and its allowance: the catalogue features it grants (PlanFeature rows) and
 *     the limits it sets (PlanLimit rows). Append-only, enforced by database triggers, and a version's
 *     allowance is sealed at the size it declared. Editing any of those terms adds version N+1 and
 *     leaves every earlier version exactly as it was, so a subscription or invoice that points at a
 *     version keeps the price and allowance it was sold, however the plan is edited later.
 *
 * Amounts are integers in the currency's minor unit throughout (399900 is ₹3,999). The rules for a
 * valid plan are the domain's `validatePlanTerms` — the same function the plan editor runs — so the
 * screen and the server cannot drift apart.
 *
 * Status moves only through named transitions — publish (draft → active), archive (draft or active →
 * archived) and restore (archived → active) — never through an edit. An archived plan is kept for the
 * subscriptions already on it and refused for new ones (`planForNewSubscription`).
 *
 * Writes are the platform's: they refuse to run in an academy's context, whatever route calls them,
 * and a signed-in caller must be a super admin. The Super Admin endpoints are SAAS-013's.
 *
 * Nothing here — or anywhere — decides what an academy may do from a plan's name or code. What a
 * version grants is read from its rows; the entitlement service (SAAS-003) is the one reader.
 */

/** The trail's plan vocabulary (subscriptions.md §36). Each is written in the same transaction as the change it records. */
export const PLAN_AUDIT_ACTIONS = {
  created: 'plan.created',
  updated: 'plan.updated',
  published: 'plan.published',
  archived: 'plan.archived',
  restored: 'plan.restored',
  /** A new version grants a different set of features — written beside `plan.updated`, naming what was added and removed. */
  entitlementChanged: 'entitlement.changed',
  /** A new version sets a different allowance for one or more limits — each with its old and new value. */
  limitChanged: 'limit.changed',
} as const;

/** One set of a plan's commercial terms, as it was fixed when the version was written. */
export interface PlanTerms {
  id: string;
  version: number;
  currency: string;
  /** Minor units; null when the plan is not sold monthly. */
  monthlyPrice: number | null;
  /** Minor units; null when the plan is not sold annually. */
  annualPrice: number | null;
  /** The cycles this version sells, in the domain's order. */
  cycles: BillingCycle[];
  /** 0 when there is no trial. */
  trialDays: number;
  /** The catalogue features this version grants, in catalogue order. */
  features: FeatureKey[];
  /**
   * A value for every catalogue limit, `null` for unlimited. A limit the version does not set reads 0 —
   * a version written before SAAS-002 grants nothing.
   */
  limits: PlanLimits;
  createdAt: string;
}

export interface PlanRecord {
  id: string;
  code: string;
  name: string;
  description: string;
  status: PlanStatus;
  displayOrder: number;
  /** The terms new subscriptions are sold on: the plan's highest version. */
  current: PlanTerms;
  createdAt: string;
  updatedAt: string;
  archivedAt?: string;
}

/** What creating a plan takes. A new plan is always a draft; publishing is its own step. */
export type CreatePlanInput = PlanTermsInput & Pick<PlanInput, 'limits' | 'features'> & { displayOrder?: number };

/** What editing a plan takes: any subset. Status is not here — it moves only through the transitions. */
export type UpdatePlanInput = Partial<CreatePlanInput>;

/** The plan asked for cannot be sold (subscriptions.md §34 `PLAN_UNAVAILABLE`). */
export class PlanUnavailableError extends ApiError {
  constructor(message: string) {
    super(409, message, undefined, 'PLAN_UNAVAILABLE');
    this.name = 'PlanUnavailableError';
  }
}

/* ─── Mapping ──────────────────────────────────────────────────────────── */

const WITH_ALLOWANCE = { features: { select: { featureKey: true } }, limits: { select: { limitKey: true, value: true } } } satisfies Prisma.PlanVersionInclude;

const WITH_CURRENT = { versions: { orderBy: { version: 'desc' }, take: 1, include: WITH_ALLOWANCE } } satisfies Prisma.PlanInclude;

type PlanWithCurrent = Prisma.PlanGetPayload<{ include: typeof WITH_CURRENT }>;

type VersionRow = Prisma.PlanVersionGetPayload<{ include: typeof WITH_ALLOWANCE }>;

/** A stored limit back as a number. Limits are BIGINT because storage is counted in bytes. */
function limitValue(value: bigint | null): number | null {
  if (value === null) return null;
  const n = Number(value);
  if (!Number.isSafeInteger(n)) throw new Error('A plan limit is too large to read exactly.');
  return n;
}

function toTerms(row: VersionRow): PlanTerms {
  const granted = new Set(row.features.map((f) => f.featureKey));
  const set = new Map(row.limits.map((l) => [l.limitKey, limitValue(l.value)]));
  return {
    id: row.id,
    version: row.version,
    currency: row.currency,
    monthlyPrice: row.monthlyPrice,
    annualPrice: row.annualPrice,
    cycles: BILLING_CYCLES.filter((c) => (c === 'monthly' ? row.monthlyPrice : row.annualPrice) !== null),
    trialDays: row.trialDays,
    features: FEATURE_KEYS.filter((key) => granted.has(key)),
    // A limit the version does not set grants nothing: 0, never "unlimited".
    limits: Object.fromEntries(LIMIT_KEYS.map((key) => [key, set.has(key) ? set.get(key)! : 0])) as PlanLimits,
    createdAt: row.createdAt.toISOString(),
  };
}

function toRecord(row: PlanWithCurrent): PlanRecord {
  const [current] = row.versions;
  // Every plan is created with its first version in the same transaction, and a version can never be
  // deleted, so a plan without one means the data was written by something other than this module.
  if (!current) throw new Error(`Plan ${row.id} has no version.`);
  return {
    id: row.id,
    code: row.code,
    name: row.name,
    description: row.description,
    status: row.status as PlanStatus,
    displayOrder: row.displayOrder,
    current: toTerms(current),
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
    ...(row.archivedAt ? { archivedAt: row.archivedAt.toISOString() } : {}),
  };
}

/** A stored version read back as the editor's input, so an edit can be validated as a whole. */
const inputOf = (plan: Pick<PlanRecord, 'name' | 'description' | 'code' | 'current'>): CreatePlanInput => ({
  name: plan.name,
  description: plan.description,
  code: plan.code,
  currency: plan.current.currency,
  cycles: plan.current.cycles,
  monthlyPrice: plan.current.monthlyPrice ?? 0,
  annualPrice: plan.current.annualPrice ?? 0,
  trialEnabled: plan.current.trialDays > 0,
  trialDays: plan.current.trialDays,
  features: plan.current.features,
  limits: plan.current.limits,
});

/**
 * What a version stores for valid input: a cycle not sold has no price, a plan without a trial has 0
 * days, features in catalogue order and a value for every catalogue limit.
 */
const versionTerms = (input: CreatePlanInput) => ({
  currency: input.currency,
  monthlyPrice: input.cycles.includes('monthly') ? input.monthlyPrice : null,
  annualPrice: input.cycles.includes('annual') ? input.annualPrice : null,
  trialDays: input.trialEnabled ? input.trialDays : 0,
  features: FEATURE_KEYS.filter((key) => input.features.includes(key)),
  limits: Object.fromEntries(LIMIT_KEYS.map((key) => [key, input.limits[key]])) as PlanLimits,
});

type VersionTerms = ReturnType<typeof versionTerms>;

const sameTerms = (a: VersionTerms, b: VersionTerms) =>
  a.currency === b.currency &&
  a.monthlyPrice === b.monthlyPrice &&
  a.annualPrice === b.annualPrice &&
  a.trialDays === b.trialDays &&
  a.features.join() === b.features.join() &&
  LIMIT_KEYS.every((key) => a.limits[key] === b.limits[key]);

/** A version row with its whole allowance, written in one statement. The counts seal the allowance at this size. */
const versionCreate = (version: number, terms: VersionTerms) => ({
  version,
  currency: terms.currency,
  monthlyPrice: terms.monthlyPrice,
  annualPrice: terms.annualPrice,
  trialDays: terms.trialDays,
  featureCount: terms.features.length,
  limitCount: LIMIT_KEYS.length,
  features: { create: terms.features.map((featureKey) => ({ featureKey })) },
  limits: { create: LIMIT_KEYS.map((limitKey) => ({ limitKey, value: terms.limits[limitKey] === null ? null : BigInt(terms.limits[limitKey]!) })) },
});

/** Every rule a plan must meet — the domain's own, the same the editor runs. */
const planIssues = (input: CreatePlanInput, codes: string[]) => [...validatePlanTerms(input, codes), ...validatePlanAllowance(input)];

/* ─── Guards ───────────────────────────────────────────────────────────── */

/**
 * Plans are platform configuration. A write refuses to run inside an academy's context — a Tenant
 * Admin never manages platform plans (§24) — and a signed-in caller must be a super admin. Operator
 * scripts and the seed run as the platform with no caller.
 */
function assertPlatformWriter(actor: AuditActor, what: string) {
  if (currentContext()?.kind !== 'platform') throw forbidden(`Only the platform can ${what}.`);
  if (actor.auth && actor.auth.role !== 'superadmin') throw forbidden(`Only a super admin can ${what}.`);
}

async function takenCodes(client: DbClient, exceptId?: string): Promise<string[]> {
  const rows = await client.plan.findMany({ where: exceptId ? { id: { not: exceptId } } : {}, select: { code: true } });
  return rows.map((r) => r.code);
}

/** Refuses invalid terms: a duplicate code is a conflict, anything else a bad request. Both carry the domain's issues. */
function refuse(issues: PlanIssue[]): never {
  const duplicate = issues.find((i) => i.field === 'code' && i.message.includes('already belongs'));
  if (duplicate) throw conflict(duplicate.message, issues);
  throw badRequest(issues[0].message, issues);
}

const optionalOrder = (value: number | undefined): number | undefined => {
  if (value === undefined) return undefined;
  if (!Number.isSafeInteger(value) || value < 0) throw badRequest('The display order is a whole number of zero or more.');
  return value;
};

async function loadPlan(client: DbClient, id: string): Promise<PlanRecord> {
  const row = await client.plan.findUnique({ where: { id }, include: WITH_CURRENT });
  if (!row) throw notFound('Plan not found.');
  return toRecord(row);
}

/* ─── Reads ────────────────────────────────────────────────────────────── */

/** Every plan, in display order, with the terms each sells today. */
export async function listPlans(query: { status?: PlanStatus } = {}): Promise<PlanRecord[]> {
  const rows = await db.plan.findMany({
    where: query.status ? { status: query.status } : {},
    include: WITH_CURRENT,
    orderBy: [{ displayOrder: 'asc' }, { createdAt: 'asc' }],
  });
  return rows.map(toRecord);
}

export const getPlan = (id: string): Promise<PlanRecord> => loadPlan(db, id);

/** A plan's whole price history, oldest first. */
export async function listPlanVersions(planId: string): Promise<PlanTerms[]> {
  await loadPlan(db, planId);
  const rows = await db.planVersion.findMany({ where: { planId }, orderBy: { version: 'asc' }, include: WITH_ALLOWANCE });
  return rows.map(toTerms);
}

/**
 * The terms a version fixed, whatever has happened to the plan since — edited, archived or both.
 * This is how a subscription or invoice reads the price it was sold at.
 */
export async function resolvePlanVersion(versionId: string): Promise<PlanTerms & { plan: Pick<PlanRecord, 'id' | 'code' | 'name' | 'status'> }> {
  const row = await db.planVersion.findUnique({
    where: { id: versionId },
    include: { ...WITH_ALLOWANCE, plan: { select: { id: true, code: true, name: true, status: true } } },
  });
  if (!row) throw notFound('Plan version not found.');
  return { ...toTerms(row), plan: { ...row.plan, status: row.plan.status as PlanStatus } };
}

/**
 * What a new subscription to `planId` on `cycle` is sold: the plan's current version and the amount,
 * in minor units, taken from that version and nowhere else. Refused with `PLAN_UNAVAILABLE` for a plan
 * that is not active — a draft is not on sale yet, an archived plan is no longer — and for a cycle the
 * plan does not sell. Subscriptions already on an archived plan are untouched: they hold a version id,
 * and `resolvePlanVersion` reads it whatever the plan's status.
 */
export async function planForNewSubscription(planId: string, cycle: BillingCycle): Promise<{ plan: PlanRecord; version: PlanTerms; amount: number }> {
  const row = await db.plan.findUnique({ where: { id: planId }, include: WITH_CURRENT });
  if (!row) throw new PlanUnavailableError('That plan does not exist.');
  const plan = toRecord(row);
  if (plan.status === 'archived') throw new PlanUnavailableError(`${plan.name} is archived and is no longer offered.`);
  if (plan.status !== 'active') throw new PlanUnavailableError(`${plan.name} is not on sale yet.`);
  const amount = cycle === 'monthly' ? plan.current.monthlyPrice : plan.current.annualPrice;
  if (amount === null) throw new PlanUnavailableError(`${plan.name} is not sold on the ${cycle} cycle.`);
  return { plan, version: plan.current, amount };
}

/* ─── Writes ───────────────────────────────────────────────────────────── */

/** Creates a plan as a draft, with its terms as version 1. */
export async function createPlan(actor: AuditActor, input: CreatePlanInput): Promise<PlanRecord> {
  assertPlatformWriter(actor, 'create a plan');
  const displayOrder = optionalOrder(input.displayOrder) ?? 0;
  const terms: CreatePlanInput = { ...input, name: input.name.trim(), description: input.description.trim(), code: normalisePlanCode(input.code) };
  const issues = planIssues(terms, await takenCodes(db));
  if (issues.length) refuse(issues);
  const fixed = versionTerms(terms);

  const id = await db.$transaction(async (tx) => {
    const plan = await tx.plan.create({
      data: {
        code: terms.code,
        name: terms.name,
        description: terms.description,
        displayOrder,
        versions: { create: versionCreate(1, fixed) },
      },
      select: { id: true },
    });
    await recordAuditLog(
      actor,
      {
        action: PLAN_AUDIT_ACTIONS.created,
        targetType: 'plan',
        targetId: plan.id,
        meta: { code: terms.code, name: terms.name, version: 1, terms: fixed },
      },
      tx,
    );
    return plan.id;
  });
  return getPlan(id);
}

/**
 * Edits a plan. Name, description and display order change on the plan itself. A change to any
 * commercial term — currency, a price, which cycles are sold, the trial, a feature or a limit — adds
 * the next version and never touches an earlier one. The code can change only while the plan is a draft: once it has been
 * offered, billing keys on it. An edit that changes nothing writes nothing and no audit event.
 */
export async function updatePlan(actor: AuditActor, id: string, input: UpdatePlanInput): Promise<PlanRecord> {
  assertPlatformWriter(actor, 'edit a plan');
  const current = await loadPlan(db, id);
  const displayOrder = optionalOrder(input.displayOrder) ?? current.displayOrder;
  const merged: CreatePlanInput = { ...inputOf(current), ...stripUndefined(input) };
  const terms: CreatePlanInput = { ...merged, name: merged.name.trim(), description: merged.description.trim(), code: normalisePlanCode(merged.code) };

  if (terms.code !== current.code && current.status !== 'draft') {
    throw conflict(`The code of a plan that has been offered cannot change. ${current.code} stays as it is.`, [
      { field: 'code', message: 'A plan code is fixed once the plan has left draft.' } satisfies PlanIssue,
    ]);
  }
  const issues = planIssues(terms, await takenCodes(db, id));
  if (issues.length) refuse(issues);

  const next = versionTerms(terms);
  const was = versionTerms(inputOf(current));
  const termsChanged = !sameTerms(next, was);
  const changes: Record<string, { from: unknown; to: unknown }> = {};
  for (const key of ['code', 'name', 'description'] as const) if (terms[key] !== current[key]) changes[key] = { from: current[key], to: terms[key] };
  if (displayOrder !== current.displayOrder) changes.displayOrder = { from: current.displayOrder, to: displayOrder };
  if (!termsChanged && Object.keys(changes).length === 0) return current;

  await db.$transaction(async (tx) => {
    await tx.plan.update({
      where: { id },
      data: {
        code: terms.code,
        name: terms.name,
        description: terms.description,
        displayOrder,
        ...(termsChanged ? { versions: { create: versionCreate(current.current.version + 1, next) } } : {}),
        // A new version is a change to the plan even when nothing on the row itself moved.
        updatedAt: new Date(),
      },
    });
    await recordAuditLog(
      actor,
      {
        action: PLAN_AUDIT_ACTIONS.updated,
        targetType: 'plan',
        targetId: id,
        meta: {
          code: terms.code,
          ...(Object.keys(changes).length ? { changes } : {}),
          ...(termsChanged ? { version: { from: current.current.version, to: current.current.version + 1 }, terms: { from: was, to: next } } : {}),
        },
      },
      tx,
    );
    if (termsChanged) await recordGrantChanges(actor, tx, id, current.current.version + 1, was, next);
  });
  return getPlan(id);
}

/**
 * What a new version changes in what academies on it may do (§36): the features it adds and removes, and
 * each limit whose allowance moved (`null` is unlimited). Nothing is written when neither changed.
 */
async function recordGrantChanges(actor: AuditActor, tx: DbClient, planId: string, version: number, was: VersionTerms, next: VersionTerms) {
  const added = next.features.filter((f) => !was.features.includes(f));
  const removed = was.features.filter((f) => !next.features.includes(f));
  if (added.length || removed.length) {
    await recordAuditLog(actor, { action: PLAN_AUDIT_ACTIONS.entitlementChanged, targetType: 'plan', targetId: planId, meta: { version, added, removed } }, tx);
  }
  const limits: Record<string, { from: number | null; to: number | null }> = {};
  for (const key of LIMIT_KEYS) if (was.limits[key] !== next.limits[key]) limits[key] = { from: was.limits[key], to: next.limits[key] };
  if (Object.keys(limits).length) {
    await recordAuditLog(actor, { action: PLAN_AUDIT_ACTIONS.limitChanged, targetType: 'plan', targetId: planId, meta: { version, limits } }, tx);
  }
}

/** Puts a draft on sale. */
export const publishPlan = (actor: AuditActor, id: string) =>
  transition(actor, id, {
    what: 'publish a plan',
    from: ['draft'],
    to: 'active',
    action: PLAN_AUDIT_ACTIONS.published,
    refused: (plan) => (plan.status === 'active' ? `${plan.name} is already on sale.` : `${plan.name} is archived — restore it instead.`),
  });

/** Stops offering a plan. Subscriptions already on it keep it, and their version, unchanged. */
export const archivePlan = (actor: AuditActor, id: string) =>
  transition(actor, id, {
    what: 'archive a plan',
    from: ['draft', 'active'],
    to: 'archived',
    action: PLAN_AUDIT_ACTIONS.archived,
    refused: (plan) => `${plan.name} is already archived.`,
  });

/** Offers an archived plan again, on the terms of its current version. */
export const restorePlan = (actor: AuditActor, id: string) =>
  transition(actor, id, {
    what: 'restore a plan',
    from: ['archived'],
    to: 'active',
    action: PLAN_AUDIT_ACTIONS.restored,
    refused: (plan) => `Only an archived plan can be restored; ${plan.name} is ${plan.status}.`,
  });

async function transition(
  actor: AuditActor,
  id: string,
  step: { what: string; from: PlanStatus[]; to: PlanStatus; action: string; refused: (plan: PlanRecord) => string },
): Promise<PlanRecord> {
  assertPlatformWriter(actor, step.what);
  const plan = await loadPlan(db, id);
  if (!step.from.includes(plan.status)) throw conflict(step.refused(plan));

  await db.$transaction(async (tx) => {
    // The status is part of the filter, so two concurrent transitions cannot both succeed.
    const moved = await tx.plan.updateMany({
      where: { id, status: plan.status },
      data: { status: step.to, archivedAt: step.to === 'archived' ? new Date() : null },
    });
    if (moved.count !== 1) throw conflict('The plan changed while this was being saved. Reload it and try again.');
    await recordAuditLog(
      actor,
      { action: step.action, targetType: 'plan', targetId: id, meta: { code: plan.code, status: { from: plan.status, to: step.to } } },
      tx,
    );
  });
  return getPlan(id);
}

function stripUndefined<T extends object>(value: T): Partial<T> {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as Partial<T>;
}
