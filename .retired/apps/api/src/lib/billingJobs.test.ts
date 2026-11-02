import { BYTES_PER_GB, type PlanLimits } from '@syniastrolms/domain';
import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest';

import { platformDb } from '../test/db.js';
import { FakeProvider } from '../test/fakeProvider.js';
import { unique } from '../test/helpers.js';
import { setBillingProfile, setTaxRule } from './billing.js';
import {
  checkoutRecovery,
  gracePeriodExpiry,
  invoiceGeneration,
  pastDueRetry,
  pauseExpiry,
  resetCheckoutRecovery,
  scheduledCancellation,
  subscriptionRenewalCheck,
  trialExpiryCheck,
  usageReconciliation,
  webhookRetry,
  type JobRun,
} from './billingJobs.js';
import { confirmCheckout, startCheckout } from './checkout.js';
import { setClock } from './clock.js';
import { setObservationSink, type Observation } from './observe.js';
import { setPaymentProvider } from './paymentProvider.js';
import { recordPayment } from './payments.js';
import { requestPlanChange } from './planChanges.js';
import { createPlan, publishPlan } from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { runBillingSchedule } from './scheduler.js';
import {
  cancelNow,
  createSubscription,
  pauseSubscription,
  recordPaymentFailed,
  recordPaymentSucceeded,
  requestCancellation,
  resumeSubscription,
  startGracePeriod,
  type LifecycleActor,
} from './subscriptions.js';
import { runAsPlatform, runInTenant } from './tenancy.js';

/* SAAS-012: the billing jobs. Each is run twice in a row and must change nothing the second time; each acts
 * only on what is due by the server's clock; each failure is a signal; and they run on the existing
 * scheduler. Billed in France at 20% so no other suite's tax rule is disturbed. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('billing job tests act as the platform', fn);
const provider: LifecycleActor = { type: 'provider', provider: 'fakepay' };
let superAdmin: LifecycleActor & { type: 'user' };
let MONTHLY: string;
let SMALL: string;
let TRIAL: string;
let STRICT: string;

const LIMITS: PlanLimits = {
  'learners.max': 100,
  'instructors.max': 5,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 5,
  'admin_accounts.max': 2,
};

async function plan(monthly: number, over: { trial?: boolean; limits?: Partial<PlanLimits> } = {}) {
  return asPlatform(async () => {
    const p = await createPlan(
      { auth: superAdmin.auth },
      {
        name: 'Jobs',
        description: 'A plan for the jobs suite.',
        code: `JB${unique().toUpperCase()}`.slice(0, 24),
        currency: 'INR',
        cycles: ['monthly', 'annual'],
        monthlyPrice: monthly,
        annualPrice: monthly * 10,
        trialEnabled: Boolean(over.trial),
        trialDays: over.trial ? 14 : 0,
        features: ['courses.manage'],
        limits: { ...LIMITS, ...over.limits },
      },
    );
    await publishPlan({ auth: superAdmin.auth }, p.id);
    return p.id;
  });
}

/** An academy on `planId` from 1 September 2026, billed in France unless `billed` is false. */
async function academy(planId: string, opts: { start?: 'trial' | 'active'; billed?: boolean } = {}) {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Jobs Academy', slug: `jb-${unique()}` } })).id;
  if (opts.billed !== false) {
    await asPlatform(() =>
      setBillingProfile({ auth: superAdmin.auth }, tenantId, {
        legalName: 'Jobs Academy SAS',
        email: 'compta@example.com',
        addressLine1: '1 rue de Rivoli',
        city: 'Paris',
        postalCode: '75001',
        country: 'FR',
      }),
    );
  }
  setClock('2026-09-01T00:00:00Z');
  const sub = await asPlatform(() => createSubscription(superAdmin, { tenantId, planId, cycle: 'monthly', start: opts.start ?? 'active' }));
  return { tenantId, subscriptionId: sub.id };
}

/** Runs a job for one academy, as the scheduler does: inside that academy's context. */
const inAcademy = (tenantId: string, job: () => Promise<JobRun>) => runInTenant(tenantId, job);

