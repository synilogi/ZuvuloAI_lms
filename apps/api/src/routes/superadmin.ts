import { Router } from 'express';
import {
  isPermissionKey,
  PERMISSION_GROUP_LABEL,
  PERMISSION_GROUPS,
  PERMISSIONS,
  permissionsInGroup,
  type PermissionKey,
  type Role,
} from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { asyncHandler, badRequest, conflict, notFound, stableCodes } from '../lib/errors.js';
import { hashPassword, requireAuth, requireSuperAdmin } from '../lib/auth.js';
import { platformContext, workspaceId } from '../lib/requestContext.js';
import { readJson } from '../lib/json.js';
import { email as emailSchema, optionalEnum, paging, parseBody, parseQuery, searchText, z } from '../lib/validate.js';
import { PERMISSION_AUDIT_ACTIONS, recordAuditLog, type AuditActorType, type AuditEntry } from '../lib/audit.js';
import { SIGNALS, observabilitySnapshot } from '../lib/observe.js';
import { leaseStatus } from '../lib/jobLease.js';
import { superadminBroadcastRouter } from './superadminBroadcast.js';
import { superadminInquiriesRouter } from './superadminInquiries.js';
import { paymentGatewaysRouter } from './paymentGateways.js';
import { superadminSalesRouter } from './superadminSales.js';
import { superadminMlmEarningsRouter } from './superadminMlmEarnings.js';
import { superadminBrandingRouter } from './branding.js';
import { superadminMlmRouter } from './superadminMlm.js';
import { grantAllPermissions, grantPermission, permissionsFor, revokePermission, unknownPermissionsFor } from '../lib/permissions.js';

export const superadminRouter = Router();

/*
 * The platform surface (docs/16 §2.2). `requireSuperAdmin` has no bypass, so nothing here is reachable by a staff
 * admin. The Super Admin also passes every workspace route (courses, people, settings …) through `requireRole` and
 * `requirePermission`; this router holds what only the platform's owner does.
 *
 * The guard is applied to the whole router rather than to each route, so a route added later cannot be left open by
 * accident. The platform context is applied the same way, and only after the guard: this is the one router whose
 * queries reach the platform's own tables.
 */
superadminRouter.use(requireAuth, requireSuperAdmin, platformContext('the Super Admin works across the platform'));
// The platform's payment gateways: where course money settles (docs/16, D-PLAT-07).
superadminRouter.use(paymentGatewaysRouter);
// Course orders, coupons and what the gateway reported (docs/16 §2.4).
superadminRouter.use('/sales', superadminSalesRouter);
// The platform team's inbox: website contact and support requests.
superadminRouter.use('/inquiries', superadminInquiriesRouter);
// One message to one audience, and the history of them.
superadminRouter.use('/notifications', superadminBroadcastRouter);
// The platform's own logo and favicon — never an academy's.
superadminRouter.use('/branding', superadminBrandingRouter);
// The affiliate program (MLM-000 …): plan, and later members, network, ledgers, wallets and payouts.
superadminRouter.use('/affiliates', superadminMlmEarningsRouter);
superadminRouter.use('/affiliates', superadminMlmRouter);

/** Only ever the columns a directory needs — `passwordHash` is never selected. */
const USER_FIELDS = {
  id: true,
  name: true,
  email: true,
  role: true,
  descriptor: true,
  instructorId: true,
  deactivatedAt: true,
  createdAt: true,
  updatedAt: true,
  tenant: { select: { id: true, name: true, slug: true } },
} as const;

interface DirectoryRow {
  id: string;
  name: string;
  email: string;
  role: string;
  descriptor: string;
  instructorId: string | null;
  deactivatedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  tenant: { id: string; name: string; slug: string } | null;
}

const toDirectoryRow = (row: DirectoryRow) => ({
  id: row.id,
  name: row.name,
  email: row.email,
  role: row.role,
  descriptor: row.descriptor,
  instructorId: row.instructorId ?? undefined,
  deactivatedAt: row.deactivatedAt?.toISOString(),
  createdAt: row.createdAt.toISOString(),
  updatedAt: row.updatedAt.toISOString(),
  // The workspace the account belongs to; absent for a super admin, which belongs to the platform.
  ...(row.tenant ? { tenant: row.tenant } : {}),
});

const ROLES = ['student', 'instructor', 'admin', 'superadmin'] as const satisfies readonly Role[];

