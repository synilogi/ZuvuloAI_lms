import { readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { BYTES_PER_GB, type PlanLimits } from '@syniastrolms/domain';
import express from 'express';
import request from 'supertest';
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from 'vitest';

import { platformDb } from '../test/db.js';
import { PASSWORD, anon, app, as, unique, type Client } from '../test/helpers.js';
import { BILLING_AUDIT_ACTIONS, recordAuditLog } from './audit.js';
import { setBillingProfile, setTaxRule } from './billing.js';
import { setClock } from './clock.js';
import { ApiError, errorHandler } from './errors.js';
import { issueInvoice } from './invoices.js';
import { observe, redact, redactText, resetObservations, setObservationSink, watchJob, webhookFailed, type Observation } from './observe.js';
import { recordPayment, refundPayment, settleRefund } from './payments.js';
import { applyDueScheduledChange, cancelPlanChange, confirmPlanChangePayment, requestPlanChange } from './planChanges.js';
import { archivePlan, createPlan, publishPlan, restorePlan, updatePlan } from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { createSubscription, expireTrial, pauseSubscription, requestCancellation, resumeSubscription, type LifecycleActor } from './subscriptions.js';
import { runAsPlatform } from './tenancy.js';

/* SAAS-014: every sensitive mutation is audited under the person, job or provider that made it (§36);
 * failures are visible (§48); and nothing the server writes to its log carries a secret, a card number,
 * a password or a token. Billed in Oman at 5% VAT so no other suite's tax rule is disturbed. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('audit and observability tests act as the platform', fn);
const provider: LifecycleActor = { type: 'provider', provider: 'testpay', reference: 'evt_audit_1' };
const scheduler: LifecycleActor = { type: 'system', job: 'audit-tests' };
let superAdmin: LifecycleActor & { type: 'user' };
let superEmail: string;
let platform: Client;
let STARTER: string;
let PRO: string;
let TRIAL: string;

const LIMITS: PlanLimits = {
  'learners.max': 100,
  'instructors.max': 5,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 5,
  'admin_accounts.max': 2,
};

async function plan(monthly: number, opts: { trial?: boolean } = {}) {
  return asPlatform(async () => {
    const p = await createPlan(
      { auth: superAdmin.auth },
      {
        name: 'Audited',
        description: 'A plan for the audit suite.',
        code: `AU${unique().toUpperCase()}`.slice(0, 24),
        currency: 'INR',
        cycles: ['monthly', 'annual'],
        monthlyPrice: monthly,
        annualPrice: monthly * 10,
        trialEnabled: Boolean(opts.trial),
        trialDays: opts.trial ? 14 : 0,
        features: ['courses.manage'],
        limits: LIMITS,
      },
    );
    await publishPlan({ auth: superAdmin.auth }, p.id);
    return p.id;
  });
}

async function subscriber(planId: string, start: 'active' | 'trial' = 'active') {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Audited Academy', slug: `aud-${unique()}` } })).id;
  await asPlatform(() =>
    setBillingProfile({ auth: superAdmin.auth }, tenantId, {
      legalName: 'Audited Academy LLC',
      email: 'billing@example.com',
      addressLine1: '1 Sultan Qaboos Street',
      city: 'Muscat',
      postalCode: '100',
      country: 'OM',
    }),
  );
  setClock('2026-09-01T00:00:00Z');
  const sub = await asPlatform(() => createSubscription(superAdmin, { tenantId, planId, cycle: 'monthly', start }));
  return { tenantId, sub };
}

/** The audit rows written about `targetId`, oldest first. */
const trail = (targetId: string) => platformDb.auditLog.findMany({ where: { targetId }, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] });

/** Collects every signal while `fn` runs. */
async function signalsDuring(fn: () => Promise<unknown>): Promise<Observation[]> {
  const seen: Observation[] = [];
  setObservationSink((_line, o) => seen.push(o));
  try {
    await fn();
  } finally {
    setObservationSink(undefined);
  }
  return seen;
}

