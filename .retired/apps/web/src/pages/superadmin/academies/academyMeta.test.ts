import { describe, expect, it } from 'vitest';
import { academyFormIssues, academyInput, emptyAcademyForm, planSummary, serverIssueField, signInDetails, withName, withSlug } from './academyMeta';
import { academyOption } from '../AdminDialogs';

/* The new-academy form, an academy's plan at a glance, and the details handed to its first admin. */

const filled = () => {
  const named = withName(emptyAcademyForm(), 'Jyotish Vidya Peetham');
  return { ...named, adminName: 'Kavita Menon', adminEmail: 'kavita@example.com', password: 'a-good-password' };
};

describe('the new-academy form', () => {
  it('suggests the address from the name until the address is typed', () => {
    const form = withName(emptyAcademyForm(), 'Jyotish Vidya Peetham');
    expect(form.slug).toBe('jyotish-vidya-peetham');
    const typed = withSlug(form, 'JVP Online');
    expect(typed.slug).toBe('jvp-online');
    expect(withName(typed, 'Something else').slug).toBe('jvp-online');
  });

  it('accepts a complete form, and sends it tidied', () => {
    expect(academyFormIssues(filled())).toEqual([]);
    expect(academyInput(filled())).toEqual({
      name: 'Jyotish Vidya Peetham',
      slug: 'jyotish-vidya-peetham',
      admin: { name: 'Kavita Menon', email: 'kavita@example.com', password: 'a-good-password' },
    });
  });

  it('asks for every field, an address by the server’s own rule, and a long enough password', () => {
    expect(academyFormIssues(emptyAcademyForm()).map((i) => i.field)).toEqual([
      'academy-name',
      'academy-slug',
      'academy-admin-name',
      'academy-admin-email',
      'academy-admin-password',
    ]);
    expect(academyFormIssues({ ...filled(), slug: 'ab' })[0].message).toBe('Use 3 to 40 characters.');
    expect(academyFormIssues({ ...filled(), slug: 'admin' })[0].message).toBe('That address is reserved. Choose another.');
    expect(academyFormIssues({ ...filled(), slug: '-bad--slug' })[0].field).toBe('academy-slug');
    expect(academyFormIssues({ ...filled(), password: 'short' }).map((i) => i.field)).toEqual(['academy-admin-password']);
  });

  it('puts a refusal from the server beside the field it is about', () => {
    expect(serverIssueField('Another academy already uses that address.')).toBe('academy-slug');
    expect(serverIssueField('An account with this email already exists.')).toBe('academy-admin-email');
    expect(serverIssueField('The password must be at least 8 characters.')).toBe('academy-admin-password');
    expect(serverIssueField('Give the academy a name.')).toBe('academy-name');
  });
});

describe('an academy’s plan at a glance', () => {
  const sub = (status: 'trialing' | 'active' | 'past_due' | 'canceling' | 'expired') => ({
    id: 's1',
    status,
    plan: { id: 'p', code: 'GROWTH', name: 'Growth' },
    currentPeriodEndAt: '2026-11-03T06:00:00.000Z',
    trialEndAt: '2026-10-17T06:00:00.000Z',
  });

  it('names the plan and where it stands', () => {
    expect(planSummary(null).label).toBe('No plan');
    expect(planSummary(sub('trialing')).label).toBe('Growth · Free trial · ends 17 Oct');
    expect(planSummary(sub('active')).label).toBe('Growth · Active');
    expect(planSummary(sub('past_due'))).toMatchObject({ label: 'Growth · Payment overdue', tone: 'danger' });
    expect(planSummary(sub('canceling')).label).toBe('Growth · Ends 3 Nov');
    expect(planSummary(sub('expired')).label).toBe('Growth · Expired');
  });
});

describe('what the first admin is handed', () => {
  it('carries the password only while it is known', () => {
    const base = { academy: 'Jyotish Vidya Peetham', email: 'kavita@example.com', loginUrl: 'https://lms.example/login' };
    expect(signInDetails({ ...base, password: 'Secret-123' })).toBe(
      'LMS: Jyotish Vidya Peetham\nSign in at: https://lms.example/login\nEmail: kavita@example.com\nPassword: Secret-123',
    );
    expect(signInDetails(base)).not.toContain('Password');
  });
});

describe('the academy picker on the admin form', () => {
  it('marks the demo academy, so nobody puts a customer’s admin in it by accident', () => {
    expect(academyOption({ name: 'ZuviloAI Academy', slug: 'default-academy', isDefault: true })).toBe('ZuviloAI Academy (default-academy) — demo LMS');
    expect(academyOption({ name: 'Jyotish Vidya Peetham', slug: 'jvp', isDefault: false })).toBe('Jyotish Vidya Peetham (jvp)');
  });
});
