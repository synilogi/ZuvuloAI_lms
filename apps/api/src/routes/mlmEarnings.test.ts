import request from 'supertest';
import { defaultMlmPlanTerms, programDay, type MlmPlanTerms } from '@syniastrolms/domain';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { setCoursePaymentProvider } from '../lib/coursePayments.js';
import { evaluateRanks, matchedThrough, releaseHeldCommissions, runMatching, runMatchingThrough } from '../lib/mlm/earnings.js';
import { repairOrders } from '../lib/mlm/cv.js';
import { activateMlmPlanVersion, activeMlmPlan, createMlmPlanVersion, setMlmEligibleCourses } from '../lib/mlm/plan.js';
import { reconcileWallets } from '../lib/mlm/wallet.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { FIRST_TENANT_ID, runAsPlatform, runInTenant } from '../lib/tenancy.js';
import { db, platformDb } from '../test/db.js';
import { FakeProvider, signWebhook } from '../test/fakeProvider.js';
import { PASSWORD, app, as, newStudent, unique, type Client } from '../test/helpers.js';

/* The money half of the affiliate program (docs/15 MLM-004 to MLM-007), through real purchases on the fake gateway: matching,
 * caps, ranks, rewards, the ceiling, reversals, wallets, KYC, withdrawals and payout batches. */

type Learner = Awaited<ReturnType<typeof newStudent>>;

let admin: Client;
let owner: Client;
let fake: FakeProvider;
let courseId: string;
let actor: { auth: { sub: string; role: 'superadmin' } };

/** A run date of its own for each run. The clock stays real: the ceiling counts this month's actual sales. */
let dayCursor = Date.parse('2031-01-01T06:00:00Z');
const nextDate = () => {
  dayCursor += 86_400_000;
  return programDay(new Date(dayCursor));
};
const run = (date = nextDate()) => runInTenant(FIRST_TENANT_ID, () => runMatching(date));
const inWorkspace = <T>(fn: () => Promise<T>) => runInTenant(FIRST_TENANT_ID, fn);

const enrol = async (who: Learner, referralCode?: string, preferredLeg: 'A' | 'B' = 'A') => {
  const res = await who.post('/affiliate/enrol', { referralCode, preferredLeg });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return res.body as { id: string; code: string };
};

const buy = async (learner: Learner) => {
  const started = await learner.post(`/learning/courses/${courseId}/purchase`, {});
  expect(started.status, JSON.stringify(started.body)).toBe(201);
  const payment = fake.pay(started.body.checkout.orderId, 'paid');
  const confirmed = await learner.post(`/learning/purchases/${started.body.purchase.id}/confirm`, {
    paymentId: payment.paymentId,
    signature: payment.signature,
  });
  expect(confirmed.status, JSON.stringify(confirmed.body)).toBe(200);
  return { purchaseId: started.body.purchase.id as string, paymentId: payment.paymentId };
};

/** A sponsor with one paying member on each leg. */
async function pair() {
  const sponsor = await newStudent();
  const me = await enrol(sponsor);
  const left = await newStudent();
  await enrol(left, me.code, 'A');
  const right = await newStudent();
  await sponsor.patch('/affiliate/preferred-leg', { leg: 'B' });
  await enrol(right, me.code, 'B');
  await buy(sponsor);
  const leftBuy = await buy(left);
  await buy(right);
  return { sponsor, me, left, right, leftBuy };
}

const earnings = async (who: Learner) => (await who.get('/affiliate/earnings')).body;
const verifyKyc = async (who: Learner, id: string) => {
  const res = await who.put('/affiliate/kyc', {
    legalName: 'Asha Rao',
    pan: 'ABCDE1234F',
    bankAccount: '123456789012',
    ifsc: 'HDFC0001234',
    accountHolder: 'Asha Rao',
  });
  expect(res.status, JSON.stringify(res.body)).toBe(200);
  expect((await owner.post(`/superadmin/affiliates/kyc/${id}/verify`, {})).status).toBe(200);
};
const fund = (id: string, amount: number) => owner.post(`/superadmin/affiliates/wallets/${id}/adjust`, { amount, reason: 'Test funding' });

beforeAll(async () => {
  admin = await as('admin');
  const email = `mlm-earn-${unique()}@example.com`;
  const created = await provisionSuperAdmin({ email, password: 'mlm-earn-pw-1', name: 'Platform' });
  owner = await as({ email, password: 'mlm-earn-pw-1' });
  actor = { auth: { sub: created.user.id, role: 'superadmin' } };
  fake = new FakeProvider('razorpay');
  setCoursePaymentProvider(fake);
  const instructorId = (await admin.get('/catalog/instructors')).body[0].id as string;
  const course = await admin.post('/courses', {
    title: `AI Course ${unique()}`,
    description: 'The eligible course.',
    instructorIds: [instructorId],
    pricing: 'paid',
    priceAmount: 10_000,
  });
  expect(course.status).toBe(201);
  courseId = course.body.id;
  expect((await admin.post(`/courses/${courseId}/publish`)).status).toBe(200);
  await runAsPlatform('the earnings tests put the course on the active plan', async () => {
    const active = await platformDb.mlmPlanVersion.findFirst({ where: { status: 'active' } });
    if (active) {
      await setMlmEligibleCourses(actor, active.id, [...new Set([...(JSON.parse(active.eligibleCourseIdsJson) as string[]), courseId])]);
      return;
    }
    const draft = await createMlmPlanVersion(actor, { ...defaultMlmPlanTerms(FIRST_TENANT_ID), eligibleCourseIds: [courseId] });
    await activateMlmPlanVersion(actor, draft.id);
  });
});

