import { beforeAll, describe, expect, it } from 'vitest';
import request from 'supertest';

import { T, db } from '../test/db.js';
import { signToken } from '../lib/auth.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { ACCOUNTS, PASSWORD, anon, app, as, decodeToken, newStudent, unique, type Client } from '../test/helpers.js';

/* Phase 14 hardening: who may read an uploaded file, what a malformed body answers, and how quickly a
 * closed admin account stops working. */

const ADMIN_PASSWORD = 'a-hardening-admin-password';
const PNG = Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex');
/** The start of an MP4: a box size, then `ftyp` and a brand. */
const MP4 = Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypisom', 'latin1'), Buffer.alloc(12)]);

let platform: Client;
let admin: Client;
let instructor: Client;
const created: string[] = [];

/** Uploads a small file as `client` and answers with the stored asset id. */
async function upload(client: Client, name = `note-${unique()}.png`, type = 'image/png') {
  const res = await client.upload('/media/upload').attach('file', PNG, { filename: name, contentType: type });
  return res;
}

beforeAll(async () => {
  const email = `platform-hardening-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: 'hardening-suite-password', name: 'Platform Owner' });
  platform = await as({ email, password: 'hardening-suite-password' });
  admin = await as('admin');
  instructor = await as('instructor');
});

describe('who may open an uploaded file', () => {
  it('keeps one learner’s hand-in away from another learner', async () => {
    const author = await newStudent('Attachment Author');
    const stored = await upload(author);
    expect(stored.status).toBe(201);
    const id = stored.body.id as string;

    // The learner who uploaded it and the academy admin can read it; an instructor only once it is handed in
    // to an assignment of a course they teach (SAAS-023).
    expect((await author.get(`/media/${id}`)).status).toBe(200);
    expect((await admin.get(`/media/${id}`)).status).toBe(200);
    expect((await instructor.get(`/media/${id}`)).status).toBe(404);
    const taught = await db.courseInstructor.findFirstOrThrow({
      where: { instructorId: decodeToken(instructor.token).instructorId },
      select: { courseId: true },
    });
    const assignment = await db.courseAssignment.create({
      data: { ...T, courseId: taught.courseId, title: `Hand-in ${unique()}`, instructions: 'Upload it.', format: 'file', status: 'published' },
    });
    await author.post(`/learning/courses/${taught.courseId}/enroll`);
    const handIn = await author.post(`/learning/assignments/${assignment.id}/submit`, { text: '', files: [{ id, name: 'x', sizeMb: 1 }] });
    expect(handIn.status).toBe(200);
    expect((await instructor.get(`/media/${id}`)).status).toBe(200);
    const other = await db.instructor.findFirstOrThrow({ where: { courses: { none: { courseId: taught.courseId } }, users: { some: {} } } });
    const outsider = await as({ email: (await db.user.findFirstOrThrow({ where: { instructorId: other.id } })).email });
    expect((await outsider.get(`/media/${id}`)).status).toBe(404);

    // Another learner holding the id cannot — and is not told it exists.
    const stranger = await newStudent('Curious Learner');
    const refused = await stranger.get(`/media/${id}`);
    expect(refused.status).toBe(404);
    expect(refused.body.message).toBe('File not found.');

    // The platform's owner reads it as the admin does (docs/16, D-PLAT-03).
    expect((await platform.get(`/media/${id}`)).status).toBe(200);
    expect((await anon().get(`/media/${id}`)).status).toBe(401);
  });

  it('opens course material to the learners enrolled in its course — and a free preview to every learner', async () => {
    const stored = await upload(instructor, `lesson-${unique()}.png`);
    expect(stored.status).toBe(201);
    const id = stored.body.id as string;
    const lesson = await db.lesson.findFirstOrThrow({ where: { status: 'published', isPreview: false } });
    const content = JSON.parse(lesson.contentJson);
    await db.lesson.update({ where: { id: lesson.id }, data: { contentJson: JSON.stringify({ ...content, image: { id, url: `/media/${id}` } }) } });
    try {
      const learner = await newStudent('Material Learner');
      // Not enrolled: as far as this learner can tell, the file does not exist (SAAS-023).
      expect((await learner.get(`/media/${id}`)).status).toBe(404);
      await learner.post(`/learning/courses/${lesson.courseId}/enroll`);
      expect((await learner.get(`/media/${id}`)).status).toBe(200);
      expect((await admin.get(`/media/${id}`)).status).toBe(200);
      expect((await instructor.get(`/media/${id}`)).status).toBe(200);

      // A published free-preview lesson is open to every signed-in learner of the academy.
      const stranger = await newStudent('Preview Learner');
      expect((await stranger.get(`/media/${id}`)).status).toBe(404);
      await db.lesson.update({ where: { id: lesson.id }, data: { isPreview: true } });
      expect((await stranger.get(`/media/${id}`)).status).toBe(200);
      // A file staff uploaded but placed nowhere is readable by staff only.
      const loose = (await upload(instructor, `loose-${unique()}.png`)).body.id as string;
      expect((await learner.get(`/media/${loose}`)).status).toBe(404);
      expect((await admin.get(`/media/${loose}`)).status).toBe(200);
    } finally {
      await db.lesson.update({ where: { id: lesson.id }, data: { contentJson: lesson.contentJson, isPreview: lesson.isPreview } });
    }
  });

  it('answers 404 for a file that does not exist, the same as one that is not theirs', async () => {
    expect((await admin.get('/media/no-such-asset')).status).toBe(404);
  });
});

describe('what a learner may upload', () => {
  it('takes a document or an image', async () => {
    const learner = await newStudent('Uploader');
    expect((await upload(learner)).status).toBe(201);
  });

  it('refuses video from a learner, and takes it from staff', async () => {
    const learner = await newStudent('Video Uploader');
    const refused = await learner.upload('/media/upload').attach('file', PNG, { filename: 'lecture.mp4', contentType: 'video/mp4' });
    expect(refused.status).toBe(403);
    expect(refused.body.message).toMatch(/instructors and admins/i);

    const allowed = await instructor.upload('/media/upload').attach('file', MP4, { filename: 'lecture.mp4', contentType: 'video/mp4' });
    expect(allowed.status).toBe(201);
    // Image bytes under a video's name and type are refused: the contents must match (SAAS-023).
    const disguised = await instructor.upload('/media/upload').attach('file', PNG, { filename: 'lecture.mp4', contentType: 'video/mp4' });
    expect(disguised.status).toBe(400);
  });

  it('still refuses a type nobody may upload, and an unauthenticated caller', async () => {
    const bad = await admin.upload('/media/upload').attach('file', PNG, { filename: 'notes.exe', contentType: 'application/octet-stream' });
    expect(bad.status).toBe(400);
    expect((await anon().upload('/media/upload').attach('file', PNG, { filename: 'a.png', contentType: 'image/png' })).status).toBe(401);
  });
});

describe('a malformed body is a bad request, not a server fault', () => {
  it('answers 400 rather than 500 on every handler that used to read the body raw', async () => {
    const instructorId = (await db.instructor.findFirstOrThrow({ select: { id: true } })).id;
    const studentId = (await db.student.findFirstOrThrow({ select: { id: true } })).id;
    const courseId = (await db.course.findFirstOrThrow({ select: { id: true } })).id;
    const enrolment = await db.enrollment.findFirstOrThrow({ select: { id: true } });

    const calls: [string, Promise<{ status: number; body: { message?: string } }>][] = [
      ['POST /instructors', admin.post('/instructors', { name: 'Only a name' })],
      ['PATCH /instructors/:id', admin.patch(`/instructors/${instructorId}`, { title: 'Only a title' })],
      ['POST /instructors/:id/status', admin.post(`/instructors/${instructorId}/status`, {})],
      ['POST /certificates/templates', admin.post('/certificates/templates', {})],
      ['POST /students/:id/suspend', admin.post(`/students/${studentId}/suspend`, {})],
      ['POST /students/:id/enroll', admin.post(`/students/${studentId}/enroll`, {})],
      ['PATCH /students/enrollments/:id', admin.patch(`/students/enrollments/${enrolment.id}`, { status: 'nonsense' })],
      ['POST /courses/:id/reorder-chapters', admin.post(`/courses/${courseId}/reorder-chapters`, {})],
      ['PUT /settings/:section', admin.put('/settings/general', { academyName: 'Only one field' })],
    ];

    for (const [name, call] of calls) {
      const res = await call;
      expect(res.status, `${name} → ${res.status}`).toBe(400);
      // Nothing about the internals leaks out with it.
      expect(JSON.stringify(res.body), name).not.toMatch(/prisma|stack|TypeError|at Object|\/Users\//i);
    }
  });

  it('still accepts a well-formed body', async () => {
    const current = (await admin.get('/settings')).body.settings.general;
    expect((await admin.put('/settings/general', current)).status).toBe(200);
  });
});

describe('closing an admin account stops it at once', () => {
  it('refuses every permission-gated endpoint on the token it already holds', async () => {
    const email = `closing-${unique()}@example.com`;
    const made = await platform.post('/superadmin/admins', { name: 'Closing Admin', email, password: ADMIN_PASSWORD, tenantId: 'tenant-1' });
    expect(made.status).toBe(201);
    created.push(made.body.id as string);
    const client = await as({ email, password: ADMIN_PASSWORD });

    // Working normally.
    expect((await client.get('/reports/instructors')).status).toBe(200);

    await platform.post(`/superadmin/admins/${made.body.id}/deactivate`);

    // Same bearer token, no new sign-in: permission-gated endpoints close immediately.
    const refused = await client.get('/reports/instructors');
    expect(refused.status).toBe(403);
    expect(refused.body.message).toMatch(/deactivated/i);
    expect((await client.put('/settings/general', {})).status).toBe(403);
    expect((await client.get('/auth/me')).status).toBe(403);
    expect((await anon().post('/auth/login', { email, password: ADMIN_PASSWORD })).status).toBe(403);

    // Routes guarded by role alone, and uploads, close as well: the account is refused on every guard.
    for (const path of ['/certificates', '/certificates/templates', '/live', '/notifications']) {
      const res = await client.get(path);
      expect(res.status, path).toBe(403);
      expect(res.body.message, path).toMatch(/deactivated/i);
    }
    expect((await client.upload('/media/upload').attach('file', Buffer.from('%PDF-1.4'), 'notes.pdf')).status).toBe(403);

    // Reopening the account restores it, again without a new token.
    await platform.post(`/superadmin/admins/${made.body.id}/reactivate`);
    expect((await client.get('/reports/instructors')).status).toBe(200);
    expect((await client.get('/live')).status).toBe(200);
  });
});

describe('the academy is unaffected', () => {
  it('leaves the seeded accounts working as they were', async () => {
    expect((await anon().post('/auth/login', { email: ACCOUNTS.admin, password: PASSWORD })).status).toBe(200);
    expect((await anon().post('/auth/login', { email: ACCOUNTS.instructor, password: PASSWORD })).status).toBe(200);
    expect((await anon().post('/auth/login', { email: ACCOUNTS.student, password: PASSWORD })).status).toBe(200);
    for (const path of ['/courses', '/students', '/settings', '/dashboard', '/instructors']) {
      expect((await admin.get(path)).status, path).toBe(200);
      expect((await instructor.get(path)).status, path).toBe(200);
    }
    // A correctly signed token naming no account is not a session: with tenancy there is no academy to
    // run it in, so it is refused as unauthenticated (401) before any handler sees it — where it used
    // to reach the handler and be answered 404.
    expect(
      (
        await request(app)
          .get('/media/anything')
          .set('Authorization', `Bearer ${signToken({ sub: 'nobody', role: 'student' })}`)
      ).status,
    ).toBe(401);
  });
});
