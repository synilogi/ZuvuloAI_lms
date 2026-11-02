import type { Request } from 'express';
import { academyTransition, isAcademyStatus, validateAcademySlug, type AcademyAction, type AcademyStatus } from '@syniastrolms/domain';

import { recordAuditLog } from './audit.js';
import { hashPassword } from './auth.js';
import { db } from './db.js';
import { badRequest, conflict, notFound } from './errors.js';
import { writeJson } from './json.js';
import { grantAllPermissions } from './permissions.js';
import { defaultTenantId } from './requestContext.js';
import { DEFAULTS, newSettingsRow } from './settings.js';
import { runAsPlatform } from './tenancy.js';

/*
 * Academies on the platform (SAAS-019): provisioning a new one, and moving one through its lifecycle.
 *
 * Provisioning is one transaction. An academy needs, before its admin can build anything:
 * - the tenant row and its first admin, holding the whole permission catalogue (as `POST /superadmin/admins`
 *   gives one) and recorded as the academy's owner;
 * - its settings, named after the academy and answering to the admin's address;
 * - a level ladder — every course and category sits on a level, and nothing in the app creates levels;
 * - a rank ladder — learners are placed on its first rank at sign-up, and nothing in the app creates ranks;
 * - a default certificate template, which completion certificates print on.
 * A failure at any step rolls every row back. No subscription is started here: a trial or a first purchase
 * goes through the billing flows, which have transactions of their own.
 */

/** The level ladder every academy starts with. Courses are placed on these; the names are the product's. */
export const STARTER_LEVELS = [
  { name: 'Beginner', order: 1, summary: 'No prior study needed' },
  { name: 'Intermediate', order: 2, summary: 'Comfortable with the fundamentals' },
  { name: 'Advanced', order: 3, summary: 'Specialised systems and practice' },
] as const;

/** The rank ladder every academy starts with. A rank's criteria count completed courses. */
export const STARTER_RANKS = [
  { title: 'Rank I · Beginner', order: 1, descriptor: 'Just getting started.', criteria: [] },
  {
    title: 'Rank II · Intermediate',
    order: 2,
    descriptor: 'Reading full charts.',
    criteria: [{ id: 'courses', label: 'Courses completed', current: 0, required: 2 }],
  },
  {
    title: 'Rank III · Advanced',
    order: 3,
    descriptor: 'Specialised systems.',
    criteria: [{ id: 'courses', label: 'Courses completed', current: 0, required: 4 }],
  },
] as const;

export interface ProvisionInput {
  name: string;
  slug: string;
  /** The first admin. A self-serve registration (SAAS-026) arrives with the password already hashed. */
  admin: { name: string; email: string } & ({ password: string } | { passwordHash: string });
}

/** Who provisions: the Super Admin (the request), or the registrant themselves once their email is verified. */
export type ProvisionedBy = { kind: 'platform'; req: Request } | { kind: 'self'; signupId: string };

const SELECT = {
  id: true,
  name: true,
  slug: true,
  status: true,
  statusReason: true,
  statusChangedAt: true,
  ownerUserId: true,
  createdAt: true,
  updatedAt: true,
  owner: { select: { id: true, name: true, email: true } },
  _count: { select: { users: true, courseRows: true, studentRows: true, instructorRows: true } },
  // The latest subscription — live or the last to end — so the platform sees each academy's plan at a glance.
  subscriptionRows: {
    orderBy: { createdAt: 'desc' },
    take: 1,
    select: { id: true, status: true, currentPeriodEndAt: true, trialEndAt: true, plan: { select: { id: true, code: true, name: true } } },
  },
} as const;

type AcademyRow = {
  id: string;
  name: string;
  slug: string;
  status: string;
  statusReason: string | null;
  statusChangedAt: Date | null;
  ownerUserId: string | null;
  createdAt: Date;
  updatedAt: Date;
  owner: { id: string; name: string; email: string } | null;
  _count: { users: number; courseRows: number; studentRows: number; instructorRows: number };
  subscriptionRows?: {
    id: string;
    status: string;
    currentPeriodEndAt: Date;
    trialEndAt: Date | null;
    plan: { id: string; code: string; name: string };
  }[];
};

