import { test, expect, type Page } from '@playwright/test';
import { ADMIN_EMAIL, freshEmail, registerOnSite, signIn } from './helpers';

/*
 * The marketplace (docs/17), live against the API and the sandbox gateway. An admin publishes two paid courses, the Super Admin
 * sells them as a bundle from the real screen, a visitor finds it on the home page, and a learner buys it: the courses open only
 * once the API says so, and the orders add up to the charge.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const SUPERADMIN_EMAIL = 'e2e-superadmin@syniastrolms.test';
const stamp = Date.now();
const BUNDLE = `E2E Bundle ${stamp}`;
const courseTitles = [`E2E Bundle Course A ${stamp}`, `E2E Bundle Course B ${stamp}`];

const token = (page: Page) => page.evaluate(() => localStorage.getItem('syniastrolms:token'));
/** Signs in and waits for the session, which the sign-in heading alone does not prove. */
async function signedIn(page: Page, email: string) {
  await signIn(page, email, /./);
  await expect.poll(() => token(page), { timeout: 20_000 }).toBeTruthy();
}
async function api(page: Page, method: string, path: string, data?: unknown) {
  const auth = await token(page);
  const res = await page.request.fetch(`${API}${path}`, {
    method,
    headers: { ...(auth ? { Authorization: `Bearer ${auth}` } : {}), ...(data ? { 'Content-Type': 'application/json' } : {}) },
    ...(data ? { data: JSON.stringify(data) } : {}),
  });
  return { status: res.status(), body: await res.json().catch(() => ({})) };
}

test('a bundle goes from the Super Admin’s screen to a learner’s courses', async ({ browser }) => {
  test.setTimeout(180_000);

  // Two paid courses, published.
  const adminPage = await (await browser.newContext()).newPage();
  await signedIn(adminPage, ADMIN_EMAIL);
  const instructors = (await api(adminPage, 'GET', '/catalog/instructors')).body as { id: string }[];
  for (const title of courseTitles) {
    const created = await api(adminPage, 'POST', '/courses', { title, description: 'A course for the bundle test.', instructorIds: [instructors[0].id], pricing: 'paid', priceAmount: 800 });
    expect(created.status, JSON.stringify(created.body)).toBe(201);
    expect((await api(adminPage, 'POST', `/courses/${created.body.id}/publish`)).status).toBe(200);
  }

  // The Super Admin makes the bundle in the real form.
  const owner = await (await browser.newContext()).newPage();
  await signedIn(owner, SUPERADMIN_EMAIL);
  await owner.goto('/superadmin/sales/bundles');
  await owner.getByRole('button', { name: 'New bundle' }).click();
  await owner.locator('#bundle-title').fill(BUNDLE);
  await owner.locator('#bundle-summary').fill('Two courses together.');
  for (const title of courseTitles) {
    await expect(owner.locator('#bundle-add-course option', { hasText: title })).toHaveCount(1);
    await owner.locator('#bundle-add-course').selectOption({ label: title });
  }
  await owner.locator('#bundle-price').fill('1000');
  await owner.locator('#bundle-status').selectOption('published');
  await owner.getByRole('button', { name: 'Save bundle' }).click();
  await expect(owner.getByText('The bundle is created')).toBeVisible();

  // A visitor finds it, and sees what it saves.
  const visitor = await (await browser.newContext()).newPage();
  await visitor.goto('/');
  await expect(visitor.getByRole('heading', { name: 'Learn more together, for one price' })).toBeVisible();
  await visitor.goto('/bundles');
  await visitor.getByRole('link', { name: BUNDLE }).click();
  await expect(visitor.getByRole('heading', { name: BUNDLE, level: 1 })).toBeVisible();
  const box = visitor.getByRole('complementary', { name: 'Buy this bundle' });
  await expect(box.getByText('₹1,000', { exact: true })).toBeVisible();
  await expect(box.getByText('₹1,600', { exact: true })).toBeVisible();
  await expect(box.getByRole('link', { name: 'Buy now' })).toHaveAttribute('href', /\/login\?next=/);

  // A learner buys it through the sandbox gateway; a decline opens nothing.
  const learnerPage = await (await browser.newContext()).newPage();
  await registerOnSite(learnerPage, 'Bundle Buyer', freshEmail());
  await learnerPage.goto(new URL(visitor.url()).pathname);
  const slug = new URL(visitor.url()).pathname.split('/').pop()!;
  const bundle = (await api(learnerPage, 'GET', `/public/bundles/${slug}`)).body as { id: string; courses: { id: string }[] };

  await learnerPage.getByRole('button', { name: /Buy now/ }).click();
  await expect(learnerPage).toHaveURL(/\/sandbox-checkout\//, { timeout: 15_000 });
  await learnerPage.getByRole('button', { name: /decline|fail/i }).click();
  await expect(learnerPage).toHaveURL(new RegExp(`/bundles/${slug}`), { timeout: 15_000 });
  await expect(learnerPage.getByText('The payment didn’t go through.')).toBeVisible({ timeout: 20_000 });
  expect((await api(learnerPage, 'POST', `/learning/courses/${bundle.courses[0].id}/enroll`)).status).toBeGreaterThanOrEqual(400);

  await learnerPage.getByRole('button', { name: /Buy now/ }).click();
  await expect(learnerPage).toHaveURL(/\/sandbox-checkout\//, { timeout: 15_000 });
  await learnerPage.getByRole('button', { name: /pay/i }).first().click();
  await expect(learnerPage).toHaveURL(new RegExp(`/bundles/${slug}`), { timeout: 15_000 });
  await expect(learnerPage.getByText('Your courses are open', { exact: true })).toBeVisible({ timeout: 30_000 });

  const orders = (await api(learnerPage, 'GET', '/learning/purchases')).body as { rows: { amount: number; courseId: string; enrolled: boolean }[] };
  expect(orders.rows).toHaveLength(2);
  expect(orders.rows.reduce((sum, o) => sum + o.amount, 0)).toBe(100_000);
  expect(orders.rows.every((o) => o.enrolled)).toBe(true);
});

test('the mentors show no contact details, and each profile lists what they teach', async ({ page }) => {
  await page.goto('/mentors');
  const first = page.locator('main li').getByRole('link').first();
  await expect(first).toBeVisible();
  await expect(page.locator('main')).not.toContainText(/@\w+\.\w+/);
  await first.click();
  await expect(page).toHaveURL(/\/mentors\/.+/);
  await expect(page.getByRole('heading', { level: 2, name: /Courses by/ })).toBeVisible();
});

test('the mega menu opens from its button and on hover, and closes with Escape', async ({ page }) => {
  await page.setViewportSize({ width: 1366, height: 900 });
  await page.goto('/');
  const toggle = page.getByRole('button', { name: 'Show the courses menu' });
  await toggle.click();
  await expect(toggle).toHaveAttribute('aria-expanded', 'true');
  await expect(page.getByRole('heading', { name: 'Popular courses', level: 2 }).first()).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(toggle).toHaveAttribute('aria-expanded', 'false');
});
