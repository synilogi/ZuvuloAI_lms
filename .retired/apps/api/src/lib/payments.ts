import type { Payment as PaymentRow, PaymentMethod as PaymentMethodRow, Refund as RefundRow } from '@prisma/client';

import { BILLING_AUDIT_ACTIONS, recordAuditLog, type AuditActor } from './audit.js';
import { now } from './clock.js';
import { db } from './db.js';
import { badRequest, conflict, forbidden, notFound } from './errors.js';
import { observe } from './observe.js';
import { withinAcademy, type LifecycleActor } from './subscriptions.js';
import { currentContext, runAsPlatform } from './tenancy.js';

/*
 * Payments, refunds and payment methods (subscriptions.md §14, §16, §29) — the only writer of Payment,
 * Refund and PaymentMethod.
 *
 *   - A payment is recorded from a verified provider event and nowhere else. It is written pending, paid
 *     or failed; a pending one settles once; a paid or failed one is never updated or deleted — the
 *     database refuses (triggers). Recording the same provider payment again changes nothing.
 *   - A payment settles its invoice only when it is for exactly the invoice's total, in its currency,
 *     and the invoice is still open. Money the provider reports is always recorded — a payment that does
 *     not match is kept as it happened and leaves the invoice open.
 *   - A refund is a Refund row beside the payment, full or partial, asked for by a super admin with a
 *     reason. The refunds of a payment can never add up to more than it, and the payment row is never
 *     touched: "refunded" and "partially refunded" are read from its refunds.
 *   - A payment method is the provider's reference and masked display data. No function here accepts a
 *     card number. Failures are reported through `observe` (§48), redacted; nothing here logs directly.
 */

export type StoredPaymentStatus = 'pending' | 'paid' | 'failed';
/** As shown: a paid payment reads refunded or partially refunded from its succeeded refunds (§14). */
export type PaymentStatus = StoredPaymentStatus | 'refunded' | 'partially_refunded';

export interface MaskedMethod {
  kind: 'card' | 'upi' | 'netbanking' | 'mandate' | 'invoice';
  brand: string;
  last4?: string;
}

export interface PaymentRecord {
  id: string;
  tenantId: string;
  invoiceId?: string;
  subscriptionId?: string;
  provider: string;
  providerPaymentId: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  /** What has been refunded, and what can still be. Minor units. */
  refunded: number;
  refundable: number;
  failureCode?: string;
  failureMessage?: string;
  method?: MaskedMethod & { display: string };
  paidAt?: string;
  failedAt?: string;
  createdAt: string;
}

export interface RefundRecord {
  id: string;
  paymentId: string;
  amount: number;
  currency: string;
  reason: string;
  status: 'pending' | 'succeeded' | 'failed';
  providerRefundId?: string;
  settledAt?: string;
  createdAt: string;
}

/** "Visa •••• 4242", "UPI" — the most of a payment method anyone ever sees. */
export const displayMethod = (m: MaskedMethod): string => (m.last4 ? `${m.brand} •••• ${m.last4}` : m.brand);

function toPayment(row: PaymentRow, refunds: RefundRow[]): PaymentRecord {
  const refunded = refunds.filter((r) => r.status === 'succeeded').reduce((sum, r) => sum + r.amount, 0);
  const committed = refunds.filter((r) => r.status !== 'failed').reduce((sum, r) => sum + r.amount, 0);
  const stored = row.status as StoredPaymentStatus;
  const status: PaymentStatus = stored !== 'paid' || refunded === 0 ? stored : refunded >= row.amount ? 'refunded' : 'partially_refunded';
  const method = row.methodKind
    ? ({
        kind: row.methodKind as MaskedMethod['kind'],
        brand: row.methodBrand ?? row.methodKind,
        ...(row.methodLast4 ? { last4: row.methodLast4 } : {}),
      } satisfies MaskedMethod)
    : undefined;
  return {
    id: row.id,
    tenantId: row.tenantId,
    ...(row.invoiceId ? { invoiceId: row.invoiceId } : {}),
    ...(row.subscriptionId ? { subscriptionId: row.subscriptionId } : {}),
    provider: row.provider,
    providerPaymentId: row.providerPaymentId,
    amount: row.amount,
    currency: row.currency,
    status,
    refunded,
    refundable: stored === 'paid' ? Math.max(0, row.amount - committed) : 0,
    ...(row.failureCode ? { failureCode: row.failureCode } : {}),
    ...(row.failureMessage ? { failureMessage: row.failureMessage } : {}),
    ...(method ? { method: { ...method, display: displayMethod(method) } } : {}),
    ...(row.paidAt ? { paidAt: row.paidAt.toISOString() } : {}),
    ...(row.failedAt ? { failedAt: row.failedAt.toISOString() } : {}),
    createdAt: row.createdAt.toISOString(),
  };
}

