import { readFileSync } from 'node:fs';
import path from 'node:path';

import bcrypt from 'bcryptjs';
import { beforeAll, describe, expect, it } from 'vitest';

import { assertDemoEnvironment, educationId as eid, istAt, seedEducationCatalog } from '../../prisma/educationCatalog.js';
import { TENANT_OWNED_MODELS } from '../lib/tenancy.js';
import { platformDb } from '../test/db.js';
import { as, unique, type Client } from '../test/helpers.js';

/* The sample education catalogue (`npm run seed:education`): seeded twice into a fresh academy it adds nothing the
 * second time, keeps every row in that academy, gives a `.test` learner a full journey through the real API — covers,
 * lectures and notes streamed from storage — and stays invisible to every other academy. */

const ASSETS = path.resolve(import.meta.dirname, '../../prisma/demo-assets/education');
const PASSWORD = 'education-test-password';

type Delegate = { count: (args: { where: { tenantId: string } }) => Promise<number> };
const delegate = (model: string) => (platformDb as unknown as Record<string, Delegate>)[model[0].toLowerCase() + model.slice(1)];
async function countsByModel(tenantId: string) {
  const counts: Record<string, number> = {};
  for (const model of [...TENANT_OWNED_MODELS, 'User', 'AppNotification']) counts[model] = await delegate(model).count({ where: { tenantId } });
  return counts;
}

const slug = `edu-test-${unique()}`.toLowerCase().slice(0, 40);
const learnerEmail = `learner-${unique()}@edu-test.test`;
let tenantId: string;
let learner: Client;
let outsider: Client;
let firstRun: Record<string, number>;
let outsideBefore: Record<string, number>;

beforeAll(async () => {
  const tenant = await platformDb.tenant.create({ data: { name: 'Education test academy', slug } });
  tenantId = tenant.id;
  const hash = await bcrypt.hash(PASSWORD, 4);
  const admin = await platformDb.user.create({
    data: { tenantId, email: `admin-${unique()}@edu-test.test`, name: 'Test Admin', role: 'admin', passwordHash: hash },
  });
  await platformDb.tenant.update({ where: { id: tenantId }, data: { ownerUserId: admin.id } });
  await platformDb.user.create({
    data: { tenantId, email: learnerEmail, name: 'Test Learner', role: 'student', passwordHash: hash, student: { create: { tenantId } } },
  });

  outsideBefore = await countsByModel('tenant-1');
  await seedEducationCatalog({ academySlug: slug, demoStudentEmail: learnerEmail });
  firstRun = await countsByModel(tenantId);
  await seedEducationCatalog({ academySlug: slug, demoStudentEmail: learnerEmail });
  learner = await as({ email: learnerEmail, password: PASSWORD });
  outsider = await as('student');
}, 60_000);

describe('guards', () => {
  it('learner activity is refused in production and for a production database', () => {
    expect(() => assertDemoEnvironment({ NODE_ENV: 'production', DATABASE_URL: 'file:./dev.db' })).toThrow(/development and staging only/);
    expect(() => assertDemoEnvironment({ DATABASE_URL: 'file:./dev.db' })).toThrow(/not set/);
    expect(() => assertDemoEnvironment({ NODE_ENV: 'development', DATABASE_URL: 'file:../data/prod.db' })).toThrow(/production database/);
    expect(() => assertDemoEnvironment({ NODE_ENV: 'staging', DATABASE_URL: 'file:./staging.db' })).not.toThrow();
  });

  it('refuses a real (non-.test) learner, a missing academy, and a second academy', async () => {
    const realLooking = `someone-${unique()}@gmail.com`;
    await expect(seedEducationCatalog({ academySlug: slug, demoStudentEmail: realLooking })).rejects.toThrow(/\.test account/);
    await expect(seedEducationCatalog({ academySlug: `missing-${unique()}`.toLowerCase() })).rejects.toThrow(/No academy/);
    // The sample ids belong to the first academy; seeding them into another is refused, not duplicated or moved.
    await expect(seedEducationCatalog({ academySlug: 'default' })).rejects.toThrow(/belong to another academy/);
  });
});

describe('seeding', () => {
  it('adds nothing on a second run and changes no account', async () => {
    expect(await countsByModel(tenantId)).toEqual(firstRun);
    expect(firstRun).toMatchObject({ Course: 13, Category: 5, Quiz: 13, CourseAssignment: 3, MediaAsset: 21, Enrollment: 4, User: 2, Student: 1 });
  });

  it('leaves every other academy as it was', async () => {
    expect(await countsByModel('tenant-1')).toEqual(outsideBefore);
  });

  it('keeps every reference inside the academy and invents no ratings or counts', async () => {
    const courses = await platformDb.course.findMany({
      where: { tenantId },
      include: { coverImage: true, level: true, category: true, instructors: { include: { instructor: true } }, chapters: { include: { lessons: true } } },
    });
    for (const c of courses) {
      const owners = new Set([c.coverImage?.tenantId, c.level.tenantId, c.category.tenantId, ...c.instructors.map((i) => i.instructor.tenantId)]);
      for (const ch of c.chapters) for (const l of ch.lessons) owners.add(l.tenantId);
      expect(owners).toEqual(new Set([tenantId]));
      expect(c.rating).toBeNull();
      expect(c.enrolledCount).toBe(await platformDb.enrollment.count({ where: { courseId: c.id } }));
    }
    expect(new Set(courses.map((c) => c.coverImageId)).size).toBe(13);
  });

  it('places live classes at Indian local times', () => {
    expect(istAt(new Date('2026-10-13T20:00:00Z'), 2, 18).toISOString()).toBe('2026-10-16T12:30:00.000Z');
  });
});

