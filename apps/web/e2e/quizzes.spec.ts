import { test, expect, type Browser, type BrowserContext, type Page } from '@playwright/test';
import { ADMIN_EMAIL, registerOnSite, freshEmail, INSTRUCTOR_EMAIL, signIn } from './helpers';

/*
 * Quiz attempts the server runs, end to end against the API. Setup (a course with two quiz lessons) is made through
 * the API; every step a person takes is done in the UI, and the API is read to prove what it stored.
 *
 *   1. Staff set a time limit and a closing time on a quiz in the builder; the server stores the close as the IST moment.
 *   2. A learner starts it, answers, sees "Saved", reloads — and is back in the same attempt with their answers and the
 *      clock still running down — then hands it in (with a double click) and sees one result.
 *   3. A learner who has used the quiz's only attempt is told why they can't start again.
 *   4. Staff archive the quiz and read every attempt in its results.
 */

const API = process.env.E2E_API_URL ?? 'http://localhost:4000';
const stamp = Date.now();
const tag = String(stamp)
  .slice(-6)
  .replace(/\d/g, (d) => 'abcdefghij'[Number(d)]);
const learner = { name: `Meera ${tag[0].toUpperCase()}${tag.slice(1)}`, email: freshEmail() };
const course = { title: `E2E Quizzes: Arithmetic ${stamp}`, chapter: 'Multiplication', timed: 'Timed check', single: 'One-try check' };

const shared: { courseId?: string; timedQuizId?: string; timedLessonId?: string; singleLessonId?: string; adminToken?: string } = {};

const token = (page: Page) => page.evaluate(() => localStorage.getItem('syniastrolms:token'));
const api = async (page: Page, method: string, path: string, data?: unknown) => {
  const auth = await token(page);
  const res = await page.request.fetch(`${API}${path}`, { method, headers: auth ? { Authorization: `Bearer ${auth}` } : {}, data });
  return { status: res.status(), body: await res.json().catch(() => ({})) };
};

/* Sessions are signed in once and reopened: sign-ins share the API's per-client `/auth` budget with every other spec. */
type State = Awaited<ReturnType<BrowserContext['storageState']>>;
const sessions: Record<string, State | undefined> = {};
async function reopen(browser: Browser, key: string, home: string) {
  const state = sessions[key];
  if (!state) throw new Error(`No session for ${key} yet — an earlier step did not finish.`);
  const page = await (await browser.newContext({ storageState: state })).newPage();
  await page.goto(home);
  return page;
}

/** The academy's date (India Standard Time) `days` from now, as a date input takes it. */
const istDate = (days: number) => new Date(Date.now() + days * 86_400_000 + 330 * 60_000).toISOString().slice(0, 10);
/** "9:58" → 598. */
const clockSeconds = (text: string) => {
  const [m, s] = text.trim().split(':').map(Number);
  return m * 60 + s;
};

const questions = [
  {
    id: 'q1',
    type: 'single',
    prompt: 'What is 7 × 8?',
    options: [
      { id: 'a', text: '54' },
      { id: 'b', text: '56' },
      { id: 'c', text: '64' },
    ],
    correct: ['b'],
    acceptedAnswers: [],
    points: 10,
    negativePoints: 2,
    required: true,
  },
  {
    id: 'q2',
    type: 'true-false',
    prompt: 'A square has four equal sides.',
    options: [
      { id: 'true', text: 'True' },
      { id: 'false', text: 'False' },
    ],
    correct: ['true'],
    acceptedAnswers: [],
    points: 10,
    required: true,
  },
  { id: 'q3', type: 'short', prompt: 'Write 1/2 as a percentage.', options: [], correct: [], acceptedAnswers: ['50%', '50'], points: 10, required: true },
];
const settings = { passMark: 70, attempts: 2, shuffleQuestions: false, shuffleOptions: false, showResults: 'score-and-answers' };

test.describe.configure({ mode: 'serial' });

test.afterAll(async ({ playwright }) => {
  if (!shared.adminToken || !shared.courseId) return;
  const request = await playwright.request.newContext({ extraHTTPHeaders: { Authorization: `Bearer ${shared.adminToken}` } });
  await request.post(`${API}/courses/${shared.courseId}/archive`);
  await request.dispose();
});

