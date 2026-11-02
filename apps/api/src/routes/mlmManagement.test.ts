import { defaultMlmPlanTerms } from '@syniastrolms/domain';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { recordAuditLog } from '../lib/audit.js';
import { setCoursePaymentProvider } from '../lib/coursePayments.js';
import { newAffiliateCode } from '../lib/mlm/affiliates.js';
import { placePendingAffiliates } from '../lib/mlm/placement.js';
import { activateMlmPlanVersion, createMlmPlanVersion, setMlmEligibleCourses } from '../lib/mlm/plan.js';
import { reconcileWallets } from '../lib/mlm/wallet.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { FIRST_TENANT_ID, runAsPlatform, runInTenant } from '../lib/tenancy.js';
import { db, platformDb, T } from '../test/db.js';
import { FakeProvider } from '../test/fakeProvider.js';
import { anon, as, newStudent, unique, type Client } from '../test/helpers.js';

/* The affiliate program's management features (docs/15 §5, §7): the member filters, carry-forward corrections, a member's KYC,
 * the audit prefix, a member's own orders, and the leg a sponsor's link names. */

const BASE = '/superadmin/affiliates';
type Learner = Awaited<ReturnType<typeof newStudent>>;
type Placed = { id: string; code: string; preferredLeg: string; placement: { parentCode: string; leg: string; depth: number } | null };

let owner: Client;
let learner: Learner;
let fake: FakeProvider;
let courseId: string;
let otherCourseId: string;

const enrol = async (who: Learner, body: { referralCode?: string; preferredLeg?: 'A' | 'B'; requestedLeg?: 'A' | 'B' } = {}) => {
  const res = await who.post('/affiliate/enrol', body);
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return res.body as Placed;
};

const buy = async (who: Learner, course = courseId) => {
  const started = await who.post(`/learning/courses/${course}/purchase`, {});
  expect(started.status, JSON.stringify(started.body)).toBe(201);
  const payment = fake.pay(started.body.checkout.orderId, 'paid');
  const confirmed = await who.post(`/learning/purchases/${started.body.purchase.id}/confirm`, { paymentId: payment.paymentId, signature: payment.signature });
  expect(confirmed.status, JSON.stringify(confirmed.body)).toBe(200);
  return started.body.purchase.id as string;
};

/** A member whose legs hold what the test says, without a sale: a correction reads and writes only the pool. */
const pool = (affiliateId: string, figures: { unmatchedA?: bigint; unmatchedB?: bigint; lifetimeA?: bigint; lifetimeB?: bigint }) =>
  db.mlmLegBalance.create({ data: { ...T, affiliateId, ...figures } });

const paidCourse = async (title: string) => {
  const admin = await as('admin');
  const instructorId = (await admin.get('/catalog/instructors')).body[0].id as string;
  const course = await admin.post('/courses', {
    title: `${title} ${unique()}`,
    description: 'For the test.',
    instructorIds: [instructorId],
    pricing: 'paid',
    priceAmount: 10_000,
  });
  expect(course.status, JSON.stringify(course.body)).toBe(201);
  expect((await admin.post(`/courses/${course.body.id}/publish`)).status).toBe(200);
  return course.body.id as string;
};

beforeAll(async () => {
  const email = `mlm-mgmt-${unique()}@example.com`;
  const created = await provisionSuperAdmin({ email, password: 'mlm-mgmt-pw-123', name: 'Platform' });
  owner = await as({ email, password: 'mlm-mgmt-pw-123' });
  const actor = { auth: { sub: created.user.id, role: 'superadmin' as const } };
  fake = new FakeProvider('razorpay');
  setCoursePaymentProvider(fake);
  courseId = await paidCourse('The eligible course');
  otherCourseId = await paidCourse('A course outside the program');
  await runAsPlatform('these tests need an active plan naming the paid course', async () => {
    const active = await platformDb.mlmPlanVersion.findFirst({ where: { status: 'active' } });
    if (active) {
      await setMlmEligibleCourses(actor, active.id, [...new Set([...(JSON.parse(active.eligibleCourseIdsJson) as string[]), courseId])]);
      return;
    }
    const draft = await createMlmPlanVersion(actor, { ...defaultMlmPlanTerms(FIRST_TENANT_ID), eligibleCourseIds: [courseId] });
    await activateMlmPlanVersion(actor, draft.id);
  });
  learner = await newStudent('Plain Learner');
});

