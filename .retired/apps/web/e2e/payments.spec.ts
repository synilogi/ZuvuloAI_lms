import { test, expect, type Page } from '@playwright/test';
import { emailedSignupCode, PASSWORD } from './helpers';

/*
 * Paying for a plan, live, through the sandbox gateway (SAAS-030): a newly registered academy buys Growth; the
 * payment is first declined, then cancelled, then paid — and only the paid one, reported by the gateway's signed
 * webhook, activates the plan. The academy's admin signs out and back in and the plan is still there.
 */

const stamp = `${Date.now()}`;
const org = { name: `E2E Paying Academy ${stamp}`, email: `e2e-pay-${stamp}@example.test` };

async function register(page: Page) {
  await page.goto('/get-started');
  await page.getByRole('button', { name: 'Choose Growth' }).click();
  await page.getByRole('textbox', { name: 'Organisation name' }).fill(org.name);
  await page.getByRole('textbox', { name: 'Your full name' }).fill('Paying Owner');
  await page.getByRole('textbox', { name: 'Work email' }).fill(org.email);
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByLabel('Confirm password').fill(PASSWORD);
  await page.getByRole('checkbox').check();
  await page.getByRole('button', { name: 'Continue' }).click();
  await page.getByRole('textbox', { name: 'Verification code' }).fill(await emailedSignupCode(org.email));
  await page.getByRole('button', { name: 'Verify and create LMS' }).click();
  await expect(page).toHaveURL(/\/admin\/welcome/, { timeout: 10_000 });
}

/** From the plan page: Buy now → billing details (first time) → confirm → the gateway's page. */
async function openCheckout(page: Page, firstTime: boolean) {
  const growth = page.getByRole('listitem').filter({ has: page.getByRole('heading', { name: /^Growth\b/ }) });
  await growth.getByRole('link', { name: 'Buy now' }).click();
  await expect(page).toHaveURL(/\/admin\/billing/);
  if (firstTime) {
    const details = page.getByRole('dialog', { name: 'Add billing details' });
    await expect(details).toBeVisible({ timeout: 10_000 });
    await details.getByRole('textbox', { name: 'Legal name' }).fill(`${org.name} Pvt Ltd`);
    await details.getByRole('textbox', { name: 'Billing email' }).fill(org.email);
    await details.getByRole('textbox', { name: 'Address', exact: true }).fill('12 MG Road');
    await details.getByRole('textbox', { name: 'City' }).fill('Bengaluru');
    await details.getByRole('textbox', { name: /State or region code/ }).fill('KA');
    await details.getByRole('textbox', { name: 'Postal code' }).fill('560001');
    await details.getByRole('textbox', { name: 'Country code' }).fill('IN');
    await details.getByRole('button', { name: /save/i }).click();
  }
  const confirm = page.getByRole('dialog', { name: /^Subscribe to Growth/ });
  await expect(confirm).toBeVisible({ timeout: 10_000 });
  await confirm.getByRole('button', { name: 'Continue to payment' }).click();
  await expect(page).toHaveURL(/\/sandbox-checkout\//, { timeout: 10_000 });
  await expect(page.getByText('Sandbox gateway — no real money moves')).toBeVisible();
}

test.describe.configure({ mode: 'serial' });

test('a declined payment and a cancelled checkout change nothing; a paid one activates the plan', async ({ page }) => {
  await register(page);

  await openCheckout(page, true);
  await page.getByRole('button', { name: 'Decline the payment' }).click();
  await expect(page).toHaveURL(/\/admin\/billing$/);
  await expect(page.getByText('The payment was declined')).toBeVisible();
  await page.goto('/admin/welcome');
  await expect(page.getByRole('heading', { level: 1, name: `Welcome to ${org.name}` })).toBeVisible();

  await openCheckout(page, false);
  await page.getByRole('button', { name: 'Cancel and go back' }).click();
  await expect(page.getByText('Checkout cancelled')).toBeVisible();
  await page.goto('/admin/welcome');
  await expect(page.getByRole('heading', { level: 1, name: `Welcome to ${org.name}` })).toBeVisible();

  await openCheckout(page, false);
  await page.getByRole('button', { name: 'Pay successfully' }).click();
  await expect(page.getByText('Payment received')).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText(/Growth/).first()).toBeVisible();
  await expect(page.getByText(/Active/).first()).toBeVisible();
});

test('the plan survives signing out and back in, and its modules are open', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email address').fill(org.email);
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).toHaveURL(/\/admin$/, { timeout: 10_000 });
  await expect(page.locator('aside a[href="/admin/live"]').first()).not.toHaveAttribute('data-plan-access', 'locked');
  await page.goto('/admin/billing');
  await expect(page.getByText(/Growth/).first()).toBeVisible();
});
