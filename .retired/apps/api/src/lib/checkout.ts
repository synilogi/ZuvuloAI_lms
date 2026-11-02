import type { Invoice as InvoiceRow, PaymentOrder as PaymentOrderRow } from '@prisma/client';
import type { BillingCycle } from '@syniastrolms/domain';

import { BILLING_AUDIT_ACTIONS, recordAuditLog, type AuditActor, type AuditAttribution } from './audit.js';
import { now } from './clock.js';
import { db } from './db.js';
import { badRequest, conflict, forbidden, notFound } from './errors.js';
import { getBillingProfile } from './billing.js';
import { issueInvoice, supersedeUnpaidInvoice } from './invoices.js';
import { observe } from './observe.js';
import { findProvider, GATEWAY_IDS, providerFor, requireActiveProvider } from './paymentGateways.js';
import { ProviderError, type CheckoutParams, type PaymentProvider, type ProviderPayment } from './paymentProvider.js';
import { recordPayment, refundPayment, settleRefund, type RefundRecord } from './payments.js';
import { confirmPlanChangePayment } from './planChanges.js';
import { planForNewSubscription, resolvePlanVersion } from './plans.js';
import {
  InvalidSubscriptionStateError,
  createSubscription,
  liveSubscription,
  loadSubscriptionRow,
  nextPeriodTerms,
  recordPaymentFailed,
  recordPaymentSucceeded,
  renewsInto,
  transition,
  withinAcademy,
  type LifecycleActor,
} from './subscriptions.js';
import { runAsPlatform } from './tenancy.js';

/*
 * Taking a payment (subscriptions.md §43–§45; SAAS-009), through the `PaymentProvider` interface and nothing
 * else. Which gateway is the backend's decision (SAAS-017): an invoice's first checkout goes through the active
 * gateway and pins the invoice to it; every later step — another checkout for the same invoice, the browser's
 * confirmation, a webhook, a refund — goes through the gateway recorded on the invoice, order or payment,
 * never the one active now. Nothing in a request names a gateway.
 *
 *   tenant asks to pay an open invoice (or an upgrade's quote, which is invoiced first)
 *     → the server takes the amount from the invoice — never from the request — and opens a provider order
 *     → the browser completes the provider's checkout
 *     → the server reads the payment back from the provider, server to server
 *     → the payment is recorded (idempotent on the provider's payment id)
 *     → the invoice settles, and the subscription moves: a trial converts, a period renews, a past-due
 *       subscription recovers, an upgrade applies — or, for a failure, the failure is recorded and a
 *       renewal falls past due (§44).
 *
 * A browser saying "it worked" activates nothing (§43). The checkout's signature proves only that the
 * browser saw a real checkout; what the payment *is* comes from the provider's own answer. The same entry
 * point — `settleProviderPayment` — is what the webhook handler (SAAS-010) calls with the provider's event.
 */

const providerActor = (provider: PaymentProvider, reference: string): LifecycleActor => ({ type: 'provider', provider: provider.name, reference });

/** Who issues an invoice the checkout needs — an upgrade's — when no person is doing it. */
const CHECKOUT_JOB: LifecycleActor = { type: 'system', job: 'checkout' };

export interface CheckoutStart {
  checkout: CheckoutParams;
  invoice: { id: string; number: string; total: number; currency: string };
}

/** The open invoice for an upgrade's quote, issued now if it has not been yet. Once per quote (database). */
async function invoiceForPlanChange(tenantId: string, planChangeId: string): Promise<InvoiceRow> {
  const change = await withinAcademy(tenantId, () => db.planChange.findUnique({ where: { id: planChangeId } }));
  if (!change) throw notFound('Plan change not found.');
  if (change.status !== 'pending_payment') throw new InvalidSubscriptionStateError('This plan change is not waiting for a payment.');
  const existing = () => withinAcademy(tenantId, () => db.invoice.findFirst({ where: { planChangeId, status: 'open' } }));
  const found = await existing();
  if (found) return found;
  try {
    const issued = await runAsPlatform('checkout issues the upgrade’s invoice', () => issueInvoice(CHECKOUT_JOB, { kind: 'plan_change', planChangeId }));
    return (await withinAcademy(tenantId, () => db.invoice.findUniqueOrThrow({ where: { id: issued.id } })))!;
  } catch (err) {
    // Two checkouts at once: the database let one invoice through, and that is the one to pay.
    const raced = await existing();
    if (raced) return raced;
    throw err;
  }
}

