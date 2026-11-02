import { useState } from 'react';
import { Link } from 'react-router-dom';
import { DownloadSimple } from '@phosphor-icons/react';
import { formatMoney } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Button } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { Field, Input } from '@/components/ui/Field/Field';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment } from '@/lib/format';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { Fact, PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AFFILIATES_BASE, AffiliateTabs } from './affiliateMeta';
import { saveCsv } from './earningsParts';
import styles from './Affiliates.module.css';
import facts from '../subscriptions/Subscriptions.module.css';

/** The program at a glance and its monthly liability against the company's ceiling (docs/15 §6.7, §7.1). */
export default function AffiliateOverviewPage() {
  const toast = useToast();
  const [period, setPeriod] = useState(() => new Date().toISOString().slice(0, 7));
  const dash = useAsync('mlm:dashboard', () => services.platformEarnings.dashboard());
  const report = useAsync(`mlm:liability:${period}`, () => services.platformEarnings.liability(period));
  const d = dash.data;
  const r = report.data;
  const money = (n: number) => formatMoney(n, r?.currency ?? 'INR');

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Affiliate overview"
        description="Members, what is waiting for you, and the month’s payout against the company’s ceiling."
        actions={
          <Button
            iconStart={<DownloadSimple size={16} />}
            onClick={() =>
              services.platformEarnings.liabilityCsv(period).then(
                (csv) => saveCsv(csv, `affiliate-liability-${period}.csv`),
                (err: Error) => toast({ kind: 'error', title: 'The export didn’t work', text: err.message }),
              )
            }
          >
            Export report
          </Button>
        }
      />
      <AffiliateTabs />
      <PrototypeNote>The demo build moves no money, so these figures stay at zero.</PrototypeNote>
      {dash.status === 'error' && !d ? (
        <PlatformError title="The overview didn’t load" error={dash.error} onRetry={() => void dash.run().catch(() => undefined)} />
      ) : !d ? (
        <Skeleton height={140} radius="var(--r-lg)" />
      ) : (
        <>
          <section className={styles.panel} aria-labelledby="mlm-members">
            <h2 id="mlm-members" className={styles.panelTitle}>
              Members
            </h2>
            <dl className={facts.facts}>
              <Fact label="All members" value={d.members.total.toLocaleString('en-IN')} />
              <Fact label="Active" value={d.members.active.toLocaleString('en-IN')} />
              <Fact label="Not yet activated" value={d.members.pending.toLocaleString('en-IN')} />
              <Fact label="Suspended" value={d.members.suspended.toLocaleString('en-IN')} />
              <Fact label="Last matching day" value={d.lastMatchingDate ?? 'None yet'} />
            </dl>
          </section>
          {d.jobs.length > 0 && (
            <section className={styles.panel} aria-labelledby="mlm-jobs">
              <h2 id="mlm-jobs" className={styles.panelTitle}>
                Scheduled jobs
              </h2>
              <dl className={facts.facts}>
                {d.jobs.map((j) => (
                  <Fact
                    key={j.job}
                    label={j.job.replace(/^mlm-/, '').replace(/-/g, ' ')}
                    value={j.lastRunAt ? `${j.lastOutcome === 'failed' ? 'Failed' : 'OK'} · ${formatMoment(j.lastRunAt)}` : 'Not run yet'}
                  />
                ))}
              </dl>
            </section>
          )}
          <section className={styles.panel} aria-labelledby="mlm-queues">
            <h2 id="mlm-queues" className={styles.panelTitle}>
              Waiting for you
            </h2>
            <dl className={facts.facts}>
              <Fact label={<Link to={`${AFFILIATES_BASE}/kyc`}>Identity checks</Link>} value={d.queues.kyc} />
              <Fact label={<Link to={`${AFFILIATES_BASE}/rewards`}>Rewards in progress</Link>} value={d.queues.rewards} />
              <Fact label={<Link to={`${AFFILIATES_BASE}/withdrawals`}>Open withdrawals</Link>} value={d.queues.withdrawals} />
              <Fact label={<Link to={`${AFFILIATES_BASE}/matching?view=commissions&status=held`}>Commissions on hold</Link>} value={d.queues.heldCommissions} />
            </dl>
          </section>
        </>
      )}
      <section className={styles.panel} aria-labelledby="mlm-liability">
        <h2 id="mlm-liability" className={styles.panelTitle}>
          Monthly liability
        </h2>
        <Field label="Month">
          <Input id="mlm-period" type="month" value={period} onChange={(e) => e.target.value && setPeriod(e.target.value)} />
        </Field>
        {report.status === 'error' && !r ? (
          <PlatformError title="The report didn’t load" error={report.error} onRetry={() => void report.run().catch(() => undefined)} />
        ) : !r ? (
          <Skeleton height={160} radius="var(--r-md)" />
        ) : (
          <>
            {r.headroom === 0 && r.grossEligibleSales > 0 && (
              <InlineMessage kind="warn" title="This month is at its ceiling">
                New commissions are held until more sales make room.
              </InlineMessage>
            )}
            <dl className={facts.facts}>
              <Fact label="Eligible sales" value={money(r.grossEligibleSales)} />
              <Fact label="Ceiling" value={money(r.ceilingAmount)} />
              <Fact label="Planning figure" value={money(r.normalAmount)} />
              <Fact label="Matching paid" value={money(r.matchingPaid)} />
              <Fact label="Rewards paid" value={money(r.rewardsPaid)} />
              <Fact label="Reversals" value={money(r.reversals)} />
              <Fact label="Field payout" value={`${money(r.fieldPayout)} (${(r.payoutRatioBps / 100).toFixed(2)}%)`} />
              <Fact label="Room left" value={money(r.headroom)} />
              <Fact label="On hold now" value={money(r.heldAmount)} />
              <Fact label="Withdrawals paid" value={money(r.withdrawalsPaid)} />
              <Fact label="Owed to wallets now" value={money(r.walletLiability)} />
            </dl>
          </>
        )}
      </section>
    </div>
  );
}
