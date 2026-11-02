import { defaultMlmPlanTerms } from '@syniastrolms/domain';
import { beforeAll, describe, expect, it } from 'vitest';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { FIRST_TENANT_ID } from '../lib/tenancy.js';
import { db, platformDb } from '../test/db.js';
import { anon, as, newStudent, unique, type Client } from '../test/helpers.js';

/* MLM-000: the Super Admin's plan endpoints. Who may call them is also walked by routeAudit.test.ts (every
 * /superadmin route refuses anonymous callers, learners, instructors and academy admins); here they are driven for
 * what they do. */
const BASE = '/superadmin/affiliates/plan';

let platform: Client;
let admin: Client;
let paidCourseId: string;

beforeAll(async () => {
  const email = `mlm-routes-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: 'mlm-routes-pw-1', name: 'Platform' });
  platform = await as({ email, password: 'mlm-routes-pw-1' });
  admin = await as('admin');
  const paid = await db.course.findFirstOrThrow({ where: { pricing: 'paid', status: 'published' }, select: { id: true } });
  paidCourseId = paid.id;
  // Start this suite from no active version, whatever the service tests left.
  const active = await platformDb.mlmPlanVersion.findFirst({ where: { status: 'active' } });
  if (active) await platformDb.mlmPlanVersion.update({ where: { id: active.id }, data: { status: 'retired', retiredAt: new Date() } });
});

describe('the plan endpoints', () => {
  it('refuse everyone but the platform', async () => {
    expect((await anon().get(BASE)).status).toBe(401);
    expect((await admin.get(BASE)).status).toBe(403);
    const learner = await newStudent('Plan Learner');
    expect((await learner.get(`${BASE}/versions`)).status).toBe(403);
    expect((await admin.post(`${BASE}/versions`, {})).status).toBe(403);
  });

  it('create a draft from the PDF, show it in the overview, and list the program LMS’s courses', async () => {
    const created = await platform.post(`${BASE}/versions`, {});
    expect(created.status, JSON.stringify(created.body)).toBe(201);
    expect(created.body).toMatchObject({ status: 'draft', programTenantId: FIRST_TENANT_ID });
    expect(created.body.tiers).toHaveLength(18);

    const overview = await platform.get(BASE);
    expect(overview.status).toBe(200);
    expect(overview.body.active).toBeNull();
    expect(overview.body.versions.some((v: { id: string }) => v.id === created.body.id)).toBe(true);

    const courses = await platform.get(`${BASE}/courses?tenantId=${FIRST_TENANT_ID}`);
    expect(courses.status).toBe(200);
    expect(courses.body.rows.some((c: { id: string; priceAmount: number | null }) => c.id === paidCourseId && c.priceAmount !== null)).toBe(true);
    expect((await platform.get(`${BASE}/courses`)).status).toBe(400);
  });

  it('validate a body: a bad rate is 400 with the field named; a malformed body is 400', async () => {
    const bad = { ...defaultMlmPlanTerms(FIRST_TENANT_ID), matchingRateBps: 9000 };
    const res = await platform.post(`${BASE}/versions`, bad);
    expect(res.status).toBe(400);
    expect(res.body.issues).toEqual(expect.arrayContaining([expect.objectContaining({ field: 'matchingRateBps' })]));
    expect((await platform.post(`${BASE}/versions`, { tiers: 'nope' })).status).toBe(400);
    expect((await platform.put(`${BASE}/versions/no-such-version`, defaultMlmPlanTerms(FIRST_TENANT_ID))).status).toBe(404);
  });

  it('edit a draft, set its courses, activate it, change the course list on the active version, and retire it', async () => {
    const created = await platform.post(`${BASE}/versions`, {});
    const id: string = created.body.id;
    const edited = await platform.put(`${BASE}/versions/${id}`, { ...defaultMlmPlanTerms(FIRST_TENANT_ID), note: 'edited by the route test' });
    expect(edited.status, JSON.stringify(edited.body)).toBe(200);
    expect(edited.body.note).toBe('edited by the route test');

    expect((await platform.post(`${BASE}/versions/${id}/activate`)).status).toBe(400); // no eligible course yet
    const withCourse = await platform.put(`${BASE}/versions/${id}/courses`, { eligibleCourseIds: [paidCourseId] });
    expect(withCourse.status).toBe(200);
    expect(withCourse.body.eligibleCourseIds).toEqual([paidCourseId]);

    const activated = await platform.post(`${BASE}/versions/${id}/activate`);
    expect(activated.status, JSON.stringify(activated.body)).toBe(200);
    expect(activated.body.status).toBe('active');
    expect((await platform.get(BASE)).body.active.id).toBe(id);
    expect((await platform.get(`${BASE}/versions/${id}`)).body.status).toBe('active');

    expect((await platform.put(`${BASE}/versions/${id}`, defaultMlmPlanTerms(FIRST_TENANT_ID))).status).toBe(409);
    expect((await platform.put(`${BASE}/versions/${id}/courses`, { eligibleCourseIds: [] })).status).toBe(400);
    expect((await platform.delete(`${BASE}/versions/${id}`)).status).toBe(409);

    const retired = await platform.post(`${BASE}/versions/${id}/retire`);
    expect(retired.status).toBe(200);
    expect(retired.body.status).toBe('retired');
    expect((await platform.get(BASE)).body.active).toBeNull();
    expect((await platform.post(`${BASE}/versions/${id}/retire`)).status).toBe(409);
  });

  it('delete an unused draft', async () => {
    const created = await platform.post(`${BASE}/versions`, {});
    expect((await platform.delete(`${BASE}/versions/${created.body.id}`)).status).toBe(204);
    expect((await platform.get(`${BASE}/versions/${created.body.id}`)).status).toBe(404);
  });
});
