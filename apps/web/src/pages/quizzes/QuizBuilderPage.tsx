import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useBlocker, useLocation, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import {
  ArrowLeft,
  ArrowRight,
  Archive,
  ArrowCounterClockwise,
  CaretLeft,
  CaretRight,
  ChartBar,
  CheckCircle,
  Eye,
  FloppyDisk,
  GearSix,
  ListNumbers,
  PencilSimpleLine,
  Plus,
  RocketLaunch,
  WarningCircle,
} from '@phosphor-icons/react';
import type { Course, Quiz, QuizInput, QuizQuestion, QuizSettings, QuestionType } from '@syniastrolms/domain';
import { defaultQuizSettings, quizTotalPoints } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { usePermissions } from '@/hooks/usePermissions';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { cx } from '@/lib/cx';
import { formatCount, formatMoment, formatRelative, pad2, plural } from '@/lib/format';
import { ColumnChart } from '@/components/charts/Charts';
import { Figure } from '@/components/data/KpiStrip';
import { ChoiceCards, FormSection, Switch } from '@/components/forms/Forms';
import { SectionHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { Meter } from '@/components/lms/progress/Meters';
import { QuizTaker } from '@/components/lms/quiz/QuizTaker';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type QuizAttemptRow } from '@/services';
import { blankQuestion, newId, QUESTION_TYPES, QuestionEditor } from './QuestionEditor';
import {
  applyWindow,
  ATTEMPT_STATUS_LABEL,
  builderIssues,
  checkedOnSave,
  formatTaken,
  STATUS_LABEL,
  windowDraft,
  windowIssues,
  type QuizWindowDraft,
} from './quizForm';
import styles from './Quizzes.module.css';

type Tab = 'questions' | 'settings' | 'preview' | 'results';

