import { afterEach, describe, expect, it, vi } from 'vitest';
import { ServiceError } from '../contracts';
import { httpPlatform } from './platform';

/* The platform service over a stubbed fetch: what it asks the API for, and what it hands back. */

interface Call {
  url: URL;
  init: RequestInit;
}

function stubFetch(status: number, payload: unknown): Call[] {
  const calls: Call[] = [];
  vi.stubGlobal('fetch', (input: string, init: RequestInit) => {
    calls.push({ url: new URL(input), init });
    return Promise.resolve(new Response(JSON.stringify(payload), { status, headers: { 'content-type': 'application/json' } }));
  });
  return calls;
}

const page = (rows: unknown[]) => ({ rows, total: rows.length, page: 1, pageSize: 20 });

afterEach(() => vi.unstubAllGlobals());

describe('the platform service talks to /superadmin', () => {
  it('reads the overview', async () => {
    const overview = {
      users: { total: 12, students: 8, instructors: 2, admins: 1, superadmins: 1 },
      people: { studentProfiles: 8, suspendedStudents: 0, instructorProfiles: 3, inactiveInstructors: 1 },
      courses: { total: 6, published: 4, draft: 1, archived: 1 },
      learning: { enrollments: 20, certificatesIssued: 3 },
      audit: { events: 2 },
      generatedAt: '2026-09-18T10:00:00.000Z',
    };
    const calls = stubFetch(200, overview);
    await expect(httpPlatform.overview()).resolves.toEqual(overview);
    expect(calls[0].url.pathname).toBe('/superadmin/overview');
    expect(calls[0].init.method).toBe('GET');
  });

  it('pages the admin directory', async () => {
    const calls = stubFetch(200, page([]));
    await httpPlatform.listAdmins({ page: 3, pageSize: 20 });
    expect(calls[0].url.pathname).toBe('/superadmin/admins');
    expect(calls[0].url.searchParams.get('page')).toBe('3');
    expect(calls[0].url.searchParams.get('pageSize')).toBe('20');
  });

  it('sends the search and the role filter as the API’s own parameters', async () => {
    const calls = stubFetch(200, page([]));
    await httpPlatform.listUsers({ page: 1, pageSize: 20, search: 'ananya', role: 'admin' });
    expect(calls[0].url.pathname).toBe('/superadmin/users');
    expect(calls[0].url.searchParams.get('search')).toBe('ananya');
    expect(calls[0].url.searchParams.get('role')).toBe('admin');

    // An unset filter is left off the request rather than sent empty.
    const next = stubFetch(200, page([]));
    await httpPlatform.listUsers({ page: 1, pageSize: 20 });
    expect(next[0].url.searchParams.has('search')).toBe(false);
    expect(next[0].url.searchParams.has('role')).toBe(false);
  });

  it('hands back the rows the API returned, in the order it returned them', async () => {
    const rows = [
      {
        id: 'b',
        action: 'test.newer',
        targetType: 'user',
        actor: { email: 'p@example.com', role: 'superadmin' },
        meta: {},
        createdAt: '2026-09-18T10:00:01.000Z',
      },
      {
        id: 'a',
        action: 'test.older',
        targetType: 'user',
        actor: { email: 'p@example.com', role: 'superadmin' },
        meta: {},
        createdAt: '2026-09-18T10:00:00.000Z',
      },
    ];
    stubFetch(200, { ...page(rows), total: 2 });
    const result = await httpPlatform.listAudit({ page: 1, pageSize: 20 });
    expect(result.rows.map((r) => r.id)).toEqual(['b', 'a']);
    expect(result.total).toBe(2);
  });

  it('reads the system status', async () => {
    const status = {
      database: { ok: true, latencyMs: 2 },
      email: { queued: 1, sent: 4, failed: 0 },
      media: { files: 3, totalBytes: 2048 },
      process: { environment: 'test', uptimeSeconds: 90 },
      generatedAt: '2026-09-18T10:00:00.000Z',
    };
    const calls = stubFetch(200, status);
    await expect(httpPlatform.system()).resolves.toEqual(status);
    expect(calls[0].url.pathname).toBe('/superadmin/system');
  });

  it('surfaces a refusal instead of swallowing it', async () => {
    stubFetch(403, { message: 'Not allowed' });
    await expect(httpPlatform.overview()).rejects.toBeInstanceOf(ServiceError);
    await expect(httpPlatform.overview()).rejects.toThrow('Not allowed');
  });

  it('surfaces a lost connection as a network error', async () => {
    vi.stubGlobal('fetch', () => Promise.reject(new Error('offline')));
    await expect(httpPlatform.listUsers()).rejects.toMatchObject({ code: 'network' });
  });
});

