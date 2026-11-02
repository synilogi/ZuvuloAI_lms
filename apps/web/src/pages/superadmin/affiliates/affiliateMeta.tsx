import type { ReactNode } from 'react';
import {
  ArrowsLeftRight,
  ArrowsMerge,
  Bank,
  IdentificationCard,
  Medal,
  SquaresFour,
  Wallet,
  BookOpenText,
  CheckCircle,
  Handshake,
  HourglassMedium,
  Notebook,
  PencilSimpleLine,
  Prohibit,
  Ranking,
  Receipt,
  Scroll,
  TreeStructure,
  UserPlus,
  UsersThree,
} from '@phosphor-icons/react';
import type {
  AffiliateStatus,
  MlmCapOverflowPolicy,
  MlmCarryForwardPolicy,
  MlmOrderStatus,
  MlmPlanStatus,
  MlmRewardKind,
  MlmSpilloverRule,
} from '@syniastrolms/domain';
import { formatMoney, normaliseAffiliateCode } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';
import { Badge } from '@/components/ui/Badge/Badge';
import { RouteTabs } from '@/components/page/RouteTabs';

/** Everything in the affiliate area lives under one root, so the tabs and every link are built from it. */
export const AFFILIATES_BASE = '/superadmin/affiliates';
export const PLAN_PATH = `${AFFILIATES_BASE}/plan`;

/** The tabs of the affiliate area. */
export function AffiliateTabs() {
  return (
    <RouteTabs
      label="Affiliate program"
      tabs={[
        { to: `${AFFILIATES_BASE}/overview`, label: 'Overview', icon: <SquaresFour size={16} /> },
        { to: `${AFFILIATES_BASE}/members`, label: 'Members', icon: <UsersThree size={16} />, also: [`${AFFILIATES_BASE}/members/`] },
        { to: `${AFFILIATES_BASE}/network`, label: 'Network', icon: <TreeStructure size={16} /> },
        { to: `${AFFILIATES_BASE}/sponsors`, label: 'Sponsors', icon: <UserPlus size={16} /> },
        { to: `${AFFILIATES_BASE}/placements`, label: 'Placements', icon: <ArrowsLeftRight size={16} /> },
        { to: `${AFFILIATES_BASE}/orders`, label: 'Orders', icon: <Receipt size={16} /> },
        { to: `${AFFILIATES_BASE}/ledgers`, label: 'Ledgers', icon: <Notebook size={16} /> },
        { to: `${AFFILIATES_BASE}/matching`, label: 'Matching', icon: <ArrowsMerge size={16} /> },
        { to: `${AFFILIATES_BASE}/ranks`, label: 'Ranks', icon: <Ranking size={16} /> },
        { to: `${AFFILIATES_BASE}/rewards`, label: 'Rewards', icon: <Medal size={16} /> },
        { to: `${AFFILIATES_BASE}/wallets`, label: 'Wallets', icon: <Wallet size={16} /> },
        { to: `${AFFILIATES_BASE}/withdrawals`, label: 'Withdrawals', icon: <Bank size={16} /> },
        { to: `${AFFILIATES_BASE}/kyc`, label: 'Identity checks', icon: <IdentificationCard size={16} /> },
        { to: `${AFFILIATES_BASE}/products`, label: 'Courses', icon: <BookOpenText size={16} /> },
        { to: PLAN_PATH, label: 'Plan', icon: <Scroll size={16} />, also: [`${PLAN_PATH}/versions`] },
      ]}
    />
  );
}

export const AFFILIATE_EYEBROW = (
  <>
    <Handshake size={13} weight="fill" aria-hidden="true" /> Affiliate program
  </>
);

interface StateMeta {
  label: string;
  tone: Tone;
  icon: ReactNode;
  meaning: string;
}

export const PLAN_VERSION_STATE: Record<MlmPlanStatus, StateMeta> = {
  draft: { label: 'Draft', tone: 'neutral', icon: <PencilSimpleLine size={13} />, meaning: 'Being written. Nothing runs under it yet.' },
  active: { label: 'Active', tone: 'accent', icon: <CheckCircle size={13} />, meaning: 'The version the program runs under today.' },
  retired: { label: 'Retired', tone: 'warn', icon: <Prohibit size={13} />, meaning: 'Replaced or stopped. Kept because commissions were computed under it.' },
};

export function PlanVersionBadge({ status }: { status: MlmPlanStatus }) {
  const meta = PLAN_VERSION_STATE[status];
  return (
    <Badge size="sm" tone={meta.tone} icon={meta.icon} title={meta.meaning}>
      {meta.label}
    </Badge>
  );
}

export const AFFILIATE_STATE: Record<AffiliateStatus, StateMeta> = {
  pending: { label: 'Not active', tone: 'neutral', icon: <PencilSimpleLine size={13} />, meaning: 'Registered; the eligible course has not been bought yet.' },
  active: { label: 'Active', tone: 'accent', icon: <CheckCircle size={13} />, meaning: 'Earns matching income and counts towards ranks.' },
  suspended: { label: 'Suspended', tone: 'warn', icon: <Prohibit size={13} />, meaning: 'Paused by the platform; earns nothing while suspended.' },
  terminated: { label: 'Closed', tone: 'danger', icon: <Prohibit size={13} />, meaning: 'Closed for good; the position stays so the tree keeps its shape.' },
};

