import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { PERMISSION_KEYS, type PermissionKey } from '@syniastrolms/domain';

import { T, db, inAcademy } from '../test/db.js';
import { grantAllPermissions, permissionsFor } from '../lib/permissions.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { ACCOUNTS, anon, app, as, unique, type Client } from '../test/helpers.js';

/* The capabilities the academy shares between the teaching workspace and the admin workspace.
 *
 * The rule under test: an instructor passes on their role as they always have, while an admin must
 * hold the key. Every case works on its own admin, so the seeded one keeps its full catalogue. */

const SECRET = 'shared-enforcement-password';
const ADMIN_PASSWORD = 'a-shared-capability-admin';
const CALENDAR_WINDOW = { from: '2026-01-01', to: '2026-12-31' };

let platform: Client;
let admin: Client;
let adminId = '';
let instructor: Client;
let student: Client;
let courseId = '';
const created: string[] = [];

type Call = (c: Client) => Promise<{ status: number }>;

/** Each newly protected capability: the key that opens it, and a request that reaches the guard. */
interface Capability {
  name: string;
  key: PermissionKey;
  call: Call;
}

const capabilities = (): Capability[] => [
  /* Reads use list endpoints, which change nothing. Writes aim at ids that match nothing: the guard
   * is middleware and runs before the resource is ever looked up, so "403 without the key, past the
   * guard with it" is proven without touching a single record of the seeded academy. The nested
   * course routers are the exception — their router-level scope check runs first, so they need a
   * real course to reach the permission check at all. */
  { name: 'GET /courses', key: 'catalog.view', call: (c) => c.get('/courses') },
  { name: 'GET /courses/:id', key: 'catalog.view', call: (c) => c.get(`/courses/${courseId}`) },
  { name: 'GET /courses/:id/chapters/stats', key: 'catalog.view', call: (c) => c.get(`/courses/${courseId}/chapters/stats`) },
  { name: 'GET /courses/:id/lessons', key: 'catalog.view', call: (c) => c.get(`/courses/${courseId}/lessons`) },
  { name: 'GET /categories', key: 'catalog.view', call: (c) => c.get('/categories') },
  { name: 'PATCH /courses/:id', key: 'catalog.edit', call: (c) => c.patch('/courses/no-such-course', { subtitle: 'No' }) },
  { name: 'PATCH chapters/:id', key: 'catalog.edit', call: (c) => c.patch(`/courses/${courseId}/chapters/no-such-chapter`, { title: 'No' }) },
  { name: 'PATCH lessons/:id', key: 'catalog.edit', call: (c) => c.patch(`/courses/${courseId}/lessons/no-such-lesson`, { title: 'No' }) },
  { name: 'POST /courses/:id/publish', key: 'catalog.publish', call: (c) => c.post('/courses/no-such-course/publish') },
  { name: 'POST /courses/:id/unpublish', key: 'catalog.publish', call: (c) => c.post('/courses/no-such-course/unpublish') },
  { name: 'POST /courses/:id/archive', key: 'catalog.archive', call: (c) => c.post('/courses/no-such-course/archive') },
  { name: 'POST /courses/:id/restore', key: 'catalog.archive', call: (c) => c.post('/courses/no-such-course/restore') },
  { name: 'GET /quizzes', key: 'assessment.view', call: (c) => c.get('/quizzes') },
  { name: 'GET /assignments', key: 'assessment.view', call: (c) => c.get('/assignments') },
  { name: 'GET /assignments/review', key: 'assessment.view', call: (c) => c.get('/assignments/review') },
  { name: 'PATCH /quizzes/:id', key: 'assessment.edit', call: (c) => c.patch('/quizzes/no-such-quiz', { title: 'No' }) },
  { name: 'DELETE /quizzes/:id', key: 'assessment.edit', call: (c) => c.delete('/quizzes/no-such-quiz') },
  { name: 'PATCH /assignments/:id', key: 'assessment.edit', call: (c) => c.patch('/assignments/no-such-assignment', { title: 'No' }) },
  {
    name: 'POST /assignments/submissions/:id/review',
    key: 'assessment.grade',
    call: (c) => c.post('/assignments/submissions/no-such-submission/review', { status: 'approved' }),
  },
  { name: 'POST /assignments/:id/remind', key: 'learners.message', call: (c) => c.post('/assignments/no-such-assignment/remind', { studentIds: [] }) },
  { name: 'GET /students', key: 'learners.view', call: (c) => c.get('/students') },
  { name: 'GET /students/:id', key: 'learners.view', call: (c) => c.get('/students/no-such-learner') },
  { name: 'POST /students/:id/enroll', key: 'learners.enroll', call: (c) => c.post('/students/no-such-learner/enroll', { courseId }) },
  { name: 'DELETE /students/enrollments/:id', key: 'learners.enroll', call: (c) => c.delete('/students/enrollments/no-such-enrolment') },
  { name: 'POST /students/message', key: 'learners.message', call: (c) => c.post('/students/message', { ids: [], subject: 'Hello', body: 'A note.' }) },
  { name: 'GET /instructors', key: 'instructors.view', call: (c) => c.get('/instructors') },
  { name: 'POST /certificates/:id/issue', key: 'certificates.issue', call: (c) => c.post('/certificates/no-such-certificate/issue') },
  { name: 'PATCH /live/:id', key: 'live.manage', call: (c) => c.patch('/live/no-such-live/', { title: 'No' }) },
  { name: 'POST /live/:id/cancel', key: 'live.manage', call: (c) => c.post('/live/no-such-live/cancel') },
  { name: 'POST /live/:id/remind', key: 'live.notify', call: (c) => c.post('/live/no-such-live/remind') },
  { name: 'PATCH /live/:id/reminders', key: 'live.notify', call: (c) => c.patch('/live/no-such-live/reminders', { reminders: [60] }) },
  { name: 'GET /reports/overview', key: 'reports.view', call: (c) => c.get('/reports/overview') },
  { name: 'GET /reports/learners', key: 'reports.view', call: (c) => c.get('/reports/learners') },
  { name: 'GET /dashboard', key: 'reports.view', call: (c) => c.get('/dashboard') },
  { name: 'GET /settings', key: 'settings.view', call: (c) => c.get('/settings') },
];

