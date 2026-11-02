import type { CSSProperties } from 'react';

import styles from './Feedback.module.css';

export interface SkeletonProps {
  width?: CSSProperties['width'];
  height?: CSSProperties['height'];
  radius?: CSSProperties['borderRadius'];
}

/** A placeholder shape. Skeletons are hidden from assistive tech; the container announces "Loading". */
export function Skeleton({ width = '100%', height = 14, radius }: SkeletonProps) {
  return <span className={styles.skeleton} style={{ width, height, borderRadius: radius }} aria-hidden="true" />;
}

function Loading({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div role="status" aria-live="polite" aria-busy="true" className={styles.skeletonStack}>
      <span className="visually-hidden">{label}</span>
      {children}
    </div>
  );
}

export function TableSkeleton({ rows = 6, columns = 4, label = 'Loading…' }: { rows?: number; columns?: number; label?: string }) {
  return (
    <Loading label={label}>
      {Array.from({ length: rows + 1 }, (_, row) => (
        <div key={row} className={styles.skeletonRow} style={{ '--cols': columns } as CSSProperties}>
          {Array.from({ length: columns }, (_, column) => (
            <Skeleton key={column} height={row === 0 ? 10 : 16} width={column === 0 ? '80%' : '60%'} />
          ))}
        </div>
      ))}
    </Loading>
  );
}

export function DetailSkeleton({ label = 'Loading…' }: { label?: string }) {
  return (
    <Loading label={label}>
      <Skeleton width="40%" height={28} />
      <Skeleton width="65%" />
      <Skeleton height={120} radius="var(--r-lg)" />
      <Skeleton width="90%" />
      <Skeleton width="75%" />
    </Loading>
  );
}

export function KpiSkeleton({ count = 4, label = 'Loading figures…' }: { count?: number; label?: string }) {
  return (
    <Loading label={label}>
      <div className={styles.skeletonKpis}>
        {Array.from({ length: count }, (_, index) => (
          <div key={index} className={styles.skeletonStack}>
            <Skeleton width="50%" height={12} />
            <Skeleton width="70%" height={30} />
          </div>
        ))}
      </div>
    </Loading>
  );
}

export function ChartSkeleton({ height = 220, label = 'Loading chart…' }: { height?: number; label?: string }) {
  return (
    <Loading label={label}>
      <Skeleton width="30%" height={14} />
      <Skeleton height={height} radius="var(--r-md)" />
    </Loading>
  );
}

export function FormSkeleton({ fields = 4, label = 'Loading form…' }: { fields?: number; label?: string }) {
  return (
    <Loading label={label}>
      {Array.from({ length: fields }, (_, index) => (
        <div key={index} className={styles.skeletonStack} style={{ gap: 6 }}>
          <Skeleton width={120} height={12} />
          <Skeleton height={40} radius="var(--r-sm)" />
        </div>
      ))}
    </Loading>
  );
}

export function Spinner({ label = 'Loading' }: { label?: string }) {
  return <span className={styles.spinner} role="status" aria-label={label} />;
}
