import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { DownloadSimple, Stack } from '@phosphor-icons/react';
import { formatMoney, MLM_WITHDRAWAL_STATUS_LABEL, type MlmPayoutBatchRow, type MlmWithdrawalRow, type MlmWithdrawalStatus } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment } from '@/lib/format';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AffiliateTabs } from './affiliateMeta';
import { ActionDialog, Pager, saveCsv, type Pending } from './earningsParts';
import styles from './Affiliates.module.css';

const inr = (n: number) => formatMoney(n, 'INR');
const TONE: Record<MlmWithdrawalStatus, 'info' | 'accent' | 'warn' | 'neutral'> = {
  requested: 'info',
  approved: 'info',
  processing: 'warn',
  paid: 'accent',
  rejected: 'neutral',
  cancelled: 'neutral',
};

/**
 * Withdrawals and payout batches (docs/15 §6.9, D-MLM-16). The company pays by bank or UPI by hand: there is no payout API. A
 * batch groups approved requests into a bank file, and each is marked paid with its bank reference.
 */
export default function WithdrawalsPage() {
  const toast = useToast();
  const [params, setParams] = useSearchParams();
  const view = params.get('view') === 'payouts' ? 'payouts' : 'withdrawals';
  const status = (params.get('status') as MlmWithdrawalStatus | null) ?? undefined;
  const page = Math.max(1, Number(params.get('page')) || 1);
  const go = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || v === 'all') p.delete(k);
      else p.set(k, v);
    }
    if (!('page' in next)) p.delete('page');
    setParams(p, { replace: true });
  };
  const list = useAsync(`mlm:withdrawals:${status ?? ''}:${page}`, () => services.platformEarnings.withdrawals({ status, page }));
  const batches = useAsync('mlm:payouts', () => services.platformEarnings.payouts());
  const [pending, setPending] = useState<Pending | null>(null);
  const refresh = () => Promise.all([list.run(), batches.run()]);
  const approved = (list.data?.rows ?? []).filter((w) => w.status === 'approved');

  const columns: Column<MlmWithdrawalRow>[] = [
    {
      key: 'member',
      header: 'Member',
      mobile: 'primary',
      render: (w) => (
        <span className={styles.stack}>
          <span>
            {w.affiliate.name} · {w.affiliate.code}
          </span>
          <span className={styles.cellMeta}>
            {w.bank.accountHolder} · ••••{w.bank.accountLast4} · {w.bank.ifsc}
          </span>
        </span>
      ),
    },
    { key: 'amount', header: 'Amount', mobile: 'meta', render: (w) => inr(w.amount) },
    {
      key: 'net',
      header: 'To pay',
      mobile: 'detail',
      render: (w) => (w.tdsAmount > 0 ? `${inr(w.netAmount)} after ${inr(w.tdsAmount)} tax` : inr(w.netAmount)),
    },
    {
      key: 'status',
      header: 'Status',
      mobile: 'status',
      render: (w) => (
        <Badge size="sm" tone={TONE[w.status]}>
          {MLM_WITHDRAWAL_STATUS_LABEL[w.status]}
        </Badge>
      ),
    },
    { key: 'date', header: 'Requested', mobile: 'detail', render: (w) => formatMoment(w.createdAt) },
    {
      key: 'actions',
      header: 'Actions',
      align: 'end',
      mobile: 'detail',
      render: (w) => (
        <span className={styles.rowActions}>
          {w.status === 'requested' && (
            <Button
              size="sm"
              onClick={() =>
                setPending({
                  title: `Approve ${inr(w.amount)} for ${w.affiliate.name}?`,
                  text: 'The amount stays held until you mark it paid.',
                  confirmLabel: 'Approve',
                  run: () => services.platformEarnings.approveWithdrawal(w.id),
                  done: 'Withdrawal approved',
                })
              }
            >
              Approve
            </Button>
          )}
          {(w.status === 'approved' || w.status === 'processing') && (
            <Button
              size="sm"
              variant="primary"
              onClick={() =>
                setPending({
                  title: `Mark ${inr(w.netAmount)} paid?`,
                  text: 'Do this only after the money has reached the member. This cannot be undone.',
                  confirmLabel: 'Mark paid',
                  input: { label: 'Bank reference', hint: 'The UTR or transaction reference.', min: 3 },
                  run: (reference) => services.platformEarnings.markWithdrawalPaid(w.id, reference),
                  done: 'Withdrawal marked paid',
                })
              }
            >
              Mark paid
            </Button>
          )}
          {(w.status === 'requested' || w.status === 'approved' || w.status === 'processing') && (
            <Button
              size="sm"
              onClick={() =>
                setPending({
                  title: `Reject ${inr(w.amount)} for ${w.affiliate.name}?`,
                  text:
                    w.status === 'processing'
                      ? 'If the bank file has gone to the bank, check that this was not paid first: rejecting gives the money back, and it could be paid twice. The amount returns to the member’s available balance.'
                      : 'The amount goes back to the member’s available balance, and they are told.',
                  confirmLabel: 'Reject',
                  tone: 'danger',
                  input: { label: 'Why', min: 3, multiline: true },
                  run: (reason) => services.platformEarnings.rejectWithdrawal(w.id, reason, w.status === 'processing'),
                  done: 'Withdrawal rejected',
                })
              }
            >
              Reject
            </Button>
          )}
        </span>
      ),
    },
  ];
  const batchColumns: Column<MlmPayoutBatchRow>[] = [
    { key: 'reference', header: 'Batch', mobile: 'primary', render: (b) => b.reference },
    { key: 'count', header: 'Withdrawals', mobile: 'detail', render: (b) => b.count },
    { key: 'total', header: 'Total', mobile: 'meta', render: (b) => inr(b.total) },
    { key: 'date', header: 'Created', mobile: 'detail', render: (b) => formatMoment(b.createdAt) },
    {
      key: 'status',
      header: 'Status',
      mobile: 'status',
      render: (b) => (
        <Badge size="sm" tone={b.closedAt ? 'neutral' : 'warn'}>
          {b.closedAt ? 'Closed' : 'Open'}
        </Badge>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      align: 'end',
      mobile: 'detail',
      render: (b) => (
        <span className={styles.rowActions}>
          <Button
            size="sm"
            iconStart={<DownloadSimple size={14} />}
            onClick={() =>
              services.platformEarnings.payoutCsv(b.id).then(
                (csv) => saveCsv(csv, `${b.reference}.csv`),
                (err: Error) => toast({ kind: 'error', title: 'The export didn’t work', text: err.message }),
              )
            }
          >
            Bank file
          </Button>
          {!b.closedAt && (
            <Button
              size="sm"
              onClick={() =>
                setPending({
                  title: `Close ${b.reference}?`,
                  text: 'Every withdrawal in it must already be marked paid or rejected.',
                  confirmLabel: 'Close batch',
                  run: () => services.platformEarnings.closePayout(b.id),
                  done: 'Batch closed',
                })
              }
            >
              Close
            </Button>
          )}
        </span>
      ),
    },
  ];
  const data = list.data;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Withdrawals and payouts"
        description="Approve requests, group them into a bank file, pay them by hand, then enter each reference."
        actions={
          view === 'withdrawals' && approved.length > 0 ? (
            <Button
              variant="primary"
              iconStart={<Stack size={16} />}
              onClick={() =>
                setPending({
                  title: `Group ${approved.length} approved withdrawals into a batch?`,
                  text: 'The bank file then holds their full account numbers, and each download is logged.',
                  confirmLabel: 'Create batch',
                  run: () => services.platformEarnings.createPayout(approved.map((w) => w.id)),
                  done: 'Batch created',
                })
              }
            >
              Create batch
            </Button>
          ) : undefined
        }
      />
      <AffiliateTabs />
      <PrototypeNote>The demo build moves no money, so there are no withdrawals here.</PrototypeNote>
      <div className={styles.controls}>
        <SegmentedControl<'withdrawals' | 'payouts'>
          label="View"
          value={view}
          onChange={(v) => go({ view: v === 'withdrawals' ? undefined : v, status: undefined })}
          segments={[
            { value: 'withdrawals', label: 'Withdrawals' },
            { value: 'payouts', label: 'Payout batches' },
          ]}
        />
        {view === 'withdrawals' && (
          <SegmentedControl<MlmWithdrawalStatus | 'all'>
            label="Status"
            value={status ?? 'all'}
            onChange={(v) => go({ status: v })}
            segments={[
              { value: 'all', label: 'All' },
              { value: 'requested', label: 'Requested' },
              { value: 'approved', label: 'Approved' },
              { value: 'processing', label: 'In a batch' },
              { value: 'paid', label: 'Paid' },
              { value: 'rejected', label: 'Rejected' },
            ]}
          />
        )}
      </div>
      {view === 'withdrawals' ? (
        list.status === 'error' && !data ? (
          <PlatformError title="The withdrawals didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
        ) : !data ? (
          <Skeleton height={280} radius="var(--r-lg)" />
        ) : data.rows.length === 0 ? (
          <StateMessage title="No withdrawals here">A request appears when a verified member asks to withdraw.</StateMessage>
        ) : (
          <>
            <DataTable<MlmWithdrawalRow>
              rows={data.rows}
              columns={columns}
              rowKey={(w) => w.id}
              label="Withdrawals"
              rowLabel={(w) => w.affiliate.code}
              framed
            />
            <Pager page={page} pageSize={data.pageSize} total={data.total} onPage={(n) => go({ page: String(n) })} />
          </>
        )
      ) : batches.status === 'error' && !batches.data ? (
        <PlatformError title="The batches didn’t load" error={batches.error} onRetry={() => void batches.run().catch(() => undefined)} />
      ) : !batches.data ? (
        <Skeleton height={200} radius="var(--r-lg)" />
      ) : batches.data.length === 0 ? (
        <StateMessage title="No payout batches yet">Approve some withdrawals, then create a batch.</StateMessage>
      ) : (
        <DataTable<MlmPayoutBatchRow>
          rows={batches.data}
          columns={batchColumns}
          rowKey={(b) => b.id}
          label="Payout batches"
          rowLabel={(b) => b.reference}
          framed
        />
      )}
      <ActionDialog pending={pending} onClose={() => setPending(null)} onDone={refresh} />
    </div>
  );
}
