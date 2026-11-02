import { createHash, randomBytes } from 'node:crypto';
import { Prisma, type CoursePurchase as PurchaseRow } from '@prisma/client';
import { chargeOf, courseSale, type CoursePricing, type CoursePurchase, type CourseQuote } from '@syniastrolms/domain';

import { settleBundleFromWebhook } from './bundlePurchases.js';
import { redeemCoupon, resolveCoupon } from './coupons.js';
import { onGatewayChargeback, onGatewayRefundEvent } from './courseRefunds.js';

import { providerForPurchase, saleProvider, verifyCourseWebhook } from './coursePayments.js';
import { db } from './db.js';
import { ApiError, badRequest, conflict, notFound } from './errors.js';
import { expiryFor, learnerRules } from './learning.js';
import { observe } from './observe.js';
import { runCoursePurchasePaidHooks, runCoursePurchaseSettledHooks } from './purchaseHooks.js';
import type { PaymentProvider, ProviderPayment } from './paymentProvider.js';
import { currentTenantId, runInTenant, tenant } from './tenancy.js';
import { workspaceId } from './requestContext.js';
import { confirmEnrolment } from '../routes/learning.js';

/*
 * A learner buying a paid course (decided 2026-10-23, re-pointed 1 Nov 2026: the money settles to the platform's own
 * gateway account — docs/16, D-PLAT-07; the price is all-inclusive; a course whose price no admin chose is not for sale).
 *
 *   1. `startCoursePurchase` — the server prices the course, checks the learner may have it, and opens one gateway
 *      order for exactly that amount. A second request while that order is open gets the same order.
 *   2. The learner pays in the gateway's checkout.
 *   3. `confirmCoursePurchase` (the browser or app, with the gateway's signature), the gateway's signed webhook
 *      (`receiveCoursePaymentWebhook`), a status check (`coursePurchaseStatus`) or the recovery job — whichever comes
 *      first — hands the payment id to `settle`, which believes only what the gateway itself reports, server to server.
 *   4. `settle` marks the purchase paid and opens the enrolment in one transaction, once.
 *
 * Guarantees, each held by the database as well as by this code:
 *   - amount, currency, learner, course and order are fixed when the order is made (trigger CoursePurchase_terms_fixed);
 *   - a purchase is paid by one payment, and stays paid (CoursePurchase_paid_is_final; unique (provider, payment id));
 *   - a gateway order belongs to one purchase (unique (provider, order id)), and a learner has at most one open order
 *     for a course (partial unique index);
 *   - an enrolment can point only at a paid purchase of that learner, that course and that academy
 *     (Enrollment_purchase_paid_*), and a learner has one enrolment per course (unique (student, course));
 *   - nobody enrols themselves in a paid course for free (Enrollment_paid_course_not_self, and `selfEnrol`).
 * A failed attempt does not close the order: the learner can try again on it. Refunds are in lib/courseRefunds.ts.
 */

/** How long an unpaid order is offered again to the same learner before a fresh one is made. */
export const PURCHASE_ORDER_TTL_MS = 30 * 60_000;

type Settled = { status: CoursePurchase['status'] | 'pending'; enrolled: boolean; message: string };

const purchaseRequired = (message: string) => new ApiError(409, message, undefined, 'COURSE_NOT_FOR_SALE');

/** The learner's view of a purchase. */
async function viewOf(row: PurchaseRow): Promise<CoursePurchase> {
  const [course, enrollment] = await Promise.all([
    db.course.findUnique({ where: { id: row.courseId }, select: { title: true } }),
    db.enrollment.findUnique({ where: { studentId_courseId: { studentId: row.studentId, courseId: row.courseId } }, select: { status: true } }),
  ]);
  return {
    id: row.id,
    orderNumber: row.orderNumber ?? row.id,
    courseId: row.courseId,
    courseTitle: course?.title ?? '',
    // A declined attempt leaves the order open to pay again; until then the learner sees it as failed (and retryable).
    status: (row.status === 'created' && row.failureMessage ? 'failed' : row.status) as CoursePurchase['status'],
    amount: row.amount,
    currency: 'INR',
    listPrice: row.listPrice,
    ...(row.discountAmount ? { discountAmount: row.discountAmount } : {}),
    ...(row.couponCode ? { couponCode: row.couponCode } : {}),
    ...(row.refundedAt ? { refundedAt: row.refundedAt.toISOString() } : {}),
    enrolled: Boolean(enrollment && enrollment.status !== 'expired'),
    ...(row.failureMessage && row.status !== 'paid' ? { failureMessage: row.failureMessage } : {}),
    ...(row.reviewReason ? { needsReview: true } : {}),
    createdAt: row.createdAt.toISOString(),
    ...(row.paidAt ? { paidAt: row.paidAt.toISOString() } : {}),
    // A bundle's share has no gateway payment of its own to quote.
    ...(row.status === 'paid' && row.providerPaymentId && !row.bundlePurchaseId ? { paymentReference: row.providerPaymentId } : {}),
  };
}

