/**
 * Where to go after signing in: a same-site path from `?next=`, else the caller's fallback.
 *
 * The value arrives in the address bar, so anyone can put anything in it, and it is followed only
 * when it is a path on this site. A leading `//` is a protocol-relative URL, and so is a leading
 * backslash pair — a browser reads `/\example.test` as `//example.test` and leaves the site — so
 * both are refused, along with backslashes and control characters anywhere in the value.
 */
export function safeNext(next: string | null, fallback: string) {
  if (!next || !next.startsWith('/')) return fallback;
  if (next[1] === '/' || next[1] === '\\') return fallback;
  for (const ch of next) {
    const code = ch.codePointAt(0) ?? 0;
    if (ch === '\\' || code < 0x20 || code === 0x7f) return fallback;
  }
  return next;
}