afterAll(() => setCoursePaymentProvider(undefined));

describe('every new route is the platform owner’s', () => {
  it('refuses a learner', async () => {
    const paths: ['get' | 'post', string, unknown?][] = [
      ['get', `${BASE}/members?rank=0`],
      ['get', `${BASE}/kyc/some-member`],
      ['post', `${BASE}/members/some-member/carry-forward/adjust`, { leg: 'A', amount: 100, reason: 'Not mine to do' }],
      ['post', `${BASE}/members/some-member/rank/recalculate`, {}],
      ['get', '/superadmin/audit?prefix=mlm.'],
    ];
    for (const [method, path, body] of paths) {
      const res = method === 'get' ? await learner.get(path) : await learner.post(path, body);
      expect(res.status, path).toBe(403);
    }
  });
});

describe('the member directory', () => {
  it('filters by rank and by identity check, and refuses a value that is neither', async () => {
    const ranked = await enrol(await newStudent('Ranked Member'));
    const plain = await enrol(await newStudent('Plain Member'));
    await db.affiliate.update({ where: { id: ranked.id }, data: { currentRankOrder: 7, kycStatus: 'rejected' } });

    const atSeven = await owner.get(`${BASE}/members`, { rank: 7, pageSize: 500 });
    expect(atSeven.status).toBe(200);
    expect(atSeven.body.rows.map((r: { id: string }) => r.id)).toContain(ranked.id);
    expect(atSeven.body.rows.map((r: { id: string }) => r.id)).not.toContain(plain.id);
    expect(atSeven.body.rows.every((r: { currentRankOrder: number }) => r.currentRankOrder === 7)).toBe(true);

    // Rank 0 is a real filter: nobody's rank yet. An empty value clears it instead.
    const noRank = await owner.get(`${BASE}/members`, { rank: 0, pageSize: 500 });
    expect(noRank.body.rows.map((r: { id: string }) => r.id)).toContain(plain.id);
    expect(noRank.body.rows.map((r: { id: string }) => r.id)).not.toContain(ranked.id);
    const cleared = await owner.get(`${BASE}/members`, { rank: '', kyc: '', search: ranked.code });
    expect(cleared.body.rows.map((r: { id: string }) => r.id)).toEqual([ranked.id]);

    const rejected = await owner.get(`${BASE}/members`, { kyc: 'rejected', pageSize: 500 });
    expect(rejected.body.rows.map((r: { id: string }) => r.id)).toContain(ranked.id);
    expect(rejected.body.rows.every((r: { kycStatus: string }) => r.kycStatus === 'rejected')).toBe(true);

    expect((await owner.get(`${BASE}/members`, { rank: 'high' })).status).toBe(400);
    expect((await owner.get(`${BASE}/members`, { kyc: 'maybe' })).status).toBe(400);
  });

  it('finds a member by code or by name, as the picker asks', async () => {
    const name = `Findable ${unique()}`;
    const member = await enrol(await newStudent(name));
    expect((await owner.get(`${BASE}/members`, { search: member.code })).body.rows.map((r: { id: string }) => r.id)).toEqual([member.id]);
    expect((await owner.get(`${BASE}/members`, { search: name })).body.rows.map((r: { id: string }) => r.id)).toEqual([member.id]);
  });
});