/**
 * Opens a checkout for one of the academy's open invoices, or for an upgrade waiting for payment. The
 * amount is the invoice's total, full stop. A checkout already open for the invoice is reused, so
 * asking twice never creates two orders.
 */
export async function startCheckout(
  tenantId: string,
  target: { invoiceId?: string; planChangeId?: string },
  who: AuditAttribution = CHECKOUT_JOB,
): Promise<CheckoutStart> {
  if (Boolean(target.invoiceId) === Boolean(target.planChangeId)) throw badRequest('Say what to pay: one invoice, or one plan change.');
  // Refused before anything is issued when no gateway is active and none is pinned yet.
  if (target.planChangeId) await requireActiveProvider();
  let invoice = target.planChangeId
    ? await invoiceForPlanChange(tenantId, target.planChangeId)
    : await withinAcademy(tenantId, () => db.invoice.findUnique({ where: { id: target.invoiceId! } }));
  if (!invoice) throw notFound('Invoice not found.');
  if (invoice.status !== 'open') throw conflict(invoice.status === 'paid' ? 'This invoice is already paid.' : 'This invoice is void and cannot be paid.');
  // A renewal is paid only while it can still renew: never for a period a cancellation, pause or expiry stopped.
  if (
    invoice.purpose === 'renewal' &&
    invoice.subscriptionId &&
    !renewsInto(await withinAcademy(tenantId, () => loadSubscriptionRow(invoice!.subscriptionId!)), invoice.periodStartAt)
  )
    throw new InvalidSubscriptionStateError('This invoice is for a period the subscription will no longer renew into, so it cannot be paid.');
  const pinned = await gatewayForInvoice(tenantId, invoice, who);
  invoice = pinned.invoice;
  const provider = pinned.provider;

  const summary = { id: invoice.id, number: invoice.number, total: invoice.total, currency: invoice.currency };
  const open = await withinAcademy(tenantId, () =>
    // An open order is reused only in the environment new payments use now.
    db.paymentOrder.findFirst({
      where: { invoiceId: invoice.id, provider: provider.name, environment: provider.environment ?? null, status: 'created' },
      orderBy: { createdAt: 'desc' },
    }),
  );
  if (open)
    return { checkout: provider.checkoutParams({ providerOrderId: open.providerOrderId, amount: open.amount, currency: open.currency }), invoice: summary };

  const order = await provider.createPayment({
    amount: invoice.total,
    currency: invoice.currency,
    receipt: invoice.number,
    notes: { invoiceId: invoice.id, tenantId, invoiceNumber: invoice.number },
  });
  await withinAcademy(tenantId, () =>
    db.$transaction(async (tx) => {
      await tx.paymentOrder.create({
        data: {
          tenantId,
          invoiceId: invoice.id,
          provider: provider.name,
          providerOrderId: order.providerOrderId,
          environment: provider.environment ?? null,
          amount: invoice.total,
          currency: invoice.currency,
          // The server's clock, as every billing time is: the recovery job reads the order's age by it.
          createdAt: now(),
        },
      });
      await recordAuditLog(
        who,
        {
          action: BILLING_AUDIT_ACTIONS.paymentCreated,
          targetType: 'invoice',
          targetId: invoice.id,
          meta: {
            tenantId,
            provider: provider.name,
            environment: provider.environment ?? null,
            providerOrderId: order.providerOrderId,
            amount: invoice.total,
            currency: invoice.currency,
          },
        },
        tx,
      );
    }),
  );
  return { checkout: provider.checkoutParams(order), invoice: summary };
}

/**
 * The gateway an invoice is paid through. An invoice already pinned keeps its gateway, whatever is active now;
 * an unpinned one is pinned, once, to the active gateway (Invoice_fixed lets `provider` be set only from null,
 * so two checkouts at once agree on the first one's choice).
 */
