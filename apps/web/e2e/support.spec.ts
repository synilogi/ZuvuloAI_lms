import { test, expect } from '@playwright/test';
import { ADMIN_EMAIL, signIn } from './helpers';

/* Support on the one platform (docs/16 §2.5): anyone signed in reaches the contact form from Help, and the message arrives in
 * the Super Admin's inbox. */

test('a support message from Help reaches the Super Admin’s inbox', async ({ page, browser }) => {
  const marker = `E2E support ${Date.now()}`;
  await signIn(page, ADMIN_EMAIL, /^Dashboard$/);
  await page.goto('/admin/help');
  await page.getByRole('link', { name: 'Contact support' }).click();
  await expect(page).toHaveURL(/\/contact\?topic=support$/);
  await page.getByRole('textbox', { name: 'Your name' }).fill('Staff Member');
  await page.getByRole('textbox', { name: 'Email' }).fill(ADMIN_EMAIL);
  await page.getByRole('textbox', { name: 'What happened' }).fill(`${marker}: the report would not open.`);
  await page.getByRole('button', { name: 'Send to support' }).click();
  await expect(page.getByText('Thanks — we’ve got your message')).toBeVisible();

  const platform = await (await browser.newContext()).newPage();
  await signIn(platform, 'e2e-superadmin@syniastrolms.test', /Platform overview/i);
  await platform.goto('/superadmin/inquiries?kind=support');
  await platform.getByRole('searchbox', { name: 'Search the inbox' }).fill(marker);
  await expect(platform.getByRole('row').filter({ hasText: 'Staff Member' }).first()).toContainText('Support');
  await platform.context().close();
});
