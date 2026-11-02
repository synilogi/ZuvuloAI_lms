import type { ID, ISODateTime } from './catalog';

export type NotificationCategory = 'course' | 'assignment' | 'quiz' | 'live' | 'certificate' | 'enrollment' | 'system';

export const NOTIFICATION_CATEGORIES: NotificationCategory[] = ['course', 'assignment', 'quiz', 'live', 'certificate', 'enrollment', 'system'];

/** app — the bell and notification centre · email · sms — text messages to the number on the account */
export type NotificationChannel = 'app' | 'email' | 'sms';

export const NOTIFICATION_CHANNELS: NotificationChannel[] = ['app', 'email', 'sms'];

export interface AppNotification {
  id: ID;
  recipientId: ID;
  category: NotificationCategory;
  title: string;
  /** One or two sentences for the list and the bell. */
  summary: string;
  /** Paragraphs for the detail page. */
  body: string[];
  createdAt: ISODateTime;
  readAt?: ISODateTime;
  /** Sent even while notifications are paused, and marked in the list. */
  important?: boolean;
  /** Who caused it, when a person did. */
  actor?: string;
  facts?: { label: string; value: string }[];
  action?: { label: string; to: string };
  secondaryAction?: { label: string; to: string };
}

export interface CategoryPreference {
  category: NotificationCategory;
  channels: Record<NotificationChannel, boolean>;
}

export type EmailDigest = 'instant' | 'daily' | 'weekly';

export interface NotificationSettings {
  categories: CategoryPreference[];
  emailDigest: EmailDigest;
  /** No text messages or pop-ups between these times, IST — HH:MM. */
  quietHours: { enabled: boolean; from: string; to: string };
  /** Until then only important notifications arrive. */
  pausedUntil?: ISODateTime;
}

/** Account and security notices can't be switched off in the app or by email. */
export const LOCKED_CHANNELS: Partial<Record<NotificationCategory, NotificationChannel[]>> = { system: ['app', 'email'] };

export const isLocked = (category: NotificationCategory, channel: NotificationChannel) => LOCKED_CHANNELS[category]?.includes(channel) ?? false;

export interface NotificationSettingsIssue {
  field: 'quietHours' | 'categories';
  message: string;
}

export function validateNotificationSettings(settings: NotificationSettings): NotificationSettingsIssue[] {
  const issues: NotificationSettingsIssue[] = [];
  const time = /^([01]\d|2[0-3]):[0-5]\d$/;
  const { quietHours } = settings;
  if (quietHours.enabled && (!time.test(quietHours.from) || !time.test(quietHours.to)))
    issues.push({ field: 'quietHours', message: 'Choose when quiet hours start and end.' });
  else if (quietHours.enabled && quietHours.from === quietHours.to)
    issues.push({ field: 'quietHours', message: 'Quiet hours need different start and end times.' });
  const locked = settings.categories.some((c) => NOTIFICATION_CHANNELS.some((ch) => isLocked(c.category, ch) && !c.channels[ch]));
  if (locked) issues.push({ field: 'categories', message: 'Account and security notices stay on in the app and by email.' });
  return issues;
}

/** Whether a notification is unread. */
export const isUnread = (n: Pick<AppNotification, 'readAt'>) => !n.readAt;

/* ─── Delivery (SAAS-021) ─────────────────────────────────────────────── */

/** India Standard Time, the academy clock quiet hours are read in. IST has no daylight saving. */
const IST_OFFSET_MIN = 330;

const minutesOf = (hhmm: string) => {
  const [h, m] = hhmm.split(':').map(Number);
  return (h % 24) * 60 + (m % 60);
};

/**
 * When the recipient's quiet hours end, if `now` falls inside them; `null` when it does not or they are off.
 * Quiet hours may run past midnight (22:00 → 07:00). Times are the recipient's, read in IST.
 */
export function quietHoursEnd(quietHours: NotificationSettings['quietHours'] | undefined, now: Date): Date | null {
  if (!quietHours?.enabled || quietHours.from === quietHours.to) return null;
  const from = minutesOf(quietHours.from);
  const to = minutesOf(quietHours.to);
  const local = new Date(now.getTime() + IST_OFFSET_MIN * 60_000);
  const minute = local.getUTCHours() * 60 + local.getUTCMinutes();
  const inside = from < to ? minute >= from && minute < to : minute >= from || minute < to;
  if (!inside) return null;
  const minutesLeft = (to - minute + 1440) % 1440;
  const end = new Date(now.getTime() + minutesLeft * 60_000);
  end.setUTCSeconds(0, 0);
  return end;
}

/** How long a failed delivery waits before its next attempt; its length is the number of attempts. */
export const DELIVERY_BACKOFF_MIN = [1, 5, 30, 120, 720] as const;

/** When attempt `attempts + 1` may run after a failure, or `null` once every attempt is used. */
export function nextDeliveryAttempt(attempts: number, now: Date): Date | null {
  const wait = DELIVERY_BACKOFF_MIN[attempts - 1];
  return wait === undefined ? null : new Date(now.getTime() + wait * 60_000);
}
