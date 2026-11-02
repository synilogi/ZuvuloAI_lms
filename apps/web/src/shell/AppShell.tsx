import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Navigate, NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { DotsThreeCircle, MoonStars, Play, Plus, Sun, X } from '@phosphor-icons/react';
import { evaluateRankLadder, type Role } from '@syniastrolms/domain';
import { useViewport } from '@/hooks/useViewport';
import { useFocusTrap } from '@/hooks/useFocusTrap';
import { useBodyScrollLock } from '@/hooks/useBodyScrollLock';
import { useAsync } from '@/hooks/useAsync';
import { cx } from '@/lib/cx';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { CountBadge } from '@/components/ui/Badge/Badge';
import { Skeleton } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { RankMeter } from '@/components/lms/rank/RankProgression';
import { CommandPalette } from '@/commands/CommandPalette';
import type { CommandContext, QuickCreateKind } from '@/commands/registry';
import { usePermissions } from '@/hooks/usePermissions';
import { pagePermission } from '@/lib/adminPermissions';
import { AccessDenied } from '@/components/page/AccessDenied';
import { usePreferences } from '@/providers/PreferencesProvider';
import { useSession } from '@/providers/SessionProvider';
import { BrandMark } from './BrandMark';
import { DesktopHeader, MobileHeader } from './Header';
import { services } from '@/services';
import { NavCountsContext, useLiveNavCounts, useNavItemCount } from './NavCounts';
import { bottomDestinations, firstOpenDestination, locate, visibleNavigation, type NavGroup, type NavItem } from './navigation';
import { QuickCreateModal } from './QuickCreateModal';
import { PageCrumbsContext, type Crumb } from './PageCrumbs';
import { ShellLayoutContext } from './ShellLayoutContext';
import { SidebarMeter } from './SidebarMeter';
import { Sidebar } from './Sidebar';
import styles from './AppShell.module.css';

const BOTTOM_NAV_H = 58;

/** The navigation this account may open. */
function useNavigation(role: Role, canOpen: (to: string) => boolean): NavGroup[] {
  return useMemo(() => visibleNavigation(role, canOpen), [role, canOpen]);
}

/**
 * The ZuviloAI app shell. At ≥768px: collapsible sidebar + header. Below: a mobile header,
 * a bottom bar with four destinations plus More, a menu drawer and a full-screen search sheet.
 */
