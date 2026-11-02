# Payment gateways (SAAS-017)

The platform takes subscription payments through a gateway that a Super Admin configures at runtime. No
gateway is set in source, `.env` or the browser.

## Architecture

```
business logic (checkout, webhooks, jobs, refunds)
        │  holds a PaymentProvider — never a concrete gateway
        ▼
lib/paymentGateways.ts   registry + factory
  activeProvider()        → the active gateway, for a NEW payment
  providerFor(name)       → the gateway RECORDED on an invoice / order / payment / refund
        │  decrypts the stored credentials (lib/credentialVault.ts) and builds the adapter, cached by version
        ▼
lib/razorpay.ts           RazorpayProvider  (the only code that knows Razorpay's URLs and payloads)
(VyaparGateway)           registered, not implemented — see "Supported gateways"
```

- `lib/paymentProvider.ts` holds the `PaymentProvider` interface. Every gateway implements it:
  - orders, fetching and capturing payments, refunds;
  - verifying checkouts and webhooks, and parsing webhooks into normalised events;
  - `checkoutParams`, and `testCredentials` where the gateway offers a check that moves no money.
- The backend decides the gateway, and nothing in a request names one.

## Supported gateways

| Gateway | Adapter | Credential fields (per environment) |
| --- | --- | --- |
| Razorpay | implemented | Key ID, Key secret, Webhook secret (separate from the key secret) |
| VyaparGateway | **not implemented** | API credential, Webhook secret (provisional) |

VyaparGateway's fields are the only ones it publicly confirms: server-side API credentials, and a webhook secret
for its HMAC-SHA256-signed webhooks.
- **It can:** be configured (stored encrypted), enabled and disabled.
- **It cannot:** be activated, tested, or receive webhooks.

Its public pages describe two different APIs, `POST /api/v1/create_order` and `POST /v1/intents`. Neither
documents the response fields, authentication, refunds, or what exactly the webhook signature covers. The full
reference is only in the merchant dashboard. The adapter is written once that contract is confirmed, and the
field names are corrected then if the contract names them differently. See `.claude/saas/progress.md` ›
Blocked.

## Adding a gateway

1. Write `lib/<gateway>.ts`, a class implementing `PaymentProvider`, and give it `testCredentials()` if the
   gateway offers a check that moves no money. It is the only file that may name the gateway's host.
2. Register it in `GATEWAYS` in `lib/paymentGateways.ts`. The entry needs:
   - its id and label;
   - `implemented: true`;
   - its credential `fields` (mark secrets `secret: true`);
   - `build(credentials, environment)`;
   - a `hint` that masks every non-secret field.
3. Add its id to the `provider` CHECK on `PaymentGatewayConfig` and `PaymentGatewayCredential` in a new migration.
4. If its checkout is not an embedded widget, return `redirectUrl` from `checkoutParams`. The web app's
   dispatcher follows `checkout.provider` and `redirectUrl`; it never chooses.
5. Test it with a stubbed `fetch`, as `lib/razorpay.test.ts` does, and run the switching suite
   (`routes/paymentGateways.test.ts`).

## Configuration and credential security

- `PAYMENT_CREDENTIALS_KEY` is the server's encryption master key, and the only payment setting in the
  environment. It is 32 bytes (`openssl rand -hex 32`). It is never entered in the panel.
- Without it, the panel still opens and the configuration form still shows. A save is refused with
  `503 SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED`, telling the server administrator to set it and restart the API.
- Each gateway has two credential slots, **test** and **live**, stored as separate rows. Saving one never touches
  the other.
  - A Razorpay key is refused in the wrong slot (`rzp_test_…` is test only).
  - The gateway's `environment` picks which slot new payments use.
  - Each checkout order records its environment, and is confirmed, reconciled and refunded with that slot.
  - Test and live webhooks share the gateway's URL; each verifies with its own slot's webhook secret.
- Credentials are sealed with AES-256-GCM under that key, with a fresh IV each time. Beside the ciphertext,
  the database stores the key's fingerprint, never the key.
- A value sealed under another key, or altered, is refused. It shows as "needs re-entry" in the panel.
- Replacing credentials (rotation) re-encrypts and replaces that slot's row in one transaction, audited as
  `gateway.credentials_replaced`. Existing payments are unchanged.
- A refused save is audited as `gateway.configuration_failed`, with the reason and no value.
- Secrets are write-only:
  - no response, log line or audit entry carries one;
  - the panel shows the key id's last four and which secrets are set;
  - saving with a secret left blank keeps the stored value.
- `RAZORPAY_*` in the environment is ignored. To move them into the database, run
  `npm run gateways:import-env -w @syniastrolms/api` once, then remove them.

## The active gateway

- It is enabled and has credentials for its environment (database CHECK and triggers), and at most one gateway
  is active (a unique index).
- A gateway that is disabled, unconfigured or not implemented cannot be activated. The panel shows why
  (`activationBlockedReason`).
- The active gateway may switch between test and live, only to an environment that has credentials. That
  affects new payments only.
- The active gateway cannot be disabled. Activate another gateway first, or turn online payment off on purpose (`POST /superadmin/payment-gateways/deactivate`). "No gateway" is
  supported: online checkout is then unavailable, and invoices are paid by hand.
- Every change is audited.

## Payment lifecycle and historical payments

1. The academy asks to pay an invoice, a plan change or a first purchase.
2. The server prices it from the invoice.
3. The invoice's first checkout pins it to the active gateway (`Invoice.provider`, set once). This is
   audited as `payment.provider_selected`.
4. The order is created through that gateway (`payment.created`).
5. The academy completes the gateway's checkout. The server finds the order within the academy and uses the
   order's gateway to verify the signature. It then reads the payment from that gateway, server to server
   (`payment.verified`).
6. The signed webhook for that gateway settles it idempotently (`webhook.accepted` or `webhook.rejected`).
7. The invoice is paid, the subscription moves, and entitlements follow.

Switching the active gateway affects only invoices that have not had a checkout yet. An invoice already started:
- keeps its gateway for further checkouts;
- is confirmed by that gateway;
- receives that gateway's webhooks;
- is refunded through that gateway.

This holds while the gateway's credentials are stored, even after it is disabled. The database refuses an
order through any other gateway (`PaymentOrder_invoice_gateway`).

A refund whose original gateway can no longer be used is refused with a 409 before anything is recorded.

## Webhook setup

Each gateway has its own URL: `https://<api host>/api/webhooks/<gateway>/subscription`. For Razorpay:
- enter that URL in the Razorpay dashboard;
- choose a webhook secret there and enter the same value as the webhook secret in the panel;
- enable `payment.authorized`, `payment.captured`, `payment.failed`, `order.paid`, `refund.processed` and
  `refund.failed`.

A webhook for a gateway with no stored credentials is 404.

## Testing

- `npm test -w @syniastrolms/api` runs everything with no network. A fixed test-only `PAYMENT_CREDENTIALS_KEY`
  is in `vitest.config.ts`.
- `lib/razorpay.test.ts` covers the Razorpay adapter over a stubbed HTTP layer, including the credential check.
- `routes/paymentGateways.test.ts` covers:
  - configuration, encryption and masking;
  - authorization;
  - the active-gateway rules and their database guards;
  - the real Razorpay adapter from stored credentials;
  - per-gateway webhooks;
  - key mismatch;
  - "no gateway";
  - switching between two fake gateways, with existing invoices staying on theirs;
  - refunds through the original gateway;
  - audit entries;
  - no secret in any response, log or audit entry.
- Tests install gateways with `setPaymentProvider(fake)` or `setPaymentProviders([a, b], 'a')`, never real
  credentials.
