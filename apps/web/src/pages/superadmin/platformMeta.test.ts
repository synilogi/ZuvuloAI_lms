import { describe, expect, it } from 'vitest';
import type { PlatformAuditEntry } from '@/services';
import {
  actionLabel,
  actorRoleLabel,
  adminChanges,
  adminFormIssues,
  auditDetails,
  auditPrefixLabel,
  describeAction,
  emptyAdminForm,
  formatBytes,
  formatUptime,
  isActive,
  pageCount,
  grantedInGroup,
  pageParam,
  rangeSummary,
  readableAuditDetails,
  targetLabel,
} from './platformMeta';

const entry = (meta: Record<string, unknown>): PlatformAuditEntry => ({
  id: 'a1',
  action: 'admin.created',
  targetType: 'user',
  targetId: 'u1',
  actor: { id: 'u0', email: 'platform@example.com', role: 'superadmin' },
  meta,
  createdAt: '2026-09-18T10:00:00.000Z',
});

describe('paging a platform directory', () => {
  it('counts pages from the total the API reports', () => {
    expect(pageCount(0, 20)).toBe(1);
    expect(pageCount(20, 20)).toBe(1);
    expect(pageCount(21, 20)).toBe(2);
    expect(pageCount(84, 20)).toBe(5);
  });

  it('reads the page from the url, and shrugs off anything that is not one', () => {
    const at = (query: string) => pageParam(new URLSearchParams(query));
    expect(at('')).toBe(1);
    expect(at('page=3')).toBe(3);
    expect(at('page=abc')).toBe(1);
    expect(at('page=0')).toBe(1);
    expect(at('page=-5')).toBe(1);
  });

  it('describes the rows on show', () => {
    expect(rangeSummary(0, 1, 20)).toBe('No results');
    expect(rangeSummary(84, 1, 20)).toBe('1–20 of 84');
    expect(rangeSummary(84, 5, 20)).toBe('81–84 of 84');
  });
});

describe('audit presentation', () => {
  it('reads an action without inventing words for one it does not know', () => {
    expect(actionLabel('admin.created')).toBe('Admin created');
    expect(actionLabel('user.suspended')).toBe('User suspended');
    expect(actionLabel('whatever')).toBe('Whatever');
  });

  it('shows metadata as text, whatever shape the column held', () => {
    expect(auditDetails(entry({ reason: 'joined', count: 3, forced: true }))).toEqual([
      { label: 'reason', value: 'joined' },
      { label: 'count', value: '3' },
      { label: 'forced', value: 'true' },
    ]);
    // A nested value is printed as JSON rather than as "[object Object]".
    expect(auditDetails(entry({ changes: { role: 'admin' } }))).toEqual([{ label: 'changes', value: '{"role":"admin"}' }]);
    expect(auditDetails(entry({ missing: null }))).toEqual([{ label: 'missing', value: '—' }]);
    expect(auditDetails(entry({}))).toEqual([]);
  });

  it('says what happened in everyday words, and never hides an action it does not know', () => {
    expect(describeAction('academy.suspended')).toBe('Workspace access paused');
    expect(describeAction('payment.recorded_offline')).toBe('Payment recorded by hand');
    expect(describeAction('something.new')).toBe('Something new');
    expect(targetLabel('academy')).toBe('Workspace');
    expect(targetLabel('tax_rule')).toBe('Tax rule');
    expect(targetLabel('mystery')).toBe('Mystery');
    expect(actorRoleLabel('superadmin')).toBe('Platform owner');
    expect(actorRoleLabel('admin')).toBe('Admin');
  });

  it('names the affiliate program’s actions and filter, and reads a carry-forward correction in CV, not rupees', () => {
    expect(describeAction('mlm.carry.adjusted')).toBe('Carry-forward corrected');
    expect(describeAction('mlm.rank.recalculated')).toBe('Rank checked by hand');
    expect(targetLabel('affiliate')).toBe('Affiliate');
    expect(auditPrefixLabel('mlm.')).toBe('Affiliate program');
    expect(auditPrefixLabel('payment.')).toBe('payment.');
    expect(
      readableAuditDetails({
        ...entry({ leg: 'A', cvChange: -50_000, before: 149_900, after: 99_900, reason: 'Mistaken credit' }),
        action: 'mlm.carry.adjusted',
      }),
    ).toEqual([
      { label: 'Leg', value: 'A' },
      { label: 'Change', value: '-500 CV' },
      { label: 'Before', value: '1,499 CV' },
      { label: 'After', value: '999 CV' },
      { label: 'Reason', value: 'Mistaken credit' },
    ]);
  });

  it('reads the details for people: plain labels, Yes/No, from → to, and an amount as money', () => {
    expect(
      readableAuditDetails(
        entry({
          subscriptionId: 'cmv1',
          planVersion: { from: null, to: 'v2' },
          emitted: { from: false, to: true },
          amount: 399900,
          currency: 'INR',
          note: 'ok',
        }),
      ),
    ).toEqual([
      { label: 'Plan version', value: '— → v2' },
      { label: 'Emitted', value: 'No → Yes' },
      { label: 'Amount', value: '₹3,999' },
      { label: 'Note', value: 'ok' },
    ]);
    expect(readableAuditDetails(entry({ changes: { role: 'admin', count: 3 } }))).toEqual([{ label: 'Changes', value: 'Role: admin; Count: 3' }]);
    expect(readableAuditDetails(entry({ tags: [] }))).toEqual([{ label: 'Tags', value: '—' }]);
    // An LMS's status change uses the Access panel's words.
    expect(readableAuditDetails({ ...entry({ from: 'suspended', to: 'active' }), action: 'academy.reactivated' })).toEqual([
      { label: 'Change', value: 'Paused → Open' },
    ]);
    expect(readableAuditDetails({ ...entry({ from: 'active', to: 'archived', reason: 'Left' }), action: 'academy.archived' })).toEqual([
      { label: 'Change', value: 'Open → Closed' },
      { label: 'Reason', value: 'Left' },
    ]);
  });
});

