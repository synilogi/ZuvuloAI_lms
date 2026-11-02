import { describe, expect, it } from 'vitest';

import { billingDetailsIssues, emptyBillingDetails } from './billingViews';

describe('billing details', () => {
  it('asks for everything an invoice needs, as the server does', () => {
    expect(billingDetailsIssues(emptyBillingDetails()).map((i) => i.field)).toEqual(['legalName', 'email', 'addressLine1', 'city', 'postalCode']);
    const full = {
      ...emptyBillingDetails(),
      legalName: 'Jyotish Vidya Pvt Ltd',
      email: 'billing@jyotish.example',
      addressLine1: '1 MG Road',
      city: 'Bengaluru',
      region: 'KA',
      postalCode: '560001',
    };
    expect(billingDetailsIssues(full)).toEqual([]);
    expect(billingDetailsIssues({ ...full, country: 'India' }).map((i) => i.field)).toEqual(['country']);
    expect(billingDetailsIssues({ ...full, region: 'Karnataka State' }).map((i) => i.field)).toEqual(['region']);
    expect(billingDetailsIssues({ ...full, taxRegistration: '29AAAAA0000A1Z5' })).toEqual([]);
    expect(billingDetailsIssues({ ...full, taxRegistration: 'x' }).map((i) => i.field)).toEqual(['taxRegistration']);
  });
});
