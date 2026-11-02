import { DEFAULT_SITE_CONTENT, type BundleInput } from '@syniastrolms/domain';
import { describe, expect, it } from 'vitest';
import { bundleIssue } from '@/pages/superadmin/site/BundlesPage';
import { postIssue } from '@/pages/superadmin/site/PostsPage';
import { fromLocalInput, toLocalInput } from '@/pages/superadmin/site/siteFields';
import { siteContentIssues } from '@/pages/superadmin/site/WebsitePage';
import { courseReturnPath, recallCheckout, rememberCheckout } from '@/pages/learn/purchaseFlow';
import { chosenFirst, shownStats } from './LandingPage';
import { AFFILIATE_POINTS, HOME_STEPS, HOME_WHY } from './siteContent';

/* The marketplace's rules (docs/17): what the home page may show, and what the Super Admin may save. */

const INCOME_CLAIM = /passive income|financial freedom|earn up to|earn ₹|guaranteed (income|returns|earnings)|get rich|make money/i;

describe('the home page’s figures', () => {
  const stats = { learners: 12, courses: 3, instructors: 0, learningHours: 40 };
  const all = { learners: true, courses: true, instructors: true, learningHours: true };

  it('shows the real numbers and hides a zero', () => {
    expect(shownStats(stats, all)).toEqual([
      { label: 'Learners', value: 12 },
      { label: 'Courses', value: 3 },
      { label: 'Hours of learning', value: 40 },
    ]);
  });

  it('hides one the Super Admin turned off', () => {
    expect(shownStats(stats, { ...all, learners: false }).map((s) => s.label)).toEqual(['Courses', 'Hours of learning']);
  });
});

describe('featured picks', () => {
  it('come first in their order, the rest follow, and something withdrawn drops out', () => {
    const items = [{ id: 'a' }, { id: 'b' }, { id: 'c' }];
    expect(chosenFirst(items, ['c', 'gone', 'a']).map((x) => x.id)).toEqual(['c', 'a', 'b']);
  });
});

describe('the home page’s fixed words', () => {
  it('make no income claim, and the document’s default makes none', () => {
    const words = [
      ...HOME_WHY.flatMap((f) => [f.title, f.text]),
      ...HOME_STEPS.flatMap((s) => [s.title, s.text]),
      ...AFFILIATE_POINTS,
      DEFAULT_SITE_CONTENT.affiliateTitle,
      DEFAULT_SITE_CONTENT.affiliateText,
    ];
    expect(words.filter((w) => INCOME_CLAIM.test(w))).toEqual([]);
  });
});

describe('saving a bundle', () => {
  const ok: BundleInput = {
    title: 'Two courses',
    summary: '',
    description: '',
    coverUrl: '',
    price: 999,
    courseIds: ['a', 'b'],
    status: 'published',
    publishAt: null,
    order: 0,
  };

  it('needs a name, a whole price and, to publish, two courses', () => {
    expect(bundleIssue(ok)).toBeUndefined();
    expect(bundleIssue({ ...ok, title: ' ' })).toMatch(/name/);
    expect(bundleIssue({ ...ok, price: 0 })).toMatch(/price/);
    expect(bundleIssue({ ...ok, price: 9.5 })).toMatch(/price/);
    expect(bundleIssue({ ...ok, courseIds: ['a'] })).toMatch(/two courses/);
    expect(bundleIssue({ ...ok, status: 'draft', courseIds: [] })).toBeUndefined();
  });
});

describe('saving a post', () => {
  const ok = { kind: 'article', title: 'A post', excerpt: '', body: 'Text.', coverUrl: '', externalUrl: '', status: 'published' } as const;

  it('needs a title, an https link if any, and something to read when published', () => {
    expect(postIssue(ok)).toBeUndefined();
    expect(postIssue({ ...ok, title: '' })).toMatch(/title/);
    expect(postIssue({ ...ok, externalUrl: 'javascript:alert(1)' })).toMatch(/https/);
    expect(postIssue({ ...ok, body: '' })).toMatch(/text or a link/);
    expect(postIssue({ ...ok, body: '', status: 'draft' })).toBeUndefined();
  });
});

describe('saving the website document', () => {
  it('accepts the defaults', () => {
    expect(siteContentIssues(DEFAULT_SITE_CONTENT)).toEqual({});
  });

  it('refuses a link that could run code, wherever a link is kept', () => {
    const banner = { title: 'A banner', text: '', linkTo: 'javascript:alert(1)' };
    expect(siteContentIssues({ ...DEFAULT_SITE_CONTENT, banners: [banner] })['site-banner-link-0']).toBeDefined();
    expect(siteContentIssues({ ...DEFAULT_SITE_CONTENT, banners: [{ ...banner, linkTo: '/courses' }] })).toEqual({});
    expect(siteContentIssues({ ...DEFAULT_SITE_CONTENT, socials: [{ platform: 'x', url: 'http://x.example' }] })['site-social-0']).toBeDefined();
    const story = { quote: 'A real quote.', name: 'A Learner', role: '', videoUrl: 'data:text/html,x' };
    expect(siteContentIssues({ ...DEFAULT_SITE_CONTENT, testimonials: [story] })['site-quote-video-0']).toBeDefined();
  });
});

describe('dates in the admin forms', () => {
  it('round-trips, and treats empty as none', () => {
    const iso = '2026-11-02T06:30:00.000Z';
    expect(fromLocalInput(toLocalInput(iso))).toBe(iso);
    expect(toLocalInput(undefined)).toBe('');
    expect(fromLocalInput('')).toBeUndefined();
  });
});

describe('coming back from a hosted checkout', () => {
  const memory = () => {
    const held = new Map<string, string>();
    return {
      getItem: (k: string) => held.get(k) ?? null,
      setItem: (k: string, v: string) => void held.set(k, v),
      removeItem: (k: string) => void held.delete(k),
    };
  };

  it('returns a bundle’s order to the bundle’s page, and a course’s to the course', () => {
    const store = memory();
    rememberCheckout('o1', { purchaseId: 'p1', courseId: 'b1', path: '/bundles/two' }, store);
    expect(courseReturnPath(recallCheckout('o1', store)!, 'paid')).toBe('/bundles/two?purchase=p1&checkout=paid');
    expect(courseReturnPath({ purchaseId: 'p2', courseId: 'c1' }, 'failed')).toBe('/learn/c1?purchase=p2&checkout=failed');
  });

  it('ignores a remembered path that leaves the site', () => {
    const store = memory();
    store.setItem('syniastrolms:course-checkout:o2', JSON.stringify({ purchaseId: 'p', courseId: 'c', path: 'https://evil.example' }));
    expect(recallCheckout('o2', store)).toEqual({ purchaseId: 'p', courseId: 'c' });
  });
});
