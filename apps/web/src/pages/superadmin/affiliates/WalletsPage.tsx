import { useState, type FormEvent } from 'react';
import { useSearchParams } from 'react-router-dom';
import { formatMoney, MLM_WALLET_ENTRY_LABEL, type MlmWalletEntryRow, type MlmWalletRow } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { Drawer } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Field, Input, SearchInput } from '@/components/ui/Field/Field';
import { useAsync } from '@/hooks/useAsync';
import { useDebouncedInput } from '@/hooks/useDebouncedInput';
import { formatMoment } from '@/lib/format';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AffiliateTabs } from './affiliateMeta';
import { Pager } from './earningsParts';
import styles from './Affiliates.module.css';

const inr = (n: number) => formatMoney(n, 'INR');
/** A signed amount, with its sign shown. */
const signed = (n: number) => (n === 0 ? '' : `${n > 0 ? '+' : '−'}${inr(Math.abs(n))}`);

/** Every member's balances, each wallet's ledger, and signed corrections with a reason (docs/15 §6.9). */
export default function WalletsPage() {
  const toast = useToast();
  const [params, setParams] = useSearchParams();
  const search = params.get('q') ?? '';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const [searchText, setSearchText] = useDebouncedInput(search, (v) => {
    const p = new URLSearchParams();
    if (v) p.set('q', v);
    setParams(p, { replace: true });
  });
  const list = useAsync(`mlm:wallets:${search}:${page}`, () => services.platformEarnings.wallets({ search: search || undefined, page }));
  const [open, setOpen] = useState<MlmWalletRow | null>(null);
  const [entryPage, setEntryPage] = useState(1);
  const entries = useAsync(`mlm:wallet:${open?.affiliate.id ?? ''}:${entryPage}`, () =>
    open ? services.platformEarnings.walletEntries(open.affiliate.id, { page: entryPage, pageSize: 50 }) : Promise.resolve(null),
  );
  const [rupees, setRupees] = useState('');
  const [reason, setReason] = useState('');
  const [issues, setIssues] = useState<{ amount?: string; reason?: string }>({});
  const [error, setError] = useState<string>();
  const [saving, setSaving] = useState(false);

  const adjust = async (e: FormEvent) => {
    e.preventDefault();
    if (!open) return;
    const paise = Math.round(Number(rupees) * 100);
    const found = {
      amount: !Number.isFinite(paise) || paise === 0 ? 'Enter an amount in rupees. Use a minus sign to take money out.' : undefined,
      reason: reason.trim().length < 3 ? 'Say why, in a few words.' : undefined,
    };
    setIssues(found);
    setError(undefined);
    if (found.amount || found.reason) return;
    setSaving(true);
    try {
      await services.platformEarnings.adjustWallet(open.affiliate.id, paise, reason.trim());
      toast({ kind: 'success', title: 'Wallet adjusted', text: signed(paise) });
      setRupees('');
      setReason('');
      await Promise.all([entries.run(), list.run()]);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const columns: Column<MlmWalletRow>[] = [
    {
      key: 'member',
      header: 'Member',
      mobile: 'primary',
      render: (w) => (
        <button
          type="button"
          className={styles.cellTitle}
          onClick={() => {
            setEntryPage(1);
            setOpen(w);
          }}
        >
          {w.affiliate.name} · {w.affiliate.code}
        </button>
      ),
    },
    { key: 'available', header: 'Available', mobile: 'meta', render: (w) => inr(w.available) },
    { key: 'held', header: 'In withdrawals', mobile: 'detail', render: (w) => inr(w.held) },
    { key: 'paid', header: 'Paid out', mobile: 'detail', render: (w) => inr(w.paid) },
    { key: 'policy', header: 'On hold', mobile: 'detail', render: (w) => inr(w.heldByPolicy) },
  ];
  const entryColumns: Column<MlmWalletEntryRow>[] = [
    {
      key: 'type',
      header: 'Entry',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <span>{MLM_WALLET_ENTRY_LABEL[r.type]}</span>
          {r.note && <span className={styles.cellMeta}>{r.note}</span>}
        </span>
      ),
    },
    { key: 'available', header: 'Available', mobile: 'meta', render: (r) => signed(r.availableDelta) },
    { key: 'held', header: 'Held', mobile: 'detail', render: (r) => signed(r.heldDelta) },
    { key: 'date', header: 'Date', mobile: 'detail', render: (r) => formatMoment(r.createdAt) },
  ];
  const data = list.data;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Wallets"
        description="Balances are the sum of an immutable ledger. A correction adds an entry and edits nothing."
      />
      <AffiliateTabs />
      <PrototypeNote>The demo build moves no money, so there are no wallets here.</PrototypeNote>
      <div className={styles.controls}>
        <SearchInput value={searchText} onValueChange={setSearchText} placeholder="Member name or code" aria-label="Search wallets" />
      </div>
      {list.status === 'error' && !data ? (
        <PlatformError title="The wallets didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={280} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title={search ? 'Nothing matches' : 'No wallets yet'}>A wallet appears with a member’s first credit.</StateMessage>
      ) : (
        <>
          <DataTable<MlmWalletRow>
            rows={data.rows}
            columns={columns}
            rowKey={(w) => w.affiliate.id}
            label="Wallets"
            rowLabel={(w) => w.affiliate.code}
            framed
          />
          <Pager
            page={page}
            pageSize={data.pageSize}
            total={data.total}
            onPage={(n) => {
              const p = new URLSearchParams(params);
              p.set('page', String(n));
              setParams(p, { replace: true });
            }}
          />
        </>
      )}
      <Drawer open={open !== null} onClose={() => setOpen(null)} title={open ? `${open.affiliate.name}` : 'Wallet'} eyebrow="Wallet">
        <div className={styles.form}>
          {entries.status === 'error' && !entries.data ? (
            <PlatformError title="The ledger didn’t load" error={entries.error} onRetry={() => void entries.run().catch(() => undefined)} />
          ) : !entries.data ? (
            <Skeleton height={200} radius="var(--r-md)" />
          ) : entries.data.rows.length === 0 ? (
            <StateMessage title="No entries yet" />
          ) : (
            <>
              <DataTable<MlmWalletEntryRow>
                rows={entries.data.rows}
                columns={entryColumns}
                rowKey={(r) => r.id}
                label="Wallet entries"
                rowLabel={(r) => r.type}
              />
              <Pager page={entryPage} pageSize={entries.data.pageSize} total={entries.data.total} onPage={setEntryPage} />
            </>
          )}
          <form className={styles.form} onSubmit={adjust} noValidate>
            <h3 className={styles.panelTitle}>Add a correction</h3>
            {error && <InlineMessage kind="error" title={error} />}
            <Field label="Amount in rupees" hint="Use a minus sign to take money out." error={issues.amount}>
              <Input id="wallet-adjust" inputMode="decimal" value={rupees} onChange={(e) => setRupees(e.target.value)} />
            </Field>
            <Field label="Why" error={issues.reason}>
              <Input id="wallet-reason" value={reason} maxLength={500} onChange={(e) => setReason(e.target.value)} />
            </Field>
            <div className={styles.formActions}>
              <Button type="submit" loading={saving}>
                Add entry
              </Button>
            </div>
          </form>
        </div>
      </Drawer>
    </div>
  );
}
