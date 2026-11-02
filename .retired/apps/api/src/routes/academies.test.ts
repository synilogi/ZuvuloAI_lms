import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest';

import * as settingsModule from '../lib/settings.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { forEachTenant } from '../lib/scheduler.js';
import { ACADEMY, platformDb } from '../test/db.js';
import { ACCOUNTS, PASSWORD, anon, as, unique, type Client } from '../test/helpers.js';

/* SAAS-019. The Super Admin provisions academies — atomically, with everything an academy needs to run —
 * and moves them through their lifecycle. A suspended or archived academy's members are refused on every
 * request, and its data stays. */

const SECRET = 'platform-academies-secret-1';
let platform: Client;

const newAcademy = (over: Record<string, unknown> = {}) => {
  const id = unique();
  return {
    name: `Academy ${id}`,
    slug: `academy-${id}`.toLowerCase(),
    admin: { name: 'Founding Admin', email: `founder-${id}@example.com`.toLowerCase(), password: 'founder-pass-1' },
    ...over,
  };
};

/** Starts the documented trial on the seeded Starter plan (`POST /superadmin/subscriptions`), as the platform does for a new academy. */
async function trial(tenantId: string) {
  const plan = await platformDb.plan.findFirstOrThrow({ where: { code: 'STARTER' } });
  const res = await platform.post('/superadmin/subscriptions', { tenantId, planId: plan.id, cycle: 'monthly', start: 'trial' });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
}

async function provision(over: Record<string, unknown> = {}) {
  const body = newAcademy(over);
  const res = await platform.post('/superadmin/tenants', body);
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return { body, academy: res.body as { id: string; slug: string; status: string; owner: { id: string } } };
}

