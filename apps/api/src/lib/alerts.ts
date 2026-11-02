import type { Observation } from './observe.js';
import { onObservationError } from './observe.js';
import { queueEmail } from './mail.js';
import { runInTenant } from './tenancy.js';
import { workspaceId } from './requestContext.js';

/*
 * Telling someone when the server has a real problem (docs/19). Every error-level signal is sent to ALERT_WEBHOOK_URL (anything that takes
 * a JSON post, such as a Slack or Discord webhook) and to ALERT_EMAIL. Signals are already redacted. One kind of signal alerts at most once
 * per quiet period, so a failure that repeats cannot flood anyone. A failure to alert is never allowed to become a second failure.
 */

const QUIET_MS = 15 * 60_000;
const lastSent = new Map<string, number>();

/** Whether this signal should alert now, remembering that it did. */
export function shouldAlert(signal: string, now = Date.now()): boolean {
  const last = lastSent.get(signal);
  if (last !== undefined && now - last < QUIET_MS) return false;
  lastSent.set(signal, now);
  return true;
}

export function alertText(o: Pick<Observation, 'signal' | 'at' | 'fields'>): string {
  return `ZuviloAI alert: ${o.signal} at ${o.at}\n${JSON.stringify(o.fields).slice(0, 1500)}`;
}

async function send(o: Observation) {
  const text = alertText(o);
  const url = process.env.ALERT_WEBHOOK_URL;
  if (url?.startsWith('https://')) {
    // `text` is what Slack reads and `content` what Discord reads.
    await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ text, content: text.slice(0, 1900) }),
      signal: AbortSignal.timeout(5_000),
    }).catch(() => undefined);
  }
  const to = process.env.ALERT_EMAIL;
  if (to) {
    await runInTenant(await workspaceId(), () => queueEmail({ to, subject: `ZuviloAI alert: ${o.signal}`, text, templateKey: 'ops-alert' })).catch(
      () => undefined,
    );
  }
}

/** Called once at boot. Does nothing outside production-like setups that name no destination. */
export function startAlerts() {
  if (!process.env.ALERT_WEBHOOK_URL && !process.env.ALERT_EMAIL) return;
  onObservationError((o) => {
    if (shouldAlert(o.signal)) void send(o).catch(() => undefined);
  });
}
