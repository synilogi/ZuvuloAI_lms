import { generateKeyPairSync } from 'node:crypto';

import jwt from 'jsonwebtoken';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { hashPassword } from '../lib/auth.js';
import { sendDueReminders } from '../lib/liveEvents.js';
import { grantAllPermissions, revokePermission } from '../lib/permissions.js';
import { ACADEMY, db, inAcademy } from '../test/db.js';
import { as, newStudent, unique, type Client } from '../test/helpers.js';

/*
 * Live classes: who may see, register for and join a class, what a learner is shown, and the scheduling rules that keep
 * the schedule honest. The audit of 2026-10-26 found each of these open; every test here pins one shut.
 */

let admin: Client;
let instructor: Client;
let instructorId: string;
let freeCourseId: string;

const inMinutes = (m: number) => new Date(Date.now() + m * 60_000).toISOString();
const input = (courseId: string, title: string, extra: Record<string, unknown> = {}) => ({
  courseId,
  title,
  instructorId,
  startsAt: inMinutes(10),
  durationMin: 45,
  meeting: { kind: 'room' },
  reminders: [],
  ...extra,
});
const EXTERNAL = { kind: 'external', link: 'https://meet.example.com/secret-room-123' };

async function enrolledIn(courseId: string, name = 'Live Learner') {
  const learner = await newStudent(name);
  expect((await learner.post(`/learning/courses/${courseId}/enroll`)).status).toBe(200);
  return learner;
}

const enrolmentOf = (learner: { studentId: string }, courseId: string) =>
  db.enrollment.findUniqueOrThrow({ where: { studentId_courseId: { studentId: learner.studentId, courseId } } });

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  instructorId = (await instructor.get('/auth/me')).body.user.instructorId;
  freeCourseId = (
    (await instructor.get('/courses', { status: 'published', pageSize: 50 })).body.rows as { id: string; pricing: string; visibility: string }[]
  ).find((c) => c.pricing === 'free' && c.visibility === 'public')!.id;
});

describe('an outside meeting’s link', () => {
  it('reaches a learner only by joining, inside the join window — never in a listing or a course page', async () => {
    const learner = await enrolledIn(freeCourseId);
    const stranger = await newStudent('Not Enrolled');
    const later = await instructor.post('/live', input(freeCourseId, `Outside later ${unique()}`, { startsAt: inMinutes(48 * 60), meeting: EXTERNAL }));
    const soon = await instructor.post('/live', input(freeCourseId, `Outside soon ${unique()}`, { meeting: EXTERNAL }));
    expect(later.status).toBe(201);
    expect(soon.status).toBe(201);

    for (const who of [learner, stranger]) {
      const page = await who.get(`/learning/courses/${freeCourseId}`);
      expect(JSON.stringify(page.body.live)).not.toContain('secret-room-123');
      expect(page.body.live.find((l: { id: string }) => l.id === later.body.id).meeting).toEqual({ kind: 'external', linkHost: 'meet.example.com' });
    }
    expect(JSON.stringify((await learner.get('/live/learner')).body)).not.toContain('secret-room-123');
    expect(JSON.stringify((await learner.get(`/live/${later.body.id}`)).body)).not.toContain('secret-room-123');

    // Too early to join: no link.
    const early = await learner.post(`/live/${later.body.id}/join`);
    expect(early.status).toBe(409);
    expect(JSON.stringify(early.body)).not.toContain('secret-room-123');
    // In its window, an enrolled learner gets it; someone not enrolled does not.
    expect((await learner.post(`/live/${soon.body.id}/join`)).body).toEqual({ kind: 'external', link: EXTERNAL.link });
    expect((await stranger.post(`/live/${soon.body.id}/join`)).status).toBe(403);
    // Staff still see it, to run the class.
    expect((await instructor.get(`/live/${later.body.id}`)).body.liveClass.meeting.link).toBe(EXTERNAL.link);
  });
});

