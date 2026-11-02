import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { ArrowLeft, ClipboardText, Exam } from '@phosphor-icons/react';
import type { Assignment } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { AssessmentStatus } from '@/components/lms/coursework/AssessmentStatus';
import { AssignmentStatus } from '@/components/lms/coursework/AssignmentStatus';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { AssignmentWork } from './AssignmentWork';
import { asStatusAssignment } from './CourseLearningPage';
import { lessonTo } from './learnParts';
import { WorkList } from '@/components/lms/shared/WorkRow';
import styles from './Learn.module.css';

type AssignmentFilter = 'to-do' | 'submitted' | 'graded';
const TO_DO: Assignment['state'][] = ['not-started', 'draft', 'overdue'];

export function LearnerAssignmentsPage() {
  const navigate = useNavigate();
  const now = useNow();
  const [params, setParams] = useSearchParams();
  const filter = (params.get('show') as AssignmentFilter | null) ?? 'to-do';
  const query = useAsync('learner-assignments', () => services.learning.listAssignments());
  const list = query.data ?? [];
  const groups: Record<AssignmentFilter, typeof list> = {
    'to-do': list.filter((a) => TO_DO.includes(a.state)),
    submitted: list.filter((a) => a.state === 'submitted' || a.state === 'under-review'),
    graded: list.filter((a) => a.state === 'graded' || a.state === 'closed'),
  };
  const shown = groups[filter];

  return (
    <div className={styles.page}>
      <PageHeader
        title="Assignments"
        description="Work to hand in for your courses. Once you hand something in, your instructor marks it and their feedback shows up under Graded."
      />
      <SegmentedControl<AssignmentFilter>
        label="Show"
        value={filter}
        onChange={(v) => setParams(v === 'to-do' ? {} : { show: v }, { replace: true })}
        segments={[
          { value: 'to-do', label: 'To do', count: query.data ? groups['to-do'].length : undefined },
          { value: 'submitted', label: 'Submitted', count: query.data ? groups.submitted.length : undefined },
          { value: 'graded', label: 'Graded', count: query.data ? groups.graded.length : undefined },
        ]}
      />
      {query.status === 'error' && !query.data ? (
        <StateMessage
          kind="error"
          title="Assignments didn’t load"
          actions={
            <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      ) : !query.data ? (
        <div className={styles.stackList} aria-busy="true">
          {Array.from({ length: 3 }, (_, i) => (
            <Skeleton key={i} height={96} radius="var(--r-lg)" />
          ))}
        </div>
      ) : shown.length === 0 ? (
        <StateMessage
          icon={<ClipboardText size={26} />}
          title={filter === 'to-do' ? 'Nothing to hand in' : filter === 'submitted' ? 'Nothing waiting for review' : 'No feedback yet'}
        >
          {filter === 'to-do'
            ? list.length
              ? 'You’re up to date. New assignments appear here as you reach them in your courses.'
              : 'Assignments appear here as you reach them in your courses.'
            : filter === 'submitted'
              ? 'Work you hand in waits here until your instructor reviews it.'
              : 'Graded work and feedback appear here.'}
        </StateMessage>
      ) : (
        <div className={styles.panel}>
          <WorkList label="Assignments">
            {shown.map((la) => (
              <AssignmentStatus
                key={la.assignment.id}
                assignment={asStatusAssignment(la)}
                chapterTitle={`${la.courseTitle}${la.chapterTitle ? ` · ${la.chapterTitle}` : ''}`}
                now={now}
                onOpen={() => navigate(`/assignments/${la.assignment.id}`)}
              />
            ))}
          </WorkList>
        </div>
      )}
      {query.data && <p className={styles.muted}>{plural(list.length, 'assignment')} across your courses.</p>}
    </div>
  );
}

export function LearnerAssignmentPage() {
  const { assignmentId } = useParams();
  const query = useAsync(`learner-assignment:${assignmentId}`, () => services.learning.getAssignment(assignmentId!));
  usePageCrumbs(query.data ? [{ label: query.data.assignment.title }] : [{ label: 'Assignment' }]);

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'This assignment isn’t available' : 'The assignment didn’t load'}
          actions={
            notFound ? (
              <LinkButton to="/assignments" iconStart={<ArrowLeft size={16} />}>
                Back to assignments
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!query.data || query.data.assignment.id !== assignmentId) {
    return (
      <div className={styles.narrowPage} aria-busy="true">
        <Skeleton width={160} height={12} />
        <Skeleton width="60%" height={30} radius="var(--r-xs)" />
        <Skeleton height={360} radius="var(--r-lg)" />
      </div>
    );
  }
  const la = query.data;
  return (
    <div className={styles.narrowPage}>
      <PageHeader
        back={{ label: 'Assignments', to: '/assignments' }}
        eyebrow={`${la.courseTitle}${la.chapterTitle ? ` · ${la.chapterTitle}` : ''}`}
        title={la.assignment.title}
        actions={
          la.lessonId ? (
            <LinkButton to={lessonTo(la.assignment.courseId, la.lessonId)} variant="ghost">
              Open in the course
            </LinkButton>
          ) : undefined
        }
      />
      <div className={styles.panel}>
        <AssignmentWork key={la.submission?.id ?? 'none'} item={la} onSubmitted={() => query.run().catch(() => undefined)} />
      </div>
    </div>
  );
}

export function LearnerAssessmentsPage() {
  const navigate = useNavigate();
  const now = useNow();
  const query = useAsync('learner-assessments', () => services.learning.listAssessments());
  const list = query.data ?? [];
  // An attempt under way stays with the tests to take, whatever the window: it can still be handed in.
  const held = (a: (typeof list)[number]) => Boolean(a.resultsAt) && (a.state === 'passed' || a.state === 'failed');
  const open = list.filter(
    (a) => !held(a) && a.state !== 'passed' && a.state !== 'locked' && (a.state === 'in-progress' || (a.window !== 'upcoming' && a.window !== 'closed')),
  );
  const later = list.filter((a) => a.state === 'locked' || (a.state !== 'passed' && a.state !== 'in-progress' && a.window === 'upcoming'));
  const closed = list.filter((a) => !held(a) && a.state !== 'passed' && a.state !== 'locked' && a.state !== 'in-progress' && a.window === 'closed');
  // Results held until a quiz closes say nothing about how it went — passed or not — until then.
  const waiting = list.filter((a) => a.resultsAt && (a.state === 'passed' || a.state === 'failed'));
  const passed = list.filter((a) => a.state === 'passed' && !a.resultsAt);

  return (
    <div className={styles.page}>
      <PageHeader title="Tests" description="Chapter quizzes and final tests. Each one opens once you’ve finished the lessons before it." />
      {query.status === 'error' && !query.data ? (
        <StateMessage
          kind="error"
          title="Your tests didn’t load"
          actions={
            <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      ) : !query.data ? (
        <div className={styles.stackList} aria-busy="true">
          {Array.from({ length: 3 }, (_, i) => (
            <Skeleton key={i} height={96} radius="var(--r-lg)" />
          ))}
        </div>
      ) : list.length === 0 ? (
        <StateMessage icon={<Exam size={26} />} title="No tests yet">
          Quizzes appear here once you enroll in a course that has them.
        </StateMessage>
      ) : (
        [
          { title: 'Ready to take', items: open },
          { title: 'Opens later', items: later },
          { title: 'Closed', items: closed },
          { title: 'Waiting for results', items: waiting },
          { title: 'Passed', items: passed },
        ]
          .filter((g) => g.items.length)
          .map((g) => (
            <section key={g.title} className={styles.courseworkGroup} aria-label={g.title}>
              <h2 className={styles.groupTitle}>
                {g.title} <span className={styles.muted}>{g.items.length}</span>
              </h2>
              <div className={styles.panel}>
                <WorkList label={g.title}>
                  {g.items.map((a) => (
                    <AssessmentStatus key={a.id} assessment={a} now={now} onStart={() => a.lessonId && navigate(lessonTo(a.courseId, a.lessonId))} />
                  ))}
                </WorkList>
              </div>
            </section>
          ))
      )}
    </div>
  );
}
