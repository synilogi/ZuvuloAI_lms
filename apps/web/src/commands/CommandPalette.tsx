import { Fragment, useEffect, useId, useMemo, useRef, useState, type KeyboardEvent } from 'react';
import { createPortal } from 'react-dom';
import { ArrowLeft, ArrowUpRight, MagnifyingGlass } from '@phosphor-icons/react';
import { useBodyScrollLock } from '@/hooks/useBodyScrollLock';
import { useFocusTrap } from '@/hooks/useFocusTrap';
import { useViewport } from '@/hooks/useViewport';
import { cx } from '@/lib/cx';
import { IconButton } from '@/components/ui/Button/Button';
import { Kbd } from '@/components/ui/Badge/Badge';
import type { Course } from '@syniastrolms/domain';
import { API_MODE } from '@/lib/apiMode';
import { services } from '@/services';
import { resolveCommands, type CommandContext } from './registry';
import styles from './CommandPalette.module.css';

interface CommandPaletteProps {
  open: boolean;
  onClose: () => void;
  context: CommandContext;
}

/** ⌘K palette on desktop; a full-screen search sheet on mobile (the shell's two search patterns). */
export function CommandPalette({ open, onClose, context }: CommandPaletteProps) {
  if (!open) return null;
  return <PaletteBody onClose={onClose} context={context} />;
}

function PaletteBody({ onClose, context }: Omit<CommandPaletteProps, 'open'>) {
  const [query, setQuery] = useState('');
  const [index, setIndex] = useState(0);
  const { isMobile } = useViewport();
  const dialogRef = useRef<HTMLDivElement>(null);
  const listRef = useRef<HTMLDivElement>(null);
  const listId = useId();
  useFocusTrap(true, dialogRef);
  useBodyScrollLock(true);

  // Against the real API the search covers the published catalog; the demo build searches fixtures.
  const [catalog, setCatalog] = useState<Course[]>();
  useEffect(() => {
    if (API_MODE !== 'http') return;
    let cancelled = false;
    services.catalog
      .listCourses()
      .then((list) => !cancelled && setCatalog(list))
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);

  const results = useMemo(() => resolveCommands(context.role, query, catalog), [context.role, query, catalog]);

  useEffect(() => setIndex(0), [query]);
  useEffect(() => {
    listRef.current?.querySelector<HTMLElement>(`[data-index="${index}"]`)?.scrollIntoView({ block: 'nearest' });
  }, [index]);

  const run = (i: number) => {
    const cmd = results[i];
    if (!cmd) return;
    onClose();
    cmd.run(context);
  };

  const onKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setIndex((i) => Math.min(results.length - 1, i + 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setIndex((i) => Math.max(0, i - 1));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      run(index);
    } else if (e.key === 'Escape') {
      e.preventDefault();
      e.stopPropagation();
      onClose();
    }
  };

  const optionId = (i: number) => `${listId}-opt-${i}`;
  let lastGroup = '';

  const list = (
    <div ref={listRef} id={listId} role="listbox" aria-label="Commands" className={styles.list}>
      {results.map((cmd, i) => {
        const header = cmd.group !== lastGroup;
        lastGroup = cmd.group;
        return (
          <Fragment key={cmd.id}>
            {header && (
              <div className={styles.group} role="presentation">
                {cmd.group}
              </div>
            )}
            <div
              id={optionId(i)}
              role="option"
              aria-selected={i === index}
              data-index={i}
              className={cx(styles.option, i === index && styles.active)}
              onMouseMove={() => setIndex(i)}
              onClick={() => run(i)}
            >
              <span className={styles.optionIcon} aria-hidden="true">
                {cmd.icon}
              </span>
              <span className={styles.optionText}>
                <span className={styles.optionLabel}>{cmd.label}</span>
                {cmd.hint && <span className={cx(styles.hint, cmd.hintTone && styles[cmd.hintTone])}>{cmd.hint}</span>}
              </span>
              {isMobile && <ArrowUpRight size={15} className={styles.mobileArrow} aria-hidden="true" />}
            </div>
          </Fragment>
        );
      })}
      {results.length === 0 && (
        <div className={styles.empty}>
          <MagnifyingGlass size={26} />
          <p>Nothing matches “{query}”. Try a lesson name, a planet, or a course.</p>
        </div>
      )}
    </div>
  );

  const input = (
    <input
      type="text"
      role="combobox"
      aria-expanded="true"
      aria-controls={listId}
      aria-activedescendant={results[index] ? optionId(index) : undefined}
      aria-autocomplete="list"
      data-autofocus
      value={query}
      onChange={(e) => setQuery(e.target.value)}
      placeholder={context.role === 'student' ? 'Search lessons, courses, or jump to…' : 'Type a command or search…'}
      className={styles.input}
    />
  );

  if (isMobile) {
    return createPortal(
      <div ref={dialogRef} role="dialog" aria-modal="true" aria-label="Search" className={styles.sheet} onKeyDown={onKeyDown}>
        <div className={styles.sheetHead}>
          <IconButton label="Close search" size="lg" icon={<ArrowLeft size={21} />} onClick={onClose} />
          {input}
        </div>
        {list}
      </div>,
      document.body,
    );
  }

  return createPortal(
    <div className={styles.root} onKeyDown={onKeyDown}>
      <div className={styles.scrim} onClick={onClose} aria-hidden="true" />
      <div ref={dialogRef} role="dialog" aria-modal="true" aria-label="Command menu" className={styles.dialog}>
        <div className={styles.head}>
          <MagnifyingGlass size={19} className={styles.headIcon} aria-hidden="true" />
          {input}
          <Kbd>ESC</Kbd>
        </div>
        {list}
        <div className={styles.foot} aria-hidden="true">
          <span>↑↓ navigate</span>
          <span>↵ open</span>
          <span>⌘K toggle</span>
        </div>
      </div>
    </div>,
    document.body,
  );
}
