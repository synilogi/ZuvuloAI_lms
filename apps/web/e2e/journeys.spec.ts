import { test, expect, type Browser, type BrowserContext, type Page } from '@playwright/test';
import { ADMIN_EMAIL, confirmEmailedCode, registerOnSite, freshEmail, INSTRUCTOR_EMAIL, PASSWORD, signIn } from './helpers';

/*
 * The role journeys end to end, live against the API. Each step a person takes is done through the UI; the API is
 * only read to prove what the step persisted (and, at the end, to tidy up).
 *
 *   1. An instructor asks to teach through the academy's link, the Admin approves them, and they sign in to teach.
 *   2. The Admin builds a course for that instructor — a chapter with a published article lesson — and publishes it.
 *   3. A new learner joins, enrols, reads the lesson and marks it complete; the progress is stored.
 *   4. The learner passes a quiz and hands in an assignment in a seeded course (Maths Foundations).
 *   5. That course's instructor grades the submission; the learner sees the grade and the feedback.
 *   6. The new instructor schedules a live class for their course; the learner sees it coming up and books a place.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const stamp = Date.now();
// People's names are letters only: the stamp spelt as letters keeps each run's people apart.
const tag = String(stamp)
  .slice(-6)
  .replace(/\d/g, (d) => 'abcdefghij'[Number(d)]);
const cap = (s: string) => s[0].toUpperCase() + s.slice(1);

const instructor = { name: `Anil ${cap(tag)}`, email: freshEmail() };
const learner = { name: `Kavya ${cap(tag)}`, email: freshEmail() };
const course = {
  title: `E2E Journey: Ratios ${stamp}`,
  description: 'A short course on ratios and proportion, built end to end by the journeys spec.',
  chapter: 'Ratios and Proportion',
  lesson: 'What a ratio tells you',
  body:
    'A ratio compares two quantities of the same kind. If a class has 12 girls and 18 boys, the ratio of girls to boys is 12 : 18, ' +
    'which simplifies to 2 : 3 by dividing both parts by 6. A proportion says two ratios are equal, such as 2 : 3 = 8 : 12.',
};
const SEEDED_COURSE = 'Maths Foundations for Classes 6–8';
const SEEDED_QUIZ_LESSON = 'Chapter check';
const SEEDED_ASSIGNMENT = 'Your first assignment: fractions at home';
const live = { title: `Ratios doubt-clearing class ${stamp}` };

const shared: {
  courseId?: string;
  lessonId?: string;
  instructorId?: string;
  assignmentId?: string;
  liveId?: string;
  adminToken?: string;
} = {};

const token = (page: Page) => page.evaluate(() => localStorage.getItem('syniastrolms:token'));
const api = async (page: Page, method: string, path: string, data?: unknown) => {
  const auth = await token(page);
  const res = await page.request.fetch(`${API}${path}`, { method, headers: auth ? { Authorization: `Bearer ${auth}` } : {}, data });
  return { status: res.status(), body: await res.json().catch(() => ({})) };
};

const fresh = async (browser: Browser) => (await browser.newContext()).newPage();

/* Sessions are signed in once and reopened: sign-ins share the API's per-client `/auth` budget with every other spec. */
type State = Awaited<ReturnType<BrowserContext['storageState']>>;
const sessions: Record<string, State | undefined> = {};
async function session(browser: Browser, key: string, home: string, signInWith?: { email: string; heading: RegExp }) {
  const state = sessions[key];
  if (state) {
    const page = await (await browser.newContext({ storageState: state })).newPage();
    await page.goto(home);
    return page;
  }
  if (!signInWith) throw new Error(`No session for ${key} yet — an earlier step did not finish.`);
  const page = await fresh(browser);
  await signIn(page, signInWith.email, signInWith.heading);
  sessions[key] = await page.context().storageState();
  return page;
}
const adminPage = (browser: Browser) =>
  session(browser, 'admin', '/admin', { email: ADMIN_EMAIL, heading: /dashboard|good (morning|afternoon|evening)|overview/i });
