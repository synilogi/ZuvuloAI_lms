import { isAffiliateCode, joinLinkFor, normaliseAffiliateCode, referralLinkFor, type AffiliateMe, type MlmLeg, type ReferralInfo } from '@syniastrolms/domain';
import type { AffiliateService } from '../contracts';
import { ServiceError } from '../contracts';
import { affiliateFigures, listCvLedger } from './affiliateCv';
import { DEMO_ACADEMY, addMember, byCode, byId, demoSponsor, referralsOf, resetTree, subtree, teamOf, type MockNode } from './affiliateTree';
import { courses } from './fixtures/catalog';
import { respond } from './simulation';

/*
 * The affiliate program for the demo learner: not in the program until they opt in, then a node of their own in the
 * demo genealogy (`affiliateTree.ts`), with a code, links, a team and referrals.
 */
const SITE = 'https://zuviloai.com';

let me: MockNode | null = null;

const QR_SVG = (code: string) =>
  `data:image/svg+xml;utf8,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" fill="#fff"/><text x="32" y="36" font-size="8" text-anchor="middle" font-family="monospace">${code}</text></svg>`)}`;

const referralInvalid = () =>
  new ServiceError('This referral link isn’t valid. Ask the person who shared it for a fresh one, or join without one.', 'not-found', 'REFERRAL_INVALID');
const notAnAffiliate = () => new ServiceError('You are not in the affiliate program.', 'not-found', 'NOT_AN_AFFILIATE');

const sponsorFor = (raw: string | undefined): MockNode | null => {
  if (!raw) return null;
  const code = normaliseAffiliateCode(raw);
  const node = isAffiliateCode(code) ? byCode(code) : undefined;
  if (!node || node.status === 'terminated') throw referralInvalid();
  return node;
};

const eligibleCourse = courses.find((c) => c.price && c.price.amount > 0) ?? courses[0];

const view = (n: MockNode): AffiliateMe => ({
  id: n.id,
  code: n.code,
  status: n.status,
  preferredLeg: n.preferredLeg,
  sponsor: n.sponsorId ? { name: byCodeOrId(n.sponsorId).name, code: byCodeOrId(n.sponsorId).code } : null,
  placement: n.parentId && n.leg ? { parentCode: byCodeOrId(n.parentId).code, leg: n.leg, depth: n.path.length } : null,
  activatedAt: n.activatedAt,
  kycStatus: n.kycStatus,
  currentRankOrder: n.currentRankOrder,
  referralLink: referralLinkFor(SITE, n.code),
  joinLink: joinLinkFor(SITE, n.code),
  legLinks: { A: joinLinkFor(SITE, n.code, 'A'), B: joinLinkFor(SITE, n.code, 'B') },
  qrUrl: QR_SVG(n.code),
  academy: { name: DEMO_ACADEMY.name, slug: DEMO_ACADEMY.slug },
  programActive: true,
  createdAt: n.joinedAt,
});

const byCodeOrId = (id: string): MockNode => byId(id);

const requireMe = (): MockNode => {
  if (!me) throw notAnAffiliate();
  return me;
};

export const affiliateService: AffiliateService = {
  me: () => respond(() => (me ? view(me) : null)),
  enrol: (input) =>
    respond(() => {
      if (me) throw new ServiceError('You are already in the affiliate program.', 'conflict');
      const sponsor = sponsorFor(input.referralCode);
      me = addMember('Ananya Rao', sponsor?.code, input.preferredLeg ?? 'A', input.requestedLeg ?? null);
      return view(me);
    }),
  setPreferredLeg: (leg: MlmLeg) =>
    respond(() => {
      requireMe().preferredLeg = leg;
      return view(me!);
    }),
  activation: () =>
    respond(() => {
      const n = requireMe();
      return {
        status: n.status,
        activatedAt: n.activatedAt,
        programActive: true,
        courses: [{ id: eligibleCourse.id, title: eligibleCourse.title, priceAmount: eligibleCourse.price?.amount ?? 10_000, purchase: 'none' as const }],
      };
    }),
  referral: (code) =>
    respond((): ReferralInfo => {
      const sponsor = sponsorFor(code);
      if (!sponsor) throw referralInvalid();
      return {
        sponsor: { name: sponsor.name, code: sponsor.code },
        academy: { ...DEMO_ACADEMY, open: true, invitationOnly: false },
        program: { active: true, course: { id: eligibleCourse.id, title: eligibleCourse.title, priceAmount: eligibleCourse.price?.amount ?? 10_000 } },
        joinLink: joinLinkFor(SITE, sponsor.code),
      };
    }),
  qrUrl: (code) => QR_SVG(code),
  tree: (root, depth) =>
    respond(() => {
      const n = requireMe();
      const id = root ?? n.id;
      if (id !== n.id && !byCodeOrId(id).path.includes(n.id)) throw new ServiceError('That affiliate is not in your team.', 'not-found');
      return subtree(id, depth ?? 3);
    }),
  team: (query) => respond(() => teamOf(requireMe().id, query)),
  referrals: () => respond(() => referralsOf(requireMe().id)),
  figures: () => respond(() => affiliateFigures(requireMe().id)),
  // The demo takes no payments, so its learner has no purchases to list.
  orders: ({ page = 1, pageSize = 20 } = {}) => respond(() => (requireMe(), { rows: [], total: 0, page, pageSize })),
  cvLedger: (query = {}) => respond(() => listCvLedger({ ...query, affiliateId: requireMe().id })),
};

/** The fixture sponsor's code, for pages and tests that open a referral link in the demo. */
export const DEMO_SPONSOR_CODE = demoSponsor().code;

/** For tests: forget the visit's opt-in and rebuild the demo tree. */
export function resetAffiliateMock() {
  me = null;
  resetTree();
}
