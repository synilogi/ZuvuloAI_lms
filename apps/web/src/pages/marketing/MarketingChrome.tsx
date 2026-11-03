import { useEffect, useId, useState, type ReactNode } from 'react';
import { Link, NavLink, useLocation } from 'react-router-dom';
import {
  ArrowLeft,
  BookOpenText,
  Certificate,
  Exam,
  Eye,
  FacebookLogo,
  InstagramLogo,
  LinkedinLogo,
  List,
  LockKey,
  TelegramLogo,
  VideoCamera,
  WhatsappLogo,
  X,
  XLogo,
  YoutubeLogo,
  type Icon,
} from '@phosphor-icons/react';
import { DEFAULT_SITE_CONTENT, type SiteSocialPlatform } from '@syniastrolms/domain';
import { BrandLogo, type BrandLogoVariant } from '@/branding/BrandLogo';
import { BRAND_NAME } from '@/branding/defaults';
import { LinkButton } from '@/components/ui/Button/Button';
import { useAsync } from '@/hooks/useAsync';
import { API_MODE } from '@/lib/apiMode';
import { homeFor } from '@/lib/roleHome';
import { useSession } from '@/providers/SessionProvider';
import { services } from '@/services';
import { ExploreMenu } from './MegaMenu';
import { COMPANY, COMPANY_ADDRESS, SUPPORT_EMAIL } from './siteContent';
import styles from './Marketing.module.css';

/*
 * The public website's frame (docs/16 §2.6): one platform selling its own courses. Home, the catalogue, teaching,
 * the affiliate program and the company's pages, with sign-in and sign-up always in reach.
 */

const NAV_LINKS = [
  { label: 'Home', to: '/' },
  { label: 'Explore Courses', to: '/courses' },
  { label: 'Course Bundles', to: '/bundles' },
  { label: 'Our Mentors', to: '/mentors' },
  { label: 'Become an Instructor', to: '/become-an-instructor' },
  { label: 'Affiliate Program', to: '/affiliate-program' },
  { label: 'About Us', to: '/about' },
];

const SOCIAL_ICONS: Record<SiteSocialPlatform, { icon: Icon; label: string }> = {
  youtube: { icon: YoutubeLogo, label: 'YouTube' },
  instagram: { icon: InstagramLogo, label: 'Instagram' },
  facebook: { icon: FacebookLogo, label: 'Facebook' },
  linkedin: { icon: LinkedinLogo, label: 'LinkedIn' },
  x: { icon: XLogo, label: 'X' },
  whatsapp: { icon: WhatsappLogo, label: 'WhatsApp' },
  telegram: { icon: TelegramLogo, label: 'Telegram' },
};

const FOOTER_COLUMNS = [
  {
    title: 'Learn',
    links: [
      { label: 'Explore courses', to: '/courses' },
      { label: 'Categories', to: '/categories' },
      { label: 'Course bundles', to: '/bundles' },
      { label: 'Our mentors', to: '/mentors' },
      { label: 'Verify a certificate', to: '/verify' },
      { label: 'Create an account', to: '/register' },
      { label: 'Log in', to: '/login' },
    ],
  },
  {
    title: 'Get involved',
    links: [
      { label: 'Become an instructor', to: '/become-an-instructor' },
      { label: 'Affiliate program', to: '/affiliate-program' },
    ],
  },
  {
    title: 'Company',
    links: [
      { label: 'About us', to: '/about' },
      { label: 'Blog and resources', to: '/blog' },
      { label: 'FAQ', to: '/faq' },
      { label: 'Help Centre', to: '/support' },
      { label: 'Contact', to: '/contact' },
    ],
  },
  {
    title: 'Legal',
    links: [
      { label: 'Privacy policy', to: '/privacy' },
      { label: 'Terms of service', to: '/terms' },
      { label: 'Refund policy', to: '/refunds' },
      { label: 'Delete account', to: '/delete-account' },
    ],
  },
];

/** The platform's logo as a link home: the lockup in the header and footer, the full logo on the sign-in panel. */
function Wordmark({ className, variant = 'lockup' }: { className?: string; variant?: BrandLogoVariant }) {
  return (
    <Link to="/" className={className ?? styles.wordmark} aria-label={`${BRAND_NAME} home`}>
      <BrandLogo variant={variant} alt="" />
    </Link>
  );
}

