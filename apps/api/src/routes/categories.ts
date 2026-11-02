import { Router } from 'express';
import type { CategoryInput, CategoryStatus } from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { asyncHandler, conflict, notFound } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requirePermission, requireStaffPermission } from '../lib/permissions.js';
import { coverImageOf, mapCategory } from '../lib/mapCourse.js';
import { id as idSchema, parseBody, z, patchOf, parseQuery, searchText, optionalId } from '../lib/validate.js';

const categorySchema = z.object({
  name: z.string().trim().min(2, 'Give the category a name.').max(80),
  description: z.string().trim().max(500).default(''),
  glyph: z.enum(['sun', 'houses', 'orbits', 'nakshatra', 'hourglass', 'lotus', 'compass', 'moon']),
  status: z.enum(['active', 'hidden']).default('active'),
  levelIds: z.array(idSchema).max(20).default([]),
  order: z.number().int().min(0).max(1000).optional(),
});

/** Category names are unique, ignoring case. */
async function assertUniqueName(name: string, excludeId?: string) {
  const rows = await db.category.findMany({ select: { id: true, name: true } });
  if (rows.some((r) => r.id !== excludeId && r.name.trim().toLowerCase() === name.trim().toLowerCase()))
    throw conflict(`A category called “${name.trim()}” already exists. Choose a different name.`);
}

export const categoriesRouter = Router();

async function rowFor(id: string) {
  const category = await db.category.findUnique({ where: { id }, include: { levels: true } });
  if (!category) return null;
  const courses = await db.course.findMany({ where: { categoryId: id } });
  return {
    category: mapCategory(category),
    courseCount: courses.length,
    publishedCount: courses.filter((c) => c.status === 'published').length,
    learnerCount: courses.reduce((n, c) => n + c.enrolledCount, 0),
  };
}

categoriesRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.view'),
  asyncHandler(async (req, res) => {
    const { search, status, sort } = parseQuery(req, z.object({ search: searchText, status: optionalId, sort: optionalId }));
    const categories = await db.category.findMany({ include: { levels: true } });
    const courses = await db.course.findMany();

    let rows = categories.map((c) => {
      const inCat = courses.filter((co) => co.categoryId === c.id);
      return {
        category: mapCategory(c),
        courseCount: inCat.length,
        publishedCount: inCat.filter((co) => co.status === 'published').length,
        learnerCount: inCat.reduce((n, co) => n + co.enrolledCount, 0),
      };
    });

    const counts: Record<CategoryStatus | 'all', number> = { all: rows.length, active: 0, hidden: 0 };
    for (const r of rows) counts[r.category.status]++;

    if (search) rows = rows.filter((r) => r.category.name.toLowerCase().includes(search.toLowerCase()));
    if (status && status !== 'all') rows = rows.filter((r) => r.category.status === status);

    if (sort === 'name') rows.sort((a, b) => a.category.name.localeCompare(b.category.name));
    else if (sort === 'courses') rows.sort((a, b) => b.courseCount - a.courseCount);
    else if (sort === 'updated') rows.sort((a, b) => b.category.updatedAt.localeCompare(a.category.updatedAt));
    else rows.sort((a, b) => a.category.order - b.category.order);

    res.json({ rows, counts });
  }),
);

categoriesRouter.get(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.view'),
  asyncHandler(async (req, res) => {
    const row = await rowFor(req.params.id);
    if (!row) throw notFound('Category not found.');
    const courses = await db.course.findMany({
      where: { categoryId: req.params.id },
      select: { id: true, title: true, status: true, enrolledCount: true, levelId: true, coverMotif: true, coverImageId: true },
    });
    res.json({ ...row, courses: courses.map(({ coverImageId, ...c }) => ({ ...c, ...coverImageOf({ coverImageId }) })) });
  }),
);

