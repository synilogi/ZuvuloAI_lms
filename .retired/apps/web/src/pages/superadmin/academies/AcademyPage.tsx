import { useEffect, useState } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import { Copy, Eye, EyeSlash, Key, UserCircle } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { AcademyBilling } from '../subscriptions/AcademyBilling';
import { ACADEMIES_BASE, AcademyStatusBadge, PlanSummaryBadge, loginUrl, signInDetails } from './academyMeta';
import { AcademyAccess } from './AcademyAccess';
import platformStyles from '../Platform.module.css';
import styles from './Academies.module.css';

/** What the new-academy form hands this page, once: the admin's address and the password just set. */
interface CreatedState {
  created?: { email?: string; password?: string };
}

/**
 * One academy: who runs it and how they sign in, what it holds, and its subscription and billing. Right after the
 * academy is created, the first admin's password is shown here once — it lives only in this page's memory, is
 * cleared from the browser history at once, and is never fetched again.
 */
export default function AcademyPage() {
  const { tenantId = '' } = useParams();
  const location = useLocation();
  const navigate = useNavigate();
  const toast = useToast();
  const [created] = useState(() => (location.state as CreatedState | null)?.created ?? null);
  const [showPassword, setShowPassword] = useState(true);

  // Take the password out of the history entry, so going back or reloading never shows it again.
  useEffect(() => {
    if (location.state) navigate({ pathname: location.pathname, search: location.search }, { replace: true, state: null });
  }, [location.state, location.pathname, location.search, navigate]);

  const query = useAsync(`platform:academy:${tenantId}`, () => services.platform.getAcademy(tenantId));
  const academy = query.data;
  // The first crumb repeats the navigation's own, so the shell shows it once: Admins & LMSs › this LMS.
  usePageCrumbs(academy ? [{ label: 'Admins & LMSs', to: ACADEMIES_BASE }, { label: academy.name }] : [{ label: 'Admin' }]);
  const reload = () => query.run().catch(() => undefined);

  if (query.status === 'error' && !academy) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={platformStyles.page}>
        {notFound ? (
          <StateMessage kind="error" title="Admin not found" actions={<LinkButton to={ACADEMIES_BASE}>Back to admins</LinkButton>}>
            This Admin no longer exists, or the link is wrong.
          </StateMessage>
        ) : (
          <PlatformError title="The Admin didn’t load" error={query.error} onRetry={reload} />
        )}
      </div>
    );
  }

  if (!academy) {
    return (
      <div className={platformStyles.page} aria-busy="true" role="status" aria-label="Loading the Admin">
        <Skeleton width="40%" height={30} radius="var(--r-xs)" />
        <div className={styles.grid}>
          <Skeleton height={200} radius="var(--r-lg)" />
          <Skeleton height={200} radius="var(--r-lg)" />
        </div>
        <Skeleton height={220} radius="var(--r-lg)" />
      </div>
    );
  }

  const email = academy.owner?.email ?? created?.email;
  const password = created?.password;

  const copyDetails = async () => {
    if (!email) return;
    try {
      await navigator.clipboard.writeText(signInDetails({ academy: academy.name, email, password, loginUrl: loginUrl() }));
      toast({ kind: 'success', title: 'Sign-in details copied', text: password ? 'Send them to the admin privately.' : 'The password is not included.' });
    } catch {
      toast({ kind: 'error', title: 'Couldn’t copy', text: 'Select the details and copy them yourself.' });
    }
  };

  return (
    <div className={platformStyles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        back={{ label: 'Admins', to: ACADEMIES_BASE }}
        title={academy.name}
        description={
          academy.isDefault
            ? 'The LMS the website itself runs on. In development it holds the demo data.'
            : `${academy.owner?.name ?? 'This Admin'}’s LMS. Manage who can get in, how they sign in, and their plan and payments.`
        }
        meta={
          <div className={styles.headerMeta}>
            <AcademyStatusBadge status={academy.status} />
            <PlanSummaryBadge subscription={academy.subscription} />
            {academy.isDefault && (
              <Badge size="sm" tone="warn">
                Demo LMS
              </Badge>
            )}
            <span className={styles.slug}>{academy.slug}</span>
          </div>
        }
      />

      {created && (
        <InlineMessage kind="success" title="Admin created.">
          It is empty and on no plan. Share the sign-in details below with its admin — they choose a plan or start a free trial when they first sign in.
        </InlineMessage>
      )}

      <AcademyAccess academy={academy} onChanged={reload} />

      <div className={styles.grid}>
        <section className={styles.panel} aria-labelledby="academy-signin">
          <SectionHeader id="academy-signin" title="Sign-in details" description="Send these to the Admin so they can sign in." />
          {email ? (
            <>
              <dl className={styles.facts}>
                <div className={styles.fact}>
                  <dt className={styles.factLabel}>Admin</dt>
                  <dd className={styles.factValue}>{academy.owner?.name ?? '—'}</dd>
                </div>
                <div className={styles.fact}>
                  <dt className={styles.factLabel}>Sign-in email</dt>
                  <dd className={styles.factValue}>
                    <a href={`mailto:${email}`}>{email}</a>
                  </dd>
                </div>
                <div className={styles.fact}>
                  <dt className={styles.factLabel}>Sign in at</dt>
                  <dd className={`${styles.factValue} ${styles.slug}`}>{loginUrl()}</dd>
                </div>
                <div className={styles.fact}>
                  <dt className={styles.factLabel}>Password</dt>
                  <dd className={styles.factValue}>
                    {password ? (
                      <span className={styles.secret}>
                        <span className={styles.secretValue} data-testid="new-admin-password">
                          {showPassword ? password : '•'.repeat(Math.min(16, password.length))}
                        </span>
                        <Button
                          size="sm"
                          variant="ghost"
                          iconStart={showPassword ? <EyeSlash size={14} /> : <Eye size={14} />}
                          onClick={() => setShowPassword((v) => !v)}
                        >
                          {showPassword ? 'Hide' : 'Show'}
                        </Button>
                      </span>
                    ) : (
                      <span className={styles.muted}>Not shown. Passwords are never stored where they can be read back.</span>
                    )}
                  </dd>
                </div>
              </dl>
              {password && (
                <p className={styles.muted}>
                  <Key size={14} aria-hidden="true" /> This is the only time the password is shown. Copy it now and send it to the admin privately.
                </p>
              )}
              <div className={styles.panelActions}>
                <Button variant="primary" iconStart={<Copy size={16} />} onClick={copyDetails}>
                  Copy sign-in details
                </Button>
                <LinkButton to="/superadmin/admins">Manage admin logins</LinkButton>
              </div>
            </>
          ) : (
            <StateMessage
              icon={<UserCircle size={26} />}
              title="No admin recorded"
              compact
              actions={<LinkButton to="/superadmin/admins">Add an admin</LinkButton>}
            >
              This LMS has no admin login yet. Add one from Admin logins.
            </StateMessage>
          )}
        </section>

        <section className={styles.panel} aria-labelledby="academy-glance">
          <SectionHeader id="academy-glance" title="What’s inside" description={`Joined ${formatDate(academy.createdAt)}.`} />
          <dl className={styles.counts}>
            {[
              { label: 'Students', value: academy.learners },
              { label: 'Courses', value: academy.courses },
              { label: 'Instructors', value: academy.instructors },
              { label: 'All logins', value: academy.accounts },
            ].map((c) => (
              <div key={c.label} className={styles.count}>
                <dt className={styles.factLabel}>{c.label}</dt>
                <dd className={styles.countValue}>{c.value.toLocaleString('en-IN')}</dd>
              </div>
            ))}
          </dl>
          {academy.courses === 0 && academy.learners === 0 && (
            <p className={styles.muted}>Nothing here yet — the LMS starts empty. Its admin adds courses and students from their dashboard.</p>
          )}
        </section>
      </div>

      <AcademyBilling tenantId={academy.id} onChanged={reload} />
    </div>
  );
}
