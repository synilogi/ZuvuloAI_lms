import { beforeAll, describe, expect, it } from 'vitest';

import { db, inAcademy } from '../test/db.js';
import { sendDueReminders } from '../lib/liveEvents.js';
import { as, newStudent, unique, type Client } from '../test/helpers.js';

let admin: Client;
let instructor: Client;
let courseId: string;
let instructorId: string;

const inHours = (h: number) => new Date(Date.now() + h * 3_600_000).toISOString();
const input = (title: string, extra: Record<string, unknown> = {}) => ({
  courseId,
  title,
  instructorId,
  startsAt: inHours(48),
  durationMin: 60,
  capacity: 2,
  meeting: { kind: 'room' },
  reminders: [1440, 60],
  ...extra,
});

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  // A free course of theirs: the suite's learners enrol in it themselves (a paid one is bought).
  courseId = (
    (await instructor.get('/courses', { status: 'published', pageSize: 50 })).body.rows as { id: string; pricing: string; visibility: string }[]
  ).find((c) => c.pricing === 'free' && c.visibility === 'public')!.id;
  const me = await instructor.get('/auth/me');
  instructorId = me.body.user.instructorId;
});

describe('live classes: scheduling, notifications, locks', () => {
  it('validates, notifies enrolled learners on scheduling, and locks edits once started or cancelled', async () => {
    const learner = await newStudent('Live Learner');
    await learner.post(`/learning/courses/${courseId}/enroll`);
    expect((await instructor.post('/live', { title: 'x' })).status).toBe(400);

    const created = await instructor.post('/live', input(`Fractions ${unique()}`));
    expect(created.status).toBe(201);
    const note = (await learner.get('/notifications', { limit: 5 })).body.rows[0];
    expect(note.category).toBe('live');
    expect(note.title).toMatch(/New live class/);

    // register (capacity 2), a second learner, then a third is refused as full
    expect((await learner.post(`/live/${created.body.id}/register`)).body.registered).toBe(true);
    const second = await newStudent('Second Seat');
    await second.post(`/learning/courses/${courseId}/enroll`);
    expect((await second.post(`/live/${created.body.id}/register`)).body).toMatchObject({ registered: true, spotsLeft: 0 });
    const third = await newStudent('No Seat');
    await third.post(`/learning/courses/${courseId}/enroll`);
    expect((await third.post(`/live/${created.body.id}/register`)).status).toBe(409);

    // a manual reminder reaches the two registered learners
    const reminded = await instructor.post(`/live/${created.body.id}/remind`);
    expect(reminded.body.sent).toBe(2);
    expect((await second.get('/notifications', { limit: 5 })).body.rows[0].title).toMatch(/starts in/);

    // cancelling notifies registered learners and freezes the class
    const cancelled = await instructor.post(`/live/${created.body.id}/cancel`, { reason: 'Instructor unwell — rescheduling next week.' });
    expect(cancelled.status).toBe(200);
    expect((await learner.get('/notifications', { limit: 5 })).body.rows[0].title).toMatch(/Cancelled/);
    expect((await instructor.patch(`/live/${created.body.id}`, input('Edited'))).status).toBe(409);
    expect((await instructor.post(`/live/${created.body.id}/cancel`, { reason: 'again' })).status).toBe(409);
    expect((await third.post(`/live/${created.body.id}/register`)).status).toBe(409);

    // a class already under way cannot be edited either
    const started = await instructor.post('/live', input(`Started ${unique()}`, { startsAt: inHours(1) }));
    await db.liveClass.update({ where: { id: started.body.id }, data: { startsAt: new Date(Date.now() - 10 * 60_000) } });
    expect((await instructor.patch(`/live/${started.body.id}`, input('Too late'))).status).toBe(409);
  });

  it('shows an "Any learner" class to learners who are not enrolled, and lets them register', async () => {
    // A learner of the academy with no enrolment in this course at all.
    const outsider = await newStudent('Not Enrolled');
    const enrolledLearner = await newStudent('Enrolled Learner');
    await enrolledLearner.post(`/learning/courses/${courseId}/enroll`);

    // "Enrolled learners" (the default) stays private to the course.
    const privateClass = await instructor.post('/live', input(`Enrolled only ${unique()}`, { visibility: 'enrolled' }));
    expect(privateClass.status).toBe(201);
    const outsiderSeesPrivate = await outsider.get('/live/learner');
    expect(outsiderSeesPrivate.body.upcoming.map((r: { liveClass: { id: string } }) => r.liveClass.id)).not.toContain(privateClass.body.id);
    expect((await outsider.post(`/live/${privateClass.body.id}/register`)).status).toBe(403);

    // "Any learner" reaches every learner, enrolled or not, and they can take a seat.
    const openClass = await instructor.post('/live', input(`Any learner ${unique()}`, { visibility: 'public', capacity: 50 }));
    expect(openClass.status).toBe(201);
    const outsiderSeesOpen = await outsider.get('/live/learner');
    expect(outsiderSeesOpen.body.upcoming.map((r: { liveClass: { id: string } }) => r.liveClass.id)).toContain(openClass.body.id);
    expect((await outsider.post(`/live/${openClass.body.id}/register`)).body.registered).toBe(true);

    // Enrolled learners still see it exactly once, not twice.
    const enrolledView = await enrolledLearner.get('/live/learner');
    const openRows = enrolledView.body.upcoming.filter((r: { liveClass: { id: string } }) => r.liveClass.id === openClass.body.id);
    expect(openRows).toHaveLength(1);
  });

  it('lets a learner open a class they may see, without the attendee list', async () => {
    const enrolled = await newStudent('Opens Detail');
    await enrolled.post(`/learning/courses/${courseId}/enroll`);
    const outsider = await newStudent('Outsider Detail');

    const privateClass = await instructor.post('/live', input(`Detail enrolled ${unique()}`, { visibility: 'enrolled' }));
    const openClass = await instructor.post('/live', input(`Detail any ${unique()}`, { visibility: 'public', capacity: 50 }));

    // The enrolled learner opens their class: the teaching fields they render, and no attendee list.
    const mine = await enrolled.get(`/live/${privateClass.body.id}`);
    expect(mine.status).toBe(200);
    expect(mine.body.courseTitle).toBeTruthy();
    expect(mine.body.instructorName).toBeTruthy();
    expect(typeof mine.body.attendeeTotal).toBe('number');
    expect(mine.body.attendees).toEqual([]);

    // A learner with no enrolment: the "Any learner" class opens, the enrolment-only one does not.
    expect((await outsider.get(`/live/${openClass.body.id}`)).status).toBe(200);
    expect((await outsider.get(`/live/${privateClass.body.id}`)).status).toBe(403);

    // Staff keep the full teaching view.
    const staff = await instructor.get(`/live/${privateClass.body.id}`);
    expect(staff.status).toBe(200);
    expect(Array.isArray(staff.body.attendees)).toBe(true);
  });

  it('reports whether the learner holds a place, on upcoming and on a class already under way', async () => {
    const learner = await newStudent('Takes a Place');
    await learner.post(`/learning/courses/${courseId}/enroll`);
    const created = await instructor.post('/live', input(`Place ${unique()}`, { capacity: 10 }));

    const before = (await learner.get('/live/learner')).body.upcoming.find((r: { liveClass: { id: string } }) => r.liveClass.id === created.body.id);
    expect(before.registered).toBe(false);

    await learner.post(`/live/${created.body.id}/register`);
    const after = (await learner.get('/live/learner')).body.upcoming.find((r: { liveClass: { id: string } }) => r.liveClass.id === created.body.id);
    expect(after.registered).toBe(true);

    // The instructor sees the place that was taken.
    const detail = await instructor.get(`/live/${created.body.id}`);
    expect(detail.body.attendeeTotal).toBe(1);
    expect(detail.body.attendees.map((a: { name: string }) => a.name)).toContain('Takes a Place');

    // Once it is under way the row still says whether the place is held, so the room can be gated on it.
    await db.liveClass.update({ where: { id: created.body.id }, data: { startsAt: new Date(Date.now() - 5 * 60_000), startedAt: new Date() } });
    const live = (await learner.get('/live/learner')).body.live.find((r: { liveClass: { id: string } }) => r.liveClass.id === created.body.id);
    expect(live).toBeDefined();
    expect(live.registered).toBe(true);
  });

  it('sends scheduled reminders once when their moment comes', async () => {
    const learner = await newStudent('Reminded');
    await learner.post(`/learning/courses/${courseId}/enroll`);
    const created = await admin.post('/live', input(`Reminder ${unique()}`, { startsAt: inHours(0.5), reminders: [60, 15] }));
    await learner.post(`/live/${created.body.id}/register`);
    const before = (await learner.get('/notifications', { limit: 50 })).body.total as number;

    // 30 minutes before the start: the 60-minute reminder is due, the 15-minute one is not. It says how long is
    // actually left — not "1 hour", which stopped being true when the class was scheduled at short notice.
    expect(await inAcademy(() => sendDueReminders(new Date()))).toBeGreaterThanOrEqual(1);
    const afterFirst = await learner.get('/notifications', { limit: 50 });
    expect(afterFirst.body.total).toBe(before + 1);
    expect(afterFirst.body.rows[0].title).toMatch(/starts in 30 min/);
    // running again does not repeat it
    await inAcademy(() => sendDueReminders(new Date()));
    expect((await learner.get('/notifications', { limit: 50 })).body.total).toBe(before + 1);
    // 10 minutes before the start the 15-minute reminder goes out
    await inAcademy(() => sendDueReminders(new Date(Date.now() + 20 * 60_000)));
    const afterSecond = await learner.get('/notifications', { limit: 50 });
    expect(afterSecond.body.total).toBe(before + 2);
    expect(afterSecond.body.rows[0].action.label).toBe('Join the class');
  });
});
