import { beforeAll, describe, expect, it } from 'vitest';
import { inAcademy } from '../test/db.js';

import { sendDueCalendarReminders } from '../lib/calendarEvents.js';
import { as, newStudent, unique, type Client } from '../test/helpers.js';

let admin: Client;
let instructor: Client;
let courseId: string;

const day = (offset: number) => new Date(Date.now() + offset * 86_400_000).toISOString().slice(0, 10);

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  courseId = (await instructor.get('/courses', { status: 'published', pageSize: 5 })).body.rows[0].id;
});

describe('calendar: derived rows carry real figures', () => {
  it('shows learners due and hand-ins for deadlines, and the phase and host for live classes', async () => {
    const dueAt = new Date(Date.now() + 3 * 86_400_000).toISOString();
    const assignment = await admin.post('/assignments', {
      courseId,
      title: `Deadline ${unique()}`,
      instructions: 'Hand in a one-page solution to the sample problem with the equation, its solution and the check covered.',
      attachments: [],
      format: 'text',
      due: { kind: 'date', dueAt },
      rubric: [],
      maxScore: 20,
      passMark: 12,
      status: 'published',
    });
    expect(assignment.status).toBe(201);
    const learner = await newStudent('Due Learner');
    await learner.post(`/learning/courses/${courseId}/enroll`);
    await learner.post(`/learning/assignments/${assignment.body.id}/submit`, { text: 'Handed in early with the full reading.', files: [] });

    const list = await instructor.get('/calendar', { from: day(-1), to: day(7) });
    expect(list.status).toBe(200);
    const row = list.body.rows.find((r: { event: { id: string } }) => r.event.id === `assignment-${assignment.body.id}`);
    expect(row).toBeDefined();
    expect(row.due.learners).toBeGreaterThan(0);
    expect(row.due.submitted).toBeGreaterThanOrEqual(1);
    expect(row.due.learners).toBeGreaterThanOrEqual(row.due.submitted);

    const detail = await instructor.get(`/calendar/assignment-${assignment.body.id}`);
    expect(detail.body.learnersDue.length).toBeGreaterThan(0);
    expect(detail.body.learnersDue.length).toBeLessThanOrEqual(8);
    expect(detail.body.learnersDue.every((l: { submitted: unknown }) => typeof l.submitted === 'boolean')).toBe(true);
    expect(detail.body.learnersDue[0].submitted).toBe(false); // owing learners first
    expect(detail.body.editable).toBe(false);

    const liveRow = list.body.rows.find((r: { event: { type: string } }) => r.event.type === 'live');
    if (liveRow) {
      expect(liveRow.phase).toBeDefined();
      const liveDetail = await instructor.get(`/calendar/${liveRow.event.id}`);
      expect(liveDetail.body.instructorTitle.length).toBeGreaterThan(0);
      expect(typeof liveDetail.body.audienceSize).toBe('number');
    }
  });
});

describe('calendar: own events and reminders', () => {
  it('validates, sizes the audience, and sends the reminder once to the owner and the course learners', async () => {
    expect((await instructor.post('/calendar', { input: { type: 'reminder', title: '', timing: 'moment', startsAt: 'nope' } })).status).toBe(400);
    const learner = await newStudent('Reminded Learner');
    await learner.post(`/learning/courses/${courseId}/enroll`);

    const startsAt = new Date(Date.now() + 45 * 60_000).toISOString();
    const created = await instructor.post('/calendar', {
      input: { type: 'reminder', title: 'Bring your geometry box', timing: 'moment', startsAt, courseId, audience: 'learners', notifyMin: 60 },
    });
    expect(created.status).toBe(201);
    const detail = await instructor.get(`/calendar/${created.body.id}`);
    expect(detail.body.audienceSize).toBeGreaterThan(0);
    expect(detail.body.editable).toBe(true);

    const before = (await learner.get('/notifications', { limit: 50 })).body.total as number;
    const sent = await inAcademy(() => sendDueCalendarReminders(new Date()));
    expect(sent).toBeGreaterThanOrEqual(1);
    const after = await learner.get('/notifications', { limit: 50 });
    expect(after.body.total).toBe(before + 1);
    expect(after.body.rows[0].title).toMatch(/Bring your geometry box/);
    const ownerNotes = await instructor.get('/notifications', { limit: 5 });
    expect(ownerNotes.body.rows[0].title).toMatch(/Bring your geometry box/);
    await inAcademy(() => sendDueCalendarReminders(new Date()));
    expect((await learner.get('/notifications', { limit: 50 })).body.total).toBe(before + 1);

    // a private reminder for another instructor's course is refused
    const myInstructorId = (await instructor.get('/auth/me')).body.user.instructorId as string;
    const foreign = (await (await as('instructor2')).get('/courses', { pageSize: 50 })).body.rows.find(
      (c: { instructorIds: string[] }) => !c.instructorIds.includes(myInstructorId),
    );
    if (foreign)
      expect(
        (await instructor.post('/calendar', { input: { type: 'reminder', title: 'Sneak', timing: 'moment', startsAt, courseId: foreign.id, audience: 'me' } }))
          .status,
      ).toBe(404);
  });
});
