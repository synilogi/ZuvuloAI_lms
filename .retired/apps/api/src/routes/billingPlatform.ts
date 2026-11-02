import { Router, type Request } from 'express';
import { BILLING_CYCLES, FEATURE_KEYS, LIMIT_KEYS, SUBSCRIPTION_STATES, type BillingCycle, type SubscriptionState } from '@syniastrolms/domain';

import { getBillingProfile, listTaxRules, retireTaxRule, setBillingProfile, setTaxRule } from '../lib/billing.js';
import { asyncHandler, notFound, stableCodes } from '../lib/errors.js';
import { getInvoice, listAllInvoices, listInvoices, voidInvoice, type InvoiceStatus } from '../lib/invoices.js';
import { OFFLINE_METHODS, recordOfflinePayment, refundThroughProvider } from '../lib/checkout.js';
import { activateGateway, configureGateway, deactivateActiveGateway, getGateway, listGateways, testGateway, updateGateway } from '../lib/paymentGateways.js';
import { listWebhookEvents } from '../lib/webhooks.js';
import { listAllPayments, listPayments, listRefunds, getPayment, type StoredPaymentStatus } from '../lib/payments.js';
import { listPlanChanges, requestPlanChange } from '../lib/planChanges.js';
import { archivePlan, createPlan, getPlan, listPlanVersions, listPlans, publishPlan, restorePlan, updatePlan } from '../lib/plans.js';
import {
  cancelNow,
  createSubscription,
  extendSubscription,
  getSubscription,
  listLifecycle,
  listSubscriptions,
  pauseSubscription,
  requestCancellation,
  resumeSubscription,
  type LifecycleActor,
} from '../lib/subscriptions.js';
import { optionalEnum, paging, parseBody, parseQuery, queryBool, z } from '../lib/validate.js';

/*
 * The Super Admin's billing surface (subscriptions.md §25, §32; SAAS-013): plans, subscriptions, invoices,
 * payments, refunds and tax rules across every academy. Mounted inside `superadminRouter`, so every route
 * here has already passed `requireAuth`, `requireSuperAdmin` and runs as the platform.
 *
 * Each route is thin: it parses the request and calls the service that owns the rule — `lib/plans.ts`,
 * `lib/subscriptions.ts`, `lib/invoices.ts`, `lib/payments.ts`, `lib/billing.ts`. No route reads a plan or
 * subscription table itself (lint rule), sets a price, or takes a figure the server should calculate.
 * Every refusal leaves with a stable code (`stableCodes`, §34).
 */

export const billingPlatformRouter = Router();

const actor = (req: Request): LifecycleActor => ({ type: 'user', auth: { sub: req.auth!.sub, role: req.auth!.role } });

const money = z.number().int().min(0).max(Number.MAX_SAFE_INTEGER);
// A value for every catalogue limit: a whole number, or null for unlimited. The domain checks the rest.
const limitsSchema = z.record(z.enum(LIMIT_KEYS as unknown as [string, ...string[]]), z.number().int().nullable());
const planSchema = z.object({
  name: z.string().max(120),
  description: z.string().max(500),
  code: z.string().max(40),
  currency: z.string().max(3),
  cycles: z.array(z.enum(BILLING_CYCLES as unknown as [BillingCycle, ...BillingCycle[]])).max(2),
  monthlyPrice: money,
  annualPrice: money,
  trialEnabled: z.boolean(),
  // The domain allows a trial of 1–90 days; 0 means none.
  trialDays: z.number().int().min(0).max(90),
  limits: limitsSchema,
  features: z.array(z.enum(FEATURE_KEYS as unknown as [string, ...string[]])).max(FEATURE_KEYS.length),
  displayOrder: z.number().int().min(0).max(10_000).optional(),
});
const planPatchSchema = planSchema.partial();

export const billingProfileSchema = z.object({
  legalName: z.string().max(200),
  email: z.string().max(254),
  addressLine1: z.string().max(200),
  addressLine2: z.string().max(200).optional(),
  city: z.string().max(100),
  region: z.string().max(10).optional(),
  postalCode: z.string().max(20),
  country: z.string().max(2),
  taxRegistration: z.string().max(40).optional(),
});

/* ─── Plans ─── */

billingPlatformRouter.get(
  '/plans',
  asyncHandler(async (req, res) => {
    const { status } = parseQuery(req, z.object({ status: optionalEnum(['draft', 'active', 'archived'] as const) }));
    const rows = await listPlans(status ? { status } : {});
    res.json({ rows, total: rows.length });
  }),
);

billingPlatformRouter.post(
  '/plans',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, planSchema);
    res.status(201).json(await createPlan(req, input as never));
  }),
);

billingPlatformRouter.get(
  '/plans/:id',
  asyncHandler(async (req, res) => {
    res.json({ plan: await getPlan(req.params.id), versions: await listPlanVersions(req.params.id) });
  }),
);

billingPlatformRouter.patch(
  '/plans/:id',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, planPatchSchema);
    res.json(await updatePlan(req, req.params.id, input as never));
  }),
);

