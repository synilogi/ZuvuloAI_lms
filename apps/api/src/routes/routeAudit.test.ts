import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';

import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { app, as, newStudent } from '../test/helpers.js';

/* SAAS-024. The endpoint audit, as a test that keeps holding: every route the app mounts is found by walking its
 * routers, so a route added later is audited without anyone listing it.
 *
 * - Anonymous: every route refuses with 401, except the explicit public list below.
 * - A learner: every staff, admin and platform route refuses (401, 403 or 404 — never data, never a
 *   validation error that would mean the body was read before the role was checked).
 */

type Route = { method: string; path: string };

/** What a mount prefix looks like in Express 4's layer regexp, turned back into a path with `x` for parameters. */
function prefixOf(layer: { regexp?: RegExp & { fast_slash?: boolean } }): string {
  if (!layer.regexp || layer.regexp.fast_slash) return '';
  return (
    layer.regexp.source
      .replace(/^\^/, '')
      .split('\\/?(?=')[0]
      .replace(/\\\//g, '/')
      // A mount parameter (`/courses/:courseId/chapters`) is compiled to `(?:/([^/]+?))`.
      .split('(?:/([^/]+?))')
      .join('/x')
  );
}

function routesOf(): Route[] {
  const found: Route[] = [];
  const walk = (stack: unknown[], base: string) => {
    for (const layer of stack as {
      route?: { path: string; methods: Record<string, boolean> };
      handle?: { stack?: unknown[] };
      regexp?: RegExp & { fast_slash?: boolean };
    }[]) {
      if (layer.route) {
        for (const method of Object.keys(layer.route.methods))
          found.push({ method: method.toUpperCase(), path: `${base}${layer.route.path}`.replace(/\/$/, '') || '/' });
      } else if (layer.handle?.stack) walk(layer.handle.stack, base + prefixOf(layer));
    }
  };
  walk((app as unknown as { _router: { stack: unknown[] } })._router.stack, '');
  return found;
}

/** A route with its parameters filled, so it can be called. */
const concrete = (path: string) => path.replace(/:[A-Za-z]+/g, 'audit-x').replace(/\$\{path\}/g, 'publish');

/** Open to visitors on purpose: sign-in and sign-up, password reset, the public catalogue and Help Centre, public
 * certificate verification, the health check, and provider webhooks (verified by signature, not by session). */
const PUBLIC: RegExp[] = [
  /^GET \/health$/,
  // The website's editable words and the affiliate plan's published terms (docs/16 §2.6): public by design, plan terms only.
  /^GET \/public\/site$/,
  /^GET \/public\/affiliate-program$/,
  // The marketplace's public reads (docs/17): figures, mentors without contact details, bundles, posts, placed images.
  /^GET \/public\/(stats|mentors(\/:id)?|bundles(\/:slug)?|posts(\/:slug)?|images\/:mediaId)$/,
  // A referral link's landing data and QR (MLM-001): the code alone is the credential.
  /^GET \/public\/affiliates\/ref\/:code(\/qr\.svg)?$/,
  // The platform's logo and favicon: read by every page, changed only through /superadmin/branding.
  /^GET \/public\/branding(\/assets\/:name)?$/,
  /^POST \/public\/inquiries$/,
  // The sandbox gateway's own pages: not found unless PAYMENT_SANDBOX=on outside production (SAAS-030).
  /^(GET|POST) \/sandbox\//,
  // The registration doors (docs/16, D-PLAT-06): nothing can sign in until the emailed code is confirmed.
  /^POST \/public\/(register|instructor-applications)$/,
  /^GET \/public\/academies\/:slug$/,
  /^POST \/public\/academies\/:slug\/register$/,
  // An instructor asking to teach there (D34): created pending, signed in by nobody until the admin approves.
  /^POST \/public\/academies\/:slug\/instructor-requests$/,
  // A learner invitation and a course link: the token, or the course, names the Admin's workspace.
  /^GET \/public\/invitations\/:token$/,
  /^POST \/public\/invitations\/:token\/(register|sign-in)$/,
  /^(GET|POST) \/public\/courses\/:courseId\/enroll$/,
  // A learner's or instructor's own registration, waiting for its emailed code: the id names a row the server holds.
  /^GET \/public\/verifications\/:id$/,
  /^POST \/public\/verifications\/(resend|verify)$/,
  /^POST \/auth\/(register|login|forgot-password|reset-password|logout)$/,
  /^GET \/auth\/reset-password\/:token$/,
  /^GET \/catalog\//,
  /^GET \/help\//,
  /^GET \/certificates\/verify\/:credentialId$/,
  // The platform's gateway reporting on course orders (docs/16, D-PLAT-07): verified by HMAC under the platform's
  // webhook secret; the SaaS-era academy address is an alias for one release.
  /^POST \/webhooks\/:provider\/courses$/,
  /^POST \/webhooks\/academies\/:tenantId\/:provider\/courses$/,
  // The live room's video service (JaaS): verified by HMAC over the body, 404 until JAAS_WEBHOOK_SECRET is set.
  /^POST \/webhooks\/jaas$/,
  // A class recording a <video> opens: the path is a two-hour grant for one person and one class, 404 otherwise.
  /^GET \/live\/recording-files\/:grant$/,
  // GitHub's push webhook: verified by HMAC over the body, 404 until DEPLOY_WEBHOOK_SECRET is set.
  /^POST \/deploy\/webhook$/,
];

/** What a learner may call: their session, their learning workspace, their notifications and files, the public
 * surface, and the learner side of live classes. Everything else is staff, admin or platform. */
const LEARNER: RegExp[] = [
  ...PUBLIC,
  /^\w+ \/auth\//,
  /^\w+ \/learning\//,
  // The affiliate program's own surface (MLM-001).
  /^\w+ \/affiliate(\/|$)/,
  /^\w+ \/notifications(\/|$)/,
  /^\w+ \/media\//,
  /^GET \/live\/learner$/,
  /^POST \/live\/:id\/(register|join|recording\/link)$/,
  /^GET \/live\/:id\/recording$/,
];

/** The admin's alone among staff: an instructor is refused (docs/04 permission matrix). */
const ADMIN_ONLY: RegExp[] = [
  /^\w+ \/superadmin(\/|$)/,
  /^(POST|PATCH|DELETE) \/categories/,
  /^(POST|PATCH) \/instructors/,
  /^\w+ \/invitations(\/|$)/,
  /^POST \/certificates\/templates/,
  /^POST \/certificates\/:id\/(revoke|restore)$/,
  /^PUT \/settings\/:section$/,
  /^POST \/students\/:id\/suspend$/,
  /^GET \/reports\/instructors$/,
  /^POST \/reports\/reviews\/:id\/(hide|show)$/,
];

const key = (r: Route) => `${r.method} ${r.path}`;
const matches = (r: Route, list: RegExp[]) => list.some((re) => re.test(key(r)));

const call = (r: Route, token?: string) => {
  const req = request(app)[r.method.toLowerCase() as 'get' | 'post' | 'put' | 'patch' | 'delete'](concrete(r.path));
  if (token) req.set('Authorization', `Bearer ${token}`);
  return r.method === 'GET' || r.method === 'DELETE' ? req : req.send({});
};

let routes: Route[];
beforeAll(() => {
  routes = routesOf();
});

describe('the endpoint audit', () => {
  it('finds every route the app mounts', () => {
    expect(routes.length).toBeGreaterThan(150);
    for (const expected of [
      'POST /superadmin/admins',
      'GET /superadmin/overview',
      'POST /webhooks/:provider/courses',
      'POST /courses/x/chapters',
      'GET /learning/courses/:courseId/lessons/:lessonId/quiz-attempts',
    ]) {
      expect(routes.map(key), expected).toContain(expected);
    }
  });

  it('refuses every non-public route to an anonymous caller with 401', async () => {
    const open: string[] = [];
    for (const route of routes.filter((r) => !matches(r, PUBLIC))) {
      const res = await call(route);
      if (res.status !== 401) open.push(`${key(route)} → ${res.status}`);
    }
    expect(open).toEqual([]);
  });

  it('refuses every staff, admin and platform route to a learner, before reading the body', async () => {
    const learner = await newStudent('Audit Learner');
    const reached: string[] = [];
    for (const route of routes.filter((r) => !matches(r, LEARNER))) {
      const res = await call(route, learner.token);
      if (![401, 403, 404].includes(res.status)) reached.push(`${key(route)} → ${res.status}`);
    }
    expect(reached).toEqual([]);
  });

  it('refuses the admin’s own routes and the platform’s to an instructor', async () => {
    const instructor = await as('instructor');
    const reached: string[] = [];
    const guarded = routes.filter((r) => matches(r, ADMIN_ONLY));
    expect(guarded.length).toBeGreaterThan(30);
    for (const route of guarded) {
      const res = await call(route, instructor.token);
      if (![401, 403, 404].includes(res.status)) reached.push(`${key(route)} → ${res.status}`);
    }
    expect(reached).toEqual([]);
  });

  it('never answers a malformed query string with a server fault', async () => {
    const email = `audit-platform-${Date.now()}@example.com`;
    await provisionSuperAdmin({ email, password: 'route-audit-secret-1', name: 'Platform' });
    const platform = await as({ email, password: 'route-audit-secret-1' });
    const admin = await as('admin');
    const learner = await newStudent('Query Learner');
    // Arrays and objects where strings are expected, the shapes Express's query parser produces from `a[]=` and `a[b]=`.
    const junk = '?search[]=a&search[]=b&status[x]=1&sort[]=z&type[]=q&page[]=2&pageSize[a]=1&courseId[]=c&category[]=d&from[]=e&audience[]=f';
    const faults: string[] = [];
    for (const route of routes.filter((r) => r.method === 'GET')) {
      const token = route.path.startsWith('/superadmin')
        ? platform.token
        : matches(route, LEARNER) && !route.path.startsWith('/catalog')
          ? learner.token
          : admin.token;
      const res = await request(app)
        .get(concrete(route.path) + junk)
        .set('Authorization', `Bearer ${token}`);
      if (res.status >= 500) faults.push(`${key(route)} → ${res.status}`);
    }
    expect(faults).toEqual([]);
  });

  it('refuses every platform route to a staff admin', async () => {
    const admin = await as('admin');
    const reached: string[] = [];
    for (const route of routes.filter((r) => r.path.startsWith('/superadmin'))) {
      const res = await call(route, admin.token);
      if (res.status !== 403) reached.push(`${key(route)} → ${res.status}`);
    }
    expect(reached).toEqual([]);
  });
});
