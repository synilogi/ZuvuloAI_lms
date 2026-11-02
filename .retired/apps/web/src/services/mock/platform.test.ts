import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { platformService as service } from './platform';
import { subscriptions } from './fixtures/subscriptions';

/* The demo build's academies: the billing demo's own, each with its latest subscription, and new ones created empty. */

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

async function refused(promise: Promise<unknown>, match: RegExp) {
  const expectation = expect(promise).rejects.toThrow(match);
  await vi.runAllTimersAsync();
  await expectation;
}

const admin = { name: 'Kavita Menon', email: 'kavita@example.com', password: 'a-good-password' };

describe('the demo platform’s academies', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('lists every academy with its latest subscription in the API’s own states, or none', async () => {
    const page = await settle(service.listAcademies({ pageSize: 500 }));
    expect(page.total).toBe(page.rows.length);
    const trialing = page.rows.find((a) => a.subscription?.status === 'trialing');
    expect(trialing?.subscription?.trialEndAt).toBeTruthy();
    expect(page.rows.some((a) => a.subscription === null)).toBe(true);
    const billed = subscriptions[0].customer.id;
    expect(page.rows.find((a) => a.id === billed)?.subscription?.plan.name).toBeTruthy();
  });

  it('searches by name or address', async () => {
    const page = await settle(service.listAcademies({ search: 'nakshatra' }));
    expect(page.rows.map((a) => a.name)).toEqual(['Nakshatra Vidya Peeth']);
  });

  it('creates an academy empty, on no plan, with its first admin as owner', async () => {
    const academy = await settle(service.createAcademy({ name: 'Jyotish Vidya Peetham', slug: 'jyotish-vidya-peetham', admin }));
    expect(academy).toMatchObject({ slug: 'jyotish-vidya-peetham', subscription: null, courses: 0, learners: 0, owner: { email: 'kavita@example.com' } });
    expect((await settle(service.getAcademy(academy.id))).name).toBe('Jyotish Vidya Peetham');
    expect((await settle(service.listAcademies({ search: 'peetham' }))).rows).toHaveLength(1);
  });

  it('refuses what the API refuses: a bad or taken address, a short password, a used email', async () => {
    await refused(service.createAcademy({ name: 'Admin', slug: 'admin', admin }), /reserved/);
    await refused(service.createAcademy({ name: 'Bad', slug: 'Bad Address', admin }), /lowercase letters/);
    await refused(service.createAcademy({ name: 'Again', slug: 'jyotish-vidya-peetham', admin: { ...admin, email: 'other@example.com' } }), /already uses/);
    await refused(service.createAcademy({ name: 'Short', slug: 'short-pass', admin: { ...admin, email: 'x@example.com', password: 'short' } }), /8 characters/);
    await refused(service.createAcademy({ name: 'Twice', slug: 'twice-over', admin }), /already exists/);
  });

  it('answers a missing academy as not found', async () => {
    const attempt = expect(service.getAcademy('nope')).rejects.toMatchObject({ code: 'not-found' });
    await vi.runAllTimersAsync();
    await attempt;
  });
});
