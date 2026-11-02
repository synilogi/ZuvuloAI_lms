import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { Command, MoonStars, Sun } from '@phosphor-icons/react';
import { LMS_STATUSES } from '@syniastrolms/domain';
import { useScrollSpy } from '@/hooks/useScrollSpy';
import { cx } from '@/lib/cx';
import { Button } from '@/components/ui/Button/Button';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { verifiedWidths } from '@/design/tokens';
import { usePreferences } from '@/providers/PreferencesProvider';
import { useShellLayout } from '@/shell/ShellLayoutContext';
import { SectionRegistryProvider, useSectionEntries } from './doc/Doc';
import styles from './DesignSystem.module.css';

const CHAPTERS = [
  { value: '/design-system', label: 'Foundations' },
  { value: '/design-system/components', label: 'Components' },
  { value: '/design-system/learning', label: 'Learning patterns' },
  { value: '/design-system/states', label: 'States' },
  { value: '/design-system/responsive', label: 'Responsive' },
];

const FACTS = [
  { value: String(LMS_STATUSES.length), label: 'learning states, each with label, icon and shape' },
  { value: '3', label: 'density modes — immersive, balanced, dense' },
  { value: '38', label: 'learning components on the shell kit' },
  { value: String(verifiedWidths.length), label: 'widths verified, 320 to 1920' },
];

export default function DesignSystemLayout() {
  return (
    <SectionRegistryProvider>
      <LayoutBody />
    </SectionRegistryProvider>
  );
}

function LayoutBody() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const { theme, toggleTheme } = usePreferences();
  const current = CHAPTERS.find((c) => c.value === pathname)?.value ?? CHAPTERS[0].value;

  const { openCommandPalette } = useShellLayout();

  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <div className={styles.headerText}>
          <span className={styles.eyebrow}>Module 01 · LMS foundation</span>
          <h1 className={styles.title}>Learning design system</h1>
          <p className={styles.lead}>
            How ZuviloAI teaches: the progress, status and course patterns every learning screen is composed from — drawn from the same tokens, type and
            surfaces as the app shell, so the LMS reads as one product.
          </p>
        </div>
        <div className={styles.headerActions}>
          <Button variant="primary" iconStart={<Command size={16} />} onClick={openCommandPalette}>
            Command menu
          </Button>
          <Button iconStart={theme === 'dark' ? <Sun size={16} /> : <MoonStars size={16} />} onClick={toggleTheme}>
            {theme === 'dark' ? 'Light' : 'Dark'} theme
          </Button>
        </div>
      </header>

      <dl className={styles.facts}>
        {FACTS.map((f) => (
          <div key={f.label} className={styles.fact}>
            <dt className={styles.factValue}>{f.value}</dt>
            <dd className={styles.factLabel}>{f.label}</dd>
          </div>
        ))}
      </dl>

      <div className={styles.tabsRow}>
        <SegmentedControl label="Design system chapters" semantics="tabs" idPrefix="ds" value={current} onChange={(v) => navigate(v)} segments={CHAPTERS} />
      </div>

      <div className={styles.chapter}>
        <div id="ds-panel" role="tabpanel" aria-labelledby={`ds-tab-${current}`} className={styles.chapterBody}>
          <Outlet />
        </div>
        <OnThisPage />
      </div>
    </div>
  );
}

function OnThisPage() {
  const entries = useSectionEntries();
  const { scrollRoot } = useShellLayout();
  const active = useScrollSpy(
    entries.map((e) => e.id),
    scrollRoot,
  );
  if (entries.length === 0) return null;

  return (
    <nav className={styles.toc} aria-label="On this page">
      <span className={styles.tocLabel}>On this page</span>
      <ol className={styles.tocList}>
        {entries.map((e) => (
          <li key={e.id}>
            <a
              href={`#${e.id}`}
              className={cx(styles.tocLink, active === e.id && styles.tocActive)}
              aria-current={active === e.id ? 'location' : undefined}
              onClick={(ev) => {
                ev.preventDefault();
                document.getElementById(e.id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
                history.replaceState(null, '', `#${e.id}`);
              }}
            >
              {e.title}
            </a>
          </li>
        ))}
      </ol>
    </nav>
  );
}
