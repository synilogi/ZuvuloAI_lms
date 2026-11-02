import { useCallback, useEffect, useRef, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { ArrowCounterClockwise, ArrowsLeftRight, Check, CreditCard, Minus, Prohibit, Receipt } from '@phosphor-icons/react';
import type { BillingCycle, CheckoutStart, Plan, PlanChangeQuote } from '@syniastrolms/domain';
import { daysUntil, invoiceTotal } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useTenantBilling } from '@/hooks/useTenantBilling';
import { formatDate, plural } from '@/lib/format';
import { BILLING_STATES, billingStateOf } from '@/lib/billingStates';
import { describeCheckoutOutcome, isAwaitingProvider, planActionMode, pollUntil } from '@/lib/billingActions';
import { openGatewayCheckout } from '@/lib/gatewayCheckout';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { WELCOME_PAGE } from '@/lib/planAccess';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { useSession } from '@/providers/SessionProvider';
import { services } from '@/services';
import { InvoiceDialog } from '@/pages/superadmin/subscriptions/InvoiceDialog';
import { BillingDetailsDialog } from './BillingDetailsDialog';
import { CancelSubscriptionDialog } from './CancelSubscriptionDialog';
import { PlanChangeDialog, type PlanChoice } from './PlanChangeDialog';
import {
  Fact,
  PaymentStatusBadge,
  PrototypeNote,
  SUBSCRIPTION_STATE,
  SubscriptionStatusBadge,
  cycleLabel,
  cyclePer,
  limitText,
  money,
  priceFor,
  rangeSummary,
} from '@/pages/superadmin/subscriptions/subscriptionMeta';
import styles from '@/pages/superadmin/subscriptions/Subscriptions.module.css';

/*
 * The academy's own subscription, for its admin (subscriptions.md §24): the plan, its status, cycle and
 * renewal date, what the academy uses against each limit, what the plan includes, the invoices and
 * payments, and the plans it could move to.
 *
 * Everything shown is the server's, for the signed-in account's academy only — there is no way to name
 * another. The admin never sets a price: asking for another plan answers with the server's quote (an
 * upgrade, charged for the rest of the period and applied once paid) or the date it applies (a
 * downgrade, at the period end). Platform plans are managed by the platform, not here.
 */

interface Pending {
  plan: Plan;
  cycle: BillingCycle;
}

/** Invoices shown a page at a time once there are more than this. */
const INVOICES_PER_PAGE = 10;

