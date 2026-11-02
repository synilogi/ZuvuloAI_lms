import { createHmac } from 'node:crypto';

import { BYTES_PER_GB } from '@syniastrolms/domain';
import request from 'supertest';
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from 'vitest';

import { refundThroughProvider } from '../lib/checkout.js';
import { setClock } from '../lib/clock.js';
import { issueInvoice } from '../lib/invoices.js';
import { setObservationSink } from '../lib/observe.js';
import { activeProvider, providerFor } from '../lib/paymentGateways.js';
import { setPaymentProvider, setPaymentProviders } from '../lib/paymentProvider.js';
import { recordPayment } from '../lib/payments.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { RazorpayProvider } from '../lib/razorpay.js';
import type { LifecycleActor } from '../lib/subscriptions.js';
import { runAsPlatform } from '../lib/tenancy.js';
import { platformDb } from '../test/db.js';
import { FakeProvider, signWebhook } from '../test/fakeProvider.js';
import { PASSWORD, app, as, unique, type Client } from '../test/helpers.js';

/* SAAS-017: payment gateways configured at runtime by the Super Admin — credentials encrypted in the database,
 * one active gateway for new payments, and every existing invoice, payment, webhook and refund kept on the
 * gateway that created it. The Razorpay part runs the real adapter over a stubbed `fetch`; nothing reaches
 * Razorpay. Switching runs two fake gateways. Billed in Malaysia at 8% so no other suite's tax rule is disturbed. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('gateway tests act as the platform', fn);
const scheduler: LifecycleActor = { type: 'system', job: 'gateway-tests' };

const KEY_ID = 'rzp_test_GatewaySuite01';
const KEY_SECRET = 'gateway-suite-key-secret-value-0001';
const WEBHOOK_SECRET = 'gateway-suite-webhook-secret-value-0001';
const NEW_KEY_SECRET = 'gateway-suite-key-secret-value-0002';
const SECRETS = [KEY_SECRET, WEBHOOK_SECRET, NEW_KEY_SECRET];

let platform: Client;
let superAdmin: LifecycleActor & { type: 'user' };
let PLAN: string;
let BIG: string;

const limits = {
  'learners.max': 100,
  'instructors.max': 10,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 10,
  'admin_accounts.max': 5,
};

async function publishedPlan(monthly: number): Promise<string> {
  const created = await platform.post('/superadmin/plans', {
    name: `Gateway Plan ${unique()}`,
    description: 'A plan for the gateway suite.',
    code: `GW${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly', 'annual'],
    monthlyPrice: monthly,
    annualPrice: monthly * 10,
    trialEnabled: false,
    trialDays: 0,
    limits,
    features: ['courses.manage'],
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  expect((await platform.post(`/superadmin/plans/${created.body.id}/publish`)).status).toBe(200);
  return created.body.id as string;
}

interface Academy {
  tenantId: string;
  admin: Client;
  subscriptionId?: string;
}

async function academy(opts: { subscribed?: boolean } = {}): Promise<Academy> {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Gateway Academy', slug: `gw-${unique()}` } })).id;
  const email = `gw-admin-${unique()}@example.com`;
  expect((await platform.post('/superadmin/admins', { name: 'Gateway Admin', email, password: PASSWORD, tenantId })).status).toBe(201);
  const admin = await as({ email, password: PASSWORD });
  await admin.put('/tenant/billing-profile', {
    legalName: 'Gateway Academy Sdn Bhd',
    email: 'accounts@example.com',
    addressLine1: '1 Jalan Ampang',
    city: 'Kuala Lumpur',
    postalCode: '50450',
    country: 'MY',
  });
  if (opts.subscribed === false) return { tenantId, admin };
  setClock('2026-09-01T00:00:00Z');
  const sub = await platform.post('/superadmin/subscriptions', { tenantId, planId: PLAN, cycle: 'monthly', start: 'active' });
  expect(sub.status, JSON.stringify(sub.body)).toBe(201);
  setClock(null);
  return { tenantId, admin, subscriptionId: sub.body.id as string };
}

/** A renewal invoice for the academy — open, unpinned, waiting for a checkout. */
async function renewalInvoice(a: Academy) {
  setClock('2026-09-28T00:00:00Z');
  const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId! }));
  setClock(null);
  return invoice;
}

const paymentEvent = (paymentId: string, orderId: string) =>
  JSON.stringify({ entity: 'event', event: 'payment.captured', payload: { payment: { entity: { id: paymentId, order_id: orderId } } }, created_at: 1 });

const deliver = (provider: string, raw: string, secret: string, eventId = `evt_${unique()}`) =>
  request(app)
    .post(`/webhooks/${provider}/subscription`)
    .set('content-type', 'application/json')
    .set('x-razorpay-event-id', eventId)
    .set('x-razorpay-signature', signWebhook(raw, secret))
    .send(raw);

const gateway = async (provider: string) =>
  ((await platform.get('/superadmin/payment-gateways')).body.rows as { provider: string }[]).find((g) => g.provider === provider)!;
const auditsFor = (action: string, targetId?: string) =>
  platformDb.auditLog.findMany({ where: { action, ...(targetId ? { targetId } : {}) }, orderBy: { createdAt: 'asc' } });

