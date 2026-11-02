import { randomInt } from 'node:crypto';
import QRCode from 'qrcode';
import {
  affiliateCodeFrom,
  isAffiliateCode,
  joinLinkFor,
  normaliseAffiliateCode,
  referralLinkFor,
  type AffiliateActivation,
  type AffiliateActivationCourse,
  type AffiliateEnrolInput,
  type AffiliateMe,
  type AffiliateStatus,
  type MlmLeg,
  type MlmPlanTerms,
  type ReferralInfo,
} from '@syniastrolms/domain';
import type { Prisma } from '@prisma/client';

import { recordAuditLog, type AuditActor } from '../audit.js';
import { db, type DbClient } from '../db.js';
import { ApiError, conflict, notFound } from '../errors.js';
import { currentTenantId, runAsPlatform, runInTenant, tenant } from '../tenancy.js';
import { getSettings } from '../settings.js';
import { activeMlmPlan } from './plan.js';
import { placeAffiliate } from './placement.js';

/*
 * Affiliates (MLM-001; docs/15 §4.3, §6.2): a learner of the program academy who came in through a referral link or
 * opted in. This module is the writer of an affiliate's identity, sponsor, status and preferences; the genealogy
 * module (MLM-002) writes placement, the CV module (MLM-003) activates on the eligible purchase.
 *
 * Every door a learner can register through (`lib/learners.ts › createLearner`) calls `attachAffiliate` inside the
 * transaction that creates the account, so an account and its affiliate row never disagree. The referral code is
 * validated when the door opens, and again here, because the sponsor may have been terminated in between.
 *
 * Nothing here reads a rank's name or a plan's terms beyond "is a version active for this academy".
 */

export const AFFILIATE_AUDIT_ACTIONS = {
  enrolled: 'mlm.affiliate.enrolled',
  activated: 'mlm.affiliate.activated',
  preferredLegChanged: 'mlm.affiliate.preferred_leg_changed',
} as const;

/** The referral code on a link is malformed, unknown, or its sponsor is gone — one answer for all of them. */
export const referralInvalid = () =>
  new ApiError(404, 'This referral link isn’t valid. Ask the person who shared it for a fresh one, or join without one.', undefined, 'REFERRAL_INVALID');

const notAnAffiliate = () => new ApiError(404, 'You are not in the affiliate program.', undefined, 'NOT_AN_AFFILIATE');

const WITH_PEOPLE = {
  user: { select: { name: true } },
  sponsor: { select: { code: true, user: { select: { name: true } } } },
  placementParent: { select: { code: true } },
  tenant: { select: { name: true, slug: true, status: true } },
} satisfies Prisma.AffiliateInclude;
type AffiliateRow = Prisma.AffiliateGetPayload<{ include: typeof WITH_PEOPLE }>;

/** The site's public URL, which every link an affiliate shares is built on. */
export const siteBaseUrl = (): string => (process.env.APP_URL || process.env.CORS_ORIGIN || 'http://localhost:5173').replace(/\/+$/, '');

/** A code no affiliate has yet. Collisions are rare (32⁷ codes); a loop handles them anyway. */
export async function newAffiliateCode(client: DbClient = db): Promise<string> {
  for (let i = 0; i < 20; i++) {
    const code = affiliateCodeFrom(() => randomInt(0, 2 ** 31) / 2 ** 31);
    const taken = await runAsPlatform('affiliate codes are unique across the platform', () =>
      client.affiliate.findUnique({ where: { code }, select: { id: true } }),
    );
    if (!taken) return code;
  }
  throw new Error('Could not find a free affiliate code.');
}

/** The sponsor a code names, wherever they are; refused when malformed, unknown or terminated. */
export async function sponsorByCode(raw: string): Promise<AffiliateRow> {
  const code = normaliseAffiliateCode(raw);
  if (!isAffiliateCode(code)) throw referralInvalid();
  const row = await runAsPlatform('a referral code names its sponsor before any account exists', () =>
    db.affiliate.findUnique({ where: { code }, include: WITH_PEOPLE }),
  );
  if (!row || row.status === 'terminated' || row.tenant.status === 'archived') throw referralInvalid();
  return row;
}

