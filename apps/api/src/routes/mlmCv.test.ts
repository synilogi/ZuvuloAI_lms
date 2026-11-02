import { defaultMlmPlanTerms } from '@syniastrolms/domain';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { setCoursePaymentProvider } from '../lib/coursePayments.js';
import { settleEligibleOrders } from '../lib/mlm/cv.js';
import { activateMlmPlanVersion, createMlmPlanVersion, setMlmEligibleCourses } from '../lib/mlm/plan.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { FIRST_TENANT_ID, runAsPlatform, runInTenant } from '../lib/tenancy.js';
import { ACADEMY, db, platformDb } from '../test/db.js';
import { FakeProvider } from '../test/fakeProvider.js';
import { as, newStudent, unique, type Client } from '../test/helpers.js';

/* MLM-003: a verified purchase of an eligible course becomes an order, activates the buyer, and credits every ancestor's
 * leg; a reversal negates the credits; the Super Admin reads products, orders, the ledger and the carry-forward pools.
 * Payments go through the fake gateway the course-purchase tests use. */

type Learner = Awaited<ReturnType<typeof newStudent>>;

let admin: Client;
let platform: Client;
let fake: FakeProvider;
let courseId: string;
let actor: { auth: { sub: string; role: 'superadmin' } };

const enrol = async (who: Learner, referralCode?: string, preferredLeg: 'A' | 'B' = 'A') => {
  const res = await who.post('/affiliate/enrol', { referralCode, preferredLeg });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return res.body as { id: string; code: string };
};

/** Buys the eligible course as a learner: start the purchase, pay at the fake gateway, confirm. */
const buy = async (learner: Learner) => {
  const started = await learner.post(`/learning/courses/${courseId}/purchase`, {});
  expect(started.status, JSON.stringify(started.body)).toBe(201);
  const payment = fake.pay(started.body.checkout.orderId, 'paid');
  const confirmed = await learner.post(`/learning/purchases/${started.body.purchase.id}/confirm`, {
    paymentId: payment.paymentId,
    signature: payment.signature,
  });
  expect(confirmed.status, JSON.stringify(confirmed.body)).toBe(200);
  expect(confirmed.body.purchase).toMatchObject({ status: 'paid', enrolled: true });
  return started.body.purchase.id as string;
};

beforeAll(async () => {
  admin = await as('admin');
  const email = `mlm-cv-${unique()}@example.com`;
  const owner = await provisionSuperAdmin({ email, password: 'mlm-cv-pw-1', name: 'Platform' });
  platform = await as({ email, password: 'mlm-cv-pw-1' });
  actor = { auth: { sub: owner.user.id, role: 'superadmin' } };
  fake = new FakeProvider('razorpay');
  setCoursePaymentProvider(fake);
  // A paid course of this suite's own, so its price and sales are known.
  const instructorId = (await admin.get('/catalog/instructors')).body[0].id as string;
  const created = await admin.post('/courses', {
    title: `AI Course ${unique()}`,
    description: 'The eligible course.',
    instructorIds: [instructorId],
    pricing: 'paid',
    priceAmount: 10_000,
  });
  expect(created.status).toBe(201);
  courseId = created.body.id;
  expect((await admin.post(`/courses/${courseId}/publish`)).status).toBe(200);
  await runAsPlatform('the CV tests put the course on the active plan', async () => {
    const active = await platformDb.mlmPlanVersion.findFirst({ where: { status: 'active' } });
    if (active) {
      const current = await platformDb.mlmPlanVersion.findUniqueOrThrow({ where: { id: active.id } });
      const ids = JSON.parse(current.eligibleCourseIdsJson) as string[];
      await setMlmEligibleCourses(actor, active.id, [...new Set([...ids, courseId])]);
      return;
    }
    const draft = await createMlmPlanVersion(actor, { ...defaultMlmPlanTerms(FIRST_TENANT_ID), eligibleCourseIds: [courseId] });
    await activateMlmPlanVersion(actor, draft.id);
  });
});

afterAll(() => setCoursePaymentProvider(undefined));

