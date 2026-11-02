import type { Request } from 'express';
import {
  INQUIRY_KIND_LABEL,
  INQUIRY_STATUSES,
  isInquiryKind,
  isInquiryStatus,
  type Inquiry,
  type InquiryKind,
  type InquiryListResult,
  type InquiryStatus,
  type PublicInquiryInput,
} from '@syniastrolms/domain';

import { recordAuditLog } from './audit.js';
import { db } from './db.js';
import { notFound } from './errors.js';
import { queueEmail } from './mail.js';
import { runAsPlatform, tenant } from './tenancy.js';

/*
 * Requests to the platform team (SAAS-027): what the company website's contact form sends, and — from SAAS-029 — the
 * support requests academy admins raise. Every request lands in the Super Admin's inbox; `SALES_NOTIFY_EMAIL`, when
 * set, is also told by email. A request moves new → in progress → closed and is never deleted (a trigger refuses it).
 */

const SELECT = {
  id: true,
  kind: true,
  status: true,
  name: true,
  email: true,
  organisation: true,
  phone: true,
  size: true,
  subject: true,
  message: true,
  note: true,
  closedAt: true,
  createdAt: true,
  updatedAt: true,
  tenant: { select: { id: true, name: true, slug: true } },
} as const;

type Row = {
  id: string;
  kind: string;
  status: string;
  name: string;
  email: string;
  organisation: string | null;
  phone: string | null;
  size: string | null;
  subject: string | null;
  message: string;
  note: string | null;
  closedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  tenant: { id: string; name: string; slug: string } | null;
};

export const toInquiry = (r: Row): Inquiry => ({
  id: r.id,
  kind: isInquiryKind(r.kind) ? r.kind : 'sales',
  status: isInquiryStatus(r.status) ? r.status : 'new',
  name: r.name,
  email: r.email,
  ...(r.organisation ? { organisation: r.organisation } : {}),
  ...(r.phone ? { phone: r.phone } : {}),
  ...(r.size ? { size: r.size } : {}),
  ...(r.subject ? { subject: r.subject } : {}),
  message: r.message,
  ...(r.tenant ? { academy: r.tenant } : {}),
  ...(r.note ? { note: r.note } : {}),
  ...(r.closedAt ? { closedAt: r.closedAt.toISOString() } : {}),
  createdAt: r.createdAt.toISOString(),
  updatedAt: r.updatedAt.toISOString(),
});

/** Tells the platform team, when an address for it is configured. Never fails the request that raised it. */
async function notifyTeam(inquiry: Inquiry) {
  const to = process.env.SALES_NOTIFY_EMAIL;
  if (!to) return;
  const who = [inquiry.name, inquiry.organisation, inquiry.academy?.name].filter(Boolean).join(' · ');
  await queueEmail({
    to,
    subject: `${INQUIRY_KIND_LABEL[inquiry.kind]}: ${who}`,
    text: `${INQUIRY_KIND_LABEL[inquiry.kind]} from ${who} <${inquiry.email}>${inquiry.phone ? `, ${inquiry.phone}` : ''}\n${inquiry.size ? `Size: ${inquiry.size}\n` : ''}\n${inquiry.message}\n\nOpen the inbox: /superadmin/inquiries`,
    templateKey: 'inquiry-received',
  }).catch(() => undefined);
}

/** A website visitor's request. No academy: it is the platform's. */
export async function createPublicInquiry(input: PublicInquiryInput): Promise<Inquiry> {
  return runAsPlatform('a website visitor contacts the platform team', async () => {
    const row = await db.inquiry.create({
      data: {
        kind: input.kind,
        name: input.name,
        email: input.email,
        organisation: input.organisation || null,
        phone: input.phone || null,
        size: input.size || null,
        message: input.message,
      },
      select: SELECT,
    });
    const inquiry = toInquiry(row);
    await notifyTeam(inquiry);
    return inquiry;
  });
}

export async function listInquiries(query: {
  status?: InquiryStatus;
  kind?: InquiryKind;
  search?: string;
  page: number;
  pageSize: number;
}): Promise<InquiryListResult> {
  const where = {
    ...(query.status ? { status: query.status } : {}),
    ...(query.kind ? { kind: query.kind } : {}),
    ...(query.search
      ? {
          OR: [
            { name: { contains: query.search } },
            { email: { contains: query.search } },
            { organisation: { contains: query.search } },
            { message: { contains: query.search } },
          ],
        }
      : {}),
  };
  const [rows, total, grouped] = await Promise.all([
    db.inquiry.findMany({ where, select: SELECT, orderBy: { createdAt: 'desc' }, skip: (query.page - 1) * query.pageSize, take: query.pageSize }),
    db.inquiry.count({ where }),
    db.inquiry.groupBy({ by: ['status'], _count: { _all: true } }),
  ]);
  const counts = Object.fromEntries(INQUIRY_STATUSES.map((s) => [s, grouped.find((g) => g.status === s)?._count._all ?? 0])) as Record<InquiryStatus, number>;
  return { rows: rows.map(toInquiry), total, page: query.page, pageSize: query.pageSize, counts };
}

/** Moves a request along, with the team's private note. Audited. */
export async function updateInquiry(req: Request, id: string, input: { status?: InquiryStatus; note?: string }): Promise<Inquiry> {
  const current = await db.inquiry.findUnique({ where: { id }, select: { status: true, note: true } });
  if (!current) throw notFound('Request not found.');
  const status = input.status ?? current.status;
  const row = await db.$transaction(async (tx) => {
    const updated = await tx.inquiry.update({
      where: { id },
      data: {
        status,
        ...(input.note !== undefined ? { note: input.note || null } : {}),
        handledById: req.auth?.sub ?? null,
        closedAt: status === 'closed' ? (current.status === 'closed' ? undefined : new Date()) : null,
      },
      select: SELECT,
    });
    await recordAuditLog(
      req,
      {
        action: 'inquiry.updated',
        targetType: 'inquiry',
        targetId: id,
        meta: { status: { from: current.status, to: status }, noted: input.note !== undefined },
      },
      tx,
    );
    return updated;
  });
  return toInquiry(row);
}

/**
 * An academy admin asks the platform team for help (SAAS-029). The academy and the person come from the signed-in
 * session (D3) — the body names only the subject and the message.
 */
export async function createAcademySupportRequest(req: Request, input: { subject: string; message: string }): Promise<Inquiry> {
  const me = await runAsPlatform('an admin raising a support request is named from their own row', () =>
    db.user.findUniqueOrThrow({ where: { id: req.auth!.sub }, select: { id: true, name: true, email: true } }),
  );
  const row = await db.inquiry.create({
    data: { ...tenant(), kind: 'support', name: me.name, email: me.email, subject: input.subject, message: input.message, userId: me.id },
    select: SELECT,
  });
  const inquiry = toInquiry(row);
  await recordAuditLog(req, { action: 'inquiry.created', targetType: 'inquiry', targetId: inquiry.id, meta: { kind: 'support' } });
  await notifyTeam(inquiry);
  return inquiry;
}

/** The academy's own requests, newest first — its admins see each other's, never another academy's. The team's note stays private. */
export async function listAcademySupportRequests(): Promise<Inquiry[]> {
  const rows = await db.inquiry.findMany({ select: SELECT, orderBy: { createdAt: 'desc' }, take: 50 });
  return rows.map((r) => {
    const { note: _note, ...rest } = toInquiry(r);
    void _note;
    return rest;
  });
}
