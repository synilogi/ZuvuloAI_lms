/**
 * Android App Links (`/.well-known/assetlinks.json`). Android opens the site's join, reset-password,
 * certificate and course links in the app only when the domain vouches for the app's signing certificate
 * here, served as JSON over https with no redirect. The file is built from the environment rather than
 * committed, because the certificate that matters in production is Google Play's app-signing key, which
 * only the Play Console shows.
 *
 *   ANDROID_APP_LINK_SHA256   comma-separated SHA-256 certificate fingerprints (AA:BB:…, 32 bytes each)
 *   ANDROID_APP_LINK_PACKAGES comma-separated package names; defaults to the production app
 *
 * Unset, the file is not served (404) and links open in the browser, which is the intended fallback.
 */
export const DEFAULT_ANDROID_PACKAGE = 'com.shubhlms.mobile';

const FINGERPRINT = /^([0-9A-F]{2}:){31}[0-9A-F]{2}$/;
const PACKAGE = /^[a-zA-Z][\w]*(\.[a-zA-Z][\w]*)+$/;

const list = (value: string | undefined) =>
  (value ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

export interface AssetLink {
  relation: string[];
  target: { namespace: 'android_app'; package_name: string; sha256_cert_fingerprints: string[] };
}

/** The statements to serve, or null when none are configured. Throws on a malformed value, so a typo fails at boot. */
export function assetLinks(env: NodeJS.ProcessEnv = process.env): AssetLink[] | null {
  const fingerprints = list(env.ANDROID_APP_LINK_SHA256).map((f) => f.toUpperCase());
  if (fingerprints.length === 0) return null;
  const bad = fingerprints.find((f) => !FINGERPRINT.test(f));
  if (bad) throw new Error(`ANDROID_APP_LINK_SHA256 has a value that is not a SHA-256 fingerprint (AA:BB:… 32 bytes): ${bad}`);
  const packages = list(env.ANDROID_APP_LINK_PACKAGES);
  const names = packages.length ? packages : [DEFAULT_ANDROID_PACKAGE];
  const badPackage = names.find((p) => !PACKAGE.test(p));
  if (badPackage) throw new Error(`ANDROID_APP_LINK_PACKAGES has a value that is not a package name: ${badPackage}`);
  return names.map((package_name) => ({
    relation: ['delegate_permission/common.handle_all_urls'],
    target: { namespace: 'android_app', package_name, sha256_cert_fingerprints: fingerprints },
  }));
}
