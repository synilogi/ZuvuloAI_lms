import request from 'supertest';
import { BYTES_PER_GB } from '@syniastrolms/domain';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { anon, app, as, unique, type Client } from '../test/helpers.js';
import { setClock } from '../lib/clock.js';
import { BILLING_ERROR_CODES } from '../lib/errors.js';
import { issueInvoice } from '../lib/invoices.js';
import { recordPayment } from '../lib/payments.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { runAsPlatform } from '../lib/tenancy.js';

/* SAAS-013: the Super Admin's billing endpoints and the Tenant Admin's /tenant endpoints, over HTTP. Each
 * academy here is new; its admin is created through the platform the way a real one is. */

const PASSWORD = 'billing-api-password';
let platform: Client;

const limits = {
  'learners.max': 100,
  'instructors.max': 10,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 10,
  'admin_accounts.max': 5,
};
const planBody = (over: object = {}) => ({
  name: 'API Plan',
  description: 'A plan made through the API.',
  code: `API${unique().toUpperCase()}`.slice(0, 24),
  currency: 'INR',
  cycles: ['monthly', 'annual'],
  monthlyPrice: 399900,
  annualPrice: 3999000,
  trialEnabled: false,
  trialDays: 0,
  limits,
  features: ['courses.manage', 'reports.basic'],
  ...over,
});

async function publishedPlan(over: object = {}): Promise<string> {
  const created = await platform.post('/superadmin/plans', planBody(over));
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  expect((await platform.post(`/superadmin/plans/${created.body.id}/publish`)).status).toBe(200);
  return created.body.id as string;
}

interface Academy {
  tenantId: string;
  admin: Client;
  adminId: string;
  subscriptionId: string;
}

/** A new academy with an admin, billed in Qatar, on an active subscription to `planId` from 1 September. */
async function academy(planId: string): Promise<Academy> {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'API Academy', slug: `api-${unique()}` } })).id;
  const email = `api-admin-${unique()}@example.com`;
  const created = await platform.post('/superadmin/admins', { name: 'API Admin', email, password: PASSWORD, tenantId });
  expect(created.status).toBe(201);
  const admin = await as({ email, password: PASSWORD });
  expect(
    (
      await admin.put('/tenant/billing-profile', {
        legalName: 'API Academy LLC',
        email: 'accounts@example.com',
        addressLine1: '1 Corniche Street',
        city: 'Doha',
        postalCode: '00000',
        country: 'QA',
      })
    ).status,
  ).toBe(200);
  setClock('2026-09-01T00:00:00Z');
  const sub = await platform.post('/superadmin/subscriptions', { tenantId, planId, cycle: 'monthly', start: 'active' });
  expect(sub.status, JSON.stringify(sub.body)).toBe(201);
  setClock(null);
  return { tenantId, admin, adminId: created.body.id as string, subscriptionId: sub.body.id as string };
}

