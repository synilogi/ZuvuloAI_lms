import { Prisma } from '@prisma/client';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { db as prodDb, forTenant } from '../lib/db.js';
import { hashPassword, signToken } from '../lib/auth.js';
import { nextCredentialId } from '../lib/certificates.js';
import { grantAllPermissions } from '../lib/permissions.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { sendDueCalendarReminders } from '../lib/calendarEvents.js';
import { sendDueReminders } from '../lib/liveEvents.js';
import { runNotificationJobs } from '../lib/notificationJobs.js';
import { setObservationSink, type Observation } from '../lib/observe.js';
import { forEachTenant, runNotificationSchedule, runScheduledJobs } from '../lib/scheduler.js';
import {
  FIRST_TENANT_ID,
  PLATFORM_MODELS,
  TENANT_OR_PLATFORM_MODELS,
  TENANT_OWNED_MODELS,
  TenantContextError,
  currentTenantId,
  runAsPlatform,
  runInTenant,
} from '../lib/tenancy.js';
import { platformDb } from '../test/db.js';
import { ACCOUNTS, PASSWORD, anon, app, as, decodeToken, type Client, unique } from '../test/helpers.js';

/*
 * The platform runs in one workspace (docs/16, D-PLAT-01). The tenancy layer underneath it — `tenantId` on every
 * academy-owned table, the triggers, the Prisma extension — is unchanged and is now defence in depth: rows of an
 * academy kept from the SaaS era (D-PLAT-02) can never be read, listed or written through the workspace, and an
 * account of such an academy is refused on every route with WORKSPACE_CLOSED.
 *
 * `B` below is such an academy, built directly through a client bound to it: it exists in the database and in no
 * request.
 */

const A = FIRST_TENANT_ID;
const suffix = unique();
const B = `tenant-b-${suffix}`;
const B_PASSWORD = 'second-academy-pass';

/** Everything the second academy holds, by id. */
const b = {} as {
  level: string;
  category: string;
  instructor: string;
  course: string;
  courseSlug: string;
  lesson: string;
  adminId: string;
  adminEmail: string;
  learnerUserId: string;
  learnerEmail: string;
  student: string;
  media: string;
  template: string;
  certificate: string;
  credential: string;
};
/** Workspace ids the second academy must never reach. */
const a = {} as { course: string; courseSlug: string; category: string; student: string; certificate: string };

let adminA: Client;
let platform: Client;