/** Everything a job could change about an academy's billing, to compare two runs. */
async function snapshot(tenantId: string) {
  const [subs, events, invoices, payments, changes, audit] = await Promise.all([
    platformDb.subscription.findMany({ where: { tenantId }, orderBy: { id: 'asc' } }),
    platformDb.subscriptionEvent.count({ where: { tenantId } }),
    platformDb.invoice.findMany({ where: { tenantId }, orderBy: { id: 'asc' }, select: { id: true, status: true, total: true } }),
    platformDb.payment.count({ where: { tenantId } }),
    platformDb.planChange.findMany({ where: { tenantId }, select: { id: true, status: true } }),
    platformDb.auditLog.count({ where: { actorType: 'system', metaJson: { contains: tenantId } } }),
  ]);
  return { subs: subs.map((s) => ({ ...s, updatedAt: undefined })), events, invoices, payments, changes, audit };
}

/** Runs `job` twice at the same moment: the first run's result, and proof the second changed nothing. */
async function twice(tenantId: string, job: () => Promise<JobRun>) {
  const first = await inAcademy(tenantId, job);
  const after = await snapshot(tenantId);
  const second = await inAcademy(tenantId, job);
  expect(second.changed, `${first.job} changed something on its second run`).toBe(0);
  expect(await snapshot(tenantId)).toEqual(after);
  return first;
}

const subOf = (id: string) => platformDb.subscription.findUniqueOrThrow({ where: { id } });
const lastEvent = async (id: string) => (await platformDb.subscriptionEvent.findMany({ where: { subscriptionId: id }, orderBy: { id: 'desc' }, take: 1 }))[0];

beforeAll(async () => {
  const created = await provisionSuperAdmin({ email: `jobs-${unique()}@example.com`, password: 'jobs-suite-password', name: 'Jobs' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
  await asPlatform(() => setTaxRule({ auth: superAdmin.auth }, { name: 'TVA', country: 'FR', components: [{ code: 'TVA', label: 'TVA', rateBps: 2000 }] }));
  MONTHLY = await plan(300000);
  SMALL = await plan(100000);
  TRIAL = await plan(150000, { trial: true });
  STRICT = await plan(100000, { limits: { 'admin_accounts.max': 1 } });
});

afterEach(() => {
  setClock(null);
  setPaymentProvider(undefined);
  vi.unstubAllEnvs();
});

describe('trial-expiry-check', () => {
  it('expires a trial once its end has passed, and not a moment before', async () => {
    const a = await academy(TRIAL, { start: 'trial' });
    setClock('2026-09-14T23:59:59Z');
    expect((await inAcademy(a.tenantId, trialExpiryCheck)).changed).toBe(0);
    setClock('2026-09-15T00:00:00Z');
    expect((await twice(a.tenantId, trialExpiryCheck)).changed).toBe(1);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'expired' });
    expect(await lastEvent(a.subscriptionId)).toMatchObject({ transition: 'trial_expired', actorType: 'system', source: 'trial-expiry-check' });
  });
});

describe('invoice-generation', () => {
  it('issues the next period’s invoice ahead of the boundary, once', async () => {
    const a = await academy(MONTHLY);
    setClock('2026-09-20T00:00:00Z');
    expect((await inAcademy(a.tenantId, invoiceGeneration)).changed).toBe(0);
    setClock('2026-09-25T00:00:00Z');
    expect((await twice(a.tenantId, invoiceGeneration)).changed).toBe(1);
    const invoices = await platformDb.invoice.findMany({ where: { tenantId: a.tenantId } });
    expect(invoices).toHaveLength(1);
    expect(invoices[0]).toMatchObject({
      purpose: 'renewal',
      status: 'open',
      subtotal: 300000,
      taxTotal: 60000,
      periodStartAt: new Date('2026-10-01T00:00:00Z'),
    });
  });

  it('skips an academy with no billing address, and honours the configured lead time', async () => {
    const a = await academy(MONTHLY, { billed: false });
    setClock('2026-09-25T00:00:00Z');
    expect(await inAcademy(a.tenantId, invoiceGeneration)).toMatchObject({ changed: 0, skipped: 1 });
    const b = await academy(MONTHLY);
    vi.stubEnv('SUBSCRIPTION_INVOICE_LEAD_DAYS', '2');
    setClock('2026-09-25T00:00:00Z');
    expect((await inAcademy(b.tenantId, invoiceGeneration)).changed).toBe(0);
    setClock('2026-09-29T00:00:00Z');
    expect((await inAcademy(b.tenantId, invoiceGeneration)).changed).toBe(1);
  });

  it('invoices the next period at a scheduled downgrade’s price, replacing an invoice issued before it was scheduled', async () => {
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const first = await platformDb.invoice.findFirstOrThrow({ where: { tenantId: a.tenantId } });
    expect(first.subtotal).toBe(300000);
    await asPlatform(() => requestPlanChange(superAdmin, a.subscriptionId, { planId: SMALL, cycle: 'monthly' }, 'downgrade'));

    expect((await twice(a.tenantId, invoiceGeneration)).changed).toBe(1);
    const invoices = await platformDb.invoice.findMany({ where: { tenantId: a.tenantId }, orderBy: { issuedAt: 'asc' } });
    expect(invoices.map((i) => [i.status, i.subtotal])).toEqual([
      ['void', 300000],
      ['open', 100000],
    ]);
    expect(invoices[0].voidReason).toMatch(/price changed/);
  });
});

