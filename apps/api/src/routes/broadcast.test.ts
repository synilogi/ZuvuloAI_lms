import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { db, platformDb, T } from '../test/db.js';
import { app, as, newStudent, type Client } from '../test/helpers.js';

/* The Super Admin's broadcast: who it reaches, that the count shown is the count sent, who may send it, and the trail. */

let owner: Client;
let ownerUserId: string;
let admin: Client;
let instructor: Client;
let outsiderTenant: string;
let outsiderUser: string;
let title = 0;

const body = (audience: unknown, extra: object = {}) => ({
  audience,
  title: `Maintenance notice ${++title}`,
  summary: 'The platform is down for an hour on Sunday.',
  ...extra,
});
const countOf = async (audience: string) => (await owner.get('/superadmin/notifications/audience-count', { audience })).body.count as number;
const received = (userId: string, subject: string) => platformDb.appNotification.count({ where: { recipientId: userId, title: subject, category: 'system' } });

beforeAll(async () => {
  const email = `broadcast-owner-${Date.now()}@example.com`;
  await provisionSuperAdmin({ email, password: 'broadcast-owner-secret-1', name: 'Owner' });
  owner = await as({ email, password: 'broadcast-owner-secret-1' });
  ownerUserId = (await platformDb.user.findUniqueOrThrow({ where: { email } })).id;
  admin = await as('admin');
  instructor = await as('instructor');

  // An account of an academy kept from the SaaS era (D-PLAT-02): closed, and never in an audience.
  const suffix = Date.now();
  outsiderTenant = `broadcast-closed-${suffix}`;
  await platformDb.tenant.create({ data: { id: outsiderTenant, name: 'Closed Academy', slug: outsiderTenant, status: 'archived' } });
  const outsider = await platformDb.user.create({
    data: { tenantId: outsiderTenant, email: `outsider-${suffix}@example.com`, name: 'Out Sider', role: 'student', passwordHash: 'x' },
  });
  outsiderUser = outsider.id;
  await platformDb.student.create({ data: { tenantId: outsiderTenant, userId: outsider.id } });
});

afterAll(async () => {
  await platformDb.appNotification.deleteMany({ where: { recipientId: outsiderUser } });
  await platformDb.user.delete({ where: { id: outsiderUser } });
  await platformDb.tenant.delete({ where: { id: outsiderTenant } });
});

describe('who may broadcast', () => {
  it('refuses everyone but the owner, before reading the body', async () => {
    const learner = await newStudent('Broadcast Learner');
    for (const client of [admin, instructor, learner]) {
      expect((await client.post('/superadmin/notifications/broadcast', body('students'))).status).toBe(403);
      expect((await client.get('/superadmin/notifications/audience-count', { audience: 'students' })).status).toBe(403);
      expect((await client.get('/superadmin/notifications/broadcasts')).status).toBe(403);
    }
    expect((await request(app).post('/superadmin/notifications/broadcast').send(body('students'))).status).toBe(401);
    expect((await request(app).get('/superadmin/notifications/audience-count').query({ audience: 'students' })).status).toBe(401);
  });
});

describe('the input', () => {
  it('takes one audience, one line of title and a summary', async () => {
    const send = (b: object) => owner.post('/superadmin/notifications/broadcast', b);
    expect((await send(body('everyone'))).status).toBe(400);
    expect((await send(body(['students', 'instructors']))).status).toBe(400);
    expect((await send(body(undefined))).status).toBe(400);
    expect((await send(body('staff', { title: 'Two\nlines' }))).status).toBe(400);
    expect((await send(body('staff', { title: 'x'.repeat(121) }))).status).toBe(400);
    expect((await send(body('staff', { summary: 'x'.repeat(501) }))).status).toBe(400);
    expect((await send(body('staff', { summary: ' ' }))).status).toBe(400);
    expect((await owner.get('/superadmin/notifications/audience-count', { audience: 'nobody' })).status).toBe(400);
    expect((await owner.get('/superadmin/notifications/audience-count')).status).toBe(400);
  });
});

