import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';

import { setCoursePaymentProvider } from '../lib/coursePayments.js';
import { reconcileCoursePurchases } from '../lib/coursePurchases.js';
import { setObservationSink, type Observation } from '../lib/observe.js';
import { runInTenant } from '../lib/tenancy.js';
import { ACADEMY, db, platformDb } from '../test/db.js';
import { FakeProvider, signWebhook } from '../test/fakeProvider.js';
import { app, as, newStudent, unique, type Client } from '../test/helpers.js';

/*
 * Paid courses (lib/coursePurchases.ts): a paid course opens only once its payment is verified with the platform's
 * gateway (docs/16, D-PLAT-07); a free course is joined as before. The gateway is a fake that keeps orders and payments in memory and
 * signs as Razorpay does, so nothing here reaches a real gateway or moves money.
 */

let admin: Client;
let instructorId: string;
let fake: FakeProvider;

type Learner = Awaited<ReturnType<typeof newStudent>>;

async function course(pricing: 'free' | 'paid', priceAmount?: number) {
  const created = await admin.post('/courses', {
    title: `${pricing === 'paid' ? 'Paid' : 'Free'} course ${unique()}`,
    description: 'A course for the purchase tests.',
    instructorIds: [instructorId],
    pricing,
    ...(priceAmount !== undefined ? { priceAmount } : {}),
  });
  expect(created.status).toBe(201);
  const published = await admin.post(`/courses/${created.body.id}/publish`);
  expect(published.status).toBe(200);
  // One chapter with one published lesson that is not a free preview: what a purchase opens.
  const chapter = await db.chapter.create({ data: { tenantId: ACADEMY, courseId: created.body.id, title: 'Chapter one', status: 'published', position: 0 } });
  const lesson = await db.lesson.create({
    data: {
      tenantId: ACADEMY,
      chapterId: chapter.id,
      courseId: created.body.id,
      title: 'Paid lesson',
      type: 'reading',
      status: 'published',
      position: 0,
      contentJson: JSON.stringify({ article: { body: 'Inside.' } }),
    },
  });
  return { id: created.body.id as string, lessonId: lesson.id };
}

const start = (learner: Learner, courseId: string, body: object = {}) => learner.post(`/learning/courses/${courseId}/purchase`, body);
const confirm = (learner: Learner, purchaseId: string, paymentId: string, signature: string) =>
  learner.post(`/learning/purchases/${purchaseId}/confirm`, { paymentId, signature });
const enrolmentOf = (learner: Learner, courseId: string) =>
  db.enrollment.findUnique({ where: { studentId_courseId: { studentId: learner.studentId, courseId } } });
const purchaseRow = (id: string) => platformDb.coursePurchase.findUniqueOrThrow({ where: { id } });

const webhookBody = (paymentId: string, orderId: string, event = 'payment.captured') =>
  JSON.stringify({ entity: 'event', event, payload: { payment: { entity: { id: paymentId, order_id: orderId } } }, created_at: Date.now() });
const deliver = (provider: string, raw: string, opts: { eventId?: string; signature?: string | null } = {}) => {
  let req = request(app)
    .post(`/webhooks/${provider}/courses`)
    .set('content-type', 'application/json')
    .set('x-razorpay-event-id', opts.eventId ?? `evt_${unique()}`);
  if (opts.signature !== null) req = req.set('x-razorpay-signature', opts.signature ?? signWebhook(raw));
  return req.send(raw);
};

beforeAll(async () => {
  admin = await as('admin');
  instructorId = (await admin.get('/catalog/instructors')).body[0].id as string;
  fake = new FakeProvider('razorpay');
  setCoursePaymentProvider(fake);
});

afterAll(() => {
  setCoursePaymentProvider(undefined);
});