/** Platform-wide counts, read from the records that already exist. Nothing here is derived or invented. */
superadminRouter.get(
  '/overview',
  asyncHandler(async (_req, res) => {
    const [
      byRole,
      courseStatuses,
      students,
      suspendedStudents,
      instructors,
      inactiveInstructors,
      enrollments,
      certificates,
      audits,
      purchases,
      paidPurchases,
      inbox,
    ] = await Promise.all([
      db.user.groupBy({ by: ['role'], _count: { _all: true } }),
      db.course.groupBy({ by: ['status'], _count: { _all: true } }),
      db.student.count(),
      db.student.count({ where: { suspended: true } }),
      db.instructor.count(),
      db.instructor.count({ where: { status: 'inactive' } }),
      db.enrollment.count(),
      db.issuedCertificate.count(),
      db.auditLog.count(),
      db.coursePurchase.count(),
      db.coursePurchase.aggregate({ where: { status: 'paid' }, _count: { _all: true }, _sum: { amount: true } }),
      db.inquiry.groupBy({ by: ['status'], _count: { _all: true } }),
    ]);

    const roleCount = (role: Role) => byRole.find((r) => r.role === role)?._count._all ?? 0;
    const statusCount = (status: string) => courseStatuses.find((c) => c.status === status)?._count._all ?? 0;

    res.json({
      users: {
        total: byRole.reduce((n, r) => n + r._count._all, 0),
        students: roleCount('student'),
        instructors: roleCount('instructor'),
        admins: roleCount('admin'),
        superadmins: roleCount('superadmin'),
      },
      // Suspension lives on the learner profile and status on the instructor profile; both are existing columns.
      people: { studentProfiles: students, suspendedStudents, instructorProfiles: instructors, inactiveInstructors },
      courses: {
        total: courseStatuses.reduce((n, c) => n + c._count._all, 0),
        published: statusCount('published'),
        draft: statusCount('draft'),
        archived: statusCount('archived'),
      },
      learning: { enrollments, certificatesIssued: certificates },
      audit: { events: audits },
      // Course sales (docs/16 §2.4): orders opened, orders paid, and the paise they brought in.
      sales: { orders: purchases, paid: paidPurchases._count._all, revenue: paidPurchases._sum.amount ?? 0 },
      inbox: { new: inbox.find((i) => i.status === 'new')?._count._all ?? 0, inProgress: inbox.find((i) => i.status === 'in_progress')?._count._all ?? 0 },
      generatedAt: new Date().toISOString(),
    });
  }),
);

/** The staff admins (docs/16, D-PLAT-03), newest first. */
superadminRouter.get(
  '/admins',
  asyncHandler(async (req, res) => {
    const { page, pageSize } = parseQuery(req, z.object({ ...paging }));
    const where = { role: 'admin' };
    const [rows, total] = await Promise.all([
      db.user.findMany({ where, select: USER_FIELDS, orderBy: { createdAt: 'desc' }, skip: (page - 1) * pageSize, take: pageSize }),
      db.user.count({ where }),
    ]);
    res.json({ rows: rows.map(toDirectoryRow), total, page, pageSize });
  }),
);

/* ─── Admin management ───────────────────────────────────────────────────
 *
 * Staff admin accounts, each limited by the permission catalogue. Each write loads its target from the database and
 * refuses anything that is not exactly a staff admin, so a learner, an instructor or another super admin cannot be
 * touched through an admin endpoint. The role is never read from the request: it is set to 'admin' on
 * creation and is not a field any of these schemas accepts, so a body carrying one is simply dropped.
 * Every successful change is written with its audit event in one transaction.
 */

const adminName = z.string().trim().min(2, 'Enter the admin’s full name.').max(120);
/** The same rule `POST /auth/register` applies, so the account can sign in straight away. */
const adminPassword = z.string().min(8, 'The password must be at least 8 characters.').max(128);

/** A staff admin lives in the platform's one workspace; nothing in the body chooses where. */
const createAdminSchema = z.object({
  name: adminName,
  email: emailSchema,
  password: adminPassword,
  /** Accepted and ignored for one release: the SaaS-era client named a workspace here (docs/16 §3.1). */
  tenantId: z.string().trim().max(64).optional(),
});
const updateAdminSchema = z.object({ name: adminName.optional(), email: emailSchema.optional() });

/**
 * The academy admin this request is about. A missing id and an id that belongs to somebody else
 * answer the same 404 — the rule `lib/scope.ts` states, so a refusal never confirms what an id is.
 */
