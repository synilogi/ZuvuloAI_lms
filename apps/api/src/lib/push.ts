import jwt from 'jsonwebtoken';
import { nextDeliveryAttempt, quietHoursEnd, type NotificationSettings } from '@syniastrolms/domain';

import { db } from './db.js';
import { readJson } from './json.js';
import { describeError } from './observe.js';
import { runAsPlatform } from './tenancy.js';

/*
 * Push notifications (SAAS-021). A push is a hint, never the message: it carries the in-app notification's id
 * and category, and the app fetches the notification through the API — as the signed-in account — before it
 * shows anything. So a push can never reveal content, and a token that reached the wrong device reveals nothing.
 *
 * `notify()` queues one `PushDelivery` per in-app notification when a provider is configured and the recipient
 * has a registered device, held until the recipient's quiet hours end unless the notification is important.
 * The worker below sends it through the provider, with the same claim, backoff and final status as email; a
 * token the provider reports as no longer valid is removed. With no provider configured nothing is queued,
 * nothing is sent and nothing fails.
 */

export interface PushMessage {
  notificationId: string;
  category: string;
}

export type PushOutcome = { token: string; ok: true } | { token: string; ok: false; invalidToken: boolean; error: string };

export interface PushProvider {
  readonly name: string;
  send(tokens: string[], message: PushMessage): Promise<PushOutcome[]>;
}

/* ─── Firebase Cloud Messaging (HTTP v1) ──────────────────────────────── */

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';

/**
 * FCM's HTTP v1 API, as Google documents it: an OAuth access token from a service-account JWT (RS256, the
 * `firebase.messaging` scope), then one `messages:send` per device. A data-only message, high priority on
 * Android and a background update on iOS, so the app decides what to show after fetching.
 */
export class FcmProvider implements PushProvider {
  readonly name = 'fcm';
  private access?: { token: string; expiresAt: number };

  constructor(
    private readonly account: ServiceAccount,
    private readonly http: typeof fetch = fetch,
  ) {}

  private async accessToken(): Promise<string> {
    if (this.access && this.access.expiresAt > Date.now() + 60_000) return this.access.token;
    const iat = Math.floor(Date.now() / 1000);
    const assertion = jwt.sign({ iss: this.account.client_email, scope: FCM_SCOPE, aud: TOKEN_URL, iat, exp: iat + 3600 }, this.account.private_key, {
      algorithm: 'RS256',
    });
    const res = await this.http(TOKEN_URL, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }).toString(),
    });
    if (!res.ok) throw new Error(`The push provider refused the credentials (${res.status}).`);
    const body = (await res.json()) as { access_token: string; expires_in: number };
    this.access = { token: body.access_token, expiresAt: Date.now() + body.expires_in * 1000 };
    return body.access_token;
  }

  async send(tokens: string[], message: PushMessage): Promise<PushOutcome[]> {
    const access = await this.accessToken();
    const url = `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(this.account.project_id)}/messages:send`;
    return Promise.all(
      tokens.map(async (token): Promise<PushOutcome> => {
        const res = await this.http(url, {
          method: 'POST',
          headers: { authorization: `Bearer ${access}`, 'content-type': 'application/json' },
          body: JSON.stringify({
            message: {
              token,
              data: { notificationId: message.notificationId, category: message.category },
              android: { priority: 'HIGH' },
              apns: { headers: { 'apns-priority': '5', 'apns-push-type': 'background' }, payload: { aps: { 'content-available': 1 } } },
            },
          }),
        });
        if (res.ok) return { token, ok: true };
        const body = (await res.json().catch(() => ({}))) as { error?: { status?: string; details?: { errorCode?: string }[] } };
        const code = body.error?.details?.find((d) => d.errorCode)?.errorCode ?? body.error?.status ?? String(res.status);
        // UNREGISTERED: the app was uninstalled or the token rotated. INVALID_ARGUMENT on a send is a malformed token.
        return { token, ok: false, invalidToken: code === 'UNREGISTERED' || code === 'INVALID_ARGUMENT', error: `FCM ${res.status} ${code}` };
      }),
    );
  }
}

/** `FCM_SERVICE_ACCOUNT` holds the service-account JSON, raw or base64. Never logged. */
export function fcmFromEnv(env: NodeJS.ProcessEnv = process.env): FcmProvider | null {
  const raw = env.FCM_SERVICE_ACCOUNT?.trim();
  if (!raw) return null;
  const text = raw.startsWith('{') ? raw : Buffer.from(raw, 'base64').toString('utf8');
  const account = JSON.parse(text) as Partial<ServiceAccount>;
  if (!account.project_id || !account.client_email || !account.private_key)
    throw new Error('FCM_SERVICE_ACCOUNT is missing project_id, client_email or private_key.');
  return new FcmProvider(account as ServiceAccount);
}

let override: PushProvider | null | undefined;
let configured: PushProvider | null | undefined;