describe('system figures', () => {
  it('sizes storage for people', () => {
    expect(formatBytes(0)).toBe('0 B');
    expect(formatBytes(512)).toBe('512 B');
    expect(formatBytes(1536)).toBe('1.5 KB');
    expect(formatBytes(1024 ** 3 * 2.5)).toBe('2.5 GB');
  });

  it('reads an uptime', () => {
    expect(formatUptime(48)).toBe('48s');
    expect(formatUptime(720)).toBe('12m');
    expect(formatUptime(3600 * 4 + 720)).toBe('4h 12m');
    expect(formatUptime(86400 * 3 + 3600 * 4)).toBe('3d 4h');
  });
});

describe('the admin form', () => {
  const filled = { name: 'Kavita Menon', email: 'kavita@example.com', password: 'a-good-password', confirm: 'a-good-password' };

  it('holds no role and no workspace, because neither is the UI’s to set (docs/16, D-PLAT-03)', () => {
    expect(Object.keys(emptyAdminForm()).sort()).toEqual(['confirm', 'email', 'name', 'password']);
    // An edit asks for no password.
    expect(adminFormIssues({ ...filled, password: '', confirm: '' }, 'edit')).toEqual([]);
  });

  it('accepts a complete form', () => {
    expect(adminFormIssues(filled, 'create')).toEqual([]);
  });

  it('asks for a name, a real address and a long enough password', () => {
    const issues = adminFormIssues({ name: 'K', email: 'nope', password: 'short', confirm: 'short' }, 'create');
    expect(issues.map((i) => i.field)).toEqual(['admin-name', 'admin-email', 'admin-password']);
  });

  it('will not create an account when the two passwords differ', () => {
    const issues = adminFormIssues({ ...filled, confirm: 'something-else' }, 'create');
    expect(issues.map((i) => i.field)).toEqual(['admin-confirm']);
  });

  it('asks for no password when editing an existing admin', () => {
    expect(adminFormIssues({ ...filled, password: '', confirm: '' }, 'edit')).toEqual([]);
  });

  it('sends only what actually changed', () => {
    const admin = { id: 'a1', name: 'Kavita Menon', email: 'kavita@example.com', role: 'admin' as const, descriptor: '', createdAt: 'x', updatedAt: 'x' };
    expect(adminChanges(filled, admin)).toEqual({});
    expect(adminChanges({ ...filled, name: 'Kavita M' }, admin)).toEqual({ name: 'Kavita M' });
    // The address is normalised the way the API normalises it, so a case change is not a change.
    expect(adminChanges({ ...filled, email: 'KAVITA@example.com' }, admin)).toEqual({});
    expect(adminChanges({ ...filled, email: 'new@example.com' }, admin)).toEqual({ email: 'new@example.com' });
  });

  it('reads an account as open until it has been closed', () => {
    expect(isActive({ deactivatedAt: undefined })).toBe(true);
    expect(isActive({ deactivatedAt: '2026-09-18T10:00:00.000Z' })).toBe(false);
  });
});

describe('the permission editor', () => {
  const group = (granted: boolean[]) => ({
    group: 'catalog' as const,
    label: 'Catalog',
    permissions: granted.map((g, i) => ({ key: `catalog.k${i}` as never, label: `K${i}`, description: 'x', granted: g })),
  });

  it('counts what is held in a group', () => {
    expect(grantedInGroup(group([true, true, false, false, true]))).toBe(3);
    expect(grantedInGroup(group([false, false]))).toBe(0);
    expect(grantedInGroup(group([]))).toBe(0);
  });
});
