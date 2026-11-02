#!/usr/bin/env bash
# Captures a REAL response from the local contract server as a test fixture
# (.claude/flutter/workflow.md §7.3). Signs in as a seeded role, calls the endpoint, scrubs tokens and
# e-mail addresses, and writes pretty JSON plus a note of the command beside it.
#
#   tool/capture_fixture.sh <METHOD> <path> <role> <out> [json-body]
#     role: none | admin | instructor | student
#     out:  path under test/fixtures/, e.g. catalog/levels.json
#
#   tool/capture_fixture.sh GET /catalog/levels none catalog/levels.json
set -euo pipefail

[[ $# -ge 4 ]] || { echo "usage: $0 METHOD path role out [json-body]" >&2; exit 2; }
METHOD="$1"; PATH_="$2"; ROLE="$3"; OUT="$4"; BODY="${5:-}"
BASE="${API_BASE:-http://localhost:${PORT:-4100}}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$HERE/test/fixtures/$OUT"

# The seed's demo accounts (apps/api/prisma/seed.ts) — local scratch database only.
DEMO_PASSWORD='syniastrolms123'
case "$ROLE" in
  none) EMAIL='' ;;
  admin) EMAIL='admin@syniastrolms.test' ;;
  instructor) EMAIL='meenakshi@syniastrolms.test' ;;
  student) EMAIL='ananya@syniastrolms.test' ;;
  *) echo "unknown role: $ROLE" >&2; exit 2 ;;
esac

AUTH=()
if [[ -n "$EMAIL" ]]; then
  TOKEN="$(curl -fs -X POST "$BASE/auth/login" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$DEMO_PASSWORD\"}" |
    node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.parse(s).token))')"
  AUTH=(-H "Authorization: Bearer $TOKEN")
fi

ARGS=(-s -o /dev/stdout -w '\n%{http_code}' -X "$METHOD" "$BASE$PATH_" -H 'Accept: application/json')
[[ -n "$BODY" ]] && ARGS+=(-H 'Content-Type: application/json' -d "$BODY")
RAW="$(curl "${ARGS[@]}" ${AUTH[@]+"${AUTH[@]}"})"
STATUS="${RAW##*$'\n'}"
PAYLOAD="${RAW%$'\n'*}"

mkdir -p "$(dirname "$TARGET")"
printf '%s' "$PAYLOAD" | node -e '
  let s = "";
  process.stdin.on("data", (d) => (s += d)).on("end", () => {
    const scrub = (v) => {
      if (typeof v === "string") {
        return v
          .replace(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g, "<token>")
          .replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, "user@example.test");
      }
      if (Array.isArray(v)) return v.map(scrub);
      if (v && typeof v === "object") {
        return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, /^(token|password|secret)$/i.test(k) ? "<redacted>" : scrub(x)]));
      }
      return v;
    };
    process.stdout.write(JSON.stringify(scrub(JSON.parse(s)), null, 2) + "\n");
  });
' >"$TARGET"

cat >"$TARGET.cmd.txt" <<NOTE
Captured $(date -u +%Y-%m-%dT%H:%M:%SZ) from the local contract server (real API, scratch database, seed data).
Command: tool/capture_fixture.sh $METHOD $PATH_ $ROLE $OUT${BODY:+ '$BODY'}
HTTP status: $STATUS
Tokens and e-mail addresses scrubbed.
NOTE
echo "$STATUS $TARGET"
