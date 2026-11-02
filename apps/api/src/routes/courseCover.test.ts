import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { forTenant } from '../lib/db.js';
import { T, db, platformDb } from '../test/db.js';
import { anon, as, newStudent, unique, type Client } from '../test/helpers.js';

/* A course's cover image: uploaded through `/media/upload`, kept on the course by id, returned by every course
 * payload, and streamed from `/catalog/covers/:id` to whoever may see the course — never across academies. */

/** A 1×1 PNG. */
const PNG = Buffer.from(
  '89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d4944415478da63f8cfc0f01f0005000201a5a1d1f90000000049454e44ae426082',
  'hex',
);
const PDF = Buffer.from('%PDF-1.7\n%âãÏÓ\n', 'latin1');

let admin: Client;
let instructor: Client;
let outsideInstructor: Client;
let levelId: string;
let categoryId: string;
/** Every course this file makes, archived at the end so later suites that pick "a published course" never get one. */
const created: string[] = [];

const uploadImage = async (client: Client, name = `cover-${unique()}.png`) => {
  const res = await client.upload('/media/upload').attach('file', PNG, { filename: name, contentType: 'image/png' });
  expect(res.status).toBe(201);
  return res.body.id as string;
};

const createCourse = async (client: Client, extra: Record<string, unknown> = {}) => {
  const res = await client.post('/courses', { title: `Cover course ${unique()}`, levelId, categoryId, ...extra });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  created.push(res.body.id);
  return res.body as { id: string; slug: string; coverImageId?: string; coverImageUrl?: string };
};

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  outsideInstructor = await as('instructor2');
  const course = await db.course.findFirstOrThrow({ where: { status: 'published' } });
  levelId = course.levelId;
  categoryId = course.categoryId;
});

afterAll(async () => {
  await db.course.updateMany({ where: { id: { in: created } }, data: { status: 'archived' } });
});

