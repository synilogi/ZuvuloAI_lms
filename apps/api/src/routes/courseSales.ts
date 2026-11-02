import { Router, type Request } from 'express';

import { requireAuth } from '../lib/auth.js';
import { confirmCoursePurchase, coursePurchaseStatus, listCoursePurchases, quoteCoursePurchase, startCoursePurchase } from '../lib/coursePurchases.js';
import { asyncHandler, badRequest } from '../lib/errors.js';
import { assertNotSuspended } from '../lib/scope.js';
import { parseBody, z } from '../lib/validate.js';

/*
 * Course sales: a learner buying a paid course (`/learning/...`). The rules and guarantees are in
 * lib/coursePurchases.ts; the gateway is the platform's (lib/coursePayments.ts). Nothing here takes an amount, a
 * currency or a learner from the request: the server knows them. The Super Admin's view of sales is on the
 * `/superadmin/sales` routes.
 */

async function learnerOf(req: Request) {
  const id = req.auth?.studentId;
  if (!id) throw badRequest('Only learners can buy courses.');
  await assertNotSuspended(id);
  return id;
}

export const coursePurchaseRouter = Router();

const couponBody = z.object({ couponCode: z.string().trim().min(1).max(40).optional() });

/** What the learner would pay now: the server's figures, with the coupon they typed. Holds nothing. */
coursePurchaseRouter.post(
  '/courses/:courseId/quote',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await learnerOf(req);
    const { couponCode } = parseBody(req, couponBody);
    res.json(await quoteCoursePurchase(studentId, req.params.courseId, couponCode));
  }),
);

/** Opens the learner's order for a paid course, or reuses the open one: the checkout values, publishable only. */
coursePurchaseRouter.post(
  '/courses/:courseId/purchase',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await learnerOf(req);
    const { couponCode } = parseBody(req, couponBody);
    res.status(201).json(await startCoursePurchase(studentId, req.params.courseId, couponCode));
  }),
);

/** The checkout finished in the browser or app: verified with the gateway before anything opens. */
coursePurchaseRouter.post(
  '/purchases/:purchaseId/confirm',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await learnerOf(req);
    const input = parseBody(req, z.object({ paymentId: z.string().trim().min(1).max(64), signature: z.string().trim().min(1).max(256) }));
    res.json(await confirmCoursePurchase(studentId, req.params.purchaseId, input));
  }),
);

/** Where a purchase stands — asked of the gateway while it is open, so a closed app or a late webhook loses nothing. */
coursePurchaseRouter.get(
  '/purchases/:purchaseId',
  requireAuth,
  asyncHandler(async (req, res) => {
    res.json(await coursePurchaseStatus(await learnerOf(req), req.params.purchaseId));
  }),
);

coursePurchaseRouter.get(
  '/purchases',
  requireAuth,
  asyncHandler(async (req, res) => {
    res.json({ rows: await listCoursePurchases(await learnerOf(req)) });
  }),
);
