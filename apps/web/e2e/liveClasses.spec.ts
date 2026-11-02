import { test, expect, type APIRequestContext, type Browser, type BrowserContext, type Page } from '@playwright/test';
import { INSTRUCTOR_EMAIL, PASSWORD, signIn } from './helpers';

/*
 * Live classes, live against the API (the audit of October 2026):
 *   1. An instructor schedules a class at a chosen IST time — 04:30, before 05:30 IST, so its UTC date is the day
 *      before — then edits only its title and clears its capacity: the start stays the same instant (the editor once
 *      read the UTC string as IST and moved every edited class 5h30m earlier), and the cleared capacity is saved.
 *   2. They cancel it with a reason (refused without one), and "Reschedule" copies it into a new class.
 *   3. A learner sees a class on an outside meeting with no link anywhere in their data, and gets the link only by
 *      joining — inside the join window, opened in a new tab; outside it the API refuses.
 *   4. An academy admin without `live.manage` and `live.notify` is offered none of the actions the API would refuse.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const SUPERADMIN = 'e2e-superadmin@syniastrolms.test';
const LEARNER_EMAIL = 'ananya@syniastrolms.test';
const COURSE = 'Maths Foundations for Classes 6–8';
const stamp = Date.now();
const titles = {
  scheduled: `E2E early class ${stamp}`,
  renamed: `E2E early class, renamed ${stamp}`,
  soon: `E2E outside meeting ${stamp}`,
  later: `E2E outside meeting later ${stamp}`,
};
/** A meeting host no test ever reaches: its page is served by the browser context (`route`), never the network. */
const MEETING = `https://meet.e2e.test/room-${stamp}`;
const limited = { email: `e2e-live-limited-${stamp}@example.test`, name: 'Lena Limited' };

const shared: { liveId?: string; courseId?: string; instructorId?: string; soonId?: string; laterId?: string; limitedId?: string; instructorToken?: string } =
  {};

const token = (page: Page) => page.evaluate(() => localStorage.getItem('syniastrolms:token'));
const api = async (page: Page, method: string, path: string, data?: unknown) => {
  const auth = await token(page);
  const res = await page.request.fetch(`${API}${path}`, { method, headers: auth ? { Authorization: `Bearer ${auth}` } : {}, data });
  return { status: res.status(), body: await res.json().catch(() => ({})), text: await res.text().catch(() => '') };
};

/** The academy's date (IST) `days` from now, as a date input takes it. */
const istDate = (days: number) => new Date(Date.now() + days * 86_400_000 + 330 * 60_000).toISOString().slice(0, 10);

/* Sessions are signed in once and reopened: sign-ins share the API's per-client `/auth` budget with every other spec. */
type State = Awaited<ReturnType<BrowserContext['storageState']>>;
const sessions: Record<string, State | undefined> = {};
async function session(browser: Browser, key: string, email: string, home: string) {
  const state = sessions[key];
  const page = await (await browser.newContext(state ? { storageState: state } : {})).newPage();
  if (state) {
    await page.goto(home);
    return page;
  }
  await page.goto('/login');
  await page.getByLabel('Email address').fill(email);
  await page.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).not.toHaveURL(/\/login/, { timeout: 10_000 });
  sessions[key] = await page.context().storageState();
  return page;
}
const instructorPage = (browser: Browser) => session(browser, 'instructor', INSTRUCTOR_EMAIL, '/teach');
const learnerPage = (browser: Browser) => session(browser, 'learner', LEARNER_EMAIL, '/home');

async function platformHeaders(request: APIRequestContext) {
  const res = await request.post(`${API}/auth/login`, { data: { email: SUPERADMIN, password: PASSWORD } });
  expect(res.ok(), await res.text()).toBe(true);
  return { Authorization: `Bearer ${((await res.json()) as { token: string }).token}` };
}

test.describe.configure({ mode: 'serial' });

test.afterAll(async ({ playwright }) => {
  // Out of the way of the specs that read the live schedule: every class this spec made is cancelled.
  if (shared.instructorToken) {
    const request = await playwright.request.newContext({ extraHTTPHeaders: { Authorization: `Bearer ${shared.instructorToken}` } });
    for (const id of [shared.liveId, shared.soonId, shared.laterId])
      if (id) await request.post(`${API}/live/${id}/cancel`, { data: { reason: 'E2E live spec finished' } });
    await request.dispose();
  }
  if (shared.limitedId) {
    const request = await playwright.request.newContext();
    const headers = await platformHeaders(request);
    await request.post(`${API}/superadmin/admins/${shared.limitedId}/deactivate`, { headers });
    await request.dispose();
  }
});

