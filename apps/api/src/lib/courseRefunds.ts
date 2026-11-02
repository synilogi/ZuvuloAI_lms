import { runCoursePurchaseChargedBackHooks } from './purchaseHooks.js';
import type { Request } from 'express';
import type { CoursePurchase } from '@prisma/client';

import { recordAuditLog } from './audit.js';
import { providerForPurchase } from './coursePayments.js';
import { db } from './db.js';
import { ApiError, conflict, notFound } from './errors.js';
import { queueEmail } from './mail.js';
import { observe } from './observe.js';
import { ProviderError, type PaymentProvider } from './paymentProvider.js';
import { runCoursePurchaseRefundedHooks } from './purchaseHooks.js';
import { tenant } from './tenancy.js';

/*
 * Refunding a course order (docs/16, D-PLAT-12). Only the Super Admin starts one, and always for the whole order: a partial
 * refund would need a rule for how much CV to take back, and the plan names none.
 *
 *   1. A refund row is written first, so a crash after the gateway's answer leaves a record to reconcile.
 *   2. The gateway is asked. A refusal marks it failed, and another may be tried. An answer that never came, or "pending",
 *      leaves it pending: the money may have moved, so nothing is closed and no second refund can start.
 *   3. When the gateway says it succeeded, here or on its signed webhook, `settleRefund` closes the learner's access, once.
 *      After that commits, the refunded hooks run: the affiliate program takes its CV back (MLM-003).
 *
 * The access a purchase opened ends by expiring its enrolment, the state every learning route already refuses and from which a
 * later purchase reopens the course. The learner's progress is kept.
 */

async function settleRefund(purchase: CoursePurchase, refundId: string, providerRefundId: string | null) {
  const applied = await db.$transaction(async (tx) => {
    const moved = await tx.coursePurchaseRefund.updateMany({
      where: { id: refundId, status: { in: ['requested', 'pending'] } },
      data: { status: 'succeeded', settledAt: new Date(), failureMessage: null, ...(providerRefundId ? { providerRefundId } : {}) },
    });
    if (moved.count !== 1) return false;
    await tx.coursePurchase.update({ where: { id: purchase.id }, data: { refundedAt: new Date() } });
    const enrollment = await tx.enrollment.findFirst({ where: { purchaseId: purchase.id, status: { not: 'expired' } }, select: { id: true } });
    if (enrollment) {
      await tx.enrollment.update({ where: { id: enrollment.id }, data: { status: 'expired', expiresAt: new Date() } });
      await tx.course.update({ where: { id: purchase.courseId }, data: { enrolledCount: { decrement: 1 } } });
    }
    await recordAuditLog(
      { type: 'system', job: 'course-refund' },
      {
        action: 'course_purchase.refund_settled',
        targetType: 'course_purchase',
        targetId: purchase.id,
        meta: { refundId, orderNumber: purchase.orderNumber, amount: purchase.amount },
      },
      tx,
    );
    return true;
  });
  if (!applied) return;
  observe('course_purchase.refunded', { purchaseId: purchase.id, tenantId: purchase.tenantId, amount: purchase.amount });
  await runCoursePurchaseRefundedHooks(purchase);
  const student = await db.student.findUnique({ where: { id: purchase.studentId }, select: { user: { select: { name: true, email: true } } } });
  const course = await db.course.findUnique({ where: { id: purchase.courseId }, select: { title: true } });
  if (student?.user) {
    await queueEmail({
      to: student.user.email,
      name: student.user.name,
      subject: `Your refund for ${course?.title ?? 'your course'}`,
      templateKey: 'course-refund',
      text: [
        `Hi ${student.user.name.split(' ')[0]},`,
        '',
        `We have refunded your order ${purchase.orderNumber ?? ''} for ${course?.title ?? 'your course'}. Your bank may take a few days to show it.`,
        'Your access to the course has ended. Your progress is kept if you buy it again.',
      ].join('\n'),
    }).catch(() => undefined);
  }
}

