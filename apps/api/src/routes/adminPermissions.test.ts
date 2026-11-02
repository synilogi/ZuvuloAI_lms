import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { PERMISSION_KEYS, type PermissionKey } from '@syniastrolms/domain';

import { T, db, inAcademy } from '../test/db.js';
import { grantAllPermissions } from '../lib/permissions.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { anon, app, as, unique, type Client } from '../test/helpers.js';

/* Permission enforcement on the fourteen endpoints that were already admin-only.
 *
 * Every case runs against an admin this file created, so the seeded academy admin the rest of the
 * suite signs in as keeps all of its grants. */

const SECRET = 'enforcement-suite-password';
const ADMIN_PASSWORD = 'an-enforcement-admin-password';
/** `/calendar` has always required a window; asking without one is a 400 in any role. */
const CALENDAR_WINDOW = { from: '2026-01-01', to: '2027-01-01' };

let platform: Client;
let admin: Client;
let adminId: string;
const created: string[] = [];
/** The academy's own `general` section, written back unchanged — a valid body that changes nothing. */
let generalSettings: unknown;
/** A valid certificate-template body, and the default to put back afterwards. */
let templateInput: Record<string, unknown>;
let originalDefaultTemplateId = '';

/** The shape `POST /instructors` accepts, as the instructors suite builds it. */
const instructorInput = () => ({
  name: 'Spare Teacher',
  title: 'Visiting Teacher',
  email: `spare-${unique()}@example.com`,
  bio: 'Teaches reasoning and quantitative aptitude to exam aspirants, with twelve years of coaching practice.',
  expertise: ['Reasoning'],
  status: 'invited' as const,
  city: 'Pune',
  languages: ['English'],
  courseIds: [],
});

/** Every protected endpoint, with the key that opens it and a request that reaches the guard. */
interface Protected {
  name: string;
  key: PermissionKey;
  call: (client: Client, id: string) => ReturnType<Client['post']>;
  /** An id that exists, for the cases that must prove nothing was mutated. */
  target?: () => Promise<string>;
}

let spareCategoryId = '';
let spareInstructorId = '';
let spareInstructorEmail = '';
const categoryId = async () => spareCategoryId;
const instructorId = async () => spareInstructorId;
const certificateId = async () => (await db.issuedCertificate.findFirstOrThrow({ select: { id: true } })).id;
const templateId = async () => (await db.certificateTemplate.findFirstOrThrow({ select: { id: true } })).id;

const PROTECTED: Protected[] = [
  { name: 'POST /categories', key: 'catalog.categories.manage', call: (c) => c.post('/categories', { name: `Cat ${unique()}`, glyph: 'sun' }) },
  {
    name: 'PATCH /categories/:id',
    key: 'catalog.categories.manage',
    call: (c, id) => c.patch(`/categories/${id}`, { name: `Renamed ${unique()}`, glyph: 'sun' }),
    target: categoryId,
  },
  { name: 'DELETE /categories/:id', key: 'catalog.categories.manage', call: (c, id) => c.delete(`/categories/${id}`), target: categoryId },
  {
    name: 'POST /certificates/templates',
    key: 'certificates.templates.manage',
    call: (c) => c.post('/certificates/templates', { id: null, input: { ...templateInput, name: `T ${unique()}` } }),
  },
  {
    name: 'POST /certificates/templates/:id/default',
    key: 'certificates.templates.manage',
    call: (c, id) => c.post(`/certificates/templates/${id}/default`),
    target: templateId,
  },
  {
    name: 'POST /certificates/:id/revoke',
    key: 'certificates.revoke',
    call: (c, id) => c.post(`/certificates/${id}/revoke`, { reason: 'test' }),
    target: certificateId,
  },
  { name: 'POST /certificates/:id/restore', key: 'certificates.revoke', call: (c, id) => c.post(`/certificates/${id}/restore`), target: certificateId },
  {
    name: 'POST /instructors',
    key: 'instructors.manage',
    call: (c) => c.post('/instructors', instructorInput()),
  },
  {
    name: 'PATCH /instructors/:id',
    key: 'instructors.manage',
    call: (c, id) => c.patch(`/instructors/${id}`, { ...instructorInput(), email: spareInstructorEmail, name: 'Retitled Teacher' }),
    target: instructorId,
  },
  {
    name: 'POST /instructors/:id/status',
    key: 'instructors.status',
    call: (c, id) => c.post(`/instructors/${id}/status`, { status: 'inactive' }),
    target: instructorId,
  },
  { name: 'POST /instructors/:id/resend-invite', key: 'instructors.manage', call: (c, id) => c.post(`/instructors/${id}/resend-invite`), target: instructorId },
  { name: 'GET /reports/instructors', key: 'reports.instructors.view', call: (c) => c.get('/reports/instructors') as ReturnType<Client['post']> },
  { name: 'PUT /settings/:section', key: 'settings.edit', call: (c) => c.put('/settings/general', generalSettings) },
  { name: 'POST /students/:id/suspend', key: 'learners.suspend', call: (c) => c.post('/students/no-such-learner/suspend', { suspended: true }) },
];

