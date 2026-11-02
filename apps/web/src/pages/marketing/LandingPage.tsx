import { useEffect, useMemo, useRef, useState, type FormEvent, type ReactNode } from 'react';
import { ArrowRight, MagnifyingGlass, Sparkle } from '@phosphor-icons/react';
import { DEFAULT_SITE_CONTENT, type Course, type Instructor } from '@syniastrolms/domain';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { SearchInput } from '@/components/ui/Field/Field';
import { Skeleton } from '@/components/ui/Feedback/Feedback';
import { IconChip } from '@/components/ui/Badge/Badge';
import { CategoryGlyph } from '@/components/lms/course/CategoryGlyph';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { useAsync } from '@/hooks/useAsync';
import { useJsonLd } from '@/hooks/useJsonLd';
import { saleDisplay } from '@/lib/coursePricing';
import { plural } from '@/lib/format';
import { services } from '@/services';
import { MarketingChrome } from './MarketingChrome';
import { BENEFITS, COMPANY, COMPANY_ADDRESS, HOW_IT_WORKS, SUPPORT_EMAIL, WHY_LEARN } from './siteContent';
import { FaqList } from './SiteParts';
import { PublicCourseCard } from './PublicCourseCard';
import { useSectionReveal } from './landingMotion';
import styles from './Landing.module.css';
import site from './Site.module.css';

/*
 * The home page (docs/16 §2.6): one platform selling its own courses. Its courses and categories come from the catalogue,
 * its headline, testimonials and questions from the document the Super Admin edits. The testimonials section stays away
 * until there is a real quote to show, and the footer comes with the chrome.
 */

const FEATURED_COUNT = 6;

/** Who runs the site and what it is called, for search engines. */
const HOME_SCHEMA = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'Organization',
      '@id': 'https://zuviloai.com/#organization',
      name: 'ZuviloAI',
      legalName: COMPANY.legalName,
      url: 'https://zuviloai.com/',
      logo: 'https://zuviloai.com/icon-512.png',
      email: COMPANY.email,
      telephone: COMPANY.phone,
      address: COMPANY_ADDRESS,
    },
    {
      '@type': 'WebSite',
      '@id': 'https://zuviloai.com/#website',
      name: 'ZuviloAI',
      url: 'https://zuviloai.com/',
      publisher: { '@id': 'https://zuviloai.com/#organization' },
    },
  ],
};

/** The Super Admin's choice in their order, topped up with the most popular courses. */
export function featuredCourses(courses: Course[], ids: string[], count = FEATURED_COUNT): Course[] {
  const chosen = ids.map((id) => courses.find((c) => c.id === id)).filter((c): c is Course => Boolean(c));
  const rest = [...courses].filter((c) => !ids.includes(c.id)).sort((a, b) => b.enrolledCount - a.enrolledCount);
  return [...chosen, ...rest].slice(0, count);
}

/** Brings the section a link names into view, on arrival and each time the link is followed. */
function useHashScroll() {
  const { hash, key } = useLocation();
  useEffect(() => {
    if (!hash) return;
    const target = document.getElementById(decodeURIComponent(hash.slice(1)));
    if (!target) return;
    const calm = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
    target.scrollIntoView({ behavior: calm ? 'auto' : 'smooth', block: 'start' });
  }, [hash, key]);
}