describe('the demo learner', () => {
  it('sees exactly their four enrolments, with the API’s own progress', async () => {
    const res = await learner.get('/learning/courses');
    expect(res.status).toBe(200);
    const byId = Object.fromEntries(
      (res.body.courses as { course: { id: string; coverImageUrl?: string }; enrollment: { status: string }; progress: { percent: number } }[]).map((c) => [
        c.course.id,
        c,
      ]),
    );
    expect(Object.keys(byId).sort()).toEqual(
      [eid('course', 'class-10-maths'), eid('course', 'ras-prelims'), eid('course', 'reasoning'), eid('course', 'ssc-gd')].sort(),
    );
    expect(byId[eid('course', 'reasoning')].enrollment.status).toBe('completed');
    for (const [courseId, c] of Object.entries(byId)) {
      const row = await platformDb.enrollment.findFirstOrThrow({ where: { courseId, student: { user: { email: learnerEmail } } } });
      expect(row.progress).toBe(c.progress.percent);
      expect(c.course.coverImageUrl).toBe(`/catalog/covers/${eid('media', `cover-${courseId.replace('edu-course-', '')}`)}`);
    }
  });

  it('has a course to continue, a test ready, an assignment due and a class coming up', async () => {
    const res = await learner.get('/learning/home');
    expect(res.status).toBe(200);
    const active = (res.body.courses as { course: { id: string }; enrollment: { status: string }; next?: { id: string } }[]).filter(
      (c) => c.enrollment.status === 'active',
    );
    expect(active[0].course.id).toBe(eid('course', 'ras-prelims'));
    expect(active[0].next?.id).toBe(eid('lesson', 'ras-prelims-physical-divisions'));
    const upcoming = res.body.upcoming as { id: string; kind: string }[];
    expect(upcoming).toContainEqual(expect.objectContaining({ id: eid('lesson', 'ssc-gd-practice-test'), kind: 'quiz' }));
    expect(upcoming).toContainEqual(expect.objectContaining({ id: eid('assignment', 'quadratic-practice'), kind: 'assignment' }));
    expect(upcoming).toContainEqual(expect.objectContaining({ id: eid('live', 'ras-geography'), kind: 'live' }));
  });

  it('streams each cover, lecture and set of notes from storage', async () => {
    const course = await learner.get(`/learning/courses/${eid('course', 'class-10-maths')}`);
    expect(course.status).toBe(200);
    const cover = await learner.get(course.body.course.coverImageUrl).buffer(true);
    expect(cover.status).toBe(200);
    expect(cover.headers['content-type']).toBe('image/webp');
    expect(Buffer.compare(cover.body as Buffer, readFileSync(path.join(ASSETS, 'covers/class-10-maths.webp')))).toBe(0);
    const lessons = course.body.course.chapters.flatMap((c: { lessons: unknown[] }) => c.lessons) as {
      type: string;
      content?: { video?: { file?: { url: string } }; document?: { file?: { url: string } } };
    }[];
    const video = await learner.get(lessons.find((l) => l.type === 'video')!.content!.video!.file!.url).buffer(true);
    expect([video.status, video.headers['content-type']]).toEqual([200, 'video/mp4']);
    const pdf = await learner.get(lessons.find((l) => l.type === 'document')!.content!.document!.file!.url).buffer(true);
    expect(pdf.status).toBe(200);
    expect((pdf.body as Buffer).subarray(0, 5).toString()).toBe('%PDF-');
  });
});

describe('isolation', () => {
  it('another academy’s learner sees none of it', async () => {
    expect((await outsider.get(`/learning/courses/${eid('course', 'ras-prelims')}`)).status).toBe(404);
    expect(JSON.stringify((await outsider.get('/catalog/courses')).body)).not.toContain('edu-course-');
    expect((await outsider.get(`/catalog/covers/${eid('media', 'cover-ras-prelims')}`)).status).toBe(404);
    expect((await outsider.get(`/media/${eid('media', 'note-maths-formula-sheet')}`)).status).toBe(404);
  });

  it('the demo learner sees no other academy’s course', async () => {
    const elsewhere = await platformDb.course.findFirstOrThrow({ where: { tenantId: 'tenant-1', status: 'published' } });
    expect((await learner.get(`/learning/courses/${elsewhere.id}`)).status).toBe(404);
  });
});
