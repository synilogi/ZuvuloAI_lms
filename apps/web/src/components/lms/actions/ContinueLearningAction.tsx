import { Play } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import { Button } from '@/components/ui/Button/Button';
import { VideoProgress } from '../progress/Meters';
import { ProgressRing } from '../progress/ProgressRing';
import styles from './Actions.module.css';

export interface ResumePoint {
  courseTitle: string;
  chapterLabel: string;
  lessonTitle: string;
  positionSec: number;
  durationSec: number;
  coursePercent: number;
}

interface ContinueLearningActionProps {
  resume: ResumePoint;
  onResume?: () => void;
  /** panel: a focused block; inline: one line with a button; bar: the mobile sticky bar. */
  variant?: 'panel' | 'inline' | 'bar';
}

/** The single most useful action for a returning learner, with enough context to trust it. */
export function ContinueLearningAction({ resume, onResume, variant = 'panel' }: ContinueLearningActionProps) {
  const minutesLeft = Math.ceil((resume.durationSec - resume.positionSec) / 60);

  if (variant === 'bar') {
    return (
      <div className={styles.bar}>
        <ProgressRing value={(resume.positionSec / resume.durationSec) * 100} size="sm" label="Lesson progress" hideValue />
        <span className={styles.barText}>
          <span className={styles.barTitle}>{resume.lessonTitle}</span>
          <span className={styles.barMeta}>{minutesLeft} min left</span>
        </span>
        <Button variant="primary" iconStart={<Play size={14} weight="fill" />} onClick={onResume}>
          Resume
        </Button>
      </div>
    );
  }

  if (variant === 'inline') {
    return (
      <div className={styles.inline}>
        <Button variant="primary" iconStart={<Play size={14} weight="fill" />} onClick={onResume}>
          Resume lesson
        </Button>
        <span className={styles.inlineMeta}>
          {resume.lessonTitle} · {minutesLeft} min left
        </span>
      </div>
    );
  }

  return (
    <section className={cx(styles.continue)} aria-label="Continue learning">
      <span className="type-eyebrow">Continue where you left off</span>
      <h3 className={styles.continueTitle}>{resume.lessonTitle}</h3>
      <p className={styles.continueMeta}>
        {resume.chapterLabel} · {resume.courseTitle}
      </p>
      <VideoProgress positionSec={resume.positionSec} durationSec={resume.durationSec} chapters={[240, 610]} />
      <div className={styles.continueActions}>
        <Button variant="primary" size="lg" iconStart={<Play size={15} weight="fill" />} onClick={onResume}>
          Resume lesson
        </Button>
        <span className={styles.continueCourse}>
          <ProgressRing value={resume.coursePercent} size="xs" label="Course progress" />
          Course <span className="tabular">{resume.coursePercent}%</span>
        </span>
      </div>
    </section>
  );
}
