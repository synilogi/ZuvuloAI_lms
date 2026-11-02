import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import type { Role } from '@syniastrolms/domain';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { useAsync, type AsyncState } from '@/hooks/useAsync';
import { homeFor } from '@/lib/roleHome';
import { useSession } from '@/providers/SessionProvider';
import { services, type CourseLinkDetails } from '@/services';
import { CreateAccountForm } from './LearnerJoinForms';
import type { AccountCreated, AccountVerificationPending } from '@syniastrolms/domain';
import { EmailCodeStep } from './EmailCodeStep';
import { enrolFailure, joinFailure } from './joinFailure';
import { AuthChrome } from './MarketingChrome';
import { ALL_INCLUSIVE, saleDisplay } from '@/lib/coursePricing';
import styles from './Marketing.module.css';

/*
 * A course enrolment link (`/courses/<course-id>/enroll`). The course names the Admin's LMS: a signed-in learner of that
 * LMS enrols; a visitor creates a learner account there and is enrolled when the platform lets learners enrol themselves.
 * A learner of another LMS can't join it — the server finds only their own LMS's courses.
 */

/** The link's sale, read with the same rule as everywhere else. */
const saleOf = (sale: NonNullable<CourseLinkDetails['course']['sale']>) =>
  saleDisplay(sale.kind === 'paid' ? { pricing: 'paid', price: sale.price } : { pricing: sale.kind === 'free' ? 'free' : 'unset' });

export type EnrollViewer = { kind: 'signed-out' } | { kind: 'loading' } | { kind: 'signed-in'; name: string; role: Role };

/** Where "Sign in" goes from a course link: the sign-in page, which comes back here. */
export const signInReturningTo = (courseId: string) => `/login?next=${encodeURIComponent(`/courses/${courseId}/enroll`)}`;

export default function CourseEnrollPage() {
  const { courseId = '' } = useParams();
  const navigate = useNavigate();
  const toast = useToast();
  const { adopt, isAuthenticated, authLoading, user, role } = useSession();
  const load = useAsync(`course-link:${courseId}`, () => services.invitations.courseLink(courseId));
  const viewer: EnrollViewer = authLoading ? { kind: 'loading' } : isAuthenticated ? { kind: 'signed-in', name: user.name, role } : { kind: 'signed-out' };

  const enrol = async () => {
    try {
      await services.enrollment.enroll(courseId);
    } catch (err) {
      return enrolFailure(err);
    }
    toast({ kind: 'success', title: 'You’re enrolled', text: load.data?.course.title });
    navigate(`/learn/${courseId}`, { replace: true });
    return undefined;
  };

  const onJoined = (session: AccountCreated, details: CourseLinkDetails) => {
    adopt(session);
    // A paid course is bought once the account exists: the course page has the order summary and the checkout.
    if (!session.enrolled && session.enrolmentCode === 'COURSE_PURCHASE_REQUIRED') {
      toast({ kind: 'info', title: `Welcome to ${details.lms.name}!`, text: `Buy ${details.course.title} to start learning.` });
      navigate(`/learn/${details.course.id}`, { replace: true });
      return;
    }
    if (session.enrolled) {
      toast({ kind: 'success', title: `Welcome to ${details.lms.name}!`, text: `You’re enrolled in ${details.course.title}.` });
      navigate(`/learn/${details.course.id}`, { replace: true });
    } else {
      toast({
        kind: 'info',
        title: `Welcome to ${details.lms.name}! You aren’t enrolled in ${details.course.title} yet.`,
        text: session.enrolment ?? 'Contact support.',
      });
      navigate('/home', { replace: true });
    }
  };

  return (
    <CourseEnrollView load={load} courseId={courseId} viewer={viewer} onEnrol={enrol} onJoined={onJoined} retry={() => load.run().catch(() => undefined)} />
  );
}