describe('correcting a carry-forward', () => {
  const adjust = (id: string, body: unknown) => owner.post(`${BASE}/members/${id}/carry-forward/adjust`, body);
  const auditRows = (id: string) => platformDb.auditLog.findMany({ where: { action: 'mlm.carry.adjusted', targetId: id }, orderBy: { createdAt: 'asc' } });

  it('moves one leg’s pool by a signed amount and records before and after', async () => {
    const member = await enrol(await newStudent('Carry Member'));
    await pool(member.id, { unmatchedA: 50_000n, unmatchedB: 7_000n, lifetimeA: 50_000n, lifetimeB: 7_000n });

    const added = await adjust(member.id, { leg: 'A', amount: 25_000, reason: 'Credit missed by support' });
    expect(added.status, JSON.stringify(added.body)).toBe(200);
    expect(added.body).toMatchObject({ unmatchedA: 75_000, unmatchedB: 7_000 });
    const taken = await adjust(member.id, { leg: 'B', amount: -7_000, reason: 'Duplicate credit removed' });
    expect(taken.status).toBe(200);
    expect(taken.body).toMatchObject({ unmatchedA: 75_000, unmatchedB: 0 });

    const rows = await auditRows(member.id);
    expect(rows.map((r) => JSON.parse(r.metaJson as string))).toEqual([
      { leg: 'A', cvChange: 25_000, before: 50_000, after: 75_000, reason: 'Credit missed by support' },
      { leg: 'B', cvChange: -7_000, before: 7_000, after: 0, reason: 'Duplicate credit removed' },
    ]);
    expect(rows[0].targetType).toBe('affiliate');
  });

  it('refuses to go below zero, and leaves nothing behind', async () => {
    const member = await enrol(await newStudent('Floor Member'));
    await pool(member.id, { unmatchedA: 1_000n });
    const refused = await adjust(member.id, { leg: 'A', amount: -1_001, reason: 'Too much taken' });
    expect(refused.status).toBe(409);
    expect((await db.mlmLegBalance.findUniqueOrThrow({ where: { affiliateId: member.id } })).unmatchedA).toBe(1_000n);
    expect(await auditRows(member.id)).toEqual([]);
    // Down to exactly zero is fine.
    expect((await adjust(member.id, { leg: 'A', amount: -1_000, reason: 'Down to nothing' })).status).toBe(200);

    // A member with no pool yet has nothing to take; the refusal creates no row.
    const empty = await enrol(await newStudent('Empty Member'));
    expect((await adjust(empty.id, { leg: 'B', amount: -1, reason: 'Nothing there' })).status).toBe(409);
    expect(await db.mlmLegBalance.findUnique({ where: { affiliateId: empty.id } })).toBeNull();
    // A correction upward makes the row, with lifetime still at zero.
    expect((await adjust(empty.id, { leg: 'B', amount: 500, reason: 'First credit by hand' })).body).toMatchObject({ unmatchedB: 500, lifetimeB: 0 });
  });

  it('never raises lifetime, so it can never earn a rank, and the nightly check stays clean', async () => {
    const member = await enrol(await newStudent('Rank Member'));
    await pool(member.id, {});
    const mismatchesBefore = await runInTenant(FIRST_TENANT_ID, () => reconcileWallets());
    // Far past every rank of any plan.
    const big = await adjust(member.id, { leg: 'A', amount: 1e15, reason: 'Huge by mistake' });
    expect(big.status).toBe(200);
    await adjust(member.id, { leg: 'B', amount: 1e15, reason: 'Huge by mistake' });
    const balance = await db.mlmLegBalance.findUniqueOrThrow({ where: { affiliateId: member.id } });
    expect(balance).toMatchObject({ lifetimeA: 0n, lifetimeB: 0n, unmatchedA: 1_000_000_000_000_000n, unmatchedB: 1_000_000_000_000_000n });

    const again = await owner.post(`${BASE}/members/${member.id}/rank/recalculate`, {});
    expect(again.status).toBe(200);
    expect(again.body).toEqual({ reached: 0 });
    expect((await db.affiliate.findUniqueOrThrow({ where: { id: member.id } })).currentRankOrder).toBe(0);
    expect(await db.mlmRankHistory.count({ where: { affiliateId: member.id } })).toBe(0);
    // The nightly check holds lifetime to the ledger: a correction gives it nothing to report.
    expect(await runInTenant(FIRST_TENANT_ID, () => reconcileWallets())).toBe(mismatchesBefore);
    // Leave no such pool for a matching run in another suite to pay on.
    await db.mlmLegBalance.update({ where: { affiliateId: member.id }, data: { unmatchedA: 0n, unmatchedB: 0n } });
  });

  it('checks the leg, the amount and the reason; an unknown member is 404', async () => {
    const member = await enrol(await newStudent('Check Member'));
    for (const bad of [
      { leg: 'C', amount: 1, reason: 'Wrong leg' },
      { leg: 'A', amount: 0, reason: 'No change' },
      { leg: 'A', amount: 1.5, reason: 'Not whole' },
      { leg: 'A', amount: 1, reason: 'x' },
      { leg: 'A', amount: 1, reason: 'Stray field', lifetime: 5 },
    ])
      expect((await adjust(member.id, bad)).status, JSON.stringify(bad)).toBe(400);
    expect((await adjust('no-such-member', { leg: 'A', amount: 1, reason: 'Nobody here' })).status).toBe(404);
  });
});