for (const [path, move] of [
  ['publish', publishPlan],
  ['archive', archivePlan],
  ['restore', restorePlan],
] as const) {
  billingPlatformRouter.post(
    `/plans/:id/${path}`,
    asyncHandler(async (req, res) => {
      res.json(await move(req, req.params.id));
    }),
  );
}

/* ─── Subscriptions ─── */

billingPlatformRouter.get(
  '/subscriptions',
  asyncHandler(async (req, res) => {
    const q = parseQuery(
      req,
      z.object({ status: optionalEnum(SUBSCRIPTION_STATES as readonly SubscriptionState[]), tenantId: z.string().max(64).optional(), ...paging }),
    );
    const { rows, total } = await listSubscriptions(q);
    res.json({ rows, total, page: q.page, pageSize: q.pageSize });
  }),
);

/** Starts an academy's subscription: a trial, or an agreement billed outside the provider (P16). The price is the plan's. */
billingPlatformRouter.post(
  '/subscriptions',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({
        tenantId: z.string().min(1).max(64),
        planId: z.string().min(1).max(64),
        cycle: z.enum(['monthly', 'annual']),
        start: z.enum(['trial', 'active']),
      }),
    );
    res.status(201).json(await createSubscription(actor(req), input));
  }),
);

billingPlatformRouter.get(
  '/subscriptions/:id',
  asyncHandler(async (req, res) => {
    const subscription = await getSubscription(req.params.id);
    const [lifecycle, planChanges, invoices, payments] = await Promise.all([
      listLifecycle(subscription.id),
      listPlanChanges(subscription.id),
      listInvoices(subscription.tenantId),
      listPayments(subscription.tenantId),
    ]);
    res.json({
      subscription,
      lifecycle,
      planChanges,
      invoices: invoices.filter((i) => i.subscriptionId === subscription.id),
      payments: payments.filter((p) => p.subscriptionId === subscription.id),
    });
  }),
);

billingPlatformRouter.post(
  '/subscriptions/:id/cancel',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ immediately: z.boolean().default(false), reason: z.string().trim().min(3).max(500) }));
    res.json(
      input.immediately
        ? await cancelNow(actor(req), req.params.id, { reason: input.reason })
        : await requestCancellation(actor(req), req.params.id, { reason: input.reason }),
    );
  }),
);

/**
 * Asks for a plan change on an academy's behalf. When it applies is the rules', not the caller's: an
 * upgrade is prorated and waits for its payment (D7, D8); a downgrade applies at the period end (D10).
 */
billingPlatformRouter.post(
  '/subscriptions/:id/plan-change',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ planId: z.string().min(1).max(64), cycle: z.enum(['monthly', 'annual']) }));
    res.status(201).json(await requestPlanChange(actor(req), req.params.id, { planId: input.planId, cycle: input.cycle as BillingCycle }));
  }),
);

billingPlatformRouter.post(
  '/subscriptions/:id/pause',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ days: z.number().int(), reason: z.string().trim().max(500).optional() }));
    res.json(await pauseSubscription(actor(req), req.params.id, input));
  }),
);

/** Complimentary days: the current period ends later, at no charge, with the reason on the record. */
billingPlatformRouter.post(
  '/subscriptions/:id/extend',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ days: z.number().int(), reason: z.string().trim().min(3).max(500) }));
    res.json(await extendSubscription(actor(req), req.params.id, input));
  }),
);

billingPlatformRouter.post(
  '/subscriptions/:id/resume',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ reason: z.string().trim().max(500).optional() }));
    res.json(await resumeSubscription(actor(req), req.params.id, input));
  }),
);

/* ─── Invoices, payments, refunds ─── */

billingPlatformRouter.get(
  '/invoices',
  asyncHandler(async (req, res) => {
    const q = parseQuery(
      req,
      z.object({ status: optionalEnum(['open', 'paid', 'void'] as readonly InvoiceStatus[]), tenantId: z.string().max(64).optional(), ...paging }),
    );
    const { rows, total } = await listAllInvoices(q);
    res.json({ rows, total, page: q.page, pageSize: q.pageSize });
  }),
);

billingPlatformRouter.get(
  '/invoices/:id',
  asyncHandler(async (req, res) => {
    res.json(await getInvoice(req.params.id));
  }),
);

billingPlatformRouter.post(
  '/invoices/:id/void',
  asyncHandler(async (req, res) => {
    const { reason } = parseBody(req, z.object({ reason: z.string().trim().min(3).max(500) }));
    res.json(await voidInvoice(req, req.params.id, reason));
  }),
);

/**
 * A payment the academy made outside the gateway — a bank transfer, cheque, cash — recorded against an open
 * invoice for its full total, with the bank or receipt reference. The invoice then does what a paid invoice
 * does: renews, recovers, starts or upgrades the subscription.
 */
billingPlatformRouter.post(
  '/invoices/:id/record-payment',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({ method: z.enum(OFFLINE_METHODS), reference: z.string().trim().min(3).max(100), note: z.string().trim().max(500).optional() }),
    );
    res.status(201).json(await recordOfflinePayment(req, req.params.id, input));
  }),
);