test('staff set a time limit and a closing time on a quiz in the builder', async ({ browser }) => {
  test.setTimeout(60_000);
  const admin = await (await browser.newContext()).newPage();
  await signIn(admin, ADMIN_EMAIL, /dashboard|good (morning|afternoon|evening)|overview/i);
  sessions.admin = await admin.context().storageState();
  shared.adminToken = (await token(admin)) ?? undefined;

  // The course, its chapter and two quiz lessons — made through the API.
  const teachers = (await api(admin, 'GET', '/instructors')).body.rows as { instructor: { id: string; email: string } }[];
  const instructorId = teachers.find((r) => r.instructor.email === INSTRUCTOR_EMAIL)!.instructor.id;
  const made = await api(admin, 'POST', '/courses', { title: course.title, description: 'Quick checks on multiplication.', instructorIds: [instructorId] });
  expect(made.status).toBe(201);
  shared.courseId = made.body.id;
  const chapter = await api(admin, 'POST', `/courses/${shared.courseId}/chapters`, { input: { title: course.chapter, status: 'published' } });
  expect(chapter.status).toBe(201);
  const lesson = async (title: string) => {
    const res = await api(admin, 'POST', `/courses/${shared.courseId}/lessons`, {
      chapterId: chapter.body.id,
      input: { title, type: 'assessment', status: 'published', durationMin: 10 },
    });
    expect(res.status).toBe(201);
    return res.body.id as string;
  };
  shared.timedLessonId = await lesson(course.timed);
  shared.singleLessonId = await lesson(course.single);
  const quiz = (lessonId: string, title: string, over: Record<string, unknown> = {}) =>
    api(admin, 'POST', '/quizzes', {
      courseId: shared.courseId,
      chapterId: chapter.body.id,
      lessonId,
      title,
      instructions: 'Answer every question.',
      status: 'published',
      questions,
      settings: { ...settings, ...over },
    });
  const timed = await quiz(shared.timedLessonId, `${course.timed} ${stamp}`);
  expect(timed.status).toBe(201);
  shared.timedQuizId = timed.body.id;
  expect((await quiz(shared.singleLessonId, `${course.single} ${stamp}`, { attempts: 1 })).status).toBe(201);
  expect((await api(admin, 'POST', `/courses/${shared.courseId}/publish`)).status).toBe(200);

  // In the builder: a ten-minute limit, and a close tomorrow at 23:30 IST.
  await admin.goto(`/admin/quizzes/${shared.timedQuizId}/settings`);
  await admin.getByRole('switch', { name: 'Limit the time' }).click();
  await admin.getByLabel('Minutes').fill('10');
  const closesDate = istDate(1);
  await admin.getByLabel('Closing date').fill(closesDate);
  await admin.getByLabel('Closing time').fill('23:30');
  await admin.getByRole('button', { name: 'Save', exact: true }).first().click();
  await expect(admin.getByText('Changes saved').first()).toBeVisible({ timeout: 10_000 });

  const stored = (await api(admin, 'GET', `/quizzes/${shared.timedQuizId}`)).body;
  expect(stored.settings.timeLimitMin).toBe(10);
  // Sent as the IST moment with its offset; stored as the same instant.
  expect(stored.settings.closesAt).toBe(new Date(`${closesDate}T23:30:00+05:30`).toISOString());
  expect(stored.questions[0].negativePoints).toBe(2);

  // Read back after a reload, the inputs show the same IST date and time.
  await admin.reload();
  await expect(admin.getByLabel('Closing date')).toHaveValue(closesDate);
  await expect(admin.getByLabel('Closing time')).toHaveValue('23:30');
});

