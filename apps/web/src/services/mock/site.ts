import { DEFAULT_SITE_CONTENT, slugify, type AdminBundle, type BlogPost, type PublicMentor, type SiteContent } from '@syniastrolms/domain';
import { ServiceError, type SiteService } from '../contracts';
import { courses, instructors } from './fixtures/catalog';
import { respond } from './simulation';

let stored: SiteContent = DEFAULT_SITE_CONTENT;
let bundles: AdminBundle[] = [];
let posts: BlogPost[] = [];

const NOT_IN_DEMO = () => new ServiceError('The demo build takes no payments.', 'unknown');
const missing = (what: string) => new ServiceError(`This ${what} isn’t available.`, 'not-found');

const mentorsOf = (): PublicMentor[] =>
  instructors
    .filter((i) => i.status === 'active')
    .map((i) => {
      const taught = courses.filter((c) => c.instructorIds.includes(i.id));
      return {
        id: i.id,
        name: i.name,
        title: i.title,
        bio: i.bio,
        expertise: i.expertise,
        languages: i.languages,
        courseCount: taught.length,
        learnerCount: taught.reduce((n, c) => n + c.enrolledCount, 0),
      };
    })
    .filter((m) => m.courseCount > 0);

const toBundle = (id: string, input: Parameters<SiteService['createBundle']>[0], orderCount = 0): AdminBundle => ({
  id,
  slug: slugify(input.title),
  title: input.title,
  summary: input.summary,
  description: input.description,
  coverUrl: input.coverUrl,
  price: input.price,
  separatePrice: 0,
  courseCount: input.courseIds.length,
  durationMin: 0,
  courses: [],
  status: input.status,
  order: input.order,
  courseIds: input.courseIds,
  orderCount,
  onSale: input.status === 'published',
});

const toPost = (id: string, input: Parameters<SiteService['createPost']>[0]): BlogPost => ({
  id,
  slug: slugify(input.title),
  kind: input.kind,
  title: input.title,
  excerpt: input.excerpt,
  body: input.body,
  coverUrl: input.coverUrl,
  externalUrl: input.externalUrl,
  status: input.status,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
});

/**
 * The demo build's website: the contact form accepts and stores nothing (the page says so), no plan is in force, and bundles and
 * posts live only until the page reloads. Nothing can be paid for here.
 */
export const siteService: SiteService = {
  contact: () => respond(() => undefined, 700),
  content: () => respond(() => stored),
  affiliateProgram: () =>
    respond(() => ({ active: false, course: null, currency: 'INR', matchingRateBps: 0, withdrawalMinAmount: 0, withdrawalRequiresKyc: true, ranks: [] })),
  adminContent: () => respond(() => stored),
  saveContent: (input) =>
    respond(() => {
      stored = input;
      return stored;
    }),
  stats: () =>
    respond(() => ({ learners: courses.reduce((n, c) => n + c.enrolledCount, 0), courses: courses.length, instructors: mentorsOf().length, learningHours: 0 })),
  mentors: () => respond(mentorsOf),
  mentor: (id) =>
    respond(() => {
      const mentor = mentorsOf().find((m) => m.id === id);
      if (!mentor) throw missing('mentor');
      return { mentor, courseSlugs: courses.filter((c) => c.instructorIds.includes(id)).map((c) => c.slug) };
    }),
  bundles: () => respond(() => bundles.filter((b) => b.status === 'published')),
  bundle: (slug) =>
    respond(() => {
      const found = bundles.find((b) => b.slug === slug && b.status === 'published');
      if (!found) throw missing('bundle');
      return found;
    }),
  posts: (kind) => respond(() => posts.filter((p) => p.status === 'published' && (!kind || p.kind === kind))),
  post: (slug) =>
    respond(() => {
      const found = posts.find((p) => p.slug === slug && p.status === 'published');
      if (!found) throw missing('post');
      return found;
    }),
  quoteBundle: () =>
    respond(() => {
      throw NOT_IN_DEMO();
    }),
  startBundlePurchase: () =>
    respond(() => {
      throw NOT_IN_DEMO();
    }),
  confirmBundlePurchase: () =>
    respond(() => {
      throw NOT_IN_DEMO();
    }),
  getBundlePurchase: () =>
    respond(() => {
      throw NOT_IN_DEMO();
    }),
  adminBundles: () => respond(() => bundles),
  createBundle: (input) =>
    respond(() => {
      const created = toBundle(`mock-bundle-${bundles.length + 1}`, input);
      bundles = [...bundles, created];
      return created;
    }),
  updateBundle: (id, input) =>
    respond(() => {
      const updated = toBundle(id, input);
      bundles = bundles.map((b) => (b.id === id ? updated : b));
      return updated;
    }),
  deleteBundle: (id) =>
    respond(() => {
      bundles = bundles.filter((b) => b.id !== id);
    }),
  adminPosts: () => respond(() => posts),
  createPost: (input) =>
    respond(() => {
      const created = toPost(`mock-post-${posts.length + 1}`, input);
      posts = [created, ...posts];
      return created;
    }),
  updatePost: (id, input) =>
    respond(() => {
      const updated = toPost(id, input);
      posts = posts.map((p) => (p.id === id ? updated : p));
      return updated;
    }),
  deletePost: (id) =>
    respond(() => {
      posts = posts.filter((p) => p.id !== id);
    }),
  visitors: (days) => respond(() => ({ days, from: '', to: '', daily: [], topPages: [], funnel: [] })),
  placeImage: (mediaId) => respond(() => ({ url: `/public/images/${mediaId}` })),
};
