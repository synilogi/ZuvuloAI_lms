import type {
  AffiliateMemberRow,
  MlmCvQuery,
  MlmLegFigures,
  MlmOrderRow,
  MlmPlanOverview,
  MlmPlanTerms,
  MlmPlanVersionSummary,
  MlmProgramCourse,
  TeamPage,
  TreeAncestor,
  TreeNodeView,
} from '@syniastrolms/domain';
import {
  ServiceError,
  type CarryForwardResult,
  type CvLedgerResult,
  type MemberListResult,
  type MlmProducts,
  type OrderListResult,
  type PlacementListResult,
  type PlatformAffiliateService,
  type SponsorListResult,
} from '../contracts';
import { API_BASE_URL, del, get, getToken, patch, post, put } from './client';

/*
 * The affiliate program's management surface against `/superadmin/affiliates/*` (MLM-000: the plan; MLM-002: members,
 * network, placements, sponsors; MLM-003: products, orders, the CV ledger and carry-forward). Every rule — which terms are valid, one active version, sealed ranks, where a node
 * may be placed — is the server's; after a change the record is read back as stored.
 */
const BASE = '/superadmin/affiliates';
const PLAN = `${BASE}/plan`;

export const httpAffiliatesPlatform: PlatformAffiliateService = {
  plan: () => get<MlmPlanOverview>(PLAN),
  listPlanVersions: async () => (await get<{ rows: MlmPlanVersionSummary[] }>(`${PLAN}/versions`)).rows,
  getPlanVersion: (id) => get<MlmPlanTerms>(`${PLAN}/versions/${id}`),
  createPlanVersion: (input) => post<MlmPlanTerms>(`${PLAN}/versions`, input),
  updatePlanVersion: (id, input) => put<MlmPlanTerms>(`${PLAN}/versions/${id}`, input),
  setEligibleCourses: (id, eligibleCourseIds) => put<MlmPlanTerms>(`${PLAN}/versions/${id}/courses`, { eligibleCourseIds }),
  activatePlanVersion: (id) => post<MlmPlanTerms>(`${PLAN}/versions/${id}/activate`),
  retirePlanVersion: (id) => post<MlmPlanTerms>(`${PLAN}/versions/${id}/retire`),
  deletePlanDraft: async (id) => {
    await del<void>(`${PLAN}/versions/${id}`);
  },
  programCourses: async (tenantId) => (await get<{ rows: MlmProgramCourse[] }>(`${PLAN}/courses`, { tenantId })).rows,

  listMembers: (query) => get<MemberListResult>(`${BASE}/members`, query),
  getMember: (id) => get<AffiliateMemberRow>(`${BASE}/members/${id}`),
  setMemberStatus: (id, status, note) => patch<AffiliateMemberRow>(`${BASE}/members/${id}`, { status, note: note ?? '' }),
  memberTree: (id, depth) => get<TreeNodeView>(`${BASE}/members/${id}/tree`, { depth }),
  memberAncestors: async (id) => (await get<{ rows: TreeAncestor[] }>(`${BASE}/members/${id}/ancestors`)).rows,
  memberTeam: (id, query) => get<TeamPage>(`${BASE}/members/${id}/team`, query),
  placeMember: (id, input) => post<AffiliateMemberRow>(`${BASE}/members/${id}/placement`, input),
  changeSponsor: (id, sponsorId, reason) => patch<AffiliateMemberRow>(`${BASE}/members/${id}/sponsor`, { sponsorId, reason }),
  placements: (query) => get<PlacementListResult>(`${BASE}/placements`, query),
  sponsors: (query) => get<SponsorListResult>(`${BASE}/sponsors`, query),
  networkCsv: (root) => csv(`${BASE}/network/export.csv`, { root }, 'Could not export the network.'),

  products: () => get<MlmProducts>(`${BASE}/products`),
  setProducts: (eligibleCourseIds) => put<MlmProducts>(`${BASE}/products`, { eligibleCourseIds }),
  orders: (query) => get<OrderListResult>(`${BASE}/orders`, query),
  getOrder: (id) => get<MlmOrderRow>(`${BASE}/orders/${id}`),
  reverseOrder: (id, reason, note) => post<MlmOrderRow>(`${BASE}/orders/${id}/reverse`, { reason, note: note ?? '' }),
  cvLedger: (query) => get<CvLedgerResult>(`${BASE}/cv`, query),
  cvCsv: (query: MlmCvQuery = {}) => csv(`${BASE}/cv/export.csv`, { ...query }, 'Could not export the ledger.'),
  carryForward: (query) => get<CarryForwardResult>(`${BASE}/carry-forward`, query),
  adjustCarryForward: (id, input) => post<MlmLegFigures>(`${BASE}/members/${id}/carry-forward/adjust`, input),
};

/** Not JSON, so not `request`: the same bearer token, the body as text. */
export async function csv(path: string, query: Record<string, string | number | undefined>, failure: string): Promise<string> {
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries(query)) if (v !== undefined && v !== '') params.set(k, String(v));
  const qs = params.toString();
  const res = await fetch(`${API_BASE_URL}${path}${qs ? `?${qs}` : ''}`, { headers: { authorization: `Bearer ${getToken() ?? ''}` } });
  if (!res.ok) throw new ServiceError(failure, res.status === 404 ? 'not-found' : 'unknown', undefined, undefined, res.status);
  return res.text();
}
