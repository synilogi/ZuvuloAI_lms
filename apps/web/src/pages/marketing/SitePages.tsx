import { ArrowRight, Certificate, EnvelopeSimple, Lifebuoy, ShieldCheck, Student } from '@phosphor-icons/react';
import { DEFAULT_SITE_CONTENT } from '@syniastrolms/domain';
import { Link } from 'react-router-dom';
import { LinkButton } from '@/components/ui/Button/Button';
import { useAsync } from '@/hooks/useAsync';
import { useJsonLd } from '@/hooks/useJsonLd';
import { services } from '@/services';
import { MarketingChrome } from './MarketingChrome';
import { COMPANY, SUPPORT_EMAIL } from './siteContent';
import { CtaBanner, FaqList, PageHero, SectionHead } from './SiteParts';
import styles from './Marketing.module.css';

/* The website's content pages (docs/16 §2.6): about and FAQ. */

export function AboutPage() {
  return (
    <MarketingChrome>
      <PageHero
        eyebrow="About"
        title="One place to learn, from people who teach"
        actions={
          <LinkButton to="/courses" variant="primary" size="lg" iconEnd={<ArrowRight size={18} />}>
            Explore courses
          </LinkButton>
        }
      >
        ZuviloAI is an online course platform run by {COMPANY.legalName}. We publish courses from approved instructors and look after everything around them:
        lessons, assessments, live classes, certificates and payments.
      </PageHero>
      <section className={styles.section} aria-labelledby="about-what">
        <SectionHead id="about-what" title="What we care about" />
        <ul className={styles.valueGrid}>
          <li>
            <Student size={24} aria-hidden="true" className={styles.yes} />
            <h3>Learning that gets finished</h3>
            <p>Courses are structured, so a learner always knows what comes next and how far they have come.</p>
          </li>
          <li>
            <Certificate size={24} aria-hidden="true" className={styles.yes} />
            <h3>Certificates that can be checked</h3>
            <p>
              Anyone can confirm a certificate on our <Link to="/verify">Verify page</Link>.
            </p>
          </li>
          <li>
            <ShieldCheck size={24} aria-hidden="true" className={styles.yes} />
            <h3>Straight dealing</h3>
            <p>Prices are shown before you sign up, and a course opens only when the payment gateway confirms the payment.</p>
          </li>
        </ul>
      </section>
      <section className={styles.section} aria-labelledby="about-contact">
        <SectionHead id="about-contact" title="Talk to us" />
        <ul className={styles.valueGrid}>
          <li>
            <EnvelopeSimple size={24} aria-hidden="true" className={styles.yes} />
            <h3>Questions about courses</h3>
            <p>
              <Link to="/contact?topic=sales">Ask about a course or an order</Link>, and we will reply by email.
            </p>
          </li>
          <li>
            <Lifebuoy size={24} aria-hidden="true" className={styles.yes} />
            <h3>Support</h3>
            <p>
              Browse the <Link to="/support">Help Centre</Link> or write to <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>.
            </p>
          </li>
        </ul>
      </section>
      <CtaBanner />
    </MarketingChrome>
  );
}

export function FaqPage() {
  const content = useAsync('site:faq', () => services.site.content().catch(() => DEFAULT_SITE_CONTENT));
  const faqs = (content.data ?? DEFAULT_SITE_CONTENT).faqs;
  useJsonLd(
    content.data && faqs.length > 0
      ? {
          '@context': 'https://schema.org',
          '@type': 'FAQPage',
          mainEntity: faqs.map((f) => ({ '@type': 'Question', name: f.q, acceptedAnswer: { '@type': 'Answer', text: f.a } })),
        }
      : undefined,
  );
  return (
    <MarketingChrome>
      <PageHero eyebrow="FAQ" title="Frequently asked questions">
        Can’t find your answer? <Link to="/contact">Ask our team</Link> or visit the <Link to="/support">Help Centre</Link>.
      </PageHero>
      <section className={styles.section} aria-label="Questions">
        <FaqList faqs={faqs} />
      </section>
      <CtaBanner />
    </MarketingChrome>
  );
}