billingPlatformRouter.get(
  '/payments',
  asyncHandler(async (req, res) => {
    const q = parseQuery(
      req,
      z.object({ status: optionalEnum(['pending', 'paid', 'failed'] as readonly StoredPaymentStatus[]), tenantId: z.string().max(64).optional(), ...paging }),
    );
    const { rows, total } = await listAllPayments(q);
    res.json({ rows, total, page: q.page, pageSize: q.pageSize });
  }),
);

billingPlatformRouter.get(
  '/payments/:id',
  asyncHandler(async (req, res) => {
    res.json({ payment: await getPayment(req.params.id), refunds: await listRefunds(req.params.id) });
  }),
);

/**
 * A refund — a super admin's decision, with a reason; full unless an amount (minor units) is given. Asked
 * of the payment provider when it took the payment, and settled by its answer.
 */
billingPlatformRouter.post(
  '/payments/:id/refund',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ amount: z.number().int().min(1).optional(), reason: z.string().trim().min(3).max(500) }));
    res.status(201).json(await refundThroughProvider(req, req.params.id, input));
  }),
);

/** Provider webhooks received (SAAS-010): each with its status, attempts and the ids it named — never its body. */
billingPlatformRouter.get(
  '/webhooks',
  asyncHandler(async (req, res) => {
    const q = parseQuery(req, z.object({ status: optionalEnum(['received', 'processed', 'ignored', 'failed'] as const), ...paging }));
    const { rows, total } = await listWebhookEvents(q);
    res.json({ rows, total, page: q.page, pageSize: q.pageSize });
  }),
);

/* ─── Payment gateways (SAAS-017) ─── */

/*
 * The gateways new payments go through. What leaves here is only what the panel may show — enabled,
 * configured, active, environment and a masked hint; a credential is write-only, and a blank secret on save
 * keeps the stored one. `:provider` is checked against the registry by the service: an unknown one is 404.
 */
billingPlatformRouter.get(
  '/payment-gateways',
  asyncHandler(async (_req, res) => {
    res.json(await listGateways());
  }),
);

billingPlatformRouter.post(
  '/payment-gateways/deactivate',
  asyncHandler(async (req, res) => {
    res.json(await deactivateActiveGateway(req));
  }),
);

billingPlatformRouter.get(
  '/payment-gateways/:provider',
  asyncHandler(async (req, res) => {
    res.json(await getGateway(req.params.provider));
  }),
);

billingPlatformRouter.post(
  '/payment-gateways/:provider/config',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({ environment: z.enum(['test', 'live']), credentials: z.record(z.string().max(64), z.string().max(500).optional()).default({}) }),
    );
    res.json(await configureGateway(req.params.provider, input, req));
  }),
);

billingPlatformRouter.patch(
  '/payment-gateways/:provider',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ enabled: z.boolean().optional(), environment: z.enum(['test', 'live']).optional() }));
    res.json(await updateGateway(req.params.provider, input, req));
  }),
);

/** Checks the stored credentials with the gateway, server to server. Nothing is charged; a failure is reported as one. */
billingPlatformRouter.post(
  '/payment-gateways/:provider/test',
  asyncHandler(async (req, res) => {
    const { environment } = parseBody(req, z.object({ environment: z.enum(['test', 'live']).optional() }));
    res.json(await testGateway(req.params.provider, req, environment));
  }),
);

billingPlatformRouter.post(
  '/payment-gateways/:provider/activate',
  asyncHandler(async (req, res) => {
    res.json(await activateGateway(req.params.provider, req));
  }),
);

/* ─── Tax rules and billing profiles ─── */

billingPlatformRouter.get(
  '/tax-rules',
  asyncHandler(async (req, res) => {
    const { includeRetired } = parseQuery(req, z.object({ includeRetired: queryBool }));
    res.json({ rows: await listTaxRules({ includeRetired: Boolean(includeRetired) }) });
  }),
);

billingPlatformRouter.post(
  '/tax-rules',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({
        name: z.string().max(80),
        country: z.string().max(2),
        region: z.string().max(10).optional(),
        inclusive: z.boolean().optional(),
        components: z.array(z.object({ code: z.string().max(16), label: z.string().max(80), rateBps: z.number() })).max(5),
      }),
    );
    res.status(201).json(await setTaxRule(req, input));
  }),
);

billingPlatformRouter.post(
  '/tax-rules/:id/retire',
  asyncHandler(async (req, res) => {
    res.json(await retireTaxRule(req, req.params.id));
  }),
);

billingPlatformRouter.get(
  '/tenants/:id/billing-profile',
  asyncHandler(async (req, res) => {
    const profile = await getBillingProfile(req.params.id);
    if (!profile) throw notFound('This Admin has no billing profile yet.');
    res.json(profile);
  }),
);

billingPlatformRouter.put(
  '/tenants/:id/billing-profile',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, billingProfileSchema);
    res.json(await setBillingProfile(req, req.params.id, input));
  }),
);

billingPlatformRouter.use(stableCodes);
