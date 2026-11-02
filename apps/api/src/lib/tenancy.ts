import { AsyncLocalStorage } from 'node:async_hooks';
import { Prisma, type PrismaClient } from '@prisma/client';

import { notFound } from './errors.js';

/*
 * Tenant isolation, enforced at the query boundary.
 *
 * Every academy-owned row carries a `tenantId`. This module holds the academy a piece of work is
 * running for — a request, a scheduled job, a script — and a Prisma extension that applies it to
 * every query on an academy-owned model: reads and filtered writes gain `tenantId` in their
 * `where`, creates are stamped with it (nested creates included), and every foreign key a write
 * names is checked to belong to the same academy. A query on an academy-owned model that runs with
 * no context at all is refused rather than run across every academy.
 *
 * Decisions this rests on (.claude/saas/progress.md): a person belongs to one academy (D1), email
 * is unique across the platform (D2), and the academy comes from the authenticated server context
 * and never from the client (D3).
 *
 * The platform context is the one controlled exception: it runs a query across every academy. It
 * is taken only by the Super Admin router, the scheduler that walks the academies, operator scripts,
 * and a short list of lookups that are platform-wide by decision — sign-in and registration by email
 * (D2), reset tokens, and certificate credential IDs (D4). Each call names its reason.
 */

/* ─── Which models belong to an academy ────────────────────────────────── */

/** Academy-owned: every row belongs to exactly one academy. */
export const TENANT_OWNED_MODELS = [
  'MediaAsset',
  'Level',
  'Category',
  'CategoryLevel',
  'Instructor',
  'Course',
  'CourseInstructor',
  'Chapter',
  'Lesson',
  'Student',
  'Enrollment',
  'LessonProgress',
  'LessonNote',
  'LessonBookmark',
  'SavedCourse',
  'Rank',
  'Quiz',
  'QuizAttempt',
  'QuizSession',
  'CourseAssignment',
  'AssignmentDraft',
  'Submission',
  'CertificateTemplate',
  'IssuedCertificate',
  'LiveClass',
  'LiveRegistration',
  'CalendarEvent',
  'Settings',
  'AdminPermission',
  'Subscription',
  'SubscriptionEvent',
  'PlanChange',
  'BillingProfile',
  'Invoice',
  'Payment',
  'Refund',
  'PaymentMethod',
  'UsageGuard',
  'PaymentOrder',
  'Invitation',
  // A learner or instructor waiting to verify their email, in the academy its link named.
  'PendingAccount',
  // Course sales: the academy's own gateway and credentials, its learners' purchases, and the webhooks they get.
  'AcademyPaymentConfig',
  'AcademyGatewayCredential',
  'CoursePurchase',
  'CoursePaymentEvent',
  'Coupon',
  'SiteContent',
  'CouponRedemption',
  'CourseReview',
  'CoursePurchaseRefund',
  // The affiliate program's members: learners of the program academy (MLM-001).
  'Affiliate',
  'MlmPlacementHistory',
  // Orders, the CV ledger and leg pools (MLM-003).
  'MlmOrder',
  'MlmCvLedger',
  'MlmLegBalance',
  'MlmMatchingRun',
  'MlmRankHistory',
  'MlmReward',
  'MlmCommission',
  'MlmWallet',
  'MlmWalletEntry',
  'MlmKyc',
  'MlmPayoutBatch',
  'MlmWithdrawal',
  'MlmProgramState',
] as const;

/**
 * Academy-owned, except for the platform's own rows: a super admin belongs to no academy, and so
 * neither do its reset tokens, notification settings, notifications or email. `tenantId` is null for
 * those and for nothing else.
 */
export const TENANT_OR_PLATFORM_MODELS = [
  'User',
  // A website visitor's request belongs to no academy; an academy admin's support request to theirs (SAAS-027).
  'Inquiry',
  'PasswordResetToken',
  'UserSession',
  'NotificationSettings',
  'AppNotification',
  'EmailOutbox',
  'DeviceToken',
  'PushDelivery',
] as const;