const toRefund = (row: RefundRow): RefundRecord => ({
  id: row.id,
  paymentId: row.paymentId,
  amount: row.amount,
  currency: row.currency,
  reason: row.reason,
  status: row.status as RefundRecord['status'],
  ...(row.providerRefundId ? { providerRefundId: row.providerRefundId } : {}),
  ...(row.settledAt ? { settledAt: row.settledAt.toISOString() } : {}),
  createdAt: row.createdAt.toISOString(),
});

/** Masked display data only: a brand that is a name, and exactly four last digits. Anything card-number-like is refused. */
function maskedMethod(method: MaskedMethod | undefined): MaskedMethod | undefined {
  if (!method) return undefined;
  const brand = method.brand?.trim() ?? '';
  if (!['card', 'upi', 'netbanking', 'mandate', 'invoice'].includes(method.kind)) throw badRequest('Unknown payment method kind.');
  if (!brand || brand.length > 40 || /\d{6,}/.test(brand)) throw badRequest('A payment method brand is a name, e.g. Visa or UPI.');
  if (method.last4 !== undefined && !/^\d{4}$/.test(method.last4)) throw badRequest('Only the last four digits of a card are ever kept.');
  return { kind: method.kind, brand, ...(method.last4 ? { last4: method.last4 } : {}) };
}

async function paymentWithRefunds(id: string): Promise<PaymentRecord> {
  const row = await db.payment.findUnique({ where: { id }, include: { refunds: true } });
  if (!row) throw notFound('Payment not found.');
  return toPayment(row, row.refunds);
}

/* ─── Payments ─────────────────────────────────────────────────────────── */

export interface ProviderPaymentInput {
  invoiceId: string;
  providerPaymentId: string;
  /** What the provider reports it took, in minor units — recorded as it happened, never trusted to settle a different total. */
  amount: number;
  currency: string;
  status: StoredPaymentStatus;
  method?: MaskedMethod;
  failureCode?: string;
  failureMessage?: string;
}

export interface RecordedPayment {
  payment: PaymentRecord;
  /** True when this call settled the invoice. */
  settledInvoice: boolean;
  /** True when the provider payment was already recorded in this state, and nothing changed. */
  duplicate: boolean;
}

/**
 * Records a payment the provider reports, against the invoice it was raised for. Idempotent on
 * (provider, providerPaymentId): the same report twice records once; a pending payment settles once;
 * a paid or failed one is never changed. A paid payment for exactly the invoice's open total settles it.
 */
