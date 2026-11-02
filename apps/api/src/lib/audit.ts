/* The platform audit trail.
 *
 * Sensitive operations that change something call `recordAuditLog` so there is a record of who did
 * it. Reads are not audited — a trail of every list request buries the events that matter. A person
 * is taken from the token, never from the body or the query, the same rule `lib/scope.ts` states.
 *
 * Not everything is done by a person (§36): the scheduler expires trials and applies downgrades, the
 * payment provider confirms and fails payments. Those events are written too, and name themselves as
 * what they are — `actorType` `system` with the job, or `provider` with the provider — rather than
 * borrowing a person. The trail is append-only: the database refuses an update or a delete (trigger
 * AuditLog_append_only), except the foreign key clearing `actorId` when an account is removed. */
import type { Request } from 'express';

import { db, type DbClient } from './db.js';
import { writeJson } from './json.js';
import { runAsPlatform } from './tenancy.js';

/**
 * The trail's vocabulary, as `subject.verb`. Written today: `admin.*`, the plan events in
 * `PLAN_AUDIT_ACTIONS` (`lib/plans.ts`, with `entitlement.changed` and `limit.changed`), and the billing
 * events in `BILLING_AUDIT_ACTIONS`. The two permission actions are defined here for the management API
 * that will write them; nothing writes them yet, and neither the migration nor the backfill records an event.
 */
export const PERMISSION_AUDIT_ACTIONS = { granted: 'admin.permissions.granted', revoked: 'admin.permissions.revoked' } as const;

/**
 * Subscriptions, invoices and payments (§36). Every one is written in the same transaction as the change
 * it records, whoever made it: a person, the scheduler (`system`) or the payment provider (`provider`).
 */
export const BILLING_AUDIT_ACTIONS = {
  subscriptionCreated: 'subscription.created',
  subscriptionActivated: 'subscription.activated',
  subscriptionRenewed: 'subscription.renewed',
  subscriptionRecovered: 'subscription.recovered',
  subscriptionPastDue: 'subscription.past_due',
  subscriptionGraceStarted: 'subscription.grace_started',
  subscriptionTrialExpired: 'subscription.trial_expired',
  subscriptionExpired: 'subscription.expired',
  subscriptionPlanChangeRequested: 'subscription.plan_change_requested',
  subscriptionPlanChangeCanceled: 'subscription.plan_change_canceled',
  /** An open plan change closed without applying: its quote expired, or the subscription changed under it. */
  subscriptionPlanChangeClosed: 'subscription.plan_change_closed',
  subscriptionPlanChanged: 'subscription.plan_changed',
  subscriptionCancelRequested: 'subscription.cancel_requested',
  subscriptionCanceled: 'subscription.canceled',
  subscriptionResumed: 'subscription.resumed',
  subscriptionPaused: 'subscription.paused',
  /** A super admin gave complimentary days: the period ends later, at no charge. */
  subscriptionExtended: 'subscription.extended',
  /** An academy gains or loses its plan's entitlements: it entered or left an entitled status, or moved plan version. */
  entitlementChanged: 'entitlement.changed',
  invoiceCreated: 'invoice.created',
  invoicePaid: 'invoice.paid',
  invoiceFailed: 'invoice.failed',
  invoiceVoided: 'invoice.voided',
  paymentSucceeded: 'payment.succeeded',
  /** A super admin recorded a payment received outside the gateway (bank transfer, cash, cheque, UPI). */
  paymentRecordedOffline: 'payment.recorded_offline',
  paymentFailed: 'payment.failed',
  paymentRefundRequested: 'payment.refund_requested',
  paymentRefunded: 'payment.refunded',
  paymentRefundFailed: 'payment.refund_failed',
  /** SAAS-017: the gateway a new invoice was pinned to, and the provider order it opened. */
  paymentProviderSelected: 'payment.provider_selected',
  paymentCreated: 'payment.created',
  /** A checkout completion whose signature verified and whose payment the gateway confirmed. */
  paymentVerified: 'payment.verified',
  paymentRefundAttempted: 'payment.refund_attempted',
  webhookAccepted: 'webhook.accepted',
  webhookRejected: 'webhook.rejected',
} as const;

