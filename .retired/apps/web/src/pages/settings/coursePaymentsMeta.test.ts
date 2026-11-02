import { describe, expect, it } from 'vitest';
import type { CourseSaleRow, CourseSalesSettings } from '@/services/contracts';
import { blankKeys, environmentBlocker, keyInputId, keyIssues, keyPayload, needsReviewCount, webhookAddress } from './coursePaymentsMeta';

/* The academy's own Razorpay keys: checked before sending, sent only as typed, and never read back. */

const settings = (over: Partial<CourseSalesSettings> = {}): CourseSalesSettings => ({
  provider: 'razorpay',
  environment: 'test',
  enabled: false,
  ready: false,
  credentials: { test: { configured: false }, live: { configured: false } },
  webhookPath: '/webhooks/academies/t1/razorpay/courses',
  fields: [
    { key: 'keyId', label: 'Key ID', secret: false },
    { key: 'keySecret', label: 'Key secret', secret: true },
    { key: 'webhookSecret', label: 'Webhook secret', secret: true },
  ],
  storageConfigured: true,
  ...over,
});

describe('course payment settings', () => {
  it('builds the webhook address on the API this app talks to', () => {
    expect(webhookAddress('https://api.example.com/', '/webhooks/academies/t1/razorpay/courses')).toBe(
      'https://api.example.com/webhooks/academies/t1/razorpay/courses',
    );
    expect(webhookAddress('http://localhost:4000', 'webhooks/x')).toBe('http://localhost:4000/webhooks/x');
  });

  it('asks for every key where nothing is saved, each beside its field', () => {
    const issues = keyIssues(settings(), 'test', blankKeys(settings()));
    expect(issues.map((i) => i.field)).toEqual(['keyId', 'keySecret', 'webhookSecret'].map((k) => keyInputId('test', k)));
    expect(issues[0].message).toBe('Enter the key id.');
  });

  it('lets a saved environment keep what is stored when a field is left blank', () => {
    const saved = settings({ credentials: { test: { configured: true, keyIdHint: 'rzp_test_…ab12' }, live: { configured: false } } });
    expect(keyIssues(saved, 'test', { keyId: '', keySecret: 'new-secret', webhookSecret: '' })).toEqual([]);
  });

  it('refuses a key of the other environment, and two secrets that are the same', () => {
    const values = { keyId: 'rzp_test_abc', keySecret: 'same', webhookSecret: 'same' };
    const messages = keyIssues(settings(), 'live', values).map((i) => i.message);
    expect(messages).toContain('This isn’t a live key: Razorpay live key ids begin with rzp_live_.');
    expect(messages).toContain('The webhook secret must be different from the key secret.');
  });

  it('sends only what was typed', () => {
    expect(keyPayload({ keyId: ' rzp_test_abc ', keySecret: '', webhookSecret: '  ' })).toEqual({ keyId: 'rzp_test_abc' });
  });

  it('will not turn payments on in an environment without keys', () => {
    expect(environmentBlocker(settings(), 'live', true)).toBe('Save your live keys before taking payments in live mode.');
    expect(environmentBlocker(settings(), 'live', false)).toBeNull();
  });

  it('counts the sales that need a look', () => {
    const row = { reviewReason: null } as CourseSaleRow;
    expect(needsReviewCount([row, { ...row, reviewReason: 'Already had the course.' }])).toBe(1);
  });
});
