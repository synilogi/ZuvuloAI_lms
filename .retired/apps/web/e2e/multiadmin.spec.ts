import { test, expect, type Browser, type Page } from '@playwright/test';
import { PASSWORD, signIn } from './helpers';

/*
 * The multi-admin journey (SAAS-031), live against the API: the Super Admin creates Admin A and Admin B, each with an
 * LMS of their own; each starts a trial and adds their own people; Admin A can reach none of Admin B's records —
 * through the screens or the API; ending A's subscription restricts A only; suspending B signs B out with a clear
 * reason while A carries on.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const SUPERADMIN = 'e2e-superadmin@syniastrolms.test';
const stamp = `${Date.now()}`;
const adminA = { lms: `E2E Admin A ${stamp}`, name: 'Admin Alpha', email: `e2e-a-${stamp}@example.test` };
const adminB = { lms: `E2E Admin B ${stamp}`, name: 'Admin Beta', email: `e2e-b-${stamp}@example.test` };
const ids: { tenantA?: string; tenantB?: string; studentB?: string; instructorB?: string } = {};

const token = (page: Page) => page.evaluate(() => localStorage.getItem('syniastrolms:token'));
const api = async (page: Page, method: string, path: string, data?: unknown) => {
  const res = await page.request.fetch(`${API}${path}`, { method, headers: { Authorization: `Bearer ${await token(page)}` }, data });
  return { status: res.status(), body: await res.json().catch(() => ({})) };
};

async function createAdmin(page: Page, admin: typeof adminA) {
  await page.goto('/superadmin/academies');
  await page.getByRole('button', { name: 'New admin' }).click();
  const dialog = page.getByRole('dialog', { name: 'New admin' });
  await dialog.getByRole('textbox', { name: 'LMS name' }).fill(admin.lms);
  await dialog.getByRole('textbox', { name: 'Full name' }).fill(admin.name);
  await dialog.getByRole('textbox', { name: 'Email address' }).fill(admin.email);
  await dialog.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await dialog.getByRole('button', { name: /^Create/ }).click();
  // The dialog has an address of its own (`/academies/new`): wait for the new Admin's page.
  await expect(page).toHaveURL(/\/superadmin\/academies\/(?!new$)[^/]+$/, { timeout: 10_000 });
  return page.url().split('/').pop()!;
}

/** An Admin's own session: signs in, starts Starter's trial, lands on the dashboard. */
async function adminSession(browser: Browser, admin: typeof adminA) {
  const page = await (await browser.newContext()).newPage();
  await signIn(page, admin.email, /Welcome to/i);
  const starter = page.getByRole('listitem').filter({ has: page.getByRole('heading', { name: /^Starter\b/ }) });
  await starter.getByRole('button', { name: /^Start \d+-day free trial$/ }).click();
  await expect(page.getByText('Your free trial has started')).toBeVisible({ timeout: 10_000 });
  await page.getByRole('link', { name: 'Go to your dashboard' }).click();
  await expect(page).toHaveURL(/\/admin$/);
  return page;
}

async function addStudent(page: Page, name: string, email: string) {
  await page.goto('/admin/students?add=1');
  const dialog = page.getByRole('dialog', { name: 'Add a student' });
  await dialog.getByRole('textbox', { name: 'Full name' }).fill(name);
  await dialog.getByRole('textbox', { name: 'Email address' }).fill(email);
  await dialog.getByRole('button', { name: 'Add student' }).click();
  await expect(page.getByText(`${name} is added`)).toBeVisible();
}

/** Signs in and waits until the app has left the sign-in page — wherever the account lands. */
async function signInAnywhere(page: Page, email: string) {
  await page.goto('/login');
  await page.getByLabel('Email address').fill(email);
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).not.toHaveURL(/\/login/, { timeout: 10_000 });
}

const instructor = (name: string, email: string) => ({
  name,
  title: 'Senior Mathematics Teacher',
  email,
  bio: 'Teaches school mathematics with twenty years of classroom practice behind every lesson.',
  expertise: ['Mathematics'],
  status: 'invited',
  city: 'Pune',
  languages: ['English'],
  courseIds: [],
});

test.describe.configure({ mode: 'serial' });

