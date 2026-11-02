import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { CreditCard, Flask } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { Button } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { money } from '@/pages/superadmin/subscriptions/subscriptionMeta';
import { services } from '@/services';
import { courseReturnPath, recallCheckout, type CheckoutOutcome, type CheckoutReturn } from '@/pages/learn/purchaseFlow';
import styles from './SandboxCheckout.module.css';

/** The learner's purchases page — where a course order comes back to when this tab did not open it. */
export const PURCHASES = '/purchases';

/** Course orders carry their purchase as the receipt (`cp_…` on the API, `mock-purchase-…` in the demo). */
export const isCourseReceipt = (receipt: string | undefined) => Boolean(receipt && (receipt.startsWith('cp_') || receipt.startsWith('mock-purchase-')));

/**
 * Where the payer goes back to, with how the checkout ended: the course page that opened the order, which asks the
 * API whether the course is open, or the learner's purchases when this tab did not open it.
 */
export function returnPath(
  orderId: string,
  receipt: string | undefined,
  outcome: CheckoutOutcome,
  recall: (orderId: string) => CheckoutReturn | null = recallCheckout,
) {
  const course = recall(orderId);
  if (course) return courseReturnPath(course, outcome);
  void isCourseReceipt(receipt);
  return PURCHASES;
}

/*
 * The sandbox gateway's hosted test checkout (SAAS-030) — development and E2E only; the API answers not found
 * everywhere else. It plays a gateway's payment page: pay, decline or cancel. The platform hears the outcome from the
 * gateway's signed webhook, never from this page, which only sends the payer back to the course page, which asks the
 * API whether the payment opened the course.
 */
export default function SandboxCheckoutPage() {
  const { orderId = '' } = useParams();
  const navigate = useNavigate();
  const order = useAsync(`sandbox:${orderId}`, () => services.sandbox.order(orderId));
  const [busy, setBusy] = useState<'success' | 'failure' | null>(null);
  const [error, setError] = useState<string>();

  const pay = async (outcome: 'success' | 'failure') => {
    setBusy(outcome);
    setError(undefined);
    try {
      const result = await services.sandbox.pay(orderId, outcome);
      navigate(returnPath(orderId, order.data?.receipt, result.status === 'paid' ? 'paid' : 'failed'), { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'The test payment did not go through.');
      setBusy(null);
    }
  };

  return (
    <div className={styles.shell}>
      <div className={styles.card}>
        <p className={styles.badge}>
          <Flask size={14} aria-hidden="true" /> Sandbox gateway — no real money moves
        </p>
        {order.status === 'error' && !order.data ? (
          <StateMessage kind="error" title="This checkout isn’t available" actions={<Button onClick={() => navigate(-1)}>Go back</Button>}>
            {order.error?.message ?? 'The sandbox gateway is switched off, or the order does not exist.'}
          </StateMessage>
        ) : !order.data ? (
          <div role="status" aria-label="Loading the checkout">
            <Skeleton width="60%" height={28} />
            <Skeleton height={80} />
          </div>
        ) : (
          <>
            <h1 className={styles.title}>Pay {money(order.data.amount, order.data.currency)}</h1>
            <p className={styles.muted}>Order {order.data.orderId}</p>
            {order.data.status === 'paid' && (
              <InlineMessage kind="info" title="Already paid.">
                This order has been paid.
              </InlineMessage>
            )}
            {error && (
              <InlineMessage kind="error" title="That didn’t work.">
                {error}
              </InlineMessage>
            )}
            <div className={styles.method}>
              <CreditCard size={20} aria-hidden="true" /> Test card ending 4242
            </div>
            <div className={styles.actions}>
              <Button
                variant="primary"
                size="lg"
                block
                loading={busy === 'success'}
                disabled={busy !== null || order.data.status === 'paid'}
                onClick={() => pay('success')}
              >
                Pay successfully
              </Button>
              <Button size="lg" block loading={busy === 'failure'} disabled={busy !== null || order.data.status === 'paid'} onClick={() => pay('failure')}>
                Decline the payment
              </Button>
              <Button
                variant="ghost"
                block
                disabled={busy !== null}
                onClick={() => navigate(returnPath(orderId, order.data?.receipt, 'cancelled'), { replace: true })}
              >
                Cancel and go back
              </Button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
