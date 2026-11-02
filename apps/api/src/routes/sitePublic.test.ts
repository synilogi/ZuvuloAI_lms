import request from 'supertest';
import { DEFAULT_SITE_CONTENT } from '@syniastrolms/domain';
import { beforeAll, describe, expect, it } from 'vitest';

import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { db } from '../test/db.js';
import { PASSWORD, app, as, newStudent, unique, type Client } from '../test/helpers.js';

/* What the public website reads from the platform's records (docs/17): figures, mentors, posts, images and the scheduled parts of the document. */

let owner: Client;

const postBody = (over: Record<string, unknown> = {}) => ({
  kind: 'article',
  title: `A post ${unique()}`,
  excerpt: 'In short.',
  body: 'The whole post.',
  coverUrl: '',
  externalUrl: '',
  eventAt: null,
  status: 'published',
  publishAt: null,
  ...over,
});

beforeAll(async () => {
  const email = `site-public-${unique()}@example.test`;
  await provisionSuperAdmin({ email, name: 'Site Owner', password: PASSWORD });
  owner = await as({ email, password: PASSWORD });
});

describe('the figures', () => {
  it('are counted from the records, and cannot be set', async () => {
    const before = (await request(app).get('/public/stats')).body;
    expect(Object.keys(before).sort()).toEqual(['courses', 'instructors', 'learners', 'learningHours']);
    await newStudent();
    expect((await request(app).get('/public/stats')).body.learners).toBe(before.learners + 1);
    expect((await owner.put('/superadmin/sales/site', { ...DEFAULT_SITE_CONTENT, stats: { learners: 100000, courses: true, instructors: true, learningHours: true } })).status).toBe(400);
  });
});

describe('mentors', () => {
  it('show no email, phone or account detail, and only those teaching a listed course', async () => {
    const res = await request(app).get('/public/mentors');
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThan(0);
    for (const m of res.body) {
      expect(m).not.toHaveProperty('email');
      expect(m).not.toHaveProperty('phone');
      expect(m.courseCount).toBeGreaterThan(0);
    }
    const one = await request(app).get(`/public/mentors/${res.body[0].id}`);
    expect(one.status).toBe(200);
    expect(one.body.courseSlugs.length).toBeGreaterThan(0);
    expect(JSON.stringify(one.body)).not.toMatch(/@/);
  });

  it('answers 404 for anyone else', async () => {
    expect((await request(app).get('/public/mentors/nobody')).status).toBe(404);
  });
});

describe('posts', () => {
  it('belong to the Super Admin to write', async () => {
    const learner = await newStudent();
    expect((await learner.post('/superadmin/sales/posts', postBody())).status).toBe(403);
    expect((await request(app).post('/superadmin/sales/posts').send(postBody())).status).toBe(401);
  });

  it('show only when published and past their date, without bodies in the list', async () => {
    const live = await owner.post('/superadmin/sales/posts', postBody());
    const draft = await owner.post('/superadmin/sales/posts', postBody({ status: 'draft' }));
    const later = await owner.post('/superadmin/sales/posts', postBody({ publishAt: new Date(Date.now() + 86_400_000).toISOString() }));
    expect(live.status, JSON.stringify(live.body)).toBe(201);
    const list = (await request(app).get('/public/posts')).body as { slug: string; body: string }[];
    expect(list.find((p) => p.slug === live.body.slug)?.body).toBe('');
    expect(list.some((p) => p.slug === draft.body.slug || p.slug === later.body.slug)).toBe(false);
    expect((await request(app).get(`/public/posts/${live.body.slug}`)).body.body).toBe('The whole post.');
    expect((await request(app).get(`/public/posts/${draft.body.slug}`)).status).toBe(404);
    expect((await request(app).get(`/public/posts/${later.body.slug}`)).status).toBe(404);
  });

  it('filter by kind, refuse an unknown kind and a non-https link', async () => {
    const webinar = await owner.post('/superadmin/sales/posts', postBody({ kind: 'webinar', eventAt: new Date().toISOString() }));
    const list = (await request(app).get('/public/posts?kind=webinar')).body as { id: string; kind: string }[];
    expect(list.every((p) => p.kind === 'webinar')).toBe(true);
    expect(list.some((p) => p.id === webinar.body.id)).toBe(true);
    expect((await request(app).get('/public/posts?kind=nonsense')).status).toBe(400);
    expect((await owner.post('/superadmin/sales/posts', postBody({ externalUrl: 'javascript:alert(1)' }))).status).toBe(400);
  });
});

