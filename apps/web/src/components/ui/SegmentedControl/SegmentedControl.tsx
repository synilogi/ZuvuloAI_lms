import { useEffect, useRef, useState, type KeyboardEvent, type ReactNode } from 'react';
import { cx } from '@/lib/cx';
import styles from './SegmentedControl.module.css';

export interface Segment<T extends string> {
  value: T;
  label: ReactNode;
  icon?: ReactNode;
  count?: number;
}

interface SegmentedControlProps<T extends string> {
  label: string;
  value: T;
  onChange: (value: T) => void;
  segments: Segment<T>[];
  size?: 'sm' | 'md';
  /** "tabs" wires tab/tabpanel semantics; "radio" is for a view or filter switch. */
  semantics?: 'tabs' | 'radio';
  idPrefix?: string;
  className?: string;
}

/** The shell's pill tablist — surface-2 track, selected segment raised on surface with sh-sm. */
export function SegmentedControl<T extends string>({
  label,
  value,
  onChange,
  segments,
  size = 'md',
  semantics = 'radio',
  idPrefix,
  className,
}: SegmentedControlProps<T>) {
  const ref = useRef<HTMLDivElement>(null);
  const isTabs = semantics === 'tabs';
  const [overflow, setOverflow] = useState<'start' | 'end' | 'both' | undefined>();

  // A track wider than its space fades at the edge that has more segments, so they read as scrollable.
  useEffect(() => {
    const track = ref.current;
    if (!track) return;
    const measure = () => {
      const max = track.scrollWidth - track.clientWidth;
      const before = track.scrollLeft > 1;
      const after = track.scrollLeft < max - 1;
      setOverflow(max <= 1 ? undefined : before && after ? 'both' : before ? 'start' : 'end');
    };
    measure();
    track.addEventListener('scroll', measure, { passive: true });
    const observer = typeof ResizeObserver === 'undefined' ? undefined : new ResizeObserver(measure);
    observer?.observe(track);
    return () => {
      track.removeEventListener('scroll', measure);
      observer?.disconnect();
    };
  }, [segments.length]);

  // Keep the selected segment visible when the track scrolls horizontally on narrow screens.
  useEffect(() => {
    const track = ref.current;
    const selected = track?.querySelector<HTMLElement>('[aria-selected="true"], [aria-checked="true"]');
    if (!track || !selected || track.scrollWidth <= track.clientWidth) return;
    const left = selected.offsetLeft - (track.clientWidth - selected.offsetWidth) / 2;
    track.scrollTo({ left: Math.max(0, left), behavior: 'smooth' });
  }, [value]);

  const onKeyDown = (e: KeyboardEvent) => {
    const i = segments.findIndex((s) => s.value === value);
    let next = i;
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') next = (i + 1) % segments.length;
    else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') next = (i - 1 + segments.length) % segments.length;
    else if (e.key === 'Home') next = 0;
    else if (e.key === 'End') next = segments.length - 1;
    else return;
    e.preventDefault();
    onChange(segments[next].value);
    requestAnimationFrame(() => ref.current?.querySelectorAll<HTMLButtonElement>('button')[next]?.focus());
  };

  return (
    <div
      ref={ref}
      role={isTabs ? 'tablist' : 'radiogroup'}
      aria-label={label}
      className={cx(styles.track, size === 'sm' && styles.sm, className)}
      data-overflow={overflow}
      onKeyDown={onKeyDown}
    >
      {segments.map((s) => {
        const selected = s.value === value;
        return (
          <button
            key={s.value}
            type="button"
            role={isTabs ? 'tab' : 'radio'}
            id={idPrefix ? `${idPrefix}-tab-${s.value}` : undefined}
            aria-controls={isTabs && idPrefix ? `${idPrefix}-panel` : undefined}
            aria-selected={isTabs ? selected : undefined}
            aria-checked={isTabs ? undefined : selected}
            tabIndex={selected ? 0 : -1}
            className={cx(styles.segment, selected && styles.selected)}
            onClick={() => onChange(s.value)}
          >
            {s.icon}
            <span>{s.label}</span>
            {s.count !== undefined && <span className={styles.count}>{s.count.toLocaleString('en-IN')}</span>}
          </button>
        );
      })}
    </div>
  );
}