describe('subscription-renewal-check', () => {
  it('never puts past due a subscription a payment renewed after the job read it', async () => {
    const a = await academy(MONTHLY);
    setClock('2026-10-01T00:00:00Z');
    const read = await subOf(a.subscriptionId);
    // The payment lands between the job's read and its write: the period moves on.
    await runInTenant(a.tenantId, () => recordPaymentSucceeded(provider, a.subscriptionId));
    await expect(
      runInTenant(a.tenantId, () => recordPaymentFailed(provider, a.subscriptionId, { reason: 'late read', periodEndAt: read.currentPeriodEndAt })),
    ).rejects.toThrow(/renewed meanwhile/);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'active', pastDueAt: null });
  });

  it('moves an unpaid subscription past due at the end of its period, keeping its access', async () => {
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    setClock('2026-09-30T23:59:59Z');
    expect((await inAcademy(a.tenantId, subscriptionRenewalCheck)).changed).toBe(0);
    setClock('2026-10-01T00:00:00Z');
    expect((await twice(a.tenantId, subscriptionRenewalCheck)).changed).toBe(1);
    const sub = await subOf(a.subscriptionId);
    expect(sub).toMatchObject({ status: 'past_due' });
    expect(sub.pastDueReason).toMatch(/^Invoice INV-2026-\d{6} was not paid by the end of the period\.$/);
  });

  it('applies a downgrade at the boundary first, then renews on the invoice paid early — on the new plan', async () => {
    setPaymentProvider(new FakeProvider());
    const a = await academy(MONTHLY);
    setClock('2026-09-20T00:00:00Z');
    await asPlatform(() => requestPlanChange(superAdmin, a.subscriptionId, { planId: SMALL, cycle: 'monthly' }, 'downgrade'));
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const invoice = await platformDb.invoice.findFirstOrThrow({ where: { tenantId: a.tenantId, status: 'open' } });
    expect(invoice.subtotal).toBe(100000);
    // Paid early: the payment settles the invoice, and the renewal waits for the boundary.
    await asPlatform(() =>
      recordPayment(provider, { invoiceId: invoice.id, providerPaymentId: `pay_${unique()}`, amount: invoice.total, currency: 'INR', status: 'paid' }),
    );
    expect(await subOf(a.subscriptionId)).toMatchObject({ amount: 300000, currentPeriodEndAt: new Date('2026-10-01T00:00:00Z') });

    setClock('2026-10-01T00:00:00Z');
    expect((await twice(a.tenantId, subscriptionRenewalCheck)).changed).toBe(1);
    expect(await subOf(a.subscriptionId)).toMatchObject({
      status: 'active',
      planId: SMALL,
      amount: 100000,
      currentPeriodEndAt: new Date('2026-11-01T00:00:00Z'),
    });
    const transitions = (await platformDb.subscriptionEvent.findMany({ where: { subscriptionId: a.subscriptionId }, orderBy: { id: 'asc' } })).map((e) => [
      e.transition,
      e.source,
    ]);
    expect(transitions.slice(-2)).toEqual([
      ['change_plan', 'subscription-renewal-check'],
      ['payment_succeeded', 'subscription-renewal-check'],
    ]);
  });
});

