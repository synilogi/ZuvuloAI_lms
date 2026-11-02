import { describe, expect, it } from 'vitest';
import { contactIssues, contactPayload, emptyContact, topicFrom } from './contactForm';
import { DEFAULT_SITE_CONTENT } from '@syniastrolms/domain';
import { BENEFITS, HOW_IT_WORKS, INSTRUCTOR_POINTS, WHY_LEARN } from './siteContent';
import { AFFILIATE_DISCLOSURE, rewardLabel } from './AffiliateProgramPage';
import { featuredCourses } from './LandingPage';
import { matchesPrice, sortCourses } from './ExploreCoursesPage';
import type { Course } from '@syniastrolms/domain';

/* The website: the contact form's rules and the words every page carries. */

describe('the contact form', () => {
  it('opens on the topic in the address, a general question otherwise', () => {
    expect(topicFrom(new URLSearchParams('topic=sales'))).toBe('sales');
    expect(topicFrom(new URLSearchParams('topic=refund'))).toBe('demo');
  });

  it('needs a name, an email and a real message, and a phone made of phone characters', () => {
    expect(Object.keys(contactIssues(emptyContact('demo'))).sort()).toEqual(['email', 'message', 'name']);
    const ok = { ...emptyContact('sales'), name: 'Lakshmi', email: 'l@school.in', message: 'We have 300 learners.' };
    expect(contactIssues(ok)).toEqual({});
    expect(contactIssues({ ...ok, phone: '<script>' }).phone).toBeDefined();
  });

  it('sends trimmed values and leaves empty optional fields out', () => {
    const payload = contactPayload({
      ...emptyContact('support'),
      name: ' Lakshmi ',
      email: 'l@school.in ',
      message: ' Help with invoices please ',
      phone: '  ',
    });
    expect(payload).toEqual({
      kind: 'support',
      name: 'Lakshmi',
      email: 'l@school.in',
      message: 'Help with invoices please',
      phone: undefined,
    });
  });
});

const INCOME_CLAIM = /passive income|financial freedom|earn up to|earn ₹|guaranteed (income|returns|earnings)|get rich|make money|per month income/i;
const SAAS_WORDS = /\bLMS\b|academy|subscription|free trial|schools? and coaching/i;
const course = (over: Partial<Course>) => ({ id: 'c', pricing: 'paid', enrolledCount: 0, ...over }) as Course;

describe('the website’s words', () => {
  const words = [
    ...[...WHY_LEARN, ...BENEFITS, ...HOW_IT_WORKS, ...INSTRUCTOR_POINTS].flatMap((f) => [f.title, f.text]),
    ...DEFAULT_SITE_CONTENT.faqs.flatMap((f) => [f.q, f.a]),
    DEFAULT_SITE_CONTENT.heroTitle,
    DEFAULT_SITE_CONTENT.heroText,
    ...AFFILIATE_DISCLOSURE,
  ];

  it('makes no income claim and says that income is not guaranteed (D-PLAT-13)', () => {
    expect(words.filter((w) => INCOME_CLAIM.test(w))).toEqual([]);
    expect(AFFILIATE_DISCLOSURE.join(' ')).toMatch(/does not guarantee any income/);
  });

  it('no longer sells software to institutions', () => {
    expect(words.filter((w) => SAAS_WORDS.test(w))).toEqual([]);
  });

  it('ships no invented testimonials', () => {
    expect(DEFAULT_SITE_CONTENT.testimonials).toEqual([]);
  });
});

describe('the catalogue', () => {
  const free = course({ id: 'free', pricing: 'free' });
  const cheap = course({ id: 'cheap', price: { amount: 500, currency: 'INR' }, enrolledCount: 9 } as Partial<Course>);
  const dear = course({ id: 'dear', price: { amount: 10000, currency: 'INR' }, enrolledCount: 1 } as Partial<Course>);

  it('filters by price', () => {
    expect(matchesPrice(free, 'free')).toBe(true);
    expect(matchesPrice(cheap, 'free')).toBe(false);
    expect(matchesPrice(cheap, 'under-1000')).toBe(true);
    expect(matchesPrice(dear, 'under-1000')).toBe(false);
    expect(matchesPrice(dear, 'over-5000')).toBe(true);
    expect(matchesPrice(free, 'paid')).toBe(false);
  });

  it('sorts by price both ways', () => {
    expect(sortCourses([dear, free, cheap], 'price-low').map((c) => c.id)).toEqual(['free', 'cheap', 'dear']);
    expect(sortCourses([free, cheap, dear], 'price-high').map((c) => c.id)).toEqual(['dear', 'cheap', 'free']);
  });

  it('puts the Super Admin’s choice first, then the most popular, and ignores unpublished ids', () => {
    expect(featuredCourses([free, cheap, dear], ['dear', 'gone']).map((c) => c.id)).toEqual(['dear', 'cheap', 'free']);
  });

  it('names a rank’s reward without promising more than the plan says', () => {
    expect(rewardLabel({ rewardKind: 'recognition', rewardAmount: 0, rewardCapAmount: null }, 'INR')).toBe('Recognition');
    expect(rewardLabel({ rewardKind: 'cash', rewardAmount: 0, rewardCapAmount: 100000 }, 'INR')).toMatch(/^Up to /);
  });
});
