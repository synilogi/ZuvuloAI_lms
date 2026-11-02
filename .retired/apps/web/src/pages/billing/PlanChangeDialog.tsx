import { useEffect } from 'react';
import { ArrowsLeftRight } from '@phosphor-icons/react';
import type { BillingCycle, Plan, PlanChangeQuote, Subscription } from '@syniastrolms/domain';
import { LIMIT_LABEL } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { services } from '@/services';
import { cycleLabel, cyclePer, limitText, money, priceFor } from '@/pages/superadmin/subscriptions/subscriptionMeta';
import styles from '@/pages/superadmin/subscriptions/Subscriptions.module.css';

export interface PlanChoice {
  plan: Plan;
  cycle: BillingCycle;
}

/**
 * A move to another plan or cycle, priced before it is asked for. The server previews it (writing nothing):
 * an upgrade shows the credit for unused time, the charge, its tax and the total due now, and applies once
 * paid; a downgrade shows the date it applies, that nothing is charged, and any limit the academy already
 * uses past. An upgrade is taxed by the billing address, so without one the admin is sent to add it first.
 */
export function PlanChangeDialog({
  subscription,
  choice,
  onClose,
  onNeedsAddress,
  onDone,
}: {
  subscription: Subscription;
  choice: PlanChoice;
  onClose: () => void;
  /** The upgrade can't be priced without a billing address: the page opens that form, then comes back here. */
  onNeedsAddress: (choice: PlanChoice) => void;
  onDone: (quote: PlanChangeQuote) => void | Promise<void>;
}) {
  const preview = useAsync(`academy:preview:${choice.plan.id}:${choice.cycle}`, () =>
    services.tenantBilling.previewChange({ planId: choice.plan.id, cycle: choice.cycle }),
  );
  const p = preview.status === 'success' ? preview.data : null;

  useEffect(() => {
    if (p?.needsBillingAddress) onNeedsAddress(choice);
  }, [p, choice, onNeedsAddress]);

  const upgrade = p?.when === 'on_payment';
  const currency = p?.currency ?? subscription.currency;

  return (
    <ConfirmDialog
      open
      onClose={onClose}
      onConfirm={async () => {
        await onDone(await services.tenantBilling.requestChange({ planId: choice.plan.id, cycle: choice.cycle }));
      }}
      icon={<ArrowsLeftRight size={20} />}
      title={`Move to ${choice.plan.name}, ${cycleLabel(choice.cycle).toLowerCase()}?`}
      description={`${money(priceFor(choice.plan, choice.cycle), choice.plan.currency)} ${cyclePer(choice.cycle)}, before tax`}
      confirmLabel={upgrade ? 'Confirm upgrade' : 'Schedule the change'}
      blocked={!p || p.needsBillingAddress}
    >
      {preview.status === 'error' ? (
        <InlineMessage kind="error" title="This change can’t be made right now.">
          {preview.error.message}
        </InlineMessage>
      ) : !p ? (
        <div aria-busy="true" className={styles.dialogBody}>
          <span className={styles.muted}>Working out what this costs…</span>
          <Skeleton height={90} radius="var(--r-md)" />
        </div>
      ) : upgrade ? (
        <div className={styles.dialogBody}>
          <div className={styles.totals}>
            <div className={styles.totalRow}>
              <span>Credit for the unused part of this period</span>
              <span className={styles.amount}>−{money(p.credit, currency)}</span>
            </div>
            <div className={styles.totalRow}>
              <span>Charge for the rest of this period</span>
              <span className={styles.amount}>{money(p.charge, currency)}</span>
            </div>
            {p.payable && (
              <>
                <div className={styles.totalRow}>
                  <span>Tax</span>
                  <span className={styles.amount}>{money(p.payable.tax, currency)}</span>
                </div>
                <div className={`${styles.totalRow} ${styles.grandTotal}`}>
                  <span>Total due now</span>
                  <span className={styles.amount}>{money(p.payable.gross, currency)}</span>
                </div>
              </>
            )}
          </div>
          {p.forfeited > 0 && (
            <p className={styles.muted}>
              {money(p.forfeited, currency)} of credit is more than the new plan costs for the rest of the period, and is not carried over.
            </p>
          )}
          <p className={styles.muted}>
            The new plan applies once the payment is confirmed. The renewal date stays {formatDate(subscription.renewsAt)}, then {money(p.to.amount, currency)}{' '}
            {cyclePer(p.to.cycle)}.
          </p>
        </div>
      ) : (
        <div className={styles.dialogBody}>
          <p>
            Applies on <span className={styles.strong}>{formatDate(p.appliesAt)}</span>, when this period ends. Nothing is charged now and nothing is refunded;
            the LMS keeps its current plan until then, and pays {money(p.to.amount, currency)} {cyclePer(p.to.cycle)} after.
          </p>
          {p.conflicts.length > 0 && (
            <InlineMessage kind="warn" title="The LMS already uses more than the new plan allows">
              <ul>
                {p.conflicts.map((c) => (
                  <li key={c.limit}>
                    {LIMIT_LABEL[c.limit]}: using {limitText(c.limit, c.usage)}, the new plan allows {limitText(c.limit, c.newLimit)}.
                  </li>
                ))}
              </ul>
              Nothing is deleted. Adding more past these limits is refused once the change applies.
            </InlineMessage>
          )}
        </div>
      )}
    </ConfirmDialog>
  );
}
