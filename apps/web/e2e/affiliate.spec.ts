import { test, expect, type Browser, type Page } from '@playwright/test';
import { freshEmail, PASSWORD, registerOnSite, signIn } from './helpers';

/*
 * The affiliate program's money, end to end through the sandbox gateway (docs/15 §10): a sponsor and one referral on each leg
 * buy the eligible course; the Super Admin's run pays matching; the member verifies their identity and withdraws; the Super
 * Admin approves, batches and marks it paid; the member's wallet says so; and a refund takes the income back.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const SUPERADMIN = 'e2e-superadmin@syniastrolms.test';
const COURSE = 'Class 10 Science: Board Exam Sprint';

const token = (page: Page) => page.evaluate(() => localStorage.getItem('syniastrolms:token'));
async function api(page: Page, method: string, path: string, data?: unknown) {
  const res = await page.request.fetch(`${API}${path}`, {
    method,
    headers: { Authorization: `Bearer ${await token(page)}`, ...(data ? { 'Content-Type': 'application/json' } : {}) },
    ...(data ? { data: JSON.stringify(data) } : {}),
  });
  return { status: res.status(), body: await res.json().catch(() => ({})) };
}

async function learner(browser: Browser, name: string, query = ''): Promise<Page> {
  const page = await (await browser.newContext()).newPage();
  await registerOnSite(page, name, freshEmail(), `/register${query}`);
  return page;
}

/** Buys the eligible course through the page and the sandbox's test checkout. */
async function buyCourse(page: Page) {
  await page.goto('/courses?price=paid');
  await page.getByRole('link', { name: COURSE }).click();
  await page.getByRole('link', { name: 'Buy now' }).first().click();
  await page.getByRole('button', { name: /^Buy course/ }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Continue to payment' }).click();
  await expect(page).toHaveURL(/\/sandbox-checkout\//, { timeout: 10_000 });
  await page.getByRole('button', { name: 'Pay successfully' }).click();
  await expect(page).toHaveURL(/\/learn\//, { timeout: 15_000 });
}

test('a sale becomes matching, a withdrawal and a paid wallet entry; a refund takes the income back', async ({ browser }) => {
  test.setTimeout(480_000);
  const owner = await (await browser.newContext()).newPage();
  await signIn(owner, SUPERADMIN, /Platform overview/i);

  // The plan is the seed's draft until someone puts a course on it and activates it.
  const courses = (await api(owner, 'GET', '/catalog/courses')).body as { id: string; title: string }[];
  const courseId = courses.find((c) => c.title === COURSE)!.id;
  const overview = (await api(owner, 'GET', '/superadmin/affiliates/plan')).body as {
    active: { id: string; eligibleCourseIds: string[] } | null;
    versions: { id: string; status: string }[];
  };
  if (overview.active) {
    expect(
      (
        await api(owner, 'PUT', `/superadmin/affiliates/plan/versions/${overview.active.id}/courses`, {
          eligibleCourseIds: [...new Set([...overview.active.eligibleCourseIds, courseId])],
        })
      ).status,
    ).toBe(200);
  } else {
    const draft = overview.versions.find((v) => v.status === 'draft')!;
    expect((await api(owner, 'PUT', `/superadmin/affiliates/plan/versions/${draft.id}/courses`, { eligibleCourseIds: [courseId] })).status).toBe(200);
    expect((await api(owner, 'POST', `/superadmin/affiliates/plan/versions/${draft.id}/activate`)).status).toBe(200);
  }

  // A sponsor joins and activates by buying; one referral lands on each leg by their links.
  const sponsor = await learner(browser, 'Sponsor Person');
  const me = (await api(sponsor, 'POST', '/affiliate/enrol', { preferredLeg: 'A' })).body as { id: string; code: string };
  expect(me.code).toBeTruthy();
  await buyCourse(sponsor);

  const left = await learner(browser, 'Left Referral', `?ref=${me.code}`);
  await buyCourse(left);
  // The sponsor chooses the leg their next referral lands on.
  expect((await api(sponsor, 'PATCH', '/affiliate/preferred-leg', { leg: 'B' })).status).toBe(200);
  const right = await learner(browser, 'Right Referral', `?ref=${me.code}`);
  await buyCourse(right);

  // The sponsor sees volume on both legs, with nothing yet paid.
  expect((await api(sponsor, 'GET', '/affiliate/figures')).body).toMatchObject({ unmatchedA: 149_900, unmatchedB: 149_900 });
  await sponsor.goto('/affiliate/earnings');
  await expect(sponsor.getByText('not guaranteed')).toBeVisible();

  // The Super Admin runs today's matching; a second run changes nothing.
  await owner.goto('/superadmin/affiliates/matching');
  await owner.getByRole('button', { name: 'Run today' }).click();
  await expect(owner.getByText(/Today’s run covered/)).toBeVisible({ timeout: 15_000 });
  const first = (await api(sponsor, 'GET', '/affiliate/earnings')).body;
  expect(first.matchingIncome).toBe(14_990);
  expect((await api(owner, 'POST', '/superadmin/affiliates/matching/run', {})).status).toBe(200);
  expect((await api(sponsor, 'GET', '/affiliate/earnings')).body.matchingIncome).toBe(14_990);

  // Identity: submitted by the member, verified by the Super Admin, stored masked.
  await sponsor.goto('/affiliate/kyc');
  await sponsor.getByLabel('Name on your PAN').fill('Sponsor Person');
  await sponsor.getByLabel('PAN', { exact: true }).fill('ABCDE1234F');
  await sponsor.getByLabel('Name on the bank account').fill('Sponsor Person');
  await sponsor.getByLabel('Account number').fill('123456789012');
  await sponsor.getByLabel('IFSC').fill('HDFC0001234');
  await sponsor.getByRole('button', { name: 'Send for review' }).click();
  await expect(sponsor.getByText('Sent for review')).toBeVisible();
  await expect(sponsor.locator('body')).not.toContainText('123456789012');

  await owner.goto('/superadmin/affiliates/kyc');
  await owner.getByRole('row').filter({ hasText: me.code }).getByRole('button', { name: 'Verify' }).click();
  await owner.getByRole('dialog').getByRole('button', { name: 'Verify', exact: true }).click();
  await expect(owner.getByText('Identity verified')).toBeVisible();

  // The income is below the plan's smallest withdrawal, so the wallet is topped up by a recorded correction.
  expect(
    (await api(owner, 'POST', `/superadmin/affiliates/wallets/${me.id}/adjust`, { amount: 100_000, reason: 'E2E top-up to the smallest withdrawal' })).status,
  ).toBe(200);

  await sponsor.goto('/affiliate/wallet');
  await sponsor.getByLabel('Amount in rupees').fill('100');
  await sponsor.getByRole('button', { name: 'Request withdrawal' }).click();
  await expect(sponsor.getByText(/below the smallest withdrawal/)).toBeVisible();
  await sponsor.getByLabel('Amount in rupees').fill('600');
  await sponsor.getByRole('button', { name: 'Request withdrawal' }).click();
  await expect(sponsor.getByText('Withdrawal requested')).toBeVisible();

  await owner.goto('/superadmin/affiliates/withdrawals?status=requested');
  await owner.getByRole('row').filter({ hasText: me.code }).getByRole('button', { name: 'Approve' }).click();
  await owner.getByRole('dialog').getByRole('button', { name: 'Approve', exact: true }).click();
  await expect(owner.getByText('Withdrawal approved')).toBeVisible();
  await owner.goto('/superadmin/affiliates/withdrawals?status=approved');
  await owner.getByRole('button', { name: 'Create batch' }).click();
  await owner.getByRole('dialog').getByRole('button', { name: 'Create batch' }).click();
  await expect(owner.getByText('Batch created')).toBeVisible();
  await owner.goto('/superadmin/affiliates/withdrawals?status=processing');
  await owner.getByRole('row').filter({ hasText: me.code }).getByRole('button', { name: 'Mark paid' }).click();
  await owner.getByRole('dialog').getByLabel('Bank reference').fill('UTR-E2E-1');
  await owner.getByRole('dialog').getByRole('button', { name: 'Mark paid' }).click();
  await expect(owner.getByText('Withdrawal marked paid')).toBeVisible();
  expect((await api(sponsor, 'GET', '/affiliate/earnings')).body.wallet).toMatchObject({ held: 0, paid: 60_000 });

  // A refund of the left referral's order takes the matched income back.
  const orders = (await api(owner, 'GET', `/superadmin/sales/orders?status=paid&pageSize=100`)).body.rows as { id: string; learner: { name: string } }[];
  const order = orders.find((o) => o.learner.name === 'Left Referral')!;
  const before = (await api(sponsor, 'GET', '/affiliate/earnings')).body.wallet.available as number;
  expect((await api(owner, 'POST', `/superadmin/sales/orders/${order.id}/refund`, { reason: 'E2E refund' })).status).toBe(200);
  const after = (await api(sponsor, 'GET', '/affiliate/earnings')).body;
  expect(after.matchingIncome).toBe(0);
  expect(after.wallet.available).toBe(before - 14_990);

  for (const page of [owner, sponsor, left, right]) await page.context().close();
  expect(PASSWORD).toBeTruthy();
});
