import { useState, type ReactNode } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { ArrowCounterClockwise } from '@phosphor-icons/react';
import type { MlmOrderRow, MlmOrderStatus, MlmReversalReason } from '@syniastrolms/domain';
import { formatMoney } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select, Textarea } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Drawer } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AFFILIATES_BASE, AffiliateTabs, OrderStatusBadge } from './affiliateMeta';
import styles from './Affiliates.module.css';

const REASON_LABEL: Record<MlmReversalReason, string> = { refund: 'Refunded', chargeback: 'Charged back', manual: 'Corrected by hand' };

/** Every verified sale of an eligible course (MLM-003): who bought, what it credited, and a reversal by hand when the gateway refunded it. */
export default function OrdersPage() {
  const toast = useToast();
  const [params, setParams] = useSearchParams();
  const status = (params.get('status') as MlmOrderStatus | null) ?? undefined;
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
  const list = useAsync(`affiliates:orders:${status ?? ''}:${search}:${page}`, () =>
    services.affiliatesPlatform.orders({ status, search: search || undefined, page, pageSize: 20 }),
  );
  const data = list.data;
  const [open, setOpen] = useState<MlmOrderRow | null>(null);
  const [reversing, setReversing] = useState<MlmOrderRow | null>(null);
  const [reason, setReason] = useState<MlmReversalReason>('refund');
  const [note, setNote] = useState('');

  const reverse = async () => {
    if (!reversing) return;
    const updated = await services.affiliatesPlatform.reverseOrder(reversing.id, reason, note.trim() || undefined);
    toast({
      kind: 'success',
      title: 'Order reversed',
      text: updated.creditedAncestors ? `The credits to ${plural(updated.creditedAncestors, 'affiliate')} were taken back.` : 'Nobody had been credited.',
    });
    setReversing(null);
    setNote('');
    if (open?.id === updated.id) setOpen(updated);
    await list.run();
  };

  const columns: Column<MlmOrderRow>[] = [
    {
      key: 'buyer',
      header: 'Buyer',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <button type="button" className={styles.cellTitle} onClick={() => setOpen(r)}>
            {r.buyer.name}
          </button>
          <span className={styles.cellMeta}>{r.buyer.affiliateCode ?? 'Outside the program'}</span>
        </span>
      ),
    },
    { key: 'course', header: 'Course', mobile: 'detail', render: (r) => r.course.title },
    { key: 'cv', header: 'CV', width: '120px', mobile: 'meta', render: (r) => <span className={styles.amount}>{formatMoney(r.cv, r.currency)}</span> },
    {
      key: 'credited',
      header: 'Credited',
      width: '100px',
      mobile: 'detail',
      render: (r) => (r.creditedAncestors ? plural(r.creditedAncestors, 'leg') : <span className={styles.faint}>Nobody</span>),
    },
    { key: 'status', header: 'Status', width: '110px', mobile: 'status', render: (r) => <OrderStatusBadge status={r.status} /> },
    {
      key: 'paid',
      header: 'Paid',
      width: '150px',
      mobile: 'detail',
      render: (r) => (
        <time dateTime={r.paidAt} className={styles.nowrap}>
          {formatMoment(r.paidAt)}
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
        description="Verified purchases of eligible courses. Each one activates its buyer and credits its CV up the tree; a refund takes those credits back."
      />
      <AffiliateTabs />
      <PrototypeNote>Demo sales derived from the demo network.</PrototypeNote>
      <div className={styles.controls}>
        <SegmentedControl<MlmOrderStatus | 'all'>
          label="Status"
          value={status ?? 'all'}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: data?.counts.all },
            { value: 'eligible', label: 'Counted', count: data?.counts.eligible },
            { value: 'pending', label: 'Waiting', count: data?.counts.pending },
            { value: 'reversed', label: 'Reversed', count: data?.counts.reversed },
          ]}
        />
        <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Buyer’s name, email or code" aria-label="Search orders" />
      </div>
      {list.status === 'error' && !data ? (
        <PlatformError title="The orders didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title={data.counts.all === 0 ? 'No orders yet' : 'Nothing matches'}>
          {data.counts.all === 0 ? 'Orders appear here as learners buy an eligible course with a verified payment.' : 'Try another status or search.'}
        </StateMessage>
      ) : (
        <>
          <DataTable<MlmOrderRow>
            rows={data.rows}
            columns={columns}
            rowKey={(r) => r.id}
            label="Orders"
            rowLabel={(r) => `${r.buyer.name}, ${r.course.title}`}
            framed
          />
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
        open={open !== null}
        onClose={() => setOpen(null)}
        title={open ? open.buyer.name : ''}
        eyebrow="Order"
        footer={
          open && open.status !== 'reversed' ? (
            <Button variant="danger" iconStart={<ArrowCounterClockwise size={16} />} onClick={() => setReversing(open)}>
              Reverse this order
            </Button>
          ) : undefined
        }
      >
        {open && <OrderFacts order={open} />}
      </Drawer>

      <ConfirmDialog
        open={reversing !== null}
        onClose={() => setReversing(null)}
        onConfirm={reverse}
        title={reversing ? `Reverse ${reversing.buyer.name}’s order?` : ''}
        confirmLabel="Reverse the order"
        tone="danger"
      >
        <p>
          Every credit this sale made is taken back, leg by leg, and nothing from it can be matched or counted towards a rank again. The buyer’s enrolment is
          the platform’s business and is not touched. This cannot be undone.
        </p>
        <Field label="Why">
          <Select id="reverse-reason" value={reason} onChange={(e) => setReason(e.target.value as MlmReversalReason)}>
            <option value="refund">Refunded at the gateway</option>
            <option value="chargeback">Chargeback</option>
            <option value="manual">Correction by hand</option>
          </Select>
        </Field>
        <Field label="Note" optional hint="For the activity log.">
          <Textarea id="reverse-note" rows={2} value={note} onChange={(e) => setNote(e.target.value)} maxLength={500} />
        </Field>
      </ConfirmDialog>
    </div>
  );
}