test('an instructor schedules a class at 04:30 IST, edits only its title, and the start stays the same instant', async ({ browser }) => {
  test.setTimeout(60_000);
  const page = await instructorPage(browser);
  shared.instructorToken = (await token(page)) ?? undefined;
  const date = istDate(3);
  const expected = new Date(`${date}T04:30:00+05:30`).toISOString();

  await page.goto('/teach/live/new');
  await expect(page.getByRole('heading', { level: 1, name: 'Schedule a live class' })).toBeVisible({ timeout: 10_000 });
  await page.locator('#live-title').fill(titles.scheduled);
  await page.locator('#live-course').selectOption({ label: COURSE });
  await page.locator('#live-date').fill(date);
  await page.locator('#live-start').fill('04:30');
  await page.locator('#live-end').fill('05:30');
  await page.getByRole('button', { name: 'Schedule class' }).click();
  await expect(page.getByText('Class scheduled').first()).toBeVisible({ timeout: 10_000 });
  await expect(page).toHaveURL(/\/teach\/live\/[^/]+$/);
  shared.liveId = page.url().split('/').pop()!;

  const created = (await api(page, 'GET', `/live/${shared.liveId}`)).body;
  expect(created.liveClass).toMatchObject({ title: titles.scheduled, startsAt: expected, durationMin: 60, capacity: 80 });
  shared.courseId = created.liveClass.courseId;
  shared.instructorId = created.liveClass.instructorId;

  // The editor shows the IST date and time it was given — not the UTC ones the API answers with.
  await page.goto(`/teach/live/${shared.liveId}/edit`);
  await expect(page.getByRole('heading', { level: 1, name: 'Edit live class' })).toBeVisible({ timeout: 10_000 });
  await expect(page.locator('#live-date')).toHaveValue(date);
  await expect(page.locator('#live-start')).toHaveValue('04:30');
  await expect(page.locator('#live-end')).toHaveValue('05:30');
  await page.locator('#live-title').fill(titles.renamed);
  // Emptied, the capacity is sent as null — which clears it; left undefined, the API would keep 80.
  await page.locator('#live-capacity').fill('');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByText('Class updated').first()).toBeVisible({ timeout: 10_000 });

  const saved = (await api(page, 'GET', `/live/${shared.liveId}`)).body.liveClass;
  expect(saved).toMatchObject({ title: titles.renamed, startsAt: expected, durationMin: 60 });
  expect(saved.capacity).toBeUndefined();
});

test('the instructor cancels the class with a reason, and Reschedule copies it into a new class', async ({ browser }) => {
  expect(shared.liveId, 'the class from the first step').toBeTruthy();
  const page = await instructorPage(browser);
  await page.goto(`/teach/live/${shared.liveId}`);
  await expect(page.getByRole('heading', { level: 1, name: titles.renamed })).toBeVisible({ timeout: 10_000 });

  await page.getByRole('button', { name: 'Cancel this class…' }).click();
  const dialog = page.getByRole('dialog', { name: 'Cancel this class?' });
  // No reason, no cancelling: the dialog stays open and says why.
  await dialog.getByRole('button', { name: 'Cancel class' }).click();
  await expect(dialog.getByText('Give learners a reason — a few words at least.')).toBeVisible();
  expect((await api(page, 'GET', `/live/${shared.liveId}`)).body.liveClass.cancelled).toBeUndefined();

  const reason = 'The instructor is unwell. We will run it next week.';
  await dialog.getByLabel('Reason for learners').fill(reason);
  await dialog.getByRole('button', { name: 'Cancel class' }).click();
  await expect(page.getByText('Class cancelled').first()).toBeVisible({ timeout: 10_000 });
  expect((await api(page, 'GET', `/live/${shared.liveId}`)).body.liveClass).toMatchObject({ cancelled: true, cancelReason: reason });

  // A cancelled class can't be edited, so Edit is gone; Reschedule opens a new class copied from it.
  await expect(page.getByRole('link', { name: 'Edit', exact: true })).toHaveCount(0);
  await page.getByRole('link', { name: 'Reschedule' }).click();
  await expect(page).toHaveURL(new RegExp(`/teach/live/new\\?from=${shared.liveId}$`));
  await expect(page.getByRole('heading', { level: 1, name: 'Schedule a live class' })).toBeVisible({ timeout: 10_000 });
  await expect(page.locator('#live-title')).toHaveValue(titles.renamed);
  await expect(page.locator('#live-start')).toHaveValue('04:30');
  await expect(page.locator('#live-course')).toHaveValue(shared.courseId!);
});

