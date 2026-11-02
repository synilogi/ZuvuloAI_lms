import { useCallback, useRef, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import {
  Bell,
  BellSimple,
  CaretDown,
  CaretRight,
  Certificate,
  Check,
  GearSix,
  House,
  Keyboard,
  Lifebuoy,
  List,
  MagnifyingGlass,
  MoonStars,
  Receipt,
  SignOut,
  Sun,
  UserCircle,
} from '@phosphor-icons/react';
import type { Role } from '@syniastrolms/domain';
import { useDismiss } from '@/hooks/useDismiss';
import { useNow } from '@/hooks/useNow';
import { cx } from '@/lib/cx';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { IconChip, Kbd } from '@/components/ui/Badge/Badge';
import { IconButton } from '@/components/ui/Button/Button';
import { Menu } from '@/components/ui/Menu/Menu';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { usePreferences } from '@/providers/PreferencesProvider';
import { API_MODE, useSession } from '@/providers/SessionProvider';
import { CATEGORY_META, notificationTime } from '@/components/lms/notification/notificationMeta';
import { services } from '@/services';
import { announceNotificationsChanged, notificationsHome, useNotificationSummary } from './notificationSummary';
import { locate, workspaceLabel } from './navigation';
import { usePageCrumbList } from './PageCrumbs';
import { HelpDialog, ProfileDialog } from './AccountDialogs';
import styles from './AppShell.module.css';

const ROLE_LABEL: Record<Role, string> = { student: 'Student', instructor: 'Instructor', admin: 'Admin', superadmin: 'Super admin' };

function useCrumbs() {
  const { role } = useSession();
  const { pathname } = useLocation();
  const pageCrumbs = usePageCrumbList();
  const hit = locate(role, pathname);
  const navLeaf = hit?.leaf && hit.leaf.to !== hit.item.to ? hit.leaf : undefined;
  // Navigation gives Item › Child; a page may add its own trail below that.
  const nav = [...(hit ? [{ label: hit.item.label, to: hit.item.to }] : []), ...(navLeaf ? [{ label: navLeaf.label, to: navLeaf.to }] : [])];
  // A page crumb that repeats a navigation crumb is dropped rather than shown twice.
  const all = [...nav, ...pageCrumbs.filter((c) => !nav.some((n) => n.label === c.label && n.to === c.to))];
  const leaf = all[all.length - 1] ?? { label: 'Not found' };
  const trail = all.slice(0, -1).map((c) => ({ label: c.label, to: c.to ?? pathname }));
  return {
    section: hit?.group?.label ?? workspaceLabel[role],
    leaf: leaf.label,
    trail,
    parent: trail[trail.length - 1],
  };
}

export function DesktopHeader({ onOpenSearch, showMidCrumb }: { onOpenSearch: () => void; showMidCrumb: boolean }) {
  const { role } = useSession();
  const crumbs = useCrumbs();
  const { theme, toggleTheme } = usePreferences();
  const [helpOpen, setHelpOpen] = useState(false);

  return (
    <header className={styles.header}>
      <nav aria-label="Breadcrumb" className={styles.breadcrumb}>
        <House size={16} aria-hidden="true" />
        <Link to="/" className={styles.crumbLink}>
          Home
        </Link>
        {showMidCrumb && crumbs.trail.length < 2 && (
          <>
            <CaretRight size={11} className={styles.crumbSep} aria-hidden="true" />
            <span className={styles.crumbText}>{crumbs.section}</span>
          </>
        )}
        {crumbs.trail.length > 2 && (
          <span
            className={styles.crumbGroup}
            title={crumbs.trail
              .slice(0, -2)
              .map((c) => c.label)
              .join(' › ')}
          >
            <CaretRight size={11} className={styles.crumbSep} aria-hidden="true" />
            <Link to={crumbs.trail[0].to} className={styles.crumbLink} aria-label={crumbs.trail[0].label}>
              …
            </Link>
          </span>
        )}
        {crumbs.trail.slice(-2).map((crumb) => (
          // Short names like “Quizzes” never truncate; only long course and chapter names give way.
          <span key={crumb.to + crumb.label} className={cx(styles.crumbGroup, crumb.label.length <= 16 && styles.crumbFixed)}>
            <CaretRight size={11} className={styles.crumbSep} aria-hidden="true" />
            <Link to={crumb.to} className={styles.crumbLink}>
              {crumb.label}
            </Link>
          </span>
        ))}
        <CaretRight size={11} className={styles.crumbSep} aria-hidden="true" />
        <span aria-current="page" className={cx(styles.crumbLeaf, typeof crumbs.leaf === 'string' && crumbs.leaf.length <= 20 && styles.crumbFixed)}>
          {crumbs.leaf}
        </span>
      </nav>

      <button type="button" className={styles.searchTrigger} onClick={onOpenSearch}>
        <MagnifyingGlass size={16} aria-hidden="true" />
        <span className={styles.searchText}>
          {role === 'student'
            ? 'Search lessons, courses, live classes…'
            : role === 'superadmin'
              ? 'Search pages and actions…'
              : 'Search courses, learners, lessons…'}
        </span>
        <Kbd>⌘K</Kbd>
      </button>

      <div className={styles.headerActions}>
        <NotificationsButton />
        <IconButton label="Help and shortcuts" icon={<Lifebuoy size={19} />} onClick={() => setHelpOpen(true)} />
        <IconButton
          label={theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme'}
          icon={theme === 'dark' ? <Sun size={19} /> : <MoonStars size={19} />}
          onClick={toggleTheme}
        />
        <AccountMenu />
      </div>
      <HelpDialog open={helpOpen} onClose={() => setHelpOpen(false)} />
    </header>
  );
}

export function MobileHeader({ onOpenMenu, onOpenSearch }: { onOpenMenu: () => void; onOpenSearch: () => void }) {
  const crumbs = useCrumbs();
  const navigate = useNavigate();
  const { user, role } = useSession();
  const summary = useNotificationSummary(user.id);
  return (
    <header className={styles.mobileHeader}>
      <IconButton label="Open menu" size="lg" icon={<List size={22} />} onClick={onOpenMenu} />
      <span className={styles.mobileTitle}>
        <span className={styles.mobileTitleLeaf}>{crumbs.leaf}</span>
        <span className={styles.mobileTitleSection}>{crumbs.parent?.label ?? crumbs.section}</span>
      </span>
      <IconButton label="Search" size="lg" icon={<MagnifyingGlass size={21} />} onClick={onOpenSearch} />
      <span className={styles.popWrap}>
        <IconButton
          label={summary.unread ? `Notifications, ${summary.unread} unread` : 'Notifications'}
          size="lg"
          icon={<Bell size={21} />}
          onClick={() => navigate(notificationsHome(role))}
        />
        {summary.unread > 0 && <span className={styles.unreadDot} aria-hidden="true" />}
      </span>
    </header>
  );
}

function NotificationsButton() {
  const { user, role } = useSession();
  const now = useNow();
  const [open, setOpen] = useState(false);
  const wrapRef = useRef<HTMLDivElement>(null);
  const close = useCallback(() => setOpen(false), []);
  useDismiss(open, close, [wrapRef]);
  const summary = useNotificationSummary(user.id);
  const home = notificationsHome(role);

  const markAll = async () => {
    await services.notifications.markAllRead(user.id).catch(() => 0);
    announceNotificationsChanged();
  };

  return (
    <div ref={wrapRef} className={styles.popWrap}>
      <IconButton
        label={summary.unread ? `Notifications, ${summary.unread} unread` : 'Notifications'}
        aria-expanded={open}
        icon={<Bell size={19} />}
        onClick={() => setOpen((o) => !o)}
      />
      {summary.unread > 0 && <span className={styles.unreadDot} aria-hidden="true" />}
      {open && (
        <div role="dialog" aria-label="Notifications" className={cx(styles.popover, styles.notifPop)}>
          <div className={styles.popHead}>
            <strong>
              Notifications
              {summary.unread > 0 && <span className={styles.popCount}>{summary.unread} unread</span>}
            </strong>
            {summary.unread > 0 && (
              <button type="button" className={styles.linkButton} onClick={markAll}>
                Mark all read
              </button>
            )}
          </div>
          {summary.rows.length === 0 ? (
            <p className={styles.notifEmpty}>
              <BellSimple size={20} aria-hidden="true" />
              {summary.failed ? 'Notifications didn’t load. Open the notification centre to try again.' : summary.loaded ? 'You’re all caught up.' : 'Loading…'}
            </p>
          ) : (
            <ul className={styles.notifList}>
              {summary.rows.map((n) => {
                const meta = CATEGORY_META[n.category];
                const Glyph = meta.icon;
                return (
                  <li key={n.id} className={styles.notifItem} data-unread={!n.readAt || undefined}>
                    <IconChip tone={meta.tone}>
                      <Glyph size={17} weight="duotone" />
                    </IconChip>
                    <Link to={`${home}/${n.id}`} className={styles.notifLink} onClick={close}>
                      <span className={styles.notifText}>
                        {n.title}
                        {!n.readAt && <span className="sr-only"> · unread</span>}
                      </span>
                      <span className={styles.notifTime}>
                        {meta.label} · {notificationTime(n.createdAt, now)}
                      </span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          )}
          <div className={styles.popFoot}>
            <Link to={home} className={styles.popFootLink} onClick={close}>
              See all notifications
            </Link>
            <Link to={`${home}/preferences`} className={styles.popFootLink} onClick={close}>
              <GearSix size={14} aria-hidden="true" /> Preferences
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}

function AccountMenu() {
  const { user, role, switchRole, logout } = useSession();
  const toast = useToast();
  const navigate = useNavigate();
  const [dialog, setDialog] = useState<null | 'profile' | 'shortcuts' | 'signout'>(null);

  return (
    <>
      <Menu
        align="end"
        width={260}
        header={
          <div className={styles.accountHead}>
            <div className={styles.accountName}>{user.name}</div>
            <div className={styles.accountEmail}>{user.email}</div>
          </div>
        }
        trigger={(props) => (
          <button type="button" className={styles.accountButton} {...props}>
            <Avatar name={user.name} size={32} tone="accent" />
            <span className={styles.accountText}>
              <span className={styles.accountTextName}>{user.name}</span>
              <span className={styles.accountTextRole}>{user.descriptor}</span>
            </span>
            <CaretDown size={12} className={styles.caret} aria-hidden="true" />
          </button>
        )}
        sections={[
          {
            items: [
              { id: 'profile', label: 'Profile', icon: <UserCircle size={17} />, onSelect: () => setDialog('profile') },
              ...(role === 'student'
                ? [
                    { id: 'certs', label: 'My certificates', icon: <Certificate size={17} />, onSelect: () => navigate('/certificates') },
                    { id: 'purchases', label: 'Purchases', icon: <Receipt size={17} />, onSelect: () => navigate('/purchases') },
                  ]
                : []),
              ...(role === 'admin'
                ? [{ id: 'settings', label: 'Platform settings', icon: <GearSix size={17} />, onSelect: () => navigate('/admin/settings/general') }]
                : []),
              {
                id: 'notifications',
                label: 'Notification preferences',
                icon: <BellSimple size={17} />,
                onSelect: () => navigate(`${notificationsHome(role)}/preferences`),
              },
              { id: 'keys', label: 'Keyboard shortcuts', icon: <Keyboard size={17} />, hint: '⌘K', onSelect: () => setDialog('shortcuts') },
            ],
          },
          ...(API_MODE === 'mock'
            ? [
                {
                  label: 'View as (demo)',
                  items: (['student', 'instructor', 'admin'] as Role[]).map((r) => ({
                    id: `role-${r}`,
                    label: ROLE_LABEL[r],
                    icon: r === role ? <Check size={17} weight="bold" /> : <span />,
                    onSelect: () => {
                      switchRole(r);
                      toast({ kind: 'success', title: `Viewing as ${ROLE_LABEL[r].toLowerCase()}`, text: 'Navigation and commands have changed to match.' });
                    },
                  })),
                },
              ]
            : []),
          { items: [{ id: 'signout', label: 'Sign out', icon: <SignOut size={17} />, onSelect: () => setDialog('signout') }] },
        ]}
      />
      <ProfileDialog open={dialog === 'profile'} onClose={() => setDialog(null)} />
      <HelpDialog open={dialog === 'shortcuts'} onClose={() => setDialog(null)} focus="shortcuts" />
      <ConfirmDialog
        open={dialog === 'signout'}
        onClose={() => setDialog(null)}
        onConfirm={() => {
          setDialog(null);
          if (API_MODE === 'http') logout();
          navigate('/signed-out');
        }}
        title="Sign out of ZuviloAI?"
        description="You’ll need to sign in again on this device. Your progress and drafts stay saved."
        confirmLabel="Sign out"
      />
    </>
  );
}