describe('past-due-retry', () => {
  it('finds a payment the academy made but nobody confirmed, records it, and recovers the subscription', async () => {
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const invoice = await platformDb.invoice.findFirstOrThrow({ where: { tenantId: a.tenantId } });
    const { checkout } = await runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: invoice.id }));
    setClock('2026-10-01T00:00:00Z');
    await inAcademy(a.tenantId, subscriptionRenewalCheck);
    expect((await subOf(a.subscriptionId)).status).toBe('past_due');
    // The academy paid; the window closed before the confirmation, and no webhook came.
    fake.pay(checkout.orderId, 'paid');

    setClock('2026-10-02T00:00:00Z');
    expect((await twice(a.tenantId, pastDueRetry)).changed).toBe(1);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'active', currentPeriodEndAt: new Date('2026-11-01T00:00:00Z') });
  });

  it('starts the grace period once the retry window has run out — and forces nothing while unconfigured', async () => {
    const a = await academy(MONTHLY);
    setClock('2026-10-01T00:00:00Z');
    await asPlatform(() => recordPaymentFailed(provider, a.subscriptionId, { reason: 'Card declined' }));
    setClock('2026-10-05T00:00:00Z');
    expect(await inAcademy(a.tenantId, pastDueRetry)).toMatchObject({ changed: 0, skipped: 1 });

    vi.stubEnv('SUBSCRIPTION_RETRY_DAYS', '3');
    vi.stubEnv('SUBSCRIPTION_GRACE_DAYS', '7');
    setClock('2026-10-03T23:00:00Z');
    expect((await inAcademy(a.tenantId, pastDueRetry)).changed).toBe(0);
    setClock('2026-10-04T00:00:00Z');
    expect((await twice(a.tenantId, pastDueRetry)).changed).toBe(1);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'past_due', gracePeriodEndAt: new Date('2026-10-11T00:00:00Z') });
    expect((await subOf(a.subscriptionId)).gracePeriodStartAt).toEqual(new Date('2026-10-04T00:00:00Z'));
  });
});

describe('checkout-recovery', () => {
  it('finds a payment on any open invoice whose confirmation was lost, and records it once', async () => {
    resetCheckoutRecovery();
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const invoice = await platformDb.invoice.findFirstOrThrow({ where: { tenantId: a.tenantId } });
    const { checkout } = await runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: invoice.id }));
    // Paid early, while the subscription is active: the browser closed and no webhook came.
    fake.pay(checkout.orderId, 'paid');

    // Too fresh to ask after: the browser or the webhook may still be on its way.
    setClock('2026-09-25T00:10:00Z');
    expect((await inAcademy(a.tenantId, checkoutRecovery)).changed).toBe(0);
    resetCheckoutRecovery();
    setClock('2026-09-25T00:30:00Z');
    expect((await twice(a.tenantId, checkoutRecovery)).changed).toBe(1);
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('paid');
    expect(await platformDb.payment.count({ where: { invoiceId: invoice.id } })).toBe(1);
    // Asked again later, it finds the order settled and records nothing more.
    resetCheckoutRecovery();
    setClock('2026-09-25T01:30:00Z');
    expect((await inAcademy(a.tenantId, checkoutRecovery)).changed).toBe(0);
    expect(await platformDb.payment.count({ where: { invoiceId: invoice.id } })).toBe(1);
  });
});