export const toAcademy = (t: AcademyRow, defaultId?: string) => ({
  id: t.id,
  name: t.name,
  slug: t.slug,
  status: (isAcademyStatus(t.status) ? t.status : 'active') as AcademyStatus,
  ...(t.statusReason ? { statusReason: t.statusReason } : {}),
  ...(t.statusChangedAt ? { statusChangedAt: t.statusChangedAt.toISOString() } : {}),
  ...(t.owner ? { owner: t.owner } : {}),
  ownerUserId: t.ownerUserId ?? undefined,
  // Kept from the original list: every account, and every course.
  accounts: t._count.users,
  courses: t._count.courseRows,
  learners: t._count.studentRows,
  instructors: t._count.instructorRows,
  isDefault: t.id === defaultId,
  // null: the academy has never subscribed — the Super Admin can start one, or its admin a trial.
  subscription: t.subscriptionRows?.[0]
    ? {
        id: t.subscriptionRows[0].id,
        status: t.subscriptionRows[0].status,
        plan: t.subscriptionRows[0].plan,
        currentPeriodEndAt: t.subscriptionRows[0].currentPeriodEndAt.toISOString(),
        ...(t.subscriptionRows[0].trialEndAt ? { trialEndAt: t.subscriptionRows[0].trialEndAt.toISOString() } : {}),
      }
    : null,
  createdAt: t.createdAt.toISOString(),
  updatedAt: t.updatedAt.toISOString(),
});

const platform = <T>(reason: string, fn: () => Promise<T>) => runAsPlatform(reason, fn);

async function assertSlugFree(slug: string, exceptId?: string) {
  const issue = validateAcademySlug(slug);
  if (issue) throw badRequest(issue, [{ field: 'slug', message: issue }]);
  const taken = await db.tenant.findUnique({ where: { slug }, select: { id: true } });
  if (taken && taken.id !== exceptId)
    throw conflict('Another Admin already uses that address.', [{ field: 'slug', message: 'Another Admin already uses that address.' }]);
}

/** Creates an academy with everything it needs to run, in one transaction. */
export async function provisionAcademy(req: Request, input: ProvisionInput) {
  return provision({ kind: 'platform', req }, input);
}

/**
 * The same provisioning for a self-serve registration (SAAS-026): the registrant becomes the academy's owner,
 * and the audit trail names them as the one who acted. No subscription is started (D28).
 */
export async function provisionSelfRegisteredAcademy(signupId: string, input: ProvisionInput) {
  return provision({ kind: 'self', signupId }, input);
}

async function provision(by: ProvisionedBy, input: ProvisionInput) {
  return platform(by.kind === 'self' ? 'a verified registrant provisions their own LMS' : 'the Super Admin provisions an Admin', async () => {
    await assertSlugFree(input.slug);
    // Email is unique across the platform (D2).
    if (await db.user.findUnique({ where: { email: input.admin.email }, select: { id: true } })) {
      throw conflict('An account with this email already exists.', [{ field: 'admin.email', message: 'An account with this email already exists.' }]);
    }
    const passwordHash = 'passwordHash' in input.admin ? input.admin.passwordHash : await hashPassword(input.admin.password);

    const id = await db.$transaction(async (tx) => {
      const academy = await tx.tenant.create({ data: { name: input.name, slug: input.slug }, select: { id: true } });
      const T = { tenantId: academy.id };
      const admin = await tx.user.create({
        data: { ...T, name: input.admin.name, email: input.admin.email, passwordHash, role: 'admin', descriptor: 'Admin' },
        select: { id: true },
      });
      await grantAllPermissions(admin.id, { grantedBy: by.kind === 'platform' ? by.req.auth?.sub : admin.id, client: tx });
      await tx.tenant.update({ where: { id: academy.id }, data: { ownerUserId: admin.id } });

      for (const level of STARTER_LEVELS) await tx.level.create({ data: { ...T, ...level } });
      for (const rank of STARTER_RANKS) {
        await tx.rank.create({ data: { ...T, title: rank.title, order: rank.order, descriptor: rank.descriptor, criteriaJson: writeJson(rank.criteria) } });
      }
      const template = await tx.certificateTemplate.create({
        data: {
          ...T,
          name: 'Standard certificate',
          style: 'classic',
          accent: 'indigo',
          heading: 'Certificate of Completion',
          statement: 'has completed the course of study in',
          signatoriesJson: writeJson([{ name: input.admin.name, title: 'Director' }]),
          showScore: true,
          showHours: true,
          isDefault: true,
        },
        select: { id: true },
      });
      const settings = newSettingsRow({
        ...DEFAULTS,
        general: { ...DEFAULTS.general, academyName: input.name, supportEmail: input.admin.email },
        certificates: { ...DEFAULTS.certificates, defaultTemplateId: template.id },
        notifications: { ...DEFAULTS.notifications, senderName: input.name, replyTo: input.admin.email },
      });
      await tx.settings.create({ data: { ...T, ...settings.data } });

      const meta = { name: input.name, slug: input.slug, adminId: admin.id, adminEmail: input.admin.email };
      if (by.kind === 'platform') {
        await recordAuditLog(by.req, { action: 'academy.created', targetType: 'academy', targetId: academy.id, meta }, tx);
      } else {
        // Nobody was signed in: the registrant, now the academy's owner, is the one who acted.
        await recordAuditLog(
          { type: 'user', auth: { sub: admin.id, role: 'admin', tenantId: academy.id } },
          { action: 'academy.self_registered', targetType: 'academy', targetId: academy.id, meta: { ...meta, signupId: by.signupId } },
          tx,
        );
      }
      return academy.id;
    });
    return getAcademy(id);
  });
}

