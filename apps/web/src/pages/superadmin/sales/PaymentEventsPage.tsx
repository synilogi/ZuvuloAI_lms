import { useSearchParams } from 'react-router-dom';
import type { PaymentEventRow } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { SalesTabs } from './salesMeta';
import { services } from '@/services';
import styles from '../affiliates/Affiliates.module.css';

const columns: Column<PaymentEventRow>[] = [
  { key: 'type', header: 'Event', mobile: 'primary', render: (r) => r.eventType },
  { key: 'id', header: 'Gateway event id', mobile: 'detail', render: (r) => <span className={styles.cellMeta}>{r.eventId}</span> },
  { key: 'provider', header: 'Gateway', width: '120px', mobile: 'meta', render: (r) => r.provider },
  {
    key: 'state',
    header: 'State',
    width: '120px',
    mobile: 'status',
    render: (r) => (
      <Badge size="sm" tone={r.processed ? 'accent' : 'warn'}>
        {r.processed ? 'Processed' : 'Received'}
      </Badge>
    ),
  },
  { key: 'when', header: 'Received', width: '160px', mobile: 'detail', render: (r) => formatMoment(r.receivedAt) },
];

/** What the gateway has reported about course payments, newest first: signed webhooks only, read-only. */
export default function PaymentEventsPage() {
  const [params, setParams] = useSearchParams();
  const page = Math.max(1, Number(params.get('page')) || 1);
  const list = useAsync(`sales:events:${page}`, () => services.sales.events({ page, pageSize: 25 }));
  const data = list.data;
  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Payment events"
        count={data ? plural(data.total, 'event') : undefined}
        description="What the gateway has told the platform, once its signature checked out. A repeat delivery changes nothing."
      />
      <SalesTabs />
      <PrototypeNote>The demo build has no gateway, so nothing is reported here.</PrototypeNote>
      {list.status === 'error' && !data ? (
        <PlatformError title="The events didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title="Nothing reported yet">Events appear here when the gateway’s webhook reaches the platform.</StateMessage>
      ) : (
        <>
          <DataTable<PaymentEventRow> rows={data.rows} columns={columns} rowKey={(r) => r.id} label="Payment events" rowLabel={(r) => r.eventType} framed />
          {data.total > data.pageSize && (
            <div className={styles.formActions}>
              <Button disabled={page <= 1} onClick={() => setParams({ page: String(page - 1) })}>
                Previous
              </Button>
              <Button disabled={page * data.pageSize >= data.total} onClick={() => setParams({ page: String(page + 1) })}>
                Next
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
