import { useState, type FormEvent } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { DownloadSimple } from '@phosphor-icons/react';
import type { AffiliateStatus, MlmCarryForwardRow, MlmCvKind, MlmCvLedgerRow, MlmLeg } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, Input, SearchInput, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AFFILIATES_BASE, AffiliateStatusBadge, AffiliateTabs, cvText, parseSignedCv } from './affiliateMeta';
import styles from './Affiliates.module.css';

type View = 'cv' | 'carry-forward';

/**
 * The immutable CV ledger (MLM-003) and the carry-forward pools it adds up to: every credit and reversal on every leg,
 * and per affiliate what each leg has earned over its life and what is still waiting to be matched.
 */
export default function LedgersPage() {
  const [params, setParams] = useSearchParams();
  const view: View = params.get('view') === 'carry-forward' ? 'carry-forward' : 'cv';
  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || v === 'all') p.delete(k);
      else p.set(k, v);
    }
    if (!('page' in next)) p.delete('page');
    setParams(p, { replace: true });
  };

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Ledgers"
        description="CV is written once and never edited: a sale credits, a reversal negates. The pools show where each affiliate's legs stand today."
      />
      <AffiliateTabs />
      <PrototypeNote>A demo ledger derived from the demo network.</PrototypeNote>
      <SegmentedControl<View>
        label="Ledger"
        value={view}
        onChange={(v) => update({ view: v === 'cv' ? undefined : v, leg: undefined, kind: undefined, q: undefined })}
        segments={[
          { value: 'cv', label: 'CV ledger' },
          { value: 'carry-forward', label: 'Carry-forward pools' },
        ]}
      />
      {view === 'cv' ? <CvLedger params={params} update={update} /> : <CarryForward params={params} update={update} />}
    </div>
  );
}

interface ViewProps {
  params: URLSearchParams;
  update: (next: Record<string, string | undefined>) => void;
}

function CvLedger({ params, update }: ViewProps) {
  const toast = useToast();
  const leg = (params.get('leg') as MlmLeg | null) ?? undefined;
  const kind = (params.get('kind') as MlmCvKind | null) ?? undefined;
  const page = Math.max(1, Number(params.get('page')) || 1);
  const list = useAsync(`affiliates:cv:${leg ?? ''}:${kind ?? ''}:${page}`, () => services.affiliatesPlatform.cvLedger({ leg, kind, page, pageSize: 25 }));
  const data = list.data;

  const exportCsv = async () => {
    try {
      const csv = await services.affiliatesPlatform.cvCsv({ leg, kind });
      const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
      const a = document.createElement('a');
      a.href = url;
      a.download = 'cv-ledger.csv';
      a.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      toast({ kind: 'error', title: 'Couldn’t export the ledger', text: (err as Error).message });
    }
  };

  const columns: Column<MlmCvLedgerRow>[] = [
    {
      key: 'affiliate',
      header: 'Credited to',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <Link to={`${AFFILIATES_BASE}/members/${r.affiliate.id}`} className={styles.cellTitle}>
            {r.affiliate.name}
          </Link>
          <span className={styles.cellMeta}>{r.affiliate.code}</span>
        </span>
      ),
    },
    { key: 'leg', header: 'Leg', width: '70px', mobile: 'meta', render: (r) => <Badge size="sm">{r.leg}</Badge> },
    {
      key: 'amount',
      header: 'Amount',
      width: '130px',
      mobile: 'meta',
      render: (r) => <span className={styles.amount}>{r.amount < 0 ? `− ${cvText(-r.amount)}` : cvText(r.amount)}</span>,
    },
    {
      key: 'kind',
      header: 'Entry',
      width: '110px',
      mobile: 'status',
      render: (r) => (
        <Badge size="sm" tone={r.kind === 'sale' ? 'accent' : 'warn'}>
          {r.kind === 'sale' ? 'Sale' : 'Reversal'}
        </Badge>
      ),
    },
    { key: 'order', header: 'From', mobile: 'detail', render: (r) => `${r.order.buyerName} · ${r.order.courseTitle}` },
    {
      key: 'when',
      header: 'When',
      width: '150px',
      mobile: 'detail',
      render: (r) => (
        <time dateTime={r.createdAt} className={styles.nowrap}>
          {formatMoment(r.createdAt)}
        </time>
      ),
    },
  ];

  return (
    <>
      <div className={styles.controls}>
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
        <SegmentedControl<MlmCvKind | 'all'>
          label="Entry"
          value={kind ?? 'all'}
          onChange={(v) => update({ kind: v })}
          segments={[
            { value: 'all', label: 'All entries' },
            { value: 'sale', label: 'Sales' },
            { value: 'reversal', label: 'Reversals' },
          ]}
        />
        <Button iconStart={<DownloadSimple size={16} />} onClick={() => void exportCsv()}>
          Export CSV
        </Button>
      </div>
      {list.status === 'error' && !data ? (
        <PlatformError title="The ledger didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title="Nothing in the ledger">Entries appear with the first verified sale of an eligible course under somebody.</StateMessage>
      ) : (
        <>
          <DataTable<MlmCvLedgerRow>
            rows={data.rows}
            columns={columns}
            rowKey={(r) => r.id}
            label="CV ledger"
            rowLabel={(r) => `${r.affiliate.name}, leg ${r.leg}, ${cvText(r.amount)}`}
            framed
          />
          <Pager page={page} total={data.total} pageSize={data.pageSize} update={update} />
        </>
      )}
    </>
  );
}

