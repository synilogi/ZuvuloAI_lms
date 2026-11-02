import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useBlocker, useLocation, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import {
  ArrowLeft,
  CheckCircle,
  DesktopTower,
  DeviceMobile,
  Eye,
  FloppyDisk,
  GearSix,
  PencilSimpleLine,
  RocketLaunch,
  Trash,
  WarningCircle,
} from '@phosphor-icons/react';
import type { CompletionRule, Course, Lesson, LessonInput, LessonType } from '@syniastrolms/domain';
import { defaultCompletion, lessonPublishIssues } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { cx } from '@/lib/cx';
import { formatRelative, pad2 } from '@/lib/format';
import { ChoiceCards, ErrorSummary, FormSection, ListInput, Switch, type FieldIssue } from '@/components/forms/Forms';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { lessonTypeMeta } from '@/components/lms/course/CourseIdentity';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type LessonDetail } from '@/services';
import { ContentEditor } from './ContentEditors';
import { LessonPreview } from './LessonPreview';
import styles from './LessonEditor.module.css';

type Tab = 'content' | 'settings' | 'preview';

const TYPES: { value: LessonType; hint: string }[] = [
  { value: 'video', hint: 'Recorded teaching' },
  { value: 'reading', hint: 'Written lesson' },
  { value: 'document', hint: 'Worksheet or reading pack' },
  { value: 'assessment', hint: 'Checks understanding' },
  { value: 'assignment', hint: 'Reviewed submission' },
  { value: 'live', hint: 'Scheduled class' },
  { value: 'practice', hint: 'Guided exercise' },
];

const COMPLETION: Record<CompletionRule, { label: string; description: string }> = {
  opened: { label: 'Opened', description: 'Complete as soon as the learner opens it.' },
  watched: { label: 'Watched to the end', description: 'Complete after 90% of the video is watched.' },
  submitted: { label: 'Submitted', description: 'Complete when work is submitted, before it is reviewed.' },
  passed: { label: 'Passed', description: 'Complete only when the learner reaches the pass mark.' },
};
const RULES_BY_TYPE: Record<LessonType, CompletionRule[]> = {
  video: ['watched', 'opened'],
  reading: ['opened'],
  document: ['opened'],
  live: ['opened'],
  practice: ['submitted', 'opened'],
  assignment: ['submitted', 'passed'],
  assessment: ['passed', 'submitted'],
};

