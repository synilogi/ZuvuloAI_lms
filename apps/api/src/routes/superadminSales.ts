import { SITE_LIMITS as L } from '@syniastrolms/domain';
import { readSiteContent, saveSiteContent } from '../lib/siteContent.js';
import { Router, type NextFunction, type Request, type Response } from 'express';
import type { Prisma } from '@prisma/client';
import type { OrderRefund, PaymentEventRow, SalesOrderDetail, SalesOrderList, SalesOrderRow, SalesOrderStatus } from '@syniastrolms/domain';

import { createCoupon, listCoupons, updateCoupon } from '../lib/coupons.js';
import { refundCoursePurchase } from '../lib/courseRefunds.js';
import { db } from '../lib/db.js';
import { asyncHandler, notFound } from '../lib/errors.js';
import { workspaceId } from '../lib/requestContext.js';
import { runInTenant } from '../lib/tenancy.js';
import { optionalEnum, paging, parseBody, parseQuery, searchText, z } from '../lib/validate.js';

/*
 * `/superadmin/sales`: the platform's course orders, coupons and payment events (docs/16 §2.4). Inside the Super Admin router, so
 * its guard applies. Runs in the workspace, so the scoped tables read and stamp as everywhere else.
 */
export const superadminSalesRouter = Router();

superadminSalesRouter.use((_req: Request, _res: Response, next: NextFunction) => {
  workspaceId().then((id) => runInTenant(id, next), next);
});

const ORDER_INCLUDE = {
  course: { select: { id: true, title: true } },
  student: { select: { user: { select: { name: true, email: true } } } },
} as const;

type OrderRow = Prisma.CoursePurchaseGetPayload<{ include: typeof ORDER_INCLUDE }>;

const statusOf = (r: { status: string; refundedAt: Date | null }): SalesOrderStatus => (r.refundedAt ? 'refunded' : (r.status as SalesOrderStatus));

const toRow = (r: OrderRow): SalesOrderRow => ({
  id: r.id,
  orderNumber: r.orderNumber ?? r.id,
  learner: r.student.user ?? { name: 'Deleted account', email: '' },
  course: r.course,
  status: statusOf(r),
  amount: r.amount,
  discountAmount: r.discountAmount,
  ...(r.couponCode ? { couponCode: r.couponCode } : {}),
  listPrice: r.listPrice,
  currency: r.currency,
  provider: r.provider,
  environment: r.environment,
  providerOrderId: r.providerOrderId,
  ...(r.providerPaymentId ? { providerPaymentId: r.providerPaymentId } : {}),
  ...(r.reviewReason ? { reviewReason: r.reviewReason } : {}),
  createdAt: r.createdAt.toISOString(),
  ...(r.paidAt ? { paidAt: r.paidAt.toISOString() } : {}),
  ...(r.refundedAt ? { refundedAt: r.refundedAt.toISOString() } : {}),
});

const ORDER_STATUSES = ['created', 'paid', 'failed', 'expired', 'refunded'] as const;

function orderWhere(q: { status?: SalesOrderStatus; search?: string }): Prisma.CoursePurchaseWhereInput {
  const status: Prisma.CoursePurchaseWhereInput =
    q.status === 'refunded' ? { refundedAt: { not: null } } : q.status === 'paid' ? { status: 'paid', refundedAt: null } : q.status ? { status: q.status } : {};
  const search: Prisma.CoursePurchaseWhereInput = q.search
    ? {
        OR: [
          { orderNumber: { contains: q.search } },
          { providerPaymentId: { contains: q.search } },
          { course: { title: { contains: q.search } } },
          { student: { user: { OR: [{ name: { contains: q.search } }, { email: { contains: q.search } }] } } },
        ],
      }
    : {};
  return { ...status, ...search };
}

