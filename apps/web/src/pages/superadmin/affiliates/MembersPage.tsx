import { Link, useSearchParams } from 'react-router-dom';
import { MLM_KYC_STATUSES, MLM_KYC_STATUS_LABEL, type AffiliateMemberRow, type AffiliateStatus, type MlmKycStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useDebouncedInput } from '@/hooks/useDebouncedInput';
import { useNow } from '@/hooks/useNow';
import { formatRelative, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AFFILIATES_BASE, AffiliateStatusBadge, AffiliateTabs } from './affiliateMeta';
import styles from './Affiliates.module.css';

/** Every affiliate on the platform (MLM-002): who they are, who referred them, where they sit, and their state. */
export default function MembersPage() {
  const now = useNow();
  const [params, setParams] = useSearchParams();
  const status = (params.get('status') as AffiliateStatus | null) ?? undefined;
  const search = params.get('q') ?? '';
  const rankParam = params.get('rank');
  const rank = rankParam !== null && /^\d+$/.test(rankParam) ? Number(rankParam) : undefined;
  const kyc = MLM_KYC_STATUSES.find((k) => k === params.get('kyc'));
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
  const list = useAsync(`affiliates:members:${status ?? ''}:${rank ?? ''}:${kyc ?? ''}:${search}:${page}`, () =>
    services.affiliatesPlatform.listMembers({ status, rank, kyc, search: search || undefined, page, pageSize: 20 }),
  );
  const tiers = useAsync('affiliates:members-tiers', () => services.platformEarnings.ranks());
  const data = list.data;

  const columns: Column<AffiliateMemberRow>[] = [
    {
      key: 'member',
      header: 'Affiliate',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <Link to={`${AFFILIATES_BASE}/members/${r.id}`} className={styles.cellTitle}>
            {r.name}
          </Link>
          <span className={styles.cellMeta}>
            {r.code} · {r.email}
          </span>
        </span>
      ),
    },
    {
      key: 'sponsor',
      header: 'Referred by',
      width: '150px',
      mobile: 'detail',
      render: (r) => (r.sponsor ? `${r.sponsor.name} · ${r.sponsor.code}` : <span className={styles.faint}>—</span>),
    },
    {
      key: 'placement',
      header: 'Placed',
      width: '150px',
      mobile: 'detail',
      render: (r) =>
        r.placement ? `${r.placement.parentCode} · ${r.placement.leg} · level ${r.placement.depth}` : <span className={styles.faint}>Root / unplaced</span>,
    },
    { key: 'team', header: 'Team', width: '90px', mobile: 'meta', render: (r) => <span className={styles.amount}>{r.teamSize}</span> },
    { key: 'status', header: 'Status', width: '110px', mobile: 'status', render: (r) => <AffiliateStatusBadge status={r.status} /> },
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
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Affiliate members"
        count={data ? plural(data.counts.all, 'affiliate') : undefined}
        description="Everyone in the affiliate program: their sponsor, their place in the binary tree and their state."
      />
      <AffiliateTabs />
      <PrototypeNote>A demo network: changes last until the page is reloaded.</PrototypeNote>
      <div className={styles.controls}>
        <SegmentedControl<AffiliateStatus | 'all'>
          label="Status"
          value={status ?? 'all'}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: data?.counts.all },
            { value: 'active', label: 'Active', count: data?.counts.active },
            { value: 'pending', label: 'Not active', count: data?.counts.pending },
            { value: 'suspended', label: 'Suspended', count: data?.counts.suspended },
            { value: 'terminated', label: 'Closed', count: data?.counts.terminated },
          ]}
        />
        <Select aria-label="Filter by rank" value={rank === undefined ? 'all' : String(rank)} onChange={(e) => update({ rank: e.target.value })}>
          <option value="all">All ranks</option>
          <option value="0">No rank yet</option>
          {tiers.data?.map((t) => (
            <option key={t.order} value={String(t.order)}>
              {t.order}. {t.name}
            </option>
          ))}
        </Select>
        <Select aria-label="Filter by identity check" value={kyc ?? 'all'} onChange={(e) => update({ kyc: e.target.value as MlmKycStatus | 'all' })}>
          <option value="all">Any identity check</option>
          {MLM_KYC_STATUSES.map((k) => (
            <option key={k} value={k}>
              {MLM_KYC_STATUS_LABEL[k]}
            </option>
          ))}
        </Select>
        <SearchInput value={searchText} onValueChange={setSearchText} placeholder="Name, code or email" aria-label="Search affiliates" />
      </div>
      {list.status === 'error' && !data ? (
        <PlatformError title="The members didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title={data.counts.all === 0 ? 'No affiliates yet' : 'Nobody matches'}>
          {data.counts.all === 0
            ? 'Affiliates appear here as learners join through referral links or opt in.'
            : 'Try another status, rank, identity check or search.'}
        </StateMessage>
      ) : (
        <>
          <DataTable<AffiliateMemberRow> rows={data.rows} columns={columns} rowKey={(r) => r.id} label="Affiliates" rowLabel={(r) => r.name} framed />
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
    </div>
  );
}
