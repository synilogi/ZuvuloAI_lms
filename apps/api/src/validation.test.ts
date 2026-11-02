import { beforeAll, describe, expect, it } from 'vitest';

import { as, type Client } from './test/helpers.js';

/* Query strings reach the server from anywhere, not only from the app's own screens. A value the
 * server does not understand must be refused with a 400 — never answered with a 500, and never
 * quietly honoured. These tests cover the two ways that went wrong: an unknown value used as a key,
 * and a page size with no ceiling. */

let admin: Client;
let instructor: Client;

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
});

describe('query validation: values the server does not understand', () => {
  it('refuses an unknown period or segment instead of failing on it', async () => {
    // `range` indexes the table of period lengths; an unknown key produced an invalid window and a 500.
    expect((await admin.get('/reports/overview', { range: 'bogus' })).status).toBe(400);
    expect((await admin.get('/reports/courses', { range: '../../etc' })).status).toBe(400);
    expect((await admin.get('/reports/learners', { segment: 'nonsense' })).status).toBe(400);
    expect((await admin.get('/reports/learners', { sortKey: 'nonsense' })).status).toBe(400);
    expect((await admin.get('/reports/learners', { sortDirection: 'sideways' })).status).toBe(400);
    expect((await admin.get('/dashboard', { scope: 'bogus' })).status).toBe(400);

    const refused = await admin.get('/reports/overview', { range: 'bogus' });
    expect(refused.body.issues?.[0]?.path).toBe('range');

    // Every period the app offers still works.
    for (const range of ['30d', '90d', '6m', '12m']) {
      expect((await admin.get('/reports/overview', { range })).status).toBe(200);
    }
    for (const segment of ['all', 'new', 'active', 'at-risk', 'inactive', 'completers']) {
      expect((await admin.get('/reports/learners', { segment })).status).toBe(200);
    }
  });

  it('caps how much of a list one request may take', async () => {
    for (const path of ['/students', '/courses', '/live', '/certificates', '/assignments/submissions', '/reports/learners']) {
      expect((await admin.get(path, { pageSize: 100_000 })).status, path).toBe(400);
      expect((await admin.get(path, { pageSize: 500 })).status, path).toBe(200);
    }
    // A page number that is not a number is a bad request, not an empty list.
    expect((await admin.get('/students', { page: 'abc' })).status).toBe(400);
    expect((await admin.get('/students', { page: 0 })).status).toBe(400);
    expect((await admin.get('/students', { page: -5 })).status).toBe(400);
    expect((await admin.get('/students', { pageSize: 0 })).status).toBe(400);
  });

  it('bounds free text and the activity limit', async () => {
    expect((await admin.get('/students', { search: 'x'.repeat(5000) })).status).toBe(400);
    expect((await admin.get('/students', { search: 'Ananya' })).status).toBe(200);

    const studentId = (await admin.get('/students', { pageSize: 1 })).body.rows[0].student.id;
    expect((await admin.get(`/students/${studentId}/activity`, { limit: 999_999 })).status).toBe(400);
    expect((await admin.get(`/students/${studentId}/activity`, { limit: 50 })).status).toBe(200);
  });

  it('keeps refusing bad input for an instructor, and still scopes them', async () => {
    expect((await instructor.get('/reports/overview', { range: 'bogus' })).status).toBe(400);
    expect((await instructor.get('/courses', { pageSize: 100_000 })).status).toBe(400);
    expect((await instructor.get('/dashboard')).status).toBe(200);
  });
});
