import { test, expect, type APIRequestContext, type Page } from '@playwright/test';
import { PASSWORD, signIn } from './helpers';

/*
 * The subscription flow end to end, on a new academy of its own so no other spec's data moves:
 *   the platform starts its subscription → the scheduler invoices the next period → the platform records the
 *   academy's bank transfer, which renews it → the platform adds complimentary days → the academy's admin sees
 *   the plan, previews a change, cancels and changes their mind.
 * The academy and its admin are provisioned through the API, as the Super Admin's academy screen does; every
 * billing step is driven through the screens. `scripts/run-e2e.mjs` provisions the E2E Super Admin and runs the
 * API with SUBSCRIPTION_INVOICE_LEAD_DAYS=31, so a monthly period is invoiced on the scheduler's next tick.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const SUPERADMIN_EMAIL = 'e2e-superadmin@syniastrolms.test';
const stamp = `${Date.now()}`;
const academy = { name: `E2E Billing Academy ${stamp}`, slug: `e2e-billing-${stamp}`, adminEmail: `e2e-billing-admin-${stamp}@example.test` };
let tenantId = '';
let subscriptionPath = '';

async function platformToken(request: APIRequestContext) {
  const res = await request.post(`${API}/auth/login`, { data: { email: SUPERADMIN_EMAIL, password: PASSWORD } });
  expect(res.ok(), await res.text()).toBe(true);
  return ((await res.json()) as { token: string }).token;
}

const dialog = (page: Page) => page.getByRole('dialog');

test.describe.configure({ mode: 'serial' });

test.beforeAll(async ({ request }) => {
  const headers = { Authorization: `Bearer ${await platformToken(request)}` };
  const created = await request.post(`${API}/superadmin/tenants`, {
    headers,
    data: { name: academy.name, slug: academy.slug, admin: { name: 'E2E Billing Admin', email: academy.adminEmail, password: PASSWORD } },
  });
  expect(created.status(), await created.text()).toBe(201);
  const body = (await created.json()) as { id?: string; academy?: { id: string } };
  tenantId = body.academy?.id ?? body.id ?? '';
  expect(tenantId).not.toBe('');
  const profile = await request.put(`${API}/superadmin/tenants/${tenantId}/billing-profile`, {
    headers,
    data: {
      legalName: academy.name,
      email: 'accounts@example.test',
      addressLine1: '12 MG Road',
      city: 'Bengaluru',
      region: 'KA',
      postalCode: '560001',
      country: 'IN',
    },
  });
  expect(profile.ok(), await profile.text()).toBe(true);
});

test('the platform starts a subscription for a new academy', async ({ page }) => {
  await signIn(page, SUPERADMIN_EMAIL, /Platform overview/i);
  await page.goto(`/superadmin/subscriptions/academies/${tenantId}`);
  await page.getByRole('button', { name: 'Start subscription' }).click();
  await dialog(page).getByLabel('Plan', { exact: true }).selectOption({ label: 'Starter' });
  await dialog(page)
    .getByRole('radio', { name: /Active now/ })
    .check();
  await dialog(page).getByRole('button', { name: 'Start subscription' }).click();

  await expect(page).toHaveURL(/\/superadmin\/subscriptions\/subscribers\/[^/]+$/, { timeout: 10_000 });
  subscriptionPath = new URL(page.url()).pathname;
  await expect(page.getByText(/Subscribed to Starter \(monthly\)/)).toBeVisible();
});

test('the next period is invoiced, and a bank transfer recorded against it renews the subscription', async ({ page }) => {
  test.setTimeout(150_000);
  await signIn(page, SUPERADMIN_EMAIL, /Platform overview/i);
  await page.goto(subscriptionPath);
  // The scheduler ticks once a minute; the renewal invoice appears on the tick after the subscription started.
  const invoice = page.getByRole('button', { name: /^INV-\d{4}-\d{6}$/ }).first();
  await expect(async () => {
    await page.reload();
    await expect(invoice).toBeVisible({ timeout: 3_000 });
  }).toPass({ timeout: 120_000, intervals: [5_000] });

  await invoice.click();
  await dialog(page).getByRole('button', { name: 'Record payment' }).click();
  const record = page.getByRole('dialog', { name: /Record a payment for INV-/ });
  await record.getByLabel('How it was paid').selectOption({ label: 'Bank transfer' });
  await record.getByRole('textbox', { name: 'Reference' }).fill(`NEFT-E2E-${stamp}`);
  await record.getByRole('checkbox', { name: /The Admin paid the full/ }).check();
  await record.getByRole('button', { name: /^Record / }).click();

  await expect(page.getByText(/subscription is renewed/i).first()).toBeVisible({ timeout: 10_000 });
  await page.keyboard.press('Escape');
  await page.reload();
  await expect(page.getByText(/Payment received — renewed to/)).toBeVisible();
  await expect(page.getByText('Bank transfer').first()).toBeVisible();
});

test('the platform adds complimentary days, on the record', async ({ page }) => {
  await signIn(page, SUPERADMIN_EMAIL, /Platform overview/i);
  await page.goto(subscriptionPath);
  await page.getByRole('button', { name: 'Add complimentary days' }).click();
  await dialog(page).getByRole('spinbutton', { name: 'Days' }).fill('10');
  await dialog(page).getByRole('textbox', { name: 'Reason' }).fill('E2E goodwill for an outage');
  await dialog(page).getByRole('button', { name: 'Add days' }).click();
  await expect(page.getByText(/Complimentary days added \(10 days\)/).first()).toBeVisible({ timeout: 10_000 });
});

test('the academy admin sees the plan, previews an upgrade, cancels and changes their mind', async ({ page }) => {
  await signIn(page, academy.adminEmail, /Dashboard/i);
  await page.goto('/admin/billing');
  await expect(page.getByText('Starter').first()).toBeVisible({ timeout: 10_000 });

  // A move up to Enterprise is priced before anything is asked for: credit for the unused month, the charge, tax.
  const enterprise = page.getByRole('listitem').filter({ hasText: 'Enterprise' }).first();
  await enterprise.getByRole('button', { name: 'Annual' }).click();
  await expect(dialog(page).getByText('Credit for the unused part of this period')).toBeVisible({ timeout: 10_000 });
  await expect(dialog(page).getByText('Total due now')).toBeVisible();
  await page.keyboard.press('Escape');

  await page.getByRole('button', { name: 'Cancel subscription' }).click();
  await dialog(page).getByRole('textbox', { name: 'Reason' }).fill('Testing the cancellation flow');
  await dialog(page).getByRole('button', { name: 'Cancel at period end' }).click();
  const keep = page.getByRole('button', { name: 'Keep my subscription' });
  await expect(keep).toBeVisible({ timeout: 10_000 });

  await keep.click();
  await expect(page.getByRole('button', { name: 'Cancel subscription' })).toBeVisible({ timeout: 10_000 });
});
