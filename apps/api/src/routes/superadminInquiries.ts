import { Router } from 'express';
import { INQUIRY_KINDS, INQUIRY_STATUSES } from '@syniastrolms/domain';

import { asyncHandler } from '../lib/errors.js';
import { listInquiries, updateInquiry } from '../lib/inquiries.js';
import { optionalEnum, paging, parseBody, parseQuery, searchText, z } from '../lib/validate.js';

/*
 * `/superadmin/inquiries` — the platform team's inbox (SAAS-027): demo, sales and support requests from the website
 * and from academy admins. Mounted inside the Super Admin router, so `requireSuperAdmin` and the platform context
 * already apply.
 */
export const superadminInquiriesRouter = Router();

superadminInquiriesRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const query = parseQuery(
      req,
      z.object({ status: optionalEnum(INQUIRY_STATUSES), kind: optionalEnum(INQUIRY_KINDS), search: searchText, page: paging.page, pageSize: paging.pageSize }),
    );
    res.json(await listInquiries(query));
  }),
);

superadminInquiriesRouter.patch(
  '/:id',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ status: z.enum(INQUIRY_STATUSES).optional(), note: z.string().trim().max(2000).optional() }));
    res.json(await updateInquiry(req, req.params.id, input));
  }),
);