async function gatewayForInvoice(tenantId: string, invoice: InvoiceRow, who: AuditAttribution): Promise<{ invoice: InvoiceRow; provider: PaymentProvider }> {
  if (invoice.provider) return { invoice, provider: await providerFor(invoice.provider) };
  const active = await requireActiveProvider();
  const pinned = await withinAcademy(tenantId, () =>
    db.$transaction(async (tx) => {
      const { count } = await tx.invoice.updateMany({ where: { id: invoice.id, provider: null }, data: { provider: active.name } });
      if (count === 1) {
        await recordAuditLog(
          who,
          { action: BILLING_AUDIT_ACTIONS.paymentProviderSelected, targetType: 'invoice', targetId: invoice.id, meta: { tenantId, provider: active.name } },
          tx,
        );
      }
      return tx.invoice.findUniqueOrThrow({ where: { id: invoice.id } });
    }),
  );
  return { invoice: pinned!, provider: pinned!.provider === active.name ? active : await providerFor(pinned!.provider!) };
}

export interface CheckoutOutcome {
  /** What the provider says the payment is. */
  status: ProviderPayment['status'];
  /** Whether this call settled the invoice. */
  settled: boolean;
  /** Whether the subscription moved as the invoice was for. False with a reason when it could not. */
  applied: boolean;
  message: string;
}

/**
 * The browser finished checkout. Its word is checked twice: the signature must be the provider's for that
 * order and payment, and the payment itself is then read from the provider. Only the provider's answer
 * is recorded. An order that is not the academy's own is not found.
 */
export async function confirmCheckout(
  tenantId: string,
  input: { orderId: string; paymentId: string; signature: string },
  who: AuditAttribution = CHECKOUT_JOB,
): Promise<CheckoutOutcome> {
  // The order is the academy's own, and it names the gateway that created it — the only one that may confirm it.
  const orders = await withinAcademy(tenantId, () => db.paymentOrder.findMany({ where: { tenantId, providerOrderId: input.orderId }, take: 2 }));
  if (orders.length !== 1) throw notFound('Checkout not found.');
  const order = orders[0]!;
  const provider = await providerFor(order.provider, order.environment);
  if (!provider.verifyCheckout(input)) {
    observe('payment.failed', { provider: provider.name, reason: 'checkout signature did not verify', tenantId, orderId: input.orderId });
    throw badRequest('That payment confirmation is not signed by the payment provider. Nothing was recorded.');
  }
  const outcome = await settleProviderPayment(provider, input.paymentId, order);
  await withinAcademy(tenantId, () =>
    recordAuditLog(who, {
      action: BILLING_AUDIT_ACTIONS.paymentVerified,
      targetType: 'invoice',
      targetId: order.invoiceId,
      meta: {
        tenantId,
        provider: provider.name,
        providerOrderId: order.providerOrderId,
        providerPaymentId: input.paymentId,
        status: outcome.status,
        settled: outcome.settled,
      },
    }),
  );
  return outcome;
}

/**
 * Records a payment exactly as the provider reports it, against the order it was for, and moves the
 * subscription the invoice was raised for. Safe to call any number of times for the same payment: the
 * payment is recorded once, the invoice settles once, and the subscription moves once.
 */