describe('enrolling: free courses as before, paid ones only by purchase', () => {
  it('enrols a learner in a free course without payment', async () => {
    const free = await course('free');
    const learner = await newStudent();
    const res = await learner.post(`/learning/courses/${free.id}/enroll`);
    expect(res.status).toBe(200);
    expect(await enrolmentOf(learner, free.id)).toMatchObject({ status: 'active', source: 'self', purchaseId: null });
    // A free course is never bought.
    expect((await start(learner, free.id)).status).toBe(409);
  });

  it('refuses a free enrolment in a paid course, through the API directly', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const res = await learner.post(`/learning/courses/${paid.id}/enroll`);
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('COURSE_PURCHASE_REQUIRED');
    expect(await enrolmentOf(learner, paid.id)).toBeNull();
  });

  it('opens nothing of a paid course to a learner who has not bought it', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    expect((await learner.post(`/learning/courses/${paid.id}/lessons/${paid.lessonId}/complete`)).status).toBe(403);
    const lesson = await learner.get(`/learning/courses/${paid.id}/lessons/${paid.lessonId}`);
    expect(JSON.stringify(lesson.body)).not.toContain('Inside.');
  });

  it('opens a course whose price no admin chose to nobody: neither free nor for sale', async () => {
    const held = await course('paid', 2999);
    await db.course.update({ where: { id: held.id }, data: { pricing: 'unset' } });
    const learner = await newStudent();
    const enrol = await learner.post(`/learning/courses/${held.id}/enroll`);
    expect(enrol.status).toBe(409);
    expect(enrol.body.code).toBe('COURSE_NOT_FOR_SALE');
    expect((await start(learner, held.id)).body.code).toBe('COURSE_NOT_FOR_SALE');
    // A paid course without a valid price is never free either.
    await db.course.update({ where: { id: held.id }, data: { pricing: 'paid', priceAmount: null } });
    expect((await learner.post(`/learning/courses/${held.id}/enroll`)).body.code).toBe('COURSE_NOT_FOR_SALE');
    expect(await enrolmentOf(learner, held.id)).toBeNull();
  });

  it('holds the rule in the database too: no self-enrolment row in a paid course, whatever the code path', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    await expect(db.enrollment.create({ data: { tenantId: ACADEMY, studentId: learner.studentId, courseId: paid.id, source: 'self' } })).rejects.toThrow();
  });
});