beforeAll(async () => {
  const email = `api-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Platform' });
  platform = await as({ email, password: PASSWORD });
  expect((await platform.post('/superadmin/tax-rules', { name: 'VAT', country: 'QA', components: [{ code: 'VAT', label: 'VAT', rateBps: 500 }] })).status).toBe(
    201,
  );
});

afterEach(() => setClock(null));

describe('the Super Admin’s billing endpoints', () => {
  it('manages plans: create, read with versions, edit into a new version, publish, archive, restore', async () => {
    const created = await platform.post('/superadmin/plans', planBody());
    expect(created.body).toMatchObject({ status: 'draft', current: { version: 1, monthlyPrice: 399900 } });
    const edited = await platform.patch(`/superadmin/plans/${created.body.id}`, { monthlyPrice: 449900 });
    expect(edited.body.current).toMatchObject({ version: 2, monthlyPrice: 449900 });
    expect((await platform.get(`/superadmin/plans/${created.body.id}`)).body.versions).toHaveLength(2);
    for (const move of ['publish', 'archive', 'restore']) expect((await platform.post(`/superadmin/plans/${created.body.id}/${move}`)).status, move).toBe(200);
    expect((await platform.get('/superadmin/plans', { status: 'active' })).body.rows.some((p: { id: string }) => p.id === created.body.id)).toBe(true);
  });

  it('starts, lists, inspects, pauses, resumes and cancels a subscription', async () => {
    const planId = await publishedPlan();
    const a = await academy(planId);
    const list = await platform.get('/superadmin/subscriptions', { tenantId: a.tenantId });
    expect(list.body).toMatchObject({ total: 1, rows: [{ id: a.subscriptionId, status: 'active', tenant: { id: a.tenantId }, plan: { id: planId } }] });
    expect((await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/pause`, { days: 7, reason: 'Summer break' })).body.status).toBe('paused');
    expect((await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/resume`, {})).body.status).toBe('active');
    expect((await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/cancel`, { reason: 'Closing down' })).body.status).toBe('canceling');
    const detail = await platform.get(`/superadmin/subscriptions/${a.subscriptionId}`);
    expect(detail.body.lifecycle.map((e: { transition: string }) => e.transition)).toEqual(['create', 'pause', 'resume', 'request_cancel']);
  });

  it('lists invoices and payments, voids an invoice and refunds a payment — with the reasons required', async () => {
    const planId = await publishedPlan();
    const a = await academy(planId);
    const invoice = await runAsPlatform('test issues an invoice', () =>
      issueInvoice({ type: 'system', job: 'test' }, { kind: 'renewal', subscriptionId: a.subscriptionId }),
    );
    expect(invoice.total).toBe(419895); // ₹3,999 + 5% VAT
    const { payment } = await runAsPlatform('test records a payment', () =>
      recordPayment(
        { type: 'provider', provider: 'testpay' },
        { invoiceId: invoice.id, providerPaymentId: `pay_${unique()}`, amount: 419895, currency: 'INR', status: 'paid' },
      ),
    );
    expect((await platform.get('/superadmin/invoices', { tenantId: a.tenantId })).body.rows[0]).toMatchObject({ id: invoice.id, status: 'paid' });
    expect((await platform.get('/superadmin/payments', { tenantId: a.tenantId })).body.total).toBe(1);
    expect((await platform.post(`/superadmin/payments/${payment.id}/refund`, { amount: 1000 })).body.code).toBe('VALIDATION_FAILED');
    const refund = await platform.post(`/superadmin/payments/${payment.id}/refund`, { amount: 1000, reason: 'Goodwill' });
    expect(refund.status).toBe(201);
    expect((await platform.get(`/superadmin/payments/${payment.id}`)).body.refunds).toHaveLength(1);
    expect((await platform.post(`/superadmin/invoices/${invoice.id}/void`, { reason: 'Too late' })).body.code).toBe('CONFLICT');
  });
});