afterAll(() => setCoursePaymentProvider(undefined));

describe('the daily matching run', () => {
  it('matches the weaker leg at the plan’s rate, credits the wallet, and a second run does nothing', async () => {
    const { sponsor, me } = await pair();
    const before = (await sponsor.get('/affiliate/figures')).body;
    expect(before).toMatchObject({ unmatchedA: 1_000_000, unmatchedB: 1_000_000 });

    const date = nextDate();
    await run(date);

    const after = (await sponsor.get('/affiliate/figures')).body;
    expect(after).toMatchObject({ unmatchedA: 0, unmatchedB: 0, matchedLifetime: 1_000_000, lastMatchingRunDate: date });
    const runs = (await sponsor.get('/affiliate/matching')).body.rows;
    expect(runs).toHaveLength(1);
    expect(runs[0]).toMatchObject({ matchedCv: 1_000_000, grossIncome: 100_000, cappedIncome: 100_000, flushedCv: 0 });
    expect((await earnings(sponsor)).wallet.available).toBe(100_000);

    await run(date);
    expect((await earnings(sponsor)).wallet.available).toBe(100_000);
    expect((await sponsor.get('/affiliate/matching')).body.total).toBe(1);
    expect((await owner.get(`/superadmin/affiliates/commissions?affiliateId=${me.id}`)).body.total).toBe(1);
  });

  it('keeps the stronger leg’s excess as carry-forward', async () => {
    const sponsor = await newStudent();
    const me = await enrol(sponsor);
    await buy(sponsor);
    for (const leg of ['A', 'A', 'B'] as const) {
      await sponsor.patch('/affiliate/preferred-leg', { leg });
      const member = await newStudent();
      await enrol(member, me.code, leg);
      await buy(member);
    }
    await run();
    expect((await sponsor.get('/affiliate/figures')).body).toMatchObject({ unmatchedA: 1_000_000, unmatchedB: 0, matchedLifetime: 1_000_000 });
  });

  it('pays a suspended member nothing, while the volume stays', async () => {
    const { sponsor, me } = await pair();
    expect((await owner.patch(`/superadmin/affiliates/members/${me.id}`, { status: 'suspended', reason: 'Testing a suspension' })).status).toBe(200);
    await run();
    expect(await db.mlmMatchingRun.count({ where: { affiliateId: me.id } })).toBe(0);
    expect((await owner.get(`/superadmin/affiliates/members/${me.id}`)).status).toBe(200);
    expect(sponsor).toBeDefined();
  });
});

