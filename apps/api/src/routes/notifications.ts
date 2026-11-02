import { Router } from 'express';
import {
  validateNotificationSettings,
  NOTIFICATION_CATEGORIES,
  type AppNotification,
  type NotificationCategory,
  type NotificationSettings,
  type CategoryPreference,
} from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { asyncHandler, conflict, notFound } from '../lib/errors.js';
import { requireAuth } from '../lib/auth.js';
import { runAsPlatform } from '../lib/tenancy.js';
import { requireUser } from '../lib/scope.js';
import { channelsFor } from '../lib/notify.js';
import { id, parseBody, parseQuery, queryBool, queryInt, z } from '../lib/validate.js';
import { readJson, writeJson } from '../lib/json.js';

export const notificationsRouter = Router();

function mapNotification(row: {
  id: string;
  recipientId: string;
  category: string;
  title: string;
  summary: string;
  bodyJson: string;
  createdAt: Date;
  readAt: Date | null;
  important: boolean;
  actor: string | null;
  factsJson: string | null;
  actionJson: string | null;
  secondaryActionJson: string | null;
}): AppNotification {
  return {
    id: row.id,
    recipientId: row.recipientId,
    category: row.category as NotificationCategory,
    title: row.title,
    summary: row.summary,
    body: readJson<string[]>(row.bodyJson, []),
    createdAt: row.createdAt.toISOString(),
    readAt: row.readAt?.toISOString(),
    important: row.important || undefined,
    actor: row.actor ?? undefined,
    facts: readJson(row.factsJson, undefined),
    action: readJson(row.actionJson, undefined),
    secondaryAction: readJson(row.secondaryActionJson, undefined),
  };
}

const categorySchema = z.enum(NOTIFICATION_CATEGORIES);
const listQuery = z.object({ unreadOnly: queryBool, category: categorySchema.optional(), limit: queryInt(1, 200, 50) });
const idsSchema = z.object({ ids: z.array(id).min(1).max(500) });

notificationsRouter.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    // The recipient is always the signed-in account; a `recipientId` in the query is ignored.
    const recipientId = requireUser(req);
    const { unreadOnly, category, limit } = parseQuery(req, listQuery);
    const all = await db.appNotification.findMany({ where: { recipientId }, orderBy: { createdAt: 'desc' } });
    const unread = all.filter((n) => !n.readAt).length;

    let rows = all;
    if (category) rows = rows.filter((n) => n.category === category);
    const counts: Record<NotificationCategory, number> = { course: 0, assignment: 0, quiz: 0, live: 0, certificate: 0, enrollment: 0, system: 0 };
    for (const n of rows.filter((n) => !n.readAt)) counts[n.category as NotificationCategory]++;

    if (unreadOnly) rows = rows.filter((n) => !n.readAt);
    const total = rows.length;
    res.json({ rows: rows.slice(0, limit).map(mapNotification), total, unread, counts });
  }),
);

/* ─── Devices for push (SAAS-021) ─────────────────────────────────────
 *
 * Registered before `/:id` so `devices` is never read as a notification id. A device token belongs to one
 * account at a time: registering it again, from any account, moves it — the device changed hands. It is
 * bound to the session that registered it, and ending that session removes it.
 */

const deviceSchema = z.object({ token: z.string().trim().min(20).max(4096), platform: z.enum(['android', 'ios', 'web']) });

const deviceView = (d: { id: string; platform: string; token: string; sessionId: string | null; createdAt: Date; lastSeenAt: Date }, sid?: string) => ({
  id: d.id,
  platform: d.platform,
  // Enough to tell devices apart; the token itself is a credential for the device and is not echoed back.
  tokenEnd: d.token.slice(-8),
  current: !!sid && d.sessionId === sid,
  createdAt: d.createdAt.toISOString(),
  lastSeenAt: d.lastSeenAt.toISOString(),
});

