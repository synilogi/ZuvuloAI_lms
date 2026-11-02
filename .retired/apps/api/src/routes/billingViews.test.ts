import { BYTES_PER_GB, monthlyValue, type Invoice, type SubscriptionOverview, type TenantBilling } from '@syniastrolms/domain';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { issueInvoice } from '../lib/invoices.js';
import { setClock } from '../lib/clock.js';
import { recordPayment, refundPayment, settleRefund } from '../lib/payments.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { cancelNow, pauseSubscription, type LifecycleActor } from '../lib/subscriptions.js';
import { runAsPlatform } from '../lib/tenancy.js';
import { platformDb } from '../test/db.js';
import { PASSWORD, as, unique, type Client } from '../test/helpers.js';

/* SAAS-015: the read models the subscription screens show — every figure the server's, history replayed
 * from the lifecycle log, and the academy's own billing page reading nothing of any other academy.
 * Billed in Kuwait at 5% so no other suite's tax rule is disturbed. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('billing view tests act as the platform', fn);
const provider: LifecycleActor = { type: 'provider', provider: 'testpay' };
const scheduler: LifecycleActor = { type: 'system', job: 'view-tests' };
let platform: Client;
let superAdmin: LifecycleActor & { type: 'user' };

const limits = {
  'learners.max': 100,
  'instructors.max': 10,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 10,
  'admin_accounts.max': 5,
};

async function publishedPlan(monthly: number, over: object = {}): Promise<string> {
  const created = await platform.post('/superadmin/plans', {
    name: `View Plan ${unique()}`,
    description: 'A plan for the view suite.',
    code: `VW${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly', 'annual'],
    monthlyPrice: monthly,
    annualPrice: monthly * 10,
    trialEnabled: true,
    trialDays: 14,
    limits,
    features: ['courses.manage', 'reports.basic'],
    ...over,
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  expect((await platform.post(`/superadmin/plans/${created.body.id}/publish`)).status).toBe(200);
  return created.body.id as string;
}

interface Academy {
  tenantId: string;
  name: string;
  admin: Client;
  subscriptionId: string;
}

async function academy(planId: string, opts: { at?: string; start?: 'trial' | 'active'; cycle?: 'monthly' | 'annual' } = {}): Promise<Academy> {
  const name = `View Academy ${unique()}`;
  const tenantId = (await platformDb.tenant.create({ data: { name, slug: `vw-${unique()}` } })).id;
  const email = `vw-admin-${unique()}@example.com`;
  expect((await platform.post('/superadmin/admins', { name: 'View Admin', email, password: PASSWORD, tenantId })).status).toBe(201);
  const admin = await as({ email, password: PASSWORD });
  await admin.put('/tenant/billing-profile', {
    legalName: `${name} LLC`,
    email: 'accounts@example.com',
    addressLine1: '1 Gulf Road',
    city: 'Kuwait City',
    postalCode: '13001',
    country: 'KW',
  });
  setClock(opts.at ?? '2026-09-01T00:00:00Z');
  const sub = await platform.post('/superadmin/subscriptions', { tenantId, planId, cycle: opts.cycle ?? 'monthly', start: opts.start ?? 'active' });
  expect(sub.status, JSON.stringify(sub.body)).toBe(201);
  setClock(null);
  return { tenantId, name, admin, subscriptionId: sub.body.id as string };
}

beforeAll(async () => {
  const email = `vw-su-${unique()}@example.com`;
  const created = await provisionSuperAdmin({ email, password: PASSWORD, name: 'Viewer' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
  platform = await as({ email, password: PASSWORD });
  expect((await platform.post('/superadmin/tax-rules', { name: 'VAT', country: 'KW', components: [{ code: 'VAT', label: 'VAT', rateBps: 500 }] })).status).toBe(
    201,
  );
});

afterEach(() => setClock(null));

describe('the Super Admin’s subscription views', () => {
  it('counts a plan’s subscribers and what they are worth a month, from the stored subscriptions', async () => {
    const planId = await publishedPlan(250000);
    await academy(planId);
    await academy(planId, { cycle: 'annual' });
    await academy(planId, { start: 'trial' });
    const res = await platform.get('/superadmin/billing-views/plans', { search: '' });
    expect(res.status).toBe(200);
    const row = res.body.rows.find((r: { plan: { id: string } }) => r.plan.id === planId);
    // Monthly ₹2,500 + annual ₹25,000 ÷ 12 (₹2,083.33) — the trial is on the plan but billed nothing.
    expect(row).toMatchObject({ subscribers: 3, activeSubscribers: 3, mrr: 250000 + Math.round(2500000 / 12) });
    expect(row.plan).toMatchObject({ monthlyPrice: 250000, annualPrice: 2500000, trialEnabled: true, trialDays: 14, status: 'active' });
    expect(res.body.counts.all).toBeGreaterThanOrEqual(res.body.counts.active);

    const detail = await platform.get(`/superadmin/billing-views/plans/${planId}`);
    expect(detail.body.trend).toHaveLength(6);
    expect(detail.body.byStatus).toEqual(
      expect.arrayContaining([
        { status: 'active', count: 2 },
        { status: 'trial', count: 1 },
      ]),
    );
    expect(detail.body.subscriptions).toHaveLength(3);
  });

  it('lists subscribers with filters, counts taken before the status filter, and paging', async () => {
    const planId = await publishedPlan(260000);
    const a = await academy(planId);
    await academy(planId, { start: 'trial' });
    await academy(planId);
    const all = await platform.get('/superadmin/billing-views/subscribers', { planId, pageSize: 100 });
    expect(all.body.total).toBe(3);
    expect(all.body.counts).toMatchObject({ all: 3, active: 2, trial: 1 });
    const trials = await platform.get('/superadmin/billing-views/subscribers', { planId, status: 'trial' });
    expect(trials.body.rows).toHaveLength(1);
    expect(trials.body.counts.all).toBe(3);
    const found = await platform.get('/superadmin/billing-views/subscribers', { search: a.name });
    expect(found.body.rows.map((r: { subscription: { id: string } }) => r.subscription.id)).toEqual([a.subscriptionId]);
    expect(found.body.rows[0].subscription).toMatchObject({
      customer: { id: a.tenantId, name: a.name, email: 'accounts@example.com', city: 'Kuwait City', country: 'KW', learners: 0 },
      status: 'active',
      cycle: 'monthly',
      amount: 260000,
      renewsAt: '2026-10-01T00:00:00.000Z',
      paymentMethod: { kind: 'invoice', brand: 'Invoice' },
    });
    const paged = await platform.get('/superadmin/billing-views/subscribers', { planId, pageSize: 2, page: 2 });
    expect(paged.body).toMatchObject({ total: 3 });
    expect(paged.body.rows).toHaveLength(1);
    expect((await platform.get('/superadmin/billing-views/subscribers', { status: 'nonsense' })).status).toBe(400);
  });

  it('replays history from the lifecycle log: who joined, who left, and the book at each month’s end', async () => {
    const planId = await publishedPlan(300000);
    const overviewAt = async (iso: string) => {
      setClock(iso);
      const res = await platform.get('/superadmin/billing-views/overview');
      expect(res.status).toBe(200);
      return res.body as SubscriptionOverview;
    };
    const growth = (v: SubscriptionOverview, detail: string) => v.growth.find((g) => g.detail === detail)!;
    const revenue = (v: SubscriptionOverview, detail: string) => v.revenue.find((r) => r.detail === detail)!.value;
    const before = await overviewAt('2025-05-15T00:00:00Z');

    // Two academies join in March 2025; one is cancelled outright in April.
    await academy(planId, { at: '2025-03-10T00:00:00Z' });
    const left = await academy(planId, { at: '2025-03-12T00:00:00Z' });
    setClock('2025-04-20T00:00:00Z');
    await asPlatform(() => cancelNow(superAdmin, left.subscriptionId, { reason: 'Closing the academy' }));
    const after = await overviewAt('2025-05-15T00:00:00Z');

    expect(growth(after, 'Mar 2025').added - growth(before, 'Mar 2025').added).toBe(2);
    expect(growth(after, 'Apr 2025').cancellations - growth(before, 'Apr 2025').cancellations).toBe(1);
    expect(revenue(after, 'Feb 2025') - revenue(before, 'Feb 2025')).toBe(0);
    expect(revenue(after, 'Mar 2025') - revenue(before, 'Mar 2025')).toBe(600000);
    expect(revenue(after, 'Apr 2025') - revenue(before, 'Apr 2025')).toBe(300000);
    expect(after.kpis.mrr.series).toHaveLength(12);
    expect(after.kpis.arr.value).toBe(after.kpis.mrr.value * 12);
  });

  it('agrees with itself: the KPI band and the status counts are the subscriber list’s own figures', async () => {
    const [overview, list] = await Promise.all([
      platform.get('/superadmin/billing-views/overview'),
      platform.get('/superadmin/billing-views/subscribers', { pageSize: 100 }),
    ]);
    const view = overview.body as SubscriptionOverview;
    expect(view.statusCounts.active).toBe(list.body.counts.active);
    expect(view.kpis.active.value).toBe(view.statusCounts.active);
    expect(view.kpis.trial.value).toBe(view.statusCounts.trial);
    const everyone = await platform.get('/superadmin/billing-views/subscribers', { pageSize: 100, page: 1 });
    let pages = [everyone.body.rows];
    for (let p = 2; (p - 1) * 100 < everyone.body.total; p++)
      pages = [...pages, (await platform.get('/superadmin/billing-views/subscribers', { pageSize: 100, page: p })).body.rows];
    const mrr = pages.flat().reduce((sum: number, r: { subscription: Parameters<typeof monthlyValue>[0] }) => sum + monthlyValue(r.subscription), 0);
    expect(view.kpis.mrr.value).toBe(mrr);
  });

  it('shows one subscription with its history in words, its own plan version, and its invoices as issued', async () => {
    const planId = await publishedPlan(270000);
    const a = await academy(planId);
    setClock('2026-09-05T00:00:00Z');
    await asPlatform(() => pauseSubscription(superAdmin, a.subscriptionId, { days: 5, reason: 'Holiday' }));
    // The plan is repriced after the academy subscribed: the subscription keeps its own version.
    setClock(null);
    expect((await platform.patch(`/superadmin/plans/${planId}`, { monthlyPrice: 290000 })).status).toBe(200);
    setClock('2026-09-06T00:00:00Z');
    const upgradeTo = await publishedPlan(500000);
    const quoted = await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/plan-change`, { planId: upgradeTo, cycle: 'monthly' });
    expect(quoted.status).toBe(409); // paused: a plan change needs an active subscription
    setClock(null);

    const res = await platform.get(`/superadmin/billing-views/subscriptions/${a.subscriptionId}`);
    expect(res.status).toBe(200);
    expect(res.body.plan).toMatchObject({ id: planId, monthlyPrice: 270000 });
    expect(res.body.subscription).toMatchObject({ status: 'paused', pausedAt: '2026-09-05T00:00:00.000Z', resumesAt: '2026-09-10T00:00:00.000Z' });
    expect(res.body.events.map((e: { kind: string }) => e.kind)).toEqual(['paused', 'created']);
    expect(res.body.events[0]).toMatchObject({ summary: 'Paused for 5 days — resumes 2026-09-10 (Holiday).', actor: 'Viewer (platform)' });
  });

  it('asks for a plan change on the academy’s behalf, priced and timed by the rules, never by the caller', async () => {
    const small = await publishedPlan(200000);
    const big = await publishedPlan(400000);
    const a = await academy(small);
    setClock('2026-09-16T00:00:00Z');
    const res = await platform.post(`/superadmin/subscriptions/${a.subscriptionId}/plan-change`, {
      planId: big,
      cycle: 'monthly',
      effective: 'immediately',
      charge: 1,
    });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    // Half of September is left: ₹4,000 − ₹2,000, halved — whatever the body said.
    expect(res.body).toMatchObject({ kind: 'upgrade', status: 'pending_payment', charge: 100000, credit: 100000 });
    setClock(null);
    const view = await platform.get(`/superadmin/billing-views/subscriptions/${a.subscriptionId}`);
    expect(view.body.subscription.planId).toBe(small);
    expect(view.body.events[0]).toMatchObject({ kind: 'plan-changed' });
    expect(view.body.events[0].summary).toMatch(/^Upgrade to View Plan .* quoted — ₹1,000 due after a ₹1,000 credit\. It applies once paid\.$/);
  });

  it('lists invoices with what came of them — pending, failed, paid, refunded, void — and the totals', async () => {
    const planId = await publishedPlan(100000);
    const a = await academy(planId);
    const b = await academy(planId);
    const c = await academy(planId);
    setClock('2026-09-28T00:00:00Z');
    const issue = (id: string) => asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: id }));
    const paid = await issue(a.subscriptionId);
    const failed = await issue(b.subscriptionId);
    const voided = await issue(c.subscriptionId);
    const pay = (invoiceId: string, status: 'paid' | 'failed', amount: number) =>
      asPlatform(() =>
        recordPayment(provider, {
          invoiceId,
          providerPaymentId: `pay_${unique()}`,
          amount,
          currency: 'INR',
          status,
          method: { kind: 'card', brand: 'Visa', last4: '4242' },
          ...(status === 'failed' ? { failureMessage: 'Card declined' } : {}),
        }),
      );
    const settled = await pay(paid.id, 'paid', paid.total);
    await pay(failed.id, 'failed', failed.total);
    expect((await platform.post(`/superadmin/invoices/${voided.id}/void`, { reason: 'Billed in error' })).status).toBe(200);
    const refund = await asPlatform(() => refundPayment({ auth: superAdmin.auth }, settled.payment.id, { reason: 'Goodwill' }));
    await asPlatform(() => settleRefund(provider, refund.id, { status: 'succeeded', providerRefundId: `rf_${unique()}` }));
    setClock(null);

    const res = await platform.get('/superadmin/billing-views/payments', { search: 'View Academy', pageSize: 100 });
    const byId = new Map<string, Invoice>(res.body.rows.map((i: Invoice) => [i.id, i]));
    expect(byId.get(paid.id)).toMatchObject({
      status: 'refunded',
      amounts: { subtotal: 100000, tax: 5000, total: 105000 },
      taxPercent: 5,
      method: { kind: 'card', brand: 'Visa', last4: '4242' },
      customerName: a.name,
      billingAddress: [`${a.name} LLC`, '1 Gulf Road', 'Kuwait City 13001', 'KW'],
    });
    expect(byId.get(failed.id)).toMatchObject({ status: 'failed', note: 'Card declined' });
    expect(byId.get(voided.id)).toMatchObject({ status: 'void', note: 'Void — Billed in error' });
    const failedOnly = await platform.get('/superadmin/billing-views/payments', { search: b.name, status: 'failed' });
    expect(failedOnly.body.totals).toMatchObject({ outstanding: 105000, collected: 0 });
    expect(failedOnly.body.counts).toMatchObject({ all: 1, failed: 1 });
    const refunded = await platform.get('/superadmin/billing-views/payments', { search: a.name });
    expect(refunded.body.totals).toMatchObject({ collected: 105000, refunded: 105000 });
    const byNumber = await platform.get(`/superadmin/billing-views/invoices/${paid.number.toLowerCase()}`);
    expect(byNumber.body.id).toBe(paid.id);
  });

  it('is the Super Admin’s alone', async () => {
    const admin = await as('admin');
    for (const path of ['overview', 'plans', 'subscribers', 'payments']) expect((await admin.get(`/superadmin/billing-views/${path}`)).status).toBe(403);
  });
});

describe('the academy’s own billing page (§24)', () => {
  it('shows its plan, status, cycle, renewal, usage, features, invoices, payments and what it could move to', async () => {
    const planId = await publishedPlan(310000);
    const a = await academy(planId);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    await asPlatform(() =>
      recordPayment(provider, {
        invoiceId: invoice.id,
        providerPaymentId: `pay_${unique()}`,
        amount: invoice.total,
        currency: 'INR',
        status: 'paid',
        method: { kind: 'card', brand: 'Visa', last4: '1881' },
      }),
    );
    setClock(null);
    const res = await a.admin.get('/tenant/billing');
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    const view = res.body as TenantBilling;
    expect(view.academy).toEqual({ id: a.tenantId, name: a.name });
    expect(view.subscription).toMatchObject({ id: a.subscriptionId, status: 'active', cycle: 'monthly', amount: 310000 });
    expect(view.plan).toMatchObject({ id: planId, monthlyPrice: 310000 });
    expect(view.restricted).toBe(false);
    // The page is told whether enforcement is on (§50): off unless ENTITLEMENT_ENFORCEMENT=on.
    expect(view.enforced).toBe(process.env.ENTITLEMENT_ENFORCEMENT === 'on');
    expect(view.usage.find((u) => u.limit === 'courses.max')).toMatchObject({ used: 0, allowed: 10, remaining: 10 });
    expect(view.features.filter((f) => f.included).map((f) => f.key)).toEqual(['courses.manage', 'reports.basic']);
    expect(view.invoices).toHaveLength(1);
    expect(view.invoices[0]).toMatchObject({ status: 'paid', amounts: { total: invoice.total } });
    expect(view.payments).toEqual([
      expect.objectContaining({ amount: invoice.total, status: 'paid', method: 'Visa •••• 1881', invoiceNumber: invoice.number }),
    ]);
    expect(view.plans.some((p) => p.id === planId)).toBe(true);
    expect(view.checkoutAvailable).toBe(false);
    expect((await a.admin.get(`/tenant/billing/invoices/${invoice.id}`)).body.id).toBe(invoice.id);
  });

  it('asks for a change and lets the server say what it is: an upgrade’s quote, a downgrade’s date', async () => {
    const small = await publishedPlan(200000);
    const big = await publishedPlan(400000);
    const a = await academy(big);
    setClock('2026-09-16T00:00:00Z');
    const down = await a.admin.post('/tenant/subscription/change', { planId: small, cycle: 'monthly' });
    expect(down.status, JSON.stringify(down.body)).toBe(201);
    expect(down.body.change).toMatchObject({ direction: 'downgrade', status: 'scheduled', effectiveAt: '2026-10-01T00:00:00.000Z', charge: 0 });
    expect(down.body.payable).toBeUndefined();
    setClock(null);
    expect((await a.admin.get('/tenant/billing')).body.openChange).toMatchObject({ id: down.body.change.id, direction: 'downgrade' });
    expect((await a.admin.post(`/tenant/subscription/plan-changes/${down.body.change.id}/cancel`, {})).status).toBe(200);

    const b = await academy(small);
    setClock('2026-09-16T00:00:00Z');
    const up = await b.admin.post('/tenant/subscription/change', { planId: big, cycle: 'monthly', charge: 1 });
    expect(up.status).toBe(201);
    expect(up.body).toMatchObject({
      change: { direction: 'upgrade', status: 'pending_payment', charge: 100000, credit: 100000 },
      payable: { net: 100000, tax: 5000, gross: 105000, currency: 'INR' },
    });
  });

  it('refuses an upgrade without a billing address, in words, before writing anything', async () => {
    const small = await publishedPlan(200000);
    const big = await publishedPlan(400000);
    const tenantId = (await platformDb.tenant.create({ data: { name: 'No Address Academy', slug: `na-${unique()}` } })).id;
    const email = `na-admin-${unique()}@example.com`;
    await platform.post('/superadmin/admins', { name: 'NA Admin', email, password: PASSWORD, tenantId });
    const admin = await as({ email, password: PASSWORD });
    setClock('2026-09-01T00:00:00Z');
    const sub = await platform.post('/superadmin/subscriptions', { tenantId, planId: small, cycle: 'monthly', start: 'active' });
    setClock('2026-09-16T00:00:00Z');
    const res = await admin.post('/tenant/subscription/change', { planId: big, cycle: 'monthly' });
    expect(res.status).toBe(409);
    expect(res.body).toMatchObject({ code: 'CONFLICT', message: 'Add the LMS’s billing address before upgrading.' });
    setClock(null);
    expect((await platform.get(`/superadmin/billing-views/subscriptions/${sub.body.id}`)).body.events).toHaveLength(1);
  });

  it('reads nothing of another academy', async () => {
    const planId = await publishedPlan(150000);
    const mine = await academy(planId);
    const theirs = await academy(planId);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: theirs.subscriptionId }));
    setClock(null);
    expect((await mine.admin.get(`/tenant/billing/invoices/${invoice.id}`)).status).toBe(404);
    expect((await mine.admin.get(`/tenant/billing/invoices/${invoice.number}`)).status).toBe(404);
    const view = (await mine.admin.get('/tenant/billing')).body as TenantBilling;
    expect(view.subscription?.id).toBe(mine.subscriptionId);
    expect(view.invoices).toEqual([]);
    // Staff below admin cannot open it at all.
    expect((await (await as('instructor')).get('/tenant/billing')).status).toBe(403);
  });
});
