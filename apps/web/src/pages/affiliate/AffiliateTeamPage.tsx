import { useSearchParams } from 'react-router-dom';
import type { AffiliateStatus, MlmLeg, TeamRow } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useDebouncedInput } from '@/hooks/useDebouncedInput';
import { useNow } from '@/hooks/useNow';
import { formatRelative, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { SearchInput } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { Pager } from '@/pages/superadmin/affiliates/earningsParts';
import { services, ServiceError } from '@/services';
import { AffiliateNav } from './affiliateNav';
import styles from './Affiliate.module.css';

const STATUS_TONE: Record<AffiliateStatus, 'neutral' | 'accent' | 'warn' | 'danger'> = {
  pending: 'neutral',
  active: 'accent',
  suspended: 'warn',
  terminated: 'danger',
};
const STATUS_LABEL: Record<AffiliateStatus, string> = { pending: 'Not active', active: 'Active', suspended: 'Suspended', terminated: 'Closed' };

/** Everyone under the learner, flat (MLM-002): leg, depth, who referred them, when they joined. */
export default function AffiliateTeamPage() {
  const now = useNow();
  const [params, setParams] = useSearchParams();
  const leg = (params.get('leg') as MlmLeg | null) ?? undefined;
  const status = (params.get('status') as AffiliateStatus | null) ?? undefined;
  const search = params.get('q') ?? '';
  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || v === 'all') p.delete(k);
      else p.set(k, v);
    }
    if (!('page' in next)) p.delete('page');
    setParams(p, { replace: true });
  };
  const page = Math.max(1, Number(params.get('page')) || 1);
  const [searchText, setSearchText] = useDebouncedInput(search, (v) => update({ q: v }));
  const team = useAsync(`affiliate:team:${leg ?? ''}:${status ?? ''}:${search}:${page}`, () =>
    services.affiliate.team({ leg, status, search: search || undefined, page, pageSize: 100 }),
  );
  const data = team.data;

  if (team.status === 'error' && team.error instanceof ServiceError && team.error.reason === 'NOT_AN_AFFILIATE') {
    return (
      <div className={styles.page}>
        <PageHeader title="Team list" />
        <StateMessage title="You’re not in the affiliate program yet" actions={<LinkButton to="/affiliate">Open the overview</LinkButton>}>
          You can read about it and join from the overview.
        </StateMessage>
      </div>
    );
  }

  const columns: Column<TeamRow>[] = [
    {
      key: 'name',
      header: 'Member',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <span className={styles.factValue}>{r.name}</span>
          <span className={styles.muted}>{r.code}</span>
        </span>
      ),
    },
    { key: 'leg', header: 'Leg', width: '70px', mobile: 'meta', render: (r) => (r.leg ? `${r.leg}` : '—') },
    { key: 'depth', header: 'Level', width: '80px', mobile: 'detail', render: (r) => String(r.depth) },
    { key: 'sponsor', header: 'Referred by', width: '130px', mobile: 'detail', render: (r) => r.sponsorCode ?? '—' },
    {
      key: 'status',
      header: 'Status',
      width: '110px',
      mobile: 'status',
      render: (r) => (
        <Badge size="sm" tone={STATUS_TONE[r.status]}>
          {STATUS_LABEL[r.status]}
        </Badge>
      ),
    },
    {
      key: 'joined',
      header: 'Joined',
      width: '120px',
      mobile: 'detail',
      render: (r) => (
        <time dateTime={r.joinedAt} className={styles.nowrap}>
          {formatRelative(r.joinedAt, now)}
        </time>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader title="Team list" description="Everyone placed under you, as a list." count={data ? plural(data.summary.total, 'member') : undefined} />
      <AffiliateNav />
      {data && (
        <dl className={styles.facts}>
          <div className={styles.fact}>
            <dt className={styles.factLabel}>Direct referrals</dt>
            <dd className={styles.factValue}>{data.summary.directReferrals}</dd>
          </div>
          <div className={styles.fact}>
            <dt className={styles.factLabel}>A leg</dt>
            <dd className={styles.factValue}>{data.summary.byLeg.A}</dd>
          </div>
          <div className={styles.fact}>
            <dt className={styles.factLabel}>B leg</dt>
            <dd className={styles.factValue}>{data.summary.byLeg.B}</dd>
          </div>
          <div className={styles.fact}>
            <dt className={styles.factLabel}>Active</dt>
            <dd className={styles.factValue}>{data.summary.active}</dd>
          </div>
        </dl>
      )}
      <div className={styles.linkRow}>
        <SegmentedControl<MlmLeg | 'all'>
          label="Leg"
          value={leg ?? 'all'}
          onChange={(v) => update({ leg: v })}
          segments={[
            { value: 'all', label: 'Both legs' },
            { value: 'A', label: 'A' },
            { value: 'B', label: 'B' },
          ]}
        />
        <SegmentedControl<AffiliateStatus | 'all'>
          label="Status"
          value={status ?? 'all'}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All' },
            { value: 'active', label: 'Active' },
            { value: 'pending', label: 'Not active' },
          ]}
        />
        <SearchInput value={searchText} onValueChange={setSearchText} placeholder="Name or code" aria-label="Search your team" />
      </div>
      {team.status === 'error' && !data ? (
        <StateMessage kind="error" title="Your team didn’t load" actions={<Button onClick={() => team.run().catch(() => undefined)}>Try again</Button>}>
          {team.error?.message}
        </StateMessage>
      ) : !data ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title={data.summary.total === 0 ? 'Nobody in your team yet' : 'Nobody matches'}>
          {data.summary.total === 0 ? 'Share your referral link. Everyone who joins through it appears here.' : 'Try another leg, status or search.'}
        </StateMessage>
      ) : (
        <>
          <DataTable<TeamRow> rows={data.rows} columns={columns} rowKey={(r) => r.id} label="Your team" rowLabel={(r) => r.name} framed />
          <Pager page={page} pageSize={data.pageSize} total={data.total} onPage={(n) => update({ page: String(n) })} />
        </>
      )}
    </div>
  );
}