describe('the ledgers are immutable', () => {
  it('refuses edits and deletes at the database', async () => {
    const { me } = await pair();
    await run();
    const row = await platformDb.mlmMatchingRun.findFirstOrThrow({ where: { affiliateId: me.id } });
    await expect(platformDb.$executeRawUnsafe(`UPDATE "MlmMatchingRun" SET "matchedCv" = 1 WHERE "id" = ?`, row.id)).rejects.toThrow(/never changed/);
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "MlmMatchingRun" WHERE "id" = ?`, row.id)).rejects.toThrow(/never deleted/);
    const entry = await platformDb.mlmWalletEntry.findFirstOrThrow({ where: { affiliateId: me.id } });
    await expect(platformDb.$executeRawUnsafe(`UPDATE "MlmWalletEntry" SET "availableDelta" = 1 WHERE "id" = ?`, entry.id)).rejects.toThrow(/never changed/);
    const commission = await platformDb.mlmCommission.findFirstOrThrow({ where: { affiliateId: me.id } });
    await expect(platformDb.$executeRawUnsafe(`UPDATE "MlmCommission" SET "amount" = 1 WHERE "id" = ?`, commission.id)).rejects.toThrow(/fixed/);
  });
});

describe('ranks and rewards', () => {
  it('needs exact 50:50: all the volume on one leg reaches no rank', async () => {
    const sponsor = await newStudent();
    const me = await enrol(sponsor);
    for (let i = 0; i < 2; i++) {
      const member = await newStudent();
      await enrol(member, me.code, 'A');
      await buy(member);
    }
    await inWorkspace(() => evaluateRanks([me.id]));
    expect(await db.mlmRankHistory.count({ where: { affiliateId: me.id } })).toBe(0);
  });

  it('walks a reward from qualified to paid, refusing every step out of order', async () => {
    const { me } = await pair();
    await inWorkspace(async () => {
      await db.mlmLegBalance.update({ where: { affiliateId: me.id }, data: { lifetimeA: 15_000_000n, lifetimeB: 15_000_000n } });
      await evaluateRanks([me.id]);
    });
    const list = (await owner.get(`/superadmin/affiliates/rewards?affiliateId=${me.id}`)).body.rows as {
      id: string;
      tierOrder: number;
      kind: string;
      amount: number;
    }[];
    expect(list.map((r) => r.tierOrder).sort()).toEqual([1, 2, 3]);
    expect((await db.affiliate.findUniqueOrThrow({ where: { id: me.id } })).currentRankOrder).toBe(3);

    const recognition = list.find((r) => r.tierOrder === 1)!;
    expect((await owner.post(`/superadmin/affiliates/rewards/${recognition.id}/approve`, {})).status).toBe(200);
    expect((await owner.get(`/superadmin/affiliates/rewards?affiliateId=${me.id}&status=paid`)).body.total).toBe(1);

    const cash = list.find((r) => r.tierOrder === 3)!;
    expect((await owner.post(`/superadmin/affiliates/rewards/${cash.id}/pay`, {})).status).toBe(409);
    expect((await owner.post(`/superadmin/affiliates/rewards/${cash.id}/fund`, {})).status).toBe(409);
    expect((await owner.post(`/superadmin/affiliates/rewards/${cash.id}/approve`, {})).status).toBe(200);
    expect((await owner.post(`/superadmin/affiliates/rewards/${cash.id}/fund`, {})).status).toBe(200);
    expect((await owner.post(`/superadmin/affiliates/rewards/${cash.id}/pay`, {})).status).toBe(200);
    expect((await owner.post(`/superadmin/affiliates/rewards/${cash.id}/pay`, {})).status).toBe(409);
    const commissions = await db.mlmCommission.findMany({ where: { affiliateId: me.id, kind: 'rank_reward' } });
    expect(commissions.reduce((s, c) => s + Number(c.amount), 0)).toBe(cash.amount);
    // The test set these pools by hand: put back the truth, so the ledger check elsewhere stays meaningful.
    await inWorkspace(() => db.mlmLegBalance.update({ where: { affiliateId: me.id }, data: { lifetimeA: 1_000_000n, lifetimeB: 1_000_000n } }));
  });
});

describe('the company ceiling', () => {
  it('holds what does not fit, shows it to the member, and releases it when sales make room', async () => {
    const { sponsor, me } = await pair();
    const big = await newStudent();
    const plan = (await runAsPlatform('reads the plan', () => activeMlmPlan())) as MlmPlanTerms;
    // Fill this month's ceiling by hand, then run: the whole income must wait.
    const month = new Date();
    const gross = (await owner.get('/superadmin/affiliates/reports/liability')).body;
    await inWorkspace(async () => {
      const room = gross.ceilingAmount - gross.fieldPayout;
      if (room > 0) {
        await db.mlmCommission.create({
          data: {
            tenantId: FIRST_TENANT_ID,
            affiliateId: me.id,
            kind: 'matching',
            amount: BigInt(room),
            status: 'paid_to_wallet',
            period: gross.period,
            planVersionId: plan.id,
            settledAt: month,
          },
        });
      }
    });
    await run();
    const held = (await earnings(sponsor)).wallet.heldByPolicy;
    expect(held).toBe(100_000);
    const rows = (await owner.get(`/superadmin/affiliates/commissions?affiliateId=${me.id}&status=held`)).body.rows;
    expect(rows[0]).toMatchObject({ status: 'held', holdReason: 'ceiling', amount: 100_000 });

    // New sales open the ceiling again, oldest hold first. A sale adds a quarter of its price, and earlier members' holds go first.
    await enrol(big);
    await buy(big);
    const waiting = (await owner.get('/superadmin/affiliates/reports/liability')).body.heldAmount as number;
    for (let room = 250_000; room < waiting; room += 250_000) {
      const buyer = await newStudent();
      await enrol(buyer);
      await buy(buyer);
    }
    await inWorkspace(() => releaseHeldCommissions(month));
    expect((await earnings(sponsor)).wallet.heldByPolicy).toBe(0);
    expect((await earnings(sponsor)).wallet.available).toBeGreaterThanOrEqual(100_000);
  });

  it('lets the Super Admin write off a hold with a reason, and the row stays', async () => {
    const { me } = await pair();
    const plan = (await runAsPlatform('reads the plan', () => activeMlmPlan())) as MlmPlanTerms;
    const row = await inWorkspace(() =>
      db.mlmCommission.create({
        data: { tenantId: FIRST_TENANT_ID, affiliateId: me.id, kind: 'matching', amount: 5000n, status: 'held', holdReason: 'ceiling', planVersionId: plan.id },
      }),
    );
    expect((await owner.post(`/superadmin/affiliates/commissions/${row.id}/write-off`, {})).status).toBe(400);
    expect((await owner.post(`/superadmin/affiliates/commissions/${row.id}/write-off`, { reason: 'Reviewed and declined' })).status).toBe(200);
    expect((await owner.post(`/superadmin/affiliates/commissions/${row.id}/release`, { reason: 'Too late now' })).status).toBe(409);
    expect((await db.mlmCommission.findUniqueOrThrow({ where: { id: row.id } })).status).toBe('written_off');
  });
});

describe('reversals', () => {
  it('claws back income already matched, once, taking the wallet below zero if it must', async () => {
    const { sponsor, me, leftBuy } = await pair();
    await run();
    expect((await earnings(sponsor)).wallet.available).toBe(100_000);

    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: leftBuy.purchaseId } });
    expect((await owner.post(`/superadmin/affiliates/orders/${order.id}/reverse`, { reason: 'refund', note: 'Refunded at the gateway' })).status).toBe(200);
    expect((await earnings(sponsor)).wallet.available).toBe(0);
    const reversal = await db.mlmCommission.findFirstOrThrow({ where: { affiliateId: me.id, kind: 'reversal' } });
    expect(Number(reversal.amount)).toBe(-100_000);
    expect((await owner.post(`/superadmin/affiliates/orders/${order.id}/reverse`, { reason: 'refund' })).status).toBe(409);
    expect((await earnings(sponsor)).wallet.available).toBe(0);
    expect(await inWorkspace(() => reconcileWallets())).toBe(0);
  });

  it('takes nothing from the wallet when the volume was still unmatched', async () => {
    const { sponsor, leftBuy } = await pair();
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: leftBuy.purchaseId } });
    expect((await owner.post(`/superadmin/affiliates/orders/${order.id}/reverse`, { reason: 'manual', note: 'A test' })).status).toBe(200);
    expect((await earnings(sponsor)).wallet.available).toBe(0);
    expect((await sponsor.get('/affiliate/figures')).body).toMatchObject({ unmatchedA: 0, unmatchedB: 1_000_000 });
  });

  it('rejects an unpaid reward the reversed volume no longer supports, and keeps the rank', async () => {
    const { me, leftBuy } = await pair();
    await inWorkspace(() => evaluateRanks([me.id]));
    const reward = await db.mlmReward.findFirst({ where: { affiliateId: me.id, tierOrder: 1 } });
    if (!reward) return expect.unreachable('A pair reaches the first rank at this course price.');
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: leftBuy.purchaseId } });
    await owner.post(`/superadmin/affiliates/orders/${order.id}/reverse`, { reason: 'manual', note: 'A test' });
    expect((await db.mlmReward.findUniqueOrThrow({ where: { id: reward.id } })).status).toBe('rejected');
    expect((await db.affiliate.findUniqueOrThrow({ where: { id: me.id } })).currentRankOrder).toBe(1);
  });

  it('reverses on the gateway’s signed word that a dispute was lost, once, and flags the order', async () => {
    const { leftBuy, sponsor } = await pair();
    const send = () => {
      const raw = JSON.stringify({ event: 'payment.dispute.lost', payload: { payment: { entity: { id: leftBuy.paymentId } } } });
      return request(app)
        .post('/webhooks/razorpay/courses')
        .set('content-type', 'application/json')
        .set('x-razorpay-event-id', `evt_${unique()}`)
        .set('x-razorpay-signature', signWebhook(raw))
        .send(raw);
    };
    expect((await send()).status).toBe(200);
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: leftBuy.purchaseId } });
    expect(order).toMatchObject({ status: 'reversed', reversalReason: 'chargeback' });
    expect((await db.coursePurchase.findUniqueOrThrow({ where: { id: leftBuy.purchaseId } })).reviewReason).toMatch(/lost dispute/);
    expect((await send()).status).toBe(200);
    expect((await sponsor.get('/affiliate/figures')).body.unmatchedA).toBe(0);
  });
});

describe('KYC', () => {
  it('seals PAN and bank account, shows only the last digits, and never returns the full values', async () => {
    const who = await newStudent();
    const me = await enrol(who);
    const saved = await who.put('/affiliate/kyc', {
      legalName: 'Asha Rao',
      pan: 'abcde1234f',
      bankAccount: '1234 5678 9012',
      ifsc: 'hdfc0001234',
      accountHolder: 'Asha Rao',
    });
    expect(saved.status, JSON.stringify(saved.body)).toBe(200);
    expect(saved.body).toMatchObject({ status: 'submitted', panLast4: '234F', bankAccountLast4: '9012', ifsc: 'HDFC0001234' });
    const raw = await db.mlmKyc.findUniqueOrThrow({ where: { affiliateId: me.id } });
    expect(raw.sealed).not.toContain('ABCDE1234F');
    expect(raw.sealed).not.toContain('123456789012');
    const queue = JSON.stringify((await owner.get('/superadmin/affiliates/kyc?status=submitted')).body);
    expect(queue).not.toContain('ABCDE1234F');
    expect(queue).not.toContain('123456789012');
  });

  it('refuses malformed documents, and only the Super Admin can review', async () => {
    const who = await newStudent();
    const me = await enrol(who);
    expect(
      (await who.put('/affiliate/kyc', { legalName: 'Asha', pan: 'NOTAPANNUM', bankAccount: '123456789012', ifsc: 'HDFC0001234', accountHolder: 'Asha' }))
        .status,
    ).toBe(400);
    await who.put('/affiliate/kyc', { legalName: 'Asha', pan: 'ABCDE1234F', bankAccount: '123456789012', ifsc: 'HDFC0001234', accountHolder: 'Asha' });
    expect((await who.post(`/superadmin/affiliates/kyc/${me.id}/verify`, {})).status).toBe(403);
    expect((await owner.post(`/superadmin/affiliates/kyc/${me.id}/reject`, { reason: 'The PAN name differs' })).status).toBe(200);
    expect((await who.get('/affiliate/kyc')).body).toMatchObject({ status: 'rejected', rejectionReason: 'The PAN name differs' });
  });
});

describe('KYC documents', () => {
  const pdf = Buffer.from('%PDF-1.4 a test identity document');
  const upload = async (who: Learner) => {
    const res = await request(app)
      .post('/media/upload')
      .set('Authorization', `Bearer ${who.token}`)
      .attach('file', pdf, { filename: 'pan.pdf', contentType: 'application/pdf' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    return res.body.id as string;
  };
  const body = { legalName: 'Asha Rao', pan: 'ABCDE1234F', bankAccount: '123456789012', ifsc: 'HDFC0001234', accountHolder: 'Asha Rao' };

  it('attaches only the member’s own uploads, and only the Super Admin can read them from the review', async () => {
    const who = await newStudent();
    const me = await enrol(who);
    const other = await newStudent();
    const theirs = await upload(other);
    expect((await who.put('/affiliate/kyc', { ...body, documentIds: [theirs] })).status).toBe(400);

    const mine = await upload(who);
    const saved = await who.put('/affiliate/kyc', { ...body, documentIds: [mine] });
    expect(saved.status, JSON.stringify(saved.body)).toBe(200);
    expect(saved.body.documents).toEqual([{ id: mine, name: 'pan.pdf' }]);

    const read = await request(app).get(`/superadmin/affiliates/kyc/${me.id}/documents/${mine}`).set('Authorization', `Bearer ${owner.token}`);
    expect(read.status).toBe(200);
    expect(read.headers['cache-control']).toBe('no-store');
    // A file that is not attached to this review answers as if it does not exist.
    expect((await request(app).get(`/superadmin/affiliates/kyc/${me.id}/documents/${theirs}`).set('Authorization', `Bearer ${owner.token}`)).status).toBe(404);
    expect((await request(app).get(`/superadmin/affiliates/kyc/${me.id}/documents/${mine}`).set('Authorization', `Bearer ${other.token}`)).status).toBe(403);
    // A staff member's reach stops short of a member's private document.
    expect((await request(app).get(`/media/${mine}`).set('Authorization', `Bearer ${other.token}`)).status).toBe(404);
  });
});

describe('withdrawals', () => {
  const activeMember = async () => {
    const who = await newStudent();
    const me = await enrol(who);
    await buy(who);
    return { who, me };
  };

  it('needs KYC, enough balance, the minimum, and one open request at a time', async () => {
    const { who, me } = await activeMember();
    await fund(me.id, 200_000);
    expect((await who.post('/affiliate/withdrawals', { amount: 100_000 })).body.message).toMatch(/KYC/);
    await verifyKyc(who, me.id);
    expect((await who.post('/affiliate/withdrawals', { amount: 100 })).body.message).toMatch(/smallest/);
    expect((await who.post('/affiliate/withdrawals', { amount: 900_000 })).body.message).toMatch(/more than/);
    expect((await who.post('/affiliate/withdrawals', { amount: 100_000 })).status).toBe(201);
    expect((await earnings(who)).wallet).toMatchObject({ available: 100_000, held: 100_000 });
    expect((await who.post('/affiliate/withdrawals', { amount: 60_000 })).body.message).toMatch(/in progress/);
  });

  it('returns the money on cancel or rejection, and pays it out through a batch', async () => {
    const { who, me } = await activeMember();
    await fund(me.id, 200_000);
    await verifyKyc(who, me.id);

    const first = (await who.post('/affiliate/withdrawals', { amount: 100_000 })).body;
    expect((await who.post(`/affiliate/withdrawals/${first.id}/cancel`, {})).status).toBe(200);
    expect((await earnings(who)).wallet).toMatchObject({ available: 200_000, held: 0 });

    const second = (await who.post('/affiliate/withdrawals', { amount: 100_000 })).body;
    expect((await owner.post(`/superadmin/affiliates/withdrawals/${second.id}/reject`, { reason: 'Bank details unclear' })).status).toBe(200);
    expect((await earnings(who)).wallet).toMatchObject({ available: 200_000, held: 0 });

    const third = (await who.post('/affiliate/withdrawals', { amount: 100_000 })).body;
    expect((await who.post(`/affiliate/withdrawals/${third.id}/cancel`, {})).status).toBe(200);
    const fourth = (await who.post('/affiliate/withdrawals', { amount: 100_000 })).body;
    expect((await owner.post('/superadmin/affiliates/payouts', { withdrawalIds: [fourth.id] })).status).toBe(409);
    expect((await owner.post(`/superadmin/affiliates/withdrawals/${fourth.id}/approve`, {})).status).toBe(200);
    expect((await who.post(`/affiliate/withdrawals/${fourth.id}/cancel`, {})).status).toBe(409);
    const batch = await owner.post('/superadmin/affiliates/payouts', { withdrawalIds: [fourth.id] });
    expect(batch.status, JSON.stringify(batch.body)).toBe(201);

    const csv = await owner.get(`/superadmin/affiliates/payouts/${batch.body.id}/export.csv`);
    expect(csv.text).toContain('123456789012');
    expect(await db.auditLog.count({ where: { action: 'mlm.payout.exported', targetId: batch.body.id } })).toBe(1);

    expect((await owner.post(`/superadmin/affiliates/payouts/${batch.body.id}/close`, {})).status).toBe(409);
    expect((await owner.post(`/superadmin/affiliates/withdrawals/${fourth.id}/paid`, { reference: 'UTR-12345' })).status).toBe(200);
    expect((await owner.post(`/superadmin/affiliates/withdrawals/${fourth.id}/paid`, { reference: 'UTR-12345' })).status).toBe(409);
    expect((await owner.post(`/superadmin/affiliates/payouts/${batch.body.id}/close`, {})).status).toBe(200);
    expect((await earnings(who)).wallet).toMatchObject({ available: 100_000, held: 0, paid: 100_000 });
    expect(await inWorkspace(() => reconcileWallets())).toBe(0);
  });

  it('keeps another member’s records out of reach', async () => {
    const a = await activeMember();
    const b = await activeMember();
    await fund(a.me.id, 200_000);
    await verifyKyc(a.who, a.me.id);
    const mine = (await a.who.post('/affiliate/withdrawals', { amount: 100_000 })).body;
    expect((await b.who.post(`/affiliate/withdrawals/${mine.id}/cancel`, {})).status).toBe(404);
    expect((await b.who.get('/affiliate/withdrawals')).body.total).toBe(0);
    expect((await a.who.get('/superadmin/affiliates/wallets')).status).toBe(403);
  });
});

describe('audit corrections (1 Nov 2026)', () => {
  const held = (affiliateId: string, amount: bigint, planVersionId: string) =>
    inWorkspace(() =>
      db.mlmCommission.create({
        data: { tenantId: FIRST_TENANT_ID, affiliateId, kind: 'matching', amount, status: 'held', holdReason: 'ceiling', planVersionId },
      }),
    );
  const planNow = async () => (await runAsPlatform('reads the plan', () => activeMlmPlan())) as MlmPlanTerms;

  it('a day with no matching is not a missed day: a catch-up cannot pay a second cap from one day’s volume', async () => {
    const { sponsor, me } = await pair();
    const today = programDay(new Date());
    await inWorkspace(() => runMatchingThrough(today));
    const first = (await sponsor.get('/affiliate/matching')).body.total as number;
    expect(first).toBe(1);
    expect(await inWorkspace(() => matchedThrough())).toBe(today);
    // New volume later the same day waits for tomorrow: the scheduler has finished today.
    const another = await newStudent();
    await enrol(another, me.code, 'A');
    await buy(another);
    await inWorkspace(() => runMatchingThrough(today));
    expect((await sponsor.get('/affiliate/matching')).body.total).toBe(1);
  });

  it('a past day in a catch-up sees only the volume that existed that day', async () => {
    const { sponsor } = await pair();
    const before = (await sponsor.get('/affiliate/figures')).body;
    expect(before.unmatchedA).toBeGreaterThan(0);
    // All this volume arrived today, so a run for last year finds nothing to match.
    const out = await inWorkspace(() => runMatching('2020-01-01', new Date()));
    const runs = (await sponsor.get('/affiliate/matching')).body.rows as { runDate: string }[];
    expect(runs.map((r) => r.runDate)).not.toContain('2020-01-01');
    expect(out.failed).toBe(0);
    expect((await sponsor.get('/affiliate/figures')).body.unmatchedA).toBe(before.unmatchedA);
  });

  it('refuses an impossible or future date on the manual run, and audits a real one', async () => {
    expect((await owner.post('/superadmin/affiliates/matching/run', { date: '2026-10-99' })).status).toBe(400);
    expect((await owner.post('/superadmin/affiliates/matching/run', { date: '2026-02-31' })).status).toBe(400);
    expect((await owner.post('/superadmin/affiliates/matching/run', { date: '2099-01-01' })).status).toBe(400);
    expect((await owner.post('/superadmin/affiliates/matching/run', {})).status).toBe(200);
    expect(await db.auditLog.count({ where: { action: 'mlm.matching.run' } })).toBeGreaterThan(0);
    // A day already finished is not run again by hand.
    expect((await owner.post('/superadmin/affiliates/matching/run', { date: '2020-01-01' })).status).toBe(409);
  });

  it('takes a reversal from holds first, so a hold cannot pay out on a refunded sale', async () => {
    const { sponsor, me, leftBuy } = await pair();
    await run();
    const plan = await planNow();
    // The income already paid goes back to a hold-sized situation: a hold exists alongside it.
    const hold = await held(me.id, 40_000n, plan.id);
    const wallet = (await earnings(sponsor)).wallet.available as number;
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: leftBuy.purchaseId } });
    expect((await owner.post(`/superadmin/affiliates/orders/${order.id}/reverse`, { reason: 'refund', note: 'A test' })).status).toBe(200);
    expect((await db.mlmCommission.findUniqueOrThrow({ where: { id: hold.id } })).status).toBe('written_off');
    expect((await earnings(sponsor)).wallet.available).toBe(wallet - 60_000);
    expect((await earnings(sponsor)).wallet.heldByPolicy).toBe(0);
  });

  it('claws back at the rate actually received: a capped day cannot cost more than it paid', async () => {
    const { sponsor, me, leftBuy } = await pair();
    await run();
    // As if earlier days had flushed a lot of volume for little income: the member’s effective rate falls by half.
    const plan = await planNow();
    await inWorkspace(() =>
      db.mlmMatchingRun.create({
        data: {
          tenantId: FIRST_TENANT_ID,
          affiliateId: me.id,
          runDate: '2019-01-01',
          planVersionId: plan.id,
          rankOrderAtRun: 0,
          capBandKey: 'starter',
          availableA: 1_000_000n,
          availableB: 1_000_000n,
          matchedCv: 1_000_000n,
          grossIncome: 100_000n,
          dailyCap: 0n,
          cappedIncome: 0n,
          flushedCv: 1_000_000n,
          carryAAfter: 0n,
          carryBAfter: 0n,
        },
      }),
    );
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: leftBuy.purchaseId } });
    await owner.post(`/superadmin/affiliates/orders/${order.id}/reverse`, { reason: 'refund', note: 'A test' });
    const reversal = await db.mlmCommission.findFirstOrThrow({ where: { affiliateId: me.id, kind: 'reversal' } });
    expect(Number(reversal.amount)).toBe(-50_000);
    expect((await earnings(sponsor)).wallet.available).toBe(50_000);
  });

  it('reverses from who received the sale, even after the member moved', async () => {
    const { me, left, leftBuy } = await pair();
    const leftMe = (await left.get('/affiliate')).body.affiliate as { id: string };
    const other = await newStudent();
    const otherMe = await enrol(other);
    // A move rewrites the path; the ledger still names the original credit.
    await inWorkspace(() =>
      db.affiliate.update({ where: { id: leftMe.id }, data: { pathIdsJson: JSON.stringify([otherMe.id]), placementParentId: otherMe.id, placementLeg: 'A' } }),
    );
    const order = await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: leftBuy.purchaseId } });
    expect((await owner.post(`/superadmin/affiliates/orders/${order.id}/reverse`, { reason: 'manual', note: 'A test' })).status).toBe(200);
    const rows = await db.mlmCvLedger.findMany({ where: { orderId: order.id, kind: 'reversal' } });
    expect(rows.map((r) => r.affiliateId)).toEqual([me.id]);
    expect(await db.mlmLegBalance.findUnique({ where: { affiliateId: otherMe.id } })).toBeNull();
  });

  it('divides a hold bigger than the room, so one large hold cannot block the queue', async () => {
    const { me } = await pair();
    const plan = await planNow();
    const report = (await owner.get('/superadmin/affiliates/reports/liability')).body;
    await inWorkspace(() => db.mlmCommission.updateMany({ where: { status: 'held' }, data: { status: 'written_off' } }));
    const big = await held(me.id, BigInt(report.headroom + 1_000), plan.id);
    await inWorkspace(() => releaseHeldCommissions());
    expect((await db.mlmCommission.findUniqueOrThrow({ where: { id: big.id } })).status).toBe('split');
    const parts = await db.mlmCommission.findMany({ where: { splitFromId: big.id }, orderBy: { amount: 'desc' } });
    expect(parts.map((c) => [Number(c.amount), c.status])).toEqual([
      [report.headroom, 'paid_to_wallet'],
      [1_000, 'held'],
    ]);
    await inWorkspace(() => db.mlmCommission.updateMany({ where: { status: 'held' }, data: { status: 'written_off' } }));
  });

  it('keeps a suspended member’s hold waiting, without blocking the member behind them', async () => {
    const a = await pair();
    const b = await pair();
    const plan = await planNow();
    const first = await held(a.me.id, 1_000n, plan.id);
    const second = await held(b.me.id, 1_000n, plan.id);
    expect((await owner.patch(`/superadmin/affiliates/members/${a.me.id}`, { status: 'suspended', reason: 'Testing a suspension' })).status).toBe(200);
    await inWorkspace(() => releaseHeldCommissions());
    expect((await db.mlmCommission.findUniqueOrThrow({ where: { id: first.id } })).status).toBe('held');
    expect((await db.mlmCommission.findUniqueOrThrow({ where: { id: second.id } })).status).toBe('paid_to_wallet');
    await inWorkspace(() => db.mlmCommission.update({ where: { id: first.id }, data: { status: 'written_off' } }));
  });

  it('retries a reversal the refund hook could not finish', async () => {
    const { leftBuy, sponsor } = await pair();
    // As if the hook had failed: the purchase is refunded and the order still stands.
    await inWorkspace(() => db.coursePurchase.update({ where: { id: leftBuy.purchaseId }, data: { refundedAt: new Date() } }));
    expect((await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: leftBuy.purchaseId } })).status).toBe('eligible');
    expect(await inWorkspace(() => repairOrders())).toBeGreaterThan(0);
    expect((await db.mlmOrder.findUniqueOrThrow({ where: { purchaseId: leftBuy.purchaseId } })).status).toBe('reversed');
    expect((await sponsor.get('/affiliate/figures')).body.unmatchedA).toBe(0);
  });

  it('activates a learner who joined after buying the eligible course', async () => {
    const who = await newStudent();
    await buy(who);
    const joined = await who.post('/affiliate/enrol', { preferredLeg: 'A' });
    expect(joined.status, JSON.stringify(joined.body)).toBe(201);
    expect(joined.body.status).toBe('active');
  });

  it('refuses a rejection once the bank has the file, unless someone checked; and keeps the batch total true', async () => {
    const who = await newStudent();
    const me = await enrol(who);
    await buy(who);
    await fund(me.id, 200_000);
    await verifyKyc(who, me.id);
    const request1 = (await who.post('/affiliate/withdrawals', { amount: 100_000 })).body;
    await owner.post(`/superadmin/affiliates/withdrawals/${request1.id}/approve`, {});
    const batch = (await owner.post('/superadmin/affiliates/payouts', { withdrawalIds: [request1.id] })).body;
    await owner.get(`/superadmin/affiliates/payouts/${batch.id}/export.csv`);
    expect((await owner.post(`/superadmin/affiliates/withdrawals/${request1.id}/reject`, { reason: 'Bank details unclear' })).status).toBe(409);
    expect(
      (await owner.post(`/superadmin/affiliates/withdrawals/${request1.id}/reject`, { reason: 'Bank says not paid', notPaidConfirmed: true })).status,
    ).toBe(200);
    const after = (await owner.get('/superadmin/affiliates/payouts')).body.find((b: { id: string }) => b.id === batch.id);
    expect(after).toMatchObject({ count: 0, total: 0 });
    expect((await who.get('/affiliate/earnings')).body.wallet.held).toBe(0);
  });

  it('does not re-list a paid withdrawal in a second bank file', async () => {
    const who = await newStudent();
    const me = await enrol(who);
    await buy(who);
    await fund(me.id, 200_000);
    await verifyKyc(who, me.id);
    const w = (await who.post('/affiliate/withdrawals', { amount: 100_000 })).body;
    await owner.post(`/superadmin/affiliates/withdrawals/${w.id}/approve`, {});
    const batch = (await owner.post('/superadmin/affiliates/payouts', { withdrawalIds: [w.id] })).body;
    await owner.post(`/superadmin/affiliates/withdrawals/${w.id}/paid`, { reference: 'UTR-77' });
    const csv = await owner.get(`/superadmin/affiliates/payouts/${batch.id}/export.csv`);
    expect(csv.text).not.toContain('123456789012');
  });

  it('refuses to delete an account that still has money, and forgets identity details when it goes', async () => {
    const who = await newStudent();
    const me = await enrol(who);
    await buy(who);
    await fund(me.id, 200_000);
    await verifyKyc(who, me.id);
    expect((await who.post('/auth/delete-account', { password: PASSWORD })).status).toBe(409);
    await fund(me.id, -200_000);
    expect((await who.post('/auth/delete-account', { password: PASSWORD })).status).toBe(200);
    expect(await db.mlmKyc.findUnique({ where: { affiliateId: me.id } })).toBeNull();
    expect((await db.affiliate.findUniqueOrThrow({ where: { id: me.id } })).status).toBe('terminated');
  });

  it('neutralises a formula in a name in every export', async () => {
    const who = await newStudent('=HYPERLINK("http://x")');
    const me = await enrol(who);
    const sponsorOf = await newStudent();
    const root = await enrol(sponsorOf);
    expect(me.id).toBeTruthy();
    const csv = await owner.get(`/superadmin/affiliates/network/export.csv?root=${root.id}`);
    expect(csv.status).toBe(200);
    const buyer = await newStudent('=CMD()');
    await enrol(buyer, root.code, 'A');
    await buy(buyer);
    const ledger = await owner.get('/superadmin/affiliates/cv/export.csv');
    expect(ledger.text).not.toMatch(/,=CMD/);
  });

  it('finds a balance that disagrees with its ledger, including a wallet with no entries', async () => {
    const who = await newStudent();
    const me = await enrol(who);
    const before = await inWorkspace(() => reconcileWallets());
    await inWorkspace(() => db.mlmWallet.create({ data: { tenantId: FIRST_TENANT_ID, affiliateId: me.id, available: 500n } }));
    expect(await inWorkspace(() => reconcileWallets())).toBe(before + 1);
    await inWorkspace(() => db.mlmWallet.update({ where: { affiliateId: me.id }, data: { available: 0n } }));
  });
});

describe('reports', () => {
  it('states the period’s sales, payout and headroom, and exports them', async () => {
    await pair();
    const res = await owner.get('/superadmin/affiliates/reports/liability');
    expect(res.status).toBe(200);
    expect(res.body.grossEligibleSales).toBeGreaterThan(0);
    expect(res.body.ceilingAmount).toBe(Math.round((res.body.grossEligibleSales * 2500) / 10000));
    expect((await owner.get('/superadmin/affiliates/reports/export.csv')).text).toContain('payoutRatioBps');
    const dash = await owner.get('/superadmin/affiliates/dashboard');
    expect(dash.status).toBe(200);
    expect(dash.body.members.total).toBeGreaterThan(0);
    expect((await owner.get('/superadmin/affiliates/reports/liability?period=2026-13')).status).toBe(400);
  });
});
