import { useState, type ReactNode } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
  ArrowCounterClockwise,
  ArrowsLeftRight,
  CheckCircle,
  ClockCountdown,
  CurrencyInr,
  Gift,
  HourglassMedium,
  PauseCircle,
  PlayCircle,
  Prohibit,
  Receipt,
  Sparkle,
  WarningCircle,
  XCircle,
} from '@phosphor-icons/react';
import type { Plan, SubscriptionEventKind, SubscriptionPayment, SubscriptionPlanChange } from '@syniastrolms/domain';
import { daysUntil, invoiceTotal } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatDate, formatRelative, formatTime, plural } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { InvoiceDialog } from './InvoiceDialog';
import { CancelDialog, ChangePlanDialog, ExtendDialog, PauseDialog, ReactivateDialog, RefundDialog, ResumeDialog } from './SubscriptionActions';
import {
  Fact,
  MethodLine,
  PaymentStatusBadge,
  PrototypeNote,
  SUBS_BASE,
  SUBSCRIPTION_STATE,
  SubscriptionStatusBadge,
  cycleLabel,
  cyclePer,
  money,
} from './subscriptionMeta';
import styles from './Subscriptions.module.css';

type Dialog = 'change' | 'pause' | 'resume' | 'cancel' | 'reactivate' | 'extend' | null;

/** How a history entry reads on the rail: its glyph and whether it is good news, bad news or neither. */
const EVENT_META: Record<SubscriptionEventKind, { icon: ReactNode; tone: 'good' | 'bad' | 'plain' }> = {
  created: { icon: <Sparkle size={12} weight="fill" />, tone: 'good' },
  'trial-started': { icon: <HourglassMedium size={12} />, tone: 'plain' },
  'trial-converted': { icon: <CheckCircle size={12} weight="fill" />, tone: 'good' },
  'plan-changed': { icon: <ArrowsLeftRight size={12} />, tone: 'plain' },
  'payment-received': { icon: <CurrencyInr size={12} />, tone: 'good' },
  'payment-failed': { icon: <WarningCircle size={12} />, tone: 'bad' },
  'cancellation-requested': { icon: <ClockCountdown size={12} />, tone: 'bad' },
  'cancellation-completed': { icon: <XCircle size={12} />, tone: 'bad' },
  paused: { icon: <PauseCircle size={12} />, tone: 'plain' },
  resumed: { icon: <PlayCircle size={12} />, tone: 'good' },
  reactivated: { icon: <ArrowCounterClockwise size={12} />, tone: 'good' },
  extended: { icon: <Gift size={12} />, tone: 'good' },
};

/** How a payment's outcome reads beside it. */
const PAYMENT_TONE: Record<SubscriptionPayment['status'], { label: string; tone: 'accent' | 'danger' | 'warn' | 'info' }> = {
  paid: { label: 'Paid', tone: 'accent' },
  pending: { label: 'Waiting', tone: 'info' },
  failed: { label: 'Failed', tone: 'danger' },
  refunded: { label: 'Refunded', tone: 'warn' },
  partially_refunded: { label: 'Partly refunded', tone: 'warn' },
};

/** One open plan change in words: an upgrade waiting for its payment, or a move waiting for the period end. */
function changeText(change: SubscriptionPlanChange, plans: Plan[]): { title: string; body: string } {
  const name = plans.find((p) => p.id === change.toPlanId)?.name ?? 'another plan';
  const target = `${name} (${cycleLabel(change.toCycle).toLowerCase()}, ${money(change.toAmount, change.currency)} ${cyclePer(change.toCycle)})`;
  if (change.status === 'pending_payment') {
    return {
      title: `Upgrade to ${target} is waiting for payment.`,
      body: `${money(change.charge, change.currency)} is due for the rest of this period, after a ${money(change.credit, change.currency)} credit. It applies once that payment is confirmed. Quoted ${formatDate(change.quotedAt)}.`,
    };
  }
  return {
    title: `Moving to ${target} on ${formatDate(change.periodEnd)}.`,
    body: `Scheduled for the end of the period. Nothing is charged or refunded; the Admin keeps its current plan until then. Asked for ${formatDate(change.quotedAt)}.`,
  };
}