export default function LandingPage() {
  useHashScroll();
  useJsonLd(HOME_SCHEMA);
  const pageRef = useRef<HTMLDivElement>(null);
  useSectionReveal(pageRef);
  const query = useAsync('site:home', () =>
    Promise.all([
      services.catalog.listCourses(),
      services.catalog.listCategories(),
      services.catalog.listInstructors(),
      // The page's words have defaults, so a failed read costs nothing a visitor would notice.
      services.site.content().catch(() => DEFAULT_SITE_CONTENT),
    ]).then(([courses, categories, instructors, content]) => ({ courses, categories, instructors, content })),
  );
  const data = query.data;
  const content = data?.content ?? DEFAULT_SITE_CONTENT;
  const featured = useMemo(() => (data ? featuredCourses(data.courses, content.featuredCourseIds) : []), [data, content.featuredCourseIds]);

  return (
    <MarketingChrome canvas="aurora">
      <div ref={pageRef} className={styles.page}>
        <section className={styles.hero} aria-labelledby="home-title">
          <div className={styles.heroCopy}>
            <p className={styles.heroEyebrow}>
              <span className={styles.heroEyebrowIcon} aria-hidden="true">
                <Sparkle size={12} weight="fill" />
              </span>
              Online courses
            </p>
            <h1 id="home-title" className={styles.heroTitle}>
              {content.heroTitle}
            </h1>
            <p className={styles.heroText}>{content.heroText}</p>
            <div className={styles.heroActions}>
              <LinkButton to="/courses" variant="primary" size="lg" className={styles.pill} iconEnd={<ArrowRight size={18} />}>
                Explore courses
              </LinkButton>
              <LinkButton to="/register" variant="secondary" size="lg" className={styles.pill}>
                Create your account
              </LinkButton>
            </div>
          </div>
          <div className={site.heroPanel}>
            <h2>Courses to start with</h2>
            {query.status === 'error' && !data ? (
              <p>
                <Link to="/courses">See all our courses</Link>
              </p>
            ) : !data ? (
              [0, 1, 2].map((i) => <Skeleton key={i} height={72} radius="var(--r-md)" />)
            ) : (
              featured.slice(0, 3).map((c) => (
                <Link key={c.id} to={`/courses/${c.slug}`} className={site.heroCourse}>
                  <CourseCover motif={c.coverMotif} imageUrl={c.coverImageUrl} className={site.heroCourseCover} />
                  <span>
                    <strong>{c.title}</strong>
                    <small>{saleDisplay(c).label}</small>
                  </span>
                </Link>
              ))
            )}
            {data && featured.length === 0 && <p>New courses are on their way.</p>}
          </div>
        </section>

        <ExploreBand />

        <Section
          id="home-featured"
          eyebrow="Featured"
          title={
            <>
              Courses learners <em>start</em> with
            </>
          }
        >
          {query.status === 'error' && !data ? (
            <p className={styles.lead}>
              The courses didn’t load. <Link to="/courses">Open the catalogue</Link> to try again.
            </p>
          ) : !data ? (
            <Skeleton height={320} radius="var(--r-lg)" />
          ) : featured.length === 0 ? (
            <p className={styles.lead}>New courses are on their way. Create an account and we will have you ready when they open.</p>
          ) : (
            <FeaturedGrid courses={featured} instructors={data.instructors} />
          )}
        </Section>

        {data && data.categories.length > 0 && (
          <Section
            id="home-categories"
            eyebrow="Categories"
            title={
              <>
                Browse by <em>subject</em>
              </>
            }
          >
            <ul className={site.categoryGrid}>
              {data.categories
                .filter((c) => c.status === 'active')
                .slice(0, 8)
                .map((c) => {
                  const count = data.courses.filter((course) => course.categoryId === c.id).length;
                  return (
                    <li key={c.id}>
                      <Link to={`/courses?category=${c.id}`} className={site.categoryCard}>
                        <CategoryGlyph glyph={c.glyph} size={36} />
                        <h3>{c.name}</h3>
                        <p className={site.categoryCount}>{plural(count, 'course')}</p>
                      </Link>
                    </li>
                  );
                })}
            </ul>
          </Section>
        )}

        <Section
          id="home-why"
          eyebrow="Why learn here"
          title={
            <>
              Courses built to be <em>finished</em>
            </>
          }
        >
          <Points items={WHY_LEARN} />
        </Section>

        <Section
          id="how-it-works"
          eyebrow="How it works"
          title={
            <>
              From browsing to <em>learning</em>
            </>
          }
        >
          <ol className={styles.steps}>
            {HOW_IT_WORKS.map((s, i) => (
              <li key={s.title}>
                <span className={styles.stepNum} aria-hidden="true">
                  {String(i + 1).padStart(2, '0')}
                </span>
                <h3>{s.title}</h3>
                <p>{s.text}</p>
              </li>
            ))}
          </ol>
        </Section>

        <section className={site.promo} aria-labelledby="home-teach">
          <div className={site.promoCopy}>
            <h2 id="home-teach">Teach what you know</h2>
            <p>Apply to become an instructor. Our team reviews each application, and approved instructors build and run their courses here.</p>
          </div>
          <div className={site.promoActions}>
            <LinkButton to="/become-an-instructor" variant="primary" iconEnd={<ArrowRight size={16} />}>
              Become an instructor
            </LinkButton>
          </div>
        </section>

        <section className={site.promo} aria-labelledby="home-affiliate">
          <div className={site.promoCopy}>
            <h2 id="home-affiliate">Recommend courses you believe in</h2>
            <p>Our optional affiliate program has published rules for referrals, volume and rewards. Read them before deciding whether it suits you.</p>
            <p className={site.promoNote}>Any income depends on verified sales and the plan rules. It is never guaranteed.</p>
          </div>
          <div className={site.promoActions}>
            <LinkButton to="/affiliate-program" iconEnd={<ArrowRight size={16} />}>
              Read how it works
            </LinkButton>
          </div>
        </section>

        {content.testimonials.length > 0 && (
          <Section
            id="home-testimonials"
            eyebrow="Testimonials"
            title={
              <>
                What learners <em>say</em>
              </>
            }
          >
            <ul className={site.quotes}>
              {content.testimonials.map((t) => (
                <li key={`${t.name}:${t.quote.slice(0, 20)}`}>
                  <figure>
                    <blockquote>{t.quote}</blockquote>
                    <figcaption>
                      <strong>{t.name}</strong>
                      {t.role}
                    </figcaption>
                  </figure>
                </li>
              ))}
            </ul>
          </Section>
        )}

        <Section
          id="home-benefits"
          eyebrow="Benefits"
          title={
            <>
              What comes with your <em>account</em>
            </>
          }
        >
          <Points items={BENEFITS} />
        </Section>

        <section className={`${styles.section} ${styles.faq}`} aria-labelledby="home-faq">
          <div className={styles.faqAside}>
            <div className={styles.introStart}>
              <p className={styles.eyebrow}>FAQ</p>
              <h2 id="home-faq">Questions learners ask first</h2>
            </div>
            <p className={styles.lead}>
              Something else? Read the <Link to="/faq">full FAQ</Link>, <Link to="/contact">contact us</Link> or write to{' '}
              <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>.
            </p>
          </div>
          <FaqList faqs={content.faqs.slice(0, 6)} />
        </section>

        <section className={styles.cta} aria-labelledby="home-cta">
          <div className={styles.ctaOrbit} aria-hidden="true" />
          <h2 id="home-cta">
            Find your next course <em>today</em>
          </h2>
          <p>Browse the catalogue without an account, and create one when you are ready to start.</p>
          <div className={styles.ctaActions}>
            <LinkButton to="/courses" variant="primary" size="lg" className={`${styles.pill} ${styles.ctaPrimary}`} iconEnd={<ArrowRight size={18} />}>
              Explore courses
            </LinkButton>
            <Link to="/register" className={styles.ctaLink}>
              Or create your account
            </Link>
          </div>
        </section>
      </div>
    </MarketingChrome>
  );
}