/** Belong to the platform and carry no `tenantId`: the academies themselves, the Help Centre (D5), the platform audit trail, and the plans academies subscribe to with their entitlement catalogue and grants (SAAS-001, SAAS-002), and the tax rules charges are taxed by (SAAS-007), and the provider webhooks received (SAAS-010) — which arrive with no academy and are matched to one by the checkout they settle — and the scheduler's job leases (SAAS-022), and self-serve registrations waiting for their email to be verified, which have no academy until they are (SAAS-026), and the platform's own logo and favicon, which no academy sets. */
export const PLATFORM_MODELS = [
  'Tenant',
  'OrderSequence',
  'HelpCategory',
  'HelpArticle',
  'AuditLog',
  'Plan',
  'PlanVersion',
  'Feature',
  'LimitDefinition',
  'PlanFeature',
  'PlanLimit',
  'TaxRule',
  'TaxRuleComponent',
  'InvoiceSequence',
  'WebhookEvent',
  'PaymentGatewayConfig',
  'PaymentGatewayCredential',
  'JobLease',
  'PendingSignup',
  'PlatformBrandAsset',
  // The affiliate program's plan versions, ranks and cap bands (MLM-000): the company's terms, naming the program academy.
  'MlmPlanVersion',
  'MlmRankTier',
  'MlmCapBand',
] as const;

const SCOPED = new Set<string>([...TENANT_OWNED_MODELS, ...TENANT_OR_PLATFORM_MODELS]);

export const isScopedModel = (model: string) => SCOPED.has(model);

/** The academy that existed before tenancy, created by the tenant_foundation migration. */
export const FIRST_TENANT_ID = 'tenant-1';

/* ─── The context a piece of work runs in ─────────────────────────────── */

export type TenantContext = { kind: 'tenant'; tenantId: string } | { kind: 'platform'; reason: string };

const storage = new AsyncLocalStorage<TenantContext>();

/*
 * Prisma queries are lazy: `db.user.findUnique(...)` returns a thenable that runs only when something
 * awaits it. Returned from a context unawaited, it would run later — in the caller's context, not this
 * one. So each of these awaits `fn` *inside* the context, and the query starts while it is in force.
 */
const within = <T>(context: TenantContext, fn: () => T | PromiseLike<T>): Promise<Awaited<T>> =>
  storage.run(context, async (): Promise<Awaited<T>> => (await fn()) as Awaited<T>);

/** Runs `fn` for one academy: every query inside is confined to it. */
export const runInTenant = <T>(tenantId: string, fn: () => T | PromiseLike<T>): Promise<Awaited<T>> => within({ kind: 'tenant', tenantId }, fn);

/** Runs `fn` across every academy. Name the reason — it is what a reviewer reads to judge the exception. */
export const runAsPlatform = <T>(reason: string, fn: () => T | PromiseLike<T>): Promise<Awaited<T>> => within({ kind: 'platform', reason }, fn);

/** Runs `fn` in the context an account lives in: its academy, or the platform for a super admin. */
export const runAsOwnerOf = <T>(owner: { tenantId: string | null }, fn: () => T | PromiseLike<T>): Promise<Awaited<T>> =>
  owner.tenantId ? runInTenant(owner.tenantId, fn) : runAsPlatform('a platform account acting on its own rows', fn);

export const currentContext = (): TenantContext | undefined => storage.getStore();

/** The academy the current work runs for. Throws outside one — a platform context has no single academy. */
export function currentTenantId(): string {
  const ctx = storage.getStore();
  if (ctx?.kind !== 'tenant')
    throw new TenantContextError(ctx ? `This needs an academy, but it is running as the platform (${ctx.reason}).` : 'This needs an academy, and none is set.');
  return ctx.tenantId;
}

/**
 * The academy a new row belongs to, spelled out at the call site: `data: { ...tenant(), title }`.
 * The extension would stamp it anyway; writing it keeps every create's academy visible to a reader
 * and to the type checker, and the extension still refuses a value that differs from the context.
 */
