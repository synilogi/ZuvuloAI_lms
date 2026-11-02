import { describe, expect, it } from 'vitest';

import { as, newStudent } from '../test/helpers.js';

/* An instructor's learner list names only the courses that instructor teaches (2026-10-28): a learner they share with
 * another instructor keeps that other course, its progress and its status to themselves — as on the learner's page. */

type Course = { id: string; pricing: string; visibility: string };

describe('the instructor’s learner list', () => {
  it('lists a shared learner with the instructor’s own courses only', async () => {
    const instructor = await as('instructor');
    const admin = await as('admin');
    const mine = new Set(((await instructor.get('/courses', { pageSize: 200 })).body.rows as Course[]).map((c) => c.id));
    const free = ((await admin.get('/courses', { status: 'published', pageSize: 200 })).body.rows as Course[]).filter(
      (c) => c.pricing === 'free' && c.visibility === 'public',
    );
    const theirs = free.find((c) => mine.has(c.id));
    const other = free.find((c) => !mine.has(c.id));
    expect(theirs && other, 'the seed has a free course of this instructor and one of another').toBeTruthy();

    const learner = await newStudent('Shared Learner');
    for (const c of [theirs!, other!]) expect((await learner.post(`/learning/courses/${c.id}/enroll`)).status).toBe(200);

    const rows = (await instructor.get('/students', { search: learner.email, pageSize: 50 })).body.rows as { courses: { id: string }[] }[];
    expect(rows).toHaveLength(1);
    expect(rows[0].courses.map((c) => c.id)).toEqual([theirs!.id]);
    const adminRow = (await admin.get('/students', { search: learner.email, pageSize: 50 })).body.rows[0] as { courses: { id: string }[] };
    expect(adminRow.courses.map((c) => c.id).sort()).toEqual([theirs!.id, other!.id].sort());
  });
});