/** The Super Admin refunds a paid order, in full, through the gateway that took the money. */
export async function refundCoursePurchase(req: Request, purchaseId: string, input: { reason: string; note?: string }) {
  const purchase = await db.coursePurchase.findUnique({ where: { id: purchaseId } });
  if (!purchase) throw notFound('Order not found.');
  if (purchase.status !== 'paid' || !purchase.providerPaymentId) throw conflict('Only a paid order can be refunded.');
  if (purchase.refundedAt) throw conflict('This order has already been refunded.');

  let refund;
  try {
    refund = await db.coursePurchaseRefund.create({
      data: {
        ...tenant(),
        purchaseId,
        amount: purchase.amount,
        reason: input.reason,
        note: input.note ?? null,
        requestedById: req.auth?.sub ?? null,
        provider: purchase.provider,
        status: 'requested',
      },
    });
  } catch (err) {
    if ((err as { code?: string }).code === 'P2002') throw conflict('A refund for this order is already under way.');
    throw err;
  }
  await recordAuditLog(req, {
    action: 'course_purchase.refund_requested',
    targetType: 'course_purchase',
    targetId: purchaseId,
    meta: { refundId: refund.id, reason: input.reason, amount: purchase.amount },
  });

  let provider: PaymentProvider;
  let settledId: string | null | undefined;
  try {
    provider = await providerForPurchase(purchase);
    const answer = await provider.refundPayment({
      providerPaymentId: purchase.providerPaymentId,
      amount: purchase.amount,
      notes: { kind: 'course', purchaseId, refundId: refund.id },
    });
    if (answer.status === 'failed') {
      await db.coursePurchaseRefund.update({
        where: { id: refund.id },
        data: { status: 'failed', providerRefundId: answer.providerRefundId, failureMessage: 'The gateway refused the refund.' },
      });
      throw new ApiError(502, 'The gateway refused the refund. Nothing changed for the learner.', undefined, 'PAYMENT_FAILED');
    }
    if (answer.status === 'succeeded') settledId = answer.providerRefundId;
    else await db.coursePurchaseRefund.update({ where: { id: refund.id }, data: { status: 'pending', providerRefundId: answer.providerRefundId } });
  } catch (err) {
    if (err instanceof ApiError && err.code === 'PAYMENT_FAILED' && !(err instanceof ProviderError)) throw err;
    // A definite refusal may be tried again. No answer at all may have moved the money, so it stays pending for a person to check.
    const refused = err instanceof ProviderError && err.detail.status !== undefined && err.detail.status >= 400 && err.detail.status < 500;
    await db.coursePurchaseRefund.update({
      where: { id: refund.id },
      data: refused
        ? { status: 'failed', failureMessage: err.message }
        : { status: 'pending', failureMessage: 'The gateway gave no clear answer. Check its dashboard before trying anything else.' },
    });
    observe('payment.failed', { scope: 'course', operation: 'refund', purchaseId, refused });
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
  if (settledId !== undefined) await settleRefund(purchase, refund.id, settledId);
  return db.coursePurchaseRefund.findUniqueOrThrow({ where: { id: refund.id } });
}

/**
 * The gateway's signed word about a refund. One we started is settled by its id. One made in the gateway's own dashboard is
 * recorded only when the gateway says the whole payment was refunded; a part refund is flagged for a person, since this system
 * refunds whole orders only and has no rule for the CV of a part.
 */
export async function onGatewayRefundEvent(
  provider: PaymentProvider,
  event: { providerRefundId: string; providerPaymentId: string; status: 'pending' | 'succeeded' | 'failed'; refundRef?: string },
) {
  const purchase = await db.coursePurchase.findFirst({ where: { provider: provider.name, providerPaymentId: event.providerPaymentId } });
  if (!purchase) return;
  const known =
    (await db.coursePurchaseRefund.findFirst({ where: { purchaseId: purchase.id, providerRefundId: event.providerRefundId } })) ??
    (event.refundRef ? await db.coursePurchaseRefund.findFirst({ where: { id: event.refundRef, purchaseId: purchase.id } }) : null);
  if (event.status === 'failed') {
    if (known && known.status !== 'succeeded')
      await db.coursePurchaseRefund.update({
        where: { id: known.id },
        data: { status: 'failed', failureMessage: 'The gateway reported that the refund failed.' },
      });
    return;
  }
  if (event.status !== 'succeeded') return;
  if (known?.status === 'failed') {
    // Money moved after we recorded a refusal: a person must look, because the access and the CV are still as they were.
    await db.coursePurchase.update({
      where: { id: purchase.id },
      data: {
        reviewReason: 'The gateway refunded this order after reporting that the refund had failed. Refund it here to close access and take back the CV.',
      },
    });
    observe('payment.unmatched', { scope: 'course', reason: 'a refund succeeded after failing', purchaseId: purchase.id });
    return;
  }
  if (known) return settleRefund(purchase, known.id, event.providerRefundId);
  if (purchase.refundedAt) return;
  const payment = await providerForPurchase(purchase).then((p) => p.fetchPayment(event.providerPaymentId));
  if (payment.status !== 'refunded') {
    await db.coursePurchase.update({
      where: { id: purchase.id },
      data: { reviewReason: 'Part of this payment was refunded at the gateway. Access and CV were left as they are.' },
    });
    observe('payment.unmatched', { scope: 'course', reason: 'a part refund made at the gateway', purchaseId: purchase.id });
    return;
  }
  // The whole payment has gone back: a refund we started and lost track of is this one.
  const open = await db.coursePurchaseRefund.findFirst({ where: { purchaseId: purchase.id, status: { in: ['requested', 'pending'] } } });
  if (open) return settleRefund(purchase, open.id, event.providerRefundId);
  const row = await db.coursePurchaseRefund.create({
    data: {
      ...tenant(),
      purchaseId: purchase.id,
      amount: purchase.amount,
      reason: 'Refunded at the gateway',
      provider: purchase.provider,
      providerRefundId: event.providerRefundId,
      status: 'pending',
    },
  });
  await settleRefund(purchase, row.id, event.providerRefundId);
}

/** A dispute the company lost. The volume is reversed once, and the order is flagged so a person can decide about access (docs/15 §6.8). */
export async function onGatewayChargeback(provider: PaymentProvider, providerPaymentId: string): Promise<void> {
  const purchase = await db.coursePurchase.findFirst({ where: { provider: provider.name, providerPaymentId } });
  if (!purchase) return;
  await db.coursePurchase.update({
    where: { id: purchase.id },
    data: {
      chargebackAt: purchase.chargebackAt ?? new Date(),
      reviewReason: 'The gateway reports a lost dispute on this payment. Affiliate volume was reversed; decide whether the learner keeps access.',
    },
  });
  await runCoursePurchaseChargedBackHooks(purchase, provider.name);
}