export function MarketingHeader() {
  const [open, setOpen] = useState(false);
  const menuId = useId();
  const location = useLocation();
  const { isAuthenticated, role } = useSession();
  // The demo build always has a persona; only a real account has somewhere to go back to.
  const signedIn = API_MODE === 'http' && isAuthenticated;
  // A link followed from the menu closes it.
  useEffect(() => setOpen(false), [location.pathname, location.search, location.hash]);

  return (
    <header className={styles.header}>
      <div className={styles.headerInner}>
        <Wordmark />
        <nav className={styles.headerNav} aria-label="Site">
          {NAV_LINKS.map((l) =>
            l.to === '/courses' ? (
              <ExploreMenu key={l.to} pathKey={`${location.pathname}${location.search}`} />
            ) : (
              <NavLink key={l.to} to={l.to} end={l.to === '/'} className={({ isActive }) => (isActive ? styles.navActive : undefined)}>
                {l.label}
              </NavLink>
            ),
          )}
        </nav>
        <div className={styles.headerActions}>
          {signedIn ? (
            <LinkButton to={homeFor(role)} variant="primary" size="sm" className={styles.headerCta}>
              My dashboard
            </LinkButton>
          ) : (
            <>
              <LinkButton to="/login" variant="secondary" size="sm">
                Login
              </LinkButton>
              <LinkButton to="/register" variant="primary" size="sm" className={styles.headerCta}>
                Sign up
              </LinkButton>
            </>
          )}
          <button type="button" className={styles.menuButton} aria-expanded={open} aria-controls={menuId} onClick={() => setOpen((v) => !v)}>
            {open ? <X size={20} aria-hidden="true" /> : <List size={20} aria-hidden="true" />}
            <span className="sr-only">{open ? 'Close menu' : 'Open menu'}</span>
          </button>
        </div>
      </div>
      <nav id={menuId} className={styles.mobileMenu} hidden={!open} aria-label="Site menu">
        {NAV_LINKS.map((l) => (
          <Link key={l.to} to={l.to}>
            {l.label}
          </Link>
        ))}
        <Link to="/categories">Categories</Link>
        <Link to="/blog">Blog and resources</Link>
        <Link to="/contact">Contact</Link>
        {signedIn ? (
          <LinkButton to={homeFor(role)} variant="primary" block>
            My dashboard
          </LinkButton>
        ) : (
          <>
            <Link to="/login">Login</Link>
            <LinkButton to="/register" variant="primary" block>
              Sign up
            </LinkButton>
          </>
        )}
      </nav>
    </header>
  );
}