export async function settleProviderPayment(provider: PaymentProvider, providerPaymentId: string, order: PaymentOrderRow): Promise<CheckoutOutcome> {
  let payment = await provider.fetchPayment(providerPaymentId);
  if (payment.providerOrderId !== order.providerOrderId) {
    observe('payment.unmatched', { provider: provider.name, reason: 'payment is for another order', providerPaymentId, orderId: order.providerOrderId });
    throw badRequest('That payment is not for this checkout.');
  }
  // A payment already recorded as failed is never changed (the database refuses it), so a late authorization of it
  // (the bank answers after the provider reported the failure) cannot be recorded. It is not captured: the provider
  // releases an uncaptured authorization to the payer, the invoice stays open to pay again, and the platform is told.
  const recordedFailed = await runAsPlatform('checking whether a payment was already recorded as failed', () =>
    db.payment.findFirst({ where: { provider: provider.name, providerPaymentId, status: 'failed' }, select: { id: true } }),
  );
  if (recordedFailed && (payment.status === 'authorized' || payment.status === 'paid')) {
    observe('payment.unmatched', {
      provider: provider.name,
      reason:
        payment.status === 'authorized'
          ? 'authorized after it was recorded as failed: not captured, so the provider releases it'
          : 'captured after it was recorded as failed: refund or reconcile by hand',
      providerPaymentId,
      orderId: order.providerOrderId,
    });
    return {
      status: payment.status,
      settled: false,
      applied: false,
      message:
        payment.status === 'authorized'
          ? 'This payment was declined earlier, so it was not taken. Any hold on the money is released by your bank. Please pay again.'
          : 'This payment was declined earlier and has since gone through. The platform team will review it.',
    };
  }
  // An approved payment is captured for exactly the order's amount; anything else is left as it is.
  if (payment.status === 'authorized' && payment.amount === order.amount && payment.currency === order.currency) {
    try {
      payment = await provider.capturePayment(providerPaymentId, order.amount, order.currency);
    } catch (err) {
      // The browser and the webhook can capture the same payment at once: the loser's capture is refused as already
      // done. The payment as the provider now has it is the answer either way.
      const current = await provider.fetchPayment(providerPaymentId);
      if (current.status !== 'paid') throw err;
      payment = current;
    }
  }
  if (payment.status === 'pending' || payment.status === 'authorized') {
    return {
      status: payment.status,
      settled: false,
      applied: false,
      message: 'The payment is not complete yet. It is recorded when the provider confirms it.',
    };
  }
  // Refunded at the provider (from its dashboard, say) before it was recorded here: the money is back with the payer, so
  // it settles nothing and moves nothing. A payment recorded first and refunded after is a refund, settled by its webhook.
  if (payment.status === 'refunded') {
    observe('payment.unmatched', {
      provider: provider.name,
      reason: 'payment was refunded at the provider',
      providerPaymentId,
      orderId: order.providerOrderId,
    });
    return { status: 'refunded', settled: false, applied: false, message: 'This payment was refunded by the payment provider, so nothing was applied.' };
  }
  const actor = providerActor(provider, providerPaymentId);
  const recorded = await recordPayment(actor, {
    invoiceId: order.invoiceId,
    providerPaymentId,
    amount: payment.amount,
    currency: payment.currency,
    status: payment.status === 'failed' ? 'failed' : 'paid',
    method: payment.method,
    failureCode: payment.failureCode,
    failureMessage: payment.failureMessage,
  });
  const invoice = await runAsPlatform('reading the invoice a payment settled', () => db.invoice.findUniqueOrThrow({ where: { id: order.invoiceId } }));

  // Everything after recording is safe to run again, and runs again on every retry: a webhook redelivered
  // after a crash between the payment and the subscription's move finishes the move, and never repeats it.
  if (payment.status === 'failed') {
    await afterFailure(actor, invoice, payment.failureMessage);
    return { status: 'failed', settled: false, applied: false, message: payment.failureMessage ?? 'The payment was refused. Nothing was charged.' };
  }
  const paidByThis = invoice.status === 'paid' && recorded.payment.status !== 'failed' && recorded.payment.amount === invoice.total;
  if (recorded.settledInvoice || paidByThis) {
    await withinAcademy(order.tenantId, () =>
      db.paymentOrder.updateMany({ where: { id: order.id, status: 'created' }, data: { status: 'paid', providerPaymentId, paidAt: new Date() } }),
    );
    const applied = await afterSettle(actor, invoice);
    if (recorded.settledInvoice) return { status: payment.status, settled: true, ...applied };
    if (applied.applied) return { status: payment.status, settled: false, ...applied };
    return { status: payment.status, settled: false, applied: false, message: 'This payment is already recorded.' };
  }
  // Money that arrived after its invoice was voided (the plan was switched, the subscription cancelled or re-priced
  // while the payment window was open): recorded, but it pays for nothing. Refunding is a super admin's reviewed
  // decision (POST /superadmin/payments/:id/refund) — nothing here, and no cancellation anywhere, refunds by itself.
  if (invoice.status === 'void' && recorded.payment.status === 'paid' && !recorded.duplicate) {
    observe('payment.unmatched', {
      provider: provider.name,
      reason: 'paid against a void invoice: refund review needed',
      providerPaymentId,
      invoiceId: invoice.id,
      tenantId: invoice.tenantId,
    });
    return {
      status: payment.status,
      settled: false,
      applied: false,
      message: 'This payment arrived after the invoice was cancelled, so nothing was applied. The platform team will review it for a refund.',
    };
  }
  return {
    status: payment.status,
    settled: false,
    applied: false,
    message: recorded.duplicate
      ? 'This payment is already recorded.'
      : 'The payment is recorded, but it does not match the invoice. The platform team will reconcile it.',
  };
}