describe('a learner’s eligibility', () => {
  it('closes a course’s classes to a learner whose enrolment expired or is paused', async () => {
    const created = await instructor.post('/live', input(freeCourseId, `Eligibility ${unique()}`));
    const id = created.body.id as string;
    await instructor.post(`/live/${id}/start`);

    for (const status of ['expired', 'paused'] as const) {
      const learner = await enrolledIn(freeCourseId, `Was enrolled (${status})`);
      expect((await learner.get(`/live/${id}`)).status).toBe(200);
      const enrolment = await enrolmentOf(learner, freeCourseId);
      await db.enrollment.update({
        where: { id: enrolment.id },
        data: status === 'expired' ? { expiresAt: new Date(Date.now() - 1000) } : { status: 'paused' },
      });
      const list = (await learner.get('/live/learner')).body;
      expect([...list.live, ...list.upcoming].map((r: { liveClass: { id: string } }) => r.liveClass.id)).not.toContain(id);
      expect((await learner.get(`/live/${id}`)).status).toBe(403);
      expect((await learner.post(`/live/${id}/register`, { registered: true })).status).toBe(403);
      expect((await learner.post(`/live/${id}/join`)).status).toBe(403);
    }
  });

  it('opens a paid course’s classes only to learners who bought it', async () => {
    const paid = await admin.post('/courses', {
      title: `Paid live ${unique()}`,
      description: 'Paid course with live classes.',
      instructorIds: [instructorId],
      pricing: 'paid',
      priceAmount: 999,
    });
    expect((await admin.post(`/courses/${paid.body.id}/publish`)).status).toBe(200);
    const created = await instructor.post('/live', input(paid.body.id, `Paid class ${unique()}`, { meeting: EXTERNAL }));
    expect(created.status).toBe(201);
    const learner = await newStudent('Has Not Bought');
    expect((await learner.post(`/learning/courses/${paid.body.id}/enroll`)).body.code).toBe('COURSE_PURCHASE_REQUIRED');
    expect((await learner.get(`/live/${created.body.id}`)).status).toBe(403);
    expect((await learner.post(`/live/${created.body.id}/join`)).status).toBe(403);
    expect(JSON.stringify((await learner.get(`/learning/courses/${paid.body.id}`)).body)).not.toContain('secret-room-123');
  });

  it('keeps an "Any learner" class of an unpublished course out of reach', async () => {
    const draft = await admin.post('/courses', {
      title: `Draft live ${unique()}`,
      description: 'Not published.',
      instructorIds: [instructorId],
      pricing: 'free',
    });
    const created = await instructor.post('/live', input(draft.body.id, `Taster ${unique()}`, { visibility: 'public' }));
    expect(created.status).toBe(201);
    const learner = await newStudent('Any Learner');
    expect((await learner.get(`/live/${created.body.id}`)).status).toBe(404);
    expect((await learner.post(`/live/${created.body.id}/register`, { registered: true })).status).toBe(404);
  });
});

describe('registering', () => {
  it('lands where the learner asked, however often they ask — a double tap never undoes a place', async () => {
    const learner = await enrolledIn(freeCourseId);
    const created = await instructor.post('/live', input(freeCourseId, `Register ${unique()}`, { startsAt: inMinutes(24 * 60), capacity: 5 }));
    const id = created.body.id as string;
    const [a, b] = await Promise.all([learner.post(`/live/${id}/register`, { registered: true }), learner.post(`/live/${id}/register`, { registered: true })]);
    expect([a.body.registered, b.body.registered]).toEqual([true, true]);
    expect(await db.liveRegistration.count({ where: { liveClassId: id } })).toBe(1);
    expect((await learner.post(`/live/${id}/register`, { registered: false })).body.registered).toBe(false);
    expect((await learner.post(`/live/${id}/register`, { registered: false })).body.registered).toBe(false);
    // An older client without a body still toggles.
    expect((await learner.post(`/live/${id}/register`)).body.registered).toBe(true);
  });

  it('never seats more learners than the class holds, even when they ask at once', async () => {
    const created = await instructor.post('/live', input(freeCourseId, `Two seats ${unique()}`, { startsAt: inMinutes(24 * 60), capacity: 2 }));
    const learners = await Promise.all(Array.from({ length: 5 }, (_, i) => enrolledIn(freeCourseId, `Seat ${i}`)));
    await Promise.all(learners.map((l) => l.post(`/live/${created.body.id}/register`, { registered: true })));
    expect(await db.liveRegistration.count({ where: { liveClassId: created.body.id } })).toBeLessThanOrEqual(2);
  });
});

