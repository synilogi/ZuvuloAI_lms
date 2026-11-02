/*
 * The public website's editable words (docs/16 §2.6, D-PLAT-13; docs/17). The Super Admin edits one document; the site reads
 * it without signing in. Testimonials start empty on purpose: a quote has to come from a real person. Figures, courses,
 * bundles and mentors are never written here: they are read from the platform's own records.
 */

/** The home page's sections that can be moved or hidden. The hero comes first and the footer last, always. */
export const HOME_SECTIONS = [
  'stats',
  'bundles',
  'categories',
  'courses',
  'mentors',
  'why',
  'how',
  'teach',
  'affiliate',
  'testimonials',
  'resources',
  'faq',
  'cta',
] as const;
export type HomeSectionId = (typeof HOME_SECTIONS)[number];

export const HOME_SECTION_LABELS: Record<HomeSectionId, string> = {
  stats: 'Platform figures',
  bundles: 'Course bundles',
  categories: 'Learning categories',
  courses: 'Popular courses',
  mentors: 'Expert mentors',
  why: 'Why learn with us',
  how: 'How it works',
  teach: 'Become an instructor',
  affiliate: 'Affiliate program',
  testimonials: 'Student stories',
  resources: 'Resources and community',
  faq: 'Questions',
  cta: 'Final call to action',
};

export interface SiteSection {
  id: HomeSectionId;
  visible: boolean;
}

/** Whether a piece of content is live: not switched off, and past its publish date when it has one. */
export interface SiteScheduled {
  /** Absent counts as published: a document saved before this field existed keeps showing what it showed. */
  published?: boolean;
  /** ISO date and time. Hidden until then. */
  publishAt?: string;
}

export interface SiteTestimonial extends SiteScheduled {
  quote: string;
  name: string;
  /** What the person did here, such as the course they took. */
  role: string;
  /** A website image of the person, shown only with their permission. */
  imageUrl?: string;
  /** A video of the person telling it themselves. */
  videoUrl?: string;
}

export interface SiteFaq {
  q: string;
  a: string;
}

export interface SiteBanner extends SiteScheduled {
  title: string;
  text: string;
  imageUrl?: string;
  linkLabel?: string;
  /** A page of this site (`/courses`) or a full https address. */
  linkTo?: string;
  /** ISO date and time. Hidden from then on. */
  endsAt?: string;
}

export const SITE_SOCIAL_PLATFORMS = ['youtube', 'instagram', 'facebook', 'linkedin', 'x', 'whatsapp', 'telegram'] as const;
export type SiteSocialPlatform = (typeof SITE_SOCIAL_PLATFORMS)[number];

export interface SiteSocialLink {
  platform: SiteSocialPlatform;
  url: string;
}

/** The figures on the home page. Each can be hidden; none can be typed in. */
export interface SiteStatsVisibility {
  learners: boolean;
  courses: boolean;
  instructors: boolean;
  learningHours: boolean;
}

export interface SiteContent {
  heroEyebrow: string;
  heroTitle: string;
  heroText: string;
  /** A website image beside the headline. Empty: the covers of the featured courses are shown instead. */
  heroImageUrl: string;
  /** The bundle the hero features. Empty: the first featured bundle, or the first featured course. */
  heroBundleId: string;
  /** Courses shown first on the home page, in this order. Empty: the most popular published courses. */
  featuredCourseIds: string[];
  /** Bundles shown first, in this order. Empty: the published bundles in their own order. */
  featuredBundleIds: string[];
  /** Mentors shown first, in this order. Empty: those teaching the most courses. */
  featuredMentorIds: string[];
  sections: SiteSection[];
  stats: SiteStatsVisibility;
  testimonials: SiteTestimonial[];
  banners: SiteBanner[];
  faqs: SiteFaq[];
  affiliateTitle: string;
  affiliateText: string;
  footerAbout: string;
  socials: SiteSocialLink[];
  seoTitle: string;
  seoDescription: string;
  seoImageUrl: string;
}

export const SITE_LIMITS = {
  heroEyebrow: 60,
  heroTitle: 120,
  heroText: 320,
  featured: 12,
  testimonials: 12,
  banners: 6,
  faqs: 30,
  quote: 500,
  name: 80,
  role: 120,
  q: 200,
  a: 1200,
  bannerTitle: 120,
  bannerText: 300,
  linkLabel: 40,
  link: 300,
  affiliateTitle: 120,
  affiliateText: 500,
  footerAbout: 400,
  socials: 7,
  seoTitle: 70,
  seoDescription: 170,
} as const;

/** Where a website image is served from, the only image address the document accepts. */
export const SITE_IMAGE_PATTERN = /^\/public\/images\/[a-z0-9]{10,40}$/;