/**
 * The invoice is paid: move the subscription it was for. Idempotent — a move already made is not made
 * again: an applied plan change stays applied, and a renewal happens only while the paid period is still
 * the next one (`periodStartAt` = the subscription's current period end), which the renewal itself moves
 * past. A move the rules no longer allow is reported, not forced.
 */
async function afterSettle(actor: LifecycleActor, invoice: InvoiceRow): Promise<{ applied: boolean; message: string }> {
  try {
    if (invoice.purpose === 'new_subscription') return await activateFirstPurchase(actor, invoice);
    if (invoice.planChangeId) {
      const change = await runAsPlatform('reading the plan change a payment settled', () => db.planChange.findUnique({ where: { id: invoice.planChangeId! } }));
      if (change?.status === 'applied') return { applied: false, message: 'Paid. The new plan already applies.' };
      await confirmPlanChangePayment(actor, invoice.planChangeId);
      return { applied: true, message: 'Paid. The new plan applies now.' };
    }
    if (invoice.subscriptionId) {
      const sub = await loadSubscriptionRow(invoice.subscriptionId);
      const renews = renewsInto(sub, invoice.periodStartAt);
      // A downgrade takes effect at this boundary (D10): renewing now would carry the old plan into the
      // next period and strand the change. The paid invoice waits, and the renewal job renews at the
      // boundary, after the change applies.
      if (renews && sub.status === 'active' && (await nextPeriodTerms(sub)).planVersionId !== sub.planVersionId) {
        return { applied: false, message: 'Paid. The renewal starts at the end of this period, on the plan you moved to.' };
      }
      if (renews) {
        await recordPaymentSucceeded(actor, sub.id);
        return { applied: true, message: sub.status === 'trialing' ? 'Paid. The subscription is active.' : 'Paid. The subscription is renewed.' };
      }
    }
    return { applied: false, message: 'Paid. The invoice is settled.' };
  } catch (err) {
    if (!(err instanceof InvalidSubscriptionStateError)) throw err;
    // Money was taken for a move that can no longer happen (a quote outlived its period, say). It stays
    // recorded against the paid invoice, and the platform decides — usually a refund.
    observe('payment.unmatched', { reason: 'paid invoice could not be applied', invoiceId: invoice.id, tenantId: invoice.tenantId, detail: err.message });
    return { applied: false, message: `Paid, but the change could not be applied: ${err.message} The platform team will follow up.` };
  }
}

/**
 * A first purchase is paid: the academy's subscription starts, active, on exactly the plan version and cycle
 * the invoice sold (SAAS-009). Through the lifecycle's own `createSubscription`, so every SAAS-004 rule holds —
 * one live subscription per academy above all. Idempotent: the subscription records the invoice, uniquely,
 * so a second confirmation or webhook finds it and changes nothing. If the academy was given a subscription
 * some other way before the payment landed, none is added: the payment stays recorded against the paid
 * invoice for the platform to refund or apply.
 */
async function activateFirstPurchase(actor: LifecycleActor, invoice: InvoiceRow): Promise<{ applied: boolean; message: string }> {
  const already = () =>
    runAsPlatform('finding the subscription an invoice bought', () => db.subscription.findUnique({ where: { sourceInvoiceId: invoice.id } }));
  if (await already()) return { applied: false, message: 'Paid. The subscription is already active.' };
  const version = await resolvePlanVersion(invoice.planVersionId!);
  // A trial bought out of (D33): only now that the payment is verified does the trial end, so an unpaid or
  // failed checkout leaves it exactly as it was. Anything else live is not replaced — the payment is then
  // reported unmatched by `afterSettle`, as before.
  const live = await liveSubscription(invoice.tenantId);
  if (live?.status === 'trialing' && actor.type === 'provider') {
    try {
      await transition(actor, live.id, 'cancel_now', () => ({ meta: { convertedByInvoice: invoice.id } }));
    } catch (err) {
      // The confirmation and the webhook for this payment, at once: the other one ended the trial (and may
      // already have started the subscription). Carry on only if the trial is gone.
      if (await already()) return { applied: false, message: 'Paid. The subscription is already active.' };
      if ((await liveSubscription(invoice.tenantId))?.id === live.id) throw err;
    }
  }
  try {
    await createSubscription(actor, {
      tenantId: invoice.tenantId,
      planId: version.plan.id,
      cycle: invoice.billingCycle as BillingCycle,
      start: 'active',
      fromInvoice: invoice.id,
      ...(actor.type === 'provider' ? { provider: { name: actor.provider } } : {}),
    });
    return { applied: true, message: 'Paid. The subscription is active.' };
  } catch (err) {
    // A confirmation and a webhook for the same payment, at the same moment: the unique index let one through.
    if ((err as { code?: string }).code === 'P2002' && (await already())) return { applied: false, message: 'Paid. The subscription is already active.' };
    throw err;
  }
}

