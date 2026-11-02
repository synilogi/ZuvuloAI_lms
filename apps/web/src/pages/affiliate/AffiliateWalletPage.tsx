import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { formatMoney, MLM_WALLET_ENTRY_LABEL, MLM_WITHDRAWAL_STATUS_LABEL, type MlmWalletEntryRow, type MlmWithdrawalRow } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Field, Input } from '@/components/ui/Field/Field';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment } from '@/lib/format';
import { Pager } from '@/pages/superadmin/affiliates/earningsParts';
import { services, ServiceError } from '@/services';
import { AffiliateNav } from './affiliateNav';
import styles from './Affiliate.module.css';

const inr = (n: number) => formatMoney(n, 'INR');
const signed = (n: number) => (n === 0 ? '' : `${n > 0 ? '+' : '−'}${inr(Math.abs(n))}`);

/** The member's balances, withdrawals and ledger. The server decides whether a withdrawal is allowed, and says why not. */
export default function AffiliateWalletPage() {
  const toast = useToast();
  const [withdrawalPage, setWithdrawalPage] = useState(1);
  const [entryPage, setEntryPage] = useState(1);
  const data = useAsync(`affiliate:wallet:${withdrawalPage}:${entryPage}`, () =>
    Promise.all([
      services.affiliateEarnings.earnings(),
      services.affiliateEarnings.kyc(),
      services.affiliateEarnings.withdrawals({ page: withdrawalPage, pageSize: 20 }),
      services.affiliateEarnings.walletEntries({ page: entryPage, pageSize: 50 }),
    ]).then(([earnings, kyc, withdrawals, entries]) => ({ earnings, kyc, withdrawals, entries })),
  );
  const [rupees, setRupees] = useState('');
  const [error, setError] = useState<string>();
  const [sending, setSending] = useState(false);

  const request = async (e: FormEvent) => {
    e.preventDefault();
    const amount = Math.round(Number(rupees.replace(/,/g, '')) * 100);
    if (!Number.isFinite(amount) || amount <= 0) return setError('Enter an amount in rupees.');
    setError(undefined);
    setSending(true);
    try {
      await services.affiliateEarnings.requestWithdrawal(amount);
      toast({ kind: 'success', title: 'Withdrawal requested', text: `${inr(amount)} is held until it is reviewed.` });
      setRupees('');
      await data.run();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSending(false);
    }
  };
  const cancel = async (id: string) => {
    try {
      await services.affiliateEarnings.cancelWithdrawal(id);
      toast({ kind: 'success', title: 'Withdrawal cancelled', text: 'The amount is back in your available balance.' });
      await data.run();
    } catch (err) {
      toast({ kind: 'error', title: 'It couldn’t be cancelled', text: (err as Error).message });
    }
  };

  if (data.status === 'error' && data.error instanceof ServiceError && data.error.reason === 'NOT_AN_AFFILIATE') {
    return (
      <div className={styles.page}>
        <PageHeader title="Wallet" />
        <StateMessage title="You’re not in the affiliate program yet" actions={<LinkButton to="/affiliate">Open the overview</LinkButton>}>
          You can read about it and join from the overview.
        </StateMessage>
      </div>
    );
  }
  const d = data.data;
  const withdrawalColumns: Column<MlmWithdrawalRow>[] = [
    {
      key: 'amount',
      header: 'Amount',
      mobile: 'primary',
      render: (w) => (w.tdsAmount > 0 ? `${inr(w.amount)} (${inr(w.netAmount)} after tax)` : inr(w.amount)),
    },
    {
      key: 'status',
      header: 'Status',
      mobile: 'status',
      render: (w) => <Badge size="sm">{MLM_WITHDRAWAL_STATUS_LABEL[w.status]}</Badge>,
    },
    { key: 'bank', header: 'To', mobile: 'detail', render: (w) => `••••${w.bank.accountLast4}` },
    { key: 'date', header: 'Requested', mobile: 'detail', render: (w) => formatMoment(w.createdAt) },
    { key: 'note', header: 'Note', mobile: 'detail', render: (w) => w.reference ?? w.rejectionReason ?? '' },
    {
      key: 'action',
      header: 'Actions',
      align: 'end',
      mobile: 'detail',
      render: (w) =>
        w.status === 'requested' ? (
          <Button size="sm" onClick={() => void cancel(w.id)}>
            Cancel
          </Button>
        ) : null,
    },
  ];
  const entryColumns: Column<MlmWalletEntryRow>[] = [
    { key: 'type', header: 'Entry', mobile: 'primary', render: (r) => MLM_WALLET_ENTRY_LABEL[r.type] },
    { key: 'available', header: 'Available', mobile: 'meta', render: (r) => signed(r.availableDelta) },
    { key: 'held', header: 'Held', mobile: 'detail', render: (r) => signed(r.heldDelta) },
    { key: 'date', header: 'Date', mobile: 'detail', render: (r) => formatMoment(r.createdAt) },
  ];

  return (
    <div className={styles.page}>
      <PageHeader title="Wallet" description="Your balance and withdrawals. Every change is an entry you can see below." />
      <AffiliateNav />
      {data.status === 'error' && !d ? (
        <StateMessage kind="error" title="Your wallet didn’t load" actions={<Button onClick={() => void data.run().catch(() => undefined)}>Try again</Button>}>
          {data.error.message}
        </StateMessage>
      ) : !d ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : (
        <>
          <section className={styles.figures} aria-label="Your balances">
            <div className={styles.figure}>
              <span className={styles.factLabel}>Available</span>
              <strong className={`${styles.figureValue} ${d.earnings.wallet.available < 0 ? styles.negative : ''}`}>{inr(d.earnings.wallet.available)}</strong>
            </div>
            <div className={styles.figure}>
              <span className={styles.factLabel}>In withdrawals</span>
              <strong className={styles.figureValue}>{inr(d.earnings.wallet.held)}</strong>
            </div>
            <div className={styles.figure}>
              <span className={styles.factLabel}>Paid out</span>
              <strong className={styles.figureValue}>{inr(d.earnings.wallet.paid)}</strong>
            </div>
            <div className={styles.figure}>
              <span className={styles.factLabel}>Held by payout policy</span>
              <strong className={styles.figureValue}>{inr(d.earnings.wallet.heldByPolicy)}</strong>
            </div>
          </section>
          {d.earnings.wallet.available < 0 && (
            <InlineMessage kind="warn" title="Your balance is below zero">
              A sale was reversed after its income reached your wallet. Later credits clear this first.
            </InlineMessage>
          )}
          <section className={styles.panel} aria-labelledby="wallet-request">
            <h2 id="wallet-request" className={styles.panelTitle}>
              Request a withdrawal
            </h2>
            {d.kyc.status !== 'verified' ? (
              <InlineMessage kind="info" title="Verify your identity first">
                Add your PAN and bank details on the <Link to="/affiliate/kyc">KYC page</Link>. You can withdraw once they are verified.
              </InlineMessage>
            ) : (
              <form className={styles.form} onSubmit={request} noValidate>
                <Field label="Amount in rupees" hint={`Paid to the account ending ${d.kyc.bankAccountLast4}.`} error={error}>
                  <Input id="withdraw-amount" inputMode="decimal" value={rupees} onChange={(e) => setRupees(e.target.value)} />
                </Field>
                <div>
                  <Button type="submit" variant="primary" loading={sending}>
                    Request withdrawal
                  </Button>
                </div>
              </form>
            )}
          </section>
          <section className={styles.panel} aria-labelledby="wallet-withdrawals">
            <h2 id="wallet-withdrawals" className={styles.panelTitle}>
              Your withdrawals
            </h2>
            {d.withdrawals.rows.length === 0 ? (
              <p className={styles.muted}>None yet.</p>
            ) : (
              <>
                <DataTable<MlmWithdrawalRow>
                  rows={d.withdrawals.rows}
                  columns={withdrawalColumns}
                  rowKey={(w) => w.id}
                  label="Withdrawals"
                  rowLabel={(w) => w.id}
                />
                <Pager page={withdrawalPage} pageSize={d.withdrawals.pageSize} total={d.withdrawals.total} onPage={setWithdrawalPage} />
              </>
            )}
          </section>
          <section className={styles.panel} aria-labelledby="wallet-ledger">
            <h2 id="wallet-ledger" className={styles.panelTitle}>
              Ledger
            </h2>
            {d.entries.rows.length === 0 ? (
              <p className={styles.muted}>No entries yet.</p>
            ) : (
              <>
                <DataTable<MlmWalletEntryRow>
                  rows={d.entries.rows}
                  columns={entryColumns}
                  rowKey={(r) => r.id}
                  label="Wallet entries"
                  rowLabel={(r) => r.type}
                />
                <Pager page={entryPage} pageSize={d.entries.pageSize} total={d.entries.total} onPage={setEntryPage} />
              </>
            )}
          </section>
        </>
      )}
    </div>
  );
}