/**
 * One academy's subscription: where it stands, what it is billed, what has happened to it and the
 * five things that can be done to it. Each action asks the billing API, which applies its own rules.
 */
export default function SubscriberDetailPage() {
  const { subscriptionId = '' } = useParams();
  const now = useNow();
  const toast = useToast();
  const [dialog, setDialog] = useState<Dialog>(null);
  const [invoiceId, setInvoiceId] = useState<string | null>(null);
  const [refunding, setRefunding] = useState<SubscriptionPayment | null>(null);

  const query = useAsync(`subs:subscription:${subscriptionId}`, () =>
    Promise.all([services.subscriptions.getSubscription(subscriptionId), services.subscriptions.listPlans()]).then(([detail, list]) => ({
      detail,
      plans: list.rows.map((r) => r.plan),
    })),
  );
  const detail = query.data?.detail;
  usePageCrumbs(detail ? [{ label: detail.subscription.customer.name }] : [{ label: 'Subscription' }]);

  const reload = async () => {
    await query.run().catch(() => undefined);
  };

  const done = (title: string, text: string) => async () => {
    setDialog(null);
    toast({ kind: 'success', title, text });
    await reload();
  };

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        {notFound ? (
          <StateMessage kind="error" title="Subscription not found" actions={<LinkButton to={`${SUBS_BASE}/subscribers`}>Back to subscriptions</LinkButton>}>
            This subscription no longer exists.
          </StateMessage>
        ) : (
          <PlatformError title="The subscription didn’t load" error={query.error} onRetry={reload} />
        )}
      </div>
    );
  }

  if (!detail || !query.data) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton width="40%" height={30} radius="var(--r-xs)" />
        <Skeleton width="55%" height={12} />
        <Skeleton height={200} radius="var(--r-lg)" />
        <Skeleton height={320} radius="var(--r-lg)" />
      </div>
    );
  }

  const { subscription: s, plan, events, invoices } = detail;
  const openChanges = detail.openChanges ?? [];
  const payments = detail.payments ?? [];
  const state = SUBSCRIPTION_STATE[s.status];
  const closed = s.status === 'canceled' || s.status === 'expired';

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        back={{ label: 'Subscriptions', to: `${SUBS_BASE}/subscribers` }}
        title={s.customer.name}
        description={state.meaning}
        meta={
          <div className={styles.headerFacts}>
            <SubscriptionStatusBadge status={s.status} size="md" />
            <span className={styles.dot}>
              <Link to={`${SUBS_BASE}/plans/${plan.id}`}>{plan.name}</Link> · {cycleLabel(s.cycle)}
            </span>
            <span className={styles.dot}>
              {closed ? 'Ended' : s.status === 'canceling' ? 'Access until' : 'Renews'} {formatDate(s.renewsAt)}
            </span>
            <span className={styles.dot}>
              <span className={styles.strong}>{money(s.amount, s.currency)}</span> {cyclePer(s.cycle)}
            </span>
          </div>
        }
        actions={
          <div className={styles.headerActions}>
            <Button onClick={() => setDialog('change')} iconStart={<ArrowsLeftRight size={16} />} disabled={closed}>
              Change plan
            </Button>
            {s.status === 'active' && (
              <Button onClick={() => setDialog('extend')} iconStart={<Gift size={16} />}>
                Add complimentary days
              </Button>
            )}
            {s.status === 'paused' ? (
              <Button onClick={() => setDialog('resume')} iconStart={<PlayCircle size={16} />}>
                Resume
              </Button>
            ) : (
              <Button onClick={() => setDialog('pause')} iconStart={<PauseCircle size={16} />} disabled={closed}>
                Pause
              </Button>
            )}
            {closed || s.status === 'canceling' ? (
              <Button variant="primary" onClick={() => setDialog('reactivate')} iconStart={<ArrowCounterClockwise size={16} />}>
                Reactivate
              </Button>
            ) : (
              <Button variant="danger" onClick={() => setDialog('cancel')} iconStart={<Prohibit size={16} />}>
                Cancel
              </Button>
            )}
          </div>
        }
      />
      <PrototypeNote />

      {s.status === 'trial' && s.trialEndsAt && (
        <InlineMessage kind="info" title={`Trial ends ${formatDate(s.trialEndsAt)}.`}>
          Day {Math.max(1, plan.trialDays - daysUntil(s.trialEndsAt, now))} of {plan.trialDays} — {plural(daysUntil(s.trialEndsAt, now), 'day')} left. The first
          charge of {money(s.amount, s.currency)} would be taken when it converts.
        </InlineMessage>
      )}
      {s.status === 'past-due' && (
        <InlineMessage kind="error" title={`${money(s.amountDue ?? s.amount, s.currency)} is outstanding.`}>
          Last charge failed {s.lastPaymentAt ? formatRelative(s.lastPaymentAt, now) : 'recently'}
          {typeof s.retriesUsed === 'number' ? ` after ${plural(s.retriesUsed, 'retry', 'retries')}` : ''}.
          {s.nextRetryAt ? ` The next retry runs ${formatDate(s.nextRetryAt)}.` : ''}
          {s.graceEndsAt ? ` The grace period ends ${formatDate(s.graceEndsAt)} — ${plural(daysUntil(s.graceEndsAt, now), 'day')} away.` : ''}
        </InlineMessage>
      )}
      {s.status === 'canceling' && (
        <InlineMessage kind="warn" title={`Cancelling on ${formatDate(s.renewsAt)}.`}>
          {s.cancelReason ?? 'No reason was recorded.'} Reactivating before that date keeps the subscription exactly as it is.
        </InlineMessage>
      )}
      {s.status === 'paused' && s.resumesAt && (
        <InlineMessage kind="info" title={`Paused until ${formatDate(s.resumesAt)}.`}>
          Nothing new can be added while it is paused. Resuming moves the renewal date out by the time actually paused, up to 30 days.
        </InlineMessage>
      )}

      {openChanges.map((change) => {
        const text = changeText(change, query.data!.plans);
        return (
          <InlineMessage key={change.id} kind="info" title={text.title}>
            {text.body}
          </InlineMessage>
        );
      })}

      <div className={styles.mainAside}>
        <div className={styles.column}>
          <section className={styles.panel} aria-labelledby="sub-facts">
            <SectionHeader id="sub-facts" title="Subscription" />
            <dl className={styles.facts}>
              <Fact label="Subscription ID" value={<span className={styles.mono}>{s.id}</span>} />
              <Fact label="Plan" value={<Link to={`${SUBS_BASE}/plans/${plan.id}`}>{plan.name}</Link>} />
              <Fact label="Billing cycle" value={cycleLabel(s.cycle)} />
              <Fact label="Started" value={formatDate(s.startedAt)} />
              <Fact label={closed ? 'Ended' : 'Renews'} value={formatDate(s.renewsAt)} />
              <Fact
                label="Trial"
                value={
                  s.trialStartedAt && s.trialEndsAt ? (
                    `${formatDate(s.trialStartedAt)} – ${formatDate(s.trialEndsAt)}`
                  ) : (
                    <span className={styles.faint}>No trial</span>
                  )
                }
              />
              {s.canceledAt && (
                <Fact label="Cancelled" value={`${formatDate(s.canceledAt)} · ${s.cancelAt === 'immediately' ? 'immediately' : 'at period end'}`} />
              )}
              {s.pausedAt && <Fact label="Paused" value={formatDate(s.pausedAt)} />}
            </dl>
            {s.cancelReason && (
              <p className={styles.muted}>
                <span className={styles.factLabel}>Reason</span> — {s.cancelReason}
              </p>
            )}
          </section>

          <section className={styles.panel} aria-labelledby="sub-billing">
            <SectionHeader id="sub-billing" title="Charges" description="What this subscription costs, and how it is paid." />
            <dl className={styles.facts}>
              <Fact label="Current amount" value={`${money(s.amount, s.currency)} ${cyclePer(s.cycle)}`} />
              <Fact label="Currency" value={s.currency} />
              <Fact
                label="Payment status"
                value={s.lastPaymentStatus ? <PaymentStatusBadge status={s.lastPaymentStatus} /> : <span className={styles.faint}>Not charged yet</span>}
              />
              <Fact label="Last payment" value={s.lastPaymentAt ? formatDate(s.lastPaymentAt) : <span className={styles.faint}>None</span>} />
              <Fact label="Next payment" value={closed || s.status === 'canceling' ? <span className={styles.faint}>None</span> : formatDate(s.renewsAt)} />
              <Fact label="Payment method" value={<MethodLine method={s.paymentMethod} />} />
            </dl>
            <p className={styles.muted}>Card details are never stored — only a brand and the last four digits, as shown.</p>
          </section>

          <section className={styles.panel} aria-labelledby="sub-invoices">
            <SectionHeader
              id="sub-invoices"
              title="Invoices"
              count={invoices.length}
              actions={
                <LinkButton size="sm" to={`${SUBS_BASE}/billing?q=${encodeURIComponent(s.customer.name)}`}>
                  All payments
                </LinkButton>
              }
            />
            {invoices.length === 0 ? (
              <StateMessage icon={<Receipt size={26} />} title="No invoices yet" compact>
                {s.status === 'trial' ? 'Nothing is invoiced during a trial.' : 'This subscription has not been billed.'}
              </StateMessage>
            ) : (
              <ul className={styles.attention}>
                {invoices.map((invoice) => (
                  <li key={invoice.id} className={styles.attentionItem}>
                    <span className={styles.stack}>
                      <button type="button" className={`${styles.cellTitle} ${styles.mono}`} onClick={() => setInvoiceId(invoice.id)}>
                        {invoice.number}
                      </button>
                      <span className={styles.cellMeta}>
                        {formatDate(invoice.periodStart)} – {formatDate(invoice.periodEnd)}
                      </span>
                    </span>
                    <span className={styles.headerFacts}>
                      <PaymentStatusBadge status={invoice.status} />
                      <span className={`${styles.amount} ${styles.strong}`}>{money(invoiceTotal(invoice), invoice.currency)}</span>
                      <Button size="sm" onClick={() => setInvoiceId(invoice.id)}>
                        View
                      </Button>
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section className={styles.panel} aria-labelledby="sub-payments">
            <SectionHeader
              id="sub-payments"
              title="Payments"
              count={payments.length}
              description="What was taken against this subscription, and what has gone back."
            />
            {payments.length === 0 ? (
              <p className={styles.muted}>No payment has been taken for this subscription.</p>
            ) : (
              <ul className={styles.attention}>
                {payments.map((payment) => {
                  const state = PAYMENT_TONE[payment.status];
                  return (
                    <li key={payment.id} className={styles.attentionItem}>
                      <span className={styles.stack}>
                        <span className={`${styles.amount} ${styles.strong}`}>{money(payment.amount, payment.currency)}</span>
                        <span className={styles.cellMeta}>
                          {formatDate(payment.at)} · {payment.method ?? (payment.provider === 'offline' ? 'Recorded offline' : payment.provider)}
                          {payment.refunded > 0 ? ` · ${money(payment.refunded, payment.currency)} refunded` : ''}
                        </span>
                        {payment.failureMessage && <span className={styles.cellMeta}>{payment.failureMessage}</span>}
                      </span>
                      <span className={styles.headerFacts}>
                        <Badge size="sm" tone={state.tone}>
                          {state.label}
                        </Badge>
                        <Button
                          size="sm"
                          onClick={() => setRefunding(payment)}
                          disabled={payment.refundable <= 0}
                          title={payment.refundable <= 0 ? 'Nothing is left to refund on this payment.' : undefined}
                        >
                          Refund
                        </Button>
                      </span>
                    </li>
                  );
                })}
              </ul>
            )}
          </section>
        </div>

        <div className={styles.column}>
          <section className={styles.panel} aria-labelledby="sub-customer">
            <SectionHeader
              id="sub-customer"
              title="Customer"
              actions={
                <LinkButton size="sm" to={`/superadmin/academies/${s.customer.id}`}>
                  Open Admin
                </LinkButton>
              }
            />
            <dl className={styles.facts}>
              <Fact label="Billing contact" value={<a href={`mailto:${s.customer.email}`}>{s.customer.email}</a>} />
              <Fact label="Location" value={`${s.customer.city}, ${s.customer.country}`} />
              <Fact
                label="Students"
                value={`${s.customer.learners.toLocaleString('en-IN')}${plan.limits['learners.max'] === null ? '' : ` of ${plan.limits['learners.max'].toLocaleString('en-IN')}`}`}
              />
            </dl>
          </section>

          <section className={styles.panel} aria-labelledby="sub-history">
            <SectionHeader id="sub-history" title="History" description="Newest first." />
            {events.length === 0 ? (
              <p className={styles.muted}>No changes to this subscription yet.</p>
            ) : (
              <ol className={styles.history}>
                {events.map((event) => {
                  const meta = EVENT_META[event.kind];
                  return (
                    <li key={event.id} className={styles.historyItem}>
                      <span
                        className={`${styles.historyNode} ${meta.tone === 'good' ? styles.historyGood : meta.tone === 'bad' ? styles.historyBad : ''}`}
                        aria-hidden="true"
                      >
                        {meta.icon}
                      </span>
                      <span className={styles.historyBody}>
                        <span className={styles.factValue}>{event.summary}</span>
                        <span className={styles.historyTime}>
                          <time dateTime={event.at}>
                            {formatDate(event.at)} · {formatTime(event.at)}
                          </time>{' '}
                          · {event.actor}
                        </span>
                      </span>
                    </li>
                  );
                })}
              </ol>
            )}
          </section>
        </div>
      </div>

      <ChangePlanDialog
        subscription={s}
        plans={query.data.plans}
        open={dialog === 'change'}
        onClose={() => setDialog(null)}
        onDone={done('Plan change requested', 'The history shows the quote or the date it applies.')}
      />
      <PauseDialog
        subscription={s}
        open={dialog === 'pause'}
        onClose={() => setDialog(null)}
        onDone={done('Subscription paused', `${s.customer.name} is paused until its resume date.`)}
      />
      <ResumeDialog
        subscription={s}
        open={dialog === 'resume'}
        onClose={() => setDialog(null)}
        onDone={done('Subscription resumed', `${s.customer.name} is active again.`)}
      />
      <CancelDialog
        subscription={s}
        open={dialog === 'cancel'}
        onClose={() => setDialog(null)}
        onDone={done('Subscription cancelled', `${s.customer.name} — the reason is on the history.`)}
      />
      <ReactivateDialog
        subscription={s}
        open={dialog === 'reactivate'}
        onClose={() => setDialog(null)}
        onDone={done('Subscription reactivated', `${s.customer.name} is active again.`)}
      />
      <ExtendDialog
        subscription={s}
        open={dialog === 'extend'}
        onClose={() => setDialog(null)}
        onDone={done('Complimentary days added', `${s.customer.name} — the new period end is on the history.`)}
      />
      <RefundDialog
        payment={refunding}
        customer={s.customer.name}
        onClose={() => setRefunding(null)}
        onDone={async (refund) => {
          setRefunding(null);
          toast({
            kind: refund.status === 'failed' ? 'error' : 'success',
            title: refund.status === 'succeeded' ? 'Refunded' : refund.status === 'pending' ? 'Refund requested' : 'The refund was refused',
            text:
              refund.status === 'pending'
                ? `${money(refund.amount, refund.currency)} — the provider confirms it shortly. The subscription is unchanged.`
                : `${money(refund.amount, refund.currency)}. The subscription is unchanged.`,
          });
          await reload();
        }}
      />
      <InvoiceDialog invoiceId={invoiceId} onClose={() => setInvoiceId(null)} onChanged={reload} />
    </div>
  );
}
