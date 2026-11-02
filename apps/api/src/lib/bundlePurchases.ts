import { randomBytes } from 'node:crypto';
import { Prisma, type BundlePurchase as PurchaseRow } from '@prisma/client';
import { allocateByWeight, type BundlePurchaseView } from '@syniastrolms/domain';
import type { Request } from 'express';

import { recordAuditLog } from './audit.js';
import { bundleOffer } from './bundles.js';
import { providerForPurchase, saleProvider } from './coursePayments.js';
import { nextOrderNumber } from './coursePurchases.js';
import { db } from './db.js';
import { ApiError, badRequest, conflict, notFound } from './errors.js';
import { expiryFor, learnerRules } from './learning.js';
import { queueEmail } from './mail.js';
import { observe } from './observe.js';
import { ProviderError, type PaymentProvider, type ProviderPayment } from './paymentProvider.js';
import { currentTenantId, tenant } from './tenancy.js';
import { confirmEnrolment } from '../routes/learning.js';

/*
 * A learner buying a course bundle (docs/17). Built beside lib/coursePurchases.ts on the same promises: the server prices the
 * order, only the gateway's own word opens anything, and settling is idempotent however many of the confirmation, the
 * webhook, a status check and the recovery job bring the same payment.
 *
 * The gateway's order and payment live on `BundlePurchase`. An enrolment in a paid course must point at a paid purchase of
 * that course (Enrollment_purchase_paid_*), so settling gives each course a child `CoursePurchase` with provider `bundle`
 * and its share of the charge. The shares add up to exactly what was charged, so sales figures and receipts read as usual.
 *
 * The tenancy checks read committed rows, so the children are committed first (still unpaid), and then one transaction
 * claims the payment, marks them paid and opens the enrolments. A crash between the two leaves an unpaid order the next
 * check settles.
 *
 * A bundle earns no affiliate volume: it cannot hold an eligible course, no purchase hook runs for its children, and
 * `recordMlmOrder` refuses them. Coupons apply to single courses only. A refund covers the whole bundle.
 */

/** How long an unpaid order is offered again to the same learner before a fresh one is made. */
export const BUNDLE_ORDER_TTL_MS = 30 * 60_000;

/** The `provider` of a course's share of a bundle order: no gateway has heard of it, so nothing may ask one about it. */
export const BUNDLE_SHARE_PROVIDER = 'bundle';

type Terms = { courseId: string; listPrice: number }[];
type Settled = { status: BundlePurchaseView['status'] | 'pending'; enrolled: boolean; message: string };

const termsOf = (row: Pick<PurchaseRow, 'termsJson'>) => JSON.parse(row.termsJson) as Terms;
const isUniqueViolation = (err: unknown) => err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002';

async function heldCourseIds(studentId: string, courseIds: string[]) {
  const rows = await db.enrollment.findMany({ where: { studentId, courseId: { in: courseIds }, status: { not: 'expired' } }, select: { courseId: true } });
  return new Set(rows.map((r) => r.courseId));
}

async function viewOf(row: PurchaseRow): Promise<BundlePurchaseView> {
  const [bundle, held] = await Promise.all([
    db.courseBundle.findUnique({ where: { id: row.bundleId }, select: { slug: true, title: true } }),
    heldCourseIds(
      row.studentId,
      termsOf(row).map((t) => t.courseId),
    ),
  ]);
  return {
    id: row.id,
    orderNumber: row.orderNumber ?? row.id,
    bundleId: row.bundleId,
    bundleSlug: bundle?.slug ?? '',
    bundleTitle: bundle?.title ?? '',
    status: (row.status === 'created' && row.failureMessage ? 'failed' : row.status) as BundlePurchaseView['status'],
    amount: row.amount,
    currency: 'INR',
    enrolled: row.status === 'paid' && !row.refundedAt && termsOf(row).every((t) => held.has(t.courseId)),
    ...(row.failureMessage && row.status !== 'paid' ? { failureMessage: row.failureMessage } : {}),
    ...(row.reviewReason ? { needsReview: true } : {}),
    ...(row.refundedAt ? { refundedAt: row.refundedAt.toISOString() } : {}),
  };
}