export async function recordPayment(actor: LifecycleActor, input: ProviderPaymentInput): Promise<RecordedPayment> {
  if (actor.type !== 'provider') throw forbidden('Payments are recorded from verified provider events only.');
  if (!Number.isSafeInteger(input.amount) || input.amount < 0) throw badRequest('A payment amount is a whole number of minor units.');
  if (!['pending', 'paid', 'failed'].includes(input.status)) throw badRequest('Unknown payment status.');
  const method = maskedMethod(input.method);
  const provider = actor.provider;

  return runAsPlatform('recording a provider payment', async () => {
    const invoice = await db.invoice.findUnique({ where: { id: input.invoiceId } });
    if (!invoice) throw notFound('Invoice not found.');
    const existing = await db.payment.findUnique({ where: { provider_providerPaymentId: { provider, providerPaymentId: input.providerPaymentId } } });
    if (existing) {
      if (existing.invoiceId !== invoice.id || existing.amount !== input.amount || existing.currency !== input.currency) {
        throw conflict('That provider payment is already recorded with different details.');
      }
      if (existing.status !== 'pending' || input.status === 'pending')
        return { payment: await paymentWithRefunds(existing.id), settledInvoice: false, duplicate: true };
    }

    const at = now();
    const settled = await withinAcademy(invoice.tenantId, () =>
      db.$transaction(async (tx) => {
        const outcome = {
          status: input.status,
          paidAt: input.status === 'paid' ? at : null,
          failedAt: input.status === 'failed' ? at : null,
          failureCode: input.status === 'failed' ? (input.failureCode ?? null) : null,
          failureMessage: input.status === 'failed' ? (input.failureMessage ?? null) : null,
        };
        const payment = existing
          ? await tx.payment.update({ where: { id: existing.id }, data: outcome })
          : await tx.payment.create({
              data: {
                tenantId: invoice.tenantId,
                invoiceId: invoice.id,
                subscriptionId: invoice.subscriptionId,
                provider,
                providerPaymentId: input.providerPaymentId,
                amount: input.amount,
                currency: input.currency,
                methodKind: method?.kind ?? null,
                methodBrand: method?.brand ?? null,
                methodLast4: method?.last4 ?? null,
                ...outcome,
              },
            });
        const settles = payment.status === 'paid' && invoice.status === 'open' && payment.amount === invoice.total && payment.currency === invoice.currency;
        if (settles) await tx.invoice.updateMany({ where: { id: invoice.id, status: 'open' }, data: { status: 'paid', paidAt: at } });

        // The trail (§36), under the provider that reported it. A pending payment is not an outcome yet.
        const money = { tenantId: invoice.tenantId, invoiceId: invoice.id, invoiceNumber: invoice.number, amount: payment.amount, currency: payment.currency };
        if (payment.status === 'paid') {
          await recordAuditLog(
            actor,
            { action: BILLING_AUDIT_ACTIONS.paymentSucceeded, targetType: 'payment', targetId: payment.id, meta: { ...money, settledInvoice: settles } },
            tx,
          );
          if (settles)
            await recordAuditLog(
              actor,
              { action: BILLING_AUDIT_ACTIONS.invoicePaid, targetType: 'invoice', targetId: invoice.id, meta: { ...money, paymentId: payment.id } },
              tx,
            );
        } else if (payment.status === 'failed') {
          const failure = { failureCode: payment.failureCode, failureMessage: payment.failureMessage };
          await recordAuditLog(
            actor,
            { action: BILLING_AUDIT_ACTIONS.paymentFailed, targetType: 'payment', targetId: payment.id, meta: { ...money, ...failure } },
            tx,
          );
          // The invoice stays open for the next attempt; its failed attempt is recorded against it.
          if (invoice.status === 'open')
            await recordAuditLog(
              actor,
              {
                action: BILLING_AUDIT_ACTIONS.invoiceFailed,
                targetType: 'invoice',
                targetId: invoice.id,
                meta: { ...money, paymentId: payment.id, ...failure },
              },
              tx,
            );
        }
        return { id: payment.id, status: payment.status, settles };
      }),
    ).catch(async (err: unknown) => {
      // The same payment recorded twice at the same moment (the browser and the webhook): the other one won the
      // unique key, so this is the duplicate it would have been a moment later.
      if ((err as { code?: string }).code !== 'P2002') throw err;
      return null;
    });
    if (!settled) {
      const winner = await db.payment.findUniqueOrThrow({ where: { provider_providerPaymentId: { provider, providerPaymentId: input.providerPaymentId } } });
      return { payment: await paymentWithRefunds(winner.id), settledInvoice: false, duplicate: true };
    }
    const signal = { paymentId: settled.id, invoiceId: invoice.id, tenantId: invoice.tenantId, provider, amount: input.amount, currency: input.currency };
    if (settled.status === 'failed') observe('payment.failed', { ...signal, failureCode: input.failureCode, failureMessage: input.failureMessage });
    // Money was taken that does not settle the invoice: an operator must reconcile it by hand.
    else if (settled.status === 'paid' && !settled.settles)
      observe('payment.unmatched', { ...signal, invoiceTotal: invoice.total, invoiceCurrency: invoice.currency, invoiceStatus: invoice.status });
    return { payment: await paymentWithRefunds(settled.id), settledInvoice: settled.settles, duplicate: false };
  });
}