beforeAll(async () => {
  superEmail = `audit-${unique()}@example.com`;
  const created = await provisionSuperAdmin({ email: superEmail, password: PASSWORD, name: 'Auditor' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
  platform = await as({ email: superEmail });
  await asPlatform(() => setTaxRule({ auth: superAdmin.auth }, { name: 'VAT', country: 'OM', components: [{ code: 'VAT', label: 'VAT', rateBps: 500 }] }));
  STARTER = await plan(399900);
  PRO = await plan(899900);
  TRIAL = await plan(149900, { trial: true });
});

afterEach(() => setClock(null));

describe('redaction (§48)', () => {
  it('drops the value under every sensitive key, however deep', () => {
    const out = redact({
      password: 'hunter2',
      passwordHash: '$2b$10$abcdefghijklmnopqrstuv',
      token: 'abc',
      resetToken: 'abc',
      authorization: 'Bearer abc.def.ghi',
      cookie: 'sid=1',
      apiKey: 'k',
      webhookSecret: 'whsec_x',
      signature: 't=1,v1=abc',
      cardNumber: '4242424242424242',
      cvv: '123',
      nested: { deeper: [{ keySecret: 's' }] },
    }) as Record<string, unknown>;
    for (const key of [
      'password',
      'passwordHash',
      'token',
      'resetToken',
      'authorization',
      'cookie',
      'apiKey',
      'webhookSecret',
      'signature',
      'cardNumber',
      'cvv',
    ])
      expect(out[key], key).toBe('[redacted]');
    expect(out.nested).toEqual({ deeper: [{ keySecret: '[redacted]' }] });
  });

  it('masks secrets inside free text — a provider message that quotes one is still safe', () => {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyIn0.c2lnbmF0dXJlLXZhbHVl';
    const text = [
      `card 4242 4242 4242 4242 and 5555-5555-5555-4444 and 4000056655665556`,
      `auth Bearer ${jwt} and bare ${jwt}`,
      'keys sk_live_51Habcdefghijk rk_test_abcdefghij whsec_abcdefghijkl rzp_live_ABCDEFGHIJ',
      'link https://app.example.com/reset-password/9f8e7d6c5b4a39281706 and ?token=abc123&x=1',
      'config RAZORPAY_KEY_SECRET=topsecretvalue password: hunter2',
    ].join('\n');
    const safe = redactText(text);
    for (const secret of [
      '4242 4242 4242 4242',
      '5555-5555-5555-4444',
      '4000056655665556',
      jwt,
      'sk_live_51Habcdefghijk',
      'rk_test_abcdefghij',
      'whsec_abcdefghijkl',
      'rzp_live_ABCDEFGHIJ',
      '9f8e7d6c5b4a39281706',
      'abc123',
      'topsecretvalue',
      'hunter2',
    ])
      expect(safe, secret).not.toContain(secret);
  });

  it('leaves what an operator needs: ids, amounts, currencies, the last four digits', () => {
    const fields = { invoiceId: 'cm0abc', amount: 419895, currency: 'INR', last4: '4242', provider: 'testpay', at: '2026-09-22T10:00:00.000Z' };
    expect(redact(fields)).toEqual(fields);
  });
});

describe('the audit trail names who did it (§36)', () => {
  it('a plan’s life, and what its versions change in features and limits, under the super admin', async () => {
    const id = await asPlatform(async () => {
      const p = await createPlan(
        { auth: superAdmin.auth },
        {
          name: 'Versioned',
          description: 'Changes grants.',
          code: `AV${unique().toUpperCase()}`.slice(0, 24),
          currency: 'INR',
          cycles: ['monthly'],
          monthlyPrice: 100000,
          annualPrice: 0,
          trialEnabled: false,
          trialDays: 0,
          features: ['courses.manage'],
          limits: LIMITS,
        },
      );
      await publishPlan({ auth: superAdmin.auth }, p.id);
      await updatePlan({ auth: superAdmin.auth }, p.id, {
        features: ['courses.manage', 'reports.basic'],
        limits: { ...LIMITS, 'courses.max': 20, 'learners.max': null },
      });
      // A price change alone moves no grant: plan.updated, and nothing else.
      await updatePlan({ auth: superAdmin.auth }, p.id, { monthlyPrice: 120000 });
      await archivePlan({ auth: superAdmin.auth }, p.id);
      await restorePlan({ auth: superAdmin.auth }, p.id);
      return p.id;
    });
    const rows = await trail(id);
    expect(rows.map((r) => r.action)).toEqual([
      'plan.created',
      'plan.published',
      'plan.updated',
      'entitlement.changed',
      'limit.changed',
      'plan.updated',
      'plan.archived',
      'plan.restored',
    ]);
    for (const r of rows)
      expect(r).toMatchObject({ actorType: 'user', actorId: superAdmin.auth.sub, actorEmail: superEmail, actorRole: 'superadmin', source: null });
    expect(JSON.parse(rows[3].metaJson)).toEqual({ version: 2, added: ['reports.basic'], removed: [] });
    expect(JSON.parse(rows[4].metaJson)).toEqual({ version: 2, limits: { 'courses.max': { from: 10, to: 20 }, 'learners.max': { from: 100, to: null } } });
  });

  it('a new subscription, and the entitlements it brings, under the person who started it', async () => {
    const { tenantId, sub } = await subscriber(STARTER);
    expect((await trail(sub.id)).map((r) => [r.action, r.actorType])).toEqual([['subscription.created', 'user']]);
    const granted = (await trail(tenantId)).find((r) => r.action === 'entitlement.changed')!;
    expect(granted).toMatchObject({ action: 'entitlement.changed', targetType: 'tenant', actorType: 'user', actorId: superAdmin.auth.sub });
    expect(JSON.parse(granted.metaJson)).toMatchObject({ subscriptionId: sub.id, entitled: { from: false, to: true } });
  });

  it('what the scheduler does is recorded as the system, naming the job — never as a person', async () => {
    const { tenantId, sub } = await subscriber(TRIAL, 'trial');
    setClock('2026-09-16T00:00:00Z');
    await asPlatform(() => expireTrial(scheduler, sub.id));
    const expired = (await trail(sub.id)).find((r) => r.action === 'subscription.trial_expired')!;
    expect(expired).toMatchObject({ actorType: 'system', source: 'audit-tests', actorId: null, actorEmail: '', actorRole: 'system' });
    const lost = (await trail(tenantId)).filter((r) => r.action === 'entitlement.changed').at(-1)!;
    expect(lost).toMatchObject({ actorType: 'system', source: 'audit-tests' });
    expect(JSON.parse(lost.metaJson)).toMatchObject({ transition: 'trial_expired', entitled: { from: true, to: false } });
  });

  it('what the provider reports is recorded as the provider — payments, invoices, refunds', async () => {
    const { sub } = await subscriber(STARTER);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: sub.id }));
    const [issued] = await trail(invoice.id);
    expect(issued).toMatchObject({ action: 'invoice.created', actorType: 'system', source: 'audit-tests' });

    // A failed attempt first: the payment and the invoice both record it; the invoice stays open.
    await asPlatform(() =>
      recordPayment(provider, {
        invoiceId: invoice.id,
        providerPaymentId: `pay_${unique()}`,
        amount: invoice.total,
        currency: 'INR',
        status: 'failed',
        failureCode: 'card_declined',
        failureMessage: 'Declined',
      }),
    );
    const paid = await asPlatform(() =>
      recordPayment(provider, { invoiceId: invoice.id, providerPaymentId: `pay_${unique()}`, amount: invoice.total, currency: 'INR', status: 'paid' }),
    );
    expect((await trail(invoice.id)).map((r) => [r.action, r.actorType, r.source])).toEqual([
      ['invoice.created', 'system', 'audit-tests'],
      ['invoice.failed', 'provider', 'testpay'],
      ['invoice.paid', 'provider', 'testpay'],
    ]);
    const payRows = await trail(paid.payment.id);
    expect(payRows.map((r) => [r.action, r.actorType, r.source])).toEqual([['payment.succeeded', 'provider', 'testpay']]);
    expect(JSON.parse(payRows[0].metaJson)).toMatchObject({ providerReference: 'evt_audit_1', amount: invoice.total, settledInvoice: true });

    // A refund asked for by a person, settled by the provider; a second one fails.
    const full = await asPlatform(() => refundPayment({ auth: superAdmin.auth }, paid.payment.id, { amount: 1000, reason: 'Goodwill credit' }));
    await asPlatform(() => settleRefund(provider, full.id, { status: 'succeeded', providerRefundId: `rf_${unique()}` }));
    const second = await asPlatform(() => refundPayment({ auth: superAdmin.auth }, paid.payment.id, { amount: 500, reason: 'Second credit' }));
    await asPlatform(() => settleRefund(provider, second.id, { status: 'failed', failureMessage: 'Insufficient balance' }));
    expect((await trail(paid.payment.id)).map((r) => [r.action, r.actorType])).toEqual([
      ['payment.succeeded', 'provider'],
      ['payment.refund_requested', 'user'],
      ['payment.refunded', 'provider'],
      ['payment.refund_requested', 'user'],
      ['payment.refund_failed', 'provider'],
    ]);
  });

  it('every move of a subscription, whoever made it', async () => {
    const { tenantId, sub } = await subscriber(STARTER);
    setClock('2026-09-05T00:00:00Z');
    await asPlatform(() => pauseSubscription(superAdmin, sub.id, { days: 3, reason: 'Holiday' }));
    await asPlatform(() => resumeSubscription(superAdmin, sub.id, {}));
    // An upgrade the provider's payment confirms: the plan and the entitlements move under the provider.
    const upgrade = await asPlatform(() => requestPlanChange(superAdmin, sub.id, { planId: PRO, cycle: 'monthly' }, 'upgrade'));
    await asPlatform(() => confirmPlanChangePayment(provider, upgrade.id));
    // A downgrade withdrawn by a person, then another applied by the scheduler at the boundary.
    const first = await asPlatform(() => requestPlanChange(superAdmin, sub.id, { planId: STARTER, cycle: 'monthly' }, 'downgrade'));
    await asPlatform(() => cancelPlanChange(superAdmin, first.id, { reason: 'Changed my mind' }));
    await asPlatform(() => requestPlanChange(superAdmin, sub.id, { planId: STARTER, cycle: 'monthly' }, 'downgrade'));
    setClock('2026-10-05T00:00:00Z');
    await asPlatform(() => applyDueScheduledChange(scheduler, sub.id));
    await asPlatform(() => requestCancellation(superAdmin, sub.id, { reason: 'Closing the academy' }));

    expect((await trail(sub.id)).map((r) => [r.action, r.actorType])).toEqual([
      ['subscription.created', 'user'],
      ['subscription.paused', 'user'],
      ['subscription.resumed', 'user'],
      ['subscription.plan_change_requested', 'user'],
      ['subscription.plan_changed', 'provider'],
      ['subscription.plan_change_requested', 'user'],
      ['subscription.plan_change_canceled', 'user'],
      ['subscription.plan_change_requested', 'user'],
      ['subscription.plan_changed', 'system'],
      ['subscription.cancel_requested', 'user'],
    ]);
    const versions = (await trail(tenantId)).filter((r) => r.action === 'entitlement.changed').map((r) => [r.actorType, JSON.parse(r.metaJson).transition]);
    // A paused academy is not entitled (§21): it loses its plan while paused and gets it back on resume.
    expect(versions).toEqual([
      ['user', 'create'],
      ['user', 'pause'],
      ['user', 'resume'],
      ['provider', 'change_plan'],
      ['system', 'change_plan'],
    ]);
  });

  it('writes every action §36 names', async () => {
    const required = [
      'plan.created',
      'plan.updated',
      'plan.archived',
      'plan.restored',
      'subscription.created',
      'subscription.plan_changed',
      'subscription.cancel_requested',
      'subscription.canceled',
      'subscription.resumed',
      'subscription.paused',
      'payment.succeeded',
      'payment.failed',
      'payment.refunded',
      'invoice.created',
      'invoice.paid',
      'invoice.failed',
      'entitlement.changed',
      'limit.changed',
    ];
    expect(Object.values(BILLING_AUDIT_ACTIONS)).toEqual(expect.arrayContaining(required.filter((a) => !a.startsWith('plan.') && a !== 'limit.changed')));
    // `subscription.canceled` has not come up above: cancel one outright.
    const { sub } = await subscriber(STARTER);
    const { cancelNow } = await import('./subscriptions.js');
    await asPlatform(() => cancelNow(superAdmin, sub.id, { reason: 'Fraudulent sign-up' }));
    const written = new Set(
      (await platformDb.auditLog.findMany({ where: { action: { in: required } }, select: { action: true }, distinct: ['action'] })).map((r) => r.action),
    );
    expect(required.filter((a) => !written.has(a))).toEqual([]);
  });
});

