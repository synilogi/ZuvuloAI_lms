#!/usr/bin/env bash
# Local contract server (.claude/flutter/workflow.md §7.3): the REAL API from apps/api on a scratch
# SQLite database, for fixture capture and integration tests. It never touches apps/api's dev.db or
# test.db and writes only under $SCRATCH.
#
#   SCRATCH=/path/to/scratch tool/contract_server.sh start    migrate + seed (first time) and start
#   SCRATCH=/path/to/scratch tool/contract_server.sh seed     recreate the scratch database
#   SCRATCH=/path/to/scratch tool/contract_server.sh sync     match the current schema (no migration)
#   SCRATCH=/path/to/scratch tool/contract_server.sh superadmin  provision the platform Super Admin
#   SCRATCH=/path/to/scratch tool/contract_server.sh stop
#   SCRATCH=/path/to/scratch tool/contract_server.sh status
#
# ENTITLEMENT_ENFORCEMENT=on starts the server with plan enforcement live (off by default, as in
# production today), for checking the app's refusal states.
#
# Port 4100 (PORT to override). The Android emulator reaches it at http://10.0.2.2:4100.
set -euo pipefail

: "${SCRATCH:?set SCRATCH to a scratch directory (never apps/api)}"
PORT="${PORT:-4100}"
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
API="$ROOT/apps/api"
DIR="$SCRATCH/flutter-api"
DB="$DIR/flutter.db"
PID="$DIR/server.pid"
LOG="$DIR/server.log"

case "$(cd "$DIR" 2>/dev/null && pwd || echo "$DIR")" in
  "$API"*) echo "SCRATCH must not be inside apps/api" >&2; exit 2 ;;
esac

env_for_api() {
  # The rate limiter still runs; its window is raised because a test suite signs in far more often
  # than a person does (the app's handling of a real 429 is covered by unit tests).
  env DATABASE_URL="file:$DB" UPLOAD_DIR="$DIR/uploads" PORT="$PORT" LIVE_REMINDERS=off \
    NODE_ENV=development MAIL_TRANSPORT=outbox RATE_LIMIT_AUTH_MAX=2000 RATE_LIMIT_MAX=20000 \
    ENTITLEMENT_ENFORCEMENT="${ENTITLEMENT_ENFORCEMENT:-off}" "$@"
}

# Brings the scratch database in line with the CURRENT prisma/schema.prisma. While the backend is
# being worked on, the generated Prisma client can expect a column no migration has added yet, and
# every query then fails with a 500. This writes only to the scratch database — no migration files
# are created in apps/api — and never runs `prisma generate`, which is shared.
sync_schema() {
  (cd "$API" && env_for_api npx prisma db push --skip-generate --accept-data-loss >/dev/null)
}

# The platform Super Admin is deliberately not seeded: it is provisioned once per environment by
# apps/api/scripts/create-superadmin.ts with credentials from the environment. The app has to show
# its "not supported here" screen for that role (§6), so the contract database needs one. These
# values are for this scratch database only and match the seed's own demo password, which is
# already in apps/api/prisma/seed.ts; override them with SUPERADMIN_EMAIL / SUPERADMIN_PASSWORD.
superadmin() {
  (cd "$API" && env_for_api env \
    SUPERADMIN_EMAIL="${SUPERADMIN_EMAIL:-ops@syniastrolms.test}" \
    SUPERADMIN_PASSWORD="${SUPERADMIN_PASSWORD:-syniastrolms123}" \
    SUPERADMIN_NAME='Platform Operations' \
    npm run --silent superadmin:create)
}

seed() {
  mkdir -p "$DIR/uploads"
  rm -f "$DB" "$DB-journal"
  (cd "$API" && env_for_api npx prisma migrate deploy >/dev/null)
  (cd "$API" && env_for_api npm run --silent seed)
  # A fresh seed leaves academy admins with no permission grants; this is the documented one-time
  # step per environment (apps/api/scripts/backfill-admin-permissions.ts), so the scratch database
  # matches a real one.
  (cd "$API" && env_for_api npm run --silent permissions:backfill)
  superadmin
}

running() { [[ -f "$PID" ]] && kill -0 "$(cat "$PID")" 2>/dev/null; }

start() {
  if running; then echo "already running on :$PORT (pid $(cat "$PID"))"; return; fi
  # Another server (another session's, another scratch database) on this port would answer the
  # health check below and be mistaken for this one. Refuse instead; choose another PORT.
  if lsof -ti "tcp:$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "port $PORT is already in use by pid $(lsof -ti "tcp:$PORT" -sTCP:LISTEN | head -1) — not this scratch database's server; set PORT" >&2
    exit 1
  fi
  [[ -f "$DB" ]] || seed
  sync_schema
  (cd "$API" && env_for_api nohup npm start </dev/null >"$LOG" 2>&1 & echo $! >"$PID")
  for _ in $(seq 1 60); do
    if curl -fs "http://localhost:$PORT/health" >/dev/null; then
      echo "contract server ready on http://localhost:$PORT (pid $(cat "$PID"), log $LOG)"
      return
    fi
    sleep 1
  done
  echo "server did not become healthy; see $LOG" >&2
  exit 1
}

stop() {
  if running; then
    # npm start → tsx → node: stop the whole process group.
    pkill -TERM -P "$(cat "$PID")" 2>/dev/null || true
    kill -TERM "$(cat "$PID")" 2>/dev/null || true
    rm -f "$PID"
    echo "stopped"
  else
    echo "not running"
  fi
  # Anything still listening on the port from this workflow's database.
  for pid in $(lsof -ti "tcp:$PORT" -sTCP:LISTEN 2>/dev/null); do kill -TERM "$pid" 2>/dev/null || true; done
}

case "${1:-}" in
  start) start ;;
  sync) sync_schema; echo "scratch database matches prisma/schema.prisma" ;;
  seed) stop; seed ;;
  superadmin) superadmin ;;
  stop) stop ;;
  status) if running; then echo "running (pid $(cat "$PID"))"; else echo "stopped"; fi ;;
  *) echo "usage: SCRATCH=… $0 start|seed|sync|superadmin|stop|status" >&2; exit 2 ;;
esac
