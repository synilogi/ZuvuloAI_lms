import cors from 'cors';
import { affiliateRouter } from './routes/affiliate.js';
import { installMlmPurchaseHook } from './lib/mlm/cv.js';
import express, { type Express } from 'express';

import { attachAuth } from './lib/auth.js';
import { db } from './lib/db.js';
import { errorHandler } from './lib/errors.js';
import { tenantContext } from './lib/requestContext.js';
import { emailLimiter, accountSignInLimiter, makeLimiter, rateLimitOptionsFromEnv, securityHeaders, type RateLimitOptions } from './lib/security.js';
import { deployWebhookRouter } from './routes/deploy-webhook.js';
import { authRouter } from './routes/auth.js';
import { catalogRouter } from './routes/catalog.js';
import { coursesRouter } from './routes/courses.js';
import { categoriesRouter } from './routes/categories.js';
import { chaptersRouter } from './routes/chapters.js';
import { lessonsRouter } from './routes/lessons.js';
import { studentsRouter } from './routes/students.js';
import { instructorsRouter } from './routes/instructors.js';
import { learningRouter } from './routes/learning.js';
import { quizzesRouter } from './routes/quizzes.js';
import { assignmentsRouter } from './routes/assignments.js';
import { certificatesRouter } from './routes/certificates.js';
import { liveRouter } from './routes/live.js';
import { calendarRouter } from './routes/calendar.js';
import { notificationsRouter } from './routes/notifications.js';
import { settingsRouter } from './routes/settings.js';
import { helpRouter } from './routes/help.js';
import { reportsRouter } from './routes/reports.js';
import { dashboardRouter } from './routes/dashboard.js';
import { mediaRouter } from './routes/media.js';
import { superadminRouter } from './routes/superadmin.js';
import { webhooksRouter } from './routes/webhooks.js';
import { coursePurchaseRouter } from './routes/courseSales.js';
import { invitationsRouter } from './routes/invitations.js';
import { publicSiteRouter } from './routes/publicSite.js';
import { sandboxRouter } from './routes/sandbox.js';

export interface AppOptions {
  rateLimits?: Partial<RateLimitOptions>;
}

// The affiliate program listens to course sales (MLM-003): registered once, before any purchase can settle.
installMlmPurchaseHook();