beforeAll(async () => {
  // Workspace ids, read through the platform so nothing about the test depends on a context.
  const courseA = await platformDb.course.findFirstOrThrow({ where: { tenantId: A, status: 'published' }, orderBy: { createdAt: 'asc' } });
  a.course = courseA.id;
  a.courseSlug = courseA.slug;
  a.category = (await platformDb.category.findFirstOrThrow({ where: { tenantId: A } })).id;
  a.student = (await platformDb.student.findFirstOrThrow({ where: { tenantId: A } })).id;
  a.certificate = (await platformDb.issuedCertificate.findFirstOrThrow({ where: { tenantId: A, status: 'issued' } })).id;

  // The second academy, built in its own context.
  await platformDb.tenant.create({ data: { id: B, name: 'Second Academy', slug: `second-${suffix}` } });
  const tb = forTenant(B);
  const T = { tenantId: B };
  b.level = (await tb.level.create({ data: { ...T, name: 'Foundations', order: 1 } })).id;
  await tb.rank.create({ data: { ...T, title: 'Rank I', order: 1, descriptor: 'Starting out.' } });
  b.category = (
    await tb.category.create({ data: { ...T, name: 'Second Category', description: 'Only in the second academy.', order: 1, status: 'active', glyph: 'sun' } })
  ).id;
  b.instructor = (
    await tb.instructor.create({ data: { ...T, name: 'Second Teacher', title: 'Teacher', email: `b-teacher-${suffix}@example.com`, status: 'active' } })
  ).id;
  // The same slug as a workspace course: slugs are unique within a tenant, not across the platform (D4).
  b.courseSlug = a.courseSlug;
  const course = await tb.course.create({
    data: {
      ...T,
      slug: b.courseSlug,
      title: `Second Academy Course ${suffix}`,
      levelId: b.level,
      categoryId: b.category,
      format: 'self-paced',
      coverMotif: 'orbits',
      status: 'published',
      visibility: 'public',
      publishedAt: new Date(),
      instructors: { create: [{ ...T, instructorId: b.instructor }] },
    },
  });
  b.course = course.id;
  const chapter = await tb.chapter.create({ data: { ...T, courseId: b.course, title: 'Chapter one', status: 'published', position: 0 } });
  b.lesson = (
    await tb.lesson.create({
      data: { ...T, chapterId: chapter.id, courseId: b.course, title: 'Lesson one', type: 'reading', status: 'published', position: 0 },
    })
  ).id;

  b.adminEmail = `b-admin-${suffix}@example.com`;
  b.adminId = (
    await tb.user.create({ data: { ...T, name: 'Second Admin', email: b.adminEmail, passwordHash: await hashPassword(B_PASSWORD), role: 'admin' } })
  ).id;
  await runInTenant(B, () => grantAllPermissions(b.adminId));

  b.learnerEmail = `b-learner-${suffix}@example.com`;
  const learner = await tb.user.create({
    data: { ...T, name: 'Second Learner', email: b.learnerEmail, passwordHash: await hashPassword(B_PASSWORD), role: 'student', student: { create: { ...T } } },
    include: { student: true },
  });
  b.learnerUserId = learner.id;
  b.student = learner.student!.id;
  await tb.enrollment.create({ data: { ...T, studentId: b.student, courseId: b.course } });

  b.media = (
    await tb.mediaAsset.create({
      data: { ...T, ownerUserId: b.adminId, kind: 'document', originalName: 'b.pdf', mime: 'application/pdf', sizeBytes: 10, storageName: `b-${suffix}.pdf` },
    })
  ).id;
  b.template = (
    await tb.certificateTemplate.create({
      data: { ...T, name: 'Second seal', style: 'classic', accent: 'emerald', heading: 'Certificate', statement: 'Completed.', isDefault: true },
    })
  ).id;
  b.credential = `SB-TEST-${suffix}`;
  b.certificate = (
    await tb.issuedCertificate.create({
      data: {
        ...T,
        credentialId: b.credential,
        studentId: b.student,
        courseId: b.course,
        title: 'Second certificate',
        templateId: b.template,
        status: 'issued',
        completedAt: new Date(),
        issuedAt: new Date(),
      },
    })
  ).id;

  adminA = await as('admin');
  const platformEmail = `tenancy-platform-${suffix}@example.com`;
  await provisionSuperAdmin({ email: platformEmail, password: B_PASSWORD, name: 'Tenancy Platform' });
  platform = await as({ email: platformEmail, password: B_PASSWORD });
});

afterAll(() => {
  delete process.env.TENANT_ENFORCEMENT;
});

const ids = (rows: { id: string }[]) => rows.map((r) => r.id);

/* ─── The schema, as the migrations built it ─────────────────────────── */