export function AffiliateStatusBadge({ status }: { status: AffiliateStatus }) {
  const meta = AFFILIATE_STATE[status];
  return (
    <Badge size="sm" tone={meta.tone} icon={meta.icon} title={meta.meaning}>
      {meta.label}
    </Badge>
  );
}

export const ORDER_STATE: Record<MlmOrderStatus, StateMeta> = {
  pending: {
    label: 'Waiting',
    tone: 'neutral',
    icon: <HourglassMedium size={13} />,
    meaning: 'Paid; counts once the plan’s delay passes and the buyer is placed.',
  },
  eligible: { label: 'Counted', tone: 'accent', icon: <CheckCircle size={13} />, meaning: 'Its CV is credited to every leg above the buyer.' },
  reversed: { label: 'Reversed', tone: 'warn', icon: <Prohibit size={13} />, meaning: 'Refunded or charged back; its credits were taken back.' },
};

export function OrderStatusBadge({ status }: { status: MlmOrderStatus }) {
  const meta = ORDER_STATE[status];
  return (
    <Badge size="sm" tone={meta.tone} icon={meta.icon} title={meta.meaning}>
      {meta.label}
    </Badge>
  );
}

export const REWARD_KIND_LABEL: Record<MlmRewardKind, string> = { recognition: 'Recognition', certificate: 'Certificate', cash: 'Cash' };

export const CAP_OVERFLOW_LABEL: Record<MlmCapOverflowPolicy, string> = {
  flush: 'Dropped (the day’s cap is final)',
  carry: 'Kept in the pools for a later day',
};

export const CARRY_FORWARD_LABEL: Record<MlmCarryForwardPolicy, string> = {
  indefinite: 'Kept until matched',
  'expire-days': 'Expires after a number of days',
};

export const SPILLOVER_LABEL: Record<MlmSpilloverRule, string> = {
  'extreme-outer': 'Outermost free position of the chosen leg',
  'breadth-first': 'First free position of the chosen leg, level by level',
};

/** Basis points as the percentage people read: 1000 → "10%", 1250 → "12.5%". */
export const percentOfBps = (bps: number): string => `${Number.isFinite(bps) ? (bps / 100).toLocaleString('en-IN', { maximumFractionDigits: 2 }) : '—'}%`;

const LAKH = 100_000 * 100;
const CRORE = 10_000_000 * 100;

/**
 * A minor-unit amount the way the plan reads: "₹5 Cr", "₹7.5 L", else the full figure. Group CV targets run to
 * ₹500 crore, which `formatMoney` would print as 11 digits.
 */
export function compactMoney(minor: number, currency = 'INR'): string {
  if (!Number.isFinite(minor)) return '—';
  if (currency !== 'INR' || Math.abs(minor) < LAKH) return formatMoney(minor, currency);
  const unit = Math.abs(minor) >= CRORE ? CRORE : LAKH;
  const value = minor / unit;
  return `₹${value.toLocaleString('en-IN', { maximumFractionDigits: 2 })} ${unit === CRORE ? 'Cr' : 'L'}`;
}

/** CV in minor units as people read it: 149900 → "1,499 CV". CV is volume, so it never wears a rupee sign. */
export const cvText = (minor: number): string => (Number.isFinite(minor) ? `${(minor / 100).toLocaleString('en-IN', { maximumFractionDigits: 2 })} CV` : '—');

/** A rank's large CV target: "5 Cr CV", "7.5 L CV", else the full figure. */
export function compactCv(minor: number): string {
  if (!Number.isFinite(minor)) return '—';
  if (Math.abs(minor) < LAKH) return cvText(minor);
  const unit = Math.abs(minor) >= CRORE ? CRORE : LAKH;
  return `${(minor / unit).toLocaleString('en-IN', { maximumFractionDigits: 2 })} ${unit === CRORE ? 'Cr' : 'L'} CV`;
}

/** A signed CV correction typed by a person, in minor units; undefined for anything that is not a non-zero amount of at most two decimals. */
export function parseSignedCv(text: string): number | undefined {
  const cleaned = text.replace(/[,\s]/g, '').replace(/^−/, '-');
  if (!/^[+-]?(\d+(\.\d{1,2})?|\.\d{1,2})$/.test(cleaned)) return undefined;
  const minor = Math.round(Number(cleaned) * 100);
  return minor !== 0 && Number.isSafeInteger(minor) ? minor : undefined;
}

/** The member a typed code names exactly: a directory search also matches fragments and names, and a correction must not land on a near miss. */
export const memberWithCode = <T extends { code: string }>(rows: T[], typed: string): T | undefined => {
  const code = normaliseAffiliateCode(typed);
  return rows.find((r) => r.code === code);
};

/** A DOM id for a validation issue's field: `tiers.3.groupCv` → `plan-tiers-3-groupCv`. */
export const fieldId = (field: string): string => `plan-${field.replace(/\./g, '-')}`;
