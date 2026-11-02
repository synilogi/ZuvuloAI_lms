import { useEffect, useState } from 'react';
import { HandCoins, Prohibit } from '@phosphor-icons/react';
import type { CheckoutOutcome, Invoice, OfflinePaymentMethod } from '@syniastrolms/domain';
import { OFFLINE_PAYMENT_METHODS, invoiceTotal } from '@syniastrolms/domain';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { services } from '@/services';
import { money } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/*
 * What the platform can do with an invoice that is still open: record a payment the academy made outside the
 * gateway, or withdraw the invoice. Both are the server's to apply — a recorded payment settles the invoice's
 * full total, and the invoice then renews, recovers or starts the subscription as a paid invoice does.
 */

/** An invoice waiting for its money: raised and unpaid, or its last charge refused. */
export const isOpenInvoice = (invoice: Pick<Invoice, 'status'>) => invoice.status === 'pending' || invoice.status === 'failed';

export const OFFLINE_METHOD_LABEL: Record<OfflinePaymentMethod, string> = {
  bank_transfer: 'Bank transfer',
  cheque: 'Cheque',
  cash: 'Cash',
  upi: 'UPI',
  other: 'Other',
};

export function RecordPaymentDialog({
  invoice,
  onClose,
  onDone,
}: {
  invoice: Invoice | null;
  onClose: () => void;
  onDone: (outcome: CheckoutOutcome) => void | Promise<void>;
}) {
  const [method, setMethod] = useState<OfflinePaymentMethod>('bank_transfer');
  const [reference, setReference] = useState('');
  const [note, setNote] = useState('');
  useEffect(() => {
    if (invoice) {
      setMethod('bank_transfer');
      setReference('');
      setNote('');
    }
  }, [invoice]);

  const ref = reference.trim();
  const total = invoice ? money(invoiceTotal(invoice), invoice.currency) : '';

  return (
    <ConfirmDialog
      open={Boolean(invoice)}
      onClose={onClose}
      onConfirm={async () => {
        if (!invoice) return;
        const outcome = await services.subscriptions.recordInvoicePayment(invoice.id, {
          method,
          reference: ref,
          ...(note.trim() ? { note: note.trim() } : {}),
        });
        await onDone(outcome);
      }}
      icon={<HandCoins size={20} />}
      title={invoice ? `Record a payment for ${invoice.number}?` : 'Record a payment'}
      description={invoice ? `${invoice.customerName} · ${total} due` : undefined}
      confirmLabel={invoice ? `Record ${total}` : 'Record payment'}
      blocked={ref.length < 3 || ref.length > 100 || note.length > 500}
      acknowledge={invoice ? `The Admin paid the full ${total}, and I have the reference to show it.` : undefined}
    >
      <div className={styles.dialogBody}>
        <Field label="How it was paid">
          <Select value={method} onChange={(e) => setMethod(e.target.value as OfflinePaymentMethod)}>
            {OFFLINE_PAYMENT_METHODS.map((m) => (
              <option key={m} value={m}>
                {OFFLINE_METHOD_LABEL[m]}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Reference" hint="The bank, cheque or receipt reference — 3 to 100 characters.">
          <Input value={reference} onChange={(e) => setReference(e.target.value)} maxLength={100} placeholder="e.g. NEFT UTR 2026091200451" />
        </Field>
        <Field label="Note" optional hint="Anything the record should say. Up to 500 characters.">
          <Textarea rows={2} value={note} onChange={(e) => setNote(e.target.value)} maxLength={500} />
        </Field>
        <p className={styles.muted}>
          This records the invoice’s full total of {total} as paid — a part payment cannot be recorded. The invoice then does what a paid invoice does: the
          subscription renews, recovers from past due, or starts.
        </p>
      </div>
    </ConfirmDialog>
  );
}

export function VoidInvoiceDialog({
  invoice,
  onClose,
  onDone,
}: {
  invoice: Invoice | null;
  onClose: () => void;
  onDone: (invoice: Invoice) => void | Promise<void>;
}) {
  const [reason, setReason] = useState('');
  useEffect(() => {
    if (invoice) setReason('');
  }, [invoice]);

  return (
    <ConfirmDialog
      open={Boolean(invoice)}
      onClose={onClose}
      onConfirm={async () => {
        if (!invoice) return;
        await onDone(await services.subscriptions.voidInvoice(invoice.id, reason.trim()));
      }}
      tone="danger"
      icon={<Prohibit size={20} />}
      title={invoice ? `Withdraw ${invoice.number}?` : 'Withdraw invoice'}
      description={invoice ? `${invoice.customerName} · ${money(invoiceTotal(invoice), invoice.currency)}` : undefined}
      confirmLabel="Withdraw invoice"
      blocked={reason.trim().length < 3 || reason.length > 500}
    >
      <div className={styles.dialogBody}>
        <Field label="Reason" hint="Kept on the invoice. At least 3 characters.">
          <Textarea rows={2} value={reason} onChange={(e) => setReason(e.target.value)} maxLength={500} placeholder="Why is this invoice withdrawn?" />
        </Field>
        <p className={styles.muted}>
          The invoice is withdrawn and can no longer be paid. It stays on the record as withdrawn. The subscription is not changed by this — if the Admin still
          owes for the period, raise the matter with them separately.
        </p>
      </div>
    </ConfirmDialog>
  );
}
