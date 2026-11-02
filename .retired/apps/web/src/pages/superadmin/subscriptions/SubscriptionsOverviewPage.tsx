import { Link } from 'react-router-dom';
import { ArrowRight, CheckCircle, ClockCountdown, CurrencyInr, HourglassMedium, Stack, TrendUp, WarningCircle } from '@phosphor-icons/react';
import { daysUntil } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatDate, formatRelative, plural } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { BarList } from '@/components/charts/BarList';
import { ColumnChart, TrendChart } from '@/components/charts/Charts';
import { StatCards, StatCardsSkeleton, type StatItem } from '@/components/data/StatCards';
import { LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote, SUBS_BASE, SubscriptionStatusBadge, SubscriptionTabs, money, moneyCompact } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/**
 * Where the platform's subscription business stands: the headline figures, what is closing this
 * week, how revenue and sign-ups have moved, and which plans carry it.
 *
 * Every figure is the billing API's, computed from the same records the Subscribers and Billing tabs
 * list, so the KPI band and the tables never disagree; the history is replayed from the lifecycle log.
 * In the demo build the figures are invented, and the screen says so.
 */
export default function SubscriptionsOverviewPage() {
  const now = useNow();
  const overview = useAsync('subs:overview', () => services.subscriptions.overview());
  const data = overview.data;

  const list = (status: string) => `${SUBS_BASE}/subscribers?status=${status}`;
  const kpis: StatItem[] = data
    ? [
        {
          id: 'active',
          label: 'Paying Admins',
          help: 'Admins on a paid plan right now.',
          icon: <CheckCircle size={18} weight="duotone" />,
          hue: 'green',
          kpi: data.kpis.active,
          value: data.kpis.active.value.toLocaleString('en-IN'),
          since: 'last month',
          absolute: true,
          to: list('active'),
          linkLabel: 'See paying Admins',
        },
        {
          id: 'trial',
          label: 'On a free trial',
          help: 'Trying a plan for free. Each trial turns paid or ends on its own.',
          icon: <HourglassMedium size={18} weight="duotone" />,
          hue: 'blue',
          kpi: data.kpis.trial,
          value: data.kpis.trial.value.toLocaleString('en-IN'),
          since: 'last month',
          absolute: true,
          to: list('trial'),
          linkLabel: 'See Admins on a free trial',
        },
        {
          id: 'past-due',
          label: 'Payment overdue',
          help: 'A payment failed. The platform is still retrying before access is limited.',
          icon: <WarningCircle size={18} weight="duotone" />,
          hue: 'orange',
          kpi: data.kpis.pastDue,
          value: data.kpis.pastDue.value.toLocaleString('en-IN'),
          since: 'last month',
          good: 'down',
          absolute: true,
          note: data.kpis.pastDue.value ? 'Worth a follow-up' : 'Nothing overdue',
          to: list('past-due'),
          linkLabel: 'See overdue subscriptions',
        },
        {
          id: 'canceling',
          label: 'Ending soon',
          help: 'Cancelled, but open until the end of the period already paid for.',
          icon: <ClockCountdown size={18} weight="duotone" />,
          hue: 'pink',
          kpi: data.kpis.canceling,
          value: data.kpis.canceling.value.toLocaleString('en-IN'),
          since: 'last month',
          good: 'down',
          absolute: true,
          to: list('canceling'),
          linkLabel: 'See subscriptions ending soon',
        },
        {
          id: 'mrr',
          label: 'Monthly income',
          help: 'What all paying subscriptions bring in each month (MRR).',
          icon: <CurrencyInr size={18} weight="duotone" />,
          hue: 'violet',
          kpi: data.kpis.mrr,
          value: money(data.kpis.mrr.value, data.currency),
          since: 'last month',
        },
        {
          id: 'arr',
          label: 'Yearly income',
          help: 'Monthly income × 12 — a year’s worth if nothing changes (ARR).',
          icon: <TrendUp size={18} weight="duotone" />,
          hue: 'gold',
          kpi: data.kpis.arr,
          value: moneyCompact(data.kpis.arr.value, data.currency),
          since: 'last month',
        },
      ]
    : [];

  const totals = (key: 'upgrades' | 'downgrades' | 'cancellations') => (data?.growth ?? []).reduce((sum, m) => sum + m[key], 0);
  const nothingSold = data && data.byPlan.length === 0 && data.kpis.active.value === 0 && data.kpis.trial.value === 0;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Plans & billing"
        description="How the business is doing: who is paying, who is trying a plan, and how much comes in each month."
        meta={data ? <span className={styles.muted}>Updated {formatRelative(data.generatedAt, now)}</span> : undefined}
      />
      <SubscriptionTabs />
      <PrototypeNote />

      {overview.status === 'error' && !data ? (
        <PlatformError title="The subscription overview didn’t load" error={overview.error} onRetry={() => overview.run().catch(() => undefined)} />
      ) : nothingSold ? (
        <StateMessage
          icon={<Stack size={26} />}
          title="No subscriptions yet"
          actions={
            <LinkButton variant="primary" to={`${SUBS_BASE}/plans`}>
              Set up plans
            </LinkButton>
          }
        >
          When Admins sign up to a plan, who is paying, your monthly income and every payment show up here.
        </StateMessage>
      ) : (
        <>
          {data ? (
            <StatCards items={kpis} label="Key numbers" columns={3} />
          ) : (
            <StatCardsSkeleton columns={3} labels={['Paying Admins', 'On a free trial', 'Payment overdue', 'Ending soon', 'Monthly income', 'Yearly income']} />
          )}

          {data && data.attention.length > 0 && (
            <section className={styles.panel} aria-labelledby="subs-attention">
              <SectionHeader
                id="subs-attention"
                title="Needs a follow-up"
                description="Free trials ending and overdue payments about to limit access, soonest first. A quick message now can keep the customer."
                actions={
                  <LinkButton size="sm" to={`${SUBS_BASE}/subscribers?status=past-due`} iconEnd={<ArrowRight size={14} />}>
                    All overdue payments
                  </LinkButton>
                }
              />
              <ul className={styles.attention}>
                {data.attention.map(({ subscription, planName }) => {
                  const trial = subscription.status === 'trial';
                  const at = trial ? subscription.trialEndsAt : subscription.graceEndsAt;
                  const left = daysUntil(at, now);
                  return (
                    <li key={subscription.id} className={styles.attentionItem}>
                      <span className={styles.stack}>
                        <Link to={`${SUBS_BASE}/subscribers/${subscription.id}`} className={styles.cellTitle}>
                          {subscription.customer.name}
                        </Link>
                        <span className={styles.cellMeta}>
                          {planName} · {trial ? 'Free trial ends' : 'Access is limited after'} {at ? formatDate(at) : '—'}
                        </span>
                      </span>
                      <span className={styles.headerFacts}>
                        <SubscriptionStatusBadge status={subscription.status} />
                        <span className={styles.muted}>{left === 0 ? 'Today' : `${plural(left, 'day')} left`}</span>
                      </span>
                    </li>
                  );
                })}
              </ul>
            </section>
          )}

          <div className={styles.twoUp}>
            <section className={styles.chartPanel} aria-labelledby="subs-revenue">
              <SectionHeader id="subs-revenue" title="Monthly income" description="What paying subscriptions brought in each month, over the last 12 months." />
              {data ? (
                <TrendChart
                  data={data.revenue.map((m) => ({ label: m.label, detail: m.detail, value: m.value }))}
                  label="Monthly income over the last twelve months"
                  unit="rupees a month"
                  formatValue={(n) => money(n, data.currency)}
                />
              ) : (
                <Skeleton height={220} radius="var(--r-md)" />
              )}
            </section>

            <section className={styles.chartPanel} aria-labelledby="subs-growth">
              <SectionHeader id="subs-growth" title="New subscriptions" description="How many Admins started a subscription each month." />
              {data ? (
                <>
                  <ColumnChart
                    data={data.growth.map((m) => ({ label: m.label, detail: m.detail, value: m.added }))}
                    label="New subscriptions each month over the last twelve months"
                    unit="new subscriptions"
                  />
                  <ul className={styles.legend} aria-label="In the last 12 months">
                    <li className={styles.legendItem}>
                      <span className={styles.legendValue}>{totals('upgrades').toLocaleString('en-IN')}</span> moved to a bigger plan
                    </li>
                    <li className={styles.legendItem}>
                      <span className={styles.legendValue}>{totals('downgrades').toLocaleString('en-IN')}</span> moved to a smaller plan
                    </li>
                    <li className={styles.legendItem}>
                      <span className={styles.legendValue}>{totals('cancellations').toLocaleString('en-IN')}</span> cancelled
                    </li>
                  </ul>
                </>
              ) : (
                <Skeleton height={220} radius="var(--r-md)" />
              )}
            </section>
          </div>

          <div className={styles.twoUp}>
            <section className={styles.panel} aria-labelledby="subs-by-plan">
              <SectionHeader
                id="subs-by-plan"
                title="Admins on each plan"
                description="Paying and free-trial Admins on each plan, and what each plan brings in a month."
                actions={
                  <LinkButton size="sm" to={`${SUBS_BASE}/plans`} iconEnd={<ArrowRight size={14} />}>
                    See plans
                  </LinkButton>
                }
              />
              {!data ? (
                <Skeleton height={140} radius="var(--r-md)" />
              ) : data.byPlan.length === 0 ? (
                <p className={styles.muted}>No Admin is on a plan yet.</p>
              ) : (
                <BarList
                  label="Admins on each plan"
                  items={data.byPlan.map((p) => ({
                    key: p.planId,
                    label: <Link to={`${SUBS_BASE}/plans/${p.planId}`}>{p.planName}</Link>,
                    value: p.subscribers,
                    display: plural(p.subscribers, 'academy', 'academies'),
                    note: `${money(p.mrr, data.currency)} a month`,
                  }))}
                />
              )}
            </section>

            <section className={styles.panel} aria-labelledby="subs-by-status">
              <SectionHeader
                id="subs-by-status"
                title="All subscriptions by status"
                description="Every subscription on the platform, grouped by where it stands."
              />
              {!data ? (
                <Skeleton height={140} radius="var(--r-md)" />
              ) : (
                <ul className={styles.attention}>
                  {(Object.entries(data.statusCounts) as [keyof typeof data.statusCounts, number][])
                    .filter(([, count]) => count > 0)
                    .sort((a, b) => b[1] - a[1])
                    .map(([status, count]) => (
                      <li key={status} className={styles.attentionItem}>
                        <SubscriptionStatusBadge status={status} size="md" />
                        <span className={styles.headerFacts}>
                          <span className={`${styles.amount} ${styles.strong}`}>{count.toLocaleString('en-IN')}</span>
                          <Link to={`${SUBS_BASE}/subscribers?status=${status}`} className={styles.muted}>
                            See list
                          </Link>
                        </span>
                      </li>
                    ))}
                </ul>
              )}
            </section>
          </div>

          <PrototypeNote>
            Demo figures. Today&apos;s totals are counted from the demo&apos;s records; the month-by-month history is modelled from today&apos;s book, not
            measured.
          </PrototypeNote>
        </>
      )}
    </div>
  );
}