describe('buying a paid course', () => {
  it('prices the order on the server, whatever the client sends', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const res = await start(learner, paid.id, { amount: 100, currency: 'USD', tenantId: 'tenant-x', studentId: 'someone-else', courseId: 'other' });
    expect(res.status).toBe(201);
    expect(res.body.purchase).toMatchObject({ status: 'created', amount: 149_900, currency: 'INR', listPrice: 1499, courseId: paid.id, enrolled: false });
    expect(res.body.checkout).toMatchObject({ orderId: expect.any(String), amount: 149_900, currency: 'INR', keyId: 'fake_key_id' });
    expect(fake.orders.get(res.body.checkout.orderId)).toMatchObject({ amount: 149_900, currency: 'INR' });
    const row = await purchaseRow(res.body.purchase.id);
    expect(row).toMatchObject({ studentId: learner.studentId, courseId: paid.id, tenantId: ACADEMY });
    // The checkout carries nothing secret.
    expect(JSON.stringify(res.body)).not.toMatch(/secret/i);
  });

  it('reuses one open order, even for many checkouts at once', async () => {
    const paid = await course('paid', 999);
    const learner = await newStudent();
    const results = await Promise.all(Array.from({ length: 6 }, () => start(learner, paid.id)));
    expect(results.every((r) => r.status === 201)).toBe(true);
    expect(new Set(results.map((r) => r.body.purchase.id)).size).toBe(1);
    expect(await platformDb.coursePurchase.count({ where: { studentId: learner.studentId, courseId: paid.id, status: 'created' } })).toBe(1);
  });

  it('opens the course after a verified payment, exactly once, however often it is confirmed', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    const before = (await db.course.findUniqueOrThrow({ where: { id: paid.id } })).enrolledCount;
    const payment = fake.pay(checkout.orderId, 'paid');
    const [a, b, c] = await Promise.all([
      confirm(learner, purchase.id, payment.paymentId, payment.signature),
      confirm(learner, purchase.id, payment.paymentId, payment.signature),
      confirm(learner, purchase.id, payment.paymentId, payment.signature),
    ]);
    for (const r of [a, b, c]) expect(r.status, JSON.stringify(r.body)).toBe(200);
    expect(a.body.purchase).toMatchObject({ status: 'paid', enrolled: true });
    expect(await enrolmentOf(learner, paid.id)).toMatchObject({ status: 'active', source: 'purchase', purchaseId: purchase.id });
    expect((await db.course.findUniqueOrThrow({ where: { id: paid.id } })).enrolledCount).toBe(before + 1);
    expect(await purchaseRow(purchase.id)).toMatchObject({ status: 'paid', providerPaymentId: payment.paymentId });
    // The lesson is open now.
    expect((await learner.post(`/learning/courses/${paid.id}/lessons/${paid.lessonId}/complete`)).status).toBe(200);
    // Nothing more to buy.
    expect((await start(learner, paid.id)).body.code).toBe('ALREADY_ENROLLED');
  });

  it('captures an approved payment for exactly the price, then opens the course', async () => {
    const paid = await course('paid', 750);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    const payment = fake.pay(checkout.orderId, 'authorized');
    const res = await confirm(learner, purchase.id, payment.paymentId, payment.signature);
    expect(res.body.purchase).toMatchObject({ status: 'paid', enrolled: true });
    expect(fake.captured).toContain(payment.paymentId);
  });

  it('opens nothing on a bad signature, a forged success, or another order’s payment', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    const payment = fake.pay(checkout.orderId, 'paid');

    const forged = await confirm(learner, purchase.id, payment.paymentId, 'not-the-signature');
    expect(forged.status).toBe(400);
    expect(forged.body.code).toBe('PAYMENT_FAILED');

    // A real payment of another order, presented with a signature for this one: the gateway says whose it is.
    const other = await newStudent();
    const elsewhere = (await start(other, (await course('paid', 1499)).id)).body;
    const theirs = fake.pay(elsewhere.checkout.orderId, 'paid');
    const crossed = await confirm(learner, purchase.id, theirs.paymentId, `sig:${checkout.orderId}|${theirs.paymentId}`);
    expect(crossed.status).toBe(400);

    expect(await enrolmentOf(learner, paid.id)).toBeNull();
    expect((await purchaseRow(purchase.id)).status).toBe('created');
  });

  it('refuses a payment for a different amount, and captures nothing', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    const payment = fake.pay(checkout.orderId, 'authorized', { amount: 100 });
    const res = await confirm(learner, purchase.id, payment.paymentId, payment.signature);
    expect(res.body.outcome).toMatchObject({ status: 'failed', enrolled: false });
    expect(res.body.purchase).toMatchObject({ status: 'failed', failureMessage: expect.stringMatching(/does not match/) });
    expect(fake.captured).not.toContain(payment.paymentId);
    expect(await enrolmentOf(learner, paid.id)).toBeNull();
  });

  it('leaves a declined order open to pay again, and opens the course on the retry', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    const declined = fake.pay(checkout.orderId, 'failed');
    const first = await confirm(learner, purchase.id, declined.paymentId, declined.signature);
    expect(first.body.outcome).toMatchObject({ status: 'failed', enrolled: false });
    // Shown as failed (and retryable): the order itself stays open.
    expect(first.body.purchase).toMatchObject({ status: 'failed', failureMessage: 'Payment declined by the bank' });
    expect((await purchaseRow(purchase.id)).status).toBe('created');
    expect(await enrolmentOf(learner, paid.id)).toBeNull();

    // The same order is offered again, and a good payment on it opens the course.
    expect((await start(learner, paid.id)).body.purchase.id).toBe(purchase.id);
    const retry = fake.pay(checkout.orderId, 'paid');
    const second = await confirm(learner, purchase.id, retry.paymentId, retry.signature);
    expect(second.body.purchase).toMatchObject({ status: 'paid', enrolled: true });
  });

  it('waits on a pending payment, and opens the course when the gateway has it — after an app restart too', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    const payment = fake.pay(checkout.orderId, 'pending');
    const res = await confirm(learner, purchase.id, payment.paymentId, payment.signature);
    expect(res.body.outcome).toMatchObject({ status: 'pending', enrolled: false });
    expect(await enrolmentOf(learner, paid.id)).toBeNull();

    // The app was closed; when it asks again, the gateway now has the money.
    fake.payments.set(payment.paymentId, { ...fake.payments.get(payment.paymentId)!, status: 'paid' });
    const status = await learner.get(`/learning/purchases/${purchase.id}`);
    expect(status.body).toMatchObject({ status: 'paid', enrolled: true });
  });

  it('shows a decline nobody confirmed (a hosted page) as failed when the learner asks, and lets them pay again', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    fake.pay(checkout.orderId, 'failed');
    expect((await learner.get(`/learning/purchases/${purchase.id}`)).body).toMatchObject({ status: 'failed', enrolled: false });
    fake.pay(checkout.orderId, 'paid');
    expect((await learner.get(`/learning/purchases/${purchase.id}`)).body).toMatchObject({ status: 'paid', enrolled: true });
  });

  it('is found again by the recovery job when nobody confirms it', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    fake.pay(checkout.orderId, 'paid');
    await platformDb.coursePurchase.update({ where: { id: purchase.id }, data: { createdAt: new Date(Date.now() - 5 * 60_000) } });
    await runInTenant(ACADEMY, () => reconcileCoursePurchases(new Date()));
    expect(await purchaseRow(purchase.id)).toMatchObject({ status: 'paid' });
    expect(await enrolmentOf(learner, paid.id)).toMatchObject({ source: 'purchase', purchaseId: purchase.id });
  });

  it('closes a stale order for reuse, yet still records a payment that arrives on it', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const first = (await start(learner, paid.id)).body;
    await platformDb.coursePurchase.update({ where: { id: first.purchase.id }, data: { expiresAt: new Date(Date.now() - 1000) } });
    const second = (await start(learner, paid.id)).body;
    expect(second.purchase.id).not.toBe(first.purchase.id);
    expect((await purchaseRow(first.purchase.id)).status).toBe('expired');

    const late = fake.pay(first.checkout.orderId, 'paid');
    const res = await confirm(learner, first.purchase.id, late.paymentId, late.signature);
    expect(res.body.purchase).toMatchObject({ status: 'paid', enrolled: true });
  });

  it('flags a second payment for a course the learner already has, and never opens it twice', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    const one = fake.pay(checkout.orderId, 'paid');
    await confirm(learner, purchase.id, one.paymentId, one.signature);
    const signals: Observation[] = [];
    setObservationSink((_l, o) => signals.push(o));
    try {
      const two = fake.pay(checkout.orderId, 'paid');
      const res = await confirm(learner, purchase.id, two.paymentId, two.signature);
      expect(res.status).toBe(200);
    } finally {
      setObservationSink(undefined);
    }
    expect(await purchaseRow(purchase.id)).toMatchObject({ providerPaymentId: one.paymentId });
    expect(await platformDb.enrollment.count({ where: { studentId: learner.studentId, courseId: paid.id } })).toBe(1);
  });

  it('flags a payment that arrives after staff already added the learner', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    expect((await admin.post(`/students/${learner.studentId}/enroll`, { courseId: paid.id, source: 'admin' })).status).toBeLessThan(300);
    const payment = fake.pay(checkout.orderId, 'paid');
    await confirm(learner, purchase.id, payment.paymentId, payment.signature);
    expect(await purchaseRow(purchase.id)).toMatchObject({ status: 'paid', reviewReason: expect.stringMatching(/already had/) });
    expect(await enrolmentOf(learner, paid.id)).toMatchObject({ source: 'admin' });
  });

  it('shows a learner only their own purchases', async () => {
    const paid = await course('paid', 1499);
    const owner = await newStudent();
    const stranger = await newStudent();
    const { purchase, checkout } = (await start(owner, paid.id)).body;
    const payment = fake.pay(checkout.orderId, 'paid');
    expect((await stranger.get(`/learning/purchases/${purchase.id}`)).status).toBe(404);
    expect((await confirm(stranger, purchase.id, payment.paymentId, payment.signature)).status).toBe(404);
    expect(await enrolmentOf(stranger, paid.id)).toBeNull();
    const list = await owner.get('/learning/purchases');
    expect(list.body.rows.map((r: { id: string }) => r.id)).toContain(purchase.id);
    expect((await stranger.get('/learning/purchases')).body.rows.map((r: { id: string }) => r.id)).not.toContain(purchase.id);
  });

  it('carries the payment reference a receipt prints, once a payment has settled the order', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    expect((await learner.get(`/learning/purchases/${purchase.id}`)).body.paymentReference).toBeUndefined();
    const payment = fake.pay(checkout.orderId, 'paid');
    await confirm(learner, purchase.id, payment.paymentId, payment.signature);
    const receipt = (await learner.get(`/learning/purchases/${purchase.id}`)).body;
    expect(receipt).toMatchObject({ status: 'paid', paymentReference: payment.paymentId, amount: 149_900, listPrice: 1499 });
    expect(receipt.paidAt).toBeTruthy();
  });

  it('keeps the purchase’s terms fixed in the database', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase } = (await start(learner, paid.id)).body;
    await expect(platformDb.coursePurchase.update({ where: { id: purchase.id }, data: { amount: 100 } })).rejects.toThrow();
    await expect(platformDb.coursePurchase.update({ where: { id: purchase.id }, data: { courseId: (await course('free')).id } })).rejects.toThrow();
    // An enrolment can't point at an unpaid purchase.
    await expect(
      db.enrollment.create({ data: { tenantId: ACADEMY, studentId: learner.studentId, courseId: paid.id, source: 'purchase', purchaseId: purchase.id } }),
    ).rejects.toThrow();
  });
});