describe('a verified sale of the eligible course', () => {
  it('records an order, activates the buyer, and credits every ancestor in the right leg, at once', async () => {
    // Root ─A─ Rahul ─A─ Deep (the buyer).
    const root = await newStudent('CV Root');
    const rootMe = await enrol(root);
    const rahul = await newStudent('CV Rahul');
    const rahulMe = await enrol(rahul, rootMe.code);
    const deep = await newStudent('CV Deep');
    const deepMe = await enrol(deep, rahulMe.code);
    expect((await deep.get('/affiliate')).body.affiliate.placement).toMatchObject({ parentCode: rahulMe.code, leg: 'A' });

    const purchaseId = await buy(deep);
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId } });
    expect(order).toMatchObject({ status: 'eligible', buyerAffiliateId: deepMe.id, creditedAncestors: 2 });
    expect(Number(order.cv)).toBe(10_000 * 100); // 100% of ₹10,000
    expect((await deep.get('/affiliate')).body.affiliate.status).toBe('active');
    const activation = await deep.get('/affiliate/activation');
    expect(activation.body.courses.find((c: { id: string }) => c.id === courseId).purchase).toBe('enrolled');

    const rahulFigures = await rahul.get('/affiliate/figures');
    expect(rahulFigures.body).toMatchObject({ lifetimeA: 1_000_000, unmatchedA: 1_000_000, lifetimeB: 0, matchable: 0, eligibleOrders: 1 });
    const rootFigures = await root.get('/affiliate/figures');
    expect(rootFigures.body).toMatchObject({ lifetimeA: 1_000_000, unmatchedA: 1_000_000 });
    expect((await deep.get('/affiliate/figures')).body.lifetimeA).toBe(0); // the buyer's own node gets nothing
    const ledger = await rahul.get('/affiliate/cv');
    expect(ledger.body.rows).toEqual([
      expect.objectContaining({ leg: 'A', kind: 'sale', amount: 1_000_000, order: expect.objectContaining({ buyerName: 'CV Deep', status: 'eligible' }) }),
    ]);
    // The ledger cannot be touched.
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM \`MlmCvLedger\` WHERE \`orderId\` = ?`, order.id)).rejects.toThrow(/never deleted/);
  });

  it('is reversed once by the Super Admin, negating the credits and never below zero', async () => {
    const root = await newStudent('Rev Root');
    const rootMe = await enrol(root);
    const buyer = await newStudent('Rev Buyer');
    await enrol(buyer, rootMe.code);
    const purchaseId = await buy(buyer);
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId } });
    expect((await root.get('/affiliate/figures')).body.unmatchedA).toBe(1_000_000);
    const reversed = await platform.post(`/superadmin/affiliates/orders/${order.id}/reverse`, { reason: 'refund', note: 'refunded in the dashboard' });
    expect(reversed.status, JSON.stringify(reversed.body)).toBe(200);
    expect(reversed.body).toMatchObject({ status: 'reversed', reversalReason: 'refund' });
    expect((await root.get('/affiliate/figures')).body).toMatchObject({ lifetimeA: 0, unmatchedA: 0 });
    const rows = await db.mlmCvLedger.findMany({ where: { orderId: order.id }, orderBy: { createdAt: 'asc' } });
    expect(rows.map((r) => [r.kind, Number(r.amount)])).toEqual([
      ['sale', 1_000_000],
      ['reversal', -1_000_000],
    ]);
    expect((await platform.post(`/superadmin/affiliates/orders/${order.id}/reverse`, { reason: 'manual' })).status).toBe(409);
    expect((await platformDb.auditLog.findFirst({ where: { action: 'mlm.order.reversed', targetId: order.id } }))?.actorId).toBe(actor.auth.sub);
  });

  it('is reversed by a refund of the sale, once, with the sponsor’s credit taken back', async () => {
    fake.refundAnswer = { status: 'succeeded', providerRefundId: 'rf' };
    const root = await newStudent('Refund Root');
    const rootMe = await enrol(root);
    const buyer = await newStudent('Refund Buyer');
    await enrol(buyer, rootMe.code);
    const purchaseId = await buy(buyer);
    expect((await root.get('/affiliate/figures')).body.unmatchedA).toBe(1_000_000);

    const refunded = await platform.post(`/superadmin/sales/orders/${purchaseId}/refund`, { reason: 'Asked within the window' });
    expect(refunded.status, JSON.stringify(refunded.body)).toBe(200);
    expect(refunded.body.affiliateOrder.status).toBe('reversed');
    expect((await root.get('/affiliate/figures')).body).toMatchObject({ lifetimeA: 0, unmatchedA: 0 });
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId } });
    expect(order.reversalReason).toBe('refund');
  });

  it('credits nobody for a buyer outside the program, and waits for an unplaced buyer', async () => {
    const outsider = await newStudent('Outsider Buyer');
    const purchaseId = await buy(outsider);
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId } });
    // Nothing to wait for: the sale counts at once, and nobody is credited.
    expect(order).toMatchObject({ status: 'eligible', buyerAffiliateId: null, creditedAncestors: 0 });
    // A buyer who has a sponsor but no position yet: nothing is credited until the placement job has run.
    const root = await newStudent('Wait Root');
    const rootMe = await enrol(root);
    const late = await newStudent('Wait Buyer');
    const lateMe = await enrol(late, rootMe.code);
    await db.affiliate.update({ where: { id: lateMe.id }, data: { placementParentId: null, placementLeg: null, pathIdsJson: '[]', depth: 0 } });
    const latePurchase = await buy(late);
    expect((await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: latePurchase } })).status).toBe('pending');
    expect((await root.get('/affiliate/figures')).body.unmatchedA).toBe(0);
    // Placed again, the eligibility job credits the root.
    await db.affiliate.update({
      where: { id: lateMe.id },
      data: { placementParentId: rootMe.id, placementLeg: 'A', pathIdsJson: JSON.stringify([rootMe.id]), depth: 1 },
    });
    const settled = await runInTenant(ACADEMY, () => settleEligibleOrders());
    expect(settled).toBeGreaterThanOrEqual(1);
    expect((await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: latePurchase } })).status).toBe('eligible');
    expect((await root.get('/affiliate/figures')).body.unmatchedA).toBe(1_000_000);
  });
});