/** What this learner may buy now: the bundle on sale, under an academy that lets learners join courses themselves. */
async function sellable(studentId: string, bundleId: string) {
  const offer = await bundleOffer(bundleId);
  if (!offer) throw notFound('Bundle not found.');
  const student = await db.student.findUnique({ where: { id: studentId }, select: { suspended: true, user: { select: { name: true, email: true } } } });
  if (!student) throw notFound('Bundle not found.');
  if (student.suspended) throw conflict('This account is suspended. Contact your admin to continue.');
  const rules = await learnerRules();
  if (rules.enrollmentPolicy !== 'open') throw conflict('Courses here are joined through your admin. Contact them to join these courses.');
  const held = await heldCourseIds(
    studentId,
    offer.terms.map((t) => t.courseId),
  );
  if (held.size === offer.terms.length) throw new ApiError(409, 'You already have every course in this bundle.', undefined, 'ALREADY_ENROLLED');
  return { ...offer, held, student: student.user };
}

/** What the learner would get now: the price, and which courses they already have. Holds nothing. */
export async function quoteBundlePurchase(studentId: string, bundleId: string) {
  const { price, held, charge } = await sellable(studentId, bundleId);
  return { price, charge, alreadyHeldCourseIds: [...held] };
}

/** Opens (or reuses) the learner's order. Nothing the client sends prices it: it names only the bundle. */
export async function startBundlePurchase(studentId: string, bundleId: string) {
  const { title, price, charge, terms, student } = await sellable(studentId, bundleId);
  const now = Date.now();
  const termsJson = JSON.stringify(terms);

  const open = await db.bundlePurchase.findFirst({ where: { studentId, bundleId, status: 'created' } });
  if (open) {
    if (open.amount === charge && open.termsJson === termsJson && open.expiresAt.getTime() > now) return checkoutFor(open, title, student);
    await db.bundlePurchase.updateMany({ where: { id: open.id, status: 'created' }, data: { status: 'expired' } });
  }

  const { provider, environment } = await saleProvider();
  const order = await provider.createPayment({
    amount: charge,
    currency: 'INR',
    receipt: `bp_${randomBytes(9).toString('hex')}`,
    notes: { kind: 'bundle', tenantId: currentTenantId(), bundleId, studentId },
  });
  if (order.amount !== charge || order.currency !== 'INR') {
    observe('payment.unmatched', { scope: 'bundle', reason: 'gateway order amount differs from the price', providerOrderId: order.providerOrderId, bundleId });
    throw new ApiError(502, 'The payment provider answered with a different amount. Nothing was charged. Try again.', undefined, 'PAYMENT_FAILED');
  }
  try {
    const row = await db.bundlePurchase.create({
      data: {
        ...tenant(),
        studentId,
        bundleId,
        amount: charge,
        currency: 'INR',
        price,
        termsJson,
        provider: provider.name,
        environment,
        providerOrderId: order.providerOrderId,
        orderNumber: await nextOrderNumber(),
        expiresAt: new Date(now + BUNDLE_ORDER_TTL_MS),
      },
    });
    return checkoutFor(row, title, student);
  } catch (err) {
    // Two checkouts at once: the other made the open order first. Use it; the order this one made is never paid.
    if (!isUniqueViolation(err)) throw err;
    const winner = await db.bundlePurchase.findFirst({ where: { studentId, bundleId, status: 'created' } });
    if (!winner) throw err;
    return checkoutFor(winner, title, student);
  }
}

async function checkoutFor(row: PurchaseRow, title: string, student: { name: string; email: string }) {
  const provider = await providerForPurchase(row);
  return {
    purchase: await viewOf(row),
    checkout: {
      ...provider.checkoutParams({ providerOrderId: row.providerOrderId, amount: row.amount, currency: row.currency }),
      description: title,
      prefill: { name: student.name, email: student.email },
    },
  };
}

async function ownPurchase(studentId: string, purchaseId: string) {
  const row = await db.bundlePurchase.findFirst({ where: { id: purchaseId, studentId } });
  if (!row) throw notFound('Purchase not found.');
  return row;
}

