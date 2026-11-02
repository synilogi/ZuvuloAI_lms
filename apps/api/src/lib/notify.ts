import { NOTIFICATION_CATEGORIES, type CategoryPreference, type NotificationCategory, type NotificationChannel } from '@syniastrolms/domain';

import { db } from './db.js';
import { runAsPlatform } from './tenancy.js';
import { readJson, writeJson } from './json.js';
import { APP_URL, queueEmail } from './mail.js';
import { queuePush } from './push.js';
import { getSettings } from './settings.js';

/**
 * The notification engine. Every module that needs to tell someone something calls `notify()`:
 *  - the recipient's per-category channel preferences, pause and email digest are honoured;
 *  - the academy's switches (`settings.notifications`) can turn a kind of message off for everyone;
 *  - `system` notices are always delivered in the app and by email;
 *  - emails go to the outbox now (`instant`) or wait for the daily/weekly digest job.
 * There is no SMS transport in this deployment; the `sms` preference is stored for the UI only.
 */
export interface NotifyInput {
  recipientUserId: string;
  category: NotificationCategory;
  title: string;
  /** One or two sentences for the list and the bell. */
  summary: string;
  /** Paragraphs for the detail page. */
  body?: string[];
  /** Delivered even while the recipient has paused notifications. */
  important?: boolean;
  actor?: string;
  facts?: { label: string; value: string }[];
  action?: { label: string; to: string };
  secondaryAction?: { label: string; to: string };
  /** Which channels the sender wants; the recipient's preferences can still switch one off. */
  channels?: { app?: boolean; email?: boolean };
  /** The academy switch that governs this kind of message, e.g. `learner.enrolmentConfirmation`. */
  switch?: AcademySwitch;
}

export type AcademySwitch =
  | 'learner.enrolmentConfirmation'
  | 'learner.weeklyDigest'
  | 'learner.inactivityNudge'
  | 'learner.certificateIssued'
  | 'staff.newSubmission'
  | 'staff.reviewOverdue'
  | 'staff.dailyEnrolments'
  | 'staff.courseReview';

export interface NotifyResult {
  app: boolean;
  email: boolean;
  /** The email waits for the recipient's digest instead of going out now. */
  digest: boolean;
}

const DEFAULT_PREFERENCE = { app: true, email: true, sms: false };

/** The channels a category reaches a recipient on, as their preferences and the locked rules decide. */
export async function channelsFor(userId: string, category: NotificationCategory): Promise<Record<NotificationChannel, boolean>> {
  const row = await db.notificationSettings.findUnique({ where: { userId } });
  const categories = row ? readJson<CategoryPreference[]>(row.categoriesJson, []) : [];
  const pref = categories.find((c) => c.category === category)?.channels ?? DEFAULT_PREFERENCE;
  const locked = category === 'system';
  const { notifications } = await getSettings();
  return { app: locked || pref.app, email: locked || pref.email, sms: !locked && pref.sms && notifications.smsEnabled && !!row?.smsNumber };
}

async function switchOn(name: AcademySwitch | undefined): Promise<boolean> {
  if (!name) return true;
  const { notifications } = await getSettings();
  const [group, key] = name.split('.') as ['learner' | 'staff', string];
  const value = (notifications[group] as Record<string, unknown>)[key];
  return value !== false;
}

export async function notify(input: NotifyInput): Promise<NotifyResult> {
  if (!NOTIFICATION_CATEGORIES.includes(input.category)) throw new Error(`Unknown notification category ${input.category}`);
  const none: NotifyResult = { app: false, email: false, digest: false };
  if (!(await switchOn(input.switch))) return none;
  // The platform's owner has no tenant, so the workspace's scope cannot see the account (docs/16, D-PLAT-03).
  const user =
    (await db.user.findUnique({ where: { id: input.recipientUserId }, select: { email: true, name: true } })) ??
    (await runAsPlatform('the platform owner is told of workspace events', () =>
      db.user.findFirst({ where: { id: input.recipientUserId, role: 'superadmin' }, select: { email: true, name: true } }),
    ));
  if (!user) return none;

  const settingsRow = await db.notificationSettings.findUnique({ where: { userId: input.recipientUserId } });
  const channels = await channelsFor(input.recipientUserId, input.category);
  const paused = settingsRow?.pausedUntil ? settingsRow.pausedUntil > new Date() : false;
  const blocked = paused && !input.important;
  const wantApp = input.channels?.app !== false;
  const wantEmail = input.channels?.email !== false;
  const digestMode = input.category !== 'system' && (settingsRow?.emailDigest === 'daily' || settingsRow?.emailDigest === 'weekly');
  const result: NotifyResult = {
    app: wantApp && channels.app && !blocked,
    email: wantEmail && channels.email && !blocked && !digestMode,
    digest: wantEmail && channels.email && !blocked && digestMode,
  };

  if (result.app || result.digest) {
    const created = await db.appNotification.create({
      data: {
        recipientId: input.recipientUserId,
        category: input.category,
        title: input.title,
        summary: input.summary,
        bodyJson: writeJson(input.body ?? [input.summary]),
        important: input.important ?? false,
        actor: input.actor,
        factsJson: input.facts ? writeJson(input.facts) : null,
        actionJson: input.action ? writeJson(input.action) : null,
        secondaryActionJson: input.secondaryAction ? writeJson(input.secondaryAction) : null,
      },
      select: { id: true },
    });
    // A push hint follows the in-app channel: on a phone, the app is where in-app notifications live (SAAS-021).
    if (result.app) {
      await queuePush({
        userId: input.recipientUserId,
        notificationId: created.id,
        important: input.important ?? false,
        quietHoursJson: settingsRow?.quietHoursJson,
      });
    }
  }
  if (result.email) {
    const lines = [`Hi ${user.name.split(' ')[0]},`, '', input.summary, ...(input.body ?? []).filter((p) => p !== input.summary).flatMap((p) => ['', p])];
    if (input.facts?.length) lines.push('', ...input.facts.map((f) => `${f.label}: ${f.value}`));
    if (input.action) lines.push('', `${input.action.label}: ${APP_URL}${input.action.to}`);
    if (input.actor) lines.push('', `— ${input.actor}`);
    await queueEmail({ to: user.email, name: user.name, subject: input.title, text: lines.join('\n'), templateKey: `notification-${input.category}` });
  }
  return result;
}

/** Sends the same notification to several accounts; returns how many received it on any channel. */
export async function notifyMany(recipientUserIds: string[], input: Omit<NotifyInput, 'recipientUserId'>): Promise<number> {
  let delivered = 0;
  for (const recipientUserId of new Set(recipientUserIds)) {
    const r = await notify({ ...input, recipientUserId });
    if (r.app || r.email || r.digest) delivered++;
  }
  return delivered;
}

/** Sign-in accounts of everyone teaching a course. */
export async function instructorUserIdsFor(courseId: string): Promise<string[]> {
  const links = await db.courseInstructor.findMany({ where: { courseId }, select: { instructorId: true } });
  const users = await db.user.findMany({ where: { instructorId: { in: links.map((l) => l.instructorId) } }, select: { id: true } });
  return users.map((u) => u.id);
}

/** Every admin account. */
export async function adminUserIds(): Promise<string[]> {
  const [admins, owners] = await Promise.all([
    db.user.findMany({ where: { role: 'admin' }, select: { id: true } }),
    runAsPlatform('the platform owner is told of workspace events', () =>
      db.user.findMany({ where: { role: 'superadmin', deactivatedAt: null }, select: { id: true } }),
    ),
  ]);
  return [...admins, ...owners].map((u) => u.id);
}
