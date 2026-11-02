import { crc32, deflateSync } from 'node:zlib';
import { test, expect, type Page } from '@playwright/test';
import { ADMIN_EMAIL, signIn } from './helpers';

/*
 * The simplified course editor, live against the API. A course is created with its title, subtitle, category and
 * cover — all on the form's first screen — saved as a draft, edited (every one of those changed, the cover image
 * removed, a description and an instructor added), and published with nothing else filled in. The required fields
 * say what is missing next to each one; only the truly optional settings stay folded away.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const token = (page: Page) => page.evaluate(() => localStorage.getItem('syniastrolms:token'));
const api = async (page: Page, method: string, path: string) => {
  const auth = await token(page);
  const res = await page.request.fetch(`${API}${path}`, { method, headers: auth ? { Authorization: `Bearer ${auth}` } : {} });
  return { status: res.status(), body: await res.json().catch(() => ({})) };
};

/** A real PNG, so the upload passes the API's type and signature checks. */
const chunk = (type: string, data: Buffer) => {
  const body = Buffer.concat([Buffer.from(type, 'latin1'), data]);
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body) >>> 0);
  return Buffer.concat([length, body, crc]);
};
function png(width: number, height: number): Buffer {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header.set([8, 2, 0, 0, 0], 8);
  const row = Buffer.concat([Buffer.from([0]), Buffer.alloc(width * 3).map((_, i) => [40, 90, 200][i % 3])]);
  const pixels = deflateSync(Buffer.concat(Array.from({ length: height }, () => row)));
  return Buffer.concat([Buffer.from('89504e470d0a1a0a', 'hex'), chunk('IHDR', header), chunk('IDAT', pixels), chunk('IEND', Buffer.alloc(0))]);
}

/**
 * Picks a cover artwork card. Its radio is laid over the whole card, so a click anywhere on the card lands on it —
 * which Playwright's hit test reports as the card's artwork being covered; the click goes where a person's would.
 */
async function pickArtwork(page: Page, name: string) {
  const group = page.getByRole('group', { name: 'Cover artwork' });
  await group.getByText(name, { exact: true }).click({ force: true });
  await expect(group.getByRole('radio', { name })).toBeChecked();
}

