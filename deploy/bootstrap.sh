#!/usr/bin/env bash
# Runs ON THE SERVER, once per site, as that site's CloudPanel user. No root anywhere:
# CloudPanel owns nginx, TLS and the vhost that proxies the site to 127.0.0.1:<PORT>; this
# script only prepares what lives under the site directory and this user's PM2.
#
# Self-contained, so it can be copied up before the repo exists on the box:
#     scp deploy/bootstrap.sh <user>@<host>:~/
#     ssh <user>@<host> 'SITE=/home/<group>/htdocs/<domain> PUBLIC=https://<domain> PORT=<port> \
#                        BRANCH=<branch> TRUST_PROXY=<hops> ./bootstrap.sh'
#
# Safe to re-run: every step checks before it acts. It never touches data/ or an existing .env.
set -euo pipefail

: "${SITE:?SITE=/home/<group>/htdocs/<domain> is required}"
: "${PUBLIC:?PUBLIC=https://<domain> is required}"
: "${PORT:?PORT=<the port the CloudPanel vhost proxies to> is required}"
: "${DB_USER:?DB_USER=<the site's MySQL user> is required}"
: "${DB_NAME:?DB_NAME=<the site's MySQL database> is required}"
: "${DB_PASSWORD:?DB_PASSWORD=<percent-encoded for an address: @ is %40, # is %23> is required}"
BRANCH=${BRANCH:-master}
TRUST_PROXY=${TRUST_PROXY:-1}
PM2_NAME=${PM2_NAME:-$(basename "$SITE")-api}
APP=$SITE/app
REPO=${REPO:-https://github.com/synilogi/ZuvuloAI_lms.git}
KEY=${KEY:-$HOME/.ssh/id_ed25519_deploy_$(basename "$SITE")}

log()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
skip() { printf '    \033[2m(already done: %s)\033[0m\n' "$*"; }

[ -w "$SITE" ] || { echo "$SITE is not writable by $(id -un) — this must run as the site user."; exit 1; }
command -v node >/dev/null && command -v pm2 >/dev/null || { echo "node and pm2 must be on PATH (CloudPanel installs both)."; exit 1; }
echo "node $(node -v), pm2 $(pm2 -v), user $(id -un)"
echo "site $SITE · $PUBLIC · port $PORT · branch $BRANCH · pm2 $PM2_NAME · trust_proxy $TRUST_PROXY"

log "Directory layout"
# data/ holds what is not in MySQL: uploaded media and database backups. Deploys
# replace app/ wholesale and must never reach into data/. Nothing under this site is
# served by nginx directly (the vhost proxies everything), so data/ is not web-exposed.
mkdir -p "$SITE/data/uploads" "$SITE/releases"
printf 'BRANCH=%s\nPM2_NAME=%s\n' "$BRANCH" "$PM2_NAME" > "$SITE/deploy.conf"
rm -f "$SITE/BRANCH"
echo "    wrote $SITE/deploy.conf"

log "GitHub deploy key"
mkdir -p ~/.ssh && chmod 700 ~/.ssh
if [ -f "$KEY" ]; then skip "$KEY"; else ssh-keygen -t ed25519 -N '' -C "deploy-$(basename "$SITE")@$(hostname)" -f "$KEY" >/dev/null; fi
if ! grep -qs "IdentityFile $KEY" ~/.ssh/config; then
  printf 'Host github.com\n    IdentityFile %s\n    IdentitiesOnly yes\n' "$KEY" >> ~/.ssh/config
fi
chmod 600 ~/.ssh/config
ssh-keygen -F github.com >/dev/null 2>&1 || ssh-keyscan -t ed25519,rsa github.com >> ~/.ssh/known_hosts 2>/dev/null

log "Cloning $REPO ($BRANCH)"
if [ -d "$APP/.git" ]; then
  skip "$APP is already a checkout"
elif [[ "$REPO" == https://* ]] || ssh -o BatchMode=yes -T git@github.com 2>&1 | grep -q 'successfully authenticated'; then
  git clone --branch "$BRANCH" "$REPO" "$APP"
else
  cat <<KEYMSG

    The deploy key is not registered yet. Add this as a READ-ONLY deploy key at
    https://github.com/synilogi/ZuvuloAI_lms/settings/keys/new
    (leave "Allow write access" unchecked), then re-run this script.

$(cat "$KEY.pub")

KEYMSG
  exit 0
fi

log "apps/api/.env"
ENV=$APP/apps/api/.env
if [ -f "$ENV" ]; then
  skip "$ENV"
else
  sed -e "s|__SITE__|$SITE|g" -e "s|__PUBLIC__|$PUBLIC|g" -e "s|__PORT__|$PORT|g" \
      -e "s|__BRANCH__|$BRANCH|g" -e "s|__TRUST_PROXY__|$TRUST_PROXY|g" \
      -e "s|__DB_USER__|$DB_USER|g" -e "s|__DB_NAME__|$DB_NAME|g" -e "s|__DB_PASSWORD__|$DB_PASSWORD|g" \
      -e "s|__JWT_SECRET__|$(openssl rand -hex 32)|" -e "s|__WEBHOOK_SECRET__|$(openssl rand -hex 32)|" \
      -e "s|__PAYMENT_CREDENTIALS_KEY__|$(openssl rand -hex 32)|" \
      "$APP/deploy/api.env.example" > "$ENV"
  chmod 600 "$ENV"
  echo "    written with fresh JWT_SECRET, DEPLOY_WEBHOOK_SECRET and PAYMENT_CREDENTIALS_KEY"
fi

log "PM2 survives a reboot"
# No root, so no systemd unit: cron restores the saved process list at boot instead.
LINE="@reboot $(command -v pm2) resurrect >/dev/null 2>&1"
if crontab -l 2>/dev/null | grep -qF 'pm2 resurrect'; then
  skip "crontab @reboot"
else
  { crontab -l 2>/dev/null || true; echo "$LINE"; } | crontab -
  echo "    added: $LINE"
fi

cat <<NEXT

Bootstrapped. Next:  $APP/deploy/deploy.sh

Email: set MAIL_TRANSPORT=smtp and SMTP_HOST / SMTP_USER / SMTP_PASS / MAIL_FROM in $ENV — until then
registration codes, password resets and invitations are stored but never sent.

Continuous deploy — two GitHub-side steps (Settings of synilogi/ZuvuloAI_lms):
  1. Deploy keys -> add (read-only):   $(cat "$KEY.pub")
  2. Webhooks -> add:  Payload URL $PUBLIC/api/deploy/webhook, content type application/json,
                       secret = DEPLOY_WEBHOOK_SECRET from $ENV, "Just the push event".
     Pushes to "$BRANCH" then deploy themselves; the log is ~/deploy-webhook.log.

NEXT
