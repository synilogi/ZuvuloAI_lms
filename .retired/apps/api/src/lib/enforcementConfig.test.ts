import { describe, expect, it } from 'vitest';

import { assertBillingConfig } from './billingConfig.js';
import { entitlementEnforcement } from './entitlements.js';
import { assertTenancyConfig } from './tenancy.js';

/* The switches that keep one Admin's data and plan apart from another's cannot be lost by accident in production. */

describe('plan enforcement', () => {
  it('is on in production unless explicitly rolled back, and off elsewhere unless asked for', () => {
    expect(entitlementEnforcement({ NODE_ENV: 'production' })).toBe(true);
    expect(entitlementEnforcement({ NODE_ENV: 'production', ENTITLEMENT_ENFORCEMENT: 'off' })).toBe(false);
    expect(entitlementEnforcement({ NODE_ENV: 'production', ENTITLEMENT_ENFORCEMENT: 'yes' })).toBe(true);
    expect(entitlementEnforcement({ NODE_ENV: 'development' })).toBe(false);
    expect(entitlementEnforcement({ NODE_ENV: 'test', ENTITLEMENT_ENFORCEMENT: 'on' })).toBe(true);
  });

  it('needs its dunning terms wherever it is on — including production by default', () => {
    expect(() => assertBillingConfig({ NODE_ENV: 'production' })).toThrow(/SUBSCRIPTION_RETRY_DAYS and SUBSCRIPTION_GRACE_DAYS/);
    expect(() => assertBillingConfig({ NODE_ENV: 'production', SUBSCRIPTION_RETRY_DAYS: '3', SUBSCRIPTION_GRACE_DAYS: '7' })).not.toThrow();
    expect(() => assertBillingConfig({ NODE_ENV: 'production', ENTITLEMENT_ENFORCEMENT: 'off' })).not.toThrow();
  });
});

describe('tenant isolation', () => {
  it('cannot be switched off in production', () => {
    expect(() => assertTenancyConfig({ NODE_ENV: 'production', TENANT_ENFORCEMENT: 'off' })).toThrow(/refused in production/);
    expect(() => assertTenancyConfig({ NODE_ENV: 'production' })).not.toThrow();
    expect(() => assertTenancyConfig({ NODE_ENV: 'development', TENANT_ENFORCEMENT: 'off' })).not.toThrow();
  });
});
