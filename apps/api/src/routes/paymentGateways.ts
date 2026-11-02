import { Router } from 'express';

import { asyncHandler } from '../lib/errors.js';
import { activateGateway, configureGateway, deactivateActiveGateway, getGateway, listGateways, testGateway, updateGateway } from '../lib/paymentGateways.js';
import { parseBody, z } from '../lib/validate.js';

/*
 * The platform's payment gateways (docs/16, D-PLAT-07): course money settles to the gateway a Super Admin configures
 * here. Mounted inside the Super Admin router, so `requireSuperAdmin` and the platform context already apply. What
 * leaves here is only what the panel may show — enabled, configured, active, environment and a masked hint; a
 * credential is write-only, and a blank secret on save keeps the stored one. `:provider` is checked against the
 * registry by the service: an unknown one is 404.
 */
export const paymentGatewaysRouter = Router();

paymentGatewaysRouter.get(
  '/payment-gateways',
  asyncHandler(async (_req, res) => {
    res.json(await listGateways());
  }),
);

paymentGatewaysRouter.post(
  '/payment-gateways/deactivate',
  asyncHandler(async (req, res) => {
    res.json(await deactivateActiveGateway(req));
  }),
);

paymentGatewaysRouter.get(
  '/payment-gateways/:provider',
  asyncHandler(async (req, res) => {
    res.json(await getGateway(req.params.provider));
  }),
);

paymentGatewaysRouter.post(
  '/payment-gateways/:provider/config',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({ environment: z.enum(['test', 'live']), credentials: z.record(z.string().max(64), z.string().max(500).optional()).default({}) }),
    );
    res.json(await configureGateway(req.params.provider, input, req));
  }),
);

paymentGatewaysRouter.patch(
  '/payment-gateways/:provider',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ enabled: z.boolean().optional(), environment: z.enum(['test', 'live']).optional() }));
    res.json(await updateGateway(req.params.provider, input, req));
  }),
);

/** Checks the stored credentials with the gateway, server to server. Nothing is charged; a failure is reported as one. */
paymentGatewaysRouter.post(
  '/payment-gateways/:provider/test',
  asyncHandler(async (req, res) => {
    const { environment } = parseBody(req, z.object({ environment: z.enum(['test', 'live']).optional() }));
    res.json(await testGateway(req.params.provider, req, environment));
  }),
);

paymentGatewaysRouter.post(
  '/payment-gateways/:provider/activate',
  asyncHandler(async (req, res) => {
    res.json(await activateGateway(req.params.provider, req));
  }),
);
