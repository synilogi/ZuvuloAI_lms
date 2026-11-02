import { useParams } from 'react-router-dom';
import { ArrowLeft, Printer, Receipt } from '@phosphor-icons/react';
import { formatMoney } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { COMPANY } from '../marketing/siteContent';
import { hasReceipt, receiptFigures } from './receipt';
import styles from './Receipt.module.css';

const BACK = (
  <LinkButton to="/purchases" iconStart={<ArrowLeft size={16} />}>
    Back to purchases
  </LinkButton>
);

/**
 * The receipt for one paid order, to read or print. It records a payment and is deliberately not a tax invoice: the
 * company's GSTIN is not confirmed, so none is shown. Every figure is the API's.
 */
export default function PurchaseReceiptPage() {
  const { purchaseId = '' } = useParams();
  const query = useAsync(`purchase-receipt:${purchaseId}`, () => services.learning.getPurchase(purchaseId));
  const purchase = query.data?.id === purchaseId ? query.data : undefined;
  usePageCrumbs([{ label: 'Purchases', to: '/purchases' }, { label: purchase?.orderNumber ?? 'Receipt' }]);

  if (query.status === 'error' && !purchase) {
    const missing = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={missing ? 'This receipt isn’t available' : 'The receipt didn’t load'}
          actions={
            missing ? (
              BACK
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!purchase) {
    return (
      <div className={styles.page} aria-busy="true" aria-label="Loading receipt">
        <Skeleton height={520} radius="var(--r-lg)" />
      </div>
    );
  }
  if (!hasReceipt(purchase)) {
    return (
      <div className={styles.page}>
        <StateMessage kind="empty" icon={<Receipt size={26} />} title="No receipt yet" actions={BACK}>
          Order {purchase.orderNumber} hasn’t been paid. A receipt appears here once the payment is confirmed.
        </StateMessage>
      </div>
    );
  }

  const figures = receiptFigures(purchase);
  const money = (paise: number) => formatMoney(paise, purchase.currency);

  return (
    <div className={styles.page}>
      <div className={styles.actions} data-print-hide>
        {BACK}
        <Button variant="primary" iconStart={<Printer size={16} />} onClick={() => window.print()}>
          Print
        </Button>
      </div>

      <article className={styles.sheet} data-print-area aria-labelledby="receipt-title">
        <header className={styles.head}>
          <div>
            <h1 id="receipt-title" className={styles.title}>
              Payment receipt
            </h1>
            <p className={styles.order}>{purchase.orderNumber}</p>
          </div>
          <address className={styles.company}>
            <strong>{COMPANY.name}</strong>
            {COMPANY.addressLines.map((line) => (
              <span key={line}>{line}</span>
            ))}
            <span>{COMPANY.email}</span>
          </address>
        </header>

        {purchase.refundedAt && (
          <p className={styles.refunded}>
            <Badge size="sm" tone="warn">
              Refunded
            </Badge>
            This order was refunded in full on {formatDate(purchase.refundedAt)}.
          </p>
        )}

        <dl className={styles.facts}>
          <div>
            <dt>Course</dt>
            <dd>{purchase.courseTitle || 'Course'}</dd>
          </div>
          <div>
            <dt>Date paid</dt>
            <dd>{formatDate(purchase.paidAt ?? purchase.createdAt)}</dd>
          </div>
          <div>
            <dt>Payment reference</dt>
            <dd className={styles.reference}>{purchase.paymentReference ?? '—'}</dd>
          </div>
        </dl>

        <table className={styles.lines}>
          <caption className="sr-only">What was charged</caption>
          <tbody>
            <tr>
              <th scope="row">List price</th>
              <td className="tabular">{money(figures.listPrice)}</td>
            </tr>
            {figures.saleSaving > 0 && (
              <tr>
                <th scope="row">Sale discount</th>
                <td className="tabular">− {money(figures.saleSaving)}</td>
              </tr>
            )}
            {figures.couponSaving > 0 && (
              <tr>
                <th scope="row">Coupon discount{purchase.couponCode ? ` (${purchase.couponCode})` : ''}</th>
                <td className="tabular">− {money(figures.couponSaving)}</td>
              </tr>
            )}
            {figures.saleSaving === 0 && figures.couponSaving === 0 && (
              <tr>
                <th scope="row">Discount</th>
                <td className="tabular">{money(0)}</td>
              </tr>
            )}
          </tbody>
          <tfoot>
            <tr>
              <th scope="row">Amount paid</th>
              <td className="tabular">{money(figures.paid)}</td>
            </tr>
          </tfoot>
        </table>

        <p className={styles.note}>Prices are all-inclusive. This is a record of your payment, not a tax invoice.</p>
      </article>
    </div>
  );
}