/** The checkout finished in the browser. Its signature proves only that this payment belongs to this order. */
export async function confirmBundlePurchase(studentId: string, purchaseId: string, input: { paymentId: string; signature: string }) {
  const row = await ownPurchase(studentId, purchaseId);
  if (row.status === 'paid') return { purchase: await viewOf(row), outcome: { status: 'paid', enrolled: true, message: 'You have these courses.' } as Settled };
  const provider = await providerForPurchase(row);
  if (!provider.verifyCheckout({ orderId: row.providerOrderId, paymentId: input.paymentId, signature: input.signature })) {
    observe('payment.unmatched', { scope: 'bundle', reason: 'checkout signature did not verify', purchaseId: row.id, providerPaymentId: input.paymentId });
    throw new ApiError(
      400,
      'This payment could not be verified, so the courses were not opened. If money left your account, it will be confirmed shortly or refunded by your bank.',
      undefined,
      'PAYMENT_FAILED',
    );
  }
  const outcome = await settleBundlePurchase(row, input.paymentId, provider);
  return { purchase: await viewOf(await db.bundlePurchase.findUniqueOrThrow({ where: { id: row.id } })), outcome };
}

/** Where a purchase stands, asking the gateway while it is open, so a closed tab or a late webhook loses nothing. */
export async function bundlePurchaseStatus(studentId: string, purchaseId: string) {
  let row = await ownPurchase(studentId, purchaseId);
  if (row.status !== 'paid') {
    await reconcile(row);
    row = await db.bundlePurchase.findUniqueOrThrow({ where: { id: row.id } });
  }
  return viewOf(row);
}

async function reconcile(row: PurchaseRow) {
  let provider: PaymentProvider;
  let payments: ProviderPayment[];
  try {
    provider = await providerForPurchase(row);
    payments = await provider.listOrderPayments(row.providerOrderId);
  } catch {
    return; // The gateway is unreachable: the order stays as it is, and the next check asks again.
  }
  const taken = payments.find((p) => p.status === 'paid') ?? payments.find((p) => p.status === 'authorized');
  if (taken) return void (await settleBundlePurchase(row, taken.providerPaymentId, provider));
  const latest = payments.at(-1);
  if (latest?.status === 'failed' && !payments.some((p) => p.status === 'pending')) await settleBundlePurchase(row, latest.providerPaymentId, provider);
}

const noteFailure = (id: string, failureCode: string, failureMessage: string) =>
  db.bundlePurchase.updateMany({ where: { id, status: { in: ['created', 'expired'] } }, data: { failureCode, failureMessage } });

/** The one place a payment opens a bundle. Believes only the gateway: the payment must be for this order, for exactly its amount. */
export async function settleBundlePurchase(row: PurchaseRow, providerPaymentId: string, provider: PaymentProvider): Promise<Settled> {
  let payment = await provider.fetchPayment(providerPaymentId);
  if (payment.providerOrderId !== row.providerOrderId) {
    observe('payment.unmatched', { scope: 'bundle', reason: 'payment is for another order', purchaseId: row.id, providerPaymentId });
    throw badRequest('That payment is not for this purchase.');
  }
  if (payment.amount !== row.amount || payment.currency !== row.currency) {
    observe('payment.unmatched', { scope: 'bundle', reason: 'payment amount differs from the purchase', purchaseId: row.id, providerPaymentId });
    const message = 'This payment does not match the bundle price, so the courses were not opened. Contact support.';
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
    await db.bundlePurchase.updateMany({ where: { id: row.id, status: { in: ['created', 'expired'] } }, data: { failureCode: null, failureMessage: null } });
    return { status: 'pending', enrolled: false, message: 'Your payment is being confirmed. The courses open as soon as it is.' };
  }
  if (payment.status === 'failed') {
    const message = payment.failureMessage ?? 'The payment was declined. Nothing was charged. You can try again.';
    await noteFailure(row.id, payment.failureCode ?? 'DECLINED', message);
    return { status: 'failed', enrolled: false, message };
  }
  if (payment.status === 'refunded') {
    observe('payment.unmatched', {
      scope: 'bundle',
      reason: 'payment was refunded at the provider before it was recorded',
      purchaseId: row.id,
      providerPaymentId,
    });
    const message = 'This payment was refunded, so the courses were not opened. You can pay again.';
    await noteFailure(row.id, 'REFUNDED', message);
    return { status: 'failed', enrolled: false, message };
  }
  return markPaid(row, providerPaymentId);
}

