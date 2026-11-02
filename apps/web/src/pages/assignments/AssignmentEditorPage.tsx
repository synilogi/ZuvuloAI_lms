import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useBlocker, useLocation, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import {
  ArrowDown,
  ArrowLeft,
  ArrowUp,
  CheckCircle,
  DesktopTower,
  DeviceMobile,
  Eye,
  FileText,
  FloppyDisk,
  Link as LinkIcon,
  NotePencil,
  PencilSimpleLine,
  Plus,
  RocketLaunch,
  Tray,
  WarningCircle,
  X,
} from '@phosphor-icons/react';
import type { AssignmentInput, Course, CourseAssignment, DuePolicy, RubricCriterion } from '@syniastrolms/domain';
import { assignmentMaxScore, validateAssignment } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { cx } from '@/lib/cx';
import { formatRelative, pad2, plural } from '@/lib/format';
import { ChoiceCards, ErrorSummary, Switch, type FieldIssue } from '@/components/forms/Forms';
import { FileCard, MediaDrop } from '@/components/forms/Upload';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { Meter } from '@/components/lms/progress/Meters';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { AssignmentPreview } from './AssignmentPreview';
import { AssignmentStatusBadge, FORMATS, newCriterionId, rubricTemplate } from './assignmentMeta';
import { SubmissionList } from './SubmissionList';
import styles from './Assignments.module.css';

type Tab = 'details' | 'preview' | 'submissions';

