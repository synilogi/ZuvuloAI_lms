import type { Request } from 'express';
import { couponDiscount, isCouponCode, normaliseCouponCode, type Coupon, type CouponInput, type CouponTerms, type CouponUpdate } from '@syniastrolms/domain';
import type { Coupon as CouponRow } from '@prisma/client';

import { recordAuditLog } from './audit.js';
import { db, type DbClient } from './db.js';
import { ApiError, badRequest, conflict, notFound } from './errors.js';
import { tenant } from './tenancy.js';

/*
 * Coupons (docs/16 §2.4). A coupon's code and discount are fixed by trigger: what past orders took off must stay explicable,
 * so a different discount is a different coupon. A use is counted when an order is paid (`redeemCoupon`, inside the
 * settlement). Orders still open hold a place too, so a limited coupon cannot be spent twice by two checkouts at once;
 * a payment that arrives anyway is honoured, since the money has been taken.
 */

const refused = (message: string) => new ApiError(409, message, [{ field: 'couponCode', message }], 'COUPON_INVALID');

const termsOf = (row: CouponRow): CouponTerms =>
  row.kind === 'percent' ? { kind: 'percent', percentBps: row.percentBps! } : { kind: 'fixed', amountOff: row.amountOff! };

const toCoupon = (row: CouponRow & { course?: { id: string; title: string } | null }): Coupon => ({
  id: row.id,
  code: row.code,
  description: row.description,
  kind: row.kind as Coupon['kind'],
  ...(row.percentBps !== null ? { percentBps: row.percentBps } : {}),
  ...(row.amountOff !== null ? { amountOff: row.amountOff } : {}),
  ...(row.startsAt ? { startsAt: row.startsAt.toISOString() } : {}),
  ...(row.endsAt ? { endsAt: row.endsAt.toISOString() } : {}),
  maxUses: row.maxUses,
  perLearnerLimit: row.perLearnerLimit,
  ...(row.course ? { course: row.course } : {}),
  status: row.status as Coupon['status'],
  usedCount: row.usedCount,
  createdAt: row.createdAt.toISOString(),
});

/**
 * The coupon a learner typed, if it can be used on this course now, and what it takes off `charge`. Every refusal says why
 * in the learner's words, except that an unknown code and a disabled one read alike.
 */
export async function resolveCoupon(
  rawCode: string,
  input: { courseId: string; studentId: string; charge: number; ignorePurchaseId?: string },
  at = new Date(),
) {
  const code = normaliseCouponCode(rawCode);
  const row = await db.coupon.findFirst({ where: { code } });
  if (!row || row.status !== 'active') throw refused('That coupon code isn’t valid.');
  if (row.startsAt && row.startsAt > at) throw refused('That coupon isn’t open yet.');
  if (row.endsAt && row.endsAt <= at) throw refused('That coupon has expired.');
  if (row.courseId && row.courseId !== input.courseId) throw refused('That coupon is for another course.');
  const open = { couponId: row.id, status: 'created', expiresAt: { gt: at }, ...(input.ignorePurchaseId ? { id: { not: input.ignorePurchaseId } } : {}) };
  if (row.maxUses !== null) {
    const held = await db.coursePurchase.count({ where: { ...open, studentId: { not: input.studentId } } });
    if (row.usedCount + held >= row.maxUses) throw refused('That coupon has been fully used.');
  }
  // An order this learner has open elsewhere holds a use too, or two open orders could spend a one-use coupon twice.
  const mine = await db.couponRedemption.count({ where: { couponId: row.id, studentId: input.studentId } });
  const openElsewhere = await db.coursePurchase.count({ where: { ...open, studentId: input.studentId, courseId: { not: input.courseId } } });
  if (mine + openElsewhere >= row.perLearnerLimit) throw refused('You have already used that coupon.');
  const discount = couponDiscount(input.charge, termsOf(row));
  if (discount <= 0) throw refused('That coupon takes nothing off this course.');
  return { coupon: row, discount };
}

/** Counts a coupon's use: inside the settlement that took the money, once per order. */
export async function redeemCoupon(tx: DbClient, purchase: { id: string; couponId: string | null; studentId: string; discountAmount: number }) {
  if (!purchase.couponId) return;
  await tx.couponRedemption.create({
    data: { ...tenant(), couponId: purchase.couponId, purchaseId: purchase.id, studentId: purchase.studentId, discountAmount: purchase.discountAmount },
  });
  await tx.coupon.update({ where: { id: purchase.couponId }, data: { usedCount: { increment: 1 } } });
}

