import { afterEach, describe, expect, it, vi } from 'vitest';
import { ServiceError } from '../contracts';
import { httpCourseSales } from './courseSales';
import { httpLearning } from './learning';

/* Course purchases and the academy's course-sales gateway over http: what each call asks for, and nothing more. */

interface Call {
  url: URL;
  init: RequestInit;
  body?: unknown;
}

function stubFetch(reply: { status?: number; body: unknown }): Call[] {
  const calls: Call[] = [];
  vi.stubGlobal('fetch', (input: string, init: RequestInit) => {
    calls.push({ url: new URL(input), init, body: init.body ? JSON.parse(String(init.body)) : undefined });
    return Promise.resolve(new Response(JSON.stringify(reply.body), { status: reply.status ?? 200, headers: { 'content-type': 'application/json' } }));
  });
  vi.stubGlobal('window', { dispatchEvent: () => true });
  return calls;
}

afterEach(() => vi.unstubAllGlobals());

describe('a learner buying a course over http', () => {
  it('names only the course to open an order, and hands back only the gateway’s payment id and signature', async () => {
    const calls = stubFetch({ body: { rows: [] } });
    await httpLearning.startPurchase('c1');
    await httpLearning.confirmPurchase('p1', { paymentId: 'pay_1', signature: 'sig' });
    await httpLearning.getPurchase('p1');
    expect(await httpLearning.listPurchases()).toEqual([]);
    expect(calls.map((c) => `${c.init.method} ${c.url.pathname}`)).toEqual([
      'POST /learning/courses/c1/purchase',
      'POST /learning/purchases/p1/confirm',
      'GET /learning/purchases/p1',
      'GET /learning/purchases',
    ]);
    expect(calls[0].body).toEqual({});
    expect(calls[1].body).toEqual({ paymentId: 'pay_1', signature: 'sig' });
  });

  it('keeps the API’s refusal code', async () => {
    stubFetch({ status: 409, body: { message: 'This LMS doesn’t take online payments yet.', code: 'PAYMENTS_NOT_SET_UP' } });
    const err = await httpLearning.startPurchase('c1').catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ServiceError);
    expect(err).toMatchObject({ reason: 'PAYMENTS_NOT_SET_UP', code: 'conflict', status: 409 });
  });
});

describe('the academy’s course-sales gateway over http', () => {
  it('sends only the keys that were typed, and reads everything else', async () => {
    const calls = stubFetch({ body: { rows: [] } });
    await httpCourseSales.settings();
    await httpCourseSales.update({ enabled: true, environment: 'live' });
    await httpCourseSales.saveCredentials('live', { keyId: ' rzp_live_x ', keySecret: '', webhookSecret: '   ' });
    await httpCourseSales.test('test');
    await httpCourseSales.purchases();
    expect(calls.map((c) => `${c.init.method} ${c.url.pathname}`)).toEqual([
      'GET /tenant/course-sales/settings',
      'PUT /tenant/course-sales/settings',
      'PUT /tenant/course-sales/credentials/live',
      'POST /tenant/course-sales/credentials/test/test',
      'GET /tenant/course-sales/purchases',
    ]);
    expect(calls[1].body).toEqual({ enabled: true, environment: 'live' });
    expect(calls[2].body).toEqual({ keyId: 'rzp_live_x' });
  });
});
