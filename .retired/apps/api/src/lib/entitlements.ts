import {
  FEATURE_KEYS,
  LIMIT_KEYS,
  RESTRICTED_MODE_POLICY,
  featureLabel,
  type FeatureKey,
  type LimitKey,
  type PlanLimits,
  type RestrictedOperation,
  type SubscriptionState,
} from '@syniastrolms/domain';
import type { NextFunction, Request, RequestHandler, Response } from 'express';

import { db, type DbClient } from './db.js';
import { ApiError, type ErrorCode } from './errors.js';
import { resolvePlanVersion } from './plans.js';
import { subscriptionPlanFor } from './subscriptions.js';
import { now as clockNow } from './clock.js';
import { currentContext, currentTenantId, runInTenant } from './tenancy.js';

/*
 * The entitlement service (subscriptions.md §22) — the single way any module asks what an academy's
 * plan allows. No route, job or other module reads the plan or subscription tables itself (the lint
 * rule in eslint.config.js keeps routes out of them); they ask here.
 *
 *   getTenantEntitlements(tenantId)   what the academy's plan grants
 *   hasFeature(tenantId, feature)     one feature
 *   getLimit(tenantId, limit)         one limit: a number, null for unlimited, 0 for none
 *   getUsage(tenantId, limit)         how much of it the academy uses now
 *   canConsume(tenantId, limit, n)    whether n more fit
 *
 * Authorization order is fixed (§33): authenticated → role / permission → tenant isolation →
 * entitlement → operation. `requireFeature` is written to sit after `requireAuth`, `requireRole` and
 * `requirePermission` on a route, inside the tenant context every academy request already runs in. It
 * never replaces any of them: a caller needs the permission *and* the academy needs the entitlement
 * (§41), and the two refusals carry different codes — `PERMISSION_DENIED` against `FEATURE_NOT_INCLUDED`
 * or `SUBSCRIPTION_REQUIRED`.
 *
 * Which plan version an academy is on, the academy's subscription answers (SAAS-004,
 * `subscriptionPlanFor`): its plan while trialing, active, past due or cancelling, nothing while paused
 * or once over. An academy that has never subscribed is entitled to nothing — and enforcement ships
 * switched off (`ENTITLEMENT_ENFORCEMENT`, §50), so nothing changes for anyone until it is switched on
 * deliberately.
 */

/* ─── What an academy is entitled to ──────────────────────────────────── */

export interface TenantEntitlements {
  tenantId: string;
  /** The subscription's status, or null when the academy has never subscribed. */
  status: SubscriptionState | null;
  /** The plan version these come from, or null when the academy is served no plan — then it is granted nothing. */
  planVersionId: string | null;
  plan: { id: string; code: string; name: string } | null;
  features: FeatureKey[];
  /** A value for every catalogue limit: a number, `null` for unlimited, 0 for none. */
  limits: PlanLimits;
  /**
   * While served no plan (paused, cancelled, expired): the features of the plan the academy last had, which
   * restricted mode keeps open for the operations its policy allows (SAAS-025). Empty for an academy that has
   * never subscribed, and equal to `features` while it is served a plan.
   */
  lastFeatures: FeatureKey[];
}

/**
 * Answers which plan version an academy is served and under what status — `planVersionId` null when
 * the status serves none — or null when it has never subscribed.
 */
export type TenantPlanSource = (
  tenantId: string,
) => Promise<{ planVersionId: string | null; status: SubscriptionState; lastPlanVersionId?: string | null } | null>;

let planSource: TenantPlanSource = subscriptionPlanFor;

/** Replaces where the plan comes from — for tests. `null` puts the subscription back. */
export function setTenantPlanSource(source: TenantPlanSource | null): void {
  planSource = source ?? subscriptionPlanFor;
}

const NOTHING = Object.fromEntries(LIMIT_KEYS.map((key) => [key, 0])) as PlanLimits;

export async function getTenantEntitlements(tenantId: string): Promise<TenantEntitlements> {
  const served = await planSource(tenantId);
  if (!served?.planVersionId) {
    const last = served?.lastPlanVersionId ? await resolvePlanVersion(served.lastPlanVersionId) : null;
    return {
      tenantId,
      status: served?.status ?? null,
      planVersionId: null,
      plan: null,
      features: [],
      limits: { ...NOTHING },
      lastFeatures: last ? FEATURE_KEYS.filter((key) => last.features.includes(key)) : [],
    };
  }
  const version = await resolvePlanVersion(served.planVersionId);
  const features = FEATURE_KEYS.filter((key) => version.features.includes(key));
  return {
    tenantId,
    status: served.status,
    planVersionId: version.id,
    plan: { id: version.plan.id, code: version.plan.code, name: version.plan.name },
    features,
    limits: version.limits,
    lastFeatures: features,
  };
}

