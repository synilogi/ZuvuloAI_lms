import { existsSync } from 'node:fs';
import path from 'node:path';
import express, { type Express } from 'express';

import { assetLinks } from './lib/appLinks.js';
import { securityHeaders } from './lib/security.js';
import { loadSitemapEntries, sitemapCache, type SitemapEntry } from './lib/sitemap.js';

/** Addresses of the SaaS era, moved for good. A query string they carry (a referral) goes with them. */
const MOVED: [string[], string, string?][] = [
  [['/pricing', '/features', '/solutions'], '/'],
  [['/how-it-works'], '/', '#how-it-works'],
  [['/get-started', '/join', '/join/:slug'], '/register'],
  [['/join/:slug/teach'], '/teach/apply'],
];

/**
 * Wraps the API so a single process can also serve the built web app. The production host's
 * vhost forwards every path to this process, so the API moves under `/api` and everything
 * else is the SPA: hashed assets cached for a year, `index.html` for any client-side route.
 *
 * In development this is unused — Vite serves the web app and the API stays at `/`.
 */
export function serveWebApp(
  api: Express,
  dist: string,
  env: NodeJS.ProcessEnv = process.env,
  sitemapEntries: () => Promise<SitemapEntry[]> = loadSitemapEntries,
): Express {
  const index = path.join(dist, 'index.html');
  // Fail at boot, not on the first visitor: a deploy that skipped the web build must not
  // come up as a process that answers every page with a 500.
  if (!existsSync(index)) throw new Error(`WEB_DIST has no index.html: ${dist} — run the web build first.`);

  const app = express();
  app.disable('x-powered-by');
  // Same proxy trust as the API, so req.ip is the visitor on this side as well.
  const trustProxy = Number(process.env.TRUST_PROXY ?? 0);
  if (trustProxy > 0) app.set('trust proxy', trustProxy);
  app.use(securityHeaders);

  app.use('/api', api);

  // Android App Links: answered here, as JSON, because the static handler skips dot-folders and the SPA
  // fallback would otherwise answer it with HTML — which Android reads as "not verified". Read once at boot.
  const links = assetLinks(env);
  app.get('/.well-known/assetlinks.json', (_req, res) => {
    if (!links) {
      res.status(404).json({ message: 'Not found.' });
      return;
    }
    res.set('Cache-Control', 'public, max-age=3600').json(links);
  });

  for (const [paths, to, hash = ''] of MOVED) {
    app.get(paths, (req, res) => {
      const at = req.originalUrl.indexOf('?');
      res.redirect(301, `${to}${at < 0 ? '' : req.originalUrl.slice(at)}${hash}`);
    });
  }

  // Built from what is published, so a new course needs no deploy. Ahead of the static files for that reason too.
  const sitemap = sitemapCache(sitemapEntries);
  app.get('/sitemap.xml', (_req, res, next) => {
    sitemap()
      .then((xml) => res.type('application/xml').set('Cache-Control', 'public, max-age=600').send(xml))
      .catch(next);
  });

  // Vite names everything under /assets by content hash, so those can be cached forever.
  app.use('/assets', express.static(path.join(dist, 'assets'), { immutable: true, maxAge: '1y', fallthrough: false }));
  app.use(express.static(dist, { index: false }));
  // Client-side routing: any other GET is the shell, never a 404 — the SPA decides.
  app.get('*', (_req, res) => res.sendFile(index, { headers: { 'Cache-Control': 'no-cache' } }));
  return app;
}
