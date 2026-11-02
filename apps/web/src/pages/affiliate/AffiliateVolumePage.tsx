import { useSearchParams } from 'react-router-dom';
import type { AffiliateFigures, MlmCvKind, MlmCvLedgerRow, MlmLeg } from '@syniastrolms/domain';
import { formatMoney } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { services, ServiceError } from '@/services';
import { AffiliateNav } from './affiliateNav';
import styles from './Affiliate.module.css';

/**
 * The learner's volume (MLM-003): what each leg has earned, what is waiting to be matched, and the ledger of every
 * verified sale under them. Written for someone who is not an accountant: "waiting" and "matchable", not "unmatched".
 */
export default function AffiliateVolumePage() {
  const figures = useAsync('affiliate:figures', () => services.affiliate.figures());
  const [params, setParams] = useSearchParams();
  const leg = (params.get('leg') as MlmLeg | null) ?? undefined;
  const kind = (params.get('kind') as MlmCvKind | null) ?? undefined;
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
  const ledger = useAsync(`affiliate:cv:${leg ?? ''}:${kind ?? ''}:${page}`, () => services.affiliate.cvLedger({ leg, kind, page, pageSize: 20 }));

  if (figures.status === 'error' && figures.error instanceof ServiceError && figures.error.reason === 'NOT_AN_AFFILIATE') {
    return (
      <div className={styles.page}>
        <PageHeader title="Volume" />
        <StateMessage title="You’re not in the affiliate program yet" actions={<LinkButton to="/affiliate">Open the overview</LinkButton>}>
          You can read about it and join from the overview.
        </StateMessage>
      </div>
    );
  }

  const columns: Column<MlmCvLedgerRow>[] = [
    { key: 'from', header: 'Sale', mobile: 'primary', render: (r) => `${r.order.buyerName} · ${r.order.courseTitle}` },
    { key: 'leg', header: 'Leg', width: '70px', mobile: 'meta', render: (r) => <Badge size="sm">{r.leg}</Badge> },
    {
      key: 'amount',
      header: 'CV',
      width: '130px',
      mobile: 'meta',
      render: (r) => <span className={r.amount < 0 ? styles.negative : undefined}>{r.amount < 0 ? `− ${formatMoney(-r.amount)}` : formatMoney(r.amount)}</span>,
    },
    {
      key: 'kind',
      header: 'Entry',
      width: '110px',
      mobile: 'status',
      render: (r) => (
        <Badge size="sm" tone={r.kind === 'sale' ? 'accent' : 'warn'}>
          {r.kind === 'sale' ? 'Sale' : 'Reversed'}
        </Badge>
      ),
    },
    {
      key: 'when',
      header: 'When',
      width: '150px',
      mobile: 'detail',
      render: (r) => <time dateTime={r.createdAt}>{formatMoment(r.createdAt)}</time>,
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        title="Volume"
        description="Every verified sale under you adds its CV to the leg it sits in. Matching income is paid on the weaker leg; the rest waits."
      />
      <AffiliateNav />
      {figures.status === 'error' ? (
        <StateMessage kind="error" title="Your figures didn’t load" actions={<Button onClick={() => figures.run().catch(() => undefined)}>Try again</Button>}>
          {figures.error?.message}
        </StateMessage>
      ) : !figures.data ? (
        <Skeleton height={120} radius="var(--r-lg)" />
      ) : (
        <FiguresPanel figures={figures.data} />
      )}
      <section className={styles.panel} aria-labelledby="ledger">
        <h2 id="ledger" className={styles.panelTitle}>
          Your ledger
        </h2>
        <div className={styles.linkRow}>
          <SegmentedControl<MlmLeg | 'all'>
            label="Leg"
            value={leg ?? 'all'}
            onChange={(v) => update({ leg: v })}
            segments={[
              { value: 'all', label: 'Both' },
              { value: 'A', label: 'A' },
              { value: 'B', label: 'B' },
            ]}
          />
          <SegmentedControl<MlmCvKind | 'all'>
            label="Entry"
            value={kind ?? 'all'}
            onChange={(v) => update({ kind: v })}
            segments={[
              { value: 'all', label: 'All' },
              { value: 'sale', label: 'Sales' },
              { value: 'reversal', label: 'Reversed' },
            ]}
          />
        </div>
        {ledger.status === 'error' && !ledger.data ? (
          <p className={styles.muted}>Couldn’t load the ledger: {ledger.error?.message}</p>
        ) : !ledger.data ? (
          <Skeleton height={160} radius="var(--r-md)" />
        ) : ledger.data.rows.length === 0 ? (
          <p className={styles.panelHint}>Nothing yet. Your first entry arrives with the first verified sale of the eligible course by someone in your team.</p>
        ) : (
          <>
            <DataTable<MlmCvLedgerRow>
              rows={ledger.data.rows}
              columns={columns}
              rowKey={(r) => r.id}
              label="Your CV ledger"
              rowLabel={(r) => r.order.buyerName}
            />
            {ledger.data.total > ledger.data.pageSize && (
              <div className={styles.linkRow}>
                <Button disabled={page <= 1} onClick={() => update({ page: String(page - 1) })}>
                  Previous
                </Button>
                <Button disabled={page * ledger.data.pageSize >= ledger.data.total} onClick={() => update({ page: String(page + 1) })}>
                  Next
                </Button>
              </div>
            )}
          </>
        )}
      </section>
    </div>
  );
}

/** The leg figures as a learner reads them. Shared with the overview. */
export function FiguresPanel({ figures }: { figures: AffiliateFigures }) {
  const c = figures.currency;
  return (
    <div className={styles.figures}>
      <Figure label="Leg A · waiting" value={formatMoney(figures.unmatchedA, c)} hint={`${formatMoney(figures.lifetimeA, c)} over its life`} />
      <Figure label="Leg B · waiting" value={formatMoney(figures.unmatchedB, c)} hint={`${formatMoney(figures.lifetimeB, c)} over its life`} />
      <Figure label="Matchable now" value={formatMoney(figures.matchable, c)} hint="The weaker leg sets it" accent />
      <Figure
        label="Matched so far"
        value={formatMoney(figures.matchedLifetime, c)}
        hint={figures.lastMatchingRunDate ? `Last run ${figures.lastMatchingRunDate}` : 'No matching run yet'}
      />
    </div>
  );
}

function Figure({ label, value, hint, accent }: { label: string; value: string; hint: string; accent?: boolean }) {
  return (
    <div className={`${styles.figure} ${accent ? styles.figureAccent : ''}`}>
      <span className={styles.factLabel}>{label}</span>
      <span className={styles.figureValue}>{value}</span>
      <span className={styles.muted}>{hint}</span>
    </div>
  );
}