describe('scheduling', () => {
  it('refuses a host who does not teach the course, a deactivated host, an archived course, and the same class twice', async () => {
    const outsiderInstructor = await db.instructor.create({
      data: { tenantId: ACADEMY, name: `Other Teacher ${unique()}`, title: 'Teacher', email: `other-${unique()}@example.com`, status: 'active' },
    });
    const notTeaching = await admin.post('/live', { ...input(freeCourseId, `Wrong host ${unique()}`), instructorId: outsiderInstructor.id });
    expect(notTeaching.status).toBe(409);
    expect(notTeaching.body.message).toMatch(/doesn’t teach this course/);

    await db.courseInstructor.create({ data: { tenantId: ACADEMY, courseId: freeCourseId, instructorId: outsiderInstructor.id } });
    await db.instructor.update({ where: { id: outsiderInstructor.id }, data: { status: 'inactive' } });
    expect((await admin.post('/live', { ...input(freeCourseId, `Inactive host ${unique()}`), instructorId: outsiderInstructor.id })).status).toBe(409);

    const archived = await admin.post('/courses', { title: `Archived ${unique()}`, description: 'Gone.', instructorIds: [instructorId], pricing: 'free' });
    await admin.post(`/courses/${archived.body.id}/archive`);
    expect((await admin.post('/live', input(archived.body.id, `Archived class ${unique()}`))).status).toBe(409);

    const once = input(freeCourseId, `Twice ${unique()}`, { startsAt: inMinutes(72 * 60) });
    expect((await instructor.post('/live', once)).status).toBe(201);
    const twice = await instructor.post('/live', once);
    expect(twice.status).toBe(409);
    expect(twice.body.message).toMatch(/already scheduled/);
  });

  it('takes a start time only with its time zone', async () => {
    const res = await instructor.post('/live', input(freeCourseId, `No zone ${unique()}`, { startsAt: '2026-12-01T19:00' }));
    expect(res.status).toBe(400);
  });

  it('saves an edit as sent: a new course, cleared fields, reminders kept — and tells learners about a new time', async () => {
    const other = await admin.post('/courses', { title: `Second course ${unique()}`, description: 'Another.', instructorIds: [instructorId], pricing: 'free' });
    await admin.post(`/courses/${other.body.id}/publish`);
    const learner = await enrolledIn(freeCourseId, 'Hears Of The Move');
    const base = input(freeCourseId, `Edit ${unique()}`, { startsAt: inMinutes(5 * 24 * 60), capacity: 30, description: 'Bring a notebook.', reminders: [60] });
    const created = await instructor.post('/live', base);
    const before = (await learner.get('/notifications', { limit: 50 })).body.total as number;

    const moved = inMinutes(6 * 24 * 60);
    // Reminders left out of the edit: they stay as scheduled.
    const rest: Record<string, unknown> = { ...base };
    delete rest.reminders;
    const res = await instructor.patch(`/live/${created.body.id}`, { ...rest, startsAt: moved, capacity: null, description: null });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ startsAt: moved, reminders: [60] });
    expect(res.body.capacity).toBeUndefined();
    expect(res.body.description).toBeUndefined();
    const notes = (await learner.get('/notifications', { limit: 50 })).body;
    expect(notes.total).toBe(before + 1);
    expect(notes.rows[0].title).toMatch(/^New time:/);

    const switched = await instructor.patch(`/live/${created.body.id}`, { ...rest, startsAt: moved, courseId: other.body.id });
    expect(switched.body.courseId).toBe(other.body.id);
  });

  it('tells every learner of the course when a class is cancelled, not only those who held a place', async () => {
    const learner = await enrolledIn(freeCourseId, 'Never Registered');
    const created = await instructor.post('/live', input(freeCourseId, `Called off ${unique()}`, { startsAt: inMinutes(3 * 24 * 60) }));
    const before = (await learner.get('/notifications', { limit: 50 })).body.total as number;
    await instructor.post(`/live/${created.body.id}/cancel`, { reason: 'The instructor is unwell.' });
    const notes = (await learner.get('/notifications', { limit: 50 })).body;
    expect(notes.total).toBe(before + 1);
    expect(notes.rows[0].title).toMatch(/^Cancelled:/);
  });

  it('lists what is coming soonest first', async () => {
    const far = await instructor.post('/live', input(freeCourseId, `Far ${unique()}`, { startsAt: inMinutes(9 * 24 * 60) }));
    const near = await instructor.post('/live', input(freeCourseId, `Near ${unique()}`, { startsAt: inMinutes(8 * 24 * 60) }));
    const rows = (await instructor.get('/live', { view: 'upcoming', pageSize: 100 })).body.rows as { liveClass: { id: string; startsAt: string } }[];
    const order = rows.map((r) => r.liveClass.id);
    expect(order.indexOf(near.body.id)).toBeLessThan(order.indexOf(far.body.id));
    const starts = rows.map((r) => r.liveClass.startsAt);
    expect([...starts].sort()).toEqual(starts);
  });
});

