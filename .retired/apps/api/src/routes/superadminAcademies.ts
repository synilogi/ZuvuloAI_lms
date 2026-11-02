import { Router } from 'express';
import { ACADEMY_STATUSES } from '@syniastrolms/domain';

import { changeAcademyStatus, getAcademy, listAcademies, provisionAcademy, updateAcademy } from '../lib/academies.js';
import { tenantBillingView } from '../lib/billingViews.js';
import { db } from '../lib/db.js';
import { asyncHandler, notFound } from '../lib/errors.js';
import { usageSummary } from '../lib/usage.js';
import { email, optionalEnum, paging, parseBody, parseQuery, queryInt, searchText, z } from '../lib/validate.js';

/*
 * `/superadmin/tenants` — the academies on the platform (SAAS-019). Mounted inside the Super Admin router, so
 * `requireSuperAdmin` and the platform context already apply to every route here. The academy these routes act
 * on is the one named in the path: the platform operator chooses it, which is why only this router takes one.
 */
export const superadminAcademiesRouter = Router();

const name = z.string().trim().min(2, 'Give the LMS a name.').max(120);
const slug = z.string().trim().toLowerCase().max(60);
const reason = z.string().trim().max(500).optional();

const provisionSchema = z.object({
  name,
  slug,
  admin: z.object({
    name: z.string().trim().min(2, 'Enter the admin’s full name.').max(120),
    email,
    // The rule sign-up and `POST /superadmin/admins` apply.
    password: z.string().min(8, 'The password must be at least 8 characters.').max(128),
  }),
});

const ROLES = ['student', 'instructor', 'admin'] as const;

async function tenantExists(id: string) {
  if (!(await db.tenant.findUnique({ where: { id }, select: { id: true } }))) throw notFound('Academy not found.');
}

/** Every academy, filterable by status and by a fragment of its name or address. */
superadminAcademiesRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    // Unpaged by default, up to the cap: the list answered with every academy before it could page.
    const query = parseQuery(req, z.object({ search: searchText, status: optionalEnum(ACADEMY_STATUSES), page: paging.page, pageSize: queryInt(1, 500, 500) }));
    res.json(await listAcademies(query));
  }),
);

/** Provisions an academy and its first admin in one transaction. */
superadminAcademiesRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    res.status(201).json(await provisionAcademy(req, parseBody(req, provisionSchema)));
  }),
);

superadminAcademiesRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    res.json(await getAcademy(req.params.id));
  }),
);

superadminAcademiesRouter.patch(
  '/:id',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ name: name.optional(), slug: slug.optional() }));
    res.json(await updateAcademy(req, req.params.id, input));
  }),
);

for (const action of ['suspend', 'reactivate', 'archive'] as const) {
  superadminAcademiesRouter.post(
    `/:id/${action}`,
    asyncHandler(async (req, res) => {
      const input = parseBody(req, z.object({ reason }));
      res.json(await changeAcademyStatus(req, req.params.id, action, input.reason));
    }),
  );
}

/** The academy's accounts. `passwordHash` is never selected. */
superadminAcademiesRouter.get(
  '/:id/users',
  asyncHandler(async (req, res) => {
    await tenantExists(req.params.id);
    const { search, role, page, pageSize } = parseQuery(req, z.object({ search: searchText, role: optionalEnum(ROLES), ...paging }));
    const where = {
      tenantId: req.params.id,
      ...(role ? { role } : {}),
      ...(search ? { OR: [{ name: { contains: search } }, { email: { contains: search } }] } : {}),
    };
    const [rows, total] = await Promise.all([
      db.user.findMany({
        where,
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          descriptor: true,
          deactivatedAt: true,
          createdAt: true,
          student: { select: { suspended: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      db.user.count({ where }),
    ]);
    res.json({
      rows: rows.map((u) => ({
        id: u.id,
        name: u.name,
        email: u.email,
        role: u.role,
        descriptor: u.descriptor,
        ...(u.deactivatedAt ? { deactivatedAt: u.deactivatedAt.toISOString() } : {}),
        ...(u.student?.suspended ? { suspended: true } : {}),
        createdAt: u.createdAt.toISOString(),
      })),
      total,
      page,
      pageSize,
    });
  }),
);

/** The academy's subscription, invoices, payments and plan — the same view its own admin has. */
superadminAcademiesRouter.get(
  '/:id/subscription',
  asyncHandler(async (req, res) => {
    await tenantExists(req.params.id);
    res.json(await tenantBillingView(req.params.id));
  }),
);

/** What the academy uses against each limit of its plan. */
superadminAcademiesRouter.get(
  '/:id/usage',
  asyncHandler(async (req, res) => {
    await tenantExists(req.params.id);
    res.json(await usageSummary(req.params.id));
  }),
);
