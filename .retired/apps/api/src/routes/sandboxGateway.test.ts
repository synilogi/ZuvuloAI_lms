import request from 'supertest';
import { afterEach, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { app, as, unique, type Client } from '../test/helpers.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { assertSandboxConfig, sandboxEnabled, sandboxProvider, setSandboxWebhookSender, type SandboxWebhook } from '../lib/sandboxGateway.js';

/*
 * The sandbox gateway (SAAS-030): a first purchase paid, declined and abandoned on its test checkout page, each
 * outcome reaching the platform only as a signed webhook through the normal webhook route — verified, idempotent,
 * and settled by the code that settles every gateway's payments.
 */

const PASSWORD = 'sandbox-password-1';
let platform: Client;
let planId: string;

/** The sandbox's webhooks are delivered to this app, through the real route. */
const deliver = (w: SandboxWebhook) => request(app).post('/webhooks/sandbox/subscription').set(w.headers).send(w.body);

async function academy() {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Sandbox Academy', slug: `sbx-${unique()}` } })).id;
  const email = `sbx-admin-${unique()}@example.com`;
  expect((await platform.post('/superadmin/admins', { name: 'Sandbox Admin', email, password: PASSWORD, tenantId })).status).toBe(201);
  const admin = await as({ email, password: PASSWORD });
  await admin.put('/tenant/billing-profile', {
    legalName: 'Sandbox Academy Pvt Ltd',
    email: 'accounts@example.com',
    addressLine1: '1 MG Road',
    city: 'Bengaluru',
    region: 'KA',
    postalCode: '560001',
    country: 'IN',
  });
  return { tenantId, admin };
}

const subscriptionOf = (tenantId: string) => platformDb.subscription.findFirst({ where: { tenantId }, orderBy: { createdAt: 'desc' } });

beforeAll(async () => {
  const email = `sbx-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Sandbox Platform' });
  platform = await as({ email, password: PASSWORD });
  const created = await platform.post('/superadmin/plans', {
    name: 'Sandbox Plan',
    description: 'Bought through the sandbox.',
    code: `SBX${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly'],
    monthlyPrice: 199900,
    annualPrice: 0,
    trialEnabled: false,
    trialDays: 0,
    limits: { 'learners.max': 100, 'instructors.max': 5, 'courses.max': 10, 'storage.bytes': 1_000_000_000, 'live_classes.max': 5, 'admin_accounts.max': 2 },
    features: ['courses.manage'],
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  await platform.post(`/superadmin/plans/${created.body.id}/publish`);
  planId = created.body.id;
});

beforeEach(() => {
  process.env.PAYMENT_SANDBOX = 'on';
  setSandboxWebhookSender(async (w) => ({ status: (await deliver(w)).status }));
});

afterEach(() => {
  delete process.env.PAYMENT_SANDBOX;
  setSandboxWebhookSender(null);
});

describe('switched off', () => {
  it('does not exist: no routes, no webhook endpoint, no checkout', async () => {
    delete process.env.PAYMENT_SANDBOX;
    expect((await request(app).get('/sandbox/orders/anything')).status).toBe(404);
    expect((await request(app).post('/sandbox/orders/anything/pay').send({ outcome: 'success' })).status).toBe(404);
    const w = sandboxProvider.webhookFor({ providerPaymentId: 'p', providerOrderId: 'o' }, 'payment.captured');
    expect((await deliver(w)).status).toBe(404);
    const a = await academy();
    expect((await a.admin.get('/tenant/billing')).body.checkoutAvailable).toBe(false);
  });

  it('is refused in production, whatever the switch says', () => {
    expect(sandboxEnabled({ PAYMENT_SANDBOX: 'on', NODE_ENV: 'production' })).toBe(false);
    expect(() => assertSandboxConfig({ PAYMENT_SANDBOX: 'on', NODE_ENV: 'production' })).toThrow(/refused in production/);
    expect(() => assertSandboxConfig({ PAYMENT_SANDBOX: 'on', NODE_ENV: 'development' })).not.toThrow();
  });
});

describe('a first purchase through the sandbox', () => {
  it('pays: the signed webhook activates the subscription, once', async () => {
    const a = await academy();
    expect((await a.admin.get('/tenant/billing')).body.checkoutAvailable).toBe(true);
    const start = await a.admin.post('/tenant/billing/purchase', { planId, cycle: 'monthly' });
    expect(start.status, JSON.stringify(start.body)).toBe(201);
    expect(start.body.checkout).toMatchObject({ provider: 'sandbox', amount: start.body.invoice.total });
    expect(start.body.checkout.redirectUrl).toMatch(new RegExp(`/sandbox-checkout/${start.body.checkout.orderId}$`));
    // GST from the server's rule, whatever the page shows.
    expect(start.body.invoice.total).toBe(Math.round(199900 * 1.18));
    expect(await subscriptionOf(a.tenantId)).toBeNull();

    const orderId = start.body.checkout.orderId as string;
    expect((await request(app).get(`/sandbox/orders/${orderId}`)).body).toMatchObject({ amount: start.body.invoice.total, status: 'created' });
    const paid = await request(app).post(`/sandbox/orders/${orderId}/pay`).send({ outcome: 'success' });
    expect(paid.body).toMatchObject({ status: 'paid', webhookDelivered: true });

    expect(await subscriptionOf(a.tenantId)).toMatchObject({ status: 'active', planId });
    const invoice = await platformDb.invoice.findUniqueOrThrow({ where: { id: start.body.invoice.id } });
    expect(invoice.status).toBe('paid');
    const payments = await platformDb.payment.findMany({ where: { tenantId: a.tenantId } });
    expect(payments).toHaveLength(1);
    expect(payments[0]).toMatchObject({ provider: 'sandbox', status: 'paid', amount: start.body.invoice.total });

    // The same event again, and the same payment under a new event id: nothing is paid twice.
    const again = sandboxProvider.webhookFor({ providerPaymentId: paid.body.paymentId, providerOrderId: orderId }, 'payment.captured');
    expect((await deliver(again)).body).toMatchObject({ received: true });
    expect((await deliver(again)).body).toMatchObject({ duplicate: true });
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
    expect(await platformDb.subscription.count({ where: { tenantId: a.tenantId } })).toBe(1);

    // Paying the same order again is refused at the gateway.
    expect((await request(app).post(`/sandbox/orders/${orderId}/pay`).send({ outcome: 'success' })).status).toBe(502);
  });

  it('is declined: nothing activates, the failure is recorded, and the academy can pay again', async () => {
    const a = await academy();
    const start = await a.admin.post('/tenant/billing/purchase', { planId, cycle: 'monthly' });
    const orderId = start.body.checkout.orderId as string;
    const declined = await request(app).post(`/sandbox/orders/${orderId}/pay`).send({ outcome: 'failure' });
    expect(declined.body).toMatchObject({ status: 'failed', webhookDelivered: true });
    expect(await subscriptionOf(a.tenantId)).toBeNull();
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: start.body.invoice.id } })).status).not.toBe('paid');
    expect(await platformDb.payment.findFirst({ where: { tenantId: a.tenantId, status: 'paid' } })).toBeNull();

    // A second try on the same invoice goes through.
    const retry = await a.admin.post('/tenant/billing/checkout', { invoiceId: start.body.invoice.id });
    expect(retry.status, JSON.stringify(retry.body)).toBeLessThan(300);
    const paid = await request(app).post(`/sandbox/orders/${retry.body.checkout.orderId}/pay`).send({ outcome: 'success' });
    expect(paid.body.status).toBe('paid');
    expect(await subscriptionOf(a.tenantId)).toMatchObject({ status: 'active' });
  });

  it('is abandoned: cancelling at the gateway changes nothing', async () => {
    const a = await academy();
    const start = await a.admin.post('/tenant/billing/purchase', { planId, cycle: 'monthly' });
    expect((await request(app).get(`/sandbox/orders/${start.body.checkout.orderId}`)).body.status).toBe('created');
    expect(await subscriptionOf(a.tenantId)).toBeNull();
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(0);
  });

  it('believes no forged or tampered webhook, and no forged browser completion', async () => {
    const a = await academy();
    const start = await a.admin.post('/tenant/billing/purchase', { planId, cycle: 'monthly' });
    const orderId = start.body.checkout.orderId as string;

    const real = sandboxProvider.webhookFor({ providerPaymentId: 'sbx_pay_forged', providerOrderId: orderId }, 'payment.captured');
    const forged = await request(app)
      .post('/webhooks/sandbox/subscription')
      .set({ ...real.headers, 'x-sandbox-signature': 'ab'.repeat(32) })
      .send(real.body);
    expect(forged.status).toBe(401);
    const tampered = await request(app).post('/webhooks/sandbox/subscription').set(real.headers).send(real.body.replace('captured', 'authorized'));
    expect(tampered.status).toBe(401);

    // The browser's word alone: a made-up payment with a made-up signature.
    const fake = await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: 'sbx_pay_made_up', signature: 'cd'.repeat(32) });
    expect(fake.status).toBeGreaterThanOrEqual(400);
    // A correctly signed completion for a payment that was never made at the gateway is still not believed.
    const signedButUnpaid = await a.admin.post('/tenant/billing/checkout/confirm', sandboxProvider.completionFor(orderId, 'sbx_pay_never_made'));
    expect(signedButUnpaid.status).toBeGreaterThanOrEqual(400);
    expect(await subscriptionOf(a.tenantId)).toBeNull();
  });

  it('never lets one academy settle another’s order', async () => {
    const a = await academy();
    const b = await academy();
    const startA = await a.admin.post('/tenant/billing/purchase', { planId, cycle: 'monthly' });
    const paid = await request(app).post(`/sandbox/orders/${startA.body.checkout.orderId}/pay`).send({ outcome: 'success' });
    // B hands A's genuine completion to its own confirm endpoint.
    const stolen = await b.admin.post('/tenant/billing/checkout/confirm', sandboxProvider.completionFor(startA.body.checkout.orderId, paid.body.paymentId));
    expect(stolen.status).toBeGreaterThanOrEqual(400);
    expect(await subscriptionOf(b.tenantId)).toBeNull();
    expect(await subscriptionOf(a.tenantId)).toMatchObject({ status: 'active' });
  });
});