describe('reminders', () => {
  it('sends one reminder, not a burst, for a class scheduled at short notice — worded by the time left', async () => {
    const learner = await enrolledIn(freeCourseId, 'Short Notice');
    const created = await instructor.post('/live', input(freeCourseId, `Short notice ${unique()}`, { startsAt: inMinutes(30), reminders: [1440, 60, 15] }));
    await learner.post(`/live/${created.body.id}/register`, { registered: true });
    const before = (await learner.get('/notifications', { limit: 50 })).body.total as number;
    await inAcademy(() => sendDueReminders(new Date()));
    const notes = (await learner.get('/notifications', { limit: 50 })).body;
    expect(notes.total).toBe(before + 1);
    expect(notes.rows[0].title).toMatch(/starts in (29|30) min/);
    expect((await instructor.post(`/live/${created.body.id}/reminders`, {})).status).not.toBe(500);
  });
});

describe('who runs a class', () => {
  it('lets an admin host only with the permission to run live classes', async () => {
    const email = `limited-admin-${unique()}@example.com`;
    const user = await db.user.create({
      data: { tenantId: ACADEMY, name: 'Limited Admin', email, passwordHash: await hashPassword('limited-admin-1'), role: 'admin' },
    });
    await inAcademy(() => grantAllPermissions(user.id));
    await inAcademy(() => revokePermission(user.id, 'live.manage'));
    const limited = await as({ email, password: 'limited-admin-1' });
    const created = await instructor.post('/live', input(freeCourseId, `Permission ${unique()}`));
    await instructor.post(`/live/${created.body.id}/start`);
    expect((await limited.post(`/live/${created.body.id}/join`)).status).toBe(403);
  });
});

describe('a room token', () => {
  const saved = { ...process.env };
  afterEach(() => {
    for (const key of ['JAAS_APP_ID', 'JAAS_KID', 'JAAS_PRIVATE_KEY', 'JAAS_WEBHOOK_SECRET']) process.env[key] = saved[key];
  });

  it('stops working when the class closes, not six hours after it was issued', async () => {
    const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
    process.env.JAAS_APP_ID = 'vpaas-magic-cookie-test';
    process.env.JAAS_KID = 'kid42';
    process.env.JAAS_PRIVATE_KEY = privateKey.export({ type: 'pkcs8', format: 'pem' }).toString().replace(/\n/g, '\\n');
    const created = await instructor.post('/live', input(freeCourseId, `Token ${unique()}`, { startsAt: inMinutes(5), durationMin: 30 }));
    const host = await instructor.post(`/live/${created.body.id}/start`);
    const claims = jwt.decode(host.body.room.jwt) as { exp: number };
    // Scheduled end (5 + 30 min) plus the hour's overrun — well short of six hours.
    expect(claims.exp * 1000).toBeLessThanOrEqual(Date.now() + (5 + 30 + 60) * 60_000 + 5_000);
  });
});