/** Everything the server logged while `fn` ran. */
async function logged(fn: () => Promise<unknown>): Promise<string> {
  const lines: string[] = [];
  const spies = (['log', 'warn', 'error', 'info'] as const).map((k) => vi.spyOn(console, k).mockImplementation((...args) => void lines.push(args.join(' '))));
  setObservationSink((line) => void lines.push(line));
  try {
    await fn();
  } finally {
    setObservationSink(undefined);
    spies.forEach((s) => s.mockRestore());
  }
  return lines.join('\n');
}

/** Razorpay's REST API, stubbed: an order echoes what was asked; a list answers empty; a 401 when told to. */
function stubRazorpay(opts: { refuse?: boolean } = {}) {
  const calls: { method: string; url: string; auth?: string }[] = [];
  vi.stubGlobal('fetch', async (url: string, init: RequestInit) => {
    calls.push({ method: String(init.method), url, auth: (init.headers as Record<string, string>).Authorization });
    if (opts.refuse) return new Response(JSON.stringify({ error: { code: 'BAD_REQUEST_ERROR', description: 'Authentication failed' } }), { status: 401 });
    if (init.method === 'POST' && url.endsWith('/orders')) {
      const body = JSON.parse(String(init.body));
      return new Response(JSON.stringify({ id: `order_rzp_${unique()}`, amount: body.amount, currency: body.currency, status: 'created' }), { status: 200 });
    }
    return new Response(JSON.stringify({ entity: 'collection', count: 0, items: [] }), { status: 200 });
  });
  return calls;
}