export const tenant = (): { tenantId: string } => ({ tenantId: currentTenantId() });

/**
 * `TENANT_ENFORCEMENT=off` is the rollback switch: writes are still stamped with their academy, so
 * data stays correct, but reads are no longer filtered and a missing context is allowed. It is only
 * safe while the platform has a single academy.
 */
export const tenantEnforcement = () => process.env.TENANT_ENFORCEMENT !== 'off';

/**
 * Called once at boot. With more than one Admin's data on the platform, turning isolation off would show every
 * Admin everyone's data, so a production process refuses \`TENANT_ENFORCEMENT=off\` outright (multi-admin SaaS).
 */
export function assertTenancyConfig(env: NodeJS.ProcessEnv = process.env) {
  if (env.NODE_ENV === 'production' && env.TENANT_ENFORCEMENT === 'off') {
    throw new Error('TENANT_ENFORCEMENT=off is refused in production: it would stop separating one Admin’s data from another’s.');
  }
}

/** A query reached an academy-owned model with no academy to confine it to. Always a programming error. */
export class TenantContextError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'TenantContextError';
  }
}

/* ─── The schema, read once ───────────────────────────────────────────── */

interface Relation {
  target: string;
  /** The scalar foreign key on this model, when this side holds it. */
  from?: string;
}

const RELATIONS = new Map<string, Map<string, Relation>>();
for (const model of Prisma.dmmf.datamodel.models) {
  const byField = new Map<string, Relation>();
  for (const field of model.fields) {
    if (field.kind !== 'object') continue;
    const from = field.relationFromFields ?? [];
    const to = field.relationToFields ?? [];
    // Every foreign key in this schema is a single column naming the target's `id`; the schema test
    // asserts that, so a composite key added later cannot slip past the reference check unseen.
    byField.set(field.name, { target: field.type, from: from.length === 1 && to[0] === 'id' ? from[0] : undefined });
  }
  RELATIONS.set(model.name, byField);
}

/** Scalar foreign keys on `model` that point at an academy-owned model — the ones a write must not aim at another academy. */
const scopedForeignKeys = (model: string): [string, string][] =>
  [...(RELATIONS.get(model)?.values() ?? [])].filter((r) => r.from && r.from !== 'tenantId' && SCOPED.has(r.target)).map((r) => [r.from!, r.target]);

/* ─── The extension ───────────────────────────────────────────────────── */

type Args = Record<string, unknown>;

const READS = new Set(['findUnique', 'findUniqueOrThrow', 'findFirst', 'findFirstOrThrow', 'findMany', 'count', 'aggregate', 'groupBy']);
const FILTERED_WRITES = new Set(['update', 'updateMany', 'updateManyAndReturn', 'delete', 'deleteMany']);
const CREATES = new Set(['create', 'createMany', 'createManyAndReturn']);

const isRecord = (v: unknown): v is Args => typeof v === 'object' && v !== null && !Array.isArray(v);
const asList = <T>(v: T | T[] | undefined): T[] => (v === undefined ? [] : Array.isArray(v) ? v : [v]);

/** Adds the academy to a filter. A filter that already names a different academy is refused, never widened. */
function withTenant(where: unknown, tenantId: string, model: string): Args {
  const base = isRecord(where) ? where : {};
  if (base.tenantId !== undefined && base.tenantId !== tenantId) throw new TenantContextError(`A ${model} query named another academy.`);
  return { ...base, tenantId };
}

/**
 * Stamps a create payload with the academy, and every nested create beneath it. Collects the foreign
 * keys the payload names so they can be checked against the academy afterwards.
 */
function stampCreate(model: string, data: unknown, tenantId: string, refs: Map<string, Set<string>>): Args {
  if (!isRecord(data)) return data as Args;
  if (data.tenantId !== undefined && data.tenantId !== tenantId) throw new TenantContextError(`A ${model} was created for another academy.`);
  collectRefs(model, data, refs);
  const out: Args = { ...data, tenantId };
  for (const [key, value] of Object.entries(data)) {
    const rel = RELATIONS.get(model)?.get(key);
    if (!rel || !isRecord(value) || !SCOPED.has(rel.target)) continue;
    out[key] = stampNested(rel.target, value, tenantId, refs);
  }
  return out;
}

