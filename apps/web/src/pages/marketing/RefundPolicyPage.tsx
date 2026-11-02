import { Link } from 'react-router-dom';
import { API_MODE } from '@/lib/apiMode';
import { MarketingChrome } from './MarketingChrome';
import { COMPANY, COMPANY_ADDRESS, SUPPORT_EMAIL } from './siteContent';
import styles from './Marketing.module.css';

/**
 * Refunds and delivery for course purchases: the page a payment partner asks a merchant to publish. Every refund is a
 * person's reviewed decision, covers the whole order (docs/16, PLAT-004), and ends access to the course.
 */
export default function RefundPolicyPage() {
  return (
    <MarketingChrome embeddable>
      <article className={styles.legal}>
        <header className={styles.legalHead}>
          <h1>Refund policy</h1>
          <p className={styles.muted}>Last updated 1 November 2026</p>
        </header>

        <section>
          <h2>What this covers</h2>
          <p>This policy covers the courses you buy on ZuviloAI. Free courses have no payment to refund.</p>
        </section>

        <section>
          <h2>What a refund does</h2>
          <ul>
            <li>A refund covers the whole order. We do not refund part of an order.</li>
            <li>When an order is refunded, your access to that course ends. You can buy it again later.</li>
            <li>Any affiliate volume the sale earned is reversed.</li>
          </ul>
        </section>

        <section>
          <h2>When we refund</h2>
          <p>We refund an order in full when:</p>
          <ul>
            <li>you were charged twice for the same course;</li>
            <li>you paid, but the course did not open and we cannot open it.</li>
          </ul>
          <p>Any other request is considered case by case.</p>
        </section>

        <section>
          <h2>How a refund is reviewed and paid</h2>
          <ul>
            <li>
              Write to <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a> or call <a href={COMPANY.phoneHref}>{COMPANY.phone}</a> with your account email
              and the order number, within 30 days of the payment.
            </li>
            <li>Our team reviews every request and replies within 2 working days with the decision and the reason.</li>
            <li>
              An approved refund goes back to the original payment method through our payment partner, Razorpay. Banks usually show it within 5–7 working days
              of approval.
            </li>
          </ul>
        </section>

        <section>
          <h2>Delivery</h2>
          <p>
            ZuviloAI is an online service: nothing is shipped. A course opens as soon as Razorpay confirms the payment, usually within a minute, and the order
            appears in your purchase history.
          </p>
        </section>

        <section>
          <h2>Contact</h2>
          <p>
            {COMPANY.name}, {COMPANY_ADDRESS} · <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a> · <a href={COMPANY.phoneHref}>{COMPANY.phone}</a>. The
            full terms are in the <Link to="/terms">terms of service</Link>.
          </p>
        </section>

        {API_MODE === 'mock' && <p className={styles.legalNote}>This is a UI demo build for review purposes — this policy is illustrative sample content.</p>}
      </article>
    </MarketingChrome>
  );
}