async function loadAdmin(id: string): Promise<DirectoryRow & { role: string }> {
  // The id goes to the lookup as it arrives, the way every other route reads a path parameter: an id
  // of any shape simply matches nothing, which is the 404 below rather than a thrown parse error.
  const user = await db.user.findUnique({ where: { id }, select: USER_FIELDS });
  if (!user || user.role !== 'admin') throw notFound('Admin not found.');
  return user;
}

const emailTaken = async (email: string) => Boolean(await db.user.findUnique({ where: { email }, select: { id: true } }));

/** Creates a staff admin — the one way to get one, since nothing else in the app can. */
superadminRouter.post(
  '/admins',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, createAdminSchema);
    if (await emailTaken(input.email)) throw conflict('An account with this email already exists.');
    const tenantId = await workspaceId();

    const passwordHash = await hashPassword(input.password);
    const created = await db.$transaction(async (tx) => {
      const user = await tx.user.create({
        // role is fixed here and comes from nowhere near the request. No Student or Instructor row:
        // a staff admin has neither, exactly as the seeded one does not.
        data: { tenantId, name: input.name, email: input.email, passwordHash, role: 'admin', descriptor: 'Platform admin' },
        select: USER_FIELDS,
      });
      // A new admin starts with the whole catalogue. Narrowing it is a deliberate act, not the default.
      await grantAllPermissions(user.id, { grantedBy: req.auth?.sub, client: tx });
      await recordAuditLog(
        req,
        { action: 'admin.created', targetType: 'admin', targetId: user.id, meta: { email: user.email, name: user.name, tenantId } },
        tx,
      );
      return user;
    });
    res.status(201).json(toDirectoryRow(created));
  }),
);

/** Renames an admin or moves it to another address. Nothing else about the account can be changed. */
superadminRouter.patch(
  '/admins/:id',
  asyncHandler(async (req, res) => {
    const target = await loadAdmin(req.params.id);
    const input = parseBody(req, updateAdminSchema);

    const name = input.name && input.name !== target.name ? input.name : undefined;
    const email = input.email && input.email !== target.email ? input.email : undefined;
    if (email && (await emailTaken(email))) throw conflict('An account with this email already exists.');
    // Nothing to do is not a change: the row goes back as it is, and no audit event is written.
    if (!name && !email) return void res.json(toDirectoryRow(target));

    const updated = await db.$transaction(async (tx) => {
      const user = await tx.user.update({ where: { id: target.id }, data: { ...(name ? { name } : {}), ...(email ? { email } : {}) }, select: USER_FIELDS });
      await recordAuditLog(
        req,
        {
          action: 'admin.updated',
          targetType: 'admin',
          targetId: user.id,
          meta: { ...(name ? { name: { from: target.name, to: name } } : {}), ...(email ? { email: { from: target.email, to: email } } : {}) },
        },
        tx,
      );
      return user;
    });
    res.json(toDirectoryRow(updated));
  }),
);

/**
 * Deactivating keeps the row and closes the door: sign-in and the session read both refuse a
 * deactivated account (`routes/auth.ts`). The actor is a super admin and the target must be an
 * admin, so no identity rule is needed here — an actor can never be its own target.
 */
superadminRouter.post(
  '/admins/:id/deactivate',
  asyncHandler(async (req, res) => {
    const target = await loadAdmin(req.params.id);
    // Already closed: answer with the account as it stands, and write no second event.
    if (target.deactivatedAt) return void res.json(toDirectoryRow(target));

    const updated = await db.$transaction(async (tx) => {
      const user = await tx.user.update({ where: { id: target.id }, data: { deactivatedAt: new Date() }, select: USER_FIELDS });
      await recordAuditLog(req, { action: 'admin.deactivated', targetType: 'admin', targetId: user.id, meta: { email: user.email } }, tx);
      return user;
    });
    res.json(toDirectoryRow(updated));
  }),
);

/** Lets a deactivated admin back in. */
superadminRouter.post(
  '/admins/:id/reactivate',
  asyncHandler(async (req, res) => {
    const target = await loadAdmin(req.params.id);
    if (!target.deactivatedAt) return void res.json(toDirectoryRow(target));

    const updated = await db.$transaction(async (tx) => {
      const user = await tx.user.update({ where: { id: target.id }, data: { deactivatedAt: null }, select: USER_FIELDS });
      await recordAuditLog(req, { action: 'admin.reactivated', targetType: 'admin', targetId: user.id, meta: { email: user.email } }, tx);
      return user;
    });
    res.json(toDirectoryRow(updated));
  }),
);

