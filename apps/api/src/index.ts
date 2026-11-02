import 'dotenv/config';
import path from 'node:path';
import { createApp } from './app.js';
import { assertProductionSecrets } from './lib/auth.js';
import { assertMailConfig, mailTransport } from './lib/mailDelivery.js';
import { db } from './lib/db.js';
import { describeError, observe } from './lib/observe.js';
import { assertPaymentConfig } from './lib/paymentGateways.js';
import { assertSandboxConfig } from './lib/sandboxGateway.js';
import { assertTenancyConfig } from './lib/tenancy.js';
import { assertRegistrationConfig } from './lib/registration.js';
import { assertTestOtpConfig, testOtpEnabled } from './lib/testOtp.js';
import { liveRoomConfig, liveRoomUsable } from './lib/liveRoom.js';
import { runScheduledJobs } from './lib/scheduler.js';
import { serveWebApp } from './web.js';

assertProductionSecrets();
assertPaymentConfig();
assertRegistrationConfig();
assertMailConfig();
assertSandboxConfig();
assertTenancyConfig();
assertTestOtpConfig();
if (testOtpEnabled())
  console.warn(
    `[api] The static test verification code is on for ${process.env.TEST_OTP_EMAIL?.trim() === '*' ? 'EVERY email address' : 'the test accounts in TEST_OTP_EMAIL'}. Development and test only.`,
  );
// The live room's video service: a half-set JaaS stops the API here rather than on a host's first start.
const liveRoom = liveRoomConfig();
if (!liveRoomUsable(liveRoom)) {
  console.warn(
    '[api] Live classes: no JaaS keys, so the built-in room is OFF (start and join answer 503 LIVE_ROOM_NOT_CONFIGURED). Set JAAS_APP_ID, JAAS_KID and JAAS_PRIVATE_KEY; outside-meeting links still work.',
  );
}
// Every link in an email is APP_URL plus a path (lib/mail.ts): a production process must name its public https address.
if (process.env.NODE_ENV === 'production' && !/^https:\/\/(?!localhost\b|127\.)[^/]+/i.test(process.env.APP_URL ?? '')) {
  console.warn(
    '[api] APP_URL is not a public https address: reset, invitation and notification links in emails will not open. Set APP_URL=https://zuviloai.com.',
  );
}
// Without the code, learners and instructors are made for addresses nobody proved they own (and that address
// is then taken platform-wide). Kept a warning, not a refusal: the live server's .env can't be read from the repo, and a
// refusal would stop the API on the next deploy. Checklist A15 asks for it to be removed there.
if (process.env.NODE_ENV === 'production' && process.env.SIGNUP_EMAIL_VERIFICATION === 'off') {
  console.error('[api] SIGNUP_EMAIL_VERIFICATION=off in production: registrations are NOT email-verified. Remove it once email delivery works.');
}
// Registration emails a code: with nothing delivering email, nobody could finish it.
if (process.env.SIGNUP_EMAIL_VERIFICATION !== 'off' && !mailTransport().delivers) {
  console.warn('[api] MAIL_TRANSPORT does not deliver email: registration codes, password resets and invitations stay in the outbox. Set MAIL_TRANSPORT=smtp.');
}

const port = Number(process.env.PORT ?? 4000);
const api = createApp();
// WEB_DIST (production): the host's vhost forwards every path to this process, so it also
// serves the built web app — API under /api, everything else is the SPA. Unset in
// development, where Vite serves the web app and the API stays at /.
const webDist = process.env.WEB_DIST ? path.resolve(process.env.WEB_DIST) : undefined;
const server = webDist ? serveWebApp(api, webDist) : api;
const listener = server.listen(port, () => {
  const mode = process.env.NODE_ENV ?? 'development';
  console.log(`[api] listening on http://localhost:${port} (${mode})${webDist ? ` — web app from ${webDist}, API under /api` : ''}`);
});

// Scheduled notifications (live/calendar reminders, digests, overdue reviews, nudges) run every minute,
// once per academy; set LIVE_REMINDERS=off to run the API without the scheduler.
if (process.env.LIVE_REMINDERS !== 'off') {
  // A failure that escapes the per-academy guard (listing the academies, say) is still a visible job failure.
  // A long tick must not overlap the next: the leases cannot stop two runs of this same process.
  let ticking = false;
  const tick = () => {
    if (ticking) return;
    ticking = true;
    void runScheduledJobs()
      .catch((err) => observe('job.failed', { job: 'scheduler', error: describeError(err) }))
      .finally(() => {
        ticking = false;
      });
  };
  tick();
  setInterval(tick, 60_000).unref();
}

// A failure nothing caught is still a visible, redacted signal rather than a silent crash loop.
process.on('unhandledRejection', (err) => observe('request.failed', { reason: 'unhandled rejection', error: describeError(err) }));
process.on('uncaughtException', (err) => {
  observe('request.failed', { reason: 'uncaught exception', error: describeError(err) });
  process.exit(1);
});

// PM2's reload stops this process with SIGINT: requests in flight finish, then the database is let go.
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.once(signal, () => {
    listener.close(() => {
      void db.$disconnect().finally(() => process.exit(0));
    });
    setTimeout(() => process.exit(0), 8_000).unref();
  });
}