export default function QuizBuilderPage() {
  const { quizId } = useParams();
  const { base, instructorId } = useWorkspace();
  const [params] = useSearchParams();
  const query = useAsync(`quiz-builder:${quizId ?? 'new'}`, () =>
    Promise.all([
      quizId ? services.quizzes.get(quizId, instructorId) : Promise.resolve(null),
      services.courses.list({ scopeInstructorId: instructorId, page: 1, pageSize: 100 }),
    ]).then(([quiz, courses]) => ({ quiz, courses: courses.rows.filter((c) => c.status !== 'archived' || c.id === quiz?.courseId) })),
  );

  usePageCrumbs(query.data ? [{ label: query.data.quiz?.title ?? 'New quiz' }] : [{ label: 'Quiz' }]);

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <StateMessage
        kind="error"
        title={notFound ? 'Quiz not found' : 'The quiz builder didn’t load'}
        actions={
          notFound ? (
            <LinkButton to={`${base}/quizzes`} iconStart={<ArrowLeft size={16} />}>
              Back to quizzes
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
      <div className={styles.page} role="status" aria-label="Loading quiz">
        <Skeleton width={120} height={12} />
        <Skeleton width="45%" height={30} radius="var(--r-xs)" />
        <div className={styles.workspace}>
          <Skeleton height={420} radius="var(--r-lg)" />
          <Skeleton height={420} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }
  return (
    <Builder
      key={query.data.quiz?.id ?? 'new'}
      quiz={query.data.quiz}
      courses={query.data.courses}
      base={base}
      courseParam={params.get('course')}
      lessonParam={params.get('lesson')}
    />
  );
}

function toInput(quiz: Quiz): QuizInput {
  const { courseId, chapterId, title, instructions, status, questions, settings } = quiz;
  return { courseId, chapterId, title, instructions, status, questions, settings };
}

function Builder({
  quiz,
  courses,
  base,
  courseParam,
  lessonParam,
}: {
  quiz: Quiz | null;
  courses: Course[];
  base: string;
  courseParam: string | null;
  /** When the builder was opened from a lesson, the new quiz is delivered by that lesson. */
  lessonParam: string | null;
}) {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const quizTo = quiz ? `${base}/quizzes/${quiz.id}` : null;

  const [baseline, setBaseline] = useState<QuizInput>(() =>
    quiz
      ? toInput(quiz)
      : {
          courseId: courses.find((c) => c.id === courseParam)?.id ?? courses[0]?.id ?? '',
          chapterId: undefined,
          title: '',
          instructions: '',
          status: 'draft',
          questions: [],
          settings: { ...defaultQuizSettings },
        },
  );
  const [form, setForm] = useState(baseline);
  // The window as typed, in IST; the settings carry it as moments once both halves of an edge are filled in.
  const [draft, setDraft] = useState<QuizWindowDraft>(() => windowDraft(baseline.settings));
  const [serverIssues, setServerIssues] = useState<string[]>([]);
  const [statusBusy, setStatusBusy] = useState(false);
  const { can } = usePermissions();
  const canEdit = can('assessment.edit');
  const [selectedId, setSelectedId] = useState<string | null>(form.questions[0]?.id ?? null);
  const [localTab, setLocalTab] = useState<Tab>('questions');
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState<null | 'save' | 'publish'>(null);
  const [error, setError] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState(quiz?.updatedAt ?? null);
  const [reveal, setReveal] = useState(true);
  const [previewKey, setPreviewKey] = useState(0);
  const [removing, setRemoving] = useState<QuizQuestion | null>(null);
  const leaving = useRef(false);

  const tab: Tab = quizTo
    ? pathname.endsWith('/settings')
      ? 'settings'
      : pathname.endsWith('/preview')
        ? 'preview'
        : pathname.endsWith('/results')
          ? 'results'
          : 'questions'
    : localTab;
  const goTab = (next: Tab) => {
    if (quizTo) navigate(next === 'questions' ? quizTo : `${quizTo}/${next}`, { replace: true });
    else setLocalTab(next);
  };

  const dirty = JSON.stringify(form) !== JSON.stringify(baseline);
  const set = <K extends keyof QuizInput>(key: K, value: QuizInput[K]) => setForm((f) => ({ ...f, [key]: value }));
  const setQuestions = (questions: QuizQuestion[]) => set('questions', questions);
  const setWindow = (patch: Partial<QuizWindowDraft>) => {
    const next = { ...draft, ...patch };
    setDraft(next);
    setForm((f) => ({ ...f, settings: applyWindow(f.settings, next) }));
  };

  const blocker = useBlocker(
    ({ currentLocation, nextLocation }) =>
      dirty && !leaving.current && !nextLocation.pathname.startsWith(quizTo ?? '__none') && currentLocation.pathname !== nextLocation.pathname,
  );
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const issues = useMemo(() => builderIssues(form, draft), [form, draft]);
  const showIssues = attempt > 0;
  const issuesByQuestion = useMemo(() => {
    const map = new Map<string, typeof issues>();
    for (const i of issues) if (i.questionId) map.set(i.questionId, [...(map.get(i.questionId) ?? []), i]);
    return map;
  }, [issues]);
  const course = courses.find((c) => c.id === form.courseId);
  const chapter = course?.chapters.find((c) => c.id === form.chapterId);
  const points = quizTotalPoints(form);
  const selectedIndex = form.questions.findIndex((q) => q.id === selectedId);
  const selected = form.questions[selectedIndex];

  const addQuestion = (type: QuestionType) => {
    const q = blankQuestion(type);
    const at = selectedIndex >= 0 ? selectedIndex + 1 : form.questions.length;
    const next = [...form.questions];
    next.splice(at, 0, q);
    setQuestions(next);
    setSelectedId(q.id);
    goTab('questions');
    requestAnimationFrame(() => document.getElementById(`q-${q.id}-prompt`)?.focus());
  };
  const updateQuestion = (next: QuizQuestion) => setQuestions(form.questions.map((q) => (q.id === next.id ? next : q)));
  const moveQuestion = (dir: -1 | 1) => {
    const next = [...form.questions];
    [next[selectedIndex], next[selectedIndex + dir]] = [next[selectedIndex + dir], next[selectedIndex]];
    setQuestions(next);
  };
  const duplicateQuestion = () => {
    const id = newId('q');
    const ids = new Map(selected.options.map((o, i) => [o.id, `${id}-o${i + 1}`]));
    const copy: QuizQuestion = {
      ...selected,
      id,
      options: selected.options.map((o) => ({ ...o, id: ids.get(o.id)! })),
      correct: selected.correct.map((c) => ids.get(c) ?? c),
    };
    const next = [...form.questions];
    next.splice(selectedIndex + 1, 0, copy);
    setQuestions(next);
    setSelectedId(id);
    toast({ kind: 'success', title: `Question ${selectedIndex + 1} duplicated`, text: `The copy is question ${selectedIndex + 2}.` });
  };
  const deleteQuestion = (q: QuizQuestion) => {
    const index = form.questions.indexOf(q);
    const next = form.questions.filter((x) => x.id !== q.id);
    setQuestions(next);
    setSelectedId(next[Math.min(index, next.length - 1)]?.id ?? null);
    setRemoving(null);
    toast({
      kind: 'info',
      title: 'Question removed',
      text: q.prompt ? `“${q.prompt.slice(0, 60)}${q.prompt.length > 60 ? '…' : ''}”` : `Question ${index + 1}`,
      action: {
        label: 'Undo',
        onClick: () => {
          setForm((f) => {
            const restored = [...f.questions];
            restored.splice(index, 0, q);
            return { ...f, questions: restored };
          });
          setSelectedId(q.id);
        },
      },
    });
  };

  const save = async (mode: 'save' | 'publish') => {
    const input: QuizInput = { ...form, status: mode === 'publish' ? 'published' : form.status };
    setAttempt((a) => a + 1);
    setError(null);
    setServerIssues([]);
    const found = builderIssues(input, draft);
    // A half-typed window always stops a save; the rest only stops one that goes live.
    const blocking = checkedOnSave(input.status) ? found : windowIssues(draft);
    if (input.title.trim().length < 3 || blocking.length) {
      const first = blocking.find((i) => i.questionId);
      if (first?.questionId) setSelectedId(first.questionId);
      if (tab !== 'settings' || !blocking.some((i) => i.field === 'settings'))
        goTab(blocking.some((i) => i.field === 'settings') && !first ? 'settings' : 'questions');
      return;
    }
    setSaving(mode);
    try {
      if (!quiz) {
        const created = await services.quizzes.create(lessonParam ? { ...input, lessonId: lessonParam } : input);
        leaving.current = true;
        toast({ kind: 'success', title: mode === 'publish' ? 'Quiz published' : 'Quiz saved as a draft', text: created.title });
        navigate(`${base}/quizzes/${created.id}`, { replace: true });
        return;
      }
      await services.quizzes.update(quiz.id, input);
      setForm(input);
      setBaseline(input);
      setSavedAt(new Date(now.getTime()).toISOString());
      setAttempt(0);
      toast({ kind: 'success', title: mode === 'publish' ? 'Quiz published' : 'Changes saved', text: input.title });
    } catch (e) {
      // A refusal to publish lists what the server's checks found.
      const listed = ((e as { issues?: { message: string }[] }).issues ?? []).map((i) => i.message);
      setServerIssues([...new Set(listed)]);
      setError(listed.length ? 'The server found these before publishing:' : (e as Error).message);
    } finally {
      setSaving(null);
    }
  };

  // Archiving keeps the quiz and every result, but no learner starts it again; restoring publishes it again.
  const changeStatus = async (status: 'archived' | 'published') => {
    if (!quiz) return;
    setStatusBusy(true);
    setError(null);
    setServerIssues([]);
    try {
      await services.quizzes.update(quiz.id, { status });
      setForm((f) => ({ ...f, status }));
      setBaseline((b) => ({ ...b, status }));
      toast({
        kind: 'success',
        title: status === 'archived' ? 'Quiz archived' : 'Quiz restored',
        text: status === 'archived' ? 'Learners can’t start it any more. Every result is kept.' : 'Learners can take it again.',
      });
    } catch (e) {
      const listed = ((e as { issues?: { message: string }[] }).issues ?? []).map((i) => i.message);
      setServerIssues([...new Set(listed)]);
      setError(listed.length ? 'It can’t be published again until these are fixed:' : (e as Error).message);
    } finally {
      setStatusBusy(false);
    }
  };

  const quizIssues = issues.filter((i) => !i.questionId);
  const questionIssueCount = issuesByQuestion.size;
  const stateLine = saving ? 'Saving…' : dirty ? 'Unsaved changes' : savedAt ? `Saved ${formatRelative(savedAt, now)}` : 'Not saved yet';

  const actions = (
    <>
      <Button iconStart={<FloppyDisk size={16} />} loading={saving === 'save'} disabled={Boolean(saving)} onClick={() => save('save')}>
        {form.status === 'published' ? 'Save' : 'Save draft'}
      </Button>
      {(!quiz || form.status === 'draft') && (
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
      {quiz && canEdit && form.status === 'published' && (
        <Button iconStart={<Archive size={16} />} loading={statusBusy} disabled={Boolean(saving) || dirty} onClick={() => changeStatus('archived')}>
          Archive
        </Button>
      )}
      {quiz && canEdit && form.status === 'archived' && (
        <Button
          variant="primary"
          iconStart={<ArrowCounterClockwise size={16} />}
          loading={statusBusy}
          disabled={Boolean(saving) || dirty}
          onClick={() => changeStatus('published')}
        >
          Restore
        </Button>
      )}
    </>
  );

  const addMenu = (label = 'Add question', variant: 'primary' | 'secondary' = 'secondary') => (
    <Menu
      width={220}
      trigger={(props) => (
        <Button {...props} variant={variant} size="sm" iconStart={<Plus size={15} />}>
          {label}
        </Button>
      )}
      sections={[
        { label: 'Question type', items: QUESTION_TYPES.map((t) => ({ id: t.value, label: t.label, icon: t.icon, onSelect: () => addQuestion(t.value) })) },
      ]}
    />
  );

  return (
    <div className={styles.page}>
      <header className={styles.top}>
        <Link to={`${base}/quizzes`} className={styles.back}>
          <ArrowLeft size={14} aria-hidden="true" /> Quizzes
        </Link>
        <div className={styles.topRow}>
          <div className={styles.topText}>
            <span className={styles.context}>
              {course?.title ?? 'Choose a course'}
              {chapter && ` · ${chapter.title}`}
            </span>
            <h1 className={styles.heading}>{form.title.trim() || (quiz ? 'Untitled quiz' : 'New quiz')}</h1>
            <div className={styles.topMeta}>
              {quiz && baseline.status === 'published' ? (
                <Badge tone="accent" dot>
                  {STATUS_LABEL.published}
                </Badge>
              ) : quiz && baseline.status === 'archived' ? (
                <Badge tone="neutral">{STATUS_LABEL.archived}</Badge>
              ) : (
                <Badge tone="warn">{STATUS_LABEL.draft}</Badge>
              )}
              <span>
                {plural(form.questions.length, 'question')} · {plural(points, 'point')}
              </span>
              {questionIssueCount > 0 && (
                <span className={styles.issueCount}>
                  <WarningCircle size={14} /> {plural(questionIssueCount, 'question')} to finish
                </span>
              )}
              <span className={cx(styles.saveState, dirty && styles.saveStateDirty)} role="status">
                {dirty ? <PencilSimpleLine size={14} /> : <CheckCircle size={14} />}
                {stateLine}
              </span>
            </div>
          </div>
          {!isMobile && <div className={styles.topActions}>{actions}</div>}
        </div>
        <SegmentedControl<Tab>
          label="Quiz builder sections"
          semantics="tabs"
          idPrefix="quiz"
          size={isMobile ? 'sm' : 'md'}
          value={tab}
          onChange={goTab}
          // Four tabs fit a phone once the icons go.
          segments={[
            { value: 'questions', label: 'Questions', icon: isMobile ? undefined : <ListNumbers size={15} />, count: form.questions.length },
            { value: 'settings', label: 'Settings', icon: isMobile ? undefined : <GearSix size={15} /> },
            { value: 'preview', label: 'Preview', icon: isMobile ? undefined : <Eye size={15} /> },
            ...(quiz ? [{ value: 'results' as const, label: 'Results', icon: isMobile ? undefined : <ChartBar size={15} /> }] : []),
          ]}
        />
      </header>

      <div id="quiz-panel" role="tabpanel" aria-labelledby={`quiz-tab-${tab}`} className={styles.panelArea}>
        {baseline.status === 'archived' && quiz && (
          <InlineMessage kind="info" title="This quiz is archived.">
            Learners can’t start it, and its lesson no longer shows it. An attempt already under way can still be handed in, and every result is kept.
            {canEdit ? ' Restore it to let learners take it again.' : ''}
          </InlineMessage>
        )}
        {(error || (showIssues && (quizIssues.length > 0 || (form.status === 'published' && questionIssueCount > 0)))) &&
          tab !== 'preview' &&
          tab !== 'results' && (
            <div className={styles.summary} role="alert">
              <WarningCircle size={20} />
              <div>
                <p className={styles.summaryTitle}>{error ? 'Couldn’t save.' : 'Finish these before publishing'}</p>
                {error && <p>{error}</p>}
                {error && serverIssues.length > 0 && (
                  <ul>
                    {serverIssues.map((m) => (
                      <li key={m}>{m}</li>
                    ))}
                  </ul>
                )}
                {!error && (
                  <ul>
                    {quizIssues.map((i) => (
                      <li key={i.message}>{i.message}</li>
                    ))}
                    {[...issuesByQuestion.entries()].map(([id, list]) => {
                      const index = form.questions.findIndex((q) => q.id === id);
                      return (
                        <li key={id}>
                          <button
                            type="button"
                            className={styles.summaryLink}
                            onClick={() => {
                              setSelectedId(id);
                              goTab('questions');
                            }}
                          >
                            Question {index + 1}: {list[0].message}
                          </button>
                        </li>
                      );
                    })}
                  </ul>
                )}
              </div>
            </div>
          )}

        {tab === 'questions' && (
          <>
            <section className={styles.details} aria-label="Quiz details">
              <Field label="Quiz title" error={showIssues && form.title.trim().length < 3 ? 'Give the quiz a title of at least 3 characters.' : undefined}>
                <Input
                  id="quiz-title"
                  className={styles.titleInput}
                  value={form.title}
                  onChange={(e) => set('title', e.target.value)}
                  placeholder="Chapter 4 check: Quadratic equations"
                  autoFocus={!quiz}
                />
              </Field>
              <div className={styles.detailsGrid}>
                <Field label="Instructions" optional hint="Shown before learners start.">
                  <Textarea
                    rows={2}
                    value={form.instructions}
                    onChange={(e) => set('instructions', e.target.value)}
                    placeholder="Ten questions on finding and checking roots. Two attempts; your higher score counts."
                  />
                </Field>
                <div className={styles.placement}>
                  <Field label="Course">
                    <Select
                      value={form.courseId}
                      onChange={(e) => setForm((f) => ({ ...f, courseId: e.target.value, chapterId: undefined }))}
                      disabled={Boolean(quiz?.lessonId)}
                    >
                      {courses.map((c) => (
                        <option key={c.id} value={c.id}>
                          {c.title}
                        </option>
                      ))}
                    </Select>
                  </Field>
                  <Field label="Chapter" optional>
                    <Select value={form.chapterId ?? ''} onChange={(e) => set('chapterId', e.target.value || undefined)} disabled={Boolean(quiz?.lessonId)}>
                      <option value="">Whole course</option>
                      {course?.chapters.map((c, i) => (
                        <option key={c.id} value={c.id}>
                          {pad2(i + 1)} · {c.title}
                        </option>
                      ))}
                    </Select>
                  </Field>
                </div>
              </div>
            </section>

            {form.questions.length === 0 ? (
              <div className={styles.emptyQuiz}>
                <StateMessage icon={<ListNumbers size={26} />} title="No questions yet">
                  Start with the question type that fits what you want to check. You can change a question’s type later.
                </StateMessage>
                <div className={styles.starters}>
                  {QUESTION_TYPES.map((t) => (
                    <button key={t.value} type="button" className={styles.starter} onClick={() => addQuestion(t.value)}>
                      <span className={styles.starterIcon}>{t.icon}</span>
                      {t.label}
                    </button>
                  ))}
                </div>
              </div>
            ) : (
              <div className={styles.workspace}>
                {isMobile ? (
                  <div className={styles.picker}>
                    <Button
                      size="sm"
                      variant="secondary"
                      aria-label="Previous question"
                      disabled={selectedIndex <= 0}
                      onClick={() => setSelectedId(form.questions[selectedIndex - 1].id)}
                    >
                      <CaretLeft size={16} />
                    </Button>
                    <Select aria-label="Question" value={selectedId ?? ''} onChange={(e) => setSelectedId(e.target.value)}>
                      {form.questions.map((q, i) => (
                        <option key={q.id} value={q.id}>
                          {i + 1}. {q.prompt.slice(0, 40) || 'Untitled question'}
                          {issuesByQuestion.has(q.id) ? ' — to finish' : ''}
                        </option>
                      ))}
                    </Select>
                    <Button
                      size="sm"
                      variant="secondary"
                      aria-label="Next question"
                      disabled={selectedIndex >= form.questions.length - 1}
                      onClick={() => setSelectedId(form.questions[selectedIndex + 1].id)}
                    >
                      <CaretRight size={16} />
                    </Button>
                    {addMenu('Add')}
                  </div>
                ) : (
                  <nav className={styles.rail} aria-label="Questions">
                    <div className={styles.railHead}>
                      <span className={styles.railTitle}>
                        {plural(form.questions.length, 'question')}
                        <span className={styles.railPoints}>{plural(points, 'point')}</span>
                      </span>
                      {addMenu()}
                    </div>
                    <ol className={styles.questionList}>
                      {form.questions.map((q, i) => {
                        const type = QUESTION_TYPES.find((t) => t.value === q.type)!;
                        const hasIssues = issuesByQuestion.has(q.id);
                        return (
                          <li key={q.id}>
                            <button
                              type="button"
                              className={cx(styles.questionItem, q.id === selectedId && styles.questionSelected)}
                              aria-current={q.id === selectedId ? 'true' : undefined}
                              onClick={() => setSelectedId(q.id)}
                            >
                              <span className={styles.questionNumber}>{i + 1}</span>
                              <span className={styles.questionText}>
                                <span className={styles.questionPrompt}>{q.prompt || 'Untitled question'}</span>
                                <span className={styles.questionMeta}>
                                  {type.icon} {type.label} · {plural(q.points, 'pt')}
                                </span>
                              </span>
                              {hasIssues && (
                                <span className={styles.questionIssue} title="Needs finishing">
                                  <WarningCircle size={16} weight="fill" />
                                  <span className="sr-only">Needs finishing</span>
                                </span>
                              )}
                            </button>
                          </li>
                        );
                      })}
                    </ol>
                  </nav>
                )}
                {selected && (
                  <QuestionEditor
                    key={selected.id}
                    question={selected}
                    number={selectedIndex + 1}
                    count={form.questions.length}
                    issues={issuesByQuestion.get(selected.id) ?? []}
                    showIssues={showIssues}
                    onChange={updateQuestion}
                    onMove={moveQuestion}
                    onDuplicate={duplicateQuestion}
                    onDelete={() => (selected.prompt.trim() ? setRemoving(selected) : deleteQuestion(selected))}
                  />
                )}
              </div>
            )}
          </>
        )}

        {tab === 'settings' && (
          <div className={styles.settings}>
            <FormSection id="scoring" title="Scoring" description="What learners need to pass, and how many tries they get.">
              <div className={styles.threeUp}>
                <Field label="Pass mark" hint={points ? `${Math.ceil((points * form.settings.passMark) / 100)} of ${points} points` : 'Percent of points'}>
                  <Input
                    type="number"
                    inputMode="numeric"
                    min={1}
                    max={100}
                    value={form.settings.passMark}
                    onChange={(e) => set('settings', { ...form.settings, passMark: Number(e.target.value) })}
                  />
                </Field>
                <Field label="Attempts">
                  <Select value={form.settings.attempts} onChange={(e) => set('settings', { ...form.settings, attempts: Number(e.target.value) })}>
                    {[1, 2, 3, 5].map((n) => (
                      <option key={n} value={n}>
                        {plural(n, 'attempt')}
                      </option>
                    ))}
                    <option value={0}>Unlimited</option>
                  </Select>
                </Field>
              </div>
              <Meter value={form.settings.passMark} threshold={form.settings.passMark} showLabel label="Pass mark" valueText={`${form.settings.passMark}%`} />
            </FormSection>
            <FormSection id="timing" title="Time limit" description="A countdown is shown while the quiz is open. Answers are submitted when time runs out.">
              <Switch
                checked={form.settings.timeLimitMin !== undefined}
                onChange={(on) => set('settings', { ...form.settings, timeLimitMin: on ? Math.max(5, form.questions.length * 2) : undefined })}
                label="Limit the time"
                description={
                  form.settings.timeLimitMin
                    ? `${form.settings.timeLimitMin} minutes for ${plural(form.questions.length, 'question')}`
                    : 'Learners can take as long as they need.'
                }
              />
              {form.settings.timeLimitMin !== undefined && (
                <Field label="Minutes" className={styles.minutes}>
                  <Input
                    type="number"
                    inputMode="numeric"
                    min={1}
                    max={240}
                    value={form.settings.timeLimitMin}
                    onChange={(e) => set('settings', { ...form.settings, timeLimitMin: Number(e.target.value) })}
                  />
                </Field>
              )}
            </FormSection>
            <FormSection
              id="availability"
              title="Availability"
              description="Optional. Learners can start the quiz only between these times, in India Standard Time (IST). An attempt still running at the close is handed in with what was saved."
            >
              <div className={styles.windowGrid}>
                <fieldset className={styles.windowEdge}>
                  <legend className={styles.windowLegend}>Opens (IST)</legend>
                  <Field label="Opening date" hideLabel>
                    <Input id="quiz-opens-date" type="date" value={draft.opensDate} onChange={(e) => setWindow({ opensDate: e.target.value })} />
                  </Field>
                  <Field label="Opening time" hideLabel>
                    <Input id="quiz-opens-time" type="time" value={draft.opensTime} onChange={(e) => setWindow({ opensTime: e.target.value })} />
                  </Field>
                  {(draft.opensDate || draft.opensTime) && (
                    <Button size="sm" variant="ghost" onClick={() => setWindow({ opensDate: '', opensTime: '' })}>
                      Clear
                    </Button>
                  )}
                </fieldset>
                <fieldset className={styles.windowEdge}>
                  <legend className={styles.windowLegend}>Closes (IST)</legend>
                  <Field label="Closing date" hideLabel>
                    <Input id="quiz-closes-date" type="date" value={draft.closesDate} onChange={(e) => setWindow({ closesDate: e.target.value })} />
                  </Field>
                  <Field label="Closing time" hideLabel>
                    <Input id="quiz-closes-time" type="time" value={draft.closesTime} onChange={(e) => setWindow({ closesTime: e.target.value })} />
                  </Field>
                  {(draft.closesDate || draft.closesTime) && (
                    <Button size="sm" variant="ghost" onClick={() => setWindow({ closesDate: '', closesTime: '' })}>
                      Clear
                    </Button>
                  )}
                </fieldset>
              </div>
              {(form.settings.opensAt || form.settings.closesAt) && (
                <p className={styles.muted}>
                  {form.settings.opensAt && `Opens ${formatMoment(form.settings.opensAt)}. `}
                  {form.settings.closesAt && `Closes ${formatMoment(form.settings.closesAt)}.`} Learners see these times in IST.
                </p>
              )}
              {showIssues &&
                issues
                  .filter((i) => i.field === 'settings')
                  .map((i) => (
                    <p key={i.message} className={styles.issue} role="alert">
                      <WarningCircle size={15} /> {i.message}
                    </p>
                  ))}
            </FormSection>
            <FormSection id="randomization" title="Randomisation" description="Shuffling makes it harder to share answers between attempts.">
              <Switch
                checked={form.settings.shuffleQuestions}
                onChange={(v) => set('settings', { ...form.settings, shuffleQuestions: v })}
                label="Shuffle questions"
                description="Each attempt shows questions in a different order."
              />
              <Switch
                checked={form.settings.shuffleOptions}
                onChange={(v) => set('settings', { ...form.settings, shuffleOptions: v })}
                label="Shuffle answers"
                description="True / false questions always show True first."
              />
            </FormSection>
            <FormSection id="results" title="Results" description="What learners see once they submit.">
              <ChoiceCards
                legend="After submitting, learners see"
                columns={3}
                value={form.settings.showResults}
                onChange={(v) => set('settings', { ...form.settings, showResults: v })}
                choices={[
                  { value: 'score-and-answers', label: 'Score and answers', description: 'Their score, the correct answers and explanations.' },
                  { value: 'score-only', label: 'Score only', description: 'Pass or fail and their score — answers stay hidden.' },
                  { value: 'hidden', label: 'Nothing yet', description: 'A confirmation; results are released later.' },
                ]}
              />
              <Field
                label="Show results"
                hint={
                  form.settings.resultsRelease === 'after-close'
                    ? form.settings.closesAt
                      ? `Everyone sees their result at the close, ${formatMoment(form.settings.closesAt)}.`
                      : 'Set a closing time under Availability first.'
                    : 'Each learner sees their result as soon as they submit.'
                }
                error={
                  showIssues && form.settings.resultsRelease === 'after-close' && !form.settings.closesAt
                    ? 'Set a closing time to show results once the quiz closes.'
                    : undefined
                }
                className={styles.release}
              >
                <Select
                  id="quiz-results-release"
                  value={form.settings.resultsRelease ?? 'on-submit'}
                  onChange={(e) => {
                    const next: QuizSettings = { ...form.settings, resultsRelease: e.target.value as 'on-submit' | 'after-close' };
                    if (next.resultsRelease === 'on-submit') delete next.resultsRelease;
                    set('settings', next);
                  }}
                >
                  <option value="on-submit">As soon as each learner submits</option>
                  <option value="after-close">When the quiz closes</option>
                </Select>
              </Field>
            </FormSection>
          </div>
        )}

        {tab === 'preview' && (
          <div className={styles.preview}>
            <div className={styles.previewBar}>
              <span>
                <Eye size={16} /> Learner preview{dirty ? ' with unsaved changes' : ''} — attempts aren’t recorded
              </span>
              <span className={styles.previewControls}>
                <Switch checked={reveal} onChange={setReveal} label="Check answers as I go" />
                <Button size="sm" onClick={() => setPreviewKey((k) => k + 1)}>
                  Restart
                </Button>
              </span>
            </div>
            <div className={styles.previewFrame}>
              <QuizTaker key={`${previewKey}-${reveal}`} quiz={form} revealAsYouGo={reveal} context={course?.title} />
            </div>
          </div>
        )}

        {tab === 'results' && quiz && <Results quiz={quiz} questions={form.questions} />}
      </div>

      {isMobile && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{actions}</div>}>
          <span />
        </StickyActionBar>
      )}

      <Modal
        open={Boolean(removing)}
        onClose={() => setRemoving(null)}
        title="Remove this question?"
        description={removing?.prompt}
        footer={
          <>
            <Button onClick={() => setRemoving(null)}>Keep it</Button>
            <Button variant="danger" onClick={() => removing && deleteQuestion(removing)}>
              Remove question
            </Button>
          </>
        }
      >
        <p className={styles.muted}>You can undo from the notification, until you leave the builder. The change is saved with the quiz.</p>
      </Modal>

      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave without saving?"
        description={`Your changes to ${form.title.trim() || 'this quiz'} haven’t been saved.`}
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

/* ─── Results preview ──────────────────────────────────────────────────── */

function Results({ quiz, questions }: { quiz: Quiz; questions: QuizQuestion[] }) {
  const stats = useAsync(`quiz-stats:${quiz.id}:${quiz.updatedAt}`, () => services.quizzes.stats(quiz.id));
  const attempts = useAsync(`quiz-attempts:${quiz.id}`, () => services.quizzes.attempts(quiz.id));
  const list = <AttemptList quiz={quiz} query={attempts} />;
  if (stats.status === 'error' && !stats.data) {
    return (
      <InlineMessage
        kind="error"
        title="Results didn’t load."
        action={
          <Button size="sm" onClick={() => stats.run().catch(() => undefined)}>
            Try again
          </Button>
        }
      >
        {stats.error.message}
      </InlineMessage>
    );
  }
  if (!stats.data) return <Skeleton height={320} radius="var(--r-lg)" />;
  const s = stats.data;
  if (s.attempts === 0) {
    return (
      <div className={styles.results}>
        {!attempts.data?.length && (
          <StateMessage icon={<ChartBar size={26} />} title="No attempts yet">
            {quiz.status === 'draft'
              ? 'Results appear once the quiz is published and learners take it.'
              : 'Results appear as soon as the first learner submits.'}
          </StateMessage>
        )}
        {attempts.data?.length ? list : null}
      </div>
    );
  }
  const passIndex = Math.floor(quiz.settings.passMark / 10);
  const rows = questions
    .map((q, i) => ({ q, i, stat: s.questions.find((x) => x.questionId === q.id) }))
    .filter((r) => r.stat)
    .sort((a, b) => a.stat!.correctRate - b.stat!.correctRate);

  return (
    <div className={styles.results}>
      <dl className={styles.resultFigures}>
        <Figure label="attempts" value={formatCount(s.attempts)} />
        <Figure label="learners" value={formatCount(s.learners)} />
        <Figure label="passed" value={`${s.passRate}%`} />
        <Figure label="average score" value={`${s.avgScore}%`} />
        <Figure label="median time" value={`${s.medianMinutes} min`} />
      </dl>
      <section className={styles.panel} aria-labelledby="distribution-title">
        <SectionHeader id="distribution-title" title="Score distribution" description={`Attempts by score band. Bands from ${passIndex * 10}% pass.`} />
        <ColumnChart
          data={s.distribution.map((d) => ({ label: d.label.split('–')[0], detail: d.label, value: d.value }))}
          label="Attempts by score band"
          unit="attempts"
          height={200}
        />
      </section>
      <section className={styles.panel} aria-labelledby="difficulty-title">
        <SectionHeader
          id="difficulty-title"
          title="Question difficulty"
          description="Hardest first. A low rate can mean a hard idea — or an ambiguous question."
        />
        <ol className={styles.difficulty}>
          {rows.map(({ q, i, stat }) => {
            const wrong = q.options.find((o) => o.id === stat!.commonWrongOptionId);
            return (
              <li key={q.id} className={styles.difficultyItem}>
                <span className={styles.questionNumber}>{i + 1}</span>
                <span className={styles.difficultyText}>
                  <span className={styles.questionPrompt}>{q.prompt}</span>
                  {wrong && stat!.correctRate < 75 && <span className={styles.questionMeta}>Most chosen wrong answer: “{wrong.text}”</span>}
                </span>
                <span className={styles.difficultyRate}>
                  <Meter
                    value={stat!.correctRate}
                    size="sm"
                    tone={stat!.correctRate < 55 ? 'danger' : stat!.correctRate < 70 ? 'warn' : 'accent'}
                    label={`Question ${i + 1}: ${stat!.correctRate}% correct`}
                  />
                  <span className="tabular">{stat!.correctRate}%</span>
                </span>
              </li>
            );
          })}
        </ol>
        <p className={styles.muted}>
          <ArrowRight size={13} /> Figures are for the published version of the quiz and update as learners submit.
        </p>
      </section>
      {list}
    </div>
  );
}

/** Every attempt, newest first: who, which attempt, how it stands, the score and the time it took — the server's clock. */
function AttemptList({ quiz, query }: { quiz: Quiz; query: ReturnType<typeof useAsync<QuizAttemptRow[]>> }) {
  const columns: Column<QuizAttemptRow>[] = [
    {
      key: 'learner',
      header: 'Learner',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.quizCell}>
          <span className={styles.quizTitle}>{r.name}</span>
          <span className={styles.quizMeta}>{r.email}</span>
        </span>
      ),
    },
    { key: 'attempt', header: 'Attempt', width: '88px', mobile: 'meta', render: (r) => <span className="tabular">#{r.attemptNo}</span> },
    {
      key: 'status',
      header: 'Status',
      width: '120px',
      mobile: 'status',
      render: (r) => (
        <Badge size="sm" tone={r.status === 'active' ? 'info' : r.status === 'expired' ? 'warn' : 'neutral'}>
          {ATTEMPT_STATUS_LABEL[r.status]}
        </Badge>
      ),
    },
    {
      key: 'score',
      header: 'Score',
      width: '120px',
      align: 'end',
      mobile: 'detail',
      render: (r) =>
        r.percent === undefined ? (
          <span className={styles.muted}>—</span>
        ) : (
          <span className={styles.nowrap}>
            <span className="tabular">{r.percent}%</span> · {r.passed ? 'Passed' : 'Not passed'}
          </span>
        ),
    },
    { key: 'taken', header: 'Time taken', width: '120px', mobile: 'detail', render: (r) => <span className="tabular">{formatTaken(r.durationSec)}</span> },
    {
      key: 'submitted',
      header: 'Submitted',
      width: '190px',
      mobile: 'detail',
      render: (r) =>
        r.status === 'active' ? (
          <span className={styles.muted}>{r.deadlineAt ? `Time runs out ${formatMoment(r.deadlineAt)}` : 'Under way'}</span>
        ) : r.submittedAt ? (
          <time dateTime={r.submittedAt}>{formatMoment(r.submittedAt)}</time>
        ) : (
          '—'
        ),
    },
  ];
  return (
    <section className={styles.panel} aria-labelledby="attempts-title">
      <SectionHeader
        id="attempts-title"
        title="Attempts"
        description={`Every attempt at ${quiz.title}, newest first. Scores are shown here whatever learners are shown.`}
      />
      {query.status === 'error' && !query.data ? (
        <InlineMessage
          kind="error"
          title="Attempts didn’t load."
          action={
            <Button size="sm" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </InlineMessage>
      ) : query.data && query.data.length === 0 ? (
        <p className={styles.muted}>No learner has started this quiz yet.</p>
      ) : (
        <DataTable
          label="Attempts"
          rows={query.data ?? []}
          columns={columns}
          rowKey={(r) => r.sessionId ?? r.attemptId ?? `${r.studentId}-${r.attemptNo}`}
          rowLabel={(r) => `${r.name}, attempt ${r.attemptNo}`}
          loading={!query.data}
          skeletonRows={4}
        />
      )}
    </section>
  );
}
