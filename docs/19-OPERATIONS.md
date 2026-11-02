# 19. Operations

How the live site is built, watched and shipped.

## Running it

Production runs one compiled file under plain node. `deploy.sh` builds `apps/api/dist/index.js` (`apps/api/scripts/build.mjs`), publishes it with Prisma's client as
`<site>/releases/api-<stamp>`, and points `<site>/api` at it. Only the build and the database scripts use the checkout's `node_modules`; the running API does not, so an
install or build cannot disturb it. The last three releases are kept: to roll back the code, point `<site>/api` at an older one and `pm2 reload`.

## Shipping it

`deploy/poll-deploy.sh` runs from cron every five minutes. When `origin/main` is ahead of the server and the `checks` job in `.github/workflows/ci.yml` has passed on that
commit, it runs `deploy.sh`. A commit CI has not passed is left alone, and a release that fails to deploy is not tried again (`<site>/deploy.failed`). The log is
`~/deploy-poll.log`, and the last deploy's is `~/deploy-last.log`.

`poll-deploy.sh` reads CI's result from GitHub's public API, so a private repository also needs a deploy key on the server and a token for that call.
The push webhook (`routes/deploy-webhook.ts`) still works if it is ever set up in GitHub, and needs no other change.

## Knowing something is wrong

| What | Where it goes |
| --- | --- |
| The site is down | `.github/workflows/uptime.yml` checks from outside every 15 minutes. GitHub emails the repository's owner when it fails |
| A failure on the server | Error-level signals (`lib/observe.ts`) go to `ALERT_WEBHOOK_URL` and `ALERT_EMAIL`, at most once per signal in 15 minutes. All are at Super Admin › System health |
| An error in a visitor's browser | Sent to `POST /public/client-errors` and shown as `client.error` with the other signals. At most five from one page load |

Alerts stay off until one of those two settings exists in `apps/api/.env`.

## Knowing who comes

Super Admin › Website › Visitors shows page views a day, the most visited pages, and how many get from a visit to a paid order. It counts public pages only, per page per
day (`SiteMetricDay`): no cookie, address or account, so it identifies nobody. Bots and browsers that ask not to be tracked are not counted. Since nobody is followed, page views
are not unique visitors, and the funnel compares totals rather than one person's path.

## Logs

PM2 writes to `~/logs/api.out.log` and `~/logs/api.error.log`. `pm2-logrotate` keeps them at 10 MB, compresses the old ones and holds 14.