export const DEFAULT_SITE_CONTENT: SiteContent = {
  heroEyebrow: 'Learn new skills. Build your future.',
  heroTitle: 'Build skills that move your career forward',
  heroText:
    'Practical courses and bundles from experienced instructors, with video lessons, assignments, live classes and certificates you can verify online. Preview a course, and start when you are ready.',
  heroImageUrl: '',
  heroBundleId: '',
  featuredCourseIds: [],
  featuredBundleIds: [],
  featuredMentorIds: [],
  sections: HOME_SECTIONS.map((id) => ({ id, visible: true })),
  stats: { learners: true, courses: true, instructors: true, learningHours: true },
  testimonials: [],
  banners: [],
  faqs: [
    {
      q: 'How do I join?',
      a: 'Choose Sign up, enter your name, email and phone, and confirm the code we email you. Browsing courses needs no account.',
    },
    {
      q: 'How do I buy a course?',
      a: 'Open the course, choose Buy now and create an account or sign in. You pay through our payment gateway, and the course opens as soon as the gateway confirms the payment.',
    },
    {
      q: 'How do I reach a course I bought?',
      a: 'Sign in and open My learning. Every course you have bought or joined is there, and picks up where you stopped.',
    },
    {
      q: 'Can I see a course before paying?',
      a: 'Every course page shows the full outline, the instructor and the price. Lessons an instructor has marked as a free preview can be read without buying.',
    },
    {
      q: 'Do you have free courses?',
      a: 'Some courses are free. Use the Free filter on the Explore page, then enrol with one click once you have an account.',
    },
    {
      q: 'What is a course bundle?',
      a: 'Several courses sold together at one price. Each course opens in My learning as soon as the payment is confirmed. Coupons apply to single courses, not bundles.',
    },
    {
      q: 'Do I get a certificate?',
      a: 'Courses that award a certificate say so on their page. Each certificate has an ID that anyone can check on our Verify page.',
    },
    {
      q: 'Can I get a refund?',
      a: 'Our refund policy explains when a course payment is refunded. A refund covers the whole order and ends access to what it bought.',
    },
    {
      q: 'How do I become an instructor?',
      a: 'Send an application from the Become an Instructor page. Our team reviews it, and you can start building courses once it is approved.',
    },
    {
      q: 'What is the affiliate program?',
      a: 'It is an optional program for people who want to recommend courses. The Affiliate Program page sets out how it works. Any income depends on verified sales and the plan rules, and it is never guaranteed.',
    },
  ],
  affiliateTitle: 'Recommend courses you believe in',
  affiliateText:
    'Learn with us, then join the optional affiliate program for your own referral link. Track verified sales, eligible commissions, your network and rewards in one place, under published rules. Read them before deciding whether it suits you.',
  footerAbout: 'Online courses with lessons, assessments, live classes and certificates you can verify.',
  socials: [],
  seoTitle: '',
  seoDescription: '',
  seoImageUrl: '',
};

/** The sections in the saved order, with any the document does not know yet added at the end, shown. */
export function orderedSections(saved: readonly SiteSection[] | undefined): SiteSection[] {
  const known = (saved ?? []).filter((s, i, all) => HOME_SECTIONS.includes(s.id) && all.findIndex((x) => x.id === s.id) === i);
  return [...known, ...HOME_SECTIONS.filter((id) => !known.some((s) => s.id === id)).map((id) => ({ id, visible: true }))];
}

/** Whether a scheduled piece of content shows at `now`. */
export function isLive(item: SiteScheduled & { endsAt?: string }, now: Date): boolean {
  if (item.published === false) return false;
  if (item.publishAt && Date.parse(item.publishAt) > now.getTime()) return false;
  if (item.endsAt && Date.parse(item.endsAt) <= now.getTime()) return false;
  return true;
}

/** Figures counted from the platform's records, for the home page. */
export interface PublicStats {
  learners: number;
  courses: number;
  instructors: number;
  learningHours: number;
}

/** A mentor as a visitor sees them: never an email, phone or account detail. */
export interface PublicMentor {
  id: string;
  name: string;
  title: string;
  bio: string;
  expertise: string[];
  yearsTeaching?: number;
  city?: string;
  languages: string[];
  photoUrl?: string;
  courseCount: number;
  learnerCount: number;
}

export const BLOG_KINDS = ['article', 'resource', 'webinar', 'workshop', 'community', 'career'] as const;
export type BlogKind = (typeof BLOG_KINDS)[number];

export const BLOG_KIND_LABELS: Record<BlogKind, string> = {
  article: 'Blog',
  resource: 'Free resource',
  webinar: 'Webinar',
  workshop: 'Live workshop',
  community: 'Community',
  career: 'Career guidance',
};

export const BLOG_LIMITS = { title: 140, excerpt: 300, body: 50_000, link: 300 } as const;