describe('tenant schema', () => {
  const read = <T>(sql: string, ...params: unknown[]) => platformDb.$queryRawUnsafe<T[]>(sql, ...params);
  const columns = async (table: string) => {
    const rows = await read<{ name: string; nullable: string }>(
      'SELECT COLUMN_NAME AS name, IS_NULLABLE AS nullable FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?',
      table,
    );
    return rows.map((r) => ({ name: r.name, notnull: r.nullable === 'NO' ? 1 : 0 }));
  };

  it('classifies every model exactly once', () => {
    const all = Prisma.dmmf.datamodel.models.map((m) => m.name).sort();
    const classified = [...TENANT_OWNED_MODELS, ...TENANT_OR_PLATFORM_MODELS, ...PLATFORM_MODELS];
    expect(new Set(classified).size).toBe(classified.length);
    expect([...classified].sort()).toEqual(all);
    // The SaaS-era tables are kept, retired, until a separate drop migration (docs/16 §3.1); the count holds.
    expect(TENANT_OWNED_MODELS.length + TENANT_OR_PLATFORM_MODELS.length).toBe(79);
  });

  it('gives every academy-owned table a tenantId — required where every row belongs to a workspace', async () => {
    for (const model of TENANT_OWNED_MODELS) {
      const col = (await columns(model)).find((c) => c.name === 'tenantId');
      expect(col, model).toBeDefined();
      expect(Number(col!.notnull), `${model}.tenantId NOT NULL`).toBe(1);
    }
    for (const model of TENANT_OR_PLATFORM_MODELS) {
      const col = (await columns(model)).find((c) => c.name === 'tenantId');
      expect(col, model).toBeDefined();
      expect(Number(col!.notnull), `${model}.tenantId nullable (platform rows)`).toBe(0);
    }
    for (const model of PLATFORM_MODELS) {
      expect(
        (await columns(model)).some((c) => c.name === 'tenantId'),
        model,
      ).toBe(false);
    }
  });

  it('backs every tenantId with a foreign key to Tenant that cannot cascade a delete', async () => {
    for (const model of [...TENANT_OWNED_MODELS, ...TENANT_OR_PLATFORM_MODELS]) {
      const fks = await read<{ table: string; from: string; to: string; on_delete: string }>(
        `SELECT k.REFERENCED_TABLE_NAME AS \`table\`, k.COLUMN_NAME AS \`from\`, k.REFERENCED_COLUMN_NAME AS \`to\`, r.DELETE_RULE AS on_delete
           FROM information_schema.KEY_COLUMN_USAGE k
           JOIN information_schema.REFERENTIAL_CONSTRAINTS r ON r.CONSTRAINT_SCHEMA = k.CONSTRAINT_SCHEMA AND r.CONSTRAINT_NAME = k.CONSTRAINT_NAME
          WHERE k.TABLE_SCHEMA = DATABASE() AND k.TABLE_NAME = ? AND k.REFERENCED_TABLE_NAME IS NOT NULL`,
        model,
      );
      const fk = fks.find((f) => f.from === 'tenantId');
      // A server on Windows reports table names in lower case.
      expect(fk?.table.toLowerCase(), model).toBe('tenant');
      expect(fk?.to, model).toBe('id');
      expect(fk!.on_delete, model).toBe('RESTRICT');
    }
  });

  it('indexes every tenantId, so every scoped query has an index to use', async () => {
    for (const model of [...TENANT_OWNED_MODELS, ...TENANT_OR_PLATFORM_MODELS]) {
      const leading = await read<{ name: string }>(
        `SELECT INDEX_NAME AS name FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND SEQ_IN_INDEX = 1 AND COLUMN_NAME = 'tenantId'`,
        model,
      );
      expect(leading.length > 0, `${model} has an index led by tenantId`).toBe(true);
    }
  });

  it('keys every foreign key on a single column naming the target id — what the reference check relies on', () => {
    for (const model of Prisma.dmmf.datamodel.models) {
      for (const field of model.fields.filter((f) => f.kind === 'object' && (f.relationFromFields?.length ?? 0) > 0)) {
        expect(field.relationFromFields, `${model.name}.${field.name}`).toHaveLength(1);
        expect(field.relationToFields, `${model.name}.${field.name}`).toEqual(['id']);
      }
    }
  });

  it('lets two tenants use the same course slug, but not one tenant twice (D4)', async () => {
    const [inA, inB] = await Promise.all([
      platformDb.course.findFirst({ where: { tenantId: A, slug: b.courseSlug } }),
      platformDb.course.findFirst({ where: { tenantId: B, slug: b.courseSlug } }),
    ]);
    expect(inA?.id).toBe(a.course);
    expect(inB?.id).toBe(b.course);
    await expect(
      forTenant(B).course.create({
        data: { tenantId: B, slug: b.courseSlug, title: `Dup ${suffix}`, levelId: b.level, categoryId: b.category, format: 'self-paced', coverMotif: 'orbits' },
      }),
    ).rejects.toMatchObject({ code: 'P2002' });
  });

  it('keeps a credential ID unique across the platform (D4)', async () => {
    const existing = await platformDb.issuedCertificate.findFirstOrThrow({ where: { tenantId: A } });
    await expect(
      forTenant(B).issuedCertificate.create({
        data: {
          tenantId: B,
          credentialId: existing.credentialId,
          studentId: b.student,
          courseId: b.course,
          title: 'Clash',
          templateId: b.template,
          completedAt: new Date(),
        },
      }),
    ).rejects.toMatchObject({ code: 'P2002' });
  });

  it('keeps the settings row of the workspace in Tenant #1', async () => {
    expect(await platformDb.settings.findUnique({ where: { tenantId: A } })).not.toBeNull();
  });
});

/* ─── Every request runs in the workspace ───────────────────────────── */