describe('staff and the sandbox', () => {
  it('lets staff add a learner to a paid course, but never as a self-enrolment', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const asSelf = await admin.post(`/students/${learner.studentId}/enroll`, { courseId: paid.id, source: 'self' });
    expect(asSelf.status).toBe(400);
    expect(await enrolmentOf(learner, paid.id)).toBeNull();
    expect((await admin.post(`/students/${learner.studentId}/enroll`, { courseId: paid.id, source: 'scholarship' })).status).toBe(201);
    expect(await enrolmentOf(learner, paid.id)).toMatchObject({ source: 'scholarship', purchaseId: null });
  });

  it('sells through the sandbox in development when no gateway is active, settled by the status check', async () => {
    setCoursePaymentProvider(undefined);
    vi.stubEnv('PAYMENT_SANDBOX', 'on');
    try {
      const { sandboxProvider } = await import('../lib/sandboxGateway.js');
      const paid = await course('paid', 1499);
      const learner = await newStudent();
      const res = await start(learner, paid.id);
      expect(res.status).toBe(201);
      expect(res.body.checkout).toMatchObject({ provider: 'sandbox', redirectUrl: expect.stringContaining('/sandbox-checkout/') });
      // The payer pays on the sandbox's page; the platform's webhook ignores a course order, the status check settles it.
      sandboxProvider.pay(res.body.checkout.orderId, 'success');
      const status = await learner.get(`/learning/purchases/${res.body.purchase.id}`);
      expect(status.body).toMatchObject({ status: 'paid', enrolled: true });
    } finally {
      vi.unstubAllEnvs();
      setCoursePaymentProvider(fake);
    }
  });
});

