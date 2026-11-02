import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import request from 'supertest';

import { createApp } from './app.js';
import { serveWebApp } from './web.js';

const dist = mkdtempSync(path.join(tmpdir(), 'web-dist-'));
mkdirSync(path.join(dist, 'assets'));
writeFileSync(path.join(dist, 'index.html'), '<!doctype html><title>shell</title>');
writeFileSync(path.join(dist, 'assets', 'index-abc123.js'), 'console.log(1)');
const app = serveWebApp(createApp(), dist);

describe('serving the web app alongside the API', () => {
  it('answers the API under /api', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true });
  });

  it('returns the shell, uncached, for a client-side route', async () => {
    const res = await request(app).get('/courses/some-course');
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/html/);
    expect(res.text).toContain('shell');
    expect(res.headers['cache-control']).toBe('no-cache');
  });

  it('caches hashed assets for a year and 404s a missing one instead of serving the shell', async () => {
    const ok = await request(app).get('/assets/index-abc123.js');
    expect(ok.status).toBe(200);
    expect(ok.headers['cache-control']).toContain('immutable');
    const missing = await request(app).get('/assets/nope.js');
    expect(missing.status).toBe(404);
  });

  it('keeps unknown API paths as JSON 404s, not the shell', async () => {
    const res = await request(app).get('/api/no-such-route');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ message: 'Not found.' });
  });

  it('answers assetlinks.json with JSON built from the environment, and 404s it when none is configured', async () => {
    const unset = await request(app).get('/.well-known/assetlinks.json');
    expect(unset.status).toBe(404);
    expect(unset.headers['content-type']).toMatch(/json/);

    const sha = Array.from({ length: 32 }, (_, i) => i.toString(16).padStart(2, '0')).join(':');
    const configured = serveWebApp(createApp(), dist, { ANDROID_APP_LINK_SHA256: sha });
    const res = await request(configured).get('/.well-known/assetlinks.json');
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/application\/json/);
    expect(res.body).toEqual([
      {
        relation: ['delegate_permission/common.handle_all_urls'],
        target: { namespace: 'android_app', package_name: 'com.shubhlms.mobile', sha256_cert_fingerprints: [sha.toUpperCase()] },
      },
    ]);
  });

  it('refuses to start with a fingerprint that is not one', () => {
    expect(() => serveWebApp(createApp(), dist, { ANDROID_APP_LINK_SHA256: 'AB:CD' })).toThrow(/ANDROID_APP_LINK_SHA256/);
  });

  it('refuses to start without a built index.html', () => {
    expect(() => serveWebApp(createApp(), path.join(dist, 'not-built'))).toThrow(/index\.html/);
  });
});

/* None of these touches the database: redirects answer before the API, and the sitemap is given its data. */
describe('the old addresses and the sitemap', () => {
  const noEntries = () => Promise.resolve([]);
  const site = serveWebApp(createApp(), dist, {}, noEntries);

  it.each([
    ['/pricing', '/'],
    ['/features', '/'],
    ['/solutions', '/'],
    ['/how-it-works', '/#how-it-works'],
    ['/get-started', '/register'],
    ['/join', '/register'],
    ['/join/old-academy', '/register'],
    ['/join/old-academy/teach', '/teach/apply'],
  ])('moves %s to %s for good', async (from, to) => {
    const res = await request(site).get(from);
    expect(res.status).toBe(301);
    expect(res.headers.location).toBe(to);
  });

  it('keeps the query string a moved address carries', async () => {
    expect((await request(site).get('/join/old-academy?ref=ABC123')).headers.location).toBe('/register?ref=ABC123');
    expect((await request(site).get('/get-started?ref=ABC123&next=%2Fcourses')).headers.location).toBe('/register?ref=ABC123&next=%2Fcourses');
    expect((await request(site).get('/how-it-works?a=1')).headers.location).toBe('/?a=1#how-it-works');
  });

  it('builds the sitemap from what is published, with the static pages, and reads it once while cached', async () => {
    let reads = 0;
    const withCourse = serveWebApp(createApp(), dist, {}, () => {
      reads += 1;
      return Promise.resolve([{ path: '/courses/a&b', lastmod: new Date('2026-10-01T00:00:00Z') }, { path: '/support/article/reset' }]);
    });
    const res = await request(withCourse).get('/sitemap.xml');
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/application\/xml/);
    expect(res.text).toContain('<loc>https://zuviloai.com/</loc>');
    expect(res.text).toContain('<loc>https://zuviloai.com/teach/apply</loc>');
    expect(res.text).toContain('<loc>https://zuviloai.com/courses/a&amp;b</loc><lastmod>2026-10-01</lastmod>');
    expect(res.text).toContain('<loc>https://zuviloai.com/support/article/reset</loc>');
    await request(withCourse).get('/sitemap.xml');
    expect(reads).toBe(1);
  });

  it('still answers with the static pages when the data cannot be read', async () => {
    const failing = serveWebApp(createApp(), dist, {}, () => Promise.reject(new Error('no database')));
    const res = await request(failing).get('/sitemap.xml');
    expect(res.status).toBe(200);
    expect(res.text).toContain('<loc>https://zuviloai.com/courses</loc>');
  });
});
