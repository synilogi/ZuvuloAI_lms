import { useEffect, useState } from 'react';
import { ArrowRight, ArrowsLeftRight, ArrowUUpLeft, Gift, PauseCircle, PlayCircle, Prohibit, ArrowCounterClockwise } from '@phosphor-icons/react';
import type { BillingCycle, Plan, RefundResult, Subscription, SubscriptionPayment } from '@syniastrolms/domain';
import { MAX_EXTENSION_DAYS, MAX_PAUSE_DAYS, currencyDigits, minorToMajor, parseMajorAmount, planChangeEffect } from '@syniastrolms/domain';
import { useNow } from '@/hooks/useNow';
import { formatDate, plural } from '@/lib/format';
import { ChoiceCards } from '@/components/forms/Forms';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { services } from '@/services';
import { cycleLabel, cyclePer, money } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/*
 * The things a platform admin can do to a subscription. Each one is a decision with a
 * consequence, so each one is a confirmation that states the consequence before the button.
 *
 * The server applies the platform's rules to each: an upgrade is prorated and applies once paid (D7,
 * D8), a downgrade waits for the period end (D10), a pause runs 1–30 days and moves the renewal date by
 * the time actually paused (D9). The dialogs say so; they never offer a choice the rules do not allow.
 */

type Effective = 'immediately' | 'period-end';

/**
 * Whether a change is charged now (D7, D8) — a dearer plan on the same cycle, or monthly to annual — the
 * same classification the server makes. Only the wording depends on it: the server decides.
 */
const moveUp = (subscription: Subscription, cycle: BillingCycle, newAmount: number) =>
  subscription.cycle !== cycle ? subscription.cycle === 'monthly' && cycle === 'annual' : newAmount > subscription.amount;

interface ActionProps {
  subscription: Subscription;
  open: boolean;
  onClose: () => void;
  /** Resolves when the change is stored; the page reloads its own data afterwards. */
  onDone: () => void | Promise<void>;
}

/* ─── Change plan ───────────────────────────────────────────────────────── */

export function ChangePlanDialog({ subscription, plans, open, onClose, onDone }: ActionProps & { plans: Plan[] }) {
  // Archived plans can't be moved on to, and neither can a draft nobody can buy.
  const choosable = plans.filter((p) => p.status === 'active' || p.id === subscription.planId);
  const [planId, setPlanId] = useState(subscription.planId);
  const [cycle, setCycle] = useState<BillingCycle>(subscription.cycle);

  useEffect(() => {
    if (open) {
      setPlanId(subscription.planId);
      setCycle(subscription.cycle);
    }
  }, [open, subscription.planId, subscription.cycle]);

  const target = choosable.find((p) => p.id === planId);
  const current = plans.find((p) => p.id === subscription.planId);
  // A plan that isn't sold on the chosen cycle can't keep it; fall back to one it does offer.
  const cycles: BillingCycle[] = target?.cycles ?? ['monthly', 'annual'];
  const chosenCycle: BillingCycle = cycles.includes(cycle) ? cycle : cycles[0];
  const effect = target ? planChangeEffect(subscription.amount, target, chosenCycle) : null;
  const unchanged = planId === subscription.planId && chosenCycle === subscription.cycle;

  return (
    <ConfirmDialog
      open={open}
      onClose={onClose}
      onConfirm={async () => {
        await services.subscriptions.changePlan(subscription.id, { planId, cycle: chosenCycle });
        await onDone();
      }}
      icon={<ArrowsLeftRight size={20} />}
      title="Change plan"
      description={subscription.customer.name}
      confirmLabel="Change plan"
      blocked={unchanged}
    >
      <div className={styles.dialogBody}>
        <div className={styles.compare}>
          <span className={styles.compareSide}>
            <span className={styles.compareLabel}>Now</span>
            <span className={styles.compareName}>{current?.name ?? 'Unknown plan'}</span>
            <span className={styles.muted}>
              {money(subscription.amount, subscription.currency)} {cyclePer(subscription.cycle)}
            </span>
          </span>
          <ArrowRight size={18} className={styles.compareArrow} aria-hidden="true" />
          <span className={styles.compareSide}>
            <span className={styles.compareLabel}>After the change</span>
            <span className={styles.compareName}>{target?.name ?? '—'}</span>
            <span className={styles.muted}>{effect ? `${money(effect.newAmount, subscription.currency)} ${cyclePer(chosenCycle)}` : '—'}</span>
          </span>
        </div>

        <Field label="New plan">
          <Select value={planId} onChange={(e) => setPlanId(e.target.value)}>
            {choosable.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
                {p.id === subscription.planId ? ' (current)' : ''}
              </option>
            ))}
          </Select>
        </Field>

        <Field label="Billing cycle">
          <Select value={chosenCycle} onChange={(e) => setCycle(e.target.value as BillingCycle)}>
            {cycles.map((c) => (
              <option key={c} value={c}>
                {cycleLabel(c)} — {target ? money(c === 'annual' ? target.annualPrice : target.monthlyPrice, subscription.currency) : '—'}
              </option>
            ))}
          </Select>
        </Field>

        {effect && !unchanged && (
          <p className={styles.difference}>
            <span>Price difference</span>
            <span className={effect.direction === 'upgrade' ? styles.up : effect.direction === 'downgrade' ? styles.down : undefined}>
              {effect.direction === 'same'
                ? 'No change'
                : `${effect.difference > 0 ? '+' : '−'}${money(Math.abs(effect.difference), subscription.currency)} ${cyclePer(chosenCycle)}`}
            </span>
          </p>
        )}
        {unchanged && <InlineMessage kind="info">This is the plan and cycle the subscription is already on. Choose a different one to continue.</InlineMessage>}
        {effect && !unchanged && (
          <p className={styles.muted}>
            {moveUp(subscription, chosenCycle, effect.newAmount)
              ? `An upgrade: the Admin pays the difference for the rest of this period, and the new plan starts once that payment is confirmed. The renewal date stays ${formatDate(subscription.renewsAt)}.`
              : `Takes effect at the end of the period, ${formatDate(subscription.renewsAt)}. Nothing is refunded; the Admin keeps what it has until then.`}
          </p>
        )}
      </div>
    </ConfirmDialog>
  );
}

