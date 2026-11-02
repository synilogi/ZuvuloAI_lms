import request from 'supertest';
import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { app, as, unique, type Client } from '../test/helpers.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { SIGNUP_MAX_ATTEMPTS } from '../lib/signup.js';

/* Self-serve registration (SAAS-026), over HTTP: a visitor registers an organisation and its admin, confirms the
 * emailed code, and is signed in to a new, empty academy of their own — with no plan, and nothing of another's. */

const PASSWORD = 'signup-password-1';
let platform: Client;

const form = (over: object = {}) => {
  const id = unique();
  return {
    academyName: `Signup Academy ${id}`,
    slug: `su-${id}`,
    name: 'Registering Admin',
    email: `su-${id}@example.com`,
    password: PASSWORD,
    acceptTerms: true,
    ...over,
  };
};

const start = (body: object) => request(app).post('/signup/start').send(body);
const verify = (signupId: string, code: string) => request(app).post('/signup/verify').send({ signupId, code });

/** The code from the latest verification email to the address — what the registrant reads in their inbox. */
async function codeFor(email: string): Promise<string> {
  const mail = await platformDb.emailOutbox.findFirst({ where: { toEmail: email, templateKey: 'signup-verification' }, orderBy: { createdAt: 'desc' } });
  const code = mail?.text.match(/\b(\d{6})\b/)?.[1];
  if (!code) throw new Error(`No verification code was emailed to ${email}`);
  return code;
}

const wrong = (code: string) => String((Number(code) + 1) % 1_000_000).padStart(6, '0');

