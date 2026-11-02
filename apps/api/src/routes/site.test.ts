import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';
import { DEFAULT_SITE_CONTENT } from '@syniastrolms/domain';

import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { db } from '../test/db.js';
import { PASSWORD, app, as, newStudent, unique, type Client } from '../test/helpers.js';

/* The public website's editable document and the affiliate terms it publishes (docs/16 §2.6, D-PLAT-13). */

let owner: Client;

beforeAll(async () => {
  const email = `site-owner-${unique()}@example.test`;
  await provisionSuperAdmin({ email, name: 'Site Owner', password: PASSWORD });
  owner = await as({ email, password: PASSWORD });
});

const edited = {
  ...DEFAULT_SITE_CONTENT,
  heroTitle: 'A headline from the owner',
  testimonials: [{ quote: 'I finished the course.', name: 'A Learner', role: 'Class 10 Science' }],
};

describe('the website document', () => {
  it('is readable without signing in, and carries no invented testimonials by default', async () => {
    const res = await request(app).get('/public/site');
    expect(res.status).toBe(200);
    expect(res.body.faqs.length).toBeGreaterThan(0);
    if ((await db.siteContent.count()) === 0) expect(res.body.testimonials).toEqual([]);
  });

  it('can be changed only by the Super Admin', async () => {
    const learner = await newStudent();
    expect((await learner.put('/superadmin/sales/site', edited)).status).toBe(403);
    expect((await request(app).put('/superadmin/sales/site').send(edited)).status).toBe(401);
  });

  it('saves, shows publicly at once, and writes the activity log', async () => {
    const saved = await owner.put('/superadmin/sales/site', edited);
    expect(saved.status, JSON.stringify(saved.body)).toBe(200);
    const shown = await request(app).get('/public/site');
    expect(shown.body.heroTitle).toBe('A headline from the owner');
    expect(shown.body.testimonials).toHaveLength(1);
    expect(await db.auditLog.count({ where: { action: 'site.content_updated' } })).toBeGreaterThan(0);
  });

  it('refuses unknown fields and an empty headline', async () => {
    expect((await owner.put('/superadmin/sales/site', { ...edited, script: '<x>' })).status).toBe(400);
    expect((await owner.put('/superadmin/sales/site', { ...edited, heroTitle: ' ' })).status).toBe(400);
  });
});

describe('the affiliate program’s published terms', () => {
  it('are public and contain plan terms only: no member, sponsor or earnings data', async () => {
    const res = await request(app).get('/public/affiliate-program');
    expect(res.status).toBe(200);
    expect(typeof res.body.active).toBe('boolean');
    expect(Object.keys(res.body).sort()).toEqual(['active', 'course', 'currency', 'matchingRateBps', 'ranks', 'withdrawalMinAmount', 'withdrawalRequiresKyc']);
  });
});