/** The sponsor a code names, who must be in the given academy: a referral never crosses academies. */
export async function sponsorFor(tenantId: string, raw: string): Promise<AffiliateRow> {
  const sponsor = await sponsorByCode(raw);
  if (sponsor.tenantId !== tenantId) throw referralInvalid();
  return sponsor;
}

/** Whether a plan version is active for this academy, and its terms. */
export async function programFor(tenantId: string): Promise<MlmPlanTerms | null> {
  const plan = await runAsPlatform('the program academy is named by the active plan', () => activeMlmPlan());
  return plan && plan.programTenantId === tenantId ? plan : null;
}

/** What a referral link shows a visitor (`GET /public/affiliates/ref/:code`). */
export async function resolveReferral(raw: string): Promise<ReferralInfo> {
  const sponsor = await sponsorByCode(raw);
  const [{ general }, plan] = await Promise.all([runInTenant(sponsor.tenantId, () => getSettings()), programFor(sponsor.tenantId)]);
  let course: ReferralInfo['program']['course'] = null;
  if (plan?.eligibleCourseIds.length) {
    const first = await runInTenant(sponsor.tenantId, () =>
      db.course.findFirst({
        where: { id: { in: plan.eligibleCourseIds }, status: 'published' },
        select: { id: true, title: true, pricing: true, priceAmount: true },
        orderBy: { title: 'asc' },
      }),
    );
    if (first) course = { id: first.id, title: first.title, priceAmount: first.pricing === 'paid' ? (first.priceAmount ?? null) : null };
  }
  return {
    sponsor: { name: sponsor.user.name, code: sponsor.code },
    academy: {
      name: general.academyName || sponsor.tenant.name,
      slug: sponsor.tenant.slug,
      open: sponsor.tenant.status === 'active',
      invitationOnly: general.enrollment === 'invite',
    },
    program: { active: plan !== null, course },
    joinLink: joinLinkFor(siteBaseUrl(), sponsor.code),
  };
}

/** A referral resolved before the account is created: the sponsor it names, the leg their link named, and the registrant's own preference. */
export interface PreparedReferral {
  sponsorId: string;
  sponsorCode: string;
  preferredLeg: MlmLeg;
  requestedLeg: MlmLeg | null;
}

/**
 * Resolves a registration's referral *before* the account is created, so a bad code is refused while nothing exists.
 * With no code there is nothing to prepare: a learner without a sponsor is not an affiliate until they opt in
 * (D-MLM-06). A verified registration whose sponsor was terminated while the code was in the post is still created,
 * as the door promised — it simply joins without the program (`referralLenient`); a door that never checked the code
 * gets the refusal.
 */
export async function prepareReferral(
  tenantId: string,
  referral: { referralCode?: string; preferredLeg?: MlmLeg; requestedLeg?: MlmLeg; referralLenient?: boolean } | undefined,
): Promise<PreparedReferral | null> {
  if (!referral?.referralCode) return null;
  try {
    const sponsor = await sponsorFor(tenantId, referral.referralCode);
    return { sponsorId: sponsor.id, sponsorCode: sponsor.code, preferredLeg: referral.preferredLeg ?? 'A', requestedLeg: referral.requestedLeg ?? null };
  } catch (err) {
    if (referral.referralLenient && err instanceof ApiError && err.code === 'REFERRAL_INVALID') return null;
    throw err;
  }
}

/**
 * Creates the affiliate row for an account just created, right after the transaction that made it: the tenancy
 * extension checks every foreign key against committed rows, so the account must exist before its affiliate names it.
 * The referral was resolved before the account was made, so the only thing that can fail here is a code collision,
 * which `newAffiliateCode` retries.
 */
export async function attachAffiliate(account: { id: string; student: { id: string } | null }, referral: PreparedReferral | null): Promise<void> {
  if (!referral || !account.student) return;
  const code = await newAffiliateCode();
  const row = await db.affiliate.create({
    data: {
      ...tenant(),
      userId: account.id,
      studentId: account.student.id,
      code,
      sponsorId: referral.sponsorId,
      preferredLeg: referral.preferredLeg,
      requestedLeg: referral.requestedLeg,
    },
    select: { id: true },
  });
  // Placed at once (D-MLM-04); the scheduler's `mlm-placement` job catches anyone this could not place.
  await placeAffiliate(row.id).catch(() => undefined);
}