const learnerPage = (browser: Browser) => session(browser, 'learner', '/home');
const newInstructorPage = (browser: Browser) => session(browser, 'instructor', '/teach');

/** The academy's date (India Standard Time) `days` from now, as a date input takes it. */
const istDate = (days: number) => new Date(Date.now() + days * 86_400_000 + 330 * 60_000).toISOString().slice(0, 10);

test.describe.configure({ mode: 'serial' });

test.afterAll(async ({ playwright }) => {
  // Out of the way of the specs that read the published catalog and the live schedule.
  if (!shared.adminToken) return;
  const request = await playwright.request.newContext({ extraHTTPHeaders: { Authorization: `Bearer ${shared.adminToken}` } });
  if (shared.liveId) await request.post(`${API}/live/${shared.liveId}/cancel`, { data: { reason: 'E2E journey finished' } });
  if (shared.courseId) await request.post(`${API}/courses/${shared.courseId}/archive`);
  await request.dispose();
});

test('an instructor asks to teach, the Admin approves them, and they sign in to their teaching workspace', async ({ browser }) => {
  test.setTimeout(60_000);
  const visitor = await fresh(browser);
  await visitor.goto('/teach/apply');
  await expect(visitor.getByRole('heading', { level: 1, name: /^Teach on/ })).toBeVisible();
  await visitor.getByLabel('Full name').fill(instructor.name);
  await visitor.getByLabel('Email address').fill(instructor.email);
  await visitor.getByLabel('Mobile number').fill('+919812345670');
  await visitor.getByLabel('Password', { exact: true }).fill(PASSWORD);
  await visitor.getByLabel('What you teach').fill('Mathematics teacher');
  await visitor.getByLabel('Years of teaching experience').fill('5');
  await visitor.getByLabel('Subjects').fill('Mathematics');
  await visitor.getByLabel('About your teaching').fill('I have taught mathematics to Classes 6 to 8 for five years.');
  await visitor.getByLabel(/agree to the/i).check();
  await visitor.getByRole('button', { name: 'Send application' }).click();
  await confirmEmailedCode(visitor, instructor.email);
  await expect(visitor.getByText('Your application is being reviewed')).toBeVisible();

  // The Admin sees the request on the Instructors page and approves it.
  const admin = await adminPage(browser);
  shared.adminToken = (await token(admin)) ?? undefined;
  await admin.goto('/admin/instructors');
  const requests = admin.getByRole('region', { name: /Pending instructor applications/ });
  const row = requests.getByRole('listitem').filter({ hasText: instructor.email });
  await expect(row).toBeVisible({ timeout: 10_000 });
  await expect(row.getByText(instructor.name)).toBeVisible();
  await row.getByRole('button', { name: 'Approve' }).click();
  await expect(admin.getByText(`${instructor.name} is now an instructor`)).toBeVisible({ timeout: 10_000 });
  await expect(admin.getByRole('listitem').filter({ hasText: instructor.email })).toHaveCount(0);

  // Persisted: no longer waiting, and an active instructor of this academy.
  const pending = (await api(admin, 'GET', '/instructors/requests')).body as { email: string }[];
  expect(pending.map((r) => r.email)).not.toContain(instructor.email);

  // They sign in with what they registered with and land in the teaching workspace.
  const teacher = await fresh(browser);
  await signIn(teacher, instructor.email, /Teaching overview/i);
  await expect(teacher).toHaveURL(/\/teach$/);
  const me = (await api(teacher, 'GET', '/auth/me')).body.user;
  expect(me).toMatchObject({ email: instructor.email, role: 'instructor' });
  sessions.instructor = await teacher.context().storageState();
});

