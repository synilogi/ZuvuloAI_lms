import { createHash } from 'node:crypto';

import { db } from './db.js';
import { getSettings } from './settings.js';
import { currentContext } from './tenancy.js';

/**
 * Outgoing email. Every message is written to the `EmailOutbox` table (the source of truth and the
 * audit trail); `MAIL_TRANSPORT` decides what happens next:
 *   - `outbox` (default): rows stay `queued` for an external sender / operator to drain.
 *   - `log`: the message is also printed to the server log (handy in development); in production
 *     only its envelope, never a body that may carry a one-time link.
 * An SMTP transport can be plugged in here later without touching the callers.
 */
export interface OutgoingEmail {
  to: string;
  name?: string;
  subject: string;
  text: string;
  /** Stable key naming the message kind, e.g. `password-reset`, `instructor-invite`. */
  templateKey: string;
}

export const APP_URL = (process.env.APP_URL ?? process.env.CORS_ORIGIN ?? 'http://localhost:5173').replace(/\/$/, '');

/** How the platform signs its own email — a super admin belongs to no academy, so no academy's name fits. */
const PLATFORM_IDENTITY = { senderName: 'ZuviloAI', replyTo: process.env.PLATFORM_REPLY_TO ?? '' };

/** The academy's sender identity (`settings.notifications`), for transports and the email footer. */
export async function mailIdentity() {
  if (currentContext()?.kind !== 'tenant') return PLATFORM_IDENTITY;
  const { notifications, general } = await getSettings();
  return { senderName: notifications.senderName || general.academyName, replyTo: notifications.replyTo || general.supportEmail };
}

/** How long the same message to the same address is not queued again (SAAS-021). */
export const EMAIL_DEDUP_WINDOW_MS = 10 * 60_000;

/** The message's identity for deduplication: the address, subject and body, hashed. */
const dedupKeyOf = (to: string, subject: string, text: string) => createHash('sha256').update(`${to}\n${subject}\n${text}`).digest('hex');

export async function queueEmail(message: OutgoingEmail): Promise<{ id: string }> {
  const identity = await mailIdentity();
  const text = `${message.text}\n\n—\n${identity.senderName}${identity.replyTo ? ` · reply to ${identity.replyTo}` : ''}`;
  // A repeat of the same message within the window — a double submit, a job retried — is the message already queued.
  const dedupKey = dedupKeyOf(message.to, message.subject, text);
  const repeat = await db.emailOutbox.findFirst({
    where: { dedupKey, toEmail: message.to, status: { not: 'failed' }, createdAt: { gte: new Date(Date.now() - EMAIL_DEDUP_WINDOW_MS) } },
    select: { id: true },
  });
  if (repeat) return repeat;
  const row = await db.emailOutbox.create({
    data: { toEmail: message.to, toName: message.name, subject: message.subject, text, templateKey: message.templateKey, dedupKey },
    select: { id: true },
  });
  if (process.env.MAIL_TRANSPORT === 'log') {
    // The body can carry a one-time link (a password reset, an invitation). In development it is printed
    // so the developer can follow it; in production only the envelope is, never the link (§48).
    const body = process.env.NODE_ENV === 'production' ? '' : `\n${text}`;
    console.log(`[mail] to=${message.to} subject="${message.subject}" template=${message.templateKey}${body}`);
  }
  return row;
}