describe('payment safety', () => {
  it('never settles an invoice with a payment the provider reports as refunded', async () => {
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const invoice = await platformDb.invoice.findFirstOrThrow({ where: { tenantId: a.tenantId } });
    const { checkout } = await runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: invoice.id }));
    // Refunded from the provider's dashboard before the confirmation arrived.
    const paid = fake.pay(checkout.orderId, 'refunded');
    const outcome = await runInTenant(a.tenantId, () =>
      confirmCheckout(a.tenantId, { orderId: checkout.orderId, paymentId: paid.paymentId, signature: paid.signature }),
    );
    expect(outcome).toMatchObject({ status: 'refunded', settled: false, applied: false });
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('open');
    expect(await platformDb.payment.count({ where: { invoiceId: invoice.id } })).toBe(0);
    expect((await subOf(a.subscriptionId)).currentPeriodEndAt).toEqual(new Date('2026-10-01T00:00:00Z'));
  });

  it('tells the payer and the platform when money lands on an invoice voided while the window was open', async () => {
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const invoice = await platformDb.invoice.findFirstOrThrow({ where: { tenantId: a.tenantId } });
    const { checkout } = await runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: invoice.id }));
    await asPlatform(() => cancelNow(superAdmin, a.subscriptionId, { reason: 'Closing down' }));
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('void');

    const seen: Observation[] = [];
    setObservationSink((_line, o) => seen.push(o));
    const paid = fake.pay(checkout.orderId, 'paid');
    const outcome = await runInTenant(a.tenantId, () =>
      confirmCheckout(a.tenantId, { orderId: checkout.orderId, paymentId: paid.paymentId, signature: paid.signature }),
    );
    setObservationSink(undefined);
    expect(outcome).toMatchObject({ settled: false, applied: false });
    expect(outcome.message).toMatch(/review it for a refund/);
    expect(seen.some((o) => o.signal === 'payment.unmatched' && /void invoice/.test(String(o.fields.reason)))).toBe(true);
    expect((await subOf(a.subscriptionId)).status).toBe('canceled');
    // Recorded, and held for a super admin's review: nothing is refunded by itself.
    expect(await platformDb.payment.count({ where: { invoiceId: invoice.id, status: 'paid' } })).toBe(1);
    expect(await platformDb.refund.count({ where: { tenantId: a.tenantId } })).toBe(0);
  });

  it('never refunds a paid invoice because its subscription is cancelled afterwards', async () => {
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const invoice = await platformDb.invoice.findFirstOrThrow({ where: { tenantId: a.tenantId } });
    const { checkout } = await runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: invoice.id }));
    const paid = fake.pay(checkout.orderId, 'paid');
    expect(
      (await runInTenant(a.tenantId, () => confirmCheckout(a.tenantId, { orderId: checkout.orderId, paymentId: paid.paymentId, signature: paid.signature })))
        .settled,
    ).toBe(true);

    await asPlatform(() => cancelNow(superAdmin, a.subscriptionId, { reason: 'Closing down' }));
    expect((await subOf(a.subscriptionId)).status).toBe('canceled');
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('paid');
    // A refund is a super admin's reviewed decision, never a side effect of cancelling.
    expect(await platformDb.refund.count({ where: { tenantId: a.tenantId } })).toBe(0);
    expect(fake.refunds).toEqual([]);
  });

  it('renews once when two renewals of an active subscription race', async () => {
    const a = await academy(MONTHLY);
    setClock('2026-09-30T00:00:00Z');
    const results = await Promise.allSettled([
      asPlatform(() => recordPaymentSucceeded(provider, a.subscriptionId)),
      asPlatform(() => recordPaymentSucceeded(provider, a.subscriptionId)),
    ]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'active', currentPeriodEndAt: new Date('2026-11-01T00:00:00Z') });
    expect(await platformDb.subscriptionEvent.count({ where: { subscriptionId: a.subscriptionId, transition: 'payment_succeeded' } })).toBe(1);
  });
});

describe('grace-period-expiry', () => {
  it('ends a subscription whose grace ran out with nothing paid', async () => {
    vi.stubEnv('SUBSCRIPTION_GRACE_DAYS', '7');
    const a = await academy(MONTHLY);
    setClock('2026-10-01T00:00:00Z');
    await asPlatform(() => recordPaymentFailed(provider, a.subscriptionId, { reason: 'Card declined' }));
    await asPlatform(() => startGracePeriod({ type: 'system', job: 'test' }, a.subscriptionId, { reason: 'Retries exhausted.' }));
    setClock('2026-10-07T23:59:59Z');
    expect((await inAcademy(a.tenantId, gracePeriodExpiry)).changed).toBe(0);
    setClock('2026-10-08T00:00:00Z');
    expect((await twice(a.tenantId, gracePeriodExpiry)).changed).toBe(1);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'expired' });
  });
});

describe('scheduled-cancellation and pause-expiry', () => {
  it('ends a cancelling subscription when its paid period ends', async () => {
    const a = await academy(MONTHLY);
    await asPlatform(() => requestCancellation(superAdmin, a.subscriptionId, { reason: 'Closing down' }));
    setClock('2026-10-01T00:00:00Z');
    expect((await twice(a.tenantId, scheduledCancellation)).changed).toBe(1);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'canceled' });
    // A cancelling subscription is never sent a renewal invoice or pushed past due.
    expect(await platformDb.invoice.count({ where: { tenantId: a.tenantId } })).toBe(0);
  });

  it('resumes a pause on its planned date, moving the renewal out by the time paused', async () => {
    const a = await academy(MONTHLY);
    setClock('2026-09-10T00:00:00Z');
    await asPlatform(() => pauseSubscription(superAdmin, a.subscriptionId, { days: 5 }));
    setClock('2026-09-15T00:00:00Z');
    expect((await twice(a.tenantId, pauseExpiry)).changed).toBe(1);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'active', currentPeriodEndAt: new Date('2026-10-06T00:00:00Z') });
  });
});

