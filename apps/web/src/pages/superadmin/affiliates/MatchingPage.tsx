import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Play } from '@phosphor-icons/react';
import {
  formatMoney,
  MLM_COMMISSION_KIND_LABEL,
  MLM_COMMISSION_STATUS_LABEL,
  type MlmCommissionRow,
  type MlmCommissionStatus,
  type MlmMatchingRunRow,
} from '@syniastrolms/domain';
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
import { ActionDialog, Pager, type Pending } from './earningsParts';
import styles from './Affiliates.module.css';

const inr = (n: number) => formatMoney(n, 'INR');
const cv = (n: number) => `${(n / 100).toLocaleString('en-IN')} CV`;

/** Matching runs and the commissions they produced (docs/15 §6.5, §6.7). A run happens once per member and day, so running it again changes nothing. */
export default function MatchingPage() {
  const toast = useToast();
  const [params, setParams] = useSearchParams();
  const view = params.get('view') === 'commissions' ? 'commissions' : 'runs';
  const status = (params.get('status') as MlmCommissionStatus | null) ?? undefined;
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
  const runs = useAsync(`mlm:runs:${page}:${view}`, () => (view === 'runs' ? services.platformEarnings.matchingRuns({ page }) : Promise.resolve(null)));
  const commissions = useAsync(`mlm:commissions:${status ?? ''}:${page}:${view}`, () =>
    view === 'commissions' ? services.platformEarnings.commissions({ status, page }) : Promise.resolve(null),
  );
  const [pending, setPending] = useState<Pending | null>(null);
  const [running, setRunning] = useState(false);
  const refresh = () => Promise.all([runs.run(), commissions.run()]);

  const runNow = async () => {
    setRunning(true);
    try {
      const out = await services.platformEarnings.runMatching();
      toast({ kind: 'success', title: `Today’s run covered ${out.matched} members`, text: `${inr(out.paid)} paid to wallets, ${inr(out.held)} held.` });
      await refresh();
    } catch (err) {
      toast({ kind: 'error', title: 'The run didn’t start', text: (err as Error).message });
    } finally {
      setRunning(false);
    }
  };

  const runColumns: Column<MlmMatchingRunRow>[] = [
    { key: 'member', header: 'Member', mobile: 'primary', render: (r) => `${r.affiliate.name} · ${r.affiliate.code}` },
    { key: 'date', header: 'Day', width: '110px', mobile: 'meta', render: (r) => r.runDate },
    { key: 'matched', header: 'Matched', mobile: 'detail', render: (r) => cv(r.matchedCv) },
    { key: 'gross', header: 'Before cap', mobile: 'detail', render: (r) => inr(r.grossIncome) },
    { key: 'paid', header: 'After cap', mobile: 'detail', render: (r) => inr(r.cappedIncome) },
    { key: 'flushed', header: 'Flushed', mobile: 'detail', render: (r) => cv(r.flushedCv) },
    { key: 'carry', header: 'Carried A / B', mobile: 'detail', render: (r) => `${cv(r.carryAAfter)} / ${cv(r.carryBAfter)}` },
    { key: 'held', header: 'Held', mobile: 'detail', render: (r) => inr(r.heldByCeiling) },
  ];
  const commissionColumns: Column<MlmCommissionRow>[] = [
    { key: 'member', header: 'Member', mobile: 'primary', render: (c) => `${c.affiliate.name} · ${c.affiliate.code}` },
    { key: 'kind', header: 'Kind', width: '120px', mobile: 'meta', render: (c) => MLM_COMMISSION_KIND_LABEL[c.kind] },
    { key: 'amount', header: 'Amount', width: '120px', mobile: 'detail', render: (c) => inr(c.amount) },
    {
      key: 'status',
      header: 'Status',
      width: '170px',
      mobile: 'status',
      render: (c) => (
        <Badge size="sm" tone={c.status === 'held' ? 'warn' : c.status === 'written_off' ? 'neutral' : 'accent'}>
          {MLM_COMMISSION_STATUS_LABEL[c.status]}
        </Badge>
      ),
    },
    { key: 'date', header: 'Date', width: '150px', mobile: 'detail', render: (c) => formatMoment(c.createdAt) },
    {
      key: 'actions',
      header: 'Actions',
      align: 'end',
      mobile: 'detail',
      render: (c) =>
        c.status === 'held' ? (
          <span className={styles.rowActions}>
            <Button
              size="sm"
              onClick={() =>
                setPending({
                  title: `Release ${inr(c.amount)}?`,
                  text: 'This pays the commission into the member’s wallet now, even if the month is above its ceiling.',
                  confirmLabel: 'Release',
                  input: { label: 'Why', min: 3, multiline: true },
                  run: (reason) => services.platformEarnings.releaseCommission(c.id, reason),
                  done: 'Commission released',
                })
              }
            >
              Release
            </Button>
            <Button
              size="sm"
              onClick={() =>
                setPending({
                  title: `Write off ${inr(c.amount)}?`,
                  text: 'The member will never receive this commission. The record stays. This cannot be undone.',
                  confirmLabel: 'Write off',
                  tone: 'danger',
                  input: { label: 'Why', min: 3, multiline: true },
                  run: (reason) => services.platformEarnings.writeOffCommission(c.id, reason),
                  done: 'Commission written off',
                })
              }
            >
              Write off
            </Button>
          </span>
        ) : null,
    },
  ];

  const active = view === 'runs' ? runs : commissions;
  const data = active.data;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Matching"
        description="The daily run pays each member’s matched volume up to their rank’s cap. Earnings above the company’s ceiling wait on hold."
        actions={
          <Button variant="primary" iconStart={<Play size={16} />} loading={running} onClick={() => void runNow()}>
            Run today
          </Button>
        }
      />
      <AffiliateTabs />
      <PrototypeNote>The demo build moves no money, so there are no runs here.</PrototypeNote>
      <div className={styles.controls}>
        <SegmentedControl<'runs' | 'commissions'>
          label="View"
          value={view}
          onChange={(v) => go({ view: v === 'runs' ? undefined : v, status: undefined })}
          segments={[
            { value: 'runs', label: 'Runs' },
            { value: 'commissions', label: 'Commissions' },
          ]}
        />
        {view === 'commissions' && (
          <SegmentedControl<MlmCommissionStatus | 'all'>
            label="Status"
            value={status ?? 'all'}
            onChange={(v) => go({ status: v })}
            segments={[
              { value: 'all', label: 'All' },
              { value: 'paid_to_wallet', label: 'In wallet' },
              { value: 'held', label: 'On hold' },
              { value: 'written_off', label: 'Written off' },
            ]}
          />
        )}
      </div>
      {active.status === 'error' && !data ? (
        <PlatformError title="This list didn’t load" error={active.error} onRetry={() => void active.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={280} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title={view === 'runs' ? 'No runs yet' : 'No commissions here'}>
          {view === 'runs' ? 'A run appears once a member has volume on both legs.' : 'Commissions appear after a matching run or a paid reward.'}
        </StateMessage>
      ) : (
        <>
          {view === 'runs' ? (
            <DataTable<MlmMatchingRunRow>
              rows={runs.data?.rows ?? []}
              columns={runColumns}
              rowKey={(r) => r.id}
              label="Matching runs"
              rowLabel={(r) => `${r.affiliate.code} ${r.runDate}`}
              framed
            />
          ) : (
            <DataTable<MlmCommissionRow>
              rows={commissions.data?.rows ?? []}
              columns={commissionColumns}
              rowKey={(c) => c.id}
              label="Commissions"
              rowLabel={(c) => `${c.affiliate.code} ${c.kind}`}
              framed
            />
          )}
          <Pager page={page} pageSize={data.pageSize} total={data.total} onPage={(n) => go({ page: String(n) })} />
        </>
      )}
      <ActionDialog pending={pending} onClose={() => setPending(null)} onDone={refresh} />
    </div>
  );
}
