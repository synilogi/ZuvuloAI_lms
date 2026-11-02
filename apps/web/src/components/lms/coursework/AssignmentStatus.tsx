import { ClipboardText } from '@phosphor-icons/react';
import type { Assignment, AssignmentState } from '@syniastrolms/domain';
import { effectiveAssignmentState, gradePassed } from '@syniastrolms/domain';
import { formatDay, formatRelative } from '@/lib/format';
import { Button } from '@/components/ui/Button/Button';
import { IconChip } from '@/components/ui/Badge/Badge';
import { StatusLabel } from '../status/Status';
import type { StatusKey } from '../status/statusRegistry';
import { WorkRow } from '../shared/WorkRow';

interface AssignmentStatusProps {
  assignment: Assignment;
  chapterTitle?: string;
  now: Date;
  onOpen?: (assignment: Assignment) => void;
}

const ACTION: Record<AssignmentState, { label: string; primary?: boolean } | null> = {
  'not-started': { label: 'Start' },
  draft: { label: 'Continue draft', primary: true },
  submitted: { label: 'View submission' },
  'under-review': { label: 'View submission' },
  graded: { label: 'Read feedback' },
  overdue: { label: 'Submit late', primary: true },
  closed: null,
};

export function AssignmentStatus({ assignment, chapterTitle, now, onOpen }: AssignmentStatusProps) {
  const state = effectiveAssignmentState(assignment, now);
  const grade = assignment.grade;
  const passed = grade ? gradePassed(grade) : undefined;

  const statusKey: StatusKey = state === 'graded' ? (passed ? 'passed' : 'failed') : state === 'closed' ? 'expired' : state;

  const statusText =
    state === 'graded' && grade ? `${passed ? 'Passed' : 'Resubmit'} · ${grade.score}/${grade.max}` : state === 'closed' ? 'Closed' : undefined;

  const dueText =
    state === 'submitted' || state === 'under-review' || state === 'graded'
      ? `Submitted ${assignment.submittedAt ? formatDay(assignment.submittedAt) : ''}`
      : state === 'overdue' || state === 'closed'
        ? `Was due ${formatDay(assignment.dueAt)}`
        : `Due ${formatDay(assignment.dueAt)} · ${formatRelative(assignment.dueAt, now)}`;

  const action = state === 'graded' && passed === false ? { label: 'Resubmit', primary: true } : ACTION[state];

  return (
    <WorkRow
      lead={
        <IconChip tone={state === 'overdue' ? 'danger' : state === 'draft' ? 'accent' : 'neutral'} size="lg">
          <ClipboardText size={19} />
        </IconChip>
      }
      eyebrow={chapterTitle}
      title={assignment.title}
      meta={dueText}
      status={
        <>
          <StatusLabel status={statusKey} label={statusText} />
          {state === 'graded' && grade && (
            <span className="type-meta">
              Pass mark {grade.passMark}/{grade.max}
            </span>
          )}
          {state === 'overdue' && <span className="type-meta">Late submissions accepted</span>}
        </>
      }
      action={
        action && (
          <Button variant={action.primary ? 'primary' : 'secondary'} size="sm" onClick={() => onOpen?.(assignment)}>
            {action.label}
          </Button>
        )
      }
      emphasis={state === 'overdue' ? 'attention' : undefined}
      muted={state === 'closed'}
    />
  );
}