export default function LessonEditorPage() {
  const { courseId, lessonId } = useParams();
  const { base, instructorId } = useWorkspace();
  const [params] = useSearchParams();

  const query = useAsync(`lesson-editor:${courseId}:${lessonId ?? 'new'}`, () =>
    Promise.all([services.courses.get(courseId!, instructorId), lessonId ? services.lessons.get(courseId!, lessonId) : Promise.resolve(null)]).then(
      ([course, detail]) => ({
        course,
        detail,
      }),
    ),
  );

  const courseTo = `${base}/courses/${courseId}`;
  usePageCrumbs(
    query.data
      ? [
          { label: query.data.course.title, to: courseTo },
          { label: 'Lessons', to: `${courseTo}/lessons` },
          { label: query.data.detail ? `Lesson ${query.data.detail.chapterIndex + 1}.${query.data.detail.lessonIndex + 1}` : 'New lesson' },
        ]
      : [{ label: 'Lesson' }],
  );

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <StateMessage
        kind="error"
        title={notFound ? 'Lesson not found' : 'The lesson editor didn’t load'}
        actions={
          notFound ? (
            <LinkButton to={`${courseTo}/lessons`} iconStart={<ArrowLeft size={16} />}>
              Back to lessons
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
      <div className={styles.page} role="status" aria-label="Loading lesson">
        <Skeleton width={120} height={12} />
        <Skeleton width="50%" height={30} radius="var(--r-xs)" />
        <div className={styles.contentGrid}>
          <Skeleton height={380} radius="var(--r-lg)" />
          <Skeleton height={260} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }

  return (
    <Editor
      key={query.data.detail?.lesson.id ?? 'new'}
      course={query.data.course}
      detail={query.data.detail}
      base={base}
      chapterParam={params.get('chapter')}
    />
  );
}

interface EditorProps {
  course: Course;
  detail: LessonDetail | null;
  base: string;
  chapterParam: string | null;
}

function blankLesson(): LessonInput {
  return {
    title: '',
    type: 'video',
    durationMin: 15,
    isPreview: false,
    status: 'draft',
    description: '',
    objectives: [],
    content: {},
    settings: { completion: 'watched', sequential: false, discussion: true, resourcesDownloadable: false },
  };
}

function toInput(lesson: Lesson): LessonInput {
  const { title, type, durationMin, isPreview, status, description, objectives, content, settings } = lesson;
  return {
    title,
    type,
    durationMin,
    isPreview: Boolean(isPreview),
    status,
    description: description ?? '',
    objectives: objectives ?? [],
    content: content ?? {},
    settings,
  };
}

function Editor({ course, detail, base, chapterParam }: EditorProps) {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const courseTo = `${base}/courses/${course.id}`;
  const lessonTo = detail ? `${courseTo}/lessons/${detail.lesson.id}` : null;

  const initialChapter = detail?.chapterId ?? (course.chapters.find((c) => c.id === chapterParam) ?? course.chapters[course.chapters.length - 1])?.id ?? '';
  const initialPlacement = {
    chapterId: initialChapter,
    position: detail ? detail.lessonIndex + 1 : (course.chapters.find((c) => c.id === initialChapter)?.lessons.length ?? 0) + 1,
  };
  const [baseline, setBaseline] = useState(() => ({ form: detail ? toInput(detail.lesson) : blankLesson(), placement: initialPlacement }));
  const [form, setForm] = useState(baseline.form);
  const [placement, setPlacement] = useState(baseline.placement);
  const [localTab, setLocalTab] = useState<Tab>('content');
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState<null | 'save' | 'publish'>(null);
  const [error, setError] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState<string | null>(detail?.lesson.updatedAt ?? null);
  const [device, setDevice] = useState<'desktop' | 'mobile'>('desktop');
  const [deleting, setDeleting] = useState(false);
  const leaving = useRef(false);

  const tab: Tab = lessonTo ? (pathname.endsWith('/settings') ? 'settings' : pathname.endsWith('/preview') ? 'preview' : 'content') : localTab;
  const goTab = (next: Tab) => {
    if (lessonTo) navigate(next === 'content' ? lessonTo : `${lessonTo}/${next}`, { replace: true });
    else setLocalTab(next);
  };

  const dirty = JSON.stringify({ form, placement }) !== JSON.stringify(baseline);
  const set = <K extends keyof LessonInput>(key: K, value: LessonInput[K]) => setForm((f) => ({ ...f, [key]: value }));

  const blocker = useBlocker(
    ({ currentLocation, nextLocation }) =>
      dirty && !leaving.current && !nextLocation.pathname.startsWith(lessonTo ?? '__none') && currentLocation.pathname !== nextLocation.pathname,
  );
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const validate = (input: LessonInput): FieldIssue[] => {
    const issues: FieldIssue[] = [];
    const title = input.title.trim();
    if (!title) issues.push({ field: 'lesson-title', message: 'Give the lesson a title.' });
    else if (title.length < 3) issues.push({ field: 'lesson-title', message: 'The title needs at least 3 characters.' });
    else if (title.length > 120) issues.push({ field: 'lesson-title', message: 'Keep the title under 120 characters.' });
    if (!Number.isInteger(input.durationMin) || input.durationMin < 1 || input.durationMin > 600)
      issues.push({ field: 'lesson-duration', message: 'Duration must be between 1 and 600 minutes.' });
    if (!placement.chapterId) issues.push({ field: 'lesson-chapter', message: 'Choose a chapter for the lesson.' });
    if (input.status === 'published') for (const issue of lessonPublishIssues(input)) if (!issues.some((i) => i.field === issue.field)) issues.push(issue);
    return issues;
  };
  const issues = attempt ? validate(form) : [];
  const errorFor = (field: string) => issues.find((i) => i.field === field)?.message;
  const publishIssues = lessonPublishIssues(form);

  const save = async (mode: 'save' | 'publish') => {
    const input: LessonInput = {
      ...form,
      status: mode === 'publish' ? 'published' : form.status,
      objectives: (form.objectives ?? []).map((o) => o.trim()).filter(Boolean),
    };
    setAttempt((a) => a + 1);
    setError(null);
    if (validate(input).length) {
      if (mode === 'publish') setForm((f) => ({ ...f, status: 'published' }));
      goTab('content');
      return;
    }
    setSaving(mode);
    try {
      if (!detail) {
        const created = await services.lessons.create(course.id, placement.chapterId, input, placement.position);
        leaving.current = true;
        toast({ kind: 'success', title: mode === 'publish' ? 'Lesson published' : 'Lesson saved as a draft', text: created.title });
        navigate(`${courseTo}/lessons/${created.id}`, { replace: true });
        return;
      }
      await services.lessons.update(course.id, detail.lesson.id, input);
      if (placement.chapterId !== baseline.placement.chapterId || placement.position !== baseline.placement.position) {
        await services.lessons.move(course.id, detail.lesson.id, placement.chapterId, placement.position);
      }
      setForm(input);
      setBaseline({ form: input, placement });
      setSavedAt(new Date(now.getTime()).toISOString());
      setAttempt(0);
      toast({ kind: 'success', title: mode === 'publish' ? 'Lesson published' : 'Changes saved', text: input.title });
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(null);
    }
  };

  const chapterIndex = course.chapters.findIndex((c) => c.id === placement.chapterId);
  const chapter = course.chapters[chapterIndex];
  const lessonCount = (chapter?.lessons.length ?? 0) + (detail && detail.chapterId === placement.chapterId ? 0 : 1);
  const stateLine = saving ? 'Saving…' : dirty ? 'Unsaved changes' : savedAt ? `Saved ${formatRelative(savedAt, now)}` : 'Not saved yet';

  const actions = (
    <>
      <Button iconStart={<FloppyDisk size={16} />} loading={saving === 'save'} disabled={Boolean(saving)} onClick={() => save('save')}>
        {form.status === 'published' ? 'Save' : 'Save draft'}
      </Button>
      {(!detail || detail.lesson.status === 'draft') && (
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

  const placementPositions = useMemo(() => {
    const target = course.chapters.find((c) => c.id === placement.chapterId);
    const others = (target?.lessons ?? []).filter((l) => l.id !== detail?.lesson.id);
    return Array.from({ length: others.length + 1 }, (_, i) => ({ value: i + 1, label: i === 0 ? 'First in the chapter' : `After “${others[i - 1].title}”` }));
  }, [course.chapters, placement.chapterId, detail?.lesson.id]);

  return (
    <div className={styles.page}>
      <header className={styles.top}>
        <Link to={`${courseTo}/lessons`} className={styles.back}>
          <ArrowLeft size={14} aria-hidden="true" /> Lessons in {course.title}
        </Link>
        <div className={styles.topRow}>
          <div className={styles.topText}>
            <span className={styles.context}>
              {chapter ? `Chapter ${pad2(chapterIndex + 1)} · ${chapter.title}` : 'Choose a chapter'}
              {detail && detail.chapterId === placement.chapterId && ` · Lesson ${detail.chapterIndex + 1}.${detail.lessonIndex + 1}`}
            </span>
            <h1 className={styles.heading}>{form.title.trim() || (detail ? 'Untitled lesson' : 'New lesson')}</h1>
            <div className={styles.topMeta}>
              <span className={styles.typeTag}>
                {lessonTypeMeta[form.type].icon}
                {lessonTypeMeta[form.type].label}
              </span>
              {form.status === 'published' && detail?.lesson.status === 'published' ? (
                <Badge tone="accent" dot>
                  Published
                </Badge>
              ) : (
                <Badge tone="warn">Draft</Badge>
              )}
              {form.isPreview && <Badge tone="info">Free preview</Badge>}
              <span className={cx(styles.saveState, dirty && styles.saveStateDirty)} role="status">
                {dirty ? <PencilSimpleLine size={14} /> : <CheckCircle size={14} />}
                {stateLine}
              </span>
            </div>
          </div>
          {!isMobile && <div className={styles.topActions}>{actions}</div>}
        </div>
        <SegmentedControl<Tab>
          label="Lesson editor sections"
          semantics="tabs"
          idPrefix="lesson"
          value={tab}
          onChange={goTab}
          segments={[
            { value: 'content', label: 'Content', icon: <PencilSimpleLine size={15} /> },
            { value: 'settings', label: 'Settings', icon: <GearSix size={15} /> },
            { value: 'preview', label: 'Preview', icon: <Eye size={15} /> },
          ]}
        />
      </header>

      <div id="lesson-panel" role="tabpanel" aria-labelledby={`lesson-tab-${tab}`} className={styles.panelArea}>
        {(issues.length > 0 || error) && tab !== 'preview' && (
          <div className={styles.messages}>
            <ErrorSummary
              issues={issues}
              attempt={attempt}
              title={form.status === 'published' ? 'Finish these before publishing' : 'Fix these before saving'}
            />
            {error && (
              <InlineMessage kind="error" title="Couldn’t save.">
                {error}
              </InlineMessage>
            )}
          </div>
        )}

        {tab === 'content' && (
          <div className={styles.contentGrid}>
            <div className={styles.main}>
              <section className={styles.panel} aria-label="Lesson">
                <Field label="Lesson title" error={errorFor('lesson-title')}>
                  <Input
                    id="lesson-title"
                    className={styles.titleInput}
                    value={form.title}
                    onChange={(e) => set('title', e.target.value)}
                    placeholder="Mars in the tenth house"
                    autoFocus={!detail}
                  />
                </Field>
                <fieldset className={styles.types}>
                  <legend className={styles.legend}>Lesson type</legend>
                  <div className={styles.typeGrid}>
                    {TYPES.map((t) => (
                      <label key={t.value} className={cx(styles.typeOption, form.type === t.value && styles.typeSelected)}>
                        <input
                          type="radio"
                          name="lesson-type"
                          className={styles.typeInput}
                          checked={form.type === t.value}
                          onChange={() =>
                            setForm((f) => ({
                              ...f,
                              type: t.value,
                              settings: { ...(f.settings ?? blankLesson().settings!), completion: defaultCompletion[t.value] },
                            }))
                          }
                        />
                        <span className={styles.typeIcon}>{lessonTypeMeta[t.value].icon}</span>
                        <span className={styles.typeLabel}>{lessonTypeMeta[t.value].label}</span>
                        <span className={styles.typeHint}>{t.hint}</span>
                      </label>
                    ))}
                  </div>
                  {detail && form.type !== detail.lesson.type && (
                    <p className={styles.typeNote}>
                      <WarningCircle size={15} /> Content you added for {lessonTypeMeta[detail.lesson.type].label.toLowerCase()} is kept if you switch back.
                    </p>
                  )}
                </fieldset>
              </section>

              <section className={styles.panel} aria-labelledby="content-title">
                <h2 id="content-title" className={styles.panelTitle}>
                  {lessonTypeMeta[form.type].icon}{' '}
                  {form.type === 'reading' ? 'Article' : form.type === 'practice' ? 'Exercise' : lessonTypeMeta[form.type].label}
                </h2>
                <ContentEditor
                  type={form.type}
                  content={form.content ?? {}}
                  onChange={(content) => set('content', content)}
                  errorFor={errorFor}
                  onUseDuration={(minutes) => set('durationMin', minutes)}
                  base={base}
                  title={form.title}
                />
              </section>
            </div>

            <aside className={styles.side}>
              <section className={styles.panel} aria-labelledby="details-title">
                <h2 id="details-title" className={styles.panelTitle}>
                  Details
                </h2>
                <Field label="Description" optional hint="A sentence or two shown under the title.">
                  <Textarea rows={3} value={form.description} onChange={(e) => set('description', e.target.value)} />
                </Field>
                <Field label="Duration" error={errorFor('lesson-duration')} hint="Minutes a learner should set aside">
                  <Input
                    id="lesson-duration"
                    type="number"
                    inputMode="numeric"
                    min={1}
                    max={600}
                    value={form.durationMin}
                    onChange={(e) => set('durationMin', Number(e.target.value))}
                  />
                </Field>
                <ListInput
                  label="Objective"
                  value={form.objectives ?? []}
                  onChange={(v) => set('objectives', v)}
                  addLabel="Add objective"
                  max={5}
                  placeholder="Name the lord of each house"
                  hint="What the learner will be able to do."
                />
                <Switch
                  checked={Boolean(form.isPreview)}
                  onChange={(v) => set('isPreview', v)}
                  label="Free preview"
                  description="Visitors can open this lesson before enrolling."
                />
              </section>

              <section className={styles.panel} aria-labelledby="visibility-title">
                <h2 id="visibility-title" className={styles.panelTitle}>
                  Visibility
                </h2>
                <ChoiceCards
                  legend="Status"
                  hideLegend
                  columns={1}
                  value={form.status}
                  onChange={(v) => set('status', v)}
                  choices={[
                    { value: 'published', label: 'Published', description: 'Enrolled learners can open it.' },
                    { value: 'draft', label: 'Draft', description: 'Hidden while you work on it.' },
                  ]}
                />
                {publishIssues.length > 0 ? (
                  <ul className={styles.readiness} aria-label="Before publishing">
                    {publishIssues.map((i) => (
                      <li key={i.field}>
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
        )}

        {tab === 'settings' && (
          <div className={styles.settings}>
            <FormSection id="completion" title="Completion" description="How this lesson counts towards course progress and certificates.">
              <ChoiceCards
                legend="The lesson is complete when"
                columns={2}
                value={form.settings?.completion ?? defaultCompletion[form.type]}
                onChange={(completion) => set('settings', { ...(form.settings ?? blankLesson().settings!), completion })}
                choices={RULES_BY_TYPE[form.type].map((rule) => ({ value: rule, ...COMPLETION[rule] }))}
              />
            </FormSection>
            <FormSection id="access" title="Access" description="What learners need before and alongside this lesson.">
              <Switch
                checked={Boolean(form.settings?.sequential)}
                onChange={(sequential) => set('settings', { ...(form.settings ?? blankLesson().settings!), sequential })}
                label="Require the previous lesson"
                description="The lesson stays locked until the one before it is complete."
              />
              <Switch
                checked={Boolean(form.settings?.discussion)}
                onChange={(discussion) => set('settings', { ...(form.settings ?? blankLesson().settings!), discussion })}
                label="Discussion"
                description="Learners can ask questions under the lesson; instructors are notified."
              />
              <Switch
                checked={Boolean(form.settings?.resourcesDownloadable)}
                onChange={(resourcesDownloadable) => set('settings', { ...(form.settings ?? blankLesson().settings!), resourcesDownloadable })}
                label="Downloadable resources"
                description="Students can save attachments — notes, worksheets, PDFs — to study offline."
              />
            </FormSection>
            <FormSection id="placement" title="Placement" description="Where the lesson sits in the curriculum.">
              <Field label="Chapter" error={errorFor('lesson-chapter')}>
                <Select
                  id="lesson-chapter"
                  value={placement.chapterId}
                  onChange={(e) => {
                    const target = course.chapters.find((c) => c.id === e.target.value);
                    const same = e.target.value === detail?.chapterId;
                    setPlacement({ chapterId: e.target.value, position: same && detail ? detail.lessonIndex + 1 : (target?.lessons.length ?? 0) + 1 });
                  }}
                >
                  {course.chapters.map((c, i) => (
                    <option key={c.id} value={c.id}>
                      {pad2(i + 1)} · {c.title}
                      {c.status === 'draft' ? ' (draft)' : ''}
                    </option>
                  ))}
                </Select>
              </Field>
              <Field label="Position">
                <Select value={placement.position} onChange={(e) => setPlacement((p) => ({ ...p, position: Number(e.target.value) }))}>
                  {placementPositions.map((p) => (
                    <option key={p.value} value={p.value}>
                      {p.label}
                    </option>
                  ))}
                </Select>
              </Field>
            </FormSection>
            {detail && (
              <FormSection id="danger" title="Delete lesson" description="Removes the lesson, its content and any progress learners recorded on it.">
                <div>
                  <Button variant="danger" iconStart={<Trash size={16} />} onClick={() => setDeleting(true)}>
                    Delete this lesson
                  </Button>
                </div>
              </FormSection>
            )}
          </div>
        )}

        {tab === 'preview' && (
          <div className={styles.previewArea}>
            <div className={styles.previewBar}>
              <span>
                <Eye size={16} /> How learners see this lesson{dirty ? ', including unsaved changes' : ''}
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
              <LessonPreview
                lesson={{ ...(detail?.lesson ?? ({ id: 'new', updatedAt: '' } as Lesson)), ...form }}
                courseTitle={course.title}
                chapterTitle={chapter?.title ?? ''}
                chapterIndex={Math.max(0, chapterIndex)}
                lessonIndex={placement.position - 1}
                lessonCount={Math.max(lessonCount, placement.position)}
                previous={detail?.previous?.title}
                next={detail?.next?.title}
              />
            </div>
          </div>
        )}
      </div>

      {isMobile && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{actions}</div>}>
          <span />
        </StickyActionBar>
      )}

      {deleting && detail && (
        <ConfirmDialog
          open
          onClose={() => setDeleting(false)}
          onConfirm={async () => {
            await services.lessons.remove(course.id, detail.lesson.id);
            leaving.current = true;
            toast({ kind: 'success', title: 'Lesson deleted', text: detail.lesson.title });
            navigate(`${courseTo}/lessons`);
          }}
          tone="danger"
          icon={<Trash size={20} />}
          title="Delete this lesson?"
          description={detail.lesson.title}
          confirmLabel="Delete lesson"
          acknowledge={detail.lesson.status === 'published' && course.enrolledCount > 0 ? 'I understand learners lose progress on this lesson' : undefined}
        >
          <p className={styles.blockHint}>Its content, objectives and settings are removed, and lessons after it move up. This can’t be undone.</p>
        </ConfirmDialog>
      )}

      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave without saving?"
        description={`Your changes to ${form.title.trim() || 'this lesson'} haven’t been saved.`}
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
