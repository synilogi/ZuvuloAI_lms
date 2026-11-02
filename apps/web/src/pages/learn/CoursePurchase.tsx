import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShoppingCartSimple } from '@phosphor-icons/react';
import type { Course } from '@syniastrolms/domain';
import { planCheckout, CHECKOUT_UNAVAILABLE } from '@/lib/gatewayCheckout';
import { openRazorpayOrder } from '@/lib/razorpayCheckout';
import { ALL_INCLUSIVE } from '@/lib/coursePricing';
import { formatINR } from '@/lib/format';
import { formatMoney, type CourseQuote } from '@syniastrolms/domain';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import {
  CANCELLED_MESSAGE,
  POLL_EVERY_MS,
  POLL_FOR_MS,
  SLOW_MESSAGE,
  confirmationPhase,
  isBusy,
  refusalPhase,
  rememberCheckout,
  statusPhase,
  type CheckoutOutcome,
  type PurchasePhase,
} from './purchaseFlow';
import styles from './CoursePurchase.module.css';

interface CoursePurchaseProps {
  course: Course;
  /** The all-inclusive price in whole rupees, as the course carries it from the server. */
  amount: number;
  /** The learner has the course now (bought, or already theirs): the page reads it again. */
  onOwned: (message?: string) => void;
  /** Coming back from a hosted checkout: the purchase to ask the API about, and how the checkout ended. */
  resume?: { purchaseId: string; outcome: CheckoutOutcome };
  /** Shown beside the buy button (Save for later). */
  extra?: ReactNode;
}

/**
 * Buy course → order summary → the gateway's checkout → the server confirms → the course opens. The price shown is the
 * course's own, all-inclusive; the amount charged is whatever order the server opens. Nothing opens until the API
 * answers that the learner is enrolled.
 */
