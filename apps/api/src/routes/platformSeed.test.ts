import { afterEach, describe, expect, it } from 'vitest';

import { seedCertificateTemplate, seedLevels, seedRanks } from '../../prisma/platformSeed.js';
import { platformDb } from '../test/db.js';
import { unique } from '../test/helpers.js';

/* A production platform is built by the platform seed alone, with no demo data: what no screen can create has to come
 * from here, or the first course can't be saved. Run against a workspace of its own, so the shared fixtures stay as they are. */

const workspace = async () => {
  const slug = `seed-${unique()}`;
  process.env.DEFAULT_TENANT_SLUG = slug;
  return platformDb.tenant.create({ data: { name: 'Seed Workspace', slug } });
};

afterEach(() => {
  delete process.env.DEFAULT_TENANT_SLUG;
});

describe('the platform seed', () => {
  it('gives an empty workspace the levels, ranks and certificate template it can’t create itself', async () => {
    const { id: tenantId } = await workspace();
    expect(await seedLevels()).toBe(true);
    expect(await seedRanks()).toBe(true);
    expect(await seedCertificateTemplate()).toBe(true);

    const levels = await platformDb.level.findMany({ where: { tenantId }, orderBy: { order: 'asc' } });
    expect(levels.map((l) => l.name)).toEqual(['Beginner', 'Intermediate', 'Advanced']);
    expect(await platformDb.rank.count({ where: { tenantId } })).toBe(3);
    expect(await platformDb.certificateTemplate.count({ where: { tenantId, isDefault: true } })).toBe(1);
  });

  it('leaves alone what is already there, so every deploy can run it', async () => {
    const { id: tenantId } = await workspace();
    await seedLevels();
    await seedRanks();
    await seedCertificateTemplate();
    await platformDb.level.updateMany({ where: { tenantId, name: 'Beginner' }, data: { name: 'Foundation' } });

    expect(await seedLevels()).toBe(false);
    expect(await seedRanks()).toBe(false);
    expect(await seedCertificateTemplate()).toBe(false);
    expect(await platformDb.level.count({ where: { tenantId } })).toBe(3);
    expect(await platformDb.level.count({ where: { tenantId, name: 'Foundation' } })).toBe(1);
  });
});
