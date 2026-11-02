import { formatMoney, type SubscriptionState } from '@syniastrolms/domain';

import { db } from './db.js';
import { adminUserIds, notifyMany, type NotifyInput } from './notify.js';
import { describeError, observe } from './observe.js';
import { runAsPlatform, runInTenant } from './tenancy.js';

/*
 * Billing notices (subscriptions.md §31): what an academy's admins are told when their subscription moves or an
 * invoice is issued. Sent from the backend events themselves — the lifecycle transition and the invoice — never
 * from a click. Through the existing notification engine, as `system` notices: always delivered in the app and
 * by email, whatever the recipient's preferences, since they concern the academy's access.
 *
 * A notice never stops billing: the move or the invoice is already committed, and a failure to tell anyone is
 * reported as a `job.failed` signal and nothing more.
 */

const BILLING_PAGE = '/admin/billing';

type Notice = Pick<NotifyInput, 'title' | 'summary' | 'body' | 'important' | 'facts'> & { action?: NotifyInput['action'] };

const day = (d: Date) => d.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' });

/** Tells every admin of the academy, inside the academy's own context. */
async function tellAdmins(tenantId: string, notice: Notice, what: string) {
  try {
    await runInTenant(tenantId, async () =>
      notifyMany(await adminUserIds(), {
        category: 'system',
        actor: 'Billing',
        action: notice.action ?? { label: 'Open billing', to: BILLING_PAGE },
        ...notice,
      }),
    );
  } catch (err) {
    observe('job.failed', { job: 'billing-notice', tenantId, notice: what, error: describeError(err) });
  }
}

export interface TransitionNoticeInput {
  tenantId: string;
  subscriptionId: string;
  transition: string;
  from: SubscriptionState | null;
  to: SubscriptionState;
  /** Who moved it: the academy's own admin is not told about their own click. */
  byAcademyAdmin: boolean;
  meta?: Record<string, unknown>;
}