describe('admin management goes to the admin endpoints', () => {
  const row = { id: 'a1', name: 'New Admin', email: 'new@example.com', role: 'admin', descriptor: 'Academy admin', createdAt: 'x', updatedAt: 'x' };

  it('creates an admin in the academy chosen for it, with only the fields the API takes', async () => {
    const calls = stubFetch(201, row);
    await expect(httpPlatform.createAdmin({ name: 'New Admin', email: 'new@example.com', password: 'a-good-password', tenantId: 't9' })).resolves.toEqual(row);
    expect(calls[0].url.pathname).toBe('/superadmin/admins');
    expect(calls[0].init.method).toBe('POST');
    // No role is sent: the API decides it, and the UI has no say. The academy is always named.
    expect(JSON.parse(String(calls[0].init.body))).toEqual({ name: 'New Admin', email: 'new@example.com', password: 'a-good-password', tenantId: 't9' });
    expect(String(calls[0].init.body)).not.toContain('role');
  });

  it('sends only the changed fields on an edit', async () => {
    const calls = stubFetch(200, row);
    await httpPlatform.updateAdmin('a1', { name: 'Renamed' });
    expect(calls[0].url.pathname).toBe('/superadmin/admins/a1');
    expect(calls[0].init.method).toBe('PATCH');
    expect(JSON.parse(String(calls[0].init.body))).toEqual({ name: 'Renamed' });
  });

  it('deactivates and reactivates through their own endpoints', async () => {
    const off = stubFetch(200, { ...row, deactivatedAt: '2026-09-18T10:00:00.000Z' });
    const closed = await httpPlatform.deactivateAdmin('a1');
    expect(off[0].url.pathname).toBe('/superadmin/admins/a1/deactivate');
    expect(off[0].init.method).toBe('POST');
    expect(closed.deactivatedAt).toBe('2026-09-18T10:00:00.000Z');

    const on = stubFetch(200, row);
    const reopened = await httpPlatform.reactivateAdmin('a1');
    expect(on[0].url.pathname).toBe('/superadmin/admins/a1/reactivate');
    expect(reopened.deactivatedAt).toBeUndefined();
  });

  it('suspends, closes and reactivates an academy through its own endpoints, with the reason only where one is given', async () => {
    const academy = { id: 't9', name: 'Pathshala', slug: 'pathshala', status: 'suspended', statusReason: 'Unpaid invoices' };
    const off = stubFetch(200, academy);
    await expect(httpPlatform.changeAcademyStatus('t9', 'suspend', '  Unpaid invoices ')).resolves.toMatchObject({ status: 'suspended' });
    expect(off[0].url.pathname).toBe('/superadmin/tenants/t9/suspend');
    expect(off[0].init.method).toBe('POST');
    expect(JSON.parse(String(off[0].init.body))).toEqual({ reason: 'Unpaid invoices' });

    const closed = stubFetch(200, { ...academy, status: 'archived' });
    await httpPlatform.changeAcademyStatus('t9', 'archive', 'Customer left');
    expect(closed[0].url.pathname).toBe('/superadmin/tenants/t9/archive');

    const on = stubFetch(200, { ...academy, status: 'active', statusReason: undefined });
    await httpPlatform.changeAcademyStatus('t9', 'reactivate');
    expect(on[0].url.pathname).toBe('/superadmin/tenants/t9/reactivate');
    expect(JSON.parse(String(on[0].init.body))).toEqual({});
  });

  it('surfaces the API’s refusal of a status change', async () => {
    stubFetch(409, { message: 'Cancel the Admin’s subscription before archiving it.' });
    await expect(httpPlatform.changeAcademyStatus('t9', 'archive', 'Leaving')).rejects.toThrow(/Cancel the Admin’s subscription/);
  });

  it('surfaces a duplicate address instead of swallowing it', async () => {
    stubFetch(409, { message: 'An account with this email already exists.' });
    await expect(httpPlatform.createAdmin({ name: 'Twice', email: 'taken@example.com', password: 'a-good-password', tenantId: 't9' })).rejects.toThrow(
      /already exists/,
    );
  });

  it('surfaces the API’s refusal of an admin with no academy', async () => {
    stubFetch(400, { message: 'Choose the academy this admin runs.' });
    await expect(httpPlatform.createAdmin({ name: 'Nowhere', email: 'n@example.com', password: 'a-good-password', tenantId: '' })).rejects.toThrow(
      /Choose the academy/,
    );
  });
});

