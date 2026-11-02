import { listPublicBundles } from './bundles.js';
import { observe } from './observe.js';
import { listPublicPosts } from './sitePublic.js';
import { db } from './db.js';
import { workspaceId } from './requestContext.js';
import { runInTenant } from './tenancy.js';

/*
 * The public website's sitemap, built from what is published right now. Served by the production single process
 * (web.ts); search engines read it rarely, so a short memory cache is all the database ever sees of them.
 */

const SITE = 'https://zuviloai.com';
const CACHE_MS = 10 * 60_000;

export interface SitemapEntry {
  path: string;
  changefreq?: 'daily' | 'weekly' | 'monthly' | 'yearly';
  priority?: number;
  lastmod?: Date;
}

const STATIC_PAGES: SitemapEntry[] = [
  { path: '/', changefreq: 'weekly', priority: 1.0 },
  { path: '/courses', changefreq: 'daily', priority: 0.9 },
  { path: '/categories', changefreq: 'weekly', priority: 0.8 },
  { path: '/bundles', changefreq: 'weekly', priority: 0.8 },
  { path: '/mentors', changefreq: 'weekly', priority: 0.7 },
  { path: '/blog', changefreq: 'weekly', priority: 0.6 },
  { path: '/become-an-instructor', changefreq: 'monthly', priority: 0.7 },
  { path: '/teach/apply', changefreq: 'monthly', priority: 0.6 },
  { path: '/affiliate-program', changefreq: 'monthly', priority: 0.6 },
  { path: '/about', changefreq: 'yearly', priority: 0.5 },
  { path: '/faq', changefreq: 'monthly', priority: 0.6 },
  { path: '/contact', changefreq: 'yearly', priority: 0.6 },
  { path: '/register', changefreq: 'monthly', priority: 0.7 },
  { path: '/support', changefreq: 'weekly', priority: 0.5 },
  { path: '/verify', changefreq: 'yearly', priority: 0.4 },
  { path: '/privacy', changefreq: 'yearly', priority: 0.3 },
  { path: '/terms', changefreq: 'yearly', priority: 0.3 },
  { path: '/refunds', changefreq: 'yearly', priority: 0.3 },
];

/** Published public courses and help articles. Unlisted and draft courses stay out. */
export async function loadSitemapEntries(): Promise<SitemapEntry[]> {
  const [courses, articles, bundles, posts] = await runInTenant(await workspaceId(), () =>
    Promise.all([
      db.course.findMany({ where: { status: 'published', visibility: 'public' }, select: { slug: true, updatedAt: true } }),
      db.helpArticle.findMany({ select: { slug: true, updatedAt: true } }),
      listPublicBundles(),
      listPublicPosts(),
    ]),
  );
  return [
    ...courses.map((c) => ({ path: `/courses/${encodeURIComponent(c.slug)}`, changefreq: 'weekly' as const, priority: 0.8, lastmod: c.updatedAt })),
    ...articles.map((a) => ({ path: `/support/article/${encodeURIComponent(a.slug)}`, changefreq: 'monthly' as const, priority: 0.4, lastmod: a.updatedAt })),
    ...bundles.map((b) => ({ path: `/bundles/${encodeURIComponent(b.slug)}`, changefreq: 'weekly' as const, priority: 0.8 })),
    ...posts.map((p) => ({ path: `/blog/${encodeURIComponent(p.slug)}`, changefreq: 'monthly' as const, priority: 0.5, lastmod: new Date(p.updatedAt) })),
  ];
}

const escapeXml = (text: string) => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');

export function renderSitemap(dynamic: SitemapEntry[]): string {
  const urls = [...STATIC_PAGES, ...dynamic].map((e) => {
    const parts = [`<loc>${escapeXml(`${SITE}${e.path}`)}</loc>`];
    if (e.lastmod) parts.push(`<lastmod>${e.lastmod.toISOString().slice(0, 10)}</lastmod>`);
    if (e.changefreq) parts.push(`<changefreq>${e.changefreq}</changefreq>`);
    if (e.priority !== undefined) parts.push(`<priority>${e.priority.toFixed(1)}</priority>`);
    return `  <url>${parts.join('')}</url>`;
  });
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.join('\n')}\n</urlset>\n`;
}

/**
 * The sitemap's text, rebuilt at most every ten minutes. If the data can't be read, the static pages still answer and
 * the next request tries again, rather than a crawler being told the site's pages are gone.
 */
export function sitemapCache(load: () => Promise<SitemapEntry[]> = loadSitemapEntries, now: () => number = Date.now) {
  let cached: { xml: string; until: number } | undefined;
  let building: Promise<string> | undefined;
  return (): Promise<string> => {
    if (cached && cached.until > now()) return Promise.resolve(cached.xml);
    building ??= load()
      .then(
        (entries) => {
          const xml = renderSitemap(entries);
          cached = { xml, until: now() + CACHE_MS };
          return xml;
        },
        (error) => {
          observe('job.failed', { job: 'sitemap', error: error instanceof Error ? error.message : String(error) });
          return cached?.xml ?? renderSitemap([]);
        },
      )
      .finally(() => {
        building = undefined;
      });
    return building;
  };
}