describe('recalculating a rank by hand', () => {
  it('answers 404 for nobody, and is audited for somebody', async () => {
    expect((await owner.post(`${BASE}/members/no-such-member/rank/recalculate`, {})).status).toBe(404);
    const member = await enrol(await newStudent('Audited Rank'));
    expect((await owner.post(`${BASE}/members/${member.id}/rank/recalculate`, {})).body).toEqual({ reached: 0 });
    expect(await platformDb.auditLog.count({ where: { action: 'mlm.rank.recalculated', targetId: member.id } })).toBe(1);
  });
});

describe('a member’s KYC', () => {
  it('is 404 when none was submitted, and masked when one was', async () => {
    const who = await newStudent('Kyc Member');
    const member = await enrol(who);
    const none = await owner.get(`${BASE}/kyc/${member.id}`);
    expect(none.status).toBe(404);

    const submitted = await who.put('/affiliate/kyc', {
      legalName: 'Asha Rao',
      pan: 'ABCDE1234F',
      bankAccount: '123456789012',
      ifsc: 'HDFC0001234',
      accountHolder: 'Asha Rao',
    });
    expect(submitted.status, JSON.stringify(submitted.body)).toBe(200);
    const res = await owner.get(`${BASE}/kyc/${member.id}`);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      status: 'submitted',
      legalName: 'Asha Rao',
      panLast4: '234F',
      bankAccountLast4: '9012',
      ifsc: 'HDFC0001234',
      affiliate: { id: member.id, code: member.code },
    });
    const text = JSON.stringify(res.body);
    expect(text).not.toContain('ABCDE1234F');
    expect(text).not.toContain('123456789012');
    expect(res.body).not.toHaveProperty('sealed');
    expect(res.body).not.toHaveProperty('sealedKeyId');
    expect((await owner.get(`${BASE}/kyc/no-such-member`)).status).toBe(404);
  });
});

