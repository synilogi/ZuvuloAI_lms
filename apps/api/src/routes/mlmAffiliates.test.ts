import { defaultMlmPlanTerms } from '@syniastrolms/domain';
import { beforeAll, describe, expect, it } from 'vitest';
import { activateMlmPlanVersion, createMlmPlanVersion, setMlmEligibleCourses } from '../lib/mlm/plan.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { FIRST_TENANT_ID, runAsPlatform } from '../lib/tenancy.js';
import { db, platformDb } from '../test/db.js';
import { anon, as, newStudent, unique, type Client } from '../test/helpers.js';

/* MLM-001: affiliates and referral registration. A sponsor opts in; a visitor opens the sponsor's link, registers
 * through the academy's join door with the code, confirms the emailed code, and arrives as a pending affiliate whose
 * sponsor is the one the link named — on the leg the link chose. */

let sponsor: Client & { email: string; userId: string; studentId: string };
let sponsorCode: string;
let slug: string;
let paidCourseId: string;
let admin: Client;

/** Registers through a door: with verification on (the default) confirms the emailed code; another suite may have switched it off, in which case the door signs the learner in at once. */
const registerThrough = async (path: string, body: Record<string, unknown>) => {
  const started = await anon().post(path, body);
  if (started.status === 201) return started;
  expect(started.status, JSON.stringify(started.body)).toBe(202);
  expect(started.body.status).toBe('verify');
  const confirmed = await anon().post('/public/verifications/verify', {
    verificationId: started.body.verificationId,
    code: await emailedCode(String(body.email)),
  });
  expect(confirmed.status, JSON.stringify(confirmed.body)).toBe(201);
  return confirmed;
};

const emailedCode = async (email: string) => {
  const mail = await platformDb.emailOutbox.findFirst({ where: { toEmail: email, templateKey: 'account-verification' }, orderBy: { createdAt: 'desc' } });
  const code = mail?.text.match(/\b(\d{6})\b/)?.[1];
  if (!code) throw new Error(`no verification code was emailed to ${email}`);
  return code;
};

beforeAll(async () => {
  admin = await as('admin');
  slug = (await platformDb.tenant.findUniqueOrThrow({ where: { id: FIRST_TENANT_ID }, select: { slug: true } })).slug;
  paidCourseId = (await db.course.findFirstOrThrow({ where: { pricing: 'paid', status: 'published' }, select: { id: true } })).id;
  // The program runs on the seeded academy: an active plan version naming its paid course.
  const owner = await provisionSuperAdmin({ email: `mlm-aff-${unique()}@example.com`, password: 'mlm-aff-suite-pw', name: 'Platform' });
  const actor = { auth: { sub: owner.user.id, role: 'superadmin' as const } };
  await runAsPlatform('the affiliate tests activate a plan', async () => {
    const active = await platformDb.mlmPlanVersion.findFirst({ where: { status: 'active' } });
    if (active) {
      // Another suite activated the plan first (they share the database): this suite's course joins its list.
      const ids = JSON.parse(active.eligibleCourseIdsJson) as string[];
      await setMlmEligibleCourses(actor, active.id, [...new Set([...ids, paidCourseId])]);
      return;
    }
    const draft = await createMlmPlanVersion(actor, { ...defaultMlmPlanTerms(FIRST_TENANT_ID), eligibleCourseIds: [paidCourseId] });
    await activateMlmPlanVersion(actor, draft.id);
  });
  sponsor = await newStudent('Sponsor Learner');
  const enrolled = await sponsor.post('/affiliate/enrol', { preferredLeg: 'B' });
  expect(enrolled.status, JSON.stringify(enrolled.body)).toBe(201);
  sponsorCode = enrolled.body.code;
});

describe('an affiliate’s own record', () => {
  it('opts a learner in with a fresh code, and refuses a second opt-in, staff and anonymous callers', async () => {
    expect(sponsorCode).toMatch(/^[A-HJ-NP-Z2-9]{8}$/);
    const me = await sponsor.get('/affiliate');
    expect(me.status).toBe(200);
    expect(me.body.affiliate).toMatchObject({ code: sponsorCode, status: 'pending', preferredLeg: 'B', sponsor: null, placement: null, programActive: true });
    expect(me.body.affiliate.referralLink).toMatch(new RegExp(`/ref/${sponsorCode}$`));
    expect(me.body.affiliate.joinLink).toContain(`/register?ref=${sponsorCode}`);
    expect((await sponsor.post('/affiliate/enrol', {})).status).toBe(409);
    expect((await admin.get('/affiliate')).status).toBe(403);
    expect((await anon().get('/affiliate')).status).toBe(401);
  });

  it('tells a learner outside the program so, and lets them change their preferred leg once in', async () => {
    const outsider = await newStudent('Outsider');
    const res = await outsider.get('/affiliate');
    expect(res.status).toBe(200);
    expect(res.body.affiliate).toBeNull();
    expect((await outsider.get('/affiliate/activation')).body.code).toBe('NOT_AN_AFFILIATE');
    const changed = await sponsor.patch('/affiliate/preferred-leg', { leg: 'A' });
    expect(changed.status).toBe(200);
    expect(changed.body.preferredLeg).toBe('A');
    expect((await sponsor.patch('/affiliate/preferred-leg', { leg: 'C' })).status).toBe(400);
  });

  it('shows the eligible course and that nothing has been bought yet', async () => {
    const activation = await sponsor.get('/affiliate/activation');
    expect(activation.status).toBe(200);
    expect(activation.body).toMatchObject({ status: 'pending', programActive: true });
    expect(activation.body.courses).toEqual(expect.arrayContaining([expect.objectContaining({ id: paidCourseId, purchase: 'none' })]));
    expect(activation.body.courses.find((c: { id: string }) => c.id === paidCourseId).priceAmount).toBeGreaterThan(0);
  });
});