export const getPayment = (id: string): Promise<PaymentRecord> => paymentWithRefunds(id);

/** An academy's payments, newest first, each with its refund state. */
export async function listPayments(tenantId: string): Promise<PaymentRecord[]> {
  const rows = await withinAcademy(tenantId, () => db.payment.findMany({ where: { tenantId }, include: { refunds: true }, orderBy: { createdAt: 'desc' } }));
  return rows.map((r) => toPayment(r, r.refunds));
}

/** Every academy's payments for the Super Admin, newest first, filtered by stored status or academy. */
export async function listAllPayments(query: {
  status?: StoredPaymentStatus;
  tenantId?: string;
  page: number;
  pageSize: number;
}): Promise<{ rows: PaymentRecord[]; total: number }> {
  if (currentContext()?.kind !== 'platform') throw forbidden('Only the platform lists every LMS’s payments.');
  const where = { ...(query.status ? { status: query.status } : {}), ...(query.tenantId ? { tenantId: query.tenantId } : {}) };
  const [rows, total] = await Promise.all([
    db.payment.findMany({ where, include: { refunds: true }, orderBy: { createdAt: 'desc' }, skip: (query.page - 1) * query.pageSize, take: query.pageSize }),
    db.payment.count({ where }),
  ]);
  return { rows: rows.map((r) => toPayment(r, r.refunds)), total };
}

/* ─── Refunds ──────────────────────────────────────────────────────────── */

/**
 * A super admin refunds some or all of a paid payment (§25, §29), with a reason. The refund starts pending
 * until the provider settles it; the payment is never touched. Never more than is left of the payment.
 */
export async function refundPayment(actor: AuditActor, paymentId: string, input: { amount?: number; reason: string }): Promise<RefundRecord> {
  if (actor.auth?.role !== 'superadmin' || currentContext()?.kind !== 'platform') throw forbidden('Only a super admin can refund a payment.');
  const reason = input.reason?.trim() ?? '';
  if (reason.length < 3) throw badRequest('Say why the payment is refunded.');
  const payment = await paymentWithRefunds(paymentId);
  if (payment.status === 'pending' || payment.status === 'failed') throw conflict('Only a paid payment can be refunded.');
  const amount = input.amount ?? payment.refundable;
  if (!Number.isSafeInteger(amount) || amount < 1) throw badRequest('A refund is a whole number of minor units, at least 1.');
  if (amount > payment.refundable) throw conflict(`At most ${payment.refundable} can still be refunded on this payment.`);

  const row = await withinAcademy(payment.tenantId, () =>
    db
      .$transaction(async (tx) => {
        const created = await tx.refund.create({
          data: {
            tenantId: payment.tenantId,
            paymentId,
            amount,
            currency: payment.currency,
            reason,
            status: 'pending',
            provider: payment.provider,
            requestedById: actor.auth!.sub,
          },
        });
        await recordAuditLog(
          actor,
          {
            action: BILLING_AUDIT_ACTIONS.paymentRefundRequested,
            targetType: 'payment',
            targetId: paymentId,
            meta: { refundId: created.id, amount, currency: payment.currency, reason, full: amount === payment.amount },
          },
          tx,
        );
        return created;
      })
      .catch((err: unknown) => {
        // Another refund landed between the check above and this one, and the database refused the excess
        // (trigger Refund_within_payment, which Prisma reports as P2003).
        if ((err as { code?: string }).code === 'P2003')
          throw conflict('Another refund on this payment was requested at the same time. Reload it to see what can still be refunded.');
        throw err;
      }),
  );
  return toRefund(row);
}