describe('saving a cover image', () => {
  it('creates a course with an uploaded image and returns where it streams from', async () => {
    const imageId = await uploadImage(admin);
    const course = await createCourse(admin, { coverImageId: imageId });
    expect(course.coverImageId).toBe(imageId);
    expect(course.coverImageUrl).toBe(`/catalog/covers/${imageId}`);
    const stored = await db.course.findUniqueOrThrow({ where: { id: course.id } });
    expect(stored.coverImageId).toBe(imageId);
    // The editor and the course list read it back.
    expect((await admin.get(`/courses/${course.id}`)).body.coverImageUrl).toBe(`/catalog/covers/${imageId}`);
    const list = await admin.get('/courses', { pageSize: 100, sort: 'created' });
    expect(list.body.rows.find((c: { id: string }) => c.id === course.id)?.coverImageUrl).toBe(`/catalog/covers/${imageId}`);
  });

  it('lets an instructor set the cover of a course they teach, and not of one they do not', async () => {
    const own = await createCourse(instructor);
    const imageId = await uploadImage(instructor);
    const res = await instructor.patch(`/courses/${own.id}`, { coverImageId: imageId });
    expect(res.status).toBe(200);
    expect(res.body.coverImageUrl).toBe(`/catalog/covers/${imageId}`);

    const other = await outsideInstructor.patch(`/courses/${own.id}`, { coverImageId: await uploadImage(outsideInstructor) });
    expect([403, 404]).toContain(other.status);
    expect((await db.course.findUniqueOrThrow({ where: { id: own.id } })).coverImageId).toBe(imageId);
  });

  it('replaces the image with a new address, and removes it with null', async () => {
    const first = await uploadImage(admin);
    const course = await createCourse(admin, { coverImageId: first });
    const second = await uploadImage(admin);
    const replaced = await admin.patch(`/courses/${course.id}`, { coverImageId: second });
    expect(replaced.body.coverImageUrl).toBe(`/catalog/covers/${second}`);
    // The old file is no longer any course's cover, so it is no longer served as one.
    expect((await admin.get(`/catalog/covers/${first}`)).status).toBe(404);
    expect((await admin.get(`/catalog/covers/${second}`)).status).toBe(200);

    // A change that does not mention the cover leaves it alone.
    const untouched = await admin.patch(`/courses/${course.id}`, { subtitle: 'Still covered' });
    expect(untouched.body.coverImageId).toBe(second);

    const removed = await admin.patch(`/courses/${course.id}`, { coverImageId: null });
    expect(removed.status).toBe(200);
    expect(removed.body.coverImageId).toBeUndefined();
    expect(removed.body.coverImageUrl).toBeUndefined();
    expect(removed.body.coverMotif).toBeTruthy();
    expect((await admin.get(`/catalog/covers/${second}`)).status).toBe(404);
  });

  it('refuses a file that is not an image, a learner’s upload, and an id that does not exist', async () => {
    const course = await createCourse(admin);
    const pdf = await admin.upload('/media/upload').attach('file', PDF, { filename: 'notes.pdf', contentType: 'application/pdf' });
    expect((await admin.patch(`/courses/${course.id}`, { coverImageId: pdf.body.id })).status).toBe(400);

    const learner = await newStudent('Cover Learner');
    const handIn = await uploadImage(learner);
    expect((await admin.patch(`/courses/${course.id}`, { coverImageId: handIn })).status).toBe(400);

    expect((await admin.patch(`/courses/${course.id}`, { coverImageId: 'no-such-media' })).status).toBe(400);
    expect((await admin.post('/courses', { title: `Bad cover ${unique()}`, levelId, categoryId, coverImageId: 'no-such-media' })).status).toBe(400);
    expect((await db.course.findUniqueOrThrow({ where: { id: course.id } })).coverImageId).toBeNull();
  });

  it('refuses an image uploaded to another academy', async () => {
    const other = `cover-other-${unique()}`;
    await platformDb.tenant.create({ data: { id: other, name: 'Other Cover Academy', slug: other } });
    const owner = await platformDb.user.create({
      data: { tenantId: other, name: 'Other Admin', email: `${other}@example.com`, passwordHash: 'x', role: 'admin' },
    });
    const asset = await forTenant(other).mediaAsset.create({
      data: {
        tenantId: other,
        ownerUserId: owner.id,
        kind: 'image',
        originalName: 'theirs.png',
        mime: 'image/png',
        sizeBytes: PNG.length,
        storageName: `${unique()}.png`,
      },
    });
    const course = await createCourse(admin);
    expect((await admin.patch(`/courses/${course.id}`, { coverImageId: asset.id })).status).toBe(400);
    expect((await db.course.findUniqueOrThrow({ where: { id: course.id } })).coverImageId).toBeNull();
  });
});