/**
 * The child purchases, committed before the money is claimed. The courses the learner does not hold share the charge in
 * proportion to their list prices. Existing children are kept: a retry never re-divides money already divided.
 */
async function ensureChildren(row: PurchaseRow) {
  const existing = await db.coursePurchase.findMany({ where: { bundlePurchaseId: row.id } });
  if (existing.length > 0) return existing;
  const terms = termsOf(row);
  const held = await heldCourseIds(
    row.studentId,
    terms.map((t) => t.courseId),
  );
  const opening = terms.filter((t) => !held.has(t.courseId));
  if (opening.length === 0) return [];
  const shares = allocateByWeight(
    row.amount,
    opening.map((t) => t.listPrice),
  );
  // A learner has one open order per course, and this payment now answers for these courses. A late payment on the old
  // order is still recorded, and flagged because the learner already has the course.
  await db.coursePurchase.updateMany({
    where: { studentId: row.studentId, courseId: { in: opening.map((t) => t.courseId) }, status: 'created' },
    data: { status: 'expired' },
  });
  const orderNumbers = await Promise.all(opening.map(() => nextOrderNumber()));
  await db.$transaction(
    opening.map((t, i) => {
      const reference = `${row.id}:${t.courseId}`;
      return db.coursePurchase.create({
        data: {
          ...tenant(),
          studentId: row.studentId,
          courseId: t.courseId,
          amount: shares[i],
          currency: row.currency,
          listPrice: t.listPrice,
          orderNumber: orderNumbers[i],
          provider: BUNDLE_SHARE_PROVIDER,
          environment: row.environment,
          providerOrderId: reference,
          bundlePurchaseId: row.id,
          expiresAt: new Date(Date.now() + BUNDLE_ORDER_TTL_MS),
        },
      });
    }),
  );
  return db.coursePurchase.findMany({ where: { bundlePurchaseId: row.id } });
}

/** Records the payment and opens every course, together and once. */
async function markPaid(row: PurchaseRow, providerPaymentId: string): Promise<Settled> {
  if (row.status === 'paid' && row.providerPaymentId === providerPaymentId)
    return { status: 'paid', enrolled: true, message: 'Payment confirmed. Your courses are open.' };
  const children = await ensureChildren(row);
  const rules = await learnerRules();
  const opened: string[] = [];
  const result = await db.$transaction(async (tx) => {
    // A deadlock runs this again from the top.
    opened.length = 0;
    const claimed = await tx.bundlePurchase.updateMany({
      where: { id: row.id, status: { in: ['created', 'expired'] }, providerPaymentId: null },
      data: { status: 'paid', providerPaymentId, paidAt: new Date(), failureCode: null, failureMessage: null },
    });
    if (claimed.count !== 1) {
      const now = await tx.bundlePurchase.findUniqueOrThrow({ where: { id: row.id } });
      return now.status === 'paid' && now.providerPaymentId === providerPaymentId ? ('duplicate' as const) : ('second-payment' as const);
    }
    for (const child of children) {
      await tx.coursePurchase.updateMany({
        where: { id: child.id, status: { in: ['created', 'expired'] }, providerPaymentId: null },
        data: { status: 'paid', providerPaymentId: child.providerOrderId, paidAt: new Date(), failureCode: null, failureMessage: null },
      });
      const existing = await tx.enrollment.findUnique({ where: { studentId_courseId: { studentId: row.studentId, courseId: child.courseId } } });
      if (!existing) {
        await tx.enrollment.create({
          data: {
            ...tenant(),
            studentId: row.studentId,
            courseId: child.courseId,
            source: 'purchase',
            purchaseId: child.id,
            expiresAt: expiryFor(new Date(), rules.accessMonths),
          },
        });
      } else if (existing.status === 'expired') {
        await tx.enrollment.update({
          where: { id: existing.id },
          data: { status: 'active', purchaseId: child.id, expiresAt: expiryFor(new Date(), rules.accessMonths) },
        });
      } else {
        // They gained the course after the order was divided (staff added them): recorded and flagged, as for a single course.
        await tx.coursePurchase.update({
          where: { id: child.id },
          data: { reviewReason: 'The learner already had this course when the bundle payment arrived.' },
        });
        continue;
      }
      await tx.course.update({ where: { id: child.courseId }, data: { enrolledCount: { increment: 1 } } });
      opened.push(child.courseId);
    }
    if (children.length === 0)
      await tx.bundlePurchase.update({ where: { id: row.id }, data: { reviewReason: 'The learner already had every course when the payment arrived.' } });
    return 'opened' as const;
  });

  if (result === 'second-payment' || children.length === 0) {
    observe('payment.unmatched', {
      scope: 'bundle',
      reason: 'money taken that opens nothing: refund review needed',
      purchaseId: row.id,
      providerPaymentId,
      tenantId: row.tenantId,
    });
    return { status: 'paid', enrolled: true, message: 'You already have these courses. The platform will review the extra payment.' };
  }
  if (result === 'opened') {
    observe('bundle_purchase.paid', { purchaseId: row.id, bundleId: row.bundleId, tenantId: row.tenantId, amount: row.amount });
    await Promise.all(opened.map((courseId) => confirmEnrolment(row.studentId, courseId, 'purchase').catch(() => undefined)));
  }
  return { status: 'paid', enrolled: true, message: 'Payment confirmed. Your courses are open.' };
}