describe('the workspace context', () => {
  it('signs a workspace account in with the workspace in its token, and a super admin with none', () => {
    expect(decodeToken(adminA.token)).toMatchObject({ role: 'admin', tenantId: A });
    expect(decodeToken(platform.token)).not.toHaveProperty('tenantId');
  });

  it('refuses a token whose workspace claim does not match the account', async () => {
    const aAdmin = await platformDb.user.findUniqueOrThrow({ where: { email: ACCOUNTS.admin } });
    const forged = signToken({ sub: aAdmin.id, role: 'admin', tenantId: B });
    expect((await request(app).get('/courses').set('Authorization', `Bearer ${forged}`)).status).toBe(401);
  });

  it('refuses an account of an academy kept from the SaaS era, at sign-in and on every route (D-PLAT-02)', async () => {
    const signIn = await anon().post('/auth/login', { email: b.adminEmail, password: B_PASSWORD });
    expect(signIn.status).toBe(403);
    expect(signIn.body.code).toBe('WORKSPACE_CLOSED');
    // A wrong password is still a wrong password: the closed workspace is told only once the password matched.
    expect((await anon().post('/auth/login', { email: b.adminEmail, password: 'not-the-password' })).status).toBe(401);

    // A token it might still hold is refused everywhere, with the same code; its rows are untouched.
    const held = signToken({ sub: b.adminId, role: 'admin', tenantId: B });
    for (const path of ['/courses', '/auth/me', '/settings', `/courses/${b.course}`]) {
      const res = await request(app).get(path).set('Authorization', `Bearer ${held}`);
      expect(res.status, path).toBe(403);
      expect(res.body.code, path).toBe('WORKSPACE_CLOSED');
    }
    const learnerToken = signToken({ sub: b.learnerUserId, role: 'student', tenantId: B, studentId: b.student });
    expect((await request(app).get('/learning/home').set('Authorization', `Bearer ${learnerToken}`)).status).toBe(403);
    expect(await platformDb.course.findUniqueOrThrow({ where: { id: b.course } })).toMatchObject({ tenantId: B, status: 'published' });
  });

  it('never takes the workspace from the body, the query or a header', async () => {
    // Body: the category lands in the workspace, whatever the body names.
    const name = `Body tenant ${suffix}`;
    const created = await adminA.post('/categories', { name, description: 'Where does this go?', glyph: 'sun', status: 'active', levelIds: [], tenantId: B });
    expect(created.status).toBe(201);
    expect((await platformDb.category.findUniqueOrThrow({ where: { id: created.body.id } })).tenantId).toBe(A);

    // Query: never widens or switches the list.
    const listed = await adminA.get('/courses', { tenantId: B, pageSize: 100 });
    if (listed.status === 200) expect(ids(listed.body.rows)).not.toContain(b.course);
    else expect(listed.status).toBe(400);

    // Header: there is no header the server reads it from.
    const headed = await request(app).get('/courses').query({ pageSize: 100 }).set('Authorization', `Bearer ${adminA.token}`).set('X-Tenant-Id', B);
    expect(headed.status).toBe(200);
    expect(ids(headed.body.rows)).not.toContain(b.course);
  });

  it('registers a new learner in the workspace, whatever workspace the body names', async () => {
    const email = `host-learner-${suffix}@example.com`;
    const res = await anon().post('/auth/register', { name: 'Host Learner', email, password: PASSWORD, workspace: `second-${suffix}` });
    expect(res.status).toBe(201);
    expect((await platformDb.user.findUniqueOrThrow({ where: { email } })).tenantId).toBe(A);
  });

  it('refuses to register an address another tenant already uses (D2)', async () => {
    expect((await anon().post('/auth/register', { name: 'Copy Cat', email: b.learnerEmail, password: PASSWORD })).status).toBe(409);
  });
});

/* ─── Changing an id cannot reach another tenant ────────────────────── */

