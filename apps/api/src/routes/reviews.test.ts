import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';

import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { db, platformDb, T } from '../test/db.js';
import { ACCOUNTS, PASSWORD, app, as, newStudent, type Client } from '../test/helpers.js';

/* Course reviews (docs/16, D-PLAT-11): who may write one, what the public reads, who may read and moderate the rest, and
 * that the course's rating follows the published reviews. */

let admin: Client;
let owner: Client;
let meenakshi: Client;
let vinod: Client;
let vinodId: string;
let meenakshiId: string;
let levelId: string;
let categoryId: string;
let seq = 0;

/** A published free course of its own, so one test's reviews never reach another's figures. */
async function newCourse(instructorId: string, data: { rating?: number; ratingCount?: number; status?: string; visibility?: string } = {}) {
  seq += 1;
  const slug = `review-course-${Date.now()}-${seq}`;
  const course = await db.course.create({
    data: {
      ...T,
      slug,
      title: `Review Course ${seq}`,
      levelId,
      categoryId,
      format: 'self-paced',
      coverMotif: 'orbits',
      pricing: 'free',
      status: 'published',
      visibility: 'public',
      ...data,
      instructors: { create: { ...T, instructorId } },
    },
  });
  return course;
}

const enrol = (studentId: string, courseId: string, data: { status?: string; expiresAt?: Date } = {}) =>
  db.enrollment.create({ data: { ...T, studentId, courseId, ...data } });

/** A learner enrolled in the course, with their review written. */
async function reviewer(courseId: string, rating: number, comment = '', name = 'Asha Rao') {
  const learner = await newStudent(name);
  await enrol(learner.studentId, courseId);
  const res = await learner.put(`/learning/courses/${courseId}/review`, { rating, comment });
  expect(res.status, JSON.stringify(res.body)).toBe(200);
  return { learner, review: res.body as { id: string; status: string } };
}

const figures = (courseId: string) => db.course.findUniqueOrThrow({ where: { id: courseId }, select: { rating: true, ratingCount: true, updatedAt: true } });

const publicReviews = (slug: string, query: Record<string, unknown> = {}) => request(app).get(`/catalog/courses/${slug}/reviews`).query(query);

beforeAll(async () => {
  admin = await as('admin');
  meenakshi = await as('instructor');
  vinod = await as('instructor2');
  const email = `review-owner-${Date.now()}@example.com`;
  await provisionSuperAdmin({ email, password: 'review-owner-secret-1', name: 'Owner' });
  owner = await as({ email, password: 'review-owner-secret-1' });
  meenakshiId = (await db.instructor.findFirstOrThrow({ where: { email: ACCOUNTS.instructor } })).id;
  vinodId = (await db.instructor.findFirstOrThrow({ where: { email: ACCOUNTS.instructor2 } })).id;
  levelId = (await db.level.findFirstOrThrow()).id;
  categoryId = (await db.category.findFirstOrThrow()).id;
});