/**
 * The academy chooses its first plan (§43; SAAS-009). Only an academy with no live subscription — never
 * subscribed, or its last one cancelled or expired — or one on a free trial, which may buy any plan before the
 * trial ends (D33): the trial stays until the payment is verified, then gives way to the paid subscription.
 * The server takes the plan's current version and prices it (`payableForNewSubscription`, SAAS-007 tax);
 * the request names only the plan and the cycle. One first-purchase invoice is open at a time: asking again
 * for the same plan and cycle reuses it and its checkout; choosing another replaces it, unless a payment on
 * it is already under way. The checkout is the ordinary one — the subscription starts only when the provider
 * confirms the payment.
 */
export async function startFirstPurchase(
  tenantId: string,
  input: { planId: string; cycle: BillingCycle },
  who: AuditAttribution = CHECKOUT_JOB,
): Promise<CheckoutStart> {
  await requireActiveProvider();
  const live = await liveSubscription(tenantId);
  if (live && live.status !== 'trialing') throw new InvalidSubscriptionStateError('This LMS already has a subscription. Change its plan instead.');
  if (!(await getBillingProfile(tenantId))) throw conflict('Add the LMS’s billing address before choosing a plan.');
  const sale = await planForNewSubscription(input.planId, input.cycle);

  const openFirstPurchase = () => withinAcademy(tenantId, () => db.invoice.findFirst({ where: { tenantId, purpose: 'new_subscription', status: 'open' } }));
  let invoice = await openFirstPurchase();
  if (invoice && (invoice.planVersionId !== sale.version.id || invoice.billingCycle !== input.cycle)) {
    await runAsPlatform('replacing an unpaid first purchase', () =>
      supersedeUnpaidInvoice(CHECKOUT_JOB, invoice!.id, 'Replaced: the LMS chose another plan or cycle.'),
    );
    if (await openFirstPurchase()) throw conflict('A payment for the plan chosen earlier is under way. Wait for it to finish, then choose again.');
    invoice = null;
  }
  if (!invoice) {
    try {
      await runAsPlatform('checkout issues the first-purchase invoice', () =>
        issueInvoice(CHECKOUT_JOB, { kind: 'new_subscription', tenantId, planId: input.planId, cycle: input.cycle }),
      );
    } catch (err) {
      // Two choices at once: the database let one invoice through (Invoice_one_open_first_purchase).
      if (!(await openFirstPurchase())) throw err;
    }
    invoice = await openFirstPurchase();
    if (!invoice) throw conflict('The purchase could not be started. Try again.');
  }
  return startCheckout(tenantId, { invoiceId: invoice.id }, who);
}

/**
 * A charge failed (§44): the failure is recorded, and a renewal that failed puts an active subscription past
 * due. Idempotent, and never late: only while the renewal is still unpaid and still the next period — an old
 * failure redelivered after the academy paid moves nothing.
 */
async function afterFailure(actor: LifecycleActor, invoice: InvoiceRow, reason: string | undefined) {
  if (invoice.purpose !== 'renewal' || !invoice.subscriptionId || invoice.status !== 'open') return;
  const sub = await loadSubscriptionRow(invoice.subscriptionId);
  // Paying early with a card that is declined is no overdue renewal: the period already paid runs to its end, and the
  // renewal check at that end decides. Only a failure once the period is over puts the subscription past due.
  if (sub.status === 'active' && invoice.periodStartAt?.getTime() === sub.currentPeriodEndAt.getTime() && sub.currentPeriodEndAt.getTime() <= now().getTime()) {
    await recordPaymentFailed(actor, sub.id, { reason: reason ?? 'The renewal payment failed.', periodEndAt: sub.currentPeriodEndAt });
  }
}

