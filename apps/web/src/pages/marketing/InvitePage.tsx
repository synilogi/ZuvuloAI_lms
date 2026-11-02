import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { Button } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { useAsync, type AsyncState } from '@/hooks/useAsync';
import { useSession } from '@/providers/SessionProvider';
import { formatDate } from '@/lib/format';
import { services, ServiceError, type InvitationDetails, type LearnerSession } from '@/services';
import { CreateAccountForm, SignInForm } from './LearnerJoinForms';
import type { AccountStartResult, AccountVerificationPending } from '@syniastrolms/domain';
import { EmailCodeStep } from './EmailCodeStep';
import { joinFailure } from './joinFailure';
import { AuthChrome } from './MarketingChrome';
import styles from './Marketing.module.css';

/*
 * A learner invitation (`/invite/<token>`). The link an Admin made names their LMS and the learner role; the learner
 * creates an account there, or signs in with the one they already have there, and lands in their learner workspace.
 * The link works once and for seven days.
 */
export default function InvitePage() {
  const { token = '' } = useParams();
  const navigate = useNavigate();
  const { adopt } = useSession();
  const toast = useToast();
  const load = useAsync(`invite:${token}`, () => services.invitations.describe(token));

  const onJoined = (session: LearnerSession, lmsName: string) => {
    adopt(session);
    toast({ kind: 'success', title: `Welcome to ${lmsName}, ${session.user.name.split(' ')[0]}!`, text: 'Your learner workspace is ready.' });
    navigate('/home', { replace: true });
  };

  return <InviteView load={load} token={token} onJoined={onJoined} retry={() => load.run().catch(() => undefined)} />;
}

export function InviteUnavailable({ message }: { message: string }) {
  return (
    <AuthChrome eyebrow="Invitation">
      <StateMessage kind="error" headingLevel="h1" title="This invitation link isn’t valid" actions={<Link to="/login">Sign in instead</Link>}>
        {message}
      </StateMessage>
    </AuthChrome>
  );
}

export function InviteView({
  load,
  token,
  onJoined,
  retry,
  initialMode = 'create',
}: {
  load: AsyncState<InvitationDetails>;
  token: string;
  onJoined: (session: LearnerSession, lmsName: string) => void;
  retry: () => void;
  initialMode?: 'create' | 'sign-in';
}) {
  if (load.status === 'error' && !load.data) {
    const gone = load.error instanceof ServiceError && (load.error.reason === 'INVITE_INVALID' || load.error.code === 'not-found');
    if (gone) return <InviteUnavailable message={load.error.message} />;
    return (
      <AuthChrome eyebrow="Invitation">
        <StateMessage
          kind="error"
          headingLevel="h1"
          title="The invitation didn’t load"
          actions={
            <Button variant="primary" onClick={retry}>
              Try again
            </Button>
          }
        >
          {load.error.message}
        </StateMessage>
      </AuthChrome>
    );
  }
  if (!load.data) {
    return (
      <AuthChrome eyebrow="Invitation">
        <div role="status" aria-label="Loading the invitation">
          <Skeleton width="70%" height={30} />
          <Skeleton width="90%" height={16} />
        </div>
      </AuthChrome>
    );
  }
  const invitation = load.data;
  if (!invitation.open) {
    return (
      <AuthChrome eyebrow={invitation.lms.name}>
        <StateMessage headingLevel="h1" title={`${invitation.lms.name} isn’t taking new learners right now`}>
          The platform isn’t open at the moment, for new or existing accounts. Contact support for help. Your invitation stays valid until it expires.
        </StateMessage>
      </AuthChrome>
    );
  }
  return <InviteJoin invitation={invitation} token={token} onJoined={onJoined} initialMode={initialMode} />;
}

function InviteJoin({
  invitation,
  token,
  onJoined,
  initialMode,
}: {
  invitation: InvitationDetails;
  token: string;
  onJoined: (session: LearnerSession, lmsName: string) => void;
  initialMode: 'create' | 'sign-in';
}) {
  const [mode, setMode] = useState(initialMode);
  const [gone, setGone] = useState<string>();
  const [pending, setPending] = useState<AccountVerificationPending>();
  const lms = invitation.lms.name;

  const attempt = async (call: () => Promise<LearnerSession | AccountStartResult>, kind: 'register' | 'sign-in') => {
    try {
      const result = await call();
      // A new account's email is verified first; signing in with an existing one joins at once.
      if ('status' in result && result.status === 'verify') setPending(result);
      else onJoined(result as LearnerSession, lms);
      return undefined;
    } catch (err) {
      const failure = joinFailure(err, lms, kind);
      if (failure.invalid) setGone(failure.invalid);
      return failure;
    }
  };

  if (gone) return <InviteUnavailable message={gone} />;
  if (pending) {
    return (
      <AuthChrome eyebrow={`Join ${lms}`}>
        <EmailCodeStep
          pending={pending}
          confirmLabel="Verify and join"
          onConfirmed={(result) => {
            if (result.status === 'created') onJoined(result, lms);
          }}
          onBack={() => setPending(undefined)}
        />
      </AuthChrome>
    );
  }

  return (
    <AuthChrome eyebrow={`Join ${lms}`}>
      <h1 className={styles.authTitle}>Join {lms}</h1>
      <p className={styles.authSubtitle}>
        {mode === 'create' ? `You’re invited to learn on ${lms}. Create your learner account.` : 'Sign in with the learner account you already have.'}
      </p>
      <SegmentedControl
        label="How would you like to join?"
        value={mode}
        onChange={setMode}
        segments={[
          { value: 'create', label: 'Create account' },
          { value: 'sign-in', label: 'I already have an account' },
        ]}
      />
      {mode === 'create' ? (
        <CreateAccountForm
          key="create"
          lmsName={lms}
          fixedEmail={invitation.email}
          onSubmit={(input) => attempt(() => services.invitations.register(token, input), 'register')}
        />
      ) : (
        <SignInForm key="sign-in" fixedEmail={invitation.email} onSubmit={(input) => attempt(() => services.invitations.signIn(token, input), 'sign-in')} />
      )}
      <p className={styles.authSwitch}>This invitation works once and expires on {formatDate(invitation.expiresAt)}.</p>
    </AuthChrome>
  );
}