/** The webhook's question: is this gateway order a bundle's? Settled through the environment it was made in. */
export async function settleBundleFromWebhook(providerName: string, providerOrderId: string, providerPaymentId: string) {
  const row = await db.bundlePurchase.findUnique({ where: { provider_providerOrderId: { provider: providerName, providerOrderId } } });
  if (row) await settleBundlePurchase(row, providerPaymentId, await providerForPurchase(row));
}

/** Every minute: an open order nobody confirmed is asked about again, and closed for reuse once past its time. */
export async function reconcileBundlePurchases(now = new Date()) {
  const open = await db.bundlePurchase.findMany({
    where: { status: 'created', createdAt: { lte: new Date(now.getTime() - 60_000) } },
    orderBy: { createdAt: 'asc' },
    take: 50,
  });
  for (const row of open) await reconcile(row).catch(() => undefined);
  await db.bundlePurchase.updateMany({ where: { status: 'created', expiresAt: { lt: now } }, data: { status: 'expired' } });
}

/* ─── Refunds: always the whole order (docs/16, D-PLAT-12) ─────────────────────── */

const LIVE_REFUND = ['requested', 'pending'];

async function settleRefund(parentId: string, providerRefundId: string | null) {
  const parent = await db.bundlePurchase.findUniqueOrThrow({ where: { id: parentId } });
  const children = await db.coursePurchase.findMany({ where: { bundlePurchaseId: parentId, status: 'paid' } });
  const applied = await db.$transaction(async (tx) => {
    const moved = await tx.bundlePurchase.updateMany({
      where: { id: parentId, refundStatus: { in: LIVE_REFUND } },
      data: { refundStatus: 'succeeded', refundedAt: new Date(), ...(providerRefundId ? { providerRefundId } : {}) },
    });
    if (moved.count !== 1) return false;
    for (const child of children) {
      await tx.coursePurchaseRefund.updateMany({
        where: { purchaseId: child.id, status: { in: LIVE_REFUND } },
        data: { status: 'succeeded', settledAt: new Date(), failureMessage: null },
      });
      await tx.coursePurchase.update({ where: { id: child.id }, data: { refundedAt: new Date() } });
      const enrollment = await tx.enrollment.findFirst({ where: { purchaseId: child.id, status: { not: 'expired' } }, select: { id: true } });
      if (enrollment) {
        await tx.enrollment.update({ where: { id: enrollment.id }, data: { status: 'expired', expiresAt: new Date() } });
        await tx.course.update({ where: { id: child.courseId }, data: { enrolledCount: { decrement: 1 } } });
      }
    }
    await recordAuditLog(
      { type: 'system', job: 'bundle-refund' },
      {
        action: 'bundle_purchase.refund_settled',
        targetType: 'bundle_purchase',
        targetId: parentId,
        meta: { orderNumber: parent.orderNumber, amount: parent.amount },
      },
      tx,
    );
    return true;
  });
  if (!applied) return;
  observe('bundle_purchase.refunded', { purchaseId: parentId, tenantId: parent.tenantId, amount: parent.amount });
  const student = await db.student.findUnique({ where: { id: parent.studentId }, select: { user: { select: { name: true, email: true } } } });
  const bundle = await db.courseBundle.findUnique({ where: { id: parent.bundleId }, select: { title: true } });
  if (student?.user) {
    await queueEmail({
      to: student.user.email,
      name: student.user.name,
      subject: `Your refund for ${bundle?.title ?? 'your bundle'}`,
      templateKey: 'course-refund',
      text: [
        `Hi ${student.user.name.split(' ')[0]},`,
        '',
        `We have refunded your order ${parent.orderNumber ?? ''} for ${bundle?.title ?? 'your bundle'}. Your bank may take a few days to show it.`,
        'Your access to its courses has ended. Your progress is kept if you buy them again.',
      ].join('\n'),
    }).catch(() => undefined);
  }
}