/**
 * A super admin refunds a payment (§29). The refund goes through the gateway that took the payment — never
 * the active one (SAAS-017). When that gateway is one of ours but can no longer be used (its credentials are
 * gone or unreadable), the refund is refused before anything is recorded. Otherwise the refund is recorded
 * first, then asked of the gateway; its answer settles it, and a refusal is recorded as failed. A payment
 * recorded by hand (no gateway of ours) keeps its refund pending for the platform to settle.
 */
export async function refundThroughProvider(actor: AuditActor, paymentId: string, input: { amount?: number; reason: string }): Promise<RefundRecord> {
  const payment = await runAsPlatform('reading the payment to refund', () => db.payment.findUnique({ where: { id: paymentId } }));
  if (!payment) throw notFound('Payment not found.');
  const throughGateway = await tookByGateway(payment.provider);
  // A gateway payment whose gateway cannot be reached for it: a controlled refusal, nothing recorded.
  const provider = throughGateway ? await providerFor(payment.provider, await environmentOf(payment.provider, payment.providerPaymentId)) : null;
  await runAsPlatform('auditing a refund attempt', () =>
    recordAuditLog(actor, {
      action: BILLING_AUDIT_ACTIONS.paymentRefundAttempted,
      targetType: 'payment',
      targetId: paymentId,
      meta: { tenantId: payment.tenantId, provider: payment.provider, amount: input.amount ?? null, throughGateway },
    }),
  );
  const refund = await refundPayment(actor, paymentId, input);
  // Money received by hand is paid back by hand: the refund is settled as the super admin records it.
  if (payment.provider === OFFLINE_PROVIDER)
    return settleRefund({ type: 'provider', provider: OFFLINE_PROVIDER, reference: actor.auth?.sub }, refund.id, { status: 'succeeded' });
  if (!provider) return refund;
  const settleAs = providerActor(provider, payment.providerPaymentId);
  try {
    const answer = await provider.refundPayment({
      providerPaymentId: payment.providerPaymentId,
      amount: refund.amount,
      notes: { refundId: refund.id, reason: input.reason },
    });
    if (answer.status === 'pending') return refund;
    return settleRefund(settleAs, refund.id, { status: answer.status, providerRefundId: answer.providerRefundId });
  } catch (err) {
    // Only a definite refusal is a failed refund. A timeout, a lost connection or the gateway's own error may come
    // after it paid the money back: recorded as failed, the amount would be refundable again — a second refund. Kept
    // pending, it stays committed until the gateway's refund event settles it (the event names it by `refundId`).
    if (!refusedForCertain(err)) {
      observe(
        'refund.failed',
        { provider: payment.provider, operation: 'refund payment', reason: 'outcome unknown, kept pending', refundId: refund.id },
        'error',
      );
      return refund;
    }
    const message = err instanceof Error ? err.message : 'The payment provider refused the refund.';
    return settleRefund(settleAs, refund.id, { status: 'failed', failureMessage: message });
  }
}

/** A refund the gateway answered with a client error (4xx, not a timeout or rate limit): it did not pay anything back. */
function refusedForCertain(err: unknown): boolean {
  const status = err instanceof ProviderError ? err.detail.status : undefined;
  return status !== undefined && status >= 400 && status < 500 && status !== 408 && status !== 429;
}

/**
 * Whether a payment was taken by a gateway (one the registry knows) rather than recorded by hand. A payment
 * recorded by hand names no gateway of ours — `manual`, `bank_transfer`, a test fake no longer installed.
 */
/** The environment of the checkout order a payment settled — whose credentials refund it. */
async function environmentOf(provider: string, providerPaymentId: string): Promise<string | null> {
  const order = await runAsPlatform('finding the order a payment settled', () =>
    db.paymentOrder.findFirst({ where: { provider, providerPaymentId }, select: { environment: true } }),
  );
  return order?.environment ?? null;
}

async function tookByGateway(provider: string): Promise<boolean> {
  return GATEWAY_IDS.includes(provider) || (await findProvider(provider)) !== null;
}