beforeAll(async () => {
  // The suite's fixtures register in one step (vitest.config.ts); this suite is about the code, so it is on.
  delete process.env.SIGNUP_EMAIL_VERIFICATION;
  const email = `su-platform-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Signup Platform' });
  platform = await as({ email, password: PASSWORD });
});

afterEach(() => {
  delete process.env.SIGNUP_EMAIL_VERIFICATION;
});

afterAll(() => {
  process.env.SIGNUP_EMAIL_VERIFICATION = 'off';
});

describe('the public plan catalogue', () => {
  it('lists the plans on sale with the server’s prices, and no drafts', async () => {
    const draft = await platform.post('/superadmin/plans', {
      name: 'Hidden draft',
      description: 'Never shown publicly.',
      code: `SUDRAFT${unique().toUpperCase()}`.slice(0, 24),
      currency: 'INR',
      cycles: ['monthly'],
      monthlyPrice: 99900,
      annualPrice: 0,
      trialEnabled: false,
      trialDays: 0,
      limits: { 'learners.max': 1, 'instructors.max': 1, 'courses.max': 1, 'storage.bytes': 1, 'live_classes.max': 1, 'admin_accounts.max': 1 },
      features: ['courses.manage'],
    });
    expect(draft.status, JSON.stringify(draft.body)).toBe(201);

    const res = await request(app).get('/public/plans');
    expect(res.status).toBe(200);
    expect(res.body.plans.length).toBeGreaterThan(0);
    for (const plan of res.body.plans) {
      expect(plan.status).toBe('active');
      expect(Number.isInteger(plan.monthlyPrice)).toBe(true);
      expect(plan).toHaveProperty('limits');
      expect(plan).toHaveProperty('features');
    }
    expect(res.body.plans.map((p: { id: string }) => p.id)).not.toContain(draft.body.id);
    expect(res.body.tax).toMatchObject({ name: 'GST', inclusive: false, rateBps: 1800 });
  });
});

describe('registering an academy', () => {
  it('creates nothing until the emailed code is confirmed, then signs the owner in to an empty academy with no plan', async () => {
    const body = form();
    const started = await start(body);
    expect(started.status, JSON.stringify(started.body)).toBe(202);
    expect(started.body).toMatchObject({ status: 'verify', email: body.email });
    expect(started.body).not.toHaveProperty('code');

    // Nothing that can sign in exists yet.
    expect(await platformDb.user.findUnique({ where: { email: body.email } })).toBeNull();
    expect(await platformDb.tenant.findUnique({ where: { slug: body.slug } })).toBeNull();
    expect((await request(app).post('/auth/login').send({ email: body.email, password: PASSWORD })).status).toBe(401);
    // The stored row holds hashes only.
    const pending = await platformDb.pendingSignup.findUniqueOrThrow({ where: { id: started.body.signupId } });
    expect(pending.passwordHash).not.toContain(PASSWORD);
    expect(pending.codeHash).not.toContain(await codeFor(body.email));

    const done = await verify(started.body.signupId, await codeFor(body.email));
    expect(done.status, JSON.stringify(done.body)).toBe(201);
    expect(done.body.user).toMatchObject({ email: body.email, role: 'admin', name: body.name });
    expect(done.body.user.permissions.length).toBeGreaterThan(5);

    const admin = { get: (path: string) => request(app).get(path).set('Authorization', `Bearer ${done.body.token}`) };
    expect((await admin.get('/auth/me')).status).toBe(200);
    expect((await admin.get('/tenant/billing')).body).toMatchObject({ subscription: null, trialAvailable: true });
    expect((await admin.get('/courses')).body).toMatchObject({ total: 0 });
    expect((await admin.get('/students')).body).toMatchObject({ total: 0 });

    const academy = await platformDb.tenant.findUniqueOrThrow({ where: { slug: body.slug }, include: { owner: true } });
    expect(academy).toMatchObject({ name: body.academyName, status: 'active' });
    expect(academy.owner?.email).toBe(body.email);
    expect(await platformDb.subscription.count({ where: { tenantId: academy.id } })).toBe(0);
    const audit = await platformDb.auditLog.findFirst({ where: { action: 'academy.self_registered', targetId: academy.id } });
    expect(audit).toMatchObject({ actorEmail: body.email, actorRole: 'admin' });

    // The owner signs in like any admin afterwards.
    expect((await request(app).post('/auth/login').send({ email: body.email, password: PASSWORD })).status).toBe(200);
  });

  it('derives the address from the organisation name when none is given', async () => {
    const id = unique();
    const started = await start(form({ academyName: `Nadi School ${id}`, slug: undefined }));
    expect(started.status, JSON.stringify(started.body)).toBe(202);
    const pending = await platformDb.pendingSignup.findUniqueOrThrow({ where: { id: started.body.signupId } });
    expect(pending.slug).toBe(`nadi-school-${id}`.toLowerCase());
  });

  it('never lets the body choose a role, an academy, a plan or a status', async () => {
    const body = form({ role: 'superadmin', tenantId: 'tenant-1', planId: 'anything', status: 'active', subscription: { status: 'active' } });
    const started = await start(body);
    expect(started.status).toBe(202);
    const done = await verify(started.body.signupId, await codeFor(body.email));
    expect(done.status).toBe(201);
    const user = await platformDb.user.findUniqueOrThrow({ where: { email: body.email } });
    expect(user.role).toBe('admin');
    expect(user.tenantId).not.toBe('tenant-1');
    expect(await platformDb.subscription.count({ where: { tenantId: user.tenantId! } })).toBe(0);
  });

  it('refuses an email that already has an account, a taken or reserved address, and a missing agreement', async () => {
    expect((await start(form({ email: 'admin@syniastrolms.test' }))).status).toBe(409);
    expect((await start(form({ slug: 'default' }))).status).toBe(400);
    process.env.SIGNUP_EMAIL_VERIFICATION = 'off';
    const taken = form();
    expect((await start(taken)).status).toBe(201);
    delete process.env.SIGNUP_EMAIL_VERIFICATION;
    const res = await start(form({ slug: taken.slug }));
    expect(res.status).toBe(409);
    expect(res.body.issues).toEqual([expect.objectContaining({ field: 'slug' })]);
    expect((await start(form({ acceptTerms: false }))).status).toBe(400);
    expect((await start(form({ password: 'short' }))).status).toBe(400);
  });
});

describe('the verification code', () => {
  it('refuses a wrong code, counts the attempts, and locks after the limit even with the right one', async () => {
    const body = form();
    const { signupId } = (await start(body)).body;
    const code = await codeFor(body.email);
    const first = await verify(signupId, wrong(code));
    expect(first.status).toBe(400);
    expect(first.body.message).toMatch(/tries left/);
    for (let i = 1; i < SIGNUP_MAX_ATTEMPTS; i++) await verify(signupId, wrong(code));
    const locked = await verify(signupId, code);
    expect(locked.status).toBe(429);
    expect(await platformDb.user.findUnique({ where: { email: body.email } })).toBeNull();
  });

  it('compares no more guesses than the limit, however many arrive at once', async () => {
    const body = form();
    const { signupId } = (await start(body)).body;
    const code = await codeFor(body.email);
    const burst = await Promise.all(Array.from({ length: SIGNUP_MAX_ATTEMPTS * 4 }, () => verify(signupId, wrong(code))));
    expect(burst.filter((r) => r.status === 400).length).toBeLessThanOrEqual(SIGNUP_MAX_ATTEMPTS);
    expect(burst.every((r) => r.status === 400 || r.status === 429)).toBe(true);
    expect((await platformDb.pendingSignup.findUniqueOrThrow({ where: { id: signupId } })).attempts).toBe(SIGNUP_MAX_ATTEMPTS);
    expect((await verify(signupId, code)).status).toBe(429);
  });

  it('works once: a replayed confirmation is refused', async () => {
    const body = form();
    const { signupId } = (await start(body)).body;
    const code = await codeFor(body.email);
    expect((await verify(signupId, code)).status).toBe(201);
    expect((await verify(signupId, code)).status).toBe(404);
  });

  it('creates one academy when the same code is confirmed twice at once', async () => {
    const body = form();
    const { signupId } = (await start(body)).body;
    const code = await codeFor(body.email);
    const results = await Promise.all([verify(signupId, code), verify(signupId, code), verify(signupId, code)]);
    expect(results.filter((r) => r.status === 201)).toHaveLength(1);
    expect(await platformDb.tenant.count({ where: { slug: body.slug } })).toBe(1);
  });

  it('expires', async () => {
    const body = form();
    const { signupId } = (await start(body)).body;
    await platformDb.pendingSignup.update({ where: { id: signupId }, data: { expiresAt: new Date(Date.now() - 1000) } });
    expect((await verify(signupId, await codeFor(body.email))).status).toBe(410);
  });

  it('is bound to its own registration', async () => {
    const a = form();
    const b = form();
    const startedA = (await start(a)).body;
    await start(b);
    expect((await verify(startedA.signupId, await codeFor(b.email))).status).toBe(400);
  });

  it('can be sent again after the cooldown, and the old code stops working', async () => {
    const body = form();
    const { signupId } = (await start(body)).body;
    const oldCode = await codeFor(body.email);
    expect((await request(app).post('/signup/resend').send({ signupId })).status).toBe(429);

    await platformDb.pendingSignup.update({ where: { id: signupId }, data: { lastSentAt: new Date(Date.now() - 120_000) } });
    // Guarantee the new code differs, so the old one is provably dead.
    let newCode = oldCode;
    for (let i = 0; i < 5 && newCode === oldCode; i++) {
      await platformDb.pendingSignup.update({ where: { id: signupId }, data: { lastSentAt: new Date(Date.now() - 120_000) } });
      const resent = await request(app).post('/signup/resend').send({ signupId });
      expect(resent.status).toBe(200);
      newCode = await codeFor(body.email);
    }
    expect(newCode).not.toBe(oldCode);
    expect((await verify(signupId, oldCode)).status).toBe(400);
    expect((await verify(signupId, newCode)).status).toBe(201);
  });

  it('a new start for the same email replaces the pending one', async () => {
    const body = form();
    const first = (await start(body)).body;
    const firstCode = await codeFor(body.email);
    const second = (await start({ ...body, academyName: `${body.academyName} Two` })).body;
    expect((await verify(first.signupId, firstCode)).status).toBe(404);
    const done = await verify(second.signupId, await codeFor(body.email));
    expect(done.status).toBe(201);
    expect((await platformDb.tenant.findUniqueOrThrow({ where: { slug: body.slug } })).name).toBe(`${body.academyName} Two`);
  });

  it('reports the address taken while the code waited, and leaves the registration open to start again', async () => {
    const body = form();
    const { signupId } = (await start(body)).body;
    const code = await codeFor(body.email);
    const other = form({ slug: body.slug });
    // Someone else registers the same address first, with verification off.
    process.env.SIGNUP_EMAIL_VERIFICATION = 'off';
    expect((await start(other)).status).toBe(201);
    delete process.env.SIGNUP_EMAIL_VERIFICATION;
    const res = await verify(signupId, code);
    expect(res.status).toBe(409);
    expect(await platformDb.user.findUnique({ where: { email: body.email } })).toBeNull();
  });
});

describe('the plan chosen while registering', () => {
  it('is kept with the registration, survives a refresh, and is offered on the new academy’s plan page — never granted', async () => {
    const plans = (await request(app).get('/public/plans')).body.plans as { id: string; code: string; cycles: string[] }[];
    const growth = plans.find((p) => p.code === 'GROWTH')!;
    const body = form({ planId: growth.id, cycle: 'annual' });
    const started = await start(body);
    expect(started.body.choice).toEqual({ planId: growth.id, cycle: 'annual' });

    // A refreshed page asks where the registration stands: the step, the address, the choice — never the code.
    const status = await request(app).get(`/signup/${started.body.signupId}`);
    expect(status.status).toBe(200);
    expect(status.body).toMatchObject({ status: 'verify', email: body.email, choice: { planId: growth.id, cycle: 'annual' } });
    expect(JSON.stringify(status.body)).not.toContain(await codeFor(body.email));

    const done = await verify(started.body.signupId, await codeFor(body.email));
    expect(done.body.choice).toEqual({ planId: growth.id, cycle: 'annual' });
    expect((await request(app).get(`/signup/${started.body.signupId}`)).status).toBe(404);

    const billing = await request(app).get('/tenant/billing').set('Authorization', `Bearer ${done.body.token}`);
    expect(billing.body).toMatchObject({ subscription: null, signupChoice: { planId: growth.id, cycle: 'annual' } });
  });

  it('drops a plan that is not on sale instead of trusting it', async () => {
    const started = await start(form({ planId: 'no-such-plan', cycle: 'annual' }));
    expect(started.status).toBe(202);
    expect(started.body.choice).toBeNull();
  });
});

describe('with email verification switched off', () => {
  it('creates the academy at once and signs its owner in', async () => {
    process.env.SIGNUP_EMAIL_VERIFICATION = 'off';
    const body = form();
    const res = await start(body);
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body).toMatchObject({ status: 'created', user: { email: body.email, role: 'admin' } });
    expect(typeof res.body.token).toBe('string');
  });
});

describe('two self-registered admins', () => {
  it('cannot reach each other’s academy', async () => {
    process.env.SIGNUP_EMAIL_VERIFICATION = 'off';
    const a = (await start(form())).body;
    const b = (await start(form())).body;
    const asA = (path: string) => request(app).get(path).set('Authorization', `Bearer ${a.token}`);
    const bUser = await platformDb.user.findUniqueOrThrow({ where: { email: b.user.email } });
    // Admin A sees only their own academy's people, never Admin B.
    const people = await asA('/instructors');
    expect(JSON.stringify(people.body)).not.toContain(b.user.email);
    // Nor can an academy admin reach another academy through the platform's routes.
    expect((await asA(`/superadmin/tenants/${bUser.tenantId}`)).status).toBe(403);
    // Each owner's session runs for their own academy only.
    const aUser = await platformDb.user.findUniqueOrThrow({ where: { email: a.user.email } });
    expect(aUser.tenantId).not.toBe(bUser.tenantId);
  });
});

describe('the static test code (lib/testOtp.ts)', () => {
  afterEach(() => {
    process.env.TEST_OTP_EMAIL = '';
    process.env.TEST_OTP_CODE = '';
    process.env.NODE_ENV = 'test';
  });

  it('registers the test account’s academy with it, refuses it for anyone else, and is refused in production', async () => {
    const mine = form();
    const theirs = form();
    const ids = { mine: (await start(mine)).body.signupId as string, theirs: (await start(theirs)).body.signupId as string };
    const emailed = await codeFor(mine.email);
    const testCode = wrong(emailed);
    process.env.TEST_OTP_EMAIL = mine.email;
    process.env.TEST_OTP_CODE = testCode;

    expect((await verify(ids.theirs, testCode)).status).toBe(400);

    process.env.NODE_ENV = 'production';
    try {
      expect((await verify(ids.mine, testCode)).status).toBe(400);
    } finally {
      process.env.NODE_ENV = 'test';
    }

    const done = await verify(ids.mine, testCode);
    expect(done.status, JSON.stringify(done.body)).toBe(201);
    expect(JSON.stringify(done.body)).not.toContain(testCode);
    expect(done.body.user).toMatchObject({ email: mine.email, role: 'admin' });
  });
});