const WITH_COURSE = { course: { select: { id: true, title: true } } } as const;
const dateOf = (value: string | null | undefined) => (value ? new Date(value) : value === null ? null : undefined);

function checkWindow(startsAt: Date | null | undefined, endsAt: Date | null | undefined) {
  if (startsAt && endsAt && endsAt <= startsAt)
    throw badRequest('A coupon must end after it starts.', [{ field: 'endsAt', message: 'A coupon must end after it starts.' }]);
}

export async function listCoupons(): Promise<Coupon[]> {
  const rows = await db.coupon.findMany({ orderBy: { createdAt: 'desc' }, include: WITH_COURSE, take: 500 });
  return rows.map(toCoupon);
}

export async function createCoupon(req: Request, input: CouponInput): Promise<Coupon> {
  const code = normaliseCouponCode(input.code);
  const issue = (field: string, message: string) => badRequest(message, [{ field, message }]);
  if (!isCouponCode(code)) throw issue('code', 'A code is 3 to 32 letters, digits, hyphens or underscores.');
  if (input.kind === 'percent' && !(Number.isInteger(input.percentBps) && input.percentBps! >= 1 && input.percentBps! <= 10000))
    throw issue('percentBps', 'Enter a percentage from 0.01 to 100.');
  if (input.kind === 'fixed' && !(Number.isInteger(input.amountOff) && input.amountOff! > 0)) throw issue('amountOff', 'Enter an amount above zero.');
  const startsAt = dateOf(input.startsAt);
  const endsAt = dateOf(input.endsAt);
  checkWindow(startsAt, endsAt);
  if (input.courseId && !(await db.course.findUnique({ where: { id: input.courseId }, select: { id: true } }))) throw notFound('Course not found.');
  if (await db.coupon.findFirst({ where: { code }, select: { id: true } }))
    throw conflict('A coupon with this code already exists.', [{ field: 'code', message: 'A coupon with this code already exists.' }]);
  const row = await db.coupon.create({
    data: {
      ...tenant(),
      code,
      description: input.description?.trim() ?? '',
      kind: input.kind,
      percentBps: input.kind === 'percent' ? input.percentBps! : null,
      amountOff: input.kind === 'fixed' ? input.amountOff! : null,
      startsAt: startsAt ?? null,
      endsAt: endsAt ?? null,
      maxUses: input.maxUses ?? null,
      perLearnerLimit: input.perLearnerLimit ?? 1,
      courseId: input.courseId ?? null,
      createdById: req.auth?.sub ?? null,
    },
    include: WITH_COURSE,
  });
  await recordAuditLog(req, {
    action: 'coupon.created',
    targetType: 'coupon',
    targetId: row.id,
    meta: { code, kind: row.kind, percentBps: row.percentBps, amountOff: row.amountOff },
  });
  return toCoupon(row);
}

export async function updateCoupon(req: Request, id: string, input: CouponUpdate): Promise<Coupon> {
  const current = await db.coupon.findUnique({ where: { id } });
  if (!current) throw notFound('Coupon not found.');
  const startsAt = dateOf(input.startsAt);
  const endsAt = dateOf(input.endsAt);
  checkWindow(startsAt === undefined ? current.startsAt : startsAt, endsAt === undefined ? current.endsAt : endsAt);
  const row = await db.coupon.update({
    where: { id },
    data: {
      ...(input.description !== undefined ? { description: input.description.trim() } : {}),
      ...(startsAt !== undefined ? { startsAt } : {}),
      ...(endsAt !== undefined ? { endsAt } : {}),
      ...(input.maxUses !== undefined ? { maxUses: input.maxUses } : {}),
      ...(input.perLearnerLimit !== undefined ? { perLearnerLimit: input.perLearnerLimit } : {}),
      ...(input.status !== undefined ? { status: input.status } : {}),
    },
    include: WITH_COURSE,
  });
  await recordAuditLog(req, { action: 'coupon.updated', targetType: 'coupon', targetId: id, meta: { code: row.code, changed: Object.keys(input) } });
  return toCoupon(row);
}
