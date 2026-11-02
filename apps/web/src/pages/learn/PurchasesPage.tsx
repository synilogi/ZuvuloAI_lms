import { Link } from 'react-router-dom';
import { Receipt } from '@phosphor-icons/react';
import type { CoursePurchase } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { PURCHASE_STATUS, purchaseAmount } from '@/lib/coursePricing';
import { formatDate, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { hasReceipt } from './receipt';
import styles from './Learn.module.css';

/** A purchase's state as the learner reads it: paid and open, waiting, or not completed. */
export function purchaseState(p: CoursePurchase): { label: string; tone: (typeof PURCHASE_STATUS)[keyof typeof PURCHASE_STATUS]['tone'] } {
  if (p.refundedAt) return { label: 'Refunded', tone: 'warn' };
  if (p.status === 'paid' && p.needsReview) return { label: 'Paid · under review', tone: 'warn' };
  return PURCHASE_STATUS[p.status];
}

const columns: Column<CoursePurchase>[] = [
  {
    key: 'course',
    header: 'Course',
    mobile: 'primary',
    render: (p) => <Link to={`/learn/${p.courseId}`}>{p.courseTitle || 'Course'}</Link>,
  },
  {
    key: 'status',
    header: 'Status',
    mobile: 'status',
    render: (p) => {
      const state = purchaseState(p);
      return (
        <Badge size="sm" tone={state.tone}>
          {state.label}
        </Badge>
      );
    },
  },
  {
    key: 'amount',
    header: 'Amount',
    align: 'end',
    mobile: 'meta',
    render: (p) => (
      <span className="tabular" title={p.couponCode ? `Coupon ${p.couponCode}` : undefined}>
        {purchaseAmount(p)}
      </span>
    ),
  },
  {
    key: 'date',
    header: 'Date',
    mobile: 'meta',
    render: (p) => (p.paidAt ? `Paid ${formatDate(p.paidAt)}` : `Ordered ${formatDate(p.createdAt)}`),
  },
  {
    key: 'order',
    header: 'Order',
    mobile: 'detail',
    render: (p) => <span className={styles.muted}>{p.orderNumber}</span>,
  },
  {
    key: 'action',
    header: '',
    align: 'end',
    mobile: 'detail',
    render: (p) =>
      p.refundedAt ? (
        <LinkButton size="sm" variant="ghost" to={`/purchases/${p.id}`}>
          Receipt
        </LinkButton>
      ) : p.status === 'paid' || p.enrolled ? (
        <span className={styles.rowActions}>
          {hasReceipt(p) && (
            <LinkButton size="sm" variant="ghost" to={`/purchases/${p.id}`}>
              Receipt
            </LinkButton>
          )}
          <LinkButton size="sm" to={`/learn/${p.courseId}`}>
            Open course
          </LinkButton>
        </span>
      ) : p.status === 'failed' ? (
        // A failed attempt is not final: buying again reuses the same order.
        <LinkButton size="sm" variant="primary" to={`/learn/${p.courseId}`}>
          Try again
        </LinkButton>
      ) : (
        <LinkButton size="sm" variant="ghost" to={`/learn/${p.courseId}`}>
          View course
        </LinkButton>
      ),
  },
];

/**
 * The learner's course purchases: what they bought, what they paid and where each order stands, with a printable receipt
 * for each paid one. Every row is the API's, read again on each visit.
 */
export default function PurchasesPage() {
  usePageCrumbs([{ label: 'Purchases' }]);
  const query = useAsync('learner-purchases', () => services.learning.listPurchases());
  const rows = query.data ?? [];

  return (
    <div className={styles.page}>
      <PageHeader
        title="Purchases"
        description="Courses you’ve bought, with what you paid. Prices are all-inclusive. A course opens as soon as its payment is confirmed."
        count={query.data ? plural(rows.length, 'order') : undefined}
      />
      {query.status === 'error' && !query.data ? (
        <StateMessage
          kind="error"
          title="Your purchases didn’t load"
          actions={
            <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      ) : (
        <DataTable
          framed
          rows={rows}
          columns={columns}
          rowKey={(p) => p.id}
          label="Your purchases"
          rowLabel={(p) => (p.status === 'failed' && p.failureMessage ? `${p.courseTitle} · ${p.failureMessage}` : p.courseTitle)}
          loading={!query.data}
          empty={
            <StateMessage
              kind="empty"
              icon={<Receipt size={26} />}
              title="No purchases yet"
              compact
              actions={<LinkButton to="/explore">Explore courses</LinkButton>}
            >
              Paid courses you buy appear here, with their order details.
            </StateMessage>
          }
        />
      )}
    </div>
  );
}
