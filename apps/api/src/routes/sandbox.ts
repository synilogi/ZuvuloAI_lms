import { Router } from 'express';

import { asyncHandler, notFound } from '../lib/errors.js';
import { deliverSandboxWebhook, sandboxEnabled, sandboxProvider } from '../lib/sandboxGateway.js';
import { parseBody, z } from '../lib/validate.js';

/*
 * `/sandbox` — the sandbox gateway's own side (SAAS-030): what its hosted test checkout page calls. Development and
 * tests only: every route is not found unless `PAYMENT_SANDBOX=on` outside production. These routes play the
 * gateway, so they carry no session — like a real gateway's page, an order is reached by its unguessable id — and
 * they change nothing on the platform directly: the outcome reaches the platform only as a signed webhook.
 */
export const sandboxRouter = Router();

sandboxRouter.use((_req, _res, next) => (sandboxEnabled() ? next() : next(notFound())));

sandboxRouter.get(
  '/orders/:orderId',
  asyncHandler(async (req, res) => {
    const order = sandboxProvider.order(req.params.orderId);
    if (!order) throw notFound('No such order at the sandbox gateway.');
    res.json(order);
  }),
);

/** The payer pays or is declined. The gateway then tells the platform, by signed webhook, before answering. */
sandboxRouter.post(
  '/orders/:orderId/pay',
  asyncHandler(async (req, res) => {
    const { outcome } = parseBody(req, z.object({ outcome: z.enum(['success', 'failure']) }));
    if (!sandboxProvider.order(req.params.orderId)) throw notFound('No such order at the sandbox gateway.');
    const { payment, webhook } = sandboxProvider.pay(req.params.orderId, outcome);
    let delivered = false;
    try {
      delivered = (await deliverSandboxWebhook(webhook)).status === 200;
    } catch {
      // A gateway whose webhook does not land leaves it to the platform's reconciliation, as a real one would.
    }
    res.json({ paymentId: payment.providerPaymentId, status: payment.status, webhookDelivered: delivered });
  }),
);
