import { test, expect } from '@playwright/test';
import { ADMIN_EMAIL, navTo, signIn } from './helpers';

/*
 * Sign in as the seeded admin and sweep the screens F14–F16 rebuilt on real records: the dashboard,
 * the roster screens, and a reports tab, then make one real write in Settings and prove it survives
 * a reload — settings are the one screen in this sweep whose whole job is to persist.
 */

test('the admin dashboard, roster and reports all carry real figures', async ({ page }) => {
  await signIn(page, ADMIN_EMAIL, /^Dashboard$/);

  // The dashboard's headline KPIs and activity feed are read from records (F15).
  await expect(page.getByText('Published courses', { exact: true })).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText(/Recent activity/i)).toBeVisible();

  await navTo(page, '/admin/students').click();
  await expect(page).toHaveURL(/\/admin\/students$/);
  const studentRows = page.locator('table tbody tr');
  await expect(studentRows.first()).toBeVisible({ timeout: 10_000 });
  expect(await studentRows.count()).toBeGreaterThan(0);

  await navTo(page, '/admin/instructors').click();
  await expect(page).toHaveURL(/\/admin\/instructors$/);
  const instructorRows = page.locator('table tbody tr');
  await expect(instructorRows.first()).toBeVisible({ timeout: 10_000 });
  expect(await instructorRows.count()).toBeGreaterThan(0);

  // Reports (F14): a real previous-period comparison, not "0 · no change".
  await navTo(page, '/admin/reports').click();
  await expect(page).toHaveURL(/\/admin\/reports$/);
  await expect(page.getByText('Enrolments').first()).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText(/compared with the .* before/i).first()).toBeVisible();
});

test('saving a settings section writes to the API and survives a reload', async ({ page }) => {
  await signIn(page, ADMIN_EMAIL, /^Dashboard$/);

  await page.goto('/admin/settings/general');
  const label = page.getByLabel('Platform name');
  await expect(label).toBeVisible({ timeout: 10_000 });
  const original = await label.inputValue();
  const changed = original === 'ZuviloAI e2e' ? 'ZuviloAI' : 'ZuviloAI e2e';

  const save = page.getByRole('button', { name: 'Save changes' });
  await expect(save).toBeDisabled();
  await label.fill(changed);
  await expect(save).toBeEnabled();
  await save.click();
  await expect(save).toBeDisabled({ timeout: 10_000 });

  // Reload from the server, not from client state, to prove the write actually persisted.
  await page.reload();
  await expect(page.getByLabel('Platform name')).toHaveValue(changed, { timeout: 10_000 });

  // Leave the setting as it was found.
  await page.getByLabel('Platform name').fill(original);
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByRole('button', { name: 'Save changes' })).toBeDisabled({ timeout: 10_000 });
});
