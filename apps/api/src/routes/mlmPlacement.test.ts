import { defaultMlmPlanTerms } from '@syniastrolms/domain';
import { beforeAll, describe, expect, it } from 'vitest';
import { activateMlmPlanVersion, createMlmPlanVersion } from '../lib/mlm/plan.js';
import { placePendingAffiliates } from '../lib/mlm/placement.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { FIRST_TENANT_ID, runAsPlatform, runInTenant } from '../lib/tenancy.js';
import { db, platformDb } from '../test/db.js';
import { as, newStudent, unique, type Client } from '../test/helpers.js';

/* MLM-002: binary placement. A sponsor at the root of a tree; referrals placed on the sponsor's preferred leg and,
 * when it is taken, deeper by the plan's spillover rule; the Super Admin's member directory, network reads, manual
 * moves with their refusals, sponsor changes and status changes. */

type Learner = Client & { email: string; userId: string; studentId: string };

let platform: Client;
let root: Learner;
let rootId: string;
let rootCode: string;

const enrol = async (who: Learner, referralCode?: string, preferredLeg: 'A' | 'B' = 'A') => {
  const res = await who.post('/affiliate/enrol', { referralCode, preferredLeg });
  expect(res.status, JSON.stringify(res.body)).toBe(201);
  return res.body as { id: string; code: string; placement: { parentCode: string; leg: string; depth: number } | null };
};

beforeAll(async () => {
  const email = `mlm-place-${unique()}@example.com`;
  const owner = await provisionSuperAdmin({ email, password: 'mlm-place-pw-1', name: 'Platform' });
  platform = await as({ email, password: 'mlm-place-pw-1' });
  const actor = { auth: { sub: owner.user.id, role: 'superadmin' as const } };
  const paid = await db.course.findFirstOrThrow({ where: { pricing: 'paid', status: 'published' }, select: { id: true } });
  await runAsPlatform('placement tests need an active plan (extreme-outer spillover)', async () => {
    const active = await platformDb.mlmPlanVersion.findFirst({ where: { status: 'active' } });
    if (active) return;
    const draft = await createMlmPlanVersion(actor, { ...defaultMlmPlanTerms(FIRST_TENANT_ID), eligibleCourseIds: [paid.id] });
    await activateMlmPlanVersion(actor, draft.id);
  });
  root = await newStudent('Root Sponsor');
  const me = await enrol(root, undefined, 'A');
  rootId = me.id;
  rootCode = me.code;
});

