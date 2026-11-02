import { CheckCircle, Exam, LockSimple, Timer } from '@phosphor-icons/react';
import type { Assessment, QuizWindow } from '@syniastrolms/domain';
import { formatDay, formatMoment, formatRelative, formatTime } from '@/lib/format';
import { Button } from '@/components/ui/Button/Button';
import { IconChip } from '@/components/ui/Badge/Badge';
import { ProgressRing } from '../progress/ProgressRing';
import { StatusLabel } from '../status/Status';
import { WorkRow } from '../shared/WorkRow';

/** A test as the learner's list carries it: its window, and the deadline of an attempt under way. */
export type AssessmentRow = Assessment & { window?: QuizWindow; opensAt?: string; closesAt?: string; deadlineAt?: string; resultsAt?: string };

interface AssessmentStatusProps {
  assessment: AssessmentRow;
  now: Date;
  onStart?: (assessment: AssessmentRow) => void;
}

export function AssessmentStatus({ assessment: a, now, onStart }: AssessmentStatusProps) {
  // 0 attempts allowed means no limit.
  const remaining = a.attemptsAllowed > 0 ? Math.max(0, a.attemptsAllowed - a.attemptsUsed) : Number.POSITIVE_INFINITY;
  const retakeOpen = !a.retakeAvailableAt || new Date(a.retakeAvailableAt).getTime() <= now.getTime();
  // No score: the lesson was completed another way, or the results are held until the quiz closes.
  const hasScore = typeof a.score === 'number';
  const scored = (a.state === 'passed' || a.state === 'failed') && hasScore && !a.resultsAt;
  // Results held until the quiz closes: not even pass or fail is shown before then.
  const held = Boolean(a.resultsAt) && (a.state === 'passed' || a.state === 'failed');
  const upcoming = a.window === 'upcoming';
  const closed = a.window === 'closed';

  const lead = scored ? (
    <ProgressRing
      value={a.score ?? 0}
      size="md"
      threshold={a.passMark}
      tone={a.state === 'passed' ? 'accent' : 'danger'}
      label={`Score ${a.score}%, pass mark ${a.passMark}%`}
    />
  ) : a.state === 'in-progress' && a.answered !== undefined ? (
    <ProgressRing
      value={(a.answered / a.questions) * 100}
      size="md"
      label={`${a.answered} of ${a.questions} answered`}
      valueText={`${a.answered}/${a.questions}`}
    />
  ) : (
    <IconChip tone={a.state === 'locked' || closed ? 'neutral' : 'accent'} size="xl">
      {held ? (
        <Exam size={24} />
      ) : a.state === 'locked' ? (
        <LockSimple size={22} />
      ) : a.state === 'passed' ? (
        <CheckCircle size={24} />
      ) : a.state === 'in-progress' ? (
        <Timer size={24} />
      ) : (
        <Exam size={24} />
      )}
    </IconChip>
  );

  const facts = `${a.questions} questions · ${a.durationMin} min · pass mark ${a.passMark}%`;
  const tries = (n: number) => `${n} ${n === 1 ? 'try' : 'tries'}`;
  const allowedText = Number.isFinite(remaining) ? `${tries(remaining)} allowed` : 'No limit on tries';

  let status;
  let action = null;
  switch (held ? 'held' : a.state) {
    case 'held':
      status = (
        <>
          <StatusLabel status="submitted" label="Submitted" />
          <span className="type-meta">Results are shown when the quiz closes, {formatMoment(a.resultsAt!)}</span>
        </>
      );
      action = (
        <Button size="sm" onClick={() => onStart?.(a)}>
          Open
        </Button>
      );
      break;
    case 'locked':
      status = (
        <>
          <StatusLabel status="locked" />
          <span className="type-meta">{a.lockedReason}</span>
        </>
      );
      break;
    case 'available':
      if (upcoming) {
        status = (
          <>
            <StatusLabel status="upcoming" label="Not open yet" />
            {a.opensAt && <span className="type-meta">Opens {formatMoment(a.opensAt)}</span>}
          </>
        );
        break;
      }
      if (closed) {
        status = (
          <>
            <StatusLabel status="expired" label="Closed" />
            {a.closesAt && <span className="type-meta">Closed {formatMoment(a.closesAt)}</span>}
          </>
        );
        break;
      }
      status = (
        <>
          <StatusLabel status="not-started" label="Ready when you are" detail={allowedText} />
          {a.closesAt && <span className="type-meta">Closes {formatMoment(a.closesAt)}</span>}
        </>
      );
      action = (
        <Button variant="primary" size="sm" onClick={() => onStart?.(a)}>
          Start test
        </Button>
      );
      break;
    case 'in-progress':
      status = (
        <>
          <StatusLabel
            status="in-progress"
            label="Attempt under way"
            detail={a.answered !== undefined ? `${a.answered} of ${a.questions} answered` : undefined}
          />
          <span className="type-meta">
            {a.deadlineAt ? `Time runs out ${formatMoment(a.deadlineAt)} (${formatRelative(a.deadlineAt, now)})` : 'Your answers are saved as you go'}
          </span>
        </>
      );
      action = (
        <Button variant="primary" size="sm" onClick={() => onStart?.(a)}>
          Resume
        </Button>
      );
      break;
    case 'submitted':
      status = (
        <>
          <StatusLabel status="under-review" label="Waiting to be marked" />
          <span className="type-meta">Results usually within 3 days</span>
        </>
      );
      break;
    case 'passed':
      status = hasScore ? (
        <StatusLabel status="passed" label={`Passed · ${a.score}%`} detail={`Best of ${tries(a.attemptsUsed)}`} />
      ) : (
        <StatusLabel status="passed" label="Completed" />
      );
      // Opens the quiz lesson, where past tries and their answers are shown.
      action = hasScore && (
        <Button size="sm" onClick={() => onStart?.(a)}>
          See your answers
        </Button>
      );
      break;
    case 'failed':
      status = (
        <>
          <StatusLabel status="failed" label={hasScore ? `${a.score}% · needed ${a.passMark}%` : 'Not passed yet'} />
          <span className="type-meta">
            {closed
              ? 'This quiz has closed'
              : remaining === 0
                ? 'No tries left — your instructor has been told'
                : !retakeOpen
                  ? `Retake opens ${formatDay(a.retakeAvailableAt!)}, ${formatTime(a.retakeAvailableAt!)} (${formatRelative(a.retakeAvailableAt!, now)})`
                  : Number.isFinite(remaining)
                    ? `${tries(remaining)} left`
                    : 'Try as often as you like'}
          </span>
        </>
      );
      action =
        remaining > 0 && !closed ? (
          <Button variant={retakeOpen ? 'primary' : 'secondary'} size="sm" disabled={!retakeOpen} onClick={() => onStart?.(a)}>
            Try again
          </Button>
        ) : (
          // Opens the quiz lesson, where past tries are listed.
          <Button size="sm" onClick={() => onStart?.(a)}>
            See your attempts
          </Button>
        );
      break;
  }

  return <WorkRow lead={lead} title={a.title} meta={facts} status={status} action={action} muted={a.state === 'locked'} />;
}
