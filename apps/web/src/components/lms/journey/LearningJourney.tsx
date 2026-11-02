import type { ReactNode } from 'react';
import type { ProgressState } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { pad2 } from '@/lib/format';
import { ProgressRing } from '../progress/ProgressRing';
import { StatusNode } from '../status/Status';
import styles from './LearningJourney.module.css';

export interface JourneyStep {
  id: string;
  title: string;
  meta?: ReactNode;
  state: ProgressState;
  /** 0–100 for in-progress steps. */
  percent?: number;
  /** Shown on locked steps so the learner knows what unlocks them. */
  lockedReason?: string;
}

interface LearningJourneyProps {
  steps: JourneyStep[];
  label: string;
  /** The step the learner is on — drawn larger with its progress ring. */
  currentId?: string;
  /** Rendered under the current step, e.g. a Continue action. */
  currentAction?: ReactNode;
  /** "path" for chapters of a course; "compact" for short, label-only journeys. */
  variant?: 'path' | 'compact';
  showIndex?: boolean;
}

const STATE_TEXT: Record<ProgressState, string> = {
  completed: 'Completed',
  'in-progress': 'In progress',
  'not-started': 'Not started',
  locked: 'Locked',
};

/**
 * A learning path drawn directly on the page — no container. Horizontal when the
 * container is wide enough to give each step a readable title; a vertical rail otherwise.
 */
export function LearningJourney({ steps, label, currentId, currentAction, variant = 'path', showIndex = true }: LearningJourneyProps) {
  const currentIndex = currentId ? steps.findIndex((s) => s.id === currentId) : -1;

  return (
    <div className={cx(styles.root, variant === 'compact' && styles.compact)}>
      <ol className={styles.list} aria-label={label}>
        {steps.map((step, i) => {
          const isCurrent = i === currentIndex;
          const connectorDone = step.state === 'completed' && i < steps.length - 1;
          return (
            <li key={step.id} className={cx(styles.step, styles[step.state], isCurrent && styles.current)} aria-current={isCurrent ? 'step' : undefined}>
              <span className={styles.markerCol}>
                <span className={cx(styles.connector, connectorDone && styles.connectorDone)} aria-hidden="true" />
                {isCurrent && variant === 'path' ? (
                  <span className={styles.currentMarker}>
                    <ProgressRing value={step.percent ?? 0} size="sm" label={`${step.title} progress`} />
                  </span>
                ) : (
                  <StatusNode
                    size={variant === 'compact' ? 14 : 20}
                    shape={step.state === 'completed' ? 'filled' : step.state === 'in-progress' ? 'partial' : step.state === 'locked' ? 'dashed' : 'ring'}
                    tone={step.state === 'locked' ? 'neutral' : step.state === 'not-started' ? 'neutral' : 'accent'}
                    fraction={(step.percent ?? 0) / 100}
                    icon={variant === 'compact' ? <span /> : undefined}
                    className={styles.node}
                  />
                )}
              </span>
              <span className={styles.body}>
                {showIndex && variant === 'path' && <span className={styles.index}>{pad2(i + 1)}</span>}
                <span className={styles.title}>{step.title}</span>
                {variant === 'path' && (
                  <span className={styles.meta}>
                    <span className="sr-only">{STATE_TEXT[step.state]}. </span>
                    {step.state === 'locked' && step.lockedReason ? step.lockedReason : step.meta}
                  </span>
                )}
                {isCurrent && currentAction && <span className={styles.action}>{currentAction}</span>}
              </span>
            </li>
          );
        })}
      </ol>
    </div>
  );
}