/** Whether the learner holds the course now — an enrolment that has not expired. */
const holds = async (studentId: string, courseId: string) => {
  const row = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId, courseId } }, select: { status: true } });
  return Boolean(row && row.status !== 'expired');
};

/**
 * What the learner may buy: a published, listed, paid course of this academy, which they do not already hold, under
 * an academy that lets learners join courses themselves. Answers the price the server charges.
 */
async function sellable(studentId: string, courseId: string) {
  const course = await db.course.findUnique({
    where: { id: courseId },
    select: { id: true, title: true, status: true, visibility: true, pricing: true, priceAmount: true, priceCurrency: true, salePrice: true },
  });
  // Another academy's course, an unknown id, a draft and a private course are all the same "not found".
  if (!course || course.status !== 'published' || course.visibility === 'private') throw notFound('Course not found.');
  const sale = courseSale({
    pricing: course.pricing as CoursePricing,
    price: course.priceAmount != null ? { amount: course.priceAmount, currency: course.priceCurrency as 'INR' } : undefined,
    salePrice: course.salePrice ?? undefined,
  });
  if (sale.kind === 'free') throw conflict('This course is free. Enrol in it instead.');
  if (sale.kind === 'unavailable') throw purchaseRequired('This course isn’t open for enrolment yet. Contact support.');
  const student = await db.student.findUnique({ where: { id: studentId }, select: { suspended: true, user: { select: { name: true, email: true } } } });
  if (!student) throw notFound('Course not found.');
  if (student.suspended) throw conflict('This account is suspended. Contact your admin to continue.');
  const rules = await learnerRules();
  if (rules.enrollmentPolicy === 'approval') throw conflict('Enrolment needs approval — ask an instructor or your admin to add you to the course.');
  if (rules.enrollmentPolicy === 'invite') throw conflict('Courses here are joined by invitation. Contact your admin to join the course.');
  if (await holds(studentId, courseId)) throw new ApiError(409, 'You already have this course.', undefined, 'ALREADY_ENROLLED');
  return { course, price: sale.price, listPrice: sale.listPrice ?? sale.price.amount, charge: chargeOf(sale.price), student: student.user };
}

/** The next order number: `ORD-YYYY-NNNNNN`, unique for good. A number lost to a failed checkout is simply skipped. */
export async function nextOrderNumber(at = new Date()) {
  const year = at.getFullYear();
  const row = await db.orderSequence.upsert({ where: { year }, create: { year, last: 1 }, update: { last: { increment: 1 } } });
  return `ORD-${year}-${String(row.last).padStart(6, '0')}`;
}

/** What the learner would pay now, with a coupon if they typed one. Refuses as buying would; nothing is held. */
export async function quoteCoursePurchase(studentId: string, courseId: string, couponCode?: string): Promise<CourseQuote> {
  const { listPrice, charge } = await sellable(studentId, courseId);
  const applied = couponCode ? await resolveCoupon(couponCode, { courseId, studentId, charge }) : null;
  const discount = applied?.discount ?? 0;
  return { listPrice, charge, discount, total: charge - discount, ...(applied ? { couponCode: applied.coupon.code } : {}) };
}

const isUniqueViolation = (err: unknown) => err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002';

/**
 * Opens (or reuses) the learner's order for a paid course. The amount is the server's: nothing the client sends
 * prices it, and the client names only the course.
 */