export default function AssignmentEditorPage() {
  const { assignmentId } = useParams();
  const { base, instructorId } = useWorkspace();
  const [params] = useSearchParams();
  const query = useAsync(`assignment-editor:${assignmentId ?? 'new'}`, () =>
    Promise.all([
      assignmentId ? services.assignments.get(assignmentId, instructorId) : Promise.resolve(null),
      services.courses.list({ scopeInstructorId: instructorId, page: 1, pageSize: 100 }),
      assignmentId ? services.assignments.submissions({ assignmentId, scopeInstructorId: instructorId, page: 1, pageSize: 1 }) : Promise.resolve(null),
    ]).then(([assignment, courses, submissions]) => ({
      assignment,
      courses: courses.rows.filter((c) => c.status !== 'archived' || c.id === assignment?.courseId),
      counts: submissions?.counts,
    })),
  );

  usePageCrumbs(query.data ? [{ label: query.data.assignment?.title ?? 'New assignment' }] : [{ label: 'Assignment' }]);

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <StateMessage
        kind="error"
        title={notFound ? 'Assignment not found' : 'The assignment didn’t load'}
        actions={
          notFound ? (
            <LinkButton to={`${base}/assignments`} iconStart={<ArrowLeft size={16} />}>
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
    );
  }
  if (!query.data) {
    return (
      <div className={styles.page} role="status" aria-label="Loading assignment">
        <Skeleton width={120} height={12} />
        <Skeleton width="45%" height={30} radius="var(--r-xs)" />
        <div className={styles.editorGrid}>
          <Skeleton height={480} radius="var(--r-lg)" />
          <Skeleton height={320} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }
  const { assignment, courses, counts } = query.data;
  return (
    <Editor
      key={assignment?.id ?? 'new'}
      assignment={assignment}
      courses={courses}
      counts={counts}
      base={base}
      courseParam={params.get('course')}
      lessonParam={params.get('lesson')}
    />
  );
}

const blank = (courseId: string): AssignmentInput => ({
  courseId,
  chapterId: undefined,
  title: '',
  instructions: '',
  attachments: [],
  format: 'file',
  due: { kind: 'relative', days: 7 },
  acceptsLate: true,
  latePenalty: 10,
  rubric: rubricTemplate('file'),
  maxScore: 20,
  passMark: 12,
  status: 'draft',
});

function toInput(a: CourseAssignment): AssignmentInput {
  const { courseId, chapterId, title, instructions, attachments, format, wordLimit, due, acceptsLate, latePenalty, rubric, maxScore, passMark, status } = a;
  return { courseId, chapterId, title, instructions, attachments, format, wordLimit, due, acceptsLate, latePenalty, rubric, maxScore, passMark, status };
}

const FIELD_IDS: Record<string, string> = {
  title: 'assignment-title',
  course: 'assignment-course',
  instructions: 'assignment-instructions',
  maxScore: 'assignment-max',
  passMark: 'assignment-pass',
  due: 'assignment-due',
  wordLimit: 'assignment-words',
};

interface EditorProps {
  assignment: CourseAssignment | null;
  courses: Course[];
  counts?: Record<string, number>;
  base: string;
  courseParam: string | null;
  /** When the editor was opened from a lesson, the new assignment is delivered by that lesson. */
  lessonParam: string | null;
}

function Editor({ assignment, courses, counts, base, courseParam, lessonParam }: EditorProps) {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const editorTo = assignment ? `${base}/assignments/${assignment.id}` : null;

  const [baseline, setBaseline] = useState<AssignmentInput>(() =>
    assignment ? toInput(assignment) : blank(courses.find((c) => c.id === courseParam)?.id ?? courses[0]?.id ?? ''),
  );
  const [form, setForm] = useState(baseline);
  const [localTab, setLocalTab] = useState<Tab>('details');
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState<null | 'save' | 'publish'>(null);
  const [error, setError] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState(assignment?.updatedAt ?? null);
  const [device, setDevice] = useState<'desktop' | 'mobile'>('desktop');
  const leaving = useRef(false);

  const tab: Tab = editorTo ? (pathname.endsWith('/preview') ? 'preview' : pathname.endsWith('/submissions') ? 'submissions' : 'details') : localTab;
  const goTab = (next: Tab) => {
    if (editorTo) navigate(next === 'details' ? editorTo : `${editorTo}/${next}`, { replace: true });
    else setLocalTab(next);
  };

  const dirty = JSON.stringify(form) !== JSON.stringify(baseline);
  const set = <K extends keyof AssignmentInput>(key: K, value: AssignmentInput[K]) => setForm((f) => ({ ...f, [key]: value }));

  const blocker = useBlocker(
    ({ currentLocation, nextLocation }) =>
      dirty && !leaving.current && !nextLocation.pathname.startsWith(editorTo ?? '__none') && currentLocation.pathname !== nextLocation.pathname,
  );
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const course = courses.find((c) => c.id === form.courseId);
  const chapterIndex = course?.chapters.findIndex((c) => c.id === form.chapterId) ?? -1;
  const chapter = course?.chapters[chapterIndex];
  const lesson = assignment?.lessonId ? course?.chapters.flatMap((c) => c.lessons).find((l) => l.id === assignment.lessonId) : undefined;
  const max = assignmentMaxScore(form);
  const publishIssues = useMemo(() => validateAssignment({ ...form, status: 'published' }, now), [form, now]);

  const validate = (input: AssignmentInput): FieldIssue[] => {
    const all = validateAssignment(input, now);
    const relevant = input.status === 'draft' ? all.filter((i) => i.field === 'title' || i.field === 'course') : all;
    return relevant.map((i) => ({ field: i.criterionId ? `criterion-${i.criterionId}` : FIELD_IDS[i.field], message: i.message }));
  };
  const issues = attempt ? validate(form) : [];
  const errorFor = (field: string) => issues.find((i) => i.field === field)?.message;

  const save = async (mode: 'save' | 'publish') => {
    const input: AssignmentInput = { ...form, status: mode === 'publish' ? 'published' : form.status, title: form.title.trim() };
    setAttempt((a) => a + 1);
    setError(null);
    if (validate(input).length) {
      if (mode === 'publish') setForm((f) => ({ ...f, status: 'published' }));
      goTab('details');
      return;
    }
    setSaving(mode);
    try {
      if (!assignment) {
        const created = await services.assignments.create(lessonParam ? { ...input, lessonId: lessonParam } : input);
        leaving.current = true;
        toast({ kind: 'success', title: mode === 'publish' ? 'Assignment published' : 'Assignment saved as a draft', text: created.title });
        navigate(`${base}/assignments/${created.id}`, { replace: true });
        return;
      }
      const saved = await services.assignments.update(assignment.id, input);
      const next = toInput(saved);
      setForm(next);
      setBaseline(next);
      setSavedAt(saved.updatedAt);
      setAttempt(0);
      toast({ kind: 'success', title: mode === 'publish' ? 'Assignment published' : 'Changes saved', text: input.title });
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(null);
    }
  };

  const stateLine = saving ? 'Saving…' : dirty ? 'Unsaved changes' : savedAt ? `Saved ${formatRelative(savedAt, now)}` : 'Not saved yet';
  const graded = counts ? counts.graded + counts.returned : 0;
  const rubricChanged = JSON.stringify(form.rubric) !== JSON.stringify(baseline.rubric) || form.maxScore !== baseline.maxScore;

  const actions = (
    <>
      <Button iconStart={<FloppyDisk size={16} />} loading={saving === 'save'} disabled={Boolean(saving)} onClick={() => save('save')}>
        {form.status === 'draft' ? 'Save draft' : 'Save'}
      </Button>
      {(!assignment || assignment.status === 'draft') && (
        <Button
          variant="primary"
          iconStart={<RocketLaunch size={16} />}
          loading={saving === 'publish'}
          disabled={Boolean(saving)}
          onClick={() => save('publish')}
        >
          Publish
        </Button>
      )}
    </>
  );

  return (
    <div className={styles.page}>
      <header className={styles.top}>
        <Link to={`${base}/assignments`} className={styles.back}>
          <ArrowLeft size={14} aria-hidden="true" /> Assignments
        </Link>
        <div className={styles.topRow}>
          <div className={styles.topText}>
            <span className={styles.context}>
              {course?.title ?? 'Choose a course'}
              {chapter && ` · Chapter ${pad2(chapterIndex + 1)}`}
            </span>
            <h1 className={styles.heading}>{form.title.trim() || (assignment ? 'Untitled assignment' : 'New assignment')}</h1>
            <div className={styles.topMeta}>
              <AssignmentStatusBadge status={assignment?.status ?? 'draft'} size="md" />
              <span className={styles.formatLabel}>
                {FORMATS[form.format].icon(15)} {FORMATS[form.format].label} · {plural(max, 'point')}
              </span>
              <span className={cx(styles.saveState, dirty && styles.saveStateDirty)} role="status">
                {dirty ? <PencilSimpleLine size={14} /> : <CheckCircle size={14} />}
                {stateLine}
              </span>
            </div>
          </div>
          {!isMobile && <div className={styles.topActions}>{actions}</div>}
        </div>
        <SegmentedControl<Tab>
          label="Assignment sections"
          semantics="tabs"
          idPrefix="assignment"
          value={tab}
          onChange={goTab}
          segments={[
            { value: 'details', label: 'Details', icon: <NotePencil size={15} /> },
            { value: 'preview', label: 'Preview', icon: <Eye size={15} /> },
            ...(assignment
              ? [{ value: 'submissions' as const, label: 'Submissions', icon: <Tray size={15} />, count: counts?.['to-review'] || undefined }]
              : []),
          ]}
        />
      </header>

      <div id="assignment-panel" role="tabpanel" aria-labelledby={`assignment-tab-${tab}`} className={styles.panelArea}>
        {tab === 'details' && (
          <>
            {error && (
              <InlineMessage kind="error" title="Couldn’t save.">
                {error}
              </InlineMessage>
            )}
            <ErrorSummary issues={issues} attempt={attempt} title={form.status === 'draft' ? 'Fix these before saving' : 'Finish these before publishing'} />
            <div className={styles.editorGrid}>
              <div className={styles.main}>
                <section className={styles.panel} aria-label="Assignment">
                  <Field label="Assignment title" error={errorFor('assignment-title')}>
                    <Input
                      id="assignment-title"
                      className={styles.titleInput}
                      value={form.title}
                      onChange={(e) => set('title', e.target.value)}
                      placeholder="Homework: five quadratic equations"
                      autoFocus={!assignment}
                    />
                  </Field>
                  <div className={styles.twoUp}>
                    <Field label="Course" error={errorFor('assignment-course')}>
                      <Select
                        id="assignment-course"
                        value={form.courseId}
                        disabled={Boolean(lesson)}
                        onChange={(e) => setForm((f) => ({ ...f, courseId: e.target.value, chapterId: undefined }))}
                      >
                        {courses.map((c) => (
                          <option key={c.id} value={c.id}>
                            {c.title}
                          </option>
                        ))}
                      </Select>
                    </Field>
                    <Field label="Chapter" optional>
                      <Select value={form.chapterId ?? ''} disabled={Boolean(lesson)} onChange={(e) => set('chapterId', e.target.value || undefined)}>
                        <option value="">Whole course</option>
                        {course?.chapters.map((c, i) => (
                          <option key={c.id} value={c.id}>
                            {pad2(i + 1)} · {c.title}
                          </option>
                        ))}
                      </Select>
                    </Field>
                  </div>
                  {lesson && course && (
                    <p className={styles.linkedLesson}>
                      <LinkIcon size={15} aria-hidden="true" />
                      <span>
                        Delivered by the lesson <Link to={`${base}/courses/${course.id}/lessons/${lesson.id}`}>{lesson.title}</Link>, so it stays in that
                        chapter.
                      </span>
                    </p>
                  )}
                  <Field
                    label="Instructions"
                    error={errorFor('assignment-instructions')}
                    hint={`${plural(form.instructions.trim() ? form.instructions.trim().split(/\s+/).length : 0, 'word')} · Use ## for a heading, - for a list and > for a note. The Preview tab shows how it reads.`}
                  >
                    <Textarea
                      id="assignment-instructions"
                      rows={10}
                      className={styles.instructions}
                      value={form.instructions}
                      onChange={(e) => set('instructions', e.target.value)}
                      placeholder={
                        'Solve the five quadratic equations from page 42, showing every step.\n\n## Then answer\n\n- Which equation has equal roots, and how can you tell?'
                      }
                    />
                  </Field>
                </section>

                <section className={styles.panel} aria-labelledby="resources-title">
                  <h2 id="resources-title" className={styles.panelTitle}>
                    Resources for learners <span className={styles.optional}>Optional</span>
                  </h2>
                  <p className={styles.blockHint}>Worksheets, sample charts or templates learners need. They appear under the instructions.</p>
                  {form.attachments.length > 0 && (
                    <ul className={styles.attachments} aria-label="Attached resources">
                      {form.attachments.map((file) => (
                        <li key={file.id}>
                          <FileCard
                            icon={<FileText size={18} />}
                            file={file}
                            detail={file.pages ? plural(file.pages, 'page') : 'Resource'}
                            onRemove={() =>
                              set(
                                'attachments',
                                form.attachments.filter((a) => a.id !== file.id),
                              )
                            }
                          />
                        </li>
                      ))}
                    </ul>
                  )}
                  {form.attachments.length < 5 ? (
                    <MediaDrop
                      id="assignment-attachment"
                      accept=".pdf,.png,.jpg,.jpeg,.docx"
                      label="Add a worksheet or chart"
                      hint="PDF, image or Word document, up to 25 MB"
                      icon={<FileText size={18} />}
                      onDone={(file) =>
                        set('attachments', [
                          ...form.attachments,
                          {
                            id: newCriterionId(),
                            name: file.name,
                            sizeMb: file.sizeMb,
                            pages: file.name.endsWith('.pdf') ? Math.max(1, Math.round(file.sizeMb * 3)) : undefined,
                          },
                        ])
                      }
                    />
                  ) : (
                    <p className={styles.blockHint}>Five resources is the most an assignment can carry. Remove one to add another.</p>
                  )}
                </section>

                <section className={styles.panel} aria-labelledby="format-title">
                  <h2 id="format-title" className={styles.panelTitle}>
                    What learners hand in
                  </h2>
                  <ChoiceCards
                    legend="Submission type"
                    hideLegend
                    columns={3}
                    value={form.format}
                    onChange={(format) =>
                      setForm((f) => {
                        // A rubric still matching the old format's starting template follows the format.
                        const shape = (r: RubricCriterion[]) => JSON.stringify(r.map(({ title, description, points }) => [title, description, points]));
                        const untouched = shape(f.rubric) === shape(rubricTemplate(f.format));
                        return { ...f, format, wordLimit: format === 'file' ? undefined : f.wordLimit, rubric: untouched ? rubricTemplate(format) : f.rubric };
                      })
                    }
                    // The retired chart format is offered only to an assignment that already uses it.
                    choices={(form.format === 'chart' ? (['file', 'text', 'chart'] as const) : (['file', 'text'] as const)).map((value) => ({
                      value,
                      label: FORMATS[value].label,
                      description: FORMATS[value].description,
                      icon: FORMATS[value].icon(20),
                    }))}
                  />
                  {form.format !== 'file' && (
                    <div className={styles.inlineRow}>
                      <Switch
                        checked={form.wordLimit !== undefined}
                        onChange={(on) => set('wordLimit', on ? 600 : undefined)}
                        label="Set a word limit"
                        description={form.wordLimit ? 'Learners see a live count as they write.' : 'Learners can write as much as they need.'}
                      />
                      {form.wordLimit !== undefined && (
                        <Field label="Words" error={errorFor('assignment-words')} className={styles.narrowField}>
                          <Input
                            id="assignment-words"
                            type="number"
                            inputMode="numeric"
                            min={50}
                            max={5000}
                            step={50}
                            value={form.wordLimit}
                            onChange={(e) => set('wordLimit', Number(e.target.value))}
                          />
                        </Field>
                      )}
                    </div>
                  )}
                </section>

                <section className={styles.panel} aria-labelledby="grading-title">
                  <h2 id="grading-title" className={styles.panelTitle}>
                    Grading
                  </h2>
                  {assignment && graded > 0 && rubricChanged && (
                    <InlineMessage kind="warn" title={`${plural(graded, 'submission')} were reviewed with the saved rubric.`}>
                      Their scores stay as they are. Reviews from now on use the rubric below.
                    </InlineMessage>
                  )}
                  <Switch
                    checked={form.rubric.length > 0}
                    onChange={(on) => setForm((f) => ({ ...f, rubric: on ? rubricTemplate(f.format) : [], maxScore: on ? 20 : assignmentMaxScore(f) }))}
                    label="Grade with a rubric"
                    description="Score each criterion; the maximum is their total. Learners see the rubric before they start."
                  />
                  {form.rubric.length > 0 ? (
                    <RubricEditor rubric={form.rubric} onChange={(rubric) => set('rubric', rubric)} errorFor={errorFor} />
                  ) : (
                    <Field label="Maximum score" error={errorFor('assignment-max')} className={styles.narrowField}>
                      <Input
                        id="assignment-max"
                        type="number"
                        inputMode="numeric"
                        min={1}
                        max={100}
                        value={form.maxScore}
                        onChange={(e) => set('maxScore', Number(e.target.value))}
                      />
                    </Field>
                  )}
                  <div className={styles.passRow}>
                    <Field
                      label="Pass mark"
                      error={errorFor('assignment-pass')}
                      hint={max ? `${Math.round((form.passMark / max) * 100)}% of ${plural(max, 'point')}` : undefined}
                      className={styles.narrowField}
                    >
                      <Input
                        id="assignment-pass"
                        type="number"
                        inputMode="numeric"
                        min={1}
                        max={max || 100}
                        step={0.5}
                        value={form.passMark}
                        onChange={(e) => set('passMark', Number(e.target.value))}
                      />
                    </Field>
                    <Meter
                      className={styles.passMeter}
                      value={max ? Math.min(100, (form.passMark / max) * 100) : 0}
                      threshold={max ? Math.min(100, (form.passMark / max) * 100) : undefined}
                      label="Pass mark as a share of the maximum score"
                    />
                  </div>
                </section>
              </div>

              <aside className={styles.side}>
                <section className={styles.panel} aria-labelledby="due-title">
                  <h2 id="due-title" className={styles.panelTitle}>
                    Due date
                  </h2>
                  <DueEditor due={form.due} onChange={(due) => set('due', due)} error={errorFor('assignment-due')} />
                  <Switch
                    checked={form.acceptsLate}
                    onChange={(acceptsLate) => setForm((f) => ({ ...f, acceptsLate, latePenalty: acceptsLate ? f.latePenalty || 10 : 0 }))}
                    label="Accept late work"
                    description={form.acceptsLate ? 'Late submissions are marked late in review.' : 'Submissions close at the due date.'}
                  />
                  {form.acceptsLate && (
                    <Field label="Late penalty" hint="Taken off the score when a late submission is graded.">
                      <Select value={form.latePenalty} onChange={(e) => set('latePenalty', Number(e.target.value))}>
                        {[0, 5, 10, 20, 25].map((p) => (
                          <option key={p} value={p}>
                            {p === 0 ? 'No penalty' : `${p}% off`}
                          </option>
                        ))}
                      </Select>
                    </Field>
                  )}
                </section>

                <section className={styles.panel} aria-labelledby="status-title">
                  <h2 id="status-title" className={styles.panelTitle}>
                    Status
                  </h2>
                  <ChoiceCards
                    legend="Status"
                    hideLegend
                    columns={1}
                    value={form.status}
                    onChange={(v) => set('status', v)}
                    choices={[
                      { value: 'published', label: 'Published', description: 'Learners who reach the chapter can submit.' },
                      { value: 'draft', label: 'Draft', description: 'Hidden while you work on it.' },
                      { value: 'closed', label: 'Closed', description: 'Visible with feedback; no new submissions.', disabled: !assignment },
                    ]}
                  />
                  {publishIssues.length > 0 ? (
                    <ul className={styles.readiness} aria-label="Before publishing">
                      {publishIssues.map((i) => (
                        <li key={`${i.field}-${i.criterionId ?? ''}`}>
                          <WarningCircle size={15} /> {i.message}
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <p className={styles.ready}>
                      <CheckCircle size={15} weight="fill" /> Ready to publish
                    </p>
                  )}
                </section>
              </aside>
            </div>
          </>
        )}

        {tab === 'preview' && (
          <div className={styles.previewArea}>
            <div className={styles.previewBar}>
              <span>
                <Eye size={16} /> How learners see this assignment{dirty ? ', including unsaved changes' : ''}
              </span>
              {!isMobile && (
                <SegmentedControl
                  size="sm"
                  label="Preview width"
                  value={device}
                  onChange={setDevice}
                  segments={[
                    { value: 'desktop', label: 'Desktop', icon: <DesktopTower size={15} /> },
                    { value: 'mobile', label: 'Mobile', icon: <DeviceMobile size={15} /> },
                  ]}
                />
              )}
            </div>
            <div className={cx(styles.previewFrame, device === 'mobile' && !isMobile && styles.previewMobile)}>
              <AssignmentPreview
                assignment={form}
                courseTitle={course?.title ?? ''}
                chapterLabel={chapter ? `Chapter ${pad2(chapterIndex + 1)} · ${chapter.title}` : undefined}
              />
            </div>
          </div>
        )}

        {tab === 'submissions' && assignment && <SubmissionList mode="assignment" assignment={assignment} />}
      </div>

      {isMobile && tab !== 'submissions' && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{actions}</div>}>
          <span />
        </StickyActionBar>
      )}

      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave without saving?"
        description={`Your changes to ${form.title.trim() || 'this assignment'} haven’t been saved.`}
        footer={
          <>
            <Button onClick={() => blocker.reset?.()}>Keep editing</Button>
            <Button variant="danger" onClick={() => blocker.proceed?.()}>
              Discard changes
            </Button>
          </>
        }
      />
    </div>
  );
}

/* ─── Due date ─────────────────────────────────────────────────────────── */

function DueEditor({ due, onChange, error }: { due: DuePolicy; onChange: (due: DuePolicy) => void; error?: string }) {
  const date = due.kind === 'date' ? due.dueAt.slice(0, 10) : '';
  const time = due.kind === 'date' ? due.dueAt.slice(11, 16) : '23:59';
  const toIso = (d: string, t: string) => `${d}T${t || '23:59'}:00+05:30`;
  return (
    <>
      <ChoiceCards<DuePolicy['kind']>
        legend="When it’s due"
        hideLegend
        columns={1}
        value={due.kind}
        onChange={(kind) => onChange(kind === 'date' ? { kind, dueAt: toIso('2026-09-30', '23:59') } : kind === 'relative' ? { kind, days: 7 } : { kind })}
        choices={[
          { value: 'relative', label: 'After the lesson unlocks', description: 'Each learner gets the same time, whenever they start.' },
          { value: 'date', label: 'On a fixed date', description: 'For cohorts that work to one deadline.' },
          { value: 'none', label: 'No due date', description: 'Practice work learners hand in when ready.' },
        ]}
      />
      {due.kind === 'relative' && (
        <Field label="Days to hand in" error={error}>
          <Input
            id="assignment-due"
            type="number"
            inputMode="numeric"
            min={1}
            max={60}
            value={due.days}
            onChange={(e) => onChange({ kind: 'relative', days: Number(e.target.value) })}
          />
        </Field>
      )}
      {due.kind === 'date' && (
        <div className={styles.twoUp}>
          <Field label="Date" error={error}>
            <Input
              id="assignment-due"
              type="date"
              value={date}
              onChange={(e) => e.target.value && onChange({ kind: 'date', dueAt: toIso(e.target.value, time) })}
            />
          </Field>
          <Field label="Time (IST)">
            <Input type="time" value={time} onChange={(e) => onChange({ kind: 'date', dueAt: toIso(date, e.target.value) })} />
          </Field>
        </div>
      )}
    </>
  );
}

/* ─── Rubric ───────────────────────────────────────────────────────────── */

function RubricEditor({
  rubric,
  onChange,
  errorFor,
}: {
  rubric: RubricCriterion[];
  onChange: (rubric: RubricCriterion[]) => void;
  errorFor: (field: string) => string | undefined;
}) {
  const total = rubric.reduce((n, c) => n + (c.points || 0), 0);
  const update = (id: string, patch: Partial<RubricCriterion>) => onChange(rubric.map((c) => (c.id === id ? { ...c, ...patch } : c)));
  const move = (index: number, dir: -1 | 1) => {
    const next = [...rubric];
    [next[index], next[index + dir]] = [next[index + dir], next[index]];
    onChange(next);
  };
  return (
    <div className={styles.rubric}>
      <ol className={styles.criteria} aria-label="Rubric criteria">
        {rubric.map((c, i) => {
          const issue = errorFor(`criterion-${c.id}`);
          return (
            <li key={c.id} className={cx(styles.criterion, issue && styles.criterionError)}>
              <span className={styles.criterionNumber} aria-hidden="true">
                {i + 1}
              </span>
              <div className={styles.criterionFields}>
                <div className={styles.criterionTop}>
                  <Input
                    id={`criterion-${c.id}`}
                    aria-label={`Criterion ${i + 1}`}
                    value={c.title}
                    placeholder="Chart accuracy"
                    onChange={(e) => update(c.id, { title: e.target.value })}
                  />
                  <span className={styles.pointsInput}>
                    <Input
                      aria-label={`Points for criterion ${i + 1}`}
                      type="number"
                      inputMode="numeric"
                      min={1}
                      max={50}
                      value={c.points}
                      onChange={(e) => update(c.id, { points: Number(e.target.value) })}
                    />
                    <span aria-hidden="true">pts</span>
                  </span>
                </div>
                <Input
                  aria-label={`What earns full marks for criterion ${i + 1}`}
                  value={c.description}
                  placeholder="What earns full marks"
                  onChange={(e) => update(c.id, { description: e.target.value })}
                />
                {issue && (
                  <p className={styles.issue}>
                    <WarningCircle size={14} /> {issue}
                  </p>
                )}
              </div>
              <div className={styles.criterionActions}>
                <IconButton size="sm" label={`Move criterion ${i + 1} up`} icon={<ArrowUp size={14} />} disabled={i === 0} onClick={() => move(i, -1)} />
                <IconButton
                  size="sm"
                  label={`Move criterion ${i + 1} down`}
                  icon={<ArrowDown size={14} />}
                  disabled={i === rubric.length - 1}
                  onClick={() => move(i, 1)}
                />
                <IconButton
                  size="sm"
                  label={`Remove criterion ${i + 1}`}
                  icon={<X size={14} />}
                  disabled={rubric.length <= 1}
                  onClick={() => onChange(rubric.filter((x) => x.id !== c.id))}
                />
              </div>
            </li>
          );
        })}
      </ol>
      <div className={styles.rubricFoot}>
        <Button
          size="sm"
          variant="ghost"
          iconStart={<Plus size={14} />}
          disabled={rubric.length >= 8}
          onClick={() => onChange([...rubric, { id: newCriterionId(), title: '', description: '', points: 2 }])}
        >
          Add criterion
        </Button>
        <span className={styles.rubricTotal}>
          Maximum score <strong className="tabular">{plural(total, 'point')}</strong>
        </span>
      </div>
    </div>
  );
}