superadminSalesRouter.get(
  '/orders',
  asyncHandler(async (req, res) => {
    const q = parseQuery(req, z.object({ status: optionalEnum(ORDER_STATUSES), search: searchText, ...paging }));
    const where = orderWhere(q);
    const [rows, total, grouped, refunded, revenue] = await Promise.all([
      db.coursePurchase.findMany({ where, include: ORDER_INCLUDE, orderBy: { createdAt: 'desc' }, skip: (q.page - 1) * q.pageSize, take: q.pageSize }),
      db.coursePurchase.count({ where }),
      db.coursePurchase.groupBy({ by: ['status'], where: { refundedAt: null }, _count: { _all: true } }),
      db.coursePurchase.count({ where: { refundedAt: { not: null } } }),
      db.coursePurchase.aggregate({ where: { status: 'paid', refundedAt: null }, _sum: { amount: true } }),
    ]);
    const count = (s: string) => grouped.find((g) => g.status === s)?._count._all ?? 0;
    const body: SalesOrderList = {
      rows: rows.map(toRow),
      total,
      page: q.page,
      pageSize: q.pageSize,
      counts: {
        all: grouped.reduce((n, g) => n + g._count._all, 0) + refunded,
        created: count('created'),
        paid: count('paid'),
        failed: count('failed'),
        expired: count('expired'),
        refunded,
      },
      revenue: revenue._sum.amount ?? 0,
    };
    res.json(body);
  }),
);

/** A cell a spreadsheet will not run as a formula, quoted as CSV needs. */
const csvCell = (value: string | number) => {
  const text = String(value);
  const safe = /^[=+\-@\t\r]/.test(text) ? `'${text}` : text;
  return `"${safe.replace(/"/g, '""')}"`;
};

superadminSalesRouter.get(
  '/orders/export.csv',
  asyncHandler(async (req, res) => {
    const q = parseQuery(req, z.object({ status: optionalEnum(ORDER_STATUSES), search: searchText }));
    const rows = await db.coursePurchase.findMany({ where: orderWhere(q), include: ORDER_INCLUDE, orderBy: { createdAt: 'desc' }, take: 50_000 });
    const head = [
      'Order',
      'Date',
      'Learner',
      'Email',
      'Course',
      'Status',
      'List price (INR)',
      'Discount (INR)',
      'Coupon',
      'Paid (INR)',
      'Gateway',
      'Payment id',
    ];
    const lines = rows
      .map(toRow)
      .map((r) =>
        [
          r.orderNumber,
          r.createdAt,
          r.learner.name,
          r.learner.email,
          r.course.title,
          r.status,
          r.listPrice,
          (r.discountAmount / 100).toFixed(2),
          r.couponCode ?? '',
          (r.amount / 100).toFixed(2),
          r.provider,
          r.providerPaymentId ?? '',
        ]
          .map(csvCell)
          .join(','),
      );
    res
      .type('text/csv')
      .set('Content-Disposition', 'attachment; filename="orders.csv"')
      .send([head.map(csvCell).join(','), ...lines].join('\r\n'));
  }),
);

const toRefund = (r: {
  id: string;
  amount: number;
  reason: string;
  note: string | null;
  status: string;
  failureMessage: string | null;
  createdAt: Date;
  settledAt: Date | null;
}): OrderRefund => ({
  id: r.id,
  amount: r.amount,
  reason: r.reason,
  ...(r.note ? { note: r.note } : {}),
  status: r.status as OrderRefund['status'],
  ...(r.failureMessage ? { failureMessage: r.failureMessage } : {}),
  createdAt: r.createdAt.toISOString(),
  ...(r.settledAt ? { settledAt: r.settledAt.toISOString() } : {}),
});

async function orderDetail(id: string): Promise<SalesOrderDetail> {
  const row = await db.coursePurchase.findUnique({ where: { id }, include: { ...ORDER_INCLUDE, mlmOrder: { select: { id: true, status: true } } } });
  if (!row) throw notFound('Order not found.');
  const refunds = await db.coursePurchaseRefund.findMany({ where: { purchaseId: id }, orderBy: { createdAt: 'desc' } });
  const live = refunds.some((r) => r.status !== 'failed');
  return {
    ...toRow(row),
    refunds: refunds.map(toRefund),
    ...(row.mlmOrder ? { affiliateOrder: row.mlmOrder } : {}),
    canRefund: row.status === 'paid' && !row.refundedAt && !live,
  };
}