describe('isolation: ids in URLs', () => {
  it('answers 404 for another tenant’s records, exactly as for records that do not exist', async () => {
    for (const path of [
      `/courses/${b.course}`,
      `/categories/${b.category}`,
      `/students/${b.student}`,
      `/certificates/${b.certificate}`,
      `/instructors/${b.instructor}`,
      `/media/${b.media}`,
    ]) {
      expect((await adminA.get(path)).status, path).toBe(404);
    }
  });

  // An admin passes the instructor scope check for any course id, so the nested course routes must
  // still confirm the course is the workspace's own — a 404, never an empty 200.
  it('answers 404 on another tenant’s course through the nested lesson and chapter routes', async () => {
    for (const path of [`/courses/${b.course}/lessons`, `/courses/${b.course}/chapters/stats`, '/courses/no-such-course/lessons']) {
      expect((await adminA.get(path)).status, path).toBe(404);
    }
    expect((await adminA.post(`/courses/${b.course}/chapters`, { input: { title: 'Planted chapter' } })).status).toBe(404);
  });

  it('cannot change or delete another tenant’s record, and leaves it as it was', async () => {
    const before = await platformDb.course.findUniqueOrThrow({ where: { id: b.course } });
    expect((await adminA.patch(`/courses/${b.course}`, { title: 'Hijacked' })).status).toBe(404);
    expect((await adminA.post(`/courses/${b.course}/archive`)).status).toBe(404);
    expect((await adminA.delete(`/categories/${b.category}`)).status).toBe(404);
    expect((await adminA.post(`/students/${b.student}/suspend`, { suspended: true, reason: 'Nope' })).status).toBe(404);
    expect(await platformDb.course.findUniqueOrThrow({ where: { id: b.course } })).toEqual(before);
    expect(await platformDb.category.findUnique({ where: { id: b.category } })).not.toBeNull();
    expect((await platformDb.student.findUniqueOrThrow({ where: { id: b.student } })).suspended).toBe(false);
  });

  it('keeps every list to the workspace', async () => {
    const [courses, students, categories, instructors] = await Promise.all([
      adminA.get('/courses', { pageSize: 100 }),
      adminA.get('/students', { pageSize: 100 }),
      adminA.get('/categories'),
      adminA.get('/instructors'),
    ]);
    expect(ids(courses.body.rows)).not.toContain(b.course);
    expect(JSON.stringify(students.body)).not.toContain(b.student);
    expect(JSON.stringify(categories.body)).not.toContain(b.category);
    expect(JSON.stringify(instructors.body)).not.toContain(b.instructor);
  });

  it('shows visitors the workspace’s catalog only, and resolves a shared slug to the workspace’s course', async () => {
    const publicList = await anon().get('/catalog/courses');
    expect(ids(publicList.body)).not.toContain(b.course);
    expect((await anon().get(`/catalog/courses/${b.courseSlug}`)).body.id).toBe(a.course);
  });

  it('confines a workspace-wide write to the workspace', async () => {
    // Setting a default template clears every other default with `where: {}` — in the workspace only.
    const templates = (await adminA.get('/certificates/templates')).body as { template: { id: string } }[];
    expect((await adminA.post(`/certificates/templates/${templates[0].template.id}/default`)).status).toBe(200);
    expect((await platformDb.certificateTemplate.findUniqueOrThrow({ where: { id: b.template } })).isDefault).toBe(true);
  });
});

describe('isolation: ids in bodies', () => {
  it('refuses to point a new record at another tenant’s rows', async () => {
    const title = `Cross-linked ${suffix}`;
    const res = await adminA.post('/courses', { title, levelId: b.level, categoryId: b.category, coverMotif: 'orbits', instructorIds: [] });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
    expect(await platformDb.course.count({ where: { title } })).toBe(0);
  });

  it('refuses to enrol another tenant’s learner, or into another tenant’s course', async () => {
    expect((await adminA.post(`/students/${b.student}/enroll`, { courseId: a.course, source: 'admin' })).status).toBe(404);
    expect((await adminA.post(`/students/${a.student}/enroll`, { courseId: b.course, source: 'admin' })).status).toBe(404);
    expect(
      await platformDb.enrollment.count({
        where: {
          OR: [
            { studentId: b.student, courseId: a.course },
            { studentId: a.student, courseId: b.course },
          ],
        },
      }),
    ).toBe(0);
  });

  it('refuses to move a record onto another tenant’s rows with an update', async () => {
    const res = await adminA.patch(`/courses/${a.course}`, { categoryId: b.category });
    expect(res.status).toBe(404);
    expect((await platformDb.course.findUniqueOrThrow({ where: { id: a.course } })).categoryId).not.toBe(b.category);
  });
});