describe('the Tenant Admin’s own subscription', () => {
  it('sees its subscription, usage, entitlements, the plans on sale, invoices and payments', async () => {
    const planId = await publishedPlan();
    const a = await academy(planId);
    const sub = await a.admin.get('/tenant/subscription');
    expect(sub.body).toMatchObject({ status: 'active', restricted: false, subscription: { id: a.subscriptionId }, openPlanChange: null });
    const usage = await a.admin.get('/tenant/subscription/usage');
    expect(usage.body.lines.find((l: { limit: string }) => l.limit === 'admin_accounts.max')).toMatchObject({ used: 1, allowed: 5, remaining: 4 });
    expect((await a.admin.get('/tenant/subscription/entitlements')).body.features).toEqual(['courses.manage', 'reports.basic']);
    expect((await a.admin.get('/tenant/plans')).body.rows.length).toBeGreaterThan(0);
    for (const path of ['/tenant/invoices', '/tenant/payments', '/tenant/billing-profile']) expect((await a.admin.get(path)).status, path).toBe(200);
  });

  it('asks for an upgrade and gets the server’s quote and payable amount — its plan waits for payment', async () => {
    const small = await publishedPlan();
    const big = await publishedPlan({ monthlyPrice: 899900, annualPrice: 8999000, features: ['courses.manage', 'reports.basic', 'custom_branding'] });
    const a = await academy(small);
    setClock('2026-09-16T00:00:00Z');
    const res = await a.admin.post('/tenant/subscription/upgrade', { planId: big, cycle: 'monthly', charge: 1, amount: 1 });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body.planChange).toMatchObject({ kind: 'upgrade', status: 'pending_payment', credit: 199950, charge: 250000 });
    expect(res.body.payable).toMatchObject({ net: 250000, tax: 12500, gross: 262500, currency: 'INR' });
    expect((await a.admin.get('/tenant/subscription/entitlements')).body.features).not.toContain('custom_branding');
    // An upgrade endpoint does not take a downgrade.
    const back = await a.admin.post('/tenant/subscription/plan-changes/' + res.body.planChange.id + '/cancel', {});
    expect(back.body.status).toBe('canceled');
    const wrong = await a.admin.post('/tenant/subscription/upgrade', {
      planId: await publishedPlan({ monthlyPrice: 100000, annualPrice: 1000000 }),
      cycle: 'monthly',
    });
    expect(wrong.body.code).toBe('INVALID_SUBSCRIPTION_STATE');
  });

  it('schedules a downgrade, cancels at period end and resumes, each on the record', async () => {
    const big = await publishedPlan({ monthlyPrice: 899900, annualPrice: 8999000 });
    const small = await publishedPlan();
    const a = await academy(big);
    const down = await a.admin.post('/tenant/subscription/downgrade', { planId: small, cycle: 'monthly' });
    expect(down.body.planChange).toMatchObject({ kind: 'downgrade', status: 'scheduled', charge: 0 });
    expect((await a.admin.post('/tenant/subscription/cancel', { reason: 'Budget cuts' })).body).toMatchObject({
      status: 'canceling',
      cancellationReason: 'Budget cuts',
    });
    expect((await a.admin.post('/tenant/subscription/resume', { reason: 'Budget found' })).body.status).toBe('active');
    const detail = await platform.get(`/superadmin/subscriptions/${a.subscriptionId}`);
    expect(detail.body.lifecycle.at(-1)).toMatchObject({ transition: 'resume', actor: { type: 'user', id: a.adminId }, meta: { reason: 'Budget found' } });
  });

  it('previews a plan change before it is asked for, writing nothing', async () => {
    const small = await publishedPlan({ monthlyPrice: 100000, annualPrice: 1000000 });
    const big = await publishedPlan({ name: 'Bigger', monthlyPrice: 400000, annualPrice: 4000000 });
    const a = await academy(small);
    setClock('2026-09-16T00:00:00Z');
    const up = await a.admin.post('/tenant/subscription/preview', { planId: big, cycle: 'monthly' });
    expect(up.status, JSON.stringify(up.body)).toBe(200);
    // Half of September is left: credit 50,000 of the old plan, 200,000 of the new, so 150,000 + 5% VAT.
    expect(up.body).toMatchObject({ kind: 'upgrade', when: 'on_payment', credit: 50000, charge: 150000, payable: { net: 150000, tax: 7500, gross: 157500 } });
    expect(up.body.to).toMatchObject({ planName: 'Bigger', cycle: 'monthly', amount: 400000 });
    expect(await platformDb.planChange.count({ where: { subscriptionId: a.subscriptionId } })).toBe(0);

    const b = await academy(big);
    setClock('2026-09-16T00:00:00Z');
    const down = await b.admin.post('/tenant/subscription/preview', { planId: small, cycle: 'monthly' });
    expect(down.body).toMatchObject({ kind: 'downgrade', when: 'period_end', appliesAt: '2026-10-01T00:00:00.000Z', charge: 0, payable: null });
  });

  it('leaves a pause the platform imposed for the platform to lift', async () => {
    const a = await academy(await publishedPlan());
    expect((await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/pause`, { days: 10 })).body.status).toBe('paused');
    const refused = await a.admin.post('/tenant/subscription/resume', {});
    expect(refused.status).toBe(403);
    expect(refused.body.message).toMatch(/paused by the platform team/);
    expect((await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/resume`, {})).body.status).toBe('active');
  });
});