/**
 * The payment gateways (SAAS-017). Written by the Super Admin's gateway screen, in the same transaction as the
 * change. The meta names the gateway, the fields that changed and a masked hint — never a credential.
 */
export const GATEWAY_AUDIT_ACTIONS = {
  /** Credentials saved for an environment that had none. */
  configured: 'gateway.configured',
  /** An environment's credentials replaced (rotation). */
  credentialsReplaced: 'gateway.credentials_replaced',
  /** A save refused: invalid credentials, or no secure storage on the server. */
  configurationFailed: 'gateway.configuration_failed',
  enabled: 'gateway.enabled',
  disabled: 'gateway.disabled',
  /** New payments through the gateway switch to its other environment's credentials. */
  environmentChanged: 'gateway.environment_changed',
  activated: 'gateway.activated',
  deactivated: 'gateway.deactivated',
  testAttempted: 'gateway.test_attempted',
} as const;

export interface AuditEvent {
  /** What happened, as `subject.verb` — e.g. `admin.created`, `admin.permissions.granted`. */
  action: string;
  /** What it happened to: `user`, `course`, `settings`, … */
  targetType: string;
  targetId?: string;
  /** Extra context worth keeping. Never put a password, token, hash or secret in here. */
  meta?: Record<string, unknown>;
}

export interface AuditEntry {
  id: string;
  action: string;
  targetType: string;
  targetId?: string;
  /** A person (`user`, with id, email and role), or a `system` job or `provider` named by `source`. */
  actor: { type: AuditActorType; id?: string; email: string; role: string; source?: string };
  meta: Record<string, unknown>;
  createdAt: string;
}

/** Who an event is attributed to: the signed-in caller of a request, or anything else that carries one. */
export type AuditActor = Pick<Request, 'auth'>;

/** Something other than a person: a scheduled job, or the payment provider (§36). */
export type AuditSource = { type: 'system'; job: string } | { type: 'provider'; provider: string; reference?: string };

/** A person (a request, or a lifecycle actor of type `user`) or a system/provider source. */
export type AuditAttribution = AuditActor | AuditSource | { type: 'user'; auth: NonNullable<Request['auth']> };

export type AuditActorType = 'user' | 'system' | 'provider';

const isSource = (who: AuditAttribution): who is AuditSource => 'type' in who && (who.type === 'system' || who.type === 'provider');

/**
 * Writes one audit event. A person is named from their token; a system or provider source is named as
 * itself. Returns the row id, or `undefined` when a person's event has no authenticated caller to
 * attribute it to — an unattributable event is not worth a row.
 *
 * Pass the transaction client when the event records a write: the mutation and its trail then land
 * together, so a successful change can never end up unaudited.
 */
export async function recordAuditLog(who: AuditAttribution, event: AuditEvent, client: DbClient = db): Promise<string | undefined> {
  const common = { action: event.action, targetType: event.targetType, targetId: event.targetId };
  if (isSource(who)) {
    const row = await client.auditLog.create({
      data: {
        ...common,
        actorType: who.type,
        actorId: null,
        actorEmail: '',
        actorRole: who.type,
        source: who.type === 'system' ? who.job : who.provider,
        metaJson: writeJson({ ...(who.type === 'provider' && who.reference ? { providerReference: who.reference } : {}), ...(event.meta ?? {}) }),
      },
      select: { id: true },
    });
    return row.id;
  }
  const auth = who.auth;
  if (!auth) return undefined;
  // The person is found across the platform: a super admin belongs to no academy, and an event written
  // inside an academy's transaction must still name them.
  const actor = await runAsPlatform('the audit trail names the person who acted', () =>
    client.user.findUnique({ where: { id: auth.sub }, select: { email: true } }),
  );
  const row = await client.auditLog.create({
    data: {
      ...common,
      actorType: 'user',
      actorId: actor ? auth.sub : null,
      actorEmail: actor?.email ?? '',
      actorRole: auth.role,
      metaJson: writeJson(event.meta ?? {}),
    },
    select: { id: true },
  });
  return row.id;
}
