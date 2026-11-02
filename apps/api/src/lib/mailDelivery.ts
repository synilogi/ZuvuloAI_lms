import nodemailer from 'nodemailer';
import { nextDeliveryAttempt } from '@syniastrolms/domain';

import { db } from './db.js';
import { describeError } from './observe.js';
import { runAsPlatform } from './tenancy.js';

/*
 * Email delivery (SAAS-021). `queueEmail` writes the outbox; this worker hands each queued message to the
 * configured transport. A message is claimed by a conditional update, so two schedulers never send it twice;
 * a failure is retried on the backoff schedule (`DELIVERY_BACKOFF_MIN`) and ends as `failed` with its reason
 * once the attempts are used; a message left `sending` by a process that died is claimed again.
 *
 * Transports (`MAIL_TRANSPORT`): `outbox` (the default) stores and never sends — no delivery happens and the
 * worker does not run; `log` is for development, where `queueEmail` has already printed the message; `smtp`
 * delivers through any SMTP relay (SAAS-026).
 */

export interface OutgoingMessage {
  to: string;
  toName?: string | null;
  subject: string;
  text: string;
}

export interface MailTransport {
  readonly name: string;
  /** False for a transport that only stores: the worker leaves the outbox alone. */
  readonly delivers: boolean;
  send(message: OutgoingMessage): Promise<{ messageId?: string }>;
}

const outbox: MailTransport = {
  name: 'outbox',
  delivers: false,
  send: async () => {
    throw new Error('The outbox transport does not send.');
  },
};

/** Development: the message was printed when it was queued (`lib/mail.ts`), so delivering it is recording that. */
const log: MailTransport = { name: 'log', delivers: true, send: async () => ({}) };

/**
 * Production (SAAS-026): any SMTP relay — the provider's SMTP endpoint (SES, SendGrid, Postmark, Zoho, Google
 * Workspace…). `SMTP_HOST`, `SMTP_PORT` (587 STARTTLS by default; 465 is implicit TLS), `SMTP_USER`, `SMTP_PASS`,
 * and `MAIL_FROM` (the platform's sending address). The password is read from the environment only, never logged.
 */
export function smtpTransport(env: NodeJS.ProcessEnv = process.env): MailTransport {
  const port = Number(env.SMTP_PORT ?? 587);
  const transporter = nodemailer.createTransport({
    host: env.SMTP_HOST,
    port,
    secure: port === 465,
    auth: env.SMTP_USER ? { user: env.SMTP_USER, pass: env.SMTP_PASS ?? '' } : undefined,
  });
  const from = env.MAIL_FROM ?? env.SMTP_USER ?? '';
  return {
    name: 'smtp',
    delivers: true,
    send: async (message) => {
      const info = await transporter.sendMail({
        from,
        to: message.toName ? { name: message.toName, address: message.to } : message.to,
        subject: message.subject,
        text: message.text,
      });
      return { messageId: info.messageId };
    },
  };
}

/** Refuses to start with `MAIL_TRANSPORT=smtp` and no relay or sender configured. Called once at boot. */
export function assertMailConfig(env: NodeJS.ProcessEnv = process.env): void {
  if (env.MAIL_TRANSPORT !== 'smtp') return;
  const missing = ['SMTP_HOST', 'MAIL_FROM'].filter((k) => !env[k]);
  if (missing.length) throw new Error(`MAIL_TRANSPORT=smtp needs ${missing.join(' and ')}.`);
}

let override: MailTransport | null = null;
let smtp: MailTransport | null = null;

/** The transport in use: a test's, else the one `MAIL_TRANSPORT` names. An unknown name stores only. */
export const mailTransport = (): MailTransport => {
  if (override) return override;
  if (process.env.MAIL_TRANSPORT === 'log') return log;
  if (process.env.MAIL_TRANSPORT === 'smtp') return (smtp ??= smtpTransport());
  return outbox;
};

/** Installs a transport (tests), or goes back to the configured one with `null`. */
export const setMailTransport = (transport: MailTransport | null) => {
  override = transport;
};

/** How long a message may stay `sending` before it is taken to have been abandoned. */
const STALE_SENDING_MS = 10 * 60_000;
const BATCH = 50;
/** How long one tick may spend delivering, so the scheduler's other work is never starved. */
const TICK_BUDGET_MS = 20_000;
/**
 * Messages someone is waiting on — a code that expires in 15 minutes, a reset or set-up link — go before everything
 * else in a tick, so a backlog of notifications and digests never holds them up.
 */