/** Checks a referral where a door opens, so a bad link is refused before an email goes out. */
export async function assertReferralUsable(tenantId: string, referralCode: string | undefined): Promise<void> {
  if (referralCode) await sponsorFor(tenantId, referralCode);
}

async function ownRow(auth: { sub: string }): Promise<AffiliateRow | null> {
  return db.affiliate.findUnique({ where: { userId: auth.sub }, include: WITH_PEOPLE });
}

async function toMe(row: AffiliateRow): Promise<AffiliateMe> {
  const [{ general }, plan] = await Promise.all([getSettings(), programFor(row.tenantId)]);
  const base = siteBaseUrl();
  return {
    id: row.id,
    code: row.code,
    status: row.status as AffiliateStatus,
    preferredLeg: row.preferredLeg as MlmLeg,
    sponsor: row.sponsor ? { name: row.sponsor.user.name, code: row.sponsor.code } : null,
    placement: row.placementParent && row.placementLeg ? { parentCode: row.placementParent.code, leg: row.placementLeg as MlmLeg, depth: row.depth } : null,
    activatedAt: row.activatedAt?.toISOString() ?? null,
    kycStatus: row.kycStatus,
    currentRankOrder: row.currentRankOrder,
    referralLink: referralLinkFor(base, row.code),
    joinLink: joinLinkFor(base, row.code),
    legLinks: { A: joinLinkFor(base, row.code, 'A'), B: joinLinkFor(base, row.code, 'B') },
    qrUrl: `/public/affiliates/ref/${row.code}/qr.svg`,
    academy: { name: general.academyName || row.tenant.name, slug: row.tenant.slug },
    programActive: plan !== null,
    createdAt: row.createdAt.toISOString(),
  };
}

/** The signed-in learner's own affiliate record, or null when they are not in the program. */
export async function affiliateMe(auth: { sub: string }): Promise<AffiliateMe | null> {
  const row = await ownRow(auth);
  return row ? toMe(row) : null;
}

export async function requireAffiliate(auth: { sub: string }): Promise<AffiliateRow> {
  const row = await ownRow(auth);
  if (!row) throw notAnAffiliate();
  return row;
}

/** A learner already in the academy opts in, naming a sponsor (or none). Audited. */
export async function enrolAffiliate(req: AuditActor & { auth: { sub: string; studentId?: string } }, input: AffiliateEnrolInput): Promise<AffiliateMe> {
  const existing = await ownRow(req.auth);
  if (existing) throw conflict('You are already in the affiliate program.');
  const tenantId = currentTenantId();
  const student = await db.student.findUnique({ where: { userId: req.auth.sub }, select: { id: true } });
  if (!student) throw notFound('Only a learner can join the affiliate program.');
  const sponsor = input.referralCode ? await sponsorFor(tenantId, input.referralCode) : null;
  const code = await newAffiliateCode();
  const id = await db.$transaction(async (tx) => {
    const row = await tx.affiliate.create({
      data: {
        ...tenant(),
        userId: req.auth.sub,
        studentId: student.id,
        code,
        sponsorId: sponsor?.id ?? null,
        preferredLeg: input.preferredLeg ?? 'A',
        requestedLeg: sponsor ? (input.requestedLeg ?? null) : null,
      },
      select: { id: true },
    });
    await recordAuditLog(
      req,
      { action: AFFILIATE_AUDIT_ACTIONS.enrolled, targetType: 'affiliate', targetId: row.id, meta: { code, sponsorCode: sponsor?.code ?? null } },
      tx,
    );
    // A learner who already bought the eligible course has done what activation asks: they cannot buy it twice.
    const plan = await activeMlmPlan();
    const paid = plan?.eligibleCourseIds.length
      ? await tx.coursePurchase.findFirst({
          where: { studentId: student.id, courseId: { in: plan.eligibleCourseIds }, status: 'paid', refundedAt: null, chargebackAt: null },
          select: { id: true },
        })
      : null;
    if (paid) await activateAffiliate(tx, student.id, paid.id, { job: 'affiliate-enrol' });
    return row.id;
  });
  await placeAffiliate(id).catch(() => undefined);
  const row = await db.affiliate.findUniqueOrThrow({ where: { id }, include: WITH_PEOPLE });
  return toMe(row);
}