export async function startCoursePurchase(studentId: string, courseId: string, couponCode?: string) {
  const { course, price, listPrice, charge: gross, student } = await sellable(studentId, courseId);
  const now = Date.now();

  const open = await db.coursePurchase.findFirst({ where: { studentId, courseId, status: 'created', bundlePurchaseId: null } });
  // The learner's own open order holds no place against them, so reusing it is not refused for the coupon it holds.
  const applied = couponCode ? await resolveCoupon(couponCode, { courseId, studentId, charge: gross, ignorePurchaseId: open?.id }) : null;
  const discount = applied?.discount ?? 0;
  const charge = gross - discount;
  if (open) {
    // Still good: same price, same coupon, not stale. Otherwise it is closed for new checkouts (a payment that still
    // arrives on it is recorded all the same) and a fresh order is made at today's price.
    if (open.amount === charge && open.currency === price.currency && open.couponId === (applied?.coupon.id ?? null) && open.expiresAt.getTime() > now)
      return checkoutFor(open, course.title, student);
    await db.coursePurchase.updateMany({ where: { id: open.id, status: 'created' }, data: { status: 'expired' } });
  }

  const { provider, environment } = await saleProvider();
  const receipt = `cp_${randomBytes(9).toString('hex')}`;
  const order = await provider.createPayment({
    amount: charge,
    currency: price.currency,
    receipt,
    notes: { kind: 'course', tenantId: currentTenantId(), courseId, studentId },
  });
  if (order.amount !== charge || order.currency !== price.currency) {
    observe('payment.unmatched', { scope: 'course', reason: 'gateway order amount differs from the price', providerOrderId: order.providerOrderId, courseId });
    throw new ApiError(502, 'The payment provider answered with a different amount. Nothing was charged. Try again.', undefined, 'PAYMENT_FAILED');
  }
  try {
    const row = await db.coursePurchase.create({
      data: {
        ...tenant(),
        studentId,
        courseId,
        amount: charge,
        currency: price.currency,
        listPrice,
        orderNumber: await nextOrderNumber(),
        discountAmount: discount,
        couponId: applied?.coupon.id ?? null,
        couponCode: applied?.coupon.code ?? null,
        provider: provider.name,
        environment,
        providerOrderId: order.providerOrderId,
        expiresAt: new Date(now + PURCHASE_ORDER_TTL_MS),
      },
    });
    return checkoutFor(row, course.title, student);
  } catch (err) {
    // Two checkouts at once: the other made the open order first. Use it; the order this one made is never paid.
    if (!isUniqueViolation(err)) throw err;
    const winner = await db.coursePurchase.findFirst({ where: { studentId, courseId, status: 'created' } });
    if (!winner) throw err;
    return checkoutFor(winner, course.title, student);
  }
}

/** The purchase and what the client needs to open the gateway's checkout: publishable values only. */
async function checkoutFor(row: PurchaseRow, courseTitle: string, student: { name: string; email: string }) {
  const provider = await providerForPurchase(row);
  return {
    purchase: await viewOf(row),
    checkout: {
      ...provider.checkoutParams({ providerOrderId: row.providerOrderId, amount: row.amount, currency: row.currency }),
      description: courseTitle,
      prefill: { name: student.name, email: student.email },
    },
  };
}

/** The learner's own purchase; another learner's, or another academy's, is "not found". */
async function ownPurchase(studentId: string, purchaseId: string) {
  const row = await db.coursePurchase.findFirst({ where: { id: purchaseId, studentId } });
  if (!row) throw notFound('Purchase not found.');
  return row;
}

/**
 * The browser or app finished the gateway's checkout. Its signature proves only that this payment belongs to this
 * order; `settle` then asks the gateway what actually happened before anything opens.
 */
export async function confirmCoursePurchase(studentId: string, purchaseId: string, input: { paymentId: string; signature: string }) {
  const row = await ownPurchase(studentId, purchaseId);
  const provider = await providerForPurchase(row);
  if (row.status === 'paid') return { purchase: await viewOf(row), outcome: { status: 'paid', enrolled: true, message: 'You have this course.' } as Settled };
  if (!provider.verifyCheckout({ orderId: row.providerOrderId, paymentId: input.paymentId, signature: input.signature })) {
    observe('payment.unmatched', { scope: 'course', reason: 'checkout signature did not verify', purchaseId: row.id, providerPaymentId: input.paymentId });
    throw new ApiError(
      400,
      'This payment could not be verified, so the course was not opened. If money left your account, it will be confirmed shortly or refunded by your bank.',
      undefined,
      'PAYMENT_FAILED',
    );
  }
  const outcome = await settle(row, input.paymentId, provider);
  return { purchase: await viewOf(await db.coursePurchase.findUniqueOrThrow({ where: { id: row.id } })), outcome };
}

