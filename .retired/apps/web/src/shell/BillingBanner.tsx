import { useEffect, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { BILLING_PAGE, BILLING_STATES, billingNotice, isBillingRefusal, type BillingRefusalCode } from '@/lib/billingStates';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { Button } from '@/components/ui/Button/Button';
import { demoNow, useNow } from '@/hooks/useNow';
import { useTenantBilling } from '@/hooks/useTenantBilling';
import { useSession } from '@/providers/SessionProvider';
import { WELCOME_PAGE } from '@/lib/planAccess';
import { BILLING_REFUSAL_EVENT } from '@/services/http/client';

/*
 * The academy's subscription, said once above the page.
 *
 * On load, for an admin who can see billing, the academy's standing is read (shared with the billing page) and
 * anything that needs acting on is said before anything is refused: an overdue payment and its grace period, a
 * pause, a cancellation under way, a subscription that has ended, a trial about to end, or no plan where plans
 * are enforced. A free trial is named for as long as it runs, with the days it has left. Not on the billing page
 * or the first-plan page, which say all of it in place. Dismissed, it stays away for the
 * session — until the situation changes.
 *
 * And whenever the API refuses a request because of the subscription — none, overdue, expired
 * (subscriptions.md §34) — the whole academy is affected, not the one action: the client announces the refusal
 * and this shows its state, with where an academy admin resolves it. Refusals that concern one action only (a
 * feature not in the plan, a limit reached) stay with that action.
 */

const DISMISSED_KEY = 'syniastrolms:billing-notice-dismissed';

function readDismissed(): string | null {
  try {
    return sessionStorage.getItem(DISMISSED_KEY);
  } catch {
    return null;
  }
}

function writeDismissed(key: string) {
  try {
    sessionStorage.setItem(DISMISSED_KEY, key);
  } catch {
    /* storage unavailable: dismissed for this page view only */
  }
}

export function BillingBanner({ canManageBilling }: { canManageBilling: boolean }) {
  const [code, setCode] = useState<BillingRefusalCode | null>(null);
  const [dismissed, setDismissed] = useState<string | null>(readDismissed);
  const { user } = useSession();
  const { pathname } = useLocation();
  const now = useNow();
  const summary = useTenantBilling(user?.id, { enabled: canManageBilling });

  useEffect(() => {
    const onRefusal = (event: Event) => {
      const next = (event as CustomEvent<{ code?: unknown }>).detail?.code;
      if (isBillingRefusal(next) && BILLING_STATES[next].academyWide) setCode(next);
    };
    window.addEventListener(BILLING_REFUSAL_EVENT, onRefusal);
    return () => window.removeEventListener(BILLING_REFUSAL_EVENT, onRefusal);
  }, []);

  if (code) {
    const state = BILLING_STATES[code];
    return (
      <InlineMessage
        kind={state.tone === 'danger' ? 'error' : state.tone === 'warn' ? 'warn' : 'info'}
        title={state.title}
        action={
          <span style={{ display: 'inline-flex', gap: 8 }}>
            {canManageBilling && state.action && <Link to={state.action.to}>{state.action.label}</Link>}
            <Button size="sm" variant="ghost" onClick={() => setCode(null)}>
              Dismiss
            </Button>
          </span>
        }
      >
        {state.body}
      </InlineMessage>
    );
  }

  // Not on the billing page or the first-plan page, which say all of it in place.
  if (!canManageBilling || !summary.data || pathname.startsWith(BILLING_PAGE) || pathname.startsWith(WELCOME_PAGE)) return null;
  // The clock as of this render, not as of the last tick: the shell mounts before a trial is started, and a
  // reading from before it began would count one day too many. `useNow` still re-renders it as time passes.
  const notice = billingNotice(summary.data, new Date(Math.max(now.getTime(), demoNow().getTime())));
  if (!notice || notice.key === dismissed) return null;
  return (
    <InlineMessage
      kind={notice.tone === 'danger' ? 'error' : notice.tone === 'warn' ? 'warn' : 'info'}
      title={notice.title}
      action={
        <span style={{ display: 'inline-flex', gap: 8 }}>
          <Link to={notice.action.to}>{notice.action.label}</Link>
          <Button
            size="sm"
            variant="ghost"
            onClick={() => {
              writeDismissed(notice.key);
              setDismissed(notice.key);
            }}
          >
            Dismiss
          </Button>
        </span>
      }
    >
      {notice.body}
    </InlineMessage>
  );
}