test('the Super Admin creates two Admins, each with an LMS of their own, and each adds their own people', async ({ page, browser }) => {
  // Two Admins created and two trials started: on a full parallel run this journey alone can pass 30 seconds.
  test.setTimeout(60_000);
  await signIn(page, SUPERADMIN, /Platform overview/i);
  ids.tenantA = await createAdmin(page, adminA);
  ids.tenantB = await createAdmin(page, adminB);

  const a = await adminSession(browser, adminA);
  await addStudent(a, 'Student of A', `e2e-sa-${stamp}@example.test`);
  expect((await api(a, 'POST', '/instructors', instructor('Instructor of A', `e2e-ia-${stamp}@example.test`))).status).toBe(201);

  const b = await adminSession(browser, adminB);
  await addStudent(b, 'Student of B', `e2e-sb-${stamp}@example.test`);
  const insB = await api(b, 'POST', '/instructors', instructor('Instructor of B', `e2e-ib-${stamp}@example.test`));
  expect(insB.status).toBe(201);
  ids.instructorB = insB.body.id;
  const studentsB = await api(b, 'GET', '/students');
  ids.studentB = studentsB.body.rows[0].student.id;

  // Each Admin's roster holds their own people only.
  await a.goto('/admin/students');
  await expect(a.getByText('Student of A').first()).toBeVisible();
  await expect(a.getByText('Student of B')).toHaveCount(0);
  await a.goto('/admin/instructors');
  await expect(a.getByText('Instructor of A').first()).toBeVisible();
  await expect(a.getByText('Instructor of B')).toHaveCount(0);

  // Admin A reaches none of Admin B's records — not through the screens, not through the API.
  await a.goto(`/admin/students/${ids.studentB}`);
  await expect(a.getByText(/not found|doesn’t exist|isn’t in your/i).first()).toBeVisible();
  expect((await api(a, 'GET', `/students/${ids.studentB}`)).status).toBe(404);
  expect((await api(a, 'POST', `/students/${ids.studentB}/suspend`, { suspended: true })).status).toBe(404);
  expect((await api(a, 'GET', `/instructors/${ids.instructorB}`)).status).toBe(404);
  expect((await api(a, 'PATCH', `/instructors/${ids.instructorB}`, instructor('Hijacked', `e2e-ib-${stamp}@example.test`))).status).toBe(404);
  expect((await api(a, 'GET', `/superadmin/tenants/${ids.tenantB}`)).status).toBe(403);
  // A forged academy in the body changes nothing: A's new learner is still A's.
  const forged = await api(a, 'POST', '/students', { name: 'Forged', email: `e2e-forged-${stamp}@example.test`, tenantId: ids.tenantB });
  expect(forged.status).toBe(201);
  expect((await api(b, 'GET', '/students')).body.rows.map((r: { student: { email: string } }) => r.student.email)).not.toContain(
    `e2e-forged-${stamp}@example.test`,
  );
});

test('ending Admin A’s subscription restricts Admin A only', async ({ page, browser }) => {
  await signIn(page, SUPERADMIN, /Platform overview/i);
  const subs = await api(page, 'GET', `/superadmin/tenants/${ids.tenantA}`);
  expect(subs.body.subscription, JSON.stringify({ tenant: ids.tenantA, status: subs.status, body: subs.body })).toBeTruthy();
  const ended = await api(page, 'POST', `/superadmin/subscriptions/${subs.body.subscription.id}/cancel`, {
    immediately: true,
    reason: 'E2E: ended to check restricted mode',
  });
  expect(ended.status).toBe(200);

  const a = await (await browser.newContext()).newPage();
  await signInAnywhere(a, adminA.email);
  await a.goto('/admin/students?add=1');
  const add = await api(a, 'POST', '/students', { name: 'Too late', email: `e2e-late-${stamp}@example.test` });
  expect(add.status).toBe(402);
  await a.goto('/admin/billing');
  await expect(a.getByText(/no active subscription|ended|choose a plan|cancel/i).first()).toBeVisible();

  const b = await (await browser.newContext()).newPage();
  await signInAnywhere(b, adminB.email);
  expect((await api(b, 'POST', '/students', { name: 'Still fine', email: `e2e-fine-${stamp}@example.test` })).status).toBe(201);
});

test('suspending Admin B signs B out with a clear reason, and Admin A is untouched', async ({ page, browser }) => {
  const b = await (await browser.newContext()).newPage();
  await signInAnywhere(b, adminB.email);

  await signIn(page, SUPERADMIN, /Platform overview/i);
  expect((await api(page, 'POST', `/superadmin/tenants/${ids.tenantB}/suspend`, { reason: 'E2E suspension' })).status).toBe(200);

  // B's open session ends on its next request, on a sign-in page that says why.
  await b.goto('/admin/students');
  await expect(b).toHaveURL(/\/login\?closed=suspended/, { timeout: 10_000 });
  await expect(b.getByText('This account is suspended')).toBeVisible();
  // And B cannot sign in again.
  await b.getByLabel('Email address').fill(adminB.email);
  await b.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await b.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(b.getByText('This account is suspended')).toBeVisible();

  const a = await (await browser.newContext()).newPage();
  await signInAnywhere(a, adminA.email);
  expect((await api(a, 'GET', '/students')).status).toBe(200);

  // Reactivated, B is back with its data.
  expect((await api(page, 'POST', `/superadmin/tenants/${ids.tenantB}/reactivate`, {})).status).toBe(200);
  await signInAnywhere(b, adminB.email);
  expect((await api(b, 'GET', '/students')).body.rows.length).toBeGreaterThan(0);
});
