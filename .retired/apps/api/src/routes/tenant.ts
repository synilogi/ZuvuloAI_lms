import { Router, type Request } from 'express';
import { type BillingCycle } from '@syniastrolms/domain';

import { requireAuth, requireRole } from '../lib/auth.js';
import { getBillingProfile, payableForPlanChange, setBillingProfile } from '../lib/billing.js';
import { invoiceView, openChangeView, tenantBillingView } from '../lib/billingViews.js';
import { confirmCheckout, startCheckout, startFirstPurchase } from '../lib/checkout.js';
import { getTenantEntitlements } from '../lib/entitlements.js';
import { createAcademySupportRequest, listAcademySupportRequests } from '../lib/inquiries.js';
import { asyncHandler, conflict, notFound, stableCodes } from '../lib/errors.js';
import { getInvoice, listInvoices } from '../lib/invoices.js';
import { listPayments } from '../lib/payments.js';
import { requirePermission } from '../lib/permissions.js';
import { UnexpectedUpgradeError, cancelPlanChange, listPlanChanges, previewPlanChange, requestPlanChange } from '../lib/planChanges.js';
import { listPlans } from '../lib/plans.js';
import {
  cancelNow,
  createSubscription,
  currentSubscription,
  liveSubscription,
  requestCancellation,
  resumeSubscription,
  type LifecycleActor,
} from '../lib/subscriptions.js';
import { currentTenantId } from '../lib/tenancy.js';
import { usageSummary } from '../lib/usage.js';
import { parseBody, z } from '../lib/validate.js';
import { billingProfileSchema } from './billingPlatform.js';

/*
 * The Tenant Admin's view of the academy's own subscription (subscriptions.md §24, §32; SAAS-013).
 *
 * Order (§33): authenticated → academy admin → permission (`settings.view` to read, `settings.edit` to
 * change) → the academy, which is always the signed-in account's own (D3: no route here takes an
 * academy id, so another academy's subscription cannot even be named) → the operation. No entitlement
 * gate: an academy must reach its subscription to renew it, whatever state it is in.
 *
 * A Tenant Admin never manages platform plans — `GET /tenant/plans` lists what is on sale, read-only —
 * and never sets a price: an upgrade answers with the quote and the payable amount the server
 * calculated, and activates only when a verified payment confirms it (SAAS-006; SAAS-009/010).
 */

export const tenantRouter = Router();

tenantRouter.use(requireAuth, requireRole('admin'));

const read = requirePermission('settings.view');
const change = requirePermission('settings.edit');
const actor = (req: Request): LifecycleActor => ({ type: 'user', auth: { sub: req.auth!.sub, role: req.auth!.role } });

/** The academy's live subscription, or a clear refusal when it has none to act on. */
async function live() {
  const sub = await liveSubscription(currentTenantId());
  if (!sub) throw conflict('This LMS has no active subscription.');
  return sub;
}

tenantRouter.get(
  '/subscription',
  read,
  asyncHandler(async (_req, res) => {
    const tenantId = currentTenantId();
    const [subscription, entitlements] = await Promise.all([currentSubscription(tenantId), getTenantEntitlements(tenantId)]);
    const planChanges = subscription ? await listPlanChanges(subscription.id) : [];
    res.json({
      subscription,
      plan: entitlements.plan,
      status: entitlements.status,
      // Restricted mode (§21): the academy keeps what it has and cannot add to it until it renews.
      restricted: !entitlements.planVersionId,
      openPlanChange: planChanges.find((c) => c.status === 'pending_payment' || c.status === 'scheduled') ?? null,
    });
  }),
);

/** Everything the academy's billing page shows (§24), in one read — `packages/domain/src/billingViews.ts` `TenantBilling`. */
tenantRouter.get(
  '/billing',
  read,
  asyncHandler(async (_req, res) => {
    res.json(await tenantBillingView(currentTenantId()));
  }),
);

/** One of the academy's own invoices as the billing page shows it. Another academy's is simply not found. */
tenantRouter.get(
  '/billing/invoices/:id',
  read,
  asyncHandler(async (req, res) => {
    res.json(await invoiceView(req.params.id));
  }),
);

/**
 * Opens the payment provider's checkout for one of the academy's open invoices, or for an upgrade that is
 * waiting for payment (invoiced first). The amount is the invoice's; nothing in the body can change it.
 */
