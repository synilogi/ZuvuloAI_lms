import { useEffect, useMemo, useState, type FormEvent, type ReactNode } from 'react';
import { ArrowRight, MagnifyingGlass, PlayCircle, Sparkle } from '@phosphor-icons/react';
import {
  BLOG_KIND_LABELS,
  DEFAULT_SITE_CONTENT,
  orderedSections,
  type Category,
  type BlogPost,
  type Course,
  type HomeSectionId,
  type Instructor,
  type PublicBundle,
  type PublicMentor,
  type PublicStats,
  type SiteBanner,
  type SiteContent,
} from '@syniastrolms/domain';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { setPageMeta } from '@/app/pageMeta';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { SearchInput } from '@/components/ui/Field/Field';
import { Skeleton } from '@/components/ui/Feedback/Feedback';
import { IconChip } from '@/components/ui/Badge/Badge';
import { CategoryGlyph } from '@/components/lms/course/CategoryGlyph';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { useAsync } from '@/hooks/useAsync';
import { useJsonLd } from '@/hooks/useJsonLd';
import { saleDisplay } from '@/lib/coursePricing';
import { formatCount, plural } from '@/lib/format';
import { services } from '@/services';
import { BundleCard, BundleCover, BundlePrice } from './BundleCard';
import { MarketingChrome } from './MarketingChrome';
import { MentorCard } from './MentorCard';
import { AFFILIATE_POINTS, COMPANY, COMPANY_ADDRESS, HOME_STEPS, HOME_WHY, INSTRUCTOR_POINTS, INSTRUCTOR_STEPS, SUPPORT_EMAIL } from './siteContent';
import { FaqList } from './SiteParts';
import { PublicCourseCard } from './PublicCourseCard';
import { siteImageSrc } from './siteImage';
import styles from './Home.module.css';
import site from './Site.module.css';

/*
 * The home page (docs/17): one platform selling its own courses and bundles. Every course, bundle, category, mentor and figure comes
 * from the platform's records; the words, the order of the sections and what shows come from the document the Super Admin edits. A
 * section with nothing real to show stays away rather than filling itself with examples.
 */

const FEATURED_COUNT = 6;
const CATEGORY_COUNT = 10;
const MENTOR_COUNT = 4;
const POST_COUNT = 3;

/** Who runs the site and what it is called, for search engines. */
const HOME_SCHEMA = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'Organization',
      '@id': 'https://zuviloai.com/#organization',
      name: 'ZuviloAI',
      legalName: COMPANY.name,
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

/** The chosen items in their order, then the rest as they come. Something no longer available simply drops out. */
export function chosenFirst<T extends { id: string }>(items: T[], ids: string[]): T[] {
  const chosen = ids.map((id) => items.find((x) => x.id === id)).filter((x): x is T => Boolean(x));
  return [...chosen, ...items.filter((x) => !ids.includes(x.id))];
}

