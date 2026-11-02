import { LIMIT_KEYS } from '@syniastrolms/domain';
import type { Subscription as SubscriptionRow } from '@prisma/client';

import { graceConfigured, invoiceLeadDays, retryDays } from './billingConfig.js';
import { settleProviderPayment } from './checkout.js';
import { now } from './clock.js';
import { db } from './db.js';
import { getTenantEntitlements, getUsage } from './entitlements.js';
import { getBillingProfile, payableForRenewal } from './billing.js';
import { issueInvoice, supersedeUnpaidInvoice } from './invoices.js';
import { describeError, observe } from './observe.js';
import { findProvider } from './paymentGateways.js';
import { applyDueScheduledChange } from './planChanges.js';
import {
  endCancelledPeriod,
  expireGrace,
  expireTrial,
  recordPaymentFailed,
  recordPaymentSucceeded,
  resumeSubscription,
  startGracePeriod,
  type LifecycleActor,
} from './subscriptions.js';
import { currentTenantId } from './tenancy.js';
import { retryFailedWebhooks } from './webhooks.js';

/*
 * The billing jobs (subscriptions.md §30; SAAS-012), run by the existing scheduler (`lib/scheduler.ts`): the
 * academy jobs once per academy inside its own context on every tick, `webhook-retry` once per tick for the
 * platform. There is no second scheduler.
 *
 * Every job is:
 *   - **idempotent** — it acts only on what is due *now* by the server's clock, and every action moves the
 *     record past the condition that selected it (a trial expires once; a renewal moves the period end; an
 *     invoice exists once per period by database constraint). Running a job twice in a row changes nothing
 *     the second time.
 *   - **retryable** — one subscription's failure is reported and the rest carry on; the next tick tries it
 *     again.
 *   - **observable** — each run returns what it changed, and every failure is a redacted `job.failed` signal.
 *   - **attributed** — every change is made as `system`, naming the job, on the lifecycle log and the audit
 *     trail.
 */

export interface JobRun {
  job: string;
  /** Records the job changed. Zero on a second run straight after the first. */
  changed: number;
  /** Due, but left alone on purpose — with no configuration for it, say. */
  skipped: number;
  failed: number;
}

/**
 * In the order a tick runs them, so no job leaves work for one that already ran: what ends a trial, a pause
 * or a cancelled period first; then the next period's invoice, then the boundary itself; then retries and
 * grace for what fell due. A tick straight after a tick therefore finds nothing to do.
 */
export const BILLING_JOBS = [
  'trial-expiry-check',
  'pause-expiry',
  'scheduled-cancellation',
  'invoice-generation',
  'subscription-renewal-check',
  'past-due-retry',
  'checkout-recovery',
  'grace-period-expiry',
  'usage-reconciliation',
] as const;

export type BillingJob = (typeof BILLING_JOBS)[number];

const actorFor = (job: string): LifecycleActor => ({ type: 'system', job });
const DAY_MS = 86_400_000;

/**
 * Runs `each` for every subscription `select` finds, as the job, counting what changed. A subscription that
 * throws is reported and skipped; the next tick tries it again.
 */
async function forEach(
  job: string,
  subs: SubscriptionRow[],
  each: (sub: SubscriptionRow, actor: LifecycleActor) => Promise<'changed' | 'skipped' | 'unchanged'>,
): Promise<JobRun> {
  const run: JobRun = { job, changed: 0, skipped: 0, failed: 0 };
  const actor = actorFor(job);
  for (const sub of subs) {
    try {
      const result = await each(sub, actor);
      if (result === 'changed') run.changed += 1;
      if (result === 'skipped') run.skipped += 1;
    } catch (err) {
      run.failed += 1;
      observe('job.failed', { job, tenantId: sub.tenantId, subscriptionId: sub.id, error: describeError(err) });
    }
  }
  return run;
}

/* ─── The jobs ─────────────────────────────────────────────────────────── */

