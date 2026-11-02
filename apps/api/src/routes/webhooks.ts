import express, { Router } from 'express';

import { asyncHandler } from '../lib/errors.js';
import { receiveJaasWebhook } from '../lib/liveSessions.js';
import { receiveCoursePaymentWebhook } from '../lib/coursePurchases.js';

/*
 * Provider webhooks. Mounted before the JSON body parser: a signature is over the exact bytes the provider sent, so
 * the body arrives raw and is verified before a word of it is read. No session: a webhook is trusted only once its
 * signature verifies under the platform's own secret for that provider.
 */
export const webhooksRouter = Router();

const lowerHeaders = (req: express.Request) => Object.fromEntries(Object.entries(req.headers).map(([k, v]) => [k.toLowerCase(), Array.isArray(v) ? v[0] : v]));

/** `POST /webhooks/jaas` — the live room's video service (lib/liveSessions.ts): recordings, signed like the payment webhooks. */
webhooksRouter.post(
  '/jaas',
  express.raw({ type: () => true, limit: '256kb' }),
  asyncHandler(async (req, res) => {
    const raw = Buffer.isBuffer(req.body) ? req.body : Buffer.alloc(0);
    const result = await receiveJaasWebhook(raw, lowerHeaders(req));
    res.status(result.status).json(result.body);
  }),
);

const courseWebhook = asyncHandler(async (req, res) => {
  const raw = Buffer.isBuffer(req.body) ? req.body : Buffer.alloc(0);
  const result = await receiveCoursePaymentWebhook(req.params.provider, raw, lowerHeaders(req));
  res.status(result.status).json(result.body);
});

/**
 * `POST /webhooks/:provider/courses` — the platform's gateway reporting on the orders learners pay for courses
 * (lib/coursePurchases.ts; docs/16, D-PLAT-07). Verified with the platform's webhook secret over the raw body.
 */
webhooksRouter.post('/:provider/courses', express.raw({ type: () => true, limit: '256kb' }), courseWebhook);

/**
 * The address the SaaS-era academy webhook was registered at. Kept for one release as an alias of the platform
 * webhook (docs/16 §3.1), so a webhook already registered at the gateway keeps delivering; the academy id in the
 * path is ignored — there is one workspace.
 */
webhooksRouter.post(
  '/academies/:tenantId/:provider/courses',
  express.raw({ type: () => true, limit: '256kb' }),
  (req, _res, next) => {
    req.params.provider = req.params.provider ?? 'razorpay';
    next();
  },
  courseWebhook,
);
