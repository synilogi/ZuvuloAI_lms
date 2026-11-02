import { useId, useState, type FormEvent } from 'react';
import { Trash } from '@phosphor-icons/react';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { API_MODE, useSession } from '@/providers/SessionProvider';
import { services } from '@/services';
import { MarketingChrome } from './MarketingChrome';
import styles from './Marketing.module.css';

/** Sign in, then come straight back here — `/login` follows a same-site `?next=` (lib/safeNext.ts). */
const LOGIN_AND_RETURN = `/login?next=${encodeURIComponent('/delete-account')}`;

/**
 * The web half of deleting an account: a signed-in learner confirms with their password. Visitors are
 * sent to sign in first, and staff are told who closes their account — the API refuses them anyway.
 */
function DeleteAccountForm() {
  const { user, role, isAuthenticated, authLoading, logout } = useSession();
  const passwordId = useId();
  const [password, setPassword] = useState('');
  const [attempt, setAttempt] = useState(0);
  const [serverError, setServerError] = useState<string>();
  const [confirming, setConfirming] = useState(false);
  const [deleted, setDeleted] = useState(false);

  // Checked before the session: signing out on success leaves no session to read.
  if (deleted) {
    return (
      <InlineMessage kind="success" title="Your account has been deleted.">
        You’ve been signed out on this device and every other one. You can register again with the same email address at any time.
      </InlineMessage>
    );
  }
  if (authLoading) return <p className={styles.muted}>Checking whether you’re signed in…</p>;
  if (!isAuthenticated) {
    return (
      <div className={styles.legalForm}>
        <p>Sign in to the account you want to delete — you’ll come straight back to this page.</p>
        <LinkButton to={LOGIN_AND_RETURN} variant="primary">
          Sign in to continue
        </LinkButton>
      </div>
    );
  }
  if (role !== 'student') {
    return (
      <InlineMessage kind="info" title="This is a staff account.">
        Instructor and admin accounts are closed by the platform team. Ask them to remove your account.
      </InlineMessage>
    );
  }

  const passwordValid = password.length > 0;
  const fieldError = attempt > 0 && !passwordValid ? 'Enter your password to confirm.' : serverError;

  const submit = (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(undefined);
    if (passwordValid) setConfirming(true);
  };

  // A refusal (usually a wrong password) belongs next to the password field, so the dialog closes to show it there.
  const confirmDelete = async () => {
    try {
      await services.account.deleteAccount(password);
    } catch (err) {
      setConfirming(false);
      setServerError(err instanceof Error ? err.message : 'Could not delete your account.');
      return;
    }
    setConfirming(false);
    setDeleted(true);
    logout();
  };

  return (
    <>
      <form className={styles.legalForm} onSubmit={submit} noValidate>
        <p>
          Signed in as <strong>{user.email || user.name}</strong>.
        </p>
        <Field label="Password" hint="Confirm it’s you before the account is deleted." error={fieldError}>
          <Input
            id={passwordId}
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            autoComplete="current-password"
          />
        </Field>
        <Button type="submit" variant="danger" iconStart={<Trash size={18} />}>
          Delete my account
        </Button>
      </form>
      <ConfirmDialog
        open={confirming}
        onClose={() => setConfirming(false)}
        onConfirm={confirmDelete}
        title="Delete your account?"
        description="This happens immediately and can’t be undone."
        icon={<Trash size={20} />}
        confirmLabel="Delete my account"
        tone="danger"
        acknowledge="I understand my account will be deleted permanently."
      >
        <p>Your name, email, notes, bookmarks, saved courses and drafts are removed, and you’re signed out everywhere.</p>
      </ConfirmDialog>
    </>
  );
}

/** How to delete a ZuviloAI account, from the Android app or here — public, and linked from the app's store listing. */
export default function DeleteAccountPage() {
  return (
    <MarketingChrome>
      <article className={styles.legal}>
        <header className={styles.legalHead}>
          <h1>Delete your ZuviloAI account</h1>
          <p className={styles.muted}>Last updated 2 October 2026</p>
        </header>

        <section>
          <p>
            You can delete your learner account yourself, from the Android app or from this page. Deletion is immediate and can’t be undone — if you only want
            fewer emails, change your notification preferences instead.
          </p>
        </section>

        <section>
          <h2>In the Android app</h2>
          <ol>
            <li>Open the ZuviloAI app and sign in.</li>
            <li>Go to Profile → Delete account.</li>
            <li>Enter your password to confirm.</li>
          </ol>
        </section>

        <section>
          <h2>Here on the web</h2>
          <p>Sign in, then confirm with your password below.</p>
          <DeleteAccountForm />
        </section>

        <section>
          <h2>What is deleted</h2>
          <ul>
            <li>Your name, replaced with “Deleted learner”, and your email address, replaced with a placeholder. Your password stops working.</li>
            <li>Lesson notes, bookmarks, saved courses and assignment drafts.</li>
            <li>Live-class registrations, notifications and notification preferences.</li>
            <li>Registered devices and any password-reset links. Every signed-in session ends, on every device.</li>
          </ul>
          <p>Your account is closed, and the email address is free to register a new account — which starts from nothing.</p>
        </section>

        <section>
          <h2>What is kept, and why</h2>
          <p>
            Course progress, quiz and assignment records, and certificates already issued are kept under the anonymous name “Deleted learner”. A certificate may
            already have been shown to an employer or another school, and deleting it would break a credential they rely on — so it keeps verifying, but the
            verification page no longer shows your name.
          </p>
        </section>

        <section>
          <h2>Instructor and admin accounts</h2>
          <p>Staff accounts are closed by the platform team, not from this page or the app. Ask them to remove your account.</p>
        </section>

        <section>
          <h2>If you can’t sign in</h2>
          <p>
            Write to <a href="mailto:help@zuviloai.com">help@zuviloai.com</a> from the email address on the account and ask us to delete it. We’ll confirm and
            complete the deletion within 30 days.
          </p>
        </section>

        {/* True of the demo build only. Against the real API the account is real and deleting it is final, so the note would be a lie. */}
        {API_MODE === 'mock' && <p className={styles.legalNote}>This is a UI demo build — no accounts are stored, so confirming here deletes nothing.</p>}
      </article>
    </MarketingChrome>
  );
}