async function newAdmin(name = 'Shared Capability Admin') {
  const email = `shared-${unique()}@example.com`;
  const res = await platform.post('/superadmin/admins', { name, email, password: ADMIN_PASSWORD, tenantId: 'tenant-1' });
  expect(res.status).toBe(201);
  created.push(res.body.id as string);
  return { id: res.body.id as string, email, client: await as({ email, password: ADMIN_PASSWORD }) };
}

const revoke = (userId: string, key: PermissionKey) => db.adminPermission.deleteMany({ where: { userId, key } });
const restore = (userId: string, key: PermissionKey) =>
  db.adminPermission.upsert({ where: { userId_key: { userId, key } }, create: { ...T, userId, key }, update: {} });

beforeAll(async () => {
  const email = `platform-shared-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: SECRET, name: 'Platform Owner' });
  platform = await as({ email, password: SECRET });
  instructor = await as('instructor');
  student = await as('student');
  const account = await newAdmin('Matrix Admin');
  admin = account.client;
  adminId = account.id;

  /* Fixtures come from the database rather than from a list endpoint: these tests publish, archive
   * and cancel as they go, and a list's contents move underneath them. Everything below belongs to
   * the seeded instructor, so one set of ids exercises both roles. */
  /* The one fixture these tests need: a course the seeded instructor teaches, so the nested course
   * routers reach their permission check. Everything else aims at ids that match nothing. */
  const teacher = await db.instructor.findFirstOrThrow({ where: { email: ACCOUNTS.instructor }, select: { id: true } });
  const taught = await db.courseInstructor.findMany({ where: { instructorId: teacher.id }, select: { courseId: true } });
  const taughtIds = taught.map((t) => t.courseId);
  expect(taughtIds.length, 'the seeded instructor teaches at least one course').toBeGreaterThan(0);

  const course = await db.course.findFirstOrThrow({ where: { id: { in: taughtIds } } });

  courseId = course.id;

  expect(courseId, 'courseId').toBeTruthy();
});

afterAll(async () => {
  if (created.length) await db.user.deleteMany({ where: { id: { in: created } } });
  console.log(
    'DIAG links=',
    await db.courseInstructor.count(),
    'courses=',
    await db.course.count(),
    'enrol=',
    await db.enrollment.count(),
    'quizzes=',
    await db.quiz.count(),
    'chapters=',
    await db.chapter.count(),
    'students=',
    await db.student.count(),
  );
});

describe('an admin needs the key; an instructor does not', () => {
  it('refuses the admin without it and reaches the handler with it', async () => {
    for (const capability of capabilities()) {
      await revoke(adminId, capability.key);
      expect((await capability.call(admin)).status, `${capability.name} without ${capability.key}`).toBe(403);

      await restore(adminId, capability.key);
      const allowed = await capability.call(admin);
      // Past the guard. What the handler then answers — 200, or a business 404/409 for a fixture
      // that does not exist — belongs to the route's own suite.
      expect(allowed.status, `${capability.name} with ${capability.key} → ${allowed.status}`).not.toBe(403);
    }
  });

  it('never asks an instructor for a key', async () => {
    const instructorUser = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.instructor }, select: { id: true } });
    expect(await inAcademy(() => permissionsFor(instructorUser.id))).toEqual([]);

    // The admin holds nothing at all while this runs, so nothing can be borrowed from it.
    await db.adminPermission.deleteMany({ where: { userId: adminId } });
    for (const capability of capabilities()) {
      expect((await capability.call(instructor)).status, `instructor ${capability.name}`).not.toBe(403);
    }
    await inAcademy(() => grantAllPermissions(adminId));
  });

  it('refuses a learner everywhere, and never the platform’s owner (docs/16, D-PLAT-03)', async () => {
    for (const capability of capabilities()) {
      expect((await capability.call(student)).status, `student ${capability.name}`).toBe(403);
      expect((await capability.call(platform)).status, `superadmin ${capability.name}`).not.toBe(403);
    }
  });

  it('refuses an anonymous caller and an unusable token', async () => {
    expect((await anon().get('/courses')).status).toBe(401);
    expect((await request(app).get('/dashboard').set('Authorization', 'Bearer not-a-real-token')).status).toBe(401);
  });
});

describe('one key does not open another door', () => {
  it('keeps reading apart from writing, and each action apart from its neighbours', async () => {
    const wrong: [PermissionKey, PermissionKey, Call][] = [
      ['catalog.view', 'catalog.edit', (c) => c.patch('/courses/no-such-course', { subtitle: 'No' })],
      ['catalog.edit', 'catalog.publish', (c) => c.post('/courses/no-such-course/publish')],
      ['catalog.edit', 'catalog.archive', (c) => c.post('/courses/no-such-course/archive')],
      ['catalog.view', 'catalog.edit', (c) => c.patch(`/courses/${courseId}/chapters/no-such-chapter`, { title: 'No' })],
      ['assessment.view', 'assessment.edit', (c) => c.patch('/quizzes/no-such-quiz', { title: 'No' })],
      ['assessment.view', 'assessment.grade', (c) => c.post('/assignments/submissions/no-such-submission/review', { status: 'approved' })],
      ['assessment.edit', 'learners.message', (c) => c.post('/assignments/no-such-assignment/remind', { studentIds: [] })],
      ['learners.view', 'learners.enroll', (c) => c.post('/students/no-such-learner/enroll', { courseId })],
      ['learners.view', 'learners.message', (c) => c.post('/students/message', { ids: [], subject: 'No', body: 'No.' })],
      ['instructors.view', 'instructors.manage', (c) => c.patch('/instructors/no-such-instructor', { title: 'No' })],
      ['instructors.view', 'instructors.status', (c) => c.post('/instructors/no-such-instructor/status', { status: 'inactive' })],
      ['live.manage', 'live.notify', (c) => c.post('/live/no-such-live/remind')],
      ['live.manage', 'live.notify', (c) => c.patch('/live/no-such-live/reminders', { reminders: [30] })],
      ['live.notify', 'live.manage', (c) => c.post('/live/no-such-live/cancel')],
      ['reports.view', 'reports.instructors.view', (c) => c.get('/reports/instructors')],
      ['settings.view', 'settings.edit', (c) => c.put('/settings/general', {})],
      ['certificates.issue', 'certificates.revoke', (c) => c.post('/certificates/no-such-certificate/revoke', { reason: 'no' })],
    ];

    for (const [held, required, call] of wrong) {
      await revoke(adminId, required);
      expect(await db.adminPermission.count({ where: { userId: adminId, key: held } }), `holds ${held}`).toBe(1);
      expect((await call(admin)).status, `${held} must not stand in for ${required}`).toBe(403);
      await restore(adminId, required);
    }
  });
});

describe('the instructor workspace is exactly as it was', () => {
  it('still reaches everything it could before', async () => {
    for (const path of [
      '/courses',
      '/quizzes',
      '/assignments',
      '/assignments/review',
      '/live',
      '/students',
      '/dashboard',
      '/settings',
      '/categories',
      '/instructors',
      '/certificates',
      '/reports/overview',
      '/reports/learners',
    ]) {
      expect((await instructor.get(path)).status, path).toBe(200);
    }
    expect((await instructor.get('/calendar', CALENDAR_WINDOW)).status).toBe(200);
    expect((await instructor.get(`/courses/${courseId}/lessons`)).status).toBe(200);
    expect((await instructor.get(`/courses/${courseId}/chapters/stats`)).status).toBe(200);
  });

  it('still authors its own courses and is still scoped to them', async () => {
    const chapter = await instructor.post(`/courses/${courseId}/chapters`, { input: { title: `Instructor chapter ${unique()}` } });
    expect(chapter.status).toBe(201);
    expect((await instructor.delete(`/courses/${courseId}/chapters/${chapter.body.id}`)).status).toBe(200);

    // A course they do not teach is still invisible — that is scope, not permission.
    expect((await instructor.get('/courses/no-such-course')).status).toBe(404);
    expect((await instructor.post('/courses/no-such-course/publish')).status).toBe(404);
  });

  it('is still refused where it always was', async () => {
    expect((await instructor.post('/categories', { name: 'No', glyph: 'sun' })).status).toBe(403);
    expect((await instructor.get('/reports/instructors')).status).toBe(403);
    expect((await instructor.put('/settings/general', {})).status).toBe(403);
    expect((await instructor.post('/students/no-such-learner/suspend', { suspended: true })).status).toBe(403);
  });
});

describe('the learner side is untouched', () => {
  it('still reads its own learning and is still kept out of the staff academy', async () => {
    for (const path of ['/learning/home', '/learning/courses', '/learning/assignments', '/learning/certificates', '/notifications']) {
      expect((await student.get(path)).status, path).toBe(200);
    }
    for (const path of ['/courses', '/students', '/quizzes', '/dashboard', '/settings']) {
      expect((await student.get(path)).status, path).toBe(403);
    }
  });
});

describe('a fully permissioned admin has lost nothing', () => {
  it('still runs the academy end to end', async () => {
    const seeded = await as('admin');
    expect((await seeded.get('/auth/me')).body.user.permissions).toEqual(PERMISSION_KEYS);
    for (const path of [
      '/courses',
      '/quizzes',
      '/assignments',
      '/live',
      '/students',
      '/dashboard',
      '/settings',
      '/categories',
      '/instructors',
      '/certificates',
      '/reports/overview',
      '/reports/instructors',
    ]) {
      expect((await seeded.get(path)).status, path).toBe(200);
    }
    /* No course is edited here on purpose. That an admin can still edit one is already shown by the
     * matrix above (with the key, the guard is passed) and by the catalog suite, which exercises the
     * real thing. Editing a seeded course from here would move it to the top of the instructor's
     * list and change what other suites read. */
    expect((await seeded.get('/calendar', CALENDAR_WINDOW)).status).toBe(200);
  });

  it('works the moment a key is granted and stops the moment it is taken away', async () => {
    const target = await newAdmin('Toggled Admin');
    expect((await target.client.get('/courses')).status).toBe(200);

    await platform.delete(`/superadmin/admins/${target.id}/permissions/catalog.view`);
    expect((await target.client.get('/courses')).status).toBe(403);

    await platform.post(`/superadmin/admins/${target.id}/permissions`, { key: 'catalog.view' });
    expect((await target.client.get('/courses')).status).toBe(200);
  });
});

describe('what stayed role-based, stayed role-based', () => {
  it('leaves certificate reads, live reads and the calendar open to an admin holding nothing', async () => {
    const stripped = await newAdmin('Holds Nothing');
    await db.adminPermission.deleteMany({ where: { userId: stripped.id } });

    for (const path of ['/certificates', '/certificates/templates', '/live']) {
      expect((await stripped.client.get(path)).status, path).toBe(200);
    }
    expect((await stripped.client.get('/calendar', CALENDAR_WINDOW)).status).toBe(200);
    expect((await stripped.client.get('/notifications')).status).toBe(200);
    expect((await stripped.client.get('/auth/me')).body.user.permissions).toEqual([]);
  });
});
