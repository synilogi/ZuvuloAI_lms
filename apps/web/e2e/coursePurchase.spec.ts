import { test, expect, type Page } from '@playwright/test';
import { ADMIN_EMAIL, registerOnSite, signIn } from './helpers';

/*
 * Selling a course, live against the API and the sandbox gateway (PAYMENT_SANDBOX=on in the E2E run; the demo academy
 * has no Razorpay keys of its own, so its course orders go through the sandbox's test checkout).
 *
 *   1. An admin makes a course Paid at a price in the editor and publishes it. A learner sees that price, is offered no
 *      free enrolment, and the API itself refuses to enrol them for free.
 *   2. A declined payment and a cancelled checkout leave the seeded paid course locked, each with a way to try again.
 *   3. A paid checkout opens the course — only once the API confirms the purchase — and the purchase is in Purchases
 *      and the course in My courses.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const SEEDED_PAID = 'Class 10 Science: Board Exam Sprint';
const stamp = Date.now();
const learner = { name: 'Kavya Buyer', email: `e2e-buyer-${stamp}@example.test` };

const token = (page: Page) => page.evaluate(() => localStorage.getItem('syniastrolms:token'));
async function api(page: Page, method: string, path: string, data?: unknown) {
  const auth = await token(page);
  const res = await page.request.fetch(`${API}${path}`, {
    method,
    headers: { ...(auth ? { Authorization: `Bearer ${auth}` } : {}), ...(data ? { 'Content-Type': 'application/json' } : {}) },
    ...(data ? { data: JSON.stringify(data) } : {}),
  });
  return { status: res.status(), body: await res.json().catch(() => ({})) };
}

async function registerLearner(page: Page) {
  await registerOnSite(page, learner.name, learner.email);
}

/** The seeded paid course's id, as the catalog lists it. */
async function seededPaidCourse(page: Page): Promise<string> {
  const courses = (await api(page, 'GET', '/catalog/courses')).body as { id: string; title: string; pricing?: string; price?: { amount: number } }[];
  const course = courses.find((c) => c.title === SEEDED_PAID);
  expect(course, 'the demo seed has one paid course').toBeTruthy();
  expect(course).toMatchObject({ pricing: 'paid', price: { amount: 1499 } });
  return course!.id;
}

