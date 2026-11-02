import {
  defaultMlmPlanTerms,
  mlmActivationIssues,
  pricingOf,
  validateMlmPlanTerms,
  type AffiliateMemberRow,
  type AffiliateStatus,
  type MlmPlanIssue,
  type MlmPlanOverview,
  type MlmPlanTerms,
  type MlmPlanTermsInput,
  type MlmPlanVersionSummary,
  type MlmProgramCourse,
} from '@syniastrolms/domain';
import type { MemberListResult, MlmProducts, PlatformAffiliateService } from '../contracts';
import { ServiceError } from '../contracts';
import { cvCsv, getOrder, listCarryForward, listCvLedger, listOrders, reverseOrder } from './affiliateCv';
import { allNodes, ancestorsOf, byId, moveNode, placementRows, setSponsor, setStatus, sponsorRows, subtree, teamOf, toMember } from './affiliateTree';
import { mockNowIso } from './clock';
import { courses } from './fixtures/catalog';
import { respond } from './simulation';

const DEMO_WORKSPACE = 'tenant-1';

/*
 * The affiliate program in the demo build: one draft of the PDF's version 1, bound to the demo workspace, and the demo genealogy (`affiliateTree.ts`) for the member, network, placement and sponsor screens. The
 * same rules as the API — valid terms, one active version, a draft alone editable, placements by rule — so every
 * state of the screens can be reached without a server.
 */
const versions: MlmPlanTerms[] = [];

function seeded(): MlmPlanTerms[] {
  if (versions.length === 0) {
    versions.push({
      ...defaultMlmPlanTerms(DEMO_WORKSPACE),
      id: 'mlm-v1',
      version: 1,
      status: 'draft',
      createdAt: mockNowIso(),
      activatedAt: null,
      retiredAt: null,
    });
  }
  return versions;
}

const clone = <T>(value: T): T => structuredClone(value);

const summaryOf = (v: MlmPlanTerms): MlmPlanVersionSummary => ({
  id: v.id,
  version: v.version,
  status: v.status,
  programTenantId: v.programTenantId,
  tierCount: v.tiers.length,
  eligibleCourseCount: v.eligibleCourseIds.length,
  createdAt: v.createdAt,
  activatedAt: v.activatedAt,
  retiredAt: v.retiredAt,
  note: v.note,
});

function find(id: string): MlmPlanTerms {
  const v = seeded().find((x) => x.id === id);
  if (!v) throw new ServiceError('Affiliate plan version not found.', 'not-found');
  return v;
}

const refuse = (issues: MlmPlanIssue[]): never => {
  throw new ServiceError(issues[0].message, 'conflict', 'VALIDATION_FAILED', issues, 400);
};

const overview = (): MlmPlanOverview => ({
  active: clone(seeded().find((v) => v.status === 'active') ?? null),
  versions: [...seeded()].sort((a, b) => b.version - a.version).map(summaryOf),
});

const page = <T>(rows: T[], query: { page?: number; pageSize?: number } = {}, size = 20) => {
  const pageSize = query.pageSize ?? size;
  const current = query.page ?? 1;
  return { rows: rows.slice((current - 1) * pageSize, current * pageSize), total: rows.length, page: current, pageSize };
};

