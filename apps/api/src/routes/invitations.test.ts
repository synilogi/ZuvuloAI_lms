import { beforeAll, describe, expect, it } from 'vitest';

import { hashToken } from '../lib/passwordReset.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { ACADEMY, platformDb } from '../test/db.js';
import { anon, as, unique, type Client } from '../test/helpers.js';

/* Learner invitations (`/invite/<token>`) and course links (`/courses/<id>/enroll`): the link alone names the role and
 * the workspace — never the request — and an invitation expires and works once. Since the platform conversion
 * (docs/16) there is one workspace; a staff admin issues invitations into it. */

const PASSWORD = 'invitation-test-password';
let platform: Client;

/** A staff admin of the workspace (docs/16, D-PLAT-03). */
async function newAdmin() {
  const email = `inv-admin-${unique()}@example.com`;
  const res = await platform.post('/superadmin/admins', { name: 'Invite Admin', email, password: PASSWORD });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return { tenantId: ACADEMY, slug: 'default', admin: await as({ email, password: PASSWORD }) };
}

const tokenOf = (url: string) => url.match(/\/invite\/([a-f0-9]{64})$/)![1];
const learner = () => ({ name: 'Invited Learner', email: `invited-${unique()}@example.com`, password: 'learner-password-1' });

beforeAll(async () => {
  const email = `inv-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Invite Platform' });
  platform = await as({ email, password: PASSWORD });
});

describe('an Admin invites a learner', () => {
  it('joins the learner to the inviting Admin’s workspace as a learner, whatever the request claims', async () => {
    const a = await newAdmin();
    const made = await a.admin.post('/invitations', {});
    expect(made.status, JSON.stringify(made.body)).toBe(201);
    const token = tokenOf(made.body.url);
    // Only the hash is stored.
    expect(await platformDb.invitation.findUnique({ where: { tokenHash: token } })).toBeNull();
    expect(await platformDb.invitation.findUnique({ where: { tokenHash: hashToken(token) } })).toMatchObject({ tenantId: a.tenantId, role: 'student' });

    const shown = await anon().get(`/public/invitations/${token}`);
    expect(shown.status).toBe(200);
    expect(shown.body).toMatchObject({ lms: { slug: a.slug }, role: 'student', open: true });

    const who = learner();
    const res = await anon().post(`/public/invitations/${token}/register`, { ...who, tenantId: ACADEMY, role: 'admin', workspace: 'default' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body.user.role).toBe('student');
    const user = await platformDb.user.findUniqueOrThrow({ where: { email: who.email } });
    expect(user).toMatchObject({ tenantId: a.tenantId, role: 'student' });

    // The new learner is in A's roster, and reads only A's data.
    const rows = (await a.admin.get('/students')).body.rows.map((r: { student: { email: string } }) => r.student.email);
    expect(rows).toContain(who.email);
    const signedIn = await as({ email: who.email, password: who.password });
    expect((await signedIn.get('/auth/me')).body.user.email).toBe(who.email);
    expect(await platformDb.auditLog.findFirst({ where: { action: 'invitation.created', targetId: made.body.invitation.id } })).toBeTruthy();
  });

  it('works once: a second accept, of either kind, is refused', async () => {
    const a = await newAdmin();
    const token = tokenOf((await a.admin.post('/invitations', {})).body.url);
    const first = learner();
    expect((await anon().post(`/public/invitations/${token}/register`, first)).status).toBe(201);
    const again = await anon().post(`/public/invitations/${token}/register`, learner());
    expect(again.status).toBe(404);
    expect(again.body.code).toBe('INVITE_INVALID');
    expect((await anon().post(`/public/invitations/${token}/sign-in`, { email: first.email, password: first.password })).status).toBe(404);
    expect((await anon().get(`/public/invitations/${token}`)).status).toBe(404);
  });

  it('holds when two people accept the same link at the same moment', async () => {
    const a = await newAdmin();
    const token = tokenOf((await a.admin.post('/invitations', {})).body.url);
    const results = await Promise.all([learner(), learner(), learner()].map((who) => anon().post(`/public/invitations/${token}/register`, who)));
    expect(results.filter((r) => r.status === 201)).toHaveLength(1);
  });

  it('refuses an expired, withdrawn, malformed or unknown link with one answer', async () => {
    const a = await newAdmin();
    const expired = await a.admin.post('/invitations', {});
    await platformDb.invitation.update({ where: { id: expired.body.invitation.id }, data: { expiresAt: new Date(Date.now() - 1000) } });
    const withdrawn = await a.admin.post('/invitations', {});
    expect((await a.admin.post(`/invitations/${withdrawn.body.invitation.id}/revoke`)).body.status).toBe('revoked');

    for (const token of [tokenOf(expired.body.url), tokenOf(withdrawn.body.url), 'not-a-token', 'a'.repeat(64)]) {
      const shown = await anon().get(`/public/invitations/${token}`);
      expect(shown.status, token).toBe(404);
      expect(shown.body.code).toBe('INVITE_INVALID');
      expect((await anon().post(`/public/invitations/${token}/register`, learner())).status, token).toBe(404);
    }
    const listed = (await a.admin.get('/invitations')).body.rows.map((r: { status: string }) => r.status);
    expect(listed).toEqual(expect.arrayContaining(['expired', 'revoked']));
  });

  it('keeps an invitation for its address, and lets nothing created fail use it up', async () => {
    const a = await newAdmin();
    const email = `named-${unique()}@example.com`;
    const made = await a.admin.post('/invitations', { email });
    expect(made.status).toBe(201);
    expect(await platformDb.emailOutbox.findFirst({ where: { toEmail: email, templateKey: 'learner-invitation' } })).toBeTruthy();
    const token = tokenOf(made.body.url);
    expect((await anon().post(`/public/invitations/${token}/register`, learner())).status).toBe(403);
    expect((await anon().post(`/public/invitations/${token}/register`, { ...learner(), email })).status).toBe(201);

    // A refused attempt (an address that already has an account) leaves an open link usable.
    const open = tokenOf((await a.admin.post('/invitations', {})).body.url);
    expect((await anon().post(`/public/invitations/${open}/register`, { ...learner(), email: 'ananya@syniastrolms.test' })).status).toBe(409);
    expect((await anon().post(`/public/invitations/${open}/register`, learner())).status).toBe(201);
  });

  it('lets a learner accept by signing in, and refuses a staff account', async () => {
    const a = await newAdmin();
    const own = learner();
    expect((await anon().post(`/public/invitations/${tokenOf((await a.admin.post('/invitations', {})).body.url)}/register`, own)).status).toBe(201);

    const token = tokenOf((await a.admin.post('/invitations', {})).body.url);
    // Meenakshi teaches: a staff account cannot take a learner's invitation.
    expect((await anon().post(`/public/invitations/${token}/sign-in`, { email: 'meenakshi@syniastrolms.test', password: 'syniastrolms123' })).status).toBe(409);
    expect((await anon().post(`/public/invitations/${token}/sign-in`, { email: own.email, password: 'wrong-password' })).status).toBe(401);
    const ok = await anon().post(`/public/invitations/${token}/sign-in`, { email: own.email, password: own.password });
    expect(ok.status, JSON.stringify(ok.body)).toBe(200);
    expect(ok.body.token).toBeTruthy();
    // Ananya's account stays where it is.
    expect((await platformDb.user.findUniqueOrThrow({ where: { email: 'ananya@syniastrolms.test' } })).tenantId).toBe(ACADEMY);
  });

  it('is for staff admins: every admin sees the workspace’s invitations, and nobody else issues one', async () => {
    const a = await newAdmin();
    const b = await newAdmin();
    const mine = await a.admin.post('/invitations', {});
    expect((await b.admin.get('/invitations')).body.rows.map((r: { id: string }) => r.id)).toContain(mine.body.invitation.id);
    expect((await b.admin.post(`/invitations/${mine.body.invitation.id}/revoke`)).body.status).toBe('revoked');
    expect((await (await as('instructor')).post('/invitations', {})).status).toBe(403);
    expect((await (await as('student')).get('/invitations')).status).toBe(403);
    expect((await anon().post('/invitations', {})).status).toBe(401);
  });
});

describe('a course link', () => {
  async function seededCourse() {
    return platformDb.course.findFirstOrThrow({ where: { tenantId: ACADEMY, status: 'published', pricing: 'free', visibility: { not: 'private' } } });
  }

  it('names the course’s own LMS, joins a new learner to it and enrols them under its open policy', async () => {
    const course = await seededCourse();
    const shown = await anon().get(`/public/courses/${course.id}/enroll`);
    expect(shown.status).toBe(200);
    expect(shown.body).toMatchObject({ course: { id: course.id, title: course.title }, open: true });

    const who = learner();
    const res = await anon().post(`/public/courses/${course.id}/enroll`, { ...who, tenantId: 'someone-else', workspace: 'other' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body.enrolled).toBe(true);
    const user = await platformDb.user.findUniqueOrThrow({ where: { email: who.email }, include: { student: true } });
    expect(user.tenantId).toBe(ACADEMY);
    expect(await platformDb.enrollment.findFirst({ where: { studentId: user.student!.id, courseId: course.id } })).toBeTruthy();
  });

  it('is not found for a course that is unknown, malformed or a draft', async () => {
    const draft = await platformDb.course.findFirst({ where: { status: { not: 'published' } } });
    for (const id of ['nope', 'zzzzzzzzzzzzzzzzzzzzzzzz', ...(draft ? [draft.id] : [])]) {
      expect((await anon().get(`/public/courses/${id}/enroll`)).status, id).toBe(404);
      expect((await anon().post(`/public/courses/${id}/enroll`, learner())).status, id).toBe(404);
    }
  });
});
