import { beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';

// The platform surface counts across every academy, so the expectations do too.
import { platformDb as db } from '../test/db.js';
import { runAsPlatform } from '../lib/tenancy.js';
import { recordAuditLog } from '../lib/audit.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { ACCOUNTS, PASSWORD, anon, app, as, unique, type Client } from '../test/helpers.js';

/* The platform surface. Super Admin has no seeded account (the seed is never modified), so the
 * suite provisions one the same way an operator would and signs in through the real login route. */

const PATHS = ['/superadmin/overview', '/superadmin/admins', '/superadmin/users', '/superadmin/audit', '/superadmin/system'] as const;
const SECRET = 'superadmin-suite-password';

let platform: Client;
let platformUserId: string;
let admin: Client;

beforeAll(async () => {
  const email = `platform-${unique()}@example.com`;
  const created = await provisionSuperAdmin({ email, password: SECRET, name: 'Platform Owner' });
  platformUserId = created.user.id;
  platform = await as({ email, password: SECRET });
  admin = await as('admin');
});

describe('every /superadmin route is for the super admin alone', () => {
  it('refuses an anonymous caller and an unusable token', async () => {
    for (const path of PATHS) {
      expect((await anon().get(path)).status).toBe(401);
      expect((await request(app).get(path).set('Authorization', 'Bearer not-a-real-token')).status).toBe(401);
    }
  });

  it('refuses the academy admin, an instructor and a learner', async () => {
    const instructor = await as('instructor');
    const student = await as('student');
    for (const path of PATHS) {
      expect((await admin.get(path)).status).toBe(403);
      expect((await instructor.get(path)).status).toBe(403);
      expect((await student.get(path)).status).toBe(403);
    }
  });

  it('lets the super admin through every one of them', async () => {
    for (const path of PATHS) expect((await platform.get(path)).status).toBe(200);
  });

  // The owner runs the workspace too (docs/16, D-PLAT-03): every staff route is open to the super admin, and the
  // staff admin keeps its own reach.
  it('lets the super admin into the workspace, and leaves the admin where it was', async () => {
    for (const path of ['/courses', '/students', '/settings', '/dashboard', '/reports/overview', '/instructors']) {
      expect((await platform.get(path)).status, path).toBe(200);
      expect((await admin.get(path)).status, path).toBe(200);
    }
  });
});

describe('GET /superadmin/overview', () => {
  it('summarises the platform from the records that exist', async () => {
    const res = await platform.get('/superadmin/overview');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      users: {
        total: expect.any(Number),
        students: expect.any(Number),
        instructors: expect.any(Number),
        admins: expect.any(Number),
        superadmins: expect.any(Number),
      },
      people: {
        studentProfiles: expect.any(Number),
        suspendedStudents: expect.any(Number),
        instructorProfiles: expect.any(Number),
        inactiveInstructors: expect.any(Number),
      },
      courses: { total: expect.any(Number), published: expect.any(Number), draft: expect.any(Number), archived: expect.any(Number) },
      learning: { enrollments: expect.any(Number), certificatesIssued: expect.any(Number) },
      generatedAt: expect.any(String),
    });

    // The figures are the database's, not a fixture's.
    expect(res.body.users.total).toBe(await db.user.count());
    expect(res.body.users.admins).toBe(await db.user.count({ where: { role: 'admin' } }));
    expect(res.body.users.superadmins).toBeGreaterThanOrEqual(1);
    expect(res.body.courses.total).toBe(await db.course.count());
  });

  it('carries no credential of any kind', async () => {
    const body = JSON.stringify((await platform.get('/superadmin/overview')).body);
    expect(body).not.toMatch(/passwordHash|password|\$2[aby]\$|secret|token/i);
  });
});

