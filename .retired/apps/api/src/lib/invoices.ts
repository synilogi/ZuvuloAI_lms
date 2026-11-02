import { addBillingPeriod, formatMoney, type BillingCycle, type TaxLine } from '@syniastrolms/domain';
import type { Invoice as InvoiceRow } from '@prisma/client';

import { BILLING_AUDIT_ACTIONS, recordAuditLog, type AuditActor } from './audit.js';
import { getBillingProfile, payableForNewSubscription, payableForPlanChange, payableForRenewal, type BillingProfileRecord, type Payable } from './billing.js';
import { noticeForRenewalInvoice } from './billingNotices.js';
import { now } from './clock.js';
import { db } from './db.js';
import { conflict, forbidden, notFound } from './errors.js';
import { writeJson } from './json.js';
import { getPlan, resolvePlanVersion } from './plans.js';
import { loadSubscriptionRow, nextPeriodTerms, withinAcademy, type LifecycleActor } from './subscriptions.js';
import { currentContext } from './tenancy.js';

/*
 * Invoices (subscriptions.md §15) — the only writer of Invoice.
 *
 * An invoice is issued from what `lib/billing.ts` says the academy pays — the stored price of what it is
 * buying, taxed at its billing address — and from nothing a request carries. Its lines, tax lines, totals
 * and the billing address it was sent to are fixed at issue (database triggers), so no later plan edit,
 * price change or change of address rewrites it. Its number comes from a per-year series that only
 * counts up, and is unique in the database. It is paid by a payment (`lib/payments.ts`) or voided by a
 * super admin — never deleted. One live invoice per plan change and per renewal period (unique indexes),
 * so nothing is billed twice.
 */

export type InvoicePurpose = Payable['purpose'];
export type InvoiceStatus = 'open' | 'paid' | 'void';

export interface InvoiceLineItem {
  description: string;
  quantity: number;
  /** Minor units, before tax. */
  unitAmount: number;
  amount: number;
}

export interface InvoiceRecord {
  id: string;
  tenantId: string;
  number: string;
  purpose: InvoicePurpose;
  status: InvoiceStatus;
  subscriptionId?: string;
  planChangeId?: string;
  currency: string;
  subtotal: number;
  taxTotal: number;
  total: number;
  inclusive: boolean;
  lines: InvoiceLineItem[];
  taxLines: TaxLine[];
  billedTo: BillingProfileRecord;
  period?: { start: string; end: string };
  issuedAt: string;
  dueAt: string;
  paidAt?: string;
  voidedAt?: string;
  voidReason?: string;
}

export function toInvoiceRecord(row: InvoiceRow): InvoiceRecord {
  return {
    id: row.id,
    tenantId: row.tenantId,
    number: row.number,
    purpose: row.purpose as InvoicePurpose,
    status: row.status as InvoiceStatus,
    ...(row.subscriptionId ? { subscriptionId: row.subscriptionId } : {}),
    ...(row.planChangeId ? { planChangeId: row.planChangeId } : {}),
    currency: row.currency,
    subtotal: row.subtotal,
    taxTotal: row.taxTotal,
    total: row.total,
    inclusive: row.inclusive,
    lines: JSON.parse(row.linesJson) as InvoiceLineItem[],
    taxLines: JSON.parse(row.taxLinesJson) as TaxLine[],
    billedTo: JSON.parse(row.billedToJson) as BillingProfileRecord,
    ...(row.periodStartAt && row.periodEndAt ? { period: { start: row.periodStartAt.toISOString(), end: row.periodEndAt.toISOString() } } : {}),
    issuedAt: row.issuedAt.toISOString(),
    dueAt: row.dueAt.toISOString(),
    ...(row.paidAt ? { paidAt: row.paidAt.toISOString() } : {}),
    ...(row.voidedAt ? { voidedAt: row.voidedAt.toISOString() } : {}),
    ...(row.voidReason ? { voidReason: row.voidReason } : {}),
  };
}

/** Who issues invoices: the scheduler, a verified provider flow, or a super admin working as the platform. */
function assertIssuer(actor: LifecycleActor) {
  if (actor.type !== 'user') return;
  if (actor.auth.role === 'superadmin' && currentContext()?.kind === 'platform') return;
  throw forbidden('Invoices are issued by the platform.');
}

const cycleWord = (cycle: BillingCycle) => (cycle === 'annual' ? 'annual' : 'monthly');
const day = (d: Date) => d.toISOString().slice(0, 10);

/** What an invoice is issued for. The server works out every figure from it. */
export type InvoiceTarget =
  | { kind: 'renewal'; subscriptionId: string }
  | { kind: 'plan_change'; planChangeId: string }
  | { kind: 'new_subscription'; tenantId: string; planId: string; cycle: BillingCycle };