/**
 * Where a purchase stands, asking the gateway when it is still open — so a learner whose app closed after paying, or
 * whose webhook is late, sees the course open as soon as the gateway has the money.
 */
export async function coursePurchaseStatus(studentId: string, purchaseId: string) {
  let row = await ownPurchase(studentId, purchaseId);
  if (row.status === 'created' || row.status === 'expired') {
    await reconcile(row);
    row = await db.coursePurchase.findUniqueOrThrow({ where: { id: row.id } });
  }
  return viewOf(row);
}

export async function listCoursePurchases(studentId: string) {
  const rows = await db.coursePurchase.findMany({ where: { studentId }, orderBy: { createdAt: 'desc' }, take: 100 });
  return Promise.all(rows.map(viewOf));
}

/** Asks the gateway for the order's payments, and settles the one that went through, if any. */
async function reconcile(row: PurchaseRow) {
  let provider: PaymentProvider;
  try {
    provider = await providerForPurchase(row);
  } catch {
    return;
  }
  let payments: ProviderPayment[];
  try {
    payments = await provider.listOrderPayments(row.providerOrderId);
  } catch {
    return; // The gateway is unreachable: the purchase stays as it is, and the next check asks again.
  }
  const taken = payments.find((p) => p.status === 'paid') ?? payments.find((p) => p.status === 'authorized');
  if (taken) return void (await settle(row, taken.providerPaymentId, provider));
  // Nothing went through. If the latest attempt was declined (on a hosted page, say, which never calls confirm), the
  // learner sees that, and can pay again on the same order; a pending attempt is left to finish.
  const latest = payments.at(-1);
  if (latest?.status === 'failed' && !payments.some((p) => p.status === 'pending')) await settle(row, latest.providerPaymentId, provider);
}

/**
 * The one place a payment opens a course. Believes only the gateway, server to server: the payment must belong to this
 * purchase's order, for exactly its amount and currency. Idempotent — the same payment settles once, however many of
 * the confirmation, the webhook, a status check and the recovery job bring it.
 */
async function settle(row: PurchaseRow, providerPaymentId: string, provider: PaymentProvider): Promise<Settled> {
  let payment = await provider.fetchPayment(providerPaymentId);
  if (payment.providerOrderId !== row.providerOrderId) {
    observe('payment.unmatched', { scope: 'course', reason: 'payment is for another order', purchaseId: row.id, providerPaymentId });
    throw badRequest('That payment is not for this purchase.');
  }
  if (payment.amount !== row.amount || payment.currency !== row.currency) {
    // Never captured, never opened: the gateway releases an uncaptured authorization by itself.
    observe('payment.unmatched', { scope: 'course', reason: 'payment amount differs from the purchase', purchaseId: row.id, providerPaymentId });
    const message = 'This payment does not match the course price, so the course was not opened. Contact support.';
    await noteFailure(row.id, 'AMOUNT_MISMATCH', message);
    return { status: 'failed', enrolled: false, message };
  }
  if (payment.status === 'authorized') {
    try {
      payment = await provider.capturePayment(providerPaymentId, row.amount, row.currency);
    } catch (err) {
      // The confirmation and the webhook can capture the same payment at once: the loser's capture is refused as done.
      const current = await provider.fetchPayment(providerPaymentId);
      if (current.status !== 'paid') throw err;
      payment = current;
    }
  }
  if (payment.status === 'pending' || payment.status === 'authorized') {
    // A new attempt is under way: an earlier decline no longer describes the purchase.
    await db.coursePurchase.updateMany({ where: { id: row.id, status: { in: ['created', 'expired'] } }, data: { failureCode: null, failureMessage: null } });
    return { status: 'pending', enrolled: false, message: 'Your payment is being confirmed. The course opens as soon as it is.' };
  }
  if (payment.status === 'failed') {
    // The order stays open: the learner can pay again on it. A failure is noted, never final.
    const message = payment.failureMessage ?? 'The payment was declined. Nothing was charged. You can try again.';
    await noteFailure(row.id, payment.failureCode ?? 'DECLINED', message);
    return { status: 'failed', enrolled: false, message };
  }
  if (payment.status === 'refunded') {
    observe('payment.unmatched', {
      scope: 'course',
      reason: 'payment was refunded at the provider before it was recorded',
      purchaseId: row.id,
      providerPaymentId,
    });
    const message = 'This payment was refunded, so the course was not opened. You can pay again.';
    await noteFailure(row.id, 'REFUNDED', message);
    return { status: 'failed', enrolled: false, message };
  }
  return markPaid(row, providerPaymentId);
}

