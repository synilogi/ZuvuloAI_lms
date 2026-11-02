import { useSearchParams } from 'react-router-dom';
import {
  formatMoney,
  MLM_COMMISSION_KIND_LABEL,
  MLM_COMMISSION_STATUS_LABEL,
  MLM_REWARD_STATUS_LABEL,
  type MlmCommissionRow,
  type MlmMatchingRunRow,
  type MlmRankHistoryRow,
  type MlmRewardRow,
} from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useAsync } from '@/hooks/useAsync';
import { formatDate, formatMoment } from '@/lib/format';
import { Pager } from '@/pages/superadmin/affiliates/earningsParts';
import { services, ServiceError } from '@/services';
import { AffiliateNav } from './affiliateNav';
import styles from './Affiliate.module.css';

const inr = (n: number) => formatMoney(n, 'INR');
const cv = (n: number) => `${(n / 100).toLocaleString('en-IN')} CV`;
type View = 'commissions' | 'matching' | 'rewards' | 'ranks';

/** The member's own record to date: what was earned and why. It shows what has happened, and never estimates what might. */
export default function AffiliateEarningsPage() {
  const [params, setParams] = useSearchParams();
  const view = (params.get('view') as View | null) ?? 'commissions';
  const summary = useAsync('affiliate:earnings', () => services.affiliateEarnings.earnings());
  const page = Math.max(1, Number(params.get('page')) || 1);
  const list = useAsync(`affiliate:earnings:${view}:${page}`, async () => {
    const e = services.affiliateEarnings;
    const query = { page, pageSize: 50 };
    if (view === 'matching') return { matching: await e.matchingRuns(query) };
    if (view === 'rewards') return { rewards: await e.rewards(query) };
    if (view === 'ranks') return { ranks: await e.rankHistory(query) };
    return { commissions: await e.commissions(query) };
  });

  if (summary.status === 'error' && summary.error instanceof ServiceError && summary.error.reason === 'NOT_AN_AFFILIATE') {
    return (
      <div className={styles.page}>
        <PageHeader title="Earnings" />
        <StateMessage title="You’re not in the affiliate program yet" actions={<LinkButton to="/affiliate">Open the overview</LinkButton>}>
          You can read about it and join from the overview.
        </StateMessage>
      </div>
    );
  }
  const s = summary.data;
  const next = s?.progress.next;

  const commissionColumns: Column<MlmCommissionRow>[] = [
    { key: 'kind', header: 'What', mobile: 'primary', render: (c) => MLM_COMMISSION_KIND_LABEL[c.kind] },
    { key: 'amount', header: 'Amount', mobile: 'meta', render: (c) => inr(c.amount) },
    {
      key: 'status',
      header: 'Status',
      mobile: 'status',
      render: (c) => (
        <Badge size="sm" tone={c.status === 'held' ? 'warn' : c.status === 'written_off' ? 'neutral' : 'accent'}>
          {MLM_COMMISSION_STATUS_LABEL[c.status]}
        </Badge>
      ),
    },
    { key: 'date', header: 'Date', mobile: 'detail', render: (c) => formatMoment(c.createdAt) },
  ];
  const runColumns: Column<MlmMatchingRunRow>[] = [
    { key: 'date', header: 'Day', mobile: 'primary', render: (r) => r.runDate },
    { key: 'matched', header: 'Matched', mobile: 'detail', render: (r) => cv(r.matchedCv) },
    { key: 'paid', header: 'Income', mobile: 'meta', render: (r) => inr(r.cappedIncome) },
    { key: 'flushed', header: 'Above your daily limit', mobile: 'detail', render: (r) => cv(r.flushedCv) },
    { key: 'carry', header: 'Carried A / B', mobile: 'detail', render: (r) => `${cv(r.carryAAfter)} / ${cv(r.carryBAfter)}` },
  ];
  const rewardColumns: Column<MlmRewardRow>[] = [
    { key: 'rank', header: 'Rank', mobile: 'primary', render: (r) => r.tierName },
    {
      key: 'reward',
      header: 'Reward',
      mobile: 'meta',
      render: (r) =>
        r.kind === 'cash'
          ? r.capAmount !== null && r.status === 'qualified'
            ? 'Decided on approval'
            : inr(r.amount)
          : r.kind === 'certificate'
            ? 'Certificate'
            : 'Recognition',
    },
    {
      key: 'status',
      header: 'Status',
      mobile: 'status',
      render: (r) => (
        <Badge size="sm" tone={r.status === 'paid' ? 'accent' : r.status === 'rejected' ? 'neutral' : 'info'}>
          {MLM_REWARD_STATUS_LABEL[r.status]}
        </Badge>
      ),
    },
    { key: 'vests', header: 'Vests', mobile: 'detail', render: (r) => (r.vestsAt ? formatDate(r.vestsAt) : '') },
  ];
  const rankColumns: Column<MlmRankHistoryRow>[] = [
    { key: 'rank', header: 'Rank', mobile: 'primary', render: (r) => r.tierName },
    { key: 'date', header: 'Reached', mobile: 'meta', render: (r) => formatMoment(r.achievedAt) },
  ];
  const d = list.data;
  const empty = d && (d.commissions?.rows.length === 0 || d.matching?.rows.length === 0 || d.rewards?.rows.length === 0 || d.ranks?.rows.length === 0);
  const shown = d?.commissions ?? d?.matching ?? d?.rewards ?? d?.ranks;

  return (
    <div className={styles.page}>
      <PageHeader title="Earnings" description="Your record to date. Income depends on verified sales and the plan rules, and it is not guaranteed." />
      <AffiliateNav />
      {summary.status === 'error' && !s ? (
        <StateMessage
          kind="error"
          title="Your earnings didn’t load"
          actions={<Button onClick={() => void summary.run().catch(() => undefined)}>Try again</Button>}
        >
          {summary.error.message}
        </StateMessage>
      ) : !s ? (
        <Skeleton height={140} radius="var(--r-lg)" />
      ) : (
        <>
          <section className={styles.figures} aria-label="Your totals">
            <div className={styles.figure}>
              <span className={styles.factLabel}>Matching income to date</span>
              <strong className={styles.figureValue}>{inr(s.matchingIncome)}</strong>
            </div>
            <div className={styles.figure}>
              <span className={styles.factLabel}>Rewards to date</span>
              <strong className={styles.figureValue}>{inr(s.rewardIncome)}</strong>
            </div>
            <div className={styles.figure}>
              <span className={styles.factLabel}>Held by payout policy</span>
              <strong className={styles.figureValue}>{inr(s.wallet.heldByPolicy)}</strong>
            </div>
          </section>
          <section className={styles.panel} aria-labelledby="rank-progress">
            <h2 id="rank-progress" className={styles.panelTitle}>
              Your rank: {s.progress.current?.name ?? 'None yet'}
            </h2>
            {next ? (
              <p className={styles.muted}>
                {next.name} needs {cv(next.legRequired)} on each leg. Leg A has {cv(s.lifetimeA)}, leg B has {cv(s.lifetimeB)}. Volume above that on one leg
                does not count for the other.
              </p>
            ) : (
              <p className={styles.muted}>You have reached the plan’s highest rank.</p>
            )}
          </section>
        </>
      )}
      <SegmentedControl<View>
        label="Show"
        value={view}
        onChange={(v) => setParams(v === 'commissions' ? {} : { view: v }, { replace: true })}
        segments={[
          { value: 'commissions', label: 'Commissions' },
          { value: 'matching', label: 'Matching' },
          { value: 'rewards', label: 'Rewards' },
          { value: 'ranks', label: 'Rank history' },
        ]}
      />
      {list.status === 'error' && !d ? (
        <StateMessage kind="error" title="This list didn’t load" actions={<Button onClick={() => void list.run().catch(() => undefined)}>Try again</Button>}>
          {list.error.message}
        </StateMessage>
      ) : !d ? (
        <Skeleton height={200} radius="var(--r-lg)" />
      ) : empty ? (
        <StateMessage title="Nothing here yet">Entries appear here as verified sales are matched.</StateMessage>
      ) : (
        <>
          {d.commissions && (
            <DataTable<MlmCommissionRow>
              rows={d.commissions.rows}
              columns={commissionColumns}
              rowKey={(r) => r.id}
              label="Commissions"
              rowLabel={(r) => r.kind}
              framed
            />
          )}
          {d.matching && (
            <DataTable<MlmMatchingRunRow>
              rows={d.matching.rows}
              columns={runColumns}
              rowKey={(r) => r.id}
              label="Matching runs"
              rowLabel={(r) => r.runDate}
              framed
            />
          )}
          {d.rewards && (
            <DataTable<MlmRewardRow> rows={d.rewards.rows} columns={rewardColumns} rowKey={(r) => r.id} label="Rewards" rowLabel={(r) => r.tierName} framed />
          )}
          {d.ranks && (
            <DataTable<MlmRankHistoryRow>
              rows={d.ranks.rows}
              columns={rankColumns}
              rowKey={(r) => r.id}
              label="Rank history"
              rowLabel={(r) => r.tierName}
              framed
            />
          )}
          {shown && (
            <Pager
              page={page}
              pageSize={shown.pageSize}
              total={shown.total}
              onPage={(n) => {
                const p = new URLSearchParams(params);
                p.set('page', String(n));
                setParams(p, { replace: true });
              }}
            />
          )}
        </>
      )}
    </div>
  );
}