async function describe(target: InvoiceTarget): Promise<{
  tenantId: string;
  description: string;
  subscriptionId?: string;
  planChangeId?: string;
  period?: { start: Date; end: Date };
}> {
  if (target.kind === 'renewal') {
    const sub = await loadSubscriptionRow(target.subscriptionId);
    // The next period, on the terms it will run on — a scheduled downgrade's, when one takes effect at its start.
    const next = await nextPeriodTerms(sub);
    const version = await resolvePlanVersion(next.planVersionId);
    const cycle = next.cycle;
    const start = sub.currentPeriodEndAt;
    const end = addBillingPeriod(start, cycle);
    return {
      tenantId: sub.tenantId,
      subscriptionId: sub.id,
      description: `${version.plan.name} — ${cycleWord(cycle)} subscription, ${day(start)} to ${day(end)}`,
      period: { start, end },
    };
  }
  if (target.kind === 'plan_change') {
    const change = await db.planChange.findUnique({ where: { id: target.planChangeId } });
    if (!change) throw notFound('Plan change not found.');
    const [from, to] = await Promise.all([resolvePlanVersion(change.fromPlanVersionId), resolvePlanVersion(change.toPlanVersionId)]);
    const credit = `less ${formatMoney(change.credit, change.currency)} unused on ${from.plan.name}`;
    const description =
      change.kind === 'cycle_upgrade'
        ? `${to.plan.name} — annual subscription from the date of payment, ${credit}`
        : `Upgrade to ${to.plan.name} for the rest of the period to ${day(change.periodEndAt)}, ${credit}`;
    return {
      tenantId: change.tenantId,
      subscriptionId: change.subscriptionId,
      planChangeId: change.id,
      description,
      ...(change.kind === 'upgrade' ? { period: { start: change.quotedAt, end: change.periodEndAt } } : {}),
    };
  }
  const plan = await getPlan(target.planId);
  const start = now();
  return {
    tenantId: target.tenantId,
    description: `${plan.name} — ${cycleWord(target.cycle)} subscription, first period`,
    period: { start, end: addBillingPeriod(start, target.cycle) },
  };
}

/**
 * Issues an invoice for `target`, open and due on issue. Refused for an academy with no billing address
 * (no tax could be decided), and — by the database — a second live invoice for the same plan change or
 * renewal period.
 */
export async function issueInvoice(actor: LifecycleActor, target: InvoiceTarget): Promise<InvoiceRecord> {
  assertIssuer(actor);
  const payable =
    target.kind === 'renewal'
      ? await payableForRenewal(target.subscriptionId)
      : target.kind === 'plan_change'
        ? await payableForPlanChange(target.planChangeId)
        : await payableForNewSubscription(target.tenantId, { planId: target.planId, cycle: target.cycle });
  const what = await describe(target);
  const billedTo = await getBillingProfile(what.tenantId);
  if (!billedTo) throw conflict('Add the LMS’s billing address before it can be invoiced.');
  const issuedAt = now();
  const series = `INV-${issuedAt.getUTCFullYear()}`;
  const lines: InvoiceLineItem[] = [{ description: what.description, quantity: 1, unitAmount: payable.net, amount: payable.net }];

  const row = await withinAcademy(what.tenantId, () =>
    db
      .$transaction(async (tx) => {
        // The series only counts up (trigger), so a number handed out is never handed out again.
        const seq = await tx.invoiceSequence.upsert({ where: { series }, create: { series, next: 2 }, update: { next: { increment: 1 } } });
        const number = `${series}-${String(seq.next - 1).padStart(6, '0')}`;
        const created = await tx.invoice.create({
          data: {
            tenantId: what.tenantId,
            number,
            purpose: payable.purpose,
            status: 'open',
            subscriptionId: what.subscriptionId ?? null,
            planChangeId: what.planChangeId ?? null,
            // A first purchase records exactly what it sells (trigger Invoice_sale_on_insert).
            planVersionId: payable.sale?.planVersionId ?? null,
            billingCycle: payable.sale?.cycle ?? null,
            currency: payable.currency,
            subtotal: payable.net,
            taxTotal: payable.tax,
            total: payable.gross,
            inclusive: payable.inclusive,
            taxRuleId: payable.taxRuleId,
            linesJson: writeJson(lines),
            taxLinesJson: writeJson(payable.lines),
            billedToJson: writeJson(billedTo),
            periodStartAt: what.period?.start ?? null,
            periodEndAt: what.period?.end ?? null,
            issuedAt,
            dueAt: issuedAt,
          },
        });
        // Whoever issued it — a super admin, the renewal job (`system`) or the provider flow — is named (§36).
        await recordAuditLog(
          actor,
          {
            action: BILLING_AUDIT_ACTIONS.invoiceCreated,
            targetType: 'invoice',
            targetId: created.id,
            meta: { tenantId: what.tenantId, number, purpose: payable.purpose, total: created.total, currency: created.currency },
          },
          tx,
        );
        return created;
      })
      .catch((err: unknown) => {
        if ((err as { code?: string }).code === 'P2002') throw conflict('This has already been invoiced.');
        throw err;
      }),
  );
  if (row.purpose === 'renewal') await noticeForRenewalInvoice(row);
  return toInvoiceRecord(row);
}

