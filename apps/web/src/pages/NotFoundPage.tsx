import { useLocation } from 'react-router-dom';
import { ArrowLeft, Compass } from '@phosphor-icons/react';
import { LinkButton } from '@/components/ui/Button/Button';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { useSession } from '@/providers/SessionProvider';
import { homeFor } from '@/lib/roleHome';
import { locate } from '@/shell/navigation';
import styles from './Pages.module.css';

/** An address the app doesn't know. When it sits under a section, the way back leads there. */
export function NotFoundPage() {
  const { role } = useSession();
  const { pathname } = useLocation();
  const hit = locate(role, pathname);
  const home = homeFor(role);

  return (
    <div className={styles.center}>
      <h1 className="sr-only">Page not found</h1>
      <StateMessage
        kind="error"
        icon={<Compass size={26} />}
        title="This page isn’t on the map"
        actions={
          hit ? (
            <LinkButton to={hit.leaf?.to ?? hit.item.to} variant="primary" iconStart={<ArrowLeft size={16} />}>
              Back to {hit.leaf?.label ?? hit.item.label}
            </LinkButton>
          ) : (
            <LinkButton to={home} variant="primary">
              Go to your home page
            </LinkButton>
          )
        }
      >
        The address may be mistyped, or the page may have moved or been deleted. Everything in the navigation is reachable.
      </StateMessage>
    </div>
  );
}