beforeAll(async () => {
  const email = `gw-su-${unique()}@example.com`;
  const created = await provisionSuperAdmin({ email, password: PASSWORD, name: 'Gateway Keeper' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
  platform = await as({ email, password: PASSWORD });
  expect((await platform.post('/superadmin/tax-rules', { name: 'SST', country: 'MY', components: [{ code: 'SST', label: 'SST', rateBps: 800 }] })).status).toBe(
    201,
  );
  PLAN = await publishedPlan(100000);
  BIG = await publishedPlan(300000);
});

afterEach(() => {
  setClock(null);
  setPaymentProvider(undefined);
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
});

afterAll(async () => {
  // Leave the shared database as found: no gateway active, Razorpay disabled.
  setPaymentProvider(undefined);
  await platform.post('/superadmin/payment-gateways/deactivate');
  await platform.patch('/superadmin/payment-gateways/razorpay', { enabled: false });
});

/* ─── Configuration, from the Super Admin panel ─────────────────────────── */

const LIVE_KEY_ID = 'rzp_live_GatewaySuite02';
const LIVE_KEY_SECRET = 'gateway-suite-live-key-secret-0003';
const LIVE_WEBHOOK_SECRET = 'gateway-suite-live-webhook-secret-0003';
const VYAPAR_API = 'gateway-suite-vyapar-api-credential-0004';
const VYAPAR_HOOK = 'gateway-suite-vyapar-webhook-secret-0004';
const ALL_SECRETS = [...SECRETS, LIVE_KEY_SECRET, LIVE_WEBHOOK_SECRET, VYAPAR_API, VYAPAR_HOOK];
const configure = (provider: string, environment: string, credentials: Record<string, string>) =>
  platform.post(`/superadmin/payment-gateways/${provider}/config`, { environment, credentials });
const credentialRow = (provider: string, environment: string) =>
  platformDb.paymentGatewayCredential.findUnique({ where: { provider_environment: { provider, environment } } });

describe('gateway configuration (Super Admin)', () => {
  it('lists every known gateway with only safe fields', async () => {
    const res = await platform.get('/superadmin/payment-gateways');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ vaultConfigured: true, active: null });
    const byId = Object.fromEntries((res.body.rows as { provider: string; unavailableReason?: string }[]).map((r) => [r.provider, r]));
    expect(Object.keys(byId).sort()).toEqual(['razorpay', 'vyapargateway']);
    expect(byId.razorpay).toMatchObject({ implemented: true, isActive: false, configured: false, testSupported: true, canActivate: false });
    expect(byId.vyapargateway).toMatchObject({ implemented: false, fieldsProvisional: true, configured: false, testSupported: false });
    expect(byId.vyapargateway.unavailableReason).toMatch(/merchant API contract/);
    for (const row of res.body.rows) expect(Object.keys(row)).not.toEqual(expect.arrayContaining(['cipher', 'credentialsCipher']));
  });

  it('refuses every gateway operation to anyone but a Super Admin', async () => {
    const a = await academy({ subscribed: false });
    const instructor = await as('instructor');
    const calls = (c: Client) => [
      c.get('/superadmin/payment-gateways'),
      c.post('/superadmin/payment-gateways/razorpay/config', {
        environment: 'test',
        credentials: { keyId: KEY_ID, keySecret: KEY_SECRET, webhookSecret: WEBHOOK_SECRET },
      }),
      c.patch('/superadmin/payment-gateways/razorpay', { enabled: true }),
      c.post('/superadmin/payment-gateways/razorpay/test'),
      c.post('/superadmin/payment-gateways/razorpay/activate'),
      c.post('/superadmin/payment-gateways/deactivate'),
    ];
    for (const c of [a.admin, instructor]) for (const res of await Promise.all(calls(c))) expect(res.status).toBe(403);
    expect((await request(app).get('/superadmin/payment-gateways')).status).toBe(401);
    expect(await credentialRow('razorpay', 'test')).toBeNull();
  });

  it('without PAYMENT_CREDENTIALS_KEY: still answers, refuses a save with SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED, audits it', async () => {
    vi.stubEnv('PAYMENT_CREDENTIALS_KEY', '');
    expect((await platform.get('/superadmin/payment-gateways')).body.vaultConfigured).toBe(false);
    const res = await configure('razorpay', 'test', { keyId: KEY_ID, keySecret: KEY_SECRET, webhookSecret: WEBHOOK_SECRET });
    expect(res.status).toBe(503);
    expect(res.body).toMatchObject({ code: 'SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED' });
    expect(res.body.message).toMatch(/PAYMENT_CREDENTIALS_KEY/);
    expect(await credentialRow('razorpay', 'test')).toBeNull();
    const failed = (await auditsFor('gateway.configuration_failed', 'razorpay')).at(-1)!;
    expect(failed.metaJson).toMatch(/Secure credential storage/);
    for (const secret of SECRETS) expect(failed.metaJson).not.toContain(secret);
  });

  it('refuses invalid credentials — missing, unknown, the wrong environment’s key, a reused secret — and audits each without a value', async () => {
    const before = (await auditsFor('gateway.configuration_failed', 'razorpay')).length;
    expect((await configure('razorpay', 'test', { keyId: KEY_ID })).status).toBe(400);
    expect((await configure('razorpay', 'test', { apiKey: 'x' })).status).toBe(400);
    const liveInTest = await configure('razorpay', 'test', { keyId: LIVE_KEY_ID, keySecret: KEY_SECRET, webhookSecret: WEBHOOK_SECRET });
    expect(liveInTest.status).toBe(400);
    expect(liveInTest.body.message).toMatch(/not a test key/);
    expect((await configure('razorpay', 'test', { keyId: KEY_ID, keySecret: KEY_SECRET, webhookSecret: KEY_SECRET })).status).toBe(400);
    const failures = (await auditsFor('gateway.configuration_failed', 'razorpay')).slice(before);
    expect(failures).toHaveLength(4);
    for (const secret of ALL_SECRETS) expect(JSON.stringify(failures)).not.toContain(secret);
    expect(await credentialRow('razorpay', 'test')).toBeNull();
  });

  it('configures Razorpay: encrypted, masked, never returned, logged or audited', async () => {
    let res!: request.Response;
    const log = await logged(async () => {
      res = await configure('razorpay', 'test', { keyId: KEY_ID, keySecret: KEY_SECRET, webhookSecret: WEBHOOK_SECRET });
    });
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    expect(res.body).toMatchObject({ provider: 'razorpay', configured: true, environment: 'test', hint: { keyId: 'rzp_test_…te01' } });
    expect(res.body.credentials.test).toMatchObject({ configured: true, hint: { keyId: 'rzp_test_…te01' } });
    expect(res.body.credentials.live).toMatchObject({ configured: false });
    expect(res.body.secretsSet.sort()).toEqual(['keySecret', 'webhookSecret']);
    // Not yet enabled: configured is not enough to become active.
    expect(res.body).toMatchObject({ canActivate: false, activationBlockedReason: expect.stringMatching(/disabled/) });

    const row = (await credentialRow('razorpay', 'test'))!;
    expect(row.cipher).toMatch(/^v1:/);
    const listed = JSON.stringify((await platform.get('/superadmin/payment-gateways')).body);
    const audit = JSON.stringify(await platformDb.auditLog.findMany({ where: { targetType: 'payment_gateway' } }));
    for (const secret of SECRETS) {
      for (const where of [row.cipher, row.hint, JSON.stringify(res.body), listed, audit, log]) expect(where).not.toContain(secret);
    }
    // Even the key ID — publishable — is stored only inside the ciphertext and masked everywhere else.
    expect(listed).not.toContain(KEY_ID);
    const configured = (await auditsFor('gateway.configured', 'razorpay')).at(-1)!;
    expect(configured).toMatchObject({ actorType: 'user', actorRole: 'superadmin' });
    expect(JSON.parse(configured.metaJson)).toMatchObject({
      provider: 'razorpay',
      environment: 'test',
      fieldsChanged: ['keyId', 'keySecret', 'webhookSecret'],
    });
  });

  it('decrypts server-side into the adapter, and replaces one secret without the others being shown or re-entered', async () => {
    const res = await configure('razorpay', 'test', { keySecret: NEW_KEY_SECRET, webhookSecret: '' });
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    const replaced = (await auditsFor('gateway.credentials_replaced', 'razorpay')).at(-1)!;
    expect(JSON.parse(replaced.metaJson)).toMatchObject({ environment: 'test', fieldsChanged: ['keySecret'] });
    expect(replaced.metaJson).not.toContain(NEW_KEY_SECRET);
    // One row, replaced in place.
    expect(await platformDb.paymentGatewayCredential.count({ where: { provider: 'razorpay', environment: 'test' } })).toBe(1);
    const provider = await providerFor('razorpay', 'test');
    expect(provider).toBeInstanceOf(RazorpayProvider);
    expect(provider.environment).toBe('test');
    expect(provider.verifyWebhook('{}', signWebhook('{}', WEBHOOK_SECRET))).toBe(true);
    const calls = stubRazorpay();
    await provider.fetchPayment('pay_x').catch(() => undefined);
    expect(calls[0]!.auth).toBe(`Basic ${Buffer.from(`${KEY_ID}:${NEW_KEY_SECRET}`).toString('base64')}`);
  });

  it('keeps live credentials apart from test: saving one never touches the other', async () => {
    const testBefore = (await credentialRow('razorpay', 'test'))!;
    const res = await configure('razorpay', 'live', { keyId: LIVE_KEY_ID, keySecret: LIVE_KEY_SECRET, webhookSecret: LIVE_WEBHOOK_SECRET });
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    // New payments still use test: adding live keys does not switch the gateway.
    expect(res.body).toMatchObject({
      environment: 'test',
      credentials: { test: { configured: true }, live: { configured: true, hint: { keyId: 'rzp_live_…te02' } } },
    });
    expect((await credentialRow('razorpay', 'test'))!.cipher).toBe(testBefore.cipher);
    expect((await providerFor('razorpay', 'live')).environment).toBe('live');
    expect((await providerFor('razorpay', 'test')).environment).toBe('test');
    // A test key cannot be saved as live.
    expect((await configure('razorpay', 'live', { keyId: KEY_ID })).status).toBe(400);
  });

  it('tests the configuration server-side with a read that charges nothing — per environment — and reports a refusal as a failure', async () => {
    const calls = stubRazorpay();
    const ok = await platform.post('/superadmin/payment-gateways/razorpay/test');
    expect(ok.body).toMatchObject({ ok: true, checked: true, environment: 'test' });
    expect(calls.map((c) => `${c.method} ${c.url}`)).toEqual(['GET https://api.razorpay.com/v1/orders?count=1']);
    expect(calls[0]!.auth).toContain(Buffer.from(`${KEY_ID}:`).toString('base64').slice(0, 12));
    const live = await platform.post('/superadmin/payment-gateways/razorpay/test', { environment: 'live' });
    expect(live.body).toMatchObject({ ok: true, environment: 'live' });
    expect(calls[1]!.auth).toBe(`Basic ${Buffer.from(`${LIVE_KEY_ID}:${LIVE_KEY_SECRET}`).toString('base64')}`);
    vi.unstubAllGlobals();
    stubRazorpay({ refuse: true });
    const refused = await platform.post('/superadmin/payment-gateways/razorpay/test');
    expect(refused.body).toMatchObject({ ok: false, checked: true, detail: 'Razorpay refused the key id and secret.' });
    for (const secret of ALL_SECRETS) expect(JSON.stringify(refused.body)).not.toContain(secret);
    const tests = await auditsFor('gateway.test_attempted', 'razorpay');
    expect(tests.slice(-3).map((t) => JSON.parse(t.metaJson).ok)).toEqual([true, true, false]);
  });

  it('configures VyaparGateway with its confirmed fields — stored encrypted, but it cannot take payments or be tested yet', async () => {
    expect((await configure('vyapargateway', 'test', { apiCredential: VYAPAR_API })).status).toBe(400);
    const res = await configure('vyapargateway', 'test', { apiCredential: VYAPAR_API, webhookSecret: VYAPAR_HOOK });
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    expect(res.body).toMatchObject({ configured: true, implemented: false, canActivate: false, secretsSet: ['apiCredential', 'webhookSecret'] });
    expect(res.body.activationBlockedReason).toMatch(/merchant API contract/);
    expect((await credentialRow('vyapargateway', 'test'))!.cipher).toMatch(/^v1:/);
    for (const secret of [VYAPAR_API, VYAPAR_HOOK]) expect(JSON.stringify(res.body)).not.toContain(secret);
    // Enabling is allowed; activation is not, and the test says it checked nothing.
    expect((await platform.patch('/superadmin/payment-gateways/vyapargateway', { enabled: true })).body).toMatchObject({ enabled: true, canActivate: false });
    expect((await platform.post('/superadmin/payment-gateways/vyapargateway/activate')).status).toBe(409);
    expect((await platform.post('/superadmin/payment-gateways/vyapargateway/test')).body).toMatchObject({ ok: false, checked: false });
    await expect(providerFor('vyapargateway', 'test')).rejects.toMatchObject({ status: 409 });
  });
});