test('a course is created with its subtitle, category and cover, edited, and published with only the required fields', async ({ page }) => {
  await signIn(page, ADMIN_EMAIL, /^Dashboard$/);
  const categories = ((await api(page, 'GET', '/catalog/categories')).body as { id: string; name: string; status: string }[]).filter(
    (c) => c.status === 'active',
  );
  expect(categories.length, 'two active categories in the demo LMS').toBeGreaterThanOrEqual(2);
  const [firstCategory, secondCategory] = [categories[categories.length - 1], categories[0]];

  await page.goto('/admin/courses/new');
  await expect(page.getByRole('heading', { level: 1, name: 'New course' })).toBeVisible({ timeout: 10_000 });

  // Subtitle, category and cover are on the form itself; only outcomes, tags and the like are folded away.
  await expect(page.getByLabel('Subtitle')).toBeVisible();
  await expect(page.getByLabel('Category')).toBeVisible();
  await expect(page.getByRole('group', { name: 'Cover artwork' })).toBeVisible();
  const more = page.getByRole('button', { name: /Additional settings/ });
  await expect(more).toHaveAttribute('aria-expanded', 'false');
  await expect(page.getByRole('textbox', { name: 'Learning outcomes 1' })).toHaveCount(0);
  await more.click();
  await expect(page.getByRole('textbox', { name: 'Learning outcomes 1' })).toBeVisible();
  await more.click();

  // Publishing an empty form names each missing field next to it.
  await page.getByRole('button', { name: 'Publish', exact: true }).click();
  await expect(page.getByText('Finish these to publish')).toBeVisible();
  await expect(page.locator('#course-title-message')).toHaveText('Give the course a title.');
  await expect(page.locator('#course-description-message')).toHaveText('Add a short description — learners read it before they enrol.');
  await expect(page.locator('#course-instructors-error')).toHaveText('Assign at least one instructor.');
  await expect(page.getByLabel('Course title')).toHaveAttribute('aria-invalid', 'true');

  // Create: title, subtitle, category and cover — no description or instructor yet, so it is a draft.
  const stamp = Date.now();
  const title = `E2E Fractions ${stamp}`;
  await page.getByLabel('Course title').fill(title);
  await page.getByLabel('Subtitle').fill('Add, compare and simplify fractions');
  await page.getByLabel('Category').selectOption(firstCategory.id);
  await pickArtwork(page, 'Orbits');
  await page.locator('#course-cover-image input[type="file"]').setInputFiles({ name: 'cover.png', mimeType: 'image/png', buffer: png(320, 200) });
  await expect(page.getByRole('button', { name: 'Remove image' })).toBeVisible({ timeout: 15_000 });
  await page.getByRole('button', { name: 'Save draft' }).click();
  await expect(page.getByText('Draft saved').first()).toBeVisible({ timeout: 10_000 });
  await expect(page).toHaveURL(/\/admin\/courses\/[^/]+$/);
  const courseId = page.url().split('/').pop()!;
  await expect(page.getByRole('heading', { level: 1, name: title })).toBeVisible();

  const created = (await api(page, 'GET', `/courses/${courseId}`)).body;
  expect(created).toMatchObject({
    status: 'draft',
    title,
    subtitle: 'Add, compare and simplify fractions',
    categoryId: firstCategory.id,
    coverMotif: 'orbits',
    description: '',
    instructorIds: [],
  });
  expect(created.coverImageId).toBeTruthy();

  // Edit: the editor opens with what was saved.
  await page.goto(`/admin/courses/${courseId}/edit`);
  await expect(page.getByLabel('Course title')).toHaveValue(title, { timeout: 10_000 });
  await expect(page.getByLabel('Subtitle')).toHaveValue('Add, compare and simplify fractions');
  await expect(page.getByLabel('Category')).toHaveValue(firstCategory.id);
  await expect(page.getByRole('button', { name: 'Remove image' })).toBeVisible();

  // Change every one of them, remove the cover image, and fill in the rest of what publishing needs.
  const renamed = `E2E Fractions, revised ${stamp}`;
  await page.getByLabel('Course title').fill(renamed);
  await page.getByLabel('Subtitle').fill('Fractions for Class 6, step by step');
  await page.getByLabel('Category').selectOption(secondCategory.id);
  await page.getByRole('button', { name: 'Remove image' }).click();
  await pickArtwork(page, 'Arc');
  await page.getByLabel('Description').fill('A short course for Class 6 on adding and simplifying fractions.');
  await page.getByRole('group', { name: 'Instructors' }).getByRole('checkbox').first().check();
  await expect(page.getByText('3/3')).toBeVisible();
  await page.getByRole('button', { name: 'Save draft' }).click();
  await expect(page.getByText('Changes saved').first()).toBeVisible({ timeout: 10_000 });

  const edited = (await api(page, 'GET', `/courses/${courseId}`)).body;
  expect(edited).toMatchObject({
    status: 'draft',
    title: renamed,
    subtitle: 'Fractions for Class 6, step by step',
    categoryId: secondCategory.id,
    coverMotif: 'ecliptic',
    description: 'A short course for Class 6 on adding and simplifying fractions.',
  });
  expect(edited.coverImageId ?? null).toBeNull();
  expect(edited.instructorIds).toHaveLength(1);

  // The edit survives a fresh load of the editor, and the course publishes from there.
  await page.goto(`/admin/courses/${courseId}/edit`);
  await expect(page.getByLabel('Course title')).toHaveValue(renamed, { timeout: 10_000 });
  await expect(page.getByLabel('Subtitle')).toHaveValue('Fractions for Class 6, step by step');
  await expect(page.getByLabel('Category')).toHaveValue(secondCategory.id);
  await expect(page.getByRole('button', { name: 'Remove image' })).toHaveCount(0);
  await page.getByRole('button', { name: 'Publish', exact: true }).click();
  await expect(page.getByText('Course published').first()).toBeVisible({ timeout: 10_000 });
  await expect(page).toHaveURL(new RegExp(`/admin/courses/${courseId}$`));

  const live = (await api(page, 'GET', `/courses/${courseId}`)).body;
  expect(live).toMatchObject({ status: 'published', title: renamed, outcomes: [], tags: [], chapters: [] });

  // Out of the way of the specs that read the published catalog.
  expect((await api(page, 'POST', `/courses/${courseId}/archive`)).status).toBe(200);
});