/** A trial whose end has passed on the server's clock expires, unconverted (§7). */
export async function trialExpiryCheck(): Promise<JobRun> {
  const subs = await db.subscription.findMany({ where: { status: 'trialing', trialEndAt: { lte: now() } } });
  return forEach('trial-expiry-check', subs, async (sub, actor) => {
    await expireTrial(actor, sub.id);
    return 'changed';
  });
}

/**
 * A renewal invoice for the next period, issued ahead of the period's end so the academy can pay in time —
 * at the next period's price, which a scheduled downgrade sets (D10). Once per period (database). An open
 * invoice whose price no longer matches the next period is replaced; one already being paid never is.
 * An overdue subscription with nothing to pay — it fell due before the academy had a billing address, or its
 * invoice was voided — is invoiced too, so it can always pay its way back (§44).
 */
export async function invoiceGeneration(): Promise<JobRun> {
  const horizon = new Date(now().getTime() + invoiceLeadDays() * DAY_MS);
  const subs = await db.subscription.findMany({
    where: { status: { in: ['trialing', 'active', 'past_due'] }, cancelAtPeriodEnd: false, currentPeriodEndAt: { lte: horizon } },
  });
  return forEach('invoice-generation', subs, async (sub, actor) => {
    if (!(await getBillingProfile(sub.tenantId))) return 'skipped';
    const existing = await db.invoice.findFirst({
      where: { subscriptionId: sub.id, purpose: 'renewal', periodStartAt: sub.currentPeriodEndAt, status: { not: 'void' } },
    });
    if (existing) {
      const due = await payableForRenewal(sub.id);
      if (existing.status !== 'open' || existing.subtotal === due.net) return 'unchanged';
      await supersedeUnpaidInvoice(actor, existing.id, 'Replaced: the next period’s price changed after this invoice was issued.');
      const stillOpen = await db.invoice.findUnique({ where: { id: existing.id } });
      if (stillOpen?.status !== 'void') return 'unchanged';
    }
    await issueInvoice(actor, { kind: 'renewal', subscriptionId: sub.id });
    return 'changed';
  });
}

/**
 * At the end of an active subscription's period (§44): a downgrade scheduled for the boundary applies first
 * (D10); then the next period's invoice decides — paid, the subscription renews; unpaid, it falls past due,
 * and keeps its access while retries run (§8).
 */
export async function subscriptionRenewalCheck(): Promise<JobRun> {
  const subs = await db.subscription.findMany({ where: { status: 'active', currentPeriodEndAt: { lte: now() } } });
  return forEach('subscription-renewal-check', subs, async (sub, actor) => {
    const scheduled = await db.planChange.findFirst({ where: { subscriptionId: sub.id, status: 'scheduled' } });
    if (scheduled) await applyDueScheduledChange(actor, sub.id);
    const invoice = await db.invoice.findFirst({
      where: { subscriptionId: sub.id, purpose: 'renewal', periodStartAt: sub.currentPeriodEndAt, status: { not: 'void' } },
    });
    if (invoice?.status === 'paid') {
      await recordPaymentSucceeded(actor, sub.id);
      return 'changed';
    }
    try {
      await recordPaymentFailed(actor, sub.id, {
        reason: invoice
          ? `Invoice ${invoice.number} was not paid by the end of the period.`
          : 'No renewal invoice could be issued (the LMS has no billing address).',
        // The period read above: a payment that renews it meanwhile wins, and nothing falls past due.
        periodEndAt: sub.currentPeriodEndAt,
      });
    } catch (err) {
      if (await renewedSince(sub.id, sub.currentPeriodEndAt)) return 'unchanged';
      throw err;
    }
    return 'changed';
  });
}

/** Whether a payment renewed the subscription after the job read it: its period has moved on. */
async function renewedSince(id: string, periodEndAt: Date): Promise<boolean> {
  const fresh = await db.subscription.findUnique({ where: { id }, select: { currentPeriodEndAt: true } });
  return !!fresh && fresh.currentPeriodEndAt.getTime() !== periodEndAt.getTime();
}

