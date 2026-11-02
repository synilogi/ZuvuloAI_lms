import { useEffect, useState, type KeyboardEvent, type ReactNode } from 'react';
import { NavLink, useLocation, useNavigate } from 'react-router-dom';
import { ArrowLineLeft, ArrowLineRight, CaretDown, CaretRight } from '@phosphor-icons/react';
import type { Role } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { CountBadge, Kbd } from '@/components/ui/Badge/Badge';
import { BrandMark } from './BrandMark';
import { useNavItemCount } from './NavCounts';
import { locate, workspaceLabel, type NavGroup, type NavItem } from './navigation';
import styles from './AppShell.module.css';

interface SidebarProps {
  role: Role;
  /** The groups to draw — already filtered for what this account may open. */
  groups: NavGroup[];
  collapsed: boolean;
  onToggleCollapse: () => void;
  primaryAction: ReactNode;
  footer?: ReactNode;
}

/** Arrow keys move between nav items, as in the shell. */
function onNavKeys(e: KeyboardEvent<HTMLElement>) {
  if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp') return;
  e.preventDefault();
  const items = Array.from(e.currentTarget.querySelectorAll<HTMLElement>('[data-navitem]'));
  const i = items.indexOf(document.activeElement as HTMLElement);
  const next = e.key === 'ArrowDown' ? Math.min(items.length - 1, i + 1) : Math.max(0, i - 1);
  items[next]?.focus();
}

export function Sidebar({ role, groups, collapsed, onToggleCollapse, primaryAction, footer }: SidebarProps) {
  const { pathname } = useLocation();
  const active = locate(role, pathname);
  const expanded = !collapsed;

  return (
    <aside className={cx(styles.sidebar, collapsed && styles.sidebarCollapsed)} aria-label="Sidebar" data-surface="ink">
      <div className={styles.brand}>
        <span className={styles.brandTile}>
          <BrandMark />
        </span>
        {expanded && (
          <span className={styles.brandText}>
            <span className={styles.brandName}>ZuviloAI</span>
            <span className={styles.brandSub}>{workspaceLabel[role]}</span>
          </span>
        )}
      </div>

      <div className={styles.primaryAction}>{primaryAction}</div>

      <nav aria-label="Main" className={styles.nav} onKeyDown={onNavKeys}>
        {groups.map((group) => (
          <div key={group.id} className={styles.navGroup}>
            {group.label && expanded && <div className={styles.groupLabel}>{group.label}</div>}
            {group.label && collapsed && <div className={styles.groupRule} aria-hidden="true" />}
            {group.items.map((item) => (
              <SidebarItem key={item.id} item={item} expanded={expanded} isActive={active?.item.id === item.id} activeLeaf={active?.leaf?.to} />
            ))}
          </div>
        ))}
      </nav>

      <div className={styles.sidebarFoot}>
        {expanded && footer}
        <button
          type="button"
          className={cx(styles.navItem, !expanded && styles.navItemCollapsed)}
          onClick={onToggleCollapse}
          title="Toggle sidebar (⌘B)"
          aria-label={expanded ? 'Collapse sidebar' : 'Expand sidebar'}
        >
          {expanded ? <ArrowLineLeft size={18} /> : <ArrowLineRight size={18} />}
          {expanded && (
            <>
              <span className={styles.navLabel}>Collapse</span>
              <Kbd plain>⌘B</Kbd>
            </>
          )}
        </button>
      </div>
    </aside>
  );
}

function SidebarItem({ item, expanded, isActive, activeLeaf }: { item: NavItem; expanded: boolean; isActive: boolean; activeLeaf?: string }) {
  const navigate = useNavigate();
  const [open, setOpen] = useState(isActive);
  useEffect(() => {
    if (isActive) setOpen(true);
  }, [isActive]);

  const badge = useNavItemCount(item);
  const count = badge.count && expanded && (
    <CountBadge tone={item.countTone ?? 'info'} label={badge.label ?? `${badge.count} new`}>
      {item.countTone === 'danger' && <span className={styles.liveDot} aria-hidden="true" />}
      {badge.count}
    </CountBadge>
  );

  const tip = !expanded && (
    <span role="tooltip" className={styles.navTip}>
      {item.label}
    </span>
  );

  if (item.children) {
    return (
      <div className={styles.navEntry}>
        <button
          type="button"
          data-navitem
          aria-expanded={expanded ? open : undefined}
          aria-label={expanded ? undefined : item.label}
          className={cx(styles.navItem, isActive && styles.navItemActive, !expanded && styles.navItemCollapsed)}
          onClick={() => (expanded ? setOpen((o) => !o) : navigate(item.children![0].to))}
        >
          {item.icon}
          {expanded && <span className={styles.navLabel}>{item.label}</span>}
          {count}
          {expanded && (open ? <CaretDown size={12} className={styles.caret} /> : <CaretRight size={12} className={styles.caret} />)}
          {tip}
        </button>
        {expanded && open && (
          <div className={styles.navKids}>
            {item.children.map((kid) => (
              <NavLink
                key={kid.to}
                to={kid.to}
                end
                data-navitem
                className={cx(styles.navKid, activeLeaf === kid.to && styles.navKidActive)}
                aria-current={activeLeaf === kid.to ? 'page' : undefined}
              >
                {kid.label}
              </NavLink>
            ))}
          </div>
        )}
      </div>
    );
  }

  return (
    <div className={styles.navEntry}>
      <NavLink
        to={item.to}
        data-navitem
        aria-label={expanded ? undefined : item.label}
        className={cx(styles.navItem, isActive && styles.navItemActive, !expanded && styles.navItemCollapsed)}
        aria-current={isActive ? 'page' : undefined}
      >
        {item.icon}
        {expanded && <span className={styles.navLabel}>{item.label}</span>}
        {count}
        {tip}
      </NavLink>
    </div>
  );
}
