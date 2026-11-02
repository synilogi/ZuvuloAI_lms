import { test, expect } from '@playwright/test';
import { ADMIN_EMAIL, confirmEmailedCode, freshEmail, PASSWORD, signIn } from './helpers';

/* How people arrive (docs/16 §2.3): an instructor applies from the website, with a profile, and waits for approval. Nobody is
 * signed in until then, and the application reaches the staff. */

test('an instructor applies, verifies their email, cannot sign in yet, and the Admin sees the application', async ({ page, browser }) => {
  const email = freshEmail();
  await page.goto('/become-an-instructor');
  await page.getByRole('link', { name: 'Apply to teach' }).first().click();
  await expect(page).toHaveURL(/\/teach\/apply$/);
  await expect(page.getByRole('heading', { level: 1, name: /^Teach on/ })).toBeVisible();
  await page.getByLabel('Full name').fill('Anil Sharma');
  await page.getByLabel('Email address').fill(email);
  await page.getByLabel('Mobile number').fill('+919812345670');
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByLabel('What you teach').fill('Physics teacher');
  await page.getByLabel('Years of teaching experience').fill('6');
  await page.getByLabel('Subjects').fill('Physics, Mechanics');
  await page.getByLabel('About your teaching').fill('I have taught physics for Classes 11 and 12 for six years.');
  await page.getByLabel(/agree to the/i).check();
  await page.getByRole('button', { name: 'Send application' }).click();
  await confirmEmailedCode(page, email);
  await expect(page.getByText('Your application is being reviewed')).toBeVisible();

  // Nobody is signed in until the application is approved.
  await page.goto('/login');
  await page.getByLabel('Email address').fill(email);
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page.getByText(/application is being reviewed/i).first()).toBeVisible();

  const admin = await (await browser.newContext()).newPage();
  await signIn(admin, ADMIN_EMAIL, /^Dashboard$/);
  await admin.goto('/admin/instructors');
  const row = admin
    .getByRole('region', { name: /Pending instructor applications/ })
    .getByRole('listitem')
    .filter({ hasText: email });
  await expect(row).toBeVisible({ timeout: 10_000 });
  await expect(row).toContainText('Physics');
  await admin.context().close();
});