/**
 * Voids an open invoice that no longer describes what will be bought, so a correct one can replace it: a
 * renewal whose price changed after it was issued (a downgrade scheduled for that boundary, SAAS-012), or a
 * first purchase the academy exchanged for another plan or cycle (SAAS-009). Done as `system`, only for an
 * invoice nobody has paid or started paying; it stays as history.
 */
export async function supersedeUnpaidInvoice(actor: LifecycleActor, id: string, reason: string): Promise<void> {
  if (actor.type !== 'system') throw forbidden('Only the platform’s jobs replace an invoice.');
  const invoice = await db.invoice.findUnique({ where: { id }, include: { payments: true } });
  if (!invoice || invoice.status !== 'open' || (invoice.purpose !== 'renewal' && invoice.purpose !== 'new_subscription')) return;
  if (invoice.payments.some((p) => p.status !== 'failed')) return;
  await withinAcademy(invoice.tenantId, () =>
    db.$transaction(async (tx) => {
      const moved = await tx.invoice.updateMany({ where: { id, status: 'open' }, data: { status: 'void', voidedAt: now(), voidReason: reason } });
      if (moved.count !== 1) return;
      await recordAuditLog(
        actor,
        { action: BILLING_AUDIT_ACTIONS.invoiceVoided, targetType: 'invoice', targetId: id, meta: { number: invoice.number, reason } },
        tx,
      );
    }),
  );
}

/** Voids an open invoice — a super admin's decision, with its reason, on the audit trail. A paid invoice is never voided. */
export async function voidInvoice(actor: AuditActor, id: string, reason: string): Promise<InvoiceRecord> {
  if (actor.auth?.role !== 'superadmin' || currentContext()?.kind !== 'platform') throw forbidden('Only a super admin can void an invoice.');
  if (!reason || reason.trim().length < 3) throw conflict('Say why the invoice is void.');
  const invoice = await db.invoice.findUnique({ where: { id } });
  if (!invoice) throw notFound('Invoice not found.');
  if (invoice.status !== 'open') throw conflict(`A ${invoice.status} invoice cannot be voided.`);
  const row = await withinAcademy(invoice.tenantId, () =>
    db.$transaction(async (tx) => {
      const moved = await tx.invoice.updateMany({ where: { id, status: 'open' }, data: { status: 'void', voidedAt: now(), voidReason: reason.trim() } });
      if (moved.count !== 1) throw conflict('The invoice changed while this was being saved.');
      await recordAuditLog(
        actor,
        { action: BILLING_AUDIT_ACTIONS.invoiceVoided, targetType: 'invoice', targetId: id, meta: { number: invoice.number, reason: reason.trim() } },
        tx,
      );
      return tx.invoice.findUniqueOrThrow({ where: { id } });
    }),
  );
  return toInvoiceRecord(row);
}

export async function getInvoice(id: string): Promise<InvoiceRecord> {
  const row = await db.invoice.findUnique({ where: { id } });
  if (!row) throw notFound('Invoice not found.');
  return toInvoiceRecord(row);
}

/** An academy's invoices, newest first. */
export async function listInvoices(tenantId: string): Promise<InvoiceRecord[]> {
  const rows = await withinAcademy(tenantId, () => db.invoice.findMany({ where: { tenantId }, orderBy: [{ issuedAt: 'desc' }, { number: 'desc' }] }));
  return rows.map(toInvoiceRecord);
}

/** Every academy's invoices for the Super Admin, newest first, filtered by status or academy. */
export async function listAllInvoices(query: {
  status?: InvoiceStatus;
  tenantId?: string;
  page: number;
  pageSize: number;
}): Promise<{ rows: InvoiceRecord[]; total: number }> {
  if (currentContext()?.kind !== 'platform') throw forbidden('Only the platform lists every LMS’s invoices.');
  const where = { ...(query.status ? { status: query.status } : {}), ...(query.tenantId ? { tenantId: query.tenantId } : {}) };
  const [rows, total] = await Promise.all([
    db.invoice.findMany({ where, orderBy: [{ issuedAt: 'desc' }, { number: 'desc' }], skip: (query.page - 1) * query.pageSize, take: query.pageSize }),
    db.invoice.count({ where }),
  ]);
  return { rows: rows.map(toInvoiceRecord), total };
}
