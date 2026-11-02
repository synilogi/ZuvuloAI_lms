import { Link, useSearchParams } from 'react-router-dom';
import { formatMoney, type AffiliateOrderRow } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pager } from '@/pages/superadmin/affiliates/earningsParts';
import { services } from '@/services';
import { AffiliateNav } from './affiliateNav';
import styles from './Affiliate.module.css';

const statusOf = (r: AffiliateOrderRow): { label: string; tone: 'accent' | 'warn' | 'neutral' } =>
  r.refunded
    ? { label: 'Refunded', tone: 'warn' }
    : r.chargedBack
      ? { label: 'Disputed', tone: 'warn' }
      : r.status === 'paid'
        ? { label: 'Paid', tone: 'accent' }
        : { label: r.status, tone: 'neutral' };

/** The learner's own paid purchases of the program's eligible courses (docs/15 §7.2). Every other purchase is on the purchases page. */
export default function AffiliateOrdersPage() {
  const [params, setParams] = useSearchParams();
  const page = Math.max(1, Number(params.get('page')) || 1);
  const orders = useAsync(`affiliate:orders:${page}`, () => services.affiliate.orders({ page, pageSize: 20 }));
  const data = orders.data;

  const columns: Column<AffiliateOrderRow>[] = [
    { key: 'course', header: 'Course', mobile: 'primary', render: (r) => r.course.title },
    { key: 'order', header: 'Order', mobile: 'detail', render: (r) => r.orderNumber ?? '—' },
    { key: 'amount', header: 'Amount', width: '120px', mobile: 'meta', render: (r) => formatMoney(r.amount, r.currency) },
    { key: 'date', header: 'Date', width: '130px', mobile: 'detail', render: (r) => (r.paidAt ? formatDate(r.paidAt) : '—') },
    {
      key: 'status',
      header: 'Status',
      width: '110px',
      mobile: 'status',
      render: (r) => {
        const status = statusOf(r);
        return (
          <Badge size="sm" tone={status.tone}>
            {status.label}
          </Badge>
        );
      },
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        title="My orders"
        description="Your purchases of the courses in the affiliate program. Receipts and every other purchase are under your purchases."
      />
      <AffiliateNav />
      {orders.status === 'error' && !data ? (
        <StateMessage kind="error" title="Your orders didn’t load" actions={<Button onClick={() => orders.run().catch(() => undefined)}>Try again</Button>}>
          {orders.error?.message}
        </StateMessage>
      ) : !data ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title="No orders yet" actions={<Link to="/affiliate">See the eligible course</Link>}>
          A purchase of an eligible course appears here once it is paid.
        </StateMessage>
      ) : (
        <>
          <DataTable<AffiliateOrderRow> rows={data.rows} columns={columns} rowKey={(r) => r.id} label="My orders" rowLabel={(r) => r.course.title} framed />
          <Pager page={page} pageSize={data.pageSize} total={data.total} onPage={(n) => setParams(n > 1 ? { page: String(n) } : {}, { replace: true })} />
        </>
      )}
      <p className={styles.muted}>
        <Link to="/purchases">Open all my purchases</Link>
      </p>
    </div>
  );
}