test('a learner sees an outside meeting without its link, and gets the link only by joining inside the window', async ({ browser }) => {
  test.setTimeout(60_000);
  expect(shared.courseId, 'the course from the first step').toBeTruthy();
  const teacher = await instructorPage(browser);
  const outside = (title: string, startsAt: string) => ({
    courseId: shared.courseId,
    title,
    instructorId: shared.instructorId,
    startsAt,
    durationMin: 45,
    meeting: { kind: 'external', link: MEETING },
    visibility: 'enrolled',
  });
  // Ten minutes from now is inside the join window (it opens 15 minutes before); two days from now is not.
  const soon = await api(teacher, 'POST', '/live', outside(titles.soon, new Date(Date.now() + 10 * 60_000).toISOString()));
  expect(soon.status, soon.text).toBe(201);
  shared.soonId = soon.body.id;
  const later = await api(teacher, 'POST', '/live', outside(titles.later, new Date(Date.now() + 2 * 86_400_000).toISOString()));
  expect(later.status, later.text).toBe(201);
  shared.laterId = later.body.id;
  // Staff still see the link.
  expect((await api(teacher, 'GET', `/live/${shared.soonId}`)).body.liveClass.meeting).toEqual({ kind: 'external', link: MEETING });

  const page = await learnerPage(browser);
  // Nowhere in the learner's data: their schedule, the class page, the course page.
  const schedule = await api(page, 'GET', '/live/learner');
  expect(schedule.status).toBe(200);
  expect(schedule.text).not.toContain(MEETING);
  const listed = [...schedule.body.live, ...schedule.body.upcoming].filter((r: { liveClass: { id: string } }) =>
    [shared.soonId, shared.laterId].includes(r.liveClass.id),
  );
  expect(listed).toHaveLength(2);
  for (const r of listed) expect(r.liveClass.meeting).toEqual({ kind: 'external', linkHost: 'meet.e2e.test' });
  const detail = await api(page, 'GET', `/live/${shared.soonId}`);
  expect(detail.text).not.toContain(MEETING);
  expect(detail.body.liveClass.meeting).toEqual({ kind: 'external', linkHost: 'meet.e2e.test' });
  expect((await api(page, 'GET', `/learning/courses/${shared.courseId}`)).text).not.toContain(MEETING);

  // Outside the window the API keeps the link.
  const early = await api(page, 'POST', `/live/${shared.laterId}/join`);
  expect(early.status).toBe(409);
  expect(early.text).not.toContain(MEETING);

  // Inside it, Join asks the API and opens what it hands over in a new tab — served here, never fetched.
  await page
    .context()
    .route('https://meet.e2e.test/**', (route) => route.fulfill({ status: 200, contentType: 'text/html', body: '<title>Meeting</title>Meeting' }));
  await page.goto(`/live/${shared.soonId}`);
  await expect(page.getByRole('heading', { level: 1, name: titles.soon })).toBeVisible({ timeout: 10_000 });
  const join = page.getByRole('region', { name: 'When and how to join' });
  await expect(join.getByText('Opens on meet.e2e.test')).toBeVisible();
  const popup = page.waitForEvent('popup');
  await join.getByRole('button', { name: 'Join class' }).click();
  const tab = await popup;
  await tab.waitForURL(MEETING, { timeout: 10_000 });
  expect(tab.url()).toBe(MEETING);

  // Joining took a place; the API vouches for nothing more (an outside meeting records no attendance).
  const after = (await api(page, 'GET', `/live/${shared.soonId}`)).body;
  expect(after.registered).toBe(true);
  expect(after.attended).toBeUndefined();
});

test('an admin without the live permissions is offered none of the actions the API would refuse', async ({ browser, request }) => {
  test.setTimeout(60_000);
  expect(shared.laterId, 'the class from the previous step').toBeTruthy();
  const headers = await platformHeaders(request);
  // A second staff admin, created with every permission, then narrowed.
  const created = await request.post(`${API}/superadmin/admins`, {
    headers,
    data: { name: limited.name, email: limited.email, password: PASSWORD },
  });
  expect(created.status(), await created.text()).toBe(201);
  shared.limitedId = ((await created.json()) as { id: string }).id;
  for (const key of ['live.manage', 'live.notify']) {
    const revoked = await request.delete(`${API}/superadmin/admins/${shared.limitedId}/permissions/${key}`, { headers });
    expect(revoked.ok(), await revoked.text()).toBe(true);
  }

  const page = await (await browser.newContext()).newPage();
  await signIn(page, limited.email, /dashboard|good (morning|afternoon|evening)|overview|welcome/i);
  const perms = (await api(page, 'GET', '/auth/me')).body.user.permissions as string[];
  expect(perms).not.toContain('live.manage');
  expect(perms).not.toContain('live.notify');

  await page.goto('/admin/live');
  await expect(page.getByRole('heading', { level: 1, name: 'Live classes' })).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('link', { name: 'Schedule a class' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Schedule a class' })).toHaveCount(0);

  // The class page shows the class, without Edit, Cancel or the reminder controls.
  await page.goto(`/admin/live/${shared.laterId}`);
  await expect(page.getByRole('heading', { level: 1, name: titles.later })).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('link', { name: 'Edit', exact: true })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Cancel this class…' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Send a reminder now' })).toHaveCount(0);
  await expect(page.getByRole('switch')).toHaveCount(0);

  // The editor says why instead of offering a form the API would refuse — and the API does refuse.
  await page.goto(`/admin/live/${shared.laterId}/edit`);
  await expect(page.getByText('You can’t schedule live classes')).toBeVisible({ timeout: 10_000 });
  expect((await api(page, 'POST', `/live/${shared.laterId}/cancel`, { reason: 'Not allowed' })).status).toBe(403);
  expect((await api(page, 'POST', `/live/${shared.laterId}/remind`)).status).toBe(403);
});