categoriesRouter.post(
  '/',
  requireAuth,
  requireRole('admin'),
  requirePermission('catalog.categories.manage'),
  // Categories are in no plan feature; restricted mode decides (SAAS-025): a new one adds, so it is refused.
  asyncHandler(async (req, res) => {
    const input = parseBody(req, categorySchema) as CategoryInput;
    await assertUniqueName(input.name);
    const count = await db.category.count();
    const row = await db.category.create({
      data: {
        ...tenant(),
        name: input.name,
        description: input.description,
        glyph: input.glyph,
        status: input.status,
        order: input.order ?? count + 1,
        levels: { create: (input.levelIds ?? []).map((levelId) => ({ ...tenant(), levelId })) },
      },
      include: { levels: true },
    });
    res.status(201).json(mapCategory(row));
  }),
);

categoriesRouter.patch(
  '/:id',
  requireAuth,
  requireRole('admin'),
  requirePermission('catalog.categories.manage'),
  // Categories are in no plan feature; restricted mode decides (SAAS-025): changing what exists stays open.
  asyncHandler(async (req, res) => {
    const input = parseBody(req, patchOf(categorySchema)) as Partial<CategoryInput>;
    const existing = await db.category.findUnique({ where: { id: req.params.id } });
    if (!existing) throw notFound('Category not found.');
    if (input.name !== undefined) await assertUniqueName(input.name, existing.id);
    if (input.levelIds) await db.categoryLevel.deleteMany({ where: { categoryId: existing.id } });
    const row = await db.category.update({
      where: { id: existing.id },
      data: {
        ...(input.name !== undefined ? { name: input.name } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
        ...(input.glyph !== undefined ? { glyph: input.glyph } : {}),
        ...(input.status !== undefined ? { status: input.status } : {}),
        ...(input.levelIds ? { levels: { create: input.levelIds.map((levelId) => ({ ...tenant(), levelId })) } } : {}),
      },
      include: { levels: true },
    });
    if (input.order !== undefined) await moveTo(existing.id, input.order);
    res.json(mapCategory(input.order !== undefined ? await db.category.findUniqueOrThrow({ where: { id: existing.id }, include: { levels: true } }) : row));
  }),
);

/**
 * Puts a category at `position` (1-based, clamped) and numbers every category 1…n after it, in one transaction: the
 * positions stay unique and gap-free, so "Move up" swaps with the one above rather than sharing its number.
 */
async function moveTo(id: string, position: number) {
  await db.$transaction(async (tx) => {
    const all = await tx.category.findMany({ orderBy: [{ order: 'asc' }, { name: 'asc' }], select: { id: true, order: true } });
    const rest = all.filter((c) => c.id !== id);
    const at = Math.min(Math.max(position, 1), rest.length + 1) - 1;
    const ordered = [...rest.slice(0, at), { id }, ...rest.slice(at)];
    for (const [i, c] of ordered.entries()) {
      if (all.find((x) => x.id === c.id)?.order !== i + 1 || c.id === id) await tx.category.update({ where: { id: c.id }, data: { order: i + 1 } });
    }
  });
}

categoriesRouter.delete(
  '/:id',
  requireAuth,
  requireRole('admin'),
  requirePermission('catalog.categories.manage'),
  // Categories are in no plan feature; restricted mode decides (SAAS-025): deleting takes down what exists, which stays open.
  asyncHandler(async (req, res) => {
    const { moveCoursesTo } = parseQuery(req, z.object({ moveCoursesTo: optionalId }));
    const inUse = await db.course.count({ where: { categoryId: req.params.id } });
    if (inUse > 0 && !moveCoursesTo) throw conflict(`${inUse} course(s) still use this category — choose a destination.`);
    if (inUse > 0 && moveCoursesTo) {
      if (moveCoursesTo === req.params.id || !(await db.category.findUnique({ where: { id: moveCoursesTo } })))
        throw conflict('Choose another category to move the courses to.');
      await db.course.updateMany({ where: { categoryId: req.params.id }, data: { categoryId: moveCoursesTo } });
    }
    await db.category.delete({ where: { id: req.params.id } });
    res.json({ moved: inUse });
  }),
);
