import { existsSync, readdirSync } from 'node:fs';
import { unlink } from 'node:fs/promises';
import path from 'node:path';
import { crc32, deflateSync } from 'node:zlib';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { BRAND_ASSET_RULES, brandAssetIssues } from '@syniastrolms/domain';

import { createApp } from '../app.js';
import { brandingDir } from '../lib/branding.js';
import { readImageInfo } from '../lib/imageInfo.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { db, platformDb } from '../test/db.js';
import { anon, app, as, newStudent, unique, type Client } from '../test/helpers.js';

/* The platform's logo and favicon: who may change them (the Super Admin alone, decided by the server), what a file
 * must be to be accepted, where a saved asset is read from, and that the built-in ZuviloAI branding is what shows
 * whenever nothing usable is saved. */

/* ─── Images, built here so each test states exactly what it uploads ─── */

const chunk = (type: string, data: Buffer) => {
  const body = Buffer.concat([Buffer.from(type, 'latin1'), data]);
  const out = Buffer.alloc(body.length + 8);
  out.writeUInt32BE(data.length, 0);
  body.copy(out, 4);
  out.writeUInt32BE(crc32(body), body.length + 4);
  return out;
};

/** A real, decodable RGBA PNG of the given size (transparent). */
function png(width: number, height: number): Buffer {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header.set([8, 6, 0, 0, 0], 8);
  const pixels = deflateSync(Buffer.alloc(height * (1 + width * 4)));
  return Buffer.concat([Buffer.from('89504e470d0a1a0a', 'hex'), chunk('IHDR', header), chunk('IDAT', pixels), chunk('IEND', Buffer.alloc(0))]);
}

/** A JPEG's structure — SOI, a baseline frame header carrying the size, EOI — which is all the server reads. */
function jpeg(width: number, height: number): Buffer {
  const frame = Buffer.from([0xff, 0xc0, 0x00, 0x0b, 0x08, 0, 0, 0, 0, 0x01, 0x01, 0x11, 0x00]);
  frame.writeUInt16BE(height, 5);
  frame.writeUInt16BE(width, 7);
  return Buffer.concat([Buffer.from([0xff, 0xd8]), frame, Buffer.from([0xff, 0xd9])]);
}

/** A WebP container with an extended header carrying the canvas size. */
function webp(width: number, height: number): Buffer {
  const out = Buffer.alloc(30);
  out.write('RIFF', 0, 'latin1');
  out.writeUInt32LE(22, 4);
  out.write('WEBPVP8X', 8, 'latin1');
  out.writeUInt32LE(10, 16);
  out.writeUIntLE(width - 1, 24, 3);
  out.writeUIntLE(height - 1, 27, 3);
  return out;
}

/** An ICO holding one PNG image. */
function ico(side: number): Buffer {
  const image = png(side, side);
  const head = Buffer.alloc(22);
  head.writeUInt16LE(1, 2);
  head.writeUInt16LE(1, 4);
  head[6] = side >= 256 ? 0 : side;
  head[7] = side >= 256 ? 0 : side;
  head.writeUInt16LE(1, 10);
  head.writeUInt16LE(32, 12);
  head.writeUInt32LE(image.length, 14);
  head.writeUInt32LE(22, 18);
  return Buffer.concat([head, image]);
}

const LOGO = png(600, 160);
const FAVICON = png(256, 256);

interface Part {
  field: string;
  data: Buffer;
  filename: string;
  contentType: string;
}
const logoPart = (data = LOGO, filename = 'logo.png', contentType = 'image/png'): Part => ({ field: 'logo', data, filename, contentType });
const faviconPart = (data = FAVICON, filename = 'favicon.png', contentType = 'image/png'): Part => ({ field: 'favicon', data, filename, contentType });