test('the Admin builds a course for the new instructor — a chapter with a published article — and publishes it', async ({ browser }) => {
  test.setTimeout(90_000);
  const page = await adminPage(browser);

  await page.goto('/admin/courses/new');
  await expect(page.getByRole('heading', { level: 1, name: 'New course' })).toBeVisible({ timeout: 10_000 });
  await page.getByLabel('Course title').fill(course.title);
  await page.getByLabel('Description').fill(course.description);
  const people = page.getByRole('group', { name: 'Instructors' });
  await people.getByRole('checkbox', { name: new RegExp(instructor.name) }).check();
  await page.getByRole('button', { name: 'Save draft' }).click();
  await expect(page.getByText('Draft saved').first()).toBeVisible({ timeout: 10_000 });
  await expect(page).toHaveURL(/\/admin\/courses\/[^/]+$/);
  shared.courseId = page.url().split('/').pop()!;
  const draft = (await api(page, 'GET', `/courses/${shared.courseId}`)).body;
  expect(draft).toMatchObject({ status: 'draft', title: course.title, description: course.description });
  expect(draft.instructorIds).toHaveLength(1);
  shared.instructorId = draft.instructorIds[0];

  // A chapter — new chapters start as drafts.
  await page.getByRole('link', { name: /^Curriculum/ }).click();
  await expect(page).toHaveURL(new RegExp(`/admin/courses/${shared.courseId}/curriculum$`));
  await page.getByRole('button', { name: 'Add chapter' }).first().click();
  const panel = page.getByRole('dialog', { name: 'Add a chapter' });
  await panel.getByLabel('Chapter title').fill(course.chapter);
  await panel.getByRole('button', { name: 'Add chapter' }).click();
  await expect(page.getByText('Chapter added').first()).toBeVisible({ timeout: 10_000 });
  await expect(panel).toBeHidden();

  // An article lesson in it, published.
  await page.getByRole('link', { name: 'Add lesson' }).first().click();
  await expect(page).toHaveURL(/\/lessons\/new\?chapter=/);
  await page.locator('#lesson-title').fill(course.lesson);
  await page.getByRole('radio', { name: /^Article/ }).check();
  await page.locator('#lesson-body').fill(course.body);
  await expect(page.getByText('Ready to publish')).toBeVisible();
  await page.getByRole('button', { name: 'Publish', exact: true }).click();
  await expect(page.getByText('Lesson published').first()).toBeVisible({ timeout: 10_000 });
  await expect(page).toHaveURL(new RegExp(`/admin/courses/${shared.courseId}/lessons/(?!new)[^/?]+$`));
  shared.lessonId = page.url().split('/').pop()!;

  // The chapter is published now that it has a lesson, then the course.
  await page.goto(`/admin/courses/${shared.courseId}/curriculum`);
  await page.getByRole('button', { name: `More actions for ${course.chapter}` }).click();
  await page.getByRole('menuitem', { name: /Publish chapter/ }).click();
  await expect(page.getByText('Chapter published').first()).toBeVisible({ timeout: 10_000 });

  await page.getByRole('button', { name: 'Publish', exact: true }).click();
  const confirm = page.getByRole('dialog', { name: `Publish ${course.title}?` });
  await confirm.getByRole('button', { name: 'Publish course' }).click();
  await expect(page.getByText('Course published').first()).toBeVisible({ timeout: 10_000 });

  const live = (await api(page, 'GET', `/courses/${shared.courseId}`)).body;
  expect(live).toMatchObject({ status: 'published', instructorIds: [shared.instructorId] });
  expect(live.chapters).toHaveLength(1);
  expect(live.chapters[0]).toMatchObject({ title: course.chapter, status: 'published' });
  expect(live.chapters[0].lessons).toHaveLength(1);
  expect(live.chapters[0].lessons[0]).toMatchObject({ id: shared.lessonId, title: course.lesson, type: 'reading', status: 'published' });
});

