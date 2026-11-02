import { useState } from 'react';
import { ArrowCounterClockwise, CheckCircle, ClipboardText } from '@phosphor-icons/react';
import { LMS_STATUSES } from '@syniastrolms/domain';
import { useNow } from '@/hooks/useNow';
import { Button } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { LessonRow } from '@/components/lms/course/CourseCurriculum';
import { AssignmentStatus } from '@/components/lms/coursework/AssignmentStatus';
import { LessonSegments } from '@/components/lms/progress/Meters';
import { ProgressRing } from '@/components/lms/progress/ProgressRing';
import { WorkList } from '@/components/lms/shared/WorkRow';
import { StatusBadge, StatusLabel, StatusNodeFor } from '@/components/lms/status/Status';
import { statusRegistry, type StatusKey } from '@/components/lms/status/statusRegistry';
import { simulation } from '@/services/mock/mockServices';
import { services } from '@/services';
import { useAsync } from '@/hooks/useAsync';
import { foundationsCourse } from '@/services/mock/fixtures/catalog';
import { assignments } from '@/services/mock/fixtures/learner';
import { ChapterIntro, DocSection, Notes, Specimen } from '../doc/Doc';
import styles from './Chapters.module.css';

const DERIVED: StatusKey[] = ['not-started', 'draft', 'overdue', 'starting-soon', 'cancelled'];

export default function States() {
  return (
    <>
      <ChapterIntro title="States">
        Every LMS state is drawn three ways — as a badge, inline, and as a node on a path — with a label, an icon and a shape. Tone reinforces; it is never the
        only signal.
      </ChapterIntro>
      <LmsStateMatrix />
      <InteractionStates />
      <RegionStates />
      <Transitions />
    </>
  );
}

/* ─── Matrix ────────────────────────────────────────────────────────────── */

function MatrixRow({ status }: { status: StatusKey }) {
  const def = statusRegistry[status];
  return (
    <tr>
      <td>
        <span className={styles.matrixKey}>{status}</span>
      </td>
      <td>
        <StatusBadge status={status} />
      </td>
      <td>
        <StatusLabel status={status} />
      </td>
      <td>
        <span className={styles.matrixShape}>
          <StatusNodeFor status={status} size={20} />
          {def.shape}
        </span>
      </td>
      <td className={styles.matrixMeaning}>{def.meaning}</td>
    </tr>
  );
}

function LmsStateMatrix() {
  const all = [...LMS_STATUSES, ...DERIVED];
  return (
    <DocSection
      id="lms-states"
      index={1}
      title="Learning states"
      lead={`${LMS_STATUSES.length} canonical states come from the domain package and are returned by the API. ${DERIVED.length} derived states are computed in the interface from dates and drafts.`}
      api={['statusRegistry', 'StatusBadge', 'StatusLabel', 'StatusNode']}
    >
      <div className={styles.matrixWrap}>
        <table className={styles.matrix}>
          <thead>
            <tr>
              <th scope="col">Key</th>
              <th scope="col">Badge</th>
              <th scope="col">Inline</th>
              <th scope="col">Node · shape</th>
              <th scope="col">Meaning</th>
            </tr>
          </thead>
          <tbody>
            {LMS_STATUSES.map((s) => (
              <MatrixRow key={s} status={s} />
            ))}
            <tr className={styles.matrixDivider}>
              <td colSpan={5}>Derived in the interface</td>
            </tr>
            {DERIVED.map((s) => (
              <MatrixRow key={s} status={s} />
            ))}
          </tbody>
        </table>
      </div>

      <ul className={styles.matrixList}>
        {all.map((s) => (
          <li key={s}>
            <StatusNodeFor status={s} size={20} />
            <div className={styles.matrixListBody}>
              <div className={styles.matrixListRow}>
                <StatusBadge status={s} />
                <span className={styles.matrixKey}>{s}</span>
              </div>
              <span className={styles.matrixMeaning}>{statusRegistry[s].meaning}</span>
            </div>
          </li>
        ))}
      </ul>
    </DocSection>
  );
}

/* ─── Interaction ───────────────────────────────────────────────────────── */

