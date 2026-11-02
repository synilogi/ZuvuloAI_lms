import { Link } from 'react-router-dom';
import { BellSimple, Certificate, EnvelopeSimple, Question } from '@phosphor-icons/react';
import type { Role } from '@syniastrolms/domain';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Kbd } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { Modal } from '@/components/overlays/Overlay';
import { useSession } from '@/providers/SessionProvider';
import { helpHome } from '@/pages/help/helpMeta';
import { notificationsHome } from './notificationSummary';
import { workspaceLabel } from './navigation';
import styles from './AppShell.module.css';

const isMac = typeof navigator !== 'undefined' && /Mac|iPhone|iPad/.test(navigator.platform);
const mod = isMac ? '⌘' : 'Ctrl';

const SHORTCUTS: { keys: string[]; action: string }[] = [
  { keys: [mod, 'K'], action: 'Open the command menu — search pages, courses and actions' },
  { keys: [mod, 'B'], action: 'Collapse or expand the sidebar' },
  { keys: [mod, 'S'], action: 'Save changes in settings' },
  { keys: ['Esc'], action: 'Close a menu, panel or dialog' },
  { keys: ['←', '→', '↑', '↓'], action: 'Move between days in the calendar month' },
  { keys: ['Page Up', 'Page Down'], action: 'Previous or next month in the calendar' },
];

/** Keyboard shortcuts and where to get help. */
export function HelpDialog({ open, onClose, focus = 'help' }: { open: boolean; onClose: () => void; focus?: 'help' | 'shortcuts' }) {
  const { role } = useSession();
  return (
    <Modal
      open={open}
      onClose={onClose}
      width={560}
      title={focus === 'shortcuts' ? 'Keyboard shortcuts' : 'Help and shortcuts'}
      description={
        focus === 'shortcuts' ? 'Work faster without reaching for the mouse.' : 'Shortcuts that work everywhere, and who to ask when something isn’t right.'
      }
      footer={<Button onClick={onClose}>Close</Button>}
    >
      <div className={styles.helpBody}>
        <table className={styles.shortcuts}>
          <caption className="sr-only">Keyboard shortcuts</caption>
          <tbody>
            {SHORTCUTS.map((s) => (
              <tr key={s.action}>
                <th scope="row">
                  <span className={styles.keys}>
                    {s.keys.map((k) => (
                      <Kbd key={k}>{k}</Kbd>
                    ))}
                  </span>
                </th>
                <td>{s.action}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {focus === 'help' && (
          <ul className={styles.helpLinks}>
            <li>
              <Question size={18} aria-hidden="true" />
              <span>
                Browse guides for every part of the platform in the{' '}
                <Link to={helpHome(role)} onClick={onClose}>
                  Help Centre
                </Link>
                .
              </span>
            </li>
            <li>
              <EnvelopeSimple size={18} aria-hidden="true" />
              <span>
                Write to <a href="mailto:synilogicteam@gmail.com">synilogicteam@gmail.com</a> — replies within a working day.
              </span>
            </li>
          </ul>
        )}
      </div>
    </Modal>
  );
}

const ROLE_NAME: Record<Role, string> = { student: 'Learner', instructor: 'Instructor', admin: 'Admin', superadmin: 'Super admin' };

/** Who is signed in, and the settings that belong to them. */
export function ProfileDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { user, role } = useSession();
  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Your profile"
      description="Your name and email come from your ZuviloAI account."
      footer={<Button onClick={onClose}>Close</Button>}
    >
      <div className={styles.profile}>
        <Avatar name={user.name} size={56} tone="accent" />
        <div className={styles.profileText}>
          <strong>{user.name}</strong>
          <span>{user.email}</span>
          <span className={styles.profileRole}>
            {ROLE_NAME[role]} · {user.descriptor} · {workspaceLabel[role]}
          </span>
        </div>
      </div>
      <ul className={styles.helpLinks}>
        <li>
          <Question size={18} aria-hidden="true" />
          <Link to={helpHome(role)} onClick={onClose}>
            Help Centre
          </Link>
        </li>
        <li>
          <BellSimple size={18} aria-hidden="true" />
          <Link to={`${notificationsHome(role)}/preferences`} onClick={onClose}>
            Notification preferences
          </Link>
        </li>
        {role === 'student' && (
          <li>
            <Certificate size={18} aria-hidden="true" />
            <Link to="/certificates" onClick={onClose}>
              Your certificates
            </Link>
          </li>
        )}
      </ul>
    </Modal>
  );
}
