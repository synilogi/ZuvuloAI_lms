import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { formatMoney, MLM_REWARD_STATUS_LABEL, type MlmRewardRow, type MlmRewardStatus } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AffiliateTabs, REWARD_KIND_LABEL } from './affiliateMeta';
import { ActionDialog, Pager, type Pending } from './earningsParts';
import styles from './Affiliates.module.css';

const inr = (n: number) => formatMoney(n, 'INR');

/** Parses rupees typed by a person into paise, or undefined. */
export const rupeesToPaise = (text: string): number | undefined => {
  const n = Number(text.replace(/,/g, '').trim());
  return Number.isFinite(n) && n > 0 ? Math.round(n * 100) : undefined;
};

/** Rewards (docs/15 §6.6): approval, vesting, funding, payment, each a person's decision, in that order. The ranks behind them are on the Ranks page. */
export default function RewardsPage() {
  const [params, setParams] = useSearchParams();
  const status = (params.get('status') as MlmRewardStatus | null) ?? undefined;
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
  const rewards = useAsync(`mlm:rewards:${status ?? ''}:${page}`, () => services.platformEarnings.rewards({ status, page }));
  const [pending, setPending] = useState<Pending | null>(null);

  const reject = (r: MlmRewardRow): Pending => ({
    title: `Reject ${r.tierName} for ${r.affiliate.name}?`,
    text: 'The reward will not be paid. The rank stays. This cannot be undone.',
    confirmLabel: 'Reject',
    tone: 'danger',
    input: { label: 'Why', min: 3, multiline: true },
    run: (reason) => services.platformEarnings.rejectReward(r.id, reason),
    done: 'Reward rejected',
  });
  const approve = (r: MlmRewardRow): Pending =>
    r.capAmount !== null
      ? {
          title: `Approve ${r.tierName} for ${r.affiliate.name}?`,
          text: `This reward is up to ${inr(r.capAmount)}. Enter the amount in rupees.`,
          confirmLabel: 'Approve',
          input: { label: 'Amount in rupees', min: 1 },
          run: (text) => {
            const amount = rupeesToPaise(text);
            if (amount === undefined) return Promise.reject(new Error('Enter an amount in rupees.'));
            return services.platformEarnings.approveReward(r.id, amount);
          },
          done: 'Reward approved',
        }
      : {
          title: `Approve ${r.tierName} for ${r.affiliate.name}?`,
          text:
            r.kind === 'cash'
              ? `${inr(r.amount)} moves on to vesting and funding. Nothing is paid yet.`
              : `This ${REWARD_KIND_LABEL[r.kind].toLowerCase()} is complete once approved.`,
          confirmLabel: 'Approve',
          run: () => services.platformEarnings.approveReward(r.id),
          done: 'Reward approved',
        };

  const columns: Column<MlmRewardRow>[] = [
    {
      key: 'member',
      header: 'Member',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <span>
            {r.affiliate.name} · {r.affiliate.code}
          </span>
          {r.note && <span className={styles.cellMeta}>{r.note}</span>}
        </span>
      ),
    },
    { key: 'rank', header: 'Rank', mobile: 'meta', render: (r) => r.tierName },
    {
      key: 'reward',
      header: 'Reward',
      mobile: 'detail',
      render: (r) =>
        r.kind !== 'cash' ? REWARD_KIND_LABEL[r.kind] : r.capAmount !== null && r.status === 'qualified' ? `Up to ${inr(r.capAmount)}` : inr(r.amount),
    },
    {
      key: 'status',
      header: 'Status',
      mobile: 'status',
      render: (r) => (
        <Badge size="sm" tone={r.needsReview ? 'warn' : r.status === 'paid' ? 'accent' : r.status === 'rejected' ? 'neutral' : 'info'}>
          {r.needsReview ? 'Paid · needs review' : MLM_REWARD_STATUS_LABEL[r.status]}
        </Badge>
      ),
    },
    { key: 'vests', header: 'Vests', width: '120px', mobile: 'detail', render: (r) => (r.vestsAt ? formatDate(r.vestsAt) : '') },
    {
      key: 'actions',
      header: '',
      align: 'end',
      mobile: 'detail',
      render: (r) => {
        const vesting = r.status === 'vesting' && r.vestsAt !== null && Date.parse(r.vestsAt) > Date.now();
        return (
          <span className={styles.rowActions}>
            {r.status === 'qualified' && (
              <Button size="sm" onClick={() => setPending(approve(r))}>
                Approve
              </Button>
            )}
            {(r.status === 'approved' || r.status === 'vesting') && (
              <Button
                size="sm"
                disabled={vesting}
                onClick={() =>
                  setPending({
                    title: `Mark ${inr(r.amount)} funded?`,
                    text: 'Confirm the money for this reward has been set aside.',
                    confirmLabel: 'Mark funded',
                    run: () => services.platformEarnings.fundReward(r.id),
                    done: 'Reward funded',
                  })
                }
              >
                Fund
              </Button>
            )}
            {r.status === 'funded' && (
              <Button
                size="sm"
                variant="primary"
                onClick={() =>
                  setPending({
                    title: `Pay ${inr(r.amount)} to ${r.affiliate.name}?`,
                    text: 'This credits the member’s wallet, subject to the month’s ceiling. Any amount above it waits on hold.',
                    confirmLabel: 'Pay reward',
                    run: () => services.platformEarnings.payReward(r.id),
                    done: 'Reward paid',
                  })
                }
              >
                Pay
              </Button>
            )}
            {r.status !== 'paid' && r.status !== 'rejected' && (
              <Button size="sm" onClick={() => setPending(reject(r))}>
                Reject
              </Button>
            )}
          </span>
        );
      },
    },
  ];

  const data = rewards.data;

  return (
    <div className={styles.page}>
      <PageHeader eyebrow={PLATFORM_EYEBROW} title="Rewards" description="A rank’s reward moves on only when you approve, fund and pay it." />
      <AffiliateTabs />
      <PrototypeNote>The demo build moves no money, so there are no rewards here.</PrototypeNote>
      <div className={styles.controls}>
        <SegmentedControl<MlmRewardStatus | 'all'>
          label="Status"
          value={status ?? 'all'}
          onChange={(v) => go({ status: v })}
          segments={[
            { value: 'all', label: 'All' },
            { value: 'qualified', label: 'To approve' },
            { value: 'vesting', label: 'Vesting' },
            { value: 'approved', label: 'To fund' },
            { value: 'funded', label: 'To pay' },
            { value: 'paid', label: 'Paid' },
            { value: 'rejected', label: 'Rejected' },
          ]}
        />
      </div>
      {rewards.status === 'error' && !data ? (
        <PlatformError title="This list didn’t load" error={rewards.error} onRetry={() => void rewards.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={280} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title="No rewards here">A reward appears when a member reaches a rank.</StateMessage>
      ) : (
        <>
          <DataTable<MlmRewardRow>
            rows={data.rows}
            columns={columns}
            rowKey={(r) => r.id}
            label="Rewards"
            rowLabel={(r) => `${r.affiliate.code} ${r.tierName}`}
            framed
          />
          <Pager page={page} pageSize={data.pageSize} total={data.total} onPage={(n) => go({ page: String(n) })} />
        </>
      )}
      <ActionDialog pending={pending} onClose={() => setPending(null)} onDone={() => rewards.run()} />
    </div>
  );
}
