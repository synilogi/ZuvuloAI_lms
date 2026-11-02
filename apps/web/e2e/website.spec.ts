import { test, expect, type Page } from '@playwright/test';
import { signIn } from './helpers';

/*
 * The public website (docs/16 §2.6), live against the API: every page renders with one heading and a clean console on desktop
 * and phone, the navigation is the brief's, the SaaS pages are gone, the catalogue filters work, and a message reaches the
 * Super Admin's inbox.
 */

const PAGES: [string, RegExp][] = [
  ['/', /./],
  ['/courses', /Explore courses/],
  ['/categories', /Browse courses by category/],
  ['/become-an-instructor', /Become an instructor/],
  ['/affiliate-program', /How the affiliate program works/],
  ['/about', /One place to learn/],
  ['/faq', /Frequently asked questions/],
  ['/contact', /Contact us/],
  ['/privacy', /Privacy policy/],
  ['/terms', /Terms of service/],
  ['/refunds', /Refund policy/],
  ['/register', /Start learning/],
  ['/teach/apply', /Teach on/],
  ['/login', /Sign in/],
];

const SHOTS = process.env.SCREENSHOT_DIR;

function watch(page: Page) {
  const errors: string[] = [];
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  page.on('pageerror', (e) => errors.push(e.message));
  return errors;
}

for (const viewport of [
  { name: 'desktop', width: 1366, height: 900 },
  { name: 'phone', width: 390, height: 844 },
]) {
  test(`every website page renders cleanly on ${viewport.name}`, async ({ page }) => {
    test.setTimeout(90_000);
    await page.setViewportSize(viewport);
    const errors = watch(page);
    for (const [path, heading] of PAGES) {
      await page.goto(path);
      await expect(page.getByRole('heading', { level: 1, name: heading })).toBeVisible();
      await expect(page.getByRole('heading', { level: 1 })).toHaveCount(1);
      const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
      expect(overflow, `${path} scrolls sideways on ${viewport.name}`).toBeLessThanOrEqual(1);
      if (SHOTS) await page.screenshot({ path: `${SHOTS}/${viewport.name}${path.replace(/[/?=]/g, '_') || '_home'}.png`, fullPage: true });
    }
    expect(errors).toEqual([]);
  });
}

test('the navigation is the platform’s, and no page sells software to institutions', async ({ page }) => {
  await page.setViewportSize({ width: 1366, height: 900 });
  await page.goto('/');
  const site = page.getByRole('navigation', { name: 'Site', exact: true });
  for (const label of ['Home', 'Explore Courses', 'Categories', 'Become an Instructor', 'Affiliate Program', 'About', 'Contact']) {
    await expect(site.getByRole('link', { name: label, exact: true })).toBeVisible();
  }
  await expect(page.getByRole('link', { name: 'Login', exact: true }).first()).toBeVisible();
  await expect(page.getByRole('link', { name: 'Sign up', exact: true }).first()).toBeVisible();
  for (const [path] of PAGES) {
    await page.goto(path);
    await expect(page.locator('body')).not.toContainText(/\bLMS\b|free trial|book a demo|schools and coaching/i);
  }
});

test('the old SaaS addresses forward and never show a plan', async ({ page }) => {
  for (const [from, to] of [
    ['/pricing', /\/welcome$/],
    ['/features', /\/welcome$/],
    ['/solutions', /\/welcome$/],
    ['/get-started', /\/register$/],
    ['/join', /\/register$/],
    ['/join/default', /\/register$/],
    ['/join/default/teach', /\/teach\/apply$/],
  ] as const) {
    await page.goto(from);
    await expect(page).toHaveURL(to);
  }
  await page.goto('/join/default?ref=ABC123&leg=B');
  await expect(page).toHaveURL(/\/register\?.*ref=ABC123/);
});

test('the phone menu opens, lists the site and closes on navigation', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  const menu = page.getByRole('navigation', { name: 'Site menu' });
  await expect(menu).toBeHidden();
  await page.getByRole('button', { name: 'Open menu' }).click();
  await expect(menu).toBeVisible();
  await menu.getByRole('link', { name: 'Explore Courses' }).click();
  await expect(page).toHaveURL(/\/courses$/);
  await expect(menu).toBeHidden();
});