/** Walks one nested-write object (`{ create, createMany, upsert, update, ... }`) for a relation. */
function stampNested(model: string, nested: Args, tenantId: string, refs: Map<string, Set<string>>): Args {
  const out: Args = { ...nested };
  if (nested.create !== undefined) {
    const items = asList(nested.create as Args | Args[]).map((item) => stampCreate(model, item, tenantId, refs));
    out.create = Array.isArray(nested.create) ? items : items[0];
  }
  if (isRecord(nested.createMany)) {
    out.createMany = { ...nested.createMany, data: asList(nested.createMany.data as Args | Args[]).map((item) => stampCreate(model, item, tenantId, refs)) };
  }
  if (nested.connectOrCreate !== undefined) {
    const items = asList(nested.connectOrCreate as Args | Args[]).map((item) => ({ ...item, create: stampCreate(model, item.create, tenantId, refs) }));
    out.connectOrCreate = Array.isArray(nested.connectOrCreate) ? items : items[0];
  }
  if (nested.upsert !== undefined) {
    const items = asList(nested.upsert as Args | Args[]).map((item) => ({
      ...item,
      create: stampCreate(model, item.create, tenantId, refs),
      update: checkUpdate(model, item.update, tenantId, refs),
    }));
    out.upsert = Array.isArray(nested.upsert) ? items : items[0];
  }
  for (const key of ['connect', 'set'] as const) {
    for (const target of asList(nested[key] as Args | Args[])) if (typeof target?.id === 'string') addRef(refs, model, target.id);
  }
  return out;
}

/** An update may not move a row to another academy, and may not point it at another academy's rows. */
function checkUpdate(model: string, data: unknown, tenantId: string, refs: Map<string, Set<string>>): Args {
  if (!isRecord(data)) return data as Args;
  if (data.tenantId !== undefined && data.tenantId !== tenantId) throw new TenantContextError(`A ${model} cannot be moved to another academy.`);
  collectRefs(model, data, refs);
  const out: Args = { ...data };
  for (const [key, value] of Object.entries(data)) {
    const rel = RELATIONS.get(model)?.get(key);
    if (!rel || !isRecord(value) || !SCOPED.has(rel.target)) continue;
    out[key] = stampNested(rel.target, value, tenantId, refs);
  }
  return out;
}

function addRef(refs: Map<string, Set<string>>, target: string, id: string) {
  if (!refs.has(target)) refs.set(target, new Set());
  refs.get(target)!.add(id);
}

function collectRefs(model: string, data: Args, refs: Map<string, Set<string>>) {
  for (const [field, target] of scopedForeignKeys(model)) {
    const value = data[field];
    if (typeof value === 'string') addRef(refs, target, value);
  }
}

/**
 * Every row a write points at must be in the same academy. Checked on the unscoped client with the
 * academy spelled out, so the check itself cannot be widened or recurse. A miss answers 404, exactly
 * as a missing row would: another academy's ids are never confirmed to exist.
 *
 * The check reads committed rows. Inside an interactive transaction in an academy context, a row
 * created earlier in the same transaction is not visible to it yet — no such transaction exists today
 * (the only interactive ones are the Super Admin's, which run as the platform).
 */
async function assertReferences(base: PrismaClient, refs: Map<string, Set<string>>, tenantId: string) {
  for (const [target, ids] of refs) {
    const list = [...ids];
    const delegate = (base as unknown as Record<string, { count: (a: Args) => Promise<number> }>)[target[0].toLowerCase() + target.slice(1)];
    // A Super Admin has no tenant and works in the workspace (docs/16, D-PLAT-03), so a row may name that account: a
    // User with no tenant is a platform account by the invariant below, never another academy's.
    const scope = target === 'User' ? { OR: [{ tenantId }, { tenantId: null }] } : { tenantId };
    const found = await delegate.count({ where: { id: { in: list }, ...scope } });
    if (found !== list.length) throw notFound(`${target === 'User' ? 'Account' : target.replace(/([a-z])([A-Z])/g, '$1 $2')} not found.`);
  }
}

