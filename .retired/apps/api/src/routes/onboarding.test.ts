import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { anon, as, unique, type Client } from '../test/helpers.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';

/* A new academy's first day, over HTTP: the platform creates it empty with its first admin; the admin sees no
 * plan, starts the free trial themselves (once), and the academy's staff can read which modules the plan opens. */

const PASSWORD = 'onboarding-password';
let platform: Client;
let trialPlanId: string;
let paidOnlyPlanId: string;

const limits = { 'learners.max': 100, 'instructors.max': 5, 'courses.max': 10, 'storage.bytes': 1_000_000_000, 'live_classes.max': 5, 'admin_accounts.max': 2 };

async function plan(over: object): Promise<string> {
  const created = await platform.post('/superadmin/plans', {
    name: 'Onboarding Plan',
    description: 'A plan for the onboarding suite.',
    code: `OB${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly'],
    monthlyPrice: 149900,
    annualPrice: 0,
    trialEnabled: false,
    trialDays: 0,
    limits,
    features: ['courses.manage', 'assessments.manage'],
    ...over,
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  await platform.post(`/superadmin/plans/${created.body.id}/publish`);
  return created.body.id as string;
}

/** A new academy as the Super Admin creates one, signed in as its first admin. */
async function newAcademy() {
  const slug = `ob-${unique()}`;
  const email = `ob-admin-${unique()}@example.com`;
  const res = await platform.post('/superadmin/tenants', { name: `Onboarding ${slug}`, slug, admin: { name: 'First Admin', email, password: PASSWORD } });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return { tenantId: res.body.id as string, admin: await as({ email, password: PASSWORD }) };
}

beforeAll(async () => {
  const email = `ob-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Onboarding Platform' });
  platform = await as({ email, password: PASSWORD });
  trialPlanId = await plan({ trialEnabled: true, trialDays: 14 });
  paidOnlyPlanId = await plan({});
});

afterEach(() => {
  delete process.env.ENTITLEMENT_ENFORCEMENT;
});

describe('a new academy starts empty, with no plan', () => {
  it('has none of another academy’s data, and its admin is offered a free trial', async () => {
    const a = await newAcademy();
    expect((await a.admin.get('/courses')).body).toMatchObject({ total: 0 });
    expect((await a.admin.get('/students')).body).toMatchObject({ total: 0 });
    const billing = await a.admin.get('/tenant/billing');
    expect(billing.body).toMatchObject({ subscription: null, plan: null, restricted: true, trialAvailable: true });
    expect((await platform.get(`/superadmin/tenants/${a.tenantId}`)).body).toMatchObject({ subscription: null, courses: 0, learners: 0 });
  });
});

describe('the admin starts the academy’s free trial themselves', () => {
  it('starts it on a plan that offers one, once, and never a paid subscription', async () => {
    const a = await newAcademy();
    const refusedPaid = await a.admin.post('/tenant/billing/trial', { planId: paidOnlyPlanId, cycle: 'monthly' });
    expect(refusedPaid.status).toBe(409);
    expect(refusedPaid.body.code).toBe('PLAN_UNAVAILABLE');

    const started = await a.admin.post('/tenant/billing/trial', { planId: trialPlanId, cycle: 'monthly' });
    expect(started.status, JSON.stringify(started.body)).toBe(201);
    expect(started.body.subscription).toMatchObject({ status: 'trialing', planId: trialPlanId });
    expect((await a.admin.get('/tenant/billing')).body).toMatchObject({ trialAvailable: false, restricted: false });
    // The platform's academy list shows it at a glance.
    expect((await platform.get(`/superadmin/tenants/${a.tenantId}`)).body.subscription).toMatchObject({ status: 'trialing', plan: { id: trialPlanId } });

    // One trial per academy, and one live subscription.
    const again = await a.admin.post('/tenant/billing/trial', { planId: trialPlanId, cycle: 'monthly' });
    expect(again.body.code).toBe('INVALID_SUBSCRIPTION_STATE');

    const event = await platformDb.subscriptionEvent.findFirstOrThrow({ where: { subscriptionId: started.body.subscription.id, transition: 'create' } });
    expect(event).toMatchObject({ actorType: 'user', toStatus: 'trialing' });
  });

  it('is refused to anyone but the academy’s admin with settings.edit', async () => {
    const a = await newAcademy();
    expect((await anon().post('/tenant/billing/trial', { planId: trialPlanId, cycle: 'monthly' })).status).toBe(401);
    expect((await (await as('student')).post('/tenant/billing/trial', { planId: trialPlanId, cycle: 'monthly' })).status).toBe(403);
    expect((await a.admin.post('/tenant/billing/trial', { planId: 'no-such-plan', cycle: 'monthly' })).status).toBeGreaterThanOrEqual(400);
  });
});

describe('the academy’s staff can read what the plan opens', () => {
  it('reports no plan, then the trial’s features, with enforcement as configured', async () => {
    process.env.ENTITLEMENT_ENFORCEMENT = 'on';
    const a = await newAcademy();
    expect((await a.admin.get('/academy/plan')).body).toMatchObject({
      enforced: true,
      status: null,
      restricted: true,
      plan: null,
      features: [],
      lastFeatures: [],
    });

    await a.admin.post('/tenant/billing/trial', { planId: trialPlanId, cycle: 'monthly' });
    const served = (await a.admin.get('/academy/plan')).body;
    expect(served).toMatchObject({ status: 'trialing', restricted: false, features: ['courses.manage', 'assessments.manage'] });
    expect(served.trialEndsAt).toEqual(expect.any(String));
    // It never carries money.
    expect(JSON.stringify(served)).not.toMatch(/amount|price|invoice/i);
  });

  it('is readable by an instructor, not by a learner', async () => {
    expect((await (await as('instructor')).get('/academy/plan')).status).toBe(200);
    expect((await (await as('student')).get('/academy/plan')).status).toBe(403);
    expect((await anon().get('/academy/plan')).status).toBe(401);
  });
});