export function CourseEnrollView({
  load,
  courseId,
  viewer,
  onEnrol,
  onJoined,
  retry,
}: {
  load: AsyncState<CourseLinkDetails>;
  courseId: string;
  viewer: EnrollViewer;
  /** Resolves with why the enrolment was refused, if it was. */
  onEnrol: () => Promise<string | undefined>;
  onJoined: (session: AccountCreated, details: CourseLinkDetails) => void;
  retry: () => void;
}) {
  const [pending, setPending] = useState<AccountVerificationPending>();
  if (load.status === 'error' && !load.data) {
    const missing = (load.error as { code?: string }).code === 'not-found';
    return (
      <AuthChrome eyebrow="Course enrolment">
        <StateMessage
          kind="error"
          headingLevel="h1"
          title={missing ? 'We couldn’t find that course' : 'The course didn’t load'}
          actions={
            missing ? (
              <Link to="/login">Sign in</Link>
            ) : (
              <Button variant="primary" onClick={retry}>
                Try again
              </Button>
            )
          }
        >
          {missing ? 'The link may be mistyped, or the course is no longer open. Ask support for a new link.' : load.error.message}
        </StateMessage>
      </AuthChrome>
    );
  }
  if (!load.data || viewer.kind === 'loading') {
    return (
      <AuthChrome eyebrow="Course enrolment">
        <div role="status" aria-label="Loading the course">
          <Skeleton width="70%" height={30} />
          <Skeleton width="90%" height={16} />
        </div>
      </AuthChrome>
    );
  }

  const details = load.data;
  // How joining the course works once signed in: free, bought (on the course page), or not open yet.
  const sale = details.course.sale ? saleOf(details.course.sale) : ({ kind: 'free', label: 'Free' } as const);
  const heading = (
    <>
      <h1 className={styles.authTitle}>{details.course.title}</h1>
      <p className={styles.authSubtitle}>on {details.lms.name}</p>
    </>
  );

  if (viewer.kind === 'signed-in') {
    return (
      <AuthChrome eyebrow={`Join ${details.lms.name}`}>
        {heading}
        {viewer.role === 'student' ? (
          sale.kind === 'paid' ? (
            <>
              <p>You’re signed in as {viewer.name}.</p>
              <p className={styles.authSubtitle}>
                This course costs {sale.label} ({ALL_INCLUSIVE.toLowerCase()}). It opens as soon as your payment is confirmed.
              </p>
              <LinkButton variant="primary" size="lg" to={`/learn/${details.course.id}`}>
                Buy the course · {sale.label}
              </LinkButton>
            </>
          ) : sale.kind === 'unavailable' ? (
            <StateMessage title="This course isn’t open for enrolment yet">
              The platform hasn’t opened it to learners. Check back later, or contact support.
            </StateMessage>
          ) : (
            <LearnerEnrol name={viewer.name} onEnrol={onEnrol} />
          )
        ) : (
          <StateMessage title="Course links are for learners" actions={<LinkButton to={homeFor(viewer.role)}>Go to your workspace</LinkButton>}>
            You’re signed in as {viewer.name}, a staff account. Learners open this link to join the course; staff accounts can’t enrol.
          </StateMessage>
        )}
      </AuthChrome>
    );
  }

  if (!details.open) {
    return (
      <AuthChrome eyebrow={details.lms.name}>
        {heading}
        <StateMessage title={`${details.lms.name} isn’t taking new learners right now`}>
          The platform isn’t open at the moment, for new or existing accounts. Contact support for help.
        </StateMessage>
      </AuthChrome>
    );
  }

  if (pending) {
    return (
      <AuthChrome eyebrow={`Join ${details.lms.name}`}>
        <EmailCodeStep
          pending={pending}
          confirmLabel={sale.kind === 'free' ? 'Verify and enrol' : 'Verify and continue'}
          onConfirmed={(result) => {
            if (result.status === 'created') onJoined(result, details);
          }}
          onBack={() => setPending(undefined)}
        />
      </AuthChrome>
    );
  }

  return (
    <AuthChrome eyebrow={`Join ${details.lms.name}`}>
      {heading}
      <p className={styles.authSubtitle}>
        {sale.kind === 'paid'
          ? `This course costs ${sale.label} (${ALL_INCLUSIVE.toLowerCase()}). Create your learner account at ${details.lms.name}, then buy it on the course page.`
          : sale.kind === 'unavailable'
            ? `This course isn’t open for enrolment yet. You can still create your learner account at ${details.lms.name}.`
            : `Create your learner account at ${details.lms.name} to start this course.`}
      </p>
      <CreateAccountForm
        lmsName={details.lms.name}
        submitLabel={sale.kind === 'free' ? 'Create account and enrol' : 'Create account and continue'}
        onSubmit={async (input) => {
          try {
            const result = await services.invitations.joinCourse(courseId, input);
            if (result.status === 'verify') setPending(result);
            else onJoined(result, details);
            return undefined;
          } catch (err) {
            return joinFailure(err, details.lms.name, 'register');
          }
        }}
        footer={
          <p className={styles.authSwitch}>
            Already have an account? <Link to={signInReturningTo(courseId)}>Sign in</Link>
          </p>
        }
      />
    </AuthChrome>
  );
}

function LearnerEnrol({ name, onEnrol }: { name: string; onEnrol: () => Promise<string | undefined> }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();
  return (
    <>
      <p>You’re signed in as {name}.</p>
      {error && (
        <InlineMessage kind="error" title="You weren’t enrolled">
          {error}
        </InlineMessage>
      )}
      <Button
        variant="primary"
        size="lg"
        block
        loading={busy}
        onClick={async () => {
          setBusy(true);
          setError(undefined);
          const refused = await onEnrol();
          setBusy(false);
          setError(refused);
        }}
      >
        Enrol
      </Button>
    </>
  );
}