describe('the activity log’s prefix', () => {
  it('returns only the actions that start with it', async () => {
    // Something that is the affiliate program's, and something that is not.
    const member = await enrol(await newStudent('Audit Member'));
    expect((await owner.post(`${BASE}/members/${member.id}/rank/recalculate`, {})).status).toBe(200);
    await recordAuditLog({ type: 'system', job: 'mlm-management-test' }, { action: 'zz.other', targetType: 'test', targetId: 'test' });

    const res = await owner.get('/superadmin/audit', { prefix: 'mlm.', pageSize: 500 });
    expect(res.status).toBe(200);
    expect(res.body.rows.length).toBeGreaterThan(0);
    expect(res.body.rows.every((r: { action: string }) => r.action.startsWith('mlm.'))).toBe(true);
    expect((await owner.get('/superadmin/audit', { prefix: 'zz.' })).body.rows.map((r: { action: string }) => r.action)).toContain('zz.other');
    // It takes the start, not any part: `lm.` is not a prefix of `mlm.`.
    expect((await owner.get('/superadmin/audit', { prefix: 'lm.' })).body.total).toBe(0);
    // Without one, the log is the whole log, and an exact action is narrower than a prefix.
    expect((await owner.get('/superadmin/audit')).body.total).toBeGreaterThan(res.body.total);
    const exact = await owner.get('/superadmin/audit', { prefix: 'mlm.', action: 'mlm.rank.recalculated', pageSize: 500 });
    expect(exact.body.rows.every((r: { action: string }) => r.action === 'mlm.rank.recalculated')).toBe(true);
  });
});

describe('a member’s own orders', () => {
  it('lists the caller’s paid purchases of eligible courses, and nobody else’s', async () => {
    const buyer = await newStudent('Order Buyer');
    await enrol(buyer);
    const other = await newStudent('Other Buyer');
    await enrol(other);
    expect((await buyer.get('/affiliate/orders')).body).toMatchObject({ rows: [], total: 0 });

    const purchaseId = await buy(buyer);
    const otherPurchase = await buy(other);
    // A purchase of a course outside the program is on the learner's purchases page, not here.
    const outside = await buy(buyer, otherCourseId);
    const res = await buyer.get('/affiliate/orders');
    expect(res.status).toBe(200);
    expect(res.body.total).toBe(1);
    const stored = await db.coursePurchase.findUniqueOrThrow({ where: { id: purchaseId } });
    expect(res.body.rows[0]).toMatchObject({
      id: purchaseId,
      course: { id: courseId },
      orderNumber: stored.orderNumber,
      amount: stored.amount,
      currency: stored.currency,
      status: 'paid',
      refunded: false,
      chargedBack: false,
    });
    expect(res.body.rows[0].paidAt).toBeTruthy();
    expect(JSON.stringify(res.body)).not.toContain(otherPurchase);
    expect(JSON.stringify(res.body)).not.toContain(outside);

    // The request cannot name another member: unknown parameters are not read.
    const asked = await buyer.get('/affiliate/orders', {
      affiliateId: (await db.affiliate.findFirstOrThrow({ where: { studentId: other.studentId } })).id,
      studentId: other.studentId,
    });
    expect(asked.body.rows.map((r: { id: string }) => r.id)).toEqual([purchaseId]);

    await db.coursePurchase.update({ where: { id: purchaseId }, data: { refundedAt: new Date() } });
    expect((await buyer.get('/affiliate/orders')).body.rows[0]).toMatchObject({ id: purchaseId, status: 'paid', refunded: true });
    // A real refund also reverses the order; this one only tests the column, so the repair job must not find it later.
    await db.coursePurchase.update({ where: { id: purchaseId }, data: { refundedAt: null } });
  });

  it('is a member’s page: refused to a learner outside the program, to staff and to a visitor', async () => {
    expect((await learner.get('/affiliate/orders')).status).toBe(404);
    expect((await (await as('admin')).get('/affiliate/orders')).status).toBe(403);
    expect((await owner.get('/affiliate/orders')).status).toBe(403);
    expect((await anon().get('/affiliate/orders')).status).toBe(401);
  });
});