export const affiliatesPlatformService: PlatformAffiliateService = {
  plan: () => respond(overview),
  listPlanVersions: () => respond(() => overview().versions),
  getPlanVersion: (id) => respond(() => clone(find(id))),
  createPlanVersion: (input) =>
    respond(() => {
      const all = seeded();
      let terms: MlmPlanTermsInput;
      if ('tiers' in input) terms = input;
      else if (input.fromVersionId) terms = { ...find(input.fromVersionId), note: '' };
      else {
        const active = all.find((v) => v.status === 'active');
        terms = active ? { ...active, note: '' } : defaultMlmPlanTerms(input.programTenantId ?? DEMO_WORKSPACE);
      }
      const issues = validateMlmPlanTerms(terms);
      if (issues.length) refuse(issues);
      const version = Math.max(0, ...all.map((v) => v.version)) + 1;
      const created: MlmPlanTerms = {
        ...clone(terms),
        id: `mlm-v${version}`,
        version,
        status: 'draft',
        createdAt: mockNowIso(),
        activatedAt: null,
        retiredAt: null,
      };
      all.push(created);
      return clone(created);
    }),
  updatePlanVersion: (id, input) =>
    respond(() => {
      const current = find(id);
      if (current.status !== 'draft') throw new ServiceError('Only a draft version can be edited. Create a new version to change the plan.', 'conflict');
      const issues = validateMlmPlanTerms(input);
      if (issues.length) refuse(issues);
      Object.assign(current, clone(input));
      return clone(current);
    }),
  setEligibleCourses: (id, eligibleCourseIds) =>
    respond(() => {
      const current = find(id);
      if (current.status === 'retired') throw new ServiceError('A retired version cannot change.', 'conflict');
      if (current.status === 'active' && eligibleCourseIds.length === 0) refuse(mlmActivationIssues({ eligibleCourseIds }));
      current.eligibleCourseIds = [...eligibleCourseIds];
      return clone(current);
    }),
  activatePlanVersion: (id) =>
    respond(() => {
      const current = find(id);
      if (current.status !== 'draft')
        throw new ServiceError(current.status === 'active' ? 'This version is already active.' : 'A retired version cannot be activated again.', 'conflict');
      const issues = [...validateMlmPlanTerms(current), ...mlmActivationIssues(current)];
      if (issues.length) refuse(issues);
      const now = mockNowIso();
      for (const v of seeded()) {
        if (v.status === 'active') {
          v.status = 'retired';
          v.retiredAt = now;
        }
      }
      current.status = 'active';
      current.activatedAt = now;
      return clone(current);
    }),
  retirePlanVersion: (id) =>
    respond(() => {
      const current = find(id);
      if (current.status !== 'active')
        throw new ServiceError(current.status === 'draft' ? 'A draft is not active.' : 'This version is already retired.', 'conflict');
      current.status = 'retired';
      current.retiredAt = mockNowIso();
      return clone(current);
    }),
  deletePlanDraft: (id) =>
    respond(() => {
      const current = find(id);
      if (current.status !== 'draft') throw new ServiceError('Only a draft can be deleted.', 'conflict');
      versions.splice(versions.indexOf(current), 1);
    }),
  programCourses: () => respond(programCourseRows),

  listMembers: (query = {}) =>
    respond((): MemberListResult => {
      const search = query.search?.trim().toLowerCase();
      const all = allNodes().map(toMember);
      const rows = all.filter(
        (m) =>
          (!query.status || m.status === query.status) &&
          (query.rank === undefined || m.currentRankOrder === query.rank) &&
          (!query.kyc || m.kycStatus === query.kyc) &&
          (!search || m.name.toLowerCase().includes(search) || m.code.toLowerCase().includes(search) || m.email.includes(search)),
      );
      const counts = { all: all.length, pending: 0, active: 0, suspended: 0, terminated: 0 } as Record<AffiliateStatus | 'all', number>;
      for (const m of all) counts[m.status]++;
      return {
        ...page(
          rows.sort((a, b) => b.joinedAt.localeCompare(a.joinedAt)),
          query,
        ),
        counts,
      };
    }),
  getMember: (id) => respond((): AffiliateMemberRow => toMember(byId(id))),
  setMemberStatus: (id, status) => respond(() => toMember(setStatus(id, status))),
  memberTree: (id, depth) => respond(() => subtree(id, depth ?? 3)),
  memberAncestors: (id) => respond(() => ancestorsOf(id)),
  memberTeam: (id, query) => respond(() => teamOf(id, query)),
  placeMember: (id, input) => respond(() => toMember(moveNode(id, input))),
  changeSponsor: (id, sponsorId) => respond(() => toMember(setSponsor(id, sponsorId))),
  placements: (query = {}) =>
    respond(() =>
      page(
        placementRows().filter((r) => !query.affiliateId || r.affiliate.id === query.affiliateId),
        query,
        50,
      ),
    ),
  sponsors: (query = {}) =>
    respond(() => {
      const search = query.search?.trim().toLowerCase();
      return page(
        sponsorRows().filter((s) => !search || s.name.toLowerCase().includes(search) || s.code.toLowerCase().includes(search)),
        query,
      );
    }),
  networkCsv: (root) =>
    respond(() => {
      const rows = teamOf(root, { pageSize: 500 }).rows;
      return (
        [
          'code,name,status,leg,depth,sponsorCode,parentCode,placementLeg,joinedAt,activatedAt',
          ...rows.map((r) =>
            [r.code, r.name, r.status, r.leg, r.depth, r.sponsorCode, r.parentCode, r.placementLeg, r.joinedAt, r.activatedAt].map((v) => v ?? '').join(','),
          ),
        ].join('\n') + '\n'
      );
    }),

  products: () => respond(products),
  setProducts: (eligibleCourseIds) =>
    respond(() => {
      const active = seeded().find((v) => v.status === 'active');
      if (!active) throw new ServiceError('No affiliate plan version is active.', 'not-found');
      if (eligibleCourseIds.length === 0) throw new ServiceError('An active version needs at least one eligible course.', 'conflict');
      active.eligibleCourseIds = [...new Set(eligibleCourseIds)];
      return products();
    }),
  orders: (query) => respond(() => listOrders(query)),
  getOrder: (id) => respond(() => getOrder(id)),
  reverseOrder: (id, reason) => respond(() => reverseOrder(id, reason)),
  cvLedger: (query) => respond(() => listCvLedger(query)),
  cvCsv: (query) => respond(() => cvCsv(query)),
  carryForward: (query) => respond(() => listCarryForward(query)),
  adjustCarryForward: () => Promise.reject(new ServiceError('The demo ledger can’t be corrected. Sign in to a real installation.', 'conflict')),
};

const programCourseRows = (): MlmProgramCourse[] =>
  courses.map((c) => ({
    id: c.id,
    title: c.title,
    status: c.status,
    priceAmount: pricingOf(c) === 'paid' ? (c.price?.amount ?? null) : null,
    currency: 'INR',
  }));

function products(): MlmProducts {
  const active = seeded().find((v) => v.status === 'active');
  return {
    active: active
      ? { id: active.id, version: active.version, programTenantId: active.programTenantId, eligibleCourseIds: [...active.eligibleCourseIds] }
      : null,
    courses: programCourseRows(),
  };
}

/** For tests: forget everything the visit changed. */
export function resetAffiliatePlanMock() {
  versions.length = 0;
}
