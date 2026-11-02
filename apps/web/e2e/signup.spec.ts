import { test, expect } from '@playwright/test';
import { emailedSignupCode, freshEmail, PASSWORD, registerOnSite } from './helpers';

/* Registration on the one platform (docs/16 §2.3): a learner signs up with a mobile number and an emailed code; an instructor
 * applies and waits for approval; nothing exists until the code is confirmed. */

test('a learner registers, a wrong code is refused, and the right one signs them in', async ({ page }) => {
  const email = freshEmail();
  await page.goto('/register');
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByText('Fix these before creating your account')).toBeVisible();

  await page.getByLabel('Full name').fill('Kavya Rao');
  await page.getByLabel('Email address').fill(email);
  await page.getByLabel('Mobile number').fill('+919812345678');
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByLabel('Confirm password').fill(PASSWORD);
  await page.getByLabel(/agree to the/i).check();
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('textbox', { name: 'Verification code' })).toBeVisible({ timeout: 10_000 });

  // Nothing exists yet, so signing in fails.
  const code = await emailedSignupCode(email, 'account-verification');
  const wrong = String((Number(code) + 1) % 1_000_000).padStart(6, '0');
  await page.getByRole('textbox', { name: 'Verification code' }).fill(wrong);
  await page.getByRole('button', { name: /^Verify and/ }).click();
  await expect(page.getByText(/tries left/)).toBeVisible();

  await page.getByRole('textbox', { name: 'Verification code' }).fill(code);
  await page.getByRole('button', { name: /^Verify and/ }).click();
  await expect(page).toHaveURL(/\/explore$/, { timeout: 10_000 });
});

test('an address already in use is refused', async ({ page, browser }) => {
  const email = freshEmail();
  await registerOnSite(page, 'First Person', email);
  const other = await (await browser.newContext()).newPage();
  await other.goto('/register');
  await other.getByLabel('Full name').fill('Second Person');
  await other.getByLabel('Email address').fill(email);
  await other.getByLabel('Mobile number').fill('+919812345679');
  await other.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await other.getByLabel('Confirm password').fill(PASSWORD);
  await other.getByLabel(/agree to the/i).check();
  await other.getByRole('button', { name: 'Create account' }).click();
  await expect(other.getByText(/already/i).first()).toBeVisible({ timeout: 10_000 });
  await other.context().close();
});

test('registering from a course page comes back to that course', async ({ page }) => {
  await registerOnSite(page, 'Back To Course', freshEmail(), '/register?next=%2Fexplore%3Fq%3Dscience');
  await expect(page).toHaveURL(/\/explore\?q=science$/);
});
