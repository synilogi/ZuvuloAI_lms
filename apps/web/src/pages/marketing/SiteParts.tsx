import type { ReactNode } from 'react';
import { ArrowRight } from '@phosphor-icons/react';
import { LinkButton } from '@/components/ui/Button/Button';
import type { Faq } from './siteContent';
import styles from './Marketing.module.css';

/* Building blocks the website's pages share. */

/** A page's opening: eyebrow, the one heading, a lead paragraph and optional actions. */
export function PageHero({ eyebrow, title, children, actions }: { eyebrow: string; title: string; children?: ReactNode; actions?: ReactNode }) {
  return (
    <section className={styles.pageHero}>
      <p className={styles.eyebrow}>{eyebrow}</p>
      <h1>{title}</h1>
      {children && <p>{children}</p>}
      {actions && <div className={`${styles.heroActions} ${styles.heroLeft}`}>{actions}</div>}
    </section>
  );
}

export function SectionHead({ id, title, children }: { id: string; title: string; children?: ReactNode }) {
  return (
    <div className={styles.sectionHead}>
      <h2 id={id}>{title}</h2>
      {children && <p>{children}</p>}
    </div>
  );
}

/** Questions as disclosure widgets: keyboard and screen-reader friendly with no script. */
export function FaqList({ faqs }: { faqs: Faq[] }) {
  return (
    <div className={styles.faqList}>
      {faqs.map((f) => (
        <details key={f.q} className={styles.faqItem}>
          <summary>{f.q}</summary>
          <p>{f.a}</p>
        </details>
      ))}
    </div>
  );
}

/** The closing call to action a page ends on. */
export function CtaBanner({
  title = 'Find your next course',
  to = '/courses',
  action = 'Explore courses',
  children,
}: {
  title?: string;
  to?: string;
  action?: string;
  children?: ReactNode;
}) {
  // The last word in the serif, as the home page's headings do.
  const words = title.trim().split(' ');
  const last = words.pop();
  return (
    <section className={styles.ctaBanner}>
      <h2>
        {words.join(' ')} <em className={styles.serifWord}>{last}</em>
      </h2>
      <p>{children ?? 'Browse the catalogue without an account, and create one when you are ready to start.'}</p>
      <div className={styles.heroActions}>
        <LinkButton to={to} variant="primary" size="lg" className={styles.ctaBannerPrimary} iconEnd={<ArrowRight size={18} />}>
          {action}
        </LinkButton>
      </div>
    </section>
  );
}