export default function AcademyBillingPage() {
  const now = useNow();
  const toast = useToast();
  const { user } = useSession();
  const canChange = (user?.permissions ?? []).includes('settings.edit');
  const [pending, setPending] = useState<PlanChoice | null>(null);
  const [quote, setQuote] = useState<PlanChangeQuote | null>(null);
  const [invoiceId, setInvoiceId] = useState<string | null>(null);
  const [withdrawing, setWithdrawing] = useState(false);
  const [paying, setPaying] = useState<string | null>(null);
  const [purchase, setPurchase] = useState<Pending | null>(null);
  const [canceling, setCanceling] = useState(false);
  const [resuming, setResuming] = useState(false);
  // The provider has the payment but has not settled it: the page asks again until the invoice is paid.
  const [awaiting, setAwaiting] = useState<string | null>(null);
  const [invoicePage, setInvoicePage] = useState(1);
  const leaving = useRef(new AbortController());
  useEffect(() => {
    const controller = new AbortController();
    leaving.current = controller;
    return () => controller.abort();
  }, []);

  // Shared with the shell's billing banner; read again on opening the page so it is current.
  const query = useTenantBilling(user?.id, { refresh: true });
  const data = query.data;
  const reload = () => query.run().catch(() => undefined);
  // Where invoices are addressed: a first purchase needs it, so choosing a plan without it opens the form first.
  const details = useAsync('academy:billing-details', () => services.tenantBilling.getBillingDetails());
  const [editingDetails, setEditingDetails] = useState(false);
  const [waitingPlan, setWaitingPlan] = useState<Pending | null>(null);
  // A plan change waiting on the address: an upgrade is taxed by it, so it can't be priced until it is set.
  const [waitingChange, setWaitingChange] = useState<PlanChoice | null>(null);
  const choosePlan = (choice: Pending) => {
    if (details.status === 'success' && !details.data) {
      setWaitingPlan(choice);
      setEditingDetails(true);
    } else setPurchase(choice);
  };
  const changeNeedsAddress = useCallback((choice: PlanChoice) => {
    setPending(null);
    setWaitingChange(choice);
    setEditingDetails(true);
  }, []);

  // "Buy now" on the first-plan page lands here with the plan and cycle chosen: go straight on to buying it —
  // the billing details first if they are missing, then the confirmation and the checkout.
  const [params, setParams] = useSearchParams();
  const wantedPlan = params.get('plan');
  const wantedCycle: BillingCycle = params.get('cycle') === 'annual' ? 'annual' : 'monthly';
  useEffect(() => {
    if (!wantedPlan || !data || details.status !== 'success') return;
    setParams({}, { replace: true });
    const chosen = data.plans.find((p) => p.id === wantedPlan);
    if (chosen && chosen.cycles.includes(wantedCycle) && planActionMode(data, canChange) === 'purchase') choosePlan({ plan: chosen, cycle: wantedCycle });
    // choosePlan reads the details just checked; running again for it would buy twice.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [wantedPlan, wantedCycle, data, details.status, canChange, setParams]);

  // Back from a gateway's own payment page (SAAS-030): the gateway's webhook decided the outcome; this only reports
  // it and reads the billing again, so what the page shows is what the server recorded.
  const returned = params.get('checkout');
  useEffect(() => {
    if (!returned) return;
    setParams({}, { replace: true });
    if (returned === 'paid') toast({ kind: 'success', title: 'Payment received', text: 'Thank you — your billing is up to date.' });
    else if (returned === 'failed') toast({ kind: 'error', title: 'The payment was declined', text: 'Nothing was charged. You can try again.' });
    else if (returned === 'cancelled') toast({ kind: 'info', title: 'Checkout cancelled', text: 'Nothing was charged.' });
    void reload();
    // Once per return.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [returned]);

  if (query.status === 'error' && !data) {
    const state = billingStateOf(query.error);
    return (
      <div className={styles.page}>
        <PageHeader title="Billing" />
        <StateMessage kind="error" title={state?.title ?? 'Billing didn’t load'} actions={<Button onClick={reload}>Try again</Button>}>
          {(query.error as Error).message}
        </StateMessage>
      </div>
    );
  }

  if (!data) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton width="30%" height={30} radius="var(--r-xs)" />
        <Skeleton height={160} radius="var(--r-lg)" />
        <Skeleton height={280} radius="var(--r-lg)" />
      </div>
    );
  }

  const { subscription: s, plan, openChange } = data;
  const closed = !s || s.status === 'canceled' || s.status === 'expired';
  const restrictedState = data.restricted && data.enforced ? BILLING_STATES[s?.status === 'expired' ? 'SUBSCRIPTION_EXPIRED' : 'SUBSCRIPTION_REQUIRED'] : null;
  const mode = planActionMode(data, canChange);
  const invoicePages = Math.max(1, Math.ceil(data.invoices.length / INVOICES_PER_PAGE));
  const currentInvoicePage = Math.min(invoicePage, invoicePages);
  const shownInvoices = data.invoices.slice((currentInvoicePage - 1) * INVOICES_PER_PAGE, currentInvoicePage * INVOICES_PER_PAGE);

  /**
   * Runs one checkout: the server fixes the amount and opens the order (`open`); the provider's window takes
   * the payment; its answer goes back to the server, which reads the payment from the provider before
   * recording anything — so what this shows afterwards is the provider's word, not the browser's.
   */
  const runCheckout = async (key: string, open: () => Promise<CheckoutStart>) => {
    setPaying(key);
    try {
      const start = await open();
      const completion = await openGatewayCheckout(start, { academy: data.academy.name, email: user?.email });
      // Sent to the gateway's own page: the payment is confirmed by its webhook when the payer returns.
      if (completion === 'redirected') return;
      if (!completion) {
        toast({ kind: 'info', title: 'Checkout closed', text: `Nothing was charged. ${start.invoice.number} is still open.` });
        return;
      }
      const outcome = await services.tenantBilling.confirmCheckout(completion);
      toast(describeCheckoutOutcome(outcome));
      setQuote(null);
      if (isAwaitingProvider(outcome)) {
        setPaying(null);
        await awaitProvider(start.invoice.id, start.invoice.number);
        return;
      }
      await reload();
    } catch (e) {
      toast({ kind: 'error', title: 'That didn’t work', text: (e as Error).message });
    } finally {
      setPaying(null);
    }
  };

  /**
   * The provider took the payment and has not settled it yet: ask for the summary every 5 seconds, a minute at
   * most, until the invoice reads as paid. Stops when the page goes away.
   */
  const awaitProvider = async (invoice: string, number: string) => {
    setAwaiting(number);
    const signal = leaving.current.signal;
    const paid = await pollUntil(async () => (await query.run()).invoices.some((i) => i.id === invoice && i.status === 'paid'), { signal });
    if (signal.aborted) return;
    setAwaiting(null);
    toast(
      paid
        ? { kind: 'success', title: 'Payment received', text: `${number} is paid.` }
        : {
            kind: 'info',
            title: 'Still being confirmed',
            text: `The provider has not settled ${number} yet. It updates here once it does — check back shortly.`,
          },
    );
    await reload();
  };

  const resume = async () => {
    setResuming(true);
    try {
      await services.tenantBilling.resume();
      toast({ kind: 'success', title: 'Subscription kept', text: 'The cancellation is withdrawn. It renews as before.' });
      await reload();
    } catch (e) {
      toast({ kind: 'error', title: 'That didn’t work', text: (e as Error).message });
    } finally {
      setResuming(false);
    }
  };

  /** Pays an open invoice, or an upgrade's quote. */
  const pay = (target: { invoiceId?: string; planChangeId?: string }) =>
    runCheckout(target.invoiceId ?? target.planChangeId ?? '', () => services.tenantBilling.startCheckout(target));

  /** The academy's first plan: the server prices and invoices it, then the same checkout runs. */
  const buy = (choice: Pending) =>
    runCheckout(`purchase:${choice.plan.id}:${choice.cycle}`, () => services.tenantBilling.startFirstPurchase({ planId: choice.plan.id, cycle: choice.cycle }));

  const withdraw = async () => {
    if (!openChange) return;
    setWithdrawing(true);
    try {
      await services.tenantBilling.withdrawChange(openChange.id);
      toast({ kind: 'success', title: 'Plan change withdrawn', text: 'The LMS stays on its current plan.' });
      setQuote(null);
      await reload();
    } catch (e) {
      toast({ kind: 'error', title: 'That didn’t work', text: (e as Error).message });
    } finally {
      setWithdrawing(false);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Billing"
        description={s ? SUBSCRIPTION_STATE[s.status].meaning : 'This LMS has no subscription yet.'}
        actions={
          canChange && s ? (
            s.status === 'canceling' ? (
              <Button variant="primary" onClick={resume} loading={resuming} iconStart={<ArrowCounterClockwise size={16} />}>
                Keep my subscription
              </Button>
            ) : s.status === 'active' || s.status === 'past-due' || s.status === 'trial' ? (
              <Button variant="danger" onClick={() => setCanceling(true)} iconStart={<Prohibit size={16} />}>
                Cancel subscription
              </Button>
            ) : undefined
          ) : undefined
        }
        meta={
          s && plan ? (
            <div className={styles.headerFacts}>
              <SubscriptionStatusBadge status={s.status} size="md" />
              <span className={styles.dot}>
                {plan.name} · {cycleLabel(s.cycle)}
              </span>
              <span className={styles.dot}>
                {closed ? 'Ended' : s.status === 'canceling' ? 'Access until' : 'Renews'} {formatDate(s.renewsAt)}
              </span>
              <span className={styles.dot}>
                <span className={styles.strong}>{money(s.amount, s.currency)}</span> {cyclePer(s.cycle)}
              </span>
            </div>
          ) : undefined
        }
      />
      <PrototypeNote>Demo billing. The LMS, its plan and its invoices are invented; nothing is charged.</PrototypeNote>

      {data.trialAvailable && canChange && (
        <InlineMessage
          kind="info"
          title="Try a plan free first."
          action={
            <LinkButton size="sm" variant="primary" to={WELCOME_PAGE}>
              Start a free trial
            </LinkButton>
          }
        >
          Every plan with a trial can be used free for its trial period — no payment and no billing details needed.
        </InlineMessage>
      )}
      {!data.enforced && (
        <InlineMessage kind="info" title={data.restricted ? 'No plan yet — nothing is blocked' : 'Plan limits are not enforced yet'}>
          The platform does not enforce plans yet, so no limit, feature or missing plan stops anyone here. The figures below show where the LMS stands against{' '}
          {data.restricted ? 'a plan' : 'its plan'}.
        </InlineMessage>
      )}
      {restrictedState && (
        <InlineMessage kind={restrictedState.tone === 'danger' ? 'error' : 'warn'} title={restrictedState.title}>
          {restrictedState.body}
        </InlineMessage>
      )}
      {s?.status === 'past-due' && (
        <InlineMessage kind="error" title={`${money(s.amountDue ?? s.amount, s.currency)} is overdue.`}>
          The last payment did not go through. Access continues for now
          {s.graceEndsAt ? `; the grace period ends ${formatDate(s.graceEndsAt)} — ${plural(daysUntil(s.graceEndsAt, now), 'day')} away` : ''}.
        </InlineMessage>
      )}
      {s?.status === 'trial' && s.trialEndsAt && (
        <InlineMessage kind="info" title={`Trial ends ${formatDate(s.trialEndsAt)}.`}>
          {plural(daysUntil(s.trialEndsAt, now), 'day')} left. The first charge of {money(s.amount, s.currency)} is taken when it converts.
        </InlineMessage>
      )}
      {awaiting && (
        <InlineMessage kind="info" title="Waiting for the payment provider…">
          The payment for {awaiting} has been taken and is being confirmed. This page updates by itself — there is no need to pay again.
        </InlineMessage>
      )}
      {s?.status === 'canceling' && (
        <InlineMessage kind="warn" title={`Cancelling on ${formatDate(s.renewsAt)}.`}>
          The LMS keeps everything it has until then.{canChange ? ' Keep the subscription to withdraw the cancellation.' : ''}
        </InlineMessage>
      )}
      {s?.status === 'paused' && (
        <InlineMessage kind="info" title={s.resumesAt ? `Paused by the platform team until ${formatDate(s.resumesAt)}.` : 'Paused by the platform team.'}>
          Nothing new can be added while the subscription is paused. The renewal date moves out by the time it is paused. Only the platform team can resume it
          early.
        </InlineMessage>
      )}
      {openChange && (
        <InlineMessage
          kind="info"
          title={
            openChange.direction === 'upgrade'
              ? `Upgrade to ${openChange.toPlanName} waiting for payment.`
              : `Moving to ${openChange.toPlanName} on ${formatDate(openChange.effectiveAt!)}.`
          }
          action={
            canChange ? (
              <span className={styles.headerFacts}>
                {openChange.direction === 'upgrade' && data.checkoutAvailable && (
                  <Button size="sm" variant="primary" onClick={() => pay({ planChangeId: openChange.id })} loading={paying === openChange.id}>
                    Pay {money(openChange.charge, openChange.currency)} + tax
                  </Button>
                )}
                <Button size="sm" onClick={withdraw} loading={withdrawing}>
                  Withdraw
                </Button>
              </span>
            ) : undefined
          }
        >
          {openChange.direction === 'upgrade'
            ? `${money(openChange.charge, openChange.currency)} is due for the rest of this period, after a ${money(openChange.credit, openChange.currency)} credit for what is unused. The new plan starts once the payment is confirmed.${
                data.checkoutAvailable ? '' : ' Online payment is not connected yet — the platform team confirms the payment.'
              }`
            : `The LMS keeps its current plan until then. Nothing is refunded, and nothing is deleted if usage is above the new plan’s limits.`}
        </InlineMessage>
      )}
      {quote?.payable && (
        <InlineMessage kind="info" title={`Payable now: ${money(quote.payable.gross, quote.payable.currency)}`}>
          {money(quote.payable.net, quote.payable.currency)} plus {money(quote.payable.tax, quote.payable.currency)} tax.
        </InlineMessage>
      )}

      <div className={styles.mainAside}>
        <div className={styles.column}>
          <section className={styles.panel} aria-labelledby="billing-usage">
            <SectionHeader id="billing-usage" title="Usage" description="What the LMS uses against each limit of its plan." />
            <dl className={styles.facts}>
              {data.usage.map((line) => (
                <Fact
                  key={line.limit}
                  label={line.label}
                  value={
                    <span className={styles.headerFacts}>
                      <span className={styles.strong}>{limitText(line.limit, line.used)}</span>
                      <span className={styles.muted}>of {limitText(line.limit, line.allowed)}</span>
                      {data.enforced && line.allowed !== null && line.used >= line.allowed && (
                        <Badge size="sm" tone="warn">
                          {BILLING_STATES.LIMIT_REACHED.title}
                        </Badge>
                      )}
                    </span>
                  }
                />
              ))}
            </dl>
          </section>

          <section className={styles.panel} aria-labelledby="billing-plans">
            <SectionHeader
              id="billing-plans"
              title="Plans"
              description={
                closed
                  ? 'The plans on sale. Prices are before tax.'
                  : 'An upgrade is charged for the rest of this period and starts once paid. A move to a smaller plan starts when the period ends.'
              }
            />
            {closed ? (
              <StateMessage icon={<CreditCard size={26} />} title={s ? 'The subscription has ended' : 'No subscription yet'} compact>
                {mode === 'purchase'
                  ? 'Choose a plan below. The first period is paid now, tax included, and the subscription starts as soon as the payment is confirmed.'
                  : !data.checkoutAvailable
                    ? 'Online payment is not available yet. Ask the platform team to start a subscription. The plans below are what is on sale.'
                    : 'An admin who can change billing settings can choose a plan below.'}
              </StateMessage>
            ) : null}
            <ul className={styles.attention}>
              {data.plans.map((p) => (
                <li key={p.id} className={styles.attentionItem}>
                  <span className={styles.stack}>
                    <span className={styles.cellTitle}>
                      {p.name} {plan?.id === p.id && <Badge size="sm">Current</Badge>}
                    </span>
                    <span className={styles.cellMeta}>{p.cycles.map((c) => `${money(priceFor(p, c), p.currency)} ${cyclePer(c)}`).join(' · ')}</span>
                  </span>
                  {mode === 'purchase' && (
                    <span className={styles.headerFacts}>
                      {p.cycles.map((c) => (
                        <Button
                          key={c}
                          size="sm"
                          variant="primary"
                          iconStart={<CreditCard size={14} />}
                          loading={paying === `purchase:${p.id}:${c}`}
                          disabled={paying !== null}
                          onClick={() => choosePlan({ plan: p, cycle: c })}
                        >
                          Choose {cycleLabel(c).toLowerCase()}
                        </Button>
                      ))}
                    </span>
                  )}
                  {mode === 'change' && s && (
                    <span className={styles.headerFacts}>
                      {p.cycles
                        .filter((c) => !(p.id === s.planId && c === s.cycle))
                        .map((c) => (
                          <Button key={c} size="sm" iconStart={<ArrowsLeftRight size={14} />} onClick={() => setPending({ plan: p, cycle: c })}>
                            {p.id === s.planId ? `Switch to ${cycleLabel(c).toLowerCase()}` : cycleLabel(c)}
                          </Button>
                        ))}
                    </span>
                  )}
                </li>
              ))}
            </ul>
          </section>

          <section className={styles.panel} aria-labelledby="billing-invoices">
            <SectionHeader id="billing-invoices" title="Invoices" count={data.invoices.length} />
            {data.invoices.length === 0 ? (
              <StateMessage icon={<Receipt size={26} />} title="No invoices yet" compact>
                Invoices appear here when the LMS is billed.
              </StateMessage>
            ) : (
              <ul className={styles.attention}>
                {shownInvoices.map((invoice) => (
                  <li key={invoice.id} className={styles.attentionItem}>
                    <span className={styles.stack}>
                      <button type="button" className={`${styles.cellTitle} ${styles.mono}`} onClick={() => setInvoiceId(invoice.id)}>
                        {invoice.number}
                      </button>
                      <span className={styles.cellMeta}>Issued {formatDate(invoice.issuedAt)}</span>
                    </span>
                    <span className={styles.headerFacts}>
                      <PaymentStatusBadge status={invoice.status} />
                      {data.checkoutAvailable && canChange && (invoice.status === 'pending' || invoice.status === 'failed') && (
                        <Button size="sm" variant="primary" onClick={() => pay({ invoiceId: invoice.id })} loading={paying === invoice.id}>
                          Pay
                        </Button>
                      )}
                      <span className={`${styles.amount} ${styles.strong}`}>{money(invoiceTotal(invoice), invoice.currency)}</span>
                    </span>
                  </li>
                ))}
              </ul>
            )}
            {invoicePages > 1 && (
              <Pagination
                page={currentInvoicePage}
                pageCount={invoicePages}
                onChange={setInvoicePage}
                summary={rangeSummary(data.invoices.length, currentInvoicePage, INVOICES_PER_PAGE, 'invoices')}
              />
            )}
          </section>
        </div>

        <div className={styles.column}>
          <section className={styles.panel} aria-labelledby="billing-features">
            <SectionHeader id="billing-features" title="Included in the plan" />
            <ul className={styles.featureList}>
              {data.features.map((f) => (
                <li key={f.key} className={f.included ? styles.featureItem : `${styles.featureItem} ${styles.featureOff}`}>
                  {f.included ? <Check size={14} aria-hidden="true" /> : <Minus size={14} aria-hidden="true" />}
                  <span className={styles.stack}>
                    <span>
                      {f.label}{' '}
                      {f.enforcement === 'planned' && (
                        <Badge size="sm" tone="info">
                          Coming soon
                        </Badge>
                      )}
                    </span>
                    {f.enforcement === 'service' && f.included && <span className={styles.cellMeta}>Included service — provided by the platform team.</span>}
                  </span>
                  {!f.included && <span className="sr-only">(not included)</span>}
                </li>
              ))}
            </ul>
          </section>

          <section className={styles.panel} aria-labelledby="billing-details">
            <SectionHeader
              id="billing-details"
              title="Billing details"
              actions={
                canChange && details.status === 'success' ? (
                  <Button size="sm" onClick={() => setEditingDetails(true)}>
                    {details.data ? 'Edit' : 'Add'}
                  </Button>
                ) : undefined
              }
            />
            {details.status === 'error' ? (
              <p className={styles.muted}>The billing details didn’t load.</p>
            ) : !details.data ? (
              <p className={styles.muted}>
                {details.status === 'success' ? 'Not added yet. Invoices are addressed here, and a plan can be bought once they are set.' : 'Loading…'}
              </p>
            ) : (
              <div className={styles.stack}>
                <span className={styles.strong}>{details.data.legalName}</span>
                <span className={styles.cellMeta}>{details.data.email}</span>
                <span>
                  {details.data.addressLine1}
                  {details.data.addressLine2 ? `, ${details.data.addressLine2}` : ''}
                </span>
                <span>
                  {details.data.city}
                  {details.data.region ? `, ${details.data.region}` : ''} {details.data.postalCode} · {details.data.country}
                </span>
                {details.data.taxRegistration && <span className={styles.cellMeta}>Tax registration {details.data.taxRegistration}</span>}
              </div>
            )}
          </section>

          <section className={styles.panel} aria-labelledby="billing-payments">
            <SectionHeader id="billing-payments" title="Payments" count={data.payments.length} />
            {data.payments.length === 0 ? (
              <p className={styles.muted}>No payments yet.</p>
            ) : (
              <dl className={styles.facts}>
                {data.payments.map((p) => (
                  <Fact
                    key={p.id}
                    label={`${formatDate(p.at)}${p.invoiceNumber ? ` · ${p.invoiceNumber}` : ''}`}
                    value={
                      <span className={styles.stack}>
                        <span className={styles.headerFacts}>
                          <span className={styles.strong}>{money(p.amount, p.currency)}</span>
                          <Badge size="sm" tone={p.status === 'paid' ? 'accent' : p.status === 'failed' ? 'danger' : 'warn'}>
                            {p.status.replace('_', ' ')}
                          </Badge>
                        </span>
                        {p.method && <span className={styles.cellMeta}>{p.method}</span>}
                        {p.failureMessage && <span className={styles.cellMeta}>{p.failureMessage}</span>}
                      </span>
                    }
                  />
                ))}
              </dl>
            )}
            <p className={styles.muted}>Card details are never stored — only a brand and the last four digits.</p>
          </section>
        </div>
      </div>

      {s && pending && (
        <PlanChangeDialog
          subscription={s}
          choice={pending}
          onClose={() => setPending(null)}
          onNeedsAddress={changeNeedsAddress}
          onDone={async (result) => {
            setPending(null);
            setQuote(result);
            toast({
              kind: 'success',
              title: result.change.direction === 'upgrade' ? 'Upgrade quoted' : 'Plan change scheduled',
              text:
                result.change.direction === 'upgrade'
                  ? 'The new plan starts once the payment is confirmed.'
                  : `The LMS moves to ${result.change.toPlanName} on ${formatDate(result.change.effectiveAt!)}.`,
            });
            await reload();
          }}
        />
      )}
      {s && (
        <CancelSubscriptionDialog
          subscription={s}
          open={canceling}
          onClose={() => setCanceling(false)}
          onDone={async (immediately) => {
            setCanceling(false);
            toast({
              kind: 'success',
              title: immediately ? 'Subscription cancelled' : 'Cancellation scheduled',
              text: immediately ? 'It has ended. Choose a plan any time to continue.' : `Everything keeps working until ${formatDate(s.renewsAt)}.`,
            });
            await reload();
          }}
        />
      )}
      {purchase && (
        <ConfirmDialog
          open
          onClose={() => setPurchase(null)}
          onConfirm={() => {
            const choice = purchase;
            setPurchase(null);
            void buy(choice);
          }}
          icon={<CreditCard size={20} />}
          title={`Subscribe to ${purchase.plan.name}, ${cycleLabel(purchase.cycle).toLowerCase()}?`}
          description={`${money(priceFor(purchase.plan, purchase.cycle), purchase.plan.currency)} ${cyclePer(purchase.cycle)}, plus tax`}
          confirmLabel="Continue to payment"
        >
          The platform works out the amount, tax included, and opens a secure payment window. The subscription starts once the payment is confirmed; if the
          payment does not go through, nothing is charged and you can choose again.
        </ConfirmDialog>
      )}
      <BillingDetailsDialog
        open={editingDetails}
        initial={details.data ?? null}
        reason={
          waitingPlan
            ? `Add where invoices are addressed before subscribing to ${waitingPlan.plan.name}. Tax is worked out from the country and region.`
            : waitingChange
              ? `Add where invoices are addressed before upgrading to ${waitingChange.plan.name}. The upgrade is taxed by the country and region.`
              : undefined
        }
        onClose={() => {
          setEditingDetails(false);
          setWaitingPlan(null);
          setWaitingChange(null);
        }}
        onSave={async (next) => {
          await services.tenantBilling.saveBillingDetails(next);
          await details.run().catch(() => undefined);
          setEditingDetails(false);
          toast({ kind: 'success', title: 'Billing details saved' });
          // The plan chosen before the address was set goes straight on to its confirmation.
          if (waitingPlan) setPurchase(waitingPlan);
          // The change chosen before the address was set is priced again, now with its tax.
          if (waitingChange) setPending(waitingChange);
          setWaitingPlan(null);
          setWaitingChange(null);
        }}
      />
      <InvoiceDialog invoiceId={invoiceId} onClose={() => setInvoiceId(null)} load={(id) => services.tenantBilling.getInvoice(id)} platformLinks={false} />
    </div>
  );
}