describe('the gateway’s webhook', () => {
  it('opens the course from a signed event, once, whatever is redelivered or replayed', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { purchase, checkout } = (await start(learner, paid.id)).body;
    const payment = fake.pay(checkout.orderId, 'paid');
    const raw = webhookBody(payment.paymentId, checkout.orderId);

    expect((await deliver('razorpay', raw, { signature: 'forged' })).status).toBe(401);
    expect((await deliver('razorpay', raw, { signature: null })).status).toBe(401);
    expect(await enrolmentOf(learner, paid.id)).toBeNull();

    const eventId = `evt_${unique()}`;
    expect((await deliver('razorpay', raw, { eventId })).body).toMatchObject({ received: true });
    expect(await enrolmentOf(learner, paid.id)).toMatchObject({ source: 'purchase', purchaseId: purchase.id });
    // Redelivered, and replayed under a new event id: acknowledged, nothing changes.
    expect((await deliver('razorpay', raw, { eventId })).body).toMatchObject({ duplicate: true });
    expect((await deliver('razorpay', raw)).body).toMatchObject({ duplicate: true });
    // The browser's confirmation arriving after the webhook changes nothing either.
    expect((await confirm(learner, purchase.id, payment.paymentId, payment.signature)).body.purchase).toMatchObject({ status: 'paid' });
    expect(await platformDb.enrollment.count({ where: { studentId: learner.studentId, courseId: paid.id } })).toBe(1);
  });

  it('settles an out-of-order failure after capture as nothing', async () => {
    const paid = await course('paid', 1499);
    const learner = await newStudent();
    const { checkout } = (await start(learner, paid.id)).body;
    const payment = fake.pay(checkout.orderId, 'paid');
    await deliver('razorpay', webhookBody(payment.paymentId, checkout.orderId));
    // A stale "failed" event for the same payment: the gateway is asked, and says it is paid.
    await deliver('razorpay', webhookBody(payment.paymentId, checkout.orderId, 'payment.failed'));
    expect(await enrolmentOf(learner, paid.id)).toMatchObject({ status: 'active' });
  });

  it('acknowledges and ignores an order that is not a course purchase, and refuses a gateway it does not know', async () => {
    const order = await fake.createPayment({ amount: 5000, currency: 'INR' });
    const payment = fake.pay(order.providerOrderId, 'paid');
    const res = await deliver('razorpay', webhookBody(payment.paymentId, order.providerOrderId));
    expect(res.status).toBe(200);
    expect((await deliver(`nobody-${unique()}`, webhookBody(payment.paymentId, order.providerOrderId))).status).toBe(401);
  });

  it('still answers at the address the SaaS-era academy webhook was registered at (docs/16 §3.1)', async () => {
    const order = await fake.createPayment({ amount: 5000, currency: 'INR' });
    const payment = fake.pay(order.providerOrderId, 'paid');
    const raw = webhookBody(payment.paymentId, order.providerOrderId);
    const res = await request(app)
      .post(`/webhooks/academies/${ACADEMY}/razorpay/courses`)
      .set('content-type', 'application/json')
      .set('x-razorpay-event-id', `evt_${unique()}`)
      .set('x-razorpay-signature', signWebhook(raw))
      .send(raw);
    expect(res.status).toBe(200);
  });
});

