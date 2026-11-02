import { Router } from 'express';
import { BILLING_CYCLES, PAYMENT_STATUSES, SUBSCRIPTION_STATUSES, type BillingCycle, type PaymentStatus, type SubscriptionStatus } from '@syniastrolms/domain';

import { invoiceView, paymentList, planDetail, planList, subscriberList, subscriptionOverview, subscriptionView } from '../lib/billingViews.js';
import { asyncHandler } from '../lib/errors.js';
import { optionalEnum, parseQuery, searchText, z } from '../lib/validate.js';

/*
 * The Super Admin subscription screens' read models (SAAS-015), as `packages/domain/src/billingViews.ts`
 * names them. Mounted inside `superadminRouter` at `/billing-views`, so every route has passed
 * `requireAuth` and `requireSuperAdmin` and runs as the platform. Read-only: every change goes through the
 * billing endpoints (`billingPlatform.ts`), and every figure here is computed by `lib/billingViews.ts`.
 */

export const billingViewsRouter = Router();

const all = <T extends string>(values: readonly T[]) => optionalEnum([...values, 'all'] as readonly (T | 'all')[]);
const day = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/)
  .optional();
const page = { page: z.coerce.number().int().min(1).max(10_000).optional(), pageSize: z.coerce.number().int().min(1).max(100).optional() };

billingViewsRouter.get(
  '/overview',
  asyncHandler(async (_req, res) => {
    res.json(await subscriptionOverview());
  }),
);

billingViewsRouter.get(
  '/plans',
  asyncHandler(async (req, res) => {
    const q = parseQuery(
      req,
      z.object({
        search: searchText,
        status: all(['draft', 'active', 'archived'] as const),
        sort: optionalEnum(['name', 'price', 'subscribers', 'updated'] as const),
      }),
    );
    res.json(await planList(q));
  }),
);

billingViewsRouter.get(
  '/plans/:id',
  asyncHandler(async (req, res) => {
    res.json(await planDetail(req.params.id));
  }),
);

billingViewsRouter.get(
  '/subscribers',
  asyncHandler(async (req, res) => {
    const q = parseQuery(
      req,
      z.object({
        search: searchText,
        planId: z.string().max(64).optional(),
        status: all(SUBSCRIPTION_STATUSES as readonly SubscriptionStatus[]),
        cycle: all(BILLING_CYCLES as readonly BillingCycle[]),
        payment: all(PAYMENT_STATUSES as readonly PaymentStatus[]),
        from: day,
        to: day,
        sort: optionalEnum(['renewal', 'started', 'customer', 'amount'] as const),
        ...page,
      }),
    );
    res.json(await subscriberList(q));
  }),
);

billingViewsRouter.get(
  '/subscriptions/:id',
  asyncHandler(async (req, res) => {
    res.json(await subscriptionView(req.params.id));
  }),
);

billingViewsRouter.get(
  '/payments',
  asyncHandler(async (req, res) => {
    const q = parseQuery(
      req,
      z.object({ search: searchText, status: all(PAYMENT_STATUSES as readonly PaymentStatus[]), planId: z.string().max(64).optional(), ...page }),
    );
    res.json(await paymentList(q));
  }),
);

billingViewsRouter.get(
  '/invoices/:id',
  asyncHandler(async (req, res) => {
    res.json(await invoiceView(req.params.id));
  }),
);
