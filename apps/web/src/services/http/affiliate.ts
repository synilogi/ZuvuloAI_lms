import type {
  AffiliateActivation,
  AffiliateFigures,
  AffiliateMe,
  AffiliateOrderRow,
  Paged,
  ReferralInfo,
  TeamPage,
  TeamRow,
  TreeNodeView,
} from '@syniastrolms/domain';
import type { AffiliateService, CvLedgerResult } from '../contracts';
import { API_BASE_URL, get, patch, post } from './client';

/*
 * The learner's own affiliate surface against `/affiliate/*` (MLM-001, MLM-002), and the public referral landing
 * data. `me` answers null, not an error, for a learner who has not joined: the home page offers the opt-in.
 */
export const httpAffiliate: AffiliateService = {
  me: async () => (await get<{ affiliate: AffiliateMe | null }>('/affiliate')).affiliate,
  enrol: (input) => post<AffiliateMe>('/affiliate/enrol', input),
  setPreferredLeg: (leg) => patch<AffiliateMe>('/affiliate/preferred-leg', { leg }),
  activation: () => get<AffiliateActivation>('/affiliate/activation'),
  referral: (code) => get<ReferralInfo>(`/public/affiliates/ref/${encodeURIComponent(code)}`),
  qrUrl: (code) => `${API_BASE_URL}/public/affiliates/ref/${encodeURIComponent(code)}/qr.svg`,
  tree: (root, depth) => get<TreeNodeView>('/affiliate/tree', { root, depth }),
  team: (query) => get<TeamPage>('/affiliate/team', query),
  referrals: async () => (await get<{ rows: TeamRow[] }>('/affiliate/referrals')).rows,
  figures: () => get<AffiliateFigures>('/affiliate/figures'),
  orders: (query) => get<Paged<AffiliateOrderRow>>('/affiliate/orders', query),
  cvLedger: (query) => get<CvLedgerResult>('/affiliate/cv', query),
};