export function AppShell() {
  const { role, user, switchRole } = useSession();
  const { can, canOpen } = usePermissions();
  const { sidebarCollapsed, toggleSidebar, theme, toggleTheme } = usePreferences();
  const { isMobile, width } = useViewport();
  const navigate = useNavigate();
  const location = useLocation();
  const toast = useToast();
  const liveCounts = useLiveNavCounts(role);
  const reviews = liveCounts.assignments;
  // The learner's own standing — never a stand-in persona's, so this must be a real call, not a fixture.
  const rankQuery = useAsync('rank-ladder', () => services.learner.getRankLadder(), { immediate: role === 'student' });

  const [paletteOpen, setPaletteOpen] = useState(false);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [quickCreate, setQuickCreate] = useState<QuickCreateKind | null>(null);
  const [scrollRoot, setScrollRoot] = useState<HTMLElement | null>(null);
  // Tablets (768–1023) start with the shell's collapsed rail so content keeps its width; the toggle still expands it.
  const [tabletExpanded, setTabletExpanded] = useState(false);
  const isTablet = width >= 768 && width < 1024;
  const collapsed = isTablet ? !tabletExpanded : sidebarCollapsed;
  const toggleRail = useCallback(() => (isTablet ? setTabletExpanded((x) => !x) : toggleSidebar()), [isTablet, toggleSidebar]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const k = e.key.toLowerCase();
      if ((e.metaKey || e.ctrlKey) && k === 'k') {
        e.preventDefault();
        setPaletteOpen((o) => !o);
      } else if ((e.metaKey || e.ctrlKey) && k === 'b') {
        e.preventDefault();
        toggleRail();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [toggleRail]);

  // Close the drawer and reset scroll on navigation
  useEffect(() => {
    setDrawerOpen(false);
    scrollRoot?.scrollTo({ top: 0 });
  }, [location.pathname, scrollRoot]);

  const commandContext: CommandContext = useMemo(
    () => ({ role, navigate, toast, toggleTheme, toggleSidebar: toggleRail, switchRole, openQuickCreate: setQuickCreate }),
    [role, navigate, toast, toggleTheme, toggleRail, switchRole],
  );

  const primaryAction = !can('catalog.edit') ? null : role === 'student' ? (
    <Button
      variant="primary"
      block
      iconStart={<Play size={15} weight="fill" />}
      onClick={() =>
        services.learning
          .listCourses()
          .then(({ courses }) => {
            const resume = courses.find((c) => c.enrollment.status === 'active' && c.next);
            navigate(resume?.next ? `/learn/${resume.course.id}/lessons/${resume.next.id}` : '/my-learning');
          })
          .catch(() => navigate('/my-learning'))
      }
      aria-label={collapsed ? 'Resume lesson' : undefined}
    >
      {!collapsed ? 'Resume lesson' : undefined}
    </Button>
  ) : (
    <Button
      variant="primary"
      block
      iconStart={<Plus size={16} />}
      onClick={() => (role === 'instructor' ? setQuickCreate('lesson') : navigate('/admin/courses/new'))}
      aria-label={collapsed ? (role === 'instructor' ? 'New lesson' : 'New course') : undefined}
    >
      {!collapsed ? (role === 'instructor' ? 'New lesson' : 'New course') : undefined}
    </Button>
  );

  const footer =
    role === 'student' ? (
      rankQuery.data ? (
        <RankMeter steps={evaluateRankLadder(rankQuery.data.ranks, rankQuery.data.standing)} />
      ) : (
        <Skeleton height={54} radius="12px" />
      )
    ) : role === 'instructor' && reviews ? (
      <SidebarMeter
        label="To mark"
        value={Math.min(reviews.value ?? 0, 20)}
        max={20}
        valueText={String(reviews.value ?? 0)}
        caption={reviews.overdue ? `${reviews.overdue} waiting more than 48 hours` : 'All marked within 48 hours'}
      />
    ) : undefined;

  const groups = useNavigation(role, canOpen);
  // The admin home is where signing in lands; an admin who may not open it goes to what they can open instead.
  const homeFallback = role === 'admin' && location.pathname === '/admin' && !canOpen('/admin') ? firstOpenDestination(groups, canOpen, '/admin') : undefined;

  const openSearch = useCallback(() => setPaletteOpen(true), []);
  const layout = useMemo(() => ({ bottomInset: isMobile ? BOTTOM_NAV_H : 0, scrollRoot, openCommandPalette: openSearch }), [isMobile, scrollRoot, openSearch]);
  const [pageCrumbs, setPageCrumbs] = useState<Crumb[]>([]);
  const crumbsValue = useMemo(() => ({ crumbs: pageCrumbs, setCrumbs: setPageCrumbs }), [pageCrumbs]);

  return (
    <PageCrumbsContext.Provider value={crumbsValue}>
      <NavCountsContext.Provider value={liveCounts}>
        <ShellLayoutContext.Provider value={layout}>
          <a href="#main" className="skip-link">
            Skip to content
          </a>
          <div className={styles.shell}>
            {!isMobile && (
              <Sidebar role={role} groups={groups} collapsed={collapsed} onToggleCollapse={toggleRail} primaryAction={primaryAction} footer={footer} />
            )}

            <div className={styles.column}>
              {isMobile ? (
                <MobileHeader onOpenMenu={() => setDrawerOpen(true)} onOpenSearch={openSearch} />
              ) : (
                <DesktopHeader onOpenSearch={openSearch} showMidCrumb={width >= 1200} />
              )}

              <main id="main" ref={setScrollRoot} className={styles.main} tabIndex={-1}>
                {/* A page the account may not open shows why, inside the shell, rather than redirecting —
                    a deep link lands somewhere that explains itself. The API refuses it too. */}
                {canOpen(location.pathname) ? (
                  <Outlet />
                ) : homeFallback ? (
                  <Navigate to={homeFallback} replace />
                ) : (
                  <AccessDenied permission={pagePermission(location.pathname)} />
                )}
              </main>

              {isMobile && <BottomNav onMore={() => setDrawerOpen(true)} moreOpen={drawerOpen} />}
            </div>
          </div>

          {isMobile && drawerOpen && (
            <NavDrawer
              onClose={() => setDrawerOpen(false)}
              theme={theme}
              onToggleTheme={toggleTheme}
              userName={user.name}
              userMeta={`${user.descriptor} · ${user.email}`}
            />
          )}

          <CommandPalette open={paletteOpen} onClose={() => setPaletteOpen(false)} context={commandContext} />
          <QuickCreateModal kind={quickCreate} onClose={() => setQuickCreate(null)} />
        </ShellLayoutContext.Provider>
      </NavCountsContext.Provider>
    </PageCrumbsContext.Provider>
  );
}

function BottomNav({ onMore, moreOpen }: { onMore: () => void; moreOpen: boolean }) {
  const { role } = useSession();
  const { canOpen } = usePermissions();
  const { pathname } = useLocation();
  const active = locate(role, pathname);
  const visible = useNavigation(role, canOpen).flatMap((g) => g.items);
  const items = bottomDestinations[role].map((id) => visible.find((i) => i.id === id)).filter((i): i is NavItem => Boolean(i));

  return (
    <nav aria-label="Primary" className={styles.bottomNav}>
      {items.map((item) => {
        const on = active?.item.id === item.id && !moreOpen;
        return (
          <NavLink key={item.id} to={item.to} className={cx(styles.bottomItem, on && styles.bottomItemActive)} aria-current={on ? 'page' : undefined}>
            <span className={styles.bottomIcon}>
              {item.icon}
              <BottomLiveDot item={item} />
            </span>
            <span className={styles.bottomLabel}>{item.short ?? item.label}</span>
          </NavLink>
        );
      })}
      <button type="button" className={cx(styles.bottomItem, moreOpen && styles.bottomItemActive)} onClick={onMore} aria-expanded={moreOpen}>
        <span className={styles.bottomIcon}>
          <DotsThreeCircle size={22} />
        </span>
        <span className={styles.bottomLabel}>More</span>
      </button>
    </nav>
  );
}

/** The bottom bar's live marker, shown only while a class really is live. */
function BottomLiveDot({ item }: { item: NavItem }) {
  const { count, label } = useNavItemCount(item);
  return item.countTone === 'danger' && count ? <span className={styles.bottomLive} role="img" aria-label={label} /> : null;
}

function NavDrawer({
  onClose,
  theme,
  onToggleTheme,
  userName,
  userMeta,
}: {
  onClose: () => void;
  theme: string;
  onToggleTheme: () => void;
  userName: string;
  userMeta: string;
}) {
  const { role } = useSession();
  const { canOpen } = usePermissions();
  const { pathname } = useLocation();
  const active = locate(role, pathname);
  const groups = useNavigation(role, canOpen);
  const ref = useRef<HTMLDivElement>(null);
  useFocusTrap(true, ref);
  useBodyScrollLock(true);

  return (
    <div className={styles.drawerRoot} onKeyDown={(e) => e.key === 'Escape' && onClose()}>
      <div className={styles.drawerScrim} onClick={onClose} aria-hidden="true" />
      <div ref={ref} role="dialog" aria-modal="true" aria-label="Menu" className={styles.drawer} data-surface="ink">
        <div className={styles.drawerHead}>
          <span className={styles.brandTile}>
            <BrandMark />
          </span>
          <span className={styles.drawerBrand}>ZuviloAI</span>
          <IconButton label="Close menu" size="lg" icon={<X size={20} />} onClick={onClose} />
        </div>
        <nav aria-label="Main" className={styles.drawerNav}>
          {groups.map((group) => (
            <div key={group.id} className={styles.drawerGroup}>
              {group.label && <div className={styles.groupLabel}>{group.label}</div>}
              {group.items.map((item) => (
                <div key={item.id}>
                  <NavLink
                    to={item.children ? item.children[0].to : item.to}
                    className={cx(styles.drawerItem, active?.item.id === item.id && styles.navItemActive)}
                    aria-current={active?.item.id === item.id ? 'page' : undefined}
                  >
                    {item.icon}
                    <span className={styles.navLabel}>{item.label}</span>
                    <DrawerCount item={item} />
                  </NavLink>
                  {item.children && active?.item.id === item.id && (
                    <div className={styles.navKids}>
                      {item.children.map((kid) => (
                        <NavLink
                          key={kid.to}
                          to={kid.to}
                          end
                          className={cx(styles.navKid, styles.drawerKid, active?.leaf?.to === kid.to && styles.navKidActive)}
                        >
                          <span>{kid.label}</span>
                        </NavLink>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          ))}
        </nav>
        <div className={styles.drawerFoot}>
          <Avatar name={userName} size={32} tone="accent" />
          <span className={styles.drawerUser}>
            <span className={styles.drawerUserName}>{userName}</span>
            <span className={styles.drawerUserMeta}>{userMeta}</span>
          </span>
          <IconButton label="Toggle theme" size="lg" icon={theme === 'dark' ? <Sun size={20} /> : <MoonStars size={20} />} onClick={onToggleTheme} />
        </div>
      </div>
    </div>
  );
}

function DrawerCount({ item }: { item: NavItem }) {
  const { count } = useNavItemCount(item);
  return count ? <CountBadge tone={item.countTone ?? 'info'}>{count}</CountBadge> : null;
}
