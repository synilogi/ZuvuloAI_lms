import { type Page, expect } from '@playwright/test';

/** Seeded accounts (see apps/api/prisma/seed.ts). Same password for all. */
export const PASSWORD = 'syniastrolms123';
export const ADMIN_EMAIL = 'admin@syniastrolms.test';
export const INSTRUCTOR_EMAIL = 'meenakshi@syniastrolms.test';

/** Signs in through the real login form and waits for the workspace to load. */
export async function signIn(page: Page, email: string, landingHeading: RegExp) {
  await page.goto('/login');
  await page.getByLabel('Email address').fill(email);
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page.getByRole('heading', { level: 1, name: landingHeading })).toBeVisible({ timeout: 25_000 });
}

/** A fresh, unique learner email so registration never collides between runs. */
export const freshEmail = () => `e2e-${Date.now()}-${Math.floor(Math.random() * 10_000)}@example.test`;

/**
 * A navigation link by its exact destination, not its visible text. Several sidebar items carry a
 * count badge (`Assignments`, `Live classes`) whose own `aria-label` becomes part of the link's
 * computed accessible name — "Assignments" then reads as "Assignments 14 new" or similar, which an
 * exact text match on the label alone no longer matches. The href never changes.
 */
export const navTo = (page: Page, href: string) => page.locator(`a[href="${href}"]`).first();

/**
 * The verification code the API emailed to `email` (SAAS-026), read from the E2E database's outbox — the
 * registrant's inbox, as far as a test can see it. `run-e2e.mjs` builds that database (`E2E_DB_FILE`, else
 * `apps/api/prisma/e2e.db`).
 */
export async function emailedSignupCode(email: string, templateKey = 'signup-verification'): Promise<string> {
  const { DatabaseSync } = await import('node:sqlite');
  const { fileURLToPath } = await import('node:url');
  // `run-e2e.mjs` passes the run's database as E2E_DB_FILE.
  const file = process.env.E2E_DB_FILE ?? fileURLToPath(new URL('../../api/prisma/e2e.db', import.meta.url));
  const db = new DatabaseSync(file, { readOnly: true });
  try {
    for (let i = 0; i < 40; i++) {
      let row: { text?: string } | undefined;
      try {
        row = db.prepare('SELECT text FROM EmailOutbox WHERE toEmail = ? AND templateKey = ? ORDER BY createdAt DESC LIMIT 1').get(email, templateKey) as
          { text?: string } | undefined;
      } catch (err) {
        // Other specs write to the same database at the same moment: a locked read is simply tried again.
        if (!/locked|busy/i.test(String(err))) throw err;
      }
      const code = row?.text?.match(/\b(\d{6})\b/)?.[1];
      if (code) return code;
      await new Promise((r) => setTimeout(r, 250));
    }
  } finally {
    db.close();
  }
  throw new Error(`No verification code was emailed to ${email}`);
}

/**
 * A learner or instructor who registered themselves confirms their email: the code step reads the emailed code (from
 * the E2E outbox) and submits it — nothing exists until it does.
 */
export async function confirmEmailedCode(page: Page, email: string) {
  await page.getByRole('textbox', { name: 'Verification code' }).waitFor();
  await page.getByRole('textbox', { name: 'Verification code' }).fill(await emailedSignupCode(email.toLowerCase(), 'account-verification'));
  await page.getByRole('button', { name: /^Verify and/ }).click();
}

/** A learner registers on the website: details, the emailed code, then wherever registration sends them. */
export async function registerOnSite(page: Page, name: string, email: string, path = '/register') {
  await page.goto(path);
  await page.getByLabel('Full name').fill(name);
  await page.getByLabel('Email address').fill(email);
  await page.getByLabel('Mobile number').fill('+919812345678');
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByLabel('Confirm password').fill(PASSWORD);
  await page.getByLabel(/agree to the/i).check();
  await page.getByRole('button', { name: 'Create account' }).click();
  await confirmEmailedCode(page, email);
  await expect(page).not.toHaveURL(/\/register/, { timeout: 10_000 });
}