function CarryForward({ params, update }: ViewProps) {
  const search = params.get('q') ?? '';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const list = useAsync(`affiliates:carry-forward:${search}:${page}`, () =>
    services.affiliatesPlatform.carryForward({ search: search || undefined, page, pageSize: 25 }),
  );
  const data = list.data;
  const [adjusting, setAdjusting] = useState<MlmCarryForwardRow | null>(null);

  const columns: Column<MlmCarryForwardRow>[] = [
    {
      key: 'affiliate',
      header: 'Affiliate',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <Link to={`${AFFILIATES_BASE}/members/${r.affiliate.id}`} className={styles.cellTitle}>
            {r.affiliate.name}
          </Link>
          <span className={styles.cellMeta}>{r.affiliate.code}</span>
        </span>
      ),
    },
    {
      key: 'unmatchedA',
      header: 'Waiting · A',
      width: '130px',
      mobile: 'meta',
      render: (r) => <span className={styles.amount}>{cvText(r.unmatchedA)}</span>,
    },
    {
      key: 'unmatchedB',
      header: 'Waiting · B',
      width: '130px',
      mobile: 'meta',
      render: (r) => <span className={styles.amount}>{cvText(r.unmatchedB)}</span>,
    },
    {
      key: 'matchable',
      header: 'Matchable',
      width: '130px',
      mobile: 'detail',
      render: (r) => <span className={styles.amount}>{cvText(Math.min(r.unmatchedA, r.unmatchedB))}</span>,
    },
    { key: 'lifetimeA', header: 'Lifetime · A', width: '130px', mobile: 'detail', render: (r) => cvText(r.lifetimeA) },
    { key: 'lifetimeB', header: 'Lifetime · B', width: '130px', mobile: 'detail', render: (r) => cvText(r.lifetimeB) },
    { key: 'matched', header: 'Matched so far', width: '130px', mobile: 'detail', render: (r) => cvText(r.matchedLifetime) },
    {
      key: 'status',
      header: 'Status',
      width: '110px',
      mobile: 'status',
      render: (r) => <AffiliateStatusBadge status={r.affiliate.status as AffiliateStatus} />,
    },
    {
      key: 'actions',
      header: '',
      align: 'end',
      mobile: 'detail',
      render: (r) => (
        <Button size="sm" onClick={() => setAdjusting(r)}>
          Correct
        </Button>
      ),
    },
  ];

  return (
    <>
      <div className={styles.controls}>
        <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Name or code" aria-label="Search pools" />
      </div>
      {list.status === 'error' && !data ? (
        <PlatformError title="The pools didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title="No pools yet">An affiliate's pools fill with the first verified sale under them.</StateMessage>
      ) : (
        <>
          <p className={styles.muted}>
            {plural(data.total, 'affiliate')} with CV. "Waiting" is what the next matching run can draw on; the smaller leg sets what is matchable.
          </p>
          <DataTable<MlmCarryForwardRow>
            rows={data.rows}
            columns={columns}
            rowKey={(r) => r.affiliate.id}
            label="Carry-forward pools"
            rowLabel={(r) => r.affiliate.name}
            framed
          />
          <Pager page={page} total={data.total} pageSize={data.pageSize} update={update} />
        </>
      )}
      {adjusting && <CarryAdjustDialog key={adjusting.affiliate.id} row={adjusting} onClose={() => setAdjusting(null)} onDone={() => list.run()} />}
    </>
  );
}