function InteractionStates() {
  const lesson = foundationsCourse.chapters[2].lessons[4];
  const rows: { name: string; note?: string; a: JSX.Element; b: JSX.Element; c: JSX.Element }[] = [
    {
      name: 'Default',
      a: <Button variant="primary">Submit</Button>,
      b: (
        <Field label="Title" hideLabel>
          <Input defaultValue="Quadratic equations" />
        </Field>
      ),
      c: <Checkbox label="Notify learners" />,
    },
    {
      name: 'Hover',
      note: 'pointer only',
      a: (
        <Button variant="primary" forceState="hover">
          Submit
        </Button>
      ),
      b: (
        <Field label="Title" hideLabel>
          <Input defaultValue="Quadratic equations" />
        </Field>
      ),
      c: <Checkbox label="Notify learners" />,
    },
    {
      name: 'Focus',
      note: 'keyboard ring',
      a: (
        <Button variant="primary" forceState="focus">
          Submit
        </Button>
      ),
      b: (
        <Field label="Title" hideLabel>
          <Input defaultValue="Quadratic equations" forceFocus />
        </Field>
      ),
      c: <Checkbox label="Notify learners" defaultChecked />,
    },
    {
      name: 'Active',
      a: (
        <Button variant="primary" forceState="active">
          Submit
        </Button>
      ),
      b: (
        <Field label="Title" hideLabel>
          <Input defaultValue="Quadratic equations|" forceFocus />
        </Field>
      ),
      c: <Checkbox label="Notify learners" checked readOnly />,
    },
    {
      name: 'Selected',
      a: <Button forceState="selected">Saved</Button>,
      b: (
        <Field label="Title" hideLabel success="Saved">
          <Input defaultValue="Quadratic equations" />
        </Field>
      ),
      c: <Checkbox label="3 selected" indeterminate readOnly />,
    },
    {
      name: 'Disabled',
      note: 'explains why nearby',
      a: (
        <Button variant="primary" disabled>
          Submit
        </Button>
      ),
      b: (
        <Field label="Title" hideLabel>
          <Input defaultValue="Quadratic equations" disabled />
        </Field>
      ),
      c: <Checkbox label="Notify learners" disabled />,
    },
    {
      name: 'Loading',
      a: (
        <Button variant="primary" loading>
          Submit
        </Button>
      ),
      b: <Skeleton height={40} radius="var(--r-sm)" />,
      c: <Skeleton width={140} height={12} />,
    },
    {
      name: 'Error',
      a: <Button variant="danger">Retry upload</Button>,
      b: (
        <Field label="Title" hideLabel error="Add a title.">
          <Input defaultValue="" />
        </Field>
      ),
      c: <StatusLabel status="failed" label="Couldn’t save" />,
    },
    {
      name: 'Success',
      a: (
        <Button variant="primary" succeeded>
          Submitted
        </Button>
      ),
      b: (
        <Field label="Title" hideLabel success="Looks good.">
          <Input defaultValue="Quadratic equations" />
        </Field>
      ),
      c: <StatusLabel status="completed" label="Saved just now" />,
    },
  ];

  return (
    <DocSection
      id="interaction"
      index={2}
      title="Interaction states"
      lead="Default, hover, focus, active, selected, disabled, loading, error, success — forced here for comparison. Focus is always a visible 2px accent ring; hover never carries information."
    >
      <Specimen surface="panel">
        <div className={styles.interaction}>
          <div className={`${styles.interactionRow} ${styles.interactionHeadRow}`}>
            <span className={styles.interactionHead}>State</span>
            <span className={styles.interactionHead}>Action</span>
            <span className={styles.interactionHead}>Field</span>
            <span className={styles.interactionHead}>Selection · status</span>
          </div>
          {rows.map((r) => (
            <div key={r.name} className={styles.interactionRow}>
              <span className={styles.interactionName}>
                {r.name}
                {r.note && <span className={styles.interactionNote}>{r.note}</span>}
              </span>
              <span>{r.a}</span>
              <span>{r.b}</span>
              <span>{r.c}</span>
            </div>
          ))}
        </div>
      </Specimen>
      <LessonRowStates lessonTitle={lesson.title} />
    </DocSection>
  );
}

function LessonRowStates({ lessonTitle }: { lessonTitle: string }) {
  const lesson = foundationsCourse.chapters[2].lessons[4];
  return (
    <Specimen
      label="Lesson row"
      notes={
        <Notes
          items={[
            { term: 'Same row, four states', text: 'Completed dims the title, current gains the accent ground and resume cue, locked loses its action.' },
          ]}
        />
      }
    >
      <ol className={styles.plainList} aria-label={`${lessonTitle} in each state`}>
        <LessonRow lesson={lesson} index={5} state="completed" onSelect={() => undefined} />
        <LessonRow lesson={lesson} index={5} state="in-progress" fraction={0.55} current onSelect={() => undefined} />
        <LessonRow lesson={lesson} index={5} state="not-started" onSelect={() => undefined} />
        <LessonRow lesson={lesson} index={5} state="locked" />
      </ol>
    </Specimen>
  );
}

/* ─── Region states ─────────────────────────────────────────────────────── */

type RegionView = 'live' | 'loading' | 'empty' | 'error';

