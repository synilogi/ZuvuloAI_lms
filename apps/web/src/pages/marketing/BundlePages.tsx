import { useEffect, useMemo, useState } from 'react';
import { Link, useLocation, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { ArrowRight, Clock, ShoppingCartSimple, Stack } from '@phosphor-icons/react';
import type { BundlePurchaseView, PublicBundle } from '@syniastrolms/domain';
import { metaDescription, setPageMeta } from '@/app/pageMeta';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { useAsync } from '@/hooks/useAsync';
import { useJsonLd } from '@/hooks/useJsonLd';
import { ALL_INCLUSIVE } from '@/lib/coursePricing';
import { formatDuration, formatINR, plural } from '@/lib/format';
import { CHECKOUT_UNAVAILABLE, planCheckout } from '@/lib/gatewayCheckout';
import { openRazorpayOrder } from '@/lib/razorpayCheckout';
import {
  CANCELLED_MESSAGE,
  POLL_EVERY_MS,
  POLL_FOR_MS,
  SLOW_MESSAGE,
  readCheckoutReturn,
  refusalPhase,
  rememberCheckout,
  type PurchasePhase,
} from '@/pages/learn/purchaseFlow';
import { API_MODE, useSession } from '@/providers/SessionProvider';
import { services } from '@/services';
import { BundleCard, BundleCover, BundlePrice } from './BundleCard';
import { MarketingChrome } from './MarketingChrome';
import { CtaBanner, PageHero } from './SiteParts';
import styles from './Home.module.css';
import marketing from './Marketing.module.css';

/*
 * Course bundles (docs/17): the listing, one bundle's page and buying it. As with a single course, the browser never prices anything
 * and never believes a checkout on its own: the courses open only when the API answers that the learner has them.
 */

/** `/bundles`. */
export function BundlesPage() {
  const query = useAsync('site:bundles', () => services.site.bundles());
  return (
    <MarketingChrome>
      <PageHero eyebrow="Course bundles" title="Course bundles">
        Several courses sold together at one price. Every course opens in My learning as soon as your payment is confirmed.
      </PageHero>
      <section className={marketing.section} aria-label="Bundles">
        {query.status === 'error' && !query.data ? (
          <StateMessage
            kind="error"
            title="The bundles didn’t load"
            actions={
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            }
          >
            {query.error.message}
          </StateMessage>
        ) : !query.data ? (
          <div className={styles.bundleGrid} aria-busy="true">
            {[0, 1, 2].map((i) => (
              <Skeleton key={i} height={380} radius="var(--r-lg)" />
            ))}
          </div>
        ) : query.data.length === 0 ? (
          <StateMessage
            title="No bundles yet"
            actions={
              <LinkButton variant="primary" to="/courses">
                Explore courses
              </LinkButton>
            }
          >
            Our courses are all available on their own in the meantime.
          </StateMessage>
        ) : (
          <ul className={styles.bundleGrid}>
            {query.data.map((b) => (
              <BundleCard key={b.id} bundle={b} headingLevel="h2" />
            ))}
          </ul>
        )}
      </section>
      <CtaBanner title="Prefer a single course?" />
    </MarketingChrome>
  );
}

/** `/bundles/:slug`. */
export function BundleDetailPage() {
  const { slug = '' } = useParams();
  const query = useAsync(`site:bundle:${slug}`, () => services.site.bundle(slug));
  const bundle = query.data;

  useEffect(() => {
    if (bundle)
      setPageMeta({ title: `${bundle.title} · ZuviloAI`, description: metaDescription(bundle.summary || bundle.description), path: `/bundles/${bundle.slug}` });
  }, [bundle]);
  useJsonLd(
    bundle && {
      '@context': 'https://schema.org',
      '@type': 'Product',
      name: bundle.title,
      description: bundle.summary || bundle.description,
      url: `https://zuviloai.com/bundles/${bundle.slug}`,
      offers: { '@type': 'Offer', price: bundle.price, priceCurrency: 'INR' },
    },
  );

  if (query.status === 'error' && !bundle) {
    const missing = (query.error as { code?: string }).code === 'not-found';
    return (
      <MarketingChrome>
        <StateMessage
          kind={missing ? 'empty' : 'error'}
          title={missing ? 'This bundle isn’t available' : 'The bundle didn’t load'}
          actions={
            missing ? (
              <LinkButton variant="primary" to="/bundles">
                See all bundles
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {missing ? 'It may have been withdrawn, or the link may be wrong.' : query.error.message}
        </StateMessage>
      </MarketingChrome>
    );
  }
  if (!bundle) {
    return (
      <MarketingChrome>
        <div className={styles.detail} aria-busy="true">
          <Skeleton height={420} radius="var(--r-lg)" />
          <Skeleton height={320} radius="var(--r-lg)" />
        </div>
      </MarketingChrome>
    );
  }
  return (
    <MarketingChrome>
      <BundleDetail bundle={bundle} />
    </MarketingChrome>
  );
}

function BundleDetail({ bundle }: { bundle: PublicBundle }) {
  const [held, setHeld] = useState<string[]>([]);
  return (
    <div className={styles.detail}>
      <div className={styles.detailMain}>
        <header>
          <span className={styles.eyebrow}>
            <Link to="/bundles">Course bundles</Link>
          </span>
          <h1>{bundle.title}</h1>
          {bundle.summary && <p className={styles.detailLead}>{bundle.summary}</p>}
          <p className={styles.bundleFacts} style={{ marginTop: 'var(--s-3)' }}>
            <span>
              <Stack size={16} aria-hidden="true" /> {plural(bundle.courseCount, 'course')}
            </span>
            {bundle.durationMin > 0 && (
              <span>
                <Clock size={16} aria-hidden="true" /> {formatDuration(bundle.durationMin)} of learning
              </span>
            )}
          </p>
        </header>
        {bundle.description && (
          <section aria-labelledby="bundle-about">
            <h2 id="bundle-about">About this bundle</h2>
            <p className={styles.detailText}>{bundle.description}</p>
          </section>
        )}
        <section aria-labelledby="bundle-courses">
          <h2 id="bundle-courses">What’s included</h2>
          <ul className={styles.bundleCourses}>
            {bundle.courses.map((c) => (
              <li key={c.id} className={styles.bundleCourse}>
                <CourseCover motif={c.coverMotif as never} imageUrl={c.coverImageUrl} className={styles.bundleCourseCover} />
                <div>
                  <h3>
                    <Link to={`/courses/${c.slug}`}>{c.title}</Link>
                  </h3>
                  {c.subtitle && <p>{c.subtitle}</p>}
                  {c.durationMin > 0 && <p>{formatDuration(c.durationMin)}</p>}
                  {held.includes(c.id) && <p className={styles.bundleCourseOwned}>You already have this course</p>}
                </div>
                {c.price != null && <span>{formatINR(c.price)}</span>}
              </li>
            ))}
          </ul>
        </section>
      </div>
      <aside className={styles.buyBox} aria-label="Buy this bundle">
        <BundleCover bundle={bundle} className={styles.buyBoxCover} />
        <BundlePrice bundle={bundle} />
        <p className={styles.buyNote}>{ALL_INCLUSIVE}. Coupons apply to single courses.</p>
        <BundleBuy bundle={bundle} onHeld={setHeld} />
      </aside>
    </div>
  );
}

/** Read back from the API: the courses are open, the attempt failed, or (null) it is still being confirmed. */
const statusOf = (purchase: BundlePurchaseView, declined = false): PurchasePhase | null => {
  if (purchase.enrolled) return { kind: 'success', message: 'Payment confirmed. Your courses are open.' };
  if (purchase.status === 'failed' || purchase.status === 'expired' || declined) {
    return { kind: 'failed', message: purchase.failureMessage ?? 'The payment didn’t go through. Nothing was charged. You can try again.' };
  }
  return null;
};

function BundleBuy({ bundle, onHeld }: { bundle: PublicBundle; onHeld: (ids: string[]) => void }) {
  const { isAuthenticated, role, authLoading } = useSession();
  const location = useLocation();
  const navigate = useNavigate();
  const toast = useToast();
  const [, setParams] = useSearchParams();
  const [phase, setPhase] = useState<PurchasePhase>({ kind: 'idle' });
  const isLearner = isAuthenticated && role === 'student';
  const here = `${location.pathname}`;

  // What this learner already has, so the page says so before they pay.
  useEffect(() => {
    if (!isLearner || API_MODE !== 'http') return;
    let live = true;
    services.site.quoteBundle(bundle.id).then(
      (quote) => live && onHeld(quote.alreadyHeldCourseIds),
      (err) => {
        const next = refusalPhase(err);
        if (live && next.kind === 'owned') setPhase({ kind: 'success', message: 'You already have every course in this bundle.' });
      },
    );
    return () => {
      live = false;
    };
  }, [bundle.id, isLearner, onHeld]);

  const succeed = (message: string) => {
    setPhase({ kind: 'success', message });
    toast({ kind: 'success', title: `${bundle.title} is yours`, text: message });
  };

  // Back from a hosted checkout: ask the API, never the address bar, whether the courses are open.
  const returned = useMemo(() => readCheckoutReturn(location.search), [location.search]);
  useEffect(() => {
    if (!returned) return;
    setParams({}, { replace: true });
    if (returned.outcome === 'cancelled') return setPhase({ kind: 'cancelled' });
    setPhase({ kind: 'verifying', purchaseId: returned.purchaseId });
    // eslint-disable-next-line react-hooks/exhaustive-deps -- the same return is asked about once.
  }, [returned]);

  // Confirming: ask every few seconds, then stop and say the courses open once the payment is confirmed.
  const verifyingId = phase.kind === 'verifying' ? phase.purchaseId : null;
  useEffect(() => {
    if (!verifyingId) return;
    let live = true;
    const started = Date.now();
    let timer: number | undefined;
    const tick = async () => {
      if (!live) return;
      if (Date.now() - started >= POLL_FOR_MS) return setPhase({ kind: 'slow', purchaseId: verifyingId });
      try {
        const settled = statusOf(await services.site.getBundlePurchase(verifyingId));
        if (!live) return;
        if (settled) return settled.kind === 'success' ? succeed(settled.message) : setPhase(settled);
      } catch {
        // A failed check is asked again on the next tick; the purchase is unchanged by it.
      }
      if (live) timer = window.setTimeout(tick, POLL_EVERY_MS);
    };
    void tick();
    return () => {
      live = false;
      window.clearTimeout(timer);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- `succeed` only names the bundle shown here.
  }, [verifyingId]);

  const buy = async () => {
    setPhase({ kind: 'starting' });
    try {
      const start = await services.site.startBundlePurchase(bundle.id);
      const plan = planCheckout(start.checkout);
      if (plan.kind === 'unavailable') return setPhase({ kind: 'failed', message: CHECKOUT_UNAVAILABLE });
      if (plan.kind === 'redirect') {
        rememberCheckout(start.checkout.orderId, { purchaseId: start.purchase.id, courseId: bundle.id, path: here });
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
      if (!completion) return setPhase({ kind: 'cancelled' });
      setPhase({ kind: 'verifying', purchaseId: start.purchase.id });
      const confirmed = await services.site.confirmBundlePurchase(start.purchase.id, completion);
      if (confirmed.outcome.enrolled) succeed(confirmed.outcome.message);
      else if (confirmed.outcome.status === 'failed') setPhase({ kind: 'failed', message: confirmed.outcome.message });
    } catch (err) {
      const next = refusalPhase(err);
      if (next.kind === 'owned') setPhase({ kind: 'success', message: 'You already have every course in this bundle.' });
      else setPhase(next);
    }
  };

  if (authLoading) return <Skeleton height={44} radius="var(--r-md)" />;
  if (phase.kind === 'success') {
    return (
      <>
        <InlineMessage kind="success" title="Your courses are open">
          {phase.message}
        </InlineMessage>
        <LinkButton to="/my-learning" variant="primary" iconEnd={<ArrowRight size={16} />}>
          Go to My learning
        </LinkButton>
      </>
    );
  }
  if (isAuthenticated && !isLearner) return <p className={styles.buyNote}>You are signed in as staff. Log in with a learner account to buy this bundle.</p>;
  if (!isLearner) {
    return (
      <>
        <LinkButton to={`/login?next=${encodeURIComponent(here)}`} variant="primary" iconEnd={<ArrowRight size={16} />}>
          Buy now
        </LinkButton>
        <p className={styles.buyNote}>
          New here? <Link to={`/register?next=${encodeURIComponent(here)}`}>Create an account</Link> and come straight back.
        </p>
      </>
    );
  }
  const busy = phase.kind === 'starting' || phase.kind === 'checkout' || phase.kind === 'verifying';
  return (
    <>
      <Button
        size="lg"
        variant="primary"
        iconStart={<ShoppingCartSimple size={16} />}
        loading={busy}
        disabled={busy || phase.kind === 'blocked' || phase.kind === 'slow'}
        onClick={() => void buy()}
      >
        Buy now · {formatINR(bundle.price)}
      </Button>
      {phase.kind === 'verifying' && (
        <InlineMessage kind="info" title="Confirming your payment…">
          Your courses open as soon as the payment is confirmed. Please keep this page open.
        </InlineMessage>
      )}
      {phase.kind === 'slow' && (
        <InlineMessage
          kind="info"
          title="Your payment is still being confirmed."
          action={
            <Button size="sm" onClick={() => setPhase({ kind: 'verifying', purchaseId: phase.purchaseId })}>
              Check again
            </Button>
          }
        >
          {SLOW_MESSAGE}
        </InlineMessage>
      )}
      {phase.kind === 'failed' && (
        <InlineMessage kind="error" title="The payment didn’t go through.">
          {phase.message}
        </InlineMessage>
      )}
      {phase.kind === 'cancelled' && <InlineMessage kind="warn" title={CANCELLED_MESSAGE} />}
      {phase.kind === 'blocked' && (
        <InlineMessage kind="warn" title={phase.title}>
          {phase.message}
        </InlineMessage>
      )}
    </>
  );
}
