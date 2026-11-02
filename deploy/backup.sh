#!/usr/bin/env bash
# Runs ON THE SERVER as the CloudPanel site user, from cron, once a day. Takes a consistent copy of the database and
# an archive of the uploaded media into <site>/data/backups/daily, keeping the newest 14 of each — a folder of its
# own, so the copies deploy.sh takes before each migration never push the daily ones out.
#
#   crontab -e  →  15 2 * * * /bin/bash <site>/app/deploy/backup.sh >> ~/backup.log 2>&1
#
# Both files hold personal data and password hashes: they are owner-only, and belong off this server too (copy
# <site>/data/backups/daily somewhere else regularly). They never go under the web root or into git.
set -euo pipefail

APP=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SITE=$(dirname "$APP")
DATA=$SITE/data
DAILY=$DATA/backups/daily
KEEP=${BACKUP_KEEP:-14}
# Cron runs with a minimal PATH; node, npm and npx live in /usr/bin on the CloudPanel image.
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
if [ -d "$HOME/.nvm/versions/node" ]; then
  PATH="$HOME/.nvm/versions/node/$(ls -1 "$HOME/.nvm/versions/node" | sort -V | tail -1)/bin:$PATH"
fi

umask 077
mkdir -p "$DAILY"
echo "[backup] $(date -u +%FT%TZ) $SITE"

cd "$APP/apps/api"
DB_BACKUP_DIR=$DAILY DB_BACKUP_KEEP=$KEEP npm run db:backup --silent

if [ -d "$DATA/uploads" ]; then
  STAMP=$(date -u +%Y%m%d-%H%M%S)
  tar -C "$DATA" -czf "$DAILY/uploads-$STAMP.tar.gz" uploads
  echo "[backup] ✓ uploads -> $DAILY/uploads-$STAMP.tar.gz ($(du -h "$DAILY/uploads-$STAMP.tar.gz" | cut -f1))"
  # shellcheck disable=SC2012
  ls -1t "$DAILY"/uploads-*.tar.gz | tail -n +$((KEEP + 1)) | xargs -r rm -f
fi