function RegionStates() {
  const now = useNow();
  const [view, setView] = useState<RegionView>('live');
  const [attempt, setAttempt] = useState(0);
  const query = useAsync(String(attempt), () => services.learner.listAssignments());

  const reload = (fail: boolean) => {
    simulation.failNext = fail;
    setAttempt((a) => a + 1);
    setView('live');
  };

  const content = () => {
    if (view === 'loading' || (view === 'live' && query.status === 'loading')) {
      return (
        <div aria-label="Loading assignments" role="status">
          {[0, 1, 2].map((i) => (
            <div key={i} className={styles.skeletonRow}>
              <Skeleton width={38} height={38} radius="var(--r-md)" />
              <div className={styles.skeletonLines}>
                <Skeleton width={`${62 - i * 10}%`} height={12} />
                <Skeleton width={`${38 + i * 6}%`} height={9} />
              </div>
            </div>
          ))}
        </div>
      );
    }
    if (view === 'error' || (view === 'live' && query.status === 'error')) {
      return (
        <StateMessage
          kind="error"
          title="Assignments didn’t load"
          actions={
            <Button variant="primary" onClick={() => reload(false)} iconStart={<ArrowCounterClockwise size={15} />}>
              Try again
            </Button>
          }
        >
          We couldn’t reach ZuviloAI. Your drafts are saved on this device.
        </StateMessage>
      );
    }
    if (view === 'empty') {
      return (
        <StateMessage icon={<CheckCircle size={26} />} title="You’re all caught up" actions={<Button>See past submissions</Button>}>
          No assignments are due. The next one, House lordship worksheet, opens when you finish lesson 6 of Chapter 3.
        </StateMessage>
      );
    }
    return (
      <WorkList label="Assignments due">
        {(query.data ?? assignments).slice(0, 3).map((a) => (
          <AssignmentStatus key={a.id} assignment={a} now={now} />
        ))}
      </WorkList>
    );
  };

  return (
    <DocSection
      id="region-states"
      index={3}
      title="Loading, empty, error, success"
      lead="A data region keeps its footprint through every state so the page doesn’t jump. This one runs against the mock service — make it fail and recover."
    >
      <Specimen
        surface="panel"
        toolbar={
          <>
            <SegmentedControl
              label="Region state"
              size="sm"
              value={view}
              onChange={setView}
              segments={[
                { value: 'live', label: 'Live data' },
                { value: 'loading', label: 'Loading' },
                { value: 'empty', label: 'Empty' },
                { value: 'error', label: 'Error' },
              ]}
            />
            <Button size="sm" variant="quiet" onClick={() => reload(true)}>
              Fail next load
            </Button>
          </>
        }
      >
        <div className={styles.regionDemo} aria-live="polite">
          <div className={styles.completionHead}>
            <span className="type-h4">
              <ClipboardText size={17} /> Assignments due
            </span>
            <span className={styles.caption}>Class 10 Mathematics</span>
          </div>
          {content()}
        </div>
      </Specimen>
    </DocSection>
  );
}

/* ─── Transitions ───────────────────────────────────────────────────────── */

function Transitions() {
  const toast = useToast();
  const chapter = foundationsCourse.chapters[2];
  const [completed, setCompleted] = useState(4);
  const [justCompleted, setJustCompleted] = useState(false);

  const complete = () => {
    if (completed >= 6) return;
    setCompleted((c) => c + 1);
    setJustCompleted(true);
    toast({
      kind: 'success',
      title: 'Lesson completed',
      text: chapter.lessons[completed].title,
      action: { label: 'Undo', onClick: () => setCompleted((c) => Math.max(4, c - 1)) },
    });
  };

  const items = chapter.lessons.map((l, i) => ({
    id: l.id,
    title: l.title,
    state: i < completed ? ('completed' as const) : i === completed ? ('in-progress' as const) : i === 7 ? ('locked' as const) : ('not-started' as const),
    fraction: i === completed ? 0.55 : undefined,
  }));
  const percent = Math.round((completed / chapter.lessons.length) * 100);

  return (
    <DocSection
      id="transitions"
      index={4}
      title="Status change"
      lead="When state changes, the change is shown where it happened: the node settles, the segments and ring advance, and a toast confirms with an undo. No confetti."
    >
      <Specimen
        surface="panel"
        notes={
          <Notes
            items={[
              { term: 'Announced', text: 'The toast is a polite live region; the ring’s value updates for assistive tech.' },
              { term: 'Undo', text: 'Completion is reversible for a few seconds from the toast.' },
            ]}
          />
        }
      >
        <div className={styles.completionDemo}>
          <div className={styles.completionHead}>
            <span className={styles.row}>
              <ProgressRing value={percent} size="md" label="Chapter 3 progress" />
              <span>
                <span className="type-h4">{chapter.title}</span>
                <span className={`${styles.caption} ${styles.block} tabular`}>
                  {completed} of {chapter.lessons.length} lessons
                </span>
              </span>
            </span>
            <span className={styles.row}>
              <Button
                variant="quiet"
                size="sm"
                onClick={() => {
                  setCompleted(4);
                  setJustCompleted(false);
                }}
              >
                Reset
              </Button>
              <Button variant="primary" onClick={complete} disabled={completed >= 6}>
                Mark current lesson complete
              </Button>
            </span>
          </div>
          <LessonSegments label={chapter.title} items={items} />
          <ol className={styles.plainList}>
            {chapter.lessons.slice(Math.max(0, completed - 1), completed + 1).map((l, i) => {
              const index = Math.max(0, completed - 1) + i;
              const state = index < completed ? 'completed' : 'in-progress';
              return (
                <LessonRow
                  key={`${l.id}-${state}`}
                  lesson={l}
                  index={index + 1}
                  state={state}
                  fraction={0.55}
                  current={state === 'in-progress'}
                  justCompleted={justCompleted && state === 'completed'}
                  onSelect={() => undefined}
                />
              );
            })}
          </ol>
        </div>
      </Specimen>
    </DocSection>
  );
}
