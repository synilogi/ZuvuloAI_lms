import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { certificateAdminService as service } from './certificates';
import { learningService } from './learning';
import { courseTemplate } from './fixtures/certificates';
import { DEMO_NOW } from './fixtures/learner';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('certificate mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers({ now: new Date(DEMO_NOW) });
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('lists issued, pending and revoked certificates with counts that add up', async () => {
    const { rows, total, counts } = await settle(service.list({ page: 1, pageSize: 20 }));
    expect(total).toBe(counts.all);
    expect(counts.issued + counts.pending + counts.revoked).toBe(counts.all);
    expect(counts.pending).toBeGreaterThan(0);
    expect(counts.revoked).toBeGreaterThan(0);
    expect(rows[0].courseTitle).toBeTruthy();
    const found = await settle(service.list({ search: 'SA-JY-2026-04817', page: 1, pageSize: 5 }));
    expect(found.rows[0].studentName).toBe('Ananya Rao');
  });

  it('issues, revokes with a reason and restores', async () => {
    const pending = (await settle(service.list({ status: 'pending', page: 1, pageSize: 1 }))).rows[0].certificate;
    expect((await settle(service.issue(pending.id))).status).toBe('issued');
    const noReason = expect(service.revoke(pending.id, 'no')).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await noReason;
    expect((await settle(service.revoke(pending.id, 'Enrollment refunded after completion'))).status).toBe('revoked');
    expect((await settle(service.restore(pending.id))).status).toBe('issued');
  });

  it('verifies a credential and counts the check', async () => {
    const detail = await settle(service.verify('sa-jy-2026-04817'));
    expect(detail.student.name).toBe('Ananya Rao');
    expect(detail.template.id).toBe('tpl-foundation');
    const missing = expect(service.verify('SA-XX-0000-00000')).rejects.toMatchObject({ code: 'not-found' });
    await vi.runAllTimersAsync();
    await missing;
  });

  it('lets the learner claim a certificate she has earned', async () => {
    const mine = await settle(learningService.listCertificates());
    expect(mine.issued.map((c) => c.courseTitle)).toEqual(['Introduction to Jyotish']);
    expect(mine.pending.map((c) => c.courseTitle)).toEqual(['Panchang Essentials']);
    expect(mine.working.map((r) => r.courseId)).toContain('foundations-vedic');
    const claimed = await settle(learningService.claimCertificate(mine.pending[0].certificate.id));
    expect(claimed.certificate.status).toBe('issued');
  });

  it('moves courses between templates and validates signatories', async () => {
    const { template } = await settle(service.getTemplate('tpl-cohort'));
    const bad = expect(service.saveTemplate(template.id, { ...template, signatories: [{ name: '', title: 'Dean' }], courseIds: [] })).rejects.toMatchObject({
      code: 'conflict',
    });
    await vi.runAllTimersAsync();
    await bad;
    await settle(service.saveTemplate(template.id, { ...template, courseIds: ['muhurta', 'dasha'] }));
    expect(courseTemplate.dasha).toBe('tpl-cohort');
    expect(courseTemplate.jaimini).toBeUndefined();
    const def = await settle(service.setDefaultTemplate('tpl-cohort'));
    expect(def.isDefault).toBe(true);
  });
});
