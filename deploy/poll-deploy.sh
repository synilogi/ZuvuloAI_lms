#!/usr/bin/env bash
# Runs ON THE SERVER from cron, as the site user, every five minutes. Ships a new commit on the deployed branch once CI has passed on it:
#
#   crontab -e  ->  */5 * * * * /bin/bash <site>/app/deploy/poll-deploy.sh >> ~/deploy-poll.log 2>&1
#
# Reaches out rather than waiting to be called, so it needs no webhook or repository setting. It only ever moves forward: a commit that
# CI has not passed, or that is not ahead of what runs now, is left alone. A release that fails to deploy is not tried again.
set -euo pipefail

if [ -d "$HOME/.nvm/versions/node" ]; then
  PATH="$HOME/.nvm/versions/node/$(ls -1 "$HOME/.nvm/versions/node" | sort -V | tail -1)/bin:$PATH"
fi
APP=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SITE=$(dirname "$APP")
BRANCH=main
# shellcheck disable=SC1091
[ -f "$SITE/deploy.conf" ] && . "$SITE/deploy.conf"
FAILED=$SITE/deploy.failed

cd "$APP"
git fetch -q origin "$BRANCH"
HERE=$(git rev-parse HEAD)
THERE=$(git rev-parse "origin/$BRANCH")
[ "$HERE" = "$THERE" ] && exit 0
git merge-base --is-ancestor "$HERE" "$THERE" || { echo "$(date -u +%FT%TZ) origin/$BRANCH is not ahead of $HERE: leaving it alone"; exit 0; }
[ "$(cat "$FAILED" 2>/dev/null || true)" = "$THERE" ] && exit 0

REPO=$(git remote get-url origin | sed -E 's#^.*github\.com[:/]##; s#\.git$##')
STATE=$(curl -fsS -m 20 -H 'Accept: application/vnd.github+json' "https://api.github.com/repos/$REPO/commits/$THERE/check-runs" | node -e '
  const runs = JSON.parse(require("fs").readFileSync(0, "utf8")).check_runs ?? [];
  const ci = runs.filter((r) => r.name === "checks");
  console.log(ci.length === 0 ? "none" : ci.every((r) => r.conclusion === "success") ? "passed" : ci.some((r) => r.status !== "completed") ? "running" : "failed");
') || STATE=unknown
[ "$STATE" = passed ] || { echo "$(date -u +%FT%TZ) $THERE: CI $STATE, not deploying"; exit 0; }

echo "$(date -u +%FT%TZ) deploying $THERE"
if BRANCH=$BRANCH bash "$APP/deploy/deploy.sh" > "$HOME/deploy-last.log" 2>&1; then
  rm -f "$FAILED"
  echo "$(date -u +%FT%TZ) deployed $THERE"
else
  echo "$THERE" > "$FAILED"
  echo "$(date -u +%FT%TZ) deploy of $THERE FAILED: see ~/deploy-last.log"
  exit 1
fi