export function MarketingFooter() {
  // The footer's own words and links are the Super Admin's; it reads fine with the defaults until they load.
  const content = useAsync('site:content', () => services.site.content().catch(() => DEFAULT_SITE_CONTENT)).data ?? DEFAULT_SITE_CONTENT;
  return (
    <footer className={styles.footer}>
      <div className={styles.footerInner}>
        <div className={styles.footerBrand}>
          <Wordmark />
          <p>{content.footerAbout}</p>
          <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>
          {content.socials.length > 0 && (
            <ul className={styles.footerSocials} aria-label="Follow us">
              {content.socials.map((s) => {
                const { icon: SocialIcon, label } = SOCIAL_ICONS[s.platform];
                return (
                  <li key={s.platform}>
                    <a href={s.url} target="_blank" rel="noopener noreferrer" aria-label={label}>
                      <SocialIcon size={20} aria-hidden="true" />
                    </a>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
        <div className={styles.footerCols}>
          {FOOTER_COLUMNS.map((col) => (
            <div key={col.title} className={styles.footerCol}>
              <h2>{col.title}</h2>
              {col.links.map((l) => (
                <Link key={l.to} to={l.to}>
                  {l.label}
                </Link>
              ))}
            </div>
          ))}
        </div>
      </div>
      <div className={styles.footerBottom}>
        <span>
          © {new Date().getFullYear()} {COMPANY.name}, {COMPANY_ADDRESS}.
        </span>
        <span>
          <a href={COMPANY.phoneHref}>{COMPANY.phone}</a> · Made in India. Prices in INR.
        </span>
      </div>
    </footer>
  );
}

/** The query a page is opened with from the mobile app, to be shown inside it (`?embed=app`). */
const EMBED_PARAM = 'embed';
const EMBED_KEY = 'zuviloai:embed';

/**
 * Whether this visit is the mobile app showing a page inside itself. Remembered for the tab, so a link
 * between two embeddable pages (privacy ↔ terms) stays embedded although it carries no query.
 */
function useEmbeddedInApp(): boolean {
  const { search } = useLocation();
  const asked = new URLSearchParams(search).get(EMBED_PARAM) === 'app';
  try {
    if (asked) sessionStorage.setItem(EMBED_KEY, '1');
    return asked || sessionStorage.getItem(EMBED_KEY) === '1';
  } catch {
    return asked;
  }
}

/**
 * Public site chrome — header, content, footer. An `embeddable` page (the policies) opened from the mobile
 * app (`?embed=app`) is shown without them: the app supplies its own title bar.
 */
export function MarketingChrome({
  children,
  embeddable = false,
  canvas = 'aurora',
}: {
  children: ReactNode;
  embeddable?: boolean;
  /** `aurora` (the website's default): a light page with soft glows of the brand hues behind it. `plain` is the flat page colour. */
  canvas?: 'plain' | 'aurora';
}) {
  const embedded = useEmbeddedInApp() && embeddable;
  if (embedded) {
    return (
      <main className={styles.main} id="main">
        {children}
      </main>
    );
  }
  return (
    <div className={canvas === 'aurora' ? `${styles.chrome} ${styles.chromeAurora}` : styles.chrome}>
      <a href="#main" className="skip-link">
        Skip to content
      </a>
      <MarketingHeader />
      <main className={styles.main} id="main">
        {children}
      </main>
      <MarketingFooter />
    </div>
  );
}

const VALUE_PROPS = [
  { icon: Eye, text: 'See the outline, the instructor and the price before you sign up.' },
  { icon: LockKey, text: 'A course opens only once the payment gateway confirms your payment.' },
  { icon: Certificate, text: 'Certificates carry an ID that anyone can check online.' },
];

/** What a course can include, shown as quiet chips under the panel's headline. */
const MODULES = [
  { icon: BookOpenText, label: 'Lessons' },
  { icon: VideoCamera, label: 'Live classes' },
  { icon: Exam, label: 'Tests & quizzes' },
  { icon: Certificate, label: 'Certificates' },
];

/** Split layout for sign in and registration — the form on a clean surface beside a brand panel on the ink ground. */
export function AuthChrome({ eyebrow, children }: { eyebrow: string; children: ReactNode }) {
  return (
    <div className={styles.authShell}>
      <a href="#main" className="skip-link">
        Skip to content
      </a>
      <main id="main" className={styles.authMain}>
        <div className={styles.authTop}>
          <Wordmark className={styles.authBrand} />
          <Link to="/" className={styles.authHome}>
            <ArrowLeft size={14} aria-hidden="true" />
            Back to website
          </Link>
        </div>
        <div className={styles.authCard}>{children}</div>
        <p className={styles.authLegal}>
          © {new Date().getFullYear()} {BRAND_NAME} · <Link to="/privacy">Privacy</Link> · <Link to="/terms">Terms</Link> ·{' '}
          <Link to="/contact?topic=support">Support</Link>
        </p>
      </main>
      <aside className={styles.authPanel} data-surface="ink">
        <div className={styles.authPanelBody}>
          <p className={styles.authEyebrow}>{eyebrow}</p>
          <p className={styles.authHeadline}>Lessons, live classes, tests and certificates, all in one place.</p>
          <ul className={styles.authModules} aria-label="What a course can include">
            {MODULES.map(({ icon: Icon, label }) => (
              <li key={label}>
                <Icon size={15} weight="duotone" aria-hidden="true" />
                {label}
              </li>
            ))}
          </ul>
          <ul className={styles.authValueList}>
            {VALUE_PROPS.map(({ icon: Icon, text }) => (
              <li key={text}>
                <span className={styles.authValueIcon}>
                  <Icon size={18} weight="duotone" aria-hidden="true" />
                </span>
                <span>{text}</span>
              </li>
            ))}
          </ul>
        </div>
        {/* True of the demo build only. Against the real API these are real credentials and the account is real, so the note would be a lie. */}
        {API_MODE === 'mock' && <p className={styles.authPanelFoot}>Demo build — this screen shows sample data only; nothing you enter here is stored.</p>}
      </aside>
    </div>
  );
}