tenantRouter.post(
  '/billing/checkout',
  change,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ invoiceId: z.string().min(1).max(64).optional(), planChangeId: z.string().min(1).max(64).optional() }));
    res.status(201).json(await startCheckout(currentTenantId(), input, req));
  }),
);

/**
 * The academy's first subscription (SAAS-009): for an academy with no live subscription, choose a plan on sale
 * and a cycle, and get the provider's checkout for it. The body names the plan and the cycle — nothing else is
 * read: the price, the tax and the amount are the server's, from the plan's current version, and the academy
 * is the signed-in account's. The subscription starts only when the provider confirms the payment.
 */
tenantRouter.post(
  '/billing/purchase',
  change,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, planChoice);
    res.status(201).json(await startFirstPurchase(currentTenantId(), { planId: input.planId, cycle: input.cycle as BillingCycle }, req));
  }),
);

/**
 * The browser finished checkout. What it sends proves nothing by itself: the signature must be the
 * provider's, and the payment is then read from the provider — only its answer is recorded (§43).
 */
tenantRouter.post(
  '/billing/checkout/confirm',
  change,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ orderId: z.string().min(1).max(64), paymentId: z.string().min(1).max(64), signature: z.string().min(1).max(256) }));
    res.json(await confirmCheckout(currentTenantId(), input, req));
  }),
);

tenantRouter.get(
  '/subscription/usage',
  read,
  asyncHandler(async (_req, res) => {
    res.json(await usageSummary(currentTenantId()));
  }),
);

tenantRouter.get(
  '/subscription/entitlements',
  read,
  asyncHandler(async (_req, res) => {
    res.json(await getTenantEntitlements(currentTenantId()));
  }),
);

/** What the academy could move to: the plans on sale, as published. Read-only. */
tenantRouter.get(
  '/plans',
  read,
  asyncHandler(async (_req, res) => {
    const rows = await listPlans({ status: 'active' });
    res.json({ rows, total: rows.length });
  }),
);

const planChoice = z.object({ planId: z.string().min(1).max(64), cycle: z.enum(['monthly', 'annual']) });

/**
 * Asks for an upgrade: answers with the quote (credit, charge) and what will be paid, tax included. The
 * academy's plan does not change until the provider confirms the payment.
 */
tenantRouter.post(
  '/subscription/upgrade',
  change,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, planChoice);
    const sub = await live();
    // An upgrade is charged, and a charge needs the billing address its tax is decided by — check first.
    if (!(await getBillingProfile(sub.tenantId))) throw conflict('Add the LMS’s billing address before upgrading.');
    const quote = await requestPlanChange(actor(req), sub.id, { planId: input.planId, cycle: input.cycle as BillingCycle }, 'upgrade');
    res.status(201).json({ planChange: quote, payable: await payableForPlanChange(quote.id) });
  }),
);

/**
 * Self-serve onboarding: an academy with no live subscription starts the chosen plan's free trial itself —
 * once per academy, on a plan that offers one, with no payment and no billing address needed. When the trial
 * ends unpaid it expires (the academy keeps its data, restricted); paying its renewal invoice converts it.
 */
tenantRouter.post(
  '/billing/trial',
  change,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, planChoice);
    const subscription = await createSubscription(actor(req), {
      tenantId: currentTenantId(),
      planId: input.planId,
      cycle: input.cycle as BillingCycle,
      start: 'trial',
    });
    res.status(201).json({ subscription });
  }),
);

/**
 * What a move to another plan or cycle would do, before it is asked for: upgrade or downgrade, when it applies,
 * the prorated credit and charge with tax, and the limits the academy already exceeds on the new plan. Writes
 * nothing, so it needs only `settings.view`.
 */
tenantRouter.post(
  '/subscription/preview',
  read,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, planChoice);
    const sub = await live();
    res.json(await previewPlanChange(actor(req), sub.id, { planId: input.planId, cycle: input.cycle as BillingCycle }));
  }),
);

/**
 * Asks for a move to another plan or cycle, and lets the server say which it is: an upgrade answers with
 * its quote and the payable amount (it applies once paid), a downgrade with the date it applies.
 */
