import { test, expect, type Page } from '@playwright/test';
import { ADMIN_EMAIL, INSTRUCTOR_EMAIL, freshEmail, registerOnSite, signIn } from './helpers';

/*
 * Every page people reach from a sidebar opens in a real browser: one heading, no crash, no failed call, nothing wider than the
 * screen. Added after the 1 Nov 2026 audit, because type checks cannot see a page that renders nothing or calls a missing route.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';

const OWNER = [
  '/superadmin',
  '/superadmin/sales/orders',
  '/superadmin/sales/coupons',
  '/superadmin/sales/events',
  '/superadmin/affiliates/overview',
  '/superadmin/affiliates/members',
  '/superadmin/affiliates/network',
  '/superadmin/affiliates/sponsors',
  '/superadmin/affiliates/placements',
  '/superadmin/affiliates/orders',
  '/superadmin/affiliates/ledgers',
  '/superadmin/affiliates/ledgers?view=carry-forward',
  '/superadmin/affiliates/matching',
  '/superadmin/affiliates/ranks',
  '/superadmin/affiliates/rewards',
  '/superadmin/affiliates/wallets',
  '/superadmin/affiliates/withdrawals',
  '/superadmin/affiliates/withdrawals?view=payouts',
  '/superadmin/affiliates/kyc',
  '/superadmin/affiliates/products',
  '/superadmin/affiliates/plan',
  '/superadmin/audit?prefix=mlm.',
  '/superadmin/website',
  '/superadmin/notifications',
  '/superadmin/inquiries',
  '/superadmin/admins',
  '/superadmin/users',
];
const ADMIN = [
  '/admin',
  '/admin/courses',
  '/admin/students',
  '/admin/instructors',
  '/admin/reports',
  '/admin/reviews',
  '/admin/settings/general',
  '/admin/help',
];
const INSTRUCTOR = [
  '/teach',
  '/teach/courses',
  '/teach/course-sales',
  '/teach/reviews',
  '/teach/reports',
  '/teach/reports/courses',
  '/teach/students',
  '/teach/help',
];
const LEARNER = [
  '/explore',
  '/home',
  '/my-learning',
  '/purchases',
  '/certificates',
  '/affiliate',
  '/affiliate/tree',
  '/affiliate/team',
  '/affiliate/volume',
  '/affiliate/earnings',
  '/affiliate/wallet',
  '/affiliate/kyc',
  '/affiliate/orders',
];

async function walk(page: Page, paths: string[], allow: RegExp[] = []) {
  const problems: string[] = [];
  let at = '';
  const allowed = (text: string) => allow.some((re) => re.test(text));
  page.on('pageerror', (e) => problems.push(`${at}: ${e.message}`));
  page.on('response', (r) => {
    if (r.status() >= 500 || (r.status() === 404 && r.url().startsWith(API) && !allowed(r.url()))) problems.push(`${at}: ${r.status()} ${r.url()}`);
  });
  for (const path of paths) {
    at = path;
    await page.goto(path);
    await expect(page.getByRole('heading', { level: 1 }).first(), `${path} has a heading`).toBeVisible({ timeout: 20_000 });
    await expect(page.getByText('This page isn’t on the map'), `${path} is a real route`).toHaveCount(0);
    await page.waitForLoadState('networkidle');
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow, `${path} scrolls sideways`).toBeLessThanOrEqual(1);
  }
  expect(problems).toEqual([]);
}

test.describe.configure({ timeout: 240_000 });

test('every page of the Super Admin’s workspace opens', async ({ page }) => {
  await signIn(page, 'e2e-superadmin@syniastrolms.test', /Platform overview/i);
  await walk(page, OWNER);
});

test('every page of the staff admin’s workspace opens', async ({ page }) => {
  await signIn(page, ADMIN_EMAIL, /^Dashboard$/);
  await walk(page, ADMIN);
});

test('every page of the instructor’s workspace opens', async ({ page }) => {
  await signIn(page, INSTRUCTOR_EMAIL, /Teaching overview/i);
  await walk(page, INSTRUCTOR);
});

test('every page of the learner’s workspace opens, in and out of the affiliate program', async ({ page }) => {
  await registerOnSite(page, 'Walking Learner', freshEmail());
  // Outside the program the member’s own records answer not-found: each page must say so, not fail.
  await walk(page, LEARNER, [/\/affiliate/]);
  await page.goto('/affiliate/wallet');
  await expect(page.getByRole('link', { name: /affiliate|overview|join/i }).first()).toBeVisible();
});

test('the same workspaces fit a phone', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await signIn(page, 'e2e-superadmin@syniastrolms.test', /Platform overview/i);
  await walk(page, [
    '/superadmin/affiliates/overview',
    '/superadmin/affiliates/matching',
    '/superadmin/affiliates/withdrawals',
    '/superadmin/affiliates/ranks',
    '/superadmin/website',
    '/superadmin/notifications',
  ]);
});
