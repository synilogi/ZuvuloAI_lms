#!/usr/bin/env bash
# Runs ON THE SERVER as the CloudPanel site user. Pulls the configured branch and ships it.
# Site-agnostic: the site root is this script's grandparent (…/<site>/app/deploy/deploy.sh),
# per-site settings come from <site>/deploy.conf (BRANCH, PM2_NAME) and apps/api/.env (PORT,
# APP_URL). The same branch therefore serves every site on the box.
#
#   <site>/app/deploy/deploy.sh
#   BRANCH=master <site>/app/deploy/deploy.sh    another branch, this run only
#   SKIP_FETCH=1  <site>/app/deploy/deploy.sh    ship the current checkout without fetching
#                                                 (first deploy seeded over ssh, or a rollback)
set -euo pipefail

# CloudPanel keeps node under the site user's nvm, which a non-interactive shell does not load.
if ! command -v node >/dev/null && [ -d "$HOME/.nvm/versions/node" ]; then
  PATH="$HOME/.nvm/versions/node/$(ls -1 "$HOME/.nvm/versions/node" | sort -V | tail -1)/bin:$PATH"
fi

APP=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SITE=$(dirname "$APP")
DATA=$SITE/data
RELEASES=$SITE/releases
KEEP=3

log() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
envval() { sed -nE "s/^$1=\"?([^\"]*)\"?[[:space:]]*$/\1/p" "$APP/apps/api/.env" | head -1; }

[ -d "$APP/.git" ] || { echo "$APP is not a git checkout — run bootstrap.sh first."; exit 1; }
[ -f "$APP/apps/api/.env" ] || { echo "Missing $APP/apps/api/.env — bootstrap.sh writes it."; exit 1; }

# deploy.conf is written by bootstrap.sh and never tracked; the BRANCH file is the older layout.
# A BRANCH given to this run (by hand, or by the webhook naming the branch that was pushed) wins
# over deploy.conf's — sourcing the file used to overwrite it, so the override never took effect.
RUN_BRANCH=${BRANCH:-}
# shellcheck disable=SC1091
[ -f "$SITE/deploy.conf" ] && . "$SITE/deploy.conf"
BRANCH=${RUN_BRANCH:-${BRANCH:-$(cat "$SITE/BRANCH" 2>/dev/null || echo master)}}
PM2_NAME=${PM2_NAME:-$(basename "$SITE")-api}
PORT=$(envval PORT); PORT=${PORT:-4000}
PUBLIC=$(envval APP_URL); PUBLIC=${PUBLIC:-$(envval CORS_ORIGIN)}
[ -n "$PUBLIC" ] || { echo "APP_URL (or CORS_ORIGIN) must be set in apps/api/.env"; exit 1; }
echo "site $SITE · branch $BRANCH · pm2 $PM2_NAME · port $PORT · $PUBLIC"

mkdir -p "$DATA/uploads" "$RELEASES"

# One deploy at a time per site. A webhook-triggered run and a manual one would otherwise race
# each other through the same checkout, build directory and PM2 reload.
exec 9>"$SITE/deploy.lock"
if ! flock -n 9; then
  echo "Another deploy of this site is already running (lock: $SITE/deploy.lock)."
  exit 1
fi

log "Fetching origin/$BRANCH"
cd "$APP"
BEFORE=$(git rev-parse HEAD)
if [ "${SKIP_FETCH:-0}" = 1 ]; then
  echo "    SKIP_FETCH=1 — deploying the current checkout"
else
  git fetch --prune origin
  # GitHub fires the push webhook before the new commit is always readable by a fetch, so a
  # webhook-triggered run names the commit it was told about and waits briefly for it to appear.
  if [ -n "${DEPLOY_EXPECT_SHA:-}" ]; then
    for i in $(seq 1 20); do
      [ "$(git rev-parse "origin/$BRANCH")" = "$DEPLOY_EXPECT_SHA" ] && break
      echo "    origin/$BRANCH is not yet at ${DEPLOY_EXPECT_SHA:0:7} (attempt $i), waiting…"
      sleep 3
      git fetch --prune origin
    done
    # A later push may have moved the branch past the named commit — its tip is then the right
    # thing to ship. A commit the branch does not contain at all means this run is pointed at the
    # wrong branch, and shipping that branch would quietly replace the site with other code.
    if [ "$(git rev-parse "origin/$BRANCH")" != "$DEPLOY_EXPECT_SHA" ]; then
      if git merge-base --is-ancestor "$DEPLOY_EXPECT_SHA" "origin/$BRANCH" 2>/dev/null; then
        echo "    origin/$BRANCH has moved past ${DEPLOY_EXPECT_SHA:0:7}; deploying its current tip."
      else
        echo "origin/$BRANCH does not contain ${DEPLOY_EXPECT_SHA:0:7} — not deploying. Is BRANCH in $SITE/deploy.conf the branch that was pushed?"
        exit 1
      fi
    fi
  fi
  # reset --hard, not pull: the server's checkout is disposable and must match the branch
  # exactly, with no chance of a merge commit or a conflict stopping a deploy at 2am.
  # It leaves untracked and ignored files alone, which is how apps/api/.env survives —
  # so never add `git clean` here.
  git checkout -q -B "$BRANCH" "origin/$BRANCH"
  git reset -q --hard "origin/$BRANCH"