/** Every account, filterable by role and by a fragment of a name or an email address. */
superadminRouter.get(
  '/users',
  asyncHandler(async (req, res) => {
    const { search, role, page, pageSize } = parseQuery(req, z.object({ search: searchText, role: optionalEnum(ROLES), ...paging }));
    // SQLite's LIKE is case-insensitive for ASCII, which is what `contains` compiles to here.
    const where = {
      ...(role ? { role } : {}),
      ...(search ? { OR: [{ name: { contains: search } }, { email: { contains: search } }] } : {}),
    };
    const [rows, total] = await Promise.all([
      db.user.findMany({ where, select: USER_FIELDS, orderBy: { createdAt: 'desc' }, skip: (page - 1) * pageSize, take: pageSize }),
      db.user.count({ where }),
    ]);
    res.json({ rows: rows.map(toDirectoryRow), total, page, pageSize });
  }),
);

/* ─── Admin permissions ──────────────────────────────────────────────────
 *
 * One key at a time, on one admin at a time. The catalogue in `packages/domain` is the only source
 * of keys: a key it does not know is a 400, never a row. Each real change is written with its audit
 * event in one transaction; asking for a change that has already happened writes neither.
 */

/** The catalogue as the editor needs it: groups in catalogue order, each key with what it means and whether it is held. */
function permissionView(granted: PermissionKey[]) {
  const held = new Set<PermissionKey>(granted);
  return PERMISSION_GROUPS.map((group) => ({
    group,
    label: PERMISSION_GROUP_LABEL[group],
    permissions: permissionsInGroup(group).map((key) => ({
      key,
      label: PERMISSIONS[key].label,
      description: PERMISSIONS[key].description,
      granted: held.has(key),
    })),
  }));
}

async function permissionPayload(admin: DirectoryRow & { role: string }) {
  const [granted, unknown] = await Promise.all([permissionsFor(admin.id), unknownPermissionsFor(admin.id)]);
  return {
    admin: toDirectoryRow(admin),
    granted,
    groups: permissionView(granted),
    // Keys held in the database that the catalogue no longer knows. They grant nothing; they are
    // surfaced so a stale row is visible rather than silently ignored.
    unknown,
  };
}

/** The key a request is asking about, or a 400 — an arbitrary string is never a permission. */
function permissionKeyFrom(value: unknown): PermissionKey {
  if (typeof value !== 'string' || !isPermissionKey(value)) throw badRequest('That is not a permission this Admin has.');
  return value;
}

/** What an admin may do, and everything it could be given. */
superadminRouter.get(
  '/admins/:id/permissions',
  asyncHandler(async (req, res) => {
    const admin = await loadAdmin(req.params.id);
    res.json(await permissionPayload(admin));
  }),
);

/** Gives one permission. Granting what is already held changes nothing and records nothing. */
superadminRouter.post(
  '/admins/:id/permissions',
  asyncHandler(async (req, res) => {
    const admin = await loadAdmin(req.params.id);
    const { key } = parseBody(req, z.object({ key: z.string().trim().max(120) }));
    const permission = permissionKeyFrom(key);

    await db.$transaction(async (tx) => {
      // The actor is the signed-in super admin, taken from the token — the body cannot name one.
      const granted = await grantPermission(admin.id, permission, { grantedBy: req.auth?.sub, client: tx });
      if (granted) {
        await recordAuditLog(
          req,
          { action: PERMISSION_AUDIT_ACTIONS.granted, targetType: 'admin', targetId: admin.id, meta: { key: permission, email: admin.email } },
          tx,
        );
      }
    });
    res.json(await permissionPayload(admin));
  }),
);

/** Takes one permission away. Revoking what is not held changes nothing and records nothing. */
superadminRouter.delete(
  '/admins/:id/permissions/:key',
  asyncHandler(async (req, res) => {
    const admin = await loadAdmin(req.params.id);
    const permission = permissionKeyFrom(req.params.key);

    await db.$transaction(async (tx) => {
      const revoked = await revokePermission(admin.id, permission, { client: tx });
      if (revoked) {
        await recordAuditLog(
          req,
          { action: PERMISSION_AUDIT_ACTIONS.revoked, targetType: 'admin', targetId: admin.id, meta: { key: permission, email: admin.email } },
          tx,
        );
      }
    });
    res.json(await permissionPayload(admin));
  }),
);