describe('the audit trail is append-only, and says who (database)', () => {
  it('refuses to change or delete an entry', async () => {
    const id = (await recordAuditLog(scheduler, { action: 'test.appended', targetType: 'test' }))!;
    await expect(platformDb.auditLog.update({ where: { id }, data: { action: 'test.rewritten' } })).rejects.toThrow();
    await expect(platformDb.auditLog.update({ where: { id }, data: { metaJson: '{"forged":true}' } })).rejects.toThrow();
    await expect(platformDb.auditLog.delete({ where: { id } })).rejects.toThrow();
    await expect(platformDb.auditLog.deleteMany({ where: { targetType: 'test' } })).rejects.toThrow();
    expect(await platformDb.auditLog.findUnique({ where: { id } })).toMatchObject({ action: 'test.appended', actorType: 'system', source: 'audit-tests' });
  });

  it('refuses an entry that does not say who: a system event without its source, or a person with one', async () => {
    const base = { actorEmail: '', action: 'test.shape', targetType: 'test' };
    await expect(platformDb.auditLog.create({ data: { ...base, actorRole: 'system', actorType: 'system' } })).rejects.toThrow();
    await expect(platformDb.auditLog.create({ data: { ...base, actorRole: 'system', actorType: 'system', source: '  ' } })).rejects.toThrow();
    await expect(
      platformDb.auditLog.create({ data: { ...base, actorRole: 'provider', actorType: 'provider', source: 'x', actorId: superAdmin.auth.sub } }),
    ).rejects.toThrow();
    await expect(platformDb.auditLog.create({ data: { ...base, actorRole: 'admin', actorType: 'user', source: 'forged' } })).rejects.toThrow();
    await expect(platformDb.auditLog.create({ data: { ...base, actorRole: 'robot', actorType: 'robot', source: 'x' } })).rejects.toThrow();
  });

  it('keeps an entry, without its link, when the account it names is removed', async () => {
    const gone = await provisionSuperAdmin({ email: `gone-${unique()}@example.com`, password: PASSWORD, name: 'Gone' });
    const id = (await recordAuditLog({ auth: { sub: gone.user.id, role: 'superadmin' } }, { action: 'test.orphaned', targetType: 'test' }))!;
    await platformDb.user.delete({ where: { id: gone.user.id } });
    expect(await platformDb.auditLog.findUnique({ where: { id } })).toMatchObject({ actorId: null, actorEmail: gone.user.email, actorType: 'user' });
  });
});