fi
AFTER=$(git rev-parse HEAD)
echo "    $BEFORE -> $AFTER"
git --no-pager log -1 --format='    %h %s (%an, %ar)'

log "Installing dependencies"
# npm ci is the slowest step by far, so it only runs when the lockfile differs from the one
# the current node_modules was installed from. The stamp is written after a successful
# install only — an interrupted install leaves none and is redone.
STAMP_FILE=$APP/node_modules/.package-lock.sha256
LOCK_SUM=$(sha256sum "$APP/package-lock.json" | cut -d' ' -f1)
if [ -f "$STAMP_FILE" ] && [ "$(cat "$STAMP_FILE")" = "$LOCK_SUM" ]; then
  echo "    package-lock.json unchanged since the last install, skipping npm ci"
else
  # --include=dev: the build (vite) and the API itself (tsx, prisma) run on devDependencies, and npm drops them
  # whenever NODE_ENV=production is set in the calling environment.
  npm ci --include=dev --no-audit --fund=false
  echo "$LOCK_SUM" > "$STAMP_FILE"
fi

# Built before anything touches the database: it is the slow step, and the running release keeps
# serving on the old schema until the migration below. Keeping migrate → restart short keeps short
# the window in which the old process runs against a schema it was not built for.
log "Building the web app"
cd "$APP/apps/web"
VITE_API_MODE=http VITE_API_BASE_URL="$PUBLIC/api" npm run build

log "Generating the Prisma client"
cd "$APP/apps/api"
npx prisma generate

log "Backing up the database"
# A consistent copy (mysqldump, gzipped) under $DATA/backups, owner-only, newest DB_BACKUP_KEEP kept — taken before
# every migration so a bad release can be rolled back with its data. A failed backup stops the deploy here,
# before anything has changed. Copy these off the server too; they never belong in git or under the web root.
DB_BACKUP_DIR=${DB_BACKUP_DIR:-$DATA/backups} npm run db:backup --silent

log "Applying database migrations"
# migrate deploy only applies committed migrations; it never resets or drops data.
npx prisma migrate deploy


# No permission backfill here. It gave every admin the whole catalogue on every deploy, which quietly
# restored any permission a Super Admin had taken away. Admins from before permissions existed were
# backfilled by earlier deploys, and every admin created since (new academy, Super Admin) is granted the
# catalogue when created. Run `npm run permissions:backfill` by hand only after the catalogue gains a key.

log "Ensuring the platform's starting configuration"
# The workspace and the Help Centre — added only where missing, never edited or deleted.
# Never the demo seed: that one deletes academy data and refuses to run in production.
npm run seed:platform --silent

log "Publishing the build"
STAMP=$(date -u +%Y%m%d%H%M%S)
cp -r "$APP/apps/web/dist" "$RELEASES/web-$STAMP"
# The API serves WEB_DIST=$SITE/web; a symlink swap means it never sees a half-copied build.
ln -sfn "$RELEASES/web-$STAMP" "$SITE/web.new"
mv -Tf "$SITE/web.new" "$SITE/web"
# shellcheck disable=SC2012
ls -1dt "$RELEASES"/web-* | tail -n +$((KEEP + 1)) | xargs -r rm -rf

log "Publishing Android App Links"
# CloudPanel's vhost answers /.well-known/ from the site root and never forwards it to the API, so the file
# Android checks is written there, from ANDROID_APP_LINK_SHA256 in apps/api/.env (removed when unset).
(cd "$APP/apps/api" && APP_LINKS_DIR="$SITE/.well-known" npm run app-links:publish --silent)

log "Restarting the API ($PM2_NAME)"
cd "$SITE"
export PM2_NAME
if pm2 describe "$PM2_NAME" >/dev/null 2>&1; then
  pm2 reload "$APP/deploy/ecosystem.config.cjs" --update-env
else
  pm2 start "$APP/deploy/ecosystem.config.cjs"
fi
pm2 save --force >/dev/null

log "Health check"
HOST=${PUBLIC#https://}; HOST=${HOST#http://}
for i in $(seq 1 20); do
  if curl -fs -m 5 "http://127.0.0.1:$PORT/api/health" >/dev/null; then
    echo "    API healthy after ${i}s"
    # Through the local vhost too, so a CloudPanel-side problem shows up here, not in a browser.
    CODE=$(curl -sk -m 10 -o /dev/null -w '%{http_code}' --resolve "$HOST:443:127.0.0.1" "$PUBLIC/" || true)
    echo "    vhost -> HTTP $CODE for $PUBLIC/"
    pm2 status "$PM2_NAME"
    exit 0
  fi
  sleep 1
done

echo "API did not answer /api/health within 20s. Recent log:" >&2
pm2 logs "$PM2_NAME" --lines 40 --nostream >&2
exit 1
