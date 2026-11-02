import { useEffect } from 'react';
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { joinLinkFor, legFromLink } from '@syniastrolms/domain';
import { Button } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { services, ServiceError } from '@/services';
import { AuthChrome } from './MarketingChrome';
import styles from './Marketing.module.css';

/*
 * A referral link (`/ref/:code`, MLM-001). The code names the sponsor; the visitor is sent on to register with the
 * referral filled in, and the leg too when the link names one. A malformed, unknown or closed code shows one message
 * and a way to join without it.
 */
export default function RefPage() {
  const { code = '' } = useParams();
  const [search] = useSearchParams();
  const leg = legFromLink(search.get('leg'));
  const navigate = useNavigate();
  const referral = useAsync(`ref:${code}`, () => services.affiliate.referral(code));

  useEffect(() => {
    if (referral.data?.academy.open && !referral.data.academy.invitationOnly) {
      navigate(joinLinkFor('', encodeURIComponent(referral.data.sponsor.code), leg), { replace: true });
    }
  }, [referral.data, navigate, leg]);

  if (referral.status === 'error' && !referral.data) {
    const invalid = referral.error instanceof ServiceError && (referral.error.code === 'not-found' || referral.error.reason === 'REFERRAL_INVALID');
    return (
      <AuthChrome eyebrow="Referral">
        <StateMessage
          kind="error"
          headingLevel="h1"
          title={invalid ? 'This referral link isn’t valid' : 'The page didn’t load'}
          actions={
            invalid ? (
              <Link to="/register">Register without a referral</Link>
            ) : (
              <Button variant="primary" onClick={() => referral.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {invalid ? 'Ask the person who shared it for a fresh link, or register without one.' : referral.error?.message}
        </StateMessage>
      </AuthChrome>
    );
  }
  if (!referral.data) {
    return (
      <AuthChrome eyebrow="Referral">
        <div role="status" aria-label="Opening the referral">
          <Skeleton width="70%" height={30} />
          <Skeleton width="90%" height={16} />
        </div>
      </AuthChrome>
    );
  }
  const { sponsor, academy } = referral.data;
  return (
    <AuthChrome eyebrow={academy.name}>
      <StateMessage
        headingLevel="h1"
        title={academy.open ? 'New learners join by invitation right now' : 'We aren’t taking new learners right now'}
        actions={
          <>
            <Link to="/login">Sign in</Link>
          </>
        }
      >
        {sponsor.name} invited you. {academy.open ? 'Ask them for an invitation link.' : 'Contact support for help.'}
      </StateMessage>
      <p className={styles.authSwitch}>Referral code {sponsor.code}</p>
    </AuthChrome>
  );
}