describe('the leg a sponsor’s link names', () => {
  it('places on that leg whatever the sponsor prefers, keeps the member’s own preference, and spills over from there', async () => {
    const sponsor = await enrol(await newStudent('Link Sponsor'), { preferredLeg: 'A' });
    // A B link, while the sponsor prefers A.
    const first = await enrol(await newStudent('First On B'), { referralCode: sponsor.code, requestedLeg: 'B', preferredLeg: 'A' });
    expect(first.placement).toEqual({ parentCode: sponsor.code, leg: 'B', depth: 1 });
    expect(first.preferredLeg).toBe('A');
    const history = await db.mlmPlacementHistory.findFirstOrThrow({ where: { affiliateId: first.id } });
    expect(history).toMatchObject({ reason: 'sponsor-direct', toLeg: 'B' });

    // B is taken: the next B link goes deeper in B (the plan's spillover rule), not over to A.
    const second = await enrol(await newStudent('Second On B'), { referralCode: sponsor.code, requestedLeg: 'B' });
    expect(second.placement).toEqual({ parentCode: first.code, leg: 'B', depth: 2 });
    expect(await db.mlmPlacementHistory.findFirstOrThrow({ where: { affiliateId: second.id } })).toMatchObject({ reason: 'spillover', toLeg: 'B' });

    // A link with no leg still follows the sponsor's preferred leg, which the links left alone.
    const plain = await enrol(await newStudent('No Leg'), { referralCode: sponsor.code });
    expect(plain.placement).toEqual({ parentCode: sponsor.code, leg: 'A', depth: 1 });
    const sponsorRow = await db.affiliate.findUniqueOrThrow({ where: { id: sponsor.id } });
    expect(sponsorRow.preferredLeg).toBe('A');
  });

  it('does not let a new member’s own preference choose their position', async () => {
    const sponsor = await enrol(await newStudent('Pref Sponsor'), { preferredLeg: 'B' });
    const member = await enrol(await newStudent('Pref Member'), { referralCode: sponsor.code, preferredLeg: 'A' });
    expect(member.placement).toEqual({ parentCode: sponsor.code, leg: 'B', depth: 1 });
    expect(member.preferredLeg).toBe('A');
    // And that preference is what their own referrals follow.
    const theirs = await enrol(await newStudent('Their Referral'), { referralCode: member.code });
    expect(theirs.placement).toEqual({ parentCode: member.code, leg: 'A', depth: 2 });
  });

  it('holds the leg through email verification, and the member’s own preference apart from it', async () => {
    const sponsor = await enrol(await newStudent('Verify Sponsor'), { preferredLeg: 'A' });
    const before = process.env.SIGNUP_EMAIL_VERIFICATION;
    process.env.SIGNUP_EMAIL_VERIFICATION = 'on';
    try {
      const email = `link-leg-${unique()}@example.com`;
      const started = await anon().post('/auth/register', {
        name: 'Verified Referral',
        email,
        password: 'link-leg-pw-123',
        referralCode: sponsor.code,
        requestedLeg: 'B',
      });
      expect(started.status, JSON.stringify(started.body)).toBe(202);
      expect(await platformDb.pendingAccount.findFirstOrThrow({ where: { email } })).toMatchObject({ requestedLeg: 'B', preferredLeg: null });
      const mail = await platformDb.emailOutbox.findFirstOrThrow({
        where: { toEmail: email, templateKey: 'account-verification' },
        orderBy: { createdAt: 'desc' },
      });
      const confirmed = await anon().post('/public/verifications/verify', {
        verificationId: started.body.verificationId,
        code: mail.text.match(/\b(\d{6})\b/)?.[1],
      });
      expect(confirmed.status, JSON.stringify(confirmed.body)).toBe(201);
      const row = await db.affiliate.findFirstOrThrow({ where: { user: { email } } });
      expect(row).toMatchObject({ requestedLeg: 'B', preferredLeg: 'A', placementParentId: sponsor.id, placementLeg: 'B' });
    } finally {
      process.env.SIGNUP_EMAIL_VERIFICATION = before;
    }
  });

  it('is carried by every door, and a bad leg is refused', async () => {
    const sponsor = await enrol(await newStudent('Door Sponsor'), { preferredLeg: 'A' });
    const slug = (await platformDb.tenant.findUniqueOrThrow({ where: { id: FIRST_TENANT_ID }, select: { slug: true } })).slug;
    const email = `door-leg-${unique()}@example.com`;
    const joined = await anon().post(`/public/academies/${slug}/register`, {
      name: 'Door Referral',
      email,
      password: 'door-leg-pw-123',
      referralCode: sponsor.code,
      requestedLeg: 'B',
    });
    expect(joined.status, JSON.stringify(joined.body)).toBe(201);
    expect(await db.affiliate.findFirstOrThrow({ where: { user: { email } } })).toMatchObject({ placementLeg: 'B', preferredLeg: 'A' });

    const hostEmail = `host-leg-${unique()}@example.com`;
    const host = await anon().post('/public/register', {
      name: 'Host Referral',
      email: hostEmail,
      phone: '9876543210',
      password: 'host-leg-pw-123',
      referralCode: sponsor.code,
      requestedLeg: 'B',
    });
    expect(host.status, JSON.stringify(host.body)).toBe(201);
    expect(await db.affiliate.findFirstOrThrow({ where: { user: { email: hostEmail } } })).toMatchObject({ requestedLeg: 'B', placementLeg: 'B' });

    expect(
      (
        await anon().post('/auth/register', {
          name: 'Bad Leg',
          email: `bad-leg-${unique()}@example.com`,
          password: 'bad-leg-pw-1234',
          referralCode: sponsor.code,
          requestedLeg: 'C',
        })
      ).status,
    ).toBe(400);
    expect((await (await newStudent('Bad Enrol')).post('/affiliate/enrol', { referralCode: sponsor.code, requestedLeg: 'C' })).status).toBe(400);
  });

  it('is kept for the scheduler’s catch-up, and dropped by a change of sponsor', async () => {
    const sponsor = await enrol(await newStudent('Catch Sponsor'), { preferredLeg: 'A' });
    const waiting = await newStudent('Catch Member');
    const row = await db.affiliate.create({
      data: { ...T, userId: waiting.userId, studentId: waiting.studentId, code: await newAffiliateCode(), sponsorId: sponsor.id, requestedLeg: 'B' },
    });
    await runInTenant(FIRST_TENANT_ID, () => placePendingAffiliates());
    expect(await db.affiliate.findUniqueOrThrow({ where: { id: row.id } })).toMatchObject({ placementParentId: sponsor.id, placementLeg: 'B' });

    // A leg the old sponsor's link named means nothing under a new one.
    const other = await enrol(await newStudent('New Sponsor'), { preferredLeg: 'A' });
    const unplaced = await newStudent('Moved Sponsor Member');
    const moved = await db.affiliate.create({
      data: { ...T, userId: unplaced.userId, studentId: unplaced.studentId, code: await newAffiliateCode(), sponsorId: sponsor.id, requestedLeg: 'B' },
    });
    const changed = await owner.patch(`${BASE}/members/${moved.id}/sponsor`, { sponsorId: other.id, reason: 'Wrong sponsor recorded' });
    expect(changed.status, JSON.stringify(changed.body)).toBe(200);
    expect(changed.body.requestedLeg).toBeNull();
    await runInTenant(FIRST_TENANT_ID, () => placePendingAffiliates());
    expect(await db.affiliate.findUniqueOrThrow({ where: { id: moved.id } })).toMatchObject({ placementParentId: other.id, placementLeg: 'A' });
  });

  it('gives the member an A and a B link, and shows the Super Admin which leg a member came in on', async () => {
    const who = await newStudent('Links Sponsor');
    const sponsor = await enrol(who);
    const { affiliate } = (await who.get('/affiliate')).body;
    expect(affiliate.legLinks.A).toMatch(new RegExp(`/register\\?ref=${sponsor.code}&leg=A$`));
    expect(affiliate.legLinks.B).toMatch(new RegExp(`/register\\?ref=${sponsor.code}&leg=B$`));
    const member = await enrol(await newStudent('Shown Member'), { referralCode: sponsor.code, requestedLeg: 'B' });
    expect((await owner.get(`${BASE}/members/${member.id}`)).body).toMatchObject({ requestedLeg: 'B', preferredLeg: 'A' });
  });
});
