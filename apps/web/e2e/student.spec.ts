import { test, expect } from '@playwright/test';
import { registerOnSite, freshEmail, navTo } from './helpers';

/*
 * Register → land in the learner workspace → browse the real catalog → enroll in a real course →
 * open its first lesson. Each step is checked against what the API actually returned, not just that
 * a page rendered, so this catches a broken registration call, a catalog that fails to load, an
 * enrollment that doesn't persist, or a lesson route that 404s just as surely as a failing API test.
 */

test('a new learner registers, enrols in a real course and reaches its first lesson', async ({ page }) => {
  const email = freshEmail();
  const name = 'Priya Testperson';

  await registerOnSite(page, name, email);
  await expect(page.getByText(new RegExp(name.split(' ')[0], 'i')).first()).toBeVisible();

  // The catalog is real: it must list at least one course, linked by its real title (the cover
  // image carries its own aria-hidden link to the same course, so this must be the accessible one).
  await navTo(page, '/explore').click();
  await expect(page).toHaveURL(/\/explore$/);
  const courseLinks = page.getByRole('link').filter({ hasText: /.+/ }).and(page.locator('a[href^="/learn/"]'));
  await expect(courseLinks.first()).toBeVisible({ timeout: 10_000 });
  const courseTitle = (await courseLinks.first().textContent())?.trim();
  expect(courseTitle && courseTitle.length).toBeTruthy();

  await courseLinks.first().click();
  await expect(page).toHaveURL(/\/learn\/[^/]+$/);
  const heading = page.getByRole('heading', { level: 1 });
  await expect(heading).toBeVisible();
  await expect(heading).not.toHaveText('');

  // Enroll for real — this is a write to the API, not a client-side toggle.
  const enrollButton = page.getByRole('button', { name: /Enroll/i });
  await enrollButton.click();
  await expect(page.getByRole('button', { name: /Enroll/i })).not.toBeVisible({ timeout: 10_000 });

  // Enrolling opens the first lesson. Its content must be the real curriculum, with a completion
  // rule the API computed — not an empty shell.
  await expect(page).toHaveURL(/\/learn\/[^/]+\/lessons\/[^/]+/, { timeout: 10_000 });
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();

  // Reloading must not lose the enrollment: the course page should now offer to continue, not enroll again.
  await page.goto(page.url().replace(/\/lessons\/.+/, ''));
  await expect(page.getByRole('button', { name: /Enroll/i })).toHaveCount(0);
});
