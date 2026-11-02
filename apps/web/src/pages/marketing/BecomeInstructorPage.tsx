import { ArrowRight } from '@phosphor-icons/react';
import { Link } from 'react-router-dom';
import { IconChip } from '@/components/ui/Badge/Badge';
import { LinkButton } from '@/components/ui/Button/Button';
import { MarketingChrome } from './MarketingChrome';
import { INSTRUCTOR_POINTS, INSTRUCTOR_STEPS } from './siteContent';
import { CtaBanner, PageHero, SectionHead } from './SiteParts';
import styles from './Marketing.module.css';
import site from './Site.module.css';

/** `/become-an-instructor`: what teaching here involves, and the way into the application. */
export default function BecomeInstructorPage() {
  return (
    <MarketingChrome>
      <PageHero
        eyebrow="Teach"
        title="Become an instructor"
        actions={
          <LinkButton to="/teach/apply" variant="primary" size="lg" iconEnd={<ArrowRight size={18} />}>
            Apply to teach
          </LinkButton>
        }
      >
        Share what you know with learners on one platform. Our team reviews each application, and approved instructors build and run their courses here.
      </PageHero>
      <section className={styles.section} aria-labelledby="teach-tools">
        <SectionHead id="teach-tools" title="What you get">
          The tools instructors work with every day.
        </SectionHead>
        <ul className={site.pointGrid}>
          {INSTRUCTOR_POINTS.map((f) => (
            <li key={f.title}>
              <IconChip tone="accent" size="lg">
                <f.icon size={22} aria-hidden="true" />
              </IconChip>
              <h3>{f.title}</h3>
              <p>{f.text}</p>
            </li>
          ))}
        </ul>
      </section>
      <section className={styles.section} aria-labelledby="teach-steps">
        <SectionHead id="teach-steps" title="How applying works" />
        <ol className={site.pointGrid}>
          {INSTRUCTOR_STEPS.map((s, i) => (
            <li key={s.title}>
              <span className={site.pointNumber} aria-hidden="true">
                {String(i + 1).padStart(2, '0')}
              </span>
              <h3>{s.title}</h3>
              <p>{s.text}</p>
            </li>
          ))}
        </ol>
      </section>
      <section className={styles.section} aria-labelledby="teach-terms">
        <div className={site.disclosure}>
          <h2 id="teach-terms">Payment for teaching</h2>
          <p>
            Any payment for your teaching is agreed with our team when your application is approved. Ask us anything first through the{' '}
            <Link to="/contact">contact page</Link>.
          </p>
        </div>
      </section>
      <CtaBanner title="Ready to teach?" to="/teach/apply" action="Apply to teach">
        Your application goes straight to our team.
      </CtaBanner>
    </MarketingChrome>
  );
}