export async function hasFeature(tenantId: string, feature: FeatureKey): Promise<boolean> {
  return (await getTenantEntitlements(tenantId)).features.includes(feature);
}

/** The academy's limit: a number, `null` for unlimited, 0 when its plan sets none or it has no plan. */
export async function getLimit(tenantId: string, limit: LimitKey): Promise<number | null> {
  return (await getTenantEntitlements(tenantId)).limits[limit];
}

/* ─── Usage ────────────────────────────────────────────────────────────── */

/** The first instant of the calendar month `at` falls in, and of the next, in UTC. */
function monthOf(at: Date): { from: Date; to: Date } {
  return { from: new Date(Date.UTC(at.getUTCFullYear(), at.getUTCMonth(), 1)), to: new Date(Date.UTC(at.getUTCFullYear(), at.getUTCMonth() + 1, 1)) };
}

/**
 * What each limit counts, calculated live from the academy's own rows. The per-metric strategy —
 * live, cached, counted or reconciled — and concurrency safety are SAAS-011's; these are the
 * definitions it starts from.
 */
const USAGE: Record<LimitKey, (client: DbClient, tenantId: string, at: Date) => Promise<number>> = {
  // Each count names the academy itself, so it counts that academy's rows in any context — an
  // academy's own, or the platform's when a super admin acts for it.
  'learners.max': (c, tenantId) => c.student.count({ where: { tenantId } }),
  // An instructor who has left no longer takes a seat; an invited one does, because they can accept.
  // A self-registration still waiting for approval, or refused, is not staff and takes no seat (D34).
  'instructors.max': (c, tenantId) => c.instructor.count({ where: { tenantId, status: { notIn: ['inactive', 'pending', 'rejected'] } } }),
  // An archived course is kept but no longer counts.
  'courses.max': (c, tenantId) => c.course.count({ where: { tenantId, status: { not: 'archived' } } }),
  'storage.bytes': async (c, tenantId) => (await c.mediaAsset.aggregate({ where: { tenantId }, _sum: { sizeBytes: true } }))._sum.sizeBytes ?? 0,
  // Live classes that start in the calendar month (UTC) of `at`, cancelled ones excepted.
  'live_classes.max': (c, tenantId, at) => {
    const { from, to } = monthOf(at);
    return c.liveClass.count({ where: { tenantId, cancelled: false, startsAt: { gte: from, lt: to } } });
  },
  'admin_accounts.max': (c, tenantId) => c.user.count({ where: { tenantId, role: 'admin', deactivatedAt: null } }),
};

/**
 * How much of a limit the academy uses — for `live_classes.max`, in the month of `at`. Runs inside the
 * academy's own context, so it counts that academy's rows and no one else's, whatever context it is
 * called from. `client` is a transaction to count inside (`lib/usage.ts`), already in the academy.
 */
export async function getUsage(tenantId: string, limit: LimitKey, at: Date = clockNow(), client?: DbClient): Promise<number> {
  if (client) return USAGE[limit](client, tenantId, at);
  const context = currentContext();
  if (context?.kind === 'tenant' && context.tenantId === tenantId) return USAGE[limit](db, tenantId, at);
  return runInTenant(tenantId, () => USAGE[limit](db, tenantId, at));
}

export interface Capacity {
  allowed: boolean;
  /** The limit: a number, or null for unlimited. */
  limit: number | null;
  usage: number;
  /** What is left before the limit, or null for unlimited. Never below zero. */
  remaining: number | null;
}

/**
 * Whether `amount` more of a limit fit the academy's plan. Not concurrency-safe on its own: two
 * requests can both read the same usage. SAAS-011 makes the check and the write atomic where a hard
 * limit needs it.
 */
export async function canConsume(tenantId: string, limit: LimitKey, amount = 1, now: Date = clockNow()): Promise<Capacity> {
  const [ceiling, usage] = await Promise.all([getLimit(tenantId, limit), getUsage(tenantId, limit, now)]);
  if (ceiling === null) return { allowed: true, limit: null, usage, remaining: null };
  return { allowed: usage + amount <= ceiling, limit: ceiling, usage, remaining: Math.max(0, ceiling - usage) };
}

/* ─── Refusing ─────────────────────────────────────────────────────────── */

/** The academy's plan does not allow this (§34). Never used for a missing permission — that is `PERMISSION_DENIED`. */
export class EntitlementError extends ApiError {
  constructor(code: Extract<ErrorCode, 'SUBSCRIPTION_REQUIRED' | 'SUBSCRIPTION_EXPIRED' | 'FEATURE_NOT_INCLUDED' | 'LIMIT_REACHED'>, message: string) {
    // 402 when no plan is being served — the fix is to (re)subscribe; 403 when the plan is too small.
    super(code === 'SUBSCRIPTION_REQUIRED' || code === 'SUBSCRIPTION_EXPIRED' ? 402 : 403, message, undefined, code);
    this.name = 'EntitlementError';
  }
}

