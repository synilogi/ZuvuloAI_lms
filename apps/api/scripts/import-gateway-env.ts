/* Moves Razorpay credentials from the environment into the Super Admin's gateway configuration (SAAS-017),
 * once, for a deployment that ran with them in `.env` before gateways were configured from the panel.
 *
 *   PAYMENT_CREDENTIALS_KEY=… RAZORPAY_KEY_ID=… RAZORPAY_KEY_SECRET=… RAZORPAY_WEBHOOK_SECRET=… \
 *     npm run gateways:import-env -w @syniastrolms/api
 *
 * The credentials are sealed under PAYMENT_CREDENTIALS_KEY and stored encrypted; Razorpay is enabled and made
 * the active gateway, as it was when configured by environment (pass --no-activate to only store them). The
 * environment (test or live) follows the key id's prefix. Nothing secret is printed. Afterwards remove
 * PAYMENT_PROVIDER and every RAZORPAY_* variable from the environment: the server ignores them. */
import 'dotenv/config';

import { db } from '../src/lib/db.js';
import { activateGateway, configureGateway, updateGateway } from '../src/lib/paymentGateways.js';

const who = { type: 'system', job: 'import-gateway-env' } as const;

async function main() {
  const keyId = process.env.RAZORPAY_KEY_ID?.trim() ?? '';
  const keySecret = process.env.RAZORPAY_KEY_SECRET?.trim() ?? '';
  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET?.trim() ?? '';
  if (!keyId || !keySecret || !webhookSecret) {
    console.error('[gateways] Set RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET and RAZORPAY_WEBHOOK_SECRET (and PAYMENT_CREDENTIALS_KEY) to import them.');
    process.exitCode = 1;
    return;
  }
  const environment = keyId.startsWith('rzp_live_') ? 'live' : 'test';
  await configureGateway('razorpay', { environment, credentials: { keyId, keySecret, webhookSecret } }, who);
  console.log(`[gateways] Razorpay (${environment}) credentials stored encrypted.`);
  if (process.argv.includes('--no-activate')) return;
  await updateGateway('razorpay', { enabled: true, environment }, who);
  await activateGateway('razorpay', who);
  console.log('[gateways] Razorpay is enabled and active. Remove PAYMENT_PROVIDER and RAZORPAY_* from the environment now.');
}

main()
  .catch((err) => {
    console.error(`[gateways] ${err instanceof Error ? err.message : 'import failed'}`);
    process.exitCode = 1;
  })
  .finally(() => db.$disconnect());