tenantRouter.post(
  '/subscription/change',
  change,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, planChoice);
    const sub = await live();
    const choice = { planId: input.planId, cycle: input.cycle as BillingCycle };
    // An upgrade is charged, and its tax is decided by the billing address: without one, only a downgrade
    // can be asked for — the service refuses an upgrade before writing anything.
    const profiled = Boolean(await getBillingProfile(sub.tenantId));
    const quote = await requestPlanChange(actor(req), sub.id, choice, profiled ? undefined : 'downgrade').catch((err: unknown) => {
      if (err instanceof UnexpectedUpgradeError) throw conflict('Add the LMS’s billing address before upgrading.');
      throw err;
    });
    const upgrade = quote.kind === 'upgrade' || quote.kind === 'cycle_upgrade';
    res.status(201).json({ change: await openChangeView(quote.id), ...(upgrade ? { payable: await payableForPlanChange(quote.id) } : {}) });
  }),
);

/** Asks for a downgrade: scheduled for the end of the period, nothing refunded, conflicts reported (D10). */
tenantRouter.post(
  '/subscription/downgrade',
  change,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, planChoice);
    const sub = await live();
    res
      .status(201)
      .json({ planChange: await requestPlanChange(actor(req), sub.id, { planId: input.planId, cycle: input.cycle as BillingCycle }, 'downgrade') });
  }),
);

tenantRouter.post(
  '/subscription/plan-changes/:id/cancel',
  change,
  asyncHandler(async (req, res) => {
    const { reason } = parseBody(req, z.object({ reason: z.string().trim().max(500).optional() }));
    res.json(await cancelPlanChange(actor(req), req.params.id, { reason }));
  }),
);

/** Cancels at the end of the paid period (the default), or now. Recorded with who, when, why and when it takes effect. */
tenantRouter.post(
  '/subscription/cancel',
  change,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ immediately: z.boolean().default(false), reason: z.string().trim().min(3).max(500) }));
    const sub = await live();
    res.json(
      input.immediately
        ? await cancelNow(actor(req), sub.id, { reason: input.reason })
        : await requestCancellation(actor(req), sub.id, { reason: input.reason }),
    );
  }),
);

/** Withdraws a pending cancellation, or ends a pause. */
tenantRouter.post(
  '/subscription/resume',
  change,
  asyncHandler(async (req, res) => {
    const { reason } = parseBody(req, z.object({ reason: z.string().trim().max(500).optional() }));
    res.json(await resumeSubscription(actor(req), (await live()).id, { reason }));
  }),
);

tenantRouter.get(
  '/invoices',
  read,
  asyncHandler(async (_req, res) => {
    const rows = await listInvoices(currentTenantId());
    res.json({ rows, total: rows.length });
  }),
);

tenantRouter.get(
  '/invoices/:id',
  read,
  asyncHandler(async (req, res) => {
    // Found from the academy's own context: another academy's invoice is simply not found.
    res.json(await getInvoice(req.params.id));
  }),
);

tenantRouter.get(
  '/payments',
  read,
  asyncHandler(async (_req, res) => {
    const rows = await listPayments(currentTenantId());
    res.json({ rows, total: rows.length });
  }),
);

tenantRouter.get(
  '/billing-profile',
  read,
  asyncHandler(async (_req, res) => {
    const profile = await getBillingProfile(currentTenantId());
    if (!profile) throw notFound('This LMS has no billing profile yet.');
    res.json(profile);
  }),
);

tenantRouter.put(
  '/billing-profile',
  change,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, billingProfileSchema);
    res.json(await setBillingProfile(req, currentTenantId(), input));
  }),
);

/** Asks the platform team for help (SAAS-029): lands in the Super Admin's inbox with this academy attached. Any admin may. */
tenantRouter.post(
  '/support',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({
        subject: z.string().trim().min(3, 'Give the request a short subject.').max(160),
        message: z.string().trim().min(10, 'Describe what you need — at least 10 characters.').max(4000),
      }),
    );
    res.status(201).json(await createAcademySupportRequest(req, input));
  }),
);

/** The academy's support requests and where each stands. */
tenantRouter.get(
  '/support',
  asyncHandler(async (_req, res) => {
    res.json({ rows: await listAcademySupportRequests() });
  }),
);

tenantRouter.use(stableCodes);
