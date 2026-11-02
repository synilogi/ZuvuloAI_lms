/*
 * The document title, canonical link, description and Open Graph tags for each page of the company website, set as
 * the route changes — the SPA serves one index.html, so without this every page would carry the same ones. Pages
 * behind sign-in keep the product name and get no canonical (robots.txt keeps them out of search).
 */

const SITE = 'https://zuviloai.com';
const PRODUCT = 'ZuviloAI';
const HOME_TITLE = 'ZuviloAI — Online courses with verifiable certificates';
const DEFAULT_DESCRIPTION =
  'Online courses with lessons, live classes, tests and certificates anyone can verify. See the outline, the instructor and the price before you sign up.';

interface PageText {
  title: string;
  description: string;
}

const HOME: PageText = { title: HOME_TITLE, description: DEFAULT_DESCRIPTION };

const PUBLIC_PAGES: Record<string, PageText> = {
  '/': HOME,
  '/welcome': HOME,
  '/courses': {
    title: 'Explore courses',
    description: 'Browse ZuviloAI’s online courses. See what each one covers, who teaches it and what it costs before you sign up.',
  },
  '/bundles': {
    title: 'Course bundles',
    description: 'Several ZuviloAI courses sold together at one price. See what each bundle includes and what it costs.',
  },
  '/mentors': {
    title: 'Our mentors',
    description: 'Meet the instructors who teach on ZuviloAI and see the courses each of them offers.',
  },
  '/blog': {
    title: 'Blog and resources',
    description: 'Articles, free resources, webinars, live workshops and career guidance from ZuviloAI.',
  },
  '/categories': {
    title: 'Course categories',
    description: 'Find a ZuviloAI course by subject, and see what each category covers.',
  },
  '/become-an-instructor': {
    title: 'Become an instructor',
    description: 'Teach on ZuviloAI: how to apply, how courses are reviewed and what the platform handles for you.',
  },
  '/affiliate-program': {
    title: 'Affiliate program',
    description: 'How the ZuviloAI affiliate program works: who can join, how referrals are recorded and the rules that apply.',
  },
  '/about': {
    title: 'About',
    description: 'ZuviloAI is an online course platform based in Kota, India.',
  },
  '/faq': {
    title: 'Frequently asked questions',
    description: 'Answers to common questions about buying ZuviloAI courses, learning on the platform, certificates and refunds.',
  },
  '/contact': {
    title: 'Contact us',
    description: 'Ask the ZuviloAI team a question about a course, a payment or your account.',
  },
  '/login': {
    title: 'Log in',
    description: 'Sign in to ZuviloAI to continue your courses, classes and certificates.',
  },
  '/register': {
    title: 'Create your account',
    description: 'Create a ZuviloAI account to enrol in courses, join live classes and earn certificates you can verify.',
  },
  '/teach/apply': {
    title: 'Apply to teach',
    description: 'Apply to teach on ZuviloAI. Tell us about yourself and the courses you would like to run.',
  },
  '/support': {
    title: 'Help Centre',
    description: 'Guides and answers for learning on ZuviloAI: your account, payments, courses and certificates.',
  },
  '/verify': {
    title: 'Verify a certificate',
    description: 'Check that a ZuviloAI certificate is genuine using the credential ID printed on it.',
  },
  '/privacy': {
    title: 'Privacy Policy',
    description: 'What personal data ZuviloAI collects, why it is used, and the choices you have.',
  },
  '/terms': {
    title: 'Terms of Service',
    description: 'The terms that apply when you use ZuviloAI and buy its courses.',
  },
  '/refunds': {
    title: 'Refund Policy',
    description: 'When a ZuviloAI course purchase can be refunded, and how to ask for a refund.',
  },
  '/delete-account': {
    title: 'Delete your account',
    description: 'How to delete your ZuviloAI account, and what happens to your data when you do.',
  },
};

/** Public pages whose address carries an id. Their own content loads later; these words stand for the kind of page. */
const PUBLIC_PATTERNS: [RegExp, PageText][] = [
  [/^\/bundles\/[^/]+$/, { title: 'Course bundle', description: 'What this ZuviloAI course bundle includes and what it costs.' }],
  [/^\/mentors\/[^/]+$/, { title: 'Mentor', description: 'A ZuviloAI instructor and the courses they offer.' }],
  [/^\/blog\/[^/]+$/, { title: 'Blog and resources', description: 'An article or resource from ZuviloAI.' }],
  [/^\/support\/article\/[^/]+$/, { title: 'Help article', description: 'A step-by-step answer from the ZuviloAI Help Centre.' }],
  [/^\/support\/[^/]+$/, { title: 'Help topic', description: 'Guides on this topic from the ZuviloAI Help Centre.' }],
  [
    /^\/verify\/[^/]+$/,
    { title: 'Certificate verification', description: 'The verification record of a ZuviloAI certificate: who earned it, for which course, and its status.' },
  ],
];

/** The canonical path of a page: `/welcome` is the home page under another name. */
const canonicalOf = (path: string) => (path === '/welcome' ? '/' : path);

const fullTitle = (title: string) => (title.startsWith(PRODUCT) ? title : `${title} · ${PRODUCT}`);

/** A description of a sensible length for a search result, on one line. */
export function metaDescription(text: string | undefined, max = 160): string {
  const line = (text ?? '').replace(/\s+/g, ' ').trim();
  if (!line) return DEFAULT_DESCRIPTION;
  return line.length <= max ? line : `${line.slice(0, max - 1).trimEnd()}…`;
}

function setMeta(doc: Document, attribute: 'name' | 'property', key: string, content: string) {
  let tag = doc.head.querySelector<HTMLMetaElement>(`meta[${attribute}="${key}"]`);
  if (!tag) {
    tag = doc.createElement('meta');
    tag.setAttribute(attribute, key);
    doc.head.appendChild(tag);
  }
  tag.setAttribute('content', content);
}

/**
 * Writes a page's tags. `path` is its canonical address; without one (a page behind sign-in) there is no canonical
 * link and the shared tags describe the site.
 */
export function setPageMeta(
  { title, description, path, image }: { title: string; description: string; path?: string; image?: string },
  doc: Document = document,
) {
  doc.title = title;
  if (image) setMeta(doc, 'property', 'og:image', image);
  setMeta(doc, 'name', 'description', description);
  setMeta(doc, 'property', 'og:title', title);
  setMeta(doc, 'property', 'og:description', description);
  setMeta(doc, 'property', 'og:url', `${SITE}${path ?? '/'}`);

  let link = doc.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
  if (!path) {
    link?.remove();
    return;
  }
  if (!link) {
    link = doc.createElement('link');
    link.rel = 'canonical';
    doc.head.appendChild(link);
  }
  link.href = `${SITE}${path}`;
}

export function applyPageMeta(pathname: string, doc: Document = document) {
  const path = pathname.length > 1 ? pathname.replace(/\/+$/, '') : pathname;
  const page = PUBLIC_PAGES[path] ?? PUBLIC_PATTERNS.find(([pattern]) => pattern.test(path))?.[1];
  if (!page) {
    setPageMeta({ title: PRODUCT, description: DEFAULT_DESCRIPTION }, doc);
    return;
  }
  setPageMeta({ title: fullTitle(page.title), description: page.description, path: canonicalOf(path) }, doc);
}
