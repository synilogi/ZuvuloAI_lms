import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { ArrowCounterClockwise, DownloadSimple } from '@phosphor-icons/react';
import { formatMoney, type MlmOrderStatus, type SalesOrderRow, type SalesOrderStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useDebouncedInput } from '@/hooks/useDebouncedInput';
import { formatMoment, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Drawer } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Field, Input, SearchInput, Textarea } from '@/components/ui/Field/Field';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import type { Tone } from '@/design/tokens';
import { services } from '@/services';
import { OrderStatusBadge } from '../affiliates/affiliateMeta';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { Fact, PrototypeNote } from '../subscriptions/subscriptionMeta';
import { SalesTabs } from './salesMeta';
import styles from '../affiliates/Affiliates.module.css';
import facts from '../subscriptions/Subscriptions.module.css';

const STATE: Record<SalesOrderStatus, { label: string; tone: Tone }> = {
  paid: { label: 'Paid', tone: 'accent' },
  created: { label: 'Awaiting payment', tone: 'info' },
  failed: { label: 'Failed', tone: 'danger' },
  expired: { label: 'Not completed', tone: 'neutral' },
  refunded: { label: 'Refunded', tone: 'warn' },
};

const REFUND_LABEL = { requested: 'Requested', pending: 'Waiting for the gateway', succeeded: 'Refunded', failed: 'Failed' } as const;

