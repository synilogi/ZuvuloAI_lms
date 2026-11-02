import { test, expect, type Browser, type BrowserContext, type Page } from '@playwright/test';
import { ADMIN_EMAIL, confirmEmailedCode, freshEmail, PASSWORD, signIn } from './helpers';

/*
 * Learner onboarding without typing an LMS address, live against the API: an Admin makes a one-time invitation link
 * in the Students page and a learner joins through it (once); a course enrolment link joins a new learner to the
 * course and enrols them.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const shared: { courseId?: string; courseTitle?: string } = {};

const token = (page: Page) => page.evaluate(() => localStorage.getItem('syniastrolms:token'));
const api = async (page: Page, method: string, path: string, data?: unknown) => {
  const auth = await token(page);
  const res = await page.request.fetch(`${API}${path}`, { method, headers: auth ? { Authorization: `Bearer ${auth}` } : {}, data });
  return { status: res.status(), body: await res.json().catch(() => ({})) };
};

const fresh = async (browser: Browser) => (await browser.newContext()).newPage();

/*
 * The seeded Admin signs in once for the whole file: sign-ins share the API's per-client budget for `/auth` with every
 * other spec, so the session is kept and reopened rather than repeated.
 */
let adminState: Awaited<ReturnType<BrowserContext['storageState']>> | undefined;
async function adminPage(browser: Browser) {
  if (adminState) {
    const page = await (await browser.newContext({ storageState: adminState })).newPage();
    await page.goto('/admin');
    return page;
  }
  const page = await fresh(browser);
  await signIn(page, ADMIN_EMAIL, /dashboard|good (morning|afternoon|evening)|overview/i);
  adminState = await page.context().storageState();
  return page;
}

async function createAccount(page: Page, name: string, email: string, submit: string) {
  await page.getByLabel('Full name').fill(name);
  const field = page.getByLabel('Email address');
  if (!(await field.getAttribute('readonly'))) await field.fill(email);
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByLabel('Confirm password').fill(PASSWORD);
  await page.getByLabel(/agree to the/i).check();
  await page.getByRole('button', { name: submit, exact: true }).click();
  // The email is verified before the account exists.
  await confirmEmailedCode(page, email);
}

test.describe.configure({ mode: 'serial' });

test('an Admin invites a learner, who joins through the link once and lands in their learner workspace', async ({ browser }) => {
  const page = await adminPage(browser);
  await page.goto('/admin/students');
  await page.getByRole('button', { name: 'Invite learners' }).click();
  const dialog = page.getByRole('dialog', { name: 'Invite learners' });
  await dialog.getByRole('button', { name: 'Create invitation link' }).click();
  const link = dialog.getByRole('textbox', { name: 'Invitation link' });
  await expect(link).toHaveValue(/\/invite\/[a-f0-9]{64}$/);
  await expect(dialog.getByText('It works once and expires in 7 days.', { exact: false })).toBeVisible();
  const path = new URL(await link.inputValue()).pathname;
  await expect(dialog.getByRole('list', { name: 'Invitations' }).getByText('Pending').first()).toBeVisible();

  // A fresh browser: nobody signed in, no LMS address typed — the link alone names the LMS.
  const learner = await fresh(browser);
  await learner.goto(path);
  await expect(learner.getByRole('heading', { level: 1, name: /^Join / })).toBeVisible();
  const email = freshEmail();
  await createAccount(learner, 'Invited Learner', email, 'Create account');
  await expect(learner).toHaveURL(/\/home$/, { timeout: 10_000 });
  expect((await api(learner, 'GET', '/auth/me')).body.user).toMatchObject({ email, role: 'student' });

  // The link worked once.
  const again = await fresh(browser);
  await again.goto(path);
  await expect(again.getByText('This invitation link isn’t valid', { exact: true })).toBeVisible();
  await expect(again.getByLabel('Full name')).toHaveCount(0);

  // The Admin sees it accepted, and the learner in their roster.
  await page.goto('/admin/students?invite=1');
  await expect(page.getByRole('dialog', { name: 'Invite learners' }).getByText('Accepted').first()).toBeVisible();
  const roster = await api(page, 'GET', `/students?search=${encodeURIComponent(email)}`);
  expect(roster.body.rows.map((r: { student: { email: string } }) => r.student.email)).toContain(email);
});

test('a withdrawn invitation no longer works', async ({ browser }) => {
  const page = await adminPage(browser);
  await page.goto('/admin/students?invite=1');
  const dialog = page.getByRole('dialog', { name: 'Invite learners' });
  const bound = freshEmail();
  await dialog.getByRole('textbox', { name: /Learner’s email address/ }).fill(bound);
  await dialog.getByRole('button', { name: 'Create invitation link' }).click();
  const link = dialog.getByRole('textbox', { name: 'Invitation link' });
  await expect(link).toHaveValue(/\/invite\/[a-f0-9]{64}$/);
  const path = new URL(await link.inputValue()).pathname;
  await expect(dialog.getByText(`We’ve also emailed it to ${bound}.`)).toBeVisible();

  // Bound to that address: shown, and not editable.
  const visitor = await fresh(browser);
  await visitor.goto(path);
  await expect(visitor.getByLabel('Email address')).toHaveValue(bound);
  await expect(visitor.getByLabel('Email address')).not.toBeEditable();

  const row = dialog.getByRole('listitem').filter({ hasText: bound });
  await row.getByRole('button', { name: /Withdraw/ }).click();
  await expect(page.getByText('Invitation withdrawn')).toBeVisible();
  await expect(row.getByText('Withdrawn')).toBeVisible();

  await visitor.reload();
  await expect(visitor.getByText('This invitation link isn’t valid', { exact: true })).toBeVisible();
});

test('a course enrolment link joins a new learner to the course’s LMS and enrols them', async ({ browser }) => {
  const page = await adminPage(browser);
  const courses = await api(page, 'GET', '/courses?status=published&page=1&pageSize=100');
  // A free course: a paid one is bought after joining (coursePurchase.spec.ts), so its link enrols nobody by itself.
  const course = (courses.body.rows as { id: string; title: string; visibility: string; pricing?: string }[]).find(
    (c) => c.visibility !== 'private' && c.pricing === 'free',
  );
  expect(course, 'a published free course in the demo LMS').toBeTruthy();
  shared.courseId = course!.id;
  shared.courseTitle = course!.title;

  // The Admin's course page offers the link.
  await page.goto(`/admin/courses/${course!.id}`);
  await expect(page.getByRole('button', { name: 'Copy enrolment link' })).toBeVisible();

  const visitor = await fresh(browser);
  await visitor.goto(`/courses/${course!.id}/enroll`);
  await expect(visitor.getByRole('heading', { level: 1, name: course!.title })).toBeVisible();
  await expect(visitor.getByRole('link', { name: 'Sign in' })).toHaveAttribute('href', `/login?next=${encodeURIComponent(`/courses/${course!.id}/enroll`)}`);
  const email = freshEmail();
  await createAccount(visitor, 'Course Learner', email, 'Create account and enrol');
  // Sent to the course only once the server enrolled them (`enrolled: true`); an enrolment twice changes nothing.
  await expect(visitor).toHaveURL(new RegExp(`/learn/${course!.id}$`), { timeout: 10_000 });
  expect((await api(visitor, 'POST', `/learning/courses/${course!.id}/enroll`)).status).toBe(200);
});
