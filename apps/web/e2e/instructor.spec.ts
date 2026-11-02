import { test, expect } from '@playwright/test';
import { INSTRUCTOR_EMAIL, navTo, signIn } from './helpers';

/*
 * Sign in as a seeded instructor, open the real review queue, grade a real submission, and check
 * the roster carries real learners. This is the write path the dashboard's "needs attention" count
 * and the reports' review figures both depend on, so it exercises the same records those screens read.
 */

test('an instructor grades a real submission from the review queue', async ({ page }) => {
  await signIn(page, INSTRUCTOR_EMAIL, /Teaching overview/i);

  await navTo(page, '/teach/assignments').click();
  await expect(page).toHaveURL(/\/teach\/assignments$/);
  await navTo(page, '/teach/assignments/review').click();
  await expect(page).toHaveURL(/\/teach\/assignments\/review$/);

  // The figures are read from real submissions, not placeholders — "0" here would mean the seed
  // or the API's review-queue query is broken, not that there's nothing to grade.
  await expect(page.getByText('to review').first()).toBeVisible();

  const firstSubmission = page.locator('table a').first();
  await expect(firstSubmission).toBeVisible({ timeout: 10_000 });
  await firstSubmission.click();

  await expect(page).toHaveURL(/\/teach\/assignments\/[^/]+\/submissions\/[^/]+/);
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  // The submission page is headed by the learner — the queue's first link may be the assignment's title instead.
  // Read once the submission page has replaced the queue's heading.
  await expect(page.getByRole('heading', { level: 1 })).not.toHaveText(/^Assignments$/);
  const learnerName = (await page.getByRole('heading', { level: 1 }).textContent())?.trim();

  // Score every rubric criterion at full marks (or fill the plain score field when there is no
  // rubric), then submit — the same validation and scoring path the API test suite exercises.
  const quickGroups = page.getByRole('group', { name: /Quick scores for/ });
  const rubricCount = await quickGroups.count();
  if (rubricCount > 0) {
    for (let i = 0; i < rubricCount; i++) await quickGroups.nth(i).getByRole('button').last().click();
  } else {
    const scoreField = page.getByLabel('Score', { exact: true });
    const max = await scoreField.getAttribute('max');
    await scoreField.fill(max ?? '80');
  }
  await page.getByLabel('Feedback for the learner').fill('Clear reasoning throughout — well done.');

  await page.getByRole('button', { name: 'Submit review' }).click();
  // Grading writes the review and sends a notification, which can take a moment longer than a
  // typical page transition — worth a longer wait than the default before calling it a failure.
  await expect(page.getByText(/Review sent to/i).first()).toBeVisible({ timeout: 20_000 });
  if (learnerName) await expect(page.getByText(new RegExp(`Review sent to ${learnerName.split(' ')[0]}`, 'i')).first()).toBeVisible();
});

test('the learner roster shows real people, not placeholder rows', async ({ page }) => {
  await signIn(page, INSTRUCTOR_EMAIL, /Teaching overview/i);

  await navTo(page, '/teach/students').click();
  await expect(page).toHaveURL(/\/teach\/students$/);

  const rows = page.locator('table tbody tr');
  await expect(rows.first()).toBeVisible({ timeout: 10_000 });
  // `rows.count()` is a one-shot read; a skeleton row can vanish between it mounting and the real
  // rows replacing it, briefly reading 0. `not.toHaveCount(0)` retries the way `toBeVisible` above did.
  await expect(rows).not.toHaveCount(0);

  // A real name, not "undefined" or an empty cell. Retried: the first row can still be a loading skeleton.
  await expect(rows.first()).toHaveText(/\S/);
  const firstRowText = (await rows.first().textContent()) ?? '';
  expect(firstRowText).not.toMatch(/undefined|NaN|null/);
});
