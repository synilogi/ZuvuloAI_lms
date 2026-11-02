import { crc32, deflateSync } from 'node:zlib';
import { expect, test, type Page } from '@playwright/test';
import { ADMIN_EMAIL, PASSWORD, signIn } from './helpers';

/*
 * The platform's logo and favicon. The Super Admin replaces them on /superadmin/branding and every screen follows —
 * the website header, the workspace, the browser's icon — and the built-in ZuviloAI branding comes back on restore.
 * An academy admin sees the platform's branding and can neither open its settings nor change it through the API.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const SUPERADMIN_EMAIL = 'e2e-superadmin@syniastrolms.test';

const chunk = (type: string, data: Buffer) => {
  const body = Buffer.concat([Buffer.from(type, 'latin1'), data]);
  const out = Buffer.alloc(body.length + 8);
  out.writeUInt32BE(data.length, 0);
  body.copy(out, 4);
  out.writeUInt32BE(crc32(body), body.length + 4);
  return out;
};

/** A real PNG of the given size, one flat colour. */
function png(width: number, height: number, [r, g, b]: [number, number, number]): Buffer {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header.set([8, 2, 0, 0, 0], 8);
  const row = Buffer.concat([Buffer.from([0]), Buffer.alloc(width * 3).map((_, i) => [r, g, b][i % 3])]);
  const pixels = deflateSync(Buffer.concat(Array.from({ length: height }, () => row)));
  return Buffer.concat([Buffer.from('89504e470d0a1a0a', 'hex'), chunk('IHDR', header), chunk('IDAT', pixels), chunk('IEND', Buffer.alloc(0))]);
}

const file = (name: string, buffer: Buffer) => ({ name, mimeType: 'image/png', buffer });
const SAVED = /\/public\/branding\/assets\/(logo|favicon)-[0-9a-f-]{36}\.png$/;
const iconLinks = (page: Page) => page.locator('link[data-brand-icon]').evaluateAll((links) => links.map((l) => l.getAttribute('href') ?? ''));

test.describe.configure({ mode: 'serial' });

test('a super admin previews, saves and restores the platform’s logo and favicon', async ({ page, browser }) => {
  await signIn(page, SUPERADMIN_EMAIL, /Platform overview/i);
  await page.goto('/superadmin/branding');
  await expect(page.getByRole('heading', { level: 1, name: 'Branding' })).toBeVisible();
  await expect(page.getByText('ZuviloAI default', { exact: true })).toHaveCount(2);
  await expect(page.getByRole('button', { name: 'Save changes' })).toBeDisabled();

  // A file that breaks a rule is explained where it was chosen, and cannot be saved.
  await page.getByLabel('Choose a favicon file').setInputFiles(file('wide.png', png(256, 128, [20, 120, 200])));
  await expect(page.getByText(/The favicon must be square/)).toBeVisible();
  await expect(page.getByRole('button', { name: 'Save changes' })).toBeDisabled();

  // Acceptable files are shown before anything is saved.
  await page.getByLabel('Choose a logo file').setInputFiles(file('new-logo.png', png(600, 160, [200, 30, 30])));
  await page.getByLabel('Choose a favicon file').setInputFiles(file('new-icon.png', png(256, 256, [200, 30, 30])));
  await expect(page.getByText('Not saved yet')).toHaveCount(2);
  await expect(page.getByText(/600 × 160 px/)).toBeVisible();
  expect((await iconLinks(page)).some((href) => SAVED.test(href))).toBe(false);

  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByText('Branding saved')).toBeVisible();
  await expect(page.getByText('Custom', { exact: true })).toHaveCount(2);
  // The shell follows at once: its mark and the browser's icon are the saved favicon.
  await expect.poll(async () => (await iconLinks(page)).every((href) => SAVED.test(href))).toBe(true);
  await expect(page.locator('aside img[src*="/public/branding/assets/favicon-"]').first()).toBeVisible();

  // A visitor who has never been here sees the saved logo on the website, and the saved icon after a plain load.
  const visitor = await (await browser.newContext()).newPage();
  await visitor.goto('/welcome');
  await expect(visitor.locator('header img[src*="/public/branding/assets/logo-"]')).toBeVisible();
  await expect.poll(async () => (await iconLinks(visitor)).every((href) => SAVED.test(href))).toBe(true);
  await visitor.context().close();

  // It is still saved after a reload.
  await page.reload();
  await expect(page.getByText('Custom', { exact: true })).toHaveCount(2);

  await page.getByRole('button', { name: 'Restore default branding' }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Restore default' }).click();
  await expect(page.getByText('Default branding restored')).toBeVisible();
  await expect(page.getByText('ZuviloAI default', { exact: true })).toHaveCount(2);
  await expect.poll(async () => (await iconLinks(page)).some((href) => SAVED.test(href))).toBe(false);
  expect((await (await page.request.get(`${API}/public/branding`)).json()) as unknown).toEqual({ logo: null, favicon: null });
});

test('an academy admin cannot open or change the platform’s branding', async ({ page, request }) => {
  await signIn(page, ADMIN_EMAIL, /.+/);
  await expect(page.locator('a[href="/superadmin/branding"]')).toHaveCount(0);
  await page.goto('/superadmin/branding');
  await expect(page).not.toHaveURL(/\/superadmin/);

  const login = await request.post(`${API}/auth/login`, { data: { email: ADMIN_EMAIL, password: PASSWORD } });
  const headers = { Authorization: `Bearer ${(await login.json()).token as string}` };
  const upload = await request.put(`${API}/superadmin/branding`, { headers, multipart: { logo: file('logo.png', png(600, 160, [0, 0, 0])) } });
  expect(upload.status()).toBe(403);
  expect((await request.get(`${API}/superadmin/branding`, { headers })).status()).toBe(403);
  expect((await request.delete(`${API}/superadmin/branding`, { headers })).status()).toBe(403);
  expect((await (await request.get(`${API}/public/branding`)).json()) as unknown).toEqual({ logo: null, favicon: null });
});
