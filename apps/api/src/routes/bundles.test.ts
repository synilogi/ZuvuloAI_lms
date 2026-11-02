import request from 'supertest';
import { defaultMlmPlanTerms } from '@syniastrolms/domain';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { reconcileBundlePurchases } from '../lib/bundlePurchases.js';
import { setCoursePaymentProvider } from '../lib/coursePayments.js';
import { activateMlmPlanVersion, createMlmPlanVersion, setMlmEligibleCourses } from '../lib/mlm/plan.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { FIRST_TENANT_ID, runAsPlatform, runInTenant } from '../lib/tenancy.js';
import { ACADEMY, db, platformDb } from '../test/db.js';
import { FakeProvider } from '../test/fakeProvider.js';
import { app, as, newStudent, unique, type Client } from '../test/helpers.js';

/* Course bundles (docs/17): what may be sold, the money from checkout to enrolment, the refund, and that no affiliate volume ever comes of it. */

type Learner = Awaited<ReturnType<typeof newStudent>>;

let admin: Client;
let owner: Client;
let actor: { auth: { sub: string; role: 'superadmin' } };
let fake: FakeProvider;
let instructorId: string;

const paidCourse = async (price: number) => {
  const created = await admin.post('/courses', {
    title: `Bundle Course ${unique()}`,
    description: 'A course.',
    instructorIds: [instructorId],
    pricing: 'paid',
    priceAmount: price,
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  expect((await admin.post(`/courses/${created.body.id}/publish`)).status).toBe(200);
  return created.body as { id: string; slug: string };
};

const draft = (courseIds: string[], over: Record<string, unknown> = {}) => ({
  title: `Bundle ${unique()}`,
  summary: 'Several courses together.',
  description: '',
  coverUrl: '',
  price: 1500,
  courseIds,
  status: 'published',
  publishAt: null,
  order: 0,
  ...over,
});

const newBundle = async (prices: number[] = [1000, 2000], price = 1500) => {
  const courses = await Promise.all(prices.map(paidCourse));
  const res = await owner.post(
    '/superadmin/sales/bundles',
    draft(
      courses.map((c) => c.id),
      { price },
    ),
  );
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return { bundle: res.body as { id: string; slug: string; separatePrice: number }, courses };
};

const start = async (who: Learner, bundleId: string) => {
  const res = await who.post(`/learning/bundles/${bundleId}/purchase`, {});
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return res.body as { purchase: { id: string; amount: number }; checkout: { orderId: string } };
};

const buy = async (who: Learner, bundleId: string) => {
  const started = await start(who, bundleId);
  const payment = fake.pay(started.checkout.orderId, 'paid');
  const confirmed = await who.post(`/learning/bundle-purchases/${started.purchase.id}/confirm`, { paymentId: payment.paymentId, signature: payment.signature });
  expect(confirmed.status, JSON.stringify(confirmed.body)).toBe(200);
  return { started, payment, confirmed: confirmed.body };
};

beforeAll(async () => {
  admin = await as('admin');
  const email = `bundle-owner-${unique()}@example.test`;
  const provisioned = await provisionSuperAdmin({ email, password: 'bundle-owner-pw-1', name: 'Bundle Owner' });
  owner = await as({ email, password: 'bundle-owner-pw-1' });
  actor = { auth: { sub: provisioned.user.id, role: 'superadmin' } };
  instructorId = (await admin.get('/catalog/instructors')).body[0].id;
  fake = new FakeProvider('razorpay');
  setCoursePaymentProvider(fake);
});

afterAll(() => setCoursePaymentProvider(undefined));

describe('managing bundles', () => {
  it('belongs to the Super Admin alone', async () => {
    const learner = await newStudent();
    expect((await learner.get('/superadmin/sales/bundles')).status).toBe(403);
    expect((await admin.post('/superadmin/sales/bundles', draft([]))).status).toBe(403);
    expect((await request(app).get('/superadmin/sales/bundles')).status).toBe(401);
  });

  it('refuses to publish fewer than two courses, a course not for sale, or a repeat', async () => {
    const one = await paidCourse(1000);
    expect((await owner.post('/superadmin/sales/bundles', draft([one.id]))).status).toBe(400);
    expect((await owner.post('/superadmin/sales/bundles', draft([one.id, one.id]))).status).toBe(400);
    const free = await admin.post('/courses', { title: `Free ${unique()}`, description: 'Free.', instructorIds: [instructorId], pricing: 'free' });
    await admin.post(`/courses/${free.body.id}/publish`);
    expect((await owner.post('/superadmin/sales/bundles', draft([one.id, free.body.id]))).status).toBe(409);
    expect((await owner.post('/superadmin/sales/bundles', draft([one.id], { status: 'draft' }))).status).toBe(201);
  });

  it('shows only what is on sale: a draft, a future date and an unpublished course all stay off the website', async () => {
    const [a, b] = await Promise.all([paidCourse(1000), paidCourse(1000)]);
    const hidden = await owner.post('/superadmin/sales/bundles', draft([a.id, b.id], { status: 'draft' }));
    const later = await owner.post('/superadmin/sales/bundles', draft([a.id, b.id], { publishAt: new Date(Date.now() + 86_400_000).toISOString() }));
    const live = await owner.post('/superadmin/sales/bundles', draft([a.id, b.id]));
    const slugs = async () => ((await request(app).get('/public/bundles')).body as { slug: string }[]).map((x) => x.slug);
    let shown = await slugs();
    expect(shown).toContain(live.body.slug);
    expect(shown).not.toContain(hidden.body.slug);
    expect(shown).not.toContain(later.body.slug);
    expect((await request(app).get(`/public/bundles/${hidden.body.slug}`)).status).toBe(404);
    expect((await admin.post(`/courses/${a.id}/unpublish`)).status).toBeLessThan(500);
    await runInTenant(ACADEMY, () => db.course.update({ where: { id: a.id }, data: { status: 'archived' } }));
    shown = await slugs();
    expect(shown).not.toContain(live.body.slug);
  });

  it('adds up what the courses cost apart, and keeps a bundle with orders from being deleted', async () => {
    const { bundle } = await newBundle([1000, 2000], 1500);
    expect(bundle.separatePrice).toBe(3000);
    const learner = await newStudent();
    await start(learner, bundle.id);
    expect((await owner.delete(`/superadmin/sales/bundles/${bundle.id}`)).status).toBe(409);
    const empty = await newBundle();
    expect((await owner.delete(`/superadmin/sales/bundles/${empty.bundle.id}`)).status).toBe(204);
  });
});

describe('buying a bundle', () => {
  it('charges the server’s price whatever the client sends, and opens nothing before the gateway says so', async () => {
    const { bundle, courses } = await newBundle();
    const learner = await newStudent();
    const res = await learner.post(`/learning/bundles/${bundle.id}/purchase`, { amount: 1, price: 1 });
    expect(res.status).toBe(201);
    expect(res.body.purchase.amount).toBe(150_000);
    expect(await db.enrollment.count({ where: { studentId: learner.studentId, courseId: { in: courses.map((c) => c.id) } } })).toBe(0);
    expect((await learner.post(`/learning/bundles/${bundle.id}/purchase`, {})).body.purchase.id).toBe(res.body.purchase.id);
  });

  it('opens every course on payment, with shares that add up to exactly the charge, once', async () => {
    const { bundle, courses } = await newBundle([1000, 2000, 3333], 999);
    const learner = await newStudent();
    const { started, payment, confirmed } = await buy(learner, bundle.id);
    expect(confirmed.purchase).toMatchObject({ status: 'paid', enrolled: true });
    const children = await db.coursePurchase.findMany({ where: { bundlePurchaseId: started.purchase.id } });
    expect(children).toHaveLength(3);
    expect(children.reduce((sum, c) => sum + c.amount, 0)).toBe(99_900);
    expect(children.every((c) => c.status === 'paid' && c.provider === 'bundle')).toBe(true);
    const enrolled = await db.enrollment.findMany({ where: { studentId: learner.studentId, courseId: { in: courses.map((c) => c.id) } } });
    expect(enrolled.map((e) => e.source)).toEqual(['purchase', 'purchase', 'purchase']);

    // The same payment again, by the browser, changes nothing.
    await learner.post(`/learning/bundle-purchases/${started.purchase.id}/confirm`, { paymentId: payment.paymentId, signature: payment.signature });
    expect(await db.coursePurchase.count({ where: { bundlePurchaseId: started.purchase.id } })).toBe(3);
    const course = await db.course.findUniqueOrThrow({ where: { id: courses[0].id } });
    expect(course.enrolledCount).toBe(1);
    // The learner's own orders list carries a share as an order of the course, with no gateway reference.
    const listed = await learner.get('/learning/purchases');
    expect(listed.body.rows).toHaveLength(3);
    expect(listed.body.rows[0].paymentReference).toBeUndefined();
  });

  it('refuses a forged signature, a payment for another order and a wrong amount', async () => {
    const { bundle } = await newBundle();
    const learner = await newStudent();
    const started = await start(learner, bundle.id);
    const forged = fake.pay(started.checkout.orderId, 'paid');
    expect((await learner.post(`/learning/bundle-purchases/${started.purchase.id}/confirm`, { paymentId: forged.paymentId, signature: 'nope' })).status).toBe(
      400,
    );
    const wrong = fake.pay(started.checkout.orderId, 'paid', { amount: 1 });
    const res = await learner.post(`/learning/bundle-purchases/${started.purchase.id}/confirm`, wrong);
    expect(res.body.outcome.status).toBe('failed');
    expect(await db.coursePurchase.count({ where: { bundlePurchaseId: started.purchase.id } })).toBe(0);
  });

  it('keeps one learner’s order from another', async () => {
    const { bundle } = await newBundle();
    const [buyer, other] = [await newStudent(), await newStudent()];
    const started = await start(buyer, bundle.id);
    expect((await other.get(`/learning/bundle-purchases/${started.purchase.id}`)).status).toBe(404);
  });

  it('skips a course the learner already has, and refuses when they have them all', async () => {
    const { bundle, courses } = await newBundle();
    const learner = await newStudent();
    await runInTenant(ACADEMY, () =>
      db.enrollment.create({ data: { tenantId: ACADEMY, studentId: learner.studentId, courseId: courses[0].id, source: 'admin' } }),
    );
    const quote = await learner.post(`/learning/bundles/${bundle.id}/quote`, {});
    expect(quote.body.alreadyHeldCourseIds).toEqual([courses[0].id]);
    const { started } = await buy(learner, bundle.id);
    const children = await db.coursePurchase.findMany({ where: { bundlePurchaseId: started.purchase.id } });
    expect(children.map((c) => c.courseId)).toEqual([courses[1].id]);
    expect(children[0].amount).toBe(150_000);
    expect((await learner.post(`/learning/bundles/${bundle.id}/purchase`, {})).status).toBe(409);
  });

  it('recovers a payment nobody confirmed', async () => {
    const { bundle } = await newBundle();
    const learner = await newStudent();
    const started = await start(learner, bundle.id);
    fake.pay(started.checkout.orderId, 'paid');
    await runInTenant(ACADEMY, async () => {
      await platformDb.$executeRawUnsafe(`UPDATE BundlePurchase SET createdAt = ? WHERE id = ?`, new Date(Date.now() - 120_000), started.purchase.id);
      await reconcileBundlePurchases();
    });
    expect((await learner.get(`/learning/bundle-purchases/${started.purchase.id}`)).body).toMatchObject({ status: 'paid', enrolled: true });
  });

  it('holds its terms in the database', async () => {
    const { bundle } = await newBundle();
    const learner = await newStudent();
    const started = await start(learner, bundle.id);
    await expect(platformDb.$executeRawUnsafe(`UPDATE \`BundlePurchase\` SET \`amount\` = 1 WHERE \`id\` = ?`, started.purchase.id)).rejects.toThrow(/fixed/);
  });
});

describe('refunding a bundle', () => {
  it('returns the whole order through the gateway, once, and closes every course', async () => {
    const { bundle, courses } = await newBundle();
    const learner = await newStudent();
    const { started, payment } = await buy(learner, bundle.id);
    const child = await db.coursePurchase.findFirstOrThrow({ where: { bundlePurchaseId: started.purchase.id } });
    fake.refundAnswer = { providerRefundId: 'rf_b', status: 'succeeded' };
    const refunded = await owner.post(`/superadmin/sales/orders/${child.id}/refund`, { reason: 'Asked within the window.' });
    expect(refunded.status, JSON.stringify(refunded.body)).toBeLessThan(300);
    expect(fake.refunds.at(-1)).toMatchObject({ providerPaymentId: payment.paymentId, amount: 150_000 });
    const after = await db.enrollment.findMany({ where: { studentId: learner.studentId, courseId: { in: courses.map((c) => c.id) } } });
    expect(after.every((e) => e.status === 'expired')).toBe(true);
    const parent = await db.bundlePurchase.findUniqueOrThrow({ where: { id: started.purchase.id } });
    expect(parent.refundedAt).not.toBeNull();
    expect(await db.coursePurchase.count({ where: { bundlePurchaseId: parent.id, refundedAt: null } })).toBe(0);
    const count = fake.refunds.length;
    expect((await owner.post(`/superadmin/sales/orders/${child.id}/refund`, { reason: 'Again.' })).status).toBe(409);
    expect(fake.refunds.length).toBe(count);
  });

  it('leaves access alone when the gateway refuses, and allows another try', async () => {
    const { bundle, courses } = await newBundle();
    const learner = await newStudent();
    const { started } = await buy(learner, bundle.id);
    const child = await db.coursePurchase.findFirstOrThrow({ where: { bundlePurchaseId: started.purchase.id } });
    fake.refundAnswer = 'error';
    expect((await owner.post(`/superadmin/sales/orders/${child.id}/refund`, { reason: 'Asked.' })).status).toBe(502);
    expect(await db.enrollment.count({ where: { studentId: learner.studentId, courseId: { in: courses.map((c) => c.id) }, status: 'active' } })).toBe(2);
    fake.refundAnswer = { providerRefundId: 'rf_c', status: 'succeeded' };
    expect((await owner.post(`/superadmin/sales/orders/${child.id}/refund`, { reason: 'Asked again.' })).status).toBeLessThan(300);
    expect(await db.enrollment.count({ where: { studentId: learner.studentId, courseId: { in: courses.map((c) => c.id) }, status: 'active' } })).toBe(0);
  });
});

describe('the affiliate program', () => {
  let eligibleId: string;

  beforeAll(async () => {
    eligibleId = (await paidCourse(10_000)).id;
    await runAsPlatform('the bundle tests put a course on the active plan', async () => {
      const active = await platformDb.mlmPlanVersion.findFirst({ where: { status: 'active' } });
      if (active) {
        const ids = JSON.parse(active.eligibleCourseIdsJson) as string[];
        await setMlmEligibleCourses(actor, active.id, [...new Set([...ids, eligibleId])]);
        return;
      }
      const created = await createMlmPlanVersion(actor, { ...defaultMlmPlanTerms(FIRST_TENANT_ID), eligibleCourseIds: [eligibleId] });
      await activateMlmPlanVersion(actor, created.id);
    });
  });

  it('keeps an eligible course out of a bundle', async () => {
    const other = await paidCourse(1000);
    const res = await owner.post('/superadmin/sales/bundles', draft([eligibleId, other.id]));
    expect(res.status).toBe(409);
    expect(res.body.message).toMatch(/affiliate/i);
    expect((await owner.post('/superadmin/sales/bundles', draft([eligibleId, other.id], { status: 'draft' }))).status).toBe(409);
  });

  it('takes a bundle off sale when one of its courses later joins the plan', async () => {
    const { bundle, courses } = await newBundle();
    await runAsPlatform('the test adds a bundled course to the plan', async () => {
      const active = await platformDb.mlmPlanVersion.findFirstOrThrow({ where: { status: 'active' } });
      const ids = JSON.parse(active.eligibleCourseIdsJson) as string[];
      await setMlmEligibleCourses(actor, active.id, [...ids, courses[0].id]);
    });
    expect((await request(app).get(`/public/bundles/${bundle.slug}`)).status).toBe(404);
    const learner = await newStudent();
    expect((await learner.post(`/learning/bundles/${bundle.id}/purchase`, {})).status).toBe(404);
  });

  it('records no order and no volume for a sale made before a course joined the plan', async () => {
    const { bundle, courses } = await newBundle();
    const learner = await newStudent();
    const { started } = await buy(learner, bundle.id);
    await runAsPlatform('the test adds a bundled course to the plan', async () => {
      const active = await platformDb.mlmPlanVersion.findFirstOrThrow({ where: { status: 'active' } });
      const ids = JSON.parse(active.eligibleCourseIdsJson) as string[];
      await setMlmEligibleCourses(actor, active.id, [...ids, courses[0].id]);
    });
    const children = await db.coursePurchase.findMany({ where: { bundlePurchaseId: started.purchase.id }, select: { id: true } });
    expect(await db.mlmOrder.count({ where: { purchaseId: { in: children.map((c) => c.id) } } })).toBe(0);
  });
});
