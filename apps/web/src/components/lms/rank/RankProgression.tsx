import { CheckCircle, LockSimple, SealCheck } from '@phosphor-icons/react';
import type { RankStep } from '@syniastrolms/domain';
import { criterionMet } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatDate, roman } from '@/lib/format';
import { Meter } from '../progress/Meters';
import styles from './RankProgression.module.css';

/* ─── Emblem ────────────────────────────────────────────────────────────── */

interface RankEmblemProps {
  steps: RankStep[];
  size?: number;
  className?: string;
}

/**
 * Concentric orbits, one per rank, growing outward. Achieved orbits are solid, the orbit
 * being worked toward carries a progress arc, future orbits are faint dashes. Twelve ticks
 * on the outer orbit are the only decorative mark — and they stay quiet.
 */
export function RankEmblem({ steps, size = 208, className }: RankEmblemProps) {
  const mid = size / 2;
  const inner = size * 0.2;
  const outer = size / 2 - 6;
  const gap = steps.length > 1 ? (outer - inner) / (steps.length - 1) : 0;
  const current = steps.find((s) => s.state === 'current');

  return (
    <svg className={cx(styles.emblem, className)} width={size} height={size} viewBox={`0 0 ${size} ${size}`} aria-hidden="true">
      {Array.from({ length: 12 }, (_, i) => {
        const a = (i / 12) * Math.PI * 2;
        const r1 = outer + 2;
        const r2 = outer + 5;
        return (
          <line
            key={i}
            x1={mid + r1 * Math.cos(a)}
            y1={mid + r1 * Math.sin(a)}
            x2={mid + r2 * Math.cos(a)}
            y2={mid + r2 * Math.sin(a)}
            className={styles.tick}
          />
        );
      })}
      {steps.map((step, i) => {
        const r = inner + gap * i;
        const c = 2 * Math.PI * r;
        if (step.state === 'achieved' || step.state === 'current') {
          return <circle key={step.rank.id} cx={mid} cy={mid} r={r} className={styles.orbitAchieved} />;
        }
        if (step.state === 'next') {
          const pct = (step.percent ?? 0) / 100;
          const end = -Math.PI / 2 + pct * Math.PI * 2;
          return (
            <g key={step.rank.id}>
              <circle cx={mid} cy={mid} r={r} className={styles.orbitTrack} />
              <circle cx={mid} cy={mid} r={r} className={styles.orbitProgress} strokeDasharray={`${c * pct} ${c}`} transform={`rotate(-90 ${mid} ${mid})`} />
              <circle cx={mid + r * Math.cos(end)} cy={mid + r * Math.sin(end)} r={4.5} className={styles.orbitBody} />
            </g>
          );
        }
        return <circle key={step.rank.id} cx={mid} cy={mid} r={r} className={styles.orbitFuture} />;
      })}
      <circle cx={mid} cy={mid} r={inner * 0.62} className={styles.core} />
      <text x={mid} y={mid} className={styles.coreText} dominantBaseline="central" textAnchor="middle">
        {roman(current?.rank.order ?? 1)}
      </text>
    </svg>
  );
}

/* ─── Full progression ─────────────────────────────────────────────────── */

interface RankProgressionProps {
  steps: RankStep[];
  learnerName?: string;
}

export function RankProgression({ steps, learnerName }: RankProgressionProps) {
  const current = steps.find((s) => s.state === 'current');
  const next = steps.find((s) => s.state === 'next');
  const descending = [...steps].reverse();

  return (
    <section className={styles.root} aria-label="Rank progression">
      <div className={styles.layout}>
        <div className={styles.lead}>
          <RankEmblem steps={steps} className={styles.leadEmblem} />
          <div className={styles.leadText}>
            <span className="type-label">{learnerName ? `${learnerName}’s standing` : 'Current standing'}</span>
            <span className={styles.currentTitle}>{current?.rank.title}</span>
            {next && (
              <p className={styles.leadNext}>
                <span className={styles.leadPct}>{next.percent}%</span> of the way to <strong>{next.rank.title}</strong>
              </p>
            )}
          </div>
        </div>

        <ol className={styles.ladder}>
          {descending.map((step) => (
            <li key={step.rank.id} className={cx(styles.rung, styles[step.state])} aria-current={step.state === 'current' ? 'step' : undefined}>
              <span className={styles.numeral} aria-hidden="true">
                {roman(step.rank.order)}
              </span>
              <div className={styles.rungBody}>
                <div className={styles.rungHead}>
                  <h4 className={styles.rungTitle}>{step.rank.title}</h4>
                  <RungState step={step} />
                </div>
                <p className={styles.descriptor}>{step.rank.descriptor}</p>

                {step.state === 'next' && step.criteria && (
                  <ul className={styles.criteria} aria-label={`Requirements for ${step.rank.title}`}>
                    {step.criteria.map((c) => {
                      const met = criterionMet(c);
                      return (
                        <li key={c.id} className={cx(styles.criterion, met && styles.met)}>
                          <span className={styles.criterionHead}>
                            {met ? <CheckCircle size={15} weight="fill" className={styles.metIcon} /> : <span className={styles.openDot} aria-hidden="true" />}
                            <span className={styles.criterionLabel}>{c.label}</span>
                            <span className={styles.criterionValue}>
                              {c.current} / {c.required}
                              {c.unit === '%' ? '%' : ''}
                            </span>
                          </span>
                          <Meter value={(c.current / c.required) * 100} label={c.label} size="xs" />
                        </li>
                      );
                    })}
                  </ul>
                )}
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}

function RungState({ step }: { step: RankStep }) {
  switch (step.state) {
    case 'achieved':
      return (
        <span className={styles.stateAchieved}>
          <SealCheck size={15} weight="fill" /> Achieved{step.achievedAt ? ` ${formatDate(step.achievedAt)}` : ''}
        </span>
      );
    case 'current':
      return (
        <span className={styles.stateCurrent}>
          <SealCheck size={15} weight="fill" /> Current rank{step.achievedAt ? ` · since ${formatDate(step.achievedAt)}` : ''}
        </span>
      );
    case 'next':
      return <span className={styles.stateNext}>{step.percent}% complete</span>;
    default:
      return (
        <span className={styles.stateFuture}>
          <LockSimple size={13} /> Later
        </span>
      );
  }
}

/* ─── Compact meter (sidebar) ──────────────────────────────────────────── */

export function RankMeter({ steps }: { steps: RankStep[] }) {
  const current = steps.find((s) => s.state === 'current');
  const next = steps.find((s) => s.state === 'next');
  const pct = next?.percent ?? 100;
  return (
    <div className={styles.meterCard}>
      <div className={styles.meterRow}>
        <span>Rank</span>
        <span className="tabular">{pct}%</span>
      </div>
      <div
        className={styles.meterTrack}
        role="progressbar"
        aria-label={next ? `Progress to ${next.rank.title}` : 'Rank progress'}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={pct}
      >
        <span className={styles.meterFill} style={{ width: `${pct}%` }} />
      </div>
      <div className={styles.meterCaption}>
        {current?.rank.title}
        {next && <> → {next.rank.title}</>}
      </div>
    </div>
  );
}
