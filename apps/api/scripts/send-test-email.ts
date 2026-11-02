/* Sends one test email straight through the configured SMTP relay, so a deployment can prove delivery
 * before it opens self-serve registration (verification codes), password resets and staff/learner
 * invitations — all of which go through the same transport. It bypasses the outbox and touches no data.
 *
 *   npm run mail:test -w @syniastrolms/api -- you@example.com
 */
import 'dotenv/config';

import { assertMailConfig, smtpTransport } from '../src/lib/mailDelivery.js';

const to = process.argv.slice(2).find((a) => a.includes('@'));
if (!to) {
  console.error('Usage: npm run mail:test -w @syniastrolms/api -- you@example.com');
  process.exit(2);
}
if (process.env.MAIL_TRANSPORT !== 'smtp') {
  console.error(
    `[mail] MAIL_TRANSPORT is "${process.env.MAIL_TRANSPORT ?? 'outbox'}", not "smtp": nothing would be delivered. Set MAIL_TRANSPORT=smtp and the SMTP_* values in apps/api/.env.`,
  );
  process.exit(1);
}
assertMailConfig();

const host = `${process.env.SMTP_HOST}:${process.env.SMTP_PORT ?? 587}`;
try {
  const { messageId } = await smtpTransport().send({
    to,
    subject: 'ZuviloAI test email',
    text: `This is a test from ${process.env.APP_URL ?? 'ZuviloAI'}. If you can read it, verification codes, password resets and invitations will be delivered.`,
  });
  console.log(`[mail] ✓ ${host} accepted the message for ${to} from ${process.env.MAIL_FROM} (id ${messageId ?? 'none'}). Check the inbox and spam folder.`);
  process.exit(0);
} catch (err) {
  console.error(`[mail] ✗ ${host} refused: ${err instanceof Error ? err.message : String(err)}`);
  process.exit(1);
}
