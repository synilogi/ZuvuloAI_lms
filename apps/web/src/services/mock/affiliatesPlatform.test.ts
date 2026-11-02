import { defaultMlmPlanTerms } from '@syniastrolms/domain';
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { resetTree } from './affiliateTree';
import { affiliatesPlatformService as svc, resetAffiliatePlanMock } from './affiliatesPlatform';
import { simulation } from './simulation';

describe('the demo affiliate plan', () => {
  beforeAll(() => {
    // `respond` schedules on the browser's window; here the global is the window, and the latency is nil.
    vi.stubGlobal('window', globalThis);
  });
  afterAll(() => vi.unstubAllGlobals());
  beforeEach(() => {
    resetAffiliatePlanMock();
    resetTree();
    simulation.latencyMs = 0;
  });

  it('starts with one draft of the PDF plan and no active version', async () => {
    const overview = await svc.plan();
    expect(overview.active).toBeNull();
    expect(overview.versions).toHaveLength(1);
    expect(overview.versions[0]).toMatchObject({ version: 1, status: 'draft', tierCount: 18, eligibleCourseCount: 0 });
  });

  it('activates a draft only with an eligible course, retiring the version before', async () => {
    const [draft] = await svc.listPlanVersions();
    await expect(svc.activatePlanVersion(draft.id)).rejects.toMatchObject({ code: 'conflict' });
    const courses = await svc.programCourses(draft.programTenantId);
    const paid = courses.find((c) => c.priceAmount !== null);
    expect(paid).toBeDefined();
    await svc.setEligibleCourses(draft.id, [paid!.id]);
    const active = await svc.activatePlanVersion(draft.id);
    expect(active.status).toBe('active');

    const next = await svc.createPlanVersion({});
    expect(next).toMatchObject({ version: 2, status: 'draft', eligibleCourseIds: [paid!.id] });
    await svc.activatePlanVersion(next.id);
    const overview = await svc.plan();
    expect(overview.active?.id).toBe(next.id);
    expect(overview.versions.find((v) => v.id === draft.id)?.status).toBe('retired');
    await expect(svc.updatePlanVersion(next.id, defaultMlmPlanTerms(draft.programTenantId))).rejects.toMatchObject({ code: 'conflict' });
    await expect(svc.deletePlanDraft(next.id)).rejects.toMatchObject({ code: 'conflict' });
  });

  it('refuses invalid terms with the field named, and deletes only drafts', async () => {
    const [draft] = await svc.listPlanVersions();
    const err = await svc.updatePlanVersion(draft.id, { ...defaultMlmPlanTerms(draft.programTenantId), matchingRateBps: 9000 }).catch((e: unknown) => e);
    expect(err).toMatchObject({ code: 'conflict', issues: [expect.objectContaining({ field: 'matchingRateBps' })] });
    const copy = await svc.createPlanVersion({ fromVersionId: draft.id });
    await svc.deletePlanDraft(copy.id);
    await expect(svc.getPlanVersion(copy.id)).rejects.toMatchObject({ code: 'not-found' });
    expect((await svc.listPlanVersions()).map((v) => v.id)).toEqual([draft.id]);
  });
});

describe('the demo genealogy', () => {
  beforeAll(() => vi.stubGlobal('window', globalThis));
  afterAll(() => vi.unstubAllGlobals());
  beforeEach(() => {
    resetTree();
    simulation.latencyMs = 0;
  });

  it('lists members with counts, and reads a member’s tree, ancestors and team', async () => {
    const members = await svc.listMembers();
    expect(members.counts.all).toBe(9);
    expect(members.rows.length).toBe(9);
    const priya = members.rows.find((m) => m.name === 'Priya Sharma')!;
    expect(priya).toMatchObject({ placement: null, sponsor: null, directReferrals: 4 });
    expect(priya.teamSize).toBe(8);
    const tree = await svc.memberTree(priya.id, 2);
    expect(tree.children?.A?.name).toBe('Rahul Verma');
    expect(tree.children?.B?.name).toBe('Rohit Mehta');
    const rahul = tree.children!.A!;
    expect(await svc.memberAncestors(rahul.id)).toEqual([expect.objectContaining({ name: 'Priya Sharma' })]);
    const team = await svc.memberTeam(priya.id, { leg: 'A' });
    expect(team.summary.byLeg.A + team.summary.byLeg.B).toBe(8);
    expect(team.rows.every((r) => r.leg === 'A')).toBe(true);
    expect((await svc.sponsors()).rows[0]).toMatchObject({ name: 'Priya Sharma', directReferrals: 4 });
    expect((await svc.placements()).rows.length).toBe(9);
    expect(await svc.networkCsv(priya.id)).toContain('Rahul Verma');
  });

  it('moves a node under the rules, and refuses a cycle, a filled position and a team move without consent', async () => {
    const members = (await svc.listMembers()).rows;
    const priya = members.find((m) => m.name === 'Priya Sharma')!;
    const rahul = members.find((m) => m.name === 'Rahul Verma')!;
    const rohit = members.find((m) => m.name === 'Rohit Mehta')!;
    const meera = members.find((m) => m.name === 'Meera Joshi')!;
    await expect(svc.placeMember(priya.id, { parentId: rahul.id, leg: 'B', reason: 'cycle' })).rejects.toMatchObject({ reason: 'PLACEMENT_CYCLE' });
    await expect(svc.placeMember(rohit.id, { parentId: priya.id, leg: 'A', reason: 'taken' })).rejects.toMatchObject({ reason: 'POSITION_TAKEN' });
    await expect(svc.placeMember(rahul.id, { parentId: rohit.id, leg: 'B', reason: 'team' })).rejects.toMatchObject({ reason: 'PLACEMENT_INVALID' });
    const moved = await svc.placeMember(meera.id, { parentId: rohit.id, leg: 'B', reason: 'closer to her coach' });
    expect(moved.placement).toMatchObject({ parentCode: rohit.code, leg: 'B' });
    expect((await svc.placements()).rows[0]).toMatchObject({ reason: 'manual', note: 'closer to her coach', actor: { type: 'user' } });
    const anjali = members.find((m) => m.name === 'Anjali Rao')!;
    const withTeam = await svc.placeMember(rahul.id, { parentId: anjali.id, leg: 'B', reason: 'whole branch', moveSubtree: true });
    expect(withTeam.placement?.parentCode).toBe(anjali.code);
    expect((await svc.memberAncestors(members.find((m) => m.name === 'Deepak Nair')!.id)).map((a) => a.name)).toEqual([
      'Priya Sharma',
      'Rohit Mehta',
      'Anjali Rao',
      'Rahul Verma',
      'Seema Iyer',
    ]);
  });

  it('changes sponsors and statuses within the rules', async () => {
    const members = (await svc.listMembers()).rows;
    const priya = members.find((m) => m.name === 'Priya Sharma')!;
    const seema = members.find((m) => m.name === 'Seema Iyer')!;
    const kiran = members.find((m) => m.name === 'Kiran Patel')!;
    expect((await svc.changeSponsor(kiran.id, priya.id, 'referred by Priya')).sponsor?.id).toBe(priya.id);
    await expect(svc.changeSponsor(priya.id, seema.id, 'cycle')).rejects.toMatchObject({ reason: 'PLACEMENT_CYCLE' });
    await expect(svc.setMemberStatus(kiran.id, 'active')).rejects.toMatchObject({ code: 'conflict' });
    expect((await svc.setMemberStatus(seema.id, 'suspended')).status).toBe('suspended');
    expect((await svc.setMemberStatus(seema.id, 'terminated')).status).toBe('terminated');
    await expect(svc.setMemberStatus(seema.id, 'active')).rejects.toMatchObject({ code: 'conflict' });
  });
});