describe('reading a cover image', () => {
  it('shows a draft’s cover to staff only, and a published course’s to everyone', async () => {
    const imageId = await uploadImage(admin);
    const course = await createCourse(admin, { coverImageId: imageId });
    const outsider = await newStudent('Cover Outsider');

    const staffView = await admin.get(`/catalog/covers/${imageId}`);
    expect(staffView.status).toBe(200);
    expect(staffView.headers['content-type']).toBe('image/png');
    expect(staffView.headers['x-content-type-options']).toBe('nosniff');
    expect(staffView.headers['cache-control']).toMatch(/private/);
    expect(Buffer.compare(staffView.body as Buffer, PNG)).toBe(0);
    expect((await instructor.get(`/catalog/covers/${imageId}`)).status).toBe(200);
    expect((await outsider.get(`/catalog/covers/${imageId}`)).status).toBe(404);
    expect((await anon().get(`/catalog/covers/${imageId}`)).status).toBe(404);

    await db.course.update({ where: { id: course.id }, data: { status: 'published', publishedAt: new Date(), visibility: 'public' } });
    const open = await anon().get(`/catalog/covers/${imageId}`);
    expect(open.status).toBe(200);
    expect(open.headers['cache-control']).toMatch(/public/);
    expect((await outsider.get(`/catalog/covers/${imageId}`)).status).toBe(200);

    // The catalog, the course page and the learner's own views all carry it.
    const listing = await anon().get('/catalog/courses');
    expect(listing.body.find((c: { id: string }) => c.id === course.id)?.coverImageUrl).toBe(`/catalog/covers/${imageId}`);
    expect((await anon().get(`/catalog/courses/${course.slug}`)).body.coverImageUrl).toBe(`/catalog/covers/${imageId}`);
    const detail = await outsider.get(`/learning/courses/${course.id}`);
    expect(detail.status).toBe(200);
    expect(JSON.stringify(detail.body)).toContain(`/catalog/covers/${imageId}`);
  });

  it('shows a private course’s cover to its enrolled learners and staff, and to nobody else', async () => {
    const imageId = await uploadImage(admin);
    const course = await createCourse(admin, { coverImageId: imageId });
    await db.course.update({ where: { id: course.id }, data: { status: 'published', publishedAt: new Date(), visibility: 'private' } });
    const enrolled = await newStudent('Private Cover Learner');
    await db.enrollment.create({ data: { ...T, courseId: course.id, studentId: enrolled.studentId, status: 'active' } });
    const outsider = await newStudent('Private Cover Outsider');

    expect((await enrolled.get(`/catalog/covers/${imageId}`)).status).toBe(200);
    expect((await admin.get(`/catalog/covers/${imageId}`)).status).toBe(200);
    expect((await outsider.get(`/catalog/covers/${imageId}`)).status).toBe(404);
    expect((await anon().get(`/catalog/covers/${imageId}`)).status).toBe(404);
  });

  it('serves no upload that is not a course cover', async () => {
    const loose = await uploadImage(admin);
    expect((await admin.get(`/catalog/covers/${loose}`)).status).toBe(404);
    expect((await anon().get(`/catalog/covers/${loose}`)).status).toBe(404);
    expect((await anon().get('/catalog/covers/no-such-media')).status).toBe(404);
  });

  it('never serves another academy’s cover, even for a published course', async () => {
    const other = `cover-read-${unique()}`;
    await platformDb.tenant.create({ data: { id: other, name: 'Other Read Academy', slug: other } });
    const owner = await platformDb.user.create({
      data: { tenantId: other, name: 'Other Admin', email: `${other}@example.com`, passwordHash: 'x', role: 'admin' },
    });
    const scoped = forTenant(other);
    const asset = await scoped.mediaAsset.create({
      data: {
        tenantId: other,
        ownerUserId: owner.id,
        kind: 'image',
        originalName: 'theirs.png',
        mime: 'image/png',
        sizeBytes: PNG.length,
        storageName: `${unique()}.png`,
      },
    });
    const level = await scoped.level.create({ data: { tenantId: other, name: 'Foundation', order: 1 } });
    const category = await scoped.category.create({ data: { tenantId: other, name: 'Charts', description: '', order: 1, glyph: 'chart', status: 'active' } });
    await scoped.course.create({
      data: {
        tenantId: other,
        slug: `theirs-${unique()}`,
        title: 'Their course',
        levelId: level.id,
        categoryId: category.id,
        format: 'self-paced',
        coverMotif: 'orbits',
        status: 'published',
        visibility: 'public',
        coverImageId: asset.id,
      },
    });
    // The default academy's visitors, and every signed-in role here, look in their own academy and find nothing.
    for (const client of [admin, instructor, await newStudent('Cross Cover Reader'), anon()])
      expect((await client.get(`/catalog/covers/${asset.id}`)).status).toBe(404);
  });

  it('keeps courses without an image working, with no cover fields', async () => {
    const plain = await createCourse(admin);
    expect(plain.coverImageId).toBeUndefined();
    expect(plain.coverImageUrl).toBeUndefined();
    const listing = await anon().get('/catalog/courses');
    expect(listing.status).toBe(200);
    for (const c of listing.body as { coverImageUrl?: string }[]) if (c.coverImageUrl) expect(c.coverImageUrl).toMatch(/^\/catalog\/covers\//);
  });
});