/** The provider settles a refund. Once. */
export async function settleRefund(
  actor: LifecycleActor,
  refundId: string,
  input: { status: 'succeeded' | 'failed'; providerRefundId?: string; failureMessage?: string },
): Promise<RefundRecord> {
  if (actor.type !== 'provider') throw forbidden('Refunds are settled from verified provider events only.');
  return runAsPlatform('settling a provider refund', async () => {
    const refund = await db.refund.findUnique({ where: { id: refundId } });
    if (!refund) throw notFound('Refund not found.');
    if (refund.status !== 'pending') {
      if (refund.status === input.status) return toRefund(refund);
      throw conflict('This refund is already settled.');
    }
    const row = await withinAcademy(refund.tenantId, () =>
      db.$transaction(async (tx) => {
        const updated = await tx.refund.update({
          where: { id: refundId },
          data: {
            status: input.status,
            settledAt: now(),
            providerRefundId: input.providerRefundId ?? null,
            failureMessage: input.status === 'failed' ? (input.failureMessage ?? null) : null,
          },
        });
        await recordAuditLog(
          actor,
          {
            action: input.status === 'succeeded' ? BILLING_AUDIT_ACTIONS.paymentRefunded : BILLING_AUDIT_ACTIONS.paymentRefundFailed,
            targetType: 'payment',
            targetId: refund.paymentId,
            meta: {
              tenantId: refund.tenantId,
              refundId,
              amount: refund.amount,
              currency: refund.currency,
              ...(input.status === 'failed' ? { failureMessage: input.failureMessage ?? null } : {}),
            },
          },
          tx,
        );
        return updated;
      }),
    );
    if (input.status === 'failed')
      observe('refund.failed', {
        refundId,
        paymentId: refund.paymentId,
        tenantId: refund.tenantId,
        amount: refund.amount,
        failureMessage: input.failureMessage,
      });
    return toRefund(row);
  });
}

export async function listRefunds(paymentId: string): Promise<RefundRecord[]> {
  const rows = await db.refund.findMany({ where: { paymentId }, orderBy: { createdAt: 'asc' } });
  return rows.map(toRefund);
}

/* ─── Payment methods ──────────────────────────────────────────────────── */

export interface PaymentMethodRecord extends MaskedMethod {
  id: string;
  provider: string;
  display: string;
  expMonth?: number;
  expYear?: number;
  isDefault: boolean;
}

const toMethod = (row: PaymentMethodRow): PaymentMethodRecord => {
  const masked: MaskedMethod = { kind: row.kind as MaskedMethod['kind'], brand: row.brand, ...(row.last4 ? { last4: row.last4 } : {}) };
  return {
    id: row.id,
    provider: row.provider,
    ...masked,
    display: displayMethod(masked),
    ...(row.expMonth ? { expMonth: row.expMonth } : {}),
    ...(row.expYear ? { expYear: row.expYear } : {}),
    isDefault: row.isDefault,
  };
};

/**
 * Saves a way to pay, as the provider reports it: its reference and masked display data. Nothing that
 * could be a card number is accepted, and there is no column one could be kept in.
 */
export async function savePaymentMethod(
  actor: LifecycleActor,
  tenantId: string,
  input: MaskedMethod & { providerMethodRef: string; expMonth?: number; expYear?: number; makeDefault?: boolean },
): Promise<PaymentMethodRecord> {
  if (actor.type !== 'provider') throw forbidden('Payment methods are saved from verified provider events only.');
  const masked = maskedMethod(input)!;
  const ref = input.providerMethodRef?.trim() ?? '';
  if (!/^[A-Za-z0-9_\-:.]{3,128}$/.test(ref) || /\d{12,}/.test(ref))
    throw badRequest('A payment method is kept as the provider’s reference, never as a card number.');
  const row = await withinAcademy(tenantId, () =>
    db.$transaction(async (tx) => {
      if (input.makeDefault) await tx.paymentMethod.updateMany({ where: { tenantId, isDefault: true }, data: { isDefault: false } });
      return tx.paymentMethod.create({
        data: {
          tenantId,
          provider: actor.provider,
          providerMethodRef: ref,
          kind: masked.kind,
          brand: masked.brand,
          last4: masked.last4 ?? null,
          expMonth: input.expMonth ?? null,
          expYear: input.expYear ?? null,
          isDefault: Boolean(input.makeDefault),
        },
      });
    }),
  );
  return toMethod(row);
}

export async function listPaymentMethods(tenantId: string): Promise<PaymentMethodRecord[]> {
  const rows = await withinAcademy(tenantId, () => db.paymentMethod.findMany({ where: { tenantId, removedAt: null }, orderBy: { createdAt: 'desc' } }));
  return rows.map(toMethod);
}
