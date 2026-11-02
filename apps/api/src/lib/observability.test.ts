import { readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import express from 'express';
import request from 'supertest';
import { beforeAll, describe, expect, it, vi } from 'vitest';

import { platformDb } from '../test/db.js';
import { PASSWORD, anon, app, as, unique, type Client } from '../test/helpers.js';
import { recordAuditLog, type AuditAttribution } from './audit.js';
import { ApiError, errorHandler } from './errors.js';
import { observe, redact, redactText, resetObservations, setObservationSink, watchJob, webhookFailed, type Observation } from './observe.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';

/* SAAS-014, kept through the platform conversion (docs/16): the audit trail says who did what (§36) and refuses to
 * change; failures are visible (§48); and nothing the server writes to its log carries a secret, a card number, a
 * password or a token. The subscription, invoice and payment cases of the SaaS era are in .retired/. */

const provider: AuditAttribution = { type: 'provider', provider: 'testpay', reference: 'evt_audit_1' };
const scheduler: AuditAttribution = { type: 'system', job: 'audit-tests' };
let superAdmin: { auth: { sub: string; role: 'superadmin' } };
let superEmail: string;
let platform: Client;

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
  superAdmin = { auth: { sub: created.user.id, role: 'superadmin' } };
  platform = await as({ email: superEmail });
  // A provider-attributed entry, so the trail has every actor kind to filter by.
  await recordAuditLog(provider, { action: 'test.provider_event', targetType: 'test' });
});

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
  beforeAll(() => resetObservations());

  it('a job that failed, named, with its error redacted — and rethrown to its caller', async () => {
    const signals = await signalsDuring(async () => {
      await expect(watchJob('renewals', () => Promise.reject(new Error('gateway said: key_secret=sk_live_abcdefghijklmn')))).rejects.toThrow();
    });
    expect(signals[0]).toMatchObject({ signal: 'job.failed', fields: { job: 'renewals', error: { name: 'Error' } } });
    expect(JSON.stringify(signals[0])).not.toContain('sk_live_abcdefghijklmn');
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
    const system = await platform.get('/superadmin/audit', { actorType: 'system', action: 'test.appended' });
    expect(system.body.rows.every((r: { actor: { type: string }; action: string }) => r.actor.type === 'system' && r.action === 'test.appended')).toBe(true);
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
      observe('payment.failed', { scope: 'course', provider: 'testpay', failureMessage: 'Card 4111111111111111 cvv 123 declined' });
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