describe('GET /superadmin/admins', () => {
  it('returns academy admins only, without a password anywhere', async () => {
    // Every page: the seeded admin is the oldest, and how many admins earlier test files created decides
    // which page it lands on.
    const res = await platform.get('/superadmin/admins', { pageSize: 100 });
    expect(res.status).toBe(200);
    expect(res.body.rows.length).toBeGreaterThan(0);
    expect(res.body.total).toBe(await db.user.count({ where: { role: 'admin' } }));
    for (let page = 2; (page - 1) * 100 < res.body.total; page++) {
      res.body.rows.push(...(await platform.get('/superadmin/admins', { pageSize: 100, page })).body.rows);
    }
    for (const row of res.body.rows as Record<string, unknown>[]) {
      expect(row.role).toBe('admin');
      expect(row).not.toHaveProperty('passwordHash');
      expect(row).not.toHaveProperty('password');
      expect(row).toMatchObject({ id: expect.any(String), name: expect.any(String), email: expect.any(String), createdAt: expect.any(String) });
    }
    expect(res.body.rows.map((r: { email: string }) => r.email)).toContain(ACCOUNTS.admin);
    // The list is admins, not everybody: no learner or instructor address appears in it.
    expect(res.body.rows.map((r: { email: string }) => r.email)).not.toContain(ACCOUNTS.student);
  });

  it('pages', async () => {
    const all = await platform.get('/superadmin/admins', { pageSize: 100 });
    const first = await platform.get('/superadmin/admins', { page: 1, pageSize: 1 });
    expect(first.body.rows).toHaveLength(Math.min(1, all.body.total));
    expect(first.body).toMatchObject({ total: all.body.total, page: 1, pageSize: 1 });
  });
});

describe('GET /superadmin/users', () => {
  it('lists accounts of every role with the role on each row and no password', async () => {
    // The API's largest page: the seeded instructors are among the oldest accounts, so a smaller page
    // depends on how many learners earlier test files happened to register.
    const res = await platform.get('/superadmin/users', { pageSize: 500 });
    expect(res.status).toBe(200);
    expect(res.body.total).toBe(await db.user.count());
    const roles = new Set((res.body.rows as { role: string }[]).map((r) => r.role));
    expect(roles.has('student')).toBe(true);
    expect(roles.has('instructor')).toBe(true);
    expect(roles.has('admin')).toBe(true);
    for (const row of res.body.rows as Record<string, unknown>[]) {
      expect(typeof row.role).toBe('string');
      expect(row).not.toHaveProperty('passwordHash');
      expect(row).not.toHaveProperty('password');
    }
    expect(JSON.stringify(res.body)).not.toMatch(/\$2[aby]\$/);
  });

  it('filters by role and searches name or email', async () => {
    const admins = await platform.get('/superadmin/users', { role: 'admin', pageSize: 100 });
    expect(admins.body.total).toBe(await db.user.count({ where: { role: 'admin' } }));
    for (const row of admins.body.rows as { role: string }[]) expect(row.role).toBe('admin');

    const byEmail = await platform.get('/superadmin/users', { search: ACCOUNTS.student });
    expect(byEmail.body.rows.map((r: { email: string }) => r.email)).toEqual([ACCOUNTS.student]);

    const byName = await platform.get('/superadmin/users', { search: 'ANANYA', pageSize: 100 });
    expect(byName.body.rows.length).toBeGreaterThan(0);
    expect(byName.body.rows.every((r: { name: string; email: string }) => /ananya/i.test(`${r.name} ${r.email}`))).toBe(true);

    const nobody = await platform.get('/superadmin/users', { search: `no-such-person-${unique()}` });
    expect(nobody.body).toMatchObject({ rows: [], total: 0 });
  });

  it('rejects a role filter that is not a role', async () => {
    expect((await platform.get('/superadmin/users', { role: 'wizard' })).status).toBe(400);
  });
});