/**
 * The audit trail, newest first. Written by `lib/audit.ts`; there is no way to write one over the API, and
 * the database refuses to change or delete one. Filter by who (`actorType`: a person, the scheduler, the
 * provider), by exact `action`, or by `target` (`targetType`, optionally with `targetId`).
 */
superadminRouter.get(
  '/audit',
  asyncHandler(async (req, res) => {
    const q = parseQuery(
      req,
      z.object({
        actorType: optionalEnum(['user', 'system', 'provider'] as const),
        action: z.string().trim().max(80).optional(),
        // A family of actions: `mlm.` is the affiliate program's. An exact `action` is narrower, so it wins.
        prefix: z.string().trim().max(80).optional(),
        targetType: z.string().trim().max(40).optional(),
        targetId: z.string().trim().max(64).optional(),
        ...paging,
      }),
    );
    const { page, pageSize } = q;
    const where = {
      ...(q.actorType ? { actorType: q.actorType } : {}),
      ...(q.prefix ? { action: { startsWith: q.prefix } } : {}),
      ...(q.action ? { action: q.action } : {}),
      ...(q.targetType ? { targetType: q.targetType } : {}),
      ...(q.targetId ? { targetId: q.targetId } : {}),
    };
    const [rows, total] = await Promise.all([
      db.auditLog.findMany({ where, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], skip: (page - 1) * pageSize, take: pageSize }),
      db.auditLog.count({ where }),
    ]);
    const entries: AuditEntry[] = rows.map((row) => ({
      id: row.id,
      action: row.action,
      targetType: row.targetType,
      targetId: row.targetId ?? undefined,
      actor: {
        type: row.actorType as AuditActorType,
        id: row.actorId ?? undefined,
        email: row.actorEmail,
        role: row.actorRole,
        ...(row.source ? { source: row.source } : {}),
      },
      meta: readJson<Record<string, unknown>>(row.metaJson, {}),
      createdAt: row.createdAt.toISOString(),
    }));
    res.json({ rows: entries, total, page, pageSize });
  }),
);

/**
 * What has gone wrong lately (§48): counts per signal since the process started, and the latest payment,
 * refund, webhook, job and request failures — redacted before they were ever kept. Filter by `signal`.
 */
superadminRouter.get(
  '/observability',
  asyncHandler(async (req, res) => {
    const q = parseQuery(req, z.object({ signal: optionalEnum(SIGNALS), limit: z.coerce.number().int().min(1).max(200).optional() }));
    res.json(observabilitySnapshot({ signal: q.signal, limit: q.limit }));
  }),
);

/**
 * Operational state, from what the application already records. No configuration, no paths, no
 * credentials: the outbox, the media table, the database round-trip and the process's own uptime.
 */
superadminRouter.get(
  '/system',
  asyncHandler(async (_req, res) => {
    const startedAt = Date.now();
    let database: { ok: boolean; latencyMs?: number } = { ok: false };
    try {
      await db.settings.count();
      database = { ok: true, latencyMs: Date.now() - startedAt };
    } catch {
      database = { ok: false };
    }

    const [outbox, oldestQueued, media] = await Promise.all([
      db.emailOutbox.groupBy({ by: ['status'], _count: { _all: true } }),
      db.emailOutbox.findFirst({ where: { status: 'queued' }, orderBy: { createdAt: 'asc' }, select: { createdAt: true } }),
      db.mediaAsset.aggregate({ _count: { _all: true }, _sum: { sizeBytes: true } }),
    ]);
    const outboxCount = (status: string) => outbox.find((o) => o.status === status)?._count._all ?? 0;

    res.json({
      database,
      email: { queued: outboxCount('queued'), sent: outboxCount('sent'), failed: outboxCount('failed'), oldestQueuedAt: oldestQueued?.createdAt.toISOString() },
      media: { files: media._count._all, totalBytes: media._sum.sizeBytes ?? 0 },
      // Who runs each scheduled job, and how each last ended (SAAS-022).
      jobs: await leaseStatus(),
      // The mode the process runs in and how long it has been up; never a value read from a secret.
      process: { environment: process.env.NODE_ENV ?? 'development', uptimeSeconds: Math.round(process.uptime()) },
      generatedAt: new Date().toISOString(),
    });
  }),
);

// Every refusal on the platform surface carries a stable code (SAAS-013, §34) — the guard's too.
superadminRouter.use(stableCodes);
