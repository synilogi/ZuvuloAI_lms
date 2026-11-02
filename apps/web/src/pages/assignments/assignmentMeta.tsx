import { ArrowCounterClockwise, CheckCircle, FileArrowUp, HourglassMedium, ListBullets, NotePencil, TextAlignLeft, WarningCircle } from '@phosphor-icons/react';
import type { AssignmentStatus, DuePolicy, RubricCriterion, Submission, SubmissionFormat } from '@syniastrolms/domain';
import { formatDate, formatTime, plural } from '@/lib/format';
import { Badge } from '@/components/ui/Badge/Badge';

export const FORMATS: Record<SubmissionFormat, { label: string; description: string; icon: (size?: number) => JSX.Element }> = {
  file: { label: 'File upload', description: 'A worksheet, table or chart as a PDF or photo.', icon: (size = 16) => <FileArrowUp size={size} /> },
  text: { label: 'Written response', description: 'An essay or reflection typed into the lesson.', icon: (size = 16) => <TextAlignLeft size={size} /> },
  // Retired: no longer offered for new work, kept so assignments made with it still open.
  chart: {
    label: 'Structured details',
    description: 'An older format: set details with a written explanation.',
    icon: (size = 16) => <ListBullets size={size} />,
  },
};

export function dueText(due: DuePolicy, short = false) {
  if (due.kind === 'date') return `Due ${formatDate(due.dueAt)}${short ? '' : `, ${formatTime(due.dueAt)}`}`;
  if (due.kind === 'relative') return short ? `Due in ${plural(due.days, 'day')}` : `Due ${plural(due.days, 'day')} after the lesson unlocks`;
  return 'No due date';
}

export function AssignmentStatusBadge({ status, size = 'sm' }: { status: AssignmentStatus; size?: 'sm' | 'md' }) {
  if (status === 'published')
    return (
      <Badge size={size} tone="accent" dot>
        Published
      </Badge>
    );
  if (status === 'closed')
    return (
      <Badge size={size} tone="neutral">
        Closed
      </Badge>
    );
  return (
    <Badge size={size} tone="warn">
      Draft
    </Badge>
  );
}

/** Where a submission stands in review. Overdue reviews are called out before anything else. */
export function ReviewBadge({ submission, overdue, size = 'sm' }: { submission?: Submission; overdue?: boolean; size?: 'sm' | 'md' }) {
  if (!submission)
    return (
      <Badge size={size} tone="neutral">
        Not submitted
      </Badge>
    );
  const { status } = submission.review;
  if ((status === 'waiting' || status === 'in-review') && overdue)
    return (
      <Badge size={size} tone="danger" icon={<WarningCircle size={13} weight="bold" />}>
        {status === 'in-review' ? 'Late · draft saved' : 'Late to mark'}
      </Badge>
    );
  if (status === 'waiting')
    return (
      <Badge size={size} tone="info" icon={<HourglassMedium size={13} />}>
        To review
      </Badge>
    );
  if (status === 'in-review')
    return (
      <Badge size={size} tone="info" icon={<NotePencil size={13} />}>
        Draft review
      </Badge>
    );
  if (status === 'returned')
    return (
      <Badge size={size} tone="warn" icon={<ArrowCounterClockwise size={13} />}>
        Resubmission requested
      </Badge>
    );
  return (
    <Badge size={size} tone="accent" icon={<CheckCircle size={13} weight="fill" />}>
      Graded
    </Badge>
  );
}

export const scoreText = (submission: Submission | undefined, max: number) =>
  submission?.review.status === 'graded' && submission.review.score !== undefined ? `${submission.review.score} / ${max}` : '—';

/** How long a submission has been waiting, in the largest sensible unit. */
export function waitingFor(iso: string, now: Date) {
  const hours = Math.max(0, (now.getTime() - new Date(iso).getTime()) / 3_600_000);
  if (hours < 1) return 'under an hour';
  if (hours < 48) return plural(Math.floor(hours), 'hour');
  return plural(Math.floor(hours / 24), 'day');
}

let serial = 0;
export const newCriterionId = () => `crit-${Date.now().toString(36)}${(serial++).toString(36)}`;

/** A starting rubric for each format, out of 20. Instructors rename and re-weight it. */
export function rubricTemplate(format: SubmissionFormat): RubricCriterion[] {
  const rows: [string, string, number][] =
    format === 'chart'
      ? [
          ['Accurate details', 'Every detail asked for is filled in correctly.', 6],
          ['Applies the chapter', 'Uses the ideas from this chapter, not general impressions.', 8],
          ['Reasoning', 'Each answer is traced back to a rule, formula or source.', 4],
          ['Clarity', 'Organised so a classmate could follow it.', 2],
        ]
      : format === 'file'
        ? [
            ['Correct working', 'Answers are right and complete for every item.', 10],
            ['Shows the method', 'Steps are visible, so a mistake can be found and learned from.', 6],
            ['Presentation', 'Legible, labelled and in the requested format.', 4],
          ]
        : [
            ['Understanding', 'Explains the idea accurately in the learner’s own words.', 8],
            ['Examples', 'Grounds the argument in worked examples from the course.', 6],
            ['Structure', 'A clear opening, a developed middle and a conclusion.', 4],
            ['Sources', 'Cites the textbook, NCERT or the course notes where relevant.', 2],
          ];
  return rows.map(([title, description, points]) => ({ id: newCriterionId(), title, description, points }));
}