describe('the audit trail', () => {
  it('records an event for the acting super admin and reads it back newest first', async () => {
    const marker = unique();
    const before = (await platform.get('/superadmin/audit')).body.total as number;

    // Written through the helper, the way a future Super Admin write operation will.
    const req = { auth: { sub: platformUserId, role: 'superadmin' as const } } as Parameters<typeof recordAuditLog>[0];
    const olderId = await runAsPlatform('the Super Admin router writes the audit trail', () =>
      recordAuditLog(req, { action: 'test.older', targetType: 'user', targetId: platformUserId, meta: { marker } }),
    );
    await new Promise((resolve) => setTimeout(resolve, 5));
    const newerId = await runAsPlatform('the Super Admin router writes the audit trail', () =>
      recordAuditLog(req, { action: 'test.newer', targetType: 'user', targetId: platformUserId, meta: { marker } }),
    );

    const res = await platform.get('/superadmin/audit', { pageSize: 100 });
    expect(res.status).toBe(200);
    expect(res.body.total).toBe(before + 2);

    const ids = (res.body.rows as { id: string }[]).map((r) => r.id);
    expect(ids.indexOf(newerId!)).toBeLessThan(ids.indexOf(olderId!));
    const times = (res.body.rows as { createdAt: string }[]).map((r) => Date.parse(r.createdAt));
    expect(times).toEqual([...times].sort((a, b) => b - a));

    const newest = (res.body.rows as AuditRow[]).find((r) => r.id === newerId)!;
    expect(newest).toMatchObject({
      action: 'test.newer',
      targetType: 'user',
      targetId: platformUserId,
      actor: { id: platformUserId, role: 'superadmin' },
      meta: { marker },
    });
    // The metadata comes back as an object, not the JSON text the column holds.
    expect(typeof newest.meta).toBe('object');
    expect(newest).not.toHaveProperty('metaJson');
  });

  it('is unreachable by the academy admin and carries no credential', async () => {
    expect((await admin.get('/superadmin/audit')).status).toBe(403);

    /* Checked field by field rather than by sweeping the JSON for words: ids here are random base36,
     * so a sweep for a short word like "jwt" eventually matches one by chance. */
    const rows = (await platform.get('/superadmin/audit', { pageSize: 100 })).body.rows as AuditRow[];
    expect(rows.length).toBeGreaterThan(0);
    const secretish = /^(password|passwordhash|token|secret|authorization|bearer|jwt)$/i;
    const bcrypt = /^\$2[aby]\$/;
    for (const row of rows) {
      expect(Object.keys(row), row.id).not.toContain('metaJson');
      for (const [key, value] of Object.entries(row.meta)) {
        expect(secretish.test(key), `${row.action} meta.${key}`).toBe(false);
        if (typeof value === 'string') expect(bcrypt.test(value), `${row.action} meta.${key}`).toBe(false);
      }
      for (const value of [row.actorEmail ?? '', row.actor.email, row.action, row.targetType]) {
        expect(bcrypt.test(String(value)), row.action).toBe(false);
      }
    }
  });

  it('has no way to write an entry over the API', async () => {
    expect((await platform.post('/superadmin/audit', { action: 'forged.event', targetType: 'user' })).status).toBe(404);
  });
});

interface AuditRow {
  id: string;
  actorEmail?: string;
  action: string;
  targetType: string;
  targetId?: string;
  actor: { id?: string; email: string; role: string };
  meta: Record<string, unknown>;
  createdAt: string;
}

describe('GET /superadmin/system', () => {
  it('reports operational state without a single configuration value', async () => {
    const res = await platform.get('/superadmin/system');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      database: { ok: true, latencyMs: expect.any(Number) },
      email: { queued: expect.any(Number), sent: expect.any(Number), failed: expect.any(Number) },
      media: { files: expect.any(Number), totalBytes: expect.any(Number) },
      process: { environment: 'test', uptimeSeconds: expect.any(Number) },
    });
    expect(res.body.email.queued).toBe(await db.emailOutbox.count({ where: { status: 'queued' } }));

    const body = JSON.stringify(res.body);
    for (const leak of [process.env.JWT_SECRET, process.env.DATABASE_URL, process.env.UPLOAD_DIR, PASSWORD]) {
      if (leak) expect(body).not.toContain(leak);
    }
    expect(body).not.toMatch(/secret|passwordHash|\/home\/|\/Users\//i);
  });
});