/** The figures to show: those the Super Admin left on, with something real to say. A zero is not a selling point. */
export function shownStats(stats: PublicStats, visible: SiteContent['stats']): { label: string; value: number }[] {
  return [
    { label: 'Learners', value: visible.learners ? stats.learners : 0 },
    { label: 'Courses', value: visible.courses ? stats.courses : 0 },
    { label: 'Expert instructors', value: visible.instructors ? stats.instructors : 0 },
    { label: 'Hours of learning', value: visible.learningHours ? stats.learningHours : 0 },
  ].filter((s) => s.value > 0);
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

interface HomeData {
  courses: Course[];
  categories: Category[];
  instructors: Instructor[];
  bundles: PublicBundle[];
  mentors: PublicMentor[];
  stats: PublicStats | null;
  posts: BlogPost[];
  content: SiteContent;
}

export default function LandingPage() {
  useHashScroll();
  useJsonLd(HOME_SCHEMA);
  const query = useAsync('site:home', () =>
    Promise.all([
      services.catalog.listCourses(),
      services.catalog.listCategories(),
      services.catalog.listInstructors(),
      // The sections these feed simply stay away when a read fails: a visitor still has the catalogue.
      services.site.bundles().catch(() => []),
      services.site.mentors().catch(() => []),
      services.site.stats().catch(() => null),
      services.site.posts().catch(() => []),
      services.site.content().catch(() => DEFAULT_SITE_CONTENT),
    ]).then(([courses, categories, instructors, bundles, mentors, stats, posts, content]): HomeData => ({
      courses,
      categories,
      instructors,
      bundles,
      mentors,
      stats,
      posts,
      content,
    })),
  );
  const data = query.data;
  const content = data?.content ?? DEFAULT_SITE_CONTENT;
  const featured = useMemo(() => (data ? featuredCourses(data.courses, content.featuredCourseIds) : []), [data, content.featuredCourseIds]);
  const bundles = useMemo(() => (data ? chosenFirst(data.bundles, content.featuredBundleIds) : []), [data, content.featuredBundleIds]);
  const heroBundle = data ? (data.bundles.find((b) => b.id === content.heroBundleId) ?? bundles[0]) : undefined;

  // The Super Admin's words for search engines, when they have written any; otherwise the page's own.
  useEffect(() => {
    if (!data || (!content.seoTitle && !content.seoDescription && !content.seoImageUrl)) return;
    setPageMeta({
      title: content.seoTitle || `ZuviloAI · ${content.heroTitle}`,
      description: content.seoDescription || content.heroText,
      path: '/',
      ...(content.seoImageUrl ? { image: siteImageSrc(content.seoImageUrl) } : {}),
    });
  }, [data, content]);

  const render = (id: HomeSectionId): ReactNode => {
    switch (id) {
      case 'stats':
        return data?.stats ? <StatsBand stats={shownStats(data.stats, content.stats)} /> : null;
      case 'bundles':
        return bundles.length > 0 ? <BundlesSection bundles={bundles.slice(0, FEATURED_COUNT)} /> : null;
      case 'categories':
        return data ? <CategoriesSection data={data} /> : null;
      case 'courses':
        return <CoursesSection status={query.status} data={data} featured={featured} />;
      case 'mentors':
        return data && data.mentors.length > 0 ? <MentorsSection mentors={chosenFirst(data.mentors, content.featuredMentorIds)} /> : null;
      case 'why':
        return <WhySection />;
      case 'how':
        return <HowSection />;
      case 'teach':
        return <TeachSection />;
      case 'affiliate':
        return <AffiliateSection title={content.affiliateTitle} text={content.affiliateText} />;
      case 'testimonials':
        return content.testimonials.length > 0 ? <StoriesSection stories={content.testimonials} /> : null;
      case 'resources':
        return data && data.posts.length > 0 ? <ResourcesSection posts={data.posts.slice(0, POST_COUNT)} /> : null;
      case 'faq':
        return <FaqSection content={content} />;
      case 'cta':
        return <FinalCta />;
    }
  };

  return (
    <MarketingChrome>
      <div className={styles.page}>
        <section className={styles.hero} aria-labelledby="home-title" data-surface="ink">
          <div className={styles.heroInner}>
            <div className={styles.heroCopy}>
              {content.heroEyebrow && (
                <p className={styles.heroEyebrow}>
                  <Sparkle size={13} weight="fill" aria-hidden="true" />
                  {content.heroEyebrow}
                </p>
              )}
              <h1 id="home-title" className={styles.heroTitle}>
                {content.heroTitle}
              </h1>
              <p className={styles.heroText}>{content.heroText}</p>
              <div className={styles.heroActions}>
                <LinkButton to="/courses" variant="primary" size="lg" iconEnd={<ArrowRight size={18} />}>
                  Explore courses
                </LinkButton>
                <Link to="/register" className={styles.heroSecondary}>
                  Join ZuviloAI
                </Link>
              </div>
              <ExploreSearch />
            </div>
            <HeroFeature imageUrl={content.heroImageUrl} bundle={heroBundle} course={featured[0]} loading={!data && query.status !== 'error'} />
          </div>
        </section>

        {content.banners.length > 0 && <Banners banners={content.banners} />}

        {orderedSections(content.sections)
          .filter((s) => s.visible)
          .map((s) => {
            const node = render(s.id);
            return node ? <div key={s.id}>{node}</div> : null;
          })}
      </div>
    </MarketingChrome>
  );
}

/** Beside the headline: the Super Admin's image, or the bundle or course the page leads with. */
function HeroFeature({ imageUrl, bundle, course, loading }: { imageUrl: string; bundle?: PublicBundle; course?: Course; loading: boolean }) {
  const src = siteImageSrc(imageUrl);
  if (loading) return <Skeleton height={380} radius="var(--r-xl)" />;
  return (
    <div className={styles.heroFeature}>
      {src && <img src={src} alt="" className={styles.heroImage} />}
      {bundle ? (
        <Link to={`/bundles/${bundle.slug}`} className={styles.featureCard}>
          {!src && <BundleCover bundle={bundle} className={styles.featureCover} />}
          <span className={styles.featureLabel}>Featured bundle</span>
          <strong className={styles.featureTitle}>{bundle.title}</strong>
          <span className={styles.featureFacts}>{plural(bundle.courseCount, 'course')}</span>
          <BundlePrice bundle={bundle} />
        </Link>
      ) : course ? (
        <Link to={`/courses/${course.slug}`} className={styles.featureCard}>
          {!src && <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.featureCover} />}
          <span className={styles.featureLabel}>Featured course</span>
          <strong className={styles.featureTitle}>{course.title}</strong>
          {course.subtitle && <span className={styles.featureFacts}>{course.subtitle}</span>}
          <span className={styles.bundlePrice}>
            <strong>{saleDisplay(course).label}</strong>
          </span>
        </Link>
      ) : null}
    </div>
  );
}

