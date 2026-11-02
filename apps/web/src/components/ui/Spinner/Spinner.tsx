import styles from './Spinner.module.css';

interface SpinnerProps {
  size?: number;
  /** Announced to assistive tech. Pass an empty string when a parent already announces loading. */
  label?: string;
}

export function Spinner({ size = 18, label = 'Loading' }: SpinnerProps) {
  const stroke = size <= 16 ? 2 : 2.5;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  return (
    <span className={styles.spinner} role={label ? 'status' : undefined} aria-label={label || undefined} style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} aria-hidden="true">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="currentColor" strokeOpacity="0.2" strokeWidth={stroke} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="currentColor"
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={`${c * 0.28} ${c}`}
        />
      </svg>
    </span>
  );
}
