import { createHash } from 'node:crypto';

import type { WebhookEvent as WebhookEventRow } from '@prisma/client';

import { settleProviderPayment } from './checkout.js';
import { db } from './db.js';
import { writeJson, readJson } from './json.js';
import { describeError, observe, webhookFailed } from './observe.js';
import { BILLING_AUDIT_ACTIONS, recordAuditLog } from './audit.js';
import { gatewaysWithCredentials, providerFor, webhookVerifiers } from './paymentGateways.js';
import { WebhookPayloadError, type PaymentProvider, type ProviderWebhookEvent } from './paymentProvider.js';
import { settleRefund } from './payments.js';
import { runAsPlatform } from './tenancy.js';

/*
 * Provider webhooks (subscriptions.md §17, §18; SAAS-010). Every delivery, in order:
 *
 *   1. verify the signature over the exact bytes received — an unsigned or mis-signed webhook is refused
 *      with 401 and nothing is stored;
 *   2. validate the payload and identify the event (the adapter maps the provider's shape);
 *   3. enforce idempotency — one `WebhookEvent` per (provider, providerEventId), so a redelivery repeats no
 *      side effect; a replay of the same body under another event id is caught by its hash;
 *   4. persist the receipt — ids and the body's SHA-256 only, never the payer's details;
 *   5. update internal state through the services that own it, each in its own transaction: the payment
 *      and the invoice it settles together (`recordPayment`), the subscription's move with its lifecycle
 *      event (`transition`) — and every step is idempotent, so a retry after a failure finishes the work
 *      without doing any of it twice;
 *   6. record who did it: the provider, on the audit trail and the lifecycle log;
 *   7. answer: 200 when the event is handled (or already was, or is not one the platform acts on); 500 when
 *      processing failed, so the provider delivers it again.
 *
 * The payment a webhook names is read back from the provider before anything is recorded
 * (`settleProviderPayment`): even a signed webhook is not taken as the account of the payment itself.
 */

export interface WebhookResult {
  status: number;
  body: { received: boolean; duplicate?: boolean; outcome?: string; message?: string };
}

const sha256 = (raw: Buffer) => createHash('sha256').update(raw).digest('hex');

/** The event's ids and reported state — what the receipt keeps. Never contact or card data. */
function referenceOf(event: ProviderWebhookEvent) {
  if (event.kind === 'payment') return { paymentId: event.providerPaymentId, ...(event.providerOrderId ? { orderId: event.providerOrderId } : {}) };
  if (event.kind === 'refund')
    return {
      refundId: event.providerRefundId,
      paymentId: event.providerPaymentId,
      status: event.status,
      ...(event.refundRef ? { refundRef: event.refundRef } : {}),
    };
  return {};
}

/** A webhook refused before processing, on the audit trail as the provider it claimed to be — no body, no header. */
const auditRejected = (provider: PaymentProvider, reason: string) =>
  runAsPlatform('auditing a rejected webhook', () =>
    recordAuditLog(
      { type: 'provider', provider: provider.name },
      { action: BILLING_AUDIT_ACTIONS.webhookRejected, targetType: 'webhook', meta: { provider: provider.name, reason } },
    ),
  );

/**
 * Receives one webhook delivery for `providerName` — the gateway named by the URL the gateway itself was given,
 * verified with that gateway's own webhook secret (SAAS-017). A gateway that is not configured here is not
 * found, whether or not it is the active one: a gateway that is no longer active still reports on the payments
 * it took. `raw` is the body exactly as it arrived.
 */