describe('the Super Admin’s sales views', () => {
  it('lists products, orders, the ledger and carry-forward pools, and exports the ledger', async () => {
    const products = await platform.get('/superadmin/affiliates/products');
    expect(products.status).toBe(200);
    expect(products.body.active.eligibleCourseIds).toContain(courseId);
    expect(products.body.courses.some((c: { id: string }) => c.id === courseId)).toBe(true);

    const orders = await platform.get('/superadmin/affiliates/orders?search=CV%20Deep');
    expect(orders.status).toBe(200);
    expect(orders.body.rows[0]).toMatchObject({ buyer: { name: 'CV Deep' }, status: 'eligible', cv: 1_000_000, course: { id: courseId } });
    expect(orders.body.counts.all).toBeGreaterThanOrEqual(3);
    const detail = await platform.get(`/superadmin/affiliates/orders/${orders.body.rows[0].id}`);
    expect(detail.body.creditedAncestors).toBe(2);

    const ledger = await platform.get('/superadmin/affiliates/cv?leg=A');
    expect(ledger.body.rows.every((r: { leg: string }) => r.leg === 'A')).toBe(true);
    const csv = await platform.get('/superadmin/affiliates/cv/export.csv');
    expect(csv.headers['content-type']).toContain('text/csv');
    expect(String(csv.text || csv.body)).toContain('CV Deep');

    const pools = await platform.get('/superadmin/affiliates/carry-forward?search=CV%20Rahul');
    expect(pools.body.rows[0]).toMatchObject({ affiliate: { name: 'CV Rahul' }, unmatchedA: 1_000_000, unmatchedB: 0 });

    const learner = await newStudent('No Access');
    expect((await learner.get('/superadmin/affiliates/orders')).status).toBe(403);
  });

  it('refuses to empty the active version’s course list through the products endpoint', async () => {
    expect((await platform.put('/superadmin/affiliates/products', { eligibleCourseIds: [] })).status).toBe(400);
  });
});