export async function getAcademy(id: string) {
  return platform('the Super Admin reads an academy', async () => {
    const row = await db.tenant.findUnique({ where: { id }, select: SELECT });
    if (!row) throw notFound('Admin not found.');
    return toAcademy(row, await defaultTenantId());
  });
}

export async function listAcademies(query: { search?: string; status?: AcademyStatus; page: number; pageSize: number }) {
  return platform('the Super Admin lists academies', async () => {
    const where = {
      ...(query.status ? { status: query.status } : {}),
      // A client is found by its academy or by its admin (D26).
      ...(query.search
        ? {
            OR: [
              { name: { contains: query.search } },
              { slug: { contains: query.search } },
              { owner: { is: { name: { contains: query.search } } } },
              { owner: { is: { email: { contains: query.search } } } },
            ],
          }
        : {}),
    };
    const [rows, total, defaultId] = await Promise.all([
      db.tenant.findMany({ where, select: SELECT, orderBy: { createdAt: 'asc' }, skip: (query.page - 1) * query.pageSize, take: query.pageSize }),
      db.tenant.count({ where }),
      defaultTenantId(),
    ]);
    return { rows: rows.map((r) => toAcademy(r, defaultId)), total, page: query.page, pageSize: query.pageSize };
  });
}

/** Renames an academy or moves it to another address. The academy this host serves keeps its address. */
export async function updateAcademy(req: Request, id: string, input: { name?: string; slug?: string }) {
  return platform('the Super Admin updates an academy', async () => {
    const current = await db.tenant.findUnique({ where: { id }, select: { id: true, name: true, slug: true } });
    if (!current) throw notFound('Admin not found.');
    const name = input.name && input.name !== current.name ? input.name : undefined;
    const slug = input.slug && input.slug !== current.slug ? input.slug : undefined;
    if (slug) {
      if (id === (await defaultTenantId())) throw conflict('The LMS this site serves keeps its address; DEFAULT_TENANT_SLUG names it.');
      await assertSlugFree(slug, id);
    }
    if (name || slug) {
      await db.$transaction(async (tx) => {
        await tx.tenant.update({ where: { id }, data: { ...(name ? { name } : {}), ...(slug ? { slug } : {}) } });
        await recordAuditLog(
          req,
          {
            action: 'academy.updated',
            targetType: 'academy',
            targetId: id,
            meta: { ...(name ? { name: { from: current.name, to: name } } : {}), ...(slug ? { slug: { from: current.slug, to: slug } } : {}) },
          },
          tx,
        );
      });
    }
    return getAcademy(id);
  });
}

const LIVE_SUBSCRIPTION = ['trialing', 'active', 'past_due', 'paused', 'canceling'];

/**
 * Suspends, archives or reactivates an academy. The data stays: a suspended or archived academy's members
 * are refused on every request (`lib/requestContext.ts`), and reactivating lets them back in.
 */
export async function changeAcademyStatus(req: Request, id: string, action: AcademyAction, reason?: string) {
  return platform(`the Super Admin changes an academy's status (${action})`, async () => {
    const current = await db.tenant.findUnique({ where: { id }, select: { id: true, status: true } });
    if (!current) throw notFound('Admin not found.');
    const from = isAcademyStatus(current.status) ? current.status : 'active';
    const to = academyTransition(from, action);
    if (!to) throw conflict(`An Admin that is ${from} cannot be ${action === 'reactivate' ? 'reactivated' : `${action}d`}.`);
    if (action !== 'reactivate') {
      // The academy this host serves is what visitors see; closing it would close the public site.
      if (id === (await defaultTenantId())) throw conflict('The LMS this site serves cannot be suspended or archived.');
      if (!reason) throw badRequest('Give a reason — it is recorded in the audit trail.', [{ field: 'reason', message: 'Give a reason.' }]);
    }
    if (action === 'archive' && (await db.subscription.count({ where: { tenantId: id, status: { in: LIVE_SUBSCRIPTION } } }))) {
      // Archiving is closing the academy; its billing contract is ended first, deliberately, through the billing flows.
      throw conflict('Cancel the Admin’s subscription before archiving it.');
    }
    await db.$transaction(async (tx) => {
      await tx.tenant.update({
        where: { id },
        data: { status: to, statusReason: to === 'active' ? null : (reason ?? null), statusChangedAt: new Date() },
      });
      await recordAuditLog(
        req,
        { action: `academy.${to === 'active' ? 'reactivated' : to}`, targetType: 'academy', targetId: id, meta: { from, to, ...(reason ? { reason } : {}) } },
        tx,
      );
    });
    return getAcademy(id);
  });
}