export async function receiveWebhook(providerName: string, raw: Buffer, headers: Record<string, string | undefined>): Promise<WebhookResult> {
  // One verifier per environment with credentials: test and live webhooks share the URL, each signed with its
  // own environment's webhook secret.
  const verifiers = await webhookVerifiers(providerName);
  if (!verifiers.length) return { status: 404, body: { received: false, message: 'Not found.' } };

  // 1. Signature, over the exact bytes. Nothing unsigned is stored or read further.
  const provider = verifiers.find((v) => v.verifyWebhook(raw, headers[v.webhookSignatureHeader]));
  if (!provider) {
    const first = verifiers[0]!;
    webhookFailed(first.name, 'signature did not verify', { eventId: first.webhookEventIdHeader ? headers[first.webhookEventIdHeader] : undefined });
    await auditRejected(first, 'signature did not verify');
    return { status: 401, body: { received: false, message: 'The webhook signature did not verify.' } };
  }

  // 2. Payload and event.
  let parsed: ReturnType<PaymentProvider['parseWebhook']>;
  try {
    parsed = provider.parseWebhook(JSON.parse(raw.toString('utf8')), headers);
  } catch (err) {
    const message = err instanceof WebhookPayloadError ? err.message : 'The webhook body is not valid JSON.';
    webhookFailed(provider.name, 'payload rejected', { detail: message });
    await auditRejected(provider, 'payload rejected');
    return { status: 400, body: { received: false, message } };
  }
  const { eventId, event } = parsed;
  const payloadHash = sha256(raw);

  return runAsPlatform('a provider webhook is matched to the academy it concerns', async () => {
    // 3 and 4. Idempotency and the receipt.
    const receipt = await claim(provider, eventId, event, payloadHash);
    if (receipt.kind === 'done') return { status: 200, body: { received: true, duplicate: true, outcome: receipt.row.status } };
    // The same event is being processed by another delivery right now. Not a success — the provider tries
    // again later and then finds it done — and never processed twice at once.
    if (receipt.kind === 'busy') return { status: 409, body: { received: true, duplicate: true, message: 'This event is being processed.' } };
    const row = receipt.row;

    // A replay: the same signed body again under a new event id. Its effects already happened.
    const replayed = await db.webhookEvent.findFirst({
      where: { provider: provider.name, payloadHash, id: { not: row.id }, status: { in: ['processed', 'ignored'] } },
    });
    if (replayed) {
      await finish(row, 'ignored', `A replay of event ${replayed.providerEventId}.`);
      return { status: 200, body: { received: true, duplicate: true, outcome: 'ignored' } };
    }

    // 5 and 6. State, through the services that own it.
    try {
      const outcome = await dispatch(provider.name, event);
      await finish(row, outcome.status, outcome.note);
      await recordAuditLog(
        { type: 'provider', provider: provider.name, reference: eventId },
        {
          action: BILLING_AUDIT_ACTIONS.webhookAccepted,
          targetType: 'webhook',
          targetId: row.id,
          meta: { provider: provider.name, eventType: event.eventType, outcome: outcome.status },
        },
      );
      return { status: 200, body: { received: true, outcome: outcome.status, ...(outcome.note ? { message: outcome.note } : {}) } };
    } catch (err) {
      const reason = describeError(err).message;
      await finish(row, 'failed', reason);
      webhookFailed(provider.name, 'processing failed', { eventId, eventType: event.eventType, error: describeError(err) });
      return { status: 500, body: { received: true, outcome: 'failed', message: 'The event could not be processed. It will be retried.' } };
    }
  });
}

/** How long a receipt may sit in `received` before it is taken to be a crashed attempt and retried. */
const IN_FLIGHT_MS = 2 * 60_000;

/**
 * Takes the event for processing. A new event is stored as received. One already processed or ignored is
 * done. One still in flight — received moments ago by another delivery — is busy. One that failed, or that
 * has sat in `received` too long (the attempt crashed), is taken again: safe, because every step of
 * processing is idempotent.
 */
async function claim(
  provider: PaymentProvider,
  eventId: string,
  event: ProviderWebhookEvent,
  payloadHash: string,
): Promise<{ kind: 'new' | 'retry'; row: WebhookEventRow } | { kind: 'done' | 'busy'; row: WebhookEventRow }> {
  const key = { provider_providerEventId: { provider: provider.name, providerEventId: eventId } };
  try {
    const row = await db.webhookEvent.create({
      data: { provider: provider.name, providerEventId: eventId, eventType: event.eventType, payloadHash, referenceJson: writeJson(referenceOf(event)) },
    });
    return { kind: 'new', row };
  } catch (err) {
    if ((err as { code?: string }).code !== 'P2002') throw err;
    const existing = await db.webhookEvent.findUniqueOrThrow({ where: key });
    if (existing.status === 'processed' || existing.status === 'ignored') return { kind: 'done', row: existing };
    if (existing.status === 'received' && Date.now() - existing.receivedAt.getTime() < IN_FLIGHT_MS) return { kind: 'busy', row: existing };
    // Taken only if still as it was read, so two retries cannot both take it.
    const taken = await db.webhookEvent.updateMany({
      where: { id: existing.id, attempts: existing.attempts, status: existing.status },
      data: { attempts: existing.attempts + 1 },
    });
    if (taken.count !== 1) return { kind: 'busy', row: existing };
    return { kind: 'retry', row: await db.webhookEvent.findUniqueOrThrow({ where: { id: existing.id } }) };
  }
}

async function finish(row: WebhookEventRow, status: 'processed' | 'ignored' | 'failed', note?: string) {
  await db.webhookEvent.update({
    where: { id: row.id },
    data: { status, note: note ?? null, processedAt: status === 'failed' ? null : new Date() },
  });
}