export function createApp(options: AppOptions = {}): Express {
  const app = express();
  const limits = { ...rateLimitOptionsFromEnv(), ...options.rateLimits };

  // Behind nginx/a load balancer the client ip is in X-Forwarded-For; TRUST_PROXY = number of hops.
  const trustProxy = Number(process.env.TRUST_PROXY ?? 0);
  if (trustProxy > 0) app.set('trust proxy', trustProxy);
  app.disable('x-powered-by');

  app.use(securityHeaders);
  app.use(cors({ origin: process.env.CORS_ORIGIN ?? 'http://localhost:5173' }));
  app.use(makeLimiter(limits.global, limits.windowMs, 'Too many requests. Please slow down.'));
  // Provider webhooks read their body raw, to verify its signature, so they come before the JSON parser.
  app.use('/webhooks', webhooksRouter);

  // Signed by GitHub over the raw body, so it must run before express.json() consumes it.
  app.use('/deploy/webhook', deployWebhookRouter);

  app.use(express.json({ limit: '1mb' }));
  app.use(attachAuth);

  // The deploy's health check reads this: a process that cannot reach its database is not healthy.
  app.get('/health', async (_req, res) => {
    try {
      await db.$queryRaw`SELECT 1`;
      res.json({ ok: true });
    } catch {
      res.status(503).json({ ok: false, message: 'The database is not answering.' });
    }
  });

  // Every request below runs in the platform's one workspace (docs/16, D-PLAT-01). The Super Admin router alone
  // widens that to the platform's own tables.
  app.use(tenantContext);

  // Every self-registration emails a code to the address it names: a budget per address, from any client.
  const perAddress = emailLimiter(limits.email, 'Too many codes have been sent to this email address. Try again in an hour.');
  for (const path of [
    '/auth/register',
    '/public/register',
    '/public/instructor-applications',
    '/public/academies/:slug/register',
    '/public/academies/:slug/instructor-requests',
    '/public/invitations/:token/register',
    '/public/courses/:courseId/enroll',
  ])
    app.post(path, perAddress);
  // A reset link is mailed to the address named, and each request revokes the links before it (an invited person's
  // set-password link included): the same budget per address, from any client. It answers alike for every address,
  // so it tells nobody whether an account exists.
  app.post('/auth/forgot-password', emailLimiter(limits.email, 'Too many reset links have been sent to this email address. Try again in an hour.'));

  // Both doors that check a password: a budget of failures per account, from any client.
  const perAccount = accountSignInLimiter(limits.account, limits.windowMs);
  app.post('/auth/login', perAccount);
  app.post('/public/invitations/:token/sign-in', perAccount);

  app.use('/auth', makeLimiter(limits.auth, limits.windowMs, 'Too many sign-in attempts. Try again later.', { skipGet: true }), authRouter);
  // The website's public data. The contact form has a tighter budget than browsing.
  app.use(
    '/public/inquiries',
    makeLimiter(Math.max(5, Math.floor(limits.auth / 3)), limits.windowMs, 'Too many messages. Try again later.', { skipGet: true }),
  );
  // Registering is a sign-up, on the sign-up budget.
  app.use('/public/register', makeLimiter(limits.auth, limits.windowMs, 'Too many sign-up attempts. Try again later.'));
  app.use('/public/instructor-applications', makeLimiter(limits.auth, limits.windowMs, 'Too many sign-up attempts. Try again later.'));
  // A referral code names its sponsor, so codes are not to be tried at speed (docs/15 §5.1).
  app.use('/public/affiliates', makeLimiter(limits.auth, limits.windowMs, 'Too many attempts. Try again later.'));
  app.use('/public/academies', makeLimiter(limits.auth, limits.windowMs, 'Too many sign-up attempts. Try again later.', { skipGet: true }));
  // Accepting an invitation and joining from a course link are sign-ups (and sign-ins) too: the same budget, and
  // the invitation lookup is limited as well, so tokens cannot be tried at speed.
  app.use('/public/invitations', makeLimiter(limits.auth, limits.windowMs, 'Too many attempts. Try again later.'));
  app.use('/public/courses', makeLimiter(limits.auth, limits.windowMs, 'Too many sign-up attempts. Try again later.', { skipGet: true }));
  // A self-registration's email code: checked and resent on the sign-up budget, its status read included.
  app.use('/public/verifications', makeLimiter(limits.auth, limits.windowMs, 'Too many attempts. Try again later.'));
  app.use('/public', publicSiteRouter);
  // The sandbox gateway's test checkout: not found unless PAYMENT_SANDBOX=on outside production.
  app.use('/sandbox', sandboxRouter);
  app.use('/catalog', catalogRouter);
  app.use('/courses', coursesRouter);
  app.use('/categories', categoriesRouter);
  app.use('/courses/:courseId/chapters', chaptersRouter);
  app.use('/courses/:courseId/lessons', lessonsRouter);
  app.use('/students', studentsRouter);
  app.use('/invitations', invitationsRouter);
  app.use('/instructors', instructorsRouter);
  app.use('/learning', learningRouter);
  // Buying a paid course (lib/coursePurchases.ts): the learner's side of course sales.
  app.use('/learning', coursePurchaseRouter);
  // The affiliate program's own surface for a learner (MLM-001 …).
  app.use('/affiliate', affiliateRouter);
  app.use('/quizzes', quizzesRouter);
  app.use('/assignments', assignmentsRouter);
  app.use('/certificates', certificatesRouter);
  app.use('/live', liveRouter);
  app.use('/calendar', calendarRouter);
  app.use('/notifications', notificationsRouter);
  app.use('/settings', settingsRouter);
  app.use('/help', helpRouter);
  app.use('/reports', reportsRouter);
  app.use('/dashboard', dashboardRouter);
  app.use('/media', mediaRouter);
  // Platform surface, guarded by requireSuperAdmin inside the router — no other role reaches it.
  app.use('/superadmin', superadminRouter);

  app.use((_req, res) => res.status(404).json({ message: 'Not found.' }));
  app.use(errorHandler);
  return app;
}