/* ─── Payments received outside the gateway ─────────────────────────── */

/** The provider name a payment received by hand is recorded under. No gateway has it. */
export const OFFLINE_PROVIDER = 'offline';

export const OFFLINE_METHODS = ['bank_transfer', 'cheque', 'cash', 'upi', 'other'] as const;
export type OfflineMethod = (typeof OFFLINE_METHODS)[number];

const OFFLINE_DISPLAY: Record<OfflineMethod, { kind: 'invoice' | 'upi'; brand: string }> = {
  bank_transfer: { kind: 'invoice', brand: 'Bank transfer' },
  cheque: { kind: 'invoice', brand: 'Cheque' },
  cash: { kind: 'invoice', brand: 'Cash' },
  upi: { kind: 'upi', brand: 'UPI' },
  other: { kind: 'invoice', brand: 'Offline payment' },
};

/**
 * A super admin records money the academy paid outside the gateway — a bank transfer, a cheque, cash — for an
 * open invoice's full total (§25). The payment is recorded exactly as a gateway's would be, under `offline` with
 * the bank or receipt reference as its id (so the same reference is never counted twice), and the invoice then
 * moves its subscription as any paid invoice does: a renewal renews, an overdue subscription recovers, a first
 * purchase starts, an upgrade applies. Who recorded it, and their note, are on the audit trail.
 */
export async function recordOfflinePayment(
  actor: AuditActor,
  invoiceId: string,
  input: { method: OfflineMethod; reference: string; note?: string },
): Promise<CheckoutOutcome> {
  if (actor.auth?.role !== 'superadmin') throw forbidden('Only a super admin can record a payment received outside the gateway.');
  if (!OFFLINE_METHODS.includes(input.method)) throw badRequest('Say how the payment was received.');
  const reference = input.reference?.trim() ?? '';
  if (reference.length < 3 || reference.length > 100) throw badRequest('Give the bank, cheque or receipt reference (3–100 characters).');
  const invoice = await runAsPlatform('reading the invoice paid offline', () => db.invoice.findUnique({ where: { id: invoiceId } }));
  if (!invoice) throw notFound('Invoice not found.');
  if (invoice.status !== 'open') throw conflict(invoice.status === 'paid' ? 'This invoice is already paid.' : 'This invoice is void and cannot be paid.');
  if (invoice.purpose === 'renewal' && invoice.subscriptionId) {
    const sub = await runAsPlatform('reading the subscription an invoice renews', () => loadSubscriptionRow(invoice.subscriptionId!));
    if (!renewsInto(sub, invoice.periodStartAt))
      throw new InvalidSubscriptionStateError('This invoice is for a period the subscription will no longer renew into, so it cannot be paid.');
  }

  const providerActorOffline: LifecycleActor = { type: 'provider', provider: OFFLINE_PROVIDER, reference: actor.auth.sub };
  const recorded = await recordPayment(providerActorOffline, {
    invoiceId,
    providerPaymentId: reference,
    amount: invoice.total,
    currency: invoice.currency,
    status: 'paid',
    method: OFFLINE_DISPLAY[input.method],
  }).catch((err: unknown) => {
    if ((err as { status?: number }).status === 409) throw conflict(`A payment with the reference ${reference} is already recorded against another invoice.`);
    throw err;
  });
  await withinAcademy(invoice.tenantId, () =>
    recordAuditLog(actor, {
      action: BILLING_AUDIT_ACTIONS.paymentRecordedOffline,
      targetType: 'invoice',
      targetId: invoiceId,
      meta: {
        tenantId: invoice.tenantId,
        invoiceNumber: invoice.number,
        paymentId: recorded.payment.id,
        method: input.method,
        reference,
        amount: invoice.total,
        currency: invoice.currency,
        ...(input.note?.trim() ? { note: input.note.trim().slice(0, 500) } : {}),
      },
    }),
  );
  if (recorded.duplicate) return { status: 'paid', settled: false, applied: false, message: 'A payment with this reference is already recorded.' };
  const settledInvoice = await runAsPlatform('reading the invoice a payment settled', () => db.invoice.findUniqueOrThrow({ where: { id: invoiceId } }));
  const applied = await afterSettle(providerActorOffline, settledInvoice);
  return { status: 'paid', settled: recorded.settledInvoice, ...applied };
}