notificationsRouter.post(
  '/devices',
  requireAuth,
  asyncHandler(async (req, res) => {
    const userId = requireUser(req);
    const input = parseBody(req, deviceSchema);
    const owner = await runAsPlatform('reading the signed-in account, to bind its device', () =>
      db.user.findUniqueOrThrow({ where: { id: userId }, select: { tenantId: true } }),
    );
    // Across academies: the token may still be registered to whoever held the device before.
    const row = await runAsPlatform('a device token is unique across the platform', () =>
      db.$transaction(async (tx) => {
        const existing = await tx.deviceToken.findUnique({ where: { token: input.token } });
        if (existing && existing.userId === userId) {
          return tx.deviceToken.update({
            where: { id: existing.id },
            data: { platform: input.platform, sessionId: req.auth!.sid ?? null, lastSeenAt: new Date() },
          });
        }
        if (existing) await tx.deviceToken.delete({ where: { id: existing.id } });
        return tx.deviceToken.create({
          data: { tenantId: owner.tenantId, userId, sessionId: req.auth!.sid ?? null, platform: input.platform, token: input.token },
        });
      }),
    );
    res.status(201).json(deviceView(row, req.auth!.sid));
  }),
);

notificationsRouter.get(
  '/devices',
  requireAuth,
  asyncHandler(async (req, res) => {
    const userId = requireUser(req);
    const rows = await db.deviceToken.findMany({ where: { userId }, orderBy: { lastSeenAt: 'desc' } });
    res.json({ devices: rows.map((d) => deviceView(d, req.auth!.sid)) });
  }),
);

notificationsRouter.delete(
  '/devices/:deviceId',
  requireAuth,
  asyncHandler(async (req, res) => {
    const userId = requireUser(req);
    const { count } = await db.deviceToken.deleteMany({ where: { id: req.params.deviceId, userId } });
    if (!count) throw notFound('Device not found.');
    res.status(204).end();
  }),
);

notificationsRouter.get(
  '/:id',
  requireAuth,
  asyncHandler(async (req, res) => {
    const recipientId = requireUser(req);
    const row = await db.appNotification.findFirst({ where: { id: req.params.id, recipientId } });
    if (!row) throw notFound('Notification not found.');
    if (!row.readAt) await db.appNotification.update({ where: { id: row.id }, data: { readAt: new Date() } });
    const related = await db.appNotification.findMany({
      where: { recipientId, category: row.category, id: { not: row.id } },
      orderBy: { createdAt: 'desc' },
      take: 3,
    });
    res.json({
      notification: mapNotification({ ...row, readAt: row.readAt ?? new Date() }),
      related: related.map(mapNotification),
      channels: await channelsFor(recipientId, row.category as NotificationCategory),
    });
  }),
);

notificationsRouter.post(
  '/read',
  requireAuth,
  asyncHandler(async (req, res) => {
    const recipientId = requireUser(req);
    const { ids, read } = parseBody(req, idsSchema.extend({ read: z.boolean() }));
    await db.appNotification.updateMany({ where: { id: { in: ids }, recipientId }, data: { readAt: read ? new Date() : null } });
    res.status(204).end();
  }),
);

notificationsRouter.post(
  '/read-all',
  requireAuth,
  asyncHandler(async (req, res) => {
    const recipientId = requireUser(req);
    const { category } = parseBody(req, z.object({ category: categorySchema.optional() }));
    const result = await db.appNotification.updateMany({
      where: { recipientId, readAt: null, ...(category ? { category } : {}) },
      data: { readAt: new Date() },
    });
    res.json(result.count);
  }),
);

notificationsRouter.post(
  '/remove',
  requireAuth,
  asyncHandler(async (req, res) => {
    const recipientId = requireUser(req);
    const { ids } = parseBody(req, idsSchema);
    await db.appNotification.deleteMany({ where: { id: { in: ids }, recipientId } });
    res.status(204).end();
  }),
);

const restoreSchema = z.object({
  id,
  category: categorySchema,
  title: z.string().max(200),
  summary: z.string().max(1000),
  body: z.array(z.string().max(4000)).max(50).optional(),
  createdAt: z.string(),
  readAt: z.string().optional(),
  important: z.boolean().optional(),
  actor: z.string().max(200).optional(),
  facts: z.unknown().optional(),
  action: z.unknown().optional(),
  secondaryAction: z.unknown().optional(),
});