test('a learner starts the timed quiz, reloads mid-attempt, resumes with their answers and the clock running, and hands it in once', async ({ browser }) => {
  test.setTimeout(90_000);
  expect(shared.timedLessonId, 'the quiz from the previous step').toBeTruthy();
  const page = await (await browser.newContext()).newPage();
  await registerOnSite(page, learner.name, learner.email);
  sessions.learner = await page.context().storageState();
  expect((await api(page, 'POST', `/learning/courses/${shared.courseId}/enroll`)).status).toBe(200);

  const lessonUrl = `/learn/${shared.courseId}/lessons/${shared.timedLessonId}`;
  await page.goto(lessonUrl);
  await expect(page.getByRole('heading', { level: 1, name: course.timed })).toBeVisible({ timeout: 10_000 });
  // The introduction says what the attempt will be, before anything starts.
  const fact = (text: string) => page.getByRole('definition').filter({ hasText: new RegExp(`^${text}$`) });
  await expect(fact('10 min')).toBeVisible();
  await expect(fact('0 of 2')).toBeVisible();
  await expect(page.getByText(/^Closes /)).toBeVisible();
  await expect(page.getByText(/keeps running if you leave/)).toBeVisible();
  // Nothing is started by reading the lesson.
  const before = (await api(page, 'GET', `/learning/courses/${shared.courseId}/lessons/${shared.timedLessonId}/quiz-attempts`)).body;
  expect(before.standing).toMatchObject({ attemptsUsed: 0, canStart: true });
  expect(before.standing.openSession).toBeUndefined();

  await page.getByRole('button', { name: 'Start quiz' }).click();
  const saved = page.getByRole('status').filter({ hasText: /^\s*Saved$/ });
  const timer = page.getByRole('timer');
  await expect(timer).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText('Wrong answers lose marks.')).toBeVisible();
  await page.getByRole('radio', { name: '56', exact: true }).check();
  await expect(saved).toBeVisible({ timeout: 10_000 });
  await page.getByRole('button', { name: 'Next' }).click();
  await page.getByRole('radio', { name: 'True', exact: true }).check();
  await expect(page.getByRole('status').filter({ hasText: /Saving…/ })).toHaveCount(0, { timeout: 10_000 });
  await expect(saved).toBeVisible();

  // The server holds both answers, numbered.
  const open = (await api(page, 'GET', `/learning/courses/${shared.courseId}/lessons/${shared.timedLessonId}/quiz-session`)).body.session;
  expect(open).toMatchObject({ status: 'active', answers: { q1: ['b'], q2: ['true'] } });
  expect(open.answersSeq).toBeGreaterThanOrEqual(2);

  const leftBefore = clockSeconds((await timer.textContent()) ?? '');
  expect(leftBefore).toBeLessThanOrEqual(600);
  await page.waitForTimeout(2500);
  await page.reload();

  // Back in the same attempt: the answers the server holds, and a clock that kept running.
  await expect(timer).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText('Attempt 1', { exact: true })).toBeVisible();
  const leftAfter = clockSeconds((await timer.textContent()) ?? '');
  expect(leftAfter).toBeLessThan(leftBefore);
  expect(leftAfter).toBeGreaterThan(500);
  await expect(page.getByRole('radio', { name: '56', exact: true })).toBeChecked();
  await expect(page.getByRole('button', { name: 'Question 2, answered' })).toBeVisible();
  await page.getByRole('button', { name: 'Question 3, not answered' }).click();
  await page.getByRole('textbox', { name: 'Your answer' }).fill('50%');

  // The check before submitting, then a double click: one submission, one attempt.
  await page.getByRole('button', { name: 'Review answers' }).click();
  await expect(page.getByRole('heading', { name: 'Check before you submit' })).toBeVisible();
  await expect(page.getByText('Every question has an answer.', { exact: false })).toBeVisible();
  // Two clicks in one tick: a real double click can land its second click on what replaces the button.
  await page.getByRole('button', { name: 'Submit answers' }).evaluate((b: HTMLElement) => {
    b.click();
    b.click();
  });
  await expect(page.getByText('Passed', { exact: true }).first()).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole('heading', { name: '30 of 30 points' })).toBeVisible();
  await expect(page.getByRole('list', { name: 'Your answers' }).getByRole('listitem')).toHaveCount(3);

  const after = (await api(page, 'GET', `/learning/courses/${shared.courseId}/lessons/${shared.timedLessonId}/quiz-attempts`)).body;
  expect(after.attempts).toHaveLength(1);
  expect(after.attempts[0]).toMatchObject({ attemptNo: 1, passed: true, percent: 100, finish: 'submitted' });
  expect(after.standing).toMatchObject({ attemptsUsed: 1, passed: true });
  expect(after.standing.openSession).toBeUndefined();
  // Handing in again — a retry — answers with the same attempt.
  const again = await api(page, 'POST', `/learning/courses/${shared.courseId}/lessons/${shared.timedLessonId}/quiz-session/${open.id}/submit`, {});
  expect(again.body.review.attemptId).toBe(after.attempts[0].attemptId);
});