describe('the Super Admin’s manual billing', () => {
  const renewalFor = (subscriptionId: string) =>
    runAsPlatform('test issues a renewal', () => issueInvoice({ type: 'system', job: 'billing-api-test' }, { kind: 'renewal', subscriptionId }));

  it('records a bank transfer against an open renewal, which renews the subscription, once per reference', async () => {
    const a = await academy(await publishedPlan());
    setClock('2026-09-25T00:00:00Z');
    const invoice = await renewalFor(a.subscriptionId);

    expect((await a.admin.post(`/superadmin/invoices/${invoice.id}/record-payment`, { method: 'cash', reference: 'R-1' })).status).toBe(403);
    expect((await platform.post(`/superadmin/invoices/${invoice.id}/record-payment`, { method: 'cash', reference: 'x' })).status).toBe(400);
    const reference = `NEFT-${unique()}`;
    const paid = await platform.post(`/superadmin/invoices/${invoice.id}/record-payment`, {
      method: 'bank_transfer',
      reference,
      note: 'Received in HDFC current account',
    });
    expect(paid.status, JSON.stringify(paid.body)).toBe(201);
    expect(paid.body).toMatchObject({ status: 'paid', settled: true, applied: true });

    const detail = await platform.get(`/superadmin/subscriptions/${a.subscriptionId}`);
    expect(detail.body.subscription).toMatchObject({ status: 'active', currentPeriodEndAt: '2026-11-01T00:00:00.000Z' });
    expect(detail.body.invoices.find((i: { id: string }) => i.id === invoice.id).status).toBe('paid');
    expect(detail.body.payments).toEqual([
      expect.objectContaining({
        provider: 'offline',
        providerPaymentId: reference,
        amount: invoice.total,
        method: expect.objectContaining({ display: 'Bank transfer' }),
      }),
    ]);
    expect(await platformDb.auditLog.count({ where: { action: 'payment.recorded_offline', targetId: invoice.id } })).toBe(1);

    expect((await platform.post(`/superadmin/invoices/${invoice.id}/record-payment`, { method: 'bank_transfer', reference })).status).toBe(409);
  });

  it('refunds a payment received by hand at once, since it is paid back by hand', async () => {
    const a = await academy(await publishedPlan());
    setClock('2026-09-25T00:00:00Z');
    const invoice = await renewalFor(a.subscriptionId);
    await platform.post(`/superadmin/invoices/${invoice.id}/record-payment`, { method: 'cheque', reference: `CHQ-${unique()}` });
    const [payment] = (await platform.get(`/superadmin/subscriptions/${a.subscriptionId}`)).body.payments;
    const refund = await platform.post(`/superadmin/payments/${payment.id}/refund`, { reason: 'Paid twice by mistake' });
    expect(refund.status, JSON.stringify(refund.body)).toBe(201);
    expect(refund.body).toMatchObject({ status: 'succeeded', amount: invoice.total });
  });

  it('gives complimentary days: the period ends later, an unpaid renewal for the old end is replaced, and only an active subscription can be extended', async () => {
    const a = await academy(await publishedPlan());
    setClock('2026-09-25T00:00:00Z');
    const invoice = await renewalFor(a.subscriptionId);

    expect((await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/extend`, { days: 0, reason: 'Outage' })).status).toBe(400);
    expect((await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/extend`, { days: 5, reason: '' })).status).toBe(400);
    const extended = await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/extend`, { days: 15, reason: 'Two-week platform outage' });
    expect(extended.status, JSON.stringify(extended.body)).toBe(200);
    expect(extended.body).toMatchObject({ status: 'active', currentPeriodEndAt: '2026-10-16T00:00:00.000Z' });

    const detail = await platform.get(`/superadmin/subscriptions/${a.subscriptionId}`);
    expect(detail.body.lifecycle.at(-1)).toMatchObject({
      transition: 'extend',
      event: 'subscription.extended',
      meta: { days: 15, reason: 'Two-week platform outage' },
    });
    expect(detail.body.invoices.find((i: { id: string }) => i.id === invoice.id)).toMatchObject({
      status: 'void',
      voidReason: expect.stringMatching(/extended by 15/),
    });

    await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/pause`, { days: 5 });
    const refused = await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/extend`, { days: 5, reason: 'While paused' });
    expect(refused.body.code).toBe('INVALID_SUBSCRIPTION_STATE');
  });
});

describe('billing notices reach the academy’s admins (§31)', () => {
  const noticesFor = async (userId: string) =>
    (await platformDb.appNotification.findMany({ where: { recipientId: userId, category: 'system' }, orderBy: { id: 'asc' } })).map((n) => n.title);

  it('tells the admins when their subscription starts, a renewal is invoiced, a payment lands, and the platform pauses or extends it', async () => {
    const a = await academy(await publishedPlan({ name: 'Notice Plan' }));
    expect(await noticesFor(a.adminId)).toEqual(['Your Notice Plan subscription is active']);

    setClock('2026-09-25T00:00:00Z');
    const invoice = await runAsPlatform('test issues a renewal', () =>
      issueInvoice({ type: 'system', job: 'billing-api-test' }, { kind: 'renewal', subscriptionId: a.subscriptionId }),
    );
    expect((await noticesFor(a.adminId)).at(-1)).toBe('Your Notice Plan renewal is coming up');
    await platform.post(`/superadmin/invoices/${invoice.id}/record-payment`, { method: 'upi', reference: `UPI-${unique()}` });
    expect((await noticesFor(a.adminId)).at(-1)).toBe('Your subscription has renewed');

    await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/extend`, { days: 7, reason: 'Goodwill' });
    expect((await noticesFor(a.adminId)).at(-1)).toBe('Complimentary days added');
    await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/pause`, { days: 3 });
    expect((await noticesFor(a.adminId)).at(-1)).toBe('Your subscription is paused');
    const email = await platformDb.emailOutbox.findFirst({ where: { subject: 'Your subscription is paused', tenantId: a.tenantId } });
    expect(email?.text).toContain('/admin/billing');
  });

  it('does not tell an admin about their own cancellation, but does tell them when the platform cancels', async () => {
    const a = await academy(await publishedPlan({ name: 'Quiet Plan' }));
    await a.admin.post('/tenant/subscription/cancel', { reason: 'Moving on' });
    expect(await noticesFor(a.adminId)).toEqual(['Your Quiet Plan subscription is active']);
    await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/cancel`, { immediately: true, reason: 'Account closed' });
    expect((await noticesFor(a.adminId)).at(-1)).toBe('Your subscription has ended');
  });
});

