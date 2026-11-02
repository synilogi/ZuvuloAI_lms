import { SignIn } from '@phosphor-icons/react';
import { LinkButton } from '@/components/ui/Button/Button';
import { BrandLogo } from '@/branding/BrandLogo';
import styles from './Pages.module.css';

/** Shown after signing out. Signing in again returns to the workspace for the demo role. */
export default function SignedOutPage() {
  return (
    <main className={styles.signedOut}>
      <div className={styles.signedOutCard}>
        <BrandLogo variant="full" />
        <h1 className={styles.signedOutTitle}>You’re signed out</h1>
        <p className={styles.signedOutText}>Your progress, notes and drafts are saved to your account. Sign in again to pick up where you left off.</p>
        <LinkButton to="/login" variant="primary" size="lg" iconStart={<SignIn size={18} />}>
          Sign in again
        </LinkButton>
      </div>
    </main>
  );
}