notificationsRouter.post(
  '/restore',
  requireAuth,
  asyncHandler(async (req, res) => {
    const recipientId = requireUser(req);
    const { notifications } = parseBody(req, z.object({ notifications: z.array(restoreSchema).min(1).max(100) }));
    await db.appNotification.createMany({
      data: notifications.map((n) => ({
        id: n.id,
        recipientId,
        category: n.category,
        title: n.title,
        summary: n.summary,
        bodyJson: writeJson(n.body),
        createdAt: new Date(n.createdAt),
        readAt: n.readAt ? new Date(n.readAt) : null,
        important: n.important ?? false,
        actor: n.actor,
        factsJson: writeJson(n.facts),
        actionJson: writeJson(n.action),
        secondaryActionJson: writeJson(n.secondaryAction),
      })),
    });
    res.status(204).end();
  }),
);

notificationsRouter.post(
  '/clear',
  requireAuth,
  asyncHandler(async (req, res) => {
    const recipientId = requireUser(req);
    const { category, unreadOnly } = parseBody(req, z.object({ category: categorySchema.optional(), unreadOnly: z.boolean().optional() }));
    const result = await db.appNotification.deleteMany({ where: { recipientId, ...(category ? { category } : {}), ...(unreadOnly ? { readAt: null } : {}) } });
    res.json(result.count);
  }),
);

function defaultSettings(): NotificationSettings {
  return {
    categories: NOTIFICATION_CATEGORIES.map((category) => ({ category, channels: { app: true, email: true, sms: false } })),
    emailDigest: 'instant',
    quietHours: { enabled: false, from: '22:00', to: '07:00' },
  };
}

notificationsRouter.get(
  '/settings/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    const row = await db.notificationSettings.findUnique({ where: { userId: requireUser(req) } });
    if (!row) return res.json({ ...defaultSettings(), smsNumber: '' });
    res.json({
      categories: readJson<CategoryPreference[]>(row.categoriesJson, defaultSettings().categories),
      emailDigest: row.emailDigest as NotificationSettings['emailDigest'],
      quietHours: readJson(row.quietHoursJson, defaultSettings().quietHours),
      pausedUntil: row.pausedUntil?.toISOString(),
      smsNumber: row.smsNumber,
    });
  }),
);

const settingsSchema = z.object({
  categories: z.array(z.object({ category: categorySchema, channels: z.object({ app: z.boolean(), email: z.boolean(), sms: z.boolean() }) })).max(20),
  emailDigest: z.enum(['instant', 'daily', 'weekly', 'off']),
  quietHours: z.object({ enabled: z.boolean(), from: z.string().max(5), to: z.string().max(5) }),
  pausedUntil: z.string().optional(),
  smsNumber: z.string().max(20).optional(),
});

notificationsRouter.put(
  '/settings/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    const userId = requireUser(req);
    const settings = parseBody(req, settingsSchema) as NotificationSettings & { smsNumber?: string };
    const issues = validateNotificationSettings(settings);
    if (issues.length) throw conflict('Check your notification settings.', issues);
    const row = await db.notificationSettings.upsert({
      where: { userId },
      update: {
        categoriesJson: writeJson(settings.categories),
        emailDigest: settings.emailDigest,
        quietHoursJson: writeJson(settings.quietHours),
        pausedUntil: settings.pausedUntil ? new Date(settings.pausedUntil) : null,
        smsNumber: settings.smsNumber ?? '',
      },
      create: {
        userId,
        categoriesJson: writeJson(settings.categories),
        emailDigest: settings.emailDigest,
        quietHoursJson: writeJson(settings.quietHours),
        pausedUntil: settings.pausedUntil ? new Date(settings.pausedUntil) : null,
        smsNumber: settings.smsNumber ?? '',
      },
    });
    res.json({
      categories: readJson(row.categoriesJson, []),
      emailDigest: row.emailDigest,
      quietHours: readJson(row.quietHoursJson, {}),
      pausedUntil: row.pausedUntil?.toISOString(),
    });
  }),
);
