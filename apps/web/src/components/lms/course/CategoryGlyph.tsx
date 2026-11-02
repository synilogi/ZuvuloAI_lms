import type { CategoryGlyph as Glyph } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import styles from './CategoryGlyph.module.css';

export const glyphLabels: Record<Glyph, string> = {
  sun: 'Sun',
  moon: 'Moon',
  houses: 'Grid',
  orbits: 'Orbits',
  nakshatra: 'Star ring',
  hourglass: 'Time',
  lotus: 'Lotus',
  compass: 'Directions',
};

/**
 * A category's emblem — the same fine-line language as course covers, reduced to a mark
 * that reads at 24px in a table and at 96px in a detail panel.
 */
export function CategoryGlyph({ glyph, size = 40, className, label }: { glyph: Glyph; size?: number; className?: string; label?: string }) {
  return (
    <span
      className={cx(styles.glyph, className)}
      style={{ width: size, height: size }}
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <svg viewBox="0 0 48 48" className={styles.art}>
        <GlyphArt glyph={glyph} />
      </svg>
    </span>
  );
}

function GlyphArt({ glyph }: { glyph: Glyph }) {
  switch (glyph) {
    case 'sun':
      return (
        <g>
          <circle cx="24" cy="24" r="7.5" />
          {Array.from({ length: 12 }, (_, i) => {
            const a = (i / 12) * Math.PI * 2;
            const long = i % 3 === 0;
            return (
              <line
                key={i}
                x1={24 + Math.cos(a) * 11}
                y1={24 + Math.sin(a) * 11}
                x2={24 + Math.cos(a) * (long ? 17 : 14.5)}
                y2={24 + Math.sin(a) * (long ? 17 : 14.5)}
              />
            );
          })}
          <circle cx="24" cy="24" r="1.6" className={styles.dot} />
        </g>
      );
    case 'moon':
      return (
        <g>
          <path d="M30 9.5a15 15 0 1 0 0 29a12 12 0 0 1 0-29z" />
          <circle cx="34" cy="16" r="1.4" className={styles.dot} />
          <circle cx="37.5" cy="25" r="0.9" className={styles.dot} />
        </g>
      );
    case 'houses':
      return (
        <g>
          <rect x="10" y="10" width="28" height="28" />
          <line x1="10" y1="10" x2="38" y2="38" />
          <line x1="38" y1="10" x2="10" y2="38" />
          <polygon points="24,10 38,24 24,38 10,24" />
          <circle cx="24" cy="17" r="1.6" className={styles.dot} />
        </g>
      );
    case 'orbits':
      return (
        <g>
          <ellipse cx="24" cy="24" rx="17" ry="7" transform="rotate(-24 24 24)" />
          <ellipse cx="24" cy="24" rx="17" ry="7" transform="rotate(36 24 24)" />
          <circle cx="24" cy="24" r="3" />
          <circle cx="38.5" cy="17.5" r="1.8" className={styles.dot} />
        </g>
      );
    case 'nakshatra':
      return (
        <g>
          <circle cx="24" cy="24" r="12" />
          <circle cx="24" cy="24" r="16.5" className={styles.faint} />
          {Array.from({ length: 27 }, (_, i) => {
            const a = (i / 27) * Math.PI * 2 - Math.PI / 2;
            const r2 = i % 9 === 0 ? 18.5 : 16.5;
            return <line key={i} x1={24 + Math.cos(a) * 12} y1={24 + Math.sin(a) * 12} x2={24 + Math.cos(a) * r2} y2={24 + Math.sin(a) * r2} />;
          })}
          <circle cx={24 + Math.cos(-Math.PI / 2 + 1.1) * 12} cy={24 + Math.sin(-Math.PI / 2 + 1.1) * 12} r="1.8" className={styles.dot} />
        </g>
      );
    case 'hourglass':
      return (
        <g>
          <line x1="13" y1="9" x2="35" y2="9" />
          <line x1="13" y1="39" x2="35" y2="39" />
          <path d="M15.5 9c0 9 17 10 17 15s-17 6-17 15" />
          <path d="M32.5 9c0 9-17 10-17 15s17 6 17 15" />
          <circle cx="24" cy="33.5" r="1.6" className={styles.dot} />
        </g>
      );
    case 'lotus':
      return (
        <g>
          <path d="M24 12c4.5 5 4.5 14 0 20c-4.5-6-4.5-15 0-20z" />
          <path d="M24 32c-2-7-7.5-12-14-12.5c0.5 7 6 12 14 12.5z" />
          <path d="M24 32c2-7 7.5-12 14-12.5c-0.5 7-6 12-14 12.5z" />
          <path d="M11 36.5c8 2.5 18 2.5 26 0" />
          <circle cx="24" cy="21" r="1.6" className={styles.dot} />
        </g>
      );
    case 'compass':
      return (
        <g>
          <circle cx="24" cy="24" r="15" />
          <polygon points="24,11 27,24 24,37 21,24" />
          <polygon points="11,24 24,21 37,24 24,27" className={styles.faint} />
          <circle cx="24" cy="24" r="1.8" className={styles.dot} />
        </g>
      );
  }
}
