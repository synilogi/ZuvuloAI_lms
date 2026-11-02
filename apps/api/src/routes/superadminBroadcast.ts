import { Router } from 'express';
import { BROADCAST_AUDIENCES, BROADCAST_SUMMARY_MAX, BROADCAST_TITLE_MAX } from '@syniastrolms/domain';

import { broadcastAudienceCount, broadcastHistory, sendBroadcast } from '../lib/broadcast.js';
import { asyncHandler, conflict } from '../lib/errors.js';
import { paging, parseBody, parseQuery, z } from '../lib/validate.js';

/* The Super Admin's notification broadcast; `superadminRouter` guards it. The rules are in lib/broadcast.ts. */
export const superadminBroadcastRouter = Router();

const audience = z.enum(BROADCAST_AUDIENCES);

// One line, since it becomes an email subject.
const broadcastBody = z.object({
  audience,
  title: z
    .string()
    .trim()
    .min(3)
    .max(BROADCAST_TITLE_MAX)
    .regex(/^[^\r\n]*$/, 'The title must fit on one line.'),
  summary: z.string().trim().min(3).max(BROADCAST_SUMMARY_MAX),
});

superadminBroadcastRouter.get(
  '/audience-count',
  asyncHandler(async (req, res) => {
    const query = parseQuery(req, z.object({ audience }));
    res.json({ audience: query.audience, count: await broadcastAudienceCount(query.audience) });
  }),
);

superadminBroadcastRouter.get(
  '/broadcasts',
  asyncHandler(async (req, res) => {
    const { page, pageSize } = parseQuery(req, z.object(paging));
    res.json(await broadcastHistory(page, pageSize));
  }),
);

superadminBroadcastRouter.post(
  '/broadcast',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, broadcastBody);
    if ((await broadcastAudienceCount(input.audience)) === 0) throw conflict('Nobody is in that audience.');
    res.status(201).json(await sendBroadcast(req, input));
  }),
);
