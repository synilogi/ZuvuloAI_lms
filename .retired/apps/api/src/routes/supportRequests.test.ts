import { beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { anon, as, unique, type Client } from '../test/helpers.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';

/* Academy admins asking the platform team for help, and the Super Admin seeing clients as admins with academies
 * (SAAS-029). */

const PASSWORD = 'support-password-1';
let platform: Client;

async function newClient() {
  const slug = `sr-${unique()}`;
  const email = `sr-admin-${unique()}@example.com`;
  const res = await platform.post('/superadmin/tenants', {
    name: `Support Academy ${slug}`,
    slug,
    admin: { name: 'Support Admin', email, password: PASSWORD },
  });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return { tenantId: res.body.id as string, slug, email, admin: await as({ email, password: PASSWORD }) };
}

beforeAll(async () => {
  const email = `sr-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Support Platform' });
  platform = await as({ email, password: PASSWORD });
});

describe('an academy admin asks for help', () => {
  it('lands in the inbox with their academy and their own name — whatever the body says', async () => {
    const a = await newClient();
    const res = await a.admin.post('/tenant/support', {
      subject: 'Invoice address',
      message: 'Our GST number is missing from the last invoice.',
      tenantId: 'tenant-1',
      email: 'someone-else@example.com',
      status: 'closed',
    });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body).toMatchObject({ kind: 'support', status: 'new', email: a.email, name: 'Support Admin', subject: 'Invoice address' });

    const row = await platformDb.inquiry.findUniqueOrThrow({ where: { id: res.body.id } });
    expect(row.tenantId).toBe(a.tenantId);
    expect(await platformDb.auditLog.findFirst({ where: { action: 'inquiry.created', targetId: row.id, actorEmail: a.email } })).toBeTruthy();

    const inbox = await platform.get('/superadmin/inquiries', { kind: 'support', search: 'GST number is missing' });
    expect(inbox.body.rows.find((r: { id: string }) => r.id === row.id)).toMatchObject({ academy: { id: a.tenantId, slug: a.slug } });
  });

  it('shows an academy its own requests only, without the team’s private note', async () => {
    const a = await newClient();
    const b = await newClient();
    const sent = await a.admin.post('/tenant/support', { subject: 'Only for A', message: 'This belongs to academy A alone.' });
    await platform.patch(`/superadmin/inquiries/${sent.body.id}`, { status: 'in_progress', note: 'Internal: check Razorpay' });

    const mine = await a.admin.get('/tenant/support');
    expect(mine.body.rows).toHaveLength(1);
    expect(mine.body.rows[0]).toMatchObject({ id: sent.body.id, status: 'in_progress' });
    expect(mine.body.rows[0]).not.toHaveProperty('note');
    // Website requests (no academy) never show up for an academy either.
    expect((await b.admin.get('/tenant/support')).body.rows).toEqual([]);
  });

  it('is for academy admins only, and checks what it is sent', async () => {
    const a = await newClient();
    expect((await a.admin.post('/tenant/support', { subject: 'x', message: 'short' })).status).toBe(400);
    for (const account of ['instructor', 'student'] as const) {
      expect((await (await as(account)).post('/tenant/support', { subject: 'Help', message: 'Please help me with this.' })).status, account).toBe(403);
    }
    expect((await anon().get('/tenant/support')).status).toBe(401);
    expect((await platform.post('/tenant/support', { subject: 'Help', message: 'Please help me with this.' })).status).toBe(403);
  });
});

describe('the Super Admin’s clients', () => {
  it('finds a client by its admin, and counts clients and open requests on the overview', async () => {
    const a = await newClient();
    const found = await platform.get('/superadmin/tenants', { search: a.email });
    expect(found.body.rows.map((r: { id: string }) => r.id)).toEqual([a.tenantId]);
    expect(found.body.rows[0].owner).toMatchObject({ email: a.email });

    const overview = (await platform.get('/superadmin/overview')).body;
    expect(overview.clients.total).toBeGreaterThanOrEqual(2);
    expect(overview.clients.active).toBeGreaterThanOrEqual(1);
    expect(typeof overview.clients.selfRegistered).toBe('number');
    expect(overview.inbox.new).toBeGreaterThanOrEqual(0);
  });
});
