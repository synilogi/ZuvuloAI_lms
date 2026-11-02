import type { Inquiry } from '@syniastrolms/domain';

import type { SupportService } from '../contracts';
import { mockNowIso } from './clock';
import { respond } from './simulation';

/** The demo build's support requests: kept in memory for this visit, and answered by nobody (the page says so). */
const requests: Inquiry[] = [];

export const supportService: SupportService = {
  list: () => respond(() => [...requests]),
  create: ({ subject, message }) =>
    respond(() => {
      const now = mockNowIso();
      const row: Inquiry = {
        id: `support-${requests.length + 1}`,
        kind: 'support',
        status: 'new',
        name: 'Demo admin',
        email: 'admin@syniastrolms.test',
        subject,
        message,
        createdAt: now,
        updatedAt: now,
      };
      requests.unshift(row);
      return row;
    }, 600),
};
