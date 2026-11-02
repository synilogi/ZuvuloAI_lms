import type { ReactNode } from 'react';
import { CheckCircle, LockSimple } from '@phosphor-icons/react';
import type { BillingCycle, LimitKey, Plan } from '@syniastrolms/domain';
import { FEATURES, LIMIT_LABEL, limitOf } from '@syniastrolms/domain';
import { Badge } from '@/components/ui/Badge/Badge';
import { cyclePer, limitText, money, priceFor } from '@/pages/superadmin/subscriptions/subscriptionMeta';
import styles from './PlanOffer.module.css';

/** The limits a plan card lists — the ones an academy plans around. */
const CARD_LIMITS: LimitKey[] = ['learners.max', 'courses.max', 'instructors.max', 'live_classes.max', 'storage.bytes'];
/** What a plan card lists as included: everything sold today. Features not built yet are left off. */
const CARD_FEATURES = FEATURES.filter((f) => f.enforcement !== 'planned');

/**
 * A plan as it is offered: its price on the cycle, trial, limits and features, with the actions the page gives it.
 * Every figure is the server's (`Plan` from the API); the card only formats them. Rendered as a list item.
 */
export function PlanOfferCard({
  plan,
  cycle,
  actions,
  highlighted = false,
  ribbon,
  taxNote = 'plus tax',
}: {
  plan: Plan;
  cycle: BillingCycle;
  actions?: ReactNode;
  /** The plan the visitor already chose (from the pricing page, say). */
  highlighted?: boolean;
  /** A short label above the name, e.g. "Your choice". */
  ribbon?: string;
  /** What follows the cycle under the price. */
  taxNote?: string;
}) {
  const sold = plan.cycles.includes(cycle);
  const nameId = `plan-${plan.id}`;
  return (
    <li className={highlighted ? `${styles.card} ${styles.highlighted}` : styles.card} aria-labelledby={nameId} data-plan-code={plan.code}>
      {ribbon && (
        <Badge size="sm" tone="accent" className={styles.ribbon}>
          {ribbon}
        </Badge>
      )}
      <div className={styles.cardHead}>
        <h3 className={styles.cardName} id={nameId}>
          {plan.name}
          {plan.trialEnabled && plan.trialDays > 0 && (
            <Badge size="sm" tone="info">
              {plan.trialDays}-day free trial
            </Badge>
          )}
        </h3>
        <p className={styles.cardDescription}>{plan.description}</p>
      </div>
      <p className={styles.price}>
        {sold ? (
          <>
            <span className={styles.priceValue}>{money(priceFor(plan, cycle), plan.currency)}</span>
            <span className={styles.priceCycle}>
              {cyclePer(cycle)}
              {taxNote ? `, ${taxNote}` : ''}
            </span>
          </>
        ) : (
          <span className={styles.priceCycle}>Not sold {cycle === 'annual' ? 'annually' : 'monthly'}</span>
        )}
      </p>

      <div>
        <p className={styles.listTitle}>Limits</p>
        <ul className={styles.limits}>
          {CARD_LIMITS.map((key) => (
            <li key={key} className={styles.limit}>
              <span>{LIMIT_LABEL[key]}</span>
              <span className={styles.limitValue}>{limitText(key, limitOf(plan.limits, key))}</span>
            </li>
          ))}
        </ul>
      </div>

      <div>
        <p className={styles.listTitle}>Includes</p>
        <ul className={styles.features}>
          {CARD_FEATURES.map((f) => {
            const included = plan.features.includes(f.key);
            return (
              <li key={f.key} className={included ? styles.feature : `${styles.feature} ${styles.featureOff}`}>
                {included ? <CheckCircle size={14} weight="fill" aria-hidden="true" /> : <LockSimple size={14} aria-hidden="true" />}
                <span>
                  {f.label}
                  <span className="sr-only">{included ? ' (included)' : ' (not included)'}</span>
                </span>
              </li>
            );
          })}
        </ul>
      </div>

      {actions && <div className={styles.cardActions}>{actions}</div>}
    </li>
  );
}

/** A small note under a card's actions. */
export const PlanOfferNote = ({ children }: { children: ReactNode }) => <span className={styles.cardNote}>{children}</span>;