export const URGENT_TEMPLATES = [
  'account-verification',
  'signup-verification',
  'password-reset',
  'instructor-invite',
  'learner-invite',
  'learner-invitation',
] as const;

export interface DeliveryRun {
  sent: number;
  retried: number;
  failed: number;
}

/** Sends what is due. Idempotent and safe to run from several processes at once. */
export async function deliverQueuedEmail(now = new Date()): Promise<DeliveryRun> {
  const run: DeliveryRun = { sent: 0, retried: 0, failed: 0 };
  const transport = mailTransport();
  if (!transport.delivers) return run;
  return runAsPlatform('the email worker delivers the outbox of every academy', async () => {
    // A message a dead process left mid-send goes back in the queue; its attempt still counts.
    await db.emailOutbox.updateMany({
      where: { status: 'sending', lastAttemptAt: { lt: new Date(now.getTime() - STALE_SENDING_MS) } },
      data: { status: 'queued' },
    });
    // Batch after batch until nothing is due or the tick's budget is spent: a backlog (an outage, a transport
    // switched on) drains in minutes rather than fifty a minute.
    const started = Date.now();
    // The urgent messages first, then the rest; each pass oldest first.
    const urgent = [...URGENT_TEMPLATES];
    for (const templateKey of [{ in: urgent }, { notIn: urgent }]) {
      // A cursor over (createdAt, id): each batch continues after the last message seen, so one tick never tries a
      // message twice — and, unlike a list of the ids already tried, the query stays the same size however long the
      // backlog is (a growing `notIn` list overran SQLite's parameter limit once a tick passed about a thousand messages).
      let after: { createdAt: Date; id: string } | undefined;
      for (;;) {
        if (Date.now() - started > TICK_BUDGET_MS) return run;
        const due = await db.emailOutbox.findMany({
          where: {
            status: 'queued',
            templateKey,
            AND: [
              { OR: [{ nextAttemptAt: null }, { nextAttemptAt: { lte: now } }] },
              ...(after ? [{ OR: [{ createdAt: { gt: after.createdAt } }, { createdAt: after.createdAt, id: { gt: after.id } }] }] : []),
            ],
          },
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
          take: BATCH,
          select: { id: true, createdAt: true },
        });
        if (!due.length) break;
        after = due[due.length - 1];
        await sendBatch(due);
      }
    }
    return run;

    async function sendBatch(due: { id: string }[]) {
      for (const { id } of due) {
        const claimed = await db.emailOutbox.updateMany({
          where: { id, status: 'queued' },
          data: { status: 'sending', lastAttemptAt: now, attempts: { increment: 1 } },
        });
        if (!claimed.count) continue; // another process took it
        const row = await db.emailOutbox.findUniqueOrThrow({
          where: { id },
          select: { toEmail: true, toName: true, subject: true, text: true, attempts: true },
        });
        try {
          const { messageId } = await transport.send({ to: row.toEmail, toName: row.toName, subject: row.subject, text: row.text });
          await db.emailOutbox.update({ where: { id }, data: { status: 'sent', sentAt: new Date(), error: null, providerMessageId: messageId ?? null } });
          run.sent++;
        } catch (err) {
          const next = nextDeliveryAttempt(row.attempts, now);
          // The reason, redacted and short: never the body, which can carry a one-time link.
          const error = describeError(err).message.slice(0, 300);
          await db.emailOutbox.update({ where: { id }, data: next ? { status: 'queued', nextAttemptAt: next, error } : { status: 'failed', error } });
          if (next) run.retried++;
          else run.failed++;
        }
      }
    }
  });
}

/** How long a sent code or link is kept readable in the outbox: the longest any of them works (a staff invitation). */
export const URGENT_BODY_RETENTION_MS = 7 * 24 * 60 * 60_000;
const REDACTED = '[Removed after delivery: this message carried a one-time code or link.]';

/**
 * Blanks the subject and body of codes and links (URGENT_TEMPLATES) once they were sent, or gave up, and every one of
 * them has expired: the outbox keeps who was sent what and when, never a code or link that could still be read later.
 * Idempotent; platform-wide.
 */
export async function redactSentSecrets(now = new Date()): Promise<number> {
  return runAsPlatform('the scheduler removes expired codes and links from the outbox', async () => {
    const { count } = await db.emailOutbox.updateMany({
      where: {
        templateKey: { in: [...URGENT_TEMPLATES] },
        status: { in: ['sent', 'failed'] },
        createdAt: { lt: new Date(now.getTime() - URGENT_BODY_RETENTION_MS) },
        text: { not: REDACTED },
      },
      data: { subject: 'One-time code or link (removed)', text: REDACTED },
    });
    return count;
  });
}