/* ─── The query boundary itself ─────────────────────────────────────── */

describe('tenant-scoped queries', () => {
  it('refuses a tenant-owned query that runs with no context at all', async () => {
    await expect(prodDb.course.count()).rejects.toBeInstanceOf(TenantContextError);
    await expect(prodDb.user.findMany()).rejects.toBeInstanceOf(TenantContextError);
  });

  it('answers each tenant with its own rows, and the platform with everyone’s', async () => {
    const [inA, inB, platformA, platformB, all] = await Promise.all([
      forTenant(A).course.count(),
      forTenant(B).course.count(),
      platformDb.course.count({ where: { tenantId: A } }),
      platformDb.course.count({ where: { tenantId: B } }),
      platformDb.course.count(),
    ]);
    expect(inB).toBe(1);
    expect(inA).toBe(platformA);
    expect(inB).toBe(platformB);
    expect(all).toBeGreaterThanOrEqual(inA + inB);
  });

  it('refuses a write that names another tenant, or moves a row to one', async () => {
    await expect(runInTenant(A, () => prodDb.level.create({ data: { tenantId: B, name: 'Smuggled', order: 9 } }))).rejects.toBeInstanceOf(TenantContextError);
    await expect(runInTenant(A, () => prodDb.level.updateMany({ data: { tenantId: B } }))).rejects.toBeInstanceOf(TenantContextError);
    await expect(runInTenant(A, () => prodDb.level.findMany({ where: { tenantId: B } }))).rejects.toBeInstanceOf(TenantContextError);
  });

  it('stamps nested creates with the tenant', async () => {
    const created = await runInTenant(B, () =>
      prodDb.category.create({
        // tenantId left out on purpose, parent and child: the extension supplies both.
        data: {
          name: `Nested ${suffix}`,
          description: 'Nested',
          order: 2,
          status: 'active',
          glyph: 'sun',
          levels: { create: [{ levelId: b.level }] },
        } as never,
      }),
    );
    const links = await platformDb.categoryLevel.findMany({ where: { categoryId: created.id } });
    expect((await platformDb.category.findUniqueOrThrow({ where: { id: created.id } })).tenantId).toBe(B);
    expect(links.map((l) => l.tenantId)).toEqual([B]);
  });

  it('refuses a write whose foreign key points at another tenant', async () => {
    await expect(runInTenant(A, () => prodDb.enrollment.create({ data: { tenantId: A, studentId: b.student, courseId: a.course } }))).rejects.toMatchObject({
      status: 404,
    });
  });

  it('keeps a workspace account inside a tenant and a super admin outside one (D1)', async () => {
    await expect(
      runAsPlatform('test', () => prodDb.user.create({ data: { name: 'Orphan', email: `orphan-${suffix}@example.com`, passwordHash: 'x', role: 'admin' } })),
    ).rejects.toBeInstanceOf(TenantContextError);
    await expect(
      runInTenant(A, () =>
        prodDb.user.create({ data: { tenantId: A, name: 'Bound', email: `bound-${suffix}@example.com`, passwordHash: 'x', role: 'superadmin' } }),
      ),
    ).rejects.toBeInstanceOf(TenantContextError);
  });

  it('keeps stamping but stops filtering when enforcement is switched off — the rollback switch', async () => {
    process.env.TENANT_ENFORCEMENT = 'off';
    try {
      expect(await prodDb.course.count()).toBe(await platformDb.course.count());
      const level = await runInTenant(B, () => prodDb.level.create({ data: { name: `Off ${suffix}`, order: 7 } as never }));
      expect(level.tenantId).toBe(B);
    } finally {
      delete process.env.TENANT_ENFORCEMENT;
    }
    await expect(prodDb.course.count()).rejects.toBeInstanceOf(TenantContextError);
  });
});

/* ─── The Super Admin runs the workspace and reads the platform ─────── */

