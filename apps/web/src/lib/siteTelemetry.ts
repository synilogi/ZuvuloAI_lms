import { countedPath } from '@syniastrolms/domain';
import { API_MODE } from '@/lib/apiMode';
import { API_BASE_URL } from '@/services/http/client';

/*
 * What the website tells its own server (docs/19), and nothing else does: which public page was opened, and that something broke. No cookie,
 * no identifier and no third party. A browser asking not to be tracked sends no page views. Neither call may ever disturb the page.
 */

const send = (path: string, body: unknown) => {
  if (API_MODE !== 'http') return;
  void fetch(`${API_BASE_URL}${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body), keepalive: true }).catch(
    () => undefined,
  );
};

/** Whether this browser asks not to be tracked. */
export function asksNotToBeTracked(nav: { doNotTrack?: string | null; globalPrivacyControl?: boolean } = navigator as never): boolean {
  return nav.doNotTrack === '1' || nav.globalPrivacyControl === true;
}

export function countVisit(pathname: string) {
  const path = countedPath(pathname);
  if (path && !asksNotToBeTracked()) send('/public/metrics', { path });
}

const MAX_REPORTS = 5;
const reported = new Set<string>();

/** Whether this error should be reported: each once, and only a few from one page load, so a loop cannot flood the server. */
export function firstReport(message: string, seen: Set<string> = reported, limit = MAX_REPORTS): boolean {
  if (seen.has(message) || seen.size >= limit) return false;
  seen.add(message);
  return true;
}

const report = (message: string, source?: string) => {
  const text = message.slice(0, 500);
  if (firstReport(text))
    send('/public/client-errors', { message: text, ...(source ? { source: source.slice(0, 300) } : {}), path: window.location.pathname.slice(0, 300) });
};

/** Reports what nothing else caught. Called once, before the app renders. */
export function watchForErrors() {
  window.addEventListener('error', (e) => report(e.message || 'Script error', e.filename));
  window.addEventListener('unhandledrejection', (e) => {
    const reason = e.reason as { message?: unknown } | undefined;
    report(typeof reason?.message === 'string' ? reason.message : String(e.reason));
  });
}