superadminSalesRouter.get(
  '/orders/:id',
  asyncHandler(async (req, res) => {
    res.json(await orderDetail(req.params.id));
  }),
);

superadminSalesRouter.post(
  '/orders/:id/refund',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({ reason: z.string().trim().min(3, 'Say why, in a few words.').max(200), note: z.string().trim().max(1000).optional() }),
    );
    await refundCoursePurchase(req, req.params.id, input);
    res.json(await orderDetail(req.params.id));
  }),
);

/* ─── Coupons ─── */

const when = z.string().datetime({ offset: true }).nullable().optional();

superadminSalesRouter.get(
  '/coupons',
  asyncHandler(async (_req, res) => {
    res.json({ rows: await listCoupons() });
  }),
);

superadminSalesRouter.post(
  '/coupons',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({
        code: z.string().trim().min(1, 'Enter a code.').max(32),
        description: z.string().trim().max(200).optional(),
        kind: z.enum(['percent', 'fixed']),
        percentBps: z.number().int().optional(),
        amountOff: z.number().int().optional(),
        startsAt: when,
        endsAt: when,
        maxUses: z.number().int().min(1).nullable().optional(),
        perLearnerLimit: z.number().int().min(1).max(100).optional(),
        courseId: z.string().trim().max(64).nullable().optional(),
      }),
    );
    res.status(201).json(await createCoupon(req, input));
  }),
);

superadminSalesRouter.patch(
  '/coupons/:id',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({
        description: z.string().trim().max(200).optional(),
        startsAt: when,
        endsAt: when,
        maxUses: z.number().int().min(1).nullable().optional(),
        perLearnerLimit: z.number().int().min(1).max(100).optional(),
        status: z.enum(['active', 'disabled']).optional(),
      }),
    );
    res.json(await updateCoupon(req, req.params.id, input));
  }),
);

/* ─── What the gateway reported ─── */

superadminSalesRouter.get(
  '/events',
  asyncHandler(async (req, res) => {
    const q = parseQuery(req, z.object({ ...paging }));
    const [rows, total] = await Promise.all([
      db.coursePaymentEvent.findMany({ orderBy: { receivedAt: 'desc' }, skip: (q.page - 1) * q.pageSize, take: q.pageSize }),
      db.coursePaymentEvent.count(),
    ]);
    const events: PaymentEventRow[] = rows.map((r) => ({
      id: r.id,
      provider: r.provider,
      eventId: r.eventId,
      eventType: r.eventType,
      processed: r.processedAt !== null,
      receivedAt: r.receivedAt.toISOString(),
    }));
    res.json({ rows: events, total, page: q.page, pageSize: q.pageSize });
  }),
);

/* The website's editable document: what it features, its testimonials and its questions (docs/16 §2.6). */
const siteContentBody = z
  .object({
    heroTitle: z.string().trim().min(3).max(L.heroTitle),
    heroText: z.string().trim().min(3).max(L.heroText),
    featuredCourseIds: z.array(z.string().min(1)).max(L.featured),
    testimonials: z
      .array(
        z.object({ quote: z.string().trim().min(3).max(L.quote), name: z.string().trim().min(1).max(L.name), role: z.string().trim().max(L.role) }).strict(),
      )
      .max(L.testimonials),
    faqs: z.array(z.object({ q: z.string().trim().min(3).max(L.q), a: z.string().trim().min(3).max(L.a) }).strict()).max(L.faqs),
  })
  .strict();

superadminSalesRouter.get(
  '/site',
  asyncHandler(async (_req, res) => {
    res.json(await readSiteContent());
  }),
);

superadminSalesRouter.put(
  '/site',
  asyncHandler(async (req, res) => {
    res.json(await saveSiteContent(req, parseBody(req, siteContentBody)));
  }),
);