describe('the document’s scheduled parts', () => {
  const testimonial = { quote: 'I finished the course.', name: 'A Learner', role: 'A course' };

  it('hides what is switched off, not yet due or finished, from visitors but not from the Super Admin', async () => {
    const saved = await owner.put('/superadmin/sales/site', {
      ...DEFAULT_SITE_CONTENT,
      testimonials: [
        { ...testimonial, name: 'Shown' },
        { ...testimonial, name: 'Off', published: false },
        { ...testimonial, name: 'Later', publishAt: new Date(Date.now() + 86_400_000).toISOString() },
      ],
      banners: [
        { title: 'Live banner', text: '' },
        { title: 'Over banner', text: '', endsAt: new Date(Date.now() - 1000).toISOString() },
      ],
    });
    expect(saved.status, JSON.stringify(saved.body)).toBe(200);
    const shown = (await request(app).get('/public/site')).body;
    expect(shown.testimonials.map((t: { name: string }) => t.name)).toEqual(['Shown']);
    expect(shown.banners.map((b: { title: string }) => b.title)).toEqual(['Live banner']);
    expect((await owner.get('/superadmin/sales/site')).body.testimonials).toHaveLength(3);
  });

  it('refuses a link that could run code, and an image that is not a website image', async () => {
    const banner = (linkTo: string) => ({ ...DEFAULT_SITE_CONTENT, banners: [{ title: 'A banner', text: '', linkTo }] });
    expect((await owner.put('/superadmin/sales/site', banner('javascript:alert(1)'))).status).toBe(400);
    expect((await owner.put('/superadmin/sales/site', banner('//evil.example'))).status).toBe(400);
    expect((await owner.put('/superadmin/sales/site', banner('/courses'))).status).toBe(200);
    expect((await owner.put('/superadmin/sales/site', { ...DEFAULT_SITE_CONTENT, heroImageUrl: 'https://evil.example/x.png' })).status).toBe(400);
    expect((await owner.put('/superadmin/sales/site', { ...DEFAULT_SITE_CONTENT, socials: [{ platform: 'x', url: 'http://not-secure.example' }] })).status).toBe(400);
  });

  it('reads a document saved before these fields existed, with every section in place', async () => {
    const row = await db.siteContent.findFirstOrThrow();
    await db.siteContent.update({ where: { id: row.id }, data: { contentJson: JSON.stringify({ heroTitle: 'An older headline', heroText: 'Older words.', featuredCourseIds: [], testimonials: [{ quote: 'Older quote.', name: 'A', role: '' }], faqs: [] }) } });
    const shown = (await request(app).get('/public/site')).body;
    expect(shown.heroTitle).toBe('An older headline');
    expect(shown.testimonials).toHaveLength(1);
    expect(shown.sections.map((s: { id: string }) => s.id)).toContain('bundles');
    expect(shown.stats.learners).toBe(true);
    await owner.put('/superadmin/sales/site', DEFAULT_SITE_CONTENT);
  });
});

describe('website images', () => {
  it('are served only when placed on the website', async () => {
    const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', 'base64');
    const uploaded = await request(app).post('/media/upload').set('Authorization', `Bearer ${owner.token}`).attach('file', png, { filename: 'hero.png', contentType: 'image/png' });
    expect(uploaded.status, JSON.stringify(uploaded.body)).toBe(201);
    const id = uploaded.body.id as string;
    expect((await request(app).get(`/public/images/${id}`)).status).toBe(404);
    const learner = await newStudent();
    expect((await learner.post('/superadmin/sales/site/images', { mediaId: id })).status).toBe(403);
    const placed = await owner.post('/superadmin/sales/site/images', { mediaId: id });
    expect(placed.status).toBe(201);
    expect(placed.body.url).toBe(`/public/images/${id}`);
    const served = await request(app).get(placed.body.url);
    expect(served.status).toBe(200);
    expect(served.headers['content-type']).toMatch(/image\/png/);
    // The document accepts it now, and the same upload twice is one placement.
    expect((await owner.post('/superadmin/sales/site/images', { mediaId: id })).status).toBe(201);
    expect((await owner.put('/superadmin/sales/site', { ...DEFAULT_SITE_CONTENT, heroImageUrl: placed.body.url })).status).toBe(200);
    await owner.put('/superadmin/sales/site', DEFAULT_SITE_CONTENT);
  });
});