describe('the audience', () => {
  it('counts the accounts that can sign in, and adds up', async () => {
    const [all, students, instructors, staff] = await Promise.all(['all', 'students', 'instructors', 'staff'].map(countOf));
    expect(students).toBeGreaterThan(0);
    expect(instructors).toBeGreaterThan(0);
    expect(staff).toBeGreaterThan(0);
    expect(all).toBe(students + instructors + staff);

    const before = students;
    const learner = await newStudent('Counted Learner');
    expect(await countOf('students')).toBe(before + 1);
    await db.student.update({ where: { id: learner.studentId }, data: { suspended: true } });
    expect(await countOf('students')).toBe(before);
    await db.student.update({ where: { id: learner.studentId }, data: { suspended: false } });
  });

  it('reaches students only, for that audience, and leaves out the suspended, the deactivated and another academy', async () => {
    const reached = await newStudent('Reached Learner');
    const suspended = await newStudent('Suspended Learner');
    const deactivated = await newStudent('Deactivated Learner');
    await db.student.update({ where: { id: suspended.studentId }, data: { suspended: true } });
    await db.user.update({ where: { id: deactivated.userId }, data: { deactivatedAt: new Date() } });
    const instructorUser = await db.user.findFirstOrThrow({ where: { role: 'instructor', instructor: { status: 'active' } } });

    const input = body('students');
    const expected = await countOf('students');
    const res = await owner.post('/superadmin/notifications/broadcast', input);
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body).toMatchObject({ audience: 'students', recipients: expected, failed: 0 });
    expect(res.body.delivered).toBe(expected);

    expect(await received(reached.userId, input.title)).toBe(1);
    expect(await received(suspended.userId, input.title)).toBe(0);
    expect(await received(deactivated.userId, input.title)).toBe(0);
    expect(await received(instructorUser.id, input.title)).toBe(0);
    expect(await received(ownerUserId, input.title)).toBe(0);
    expect(await received(outsiderUser, input.title)).toBe(0);

    // In the workspace, where the learner reads it, and by email: `system` is not left to a digest.
    const list = await reached.get('/notifications');
    expect(JSON.stringify(list.body)).toContain(input.title);
    expect(await platformDb.emailOutbox.count({ where: { toEmail: reached.email, subject: input.title } })).toBe(1);

    await db.student.update({ where: { id: suspended.studentId }, data: { suspended: false } });
  });

  it('leaves out an instructor who is pending or inactive, and reaches the owners under staff and all', async () => {
    const active = await db.user.findFirstOrThrow({ where: { role: 'instructor', instructor: { status: 'active' } }, include: { instructor: true } });
    const adminUser = await db.user.findFirstOrThrow({ where: { role: 'admin', deactivatedAt: null } });
    const before = await countOf('instructors');
    await db.instructor.update({ where: { id: active.instructorId! }, data: { status: 'pending' } });
    try {
      expect(await countOf('instructors')).toBe(before - 1);
      const input = body('instructors');
      await owner.post('/superadmin/notifications/broadcast', input);
      expect(await received(active.id, input.title)).toBe(0);
    } finally {
      await db.instructor.update({ where: { id: active.instructorId! }, data: { status: 'active' } });
    }

    const staff = body('staff');
    const sent = await owner.post('/superadmin/notifications/broadcast', staff);
    expect(sent.status).toBe(201);
    expect(await received(ownerUserId, staff.title)).toBe(1);
    expect(await received(adminUser.id, staff.title)).toBe(1);
    expect(await received(active.id, staff.title)).toBe(0);
  });
});

describe('the recipient’s preferences', () => {
  it('honours a pause; `system` cannot be switched off by category, as everywhere else', async () => {
    const paused = await newStudent('Paused Reader');
    const optedOut = await newStudent('Opted Out Reader');
    await db.notificationSettings.create({ data: { ...T, userId: paused.userId, pausedUntil: new Date(Date.now() + 86_400_000) } });
    await db.notificationSettings.create({
      data: { ...T, userId: optedOut.userId, categoriesJson: JSON.stringify([{ category: 'system', channels: { app: false, email: false, sms: false } }]) },
    });

    const input = body('students');
    const res = await owner.post('/superadmin/notifications/broadcast', input);
    expect(res.status).toBe(201);
    expect(res.body.delivered).toBe(res.body.recipients - 1);
    expect(await received(paused.userId, input.title)).toBe(0);
    expect(await platformDb.emailOutbox.count({ where: { toEmail: paused.email, subject: input.title } })).toBe(0);
    expect(await received(optedOut.userId, input.title)).toBe(1);
  });
});

describe('the trail', () => {
  it('audits each broadcast with its count, and reads the history from the audit log', async () => {
    const input = body('staff', { summary: 'A note for the team.' });
    const expected = await countOf('staff');
    const res = await owner.post('/superadmin/notifications/broadcast', input);
    const rows = await platformDb.auditLog.findMany({ where: { targetType: 'broadcast', targetId: res.body.id } });
    expect(rows.map((r) => r.action).sort()).toEqual(['notification.broadcast.sent', 'notification.broadcast.started']);
    expect(rows.every((r) => r.actorRole === 'superadmin')).toBe(true);
    expect(JSON.parse(rows.find((r) => r.action.endsWith('sent'))!.metaJson)).toMatchObject({
      audience: 'staff',
      recipients: expected,
      delivered: expected,
      failed: 0,
    });
    expect(JSON.parse(rows.find((r) => r.action.endsWith('started'))!.metaJson)).toMatchObject({ title: input.title, recipients: expected });

    const history = await owner.get('/superadmin/notifications/broadcasts', { pageSize: 1 });
    expect(history.status).toBe(200);
    expect(history.body.total).toBeGreaterThan(1);
    expect(history.body.rows).toHaveLength(1);
    expect(history.body.rows[0]).toMatchObject({
      id: res.body.id,
      audience: 'staff',
      title: input.title,
      summary: input.summary,
      recipients: expected,
      delivered: expected,
      failed: 0,
      state: 'sent',
    });
  });

  it('shows a broadcast that began and never closed as unfinished', async () => {
    const started = await platformDb.auditLog.create({
      data: {
        action: 'notification.broadcast.started',
        targetType: 'broadcast',
        targetId: `crashed-${Date.now()}`,
        actorEmail: 'owner@example.com',
        actorRole: 'superadmin',
        metaJson: JSON.stringify({ audience: 'all', title: 'Interrupted', summary: 'Cut short', recipients: 9 }),
      },
    });
    const history = await owner.get('/superadmin/notifications/broadcasts', { pageSize: 50 });
    const row = history.body.rows.find((r: { id: string }) => r.id === started.targetId);
    expect(row).toMatchObject({ state: 'unfinished', recipients: 9, title: 'Interrupted' });
    expect(row.delivered).toBeUndefined();
  });
});