const put = (client: Client, ...parts: Part[]) => {
  const req = request(app).put('/superadmin/branding');
  if (client.token) req.set('Authorization', `Bearer ${client.token}`);
  for (const p of parts) req.attach(p.field, p.data, { filename: p.filename, contentType: p.contentType });
  return req;
};

const storedFiles = () => readdirSync(brandingDir());
const nameOf = (url: string) => url.split('/').pop()!;

let platform: Client;
let admin: Client;
let instructor: Client;
/** Files already in the folder when this suite starts — a developer's own saved branding shares it — are never touched. */
let alreadyThere: string[];

beforeAll(async () => {
  const email = `branding-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: 'branding-secret-1', name: 'Brand Keeper' });
  platform = await as({ email, password: 'branding-secret-1' });
  admin = await as('admin');
  instructor = await as('instructor');
  alreadyThere = storedFiles();
  await platformDb.platformBrandAsset.deleteMany();
});

afterAll(async () => {
  await platform.delete('/superadmin/branding');
  for (const name of storedFiles().filter((f) => !alreadyThere.includes(f))) await unlink(path.join(brandingDir(), name));
});

describe('reading an image from its bytes', () => {
  it('finds the format and size of each accepted kind', () => {
    expect(readImageInfo(png(600, 160))).toEqual({ format: 'png', width: 600, height: 160 });
    expect(readImageInfo(jpeg(800, 200))).toEqual({ format: 'jpeg', width: 800, height: 200 });
    expect(readImageInfo(webp(512, 128))).toEqual({ format: 'webp', width: 512, height: 128 });
    expect(readImageInfo(ico(64))).toEqual({ format: 'ico', width: 64, height: 64 });
    expect(readImageInfo(ico(256))).toEqual({ format: 'ico', width: 256, height: 256 });
  });

  it('refuses what is not a whole image', () => {
    expect(readImageInfo(Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'))).toBeNull();
    expect(readImageInfo(Buffer.from('MZ\x90\x00\x03\x00\x00\x00', 'latin1'))).toBeNull();
    expect(readImageInfo(Buffer.alloc(0))).toBeNull();
    // Cut short.
    expect(readImageInfo(LOGO.subarray(0, LOGO.length - 5))).toBeNull();
    // Only the first bytes of a PNG — what a signature check alone would have accepted.
    expect(readImageInfo(Buffer.from('89504e470d0a1a0a', 'hex'))).toBeNull();
    // A second file hiding after the image.
    expect(readImageInfo(Buffer.concat([LOGO, Buffer.from('<script>alert(1)</script>')]))).toBeNull();
    // An icon whose directory points outside the file.
    const outside = ico(64);
    outside.writeUInt32LE(9_999_999, 18);
    expect(readImageInfo(outside)).toBeNull();
    // A header claiming an absurd size.
    expect(readImageInfo(png(1, 1).fill(0xff, 16, 20))).toBeNull();
  });
});

describe('the rules a brand asset must meet', () => {
  it('accepts the shapes the screens are built for, and says why it refuses the rest', () => {
    expect(brandAssetIssues('logo', { name: 'logo.png', mime: 'image/png', bytes: 40_000, width: 600, height: 160 })).toEqual([]);
    expect(brandAssetIssues('favicon', { name: 'icon.ico', mime: 'image/x-icon', bytes: 9_000, width: 64, height: 64 })).toEqual([]);
    expect(brandAssetIssues('logo', { name: 'logo.svg', mime: 'image/svg+xml' })[0]).toMatch(/PNG, JPG or WebP/);
    expect(brandAssetIssues('favicon', { name: 'icon.jpg', mime: 'image/jpeg' })[0]).toMatch(/PNG or ICO/);
    expect(brandAssetIssues('logo', { bytes: BRAND_ASSET_RULES.logo.maxBytes + 1 })[0]).toMatch(/at most 1 MB/);
    expect(brandAssetIssues('logo', { width: 100, height: 40 })[0]).toMatch(/at least 128 × 64/);
    expect(brandAssetIssues('logo', { width: 3000, height: 600 })[0]).toMatch(/at most 2400 × 1200/);
    expect(brandAssetIssues('logo', { width: 300, height: 600 })[0]).toMatch(/between square and 6 times/);
    expect(brandAssetIssues('logo', { width: 2000, height: 100 })[0]).toMatch(/between square and 6 times/);
    expect(brandAssetIssues('favicon', { width: 256, height: 128 })[0]).toMatch(/must be square/);
    expect(brandAssetIssues('favicon', { width: 32, height: 32 })[0]).toMatch(/at least 48 × 48/);
  });
});

describe('who may change the platform’s branding', () => {
  it('shows every visitor the built-in branding when nothing is saved', async () => {
    const res = await anon().get('/public/branding');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ logo: null, favicon: null });
    expect(res.headers['cache-control']).toBe('no-cache');
  });

  it('refuses everyone but the Super Admin, on the server, and keeps nothing they send', async () => {
    const learner = await newStudent('Brand Learner');
    for (const [who, client] of [
      ['academy admin', admin],
      ['instructor', instructor],
      ['learner', learner],
    ] as const) {
      expect((await client.get('/superadmin/branding')).status, who).toBe(403);
      const upload = await put(client, logoPart(), faviconPart());
      expect(upload.status, who).toBe(403);
      expect(upload.body.code, who).toBe('PERMISSION_DENIED');
      expect((await client.delete('/superadmin/branding')).status, who).toBe(403);
      expect((await client.delete('/superadmin/branding/logo')).status, who).toBe(403);
    }
    expect((await anon().get('/superadmin/branding')).status).toBe(401);
    expect((await put(anon(), logoPart())).status).toBe(401);
    expect((await anon().delete('/superadmin/branding')).status).toBe(401);

    expect(await platformDb.platformBrandAsset.count()).toBe(0);
    expect(storedFiles()).toEqual(alreadyThere);
    expect((await anon().get('/public/branding')).body).toEqual({ logo: null, favicon: null });
  });

  it('has no academy-level way in: an academy’s appearance settings never become the platform’s branding', async () => {
    const before = await admin.get('/settings');
    expect(before.status).toBe(200);
    const saved = await admin.put('/settings/appearance', { ...before.body.settings.appearance, brandName: 'An Academy' });
    expect(saved.status, JSON.stringify(saved.body)).toBe(200);
    expect(await platformDb.platformBrandAsset.count()).toBe(0);
    expect((await anon().get('/public/branding')).body).toEqual({ logo: null, favicon: null });
    await admin.put('/settings/appearance', before.body.settings.appearance);
  });
});

describe('saving a logo and a favicon', () => {
  let logoUrl: string;
  let faviconUrl: string;

  it('stores both, shows them to the Super Admin, and serves them to every visitor', async () => {
    const appearanceBefore = (await db.settings.findFirstOrThrow()).appearanceJson;
    const res = await put(platform, logoPart(LOGO, 'Our "new" logo.png'), faviconPart());
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    expect(res.body.logo).toMatchObject({
      mime: 'image/png',
      width: 600,
      height: 160,
      sizeBytes: LOGO.length,
      name: 'Our _new_ logo.png',
      updatedBy: 'Brand Keeper',
    });
    expect(res.body.favicon).toMatchObject({ mime: 'image/png', width: 256, height: 256, name: 'favicon.png' });
    logoUrl = res.body.logo.url;
    faviconUrl = res.body.favicon.url;
    // The address is the server's own name for the file, never the uploaded one.
    expect(logoUrl).toMatch(/^\/public\/branding\/assets\/logo-[0-9a-f-]{36}\.png$/);
    expect(faviconUrl).toMatch(/^\/public\/branding\/assets\/favicon-[0-9a-f-]{36}\.png$/);

    expect((await platform.get('/superadmin/branding')).body.logo.url).toBe(logoUrl);
    const seen = await anon().get('/public/branding');
    expect(seen.body).toEqual({
      logo: { url: logoUrl, mime: 'image/png', width: 600, height: 160 },
      favicon: { url: faviconUrl, mime: 'image/png', width: 256, height: 256 },
    });

    const file = await anon().get(logoUrl).buffer(true);
    expect(file.status).toBe(200);
    expect(Buffer.compare(file.body as Buffer, LOGO)).toBe(0);
    expect(file.headers['content-type']).toBe('image/png');
    expect(file.headers['x-content-type-options']).toBe('nosniff');
    expect(file.headers['cache-control']).toBe('public, max-age=31536000, immutable');
    expect(file.headers['content-security-policy']).toMatch(/default-src 'none'/);

    // Platform branding only: the academy's own appearance is exactly as it was.
    expect((await db.settings.findFirstOrThrow()).appearanceJson).toBe(appearanceBefore);
    const audit = await platformDb.auditLog.findFirstOrThrow({ where: { action: 'branding.updated' }, orderBy: { createdAt: 'desc' } });
    expect(audit).toMatchObject({ targetType: 'branding', actorRole: 'superadmin' });
    expect(JSON.parse(audit.metaJson)).toMatchObject({ logo: { format: 'png', width: 600, height: 160 }, favicon: { format: 'png', width: 256 } });
  });

  it('is still there for a server that has just started', async () => {
    const fresh = createApp();
    const seen = await request(fresh).get('/public/branding');
    expect(seen.body.logo.url).toBe(logoUrl);
    expect((await request(fresh).get(faviconUrl)).status).toBe(200);
  });

  it('gives a replacement a new address, drops the old file, and leaves the other asset alone', async () => {
    const next = jpeg(900, 300);
    const res = await put(platform, logoPart(next, 'wide.JPG', 'image/jpeg'));
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    expect(res.body.logo).toMatchObject({ mime: 'image/jpeg', width: 900, height: 300 });
    expect(res.body.logo.url).toMatch(/\.jpg$/);
    expect(res.body.logo.url).not.toBe(logoUrl);
    expect(res.body.favicon.url).toBe(faviconUrl);
    expect((await anon().get(logoUrl)).status).toBe(404);
    expect(existsSync(path.join(brandingDir(), nameOf(logoUrl)))).toBe(false);
    expect((await anon().get(res.body.logo.url)).headers['content-type']).toBe('image/jpeg');
    logoUrl = res.body.logo.url;
  });

  it('accepts a WebP logo and an ICO favicon', async () => {
    const res = await put(platform, logoPart(webp(512, 128), 'logo.webp', 'image/webp'), faviconPart(ico(64), 'favicon.ico', 'image/vnd.microsoft.icon'));
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    expect(res.body.logo).toMatchObject({ mime: 'image/webp', width: 512, height: 128 });
    expect(res.body.favicon).toMatchObject({ mime: 'image/x-icon', width: 64, height: 64 });
    expect((await anon().get(res.body.favicon.url)).headers['content-type']).toBe('image/x-icon');
    logoUrl = res.body.logo.url;
    faviconUrl = res.body.favicon.url;
  });

  it('serves only the saved files, whatever the address asks for', async () => {
    const media = await admin.upload('/media/upload').attach('file', LOGO, { filename: 'lesson.png', contentType: 'image/png' });
    expect(media.status).toBe(201);
    const mediaFile = (await db.mediaAsset.findUniqueOrThrow({ where: { id: media.body.id } })).storageName;
    for (const name of [
      mediaFile,
      `..%2F${mediaFile}`,
      '..%2F..%2Fprisma%2Ftest.db',
      '%2e%2e%2f%2e%2e%2f.env',
      '..%5C..%5C.env',
      '.env',
      'logo-00000000-0000-0000-0000-000000000000.png',
      `${nameOf(logoUrl)}%00.png`,
    ]) {
      const res = await anon().get(`/public/branding/assets/${name}`);
      expect(res.status, name).toBe(404);
      expect(res.body, name).toEqual({ message: 'File not found.' });
    }
  });

  it('falls back to the built-in asset when a saved file has gone missing', async () => {
    await unlink(path.join(brandingDir(), nameOf(faviconUrl)));
    const seen = await anon().get('/public/branding');
    expect(seen.body.favicon).toBeNull();
    expect(seen.body.logo.url).toBe(logoUrl);
    expect((await anon().get(faviconUrl)).status).toBe(404);
    expect((await platform.get('/superadmin/branding')).body.favicon).toBeNull();
    // And it can simply be uploaded again.
    const again = await put(platform, faviconPart());
    expect(again.status).toBe(200);
    faviconUrl = again.body.favicon.url;
    expect((await anon().get(faviconUrl)).status).toBe(200);
  });

  describe('a file that is not acceptable', () => {
    const refused = async (parts: Part[], field: 'logo' | 'favicon', message: RegExp, status = 400) => {
      const filesBefore = storedFiles();
      const res = await put(platform, ...parts);
      expect(res.status, JSON.stringify(res.body)).toBe(status);
      if (status === 400) {
        expect(res.body.code).toBe('VALIDATION_FAILED');
        const issue = (res.body.issues as { field: string; message: string }[]).find((i) => i.field === field);
        expect(issue?.message, JSON.stringify(res.body)).toMatch(message);
      }
      // Nothing of it is kept, and what was saved is untouched.
      expect(storedFiles()).toEqual(filesBefore);
      expect((await anon().get('/public/branding')).body).toMatchObject({ logo: { url: logoUrl }, favicon: { url: faviconUrl } });
    };

    it('is refused for its type', async () => {
      const svg = Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>');
      await refused([logoPart(svg, 'logo.svg', 'image/svg+xml')], 'logo', /must be a PNG, JPG or WebP file/);
      await refused([logoPart(Buffer.from('%PDF-1.7\n'), 'logo.pdf', 'application/pdf')], 'logo', /must be a PNG, JPG or WebP file/);
      await refused([logoPart(Buffer.from('<html><script>alert(1)</script></html>'), 'logo.html', 'text/html')], 'logo', /must be a PNG, JPG or WebP file/);
      await refused([faviconPart(jpeg(256, 256), 'favicon.jpg', 'image/jpeg')], 'favicon', /must be a PNG or ICO file/);
      // The name says image, the declared type does not — and the other way round.
      await refused([logoPart(LOGO, 'logo.png', 'text/html')], 'logo', /must be a PNG, JPG or WebP file/);
      await refused([logoPart(LOGO, 'logo.php', 'image/png')], 'logo', /must be a PNG, JPG or WebP file/);
    });

    it('is refused when its contents are not the image its name claims', async () => {
      await refused([logoPart(Buffer.from('<html><script>alert(1)</script></html>'), 'logo.png')], 'logo', /not a valid PNG, JPG or WebP image/);
      await refused([logoPart(Buffer.from('MZ\x90\x00\x03\x00\x00\x00', 'latin1'), 'logo.png')], 'logo', /not a valid/);
      await refused([logoPart(Buffer.concat([LOGO, Buffer.from('<script>alert(1)</script>')]))], 'logo', /not a valid/);
      await refused([logoPart(LOGO.subarray(0, 60))], 'logo', /not a valid/);
      // A real JPEG under a PNG's name.
      await refused([logoPart(jpeg(600, 160), 'logo.png')], 'logo', /do not match its type/);
      // A real WebP is an image, but not one a favicon may be.
      await refused([faviconPart(webp(256, 256), 'favicon.png')], 'favicon', /do not match its type/);
    });

    it('is refused for its size, dimensions or proportions', async () => {
      await refused([logoPart(png(100, 40))], 'logo', /at least 128 × 64/);
      await refused([logoPart(png(2600, 800))], 'logo', /at most 2400 × 1200/);
      await refused([logoPart(png(300, 600))], 'logo', /between square and 6 times/);
      await refused([logoPart(png(1400, 100))], 'logo', /between square and 6 times/);
      await refused([faviconPart(png(256, 128))], 'favicon', /must be square/);
      await refused([faviconPart(png(32, 32))], 'favicon', /at least 48 × 48/);
      await refused([faviconPart(ico(32), 'favicon.ico', 'image/x-icon')], 'favicon', /at least 48 × 48/);
      // Over the favicon's own limit, though under the logo's.
      const heavy = Buffer.concat([png(256, 256).subarray(0, -12), chunk('tEXt', Buffer.alloc(300 * 1024, 0x61)), chunk('IEND', Buffer.alloc(0))]);
      expect(readImageInfo(heavy)).toMatchObject({ width: 256 });
      await refused([faviconPart(heavy)], 'favicon', /at most 256 KB/);
      // Over every limit: refused while it is still arriving.
      await refused([logoPart(Buffer.alloc(BRAND_ASSET_RULES.logo.maxBytes + 1024))], 'logo', /./, 413);
    });

    it('refuses the whole request when one of two files is bad, saving neither', async () => {
      await refused([logoPart(png(640, 160)), faviconPart(png(256, 128))], 'favicon', /must be square/);
    });

    it('is refused when nothing, or something unexpected, is sent', async () => {
      const empty = await platform.put('/superadmin/branding', {});
      expect(empty.status).toBe(400);
      expect(empty.body.message).toBe('Choose a logo or a favicon to upload.');
      const stray = await request(app)
        .put('/superadmin/branding')
        .set('Authorization', `Bearer ${platform.token}`)
        .attach('file', LOGO, { filename: 'logo.png', contentType: 'image/png' });
      expect(stray.status).toBe(400);
      const twice = await request(app)
        .put('/superadmin/branding')
        .set('Authorization', `Bearer ${platform.token}`)
        .attach('logo', LOGO, { filename: 'a.png', contentType: 'image/png' })
        .attach('logo', LOGO, { filename: 'b.png', contentType: 'image/png' });
      expect(twice.status).toBe(400);
      expect((await anon().get('/public/branding')).body.logo.url).toBe(logoUrl);
    });
  });

  it('restores one default, then the other, removing the files', async () => {
    const one = await platform.delete('/superadmin/branding/logo');
    expect(one.status).toBe(200);
    expect(one.body.logo).toBeNull();
    expect(one.body.favicon.url).toBe(faviconUrl);
    expect((await anon().get(logoUrl)).status).toBe(404);
    expect(existsSync(path.join(brandingDir(), nameOf(logoUrl)))).toBe(false);
    expect((await platform.delete('/superadmin/branding/banner')).status).toBe(404);

    const all = await platform.delete('/superadmin/branding');
    expect(all.status).toBe(200);
    expect(all.body).toEqual({ logo: null, favicon: null });
    expect((await anon().get('/public/branding')).body).toEqual({ logo: null, favicon: null });
    expect(await platformDb.platformBrandAsset.count()).toBe(0);
    expect(storedFiles()).toEqual(alreadyThere);

    const audits = await platformDb.auditLog.findMany({ where: { action: 'branding.restored' }, orderBy: { createdAt: 'desc' }, take: 2 });
    expect(audits.map((a) => JSON.parse(a.metaJson).assets)).toEqual([['favicon'], ['logo']]);
    // Restoring when the default is already in use changes nothing and records nothing.
    const recorded = await platformDb.auditLog.count({ where: { action: 'branding.restored' } });
    expect((await platform.delete('/superadmin/branding')).status).toBe(200);
    expect(await platformDb.auditLog.count({ where: { action: 'branding.restored' } })).toBe(recorded);
  });
});
