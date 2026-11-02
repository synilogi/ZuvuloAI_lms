import { Broadcast } from '@phosphor-icons/react';
import type { WebhookReceipt } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate, formatTime, plural } from '@/lib/format';
import type { Tone } from '@/design/tokens';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PAGE_SIZE, PrototypeNote, SubscriptionTabs, rangeSummary, useListParams } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

type Status = WebhookReceipt['status'];

const STATUS: Record<Status, { label: string; tone: Tone; meaning: string }> = {
  received: { label: 'Waiting', tone: 'info', meaning: 'Received and not handled yet.' },
  processed: { label: 'Done', tone: 'accent', meaning: 'Checked and applied — the subscription or invoice was updated.' },
  ignored: { label: 'Not needed', tone: 'neutral', meaning: 'Checked, and nothing needed to change.' },
  failed: { label: 'Failed', tone: 'danger', meaning: 'Couldn’t be applied. The platform tries again a few times.' },
};

const when = (iso: string) => `${formatDate(iso)} · ${formatTime(iso)}`;

/**
 * What the payment providers told the platform, as it arrived (SAAS-010): each event with its status, how many
 * times it was attempted and why it failed. Read-only — a webhook is the provider's word, and the platform
 * acts on it by itself. Bodies are never kept, so none is shown.
 */
export default function WebhooksPage() {
  const { params, update, page } = useListParams();
  const status = (params.get('status') as Status | 'all' | null) ?? 'all';

  const query = { status, page, pageSize: PAGE_SIZE };
  const list = useAsync(`subs:webhooks:${JSON.stringify(query)}`, () => services.subscriptions.listWebhooks(query));
  const data = list.data;
  const rows = data?.rows ?? [];

  const columns: Column<WebhookReceipt>[] = [
    {
      key: 'received',
      header: 'Received',
      width: '170px',
      mobile: 'meta',
      render: (w) => (
        <time dateTime={w.receivedAt} className={styles.nowrap}>
          {when(w.receivedAt)}
        </time>
      ),
    },
    {
      key: 'event',
      header: 'Event',
      mobile: 'primary',
      render: (w) => (
        <span className={styles.stack}>
          <span className={`${styles.cellTitle} ${styles.mono}`}>{w.eventType}</span>
          <span className={`${styles.cellMeta} ${styles.mono}`}>{w.providerEventId}</span>
        </span>
      ),
    },
    { key: 'provider', header: 'From', width: '120px', mobile: 'detail', render: (w) => <span className={styles.nowrap}>{w.provider}</span> },
    {
      key: 'status',
      header: 'Status',
      width: '120px',
      mobile: 'status',
      render: (w) => (
        <Badge size="sm" tone={STATUS[w.status].tone} title={STATUS[w.status].meaning}>
          {STATUS[w.status].label}
        </Badge>
      ),
    },
    { key: 'attempts', header: 'Tries', width: '96px', align: 'end', mobile: 'detail', render: (w) => <span className={styles.amount}>{w.attempts}</span> },
    {
      key: 'processed',
      header: 'Handled',
      width: '170px',
      mobile: 'detail',
      render: (w) =>
        w.processedAt ? (
          <time dateTime={w.processedAt} className={styles.nowrap}>
            {when(w.processedAt)}
          </time>
        ) : (
          <span className={styles.faint}>Not yet</span>
        ),
    },
    {
      key: 'error',
      header: 'Problem',
      mobile: 'detail',
      render: (w) => (w.note ? <span className={w.status === 'failed' ? undefined : styles.muted}>{w.note}</span> : <span className={styles.faint}>—</span>),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Payment events"
        count={data ? plural(data.total, 'event') : undefined}
        description="Messages the payment provider sends when a payment goes through, fails or is refunded — and what the platform did with each. You only need this page when looking into a payment problem."
      />
      <SubscriptionTabs />
      <PrototypeNote>Demo events. No provider sent them.</PrototypeNote>

      <div className={styles.controls}>
        <SegmentedControl<Status | 'all'>
          label="Show"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All' },
            { value: 'failed', label: 'Failed' },
            { value: 'processed', label: 'Done' },
            { value: 'ignored', label: 'Not needed' },
            { value: 'received', label: 'Waiting' },
          ]}
        />
      </div>

      {list.status === 'error' && !data ? (
        <PlatformError title="Payment events didn’t load" error={list.error} onRetry={() => list.run().catch(() => undefined)} />
      ) : data && rows.length === 0 ? (
        <StateMessage icon={<Broadcast size={26} />} title={status === 'all' ? 'No payment events yet' : `No “${STATUS[status].label}” events`}>
          {status === 'all' ? 'They show up here as soon as the payment provider sends one.' : 'Try another filter.'}
        </StateMessage>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Payment events"
            rows={rows}
            columns={columns}
            rowKey={(w) => w.id}
            rowLabel={(w) => `${w.eventType} — ${w.providerEventId}`}
            loading={!data}
            skeletonRows={8}
          />
        </div>
      )}

      {data && data.total > PAGE_SIZE && (
        <Pagination
          page={page}
          pageCount={Math.ceil(data.total / PAGE_SIZE)}
          onChange={(p) => update({ page: String(p) }, true)}
          summary={rangeSummary(data.total, page, PAGE_SIZE, 'events')}
        />
      )}
    </div>
  );
}