describe('the Super Admin', () => {
  it('sees every account with its tenant, and super admins with none', async () => {
    // Every page: the whole suite creates more accounts than one page holds (500 at most).
    type Row = { email: string; role: string; tenant?: { id: string } };
    const rows: Row[] = [];
    let total = 0;
    for (let page = 1; page === 1 || rows.length < total; page++) {
      const res = await platform.get('/superadmin/users', { pageSize: 500, page });
      expect(res.status).toBe(200);
      total = res.body.total;
      if (!(res.body.rows as Row[]).length) break;
      rows.push(...(res.body.rows as Row[]));
    }
    expect(rows.find((r) => r.email === b.adminEmail)?.tenant?.id).toBe(B);
    expect(rows.find((r) => r.email === ACCOUNTS.admin)?.tenant?.id).toBe(A);
    for (const row of rows.filter((r) => r.role === 'superadmin')) expect(row.tenant).toBeUndefined();
    expect(total).toBe(await platformDb.user.count());
    expect(rows).toHaveLength(total);
  });

  it('creates a staff admin in the workspace, whatever tenant the body names, who then works in the workspace', async () => {
    const email = `staff-admin-${suffix}@example.com`;
    const created = await platform.post('/superadmin/admins', { name: 'Staff Admin', email, password: B_PASSWORD, tenantId: B });
    expect(created.status, JSON.stringify(created.body)).toBe(201);
    expect(created.body.tenant?.id).toBe(A);
    const grants = await platformDb.adminPermission.findMany({ where: { userId: created.body.id } });
    expect(grants.length).toBeGreaterThan(0);
    expect(new Set(grants.map((g) => g.tenantId))).toEqual(new Set([A]));
    const client = await as({ email, password: B_PASSWORD });
    const courses = ids((await client.get('/courses', { pageSize: 100 })).body.rows);
    expect(courses).toContain(a.course);
    expect(courses).not.toContain(b.course);
  });

  it('manages the workspace’s courses, people and settings through the same routes staff use (D-PLAT-03)', async () => {
    const courses = await platform.get('/courses', { pageSize: 100 });
    expect(courses.status).toBe(200);
    expect(ids(courses.body.rows)).toContain(a.course);
    expect(ids(courses.body.rows)).not.toContain(b.course);
    expect((await platform.get(`/courses/${b.course}`)).status).toBe(404);
    expect((await platform.get('/settings')).status).toBe(200);
    expect((await platform.get('/students', { pageSize: 5 })).status).toBe(200);
    // A write, with its audit row under the super admin.
    const name = `Platform category ${suffix}`;
    const created = await platform.post('/categories', { name, description: 'Made by the owner.', glyph: 'sun', status: 'active', levelIds: [] });
    expect(created.status, JSON.stringify(created.body)).toBe(201);
    expect((await platformDb.category.findUniqueOrThrow({ where: { id: created.body.id } })).tenantId).toBe(A);
  });

  it('can own what it makes in the workspace, though it has no tenant of its own', async () => {
    const superUser = await platformDb.user.findUniqueOrThrow({ where: { email: `tenancy-platform-${suffix}@example.com` } });
    const event = (ownerId: string) => ({
      data: { tenantId: A, type: 'event', title: `Owned ${suffix}`, timing: 'timed', startsAt: new Date(), ownerId },
    });
    const row = await runInTenant(A, () => prodDb.calendarEvent.create(event(superUser.id)));
    expect(row).toMatchObject({ tenantId: A, ownerId: superUser.id });
    // A row may still never name another tenant's account.
    await expect(runInTenant(A, () => prodDb.calendarEvent.create(event(b.adminId)))).rejects.toMatchObject({ status: 404 });
  });

  it('keeps the platform surface closed to a staff admin', async () => {
    expect((await adminA.get('/superadmin/users')).status).toBe(403);
    expect((await adminA.get('/superadmin/overview')).status).toBe(403);
  });
});

/* ─── Platform-wide by decision ─────────────────────────────────────── */