/** Writes the refund's record on the order and on each course's share, before the gateway is asked. */
async function openRefund(
  parent: PurchaseRow,
  children: { id: string; amount: number }[],
  fields: { reason: string; note?: string | null; requestedById?: string | null },
) {
  await db.bundlePurchase.update({ where: { id: parent.id }, data: { refundStatus: 'requested' } });
  for (const child of children) {
    await db.coursePurchaseRefund.create({
      data: {
        ...tenant(),
        purchaseId: child.id,
        amount: child.amount,
        reason: fields.reason,
        note: fields.note ?? null,
        requestedById: fields.requestedById ?? null,
        provider: BUNDLE_SHARE_PROVIDER,
        status: 'requested',
      },
    });
  }
}

const markRefundRows = async (parentId: string, data: { refundStatus: string; providerRefundId?: string | null }, failureMessage: string | null) => {
  const children = await db.coursePurchase.findMany({ where: { bundlePurchaseId: parentId }, select: { id: true } });
  await db.bundlePurchase.update({ where: { id: parentId }, data });
  await db.coursePurchaseRefund.updateMany({
    where: { purchaseId: { in: children.map((c) => c.id) }, status: { in: LIVE_REFUND } },
    data: { status: data.refundStatus, failureMessage },
  });
};

/**
 * The Super Admin refunds a bundle, from any one of its courses' orders. The whole order goes back through the gateway
 * that took the money, and every course it opened closes. Answers the record of the share it was asked from.
 */
export async function refundBundleShare(req: Request, childPurchaseId: string, bundlePurchaseId: string, input: { reason: string; note?: string }) {
  const parent = await db.bundlePurchase.findUniqueOrThrow({ where: { id: bundlePurchaseId } });
  if (parent.status !== 'paid' || !parent.providerPaymentId) throw conflict('Only a paid order can be refunded.');
  if (parent.refundedAt) throw conflict('This bundle has already been refunded.');
  if (parent.refundStatus && LIVE_REFUND.includes(parent.refundStatus)) throw conflict('A refund for this bundle is already under way.');
  const children = await db.coursePurchase.findMany({ where: { bundlePurchaseId, status: 'paid' }, select: { id: true, amount: true } });
  await openRefund(parent, children, { ...input, requestedById: req.auth?.sub ?? null });
  await recordAuditLog(req, {
    action: 'bundle_purchase.refund_requested',
    targetType: 'bundle_purchase',
    targetId: parent.id,
    meta: { reason: input.reason, amount: parent.amount, courses: children.length },
  });

  let settledId: string | null | undefined;
  try {
    const provider = await providerForPurchase(parent);
    const answer = await provider.refundPayment({
      providerPaymentId: parent.providerPaymentId,
      amount: parent.amount,
      notes: { kind: 'bundle', purchaseId: parent.id },
    });
    if (answer.status === 'failed') {
      await markRefundRows(parent.id, { refundStatus: 'failed', providerRefundId: answer.providerRefundId }, 'The gateway refused the refund.');
      throw new ApiError(502, 'The gateway refused the refund. Nothing changed for the learner.', undefined, 'PAYMENT_FAILED');
    }
    if (answer.status === 'succeeded') settledId = answer.providerRefundId;
    else await markRefundRows(parent.id, { refundStatus: 'pending', providerRefundId: answer.providerRefundId }, null);
  } catch (err) {
    if (err instanceof ApiError && err.code === 'PAYMENT_FAILED' && !(err instanceof ProviderError)) throw err;
    // A definite refusal may be tried again. No answer at all may have moved the money, so it stays pending for a person to check.
    const refused = err instanceof ProviderError && err.detail.status !== undefined && err.detail.status >= 400 && err.detail.status < 500;
    await markRefundRows(
      parent.id,
      { refundStatus: refused ? 'failed' : 'pending' },
      refused ? (err as Error).message : 'The gateway gave no clear answer. Check its dashboard before trying anything else.',
    );
    observe('payment.failed', { scope: 'bundle', operation: 'refund', purchaseId: parent.id, refused });
    throw new ApiError(
      502,
      refused
        ? 'The gateway refused the refund. Nothing changed for the learner.'
        : 'The gateway gave no clear answer, so the refund is marked pending. Check its dashboard.',
      undefined,
      'PAYMENT_FAILED',
    );
  }
  // Outside the try: once the gateway has said yes, nothing after this may mark the refund as unanswered.
  if (settledId !== undefined) await settleRefund(parent.id, settledId);
  return db.coursePurchaseRefund.findFirstOrThrow({ where: { purchaseId: childPurchaseId }, orderBy: { createdAt: 'desc' } });
}