test('a learner who has used the only attempt is told why they cannot start again', async ({ browser }) => {
  test.setTimeout(60_000);
  const page = await reopen(browser, 'learner', '/home');
  await page.goto(`/learn/${shared.courseId}/lessons/${shared.singleLessonId}`);
  await expect(page.getByRole('heading', { level: 1, name: course.single })).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('definition').filter({ hasText: /^0 of 1$/ })).toBeVisible();
  await page.getByRole('button', { name: 'Start quiz' }).click();
  await page.getByRole('radio', { name: '54', exact: true }).check();
  // From any question, the check before submitting is one step away.
  await page.getByRole('button', { name: 'Review and submit' }).click();
  await expect(page.getByText('2 questions not answered')).toBeVisible();
  await page.getByRole('button', { name: 'Submit answers' }).click();
  await expect(page.getByText('Not passed yet').first()).toBeVisible({ timeout: 15_000 });
  // A wrong answer lost its negative marks.
  await expect(page.getByRole('heading', { name: '−2 of 30 points' })).toBeVisible();
  await expect(page.getByText('You have used all 1 attempts for this quiz.')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Try again' })).toHaveCount(0);

  // Coming back later: the reason, and no way to start.
  await page.reload();
  await expect(page.getByText('You have used all 1 attempts for this quiz.')).toBeVisible({ timeout: 10_000 });
  await expect(page.getByRole('button', { name: 'Start a new attempt' })).toBeDisabled();
  await expect(page.getByRole('region', { name: 'Your attempts' }).getByText('0% · Not passed')).toBeVisible();
  const refused = await api(page, 'POST', `/learning/courses/${shared.courseId}/lessons/${shared.singleLessonId}/quiz-session`, { startKey: `e2e-${stamp}-x` });
  expect(refused.status).toBe(409);
});

test('staff archive the quiz and read every attempt in its results', async ({ browser }) => {
  test.setTimeout(60_000);
  const admin = await reopen(browser, 'admin', '/admin');
  await admin.goto(`/admin/quizzes?q=${encodeURIComponent(`${course.timed} ${stamp}`)}`);
  await admin
    .getByRole('button', { name: `More actions for ${course.timed} ${stamp}` })
    .first()
    .click();
  await admin.getByRole('menuitem', { name: 'Archive' }).click();
  await expect(admin.getByText('Quiz archived').first()).toBeVisible({ timeout: 10_000 });
  expect((await api(admin, 'GET', `/quizzes/${shared.timedQuizId}`)).body.status).toBe('archived');

  // The archived filter finds it.
  await admin.getByRole('radio', { name: /^Archived/ }).click();
  await expect(admin.getByRole('link', { name: `${course.timed} ${stamp}` }).first()).toBeVisible({ timeout: 10_000 });

  // Its results list the learner's attempt.
  await admin.goto(`/admin/quizzes/${shared.timedQuizId}/results`);
  await expect(admin.getByText('This quiz is archived.')).toBeVisible({ timeout: 10_000 });
  const attempts = admin.getByRole('region', { name: 'Attempts' });
  const row = attempts.getByRole('row').filter({ hasText: learner.email });
  await expect(row).toBeVisible({ timeout: 10_000 });
  await expect(row.getByText('Submitted')).toBeVisible();
  await expect(row.getByText('100%')).toBeVisible();
  await expect(row.getByText('#1')).toBeVisible();

  // An archived quiz is gone from the learner's lesson, and no new attempt starts.
  const learnerPage = await reopen(browser, 'learner', '/home');
  const start = await api(learnerPage, 'POST', `/learning/courses/${shared.courseId}/lessons/${shared.timedLessonId}/quiz-session`, {
    startKey: `e2e-${stamp}-y`,
  });
  expect(start.status).toBe(404);
});
