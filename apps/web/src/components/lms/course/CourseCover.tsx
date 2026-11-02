import { useEffect, useState } from 'react';
import type { CoverMotif } from '@syniastrolms/domain';
import { useApiImage } from '@/hooks/useApiImage';
import { cx } from '@/lib/cx';
import styles from './Course.module.css';

/**
 * Generated course artwork: fine-line geometry (a grid of diamonds, a ring of 27 points, orbits,
 * an arc) on a soft accent ground. No illustrations,
 * no photography required — covers stay consistent however large the catalog grows.
 *
 * A course with an uploaded cover passes its `imageUrl`: the image is laid over the motif in the
 * same box, so the motif shows while it loads and stays when it is missing or fails to load.
 */
export function CourseCover({ motif, imageUrl, className, label }: { motif: CoverMotif; imageUrl?: string; className?: string; label?: string }) {
  const src = useApiImage(imageUrl);
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [src]);
  return (
    <span className={cx(styles.cover, className)} role={label ? 'img' : undefined} aria-label={label} aria-hidden={label ? undefined : true}>
      <svg viewBox="0 0 160 100" preserveAspectRatio="xMidYMid meet" className={styles.coverArt}>
        {motif === 'houses' && <Houses />}
        {motif === 'nakshatra' && <Nakshatra />}
        {motif === 'orbits' && <Orbits />}
        {motif === 'ecliptic' && <Ecliptic />}
      </svg>
      {src && !failed && <img src={src} alt="" className={styles.coverImage} decoding="async" onError={() => setFailed(true)} />}
    </span>
  );
}

function Houses() {
  // Grid: a square, its diagonals, and the diamond joining the edge midpoints.
  const x = 52,
    y = 12,
    s = 76;
  return (
    <g className={styles.coverLines}>
      <rect x={x} y={y} width={s} height={s} />
      <line x1={x} y1={y} x2={x + s} y2={y + s} />
      <line x1={x + s} y1={y} x2={x} y2={y + s} />
      <polygon points={`${x + s / 2},${y} ${x + s},${y + s / 2} ${x + s / 2},${y + s} ${x},${y + s / 2}`} />
      <circle cx={x + s / 2} cy={y + s / 4} r={2.2} className={styles.coverDot} />
    </g>
  );
}

function Nakshatra() {
  const cx0 = 112,
    cy0 = 58,
    r = 34;
  return (
    <g className={styles.coverLines}>
      <circle cx={cx0} cy={cy0} r={r} />
      <circle cx={cx0} cy={cy0} r={r - 10} className={styles.coverFaint} />
      {Array.from({ length: 27 }, (_, i) => {
        const a = (i / 27) * Math.PI * 2 - Math.PI / 2;
        return <line key={i} x1={cx0 + (r - 4) * Math.cos(a)} y1={cy0 + (r - 4) * Math.sin(a)} x2={cx0 + r * Math.cos(a)} y2={cy0 + r * Math.sin(a)} />;
      })}
      <circle cx={cx0 + (r - 10) * Math.cos(-0.9)} cy={cy0 + (r - 10) * Math.sin(-0.9)} r={2.4} className={styles.coverDot} />
    </g>
  );
}

function Orbits() {
  return (
    <g className={styles.coverLines}>
      <circle cx={40} cy={82} r={22} />
      <circle cx={40} cy={82} r={44} className={styles.coverFaint} />
      <circle cx={40} cy={82} r={70} />
      <circle cx={40} cy={82} r={98} className={styles.coverFaint} />
      <circle cx={40 + 70 * Math.cos(-0.72)} cy={82 + 70 * Math.sin(-0.72)} r={2.6} className={styles.coverDot} />
    </g>
  );
}

function Ecliptic() {
  return (
    <g className={styles.coverLines}>
      <ellipse cx={80} cy={52} rx={70} ry={20} transform="rotate(-12 80 52)" />
      <ellipse cx={80} cy={52} rx={70} ry={20} transform="rotate(12 80 52)" className={styles.coverFaint} />
      <line x1={4} y1={52} x2={156} y2={52} className={styles.coverFaint} />
      <circle cx={126} cy={42} r={2.4} className={styles.coverDot} />
    </g>
  );
}
