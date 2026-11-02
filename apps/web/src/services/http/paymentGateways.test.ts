import { afterEach, describe, expect, it, vi } from 'vitest';
import { platformErrorOf } from '@/lib/platformErrors';
import { ServiceError } from '../contracts';
import { httpPaymentGateways as service } from './paymentGateways';

/* SAAS-017: what each gateway call asks the API for — and that nothing but the typed credentials is sent. */

interface Call {
  url: URL;
  init: RequestInit;
  body?: unknown;
}

const events: string[] = [];

function stubFetch(reply: { status?: number; body: unknown }): Call[] {
  const calls: Call[] = [];
  vi.stubGlobal('fetch', (input: string, init: RequestInit) => {
    calls.push({ url: new URL(input), init, body: init.body ? JSON.parse(String(init.body)) : undefined });
    return Promise.resolve(new Response(JSON.stringify(reply.body), { status: reply.status ?? 200, headers: { 'content-type': 'application/json' } }));
  });
  vi.stubGlobal('window', { dispatchEvent: (e: Event) => events.push(e.type) });
  return calls;
}

afterEach(() => {
  vi.unstubAllGlobals();
  events.length = 0;
});

describe('payment gateways over http', () => {
  it('calls each endpoint with its method and body', async () => {
    const calls = stubFetch({ body: {} });
    await service.list();
    await service.get('razorpay');
    await service.configure('razorpay', { environment: 'live', credentials: { keySecret: 's' } });
    await service.update('razorpay', { enabled: false });
    await service.update('razorpay', { environment: 'live' });
    await service.test('razorpay', 'live');
    await service.test('razorpay');
    await service.activate('razorpay');
    await service.deactivate();
    expect(calls.map((c) => `${c.init.method} ${c.url.pathname}`)).toEqual([
      'GET /superadmin/payment-gateways',
      'GET /superadmin/payment-gateways/razorpay',
      'POST /superadmin/payment-gateways/razorpay/config',
      'PATCH /superadmin/payment-gateways/razorpay',
      'PATCH /superadmin/payment-gateways/razorpay',
      'POST /superadmin/payment-gateways/razorpay/test',
      'POST /superadmin/payment-gateways/razorpay/test',
      'POST /superadmin/payment-gateways/razorpay/activate',
      'POST /superadmin/payment-gateways/deactivate',
    ]);
    expect(calls[2].body).toEqual({ environment: 'live', credentials: { keySecret: 's' } });
    expect(calls[3].body).toEqual({ enabled: false });
    expect(calls[4].body).toEqual({ environment: 'live' });
    expect(calls[5].body).toEqual({ environment: 'live' });
    expect(calls[6].body).toEqual({});
  });

  it('passes a refusal on in the server’s own words', async () => {
    stubFetch({ status: 409, body: { message: 'Razorpay is the active gateway.', code: 'CONFLICT' } });
    const error = (await service.update('razorpay', { enabled: false }).catch((e: unknown) => e)) as ServiceError;
    expect(error).toBeInstanceOf(ServiceError);
    expect(error.code).toBe('conflict');
    expect(error.message).toBe('Razorpay is the active gateway.');
  });

  it('keeps the missing-key refusal as a platform state, not an academy billing banner', async () => {
    const serverMessage =
      'Secure credential storage is not configured on the server. The server administrator must set PAYMENT_CREDENTIALS_KEY and restart the API; nothing was saved.';
    stubFetch({ status: 503, body: { message: serverMessage, code: 'SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED' } });
    const error = (await service.configure('razorpay', { environment: 'test', credentials: {} }).catch((e: unknown) => e)) as ServiceError;
    expect(error.reason).toBe('SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED');
    expect(error.message).toBe(serverMessage);
    expect(platformErrorOf(error)?.code).toBe('SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED');
    expect(events).toEqual([]);
  });
});