/** A signed correction to one leg's waiting CV. The activity log records it with the figures before and after; lifetime CV, and so rank, never moves. */
function CarryAdjustDialog({ row, onClose, onDone }: { row: MlmCarryForwardRow; onClose: () => void; onDone: () => unknown }) {
  const toast = useToast();
  const [leg, setLeg] = useState<MlmLeg>('A');
  const [text, setText] = useState('');
  const [reason, setReason] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const amount = parseSignedCv(text);
  const before = leg === 'A' ? row.unmatchedA : row.unmatchedB;
  const after = amount === undefined ? undefined : before + amount;
  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (amount === undefined) return;
    setSaving(true);
    setError(undefined);
    try {
      await services.affiliatesPlatform.adjustCarryForward(row.affiliate.id, { leg, amount, reason: reason.trim() });
      toast({ kind: 'success', title: `Leg ${leg} corrected for ${row.affiliate.name}`, text: 'The correction is in the activity log.' });
      onClose();
      await onDone();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };
  return (
    <Modal open onClose={onClose} title={`Correct ${row.affiliate.name}’s carry-forward`}>
      <form className={styles.form} onSubmit={submit} noValidate>
        {error && (
          <InlineMessage kind="error" title="Couldn’t correct it.">
            {error}
          </InlineMessage>
        )}
        <Field label="Leg">
          <Select value={leg} onChange={(e) => setLeg(e.target.value as MlmLeg)}>
            <option value="A">A / Left · {cvText(row.unmatchedA)} waiting</option>
            <option value="B">B / Right · {cvText(row.unmatchedB)} waiting</option>
          </Select>
        </Field>
        <Field
          label="Change in CV"
          hint={after === undefined ? 'Use a minus sign to take CV out. Lifetime CV and rank do not change.' : `Leaves ${cvText(after)} waiting on leg ${leg}.`}
          error={after !== undefined && after < 0 ? 'That would take the leg below zero.' : undefined}
        >
          <Input id="carry-adjust-amount" inputMode="decimal" value={text} onChange={(e) => setText(e.target.value)} />
        </Field>
        <Field label="Reason" hint="Written to the activity log with the figures before and after.">
          <Textarea id="carry-adjust-reason" rows={2} maxLength={500} value={reason} onChange={(e) => setReason(e.target.value)} />
        </Field>
        <div className={styles.formActions}>
          <Button onClick={onClose} disabled={saving}>
            Cancel
          </Button>
          <Button type="submit" variant="primary" loading={saving} disabled={after === undefined || after < 0 || reason.trim().length < 3}>
            Save correction
          </Button>
        </div>
      </form>
    </Modal>
  );
}

function Pager({ page, total, pageSize, update }: { page: number; total: number; pageSize: number; update: ViewProps['update'] }) {
  if (total <= pageSize) return null;
  return (
    <div className={styles.formActions}>
      <Button disabled={page <= 1} onClick={() => update({ page: String(page - 1) })}>
        Previous
      </Button>
      <span className={styles.muted}>
        Page {page} of {Math.ceil(total / pageSize)}
      </span>
      <Button disabled={page * pageSize >= total} onClick={() => update({ page: String(page + 1) })}>
        Next
      </Button>
    </div>
  );
}