export interface BlogPost {
  id: string;
  slug: string;
  kind: BlogKind;
  title: string;
  excerpt: string;
  body: string;
  coverUrl: string;
  externalUrl: string;
  eventAt?: string;
  status: 'draft' | 'published';
  publishAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface BlogPostInput {
  kind: BlogKind;
  title: string;
  excerpt: string;
  body: string;
  coverUrl: string;
  externalUrl: string;
  eventAt?: string | null;
  status: 'draft' | 'published';
  publishAt?: string | null;
}

/** One course in a bundle, as the website shows it. */
export interface BundleCourse {
  id: string;
  slug: string;
  title: string;
  subtitle: string;
  coverMotif: string;
  coverImageUrl?: string;
  durationMin: number;
  /** What the course sells for alone, in whole rupees; null for a free or unpriced course. */
  price: number | null;
}

export interface PublicBundle {
  id: string;
  slug: string;
  title: string;
  summary: string;
  description: string;
  coverUrl: string;
  /** Whole rupees, all-inclusive. */
  price: number;
  /** What the courses cost one by one, in whole rupees. Shown struck through only when above `price`. */
  separatePrice: number;
  courseCount: number;
  durationMin: number;
  courses: BundleCourse[];
}

export interface AdminBundle extends PublicBundle {
  status: 'draft' | 'published' | 'archived';
  publishAt?: string;
  order: number;
  courseIds: string[];
  /** Orders ever made: a bundle with any is archived rather than deleted. */
  orderCount: number;
}

export interface BundleInput {
  title: string;
  summary: string;
  description: string;
  coverUrl: string;
  price: number;
  courseIds: string[];
  status: 'draft' | 'published' | 'archived';
  publishAt?: string | null;
  order: number;
}

export const BUNDLE_LIMITS = { title: 120, summary: 240, description: 5000, minCourses: 2, maxCourses: 30, maxPrice: 1_000_000 } as const;

export interface BundlePurchaseView {
  id: string;
  orderNumber: string;
  bundleId: string;
  bundleSlug: string;
  bundleTitle: string;
  /** 'failed' is an open order whose last attempt was declined: it can be paid again. */
  status: 'created' | 'paid' | 'failed' | 'expired';
  amount: number;
  currency: 'INR';
  /** Every course the order bought is open to the learner now. */
  enrolled: boolean;
  failureMessage?: string;
  needsReview?: boolean;
  refundedAt?: string;
}

/**
 * Shares `total` across `weights` in whole units, in proportion, so the shares always add up to exactly `total`: a bundle's
 * charge split across its courses. What rounding leaves over goes to the largest remainders, the earliest first. All-zero
 * weights share equally.
 */
export function allocateByWeight(total: number, weights: readonly number[]): number[] {
  if (weights.length === 0) return [];
  const all = weights.reduce((sum, w) => sum + w, 0);
  const used = all > 0 ? weights : weights.map(() => 1);
  const sum = all > 0 ? all : weights.length;
  const exact = used.map((w) => (total * w) / sum);
  const shares = exact.map(Math.floor);
  const left = total - shares.reduce((n, s) => n + s, 0);
  const byRemainder = exact.map((e, i) => ({ i, r: e - Math.floor(e) })).sort((a, b) => b.r - a.r || a.i - b.i);
  for (let k = 0; k < left; k++) shares[byRemainder[k].i] += 1;
  return shares;
}

/** The affiliate program's published terms (MLM-000): read from the active plan, never written into a page. */
export interface PublicAffiliateRank {
  order: number;
  name: string;
  /** Minor units of lifetime group CV, half from each leg. */
  groupCv: number;
  rewardKind: 'recognition' | 'certificate' | 'cash';
  rewardAmount: number;
  rewardCapAmount: number | null;
  /** The most matching income this rank can receive in a day, in minor units. */
  dailyCap: number;
}

export interface PublicAffiliateProgram {
  /** False when no plan is active: the page explains the idea and publishes no terms. */
  active: boolean;
  course: { slug: string; title: string; priceAmount: number | null; currency: string } | null;
  currency: string;
  matchingRateBps: number;
  withdrawalMinAmount: number;
  withdrawalRequiresKyc: boolean;
  ranks: PublicAffiliateRank[];
}

/** The first part of an address the website counts visits to. Sign-in workspaces are never counted. */
export const COUNTED_PAGES = [
  'courses',
  'categories',
  'bundles',
  'mentors',
  'blog',
  'about',
  'faq',
  'contact',
  'login',
  'register',
  'become-an-instructor',
  'affiliate-program',
] as const;

/** The path to count for an address, without its query, or null when it is not a page of the public website. */
export function countedPath(pathname: string): string | null {
  const path = pathname.length > 1 ? pathname.replace(/\/+$/, '') : pathname;
  if (path.length > 180 || !/^\/[A-Za-z0-9/_-]*$/.test(path)) return null;
  if (path === '/' || path === '/welcome') return '/';
  return (COUNTED_PAGES as readonly string[]).includes(path.split('/')[1]) ? path : null;
}

export interface VisitorFunnelStep {
  label: string;
  count: number;
}

export interface VisitorReport {
  days: number;
  from: string;
  to: string;
  /** Page views a day, oldest first. A day with none is listed as zero. */
  daily: { day: string; views: number }[];
  topPages: { path: string; views: number }[];
  funnel: VisitorFunnelStep[];
}

/** What share of the step before each step reached it, as a whole percentage. The first step has none. */
export function funnelRates(steps: readonly VisitorFunnelStep[]): (number | null)[] {
  return steps.map((step, i) => (i === 0 ? null : steps[i - 1].count > 0 ? Math.round((step.count / steps[i - 1].count) * 100) : null));
}