/**
 * A person belongs to an academy exactly when they are not a super admin (D1). Checked on every
 * account created, in any context, so neither a tenantless academy account nor an academy-bound
 * super admin can be written.
 */
function assertUserInvariant(operation: string, args: Args) {
  const rows =
    operation === 'upsert'
      ? [args.create]
      : operation === 'createMany' || operation === 'createManyAndReturn'
        ? asList((args.data as Args | Args[]) ?? [])
        : [args.data];
  for (const row of rows) {
    if (!isRecord(row) || row.role === undefined) continue;
    const platform = row.role === 'superadmin';
    const hasTenant = typeof row.tenantId === 'string';
    if (platform && hasTenant) throw new TenantContextError('A super admin belongs to the platform, not to an academy.');
    if (!platform && !hasTenant) throw new TenantContextError('An academy account needs an academy.');
  }
}

/** Builds the tenancy extension over `base`, which it uses for its own unscoped reference checks. */
export function tenancyExtension(base: PrismaClient) {
  return Prisma.defineExtension({
    name: 'tenancy',
    query: {
      $allModels: {
        async $allOperations({ model, operation, args, query }) {
          if (!model || !SCOPED.has(model)) return query(args);
          const a = { ...(args as Args) };
          const ctx = storage.getStore();

          if (!tenantEnforcement()) {
            // Rollback mode: keep stamping new rows so the data stays right, filter nothing.
            if (ctx?.kind === 'tenant' && CREATES.has(operation)) {
              const refs = new Map<string, Set<string>>();
              a.data = Array.isArray(a.data) ? a.data.map((d) => stampCreate(model, d, ctx.tenantId, refs)) : stampCreate(model, a.data, ctx.tenantId, refs);
            }
            if (model === 'User' && (CREATES.has(operation) || operation === 'upsert')) assertUserInvariant(operation, a);
            return query(a as typeof args);
          }

          if (!ctx) throw new TenantContextError(`${model}.${operation} ran with no academy and no platform context.`);
          if (ctx.kind === 'platform') {
            if (model === 'User' && (CREATES.has(operation) || operation === 'upsert')) assertUserInvariant(operation, a);
            return query(a as typeof args);
          }

          const { tenantId } = ctx;
          const refs = new Map<string, Set<string>>();
          if (READS.has(operation) || FILTERED_WRITES.has(operation) || operation === 'upsert') a.where = withTenant(a.where, tenantId, model);
          if (CREATES.has(operation)) {
            a.data = Array.isArray(a.data) ? a.data.map((d) => stampCreate(model, d, tenantId, refs)) : stampCreate(model, a.data, tenantId, refs);
          }
          if (FILTERED_WRITES.has(operation) && a.data !== undefined) a.data = checkUpdate(model, a.data, tenantId, refs);
          if (operation === 'upsert') {
            a.create = stampCreate(model, a.create, tenantId, refs);
            a.update = checkUpdate(model, a.update, tenantId, refs);
          }
          if (model === 'User' && (CREATES.has(operation) || operation === 'upsert')) assertUserInvariant(operation, a);
          if (refs.size) await assertReferences(base, refs, tenantId);
          return query(a as typeof args);
        },
      },
    },
  });
}

/**
 * An extension that runs every query of a client inside one context. It has to sit *under* the
 * tenancy extension — Prisma runs query hooks in the order extensions were added — so a bound client
 * is built from the base client up, never stacked on top of `db`.
 */
export function bindContext(context: TenantContext) {
  return Prisma.defineExtension({
    name: 'bind-context',
    // Awaited inside the context: the next hook (tenancy) must start while the context is in force.
    query: { $allModels: { $allOperations: ({ args, query }) => storage.run(context, async () => await query(args)) } },
  });
}
