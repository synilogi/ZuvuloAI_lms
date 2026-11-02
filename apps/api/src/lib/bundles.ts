import type { Prisma } from '@prisma/client';
import {
  chargeOf,
  courseDurationMin,
  courseSale,
  slugify,
  type AdminBundle,
  type BundleCourse,
  type BundleInput,
  type CoursePricing,
  type PublicBundle,
} from '@syniastrolms/domain';
import type { Request } from 'express';

import { recordAuditLog } from './audit.js';
import { db } from './db.js';
import { conflict, notFound, badRequest } from './errors.js';
import { COURSE_INCLUDE, mapCourse } from './mapCourse.js';
import { activeMlmPlan } from './mlm/plan.js';
import { runAsPlatform } from './tenancy.js';
import { tenant } from './tenancy.js';

/*
 * Course bundles (docs/17): several courses at one price, made by the Super Admin. A bundle is on sale while it is
 * published, past its publish date, holds at least two courses that are each published, listed and paid, and none of them
 * earns affiliate volume: the plan's commission assumes the full price, so an eligible course is sold on its own only.
 * One that stops qualifying (a course unpublished, or added to the plan) simply leaves the website.
 */

const BUNDLE_INCLUDE = {
  courses: { orderBy: { order: 'asc' }, include: { course: { include: COURSE_INCLUDE } } },
  _count: { select: { purchases: true } },
} satisfies Prisma.CourseBundleInclude;

type BundleRow = Prisma.CourseBundleGetPayload<{ include: typeof BUNDLE_INCLUDE }>;
type CourseRow = BundleRow['courses'][number]['course'];

const saleOf = (course: Pick<CourseRow, 'pricing' | 'priceAmount' | 'priceCurrency' | 'salePrice'>) =>
  courseSale({
    pricing: course.pricing as CoursePricing,
    price: course.priceAmount != null ? { amount: course.priceAmount, currency: course.priceCurrency as 'INR' } : undefined,
    salePrice: course.salePrice ?? undefined,
  });

function mapBundleCourse(row: CourseRow): BundleCourse {
  const course = mapCourse(row);
  const sale = saleOf(row);
  return {
    id: course.id,
    slug: course.slug,
    title: course.title,
    subtitle: course.subtitle,
    coverMotif: course.coverMotif,
    ...(course.coverImageUrl ? { coverImageUrl: course.coverImageUrl } : {}),
    durationMin: courseDurationMin(course),
    price: sale.kind === 'paid' ? sale.price.amount : null,
  };
}

function mapPublic(row: BundleRow): PublicBundle {
  const courses = row.courses.map((c) => mapBundleCourse(c.course));
  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    summary: row.summary,
    description: row.description,
    coverUrl: row.coverUrl,
    price: row.price,
    separatePrice: courses.reduce((sum, c) => sum + (c.price ?? 0), 0),
    courseCount: courses.length,
    durationMin: courses.reduce((sum, c) => sum + c.durationMin, 0),
    courses,
  };
}

const mapAdmin = (row: BundleRow): AdminBundle => ({
  ...mapPublic(row),
  status: row.status as AdminBundle['status'],
  ...(row.publishAt ? { publishAt: row.publishAt.toISOString() } : {}),
  order: row.order,
  courseIds: row.courses.map((c) => c.courseId),
  orderCount: row._count.purchases,
});

const eligibleCourseIds = async () => (await runAsPlatform('bundles read which courses the active plan names', () => activeMlmPlan()))?.eligibleCourseIds ?? [];

/** Whether a course can be sold in a bundle. */
const qualifies = (course: CourseRow, eligible: readonly string[]) =>
  course.status === 'published' && course.visibility === 'public' && saleOf(course).kind === 'paid' && !eligible.includes(course.id);

function onSale(row: BundleRow, eligible: readonly string[], now: Date) {
  return (
    row.status === 'published' &&
    (!row.publishAt || row.publishAt.getTime() <= now.getTime()) &&
    row.courses.length >= 2 &&
    row.courses.every((c) => qualifies(c.course, eligible))
  );
}

export async function listPublicBundles(now = new Date()): Promise<PublicBundle[]> {
  const [rows, eligible] = await Promise.all([
    db.courseBundle.findMany({ where: { status: 'published' }, include: BUNDLE_INCLUDE, orderBy: [{ order: 'asc' }, { createdAt: 'desc' }] }),
    eligibleCourseIds(),
  ]);
  return rows.filter((r) => onSale(r, eligible, now)).map(mapPublic);
}

export async function getPublicBundle(slug: string, now = new Date()): Promise<PublicBundle> {
  const [row, eligible] = await Promise.all([db.courseBundle.findFirst({ where: { slug }, include: BUNDLE_INCLUDE }), eligibleCourseIds()]);
  if (!row || !onSale(row, eligible, now)) throw notFound('Bundle not found.');
  return mapPublic(row);
}