/** Notes why the last attempt opened nothing, on a purchase that is not paid. The order stays open to pay again. */
const noteFailure = (id: string, failureCode: string, failureMessage: string) =>
  db.coursePurchase.updateMany({ where: { id, status: { in: ['created', 'expired'] } }, data: { failureCode, failureMessage } });

/** Records the payment and opens the enrolment, together and once. */
async function markPaid(row: PurchaseRow, providerPaymentId: string): Promise<Settled> {
  const rules = await learnerRules();
  const result = await db.$transaction(async (tx) => {
    // Claimed once: only an unpaid purchase becomes paid, and only with this payment.
    const claimed = await tx.coursePurchase.updateMany({
      where: { id: row.id, status: { in: ['created', 'expired'] }, providerPaymentId: null },
      data: { status: 'paid', providerPaymentId, paidAt: new Date(), failureCode: null, failureMessage: null },
    });
    if (claimed.count !== 1) {
      const now = await tx.coursePurchase.findUniqueOrThrow({ where: { id: row.id } });
      if (now.status === 'paid' && now.providerPaymentId === providerPaymentId) return 'duplicate' as const;
      // A second payment on an order already paid: money taken that opens nothing.
      return 'second-payment' as const;
    }
    // The money was taken at this discount, whatever else this payment turns out to open.
    await redeemCoupon(tx, row);
    const existing = await tx.enrollment.findUnique({ where: { studentId_courseId: { studentId: row.studentId, courseId: row.courseId } } });
    if (!existing) {
      await tx.enrollment.create({
        data: {
          ...tenant(),
          studentId: row.studentId,
          courseId: row.courseId,
          source: 'purchase',
          purchaseId: row.id,
          expiresAt: expiryFor(new Date(), rules.accessMonths),
        },
      });
      await tx.course.update({ where: { id: row.courseId }, data: { enrolledCount: { increment: 1 } } });
      await runCoursePurchasePaidHooks(tx, { ...row, providerPaymentId });
      return 'opened' as const;
    }
    if (existing.status === 'expired') {
      await tx.enrollment.update({
        where: { id: existing.id },
        data: { status: 'active', purchaseId: row.id, expiresAt: expiryFor(new Date(), rules.accessMonths) },
      });
      await tx.course.update({ where: { id: row.courseId }, data: { enrolledCount: { increment: 1 } } });
      await runCoursePurchasePaidHooks(tx, { ...row, providerPaymentId });
      return 'opened' as const;
    }
    // They already had the course (staff added them, or another order was paid first): recorded and flagged.
    await tx.coursePurchase.update({ where: { id: row.id }, data: { reviewReason: 'The learner already had this course when the payment arrived.' } });
    return 'already-held' as const;
  });

  if (result === 'second-payment' || result === 'already-held') {
    observe('payment.unmatched', {
      scope: 'course',
      reason:
        result === 'second-payment'
          ? 'a second payment on a paid course order: refund review needed'
          : 'paid for a course the learner already had: refund review needed',
      purchaseId: row.id,
      providerPaymentId,
      tenantId: row.tenantId,
    });
    return { status: 'paid', enrolled: true, message: 'You already have this course. The platform will review the extra payment.' };
  }
  if (result === 'opened') {
    observe('course_purchase.paid', { purchaseId: row.id, courseId: row.courseId, tenantId: row.tenantId, amount: row.amount });
    await runCoursePurchaseSettledHooks({ ...row, providerPaymentId });
    await confirmEnrolment(row.studentId, row.courseId, 'purchase').catch(() => undefined);
  }
  return { status: 'paid', enrolled: true, message: 'Payment confirmed. The course is open.' };
}

/* ─── The gateway's webhook ─────────────────────────────────────────── */

const payloadHash = (raw: Buffer) => createHash('sha256').update(raw).digest('hex');

