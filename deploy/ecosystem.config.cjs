/* PM2 process definition for the ZuviloAI API, run as the CloudPanel site user.
 *
 * Site-agnostic: the site root is this file's grandparent (…/<site>/app/deploy/), the process
 * name comes from PM2_NAME in the environment or <site>/deploy.conf (written by bootstrap.sh),
 * defaulting to "<site dir name>-api", and logs go to the user's CloudPanel logs directory.
 *
 * The API runs as one compiled bundle under plain node (apps/api/scripts/build.mjs), so production
 * needs none of the development tools at run time.
 */
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const APP = path.resolve(__dirname, '..');
const SITE = path.dirname(APP);

function confValue(key) {
  try {
    const m = fs.readFileSync(path.join(SITE, 'deploy.conf'), 'utf8').match(new RegExp(`^${key}=(.*)$`, 'm'));
    return m ? m[1].trim().replace(/^"(.*)"$/, '$1') : undefined;
  } catch {
    return undefined;
  }
}

const name = process.env.PM2_NAME || confValue('PM2_NAME') || `${path.basename(SITE)}-api`;
const logs = path.join(os.homedir(), 'logs');

module.exports = {
  apps: [
    {
      name,
      // The checkout's apps/api, for its .env. The code is the compiled release deploy.sh points <site>/api at, so a build or an
      // install in the checkout cannot disturb the running API.
      cwd: path.join(APP, 'apps', 'api'),
      script: path.join(SITE, 'api', 'index.js'),
      // The node running PM2, by absolute path: the @reboot cron has a minimal PATH, and CloudPanel keeps node under the user's nvm.
      interpreter: process.execPath,
      // One instance: the notification scheduler in src/index.ts is in-process. Scaling out means LIVE_REMINDERS=off on the others.
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '20s',
      max_memory_restart: '600M',
      // src/index.ts lets requests in flight finish on SIGINT (at most 8 s) before exiting; PM2's default is 1.6 s.
      kill_timeout: 10000,
      env: { NODE_ENV: 'production' },
      error_file: path.join(logs, 'api.error.log'),
      out_file: path.join(logs, 'api.out.log'),
      merge_logs: true,
      time: true,
    },
  ],
};