describe('failures are visible (§48)', () => {
  afterAll(() => resetObservations());

  it('a failed payment, a refund the provider refused, and money that does not settle its invoice', async () => {
    const { sub } = await subscriber(STARTER);
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: sub.id }));
    const signals = await signalsDuring(async () => {
      await asPlatform(() =>
        recordPayment(provider, {
          invoiceId: invoice.id,
          providerPaymentId: `pay_${unique()}`,
          amount: invoice.total,
          currency: 'INR',
          status: 'failed',
          failureCode: 'card_declined',
          failureMessage: 'Card 4111 1111 1111 1111 was declined',
        }),
      );
      await asPlatform(() =>
        recordPayment(provider, { invoiceId: invoice.id, providerPaymentId: `pay_${unique()}`, amount: 1, currency: 'INR', status: 'paid' }),
      );
    });
    const failed = signals.find((o) => o.signal === 'payment.failed')!;
    expect(failed).toMatchObject({ level: 'warn', fields: { invoiceId: invoice.id, provider: 'testpay', failureCode: 'card_declined' } });
    expect(failed.fields.failureMessage).toBe('Card [redacted-card] was declined');
    expect(signals.find((o) => o.signal === 'payment.unmatched')).toMatchObject({ fields: { amount: 1, invoiceTotal: invoice.total } });

    // The Super Admin sees them in the failure window, and the failed payment in the payment list.
    const seen = await platform.get('/superadmin/observability', { signal: 'payment.failed' });
    expect(seen.status).toBe(200);
    expect(seen.body.failures.some((o: Observation) => o.fields.invoiceId === invoice.id)).toBe(true);
    expect(seen.body.counts['payment.failed']).toBeGreaterThanOrEqual(1);
    const list = await platform.get('/superadmin/payments', { status: 'failed', tenantId: invoice.tenantId });
    expect(list.body.rows).toHaveLength(1);
  });

  // SAAS-024 billing matrix: the right figure in the wrong currency is not the invoice's money either.
  it('a payment of the invoice’s total in another currency, which settles nothing', async () => {
    const { sub } = await subscriber(STARTER);
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: sub.id }));
    const signals = await signalsDuring(() =>
      asPlatform(() =>
        recordPayment(provider, { invoiceId: invoice.id, providerPaymentId: `pay_${unique()}`, amount: invoice.total, currency: 'USD', status: 'paid' }),
      ),
    );
    expect(signals.find((o) => o.signal === 'payment.unmatched')).toMatchObject({ fields: { currency: 'USD', invoiceCurrency: invoice.currency } });
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('open');
  });

  it('a webhook that could not be accepted, without its signature or secret', async () => {
    const signals = await signalsDuring(async () => {
      webhookFailed('testpay', 'signature did not verify', { eventId: 'evt_1', signature: 't=1,v1=deadbeef', detail: 'expected with whsec_abcdefghijklmnop' });
    });
    expect(signals).toHaveLength(1);
    expect(signals[0]).toMatchObject({ signal: 'webhook.failed', level: 'error', fields: { provider: 'testpay', eventId: 'evt_1', signature: '[redacted]' } });
    expect(JSON.stringify(signals[0])).not.toContain('whsec_abcdefghijklmnop');
    expect((await platform.get('/superadmin/observability', { signal: 'webhook.failed' })).body.failures[0].fields.eventId).toBe('evt_1');
  });

  it('a job that failed, named, with its error redacted — and rethrown to its caller', async () => {
    const signals = await signalsDuring(async () => {
      await expect(watchJob('renewals', () => Promise.reject(new Error('gateway said: key_secret=sk_live_abcdefghijklmn')))).rejects.toThrow();
    });
    expect(signals[0]).toMatchObject({ signal: 'job.failed', fields: { job: 'renewals', error: { name: 'Error' } } });
    expect(JSON.stringify(signals[0])).not.toContain('sk_live_abcdefghijklmn');
  });

  it('a subscription moving between states', async () => {
    const signals = await signalsDuring(async () => {
      const { sub } = await subscriber(STARTER);
      await asPlatform(() => requestCancellation(superAdmin, sub.id, { reason: 'Seeing the signal' }));
    });
    const moves = signals
      .filter((o) => o.signal === 'subscription.state_changed')
      .map((o) => [o.fields.transition, o.fields.from, o.fields.to, o.fields.actorType]);
    expect(moves).toEqual([
      ['create', null, 'active', 'user'],
      ['request_cancel', 'active', 'canceling', 'user'],
    ]);
  });

  it('an entitlement refusal, a limit reached, and a server fault — each with the academy and path, never the query', async () => {
    const mini = express();
    mini.use((req, _res, next) => {
      (req as express.Request).auth = { sub: 'u1', role: 'admin', tenantId: 't-observed' };
      next();
    });
    mini.get('/feature', () => {
      throw new ApiError(403, 'Live classes are not included.', undefined, 'FEATURE_NOT_INCLUDED');
    });
    mini.get('/limit', () => {
      throw new ApiError(403, 'Course limit reached.', undefined, 'LIMIT_REACHED');
    });
    mini.get('/fault', () => {
      throw new Error('connect failed with password=hunter2 for Bearer abcdefghijklmnop');
    });
    mini.use(errorHandler);
    const signals = await signalsDuring(async () => {
      await request(mini).get('/feature?token=abc');
      await request(mini).get('/limit');
      const fault = await request(mini).get('/fault?token=leaky');
      expect(fault.status).toBe(500);
      expect(JSON.stringify(fault.body)).not.toContain('hunter2');
    });
    expect(signals.map((o) => [o.signal, o.fields.path, o.fields.tenantId])).toEqual([
      ['entitlement.denied', '/feature', 't-observed'],
      ['limit.reached', '/limit', 't-observed'],
      ['request.failed', '/fault', 't-observed'],
    ]);
    const all = JSON.stringify(signals);
    for (const secret of ['hunter2', 'abcdefghijklmnop', 'leaky', 'token=abc']) expect(all, secret).not.toContain(secret);
  });

  it('is the Super Admin’s alone', async () => {
    expect((await (await as('admin')).get('/superadmin/observability')).status).toBe(403);
    expect((await anon().get('/superadmin/observability')).status).toBe(401);
  });

  it('the audit trail can be read by who did it: a person, the scheduler, the provider', async () => {
    const res = await platform.get('/superadmin/audit', { actorType: 'provider', pageSize: 100 });
    expect(res.status).toBe(200);
    expect(res.body.rows.length).toBeGreaterThan(0);
    for (const row of res.body.rows) expect(row.actor).toMatchObject({ type: 'provider', source: expect.any(String) });
    const system = await platform.get('/superadmin/audit', { actorType: 'system', action: 'invoice.created' });
    expect(system.body.rows.every((r: { actor: { type: string }; action: string }) => r.actor.type === 'system' && r.action === 'invoice.created')).toBe(true);
    expect((await platform.get('/superadmin/audit', { actorType: 'robot' })).status).toBe(400);
  });
});