/* ─── Cancel ────────────────────────────────────────────────────────────── */

const REASONS = [
  'Moved the programme back to in-person teaching.',
  'Cohort finished and no new intake is planned.',
  'Cost — the Admin is between funding rounds.',
  'Moving to another platform.',
  'Non-payment after the grace period.',
];

export function CancelDialog({ subscription, open, onClose, onDone }: ActionProps) {
  const [reason, setReason] = useState('');
  const [effective, setEffective] = useState<Effective>('period-end');

  useEffect(() => {
    if (open) {
      setReason('');
      setEffective('period-end');
    }
  }, [open]);

  return (
    <ConfirmDialog
      open={open}
      onClose={onClose}
      onConfirm={async () => {
        await services.subscriptions.cancel(subscription.id, { reason: reason.trim(), effective });
        await onDone();
      }}
      tone="danger"
      icon={<Prohibit size={20} />}
      title={`Cancel ${subscription.customer.name}?`}
      description={`Subscription ${subscription.id}`}
      confirmLabel="Cancel subscription"
      blocked={reason.trim().length < 5}
    >
      <div className={styles.dialogBody}>
        <Field label="Reason" hint="Kept on the subscription's history so the record explains itself later.">
          <Textarea rows={2} value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Why is this subscription ending?" />
        </Field>
        <Field label="Or pick one" hideLabel>
          <Select value="" onChange={(e) => e.target.value && setReason(e.target.value)} aria-label="Common reasons">
            <option value="">Pick a common reason…</option>
            {REASONS.map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </Select>
        </Field>
        <ChoiceCards<Effective>
          legend="When it takes effect"
          value={effective}
          onChange={setEffective}
          columns={1}
          choices={[
            {
              value: 'period-end',
              label: `At the end of the billing period — ${formatDate(subscription.renewsAt)}`,
              description: 'The Admin keeps its access until then. Nothing is charged after that.',
            },
            { value: 'immediately', label: 'Immediately', description: 'The subscription closes today. Nothing is refunded for the rest of the period.' },
          ]}
        />
      </div>
    </ConfirmDialog>
  );
}

/* ─── Pause ─────────────────────────────────────────────────────────────── */

/** A pause runs 1–30 days (D9). */
const PAUSE_OPTIONS = [7, 14, 21, MAX_PAUSE_DAYS];

export function PauseDialog({ subscription, open, onClose, onDone }: ActionProps) {
  const now = useNow();
  const [days, setDays] = useState(30);
  useEffect(() => {
    if (open) setDays(30);
  }, [open]);

  const resumeDate = new Date(now.getTime() + days * 86_400_000).toISOString();

  return (
    <ConfirmDialog
      open={open}
      onClose={onClose}
      onConfirm={async () => {
        await services.subscriptions.pause(subscription.id, days);
        await onDone();
      }}
      icon={<PauseCircle size={20} />}
      title={`Pause ${subscription.customer.name}?`}
      description={`Subscription ${subscription.id}`}
      confirmLabel="Pause subscription"
    >
      <div className={styles.dialogBody}>
        <Field label="Pause for" hint="Up to 30 days. The renewal date moves out by the time actually paused.">
          <Select value={String(days)} onChange={(e) => setDays(Number(e.target.value))}>
            {PAUSE_OPTIONS.map((d) => (
              <option key={d} value={d}>
                {plural(d, 'day')}
              </option>
            ))}
          </Select>
        </Field>
        <p className={styles.muted}>
          Resumes on {formatDate(resumeDate)}. The Admin keeps its content and its learners while it is paused, and cannot add to them until it resumes.
        </p>
      </div>
    </ConfirmDialog>
  );
}

/* ─── Resume and reactivate ─────────────────────────────────────────────── */

export function ResumeDialog({ subscription, open, onClose, onDone }: ActionProps) {
  return (
    <ConfirmDialog
      open={open}
      onClose={onClose}
      onConfirm={async () => {
        await services.subscriptions.resume(subscription.id);
        await onDone();
      }}
      icon={<PlayCircle size={20} />}
      title={`Resume ${subscription.customer.name}?`}
      description={subscription.resumesAt ? `Paused until ${formatDate(subscription.resumesAt)}` : undefined}
      confirmLabel="Resume subscription"
    >
      The subscription is active again today. Its renewal date moves out by the time it was actually paused.
    </ConfirmDialog>
  );
}

export function ReactivateDialog({ subscription, open, onClose, onDone }: ActionProps) {
  return (
    <ConfirmDialog
      open={open}
      onClose={onClose}
      onConfirm={async () => {
        await services.subscriptions.reactivate(subscription.id);
        await onDone();
      }}
      icon={<ArrowCounterClockwise size={20} />}
      title={`Reactivate ${subscription.customer.name}?`}
      description={subscription.cancelReason}
      confirmLabel="Reactivate subscription"
    >
      {subscription.status === 'canceling'
        ? 'The cancellation is withdrawn. The subscription stays on its plan and renews as before.'
        : 'A new subscription starts today on the same plan and cycle, at the plan’s current price. The closed one stays in the history.'}
    </ConfirmDialog>
  );
}

/* ─── Complimentary days ────────────────────────────────────────────────── */

/**
 * Days given at no charge: the current period ends later and the next charge moves with it. Only an active
 * subscription can be extended — the server refuses any other state.
 */
export function ExtendDialog({ subscription, open, onClose, onDone }: ActionProps) {
  const [days, setDays] = useState('14');
  const [reason, setReason] = useState('');
  useEffect(() => {
    if (open) {
      setDays('14');
      setReason('');
    }
  }, [open]);

  const n = Number(days);
  const valid = Number.isInteger(n) && n >= 1 && n <= MAX_EXTENSION_DAYS;
  const newEnd = valid ? new Date(new Date(subscription.renewsAt).getTime() + n * 86_400_000).toISOString() : null;

  return (
    <ConfirmDialog
      open={open}
      onClose={onClose}
      onConfirm={async () => {
        await services.subscriptions.extend(subscription.id, { days: n, reason: reason.trim() });
        await onDone();
      }}
      icon={<Gift size={20} />}
      title={`Add complimentary days to ${subscription.customer.name}?`}
      description={`Period ends ${formatDate(subscription.renewsAt)}`}
      confirmLabel="Add days"
      blocked={!valid || reason.trim().length < 3}
    >
      <div className={styles.dialogBody}>
        <Field
          label="Days"
          hint={`Between 1 and ${MAX_EXTENSION_DAYS}.`}
          error={days && !valid ? `Give a whole number of days from 1 to ${MAX_EXTENSION_DAYS}.` : undefined}
        >
          <Input type="number" min={1} max={MAX_EXTENSION_DAYS} inputMode="numeric" value={days} onChange={(e) => setDays(e.target.value)} />
        </Field>
        <Field label="Reason" hint="Kept on the subscription’s history. At least 3 characters.">
          <Textarea rows={2} value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Why are these days given?" />
        </Field>
        <p className={styles.muted}>
          {newEnd
            ? `The period then ends ${formatDate(newEnd)}, and the next charge moves with it. Nothing is charged for the extra days.`
            : 'The period ends later by the days given, and the next charge moves with it.'}
        </p>
      </div>
    </ConfirmDialog>
  );
}

/* ─── Refund ────────────────────────────────────────────────────────────── */

type RefundScope = 'full' | 'partial';

/**
 * Returns some or all of a payment, never more than is still refundable. The amount is typed in rupees and
 * sent in paise; a full refund names no amount, so the server refunds exactly what remains.
 */
export function RefundDialog({
  payment,
  customer,
  onClose,
  onDone,
}: {
  payment: SubscriptionPayment | null;
  customer: string;
  onClose: () => void;
  onDone: (refund: RefundResult) => void | Promise<void>;
}) {
  const [scope, setScope] = useState<RefundScope>('full');
  const [amount, setAmount] = useState('');
  const [reason, setReason] = useState('');
  useEffect(() => {
    if (payment) {
      setScope('full');
      setAmount('');
      setReason('');
    }
  }, [payment]);

  const currency = payment?.currency ?? 'INR';
  const refundable = payment?.refundable ?? 0;
  const minor = scope === 'partial' ? parseMajorAmount(amount, currency) : refundable;
  const amountError =
    scope === 'partial' && amount !== ''
      ? minor === null || minor < 1
        ? `Enter an amount above zero, to at most ${currencyDigits(currency)} decimal places.`
        : minor > refundable
          ? `At most ${money(refundable, currency)} can be refunded.`
          : undefined
      : undefined;
  const valid = minor !== null && minor >= 1 && minor <= refundable;

  return (
    <ConfirmDialog
      open={Boolean(payment)}
      onClose={onClose}
      onConfirm={async () => {
        if (!payment) return;
        const refund = await services.subscriptions.refundPayment(payment.id, {
          ...(scope === 'partial' ? { amount: minor! } : {}),
          reason: reason.trim(),
        });
        await onDone(refund);
      }}
      tone="danger"
      icon={<ArrowUUpLeft size={20} />}
      title={`Refund ${customer}?`}
      description={payment ? `${money(payment.amount, currency)} paid ${formatDate(payment.at)}${payment.method ? ` · ${payment.method}` : ''}` : undefined}
      confirmLabel={valid ? `Refund ${money(minor!, currency)}` : 'Refund'}
      blocked={!valid || reason.trim().length < 3}
    >
      <div className={styles.dialogBody}>
        <ChoiceCards<RefundScope>
          legend="How much"
          value={scope}
          onChange={setScope}
          columns={1}
          choices={[
            {
              value: 'full',
              label: `Everything still refundable — ${money(refundable, currency)}`,
              description: 'The rest of this payment goes back to the Admin.',
            },
            { value: 'partial', label: 'Part of it', description: 'An amount you name, up to what is still refundable.' },
          ]}
        />
        {scope === 'partial' && (
          <Field label={`Amount (${currency})`} hint={`Up to ${minorToMajor(refundable, currency).toLocaleString('en-IN')}.`} error={amountError}>
            <Input
              type="number"
              min={0}
              step={currencyDigits(currency) === 0 ? 1 : 1 / 10 ** currencyDigits(currency)}
              inputMode="decimal"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              autoFocus
            />
          </Field>
        )}
        <Field label="Reason" hint="Kept with the refund. At least 3 characters.">
          <Textarea rows={2} value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Why is this being refunded?" />
        </Field>
        <InlineMessage kind="warn">Refunding does not cancel the subscription — cancel it separately if needed.</InlineMessage>
        {payment && payment.provider !== 'offline' && (
          <p className={styles.muted}>The refund is asked of the payment provider; it may show as pending until the provider confirms it.</p>
        )}
      </div>
    </ConfirmDialog>
  );
}