/** What a sale of this bundle would be right now: the server's price and the courses it buys. Null when it is not on sale. */
export async function bundleOffer(bundleId: string, now = new Date()) {
  const [row, eligible] = await Promise.all([db.courseBundle.findUnique({ where: { id: bundleId }, include: BUNDLE_INCLUDE }), eligibleCourseIds()]);
  if (!row || !onSale(row, eligible, now)) return null;
  return {
    title: row.title,
    price: row.price,
    charge: chargeOf({ amount: row.price, currency: 'INR' }),
    terms: row.courses.map((c) => {
      const sale = saleOf(c.course);
      return { courseId: c.courseId, listPrice: sale.kind === 'paid' ? sale.price.amount : 0 };
    }),
  };
}

export async function listAdminBundles(): Promise<AdminBundle[]> {
  const rows = await db.courseBundle.findMany({ include: BUNDLE_INCLUDE, orderBy: [{ order: 'asc' }, { createdAt: 'desc' }] });
  return rows.map(mapAdmin);
}

async function uniqueSlug(title: string, exceptId?: string) {
  const base = slugify(title) || 'bundle';
  for (let n = 1; ; n++) {
    const slug = n === 1 ? base : `${base}-${n}`;
    const taken = await db.courseBundle.findFirst({ where: { slug, ...(exceptId ? { NOT: { id: exceptId } } : {}) }, select: { id: true } });
    if (!taken) return slug;
  }
}

/** The rules a saved bundle must meet. A draft may be unfinished; a published one has to be sellable as it stands. */
async function assertCourses(input: BundleInput) {
  const ids = input.courseIds;
  if (new Set(ids).size !== ids.length) throw badRequest('A course can be in a bundle only once.');
  const courses = await db.course.findMany({ where: { id: { in: ids } }, include: COURSE_INCLUDE });
  if (courses.length !== ids.length) throw notFound('Course not found.');
  const eligible = await eligibleCourseIds();
  const earning = courses.find((c) => eligible.includes(c.id));
  if (earning) throw conflict(`“${earning.title}” earns affiliate volume, so it is sold on its own and cannot be in a bundle.`);
  if (input.status !== 'published') return;
  if (ids.length < 2) throw badRequest('A published bundle needs at least two courses.');
  const unavailable = courses.find((c) => !qualifies(c as CourseRow, eligible));
  if (unavailable) throw conflict(`“${unavailable.title}” is not a published, listed, paid course, so this bundle can’t be published.`);
}

const fieldsOf = (input: BundleInput) => ({
  title: input.title,
  summary: input.summary,
  description: input.description,
  coverUrl: input.coverUrl,
  price: input.price,
  status: input.status,
  publishAt: input.publishAt ? new Date(input.publishAt) : null,
  order: input.order,
});

const linksOf = (input: BundleInput) => input.courseIds.map((courseId, order) => ({ ...tenant(), courseId, order }));

export async function createBundle(req: Request, input: BundleInput): Promise<AdminBundle> {
  await assertCourses(input);
  const row = await db.courseBundle.create({
    data: { ...tenant(), slug: await uniqueSlug(input.title), ...fieldsOf(input), courses: { create: linksOf(input) } },
    include: BUNDLE_INCLUDE,
  });
  await recordAuditLog(req, {
    action: 'bundle.created',
    targetType: 'bundle',
    targetId: row.id,
    meta: { title: row.title, price: row.price, courses: input.courseIds.length },
  });
  return mapAdmin(row);
}

export async function updateBundle(req: Request, id: string, input: BundleInput): Promise<AdminBundle> {
  const existing = await db.courseBundle.findUnique({ where: { id }, select: { id: true } });
  if (!existing) throw notFound('Bundle not found.');
  await assertCourses(input);
  await db.courseBundleCourse.deleteMany({ where: { bundleId: id } });
  await db.courseBundleCourse.createMany({ data: linksOf(input).map((l) => ({ ...l, bundleId: id })) });
  const row = await db.courseBundle.update({ where: { id }, data: fieldsOf(input), include: BUNDLE_INCLUDE });
  await recordAuditLog(req, {
    action: 'bundle.updated',
    targetType: 'bundle',
    targetId: id,
    meta: { title: row.title, price: row.price, status: row.status, courses: input.courseIds.length },
  });
  return mapAdmin(row);
}

/** A bundle anyone ever ordered stays on record: it can be archived, not deleted. */
export async function deleteBundle(req: Request, id: string): Promise<void> {
  const row = await db.courseBundle.findUnique({ where: { id }, include: { _count: { select: { purchases: true } } } });
  if (!row) throw notFound('Bundle not found.');
  if (row._count.purchases > 0) throw conflict('This bundle has orders, so it can’t be deleted. Archive it instead.');
  await db.courseBundle.delete({ where: { id } });
  await recordAuditLog(req, { action: 'bundle.deleted', targetType: 'bundle', targetId: id, meta: { title: row.title } });
}