/**
 * An overdue subscription (§8, §44). First, a payment made but never confirmed — a closed window, a lost
 * webhook — is found again by asking the provider for the payments on the invoice's checkout orders, and
 * recorded; that recovers the subscription. Then, once the retry window (`SUBSCRIPTION_RETRY_DAYS`) has
 * run out, the grace period starts. With either setting missing, nothing is forced: the academy stays past
 * due, with its access.
 */
export async function pastDueRetry(): Promise<JobRun> {
  const subs = await db.subscription.findMany({ where: { status: 'past_due', gracePeriodEndAt: null } });
  const window = retryDays();
  return forEach('past-due-retry', subs, async (sub, actor) => {
    const invoices = await db.invoice.findMany({ where: { subscriptionId: sub.id, status: 'open' }, include: { orders: { where: { status: 'created' } } } });
    for (const order of invoices.flatMap((i) => i.orders)) {
      // Each order is asked of the gateway that created it (SAAS-017), whichever is active now.
      const provider = await findProvider(order.provider, order.environment);
      if (!provider) continue;
      for (const payment of await provider.listOrderPayments(order.providerOrderId)) {
        if (payment.status !== 'paid' && payment.status !== 'authorized') continue;
        const outcome = await settleProviderPayment(provider, payment.providerPaymentId, order);
        if (outcome.settled) return 'changed';
      }
    }
    if (window === null || !graceConfigured()) return 'skipped';
    if (!sub.pastDueAt || now().getTime() - sub.pastDueAt.getTime() < window * DAY_MS) return 'unchanged';
    await startGracePeriod(actor, sub.id, { reason: `Payment retries exhausted: nothing was paid within ${window} days.` });
    return 'changed';
  });
}

/** How old a checkout must be before it is asked after, and how long it is asked after for. */
export const CHECKOUT_RECOVERY_AFTER_MS = 15 * 60_000;
export const CHECKOUT_RECOVERY_FOR_MS = 3 * DAY_MS;
/** How often one academy's open checkouts are asked after; the job runs every minute. */
export const CHECKOUT_RECOVERY_EVERY_MS = 15 * 60_000;
const recoveredAt = new Map<string, number>();

/**
 * A checkout paid at the provider whose confirmation never arrived — the window closed, the network dropped, the
 * webhook was lost — for any invoice that is still open: a first purchase, an upgrade, an early renewal. The provider
 * is asked for the payments on each such order between a quarter of an hour and three days old, and a payment it
 * reports is recorded exactly as a webhook would record it. Overdue subscriptions are `past-due-retry`'s. Each
 * academy is asked at most every quarter of an hour (in memory: one API process, docs/10-DEPLOYMENT.md).
 */
export async function checkoutRecovery(): Promise<JobRun> {
  const run: JobRun = { job: 'checkout-recovery', changed: 0, skipped: 0, failed: 0 };
  const tenantId = currentTenantId();
  const at = now().getTime();
  if (at - (recoveredAt.get(tenantId) ?? 0) < CHECKOUT_RECOVERY_EVERY_MS) return run;
  recoveredAt.set(tenantId, at);
  const orders = await db.paymentOrder.findMany({
    where: {
      status: 'created',
      createdAt: { gte: new Date(at - CHECKOUT_RECOVERY_FOR_MS), lte: new Date(at - CHECKOUT_RECOVERY_AFTER_MS) },
      invoice: { status: 'open', OR: [{ subscriptionId: null }, { subscription: { status: { not: 'past_due' } } }] },
    },
    orderBy: { createdAt: 'asc' },
    take: 50,
  });
  for (const order of orders) {
    try {
      // Each order is asked of the gateway that created it (SAAS-017), whichever is active now.
      const provider = await findProvider(order.provider, order.environment);
      if (!provider) {
        run.skipped++;
        continue;
      }
      let settled = false;
      for (const payment of await provider.listOrderPayments(order.providerOrderId)) {
        if (payment.status !== 'paid' && payment.status !== 'authorized') continue;
        if ((await settleProviderPayment(provider, payment.providerPaymentId, order)).settled) settled = true;
        if (settled) break;
      }
      if (settled) run.changed++;
    } catch (err) {
      run.failed++;
      observe('job.failed', { job: 'checkout-recovery', tenantId, orderId: order.providerOrderId, error: describeError(err) });
    }
  }
  return run;
}

