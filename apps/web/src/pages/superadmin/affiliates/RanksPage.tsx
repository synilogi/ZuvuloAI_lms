import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { ArrowsClockwise } from '@phosphor-icons/react';
import { legCvOf, normaliseAffiliateCode, type MlmRankHistoryRow, type MlmRankTier } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment, plural } from '@/lib/format';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AffiliateTabs, compactCv, compactMoney, cvText, memberWithCode, REWARD_KIND_LABEL } from './affiliateMeta';
import { ActionDialog, Pager, type Pending } from './earningsParts';
import styles from './Affiliates.module.css';

/** The active plan's rank tiers and who reached what (docs/15 §6.6). A rank comes from verified sales on both legs; a person only asks for the check again. */
export default function RanksPage() {
  const [params, setParams] = useSearchParams();
  const page = Math.max(1, Number(params.get('page')) || 1);
  const tiers = useAsync('mlm:rank-tiers', () => services.platformEarnings.ranks());
  const plan = useAsync('mlm:rank-plan', () => services.affiliatesPlatform.plan());
  const history = useAsync(`mlm:rank-history:${page}`, () => services.platformEarnings.rankHistory({ page }));
  const [pending, setPending] = useState<Pending | null>(null);

  const bandOf = (key: string) => plan.data?.active?.capBands.find((b) => b.key === key);
  const tierColumns: Column<MlmRankTier>[] = [
    { key: 'rank', header: 'Rank', mobile: 'primary', render: (t) => `${t.order}. ${t.name}` },
    { key: 'group', header: 'Group CV', mobile: 'meta', render: (t) => compactCv(t.groupCv) },
    { key: 'leg', header: 'Each leg', mobile: 'meta', render: (t) => compactCv(legCvOf(t)) },
    {
      key: 'reward',
      header: 'Reward',
      mobile: 'detail',
      render: (t) =>
        t.rewardKind !== 'cash'
          ? REWARD_KIND_LABEL[t.rewardKind]
          : t.rewardCapAmount !== null
            ? `Up to ${compactMoney(t.rewardCapAmount)}`
            : compactMoney(t.rewardAmount),
    },
    {
      key: 'band',
      header: 'Cap band',
      mobile: 'detail',
      render: (t) => {
        const band = bandOf(t.capBandKey);
        return band ? `${band.label} · ${compactMoney(band.dailyCap)} a day` : t.capBandKey;
      },
    },
    { key: 'vesting', header: 'Vesting', width: '110px', mobile: 'detail', render: (t) => (t.vestingDays ? plural(t.vestingDays, 'day') : 'None') },
  ];
  const historyColumns: Column<MlmRankHistoryRow>[] = [
    { key: 'member', header: 'Member', mobile: 'primary', render: (r) => `${r.affiliate.name} · ${r.affiliate.code}` },
    { key: 'rank', header: 'Rank', mobile: 'meta', render: (r) => r.tierName },
    { key: 'legs', header: 'Legs A / B when reached', mobile: 'detail', render: (r) => `${cvText(r.lifetimeA)} / ${cvText(r.lifetimeB)}` },
    { key: 'date', header: 'Reached', mobile: 'detail', render: (r) => formatMoment(r.achievedAt) },
  ];

  const recalculate: Pending = {
    title: 'Check a member’s rank again',
    text: 'This compares the member’s verified leg volume with the ranks of the active plan. It can only add a rank they have earned.',
    confirmLabel: 'Recalculate',
    input: { label: 'Affiliate code', min: 4 },
    run: async (typed) => {
      const { rows } = await services.affiliatesPlatform.listMembers({ search: normaliseAffiliateCode(typed), pageSize: 20 });
      const member = memberWithCode(rows, typed);
      if (!member) throw new Error(`No member has the code ${normaliseAffiliateCode(typed)}.`);
      const { reached } = await services.platformEarnings.recalculateRank(member.id);
      return { name: member.name, reached };
    },
    done: (result) => {
      const { name, reached } = result as { name: string; reached: number };
      return reached ? `${name} reached ${plural(reached, 'new rank')}` : `${name} has no new rank`;
    },
  };

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Ranks"
        description="What each rank of the active plan asks for. A rank needs half its group CV on each leg, from verified sales."
        actions={
          <Button iconStart={<ArrowsClockwise size={16} />} onClick={() => setPending(recalculate)}>
            Recalculate a member
          </Button>
        }
      />
      <AffiliateTabs />
      <PrototypeNote>The demo build moves no money, so no plan is running here.</PrototypeNote>
      <section className={styles.panel} aria-labelledby="rank-tiers">
        <h2 id="rank-tiers" className={styles.panelTitle}>
          Rank tiers
        </h2>
        {tiers.status === 'error' && !tiers.data ? (
          <PlatformError title="The ranks didn’t load" error={tiers.error} onRetry={() => void tiers.run().catch(() => undefined)} />
        ) : !tiers.data ? (
          <Skeleton height={240} radius="var(--r-md)" />
        ) : tiers.data.length === 0 ? (
          <StateMessage title="No plan is active">Ranks appear here once a plan version is activated.</StateMessage>
        ) : (
          <DataTable<MlmRankTier> rows={tiers.data} columns={tierColumns} rowKey={(t) => String(t.order)} label="Rank tiers" rowLabel={(t) => t.name} />
        )}
      </section>
      <section className={styles.panel} aria-labelledby="rank-history">
        <h2 id="rank-history" className={styles.panelTitle}>
          Rank history
        </h2>
        {history.status === 'error' && !history.data ? (
          <PlatformError title="The history didn’t load" error={history.error} onRetry={() => void history.run().catch(() => undefined)} />
        ) : !history.data ? (
          <Skeleton height={200} radius="var(--r-md)" />
        ) : history.data.rows.length === 0 ? (
          <StateMessage title="No ranks reached yet">A row appears when a member reaches a rank.</StateMessage>
        ) : (
          <>
            <DataTable<MlmRankHistoryRow>
              rows={history.data.rows}
              columns={historyColumns}
              rowKey={(r) => r.id}
              label="Rank history"
              rowLabel={(r) => `${r.affiliate.code} ${r.tierName}`}
            />
            <Pager
              page={page}
              pageSize={history.data.pageSize}
              total={history.data.total}
              onPage={(n) => setParams(n > 1 ? { page: String(n) } : {}, { replace: true })}
            />
          </>
        )}
      </section>
      <ActionDialog pending={pending} onClose={() => setPending(null)} onDone={() => history.run()} />
    </div>
  );
}
