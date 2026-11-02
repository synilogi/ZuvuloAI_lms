import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { couponDiscount, courseSale, MIN_CHARGE } from '@syniastrolms/domain';

import { setCoursePaymentProvider } from '../lib/coursePayments.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { ACADEMY, db, platformDb } from '../test/db.js';
import { FakeProvider, signWebhook } from '../test/fakeProvider.js';
import { PASSWORD, app, as, newStudent, unique, type Client } from '../test/helpers.js';

/* Course sales on the platform (docs/16 §2.4): order numbers, sale prices, coupons and refunds. Money comes only from the server,
 * a coupon is counted once its order is paid, and a refund closes the access it bought and takes the CV back. */

let admin: Client;
let owner: Client;
let instructorId: string;
let fake: FakeProvider;

async function course(priceAmount: number, salePrice?: number) {
  const created = await admin.post('/courses', {
    title: `Sale course ${unique()}`,
    description: 'A course for the sales tests.',
    instructorIds: [instructorId],
    pricing: 'paid',
    priceAmount,
    ...(salePrice !== undefined ? { salePrice } : {}),
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  expect((await admin.post(`/courses/${created.body.id}/publish`)).status).toBe(200);
  return created.body.id as string;
}

const coupon = (over: object = {}) =>
  owner.post('/superadmin/sales/coupons', { code: `C${unique()}`.toUpperCase().slice(0, 20), kind: 'percent', percentBps: 1000, ...over });

async function pay(learner: Awaited<ReturnType<typeof newStudent>>, courseId: string, body: object = {}) {
  const started = await learner.post(`/learning/courses/${courseId}/purchase`, body);
  expect(started.status, JSON.stringify(started.body)).toBe(201);
  const { paymentId, signature } = fake.pay(started.body.checkout.orderId, 'paid');
  const confirmed = await learner.post(`/learning/purchases/${started.body.purchase.id}/confirm`, { paymentId, signature });
  expect(confirmed.status, JSON.stringify(confirmed.body)).toBe(200);
  return started.body.purchase as { id: string; orderNumber: string; amount: number };
}

beforeAll(async () => {
  admin = await as('admin');
  instructorId = (await admin.get('/catalog/instructors')).body[0].id as string;
  const email = `sales-owner-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Sales Owner' });
  owner = await as({ email, password: PASSWORD });
  fake = new FakeProvider('razorpay');
  setCoursePaymentProvider(fake);
});
afterAll(() => setCoursePaymentProvider(undefined));

describe('the arithmetic', () => {
  it('rounds a percentage half up in paise, and leaves at least the smallest charge', () => {
    expect(couponDiscount(149900, { kind: 'percent', percentBps: 1000 })).toBe(14990);
    expect(couponDiscount(999, { kind: 'percent', percentBps: 1250 })).toBe(125);
    expect(couponDiscount(149900, { kind: 'percent', percentBps: 10000 })).toBe(149900 - MIN_CHARGE);
    expect(couponDiscount(149900, { kind: 'fixed', amountOff: 500000 })).toBe(149900 - MIN_CHARGE);
    expect(couponDiscount(MIN_CHARGE, { kind: 'fixed', amountOff: 50 })).toBe(0);
  });

  it('sells at the sale price only when it is below the list price', () => {
    expect(courseSale({ pricing: 'paid', price: { amount: 1000, currency: 'INR' }, salePrice: 700 })).toMatchObject({
      kind: 'paid',
      price: { amount: 700 },
      listPrice: 1000,
    });
    expect(courseSale({ pricing: 'paid', price: { amount: 1000, currency: 'INR' }, salePrice: 1000 })).toMatchObject({ kind: 'paid', price: { amount: 1000 } });
  });
});

describe('an order', () => {
  it('gets its own number, in sequence, fixed for good', async () => {
    const id = await course(1499);
    const a = await pay(await newStudent(), id);
    const b = await pay(await newStudent(), id);
    const year = new Date().getFullYear();
    expect(a.orderNumber).toMatch(new RegExp(`^ORD-${year}-\\d{6}$`));
    expect(Number(b.orderNumber.slice(-6))).toBe(Number(a.orderNumber.slice(-6)) + 1);
    await expect(platformDb.coursePurchase.update({ where: { id: a.id }, data: { orderNumber: 'ORD-0000-000000' } })).rejects.toThrow();
  });

  it('charges the sale price, and refuses one at or above the list price', async () => {
    const id = await course(2000, 1500);
    const learner = await newStudent();
    expect((await learner.post(`/learning/courses/${id}/quote`)).body).toEqual({ listPrice: 2000, charge: 150000, discount: 0, total: 150000 });
    expect((await pay(learner, id)).amount).toBe(150000);
    const bad = await admin.post('/courses', {
      title: `Bad sale ${unique()}`,
      description: 'x',
      instructorIds: [instructorId],
      pricing: 'paid',
      priceAmount: 1000,
      salePrice: 1000,
    });
    expect(bad.status).toBe(400);
  });

  it('takes the price from the server, whatever the body says', async () => {
    const id = await course(1499);
    const learner = await newStudent();
    const started = await learner.post(`/learning/courses/${id}/purchase`, { amount: 1, discountAmount: 149800 });
    expect(started.body.purchase.amount).toBe(149900);
  });
});

describe('a coupon', () => {
  it('takes its discount off the order, and counts once it is paid', async () => {
    const id = await course(1000);
    const made = await coupon({ maxUses: 5 });
    expect(made.status, JSON.stringify(made.body)).toBe(201);
    const learner = await newStudent();
    const quote = await learner.post(`/learning/courses/${id}/quote`, { couponCode: made.body.code.toLowerCase() });
    expect(quote.body).toEqual({ listPrice: 1000, charge: 100000, discount: 10000, total: 90000, couponCode: made.body.code });
    expect((await platformDb.coupon.findUniqueOrThrow({ where: { id: made.body.id } })).usedCount).toBe(0);

    const purchase = await pay(learner, id, { couponCode: made.body.code });
    expect(purchase.amount).toBe(90000);
    const row = await platformDb.coupon.findUniqueOrThrow({ where: { id: made.body.id } });
    expect(row.usedCount).toBe(1);
    expect(await platformDb.couponRedemption.count({ where: { couponId: row.id, purchaseId: purchase.id, discountAmount: 10000 } })).toBe(1);
  });

  it('refuses what it may not do, in words a learner can act on', async () => {
    const id = await course(1000);
    const other = await course(1000);
    const learner = await newStudent();
    const quote = (couponCode: string, courseId = id) => learner.post(`/learning/courses/${courseId}/quote`, { couponCode });
    expect((await quote('NO-SUCH-CODE')).body.code).toBe('COUPON_INVALID');

    const disabled = (await coupon()).body;
    expect((await owner.patch(`/superadmin/sales/coupons/${disabled.id}`, { status: 'disabled' })).status).toBe(200);
    expect((await quote(disabled.code)).status).toBe(409);

    const past = (await coupon({ endsAt: new Date(Date.now() - 1000).toISOString() })).body;
    expect((await quote(past.code)).body.message).toMatch(/expired/);
    const future = (await coupon({ startsAt: new Date(Date.now() + 86_400_000).toISOString() })).body;
    expect((await quote(future.code)).body.message).toMatch(/isn’t open yet/);
    const elsewhere = (await coupon({ courseId: other })).body;
    expect((await quote(elsewhere.code)).body.message).toMatch(/another course/);
    expect((await quote(elsewhere.code, other)).status).toBe(200);
  });

  it('holds one use per learner, and its ceiling, against checkouts still open', async () => {
    const id = await course(1000);
    const once = (await coupon({ maxUses: 1 })).body;
    const first = await newStudent();
    const second = await newStudent();
    // The first learner's open order holds the only place.
    expect((await first.post(`/learning/courses/${id}/purchase`, { couponCode: once.code })).status).toBe(201);
    expect((await second.post(`/learning/courses/${id}/quote`, { couponCode: once.code })).body.message).toMatch(/fully used/);

    const mine = (await coupon()).body;
    const buyer = await newStudent();
    await pay(buyer, id, { couponCode: mine.code });
    const another = await course(1000);
    expect((await buyer.post(`/learning/courses/${another}/quote`, { couponCode: mine.code })).body.message).toMatch(/already used/);
  });

  it('keeps its code and discount fixed, is never deleted, and is the owner’s alone', async () => {
    const made = (await coupon()).body;
    await expect(platformDb.coupon.update({ where: { id: made.id }, data: { percentBps: 9000 } })).rejects.toThrow();
    await expect(platformDb.coupon.delete({ where: { id: made.id } })).rejects.toThrow();
    expect((await coupon({ code: made.code })).status).toBe(409);
    expect((await coupon({ kind: 'percent', percentBps: 20000 })).status).toBe(400);
    expect((await admin.get('/superadmin/sales/coupons')).status).toBe(403);
    expect((await (await newStudent()).post('/superadmin/sales/coupons', {})).status).toBe(403);
  });
});

describe('a refund', () => {
  const enrolment = (learner: { studentId: string }, courseId: string) =>
    db.enrollment.findUniqueOrThrow({ where: { studentId_courseId: { studentId: learner.studentId, courseId } } });
  const refund = (id: string) => owner.post(`/superadmin/sales/orders/${id}/refund`, { reason: 'Asked within the window' });

  it('returns the whole amount, closes the access it bought, once, and lets the learner buy again', async () => {
    fake.refundAnswer = { status: 'succeeded', providerRefundId: 'rf' };
    const id = await course(1499);
    const learner = await newStudent();
    const before = (await db.course.findUniqueOrThrow({ where: { id } })).enrolledCount;
    const purchase = await pay(learner, id);
    expect((await db.course.findUniqueOrThrow({ where: { id } })).enrolledCount).toBe(before + 1);

    const res = await refund(purchase.id);
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    expect(res.body).toMatchObject({ status: 'refunded', canRefund: false });
    expect(res.body.refunds[0]).toMatchObject({ status: 'succeeded', amount: 149900 });
    expect(fake.refunds.at(-1)).toMatchObject({ amount: 149900 });
    expect((await enrolment(learner, id)).status).toBe('expired');
    expect((await db.course.findUniqueOrThrow({ where: { id } })).enrolledCount).toBe(before);
    expect((await learner.get(`/learning/courses/${id}/lessons/none`)).status).not.toBe(200);
    expect(await platformDb.emailOutbox.findFirst({ where: { toEmail: learner.email, templateKey: 'course-refund' } })).toBeTruthy();

    const count = fake.refunds.length;
    expect((await refund(purchase.id)).status).toBe(409);
    expect(fake.refunds).toHaveLength(count);

    expect((await pay(learner, id)).amount).toBe(149900);
    expect((await enrolment(learner, id)).status).toBe('active');
  });

  it('is refused unpaid, and refused to everyone but the owner', async () => {
    const id = await course(1499);
    const learner = await newStudent();
    const open = await learner.post(`/learning/courses/${id}/purchase`);
    expect((await refund(open.body.purchase.id)).status).toBe(409);
    const paid = await pay(await newStudent(), await course(1499));
    expect((await admin.post(`/superadmin/sales/orders/${paid.id}/refund`, { reason: 'Not mine to do' })).status).toBe(403);
    expect((await learner.post(`/superadmin/sales/orders/${paid.id}/refund`, { reason: 'Not mine to do' })).status).toBe(403);
    expect((await owner.post(`/superadmin/sales/orders/${paid.id}/refund`, {})).status).toBe(400);
  });

  it('leaves access alone when the gateway refuses, and allows another try', async () => {
    const id = await course(1499);
    const learner = await newStudent();
    const purchase = await pay(learner, id);
    fake.refundAnswer = 'error';
    expect((await refund(purchase.id)).status).toBe(502);
    expect((await enrolment(learner, id)).status).toBe('active');
    fake.refundAnswer = { status: 'succeeded', providerRefundId: 'rf' };
    expect((await refund(purchase.id)).body.status).toBe('refunded');
  });

  it('stays pending on an unclear answer, blocks a second refund, and settles on the gateway’s signed word', async () => {
    const id = await course(1499);
    const learner = await newStudent();
    const purchase = await pay(learner, id);
    fake.refundAnswer = 'timeout';
    expect((await refund(purchase.id)).status).toBe(502);
    expect((await enrolment(learner, id)).status).toBe('active');
    const detail = (await owner.get(`/superadmin/sales/orders/${purchase.id}`)).body;
    expect(detail).toMatchObject({ status: 'paid', canRefund: false });
    expect(detail.refunds[0].status).toBe('pending');
    fake.refundAnswer = { status: 'succeeded', providerRefundId: 'rf' };
    expect((await refund(purchase.id)).status).toBe(409);

    const paymentId = detail.providerPaymentId as string;
    const raw = JSON.stringify({
      entity: 'event',
      event: 'refund.processed',
      payload: { refund: { entity: { id: `rfnd_${unique()}`, payment_id: paymentId, status: 'processed', notes: { refundId: detail.refunds[0].id } } } },
      created_at: Date.now(),
    });
    const delivered = await request(app)
      .post('/webhooks/razorpay/courses')
      .set('content-type', 'application/json')
      .set('x-razorpay-event-id', `evt_${unique()}`)
      .set('x-razorpay-signature', signWebhook(raw))
      .send(raw);
    expect(delivered.status, JSON.stringify(delivered.body)).toBe(200);
    expect((await enrolment(learner, id)).status).toBe('expired');
    expect((await owner.get(`/superadmin/sales/orders/${purchase.id}`)).body.status).toBe('refunded');
  });

  it('flags a part refund made at the gateway, and changes nothing else', async () => {
    const id = await course(1499);
    const learner = await newStudent();
    const purchase = await pay(learner, id);
    const row = await platformDb.coursePurchase.findUniqueOrThrow({ where: { id: purchase.id } });
    const raw = JSON.stringify({
      entity: 'event',
      event: 'refund.processed',
      payload: { refund: { entity: { id: `rfnd_${unique()}`, payment_id: row.providerPaymentId, status: 'processed', notes: {} } } },
      created_at: Date.now(),
    });
    await request(app)
      .post('/webhooks/razorpay/courses')
      .set('content-type', 'application/json')
      .set('x-razorpay-event-id', `evt_${unique()}`)
      .set('x-razorpay-signature', signWebhook(raw))
      .send(raw);
    expect((await enrolment(learner, id)).status).toBe('active');
    expect((await platformDb.coursePurchase.findUniqueOrThrow({ where: { id: purchase.id } })).reviewReason).toMatch(/Part of this payment/);
  });
});

describe('the owner’s view of sales', () => {
  it('lists orders with their learners and takings, searches them, and exports them safely', async () => {
    const id = await course(1499);
    const learner = await newStudent('Order Finder');
    const purchase = await pay(learner, id);
    const list = await owner.get('/superadmin/sales/orders', { search: purchase.orderNumber });
    expect(list.status).toBe(200);
    expect(list.body.rows).toHaveLength(1);
    expect(list.body.rows[0]).toMatchObject({ orderNumber: purchase.orderNumber, status: 'paid', learner: { name: 'Order Finder' } });
    expect(list.body.revenue).toBeGreaterThanOrEqual(149900);
    expect((await owner.get('/superadmin/sales/orders', { status: 'nonsense' })).status).toBe(400);

    const csv = await owner.get('/superadmin/sales/orders/export.csv', { search: purchase.orderNumber });
    expect(csv.headers['content-type']).toMatch(/text\/csv/);
    expect(csv.text).toContain(purchase.orderNumber);
    expect(await platformDb.coursePurchase.count({ where: { tenantId: ACADEMY, id: purchase.id } })).toBe(1);
  });

  it('shows what the gateway reported', async () => {
    const res = await owner.get('/superadmin/sales/events');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ page: 1 });
  });
});

describe('what an instructor sees of their courses (D-PLAT-10)', () => {
  it('counts enrolments and orders for their own courses, never money and never anyone else’s', async () => {
    const id = await course(1499);
    const learner = await newStudent();
    await pay(learner, id);

    const staff = await admin.get('/reports/course-sales');
    expect(staff.status).toBe(200);
    expect(staff.body.find((r: { courseId: string }) => r.courseId === id)).toMatchObject({ pricing: 'paid', enrolled: 1, paidOrders: 1, refundedOrders: 0 });
    expect(JSON.stringify(staff.body)).not.toMatch(/amount|revenue|price/i);

    const instructor = await as('instructor');
    const mine = await instructor.get('/reports/course-sales');
    expect(mine.status).toBe(200);
    const ownIds = (await instructor.get('/courses?page=1&pageSize=100')).body.rows.map((c: { id: string }) => c.id);
    expect(mine.body.every((r: { courseId: string }) => ownIds.includes(r.courseId))).toBe(true);

    expect((await learner.get('/reports/course-sales')).status).toBe(403);
  });
});
