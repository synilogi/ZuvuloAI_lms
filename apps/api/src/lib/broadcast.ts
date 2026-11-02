import { randomUUID } from 'node:crypto';
import type { Prisma } from '@prisma/client';
import type { Request } from 'express';
import type { BroadcastAudience, BroadcastHistoryRow, BroadcastInput, BroadcastResult } from '@syniastrolms/domain';

import { recordAuditLog } from './audit.js';
import { db } from './db.js';
import { readJson } from './json.js';
import { notify } from './notify.js';
import { observe } from './observe.js';
import { workspaceId } from './requestContext.js';
import { runAsPlatform, runInTenant } from './tenancy.js';

/*
 * The Super Admin's broadcast (docs/05). The `/superadmin` router runs as the platform, which would reach the accounts
 * of academies closed in the conversion and cannot read the workspace's notification settings, so all of this runs in
 * the workspace. The platform's owners belong to no academy and are added by name.
 *
 * An audience is the accounts that can sign in, by the rules `closedReason` (lib/requestContext.ts) applies: no
 * deactivated or deleted account, no suspended learner, no instructor pending, refused or inactive. "Staff" is the
 * admins and the owners; instructors are their own audience.
 *
 * Messages use the `system` category through `notify`, one recipient at a time, in batches with no transaction open. The
 * category's existing rule applies: `system` is locked on in every person's preferences and never waits for a digest. A
 * person's pause is honoured, because a broadcast is not marked important.
 */

const BATCH_SIZE = 100;

export const BROADCAST_AUDIT = { started: 'notification.broadcast.started', sent: 'notification.broadcast.sent' } as const;

const STUDENTS: Prisma.UserWhereInput = { role: 'student', deactivatedAt: null, student: { is: { suspended: false } } };
const INSTRUCTORS: Prisma.UserWhereInput = {
  role: 'instructor',
  deactivatedAt: null,
  instructor: { is: { status: { notIn: ['inactive', 'pending', 'rejected'] } } },
};
const ADMINS: Prisma.UserWhereInput = { role: 'admin', deactivatedAt: null };

const WORKSPACE_ACCOUNTS: Record<BroadcastAudience, Prisma.UserWhereInput> = {
  all: { OR: [STUDENTS, INSTRUCTORS, ADMINS] },
  students: STUDENTS,
  instructors: INSTRUCTORS,
  staff: ADMINS,
};

const includesOwners = (audience: BroadcastAudience) => audience === 'all' || audience === 'staff';

const owners = () =>
  runAsPlatform('a broadcast reaches the platform owners, who belong to no academy', () =>
    db.user.findMany({ where: { role: 'superadmin', deactivatedAt: null }, select: { id: true }, orderBy: { id: 'asc' } }),
  );

/** How many people a broadcast to this audience reaches. */
export async function broadcastAudienceCount(audience: BroadcastAudience): Promise<number> {
  const inWorkspace = await runInTenant(await workspaceId(), () => db.user.count({ where: WORKSPACE_ACCOUNTS[audience] }));
  return inWorkspace + (includesOwners(audience) ? (await owners()).length : 0);
}

/** Sends one batch. A failure for one person is counted and the rest still go. */
async function sendBatch(ids: string[], message: { title: string; summary: string }, tally: { delivered: number; failed: number }) {
  for (const recipientUserId of ids) {
    try {
      const sent = await notify({ recipientUserId, category: 'system', title: message.title, summary: message.summary });
      if (sent.app || sent.email || sent.digest) tally.delivered += 1;
    } catch (err) {
      tally.failed += 1;
      observe('job.failed', { job: 'notification-broadcast', recipientUserId, error: err instanceof Error ? err.message : String(err) });
    }
  }
}

/**
 * Sends a broadcast. Two audit rows, because no transaction can span the sending: one before the first message, so a
 * crash part-way still leaves a record that it began, and one after, with the counts.
 */
export async function sendBroadcast(req: Request, input: BroadcastInput): Promise<BroadcastResult> {
  const workspace = await workspaceId();
  const id = randomUUID();
  const { audience, title, summary } = input;
  const recipients = await broadcastAudienceCount(audience);
  await recordAuditLog(req, { action: BROADCAST_AUDIT.started, targetType: 'broadcast', targetId: id, meta: { audience, title, summary, recipients } });

  const tally = { delivered: 0, failed: 0 };
  let attempted = 0;
  await runInTenant(workspace, async () => {
    let after: string | undefined;
    for (;;) {
      const batch = await db.user.findMany({
        where: { AND: [WORKSPACE_ACCOUNTS[audience], ...(after ? [{ id: { gt: after } }] : [])] },
        select: { id: true },
        orderBy: { id: 'asc' },
        take: BATCH_SIZE,
      });
      if (batch.length === 0) break;
      await sendBatch(
        batch.map((u) => u.id),
        { title, summary },
        tally,
      );
      attempted += batch.length;
      after = batch[batch.length - 1].id;
      if (batch.length < BATCH_SIZE) break;
    }
    if (includesOwners(audience)) {
      const ownerIds = (await owners()).map((u) => u.id);
      await sendBatch(ownerIds, { title, summary }, tally);
      attempted += ownerIds.length;
    }
  });

  await recordAuditLog(req, { action: BROADCAST_AUDIT.sent, targetType: 'broadcast', targetId: id, meta: { audience, recipients: attempted, ...tally } });
  return { id, audience, recipients: attempted, ...tally };
}

interface BroadcastMeta {
  audience: BroadcastAudience;
  title: string;
  summary: string;
  recipients: number;
  delivered?: number;
  failed?: number;
}

/** The history, newest first, from the audit log: one row per broadcast begun, with the counts of its closing record. */
export async function broadcastHistory(
  page: number,
  pageSize: number,
): Promise<{ rows: BroadcastHistoryRow[]; total: number; page: number; pageSize: number }> {
  const where = { action: BROADCAST_AUDIT.started };
  const [started, total] = await Promise.all([
    db.auditLog.findMany({ where, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], skip: (page - 1) * pageSize, take: pageSize }),
    db.auditLog.count({ where }),
  ]);
  const finished = await db.auditLog.findMany({
    where: { action: BROADCAST_AUDIT.sent, targetId: { in: started.flatMap((s) => (s.targetId ? [s.targetId] : [])) } },
  });
  const closing = new Map(finished.map((f) => [f.targetId, readJson<Partial<BroadcastMeta>>(f.metaJson, {})]));
  const rows = started.map((s): BroadcastHistoryRow => {
    const meta = readJson<BroadcastMeta>(s.metaJson, { audience: 'all', title: '', summary: '', recipients: 0 });
    const end = closing.get(s.targetId);
    return {
      id: s.targetId ?? s.id,
      audience: meta.audience,
      title: meta.title,
      summary: meta.summary,
      recipients: end?.recipients ?? meta.recipients,
      ...(end ? { delivered: end.delivered ?? 0, failed: end.failed ?? 0 } : {}),
      state: end ? 'sent' : 'unfinished',
      sentBy: s.actorEmail,
      createdAt: s.createdAt.toISOString(),
    };
  });
  return { rows, total, page, pageSize };
}
