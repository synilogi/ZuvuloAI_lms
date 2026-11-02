import { useState } from 'react';
import { Link } from 'react-router-dom';
import { DownloadSimple, HandCoins, Printer, Prohibit } from '@phosphor-icons/react';
import { invoiceSubtotal, invoiceTax, invoiceTotal, type Invoice } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { API_MODE } from '@/lib/apiMode';
import { formatDate } from '@/lib/format';
import { printSheet } from '@/lib/print';
import { Button } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { downloadCsv } from '@/pages/reports/reportMeta';
import { services } from '@/services';
import { RecordPaymentDialog, VoidInvoiceDialog, isOpenInvoice } from './InvoiceActions';
import { Fact, MethodLine, PaymentStatusBadge, SUBS_BASE, cycleLabel, money } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/**
 * One invoice, as a sheet.
 *
 * The invoice as the platform issued it: its figures are the server's, fixed at issue, and never
 * recalculated here. No PDF is generated yet. Download writes the line items to a CSV with the same
 * helper the reports use, and Print sends this sheet — and only this sheet — to paper. The academy's
 * own billing page opens its invoices through `load`, from its own endpoint.
 *
 * Given `onChanged` (the platform's screens), an open invoice also offers Record payment and Void; the sheet
 * steps aside while that decision is made, then shows the invoice as it now stands.
 */
