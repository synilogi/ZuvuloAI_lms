import { beforeAll, describe, expect, it } from 'vitest';

import { readdirSync } from 'node:fs';

import { MEDIA_KINDS, contentDisposition, ensureUploadDir, matchesSignature } from '../lib/media.js';
import { forTenant } from '../lib/db.js';
import { T, db, platformDb } from '../test/db.js';
import { anon, as, newStudent, unique, type Client } from '../test/helpers.js';

/* SAAS-023. Every media endpoint: who may upload what, whose bytes are accepted, who may read a file, and what
 * the download says about it. */

const PDF = Buffer.from('%PDF-1.7\n%âãÏÓ\n', 'latin1');
let admin: Client;
let instructor: Client;

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
});

describe('uploads are checked by their contents, not only their name and type', () => {
  it('recognises each allowed kind by its signature and refuses a disguise', () => {
    expect(matchesSignature('.pdf', PDF)).toBe(true);
    expect(matchesSignature('.png', Buffer.from('89504e470d0a1a0a', 'hex'))).toBe(true);
    expect(matchesSignature('.jpg', Buffer.from('ffd8ffe0', 'hex'))).toBe(true);
    expect(matchesSignature('.webp', Buffer.concat([Buffer.from('RIFF'), Buffer.alloc(4), Buffer.from('WEBPVP8 ')]))).toBe(true);
    expect(matchesSignature('.mp4', Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypmp42')]))).toBe(true);
    expect(matchesSignature('.webm', Buffer.from('1a45dfa39f', 'hex'))).toBe(true);
    expect(matchesSignature('.pdf', Buffer.from('MZ\x90\x00'))).toBe(false);
    expect(matchesSignature('.png', PDF)).toBe(false);
    expect(matchesSignature('.exe', PDF)).toBe(false);
  });

  it('refuses a program renamed as a PDF, and keeps nothing of it', async () => {
    const before = await db.mediaAsset.count();
    const res = await admin
      .upload('/media/upload')
      .attach('file', Buffer.from('MZ\x90\x00\x03\x00\x00\x00', 'latin1'), { filename: 'syllabus.pdf', contentType: 'application/pdf' });
    expect(res.status).toBe(400);
    expect(await db.mediaAsset.count()).toBe(before);
  });

  it('stores a clean name, and downloads with a header that cannot be broken by one', async () => {
    const res = await admin.upload('/media/upload').attach('file', PDF, { filename: 'Algebra "notes".pdf', contentType: 'application/pdf' });
    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Algebra _notes_.pdf');
    const file = await admin.get(`/media/${res.body.id}`);
    expect(file.status).toBe(200);
    expect(file.headers['content-disposition']).toBe(contentDisposition('Algebra _notes_.pdf'));
    expect(file.headers['x-content-type-options']).toBe('nosniff');
    expect(file.headers['cache-control']).toMatch(/private/);
  });
});

describe('a file is read only where the reader may open it', () => {
  it('opens an assignment attachment to learners enrolled in its course only', async () => {
    const stored = await instructor.upload('/media/upload').attach('file', PDF, { filename: `brief-${unique()}.pdf`, contentType: 'application/pdf' });
    const id = stored.body.id as string;
    // A free course: learners enrol themselves in it (a paid one is bought).
    const course = await db.course.findFirstOrThrow({ where: { status: 'published', visibility: 'public', pricing: 'free' } });
    const assignment = await db.courseAssignment.create({
      data: {
        ...T,
        courseId: course.id,
        title: `Brief ${unique()}`,
        format: 'text',
        status: 'published',
        attachmentsJson: JSON.stringify([{ id, name: 'brief.pdf', sizeMb: 0.1 }]),
      },
    });
    try {
      const enrolled = await newStudent('Enrolled Reader');
      const outsider = await newStudent('Outside Reader');
      expect((await enrolled.post(`/learning/courses/${course.id}/enroll`)).status).toBe(200);
      expect((await enrolled.get(`/media/${id}`)).status).toBe(200);
      expect((await outsider.get(`/media/${id}`)).status).toBe(404);
      // A draft assignment's attachment is not yet for learners.
      await db.courseAssignment.update({ where: { id: assignment.id }, data: { status: 'draft' } });
      const later = await newStudent('Draft Reader');
      expect((await later.post(`/learning/courses/${course.id}/enroll`)).status).toBe(200);
      expect((await later.get(`/media/${id}`)).status).toBe(404);
    } finally {
      await db.courseAssignment.delete({ where: { id: assignment.id } });
    }
  });

  it('never finds another academy’s file, whatever the role', async () => {
    const other = `media-other-${unique()}`;
    await platformDb.tenant.create({ data: { id: other, name: 'Other Media Academy', slug: other } });
    const owner = await platformDb.user.create({
      data: { tenantId: other, name: 'Other Admin', email: `${other}@example.com`, passwordHash: 'x', role: 'admin' },
    });
    const asset = await forTenant(other).mediaAsset.create({
      data: {
        tenantId: other,
        ownerUserId: owner.id,
        kind: 'document',
        originalName: 'secret.pdf',
        mime: 'application/pdf',
        sizeBytes: 10,
        storageName: `${unique()}.pdf`,
      },
    });
    for (const client of [admin, instructor, await newStudent('Cross Reader')]) expect((await client.get(`/media/${asset.id}`)).status).toBe(404);
    expect((await anon().get(`/media/${asset.id}`)).status).toBe(401);
  });

  it('offers no way to delete or overwrite a stored file over the API', async () => {
    const stored = await admin.upload('/media/upload').attach('file', PDF, { filename: 'kept.pdf', contentType: 'application/pdf' });
    for (const method of ['delete', 'put', 'patch'] as const) {
      const res = await (method === 'delete' ? admin.delete(`/media/${stored.body.id}`) : admin[method](`/media/${stored.body.id}`, {}));
      expect(res.status, method).toBe(404);
    }
    expect(await db.mediaAsset.count({ where: { id: stored.body.id } })).toBe(1);
  });
});

describe('a learner’s upload is cut off before it reaches the disk (2026-10-28)', () => {
  it('refuses video and anything past the hand-in size, writing nothing', async () => {
    const learner = await newStudent('Big File Sender');
    const files = () => readdirSync(ensureUploadDir()).length;
    const before = files();
    const video = await learner.upload('/media/upload').attach('file', Buffer.alloc(2048), { filename: 'lecture.mp4', contentType: 'video/mp4' });
    expect(video.status).toBe(403);
    const ceiling = Math.max(MEDIA_KINDS.document.maxBytes, MEDIA_KINDS.image.maxBytes);
    const huge = Buffer.concat([PDF, Buffer.alloc(ceiling + 1024)]);
    const big = await learner.upload('/media/upload').attach('file', huge, { filename: 'huge.pdf', contentType: 'application/pdf' });
    expect(big.status).toBe(413);
    expect(files()).toBe(before);
  });
});
