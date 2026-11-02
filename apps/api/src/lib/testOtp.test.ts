import { describe, expect, it } from 'vitest';

import { assertTestOtpConfig, testOtpAllowedHere, testOtpEnabled, testOtpMatches } from './testOtp.js';

/* The static test code (lib/testOtp.ts): only for the one test account, only in development or test — never on a staging
 * or production server, which refuses to start with it set (owner's rule, 2026-10-28). */

const EMAIL = 'qa-account@example.com';
const CODE = '482913';
const set = (env: Record<string, string | undefined>): NodeJS.ProcessEnv => ({ TEST_OTP_EMAIL: EMAIL, TEST_OTP_CODE: CODE, ...env });

const staging = (over: Record<string, string | undefined> = {}) =>
  set({ NODE_ENV: 'production', APP_ENV: 'staging', APP_URL: 'https://staging.example.com', CORS_ORIGIN: 'https://staging.example.com', ...over });

const PRODUCTIONS: [string, NodeJS.ProcessEnv][] = [
  ['NODE_ENV=production', set({ NODE_ENV: 'production', APP_URL: 'https://zuviloai.com', CORS_ORIGIN: 'https://zuviloai.com' })],
  ['production on any other host', set({ NODE_ENV: 'production', APP_URL: 'https://staging.example.com', CORS_ORIGIN: 'https://staging.example.com' })],
  ['APP_ENV=staging on the production site', staging({ APP_URL: 'https://zuviloai.com', CORS_ORIGIN: 'https://zuviloai.com' })],
  ['APP_ENV=staging on www', staging({ APP_URL: 'https://www.zuviloai.com' })],
  ['APP_ENV=staging serving the production origin', staging({ CORS_ORIGIN: 'https://zuviloai.com' })],
  ['APP_ENV=staging with no APP_URL', staging({ APP_URL: undefined })],
  ['APP_ENV=staging with an unreadable APP_URL', staging({ APP_URL: 'not a url' })],
  ['APP_ENV with any other value', staging({ APP_ENV: 'Staging ' })],
  ['NODE_ENV=development on the production site', set({ NODE_ENV: 'development', APP_URL: 'https://zuviloai.com' })],
  ['NODE_ENV=test serving the production origin', set({ NODE_ENV: 'test', CORS_ORIGIN: 'https://zuviloai.com' })],
  ['the production origin among several', set({ NODE_ENV: 'development', CORS_ORIGIN: 'http://localhost:5173, https://www.zuviloai.com' })],
  ['the production site with a trailing dot', staging({ APP_URL: 'https://zuviloai.com.' })],
  ['the production server by its address', staging({ APP_URL: 'http://82.25.115.114' })],
  ['a staging deployment off the production site', staging()],
  ['NODE_ENV=development on a server that calls itself staging', set({ NODE_ENV: 'development', APP_ENV: 'staging' })],
  ['NODE_ENV=test on a server that calls itself production', set({ NODE_ENV: 'test', APP_ENV: 'Production' })],
  ['an unset NODE_ENV', set({ NODE_ENV: undefined })],
  ['an unknown NODE_ENV', set({ NODE_ENV: 'prod' })],
];

describe('where the static code may run', () => {
  it('runs in development and test only', () => {
    for (const env of [set({ NODE_ENV: 'development' }), set({ NODE_ENV: 'test' })]) {
      expect(testOtpAllowedHere(env)).toBe(true);
      expect(() => assertTestOtpConfig(env)).not.toThrow();
      expect(testOtpEnabled(env)).toBe(true);
      expect(testOtpMatches(EMAIL, CODE, env)).toBe(true);
    }
  });

  it.each(PRODUCTIONS)('never runs with %s: the API refuses to start, and the code is refused anyway', (_, env) => {
    expect(testOtpAllowedHere(env)).toBe(false);
    expect(() => assertTestOtpConfig(env)).toThrow(/refused here/);
    expect(testOtpEnabled(env)).toBe(false);
    expect(testOtpMatches(EMAIL, CODE, env)).toBe(false);
  });

  it('refuses production with even one of the two set', () => {
    const prod = { NODE_ENV: 'production', APP_URL: 'https://zuviloai.com', CORS_ORIGIN: 'https://zuviloai.com' };
    expect(() => assertTestOtpConfig({ ...prod, TEST_OTP_CODE: CODE })).toThrow(/refused here/);
    expect(() => assertTestOtpConfig({ ...prod, TEST_OTP_EMAIL: EMAIL })).toThrow(/refused here/);
  });

  it('lets production start, and changes nothing, when neither is set', () => {
    const prod = { NODE_ENV: 'production', APP_URL: 'https://zuviloai.com', CORS_ORIGIN: 'https://zuviloai.com' };
    expect(() => assertTestOtpConfig(prod)).not.toThrow();
    expect(() => assertTestOtpConfig({ ...prod, TEST_OTP_EMAIL: ' ', TEST_OTP_CODE: '' })).not.toThrow();
    expect(testOtpEnabled(prod)).toBe(false);
  });
});