describe('the demo sales', () => {
  beforeAll(() => vi.stubGlobal('window', globalThis));
  afterAll(() => vi.unstubAllGlobals());
  beforeEach(() => {
    resetTree();
    resetAffiliatePlanMock();
    simulation.latencyMs = 0;
  });

  it('derives an order per activated member, credits every leg above the buyer, and adds up the pools', async () => {
    const orders = await svc.orders();
    // Six active members, one refunded (the suspended one), one buyer outside the program.
    expect(orders.counts).toEqual({ all: 8, eligible: 7, pending: 0, reversed: 1 });
    const outsider = orders.rows.find((o) => o.buyer.affiliateCode === null)!;
    expect(outsider).toMatchObject({ creditedAncestors: 0, status: 'eligible' });
    // Deepak sits on Seema's A, Seema on Rahul's A, Rahul on Priya's A: his sale credits three A legs.
    const deepak = orders.rows.find((o) => o.buyer.name === 'Deepak Nair')!;
    expect(deepak.creditedAncestors).toBe(3);
    const ledger = await svc.cvLedger({ affiliateId: 'aff-1' }); // Priya, the root
    expect(ledger.rows.every((r) => r.affiliate.name === 'Priya Sharma')).toBe(true);
    expect(ledger.rows.some((r) => r.leg === 'A') && ledger.rows.some((r) => r.leg === 'B')).toBe(true);
    const pools = await svc.carryForward({ search: 'Priya' });
    expect(pools.rows[0].affiliate.name).toBe('Priya Sharma');
    expect(pools.rows[0].lifetimeA).toBeGreaterThan(pools.rows[0].lifetimeB);
    expect(pools.rows[0].unmatchedA).toBe(pools.rows[0].lifetimeA); // nothing matched yet in the demo
    expect(await svc.cvCsv({ leg: 'B' })).toContain('Priya Sharma');
    expect((await svc.cvLedger({ kind: 'reversal' })).rows.every((r) => r.amount < 0)).toBe(true);
  });

  it('reverses an order once, negating its credits', async () => {
    const before = (await svc.carryForward({ search: 'Priya' })).rows[0];
    const deepak = (await svc.orders({ search: 'Deepak' })).rows[0];
    const reversed = await svc.reverseOrder(deepak.id, 'refund', 'refunded in the dashboard');
    expect(reversed).toMatchObject({ status: 'reversed', reversalReason: 'refund' });
    const after = (await svc.carryForward({ search: 'Priya' })).rows[0];
    expect(after.unmatchedA).toBe(before.unmatchedA - deepak.cv);
    await expect(svc.reverseOrder(deepak.id, 'manual')).rejects.toMatchObject({ code: 'conflict' });
    expect((await svc.getOrder(deepak.id)).status).toBe('reversed');
    await expect(svc.getOrder('nope')).rejects.toMatchObject({ code: 'not-found' });
  });

  it('edits the active version’s eligible courses through the products view, never to none', async () => {
    expect((await svc.products()).active).toBeNull();
    const draft = (await svc.listPlanVersions())[0];
    const paid = (await svc.programCourses('acad-demo')).filter((c) => c.priceAmount !== null);
    await svc.setEligibleCourses(draft.id, [paid[0].id]);
    await svc.activatePlanVersion(draft.id);
    const products = await svc.products();
    expect(products.active?.eligibleCourseIds).toEqual([paid[0].id]);
    expect(products.courses.length).toBeGreaterThan(1);
    const updated = await svc.setProducts([paid[0].id, paid[1].id]);
    expect(updated.active?.eligibleCourseIds).toEqual([paid[0].id, paid[1].id]);
    await expect(svc.setProducts([])).rejects.toMatchObject({ code: 'conflict' });
  });
});