/** What the event means for the platform's records. */
async function dispatch(name: string, event: ProviderWebhookEvent): Promise<{ status: 'processed' | 'ignored'; note?: string }> {
  if (event.kind === 'payment') {
    if (!event.providerOrderId) return { status: 'ignored', note: 'The payment is not for a checkout order.' };
    const order = await db.paymentOrder.findUnique({
      where: { provider_providerOrderId: { provider: name, providerOrderId: event.providerOrderId } },
    });
    if (!order) return { status: 'ignored', note: 'The payment is for an order the platform did not open.' };
    // Read back with the credentials the order was created with (SAAS-017), whatever the gateway uses now.
    const provider = await providerFor(order.provider, order.environment);
    const outcome = await settleProviderPayment(provider, event.providerPaymentId, order);
    return { status: 'processed', note: outcome.message };
  }
  if (event.kind === 'refund') {
    if (event.status === 'pending') return { status: 'ignored', note: 'The refund is not settled yet.' };
    const refund = event.refundRef
      ? await db.refund.findUnique({ where: { id: event.refundRef } })
      : await db.refund.findFirst({ where: { provider: name, providerRefundId: event.providerRefundId } });
    if (!refund) return { status: 'ignored', note: 'The refund is not one the platform asked for.' };
    const payment = await db.payment.findUnique({ where: { id: refund.paymentId } });
    if (!payment || payment.provider !== name || payment.providerPaymentId !== event.providerPaymentId) {
      observe('payment.unmatched', { provider: name, reason: 'refund event names another payment', refundId: refund.id });
      return { status: 'ignored', note: 'The refund event names a different payment.' };
    }
    if (refund.status !== 'pending' && refund.status !== event.status) return { status: 'ignored', note: `The refund is already ${refund.status}.` };
    await settleRefund({ type: 'provider', provider: name, reference: event.providerRefundId }, refund.id, {
      status: event.status,
      providerRefundId: event.providerRefundId,
    });
    return { status: 'processed' };
  }
  return { status: 'ignored', note: `The platform does not act on ${event.eventType}.` };
}

/** The event a receipt recorded, rebuilt from the ids it kept — enough to process it again. */
function eventOf(row: WebhookEventRow): ProviderWebhookEvent {
  const ref = readJson<Record<string, string>>(row.referenceJson, {});
  if ((row.eventType.startsWith('payment.') || row.eventType === 'order.paid') && ref.paymentId) {
    return { kind: 'payment', eventType: row.eventType, providerPaymentId: ref.paymentId, ...(ref.orderId ? { providerOrderId: ref.orderId } : {}) };
  }
  if (row.eventType.startsWith('refund.') && ref.refundId && ref.paymentId) {
    return {
      kind: 'refund',
      eventType: row.eventType,
      providerRefundId: ref.refundId,
      providerPaymentId: ref.paymentId,
      status: (ref.status as 'pending' | 'succeeded' | 'failed') ?? 'pending',
      ...(ref.refundRef ? { refundRef: ref.refundRef } : {}),
    };
  }
  return { kind: 'other', eventType: row.eventType };
}

/** A failed event, or one left `received` by an attempt that died, is retried at most this many times. */
export const WEBHOOK_MAX_ATTEMPTS = 10;

/**
 * The webhook-retry job (SAAS-012): processes again every event whose processing failed, or that an attempt
 * left in `received` and abandoned, from the ids its receipt kept. Each is taken by compare-and-set, so two
 * runs never process one together, and processing is idempotent, so a retry never repeats an effect.
 * Returns how many events it finished.
 */
export async function retryFailedWebhooks(): Promise<{ retried: number; failed: number }> {
  let retried = 0;
  let failed = 0;
  // Each gateway's events are retried through that gateway — the one that sent them, active or not.
  for (const name of await gatewaysWithCredentials()) {
    const run = await retryFor(name);
    retried += run.retried;
    failed += run.failed;
  }
  return { retried, failed };
}

async function retryFor(name: string): Promise<{ retried: number; failed: number }> {
  const stale = new Date(Date.now() - IN_FLIGHT_MS);
  const due = await db.webhookEvent.findMany({
    where: {
      provider: name,
      attempts: { lt: WEBHOOK_MAX_ATTEMPTS },
      OR: [{ status: 'failed' }, { status: 'received', receivedAt: { lt: stale } }],
    },
    orderBy: { receivedAt: 'asc' },
    take: 100,
  });
  let retried = 0;
  let failed = 0;
  for (const row of due) {
    const taken = await db.webhookEvent.updateMany({ where: { id: row.id, attempts: row.attempts, status: row.status }, data: { attempts: row.attempts + 1 } });
    if (taken.count !== 1) continue;
    try {
      const outcome = await dispatch(name, eventOf(row));
      await finish(row, outcome.status, outcome.note);
      retried += 1;
    } catch (err) {
      await finish(row, 'failed', describeError(err).message);
      webhookFailed(name, 'retry failed', { eventId: row.providerEventId, attempt: row.attempts + 1, error: describeError(err) });
      failed += 1;
    }
  }
  return { retried, failed };
}

/** Recent webhook receipts for the Super Admin, newest first, with the ids each named. */
export async function listWebhookEvents(query: { status?: WebhookEventRow['status']; page: number; pageSize: number }) {
  const where = query.status ? { status: query.status } : {};
  const [rows, total] = await Promise.all([
    db.webhookEvent.findMany({ where, orderBy: [{ receivedAt: 'desc' }, { id: 'desc' }], skip: (query.page - 1) * query.pageSize, take: query.pageSize }),
    db.webhookEvent.count({ where }),
  ]);
  return {
    rows: rows.map((r) => ({
      id: r.id,
      provider: r.provider,
      providerEventId: r.providerEventId,
      eventType: r.eventType,
      status: r.status,
      attempts: r.attempts,
      note: r.note ?? undefined,
      reference: readJson<Record<string, string>>(r.referenceJson, {}),
      receivedAt: r.receivedAt.toISOString(),
      processedAt: r.processedAt?.toISOString(),
    })),
    total,
  };
}
