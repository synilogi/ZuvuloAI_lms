import { Link } from 'react-router-dom';
import { API_MODE } from '@/lib/apiMode';
import { MarketingChrome } from './MarketingChrome';
import { COMPANY, COMPANY_ADDRESS, SUPPORT_EMAIL } from './siteContent';
import styles from './Marketing.module.css';

/** Terms of service for the platform (docs/16 §2.6): learners, instructors and affiliates. */
export default function TermsPage() {
  return (
    <MarketingChrome embeddable>
      <article className={styles.legal}>
        <header className={styles.legalHead}>
          <h1>Terms of service</h1>
          <p className={styles.muted}>Last updated 1 November 2026</p>
        </header>

        <section>
          <h2>Agreement</h2>
          <p>
            ZuviloAI is provided by {COMPANY.legalName}, {COMPANY_ADDRESS} (“we”). By creating an account, buying a course or using ZuviloAI, you agree to these
            terms.
          </p>
        </section>

        <section>
          <h2>The service</h2>
          <p>
            ZuviloAI is an online learning platform. We publish courses from approved instructors and sell them directly to learners. Courses can include video
            and written lessons, quizzes, assignments, live classes and certificates.
          </p>
        </section>

        <section>
          <h2>Accounts and roles</h2>
          <p>
            Learners register with their name, email, mobile number and a password, and confirm a code we send them. Instructors apply and are approved by our
            team, or are invited by us. Keep your sign-in details to yourself: you are responsible for activity under your account.
          </p>
        </section>

        <section>
          <h2>Buying a course</h2>
          <ul>
            <li>Each course page shows its price before you buy. Some courses are free.</li>
            <li>A paid course opens only when our payment gateway confirms the payment. Each order has its own order number in your purchase history.</li>
            <li>A coupon applies only under its own conditions, and each learner can use a coupon once.</li>
            <li>
              Refunds are set out in the <Link to="/refunds">refund policy</Link>. A refund covers the whole order and ends access to the course.
            </li>
          </ul>
        </section>

        <section>
          <h2>Course content</h2>
          <p>
            Instructors keep the rights in the material they create, as agreed with us when they are approved, and allow us to host and sell it on the platform.
            You may use a course for your own learning only. How we handle personal data is set out in the <Link to="/privacy">privacy policy</Link>.
          </p>
        </section>

        <section>
          <h2>Coursework and certificates</h2>
          <p>
            Assignments and assessments are reviewed by the course’s instructors. A certificate is issued when a course’s requirements are met and carries a
            credential ID anyone can check on the verification page. We may revoke a certificate issued in error or obtained dishonestly.
          </p>
        </section>

        <section>
          <h2>Acceptable use</h2>
          <ul>
            <li>Don’t share your account, or present someone else’s coursework as your own.</li>
            <li>Don’t record, redistribute or resell live classes or course content without our written permission.</li>
            <li>Don’t try to reach other people’s data, probe the service for weaknesses, or disrupt it for others.</li>
            <li>Don’t use the platform to publish unlawful content or to send unsolicited messages.</li>
          </ul>
        </section>

        <section>
          <h2>The affiliate program</h2>
          <p>
            The <Link to="/affiliate-program">affiliate program</Link> is optional, and you do not need to join it to learn here. Joining does not guarantee any
            income. Commission depends on verified course sales and the plan in force, and a refund reverses the volume the sale earned. Members must describe
            the program honestly and must not promise income or results to anyone.
          </p>
        </section>

        <section>
          <h2>Suspension and closing an account</h2>
          <p>
            We may suspend an account that breaks these terms, and its owner is told why when they sign in. Learners can delete their own accounts at any time
            from the <Link to="/delete-account">delete your account</Link> page.
          </p>
        </section>

        <section>
          <h2>Changes to these terms</h2>
          <p>
            We may update these terms as the service grows. Material changes are announced by email and in-app notification at least 14 days before they take
            effect.
          </p>
        </section>

        <section>
          <h2>Contact</h2>
          <p>
            Questions about these terms go to {COMPANY.legalName} at <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a> or{' '}
            <a href={COMPANY.phoneHref}>{COMPANY.phone}</a>.
          </p>
        </section>

        {/* True of the demo build only. Against the real API these terms are the ones accounts are held to, so the note would be a lie. */}
        {API_MODE === 'mock' && (
          <p className={styles.legalNote}>
            This is a UI demo build for review purposes — these terms are illustrative sample content, not a binding agreement.
          </p>
        )}
      </article>
    </MarketingChrome>
  );
}
