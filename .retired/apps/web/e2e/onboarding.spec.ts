import { test, expect, type Page } from '@playwright/test';
import { PASSWORD, signIn } from './helpers';

/*
 * A new customer's first day, entirely through the screens:
 *   the Super Admin creates an academy and its first admin → the academy starts empty, with no plan →
 *   its admin signs in to the plan choice, with the plan-gated modules locked → starts Starter's free trial →
 *   the modules Starter includes open, the rest stay locked with a way to upgrade.
 * Plans are enforced in the E2E API (apps/api/.env), as in a new production deployment.
 */

const SUPERADMIN_EMAIL = 'e2e-superadmin@syniastrolms.test';
const stamp = `${Date.now()}`;
const academy = { name: `E2E Onboarding ${stamp}`, adminName: 'Onboarding Admin', adminEmail: `e2e-onboarding-${stamp}@example.test` };

const nav = (page: Page, href: string) => page.locator(`aside a[href="${href}"]`).first();

test.describe.configure({ mode: 'serial' });

test('the Super Admin creates a new academy, which starts empty and with no plan', async ({ page }) => {
  await signIn(page, SUPERADMIN_EMAIL, /Platform overview/i);
  await page.goto('/superadmin/academies');
  await page.getByRole('button', { name: 'New admin' }).click();

  const dialog = page.getByRole('dialog', { name: 'New admin' });
  await dialog.getByRole('textbox', { name: 'LMS name' }).fill(academy.name);
  await dialog.getByRole('textbox', { name: 'Full name' }).fill(academy.adminName);
  await dialog.getByRole('textbox', { name: 'Email address' }).fill(academy.adminEmail);
  await dialog.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await expect(dialog.getByText(/starts empty/i)).toBeVisible();
  await dialog.getByRole('button', { name: 'Create Admin' }).click();

  await expect(page).toHaveURL(/\/superadmin\/academies\/[^/]+$/, { timeout: 10_000 });
  await expect(page.getByText(academy.adminEmail).first()).toBeVisible();

  await page.goto('/superadmin/academies');
  const row = page.getByRole('row').filter({ hasText: academy.name });
  await expect(row).toContainText('No plan');
});

test('its admin lands on the plan choice, with the plan-gated modules locked', async ({ page }) => {
  await signIn(page, academy.adminEmail, /Welcome to/i);
  await expect(page).toHaveURL(/\/admin\/welcome$/);
  await expect(page.getByRole('heading', { level: 1, name: `Welcome to ${academy.name}` })).toBeVisible();

  // Nothing of another academy's: the sidebar shows the modules, locked until a plan is chosen.
  await expect(nav(page, '/admin/live')).toHaveAttribute('data-plan-access', 'locked');

  await page.goto('/admin/live');
  await expect(page.getByRole('heading', { level: 1, name: /^Unlock / })).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('link', { name: 'See plans' }).or(page.getByRole('button', { name: 'See plans' }))).toBeVisible();
});

test('it starts Starter’s free trial itself, and only what Starter includes opens', async ({ page }) => {
  await signIn(page, academy.adminEmail, /Welcome to/i);
  const starter = page.getByRole('listitem').filter({ has: page.getByRole('heading', { name: /^Starter\b/ }) });
  await starter.getByRole('button', { name: /^Start \d+-day free trial$/ }).click();

  await expect(page.getByText('Your free trial has started')).toBeVisible({ timeout: 10_000 });
  await page
    .getByRole('link', { name: 'Go to your dashboard' })
    .or(page.getByRole('button', { name: 'Go to your dashboard' }))
    .click();

  await expect(page.getByTestId('setup-checklist')).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText(/Free trial · 14 days left/).first()).toBeVisible();

  // Starter includes courses and assessments; live classes and certificates are not in it.
  await expect(nav(page, '/admin/quizzes')).not.toHaveAttribute('data-plan-access', 'locked');
  await expect(nav(page, '/admin/live')).toHaveAttribute('data-plan-access', 'locked');
  await page.goto('/admin/quizzes');
  await expect(page.getByRole('heading', { level: 1, name: /^Unlock / })).toHaveCount(0);
  await page.goto('/admin/live');
  await expect(page.getByRole('heading', { level: 1, name: /^Unlock / })).toBeVisible({ timeout: 10_000 });
});
