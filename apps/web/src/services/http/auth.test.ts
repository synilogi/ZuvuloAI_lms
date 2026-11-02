import { afterEach, describe, expect, it, vi } from 'vitest';

import { ServiceError } from '../contracts';
import { deleteAccount, sessionRefused } from './auth';

describe('sessionRefused', () => {
  it('ends the session when the API refuses it', () => {
    expect(sessionRefused(new ServiceError('This account has been deactivated.', 'forbidden'))).toBe(true);
    expect(sessionRefused(new ServiceError('Sign in required', 'conflict'))).toBe(true);
    expect(sessionRefused(new ServiceError('Account not found.', 'not-found'))).toBe(true);
    expect(sessionRefused(new Error('unexpected'))).toBe(true);
  });

  it('keeps the token when the API could not be reached or failed', () => {
    expect(sessionRefused(new ServiceError('Could not reach the server.', 'network'))).toBe(false);
    expect(sessionRefused(new ServiceError('Something went wrong.', 'unknown'))).toBe(false);
  });
});

describe('deleteAccount', () => {
  afterEach(() => vi.unstubAllGlobals());

  /** Answers the one request with `status`/`body`, recording what was asked. */
  function stubFetch(status: number, body: unknown) {
    const calls: { url: string; init: RequestInit }[] = [];
    vi.stubGlobal('fetch', (url: string, init: RequestInit) => {
      calls.push({ url, init });
      return Promise.resolve(new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } }));
    });
    return calls;
  }

  it('posts the password to the delete-account endpoint', async () => {
    const calls = stubFetch(200, { ok: true });
    await deleteAccount('correct horse');
    expect(calls).toHaveLength(1);
    expect(new URL(calls[0].url).pathname).toBe('/auth/delete-account');
    expect(calls[0].init.method).toBe('POST');
    expect(JSON.parse(String(calls[0].init.body))).toEqual({ password: 'correct horse' });
  });

  it("rejects with the API's own words so the page can show them", async () => {
    stubFetch(403, { message: 'Your password is not correct.' });
    await expect(deleteAccount('wrong')).rejects.toMatchObject({ code: 'forbidden', message: 'Your password is not correct.' });
  });
});