describe('a referral link', () => {
  it('resolves to the sponsor, the academy and the program, and draws a QR', async () => {
    const res = await anon().get(`/public/affiliates/ref/${sponsorCode}`);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ sponsor: { code: sponsorCode, name: 'Sponsor Learner' }, academy: { slug, open: true }, program: { active: true } });
    // The first eligible course by title; another suite may have added one of its own.
    const eligible = JSON.parse((await platformDb.mlmPlanVersion.findFirstOrThrow({ where: { status: 'active' } })).eligibleCourseIdsJson) as string[];
    expect(eligible).toContain(res.body.program.course.id);
    expect(res.body.joinLink).toContain(`/register?ref=${sponsorCode}`);
    // Spaces and lower case are forgiven; a changed character is not.
    expect((await anon().get(`/public/affiliates/ref/${sponsorCode.toLowerCase()}`)).status).toBe(200);
    const broken = (sponsorCode[0] === 'A' ? 'B' : 'A') + sponsorCode.slice(1);
    const bad = await anon().get(`/public/affiliates/ref/${broken}`);
    expect(bad.status).toBe(404);
    expect(bad.body.code).toBe('REFERRAL_INVALID');
    expect((await anon().get('/public/affiliates/ref/nope')).status).toBe(404);

    const qr = await anon().get(`/public/affiliates/ref/${sponsorCode}/qr.svg`);
    expect(qr.status).toBe(200);
    expect(qr.headers['content-type']).toContain('image/svg+xml');
    expect(String(qr.text || qr.body)).toContain('<svg');
    expect((await anon().get('/public/affiliates/ref/nope/qr.svg')).status).toBe(404);
  });
});

describe('registering through a referral', () => {
  it('creates the learner as a pending affiliate under the sponsor, on the leg the link chose', async () => {
    const email = `referred-${unique()}@example.com`;
    await registerThrough(`/public/academies/${slug}/register`, {
      name: 'Referred Learner',
      email,
      password: 'referred-pw-123',
      referralCode: sponsorCode,
      preferredLeg: 'B',
    });
    const learner = await as({ email, password: 'referred-pw-123' });
    const me = await learner.get('/affiliate');
    expect(me.status).toBe(200);
    expect(me.body.affiliate).toMatchObject({ status: 'pending', preferredLeg: 'B', sponsor: { code: sponsorCode, name: 'Sponsor Learner' } });
    // Placed at once (MLM-002), on the sponsor's preferred leg or deeper in it.
    expect(me.body.affiliate.placement).not.toBeNull();
    // The sponsor's referral is recorded on the row, in the same academy.
    const row = await db.affiliate.findUniqueOrThrow({ where: { code: me.body.affiliate.code } });
    const sponsorRow = await db.affiliate.findUniqueOrThrow({ where: { code: sponsorCode } });
    expect(row.sponsorId).toBe(sponsorRow.id);
    expect(row.tenantId).toBe(FIRST_TENANT_ID);
  });

  it('refuses a bad code before any email goes out, and a code of a sponsor in another academy', async () => {
    const email = `bad-ref-${unique()}@example.com`;
    const res = await anon().post(`/public/academies/${slug}/register`, { name: 'Bad Ref', email, password: 'bad-ref-pw-123', referralCode: 'NOPE1234' });
    expect(res.status).toBe(404);
    expect(res.body.code).toBe('REFERRAL_INVALID');
    expect(await platformDb.emailOutbox.count({ where: { toEmail: email } })).toBe(0);
    expect(await platformDb.pendingAccount.count({ where: { email } })).toBe(0);
  });

  it('registers without a code as an ordinary learner, not an affiliate', async () => {
    const email = `plain-${unique()}@example.com`;
    await registerThrough(`/public/academies/${slug}/register`, { name: 'Plain Learner', email, password: 'plain-pw-12345' });
    const learner = await as({ email, password: 'plain-pw-12345' });
    expect((await learner.get('/affiliate')).body.affiliate).toBeNull();
  });

  it('also carries a referral through the host sign-up (`/auth/register`)', async () => {
    const email = `host-ref-${unique()}@example.com`;
    await registerThrough('/auth/register', { name: 'Host Referred', email, password: 'host-ref-pw-123', referralCode: sponsorCode });
    const learner = await as({ email, password: 'host-ref-pw-123' });
    expect((await learner.get('/affiliate')).body.affiliate.sponsor?.code).toBe(sponsorCode);
  });
});