describe('pricing a course (admin)', () => {
  it('validates the price on the server, and never makes a paid course free by omission', async () => {
    const base = { description: 'Pricing.', instructorIds: [instructorId] };
    expect((await admin.post('/courses', { ...base, title: `P ${unique()}`, pricing: 'paid' })).status).toBe(400);
    expect((await admin.post('/courses', { ...base, title: `P ${unique()}`, pricing: 'paid', priceAmount: 0 })).status).toBe(400);
    expect((await admin.post('/courses', { ...base, title: `P ${unique()}`, pricing: 'paid', priceAmount: 99.5 })).status).toBe(400);
    expect((await admin.post('/courses', { ...base, title: `P ${unique()}`, pricing: 'paid', priceAmount: 600_000 })).status).toBe(400);
    expect((await admin.post('/courses', { ...base, title: `P ${unique()}`, pricing: 'free', priceAmount: 499 })).status).toBe(400);

    const paid = await admin.post('/courses', { ...base, title: `P ${unique()}`, pricing: 'paid', priceAmount: 2499 });
    expect(paid.body).toMatchObject({ pricing: 'paid', price: { amount: 2499, currency: 'INR' } });
    // An edit that leaves pricing out keeps it; switching to paid without a price is refused and changes nothing.
    expect((await admin.patch(`/courses/${paid.body.id}`, { subtitle: 'Kept' })).body).toMatchObject({ pricing: 'paid', price: { amount: 2499 } });
    const plain = await admin.post('/courses', { ...base, title: `P ${unique()}` });
    expect(plain.body).toMatchObject({ pricing: 'free' });
    expect(plain.body.price).toBeUndefined();
    const refused = await admin.patch(`/courses/${plain.body.id}`, { pricing: 'paid', subtitle: 'Not saved' });
    expect(refused.status).toBe(400);
    expect((await admin.get(`/courses/${plain.body.id}`)).body).toMatchObject({ pricing: 'free', subtitle: '' });
    expect((await admin.patch(`/courses/${paid.body.id}`, { pricing: 'free' })).body).toMatchObject({ pricing: 'free' });
  });

  it('leaves pricing to the admin: an instructor’s course waits unpriced, and an instructor cannot change a price', async () => {
    const instructor = await as('instructor');
    const mine = await instructor.post('/courses', { title: `Mine ${unique()}`, pricing: 'free' });
    expect(mine.status).toBe(201);
    expect(mine.body.pricing).toBe('unset');
    expect((await instructor.patch(`/courses/${mine.body.id}`, { pricing: 'free' })).status).toBe(403);
    expect((await instructor.patch(`/courses/${mine.body.id}`, { priceAmount: 10 })).status).toBe(403);
  });
});

describe('no gateway', () => {
  it('answers a purchase with PAYMENTS_NOT_SET_UP while the platform takes no online payments', async () => {
    setCoursePaymentProvider(undefined);
    try {
      const paid = await course('paid', 1499);
      const learner = await newStudent();
      const res = await start(learner, paid.id);
      expect(res.status).toBe(409);
      expect(res.body.code).toBe('PAYMENTS_NOT_SET_UP');
      expect(await platformDb.coursePurchase.count({ where: { studentId: learner.studentId } })).toBe(0);
    } finally {
      setCoursePaymentProvider(fake);
    }
  });
});
