import { Router, type Request } from 'express';

import { db } from '../lib/db.js';
import { asyncHandler } from '../lib/errors.js';
import { permissionsFor } from '../lib/permissions.js';
import { startSession } from '../lib/sessions.js';
import { resendSignupCode, signupStatus, startSignup, verifySignup } from '../lib/signup.js';
import { runAsPlatform, runInTenant } from '../lib/tenancy.js';
import { email, parseBody, z } from '../lib/validate.js';
import { toProfile } from './auth.js';

/*
 * `/signup` — self-serve registration of an academy and its admin (SAAS-026, D27). Public and rate limited
 * (`app.ts`). The body names the organisation and the person; nothing in it can choose a role, an academy, a
 * plan or a status: the registrant is always the new academy's owner admin, and the academy starts with no
 * subscription (D28) — a free trial or a verified payment comes next, from the admin workspace.
 */
export const signupRouter = Router();

const startSchema = z.object({
  academyName: z.string().trim().min(2, 'Enter your organisation’s name.').max(120),
  slug: z.string().trim().toLowerCase().max(60).optional(),
  name: z.string().trim().min(2, 'Enter your full name.').max(120),
  email,
  password: z.string().min(8, 'Password must be at least 8 characters.').max(128),
  acceptTerms: z.literal(true, { message: 'Agree to the Terms and Privacy Policy to continue.' }),
  planId: z.string().trim().min(1).max(64).optional(),
  cycle: z.enum(['monthly', 'annual']).optional(),
});

const signupId = z.string().trim().min(1).max(64);

/** Signs the new admin in: the same session a sign-in starts, with the permissions their grant holds. */
async function sessionFor(req: Request, adminId: string, academyId: string) {
  const user = await runAsPlatform('the new admin signs in after registering', () => db.user.findUniqueOrThrow({ where: { id: adminId } }));
  const token = await startSession(user, req.get('user-agent'));
  const permissions = await runInTenant(academyId, () => permissionsFor(user.id));
  return { token, user: toProfile(user, permissions) };
}

signupRouter.post(
  '/start',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, startSchema);
    const result = await startSignup(input);
    if (result.status === 'created') {
      // Email verification is switched off for this deployment: the academy exists already.
      res.status(201).json({ status: 'created', choice: result.choice, ...(await sessionFor(req, result.adminId, result.academyId)) });
      return;
    }
    res.status(202).json(result);
  }),
);

/** Where an open registration stands, for a page that was refreshed at the code step. 404 once it is used or replaced. */
signupRouter.get(
  '/:signupId',
  asyncHandler(async (req, res) => {
    res.json(await signupStatus(req.params.signupId));
  }),
);

signupRouter.post(
  '/resend',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ signupId }));
    res.json(await resendSignupCode(input.signupId));
  }),
);

signupRouter.post(
  '/verify',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({
        signupId,
        code: z
          .string()
          .trim()
          .regex(/^\d{6}$/, 'Enter the 6-digit code from the email.'),
      }),
    );
    const created = await verifySignup(input.signupId, input.code);
    res.status(201).json({ status: 'created', choice: created.choice, ...(await sessionFor(req, created.adminId, created.academyId)) });
  }),
);