export function CoursePurchase({ course, amount, onOwned, resume, extra }: CoursePurchaseProps) {
  const toast = useToast();
  const navigate = useNavigate();
  const [phase, setPhase] = useState<PurchasePhase>({ kind: 'idle' });
  const inFlight = useRef(false);
  const ownedRef = useRef(onOwned);
  ownedRef.current = onOwned;
  const price = formatINR(amount);
  const [couponText, setCouponText] = useState('');
  const [quote, setQuote] = useState<CourseQuote | null>(null);
  const [couponError, setCouponError] = useState<string>();
  const [applying, setApplying] = useState(false);

  // The server prices the coupon: this page only shows its answer, and the order is priced again when it is made.
  const applyCoupon = async () => {
    const code = couponText.trim();
    setCouponError(undefined);
    setQuote(null);
    if (!code) return;
    setApplying(true);
    try {
      setQuote(await services.learning.quotePurchase(course.id, code));
    } catch (err) {
      setCouponError(err instanceof Error ? err.message : 'That coupon could not be checked.');
    } finally {
      setApplying(false);
    }
  };

  const succeed = useCallback(
    (message: string) => {
      setPhase({ kind: 'success', message });
      toast({ kind: 'success', title: `You’re enrolled in ${course.title}`, text: message });
      ownedRef.current(message);
    },
    [course.title, toast],
  );

  const apply = useCallback(
    (next: PurchasePhase | { kind: 'owned' }) => {
      if (next.kind === 'owned') {
        setPhase({ kind: 'idle' });
        ownedRef.current();
      } else if (next.kind === 'success') succeed(next.message);
      else setPhase(next);
    },
    [succeed],
  );

  // Back from a hosted checkout: ask the API, never the address bar, whether the course is open.
  const resumeKey = resume ? `${resume.purchaseId}:${resume.outcome}` : '';
  useEffect(() => {
    if (!resume) return;
    let live = true;
    if (resume.outcome === 'cancelled') setPhase({ kind: 'cancelled' });
    else setPhase({ kind: 'verifying', purchaseId: resume.purchaseId });
    services.learning.getPurchase(resume.purchaseId).then(
      (purchase) => {
        if (!live) return;
        // Cancelled: only an open course changes that (an earlier attempt's failure is not this one's).
        if (resume.outcome === 'cancelled') return purchase.enrolled ? apply(statusPhase(purchase)!) : setPhase({ kind: 'cancelled' });
        const settled = statusPhase(purchase, resume.outcome === 'failed');
        if (settled) apply(settled);
        else setPhase({ kind: 'verifying', purchaseId: purchase.id });
      },
      (err) => live && apply(refusalPhase(err)),
    );
    return () => {
      live = false;
    };
    // `resume` is read through its key: the same return is asked about once.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resumeKey, apply]);

  // Confirming: ask again every few seconds, then stop and say the course opens once the payment is confirmed.
  const verifyingId = phase.kind === 'verifying' ? phase.purchaseId : null;
  useEffect(() => {
    if (!verifyingId) return;
    let live = true;
    const started = Date.now();
    let timer: number | undefined;
    const tick = async () => {
      if (!live) return;
      if (Date.now() - started >= POLL_FOR_MS) {
        setPhase({ kind: 'slow', purchaseId: verifyingId });
        return;
      }
      try {
        const settled = statusPhase(await services.learning.getPurchase(verifyingId));
        if (!live) return;
        if (settled) {
          apply(settled);
          return;
        }
      } catch {
        // A failed check is asked again on the next tick; the purchase is unchanged by it.
      }
      if (live) timer = window.setTimeout(tick, POLL_EVERY_MS);
    };
    timer = window.setTimeout(tick, POLL_EVERY_MS);
    return () => {
      live = false;
      window.clearTimeout(timer);
    };
  }, [verifyingId, apply]);

  const buy = async () => {
    if (inFlight.current) return;
    inFlight.current = true;
    setPhase({ kind: 'starting' });
    try {
      const start = await services.learning.startPurchase(course.id, quote?.couponCode);
      const plan = planCheckout(start.checkout);
      if (plan.kind === 'unavailable') {
        setPhase({ kind: 'failed', message: CHECKOUT_UNAVAILABLE });
        return;
      }
      if (plan.kind === 'redirect') {
        // The hosted page sends the learner back here; this tab remembers which purchase to ask about.
        rememberCheckout(start.checkout.orderId, { purchaseId: start.purchase.id, courseId: course.id });
        // A page of this app (the sandbox's test checkout) opens in place, keeping the demo build's state; any other
        // gateway's page is a real departure.
        const target = new URL(plan.url);
        if (target.origin === window.location.origin) navigate(`${target.pathname}${target.search}`);
        else window.location.assign(plan.url);
        return;
      }
      setPhase({ kind: 'checkout' });
      const completion = await openRazorpayOrder({
        keyId: plan.keyId,
        orderId: start.checkout.orderId,
        amount: start.checkout.amount,
        currency: start.checkout.currency,
        name: start.checkout.description,
        description: ALL_INCLUSIVE,
        prefill: start.checkout.prefill,
        notes: { purchaseId: start.purchase.id },
      });
      if (!completion) {
        setPhase({ kind: 'cancelled' });
        return;
      }
      setPhase({ kind: 'verifying', purchaseId: start.purchase.id });
      apply(confirmationPhase(await services.learning.confirmPurchase(start.purchase.id, completion)));
    } catch (err) {
      apply(refusalPhase(err));
    } finally {
      inFlight.current = false;
    }
  };

  const checkAgain = (purchaseId: string) => setPhase({ kind: 'verifying', purchaseId });

  const busy = isBusy(phase);
  const blocked = phase.kind === 'blocked';

  return (
    <div className={styles.purchase}>
      <div className={styles.row}>
        <Button
          size="lg"
          variant="primary"
          iconStart={<ShoppingCartSimple size={16} />}
          loading={busy}
          disabled={busy || blocked || phase.kind === 'slow' || phase.kind === 'success'}
          onClick={() => setPhase({ kind: 'summary' })}
        >
          Buy course · {price}
        </Button>
        {extra}
      </div>
      <p className={styles.note}>{ALL_INCLUSIVE} · pay once, online</p>

      {phase.kind === 'starting' && (
        <p className={styles.status} role="status">
          Opening the payment…
        </p>
      )}
      {phase.kind === 'checkout' && (
        <p className={styles.status} role="status">
          Complete the payment in the payment window.
        </p>
      )}
      {phase.kind === 'verifying' && (
        <InlineMessage kind="info" title="Confirming your payment…">
          The course opens as soon as the payment is confirmed. Please keep this page open.
        </InlineMessage>
      )}
      {phase.kind === 'slow' && (
        <InlineMessage
          kind="info"
          title="Your payment is still being confirmed."
          action={
            <Button size="sm" onClick={() => checkAgain(phase.purchaseId)}>
              Check again
            </Button>
          }
        >
          {SLOW_MESSAGE}
        </InlineMessage>
      )}
      {phase.kind === 'failed' && (
        <InlineMessage
          kind="error"
          title="The payment didn’t go through."
          action={
            <Button size="sm" onClick={() => void buy()}>
              Try again
            </Button>
          }
        >
          {phase.message}
        </InlineMessage>
      )}
      {phase.kind === 'cancelled' && (
        <InlineMessage
          kind="warn"
          title={CANCELLED_MESSAGE}
          action={
            <Button size="sm" onClick={() => void buy()}>
              Try again
            </Button>
          }
        />
      )}
      {phase.kind === 'blocked' && (
        <InlineMessage kind="warn" title={phase.title}>
          {phase.message}
        </InlineMessage>
      )}

      <Modal
        open={phase.kind === 'summary'}
        onClose={() => setPhase({ kind: 'idle' })}
        icon={<ShoppingCartSimple size={20} />}
        title="Order summary"
        description="You’ll pay securely in the next step. The course opens as soon as the payment is confirmed."
        footer={
          <>
            <Button onClick={() => setPhase({ kind: 'idle' })}>Cancel</Button>
            <Button variant="primary" onClick={() => void buy()} data-autofocus>
              Continue to payment
            </Button>
          </>
        }
      >
        <dl className={styles.summary}>
          <div>
            <dt>Course</dt>
            <dd>{course.title}</dd>
          </div>
          <div>
            <dt>Price</dt>
            <dd>{price}</dd>
          </div>
          {quote && quote.discount > 0 && (
            <div>
              <dt>Coupon {quote.couponCode}</dt>
              <dd>− {formatMoney(quote.discount, 'INR')}</dd>
            </div>
          )}
          <div className={styles.total}>
            <dt>You pay</dt>
            <dd>{quote ? formatMoney(quote.total, 'INR') : price}</dd>
          </div>
        </dl>
        <div className={styles.row}>
          <Field label="Coupon code" optional error={couponError}>
            <Input
              id="purchase-coupon"
              value={couponText}
              onChange={(e) => {
                setCouponText(e.target.value);
                setQuote(null);
                setCouponError(undefined);
              }}
              autoCapitalize="characters"
              autoComplete="off"
            />
          </Field>
          <Button loading={applying} disabled={!couponText.trim()} onClick={() => void applyCoupon()}>
            Apply
          </Button>
        </div>
        <p className={styles.fine}>{ALL_INCLUSIVE} — nothing is added at checkout.</p>
      </Modal>
    </div>
  );
}
