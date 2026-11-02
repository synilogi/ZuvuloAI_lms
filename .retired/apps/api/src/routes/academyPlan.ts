import { Router } from 'express';
import type { AcademyPlan } from '@syniastrolms/domain';

import { requireAuth, requireRole } from '../lib/auth.js';
import { entitlementEnforcement, getTenantEntitlements } from '../lib/entitlements.js';
import { db } from '../lib/db.js';
import { asyncHandler } from '../lib/errors.js';
import { getSettings } from '../lib/settings.js';
import { currentSubscription } from '../lib/subscriptions.js';
import { currentTenantId } from '../lib/tenancy.js';

/*
 * What the academy's plan lets its staff use (`AcademyPlan`, packages/domain/src/entitlement.ts), so the
 * workspace can show each module open, read-only or locked before anyone clicks into a refusal. Readable by
 * every member of the academy's staff — admins and instructors — since both see plan-gated modules. It names
 * the plan and its features, never prices, invoices or payments: those stay on the admin's billing page.
 */

export const academyPlanRouter = Router();

academyPlanRouter.get(
  '/plan',
  requireAuth,
  requireRole('instructor'),
  asyncHandler(async (_req, res) => {
    const tenantId = currentTenantId();
    const [granted, subscription, row, { general }] = await Promise.all([
      getTenantEntitlements(tenantId),
      currentSubscription(tenantId),
      db.tenant.findUniqueOrThrow({ where: { id: tenantId }, select: { name: true, slug: true } }),
      getSettings(),
    ]);
    const live = subscription && !['canceled', 'expired'].includes(subscription.status) ? subscription : null;
    const body: AcademyPlan = {
      enforced: entitlementEnforcement(),
      status: granted.status,
      restricted: !granted.planVersionId,
      plan: granted.plan,
      features: granted.features,
      lastFeatures: granted.planVersionId ? [] : granted.lastFeatures,
      ...(live?.status === 'trialing' && live.trialEndAt ? { trialEndsAt: live.trialEndAt } : {}),
      ...(live && live.status !== 'trialing' ? { renewsAt: live.currentPeriodEndAt } : {}),
      academy: { name: general.academyName || row.name, slug: row.slug },
    };
    res.json(body);
  }),
);
