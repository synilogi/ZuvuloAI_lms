import { Router } from 'express';

import { requireAuth, requireRole } from '../lib/auth.js';
import { asyncHandler } from '../lib/errors.js';
import { createInvitation, listInvitations, revokeInvitation } from '../lib/invitations.js';
import { requirePermission } from '../lib/permissions.js';
import { email, parseBody, z } from '../lib/validate.js';

/*
 * `/invitations` — an Admin's learner invitations (`/invite/<token>` links), always in the Admin's own workspace.
 * The same permission as adding a learner by hand.
 */
export const invitationsRouter = Router();

invitationsRouter.use(requireAuth, requireRole('admin'), requirePermission('learners.enroll'));

invitationsRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    res.json(await listInvitations());
  }),
);

invitationsRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ email: email.optional() }));
    res.status(201).json(await createInvitation(req, input));
  }),
);

invitationsRouter.post(
  '/:id/revoke',
  asyncHandler(async (req, res) => {
    res.json(await revokeInvitation(req, req.params.id));
  }),
);