/** Buy course → order summary → the sandbox's test checkout. `summary` is false for a retry, which goes straight on. */
async function openCheckout(page: Page, how: 'summary' | 'retry') {
  if (how === 'summary') {
    await page.getByRole('button', { name: 'Buy course · ₹1,499' }).click();
    const summary = page.getByRole('dialog', { name: 'Order summary' });
    await expect(summary).toBeVisible();
    await expect(summary.getByText(SEEDED_PAID)).toBeVisible();
    await expect(summary.getByText('₹1,499')).toHaveCount(2);
    await expect(summary.getByText(/All-inclusive price/)).toBeVisible();
    // The price is all-inclusive: no tax, fee or discount line is invented on the client.
    await expect(summary.getByText(/GST|tax|discount/i)).toHaveCount(0);
    await summary.getByRole('button', { name: 'Continue to payment' }).click();
  } else {
    await page.getByRole('button', { name: 'Try again' }).click();
  }
  await expect(page).toHaveURL(/\/sandbox-checkout\//, { timeout: 10_000 });
  await expect(page.getByText('Sandbox gateway — no real money moves')).toBeVisible();
  await expect(page.getByRole('heading', { level: 1, name: 'Pay ₹1,499' })).toBeVisible({ timeout: 10_000 });
}

/**
 * The seed dates its paid course a year back (so the catalogue lists it last) and gives it no learners, so the API's
 * "archive inactive courses" job archives it as soon as the API boots. Until the seed stops doing that, the admin puts
 * it back on sale here — restore, publish — exactly as an admin would from the courses list.
 */
/** The demo seed's paid course is on sale from the start: published, not archived by the inactive-course job at boot. */
async function seededCourseOnSale(page: Page) {
  const list = (await api(page, 'GET', `/courses?search=${encodeURIComponent(SEEDED_PAID)}&status=all&page=1&pageSize=10`)).body as {
    rows: { id: string; title: string; status: string; pricing?: string }[];
  };
  const course = list.rows.find((c) => c.title === SEEDED_PAID);
  expect(course, 'the demo seed has one paid course').toBeTruthy();
  expect(course).toMatchObject({ status: 'published', pricing: 'paid' });
}

const enrolledIn = async (page: Page, courseId: string) => (await api(page, 'GET', `/learning/courses/${courseId}`)).body.enrolled as boolean;

test.describe.configure({ mode: 'serial' });

test('an admin sells a course at a price; a learner sees it and cannot enrol in it for free', async ({ page, browser }) => {
  await signIn(page, ADMIN_EMAIL, /^Dashboard$/);
  await seededCourseOnSale(page);
  await page.goto('/admin/courses/new');
  await expect(page.getByRole('heading', { level: 1, name: 'New course' })).toBeVisible({ timeout: 10_000 });

  // A new course starts free; choosing Paid asks for a price, checked before anything is sent.
  const pricing = page.getByRole('group', { name: 'Free or paid' });
  await expect(pricing.getByRole('radio', { name: /^Free/ })).toBeChecked();
  await expect(page.locator('#course-price')).toHaveCount(0);
  const title = `E2E Paid Physics ${stamp}`;
  await page.getByLabel('Course title').fill(title);
  await page.getByLabel('Description').fill('Motion, force and energy for Class 9, with worked examples.');
  await page.getByRole('group', { name: 'Instructors' }).getByRole('checkbox').first().check();
  await pricing.getByRole('radio', { name: /^Paid/ }).check({ force: true });
  await page.locator('#course-price').fill('0');
  await page.getByRole('button', { name: 'Publish', exact: true }).click();
  await expect(page.locator('#course-price-message')).toHaveText('The price must be between ₹1 and ₹5,00,000.');
  await page.locator('#course-price').fill('749.50');
  await expect(page.locator('#course-price-message')).toHaveText('Enter whole rupees only — no paise.');
  await page.locator('#course-price').fill('749');
  await page.getByRole('button', { name: 'Publish', exact: true }).click();
  await expect(page.getByText('Course published').first()).toBeVisible({ timeout: 10_000 });
  await expect(page).toHaveURL(/\/admin\/courses\/[^/]+$/);
  const courseId = page.url().split('/').pop()!;

  const saved = (await api(page, 'GET', `/courses/${courseId}`)).body;
  expect(saved).toMatchObject({ status: 'published', pricing: 'paid', price: { amount: 749, currency: 'INR' } });
  // The overview says what it costs.
  await expect(page.getByRole('region', { name: 'Details' }).getByText('Paid · ₹749')).toBeVisible();

  // An edit that does not touch pricing leaves the price exactly as it is.
  await page.goto(`/admin/courses/${courseId}/edit`);
  await expect(page.locator('#course-price')).toHaveValue('749', { timeout: 10_000 });
  await page.getByLabel('Subtitle').fill('Motion and force, step by step');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByText('Changes saved').first()).toBeVisible({ timeout: 10_000 });
  expect((await api(page, 'GET', `/courses/${courseId}`)).body).toMatchObject({ pricing: 'paid', price: { amount: 749 } });

  // A learner sees the price and a way to buy it — never a free enrolment.
  const context = await browser.newContext();
  const learnerPage = await context.newPage();
  try {
    await registerLearner(learnerPage);
    await learnerPage.goto(`/learn/${courseId}`);
    await expect(learnerPage.getByRole('heading', { level: 1, name: title })).toBeVisible({ timeout: 10_000 });
    await expect(learnerPage.getByRole('button', { name: 'Buy course · ₹749' })).toBeVisible();
    await expect(learnerPage.getByText('All-inclusive price').first()).toBeVisible();
    await expect(learnerPage.getByRole('button', { name: /Enroll/i })).toHaveCount(0);
    // The API itself refuses a free enrolment in a paid course.
    const refused = await api(learnerPage, 'POST', `/learning/courses/${courseId}/enroll`);
    expect(refused.status).toBe(409);
    expect(refused.body.code).toBe('COURSE_PURCHASE_REQUIRED');
    // The catalog card shows the same price.
    await learnerPage.goto(`/explore?q=${encodeURIComponent(title)}`);
    await expect(learnerPage.getByRole('listitem').filter({ hasText: title }).getByText('₹749')).toBeVisible({ timeout: 10_000 });
  } finally {
    await context.close();
  }

  // Clean up: the course is archived, out of every catalog.
  expect((await api(page, 'POST', `/courses/${courseId}/archive`)).status).toBe(200);
});