describe('log sweep: nothing written to the server log carries a secret (§48)', () => {
  it('through sign-in, a password reset, payment and webhook failures, a job failure and a server fault', async () => {
    const lines: string[] = [];
    const capture =
      (_: unknown) =>
      (...args: unknown[]) => {
        lines.push(args.map((a) => (typeof a === 'string' ? a : a instanceof Error ? `${a.message}\n${a.stack}` : JSON.stringify(a))).join(' '));
      };
    const spies = (['log', 'info', 'warn', 'error', 'debug'] as const).map((m) => vi.spyOn(console, m).mockImplementation(capture(m)));
    const writes = [process.stdout, process.stderr].map((stream) =>
      vi.spyOn(stream, 'write').mockImplementation(((chunk: unknown) => {
        lines.push(String(chunk));
        return true;
      }) as never),
    );
    vi.stubEnv('OBSERVABILITY_LOG', 'on');
    vi.stubEnv('MAIL_TRANSPORT', 'log');

    const secrets: string[] = [PASSWORD];
    try {
      // Sign in with a password; the token it returns is a secret too.
      const login = await request(app).post('/auth/login').send({ email: superEmail, password: PASSWORD });
      expect(login.status).toBe(200);
      secrets.push(login.body.token);
      await request(app).get('/superadmin/observability').set('Authorization', `Bearer ${login.body.token}`);
      await request(app).post('/auth/login').send({ email: superEmail, password: 'a-wrong-password-attempt' });
      secrets.push('a-wrong-password-attempt');

      // A reset link, as the production mail log prints it: the envelope only.
      vi.stubEnv('NODE_ENV', 'production');
      try {
        expect((await request(app).post('/auth/forgot-password').send({ email: superEmail })).status).toBe(200);
      } finally {
        vi.stubEnv('NODE_ENV', 'test');
      }
      const mail = await platformDb.emailOutbox.findFirst({ where: { toEmail: superEmail, templateKey: 'password-reset' }, orderBy: { createdAt: 'desc' } });
      const resetToken = /reset-password\/(\S+)/.exec(mail!.text)![1];
      secrets.push(resetToken);

      // A declined card whose message quotes the number, a refused webhook, a failing job.
      const { sub } = await subscriber(STARTER);
      const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: sub.id }));
      await asPlatform(() =>
        recordPayment(provider, {
          invoiceId: invoice.id,
          providerPaymentId: `pay_${unique()}`,
          amount: invoice.total,
          currency: 'INR',
          status: 'failed',
          failureMessage: 'Card 4111111111111111 cvv 123 declined',
        }),
      );
      secrets.push('4111111111111111');
      webhookFailed('testpay', 'bad signature', { signature: 'v1=cafebabecafebabe', headers: { authorization: 'Basic dXNlcjpwYXNzd29yZA==' } });
      secrets.push('cafebabecafebabe', 'dXNlcjpwYXNzd29yZA==');
      await watchJob('renewals', () => Promise.reject(new Error('webhook_secret=whsec_sweepsecret123'))).catch(() => undefined);
      secrets.push('whsec_sweepsecret123');
      observe('job.failed', { job: 'direct', password: 'direct-password-field', note: 'jwt eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ4In0.c2lnbmF0dXJl' });
      secrets.push('direct-password-field', 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ4In0.c2lnbmF0dXJl');
    } finally {
      vi.unstubAllEnvs();
      for (const s of [...spies, ...writes]) s.mockRestore();
    }

    const log = lines.join('\n');
    expect(log).toContain('"observability":"payment.failed"');
    expect(log).toContain('"observability":"webhook.failed"');
    expect(log).toContain('"observability":"job.failed"');
    expect(log).toContain('[mail] to=');
    for (const secret of secrets) expect(log, `the log carries ${secret.slice(0, 12)}…`).not.toContain(secret);
    expect(log).not.toMatch(/\b\d(?:[ -]?\d){12,18}\b/);
  });

  it('nothing in the server writes to the console except the logger, the mail log and the start-up line', () => {
    const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
    const allowed = new Set(['lib/observe.ts', 'lib/mail.ts', 'index.ts']);
    const offenders: string[] = [];
    const walk = (dir: string) => {
      for (const name of readdirSync(dir)) {
        const file = path.join(dir, name);
        if (statSync(file).isDirectory()) walk(file);
        else if (file.endsWith('.ts') && !file.endsWith('.test.ts') && !file.includes(`${path.sep}test${path.sep}`)) {
          const rel = path.relative(root, file).split(path.sep).join('/');
          if (/\bconsole\.(log|info|warn|error|debug)\b|process\.std(out|err)\.write/.test(readFileSync(file, 'utf8')) && !allowed.has(rel))
            offenders.push(rel);
        }
      }
    };
    walk(root);
    expect(offenders).toEqual([]);
  });
});
