import type { PublicAffiliateProgram, SiteContent } from '@syniastrolms/domain';
import type { SiteService } from '../contracts';
import { get, post, put } from './client';

/** The website's contact form and editable content, against `/public/*` and `/superadmin/sales/site`. */
export const httpSite: SiteService = {
  contact: async (input) => {
    await post<{ received: true }>('/public/inquiries', input);
  },
  content: () => get<SiteContent>('/public/site'),
  affiliateProgram: () => get<PublicAffiliateProgram>('/public/affiliate-program'),
  adminContent: () => get<SiteContent>('/superadmin/sales/site'),
  saveContent: (input) => put<SiteContent>('/superadmin/sales/site', input),
};