describe('placement by rule', () => {
  it('makes a sponsorless opt-in a root, and places referrals on the sponsor’s leg, spilling over outward', async () => {
    expect((await root.get('/affiliate')).body.affiliate.placement).toBeNull();
    const rahul = await enrol(await newStudent('Rahul'), rootCode, 'A');
    expect(rahul.placement).toEqual({ parentCode: rootCode, leg: 'A', depth: 1 });
    // The root's A position is taken: the next A referral spills over to Rahul's A (extreme-outer).
    const rohan = await enrol(await newStudent('Rohan'), rootCode, 'A');
    expect(rohan.placement).toEqual({ parentCode: rahul.code, leg: 'A', depth: 2 });
    // The root switches its preferred leg to B: the next referral goes to the root's B directly.
    expect((await root.patch('/affiliate/preferred-leg', { leg: 'B' })).status).toBe(200);
    const rohit = await enrol(await newStudent('Rohit'), rootCode, 'B');
    expect(rohit.placement).toEqual({ parentCode: rootCode, leg: 'B', depth: 1 });
    await root.patch('/affiliate/preferred-leg', { leg: 'A' });

    const rows = (
      await db.affiliate.findMany({ where: { id: { in: [rahul.id, rohan.id, rohit.id] } }, select: { id: true, pathIdsJson: true, depth: true } })
    ).sort((a, b) => a.depth - b.depth);
    expect(JSON.parse(rows[2].pathIdsJson)).toEqual([rootId, rahul.id]);
    const history = await db.mlmPlacementHistory.findMany({ where: { affiliateId: { in: [rohan.id, rahul.id] } }, orderBy: { createdAt: 'asc' } });
    expect(history.map((h) => h.reason)).toEqual(['sponsor-direct', 'spillover']);
  });

  it('reads the tree, the team with counts and legs, and direct referrals', async () => {
    const tree = await root.get('/affiliate/tree?depth=2');
    expect(tree.status).toBe(200);
    expect(tree.body.children.A.name).toBe('Rahul');
    expect(tree.body.children.A.children.A.name).toBe('Rohan');
    expect(tree.body.children.B.name).toBe('Rohit');
    expect(tree.body.children.A.children.A.children).toBeNull(); // beyond the depth asked for
    expect(tree.body.directReferrals).toBe(3);

    const teamPage = await root.get('/affiliate/team');
    expect(teamPage.status).toBe(200);
    expect(teamPage.body.summary).toMatchObject({ total: 3, directReferrals: 3, byLeg: { A: 2, B: 1 }, pending: 3, active: 0 });
    expect(teamPage.body.rows.find((r: { name: string }) => r.name === 'Rohan')).toMatchObject({ leg: 'A', depth: 2 });
    expect((await root.get('/affiliate/team?leg=B')).body.rows.map((r: { name: string }) => r.name)).toEqual(['Rohit']);

    const referrals = await root.get('/affiliate/referrals');
    expect(referrals.body.rows).toHaveLength(3);
    // A downline member's subtree can be read; a stranger's cannot.
    const rahulId = referrals.body.rows.find((r: { name: string }) => r.name === 'Rahul').id;
    expect((await root.get(`/affiliate/tree?root=${rahulId}`)).body.name).toBe('Rahul');
    const stranger = await enrol(await newStudent('Stranger'));
    expect((await root.get(`/affiliate/tree?root=${stranger.id}`)).status).toBe(404);
  });

  it('places anyone left unplaced on the next job run', async () => {
    const late = await newStudent('Late Placement');
    // The root sends this one down its B leg (a referral's own preferred leg is where *their* referrals go, not where they are placed).
    await root.patch('/affiliate/preferred-leg', { leg: 'B' });
    const me = await enrol(late, rootCode, 'B');
    expect(me.placement?.parentCode).not.toBe(rootCode); // the root's B is Rohit: spilled over to Rohit's B
    // Undo the placement to simulate a registration the placement could not finish.
    await db.affiliate.update({ where: { id: me.id }, data: { placementParentId: null, placementLeg: null, pathIdsJson: '[]', depth: 0 } });
    expect((await late.get('/affiliate')).body.affiliate.placement).toBeNull();
    const placed = await runInTenant(FIRST_TENANT_ID, () => placePendingAffiliates());
    expect(placed).toBeGreaterThanOrEqual(1);
    expect((await late.get('/affiliate')).body.affiliate.placement).not.toBeNull();
    await root.patch('/affiliate/preferred-leg', { leg: 'A' });
  });
});