/**
 * `POST /webhooks/:provider/courses` — the platform's gateway reporting on the orders learners pay for courses.
 * Untrusted until its signature verifies under the platform's webhook secret for that gateway (test or live). An
 * order that is not a course purchase is acknowledged and ignored: the platform may sell other things on the same
 * account. Runs in the one workspace (docs/16, D-PLAT-01).
 */
export async function receiveCoursePaymentWebhook(providerName: string, raw: Buffer, headers: Record<string, string | undefined>) {
  const tenantId = await workspaceId();
  return runInTenant(tenantId, async () => {
    const provider = await verifyCourseWebhook(providerName, raw, headers);
    if (!provider) {
      observe('webhook.failed', { scope: 'course', provider: providerName, reason: 'signature did not verify', eventId: headers['x-razorpay-event-id'] });
      return { status: 401, body: { message: 'The signature did not verify.' } };
    }
    let parsed;
    try {
      parsed = provider.parseWebhook(JSON.parse(raw.toString('utf8')), headers);
    } catch {
      return { status: 400, body: { message: 'Unreadable webhook.' } };
    }
    const hash = payloadHash(raw);
    // The same signed body under a new event id is a replay: acknowledged, not processed again.
    const replay = await db.coursePaymentEvent.findFirst({ where: { provider: provider.name, payloadHash: hash, NOT: { eventId: parsed.eventId } } });
    if (replay) return { status: 200, body: { received: true, duplicate: true } };
    let event = await db.coursePaymentEvent.findUnique({
      where: { tenantId_provider_eventId: { tenantId, provider: provider.name, eventId: parsed.eventId } },
    });
    if (event?.processedAt) return { status: 200, body: { received: true, duplicate: true } };
    if (!event) {
      try {
        event = await db.coursePaymentEvent.create({
          data: { ...tenant(), provider: provider.name, eventId: parsed.eventId, eventType: parsed.event.eventType, payloadHash: hash },
        });
      } catch (err) {
        // The same event delivered twice at once: the other delivery processes it.
        if (isUniqueViolation(err)) return { status: 200, body: { received: true, duplicate: true } };
        throw err;
      }
    }

    if (parsed.event.kind === 'payment' && parsed.event.eventType === 'payment.dispute.lost') {
      await onGatewayChargeback(provider, parsed.event.providerPaymentId);
    } else if (parsed.event.kind === 'payment' && parsed.event.providerOrderId) {
      const purchase = await db.coursePurchase.findUnique({
        where: { provider_providerOrderId: { provider: provider.name, providerOrderId: parsed.event.providerOrderId } },
      });
      // Settled through the environment the purchase was made in, re-reading the payment from the gateway.
      if (purchase) await settle(purchase, parsed.event.providerPaymentId, await providerForPurchase(purchase));
      else await settleBundleFromWebhook(provider.name, parsed.event.providerOrderId, parsed.event.providerPaymentId);
    }
    if (parsed.event.kind === 'refund') await onGatewayRefundEvent(provider, parsed.event);
    await db.coursePaymentEvent.update({ where: { id: event.id }, data: { processedAt: new Date() } });
    return { status: 200, body: { received: true } };
  });
}

/* ─── Recovery ──────────────────────────────────────────────────────── */

/**
 * Every minute, per academy: an open order nobody confirmed (the app closed, the webhook was lost) is asked about
 * again while it is open, and settled if the gateway has the money; once past its time it is asked one last time and
 * closed for reuse. A payment that arrives later still settles, through the webhook or the learner's status check.
 */
export async function reconcileCoursePurchases(now = new Date()) {
  const open = await db.coursePurchase.findMany({
    where: { status: 'created', bundlePurchaseId: null, createdAt: { lte: new Date(now.getTime() - 60_000) } },
    orderBy: { createdAt: 'asc' },
    take: 50,
  });
  let settled = 0;
  for (const row of open) {
    try {
      await reconcile(row);
      const after = await db.coursePurchase.findUniqueOrThrow({ where: { id: row.id } });
      if (after.status === 'paid') settled++;
    } catch {
      // One bad order never stops the others; it is tried again on the next tick.
    }
  }
  const expired = await db.coursePurchase.updateMany({ where: { status: 'created', expiresAt: { lt: now } }, data: { status: 'expired' } });
  return { checked: open.length, settled, expired: expired.count };
}