beforeAll(async () => {
  const email = `platform-academies-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: SECRET, name: 'Platform Owner' });
  platform = await as({ email, password: SECRET });
});

afterEach(() => vi.restoreAllMocks());

describe('provisioning an academy', () => {
  it('creates the academy, its owner admin and everything it needs, in one step', async () => {
    const { body, academy } = await provision();
    expect(academy).toMatchObject({ name: body.name, slug: body.slug, status: 'active', accounts: 1, courses: 0, isDefault: false });

    const admin = await platformDb.user.findUniqueOrThrow({ where: { email: body.admin.email } });
    expect(admin).toMatchObject({ role: 'admin', tenantId: academy.id, name: 'Founding Admin' });
    expect(admin.passwordHash).toMatch(/^\$2/);
    expect(academy.owner.id).toBe(admin.id);
    expect(await platformDb.adminPermission.count({ where: { userId: admin.id } })).toBe(24);

    expect(await platformDb.level.count({ where: { tenantId: academy.id } })).toBe(3);
    expect(await platformDb.rank.count({ where: { tenantId: academy.id } })).toBe(3);
    const template = await platformDb.certificateTemplate.findFirstOrThrow({ where: { tenantId: academy.id } });
    expect(template.isDefault).toBe(true);
    const settings = await platformDb.settings.findUniqueOrThrow({ where: { tenantId: academy.id } });
    expect(JSON.parse(settings.generalJson)).toMatchObject({ academyName: body.name, supportEmail: body.admin.email });
    expect(JSON.parse(settings.certificatesJson).defaultTemplateId).toBe(template.id);

    const audit = await platformDb.auditLog.findFirstOrThrow({ where: { action: 'academy.created', targetId: academy.id } });
    expect(JSON.parse(audit.metaJson)).toMatchObject({ slug: body.slug, adminEmail: body.admin.email });
    expect(audit.metaJson).not.toMatch(/founder-pass/);
  });

  it('lets the new admin sign in and build a course once it has a subscription, seeing only its own academy', async () => {
    const { body, academy } = await provision();
    await trial(academy.id);
    const signIn = await anon().post('/auth/login', { email: body.admin.email, password: body.admin.password });
    expect(signIn.status).toBe(200);
    expect(signIn.body.user.permissions).toHaveLength(24);
    const founder = await as({ email: body.admin.email, password: body.admin.password });

    const levels = await platformDb.level.findMany({ where: { tenantId: academy.id }, orderBy: { order: 'asc' } });
    const category = await founder.post('/categories', { name: 'First Category', glyph: 'sun', levelIds: [levels[0].id] });
    expect(category.status).toBe(201);
    const course = await founder.post('/courses', { title: 'First Course', levelId: levels[0].id, categoryId: category.body.id });
    expect(course.status).toBe(201);
    expect((await platformDb.course.findUniqueOrThrow({ where: { id: course.body.id } })).tenantId).toBe(academy.id);

    const list = await founder.get('/courses', { pageSize: 100 });
    expect(list.body.rows.map((r: { id: string }) => r.id)).toEqual([course.body.id]);
    expect((await founder.get('/settings')).body.settings.general.academyName).toBe(body.name);
  });

  it('builds nothing under enforcement until the academy has a subscription — provisioning starts none (SAAS-025)', async () => {
    const { body, academy } = await provision();
    const founder = await as({ email: body.admin.email, password: body.admin.password });
    const level = await platformDb.level.findFirstOrThrow({ where: { tenantId: academy.id } });
    process.env.ENTITLEMENT_ENFORCEMENT = 'on';
    try {
      const refused = await founder.post('/courses', { title: 'Too Early', levelId: level.id, categoryId: 'none' });
      expect(refused.status).toBe(402);
      expect(refused.body.code).toBe('SUBSCRIPTION_REQUIRED');
      expect((await founder.get('/tenant/billing')).status).toBe(200); // it can still choose a plan
      await trial(academy.id);
      const category = await founder.post('/categories', { name: 'After Trial', glyph: 'sun', levelIds: [level.id] });
      expect(category.status).toBe(201);
      expect((await founder.post('/courses', { title: 'Now Possible', levelId: level.id, categoryId: category.body.id })).status).toBe(201);
    } finally {
      delete process.env.ENTITLEMENT_ENFORCEMENT;
    }
  });

  it('rolls everything back when a step fails part-way', async () => {
    const body = newAcademy();
    vi.spyOn(settingsModule, 'newSettingsRow').mockImplementationOnce(() => {
      throw new Error('settings could not be written');
    });
    expect((await platform.post('/superadmin/tenants', body)).status).toBe(500);
    expect(await platformDb.tenant.findUnique({ where: { slug: body.slug } })).toBeNull();
    expect(await platformDb.user.findUnique({ where: { email: body.admin.email } })).toBeNull();
    expect(await platformDb.auditLog.count({ where: { action: 'academy.created', metaJson: { contains: body.slug } } })).toBe(0);
    // Nothing was left behind for a retry to trip over.
    expect((await platform.post('/superadmin/tenants', body)).status).toBe(201);
  });

  it('refuses an invalid, reserved or taken address, a taken email and a weak password', async () => {
    const { body } = await provision();
    const cases: [Record<string, unknown>, number][] = [
      [{ slug: 'Not A Slug' }, 400],
      [{ slug: 'ab' }, 400],
      [{ slug: 'superadmin' }, 400],
      [{ slug: body.slug }, 409],
      [{ admin: { ...newAcademy().admin, email: body.admin.email } }, 409],
      [{ admin: { ...newAcademy().admin, email: ACCOUNTS.student } }, 409],
      [{ admin: { ...newAcademy().admin, password: 'short' } }, 400],
      [{ admin: undefined }, 400],
      [{ name: 'x' }, 400],
    ];
    for (const [over, status] of cases) {
      const res = await platform.post('/superadmin/tenants', newAcademy(over));
      expect(res.status, JSON.stringify(over)).toBe(status);
    }
  });

  it('is the Super Admin’s alone', async () => {
    const body = newAcademy();
    expect((await anon().post('/superadmin/tenants', body)).status).toBe(401);
    for (const account of ['admin', 'instructor', 'student'] as const) {
      expect((await (await as(account)).post('/superadmin/tenants', body)).status, account).toBe(403);
      expect((await (await as(account)).get('/superadmin/tenants')).status, account).toBe(403);
    }
    expect(await platformDb.tenant.findUnique({ where: { slug: body.slug } })).toBeNull();
  });
});

describe('reading and updating academies', () => {
  it('lists, searches, filters and pages academies, keeping the fields the list always had', async () => {
    const { academy } = await provision({ name: `Searchable Peetham ${unique()}` });
    const all = await platform.get('/superadmin/tenants', { pageSize: 500 });
    expect(all.status).toBe(200);
    const row = all.body.rows.find((r: { id: string }) => r.id === academy.id);
    expect(row).toMatchObject({ status: 'active', accounts: 1, courses: 0 });
    expect(all.body.rows.find((r: { id: string }) => r.id === ACADEMY).isDefault).toBe(true);

    const found = await platform.get('/superadmin/tenants', { search: 'Searchable Peetham' });
    expect(found.body.rows.map((r: { id: string }) => r.id)).toContain(academy.id);
    expect((await platform.get('/superadmin/tenants', { status: 'archived' })).body.rows.map((r: { id: string }) => r.id)).not.toContain(academy.id);
    const paged = await platform.get('/superadmin/tenants', { page: 1, pageSize: 1 });
    expect(paged.body.rows).toHaveLength(1);
    expect(paged.body.total).toBeGreaterThan(1);
    expect((await platform.get('/superadmin/tenants', { status: 'deleted' })).status).toBe(400);
  });

  it('shows one academy with its users, subscription and usage, and nothing of another', async () => {
    const { body, academy } = await provision();
    expect((await platform.get(`/superadmin/tenants/${academy.id}`)).body.owner.email).toBe(body.admin.email);
    const users = await platform.get(`/superadmin/tenants/${academy.id}/users`);
    expect(users.body.rows.map((u: { email: string }) => u.email)).toEqual([body.admin.email]);
    expect(JSON.stringify(users.body)).not.toMatch(/passwordHash/);
    const subscription = await platform.get(`/superadmin/tenants/${academy.id}/subscription`);
    expect(subscription.status).toBe(200);
    expect(subscription.body).toMatchObject({ academy: { id: academy.id }, subscription: null, invoices: [] });
    const usage = await platform.get(`/superadmin/tenants/${academy.id}/usage`);
    expect(usage.body.lines.find((l: { limit: string }) => l.limit === 'admin_accounts.max').used).toBe(1);
    for (const path of ['', '/users', '/subscription', '/usage'])
      expect((await platform.get(`/superadmin/tenants/no-such-academy${path}`)).status, path).toBe(404);
  });

  it('renames an academy and moves its address, but not the address of the academy this site serves', async () => {
    const { academy } = await provision();
    const moved = `moved-${unique()}`.toLowerCase();
    const res = await platform.patch(`/superadmin/tenants/${academy.id}`, { name: 'Renamed Academy', slug: moved });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ name: 'Renamed Academy', slug: moved });
    expect(await platformDb.auditLog.count({ where: { action: 'academy.updated', targetId: academy.id } })).toBe(1);
    expect((await platform.patch(`/superadmin/tenants/${ACADEMY}`, { slug: `other-${unique()}`.toLowerCase() })).status).toBe(409);
    expect((await platform.patch(`/superadmin/tenants/${academy.id}`, { slug: 'Bad Slug' })).status).toBe(400);
    expect((await platform.patch(`/superadmin/tenants/${academy.id}`, { status: 'archived', id: 'x' })).body.status).toBe('active');
  });
});

describe('an academy’s lifecycle is enforced on every request', () => {
  it('closes a suspended academy to all its members at once, keeps its data, and opens it again', async () => {
    const { body, academy } = await provision();
    await trial(academy.id);
    const founder = await as({ email: body.admin.email, password: body.admin.password });
    const level = await platformDb.level.findFirstOrThrow({ where: { tenantId: academy.id } });
    const category = await founder.post('/categories', { name: 'Kept Category', glyph: 'sun', levelIds: [level.id] });
    expect(category.status).toBe(201);

    expect((await platform.post(`/superadmin/tenants/${academy.id}/suspend`, {})).status).toBe(400);
    const suspended = await platform.post(`/superadmin/tenants/${academy.id}/suspend`, { reason: 'Terms of service review' });
    expect(suspended.body).toMatchObject({ status: 'suspended', statusReason: 'Terms of service review' });

    // Same token, no new sign-in: every route refuses, with the stable code.
    for (const path of ['/auth/me', '/courses', '/categories', '/settings', '/tenant/billing', '/catalog/courses', '/notifications']) {
      const res = await founder.get(path);
      expect(res.status, path).toBe(403);
      expect(res.body.code, path).toBe('ACADEMY_SUSPENDED');
    }
    expect((await founder.post('/categories', { name: 'Blocked', glyph: 'sun' })).body.code).toBe('ACADEMY_SUSPENDED');
    const login = await anon().post('/auth/login', { email: body.admin.email, password: body.admin.password });
    expect(login.status).toBe(403);
    expect(login.body.code).toBe('ACADEMY_SUSPENDED');
    // A wrong password still gets the same answer as for anyone: the academy's state is told only to its members.
    expect((await anon().post('/auth/login', { email: body.admin.email, password: 'wrong-password' })).status).toBe(401);

    // Other academies carry on; nothing was deleted.
    expect((await (await as('admin')).get('/courses')).status).toBe(200);
    expect(await platformDb.category.count({ where: { id: category.body.id } })).toBe(1);
    expect(await platformDb.user.count({ where: { tenantId: academy.id } })).toBe(1);

    expect((await platform.post(`/superadmin/tenants/${academy.id}/suspend`, { reason: 'again' })).status).toBe(409);
    const back = await platform.post(`/superadmin/tenants/${academy.id}/reactivate`, {});
    expect(back.body.status).toBe('active');
    expect(back.body.statusReason).toBeUndefined();
    expect((await founder.get('/categories')).status).toBe(200);
    // The academy's own lifecycle — the trial it was given writes its own, separate entry.
    const actions = (
      await platformDb.auditLog.findMany({ where: { targetId: academy.id, action: { startsWith: 'academy.' } }, orderBy: { createdAt: 'asc' } })
    ).map((a) => a.action);
    expect(actions).toEqual(['academy.created', 'academy.suspended', 'academy.reactivated']);
  });

  it('archives only once the subscription has ended, and refuses members of an archived academy with its own code', async () => {
    const { body, academy } = await provision();
    const plan = await platformDb.plan.findFirstOrThrow({ where: { code: 'STARTER' } });
    const trial = await platform.post('/superadmin/subscriptions', { tenantId: academy.id, planId: plan.id, cycle: 'monthly', start: 'trial' });
    expect(trial.status).toBe(201);
    expect((await platform.post(`/superadmin/tenants/${academy.id}/archive`, { reason: 'Closing down' })).status).toBe(409);
    expect((await platform.post(`/superadmin/subscriptions/${trial.body.id}/cancel`, { immediately: true, reason: 'Closing down' })).status).toBe(200);

    const archived = await platform.post(`/superadmin/tenants/${academy.id}/archive`, { reason: 'Closing down' });
    expect(archived.body.status).toBe('archived');
    const login = await anon().post('/auth/login', { email: body.admin.email, password: body.admin.password });
    expect(login.body.code).toBe('ACADEMY_ARCHIVED');
    // Kept, and can be reopened.
    expect(await platformDb.subscription.count({ where: { tenantId: academy.id } })).toBe(1);
    expect((await platform.post(`/superadmin/tenants/${academy.id}/reactivate`, {})).body.status).toBe('active');
  });

  it('never closes the academy this site serves, and refuses what a status cannot do', async () => {
    expect((await platform.post(`/superadmin/tenants/${ACADEMY}/suspend`, { reason: 'No' })).status).toBe(409);
    expect((await platform.post(`/superadmin/tenants/${ACADEMY}/archive`, { reason: 'No' })).status).toBe(409);
    expect((await platform.post(`/superadmin/tenants/${ACADEMY}/reactivate`, {})).status).toBe(409);
    expect((await platform.post('/superadmin/tenants/no-such-academy/suspend', { reason: 'x' })).status).toBe(404);
    expect((await anon().post('/auth/login', { email: ACCOUNTS.admin, password: PASSWORD })).status).toBe(200);
  });

  it('gives a suspended academy no scheduled notifications, while its subscription keeps its billing lifecycle', async () => {
    const { academy } = await provision();
    await platform.post(`/superadmin/tenants/${academy.id}/suspend`, { reason: 'Paused by the platform' });
    const notified = await forEachTenant(async (id) => id);
    expect([...notified.keys()]).not.toContain(academy.id);
    expect([...notified.keys()]).toContain(ACADEMY);
    const billed = await forEachTenant(async (id) => id, 'billing', ['active', 'suspended']);
    expect([...billed.keys()]).toContain(academy.id);
    await platform.post(`/superadmin/tenants/${academy.id}/reactivate`, {});
  });
});