test('a declined payment and a cancelled checkout leave the course locked, each with a retry', async ({ page }) => {
  await signIn(page, learner.email, /Kavya/);
  const courseId = await seededPaidCourse(page);
  await page.goto(`/learn/${courseId}`);
  await expect(page.getByRole('heading', { level: 1, name: SEEDED_PAID })).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('button', { name: /Enroll/i })).toHaveCount(0);

  // Declined at the gateway: back on the course page, still locked, with the reason and a retry.
  await openCheckout(page, 'summary');
  await page.getByRole('button', { name: 'Decline the payment' }).click();
  await expect(page).toHaveURL(new RegExp(`/learn/${courseId}$`), { timeout: 10_000 });
  await expect(page.getByText('The payment didn’t go through.')).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('button', { name: 'Try again' })).toBeVisible();
  expect(await enrolledIn(page, courseId)).toBe(false);

  // Cancelled: nothing charged, still locked, and the retry is there.
  await openCheckout(page, 'retry');
  await page.getByRole('button', { name: 'Cancel and go back' }).click();
  await expect(page).toHaveURL(new RegExp(`/learn/${courseId}$`), { timeout: 10_000 });
  await expect(page.getByText('Payment cancelled. You weren’t charged.')).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('button', { name: 'Try again' })).toBeVisible();
  expect(await enrolledIn(page, courseId)).toBe(false);
  await expect(page.getByRole('button', { name: 'Buy course · ₹1,499' })).toBeEnabled();

  // Both attempts were on the one open order: one purchase, unpaid, at the server's price.
  const purchases = (await api(page, 'GET', '/learning/purchases')).body.rows as { courseId: string; status: string; amount: number; enrolled: boolean }[];
  const mine = purchases.filter((p) => p.courseId === courseId);
  expect(mine).toHaveLength(1);
  expect(mine[0]).toMatchObject({ amount: 149900, enrolled: false });
  // A decline on the hosted page never calls confirm; the server finds it when asked, and shows it as failed (retryable).
  expect(mine[0].status).toBe('failed');
  await page.goto('/purchases');
  const row = page.getByRole('row').filter({ hasText: SEEDED_PAID });
  await expect(row.getByText('Payment failed — try again')).toBeVisible({ timeout: 10_000 });
  await expect(row.getByRole('link', { name: 'Try again' })).toHaveAttribute('href', `/learn/${courseId}`);
});

test('a paid checkout opens the course only once the API confirms it; it shows in Purchases and My courses', async ({ page }) => {
  await signIn(page, learner.email, /Kavya/);
  const courseId = await seededPaidCourse(page);
  await page.goto(`/learn/${courseId}`);
  await expect(page.getByRole('heading', { level: 1, name: SEEDED_PAID })).toBeVisible({ timeout: 10_000 });

  await openCheckout(page, 'summary');
  // Paid at the gateway, but nothing is open until the API has confirmed the purchase with it.
  expect(await enrolledIn(page, courseId)).toBe(false);
  await page.getByRole('button', { name: 'Pay successfully' }).click();
  await expect(page).toHaveURL(new RegExp(`/learn/${courseId}$`), { timeout: 10_000 });
  // The webhook often settles the order before the learner is back, so the open course is the proof, not a toast.
  await expect(page.getByRole('link', { name: 'Start the course' })).toBeVisible();
  await expect(page.getByRole('button', { name: /Buy course/ })).toHaveCount(0);
  expect(await enrolledIn(page, courseId)).toBe(true);

  // Buying it again is refused: the learner has it.
  const again = await api(page, 'POST', `/learning/courses/${courseId}/purchase`);
  expect(again.status).toBe(409);
  expect(again.body.code).toBe('ALREADY_ENROLLED');

  // The purchase, with what was paid.
  await page.goto('/purchases');
  await expect(page.getByRole('heading', { level: 1, name: 'Purchases' })).toBeVisible({ timeout: 10_000 });
  const row = page.getByRole('row').filter({ hasText: SEEDED_PAID });
  await expect(row).toBeVisible({ timeout: 10_000 });
  await expect(row.getByText('Paid', { exact: true })).toBeVisible();
  await expect(row.getByText('₹1,499')).toBeVisible();

  // And the course is in My courses.
  await page.goto('/my-learning/in-progress');
  await expect(page.getByRole('link', { name: SEEDED_PAID })).toBeVisible({ timeout: 10_000 });
});
