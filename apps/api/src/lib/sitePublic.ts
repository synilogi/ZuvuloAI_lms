import path from 'node:path';
import type { BlogKind, BlogPost, BlogPostInput, PublicMentor, PublicStats } from '@syniastrolms/domain';
import { courseDurationMin, slugify } from '@syniastrolms/domain';
import type { BlogPost as BlogRow } from '@prisma/client';
import type { Request, Response } from 'express';

import { recordAuditLog } from './audit.js';
import { db } from './db.js';
import { conflict, notFound } from './errors.js';
import { STAFF_ONLY } from './instructorRequests.js';
import { COURSE_INCLUDE, mapCourse } from './mapCourse.js';
import { contentDisposition, ensureUploadDir } from './media.js';
import { tenant } from './tenancy.js';

/*
 * What the public website reads from the platform's records (docs/17): its figures, its mentors, its posts and its images.
 * Figures are counted here and never stored, so the site cannot show a number the records do not hold.
 */

const LISTED = { status: 'published', visibility: 'public' } as const;

/** Counted from the records. Learning hours are the published lessons of listed courses, rounded down. */
export async function publicStats(): Promise<PublicStats> {
  const [learners, courses, instructors] = await Promise.all([
    db.student.count(),
    db.course.findMany({ where: LISTED, include: COURSE_INCLUDE }),
    db.instructor.count({ where: { ...STAFF_ONLY, status: 'active', courses: { some: { course: LISTED } } } }),
  ]);
  const minutes = courses.reduce((sum, c) => sum + courseDurationMin(mapCourse(c)), 0);
  return { learners, courses: courses.length, instructors, learningHours: Math.floor(minutes / 60) };
}

const readList = (json: string): string[] => {
  try {
    const value = JSON.parse(json) as unknown;
    return Array.isArray(value) ? value.filter((v): v is string => typeof v === 'string') : [];
  } catch {
    return [];
  }
};

const photoUrlOf = (photoJson: string | null): string | undefined => {
  if (!photoJson) return undefined;
  try {
    const id = (JSON.parse(photoJson) as { id?: unknown }).id;
    return typeof id === 'string' ? `/public/images/${id}` : undefined;
  } catch {
    return undefined;
  }
};

/** Active instructors teaching at least one listed course, with nothing a visitor should not see: no email, no phone. */
export async function publicMentors(): Promise<PublicMentor[]> {
  const rows = await db.instructor.findMany({
    where: { ...STAFF_ONLY, status: 'active', courses: { some: { course: LISTED } } },
    include: { courses: { where: { course: LISTED }, select: { course: { select: { enrolledCount: true } } } } },
    orderBy: { name: 'asc' },
  });
  return rows.map((r) => {
    const photoUrl = photoUrlOf(r.photoJson);
    return {
      id: r.id,
      name: r.name,
      title: r.title,
      bio: r.bio,
      expertise: readList(r.expertiseJson),
      ...(r.yearsTeaching != null ? { yearsTeaching: r.yearsTeaching } : {}),
      ...(r.city ? { city: r.city } : {}),
      languages: readList(r.languagesJson),
      ...(photoUrl ? { photoUrl } : {}),
      courseCount: r.courses.length,
      learnerCount: r.courses.reduce((sum, c) => sum + c.course.enrolledCount, 0),
    };
  });
}

/** One mentor and the listed courses they teach. */
export async function publicMentor(id: string) {
  const mentor = (await publicMentors()).find((m) => m.id === id);
  if (!mentor) throw notFound('This mentor isn’t available.');
  const courses = await db.course.findMany({ where: { ...LISTED, instructors: { some: { instructorId: id } } }, select: { slug: true } });
  return { mentor, courseSlugs: courses.map((c) => c.slug) };
}

/* ─── Images ───────────────────────────────────────────────────────── */

/** The Super Admin places an uploaded image on the website, which is what lets anyone read it without a session. */
export async function registerSiteImage(req: Request, mediaId: string) {
  const media = await db.mediaAsset.findUnique({ where: { id: mediaId }, select: { id: true, kind: true } });
  if (!media) throw notFound('File not found.');
  if (media.kind !== 'image') throw conflict('Only an image can be placed on the website.');
  const existing = await db.siteImage.findUnique({ where: { mediaId } });
  if (!existing) {
    await db.siteImage.create({ data: { ...tenant(), mediaId } });
    await recordAuditLog(req, { action: 'site.image_added', targetType: 'media', targetId: mediaId });
  }
  return { url: `/public/images/${mediaId}` };
}

/**
 * Serves an image a visitor may see: one placed on the website, or an active instructor's photo. Every other upload answers the
 * same 404 as a file that does not exist, so course material and learners' hand-ins stay behind the session.
 */