/** A search that opens the catalogue on its results. */
function ExploreSearch() {
  const navigate = useNavigate();
  const [q, setQ] = useState('');
  const submit = (e: FormEvent) => {
    e.preventDefault();
    const term = q.trim();
    navigate(term ? `/courses?q=${encodeURIComponent(term)}` : '/courses');
  };
  return (
    <form className={styles.heroSearch} onSubmit={submit} role="search">
      <SearchInput value={q} onValueChange={setQ} placeholder="What do you want to learn?" aria-label="Search courses" />
      <Button type="submit" iconStart={<MagnifyingGlass size={16} />}>
        Search
      </Button>
    </form>
  );
}

function Banners({ banners }: { banners: SiteBanner[] }) {
  return (
    <section className={styles.banners} aria-label="Announcements">
      {banners.map((b) => {
        const src = siteImageSrc(b.imageUrl);
        const external = b.linkTo?.startsWith('https://');
        return (
          <article key={b.title} className={styles.banner}>
            {src && <img src={src} alt="" loading="lazy" />}
            <div>
              <h2>{b.title}</h2>
              {b.text && <p>{b.text}</p>}
            </div>
            {b.linkTo &&
              (external ? (
                <a className={styles.bannerLink} href={b.linkTo} target="_blank" rel="noopener noreferrer">
                  {b.linkLabel || 'Find out more'}
                </a>
              ) : (
                <Link className={styles.bannerLink} to={b.linkTo}>
                  {b.linkLabel || 'Find out more'}
                </Link>
              ))}
          </article>
        );
      })}
    </section>
  );
}