/** Where the affiliate's own future referrals are placed. */
export async function setPreferredLeg(req: AuditActor & { auth: { sub: string } }, leg: MlmLeg): Promise<AffiliateMe> {
  const row = await requireAffiliate(req.auth);
  if (row.preferredLeg !== leg) {
    await db.$transaction(async (tx) => {
      await tx.affiliate.update({ where: { id: row.id }, data: { preferredLeg: leg } });
      await recordAuditLog(
        req,
        { action: AFFILIATE_AUDIT_ACTIONS.preferredLegChanged, targetType: 'affiliate', targetId: row.id, meta: { from: row.preferredLeg, to: leg } },
        tx,
      );
    });
  }
  return toMe(await db.affiliate.findUniqueOrThrow({ where: { id: row.id }, include: WITH_PEOPLE }));
}

/** The eligible courses and where the affiliate stands with each: what the activation card shows. */
export async function affiliateActivation(auth: { sub: string }): Promise<AffiliateActivation> {
  const row = await requireAffiliate(auth);
  const plan = await programFor(row.tenantId);
  let courses: AffiliateActivationCourse[] = [];
  if (plan?.eligibleCourseIds.length) {
    const [found, enrolments, purchases] = await Promise.all([
      db.course.findMany({
        where: { id: { in: plan.eligibleCourseIds } },
        select: { id: true, title: true, pricing: true, priceAmount: true },
        orderBy: { title: 'asc' },
      }),
      db.enrollment.findMany({ where: { studentId: row.studentId, courseId: { in: plan.eligibleCourseIds } }, select: { courseId: true } }),
      db.coursePurchase.findMany({ where: { studentId: row.studentId, courseId: { in: plan.eligibleCourseIds } }, select: { courseId: true, status: true } }),
    ]);
    const enrolled = new Set(enrolments.map((e) => e.courseId));
    courses = found.map((c) => {
      const bought = purchases.filter((p) => p.courseId === c.id);
      const purchase: AffiliateActivationCourse['purchase'] = enrolled.has(c.id)
        ? 'enrolled'
        : bought.some((p) => p.status === 'paid')
          ? 'paid'
          : bought.some((p) => p.status === 'created')
            ? 'pending'
            : 'none';
      return { id: c.id, title: c.title, priceAmount: c.pricing === 'paid' ? (c.priceAmount ?? null) : null, purchase };
    });
  }
  return { status: row.status as AffiliateStatus, activatedAt: row.activatedAt?.toISOString() ?? null, programActive: plan !== null, courses };
}

/**
 * The eligible purchase was paid: the affiliate is active from here (§6.2). Called inside the purchase's settlement
 * transaction by the CV module (MLM-003); idempotent, and a no-op for a learner who is not an affiliate.
 */
export async function activateAffiliate(tx: DbClient, studentId: string, purchaseId: string, source: { job?: string } = {}): Promise<boolean> {
  const row = await tx.affiliate.findUnique({ where: { studentId }, select: { id: true, status: true } });
  if (!row || row.status !== 'pending') return false;
  await tx.affiliate.update({ where: { id: row.id }, data: { status: 'active', activatedAt: new Date(), activationPurchaseId: purchaseId } });
  await recordAuditLog(
    { type: 'system', job: source.job ?? 'course-purchase' },
    { action: AFFILIATE_AUDIT_ACTIONS.activated, targetType: 'affiliate', targetId: row.id, meta: { purchaseId } },
    tx,
  );
  return true;
}

/** The referral link as an SVG QR code, for a page or a printed card. */
export async function referralQrSvg(code: string): Promise<string> {
  const sponsor = await sponsorByCode(code);
  return QRCode.toString(referralLinkFor(siteBaseUrl(), sponsor.code), { type: 'svg', margin: 1, errorCorrectionLevel: 'M' });
}