test('a new learner joins, enrols in that course, reads the lesson and marks it complete', async ({ browser }) => {
  test.setTimeout(60_000);
  expect(shared.courseId, 'the course from the previous step').toBeTruthy();
  const page = await fresh(browser);
  await registerOnSite(page, learner.name, learner.email);
  sessions.learner = await page.context().storageState();

  // Found in the catalog by its title.
  await page.goto('/explore');
  await page.getByLabel('Search courses').fill(course.title);
  await page.locator(`a[href="/learn/${shared.courseId}"]`).filter({ hasText: course.title }).click();
  await expect(page.getByRole('heading', { level: 1, name: course.title })).toBeVisible({ timeout: 10_000 });
  await page.getByRole('button', { name: /^Enroll/ }).click();

  // Enrolling opens the first lesson: the article, with its completion button.
  await expect(page).toHaveURL(new RegExp(`/learn/${shared.courseId}/lessons/${shared.lessonId}$`), { timeout: 10_000 });
  await expect(page.getByRole('heading', { level: 1, name: course.lesson })).toBeVisible();
  await expect(page.getByText('A ratio compares two quantities of the same kind.', { exact: false })).toBeVisible();
  await page.getByRole('button', { name: 'Mark complete' }).click();
  await expect(page.getByRole('button', { name: 'Completed' }).first()).toBeVisible({ timeout: 10_000 });

  // Stored: the lesson is complete and so is the one-lesson course.
  const shape = (await api(page, 'GET', `/learning/courses/${shared.courseId}`)).body;
  expect(shape.enrolled).toBe(true);
  expect(shape.snapshot.lessons[shared.lessonId!].state).toBe('completed');
  expect(shape.progress.percent).toBe(100);

  // And it survives a reload.
  await page.reload();
  await expect(page.getByRole('button', { name: 'Completed' }).first()).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('button', { name: 'Mark complete' })).toHaveCount(0);
});