function OrderFacts({ order }: { order: MlmOrderRow }) {
  return (
    <dl className={styles.facts}>
      <Fact label="Status" value={<OrderStatusBadge status={order.status} />} />
      <Fact label="Course" value={order.course.title} />
      <Fact label="Net amount" value={formatMoney(order.netAmount, order.currency)} />
      <Fact label="CV" value={formatMoney(order.cv, order.currency)} />
      <Fact
        label="Buyer"
        value={
          order.buyer.affiliateCode ? (
            <>
              {order.buyer.email} ·{' '}
              <Link to={`${AFFILIATES_BASE}/members?q=${encodeURIComponent(order.buyer.affiliateCode)}`}>{order.buyer.affiliateCode}</Link>
            </>
          ) : (
            `${order.buyer.email} · not in the program`
          )
        }
      />
      <Fact label="Sponsor at the sale" value={order.sponsorCodeAtSale ?? 'None'} />
      <Fact label="Credited" value={order.creditedAncestors ? `${plural(order.creditedAncestors, 'affiliate')} above the buyer` : 'Nobody'} />
      <Fact label="Plan version" value={String(order.planVersion)} />
      <Fact label="Paid" value={formatMoment(order.paidAt)} />
      <Fact label="Counted from" value={order.eligibleAt ? formatMoment(order.eligibleAt) : 'Not yet (waiting for the delay or the placement)'} />
      {order.reversedAt && (
        <Fact label="Reversed" value={`${formatMoment(order.reversedAt)} · ${order.reversalReason ? REASON_LABEL[order.reversalReason] : ''}`} />
      )}
      <Fact label="Purchase" value={<span className={styles.mono}>{order.purchaseId}</span>} />
    </dl>
  );
}

function Fact({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className={styles.fact}>
      <dt className={styles.factLabel}>{label}</dt>
      <dd className={styles.factValue}>{value}</dd>
    </div>
  );
}