describe('a Tenant Admin request for another tenant’s subscription is refused', () => {
  it('cannot name another academy — its invoice and plan change are simply not found', async () => {
    const planId = await publishedPlan();
    const [a, b] = [await academy(planId), await academy(planId)];
    const invoice = await runAsPlatform('test issues an invoice', () =>
      issueInvoice({ type: 'system', job: 'test' }, { kind: 'renewal', subscriptionId: b.subscriptionId }),
    );
    const theirs = await a.admin.get(`/tenant/invoices/${invoice.id}`);
    expect(theirs.status).toBe(404);
    expect(theirs.body.code).toBe('NOT_FOUND');
    const big = await publishedPlan({ monthlyPrice: 899900, annualPrice: 8999000 });
    setClock('2026-09-16T00:00:00Z');
    const quote = await b.admin.post('/tenant/subscription/upgrade', { planId: big, cycle: 'monthly' });
    expect((await a.admin.post(`/tenant/subscription/plan-changes/${quote.body.planChange.id}/cancel`, {})).body.code).toBe('NOT_FOUND');
    // Its own view never shows the other academy.
    expect((await a.admin.get('/tenant/subscription')).body.subscription.id).toBe(a.subscriptionId);
    expect((await a.admin.get('/tenant/invoices')).body.total).toBe(0);
  });

  it('cannot reach the platform’s endpoints, or manage a plan', async () => {
    const planId = await publishedPlan();
    const a = await academy(planId);
    for (const [method, path] of [
      ['get', `/superadmin/subscriptions/${a.subscriptionId}`],
      ['get', '/superadmin/subscriptions'],
      ['patch', `/superadmin/plans/${planId}`],
      ['post', `/superadmin/plans/${planId}/archive`],
      ['post', '/superadmin/tax-rules'],
    ] as const) {
      const res = await (a.admin[method] as (p: string, b?: unknown) => request.Test)(path, {});
      expect(res.status, path).toBe(403);
      expect(res.body.code, path).toBe('PERMISSION_DENIED');
    }
  });

  it('needs the settings permissions: view to read, edit to change', async () => {
    const planId = await publishedPlan();
    const a = await academy(planId);
    await platformDb.adminPermission.deleteMany({ where: { userId: a.adminId, key: 'settings.edit' } });
    expect((await a.admin.get('/tenant/subscription')).status).toBe(200);
    const refused = await a.admin.post('/tenant/subscription/cancel', { reason: 'No right to' });
    expect(refused.body).toMatchObject({ code: 'PERMISSION_DENIED' });
    const learner = await as('student');
    expect((await learner.get('/tenant/subscription')).body.code).toBe('PERMISSION_DENIED');
  });
});