test('the learner passes a quiz and hands in an assignment in a seeded course', async ({ browser }) => {
  test.setTimeout(60_000);
  const page = await learnerPage(browser);
  await page.goto('/explore');
  await page.getByLabel('Search courses').fill('Maths Foundations');
  const link = page.locator('a[href^="/learn/"]').filter({ hasText: SEEDED_COURSE });
  await expect(link).toBeVisible({ timeout: 10_000 });
  await link.click();
  await expect(page.getByRole('heading', { level: 1, name: SEEDED_COURSE })).toBeVisible({ timeout: 10_000 });
  const courseId = new URL(page.url()).pathname.split('/').pop()!;
  await page.getByRole('button', { name: /^Enroll/ }).click();
  await expect(page).toHaveURL(/\/lessons\//, { timeout: 10_000 });

  // A chapter's quiz opens once its lessons are finished: the video (watched to the end), then the article.
  await expect(page.getByRole('heading', { level: 1, name: /^Introduction to integers/ })).toBeVisible({ timeout: 10_000 });
  const seek = page.getByRole('slider', { name: 'Seek' });
  await seek.fill((await seek.getAttribute('max')) ?? '1080');
  // The server counts the position the player saves, which can land just after the click, so a refused click is tried again.
  await expect(async () => {
    const mark = page.getByRole('button', { name: 'Mark complete' });
    if (await mark.count()) await mark.click();
    await expect(page.getByRole('button', { name: 'Completed' }).first()).toBeVisible({ timeout: 2_000 });
  }).toPass({ timeout: 20_000 });
  await page
    .getByRole('link', { name: /^Next lesson: The rules of signs/ })
    .first()
    .click();
  await expect(page.getByRole('heading', { level: 1, name: 'The rules of signs' })).toBeVisible({ timeout: 10_000 });
  await page.getByRole('button', { name: 'Mark complete' }).click();
  await expect(page.getByRole('button', { name: 'Completed' }).first()).toBeVisible({ timeout: 10_000 });
  await page
    .getByRole('link', { name: `Next lesson: ${SEEDED_QUIZ_LESSON}` })
    .first()
    .click();
  await expect(page.getByRole('heading', { level: 1, name: SEEDED_QUIZ_LESSON })).toBeVisible({ timeout: 10_000 });
  const quizLessonId = new URL(page.url()).pathname.split('/').pop()!;
  // The attempt is the server's: Start begins a session, whose questions come with it; answers save as they go.
  await page.getByRole('button', { name: 'Start quiz' }).click();
  await page.getByRole('radio', { name: '12', exact: true }).check();
  await page.getByRole('button', { name: 'Next' }).click();
  await page.getByRole('radio', { name: 'False', exact: true }).check();
  await page.getByRole('button', { name: 'Next' }).click();
  await page.getByRole('textbox', { name: 'Your answer' }).fill('75%');
  await page.getByRole('button', { name: 'Review answers' }).click();
  await expect(page.getByRole('heading', { name: 'Check before you submit' })).toBeVisible();
  await page.getByRole('button', { name: 'Submit answers' }).click();
  await expect(page.getByText('Passed', { exact: true }).first()).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole('heading', { name: '30 of 30 points' })).toBeVisible();

  const attempts = (await api(page, 'GET', `/learning/courses/${courseId}/lessons/${quizLessonId}/quiz-attempts`)).body.attempts as {
    passed: boolean;
    percent: number;
  }[];
  expect(attempts).toHaveLength(1);
  expect(attempts[0]).toMatchObject({ passed: true, percent: 100 });

  // The assignment, opened from the course page's to-do list.
  await page.goto(`/learn/${courseId}`);
  const todo = page.getByRole('list', { name: 'Assignments to do' }).getByRole('listitem').filter({ hasText: SEEDED_ASSIGNMENT });
  await todo.getByRole('button').click();
  await expect(page).toHaveURL(/\/assignments\/[^/]+$/, { timeout: 10_000 });
  shared.assignmentId = new URL(page.url()).pathname.split('/').pop()!;
  const response =
    'Recipe: 3/4 cup of milk = 0.75 = 75%. I divided 3 by 4. Medicine label: 1/2 tablet = 0.5 = 50%. I halved one whole. ' +
    'Electricity bill: 1/4 of the units at night = 0.25 = 25%. I divided 1 by 4.';
  await page.getByLabel('Your response').fill(response);
  await page.getByRole('button', { name: 'Submit for review' }).click();
  await expect(page.getByText('Submitted for review').first()).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText('Submitted — waiting for review')).toBeVisible();

  const item = (await api(page, 'GET', `/learning/assignments/${shared.assignmentId}`)).body;
  expect(item.submission).toMatchObject({ text: response, attempt: 1 });
  expect(item.submission.review.status).toBe('waiting');
});

test('the course’s instructor grades the submission, and the learner sees the grade', async ({ browser }) => {
  test.setTimeout(60_000);
  expect(shared.assignmentId, 'the submission from the previous step').toBeTruthy();
  const page = await session(browser, 'meenakshi', '/teach', { email: INSTRUCTOR_EMAIL, heading: /Teaching overview/i });

  // The submission waits in the review queue.
  await page.goto(`/teach/assignments/review?q=${encodeURIComponent(learner.email)}`);
  const review = page.getByRole('link', { name: `Review ${learner.name}’s submission` });
  await expect(review).toBeVisible({ timeout: 10_000 });
  await review.click();
  await expect(page).toHaveURL(new RegExp(`/teach/assignments/${shared.assignmentId}/submissions/[^/]+$`));
  await expect(page.getByRole('heading', { level: 1, name: learner.name })).toBeVisible();

  await page.getByLabel('Score', { exact: true }).fill('88');
  const feedback = 'Clear conversions and well-chosen examples — show the division for the bill too.';
  await page.getByLabel('Feedback for the learner').fill(feedback);
  await page.getByRole('button', { name: 'Submit review' }).click();
  await expect(page.getByText(`Review sent to ${learner.name.split(' ')[0]}`).first()).toBeVisible({ timeout: 20_000 });

  // The learner sees the score and the feedback on their assignment.
  const mine = await learnerPage(browser);
  await mine.goto(`/assignments/${shared.assignmentId}`);
  await expect(mine.getByText(feedback)).toBeVisible({ timeout: 10_000 });
  await expect(mine.getByText('/ 100')).toBeVisible();
  await expect(mine.getByText('88', { exact: true })).toBeVisible();
  await expect(mine.getByText('Passed', { exact: true })).toBeVisible();

  const item = (await api(mine, 'GET', `/learning/assignments/${shared.assignmentId}`)).body;
  expect(item.submission.review).toMatchObject({ status: 'graded', score: 88, feedback });
});