describe('writing a review', () => {
  it('lets an enrolled learner create, read and edit one, audited, with one row per learner and course', async () => {
    const course = await newCourse(meenakshiId);
    const learner = await newStudent('Maya Sen');
    await enrol(learner.studentId, course.id);
    const path = `/learning/courses/${course.id}/review`;

    expect((await learner.get(path)).body).toEqual({ eligible: true, review: null });

    const created = await learner.put(path, { rating: 4, comment: '  Clear and thorough.  ' });
    expect(created.status, JSON.stringify(created.body)).toBe(200);
    expect(created.body).toMatchObject({ courseId: course.id, rating: 4, comment: 'Clear and thorough.', status: 'published' });

    const edited = await learner.put(path, { rating: 2 });
    expect(edited.body).toMatchObject({ id: created.body.id, rating: 2, comment: '' });
    expect(await db.courseReview.count({ where: { courseId: course.id } })).toBe(1);
    expect((await learner.get(path)).body).toMatchObject({ eligible: true, review: { id: created.body.id, rating: 2 } });

    const trail = await platformDb.auditLog.findMany({ where: { targetType: 'course_review', targetId: created.body.id }, orderBy: { createdAt: 'asc' } });
    expect(trail.map((e) => e.action).sort()).toEqual(['course.review.created', 'course.review.updated']);
    expect(JSON.parse(trail.find((e) => e.action === 'course.review.updated')!.metaJson)).toMatchObject({ rating: 2, previousRating: 4 });
  });

  it('refuses a learner who is not enrolled, whose enrolment expired or lapsed, or is paused', async () => {
    const course = await newCourse(meenakshiId);
    const path = `/learning/courses/${course.id}/review`;
    const body = { rating: 5 };

    const stranger = await newStudent('Not Enrolled');
    expect((await stranger.put(path, body)).status).toBe(403);
    expect((await stranger.get(path)).body).toEqual({ eligible: false, review: null });

    const expired = await newStudent('Expired Learner');
    await enrol(expired.studentId, course.id, { status: 'expired' });
    expect((await expired.put(path, body)).status).toBe(403);

    // Still `active` on the row with its date passed: the status alone would let this through.
    const lapsed = await newStudent('Lapsed Learner');
    await enrol(lapsed.studentId, course.id, { status: 'active', expiresAt: new Date(Date.now() - 60_000) });
    expect((await lapsed.put(path, body)).status).toBe(403);
    expect((await db.enrollment.findFirstOrThrow({ where: { studentId: lapsed.studentId, courseId: course.id } })).status).toBe('expired');

    const paused = await newStudent('Paused Learner');
    await enrol(paused.studentId, course.id, { status: 'paused' });
    expect((await paused.put(path, body)).status).toBe(403);

    expect(await db.courseReview.count({ where: { courseId: course.id } })).toBe(0);
  });

  it('accepts a completed enrolment', async () => {
    const course = await newCourse(meenakshiId);
    const learner = await newStudent('Finished Learner');
    await enrol(learner.studentId, course.id, { status: 'completed' });
    expect((await learner.put(`/learning/courses/${course.id}/review`, { rating: 5 })).status).toBe(200);
  });

  it('refuses a suspended learner, staff and a visitor, and a rating or comment out of bounds', async () => {
    const course = await newCourse(meenakshiId);
    const path = `/learning/courses/${course.id}/review`;
    expect((await request(app).put(path).send({ rating: 5 })).status).toBe(401);
    expect((await request(app).get(path)).status).toBe(401);
    expect((await admin.put(path, { rating: 5 })).status).toBe(403);
    expect((await meenakshi.put(path, { rating: 5 })).status).toBe(403);

    const learner = await newStudent('Bounds Learner');
    await enrol(learner.studentId, course.id);
    for (const rating of [0, 6, 3.5, '5', undefined]) expect((await learner.put(path, { rating })).status, String(rating)).toBe(400);
    expect((await learner.put(path, { rating: 5, comment: 'x'.repeat(2001) })).status).toBe(400);
    expect((await learner.put(path, { rating: 5, comment: 'x'.repeat(2000) })).status).toBe(200);

    await db.student.update({ where: { id: learner.studentId }, data: { suspended: true } });
    expect((await learner.put(path, { rating: 1 })).status).toBe(403);
    await db.student.update({ where: { id: learner.studentId }, data: { suspended: false } });

    expect((await learner.put('/learning/courses/no-such-course/review', { rating: 5 })).status).toBe(404);
  });

  it('is held to its bounds by the database too', async () => {
    const course = await newCourse(meenakshiId);
    const learner = await newStudent('Direct Writer');
    await expect(db.courseReview.create({ data: { ...T, studentId: learner.studentId, courseId: course.id, rating: 6 } })).rejects.toThrow();
    await expect(db.courseReview.create({ data: { ...T, studentId: learner.studentId, courseId: course.id, rating: 5, status: 'other' } })).rejects.toThrow();
  });
});