describe('a renewal invoice follows the subscription', () => {
  const renewals = (tenantId: string) =>
    platformDb.invoice.findMany({
      where: { tenantId, purpose: 'renewal' },
      orderBy: { issuedAt: 'asc' },
      select: { id: true, status: true, periodStartAt: true, voidReason: true },
    });

  it('is voided by a cancellation, cannot be paid, and is issued again when the cancellation is withdrawn', async () => {
    setPaymentProvider(new FakeProvider());
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const [issued] = await renewals(a.tenantId);

    await asPlatform(() => requestCancellation(superAdmin, a.subscriptionId, { reason: 'Closing down' }));
    expect((await renewals(a.tenantId))[0]).toMatchObject({ status: 'void', voidReason: expect.stringMatching(/canceling/) });
    await expect(runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: issued!.id }))).rejects.toThrow(/void/);

    await asPlatform(() => resumeSubscription(superAdmin, a.subscriptionId));
    expect((await twice(a.tenantId, invoiceGeneration)).changed).toBe(1);
    expect((await renewals(a.tenantId)).map((i) => [i.status, i.periodStartAt])).toEqual([
      ['void', new Date('2026-10-01T00:00:00Z')],
      ['open', new Date('2026-10-01T00:00:00Z')],
    ]);
  });

  it('is voided by a pause, and the next one is for the boundary the pause moved', async () => {
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    await asPlatform(() => pauseSubscription(superAdmin, a.subscriptionId, { days: 5 }));
    expect((await renewals(a.tenantId)).map((i) => i.status)).toEqual(['void']);

    setClock('2026-09-30T00:00:00Z');
    await inAcademy(a.tenantId, pauseExpiry);
    expect((await twice(a.tenantId, invoiceGeneration)).changed).toBe(1);
    expect((await renewals(a.tenantId)).map((i) => [i.status, i.periodStartAt])).toEqual([
      ['void', new Date('2026-10-01T00:00:00Z')],
      ['open', new Date('2026-10-06T00:00:00Z')],
    ]);
  });

  it('is left open while a payment for it is pending, but checkout refuses it once the subscription is over', async () => {
    setPaymentProvider(new FakeProvider());
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const [issued] = await renewals(a.tenantId);
    await asPlatform(() =>
      recordPayment(provider, { invoiceId: issued!.id, providerPaymentId: `pay_${unique()}`, amount: 360000, currency: 'INR', status: 'pending' }),
    );
    await asPlatform(() => cancelNow(superAdmin, a.subscriptionId, { reason: 'Closing down' }));

    expect((await renewals(a.tenantId))[0]!.status).toBe('open');
    await expect(runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: issued!.id }))).rejects.toMatchObject({
      code: 'INVALID_SUBSCRIPTION_STATE',
    });
  });

  it('is issued to an academy that fell past due before it had a billing address, and paying it recovers the subscription', async () => {
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(MONTHLY, { billed: false });
    setClock('2026-10-01T00:00:00Z');
    await inAcademy(a.tenantId, subscriptionRenewalCheck);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'past_due', pastDueReason: expect.stringMatching(/no billing address/) });
    expect(await inAcademy(a.tenantId, invoiceGeneration)).toMatchObject({ changed: 0, skipped: 1 });

    await asPlatform(() =>
      setBillingProfile({ auth: superAdmin.auth }, a.tenantId, {
        legalName: 'Jobs Academy SAS',
        email: 'compta@example.com',
        addressLine1: '1 rue de Rivoli',
        city: 'Paris',
        postalCode: '75001',
        country: 'FR',
      }),
    );
    setClock('2026-10-02T00:00:00Z');
    expect((await twice(a.tenantId, invoiceGeneration)).changed).toBe(1);
    const [invoice] = await renewals(a.tenantId);
    expect(invoice).toMatchObject({ status: 'open', periodStartAt: new Date('2026-10-01T00:00:00Z') });

    const { checkout } = await runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: invoice!.id }));
    fake.pay(checkout.orderId, 'paid');
    expect((await inAcademy(a.tenantId, pastDueRetry)).changed).toBe(1);
    expect(await subOf(a.subscriptionId)).toMatchObject({ status: 'active', currentPeriodEndAt: new Date('2026-11-01T00:00:00Z') });
  });
});