test('the new instructor schedules a live class, and the learner sees it coming up and books a place', async ({ browser }) => {
  test.setTimeout(60_000);
  expect(shared.courseId, 'the course from the earlier step').toBeTruthy();
  const teacher = await newInstructorPage(browser);
  await teacher.goto('/teach/live/new');
  await expect(teacher.getByRole('heading', { level: 1, name: 'Schedule a live class' })).toBeVisible({ timeout: 10_000 });
  await teacher.locator('#live-title').fill(live.title);
  await teacher.locator('#live-course').selectOption({ label: course.title });
  await teacher.locator('#live-date').fill(istDate(2));
  await teacher.getByRole('button', { name: 'Schedule class' }).click();
  await expect(teacher.getByText('Class scheduled').first()).toBeVisible({ timeout: 10_000 });

  const own = (await api(teacher, 'GET', `/live?search=${encodeURIComponent(live.title)}&page=1&pageSize=20`)).body.rows as {
    liveClass: { id: string; title: string; courseId: string; instructorId: string };
  }[];
  expect(own, 'the class is in the instructor’s schedule').toHaveLength(1);
  expect(own[0].liveClass).toMatchObject({ title: live.title, courseId: shared.courseId, instructorId: shared.instructorId });
  shared.liveId = own[0].liveClass.id;

  // The learner, enrolled in that course, sees it under Coming up — with a place to book.
  const page = await learnerPage(browser);
  await page.goto('/live');
  const upcoming = page.getByRole('region', { name: /Coming up/ });
  const row = upcoming.getByRole('listitem').filter({ hasText: live.title });
  await expect(row).toBeVisible({ timeout: 10_000 });
  await expect(row.getByText(course.title)).toBeVisible();
  await row.getByRole('button', { name: 'Register' }).click();
  await expect(page.getByText('You’re registered').first()).toBeVisible({ timeout: 10_000 });
  await expect(row.getByRole('button', { name: `Registered for ${live.title}. Cancel registration` })).toBeVisible();

  // The class page is where they join: the room opens there once the instructor starts it.
  await row.getByRole('link', { name: live.title }).click();
  await expect(page).toHaveURL(new RegExp(`/live/${shared.liveId}$`));
  await expect(page.getByRole('heading', { level: 1, name: live.title })).toBeVisible();
  const join = page.getByRole('region', { name: 'When and how to join' });
  await expect(join).toBeVisible();
  await expect(join.getByRole('button', { name: `Registered for ${live.title}. Cancel registration` })).toBeVisible();

  const schedule = (await api(page, 'GET', '/live/learner')).body as { upcoming: { liveClass: { id: string }; registered: boolean }[] };
  expect(schedule.upcoming.find((r) => r.liveClass.id === shared.liveId)).toMatchObject({ registered: true });
  const shape = (await api(page, 'GET', `/learning/courses/${shared.courseId}`)).body as { live: { id: string }[] };
  expect(shape.live.map((l) => l.id)).toContain(shared.liveId);
});