describe('the course’s rating', () => {
  it('leaves a seeded value alone until the first review, then replaces it with the published reviews’ figures', async () => {
    const course = await newCourse(meenakshiId, { rating: 4.9, ratingCount: 200 });
    const other = await newCourse(meenakshiId, { rating: 4.2, ratingCount: 80 });

    await reviewer(course.id, 5);
    expect(await figures(course.id)).toMatchObject({ rating: 5, ratingCount: 1 });
    // Nothing else moves: a course with no review keeps what it had.
    expect(await figures(other.id)).toMatchObject({ rating: 4.2, ratingCount: 80 });

    const { learner } = await reviewer(course.id, 2);
    expect(await figures(course.id)).toMatchObject({ rating: 3.5, ratingCount: 2 });
    await learner.put(`/learning/courses/${course.id}/review`, { rating: 4 });
    expect(await figures(course.id)).toMatchObject({ rating: 4.5, ratingCount: 2 });
  });

  it('rounds to one decimal', async () => {
    const course = await newCourse(meenakshiId);
    for (const rating of [5, 5, 4]) await reviewer(course.id, rating);
    expect(await figures(course.id)).toMatchObject({ rating: 4.7, ratingCount: 3 });
  });

  it('follows hide and show, has no rating once every review is hidden, and does not come back to the seeded value', async () => {
    const course = await newCourse(meenakshiId, { rating: 4.9, ratingCount: 200 });
    const one = await reviewer(course.id, 5);
    const two = await reviewer(course.id, 1);
    expect(await figures(course.id)).toMatchObject({ rating: 3, ratingCount: 2 });

    expect((await admin.post(`/reports/reviews/${two.review.id}/hide`)).body.status).toBe('hidden');
    expect(await figures(course.id)).toMatchObject({ rating: 5, ratingCount: 1 });

    await admin.post(`/reports/reviews/${one.review.id}/hide`);
    expect(await figures(course.id)).toMatchObject({ rating: null, ratingCount: null });

    await admin.post(`/reports/reviews/${two.review.id}/show`);
    expect(await figures(course.id)).toMatchObject({ rating: 1, ratingCount: 1 });
  });

  it('does not count as an edit of the course', async () => {
    const course = await newCourse(meenakshiId);
    const before = (await figures(course.id)).updatedAt;
    await reviewer(course.id, 3);
    expect((await figures(course.id)).updatedAt).toEqual(before);
  });

  it('keeps the catalogue’s showRatings and minRatings rules', async () => {
    const settings = (await admin.get('/settings')).body.settings ?? (await admin.get('/settings')).body;
    const course = await newCourse(meenakshiId);
    await reviewer(course.id, 5);
    await reviewer(course.id, 4);
    const rating = async () => (await request(app).get(`/catalog/courses/${course.slug}`)).body.rating;
    try {
      await admin.put('/settings/courses', { ...settings.courses, showRatings: true, minRatings: 3 });
      expect(await rating()).toBeUndefined();
      await admin.put('/settings/courses', { ...settings.courses, showRatings: true, minRatings: 2 });
      expect(await rating()).toBe(4.5);

      // Off is off: the reviews each carry a rating, so they go too.
      await admin.put('/settings/courses', { ...settings.courses, showRatings: false });
      expect(await rating()).toBeUndefined();
      expect((await publicReviews(course.slug)).body).toMatchObject({ rows: [], total: 0 });
    } finally {
      await admin.put('/settings/courses', settings.courses);
    }
  });
});

describe('what the public reads', () => {
  it('shows first name, rating and comment only, newest first, a page at a time, and the comment exactly as written', async () => {
    const course = await newCourse(meenakshiId);
    const script = '<script>alert(1)</script> & <b>bold</b>';
    const { learner } = await reviewer(course.id, 5, script, 'Priyanka Devi Sharma');
    await reviewer(course.id, 3, 'Fine.', 'Ravi Kumar');

    const res = await publicReviews(course.slug, { pageSize: 1 });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ rows: [{ firstName: 'Ravi', rating: 3, comment: 'Fine.' }], total: 2, page: 1, pageSize: 1 });

    const second = await publicReviews(course.slug, { pageSize: 1, page: 2 });
    expect(second.body.rows).toEqual([{ firstName: 'Priyanka', rating: 5, comment: script }]);
    expect(Object.keys(second.body.rows[0]).sort()).toEqual(['comment', 'firstName', 'rating']);
    expect(JSON.stringify(res.body)).not.toContain(learner.email);

    expect((await publicReviews(course.slug, { pageSize: 51 })).status).toBe(400);
  });

  it('keeps a hidden review out, and an edit by its author does not bring it back', async () => {
    const course = await newCourse(meenakshiId);
    const shown = await reviewer(course.id, 4, 'Visible');
    const hidden = await reviewer(course.id, 1, 'Abusive');
    await admin.post(`/reports/reviews/${hidden.review.id}/hide`);

    let body = (await publicReviews(course.slug)).body;
    expect(body.total).toBe(1);
    expect(body.rows.map((r: { comment: string }) => r.comment)).toEqual(['Visible']);

    const edit = await hidden.learner.put(`/learning/courses/${course.id}/review`, { rating: 5, comment: 'Edited' });
    expect(edit.body).toMatchObject({ status: 'hidden', comment: 'Edited' });
    body = (await publicReviews(course.slug)).body;
    expect(body.rows.map((r: { comment: string }) => r.comment)).toEqual(['Visible']);
    expect(await figures(course.id)).toMatchObject({ rating: 4, ratingCount: 1 });

    // Its author can still see it, and its state.
    expect((await hidden.learner.get(`/learning/courses/${course.id}/review`)).body.review).toMatchObject({ status: 'hidden' });
    expect(shown.review.status).toBe('published');
  });

  it('answers 404 for a course that is not listed', async () => {
    for (const data of [{ status: 'draft' }, { visibility: 'private' }]) {
      const course = await newCourse(meenakshiId, data);
      expect((await publicReviews(course.slug)).status, JSON.stringify(data)).toBe(404);
    }
    expect((await publicReviews('no-such-course')).status).toBe(404);
  });

  it('forgets a deleted account’s reviews and recomputes the rating', async () => {
    const course = await newCourse(meenakshiId);
    await reviewer(course.id, 5, 'Stays');
    const { learner } = await reviewer(course.id, 1, 'Goes', 'Leaving Person');
    expect(await figures(course.id)).toMatchObject({ rating: 3, ratingCount: 2 });

    const gone = await request(app).post('/auth/delete-account').set('Authorization', `Bearer ${learner.token}`).send({ password: PASSWORD });
    expect(gone.status, JSON.stringify(gone.body)).toBe(200);
    expect(await figures(course.id)).toMatchObject({ rating: 5, ratingCount: 1 });
    expect((await publicReviews(course.slug)).body.rows.map((r: { comment: string }) => r.comment)).toEqual(['Stays']);
  });
});