/* ─── The active gateway ─────────────────────────────────────────────── */

describe('the active gateway', () => {
  it('can only be an enabled, configured, implemented gateway — and only one at a time', async () => {
    expect((await platform.post('/superadmin/payment-gateways/razorpay/activate')).status).toBe(409); // disabled
    expect((await platform.patch('/superadmin/payment-gateways/razorpay', { enabled: true })).body).toMatchObject({
      enabled: true,
      isActive: false,
      canActivate: true,
    });
    expect((await auditsFor('gateway.enabled', 'razorpay')).length).toBeGreaterThan(0);

    const activated = await platform.post('/superadmin/payment-gateways/razorpay/activate');
    expect(activated.status, JSON.stringify(activated.body)).toBe(200);
    expect(activated.body).toMatchObject({ isActive: true });
    expect(JSON.parse((await auditsFor('gateway.activated', 'razorpay')).at(-1)!.metaJson)).toMatchObject({ environment: 'test', previous: null });
    expect((await platform.get('/superadmin/payment-gateways')).body.active).toBe('razorpay');

    expect((await platform.post('/superadmin/payment-gateways/stripe/activate')).status).toBe(404);
    // The active gateway cannot be disabled.
    expect((await platform.patch('/superadmin/payment-gateways/razorpay', { enabled: false })).status).toBe(409);
    expect(await platformDb.paymentGatewayConfig.count({ where: { isActive: true } })).toBe(1);
  });

  it('is what the factory builds for new payments: the Razorpay adapter, in its environment, from the stored credentials', async () => {
    const provider = await activeProvider();
    expect(provider).toBeInstanceOf(RazorpayProvider);
    expect(provider).toMatchObject({ name: 'razorpay', environment: 'test' });
    // Cached until the credentials change.
    expect(await activeProvider()).toBe(provider);
  });

  it('takes no new payment in test mode on a production process, yet still settles what test mode made', async () => {
    vi.stubEnv('NODE_ENV', 'production');
    try {
      // A test card would otherwise buy a real plan on the live site.
      expect(await activeProvider()).toBeNull();
      expect(await providerFor('razorpay', 'test')).toMatchObject({ name: 'razorpay', environment: 'test' });
    } finally {
      vi.unstubAllEnvs();
    }
    expect(await activeProvider()).toMatchObject({ name: 'razorpay', environment: 'test' });
  });

  it('holds its rules in the database too: never two active, never an unconfigured one, never deleted', async () => {
    await expect(platformDb.paymentGatewayConfig.update({ where: { provider: 'vyapargateway' }, data: { isActive: true } })).rejects.toThrow();
    await expect(platformDb.paymentGatewayConfig.create({ data: { provider: 'stripe' } })).rejects.toThrow();
    await expect(platformDb.paymentGatewayConfig.delete({ where: { provider: 'razorpay' } })).rejects.toThrow();
    await expect(
      platformDb.paymentGatewayCredential.delete({ where: { provider_environment: { provider: 'razorpay', environment: 'test' } } }),
    ).rejects.toThrow();
    await expect(platformDb.$executeRawUnsafe(`UPDATE "PaymentGatewayConfig" SET "enabled" = 0 WHERE "provider" = 'razorpay'`)).rejects.toThrow();
  });

  it('opens a real Razorpay order for a new invoice, priced by the server, recording its environment, with no secret in the checkout', async () => {
    const calls = stubRazorpay();
    const a = await academy();
    const invoice = await renewalInvoice(a);
    const res = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id, provider: 'vyapargateway', amount: 1, environment: 'live' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body.checkout).toMatchObject({ provider: 'razorpay', keyId: KEY_ID, amount: invoice.total, currency: 'INR' });
    for (const secret of ALL_SECRETS) expect(JSON.stringify(res.body)).not.toContain(secret);
    expect(calls.filter((c) => c.method === 'POST')).toHaveLength(1);
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).provider).toBe('razorpay');
    expect((await platformDb.paymentOrder.findFirstOrThrow({ where: { invoiceId: invoice.id } })).environment).toBe('test');
  });

  it('switches to live for new payments only: an order made in test is still confirmed with the test keys', async () => {
    const payments = new Map<string, { order: string; amount: number }>();
    const calls: { method: string; url: string; auth: string }[] = [];
    vi.stubGlobal('fetch', async (url: string, init: RequestInit) => {
      calls.push({ method: String(init.method), url, auth: (init.headers as Record<string, string>).Authorization });
      if (init.method === 'POST' && url.endsWith('/orders')) {
        const body = JSON.parse(String(init.body));
        return new Response(JSON.stringify({ id: `order_rzp_${unique()}`, amount: body.amount, currency: body.currency, status: 'created' }));
      }
      const pay = /\/payments\/([^/?]+)(\?|$)/.exec(url)?.[1];
      if (pay && payments.has(pay)) {
        const p = payments.get(pay)!;
        return new Response(JSON.stringify({ id: pay, order_id: p.order, amount: p.amount, currency: 'INR', status: 'captured', method: 'upi' }));
      }
      return new Response(JSON.stringify({ items: [] }));
    });
    const auth = (id: string, secret: string) => `Basic ${Buffer.from(`${id}:${secret}`).toString('base64')}`;
    const a = await academy();
    const inTest = await a.admin.post('/tenant/billing/checkout', { invoiceId: (await renewalInvoice(a)).id });
    const testOrder = inTest.body.checkout.orderId as string;

    const switched = await platform.patch('/superadmin/payment-gateways/razorpay', { environment: 'live' });
    expect(switched.body).toMatchObject({ environment: 'live', isActive: true });
    expect(JSON.parse((await auditsFor('gateway.environment_changed', 'razorpay')).at(-1)!.metaJson)).toMatchObject({ from: 'test', to: 'live', active: true });
    expect(await activeProvider()).toMatchObject({ environment: 'live' });

    // A new invoice now opens a live order with the live keys.
    const b = await academy();
    const inLive = await b.admin.post('/tenant/billing/checkout', { invoiceId: (await renewalInvoice(b)).id });
    expect(inLive.body.checkout.keyId).toBe(LIVE_KEY_ID);
    expect(calls.at(-1)!.auth).toBe(auth(LIVE_KEY_ID, LIVE_KEY_SECRET));
    expect((await platformDb.paymentOrder.findFirstOrThrow({ where: { providerOrderId: inLive.body.checkout.orderId } })).environment).toBe('live');

    // The test order is confirmed with the test key secret, and read back with the test keys.
    const paymentId = `pay_${unique()}`;
    payments.set(paymentId, { order: testOrder, amount: inTest.body.checkout.amount });
    const signature = createHmac('sha256', NEW_KEY_SECRET).update(`${testOrder}|${paymentId}`).digest('hex');
    const confirmed = await a.admin.post('/tenant/billing/checkout/confirm', { orderId: testOrder, paymentId, signature });
    expect(confirmed.body, JSON.stringify(confirmed.body)).toMatchObject({ status: 'paid', settled: true });
    expect(calls.filter((c) => c.url.includes(paymentId)).every((c) => c.auth === auth(KEY_ID, NEW_KEY_SECRET))).toBe(true);
    // Signed with the live secret instead, the test order's confirmation would not verify.
    const liveSigned = createHmac('sha256', LIVE_KEY_SECRET).update(`${testOrder}|${paymentId}`).digest('hex');
    expect((await a.admin.post('/tenant/billing/checkout/confirm', { orderId: testOrder, paymentId, signature: liveSigned })).status).toBe(400);

    // Test and live webhooks share the URL; each verifies with its own environment's secret.
    const raw = paymentEvent(`pay_${unique()}`, `order_unknown_${unique()}`);
    expect((await deliver('razorpay', raw, LIVE_WEBHOOK_SECRET)).status).toBe(200);
    expect((await deliver('razorpay', raw, WEBHOOK_SECRET)).status).toBe(200);

    // An environment with no credentials cannot be switched to (vyapar has none for live).
    expect((await platform.patch('/superadmin/payment-gateways/vyapargateway', { environment: 'live' })).status).toBe(409);
    expect((await platform.patch('/superadmin/payment-gateways/razorpay', { environment: 'test' })).body).toMatchObject({ environment: 'test' });
  });

  it('verifies a Razorpay webhook with the stored webhook secret — not the key secret — and audits a rejection', async () => {
    const raw = paymentEvent(`pay_${unique()}`, `order_unknown_${unique()}`);
    expect((await deliver('razorpay', raw, NEW_KEY_SECRET)).status).toBe(401);
    expect((await auditsFor('webhook.rejected')).at(-1)).toMatchObject({ actorType: 'provider', source: 'razorpay' });
    const accepted = await deliver('razorpay', raw, WEBHOOK_SECRET);
    expect(accepted.status, JSON.stringify(accepted.body)).toBe(200);
    expect((await auditsFor('webhook.accepted')).at(-1)).toMatchObject({ actorType: 'provider', source: 'razorpay' });
    // A gateway with no adapter has no webhook endpoint yet.
    expect((await deliver('vyapargateway', raw, VYAPAR_HOOK)).status).toBe(404);
  });

  it('refuses stored credentials sealed under another key: needs re-entry, no online payment, nothing decrypted', async () => {
    const row = (await credentialRow('razorpay', 'test'))!;
    await platformDb.$executeRawUnsafe(`UPDATE "PaymentGatewayCredential" SET "keyId" = 'ffffffffffffffff' WHERE "id" = '${row.id}'`);
    try {
      expect(await gateway('razorpay')).toMatchObject({ configured: false, needsReentry: true });
      expect(await activeProvider()).toBeNull();
      await expect(providerFor('razorpay', 'test')).rejects.toMatchObject({ status: 409 });
      // A partial save cannot reuse what cannot be opened: every field must be entered again.
      expect((await configure('razorpay', 'test', { keySecret: NEW_KEY_SECRET })).body.message).toMatch(/entered again/);
    } finally {
      await platformDb.$executeRawUnsafe(`UPDATE "PaymentGatewayCredential" SET "keyId" = '${row.keyId}' WHERE "id" = '${row.id}'`);
    }
    expect(await activeProvider()).toBeInstanceOf(RazorpayProvider);
  });

  it('can be switched off on purpose: no gateway, online payment unavailable, audited', async () => {
    const res = await platform.post('/superadmin/payment-gateways/deactivate');
    expect(res.body).toEqual({ deactivated: 'razorpay' });
    expect(await activeProvider()).toBeNull();
    expect(JSON.parse((await auditsFor('gateway.deactivated', 'razorpay')).at(-1)!.metaJson)).toMatchObject({ replacedBy: null });
    const a = await academy();
    const invoice = await renewalInvoice(a);
    expect((await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id })).body).toMatchObject({ code: 'PAYMENT_REQUIRED' });
    expect((await a.admin.get('/tenant/billing')).body.checkoutAvailable).toBe(false);
    // Now it may be disabled.
    expect((await platform.patch('/superadmin/payment-gateways/razorpay', { enabled: false })).body).toMatchObject({ enabled: false });
    expect((await auditsFor('gateway.disabled', 'razorpay')).length).toBeGreaterThan(0);
  });

  it('keeps serving what it created after it is disabled: the invoice pinned to it still resolves to it', async () => {
    const pinned = await platformDb.invoice.findFirstOrThrow({ where: { provider: 'razorpay', status: 'open' } });
    expect(pinned.provider).toBe('razorpay');
    expect(await providerFor('razorpay', 'test')).toBeInstanceOf(RazorpayProvider);
  });
});

