import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { Archive, ArrowCounterClockwise, CheckCircle, Circle, Copy, PencilSimple, RocketLaunch, Users } from '@phosphor-icons/react';
import type { PlanVersion } from '@syniastrolms/domain';
import { FEATURE_GROUPS, LIMIT_KEYS } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatDate, formatRelative, plural } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { ColumnChart } from '@/components/charts/Charts';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { Fact, PlanStatusBadge, PrototypeNote, SUBS_BASE, SubscriptionStatusBadge, cyclePer, limitLabel, limitText, money } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/** One plan: what it costs, what it allows, who is on it and how that has moved. */
export default function PlanDetailPage() {
  const { planId = '' } = useParams();
  const now = useNow();
  const toast = useToast();
  const navigate = useNavigate();
  const [archiving, setArchiving] = useState(false);
  const [publishing, setPublishing] = useState(false);

  const query = useAsync(`subs:plan:${planId}`, () => services.subscriptions.getPlan(planId));
  const detail = query.data;
  usePageCrumbs(detail ? [{ label: detail.plan.name }] : [{ label: 'Plan' }]);

  const reload = () => query.run().catch(() => undefined);

  const duplicate = async () => {
    try {
      const copy = await services.subscriptions.duplicatePlan(planId);
      toast({ kind: 'success', title: `${copy.name} created`, text: `Saved as a draft with the code ${copy.code}.` });
      navigate(`${SUBS_BASE}/plans/${copy.id}/edit`);
    } catch (error) {
      toast({ kind: 'error', title: 'Couldn’t duplicate the plan', text: (error as Error).message });
    }
  };

  const changeArchive = async () => {
    if (!detail) return;
    const wasArchived = detail.plan.status === 'archived';
    const plan = wasArchived ? await services.subscriptions.restorePlan(planId) : await services.subscriptions.archivePlan(planId);
    setArchiving(false);
    toast({
      kind: 'success',
      title: wasArchived ? `${plan.name} is back on sale` : `${plan.name} is retired`,
      text: wasArchived ? 'New Admins can choose it again.' : 'New sign-ups can’t choose it. The Admins on it keep it.',
    });
    await reload();
  };

  const publish = async () => {
    const plan = await services.subscriptions.publishPlan(planId);
    setPublishing(false);
    toast({ kind: 'success', title: `${plan.name} is on sale`, text: 'New Admins can choose it from now on.' });
    await reload();
  };

  if (query.status === 'error' && !detail) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        {notFound ? (
          <StateMessage kind="error" title="Plan not found" actions={<LinkButton to={`${SUBS_BASE}/plans`}>Back to plans</LinkButton>}>
            This plan no longer exists.
          </StateMessage>
        ) : (
          <PlatformError title="The plan didn’t load" error={query.error} onRetry={reload} />
        )}
      </div>
    );
  }

  if (!detail) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton width="35%" height={30} radius="var(--r-xs)" />
        <Skeleton width="60%" height={12} />
        <Skeleton height={220} radius="var(--r-lg)" />
        <Skeleton height={280} radius="var(--r-lg)" />
      </div>
    );
  }

  const { plan } = detail;
  const archived = plan.status === 'archived';
  const enabled = new Set(plan.features);

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        back={{ label: 'Plans', to: `${SUBS_BASE}/plans` }}
        title={plan.name}
        description={plan.description}
        meta={
          <div className={styles.headerFacts}>
            <PlanStatusBadge status={plan.status} size="md" />
            {plan.cycles.map((cycle) => (
              <span key={cycle} className={styles.dot}>
                <span className={styles.strong}>{money(cycle === 'annual' ? plan.annualPrice : plan.monthlyPrice, plan.currency)}</span> {cyclePer(cycle)}
              </span>
            ))}
            <span className={styles.dot}>{plural(detail.activeSubscribers, 'Admin')} on it</span>
            <span className={styles.dot}>Updated {formatRelative(plan.updatedAt, now)}</span>
          </div>
        }
        actions={
          <div className={styles.headerActions}>
            <LinkButton to={`${SUBS_BASE}/plans/${plan.id}/edit`} iconStart={<PencilSimple size={16} />}>
              Edit
            </LinkButton>
            <Button onClick={duplicate} iconStart={<Copy size={16} />}>
              Duplicate
            </Button>
            {plan.status === 'draft' && (
              <Button variant="primary" onClick={() => setPublishing(true)} iconStart={<RocketLaunch size={16} />}>
                Put on sale
              </Button>
            )}
            <Button
              onClick={() => setArchiving(true)}
              variant={archived ? 'secondary' : 'danger'}
              iconStart={archived ? <ArrowCounterClockwise size={16} /> : <Archive size={16} />}
            >
              {archived ? 'Put back on sale' : 'Retire'}
            </Button>
          </div>
        }
      />
      <PrototypeNote>A demo plan. Nothing here is sold, and no Admin is gated by it.</PrototypeNote>

      <div className={styles.twoUp}>
        <section className={styles.panel} aria-labelledby="plan-pricing">
          <SectionHeader id="plan-pricing" title="Pricing and trial" />
          <dl className={styles.facts}>
            <Fact label="Plan code" value={<span className={styles.mono}>{plan.code}</span>} />
            <Fact label="Currency" value={plan.currency} />
            <Fact
              label="Monthly"
              value={plan.cycles.includes('monthly') ? money(plan.monthlyPrice, plan.currency) : <span className={styles.faint}>Not offered</span>}
            />
            <Fact
              label="Annual"
              value={plan.cycles.includes('annual') ? money(plan.annualPrice, plan.currency) : <span className={styles.faint}>Not offered</span>}
            />
            <Fact label="Trial" value={plan.trialEnabled ? plural(plan.trialDays, 'day') : <span className={styles.faint}>None</span>} />
            <Fact label="Created" value={formatDate(plan.createdAt)} />
          </dl>
        </section>

        <section className={styles.panel} aria-labelledby="plan-subscribers">
          <SectionHeader id="plan-subscribers" title="Who is on it" description="Admins on this plan, whatever stage they are at." />
          <dl className={styles.facts}>
            <Fact label="Paying or on a free trial" value={detail.activeSubscribers.toLocaleString('en-IN')} />
            <Fact label="All subscriptions" value={detail.subscribers.toLocaleString('en-IN')} />
            <Fact label="Brings in a month" value={money(detail.mrr, plan.currency)} />
          </dl>
          {detail.byStatus.length > 0 && (
            <ul className={styles.featureList} aria-label="Subscriptions by state">
              {detail.byStatus.map(({ status, count }) => (
                <li key={status}>
                  <Link to={`${SUBS_BASE}/subscribers?plan=${plan.id}&status=${status}`} className={styles.featureItem}>
                    <SubscriptionStatusBadge status={status} />
                    <span className={styles.amount}>{count}</span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>

      <section className={styles.panel} aria-labelledby="plan-limits">
        <SectionHeader id="plan-limits" title="Limits" description="The most an Admin on this plan can have." />
        <div className={styles.limits}>
          {LIMIT_KEYS.map((key) => (
            <div key={key} className={styles.limit}>
              <p className={styles.limitValue}>{limitText(key, plan.limits[key])}</p>
              <span className={styles.factLabel}>{limitLabel(key)}</span>
            </div>
          ))}
        </div>
      </section>

      <section className={styles.panel} aria-labelledby="plan-features">
        <SectionHeader id="plan-features" title="Features" description="Which parts of the LMS this plan switches on, and which it leaves out." />
        {FEATURE_GROUPS.map((group) => (
          <div key={group.id} className={styles.featureGroup}>
            <h3 className={styles.featureGroupTitle}>{group.label}</h3>
            <ul className={styles.featureList}>
              {group.features.map((feature) => {
                const on = enabled.has(feature.key);
                return (
                  <li key={feature.key} className={`${styles.featureItem} ${on ? '' : styles.featureOff}`}>
                    {on ? <CheckCircle size={14} weight="fill" /> : <Circle size={14} />}
                    <span>{feature.label}</span>
                    <span className="sr-only">{on ? 'included' : 'not included'}</span>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </section>

      {detail.versions && detail.versions.length > 0 && <VersionHistory versions={detail.versions} />}

      <section className={styles.chartPanel} aria-labelledby="plan-trend">
        <SectionHeader
          id="plan-trend"
          title="Admins on this plan over time"
          description="How many Admins were on it at the end of each of the last six months."
        />
        <ColumnChart
          data={detail.trend.map((t) => ({ label: t.label, detail: t.detail, value: t.active }))}
          label={`Active subscriptions on ${plan.name} over the last six months`}
          unit="active subscriptions"
          height={160}
        />
        <ul className={styles.legend} aria-label="Six-month totals">
          <li className={styles.legendItem}>
            <span className={styles.legendValue}>{detail.trend.reduce((n, t) => n + t.added, 0)}</span> new
          </li>
          <li className={styles.legendItem}>
            <span className={styles.legendValue}>{detail.trend.reduce((n, t) => n + t.canceled, 0)}</span> cancelled
          </li>
        </ul>
      </section>

      <section className={styles.panel} aria-labelledby="plan-list">
        <SectionHeader
          id="plan-list"
          title="On this plan"
          count={detail.subscriptions.length}
          description="Newest first."
          actions={
            detail.subscriptions.length > 0 ? (
              <LinkButton size="sm" to={`${SUBS_BASE}/subscribers?plan=${plan.id}`}>
                See all
              </LinkButton>
            ) : undefined
          }
        />
        {detail.subscriptions.length === 0 ? (
          <StateMessage icon={<Users size={26} />} title="Nobody is on this plan" compact>
            {plan.status === 'draft' ? 'It is still a draft, so no Admin can choose it yet.' : 'No Admin has taken this plan.'}
          </StateMessage>
        ) : (
          <ul className={styles.attention}>
            {detail.subscriptions.slice(0, 8).map(({ subscription }) => (
              <li key={subscription.id} className={styles.attentionItem}>
                <span className={styles.stack}>
                  <Link to={`${SUBS_BASE}/subscribers/${subscription.id}`} className={styles.cellTitle}>
                    {subscription.customer.name}
                  </Link>
                  <span className={styles.cellMeta}>
                    {subscription.customer.city} · started {formatDate(subscription.startedAt)}
                  </span>
                </span>
                <span className={styles.headerFacts}>
                  <SubscriptionStatusBadge status={subscription.status} />
                  <span className={styles.amount}>
                    {money(subscription.amount, subscription.currency)} <span className={styles.faint}>{cyclePer(subscription.cycle)}</span>
                  </span>
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>

      <ConfirmDialog
        open={publishing}
        onClose={() => setPublishing(false)}
        onConfirm={publish}
        icon={<RocketLaunch size={20} />}
        title={`Put ${plan.name} on sale?`}
        description={plan.code}
        confirmLabel="Put on sale"
      >
        New Admins can choose it, and it appears when you change an Admin’s plan. A plan on sale can be retired later, but it can’t go back to being a draft.
      </ConfirmDialog>
      <ConfirmDialog
        open={archiving}
        onClose={() => setArchiving(false)}
        onConfirm={changeArchive}
        tone={archived ? 'default' : 'danger'}
        icon={archived ? <ArrowCounterClockwise size={20} /> : <Archive size={20} />}
        title={archived ? `Put ${plan.name} back on sale?` : `Retire ${plan.name}?`}
        description={plural(detail.subscribers, 'subscription')}
        confirmLabel={archived ? 'Put back on sale' : 'Retire plan'}
      >
        {archived
          ? 'It goes back on the list new Admins choose from. Nothing about the subscriptions already on it changes.'
          : 'New Admins can no longer choose it, and it no longer appears when you change an Admin’s plan. Admins already on it keep its price and features until they move.'}
      </ConfirmDialog>
    </div>
  );
}

/** "₹3,999 a month · ₹39,990 a year" — what a version sold, on the cycles it sold. */
function versionPrice(v: PlanVersion): string {
  const parts = [
    v.monthlyPrice !== null && v.cycles.includes('monthly') ? `${money(v.monthlyPrice, v.currency)} ${cyclePer('monthly')}` : null,
    v.annualPrice !== null && v.cycles.includes('annual') ? `${money(v.annualPrice, v.currency)} ${cyclePer('annual')}` : null,
  ].filter(Boolean);
  return parts.length ? parts.join(' · ') : 'Not priced';
}

/**
 * Every version of the plan's terms, newest first. Editing a price, the trial, a feature or a limit writes the
 * next version; a subscription keeps the version it was sold, so an edit never re-bills anyone.
 */
function VersionHistory({ versions }: { versions: PlanVersion[] }) {
  const newestFirst = [...versions].sort((a, b) => b.version - a.version);
  return (
    <section className={styles.panel} aria-labelledby="plan-versions">
      <SectionHeader
        id="plan-versions"
        title="Version history"
        count={versions.length}
        description="Each change to the price or terms makes a new version. Admins keep the version they bought until they change plan."
      />
      <ul className={styles.attention}>
        {newestFirst.map((v, i) => (
          <li key={v.id} className={styles.attentionItem}>
            <span className={styles.stack}>
              <span className={styles.cellTitle}>
                Version {v.version}
                {i === 0 ? ' · current' : ''}
              </span>
              <span className={styles.cellMeta}>
                {formatDate(v.createdAt)} · {v.trialDays > 0 ? `${plural(v.trialDays, 'day')} trial` : 'No trial'} · {plural(v.features.length, 'feature')}
              </span>
            </span>
            <span className={styles.amount}>{versionPrice(v)}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}
