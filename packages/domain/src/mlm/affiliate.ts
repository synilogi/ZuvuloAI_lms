import type { MlmLeg } from './plan';

/*
 * Affiliates (docs/15 §4.3, §6.2): a learner of the program academy who joined through a referral or opted in. The
 * affiliate code is the referral credential on every link and QR, so it is short, unambiguous to read aloud and
 * check-digited, so a mistyped code is refused before it is looked up.
 */

export type AffiliateStatus = 'pending' | 'active' | 'suspended' | 'terminated';
export const AFFILIATE_STATUSES: readonly AffiliateStatus[] = ['pending', 'active', 'suspended', 'terminated'];

/** 32 characters with no 0/O or 1/I, so a code survives being read over the phone. */
export const AFFILIATE_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
export const AFFILIATE_CODE_LENGTH = 8;

const value = (ch: string): number => AFFILIATE_CODE_ALPHABET.indexOf(ch);

/** The check character for the first seven: a position-weighted sum modulo the alphabet. */
function checkChar(body: string): string {
  let sum = 0;
  for (let i = 0; i < body.length; i++) sum += (i + 1) * value(body[i]);
  return AFFILIATE_CODE_ALPHABET[sum % AFFILIATE_CODE_ALPHABET.length];
}

/** A new code from a source of randomness in [0, 1): seven random characters and their check character. */
export function affiliateCodeFrom(random: () => number = Math.random): string {
  let body = '';
  for (let i = 0; i < AFFILIATE_CODE_LENGTH - 1; i++)
    body += AFFILIATE_CODE_ALPHABET[Math.floor(random() * AFFILIATE_CODE_ALPHABET.length) % AFFILIATE_CODE_ALPHABET.length];
  return body + checkChar(body);
}

/** Upper case, with the spaces and hyphens people add when they copy a code by hand removed. */
export const normaliseAffiliateCode = (raw: string): string => raw.trim().toUpperCase().replace(/[\s-]/g, '');

/** Whether a (normalised) code has the right shape and its check character holds. */
export function isAffiliateCode(code: string): boolean {
  if (code.length !== AFFILIATE_CODE_LENGTH) return false;
  for (const ch of code) if (value(ch) < 0) return false;
  return checkChar(code.slice(0, -1)) === code[code.length - 1];
}

/** The link an affiliate shares: the site resolves the code and sends the visitor on to register. */
export const referralLinkFor = (baseUrl: string, code: string): string => `${baseUrl.replace(/\/+$/, '')}/ref/${code}`;

/** The registration page with the referral already filled in, and the leg the sponsor chose for this referral. */
export const joinLinkFor = (baseUrl: string, code: string, leg?: MlmLeg): string =>
  `${baseUrl.replace(/\/+$/, '')}/register?ref=${code}${leg ? `&leg=${leg}` : ''}`;

/** The leg a link's `?leg=` names, or undefined for anything else: a stray value is no reason to refuse a registration. */
export const legFromLink = (raw: string | null | undefined): MlmLeg | undefined => {
  const leg = raw?.trim().toUpperCase();
  return leg === 'A' || leg === 'B' ? leg : undefined;
};

/** What a visitor sees when they open a referral link, before any account exists. */
export interface ReferralInfo {
  sponsor: { name: string; code: string };
  academy: { name: string; slug: string; open: boolean; invitationOnly: boolean };
  /** Whether a plan version is active for this academy, and the first eligible course for the activation card. */
  program: { active: boolean; course: { id: string; title: string; priceAmount: number | null } | null };
  joinLink: string;
}

/** An eligible course and where the learner stands with it. */
export interface AffiliateActivationCourse {
  id: string;
  title: string;
  /** Whole rupees, or null when the course cannot be sold. */
  priceAmount: number | null;
  /** `none` (not bought), `pending` (a checkout is open), `paid` (bought; activation follows the plan), `enrolled` (has the course). */
  purchase: 'none' | 'pending' | 'paid' | 'enrolled';
}

export interface AffiliateActivation {
  status: AffiliateStatus;
  activatedAt: string | null;
  /** No active plan version: nothing to buy yet. */
  programActive: boolean;
  courses: AffiliateActivationCourse[];
}

/** The signed-in affiliate's own record, as the home page shows it. */
export interface AffiliateMe {
  id: string;
  code: string;
  status: AffiliateStatus;
  preferredLeg: MlmLeg;
  sponsor: { name: string; code: string } | null;
  placement: { parentCode: string; leg: MlmLeg; depth: number } | null;
  activatedAt: string | null;
  kycStatus: string;
  currentRankOrder: number;
  referralLink: string;
  joinLink: string;
  /** Links that place the person who joins on one named leg, whatever the preferred leg is. */
  legLinks: Record<MlmLeg, string>;
  qrUrl: string;
  academy: { name: string; slug: string };
  programActive: boolean;
  createdAt: string;
}

export interface AffiliateEnrolInput {
  referralCode?: string;
  /** Where this member's own future referrals go. */
  preferredLeg?: MlmLeg;
  /** The leg of the sponsor that the sponsor's link named. */
  requestedLeg?: MlmLeg;
}

/** What an affiliate's own registration adds to the door's input. */
export interface AffiliateReferralInput {
  referralCode?: string;
  preferredLeg?: MlmLeg;
  requestedLeg?: MlmLeg;
}

/** A paid purchase of an eligible course, as the member who bought it sees it. Amounts in minor units. */
export interface AffiliateOrderRow {
  id: string;
  course: { id: string; title: string };
  orderNumber: string | null;
  amount: number;
  currency: string;
  paidAt: string | null;
  status: string;
  refunded: boolean;
  /** The bank reported a lost dispute on this payment. */
  chargedBack: boolean;
}