function Section({
  id,
  eyebrow,
  title,
  intro,
  action,
  children,
}: {
  id: string;
  eyebrow: string;
  title: string;
  intro?: string;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className={styles.section} aria-labelledby={`${id}-title`} id={id}>
      <div className={styles.sectionHead}>
        <div>
          <p className={styles.eyebrow}>{eyebrow}</p>
          <h2 id={`${id}-title`}>{title}</h2>
          {intro && <p className={styles.sectionIntro}>{intro}</p>}
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}

function StatsBand({ stats }: { stats: { label: string; value: number }[] }) {
  if (stats.length === 0) return null;
  return (
    <section className={styles.stats} aria-label="The platform in figures">
      <dl>
        {stats.map((s) => (
          <div key={s.label}>
            <dd>{formatCount(s.value)}</dd>
            <dt>{s.label}</dt>
          </div>
        ))}
      </dl>
    </section>
  );
}

function BundlesSection({ bundles }: { bundles: PublicBundle[] }) {
  return (
    <Section
      id="home-bundles"
      eyebrow="Course bundles"
      title="Learn more together, for one price"
      action={
        <LinkButton to="/bundles" iconEnd={<ArrowRight size={16} />}>
          View all bundles
        </LinkButton>
      }
    >
      <ul className={styles.bundleGrid}>
        {bundles.map((b) => (
          <BundleCard key={b.id} bundle={b} />
        ))}
      </ul>
    </Section>
  );
}

function CategoriesSection({ data }: { data: HomeData }) {
  // Only subjects with something to learn in them: an empty category is a dead end.
  const categories = data.categories
    .filter((c) => c.status === 'active')
    .map((c) => ({ category: c, count: data.courses.filter((course) => course.categoryId === c.id).length }))
    .filter((c) => c.count > 0)
    .slice(0, CATEGORY_COUNT);
  if (categories.length === 0) return null;
  return (
    <Section
      id="home-categories"
      eyebrow="Learning categories"
      title="Explore by subject"
      action={
        <LinkButton to="/categories" iconEnd={<ArrowRight size={16} />}>
          All categories
        </LinkButton>
      }
    >
      <ul className={styles.categoryGrid}>
        {categories.map(({ category, count }) => (
          <li key={category.id}>
            <Link to={`/courses?category=${category.id}`} className={styles.categoryCard}>
              <CategoryGlyph glyph={category.glyph} size={40} />
              <h3>{category.name}</h3>
              <p>{plural(count, 'course')}</p>
            </Link>
          </li>
        ))}
      </ul>
    </Section>
  );
}

function CoursesSection({ status, data, featured }: { status: string; data?: HomeData; featured: Course[] }) {
  return (
    <Section
      id="home-featured"
      eyebrow="Popular courses"
      title="Courses learners start with"
      action={
        <LinkButton to="/courses" iconEnd={<ArrowRight size={16} />}>
          View all courses
        </LinkButton>
      }
    >
      {status === 'error' && !data ? (
        <p className={styles.sectionIntro}>
          The courses didn’t load. <Link to="/courses">Open the catalogue</Link> to try again.
        </p>
      ) : !data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : featured.length === 0 ? (
        <p className={styles.sectionIntro}>New courses are on their way. Create an account and we will have you ready when they open.</p>
      ) : (
        <ul className={site.courseGrid}>
          {featured.map((c) => (
            <PublicCourseCard key={c.id} course={c} instructors={data.instructors} showActions />
          ))}
        </ul>
      )}
    </Section>
  );
}

function MentorsSection({ mentors }: { mentors: PublicMentor[] }) {
  return (
    <Section
      id="home-mentors"
      eyebrow="Our mentors"
      title="Learn from expert mentors"
      action={
        <LinkButton to="/mentors" iconEnd={<ArrowRight size={16} />}>
          Meet all mentors
        </LinkButton>
      }
    >
      <ul className={styles.mentorGrid}>
        {mentors.slice(0, MENTOR_COUNT).map((m) => (
          <MentorCard key={m.id} mentor={m} />
        ))}
      </ul>
    </Section>
  );
}

function WhySection() {
  return (
    <Section id="home-why" eyebrow="Why ZuviloAI" title="Built for learning you finish">
      <ul className={styles.whyGrid}>
        {HOME_WHY.map((f) => (
          <li key={f.title}>
            <IconChip tone="accent" size="lg">
              <f.icon size={22} aria-hidden="true" />
            </IconChip>
            <h3>{f.title}</h3>
            <p>{f.text}</p>
          </li>
        ))}
      </ul>
    </Section>
  );
}

function HowSection() {
  return (
    <Section id="how-it-works" eyebrow="How it works" title="From browsing to learning, in four steps">
      <ol className={styles.steps}>
        {HOME_STEPS.map((s, i) => (
          <li key={s.title}>
            <span className={styles.stepNumber} aria-hidden="true">
              {i + 1}
            </span>
            <h3>{s.title}</h3>
            <p>{s.text}</p>
          </li>
        ))}
      </ol>
    </Section>
  );
}

function TeachSection() {
  return (
    <section className={styles.split} aria-labelledby="home-teach">
      <div>
        <p className={styles.eyebrow}>Become an instructor</p>
        <h2 id="home-teach">Share your knowledge. Inspire the next generation.</h2>
        <p className={styles.sectionIntro}>
          Apply to teach on ZuviloAI. Our team reviews each application, and approved instructors build and run their courses here.
        </p>
        <ol className={styles.miniSteps}>
          {INSTRUCTOR_STEPS.map((s) => (
            <li key={s.title}>
              <strong>{s.title}</strong> {s.text}
            </li>
          ))}
        </ol>
        <LinkButton to="/become-an-instructor" variant="primary" iconEnd={<ArrowRight size={16} />}>
          Become an instructor
        </LinkButton>
      </div>
      <ul className={styles.splitList}>
        {INSTRUCTOR_POINTS.map((p) => (
          <li key={p.title}>
            <p.icon size={22} aria-hidden="true" />
            <div>
              <h3>{p.title}</h3>
              <p>{p.text}</p>
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}

function AffiliateSection({ title, text }: { title: string; text: string }) {
  return (
    <section className={`${styles.split} ${styles.splitInk}`} aria-labelledby="home-affiliate" data-surface="ink">
      <div>
        <p className={styles.eyebrow}>Affiliate program</p>
        <h2 id="home-affiliate">{title}</h2>
        <p className={styles.sectionIntro}>{text}</p>
        <LinkButton to="/affiliate-program" variant="primary" iconEnd={<ArrowRight size={16} />}>
          Explore the affiliate program
        </LinkButton>
        <p className={styles.fineNote}>Any income depends on verified sales and the plan rules. It is never guaranteed.</p>
      </div>
      <ol className={styles.affiliateSteps}>
        {AFFILIATE_POINTS.map((p, i) => (
          <li key={p}>
            <span aria-hidden="true">{i + 1}</span>
            {p}
          </li>
        ))}
      </ol>
    </section>
  );
}

function StoriesSection({ stories }: { stories: SiteContent['testimonials'] }) {
  return (
    <Section id="home-testimonials" eyebrow="Student stories" title="What learners say">
      <ul className={styles.stories}>
        {stories.map((t) => {
          const src = siteImageSrc(t.imageUrl);
          return (
            <li key={`${t.name}:${t.quote.slice(0, 20)}`}>
              <figure>
                <blockquote>{t.quote}</blockquote>
                <figcaption>
                  {src && <img src={src} alt="" width={44} height={44} loading="lazy" />}
                  <span>
                    <strong>{t.name}</strong>
                    {t.role}
                  </span>
                </figcaption>
                {t.videoUrl && (
                  <a href={t.videoUrl} target="_blank" rel="noopener noreferrer" className={styles.storyVideo}>
                    <PlayCircle size={18} aria-hidden="true" /> Watch {t.name.split(' ')[0]}’s story
                  </a>
                )}
              </figure>
            </li>
          );
        })}
      </ul>
    </Section>
  );
}

function ResourcesSection({ posts }: { posts: BlogPost[] }) {
  return (
    <Section
      id="home-resources"
      eyebrow="Resources and community"
      title="Keep learning between courses"
      action={
        <LinkButton to="/blog" iconEnd={<ArrowRight size={16} />}>
          All resources
        </LinkButton>
      }
    >
      <ul className={styles.postGrid}>
        {posts.map((p) => (
          <PostCard key={p.id} post={p} />
        ))}
      </ul>
    </Section>
  );
}

export function PostCard({ post, headingLevel: Heading = 'h3' }: { post: BlogPost; headingLevel?: 'h2' | 'h3' }) {
  const src = siteImageSrc(post.coverUrl);
  return (
    <li className={styles.postCard}>
      {src && <img src={src} alt="" loading="lazy" />}
      <div>
        <span className={styles.postKind}>{BLOG_KIND_LABELS[post.kind]}</span>
        <Heading>
          <Link to={`/blog/${post.slug}`}>{post.title}</Link>
        </Heading>
        {post.excerpt && <p>{post.excerpt}</p>}
      </div>
    </li>
  );
}

function FaqSection({ content }: { content: SiteContent }) {
  return (
    <section className={styles.faq} aria-labelledby="home-faq">
      <div>
        <p className={styles.eyebrow}>FAQ</p>
        <h2 id="home-faq">Questions learners ask first</h2>
        <p className={styles.sectionIntro}>
          Something else? Read the <Link to="/faq">full FAQ</Link>, <Link to="/contact">contact us</Link> or write to{' '}
          <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>.
        </p>
      </div>
      <FaqList faqs={content.faqs.slice(0, 7)} />
    </section>
  );
}

function FinalCta() {
  return (
    <section className={styles.finalCta} aria-labelledby="home-cta" data-surface="ink">
      <h2 id="home-cta">Your learning journey starts here</h2>
      <p>Browse the catalogue without an account, and create one when you are ready to start.</p>
      <div className={styles.heroActions}>
        <LinkButton to="/courses" variant="primary" size="lg" iconEnd={<ArrowRight size={18} />}>
          Explore courses
        </LinkButton>
        <Link to="/register" className={styles.heroSecondary}>
          Create your account
        </Link>
      </div>
    </section>
  );
}