describe('what the static code confirms', () => {
  const dev = set({ NODE_ENV: 'development' });

  it('confirms the test account only, whatever the address’s case', () => {
    expect(testOtpMatches(' QA-Account@Example.com ', CODE, dev)).toBe(true);
    expect(testOtpMatches('someone-else@example.com', CODE, dev)).toBe(false);
    expect(testOtpMatches(`x${EMAIL}`, CODE, dev)).toBe(false);
  });

  it('confirms every listed test account, and only those', () => {
    const list = set({ NODE_ENV: 'development', TEST_OTP_EMAIL: ` ${EMAIL} , QA-Two@Example.com,, ` });
    expect(() => assertTestOtpConfig(list)).not.toThrow();
    expect(testOtpMatches(EMAIL, CODE, list)).toBe(true);
    expect(testOtpMatches('qa-two@example.com', CODE, list)).toBe(true);
    expect(testOtpMatches('qa-three@example.com', CODE, list)).toBe(false);
    expect(testOtpMatches('', CODE, list)).toBe(false);
  });

  it('confirms every address with *, on a development or test process only', () => {
    for (const NODE_ENV of ['development', 'test']) {
      const env = set({ NODE_ENV, TEST_OTP_EMAIL: ' * ' });
      expect(() => assertTestOtpConfig(env)).not.toThrow();
      expect(testOtpMatches('anyone@example.com', CODE, env)).toBe(true);
      expect(testOtpMatches('real.person@gmail.com', CODE, env)).toBe(true);
      expect(testOtpMatches('anyone@example.com', '482914', env)).toBe(false);
    }
    // A staging server refuses it as production does.
    const onStaging = staging({ TEST_OTP_EMAIL: '*' });
    expect(() => assertTestOtpConfig(onStaging)).toThrow(/refused here/);
    expect(testOtpMatches('anyone@example.com', CODE, onStaging)).toBe(false);
    for (const [, env] of PRODUCTIONS) {
      const all = { ...env, TEST_OTP_EMAIL: '*' };
      expect(() => assertTestOtpConfig(all)).toThrow(/refused here/);
      expect(testOtpMatches('anyone@example.com', CODE, all)).toBe(false);
    }
  });

  it('takes no other wildcard, and one bad entry turns the whole list off', () => {
    for (const emails of ['*@example.com', `${EMAIL},*`, `${EMAIL},not-an-address`, `${EMAIL},a b@example.com`]) {
      const env = set({ NODE_ENV: 'development', TEST_OTP_EMAIL: emails });
      expect(() => assertTestOtpConfig(env)).toThrow(/no other wildcards/);
      expect(testOtpMatches(EMAIL, CODE, env)).toBe(false);
      expect(testOtpMatches('anyone@example.com', CODE, env)).toBe(false);
    }
  });

  it('confirms only the configured code', () => {
    for (const code of ['482914', '48291', '4829130', '', '000000']) expect(testOtpMatches(EMAIL, code, dev)).toBe(false);
  });

  it('is off when half set or malformed, and boot says so without naming the values', () => {
    const cases: [NodeJS.ProcessEnv, RegExp][] = [
      [{ NODE_ENV: 'development', TEST_OTP_EMAIL: EMAIL }, /both/],
      [{ NODE_ENV: 'development', TEST_OTP_CODE: CODE }, /both/],
      [set({ NODE_ENV: 'development', TEST_OTP_CODE: '12345' }), /6 digits/],
      [set({ NODE_ENV: 'development', TEST_OTP_CODE: 'abcdef' }), /6 digits/],
      [set({ NODE_ENV: 'development', TEST_OTP_EMAIL: 'not-an-address' }), /email address/],
    ];
    for (const [env, message] of cases) expect(() => assertTestOtpConfig(env)).toThrow(message);
    // Half set or with a malformed code, nothing matches.
    for (const [env] of cases.slice(0, 4)) {
      expect(testOtpMatches(EMAIL, CODE, env)).toBe(false);
      expect(testOtpMatches(EMAIL, env.TEST_OTP_CODE ?? '', env)).toBe(false);
    }
    // No refusal ever repeats the configured code or address.
    for (const env of [...PRODUCTIONS.map(([, e]) => e), ...cases.map(([e]) => e)]) {
      try {
        assertTestOtpConfig(env);
      } catch (err) {
        expect((err as Error).message).not.toContain(CODE);
        expect((err as Error).message).not.toContain(EMAIL);
      }
    }
  });
});