describe('platform-wide lookups', () => {
  it('issues a reset link in the account’s own tenant, and in none for a super admin', async () => {
    expect((await anon().post('/auth/forgot-password', { email: b.learnerEmail })).status).toBe(200);
    expect((await platformDb.passwordResetToken.findFirstOrThrow({ where: { userId: b.learnerUserId }, orderBy: { createdAt: 'desc' } })).tenantId).toBe(B);
    expect((await platformDb.emailOutbox.findFirstOrThrow({ where: { toEmail: b.learnerEmail }, orderBy: { createdAt: 'desc' } })).tenantId).toBe(B);

    const superEmail = `tenancy-platform-${suffix}@example.com`;
    const superUser = await platformDb.user.findUniqueOrThrow({ where: { email: superEmail } });
    expect((await anon().post('/auth/forgot-password', { email: superEmail })).status).toBe(200);
    expect((await platformDb.passwordResetToken.findFirstOrThrow({ where: { userId: superUser.id }, orderBy: { createdAt: 'desc' } })).tenantId).toBeNull();
    expect((await platformDb.emailOutbox.findFirstOrThrow({ where: { toEmail: superEmail }, orderBy: { createdAt: 'desc' } })).tenantId).toBeNull();
  });

  it('hands out a credential ID no tenant already holds (D4)', async () => {
    const title = 'Maths Foundations for Classes 6–8';
    const next = await runInTenant(A, () => nextCredentialId(title, 'SA'));
    // Another tenant takes that exact number first…
    await forTenant(B).issuedCertificate.create({
      data: {
        tenantId: B,
        credentialId: next,
        studentId: b.student,
        courseId: b.course,
        title: 'Taken first',
        templateId: b.template,
        completedAt: new Date(),
      },
    });
    // …so the workspace is handed a different one rather than a unique-index failure.
    expect(await runInTenant(A, () => nextCredentialId(title, 'SA'))).not.toBe(next);
  });

  it('verifies the workspace’s certificates by credential', async () => {
    const aCredential = (await platformDb.issuedCertificate.findUniqueOrThrow({ where: { id: a.certificate } })).credentialId;
    expect((await anon().get(`/certificates/verify/${aCredential}`)).status).toBe(200);
  });
});

/* ─── Scheduled work runs per active tenant ─────────────────────────── */

describe('scheduled work', () => {
  it('runs once inside every active tenant', async () => {
    const seen = await forEachTenant(async () => currentTenantId());
    expect(seen.get(A)).toBe(A);
    expect(seen.get(B)).toBe(B);
  });

  it('skips an archived tenant', async () => {
    await platformDb.tenant.update({ where: { id: B }, data: { status: 'archived' } });
    try {
      const seen = await forEachTenant(async () => currentTenantId());
      expect(seen.has(A)).toBe(true);
      expect(seen.has(B)).toBe(false);
    } finally {
      await platformDb.tenant.update({ where: { id: B }, data: { status: 'active' } });
    }
  });

  it('keeps going when one tenant fails, and reports the failure as a job signal', async () => {
    const signals: Observation[] = [];
    setObservationSink((_line, o) => signals.push(o));
    try {
      const seen = await forEachTenant(async (id) => {
        if (id === B) throw new Error('this academy is broken');
        return id;
      }, 'test-job');
      expect(seen.has(A)).toBe(true);
      expect(seen.has(B)).toBe(false);
      const failed = signals.filter((o) => o.signal === 'job.failed');
      expect(failed).toHaveLength(1);
      expect(failed[0].fields).toMatchObject({ job: 'test-job', tenantId: B, error: { name: 'Error', message: 'this academy is broken' } });
    } finally {
      setObservationSink(undefined);
    }
  });

  it('runs the real every-minute jobs inside one tenant without touching another', async () => {
    // The real jobs, run for the second tenant only — running them for the workspace would archive and nudge the
    // fixtures other suites rely on. What matters is that nothing leaks across.
    const aBefore = await Promise.all([
      platformDb.appNotification.count({ where: { tenantId: A } }),
      platformDb.course.count({ where: { tenantId: A, status: 'archived' } }),
      platformDb.emailOutbox.count({ where: { tenantId: A } }),
    ]);
    await runInTenant(B, () => Promise.all([sendDueReminders(new Date()), sendDueCalendarReminders(new Date()), runNotificationJobs(new Date())]));
    const aAfter = await Promise.all([
      platformDb.appNotification.count({ where: { tenantId: A } }),
      platformDb.course.count({ where: { tenantId: A, status: 'archived' } }),
      platformDb.emailOutbox.count({ where: { tenantId: A } }),
    ]);
    expect(aAfter).toEqual(aBefore);
    // And every row the jobs wrote belongs to the tenant they ran for.
    expect(await platformDb.appNotification.count({ where: { recipient: { tenantId: B }, NOT: { tenantId: B } } })).toBe(0);
  });

  it('is what the every-minute tick runs: the same work, once per tenant', () => {
    expect(runScheduledJobs.toString()).toContain('runNotificationSchedule');
    expect(runNotificationSchedule.toString()).toContain('forEachTenant');
  });
});