describe('usage-reconciliation', () => {
  it('reports every limit an academy is over, and changes nothing — ever', async () => {
    const a = await academy(STRICT);
    for (let i = 0; i < 2; i++)
      await platformDb.user.create({
        data: { email: `jb-admin-${unique()}@example.com`, name: 'Over', role: 'admin', passwordHash: 'x', tenantId: a.tenantId },
      });
    const seen: Observation[] = [];
    setObservationSink((_line, o) => seen.push(o));
    try {
      const run = await twice(a.tenantId, usageReconciliation);
      expect(run.changed).toBe(0);
    } finally {
      setObservationSink(undefined);
    }
    expect(seen.filter((o) => o.signal === 'limit.reached' && o.fields.tenantId === a.tenantId)).toHaveLength(2);
    expect(seen[0].fields).toMatchObject({ limit: 'admin_accounts.max', used: 2, allowed: 1, over: true });
  });
});

describe('webhook-retry', () => {
  it('processes a failed webhook again from its receipt, once', async () => {
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const invoice = await platformDb.invoice.findFirstOrThrow({ where: { tenantId: a.tenantId } });
    const start = await runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: invoice.id }));
    const { paymentId } = fake.pay(start.checkout.orderId, 'paid');
    await platformDb.webhookEvent.create({
      data: {
        provider: 'fakepay',
        providerEventId: `evt_${unique()}`,
        eventType: 'payment.captured',
        payloadHash: 'f'.repeat(64),
        referenceJson: JSON.stringify({ paymentId, orderId: start.checkout.orderId }),
        status: 'failed',
        note: 'socket hang up',
      },
    });

    const first = await asPlatform(webhookRetry);
    expect(first.changed).toBeGreaterThanOrEqual(1);
    expect((await asPlatform(webhookRetry)).changed).toBe(0);
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('paid');
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
  });
});

describe('failures are observable, and do not stop the rest', () => {
  it('reports the subscription that failed and carries on with the others', async () => {
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(MONTHLY);
    setClock('2026-09-25T00:00:00Z');
    await inAcademy(a.tenantId, invoiceGeneration);
    const invoice = await platformDb.invoice.findFirstOrThrow({ where: { tenantId: a.tenantId } });
    await runInTenant(a.tenantId, () => startCheckout(a.tenantId, { invoiceId: invoice.id }));
    setClock('2026-10-01T00:00:00Z');
    await inAcademy(a.tenantId, subscriptionRenewalCheck);
    fake.listOrderPayments = async () => {
      throw new Error('provider unreachable: key_secret=abcdef123456');
    };
    const seen: Observation[] = [];
    setObservationSink((_line, o) => seen.push(o));
    try {
      expect(await inAcademy(a.tenantId, pastDueRetry)).toMatchObject({ failed: 1, changed: 0 });
    } finally {
      setObservationSink(undefined);
    }
    const failure = seen.find((o) => o.signal === 'job.failed')!;
    expect(failure.fields).toMatchObject({ job: 'past-due-retry', tenantId: a.tenantId, subscriptionId: a.subscriptionId });
    expect(JSON.stringify(failure)).not.toContain('abcdef123456');
  });
});

describe('the existing scheduler runs them', () => {
  it('runs every job for every academy on one tick, and a second tick changes nothing', async () => {
    setPaymentProvider(new FakeProvider());
    const a = await academy(MONTHLY);
    const b = await academy(TRIAL, { start: 'trial' });
    setClock('2026-10-02T00:00:00Z');
    const first = await runBillingSchedule();
    const runsFor = (tick: typeof first, tenantId: string) => tick.academies.get(tenantId)!;
    expect(runsFor(first, a.tenantId).find((r) => r.job === 'invoice-generation')!.changed).toBe(1);
    expect(runsFor(first, a.tenantId).find((r) => r.job === 'subscription-renewal-check')!.changed).toBe(1);
    expect(runsFor(first, b.tenantId).find((r) => r.job === 'trial-expiry-check')!.changed).toBe(1);
    const before = [await snapshot(a.tenantId), await snapshot(b.tenantId)];
    const second = await runBillingSchedule();
    for (const tenantId of [a.tenantId, b.tenantId]) expect(runsFor(second, tenantId).every((r) => r.changed === 0)).toBe(true);
    expect([await snapshot(a.tenantId), await snapshot(b.tenantId)]).toEqual(before);
  });
});
