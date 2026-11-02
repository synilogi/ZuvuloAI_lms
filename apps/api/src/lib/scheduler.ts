import { reconcileCoursePurchases } from './coursePurchases.js';
import { placePendingAffiliates } from './mlm/placement.js';
import { repairOrders, settleEligibleOrders } from './mlm/cv.js';
import { claimNightly, evaluateRanks, releaseHeldCommissions, runDueMatching } from './mlm/earnings.js';
import { reconcileWallets } from './mlm/wallet.js';
import { db } from './db.js';
import { sendDueCalendarReminders } from './calendarEvents.js';
import { sendDueReminders } from './liveEvents.js';
import { closeStaleRooms, keepPendingRecordings } from './liveSessions.js';
import { runNotificationJobs } from './notificationJobs.js';
import { watchJob } from './observe.js';
import { withLease } from './jobLease.js';
import { deliverQueuedEmail, redactSentSecrets } from './mailDelivery.js';
import { deliverQueuedPushes } from './push.js';
import { prunePendingRegistrations } from './pendingAccounts.js';
import { pruneSessions } from './sessions.js';
import { runAsPlatform, runInTenant } from './tenancy.js';
import { settleOverdueQuizSessions } from '../routes/learning.js';

/**
 * Runs `fn` once for every active workspace, inside its context — so a job reads its settings, sees only its rows
 * and writes only to it. The platform has one workspace (docs/16, D-PLAT-01); academies kept from the SaaS era are
 * archived and get no scheduled work. A failure is reported as a `job.failed` signal (§48, redacted). Listing the
 * workspaces is the scheduler's one platform-wide read.
 */
export async function forEachTenant<T>(
  fn: (tenantId: string) => Promise<T>,
  job = 'scheduled-work',
  statuses: readonly string[] = ['active'],
): Promise<Map<string, T>> {
  const tenants = await runAsPlatform('the scheduler walks every academy', () =>
    db.tenant.findMany({ where: { status: { in: [...statuses] } }, select: { id: true }, orderBy: { createdAt: 'asc' } }),
  );
  const results = new Map<string, T>();
  for (const { id } of tenants) {
    try {
      results.set(id, await watchJob(job, () => runInTenant(id, () => fn(id)), { tenantId: id }));
    } catch {
      // Reported by watchJob; the next academy still runs.
    }
  }
  return results;
}

/**
 * The every-minute work: live and calendar reminders, digests, overdue reviews, nudges, archiving — per academy;
 * and the live room's housekeeping: closing rooms left open, keeping recordings the video service posted.
 */
export const runNotificationSchedule = (now = new Date()) =>
  forEachTenant(
    (tenantId) =>
      Promise.all([sendDueReminders(now), sendDueCalendarReminders(now), runNotificationJobs(now), closeStaleRooms(now), keepPendingRecordings(tenantId)]),
    'scheduled-notifications',
  );

/**
 * Runs one job of the tick under its lease (SAAS-022): in only one process at a time, however many run the
 * scheduler. `null` when another process holds the lease this tick, or the job failed (already reported).
 */
const leased = <T>(job: string, fn: () => Promise<T>): Promise<T | null> =>
  withLease(job, fn)
    .then((run) => (run.ran ? run.result : null))
    .catch(() => null);

/** Everything the scheduler runs each minute, each job under its own lease. */
export const runScheduledJobs = async (now = new Date()) => {
  const notifications = await leased('scheduled-notifications', () => runNotificationSchedule(now));
  // Quiz attempts left open past their deadline and grace: finished as expired, on the answers the server accepted,
  // so they count and are scored without waiting for the learner to come back. Idempotent: a session is finished by
  // exactly one conditional update.
  const quizzes = await leased('quiz-session-expiry', () => forEachTenant(() => settleOverdueQuizSessions({}, now), 'quiz-session-expiry'));
  // Long-expired sessions (SAAS-020): platform-wide, idempotent, and indexed on expiry.
  const sessions = await leased('session-prune', () => watchJob('session-prune', () => pruneSessions(now)));
  // Registrations whose code expired a day ago and was never confirmed: they hold a password hash and nothing else.
  await leased('registration-prune', () => watchJob('registration-prune', () => prunePendingRegistrations(now)));
  // Codes and links already delivered and long expired: their text leaves the outbox (checklist A19).
  await leased('outbox-redact', () => watchJob('outbox-redact', () => redactSentSecrets(now)));
  // Delivery (SAAS-021): the outbox through the mail transport, push hints through the push provider. Each
  // does nothing when its transport or provider does not deliver, and claims rows so two processes cannot
  // send one twice even without the lease.
  // Course purchases nobody confirmed (the app closed, a webhook was lost): asked of each academy's gateway again.
  await leased('course-purchase-recovery', () =>
    watchJob('course-purchase-recovery', () => forEachTenant(() => reconcileCoursePurchases(now), 'course-purchase-recovery')),
  );
  // Affiliates who have a sponsor and no position yet (MLM-002): placed by the plan's spillover rule, oldest first.
  await leased('mlm-placement', () => watchJob('mlm-placement', () => forEachTenant(() => placePendingAffiliates(), 'mlm-placement')));
  // Orders whose CV delay has passed (MLM-003): credited to every ancestor, once.
  await leased('mlm-cv-eligibility', () => watchJob('mlm-cv-eligibility', () => forEachTenant(() => settleEligibleOrders(now), 'mlm-cv-eligibility')));
  // Earnings (docs/15 §9). Every minute: mend what a failed hook left, then the day's matching once its hour has come (it stops
  // itself once the day is done), then holds that now fit under the ceiling. Once a night: every member's rank, and every
  // balance against its ledger.
  await leased('mlm-repair', () => watchJob('mlm-repair', () => forEachTenant(() => repairOrders(now), 'mlm-repair')));
  await leased('mlm-matching', () => watchJob('mlm-matching', () => forEachTenant(() => runDueMatching(now), 'mlm-matching')));
  await leased('mlm-ceiling', () => watchJob('mlm-ceiling', () => forEachTenant(() => releaseHeldCommissions(now), 'mlm-ceiling')));
  await leased('mlm-nightly', () =>
    watchJob('mlm-nightly', () =>
      forEachTenant(async () => {
        if (!(await claimNightly(now))) return;
        await evaluateRanks(undefined, now);
        await reconcileWallets();
      }, 'mlm-nightly'),
    ),
  );
  const email = await leased('email-delivery', () => watchJob('email-delivery', () => deliverQueuedEmail(now)));
  const push = await leased('push-delivery', () => watchJob('push-delivery', () => deliverQueuedPushes(now)));
  return { notifications, quizzes, sessions, email, push };
};