describe('every error is one of the documented codes, with no provider or database detail', () => {
  it('answers every refusal across both surfaces with a documented code', async () => {
    const planId = await publishedPlan();
    const a = await academy(planId);
    const plan = await platform.get(`/superadmin/plans/${planId}`);
    const failures = [
      await anon().get('/tenant/subscription'),
      await request(app).get('/superadmin/plans').set('Authorization', 'Bearer not-a-token'),
      await platform.post('/superadmin/plans', { name: 'x' }),
      await platform.post('/superadmin/plans', planBody({ code: plan.body.plan.code })),
      await platform.post('/superadmin/plans', planBody({ monthlyPrice: 3999.5 })),
      await platform.get('/superadmin/plans/no-such-plan'),
      await platform.post(`/superadmin/plans/${planId}/publish`),
      await platform.post('/superadmin/subscriptions', { tenantId: a.tenantId, planId, cycle: 'monthly', start: 'active' }),
      await platform.get('/superadmin/subscriptions/nope'),
      await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/pause`, { days: 45 }),
      await platform.post('/superadmin/tax-rules', { name: 'VAT', country: 'ZZ', components: [{ code: 'V', label: 'V', rateBps: 1 }] }),
      await platform.post('/superadmin/payments/nope/refund', { reason: 'Because' }),
      await a.admin.post('/tenant/subscription/upgrade', { planId: 'nope', cycle: 'monthly' }),
      await a.admin.post('/tenant/subscription/upgrade', { planId, cycle: 'monthly' }),
      await a.admin.post('/tenant/subscription/resume', {}),
      await a.admin.put('/tenant/billing-profile', { country: 'IN' }),
      await a.admin.get('/tenant/invoices/nope'),
    ];
    failures.forEach((res, i) => {
      expect(res.status, `failure #${i}`).toBeGreaterThanOrEqual(400);
      expect(BILLING_ERROR_CODES, `failure #${i}: ${JSON.stringify(res.body)}`).toContain(res.body.code);
    });
  });

  it('never lets a provider or database detail into an error body', async () => {
    // Two rules for the same place at once: one wins, the other meets the database's unique index.
    const results = await Promise.all(
      Array.from({ length: 4 }, () =>
        platform.post('/superadmin/tax-rules', { name: 'Race', country: 'BH', components: [{ code: 'VAT', label: 'VAT', rateBps: 1000 }] }),
      ),
    );
    const bodies = results.map((r) => JSON.stringify(r.body)).join('\n');
    expect(bodies).not.toMatch(/prisma|sqlite|constraint|unique|SELECT|INSERT|stack|node_modules|\.ts:\d|P20\d\d/i);
    for (const r of results.filter((x) => x.status >= 400)) expect(BILLING_ERROR_CODES).toContain(r.body.code);
    expect((await platform.get('/superadmin/tax-rules')).body.rows.filter((r: { country: string }) => r.country === 'BH')).toHaveLength(1);
  });
});