test('a visitor explores: search and price filters narrow the list, and a course opens with its price and a way to buy', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('searchbox', { name: 'Search courses' }).fill('Board Exam');
  await page.getByRole('button', { name: 'Search', exact: true }).click();
  await expect(page).toHaveURL(/\/courses\?q=Board/);
  await expect(page.getByRole('link', { name: 'Class 10 Science: Board Exam Sprint' })).toBeVisible();

  await page.goto('/courses?price=free');
  await expect(page.getByRole('link', { name: 'Class 10 Science: Board Exam Sprint' })).toHaveCount(0);
  await page.goto('/courses?price=paid');
  const link = page.getByRole('link', { name: 'Class 10 Science: Board Exam Sprint' });
  await expect(link).toBeVisible();
  await link.click();

  await expect(page.getByRole('heading', { level: 1, name: 'Class 10 Science: Board Exam Sprint' })).toBeVisible();
  await expect(page.getByText('₹1,499').first()).toBeVisible();
  await page.getByRole('link', { name: 'Buy now' }).first().click();
  await expect(page).toHaveURL(/\/login\?next=%2Flearn%2F/);
});

test('the affiliate page publishes the plan’s terms and promises no income', async ({ page }) => {
  await page.goto('/affiliate-program');
  await expect(page.getByText('Joining this program does not guarantee any income.')).toBeVisible();
  await expect(page.locator('body')).not.toContainText(/passive income|financial freedom|earn up to|get rich/i);
});

test('a message reaches the Super Admin’s inbox and is moved along', async ({ page }) => {
  const stamp = Date.now();
  const message = `A question about the science course ${stamp}.`;
  await page.goto('/contact');
  await page.getByRole('button', { name: 'Send message' }).click();
  await expect(page.getByText('Fix these before sending')).toBeVisible();

  await page.getByRole('textbox', { name: 'Your name' }).fill('Lakshmi Iyer');
  await page.getByRole('textbox', { name: 'Email' }).fill(`lead-${stamp}@example.test`);
  await page.getByRole('textbox', { name: 'How can we help?' }).fill(message);
  await page.getByRole('button', { name: 'Send message' }).click();
  await expect(page.getByText('Thanks — we’ve got your message')).toBeVisible();

  await signIn(page, 'e2e-superadmin@syniastrolms.test', /Platform overview/i);
  await page.goto('/superadmin/inquiries');
  await expect(page.getByRole('heading', { level: 1, name: 'Inbox' })).toBeVisible();
  await page.getByRole('searchbox', { name: 'Search the inbox' }).fill(String(stamp));
  const row = page.getByRole('row').filter({ hasText: 'Lakshmi Iyer' });
  await expect(row).toContainText('General');
  await expect(row).toContainText('New');
  await row.getByRole('button', { name: /Lakshmi Iyer/ }).click();

  const panel = page.getByRole('dialog', { name: 'Lakshmi Iyer' });
  await expect(panel.getByText(message)).toBeVisible();
  await panel.getByRole('combobox', { name: 'Status' }).selectOption('in_progress');
  await panel.getByRole('button', { name: 'Save' }).click();
  await expect(row).toContainText(/In progress/i);
});

test('the Super Admin edits the home page, and a visitor sees it', async ({ page, browser }) => {
  const title = `Learning that fits your week ${Date.now()}`;
  await signIn(page, 'e2e-superadmin@syniastrolms.test', /Platform overview/i);
  await page.goto('/superadmin/website');
  await page.getByRole('textbox', { name: 'Headline', exact: true }).fill(title);
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByText('The website is updated')).toBeVisible();

  const visitor = await (await browser.newContext()).newPage();
  await visitor.goto('/');
  await expect(visitor.getByRole('heading', { level: 1, name: title })).toBeVisible();
  await visitor.context().close();
});