describe('the Super Admin’s network tools', () => {
  it('lists members with counts, shows a member, and exports the network', async () => {
    const list = await platform.get(`/superadmin/affiliates/members?tenantId=${FIRST_TENANT_ID}&search=${rootCode}`);
    expect(list.status).toBe(200);
    expect(list.body.rows[0]).toMatchObject({ code: rootCode, directReferrals: 4, status: 'pending' });
    expect(list.body.rows[0].teamSize).toBeGreaterThanOrEqual(4);
    const detail = await platform.get(`/superadmin/affiliates/members/${rootId}`);
    expect(detail.body).toMatchObject({ code: rootCode, placement: null, sponsor: null });
    expect((await platform.get(`/superadmin/affiliates/members/${rootId}/tree?depth=1`)).body.children.A.name).toBe('Rahul');
    const sponsors = await platform.get(`/superadmin/affiliates/sponsors?search=${rootCode}`);
    expect(sponsors.body.rows[0]).toMatchObject({ code: rootCode, directReferrals: 4 });
    const csv = await platform.get(`/superadmin/affiliates/network/export.csv?root=${rootId}`);
    expect(csv.status).toBe(200);
    expect(csv.headers['content-type']).toContain('text/csv');
    expect(String(csv.text || csv.body)).toContain('Rahul');
    const placements = await platform.get(`/superadmin/affiliates/placements?affiliateId=${rootId}`);
    expect(placements.body.rows[0]).toMatchObject({ reason: 'root', actor: { type: 'system' } });
  });

  it('refuses a cycle, a filled position and a move with a team, and moves a leaf with a reason', async () => {
    const referrals = (await root.get('/affiliate/referrals')).body.rows as { id: string; name: string }[];
    const rahul = referrals.find((r) => r.name === 'Rahul')!;
    const rohit = referrals.find((r) => r.name === 'Rohit')!;
    const rohan = (await root.get('/affiliate/team?search=Rohan')).body.rows[0] as { id: string };
    const move = (who: string, body: Record<string, unknown>) =>
      platform.post(`/superadmin/affiliates/members/${who}/placement`, { reason: 'test move', ...body });

    expect((await move(rootId, { parentId: rohan.id, leg: 'B' })).body.code).toBe('PLACEMENT_CYCLE'); // under its own descendant
    expect((await move(rahul.id, { parentId: rahul.id, leg: 'B' })).body.code).toBe('PLACEMENT_CYCLE'); // under itself
    expect((await move(rohit.id, { parentId: rootId, leg: 'A' })).body.code).toBe('POSITION_TAKEN'); // Rahul is there
    expect((await move(rahul.id, { parentId: rohit.id, leg: 'A' })).body.code).toBe('PLACEMENT_INVALID'); // Rahul has Rohan under him
    expect((await move(rahul.id, { parentId: 'no-such', leg: 'A' })).status).toBe(404);

    // Rohan (a leaf under Rahul A) moves to Rohit's A.
    const moved = await move(rohan.id, { parentId: rohit.id, leg: 'A' });
    expect(moved.status, JSON.stringify(moved.body)).toBe(200);
    expect(moved.body.placement).toMatchObject({
      parentCode: (await platform.get(`/superadmin/affiliates/members/${rohit.id}`)).body.code,
      leg: 'A',
      depth: 2,
    });
    const row = await db.affiliate.findUniqueOrThrow({ where: { id: rohan.id } });
    expect(JSON.parse(row.pathIdsJson)).toEqual([rootId, rohit.id]);
    expect((await platform.get(`/superadmin/affiliates/placements?affiliateId=${rohan.id}`)).body.rows[0]).toMatchObject({
      reason: 'manual',
      actor: { type: 'user' },
      note: 'test move',
    });
    expect((await root.get('/affiliate/team')).body.summary.byLeg).toEqual({ A: 1, B: 3 });

    // Rahul, now a leaf, moves with `moveSubtree` not needed; the whole-team flag is honoured when there is one.
    const back = await move(rohan.id, { parentId: rahul.id, leg: 'A' });
    expect(back.status).toBe(200);
    const deep = await enrol(await newStudent('Deep'), rootCode, 'A'); // spills to Rohan's A
    expect(deep.placement?.depth).toBe(3);
    const subtreeMove = await move(rahul.id, { parentId: rohit.id, leg: 'A', moveSubtree: true });
    expect(subtreeMove.status, JSON.stringify(subtreeMove.body)).toBe(200);
    const deepRow = await db.affiliate.findUniqueOrThrow({ where: { id: deep.id } });
    expect(JSON.parse(deepRow.pathIdsJson)).toEqual([rootId, rohit.id, rahul.id, rohan.id]);
    expect(deepRow.depth).toBe(4);
  });

  it('changes a sponsor and an affiliate’s status, within the rules', async () => {
    const referrals = (await root.get('/affiliate/referrals')).body.rows as { id: string; name: string }[];
    const rohit = referrals.find((r) => r.name === 'Rohit')!;
    const rahul = referrals.find((r) => r.name === 'Rahul')!;
    const changed = await platform.patch(`/superadmin/affiliates/members/${rahul.id}/sponsor`, { sponsorId: rohit.id, reason: 'referred by Rohit in fact' });
    expect(changed.status, JSON.stringify(changed.body)).toBe(200);
    expect(changed.body.sponsor.id).toBe(rohit.id);
    expect((await platform.patch(`/superadmin/affiliates/members/${rootId}/sponsor`, { sponsorId: rahul.id, reason: 'cycle' })).body.code).toBe(
      'PLACEMENT_CYCLE',
    );

    expect((await platform.patch(`/superadmin/affiliates/members/${rahul.id}`, { status: 'active' })).status).toBe(409); // activation is the purchase's
    const suspended = await platform.patch(`/superadmin/affiliates/members/${rahul.id}`, { status: 'suspended', note: 'review' });
    expect(suspended.body.status).toBe('suspended');
    const terminated = await platform.patch(`/superadmin/affiliates/members/${rahul.id}`, { status: 'terminated', note: 'closed' });
    expect(terminated.body.status).toBe('terminated');
    expect((await platform.patch(`/superadmin/affiliates/members/${rahul.id}`, { status: 'suspended' })).status).toBe(409);
    // A terminated sponsor's code no longer opens a referral.
    expect((await platform.get(`/public/affiliates/ref/${terminated.body.code}`)).status).toBe(404);
  });
});