describe('academies go to /superadmin/tenants', () => {
  const academy = {
    id: 't1',
    name: 'Jyotish Vidya Peetham',
    slug: 'jyotish-vidya-peetham',
    status: 'active',
    owner: { id: 'u1', name: 'Kavita Menon', email: 'kavita@example.com' },
    accounts: 1,
    courses: 0,
    learners: 0,
    instructors: 0,
    isDefault: false,
    subscription: {
      id: 's1',
      status: 'trialing',
      plan: { id: 'p1', code: 'GROWTH', name: 'Growth' },
      currentPeriodEndAt: 'x',
      trialEndAt: '2026-10-17T00:00:00.000Z',
    },
    createdAt: '2026-10-03T10:00:00.000Z',
  };

  it('lists academies with each one’s latest subscription, searching only when asked', async () => {
    const calls = stubFetch(200, page([academy, { ...academy, id: 't2', subscription: null }]));
    const result = await httpPlatform.listAcademies({ page: 1, pageSize: 500 });
    expect(calls[0].url.pathname).toBe('/superadmin/tenants');
    expect(calls[0].url.searchParams.get('pageSize')).toBe('500');
    expect(calls[0].url.searchParams.has('search')).toBe(false);
    expect(result.rows[0].subscription).toMatchObject({ status: 'trialing', plan: { name: 'Growth' } });
    expect(result.rows[1].subscription).toBeNull();

    const searched = stubFetch(200, page([]));
    await httpPlatform.listAcademies({ search: '  jyotish ' });
    expect(searched[0].url.searchParams.get('search')).toBe('jyotish');
  });

  it('reads one academy by id', async () => {
    const calls = stubFetch(200, academy);
    await expect(httpPlatform.getAcademy('t1')).resolves.toMatchObject({ name: 'Jyotish Vidya Peetham' });
    expect(calls[0].url.pathname).toBe('/superadmin/tenants/t1');
  });

  it('creates an academy with its first admin, tidied the way the API stores them', async () => {
    const calls = stubFetch(201, academy);
    await httpPlatform.createAcademy({
      name: ' Jyotish Vidya Peetham ',
      slug: 'Jyotish-Vidya-Peetham',
      admin: { name: ' Kavita Menon ', email: ' Kavita@Example.com ', password: '  keep spaces  ' },
    });
    expect(calls[0].url.pathname).toBe('/superadmin/tenants');
    expect(calls[0].init.method).toBe('POST');
    expect(JSON.parse(String(calls[0].init.body))).toEqual({
      name: 'Jyotish Vidya Peetham',
      slug: 'jyotish-vidya-peetham',
      // A password is sent exactly as typed.
      admin: { name: 'Kavita Menon', email: 'kavita@example.com', password: '  keep spaces  ' },
    });
  });

  it('surfaces a taken address with the field it concerns', async () => {
    stubFetch(409, {
      message: 'Another academy already uses that address.',
      issues: [{ field: 'slug', message: 'Another academy already uses that address.' }],
    });
    await expect(httpPlatform.createAcademy({ name: 'Twice', slug: 'twice', admin: { name: 'A B', email: 'a@b.co', password: 'longenough' } })).rejects.toThrow(
      /already uses that address/,
    );
  });
});

describe('editing one admin’s permissions', () => {
  const state = {
    admin: { id: 'a1', name: 'Managed', email: 'managed@example.com', role: 'admin', descriptor: '', createdAt: 'x', updatedAt: 'x' },
    granted: ['catalog.view'],
    groups: [{ group: 'catalog', label: 'Catalog', permissions: [{ key: 'catalog.view', label: 'View courses', description: 'See courses.', granted: true }] }],
    unknown: [],
  };

  it('reads the whole catalogue for one admin', async () => {
    const calls = stubFetch(200, state);
    const result = await httpPlatform.adminPermissions('a1');
    expect(calls[0].url.pathname).toBe('/superadmin/admins/a1/permissions');
    expect(calls[0].init.method).toBe('GET');
    // The metadata comes from the API, so the editor never rebuilds the catalogue.
    expect(result.groups[0].permissions[0]).toMatchObject({ label: 'View courses', description: 'See courses.', granted: true });
  });

  it('grants one key by name, and nothing else', async () => {
    const calls = stubFetch(200, state);
    await httpPlatform.grantPermission('a1', 'catalog.publish');
    expect(calls[0].url.pathname).toBe('/superadmin/admins/a1/permissions');
    expect(calls[0].init.method).toBe('POST');
    expect(JSON.parse(String(calls[0].init.body))).toEqual({ key: 'catalog.publish' });
    // No actor and no target are sent: the API takes both from the token and the URL.
    expect(String(calls[0].init.body)).not.toMatch(/actor|userId|role/);
  });

  it('revokes one key through its own address', async () => {
    const calls = stubFetch(200, { ...state, granted: [] });
    const result = await httpPlatform.revokePermission('a1', 'catalog.view');
    expect(calls[0].url.pathname).toBe('/superadmin/admins/a1/permissions/catalog.view');
    expect(calls[0].init.method).toBe('DELETE');
    expect(result.granted).toEqual([]);
  });

  it('surfaces a refusal rather than pretending the change happened', async () => {
    stubFetch(403, { message: 'Not allowed' });
    await expect(httpPlatform.grantPermission('a1', 'settings.edit')).rejects.toThrow('Not allowed');
    stubFetch(400, { message: 'That is not a permission this academy has.' });
    await expect(httpPlatform.grantPermission('a1', 'catalog.view')).rejects.toThrow(/not a permission/);
  });
});