/* ─── Switching: existing payments stay on their gateway ─────────────── */

describe('switching the active gateway', () => {
  const first = () => new FakeProvider('fakepay');
  const second = () => new FakeProvider('fakepay2');

  it('moves only new invoices: invoice A stays on the old gateway, invoice B uses the new one', async () => {
    const one = first();
    const two = second();
    setPaymentProviders([one, two], 'fakepay');
    const a = await academy();
    const b = await academy();
    const invoiceA = await renewalInvoice(a);
    const startA = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoiceA.id });
    expect(startA.body.checkout.provider).toBe('fakepay');

    // Day 2: the Super Admin switches.
    setPaymentProviders([one, two], 'fakepay2');
    const invoiceB = await renewalInvoice(b);
    const startB = await b.admin.post('/tenant/billing/checkout', { invoiceId: invoiceB.id });
    expect(startB.body.checkout.provider).toBe('fakepay2');
    // Invoice A, asked again, reuses its order on its own gateway.
    const againA = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoiceA.id });
    expect(againA.body.checkout).toMatchObject({ provider: 'fakepay', orderId: startA.body.checkout.orderId });
    expect(two.orders.size).toBe(1);

    // A is paid and confirmed through fakepay, although fakepay2 is active.
    const paidA = one.pay(startA.body.checkout.orderId, 'paid');
    // Another gateway's signature for the same order does not verify.
    const forged = await a.admin.post('/tenant/billing/checkout/confirm', {
      orderId: startA.body.checkout.orderId,
      paymentId: paidA.paymentId,
      signature: `sig-fakepay2:${startA.body.checkout.orderId}|${paidA.paymentId}`,
    });
    expect(forged.status).toBe(400);
    const confirmA = await a.admin.post('/tenant/billing/checkout/confirm', {
      orderId: startA.body.checkout.orderId,
      paymentId: paidA.paymentId,
      signature: paidA.signature,
    });
    expect(confirmA.body).toMatchObject({ status: 'paid', settled: true, applied: true });
    const paymentA = await platformDb.payment.findFirstOrThrow({ where: { invoiceId: invoiceA.id } });
    expect(paymentA.provider).toBe('fakepay');
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoiceA.id } })).provider).toBe('fakepay');
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoiceB.id } })).provider).toBe('fakepay2');

    // B is paid through fakepay2's webhook; a duplicate delivery repeats nothing.
    const paidB = two.pay(startB.body.checkout.orderId, 'paid');
    const raw = paymentEvent(paidB.paymentId, startB.body.checkout.orderId);
    const eventId = `evt_${unique()}`;
    expect((await deliver('fakepay2', raw, 'fake-webhook-secret-for-tests', eventId)).body).toMatchObject({ received: true, outcome: 'processed' });
    expect((await deliver('fakepay2', raw, 'fake-webhook-secret-for-tests', eventId)).body).toMatchObject({ duplicate: true });
    expect(await platformDb.payment.count({ where: { invoiceId: invoiceB.id } })).toBe(1);
    expect((await platformDb.payment.findFirstOrThrow({ where: { invoiceId: invoiceB.id } })).provider).toBe('fakepay2');
    expect((await platformDb.subscription.findUniqueOrThrow({ where: { id: b.subscriptionId! } })).currentPeriodEndAt.toISOString()).toBe(
      '2026-11-01T00:00:00.000Z',
    );
  });

  it('never lets an order or a pin move an invoice to another gateway (database)', async () => {
    setPaymentProviders([first(), second()], 'fakepay');
    const a = await academy();
    const invoice = await renewalInvoice(a);
    expect((await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id })).status).toBe(201);
    await expect(
      platformDb.paymentOrder.create({
        data: {
          tenantId: a.tenantId,
          invoiceId: invoice.id,
          provider: 'fakepay2',
          providerOrderId: `order_${unique()}`,
          amount: invoice.total,
          currency: 'INR',
        },
      }),
    ).rejects.toThrow();
    await expect(platformDb.invoice.update({ where: { id: invoice.id }, data: { provider: 'fakepay2' } })).rejects.toThrow();
  });

  it('refuses a checkout on a pinned invoice whose gateway can no longer be used — no order, nothing changed', async () => {
    const one = first();
    setPaymentProviders([one, second()], 'fakepay');
    const a = await academy();
    const invoice = await renewalInvoice(a);
    await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    setPaymentProviders([second()], 'fakepay2');
    const res = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    expect(res.status).toBe(409);
    expect(await platformDb.paymentOrder.count({ where: { invoiceId: invoice.id } })).toBe(1);
  });

  it('prices a new upgrade on the new gateway, and rejects a wrong amount or a failed payment without applying it', async () => {
    const two = second();
    setPaymentProviders([first(), two], 'fakepay2');
    const a = await academy();
    setClock('2026-09-16T00:00:00Z');
    const quote = await a.admin.post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly' });
    const start = await a.admin.post('/tenant/billing/checkout', { planChangeId: quote.body.change.id });
    expect(start.body.checkout.provider).toBe('fakepay2');
    const orderId = start.body.checkout.orderId as string;

    const failed = two.pay(orderId, 'failed');
    expect((await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: failed.paymentId, signature: failed.signature })).body).toMatchObject({
      status: 'failed',
      applied: false,
    });
    const short = two.pay(orderId, 'paid', { amount: 1 });
    expect((await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: short.paymentId, signature: short.signature })).body).toMatchObject({
      settled: false,
      applied: false,
    });
    expect((await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId! } })).planId).toBe(PLAN);

    const paid = two.pay(orderId, 'paid');
    expect((await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: paid.paymentId, signature: paid.signature })).body).toMatchObject({
      settled: true,
      applied: true,
    });
    expect((await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId! } })).planId).toBe(BIG);
  });

  it('starts a first purchase on the active gateway, and audits the choice, the order and the verification', async () => {
    const one = first();
    setPaymentProviders([one], 'fakepay');
    const a = await academy({ subscribed: false });
    const res = await a.admin.post('/tenant/billing/purchase', { planId: PLAN, cycle: 'monthly', provider: 'fakepay2', amount: 1, tenantId: 'someone-else' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body.checkout).toMatchObject({ provider: 'fakepay', amount: 108000 });
    const invoiceId = res.body.invoice.id as string;
    const paid = one.pay(res.body.checkout.orderId, 'paid');
    expect(
      (await a.admin.post('/tenant/billing/checkout/confirm', { orderId: res.body.checkout.orderId, paymentId: paid.paymentId, signature: paid.signature }))
        .body,
    ).toMatchObject({
      settled: true,
      applied: true,
    });
    expect(await platformDb.subscription.count({ where: { tenantId: a.tenantId } })).toBe(1);
    for (const action of ['payment.provider_selected', 'payment.created', 'payment.verified']) {
      const entry = (await auditsFor(action, invoiceId)).at(-1);
      expect(entry, action).toMatchObject({ actorType: 'user', actorRole: 'admin' });
      expect(JSON.parse(entry!.metaJson)).toMatchObject({ provider: 'fakepay', tenantId: a.tenantId });
    }
  });

  it('keeps each academy to its own checkouts: another academy’s order is not found', async () => {
    const one = first();
    setPaymentProviders([one], 'fakepay');
    const a = await academy();
    const b = await academy();
    const start = await a.admin.post('/tenant/billing/checkout', { invoiceId: (await renewalInvoice(a)).id });
    const paid = one.pay(start.body.checkout.orderId, 'paid');
    expect(
      (await b.admin.post('/tenant/billing/checkout/confirm', { orderId: start.body.checkout.orderId, paymentId: paid.paymentId, signature: paid.signature }))
        .status,
    ).toBe(404);
    expect(await platformDb.payment.count({ where: { invoiceId: start.body.invoice.id } })).toBe(0);
  });
});