/**
 * Whether plans are enforced. \`on\` and \`off\` say so; unset means on in production — a deployment cannot lose plan
 * enforcement by forgetting a variable — and off elsewhere. \`off\` in production is the documented emergency
 * rollback, and the API says so loudly at boot (\`assertEnforcementConfig\`).
 */
export const entitlementEnforcement = (env: NodeJS.ProcessEnv = process.env) =>
  env.ENTITLEMENT_ENFORCEMENT === 'on' || (env.ENTITLEMENT_ENFORCEMENT !== 'off' && env.NODE_ENV === 'production');

/** The refusal for an academy served no plan: ended, paused, or never subscribed — each with the prompt it needs. */
export function notServed(granted: Pick<TenantEntitlements, 'status'>): EntitlementError {
  if (granted.status === 'canceled' || granted.status === 'expired')
    return new EntitlementError('SUBSCRIPTION_EXPIRED', 'This LMS’s subscription has ended. Renew it to use this.');
  if (granted.status === 'paused') return new EntitlementError('SUBSCRIPTION_REQUIRED', 'This LMS’s subscription is paused. Resume it to use this.');
  return new EntitlementError('SUBSCRIPTION_REQUIRED', 'This LMS has no plan. Choose one to use this.');
}

/**
 * Restricted mode (§21): the academy's subscription serves no plan. What it may still do is
 * `RESTRICTED_MODE_POLICY` — keep and edit what exists, take it down, serve its learners; add nothing.
 */
export async function isRestricted(tenantId: string): Promise<boolean> {
  return !(await getTenantEntitlements(tenantId)).planVersionId;
}

/** Refuses when the academy's plan does not grant `feature`. The entitlement step of the §33 order. */
export async function assertFeature(tenantId: string, feature: FeatureKey, opts: { restricted?: RestrictedOperation } = {}): Promise<void> {
  const granted = await getTenantEntitlements(tenantId);
  if (!granted.planVersionId) {
    // Restricted mode keeps what the academy had and adds nothing (§21): an operation the policy keeps open goes
    // ahead only for a feature its last plan included. An academy that never subscribed had none, so it is never
    // granted more than a subscribed lower tier (SAAS-025).
    if (opts.restricted && RESTRICTED_MODE_POLICY[opts.restricted].allowed && granted.lastFeatures.includes(feature)) return;
    throw notServed(granted);
  }
  if (!granted.features.includes(feature)) {
    throw new EntitlementError('FEATURE_NOT_INCLUDED', `${featureLabel(feature)} is not included in the ${granted.plan!.name} plan.`);
  }
}

/** Every feature some route gates on — so a test can prove the catalogue is actually enforced somewhere. */
export const GATED_FEATURES = new Set<FeatureKey>();

export interface FeatureGateOptions {
  /** Narrows the gate to the requests it applies to — the appearance section of settings, say. */
  when?: (req: Request) => boolean;
  /**
   * What the route is, under restricted mode (§21). An operation `RESTRICTED_MODE_POLICY` keeps open —
   * editing what exists — goes ahead while the academy is served no plan; anything else is refused with
   * the renew/subscribe prompt. Omitted, the route is closed in restricted mode.
   */
  restricted?: RestrictedOperation;
}

/**
 * Route middleware: the academy's plan must grant `feature`. Place it after `requireAuth`,
 * `requireRole` and any `requirePermission`, so a caller without permission is refused as such before
 * the plan is consulted. Does nothing while enforcement is off.
 */
export function requireFeature(feature: FeatureKey, opts: FeatureGateOptions = {}): RequestHandler {
  GATED_FEATURES.add(feature);
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!entitlementEnforcement() || (opts.when && !opts.when(req))) return next();
    assertFeature(currentTenantId(), feature, { restricted: opts.restricted }).then(() => next(), next);
  };
}

/**
 * Route middleware for a write no feature governs but restricted mode does — a sign-up, adding an
 * instructor, an upload: refused while the academy is served no plan, if the policy closes `operation`.
 */
export function requireUnrestricted(operation: RestrictedOperation): RequestHandler {
  return (_req: Request, _res: Response, next: NextFunction) => {
    if (!entitlementEnforcement() || RESTRICTED_MODE_POLICY[operation].allowed) return next();
    getTenantEntitlements(currentTenantId()).then((granted) => (granted.planVersionId ? next() : next(notServed(granted))), next);
  };
}