/** The gateway's signed word about a refund of a bundle's payment. Answers false when the payment is not a bundle's. */
export async function onBundleRefundEvent(
  provider: PaymentProvider,
  event: { providerRefundId: string; providerPaymentId: string; status: 'pending' | 'succeeded' | 'failed' },
): Promise<boolean> {
  const parent = await db.bundlePurchase.findFirst({ where: { provider: provider.name, providerPaymentId: event.providerPaymentId } });
  if (!parent) return false;
  if (event.status === 'failed') {
    if (parent.refundStatus && LIVE_REFUND.includes(parent.refundStatus))
      await markRefundRows(parent.id, { refundStatus: 'failed' }, 'The gateway reported that the refund failed.');
    return true;
  }
  if (event.status !== 'succeeded' || parent.refundedAt) return true;
  if (parent.refundStatus && LIVE_REFUND.includes(parent.refundStatus)) {
    await settleRefund(parent.id, event.providerRefundId);
    return true;
  }
  // A refund made in the gateway's own dashboard counts only when the whole payment went back; this system has no rule for a part.
  const payment = await provider.fetchPayment(event.providerPaymentId);
  if (payment.status !== 'refunded') {
    await db.bundlePurchase.update({
      where: { id: parent.id },
      data: { reviewReason: 'Part of this payment was refunded at the gateway. Access was left as it is.' },
    });
    observe('payment.unmatched', { scope: 'bundle', reason: 'a part refund made at the gateway', purchaseId: parent.id });
    return true;
  }
  const children = await db.coursePurchase.findMany({ where: { bundlePurchaseId: parent.id, status: 'paid' }, select: { id: true, amount: true } });
  await openRefund(parent, children, { reason: 'Refunded at the gateway' });
  await settleRefund(parent.id, event.providerRefundId);
  return true;
}

/** A dispute the company lost: flagged on the order and its shares, so a person can decide about access. */
export async function onBundleChargeback(provider: PaymentProvider, providerPaymentId: string): Promise<boolean> {
  const parent = await db.bundlePurchase.findFirst({ where: { provider: provider.name, providerPaymentId } });
  if (!parent) return false;
  const reviewReason = 'The gateway reports a lost dispute on this bundle payment. Decide whether the learner keeps access.';
  await db.bundlePurchase.update({ where: { id: parent.id }, data: { chargebackAt: parent.chargebackAt ?? new Date(), reviewReason } });
  await db.coursePurchase.updateMany({ where: { bundlePurchaseId: parent.id }, data: { chargebackAt: parent.chargebackAt ?? new Date(), reviewReason } });
  return true;
}