/* ─── Refunds go through the gateway that took the payment ───────────── */

describe('refunds', () => {
  it('uses the original payment’s gateway, never the active one', async () => {
    const one = new FakeProvider('fakepay');
    const two = new FakeProvider('fakepay2');
    setPaymentProviders([one, two], 'fakepay');
    const a = await academy();
    const start = await a.admin.post('/tenant/billing/checkout', { invoiceId: (await renewalInvoice(a)).id });
    const paid = one.pay(start.body.checkout.orderId, 'paid');
    await a.admin.post('/tenant/billing/checkout/confirm', { orderId: start.body.checkout.orderId, paymentId: paid.paymentId, signature: paid.signature });
    const payment = await platformDb.payment.findFirstOrThrow({ where: { providerPaymentId: paid.paymentId } });

    setPaymentProviders([one, two], 'fakepay2');
    const refund = await asPlatform(() => refundThroughProvider(superAdmin, payment.id, { amount: 1000, reason: 'Goodwill' }));
    expect(refund.status).toBe('succeeded');
    expect(one.refunds).toEqual([{ providerPaymentId: paid.paymentId, amount: 1000, notes: expect.anything() }]);
    expect(two.refunds).toEqual([]);
    expect((await auditsFor('payment.refund_attempted', payment.id)).at(-1)).toMatchObject({ actorType: 'user', actorRole: 'superadmin' });
  });

  it('refuses, changing nothing, when the original gateway can no longer be used', async () => {
    const a = await academy();
    const invoice = await renewalInvoice(a);
    // A payment Razorpay took, while only another gateway is installed now.
    const recorded = await recordPayment(
      { type: 'provider', provider: 'razorpay', reference: 'pay_old' },
      {
        invoiceId: invoice.id,
        providerPaymentId: `pay_old_${unique()}`,
        amount: invoice.total,
        currency: 'INR',
        status: 'paid',
      },
    );
    setPaymentProviders([new FakeProvider('fakepay2')], 'fakepay2');
    await expect(asPlatform(() => refundThroughProvider(superAdmin, recorded.payment.id, { reason: 'Mistake' }))).rejects.toMatchObject({ status: 409 });
    expect(await platformDb.refund.count({ where: { paymentId: recorded.payment.id } })).toBe(0);
    expect((await platformDb.payment.findUniqueOrThrow({ where: { id: recorded.payment.id } })).status).toBe('paid');
  });
});