export async function sendPublicImage(mediaId: string, res: Response) {
  const placed = await db.siteImage.findUnique({ where: { mediaId }, select: { id: true } });
  const allowed = placed ?? (await db.instructor.findFirst({ where: { ...STAFF_ONLY, status: 'active', photoJson: { contains: `"${mediaId}"` } }, select: { id: true } }));
  const image = allowed ? await db.mediaAsset.findUnique({ where: { id: mediaId }, select: { storageName: true, mime: true, originalName: true, kind: true } }) : null;
  if (!image || image.kind !== 'image') throw notFound('Image not found.');
  await new Promise<void>((resolve, reject) =>
    res.sendFile(
      path.join(ensureUploadDir(), image.storageName),
      {
        headers: {
          'Content-Type': image.mime,
          'Content-Disposition': contentDisposition(image.originalName),
          'X-Content-Type-Options': 'nosniff',
          'Cache-Control': 'public, max-age=86400',
        },
        dotfiles: 'deny',
      },
      (err) => (err ? reject(err) : resolve()),
    ),
  ).catch((err: NodeJS.ErrnoException) => {
    if (err.code === 'ENOENT') throw notFound('Image not found.');
    if (!res.headersSent) throw err;
  });
}

/* ─── Posts ────────────────────────────────────────────────────────── */

const mapPost = (r: BlogRow): BlogPost => ({
  id: r.id,
  slug: r.slug,
  kind: r.kind as BlogKind,
  title: r.title,
  excerpt: r.excerpt,
  body: r.body,
  coverUrl: r.coverUrl,
  externalUrl: r.externalUrl,
  ...(r.eventAt ? { eventAt: r.eventAt.toISOString() } : {}),
  status: r.status as BlogPost['status'],
  ...(r.publishAt ? { publishAt: r.publishAt.toISOString() } : {}),
  createdAt: r.createdAt.toISOString(),
  updatedAt: r.updatedAt.toISOString(),
});

const livePosts = (now: Date) => ({ status: 'published', OR: [{ publishAt: null }, { publishAt: { lte: now } }] });

/** Live posts, newest first, without their bodies. */
export async function listPublicPosts(kind?: BlogKind, now = new Date()): Promise<BlogPost[]> {
  const rows = await db.blogPost.findMany({ where: { ...livePosts(now), ...(kind ? { kind } : {}) }, orderBy: [{ publishAt: 'desc' }, { createdAt: 'desc' }], take: 100 });
  return rows.map((r) => ({ ...mapPost(r), body: '' }));
}

export async function getPublicPost(slug: string, now = new Date()): Promise<BlogPost> {
  const row = await db.blogPost.findFirst({ where: { slug, ...livePosts(now) } });
  if (!row) throw notFound('This post isn’t available.');
  return mapPost(row);
}

export const listAdminPosts = async (): Promise<BlogPost[]> => (await db.blogPost.findMany({ orderBy: { createdAt: 'desc' } })).map(mapPost);

async function uniqueSlug(title: string, exceptId?: string) {
  const base = slugify(title) || 'post';
  for (let n = 1; ; n++) {
    const slug = n === 1 ? base : `${base}-${n}`;
    const taken = await db.blogPost.findFirst({ where: { slug, ...(exceptId ? { NOT: { id: exceptId } } : {}) }, select: { id: true } });
    if (!taken) return slug;
  }
}

const postFields = (input: BlogPostInput) => ({
  kind: input.kind,
  title: input.title,
  excerpt: input.excerpt,
  body: input.body,
  coverUrl: input.coverUrl,
  externalUrl: input.externalUrl,
  eventAt: input.eventAt ? new Date(input.eventAt) : null,
  status: input.status,
  publishAt: input.publishAt ? new Date(input.publishAt) : null,
});

export async function createPost(req: Request, input: BlogPostInput): Promise<BlogPost> {
  const row = await db.blogPost.create({ data: { ...tenant(), slug: await uniqueSlug(input.title), ...postFields(input) } });
  await recordAuditLog(req, { action: 'site.post_created', targetType: 'post', targetId: row.id, meta: { title: row.title, status: row.status } });
  return mapPost(row);
}

export async function updatePost(req: Request, id: string, input: BlogPostInput): Promise<BlogPost> {
  if (!(await db.blogPost.findUnique({ where: { id }, select: { id: true } }))) throw notFound('Post not found.');
  const row = await db.blogPost.update({ where: { id }, data: postFields(input) });
  await recordAuditLog(req, { action: 'site.post_updated', targetType: 'post', targetId: id, meta: { title: row.title, status: row.status } });
  return mapPost(row);
}

export async function deletePost(req: Request, id: string): Promise<void> {
  const row = await db.blogPost.findUnique({ where: { id }, select: { id: true, title: true } });
  if (!row) throw notFound('Post not found.');
  await db.blogPost.delete({ where: { id } });
  await recordAuditLog(req, { action: 'site.post_deleted', targetType: 'post', targetId: id, meta: { title: row.title } });
}
