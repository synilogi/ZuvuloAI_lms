/* Writes Android's App Links file where the web server answers `/.well-known/` itself. CloudPanel's vhost serves
 * that folder from the site root (it is where certificate challenges live) and never forwards it to the API, so
 * the route in `src/web.ts` is not reached in production; this puts the same statements, built by the same
 * `assetLinks()` from ANDROID_APP_LINK_SHA256 / ANDROID_APP_LINK_PACKAGES, into the file nginx reads.
 *
 *   APP_LINKS_DIR=<site>/.well-known npm run app-links:publish -w @syniastrolms/api
 *
 * Unset fingerprints remove the file, so the URL 404s and links open in the browser — the intended fallback.
 * deploy.sh runs it on every deploy, so a change to .env takes effect with the next one.
 */
import 'dotenv/config';

import { existsSync, mkdirSync, renameSync, rmSync, writeFileSync } from 'node:fs';
import path from 'node:path';

import { assetLinks } from '../src/lib/appLinks.js';

const dir = process.env.APP_LINKS_DIR;
if (!dir) {
  console.error('[app-links] APP_LINKS_DIR is not set; nothing written.');
  process.exit(1);
}
const file = path.join(path.resolve(dir), 'assetlinks.json');
const links = assetLinks(process.env);

if (!links) {
  if (existsSync(file)) rmSync(file);
  console.log('[app-links] ANDROID_APP_LINK_SHA256 is not set; no assetlinks.json is served.');
  process.exit(0);
}

mkdirSync(path.dirname(file), { recursive: true, mode: 0o755 });
// Written beside and renamed over, so nginx never serves half a file.
const temp = `${file}.tmp`;
writeFileSync(temp, `${JSON.stringify(links, null, 2)}\n`, { mode: 0o644 });
renameSync(temp, file);
const packages = links.map((l) => l.target.package_name).join(', ');
console.log(`[app-links] ${file}: ${packages}, ${links[0].target.sha256_cert_fingerprints.length} certificate(s).`);