function Section({ id, eyebrow, title, children }: { id: string; eyebrow: string; title: ReactNode; children: ReactNode }) {
  return (
    <section className={styles.section} aria-labelledby={`${id}-title`} id={id}>
      <div className={styles.intro}>
        <p className={styles.eyebrow}>{eyebrow}</p>
        <h2 id={`${id}-title`}>{title}</h2>
      </div>
      {children}
    </section>
  );
}

function Points({ items }: { items: typeof WHY_LEARN }) {
  return (
    <ul className={site.pointGrid}>
      {items.map((f) => (
        <li key={f.title}>
          <IconChip tone="accent" size="lg">
            <f.icon size={22} aria-hidden="true" />
          </IconChip>
          <h3>{f.title}</h3>
          <p>{f.text}</p>
        </li>
      ))}
    </ul>
  );
}

function FeaturedGrid({ courses, instructors }: { courses: Course[]; instructors: Instructor[] }) {
  return (
    <>
      <ul className={site.courseGrid}>
        {courses.map((c) => (
          <PublicCourseCard key={c.id} course={c} instructors={instructors} />
        ))}
      </ul>
      <div className={site.exploreBand}>
        <LinkButton to="/courses" iconEnd={<ArrowRight size={16} />}>
          See all courses
        </LinkButton>
      </div>
    </>
  );
}

/** The explore call to action: a search that opens the catalogue on its results. */
function ExploreBand() {
  const navigate = useNavigate();
  const [q, setQ] = useState('');
  const submit = (e: FormEvent) => {
    e.preventDefault();
    const term = q.trim();
    navigate(term ? `/courses?q=${encodeURIComponent(term)}` : '/courses');
  };
  return (
    <section className={site.exploreBand} aria-labelledby="home-explore">
      <h2 id="home-explore" className={styles.lead}>
        What do you want to learn?
      </h2>
      <form className={site.searchForm} onSubmit={submit} role="search">
        <SearchInput value={q} onValueChange={setQ} placeholder="Search courses" aria-label="Search courses" />
        <Button type="submit" variant="primary" iconStart={<MagnifyingGlass size={16} />}>
          Search
        </Button>
      </form>
    </section>
  );
}
