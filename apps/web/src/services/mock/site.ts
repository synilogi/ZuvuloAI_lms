import { DEFAULT_SITE_CONTENT, type SiteContent } from '@syniastrolms/domain';
import type { SiteService } from '../contracts';
import { respond } from './simulation';

let stored: SiteContent = DEFAULT_SITE_CONTENT;

/** The demo build's website: the contact form accepts and stores nothing (the page says so), and no plan is in force. */
export const siteService: SiteService = {
  contact: () => respond(() => undefined, 700),
  content: () => respond(() => stored),
  affiliateProgram: () =>
    respond(() => ({ active: false, course: null, currency: 'INR', matchingRateBps: 0, withdrawalMinAmount: 0, withdrawalRequiresKyc: true, ranks: [] })),
  adminContent: () => respond(() => stored),
  saveContent: (input) =>
    respond(() => {
      stored = input;
      return stored;
    }),
};