describe('staff reviews', () => {
  it('confines an instructor to their own courses, and an admin and the owner see all of them, hidden included', async () => {
    const mine = await newCourse(meenakshiId);
    const theirs = await newCourse(vinodId);
    const a = await reviewer(mine.id, 4, 'For Meenakshi');
    const b = await reviewer(theirs.id, 2, 'For Vinod');
    await admin.post(`/reports/reviews/${a.review.id}/hide`);

    const seen = await meenakshi.get('/reports/reviews', { pageSize: 500 });
    expect(seen.status).toBe(200);
    const ids = seen.body.rows.map((r: { id: string }) => r.id);
    expect(ids).toContain(a.review.id);
    expect(ids).not.toContain(b.review.id);
    expect(seen.body.courses.map((c: { id: string }) => c.id)).toContain(mine.id);
    expect(seen.body.courses.map((c: { id: string }) => c.id)).not.toContain(theirs.id);
    expect(seen.body.rows.find((r: { id: string }) => r.id === a.review.id)).toMatchObject({
      status: 'hidden',
      courseTitle: mine.title,
      learnerName: 'Asha Rao',
    });

    // Naming another's course in the query is no way round: it matches nothing.
    const asked = await meenakshi.get('/reports/reviews', { courseId: theirs.id });
    expect(asked.body).toMatchObject({ rows: [], total: 0 });
    expect((await vinod.get('/reports/reviews', { courseId: theirs.id })).body.rows.map((r: { id: string }) => r.id)).toEqual([b.review.id]);

    for (const staff of [admin, owner]) {
      const all = (await staff.get('/reports/reviews', { pageSize: 500 })).body.rows.map((r: { id: string }) => r.id);
      expect(all).toEqual(expect.arrayContaining([a.review.id, b.review.id]));
    }
    expect((await admin.get('/reports/reviews', { courseId: mine.id, status: 'published' })).body.total).toBe(0);
    expect((await admin.get('/reports/reviews', { courseId: mine.id, status: 'hidden' })).body.total).toBe(1);
  });

  it('refuses a learner and a visitor', async () => {
    const learner = await newStudent('Curious Learner');
    expect((await learner.get('/reports/reviews')).status).toBe(403);
    expect((await request(app).get('/reports/reviews')).status).toBe(401);
  });

  it('lets an admin and the owner hide and show, audited, and nobody else', async () => {
    const course = await newCourse(meenakshiId);
    const { learner, review } = await reviewer(course.id, 4);
    const hide = `/reports/reviews/${review.id}/hide`;
    const show = `/reports/reviews/${review.id}/show`;

    // The course's own instructor reads it but does not moderate it.
    for (const refused of [meenakshi, vinod, learner]) {
      expect((await refused.post(hide)).status).toBe(403);
      expect((await refused.post(show)).status).toBe(403);
    }
    expect((await request(app).post(hide)).status).toBe(401);
    expect((await db.courseReview.findUniqueOrThrow({ where: { id: review.id } })).status).toBe('published');

    expect((await admin.post(hide)).body.status).toBe('hidden');
    // Hiding what is already hidden changes nothing and records nothing.
    expect((await admin.post(hide)).body.status).toBe('hidden');
    expect((await owner.post(show)).body.status).toBe('published');

    const trail = await platformDb.auditLog.findMany({
      where: { targetType: 'course_review', targetId: review.id, action: { in: ['course.review.hidden', 'course.review.shown'] } },
    });
    expect(trail.map((e) => `${e.action} ${e.actorRole}`).sort()).toEqual(['course.review.hidden admin', 'course.review.shown superadmin']);

    expect((await admin.post('/reports/reviews/no-such-review/hide')).status).toBe(404);
  });

  it('needs the catalog.publish key on a staff admin', async () => {
    const course = await newCourse(meenakshiId);
    const { review } = await reviewer(course.id, 4);
    const user = await db.user.findUniqueOrThrow({ where: { email: ACCOUNTS.admin } });
    const held = await db.adminPermission.findFirstOrThrow({ where: { userId: user.id, key: 'catalog.publish' } });
    await db.adminPermission.delete({ where: { id: held.id } });
    try {
      expect((await admin.post(`/reports/reviews/${review.id}/hide`)).status).toBe(403);
    } finally {
      await db.adminPermission.create({ data: { ...T, userId: user.id, key: 'catalog.publish' } });
    }
  });
});
