import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { app, as, unique, type Client } from '../test/helpers.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';

/* The company website's contact form and the platform team's inbox (SAAS-027). */

const PASSWORD = 'inquiry-password-1';
let platform: Client;

const send = (body: object) => request(app).post('/public/inquiries').send(body);
const form = (over: object = {}) => ({
  kind: 'demo',
  name: 'Lakshmi Iyer',
  email: `lead-${unique()}@school.example`,
  organisation: 'Saraswati Coaching Institute',
  phone: '+91 98450 12345',
  size: '200–500 learners',
  message: 'We teach 300 students across three cities and want to move our classes online.',
  ...over,
});

beforeAll(async () => {
  const email = `inq-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Inbox Platform' });
  platform = await as({ email, password: PASSWORD });
});

describe('the contact form', () => {
  it('stores a visitor’s request for the platform, belonging to no academy', async () => {
    const body = form();
    const res = await send(body);
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body).toEqual({ received: true });
    const row = await platformDb.inquiry.findFirstOrThrow({ where: { email: body.email } });
    expect(row).toMatchObject({ kind: 'demo', status: 'new', tenantId: null, organisation: 'Saraswati Coaching Institute', size: '200–500 learners' });
  });

  it('refuses what is not a request, and quietly drops a bot’s', async () => {
    expect((await send(form({ kind: 'refund' }))).status).toBe(400);
    expect((await send(form({ email: 'not-an-email' }))).status).toBe(400);
    expect((await send(form({ message: 'hi' }))).status).toBe(400);
    expect((await send(form({ phone: '<script>' }))).status).toBe(400);

    const bot = form({ website: 'http://spam.example' });
    expect((await send(bot)).status).toBe(201);
    expect(await platformDb.inquiry.count({ where: { email: bot.email } })).toBe(0);
  });

  it('never takes an academy or a status from the body', async () => {
    const body = form({ tenantId: 'tenant-1', status: 'closed', note: 'pre-approved' });
    expect((await send(body)).status).toBe(201);
    expect(await platformDb.inquiry.findFirstOrThrow({ where: { email: body.email } })).toMatchObject({ tenantId: null, status: 'new', note: null });
  });
});

describe('the platform team’s inbox', () => {
  it('lists requests newest first with counts, filters them, and moves one along on the record', async () => {
    const body = form({ kind: 'sales', organisation: `Filter Org ${unique()}` });
    await send(body);

    const list = await platform.get('/superadmin/inquiries', { kind: 'sales', search: body.organisation });
    expect(list.status).toBe(200);
    expect(list.body.rows).toHaveLength(1);
    const [row] = list.body.rows;
    expect(row).toMatchObject({ kind: 'sales', status: 'new', email: body.email });
    expect(row).not.toHaveProperty('academy');
    expect(list.body.counts.new).toBeGreaterThan(0);

    const moved = await platform.patch(`/superadmin/inquiries/${row.id}`, { status: 'in_progress', note: 'Called, demo booked Monday.' });
    expect(moved.status).toBe(200);
    expect(moved.body).toMatchObject({ status: 'in_progress', note: 'Called, demo booked Monday.' });
    const closed = await platform.patch(`/superadmin/inquiries/${row.id}`, { status: 'closed' });
    expect(closed.body.closedAt).toBeTruthy();
    const reopened = await platform.patch(`/superadmin/inquiries/${row.id}`, { status: 'new' });
    expect(reopened.body.closedAt).toBeUndefined();

    const audit = await platformDb.auditLog.findMany({ where: { action: 'inquiry.updated', targetId: row.id } });
    expect(audit).toHaveLength(3);

    expect((await platform.patch('/superadmin/inquiries/nope', { status: 'closed' })).status).toBe(404);
    expect((await platform.patch(`/superadmin/inquiries/${row.id}`, { status: 'spam' })).status).toBe(400);
  });

  it('is the platform’s alone', async () => {
    for (const account of ['admin', 'instructor', 'student'] as const) {
      const client = await as(account);
      expect((await client.get('/superadmin/inquiries')).status, account).toBe(403);
    }
    expect((await request(app).get('/superadmin/inquiries')).status).toBe(401);
  });

  it('keeps every request: a delete is refused by the database', async () => {
    const body = form();
    await send(body);
    const row = await platformDb.inquiry.findFirstOrThrow({ where: { email: body.email } });
    await expect(platformDb.inquiry.delete({ where: { id: row.id } })).rejects.toThrow();
  });
});