export function InvoiceDialog({
  invoiceId,
  onClose,
  load = (id) => services.subscriptions.getInvoice(id),
  platformLinks = true,
  onChanged,
}: {
  invoiceId: string | null;
  onClose: () => void;
  load?: (id: string) => Promise<Invoice>;
  /** Link the subscription to its platform page — off on the academy's own billing page, which cannot open it. */
  platformLinks?: boolean;
  /** Offers the platform's actions on an open invoice, and is told when one changed it. */
  onChanged?: () => void | Promise<void>;
}) {
  const toast = useToast();
  const [acting, setActing] = useState<'record' | 'void' | null>(null);
  const query = useAsync(`subs:invoice:${invoiceId ?? 'none'}`, () => (invoiceId ? load(invoiceId) : Promise.resolve(null)), {
    immediate: Boolean(invoiceId),
  });
  const invoice = invoiceId ? query.data : null;

  const download = () => {
    if (!invoice) return;
    downloadCsv(
      `${invoice.number}.csv`,
      ['Description', 'Quantity', `Unit amount (${invoice.currency})`, `Amount (${invoice.currency})`],
      [
        ...invoice.lines.map((line) => [line.description, line.quantity, line.unitAmount, line.quantity * line.unitAmount]),
        ['Subtotal', '', '', invoiceSubtotal(invoice)],
        [`Tax (${invoice.taxPercent}%)`, '', '', invoiceTax(invoice)],
        ['Total', '', '', invoiceTotal(invoice)],
      ],
    );
    toast({ kind: 'success', title: `${invoice.number} saved`, text: 'The line items were written to a CSV file.' });
  };

  const settled = async (toastInput: Parameters<typeof toast>[0]) => {
    setActing(null);
    toast(toastInput);
    await Promise.all([query.run().catch(() => undefined), onChanged?.()]);
  };

  const actionable = Boolean(onChanged && invoice && isOpenInvoice(invoice));

  return (
    <>
      <Modal
        open={Boolean(invoiceId) && !acting}
        onClose={onClose}
        title={invoice ? `Invoice ${invoice.number}` : 'Invoice'}
        description={invoice ? `${invoice.customerName} · ${invoice.planName}` : undefined}
        width={620}
        footer={
          <>
            {actionable && (
              <>
                <Button variant="danger" onClick={() => setActing('void')} iconStart={<Prohibit size={16} />} data-print-hide>
                  Withdraw invoice
                </Button>
                <Button onClick={() => setActing('record')} iconStart={<HandCoins size={16} />} data-print-hide>
                  Record payment
                </Button>
              </>
            )}
            <Button onClick={download} iconStart={<DownloadSimple size={16} />} disabled={!invoice} data-print-hide>
              Download
            </Button>
            <Button onClick={printSheet} iconStart={<Printer size={16} />} disabled={!invoice} data-print-hide>
              Print
            </Button>
            <Button variant="primary" onClick={onClose} data-print-hide>
              Close
            </Button>
          </>
        }
      >
        {query.status === 'error' ? (
          <StateMessage
            kind="error"
            title="The invoice didn’t load"
            compact
            actions={<Button onClick={() => query.run().catch(() => undefined)}>Try again</Button>}
          >
            {query.error.message}
          </StateMessage>
        ) : !invoice ? (
          <div aria-busy="true">
            <Skeleton height={26} width="45%" radius="var(--r-xs)" />
            <Skeleton height={180} radius="var(--r-md)" />
          </div>
        ) : (
          <div className={styles.invoice}>
            <div className={styles.invoiceHead}>
              <div className={styles.stack}>
                <p className={styles.invoiceNumber}>{invoice.number}</p>
                <span className={styles.muted}>Issued {formatDate(invoice.issuedAt)}</span>
              </div>
              <div className={styles.stack}>
                <PaymentStatusBadge status={invoice.status} size="md" />
                <span className={styles.muted}>
                  {invoice.status === 'paid' && invoice.paidAt
                    ? `Paid ${formatDate(invoice.paidAt)}`
                    : invoice.status === 'pending'
                      ? 'Not settled yet'
                      : (invoice.note ?? '')}
                </span>
              </div>
            </div>

            <dl className={styles.facts}>
              <Fact
                label="Billed to"
                value={
                  <address className={styles.address}>
                    {invoice.billingAddress.map((line) => (
                      <span key={line}>
                        {line}
                        <br />
                      </span>
                    ))}
                  </address>
                }
              />
              <Fact
                label="Subscription"
                value={
                  platformLinks ? (
                    <Link to={`${SUBS_BASE}/subscribers/${invoice.subscriptionId}`} className={styles.mono} onClick={onClose}>
                      {invoice.subscriptionId}
                    </Link>
                  ) : (
                    <span className={styles.mono}>{invoice.subscriptionId}</span>
                  )
                }
              />
              <Fact label="Plan" value={`${invoice.planName} · ${cycleLabel(invoice.cycle)}`} />
              <Fact label="Billing period" value={`${formatDate(invoice.periodStart)} – ${formatDate(invoice.periodEnd)}`} />
              <Fact label="Payment method" value={<MethodLine method={invoice.method} />} />
            </dl>

            <table className={styles.lineTable}>
              <caption className="sr-only">Invoice {invoice.number} line items</caption>
              <thead>
                <tr>
                  <th scope="col">Description</th>
                  <th scope="col" className={styles.numeric}>
                    Qty
                  </th>
                  <th scope="col" className={styles.numeric}>
                    Unit
                  </th>
                  <th scope="col" className={styles.numeric}>
                    Amount
                  </th>
                </tr>
              </thead>
              <tbody>
                {invoice.lines.map((line) => (
                  <tr key={line.description}>
                    <td>{line.description}</td>
                    <td className={styles.numeric}>{line.quantity}</td>
                    <td className={styles.numeric}>{money(line.unitAmount, invoice.currency)}</td>
                    <td className={styles.numeric}>{money(line.quantity * line.unitAmount, invoice.currency)}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            <div className={styles.totals}>
              <div className={styles.totalRow}>
                <span>Subtotal</span>
                <span className={styles.amount}>{money(invoiceSubtotal(invoice), invoice.currency)}</span>
              </div>
              <div className={styles.totalRow}>
                <span>Tax ({invoice.taxPercent}%)</span>
                <span className={styles.amount}>{money(invoiceTax(invoice), invoice.currency)}</span>
              </div>
              <div className={`${styles.totalRow} ${styles.grandTotal}`}>
                <span>Total</span>
                <span className={styles.amount}>{money(invoiceTotal(invoice), invoice.currency)}</span>
              </div>
            </div>

            {invoice.note && invoice.status !== 'paid' && <p className={styles.muted}>{invoice.note}</p>}
            <p className={styles.muted}>
              {API_MODE === 'mock'
                ? 'A demo record, not a tax invoice. No payment was taken and no PDF is produced — Download writes the line items to a CSV file.'
                : 'As issued by the platform. No PDF is produced yet — Download writes the line items to a CSV file.'}
            </p>
          </div>
        )}
      </Modal>
      <RecordPaymentDialog
        invoice={acting === 'record' ? (invoice ?? null) : null}
        onClose={() => setActing(null)}
        onDone={(outcome) =>
          settled({ kind: outcome.status === 'failed' ? 'error' : outcome.settled ? 'success' : 'info', title: 'Payment recorded', text: outcome.message })
        }
      />
      <VoidInvoiceDialog
        invoice={acting === 'void' ? (invoice ?? null) : null}
        onClose={() => setActing(null)}
        onDone={(voided) => settled({ kind: 'success', title: `${voided.number} is withdrawn`, text: 'It can no longer be paid, and stays on the record.' })}
      />
    </>
  );
}