/** The notice for a lifecycle move, or none. Reads the subscription as the move left it. */
export async function noticeForTransition(input: TransitionNoticeInput): Promise<void> {
  const sub = await runAsPlatform('reading a subscription for its notice', () =>
    db.subscription.findUnique({ where: { id: input.subscriptionId }, include: { plan: { select: { name: true } } } }),
  );
  if (!sub) return;
  const plan = sub.plan.name;
  const ends = day(sub.currentPeriodEndAt);
  const notice = ((): Notice | null => {
    switch (input.transition) {
      case 'create':
        return input.to === 'trialing'
          ? {
              title: `Your ${plan} trial has started`,
              summary: `Your free trial of ${plan} runs until ${ends}.`,
              facts: [{ label: 'Trial ends', value: ends }],
            }
          : {
              title: `Your ${plan} subscription is active`,
              summary: `Your LMS is on ${plan}. It renews on ${ends}.`,
              facts: [{ label: 'Renews', value: ends }],
            };
      case 'payment_succeeded':
        if (input.from === 'trialing')
          return {
            title: `Your ${plan} subscription is active`,
            summary: `Payment received. Your first paid period starts as your trial ends, and runs until ${ends}.`,
          };
        if (input.from === 'past_due')
          return { title: 'Payment received: your subscription is restored', summary: `Thank you. ${plan} is active again and renews on ${ends}.` };
        return {
          title: 'Your subscription has renewed',
          summary: `Payment received. ${plan} is renewed until ${ends}.`,
          facts: [{ label: 'Next renewal', value: ends }],
        };
      case 'payment_failed':
        return {
          title: 'Your subscription payment is overdue',
          summary: `We could not take payment for ${plan}. Your LMS keeps its access for now. Pay the open invoice to keep it.`,
          important: true,
          action: { label: 'Pay now', to: BILLING_PAGE },
        };
      case 'grace_started':
        return sub.gracePeriodEndAt
          ? {
              title: `Pay by ${day(sub.gracePeriodEndAt)} to keep your LMS's access`,
              summary: `Your subscription is still unpaid. Unless the open invoice is paid by ${day(sub.gracePeriodEndAt)}, your LMS will be restricted.`,
              important: true,
              action: { label: 'Pay now', to: BILLING_PAGE },
            }
          : null;
      case 'trial_expired':
        return {
          title: 'Your free trial has ended',
          summary: `Your ${plan} trial is over. Choose a plan to keep creating courses and adding learners. Everything you made is kept.`,
          important: true,
          action: { label: 'Choose a plan', to: BILLING_PAGE },
        };
      case 'grace_expired':
        return {
          title: 'Your subscription has expired',
          summary: 'Nothing was paid, so your LMS is now restricted. Everything you made is kept. Subscribe again to carry on.',
          important: true,
          action: { label: 'Choose a plan', to: BILLING_PAGE },
        };
      case 'request_cancel':
        return input.byAcademyAdmin
          ? null
          : { title: 'Your subscription will end', summary: `${plan} is set to end on ${ends}. Your LMS keeps its access until then.` };
      case 'cancel_now':
        // A trial that gave way to a paid plan (D33) is not an ending: the new subscription's own notice says so.
        if (input.meta?.convertedByInvoice) return null;
        return {
          title: 'Your subscription has ended',
          summary: `${plan} has been cancelled. Everything you made is kept. Choose a plan whenever you want to carry on.`,
          important: true,
          action: { label: 'Choose a plan', to: BILLING_PAGE },
        };
      case 'period_ended':
        return {
          title: 'Your subscription has ended',
          summary: `${plan} has been cancelled. Everything you made is kept. Choose a plan whenever you want to carry on.`,
          important: true,
          action: { label: 'Choose a plan', to: BILLING_PAGE },
        };
      case 'pause':
        return {
          title: 'Your subscription is paused',
          summary: `The platform team has paused ${plan}${sub.resumesAt ? ` until ${day(sub.resumesAt)}` : ''}. Your renewal date moves out by the time paused.`,
          important: true,
        };
      case 'resume':
        if (input.from === 'canceling' && input.byAcademyAdmin) return null;
        return { title: 'Your subscription has resumed', summary: `${plan} is active again and renews on ${ends}.` };
      case 'change_plan':
        return { title: `Your LMS is now on ${plan}`, summary: `Your plan has changed to ${plan}. It renews on ${ends}.` };
      case 'extend':
        return {
          title: 'Complimentary days added',
          summary: `The platform team added ${String(input.meta?.days ?? '')} days to your subscription at no charge. It now renews on ${ends}.`,
        };
      default:
        return null;
    }
  })();
  if (notice) await tellAdmins(input.tenantId, notice, input.transition);
}

/** A renewal invoice is issued: the period is ending, or the trial is. */
export async function noticeForRenewalInvoice(invoice: { tenantId: string; subscriptionId: string | null; number: string; total: number; currency: string }) {
  if (!invoice.subscriptionId) return;
  const sub = await runAsPlatform('reading a subscription for its invoice notice', () =>
    db.subscription.findUnique({ where: { id: invoice.subscriptionId! }, include: { plan: { select: { name: true } } } }),
  );
  if (!sub) return;
  const amount = formatMoney(invoice.total, invoice.currency);
  const ends = day(sub.currentPeriodEndAt);
  const facts = [
    { label: 'Invoice', value: invoice.number },
    { label: 'Amount', value: amount },
    { label: sub.status === 'trialing' ? 'Trial ends' : 'Due by', value: ends },
  ];
  const notice: Notice =
    sub.status === 'trialing'
      ? {
          title: `Your ${sub.plan.name} trial ends on ${ends}`,
          summary: `To keep ${sub.plan.name} after your trial, pay invoice ${invoice.number} (${amount}). Paying early keeps the rest of your trial.`,
          facts,
          action: { label: 'Pay now', to: BILLING_PAGE },
        }
      : sub.status === 'past_due'
        ? {
            title: `Invoice ${invoice.number} is ready to pay`,
            summary: `Your subscription is overdue. Pay ${amount} to restore it.`,
            facts,
            important: true,
            action: { label: 'Pay now', to: BILLING_PAGE },
          }
        : {
            title: `Your ${sub.plan.name} renewal is coming up`,
            summary: `Invoice ${invoice.number} for ${amount} is ready. Pay it by ${ends} to renew without interruption.`,
            facts,
            action: { label: 'Pay now', to: BILLING_PAGE },
          };
  await tellAdmins(invoice.tenantId, notice, 'renewal-invoice');
}