/** Forgets when each academy's checkouts were last asked after — for tests that move the clock. */
export const resetCheckoutRecovery = () => recoveredAt.clear();

/** A grace period that ran out with nothing paid ends the subscription: expired, restricted (§8). */
export async function gracePeriodExpiry(): Promise<JobRun> {
  const subs = await db.subscription.findMany({ where: { status: 'past_due', gracePeriodEndAt: { lte: now() } } });
  return forEach('grace-period-expiry', subs, async (sub, actor) => {
    await expireGrace(actor, sub.id);
    return 'changed';
  });
}

/** A cancellation asked for at the period's end takes effect when it comes. */
export async function scheduledCancellation(): Promise<JobRun> {
  const subs = await db.subscription.findMany({ where: { status: 'canceling', currentPeriodEndAt: { lte: now() } } });
  return forEach('scheduled-cancellation', subs, async (sub, actor) => {
    await endCancelledPeriod(actor, sub.id);
    return 'changed';
  });
}

/** A pause ends on its planned date, and the period end moves out by the time paused (D9). */
export async function pauseExpiry(): Promise<JobRun> {
  const subs = await db.subscription.findMany({ where: { status: 'paused', resumesAt: { lte: now() } } });
  return forEach('pause-expiry', subs, async (sub, actor) => {
    await resumeSubscription(actor, sub.id, { reason: 'The planned end of the pause.' });
    return 'changed';
  });
}

/**
 * Usage against the plan (SAAS-011). Usage is counted live — there is no stored figure to drift — so this
 * reconciles by reporting, not by writing: every limit the academy is already over (after a downgrade, say)
 * is a `limit.reached` signal, so the platform can see it. It changes nothing, ever.
 */
export async function usageReconciliation(): Promise<JobRun> {
  const run: JobRun = { job: 'usage-reconciliation', changed: 0, skipped: 0, failed: 0 };
  const tenantId = currentTenantId();
  const granted = await getTenantEntitlements(tenantId);
  if (!granted.planVersionId) return run;
  for (const limit of LIMIT_KEYS) {
    const allowed = granted.limits[limit];
    if (allowed === null) continue;
    const used = await getUsage(tenantId, limit, now());
    if (used > allowed) observe('limit.reached', { job: 'usage-reconciliation', tenantId, limit, used, allowed, over: true });
  }
  return run;
}

const ACADEMY_JOBS: Record<BillingJob, () => Promise<JobRun>> = {
  'trial-expiry-check': trialExpiryCheck,
  'invoice-generation': invoiceGeneration,
  'subscription-renewal-check': subscriptionRenewalCheck,
  'past-due-retry': pastDueRetry,
  'checkout-recovery': checkoutRecovery,
  'grace-period-expiry': gracePeriodExpiry,
  'scheduled-cancellation': scheduledCancellation,
  'pause-expiry': pauseExpiry,
  'usage-reconciliation': usageReconciliation,
};

/** Every academy job, in order, for the academy the caller runs in. One job failing does not stop the next. */
export async function runAcademyBillingJobs(): Promise<JobRun[]> {
  const runs: JobRun[] = [];
  for (const job of BILLING_JOBS) {
    try {
      runs.push(await ACADEMY_JOBS[job]());
    } catch (err) {
      observe('job.failed', { job, tenantId: currentTenantId(), error: describeError(err) });
      runs.push({ job, changed: 0, skipped: 0, failed: 1 });
    }
  }
  return runs;
}

/** The platform's job: webhooks whose processing failed, retried (SAAS-010). */
export async function webhookRetry(): Promise<JobRun> {
  const { retried, failed } = await retryFailedWebhooks();
  return { job: 'webhook-retry', changed: retried, skipped: 0, failed };
}
