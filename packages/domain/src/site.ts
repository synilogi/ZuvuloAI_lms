/*
 * The public website's editable words (docs/16 §2.6, D-PLAT-13). The Super Admin edits one document; the site reads it
 * without signing in. Testimonials start empty on purpose: a quote has to come from a real person.
 */

export interface SiteTestimonial {
  quote: string;
  name: string;
  /** What the person did here, such as the course they took. */
  role: string;
}

export interface SiteFaq {
  q: string;
  a: string;
}

export interface SiteContent {
  heroTitle: string;
  heroText: string;
  /** Courses shown first on the home page, in this order. Empty: the most popular published courses. */
  featuredCourseIds: string[];
  testimonials: SiteTestimonial[];
  faqs: SiteFaq[];
}

export const SITE_LIMITS = {
  heroTitle: 120,
  heroText: 320,
  featured: 12,
  testimonials: 12,
  faqs: 30,
  quote: 500,
  name: 80,
  role: 120,
  q: 200,
  a: 1200,
} as const;

export const DEFAULT_SITE_CONTENT: SiteContent = {
  heroTitle: 'Learn practical skills, one course at a time',
  heroText:
    'Video lessons, quizzes, assignments, live classes and certificates you can verify online. Browse the catalogue, preview a course, and start when you are ready.',
  featuredCourseIds: [],
  testimonials: [],
  faqs: [
    {
      q: 'How do I buy a course?',
      a: 'Open the course, choose Buy now and create an account or sign in. You pay through our payment gateway, and the course opens as soon as the gateway confirms the payment.',
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
      q: 'Do I get a certificate?',
      a: 'Courses that award a certificate say so on their page. Each certificate has an ID that anyone can check on our Verify page.',
    },
    {
      q: 'Can I get a refund?',
      a: 'Our refund policy explains when a course payment is refunded. A refund covers the whole order and ends access to the course.',
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
};

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