/** Every course order on the platform (docs/16 §2.4): who bought what, what they paid, and the refund of a whole order. */
export default function SalesOrdersPage() {
  const toast = useToast();
  const [params, setParams] = useSearchParams();
  const status = (params.get('status') as SalesOrderStatus | null) ?? undefined;
  const search = params.get('q') ?? '';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || v === 'all') p.delete(k);
      else p.set(k, v);
    }
    if (!('page' in next)) p.delete('page');
    setParams(p, { replace: true });
  };
  const [searchText, setSearchText] = useDebouncedInput(search, (v) => update({ q: v }));
  const list = useAsync(`sales:orders:${status ?? ''}:${search}:${page}`, () =>
    services.sales.orders({ status, search: search || undefined, page, pageSize: 20 }),
  );
  const data = list.data;
  const [openId, setOpenId] = useState<string | null>(null);
  const detail = useAsync(`sales:order:${openId ?? ''}`, () => (openId ? services.sales.order(openId) : Promise.resolve(null)));
  const order = detail.data;
  const [refunding, setRefunding] = useState(false);
  const [reason, setReason] = useState('');
  const [note, setNote] = useState('');

  const refund = async () => {
    if (!order) return;
    await services.sales.refund(order.id, { reason: reason.trim(), note: note.trim() || undefined });
    toast({ kind: 'success', title: `Order ${order.orderNumber} refunded`, text: 'The learner’s access has ended and they have been told by email.' });
    setRefunding(false);
    setReason('');
    setNote('');
    await Promise.all([detail.run(), list.run()]);
  };

  const exportCsv = async () => {
    try {
      const csv = await services.sales.ordersCsv({ status, search: search || undefined });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
      a.download = 'orders.csv';
      a.click();
      URL.revokeObjectURL(a.href);
    } catch (err) {
      toast({ kind: 'error', title: 'The export didn’t work', text: (err as Error).message });
    }
  };

  const columns: Column<SalesOrderRow>[] = [
    {
      key: 'order',
      header: 'Order',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <button type="button" className={styles.cellTitle} onClick={() => setOpenId(r.id)}>
            {r.orderNumber}
          </button>
          <span className={styles.cellMeta}>{r.learner.name}</span>
        </span>
      ),
    },
    { key: 'course', header: 'Course', mobile: 'detail', render: (r) => r.course.title },
    {
      key: 'amount',
      header: 'Amount',
      width: '130px',
      mobile: 'meta',
      render: (r) => (
        <span className={styles.stack}>
          <span className={styles.amount}>{formatMoney(r.amount, r.currency)}</span>
          {r.couponCode && <span className={styles.cellMeta}>{r.couponCode}</span>}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      width: '150px',
      mobile: 'status',
      render: (r) => (
        <Badge size="sm" tone={r.reviewReason ? 'warn' : STATE[r.status].tone}>
          {r.reviewReason ? `${STATE[r.status].label} · review` : STATE[r.status].label}
        </Badge>
      ),
    },
    {
      key: 'date',
      header: 'Date',
      width: '150px',
      mobile: 'detail',
      render: (r) => (
        <time dateTime={r.createdAt} className={styles.nowrap}>
          {formatMoment(r.paidAt ?? r.createdAt)}
        </time>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Orders"
        count={data ? plural(data.counts.all, 'order') : undefined}
        description="Every course order. A course opens only once the gateway confirms the payment."
        actions={
          <Button iconStart={<DownloadSimple size={16} />} onClick={() => void exportCsv()}>
            Export CSV
          </Button>
        }
      />
      <SalesTabs />
      <PrototypeNote>The demo build has no platform behind it, so there are no orders here.</PrototypeNote>
      {data && (
        <dl className={facts.facts}>
          <Fact label="Takings, after refunds" value={formatMoney(data.revenue, 'INR')} />
          <Fact label="Paid orders" value={data.counts.paid.toLocaleString('en-IN')} />
          <Fact label="Refunded" value={data.counts.refunded.toLocaleString('en-IN')} />
        </dl>
      )}
      <div className={styles.controls}>
        <SegmentedControl<SalesOrderStatus | 'all'>
          label="Status"
          value={status ?? 'all'}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: data?.counts.all },
            { value: 'paid', label: 'Paid', count: data?.counts.paid },
            { value: 'created', label: 'Awaiting', count: data?.counts.created },
            { value: 'failed', label: 'Failed', count: data?.counts.failed },
            { value: 'expired', label: 'Not completed', count: data?.counts.expired },
            { value: 'refunded', label: 'Refunded', count: data?.counts.refunded },
          ]}
        />
        <SearchInput value={searchText} onValueChange={setSearchText} placeholder="Order number, learner, course or payment id" aria-label="Search orders" />
      </div>
      {list.status === 'error' && !data ? (
        <PlatformError title="The orders didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title={data.counts.all === 0 ? 'No orders yet' : 'Nothing matches'}>
          {data.counts.all === 0 ? 'Orders appear here as soon as a learner starts buying a course.' : 'Try another status or search.'}
        </StateMessage>
      ) : (
        <>
          <DataTable<SalesOrderRow> rows={data.rows} columns={columns} rowKey={(r) => r.id} label="Orders" rowLabel={(r) => r.orderNumber} framed />
          {data.total > data.pageSize && (
            <div className={styles.formActions}>
              <Button disabled={page <= 1} onClick={() => update({ page: String(page - 1) })}>
                Previous
              </Button>
              <span className={styles.muted}>
                Page {page} of {Math.ceil(data.total / data.pageSize)}
              </span>
              <Button disabled={page * data.pageSize >= data.total} onClick={() => update({ page: String(page + 1) })}>
                Next
              </Button>
            </div>
          )}
        </>
      )}

      <Drawer
        open={openId !== null}
        onClose={() => setOpenId(null)}
        title={order?.orderNumber ?? 'Order'}
        eyebrow="Order"
        footer={
          order?.canRefund ? (
            <Button variant="danger" iconStart={<ArrowCounterClockwise size={16} />} onClick={() => setRefunding(true)}>
              Refund this order
            </Button>
          ) : undefined
        }
      >
        {detail.status === 'error' && !order ? (
          <PlatformError title="The order didn’t load" error={detail.error} onRetry={() => void detail.run().catch(() => undefined)} />
        ) : !order ? (
          <Skeleton height={240} radius="var(--r-md)" />
        ) : (
          <div className={styles.form}>
            {order.reviewReason && (
              <InlineMessage kind="warn" title="Needs a look">
                {order.reviewReason}
              </InlineMessage>
            )}
            <dl className={facts.facts}>
              <Fact label="Status" value={STATE[order.status].label} />
              <Fact label="Learner" value={`${order.learner.name} · ${order.learner.email}`} />
              <Fact label="Course" value={order.course.title} />
              <Fact label="List price" value={formatMoney(order.listPrice * 100, order.currency)} />
              {order.couponCode && <Fact label={`Coupon ${order.couponCode}`} value={`− ${formatMoney(order.discountAmount, order.currency)}`} />}
              <Fact label="Charged" value={formatMoney(order.amount, order.currency)} />
              <Fact label="Ordered" value={formatMoment(order.createdAt)} />
              {order.paidAt && <Fact label="Paid" value={formatMoment(order.paidAt)} />}
              <Fact label="Gateway" value={`${order.provider} (${order.environment})`} />
              <Fact label="Gateway order" value={order.providerOrderId} />
              {order.providerPaymentId && <Fact label="Gateway payment" value={order.providerPaymentId} />}
              {order.affiliateOrder && <Fact label="Affiliate order" value={<OrderStatusBadge status={order.affiliateOrder.status as MlmOrderStatus} />} />}
            </dl>
            {order.refunds.map((r) => (
              <InlineMessage
                key={r.id}
                kind={r.status === 'failed' ? 'error' : r.status === 'succeeded' ? 'info' : 'warn'}
                title={`Refund: ${REFUND_LABEL[r.status]}`}
              >
                {formatMoney(r.amount, order.currency)} · {r.reason} · {formatMoment(r.settledAt ?? r.createdAt)}
                {r.failureMessage ? ` · ${r.failureMessage}` : ''}
              </InlineMessage>
            ))}
          </div>
        )}
      </Drawer>

      <ConfirmDialog
        open={refunding}
        onClose={() => setRefunding(false)}
        onConfirm={refund}
        title={order ? `Refund ${order.orderNumber}?` : ''}
        confirmLabel={order ? `Refund ${formatMoney(order.amount, order.currency)}` : 'Refund'}
        tone="danger"
        blocked={reason.trim().length < 3}
      >
        <p>
          The whole amount goes back through the gateway. The learner’s access to the course ends, and any CV this sale earned is taken back. This cannot be
          undone.
        </p>
        <Field label="Why" hint="At least a few words. Kept on the order and in the activity log.">
          <Input id="refund-reason" value={reason} onChange={(e) => setReason(e.target.value)} maxLength={200} />
        </Field>
        <Field label="Note" optional>
          <Textarea id="refund-note" rows={2} value={note} onChange={(e) => setNote(e.target.value)} maxLength={1000} />
        </Field>
      </ConfirmDialog>
    </div>
  );
}