/** An academy admin holding the whole catalogue, created the way the platform creates one. */
async function newAdmin(name = 'Enforcement Admin') {
  const email = `enforce-${unique()}@example.com`;
  const res = await platform.post('/superadmin/admins', { name, email, password: ADMIN_PASSWORD, tenantId: 'tenant-1' });
  expect(res.status).toBe(201);
  created.push(res.body.id as string);
  return { id: res.body.id as string, email, client: await as({ email, password: ADMIN_PASSWORD }) };
}

const revoke = (userId: string, key: PermissionKey) => db.adminPermission.deleteMany({ where: { userId, key } });
const restore = (userId: string, key: PermissionKey) => db.adminPermission.create({ data: { ...T, userId, key } });

beforeAll(async () => {
  const email = `platform-enforce-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: SECRET, name: 'Platform Owner' });
  platform = await as({ email, password: SECRET });
  const account = await newAdmin('Matrix Admin');
  admin = account.client;
  adminId = account.id;

  generalSettings = (await admin.get('/settings')).body.settings.general;
  // A template body the validator accepts: the academy's own, renamed.
  const templates = (await admin.get('/certificates/templates')).body as { template: Record<string, unknown> }[];
  templateInput = { ...templates[0].template, courseIds: [] };
  originalDefaultTemplateId = (templates.find((t) => t.template.isDefault)?.template.id as string) ?? '';
  // Records this file may change freely: the seeded academy keeps its own.
  spareCategoryId = (await admin.post('/categories', { name: `Spare ${unique()}`, glyph: 'moon' })).body.id;
  expect(spareCategoryId).toBeTruthy();
  const spareInstructor = instructorInput();
  spareInstructorEmail = spareInstructor.email;
  spareInstructorId = (await admin.post('/instructors', spareInstructor)).body.id;
  expect(spareInstructorId).toBeTruthy();
});

afterAll(async () => {
  /* Leave the academy as it was found. Every delete is guarded by a truthy id: Prisma ignores an
   * `undefined` in a `where`, so an unguarded one would not narrow the delete — it would empty the
   * table. */
  await db.student.updateMany({ where: { suspended: true }, data: { suspended: false, suspendReason: null } });

  if (originalDefaultTemplateId) {
    await db.certificateTemplate.updateMany({ where: { isDefault: true }, data: { isDefault: false } });
    await db.certificateTemplate.update({ where: { id: originalDefaultTemplateId }, data: { isDefault: true } });
  }
  const spareTemplates = await db.certificateTemplate.findMany({ where: { name: { startsWith: 'T ' } }, select: { id: true } });
  if (spareTemplates.length) await db.certificateTemplate.deleteMany({ where: { id: { in: spareTemplates.map((t) => t.id) } } });

  const spareInstructors = await db.instructor.findMany({ where: { email: { startsWith: 'spare-' } }, select: { id: true } });
  const spareIds = spareInstructors.map((i) => i.id);
  if (spareIds.length) {
    await db.user.deleteMany({ where: { instructorId: { in: spareIds } } });
    await db.courseInstructor.deleteMany({ where: { instructorId: { in: spareIds } } });
    await db.instructor.deleteMany({ where: { id: { in: spareIds } } });
  }

  const spareCategories = await db.category.findMany({ where: { name: { startsWith: 'Spare ' } }, select: { id: true } });
  const liveCategories = await db.category.findMany({ where: { name: { startsWith: 'Live ' } }, select: { id: true } });
  const categoryIds = [...spareCategories, ...liveCategories].map((c) => c.id);
  if (categoryIds.length) {
    await db.categoryLevel.deleteMany({ where: { categoryId: { in: categoryIds } } });
    await db.category.deleteMany({ where: { id: { in: categoryIds } } });
  }

  if (created.length) await db.user.deleteMany({ where: { id: { in: created } } });
});

describe('the fourteen admin-only endpoints answer to a grant', () => {
  it('refuses an anonymous caller and an unusable token', async () => {
    for (const route of PROTECTED) {
      const id = route.target ? await route.target() : 'x';
      expect((await route.call(anon(), id)).status, route.name).toBe(401);
      const withJunk = await request(app).post('/categories').set('Authorization', 'Bearer not-a-real-token').send({});
      expect(withJunk.status).toBe(401);
    }
  });

  it('refuses a learner and an instructor, and never the super admin', async () => {
    const instructor = await as('instructor');
    const student = await as('student');
    for (const route of PROTECTED) {
      const id = route.target ? await route.target() : 'x';
      expect((await route.call(student, id)).status, `student ${route.name}`).toBe(403);
      expect((await route.call(instructor, id)).status, `instructor ${route.name}`).toBe(403);
      // The platform's owner passes every grant (docs/16, D-PLAT-03): whatever else the call answers, it is never 403.
      expect((await route.call(platform, id)).status, `superadmin ${route.name}`).not.toBe(403);
    }
  });

  it('refuses an admin whose grant was taken away, and lets it back in when restored', async () => {
    for (const route of PROTECTED) {
      const id = route.target ? await route.target() : 'x';
      await revoke(adminId, route.key);
      const refused = await route.call(admin, id);
      expect(refused.status, `${route.name} without ${route.key}`).toBe(403);

      await restore(adminId, route.key);
      const allowed = await route.call(admin, id);
      // With the grant the request reaches the handler. Whether that handler then answers 200, 201
      // or a business 400/409 is the existing route suites' subject, not this one's — what matters
      // here is that the permission guard no longer refuses it.
      expect(allowed.status, `${route.name} with ${route.key} → ${allowed.status}`).not.toBe(403);
      expect(allowed.status, route.name).not.toBe(401);
    }
  });

  it('changes nothing when it refuses', async () => {
    const id = await instructorId();
    const before = await db.instructor.findUniqueOrThrow({ where: { id } });
    await revoke(adminId, 'instructors.manage');
    await revoke(adminId, 'instructors.status');

    expect((await admin.patch(`/instructors/${id}`, { title: 'Should not stick' })).status).toBe(403);
    expect((await admin.post(`/instructors/${id}/status`, { status: 'inactive' })).status).toBe(403);

    const after = await db.instructor.findUniqueOrThrow({ where: { id } });
    expect(after.title).toBe(before.title);
    expect(after.status).toBe(before.status);

    await restore(adminId, 'instructors.manage');
    await restore(adminId, 'instructors.status');
  });

  it('never lets a revoked settings grant write, and reads stay open', async () => {
    const before = await db.settings.findUniqueOrThrow({ where: { tenantId: T.tenantId } });
    await revoke(adminId, 'settings.edit');
    expect((await admin.put('/settings/general', { academyName: 'Should not stick' })).status).toBe(403);
    expect(await db.settings.findUniqueOrThrow({ where: { tenantId: T.tenantId } })).toEqual(before);
    // Reading settings stayed role-based, so it still answers.
    expect((await admin.get('/settings')).status).toBe(200);
    await restore(adminId, 'settings.edit');
  });
});

describe('a grant opens its own door and no other', () => {
  it('does not let a neighbouring key stand in for the one required', async () => {
    const pairs: [PermissionKey, PermissionKey, () => Promise<{ status: number }>][] = [
      ['instructors.view', 'instructors.manage', async () => admin.patch(`/instructors/${await instructorId()}`, { title: 'No' })],
      ['instructors.view', 'instructors.status', async () => admin.post(`/instructors/${await instructorId()}/status`, { status: 'inactive' })],
      ['certificates.issue', 'certificates.revoke', async () => admin.post(`/certificates/${await certificateId()}/revoke`, { reason: 'no' })],
      ['settings.view', 'settings.edit', async () => admin.put('/settings/general', { academyName: 'No' })],
      ['catalog.view', 'catalog.categories.manage', async () => admin.post('/categories', { name: `No ${unique()}`, order: 98 })],
      ['learners.view', 'learners.suspend', async () => admin.post('/students/no-such-learner/suspend', { suspended: true })],
      ['reports.view', 'reports.instructors.view', async () => admin.get('/reports/instructors')],
    ];

    for (const [held, required, call] of pairs) {
      await revoke(adminId, required);
      expect(await db.adminPermission.count({ where: { userId: adminId, key: held } }), `holds ${held}`).toBe(1);
      expect((await call()).status, `${held} must not stand in for ${required}`).toBe(403);
      await restore(adminId, required);
    }
  });

  it('is not satisfied by a key the catalogue does not know', async () => {
    await revoke(adminId, 'settings.edit');
    await db.adminPermission.create({ data: { ...T, userId: adminId, key: 'settings.*' } });
    expect((await admin.put('/settings/general', { academyName: 'No' })).status).toBe(403);
    await db.adminPermission.deleteMany({ where: { userId: adminId, key: 'settings.*' } });
    await restore(adminId, 'settings.edit');
  });

  it('takes effect on the next request, without a new token', async () => {
    const id = (await admin.post('/categories', { name: `Live ${unique()}`, glyph: 'lotus' })).body.id as string;
    // Same bearer token throughout: the grant is read from the database every time.
    await revoke(adminId, 'catalog.categories.manage');
    expect((await admin.patch(`/categories/${id}`, { name: 'Nope' })).status).toBe(403);
    await restore(adminId, 'catalog.categories.manage');
    expect((await admin.patch(`/categories/${id}`, { name: `Renamed ${unique()}` })).status).toBe(200);
  });
});

describe('the session response carries the current grants', () => {
  it('answers with what the database holds right now, for an unchanged token', async () => {
    await inAcademy(() => grantAllPermissions(adminId));
    const me = await admin.get('/auth/me');
    expect(me.status).toBe(200);
    expect(me.body.user.permissions).toEqual(PERMISSION_KEYS);

    await revoke(adminId, 'settings.edit');
    const narrowed = await admin.get('/auth/me');
    expect(narrowed.body.user.permissions).not.toContain('settings.edit');
    expect(narrowed.body.user.permissions).toContain('settings.view');

    await restore(adminId, 'settings.edit');
    expect((await admin.get('/auth/me')).body.user.permissions).toEqual(PERMISSION_KEYS);
  });

  it('gives every other role an empty list, and no token ever carries one', async () => {
    for (const account of ['student', 'instructor'] as const) {
      const client = await as(account);
      expect((await client.get('/auth/me')).body.user.permissions, account).toEqual([]);
    }
    expect((await platform.get('/auth/me')).body.user.permissions).toEqual([]);

    // The JWT holds the role and the scope ids — never a permission.
    const [, payload] = admin.token.split('.');
    const claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    // The academy (D3) is a claim the server re-checks against the account on every request, and the session
    // (SAAS-020) one it checks is still open; grants are not claims at all.
    expect(Object.keys(claims).sort()).toEqual(['exp', 'iat', 'role', 'sid', 'sub', 'tenantId']);
    expect(JSON.stringify(claims)).not.toMatch(/permission|settings\.|catalog\./);
  });

  it('cannot be talked into granting itself anything', async () => {
    await revoke(adminId, 'settings.edit');
    // A body, a query and a header all claiming the permission change nothing.
    expect((await admin.put('/settings/general', { academyName: 'No', permissions: PERMISSION_KEYS })).status).toBe(403);
    expect((await admin.get('/auth/me', { permissions: 'settings.edit' })).body.user.permissions).not.toContain('settings.edit');
    expect(
      (await request(app).put('/settings/general').set('Authorization', `Bearer ${admin.token}`).set('x-permissions', 'settings.edit').send({})).status,
    ).toBe(403);
    await restore(adminId, 'settings.edit');
  });
});

describe('the rest of the academy is untouched', () => {
  it('now refuses a grant-less admin on the capabilities that became permission-controlled', async () => {
    const stripped = await newAdmin('No Grants At All');
    await db.adminPermission.deleteMany({ where: { userId: stripped.id } });

    // Phase 12 put these behind a key; without one there is nothing to stand on.
    for (const path of ['/courses', '/students', '/quizzes', '/assignments', '/dashboard', '/settings', '/categories', '/instructors', '/reports/overview']) {
      expect((await stripped.client.get(path)).status, path).toBe(403);
    }

    // And these stay role-based: no key exists for reading certificates or live classes, and the
    // calendar is a personal workspace rather than an academy capability.
    for (const path of ['/certificates', '/certificates/templates', '/live']) {
      expect((await stripped.client.get(path)).status, path).toBe(200);
    }
    expect((await stripped.client.get('/calendar', CALENDAR_WINDOW)).status).toBe(200);
    expect((await stripped.client.get('/auth/me')).status).toBe(200);
  });

  it('leaves instructors exactly as they were', async () => {
    const instructor = await as('instructor');
    for (const path of ['/courses', '/quizzes', '/assignments', '/live', '/students', '/dashboard', '/reports/overview', '/categories', '/certificates']) {
      expect((await instructor.get(path)).status, path).toBe(200);
    }
    expect((await instructor.get('/calendar', CALENDAR_WINDOW)).status).toBe(200);
    // And still refused where they always were.
    expect((await instructor.post('/categories', { name: 'No', order: 1 })).status).toBe(403);
    expect((await instructor.get('/reports/instructors')).status).toBe(403);
  });

  it('leaves the seeded admin able to run the academy', async () => {
    const seeded = await as('admin');
    expect((await seeded.get('/reports/instructors')).status).toBe(200);
    expect((await seeded.put('/settings/general', (await seeded.get('/settings')).body.settings.general)).status).toBe(200);
    expect((await seeded.get('/auth/me')).body.user.permissions).toEqual(PERMISSION_KEYS);
  });

  it('still refuses a learner everywhere it used to', async () => {
    const student = await as('student');
    for (const path of ['/courses', '/students', '/dashboard', '/settings', '/categories']) {
      expect((await student.get(path)).status, path).toBe(403);
    }
    expect((await student.get('/learning/home')).status).toBe(200);
  });
});
