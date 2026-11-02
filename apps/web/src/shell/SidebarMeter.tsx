import styles from './AppShell.module.css';

/** The shell's sidebar footer card (storage meter), generalised for any role-relevant measure. */
export function SidebarMeter({ label, value, max, valueText, caption }: { label: string; value: number; max: number; valueText: string; caption: string }) {
  const pct = Math.round((value / max) * 100);
  return (
    <div className={styles.meterCard}>
      <div className={styles.meterCardRow}>
        <span>{label}</span>
        <span className="tabular">{valueText}</span>
      </div>
      <div className={styles.meterCardTrack} role="progressbar" aria-label={label} aria-valuemin={0} aria-valuemax={max} aria-valuenow={value}>
        <span className={styles.meterCardFill} style={{ width: `${pct}%` }} />
      </div>
      <div className={styles.meterCardCaption}>{caption}</div>
    </div>
  );
}