/** The provider in use: a test's, else the one `PUSH_PROVIDER` names (`fcm`), else none. */
export function pushProvider(): PushProvider | null {
  if (override !== undefined) return override;
  if (configured === undefined) configured = process.env.PUSH_PROVIDER === 'fcm' ? fcmFromEnv() : null;
  return configured;
}

/** Installs a provider (tests); `undefined` goes back to the configured one. */
export const setPushProvider = (provider: PushProvider | null | undefined) => {
  override = provider;
};

/* ─── Queueing and delivering ─────────────────────────────────────────── */

/**
 * Queues the push hint for a notification just created for `userId`, in the caller's context. Nothing is queued
 * without a provider or without a registered device.
 */
export async function queuePush(input: { userId: string; notificationId: string; important: boolean; quietHoursJson?: string | null }, now = new Date()) {
  if (!pushProvider()) return;
  if (!(await db.deviceToken.count({ where: { userId: input.userId } }))) return;
  const quiet = input.important ? null : quietHoursEnd(readJson<NotificationSettings['quietHours'] | undefined>(input.quietHoursJson ?? null, undefined), now);
  await db.pushDelivery.create({ data: { userId: input.userId, notificationId: input.notificationId, nextAttemptAt: quiet ?? now } });
}

const STALE_SENDING_MS = 10 * 60_000;
const BATCH = 50;
const TICK_BUDGET_MS = 20_000;

export interface PushRun {
  sent: number;
  skipped: number;
  retried: number;
  failed: number;
}

/** Sends the push hints that are due. Idempotent and safe to run from several processes at once. */
export async function deliverQueuedPushes(now = new Date()): Promise<PushRun> {
  const run: PushRun = { sent: 0, skipped: 0, retried: 0, failed: 0 };
  const configuredProvider = pushProvider();
  if (!configuredProvider) return run;
  const provider: PushProvider = configuredProvider;
  return runAsPlatform('the push worker delivers hints for every academy', async () => {
    await db.pushDelivery.updateMany({
      where: { status: 'sending', lastAttemptAt: { lt: new Date(now.getTime() - STALE_SENDING_MS) } },
      data: { status: 'queued' },
    });
    // Batch after batch within the tick's budget: quiet hours release everyone's held pushes at once.
    const started = Date.now();
    const tried = new Set<string>();
    const due: { id: string }[] = [];
    for (;;) {
      if (Date.now() - started > TICK_BUDGET_MS) break;
      const batch = await db.pushDelivery.findMany({
        where: { status: 'queued', id: { notIn: [...tried] }, nextAttemptAt: { lte: now } },
        orderBy: { nextAttemptAt: 'asc' },
        take: BATCH,
        select: { id: true },
      });
      if (!batch.length) break;
      for (const { id } of batch) tried.add(id);
      due.splice(0, due.length, ...batch);
      await sendBatch();
    }
    return run;

    async function sendBatch() {
      for (const { id } of due) {
        const claimed = await db.pushDelivery.updateMany({
          where: { id, status: 'queued' },
          data: { status: 'sending', lastAttemptAt: now, attempts: { increment: 1 } },
        });
        if (!claimed.count) continue;
        const row = await db.pushDelivery.findUniqueOrThrow({
          where: { id },
          include: { notification: { select: { id: true, category: true, readAt: true } } },
        });
        // Already read while it waited out quiet hours: there is nothing left to point at.
        if (row.notification.readAt) {
          await db.pushDelivery.update({ where: { id }, data: { status: 'skipped', error: 'Read before it was sent.' } });
          run.skipped++;
          continue;
        }
        const devices = await db.deviceToken.findMany({ where: { userId: row.userId }, select: { token: true } });
        if (!devices.length) {
          await db.pushDelivery.update({ where: { id }, data: { status: 'skipped', error: 'No registered device.' } });
          run.skipped++;
          continue;
        }
        try {
          const outcomes = await provider.send(
            devices.map((d) => d.token),
            { notificationId: row.notification.id, category: row.notification.category },
          );
          const invalid = outcomes.filter((o) => !o.ok && o.invalidToken).map((o) => o.token);
          if (invalid.length) await db.deviceToken.deleteMany({ where: { token: { in: invalid } } });
          const delivered = outcomes.filter((o) => o.ok).length;
          const failure = outcomes.find((o): o is Extract<PushOutcome, { ok: false }> => !o.ok && !o.invalidToken);
          if (delivered || !failure) {
            await db.pushDelivery.update({
              where: { id },
              data: delivered
                ? { status: 'sent', sentAt: new Date(), delivered, error: null }
                : { status: 'skipped', error: 'Every device token was no longer valid.' },
            });
            if (delivered) run.sent++;
            else run.skipped++;
            continue;
          }
          throw new Error(failure.error);
        } catch (err) {
          const next = nextDeliveryAttempt(row.attempts, now);
          const error = describeError(err).message.slice(0, 300);
          await db.pushDelivery.update({ where: { id }, data: next ? { status: 'queued', nextAttemptAt: next, error } : { status: 'failed', error } });
          if (next) run.retried++;
          else run.failed++;
        }
      }
    }
  });
}
