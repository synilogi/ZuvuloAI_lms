import { useEffect, useMemo, useRef, useState, type FormEvent } from 'react';
import { useBlocker, useNavigate, useParams } from 'react-router-dom';
import {
  ArrowRight,
  ArrowsClockwise,
  CaretDown,
  CheckCircle,
  Circle,
  FloppyDisk,
  CurrencyInr,
  Gift,
  Image as ImageIcon,
  ListNumbers,
  PencilSimpleLine,
  RocketLaunch,
  Timer,
  Trash,
  UsersThree,
  VideoCamera,
} from '@phosphor-icons/react';
import type { Category, Course, CourseFormat, CoverMotif, Instructor, Level } from '@syniastrolms/domain';
import { hasPublishedLessons, publishChecklist, slugify } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { cx } from '@/lib/cx';
import { plural } from '@/lib/format';
import { ChoiceCards, ErrorSummary, FormSection, ListInput, Switch, TagInput, type FieldIssue } from '@/components/forms/Forms';
import { MediaDrop } from '@/components/forms/Upload';
import { PageHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { CourseStatusBadge, visibilityMeta } from '@/components/lms/course/CourseStatus';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { ADVANCED_FIELDS, SUBTITLE_MAX, TITLE_MAX, payloadOf, toForm, validate, type FormState, type Intent } from './courseForm';
import { UNSET_WARNING, pricingSummary } from '@/lib/coursePricing';
import styles from './CourseEditor.module.css';

const MOTIFS: { value: CoverMotif; label: string }[] = [
  { value: 'houses', label: 'Grid' },
  { value: 'nakshatra', label: 'Star ring' },
  { value: 'orbits', label: 'Orbits' },
  { value: 'ecliptic', label: 'Arc' },
];

const FORMATS: { value: CourseFormat; label: string; description: string; icon: JSX.Element }[] = [
  { value: 'self-paced', label: 'Self-paced', description: 'Learners start any time and move at their own speed.', icon: <Timer size={18} /> },
  { value: 'cohort', label: 'Cohort', description: 'A group starts together on a schedule with live classes.', icon: <UsersThree size={18} /> },
  { value: 'hybrid', label: 'Hybrid', description: 'Self-paced lessons with optional live sessions.', icon: <VideoCamera size={18} /> },
];

const FORMAT_LABEL: Record<CourseFormat, string> = { 'self-paced': 'Self-paced', cohort: 'Cohort', hybrid: 'Hybrid' };

const SECTIONS = [
  { id: 'basics', label: 'Basic details' },
  { id: 'content', label: 'Course content' },
  { id: 'more', label: 'Additional settings' },
];

/** The publishing checklist's items, and the field each one sends the person to. */
const CHECK_FIELD: Record<string, string> = { title: 'course-title', description: 'course-description', instructor: 'course-instructors' };

const errorFor = (issues: FieldIssue[], field: string) => issues.find((i) => i.field === field)?.message;

/** Scrolls a field into view and focuses it — the checklist's and the error summary's links. */
function focusField(id: string) {
  const el = document.getElementById(id);
  el?.scrollIntoView({ block: 'center', behavior: 'smooth' });
  el?.focus({ preventScroll: true });
}

export default function CourseEditorPage() {
  const { courseId } = useParams();
  const isNew = !courseId;
  const { base, instructorId } = useWorkspace();

  const query = useAsync(`course-editor:${courseId ?? 'new'}`, () =>
    Promise.all([
      courseId ? services.courses.get(courseId, instructorId) : Promise.resolve(null),
      services.catalog.listCategories(),
      services.catalog.listLevels(),
      services.catalog.listInstructors(),
      services.catalog.listCourses(),
    ]).then(([course, categories, levels, instructors, all]) => ({
      course,
      categories,
      levels,
      instructors,
      tags: [...new Set(all.flatMap((c) => c.tags))].sort(),
    })),
  );

  usePageCrumbs(
    isNew
      ? [{ label: 'New course' }]
      : query.data?.course
        ? [{ label: query.data.course.title, to: `${base}/courses/${courseId}` }, { label: 'Edit' }]
        : [{ label: 'Edit' }],
  );

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'Course not found' : 'The editor didn’t load'}
          actions={
            notFound ? undefined : (
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

  if (!query.data) return <EditorSkeleton />;
  return <Editor key={query.data.course?.updatedAt ?? 'new'} {...query.data} base={base} instructorId={instructorId} />;
}

interface EditorProps {
  course: Course | null;
  categories: Category[];
  levels: Level[];
  instructors: Instructor[];
  tags: string[];
  base: string;
  instructorId?: string;
}

function Editor({ course, categories, levels, instructors, tags, base, instructorId }: EditorProps) {
  const navigate = useNavigate();
  const toast = useToast();
  const { can } = usePermissions();
  const { isMobile } = useViewport();
  const [baseline, setBaseline] = useState(() => toForm(course, { levelId: levels[0]?.id ?? '', instructorId }));
  const [form, setForm] = useState(baseline);
  const [attempt, setAttempt] = useState(0);
  const [intent, setIntent] = useState<Intent>('draft');
  const [saving, setSaving] = useState<Intent | null>(null);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [moreOpen, setMoreOpen] = useState(false);
  // Where the chosen cover image is shown from: the saved cover's address, or a fresh upload's.
  const [coverPreview, setCoverPreview] = useState<string | undefined>(course?.coverImageUrl);
  const leaving = useRef(false);

  // A live course is held to the publishing rules on every save, so an edit can't strip what it needs.
  const isLive = course?.status === 'published';
  // Publish is offered on a new course or a draft, to an account that may publish (the API checks again).
  const offersPublish = (!course || course.status === 'draft') && can('catalog.publish');
  const rulesFor = (wanted: Intent): Intent => (isLive ? 'publish' : wanted);
  // Prices are the academy admin's: the teaching workspace shows a course's pricing but never sends it.
  const canPrice = base === '/admin' && !instructorId;

  const dirty = JSON.stringify(form) !== JSON.stringify(baseline);
  const issues = attempt > 0 ? validate(form, rulesFor(intent), { canPrice }) : [];
  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => setForm((f) => ({ ...f, [key]: value }));
  const panelOpen = moreOpen || issues.some((i) => ADVANCED_FIELDS.has(i.field));

  const blocker = useBlocker(({ currentLocation, nextLocation }) => dirty && !leaving.current && currentLocation.pathname !== nextLocation.pathname);

  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const draftCourse = useMemo<Course>(
    () => ({
      ...(course ?? { id: 'new', slug: '', chapters: [], enrolledCount: 0, status: 'draft', createdAt: '', updatedAt: '' }),
      ...form,
      coverImageId: form.coverImageId ?? undefined,
      coverImageUrl: form.coverImageId ? coverPreview : undefined,
      certificateTitle: form.awardsCertificate ? form.certificateTitle : undefined,
      salePrice: form.saleText.trim() ? Number(form.saleText.replace(/,/g, '')) : undefined,
    }),
    [course, form, coverPreview],
  );
  const checks = publishChecklist(draftCourse);
  const met = checks.filter((c) => c.met).length;
  const lessons = course?.chapters.reduce((n, c) => n + c.lessons.length, 0) ?? 0;

  const activeInstructors = instructors.filter((i) => i.status !== 'inactive' || form.instructorIds.includes(i.id));
  // Left blank, a new course lands in the academy's first active category (the API's default).
  const defaultCategory = categories.find((c) => c.status === 'active') ?? categories[0];

  const submit = async (wanted: Intent, e?: FormEvent) => {
    e?.preventDefault();
    setIntent(wanted);
    setAttempt((a) => a + 1);
    setSaveError(null);
    const found = validate(form, rulesFor(wanted), { canPrice });
    if (found.length) {
      if (found.some((i) => ADVANCED_FIELDS.has(i.field))) setMoreOpen(true);
      return;
    }
    setSaving(wanted);
    try {
      const saved = !course
        ? await services.courses.create(payloadOf(form, { canPrice }))
        : dirty
          ? await services.courses.update(course.id, payloadOf(form, { baseline, canPrice }))
          : course;
      setBaseline(form);
      leaving.current = true;
      const to = `${base}/courses/${saved.id}`;

      if (wanted === 'publish') {
        try {
          const live = await services.courses.publish(saved.id);
          toast({ kind: 'success', title: 'Course published', text: `${live.title} is live for learners.` });
        } catch (err) {
          // The draft is safe; only going live was refused (review before publishing, the plan, permissions).
          toast({ kind: 'warn', title: 'Saved as a draft — not published', text: (err as Error).message });
        }
        navigate(to);
        return;
      }

      toast(
        course
          ? { kind: 'success', title: 'Changes saved', text: saved.title }
          : {
              kind: 'success',
              title: 'Draft saved',
              text: `${saved.title} is private until you publish it.`,
              action: { label: 'Add lessons', onClick: () => navigate(`${to}/curriculum`) },
            },
      );
      navigate(to);
    } catch (err) {
      setSaveError((err as Error).message);
    } finally {
      setSaving(null);
    }
  };

  const cancel = () => navigate(course ? `${base}/courses/${course.id}` : `${base}/courses`);

  const stateLine = saving ? 'Saving…' : dirty ? 'Unsaved changes' : course ? 'All changes saved' : 'Nothing saved yet';

  const actions = offersPublish ? (
    <div className={styles.actions}>
      <Button onClick={() => void submit('draft')} loading={saving === 'draft'} disabled={saving !== null} iconStart={<FloppyDisk size={16} />}>
        Save draft
      </Button>
      <Button
        variant="primary"
        onClick={() => void submit('publish')}
        loading={saving === 'publish'}
        disabled={saving !== null}
        iconStart={<RocketLaunch size={16} />}
      >
        Publish
      </Button>
    </div>
  ) : (
    <div className={styles.actions}>
      <Button onClick={cancel} disabled={saving !== null}>
        Cancel
      </Button>
      <Button type="submit" form="course-form" variant="primary" loading={saving !== null} iconStart={<FloppyDisk size={16} />}>
        {course && course.status !== 'draft' ? 'Save changes' : 'Save draft'}
      </Button>
    </div>
  );

  const visibility = visibilityMeta[form.visibility];
  const defaultsLine = [visibility.label, FORMAT_LABEL[form.format], form.language, form.awardsCertificate ? 'Certificate on completion' : 'No certificate']
    .filter(Boolean)
    .join(' · ');

  return (
    <div className={styles.page}>
      <PageHeader
        back={{ label: course ? course.title : 'All courses', to: course ? `${base}/courses/${course.id}` : `${base}/courses` }}
        title={course ? 'Edit course' : 'New course'}
        description={
          isLive
            ? 'This course is live. Saved changes show to learners straight away.'
            : 'A title, a description and an instructor are all you need to publish. Everything else is optional and can be added later.'
        }
        meta={course && <CourseStatusBadge status={course.status} />}
      />

      <div className={styles.editor}>
        <form id="course-form" className={styles.form} onSubmit={(e) => void submit('draft', e)} noValidate>
          <div className={styles.messages}>
            <ErrorSummary issues={issues} attempt={attempt} title={rulesFor(intent) === 'publish' ? 'Finish these to publish' : 'Fix these before saving'} />
            {saveError && (
              <InlineMessage kind="error" title="Couldn’t save.">
                {saveError}
              </InlineMessage>
            )}
          </div>

          {/* 1 · Basic details — what publishing needs, with the optional parts learners see first */}
          <FormSection
            id="basics"
            title="Basic details"
            description="Title, description and an instructor are needed to publish. Subtitle, category, pricing and cover can follow."
          >
            <Field
              label="Course title"
              error={errorFor(issues, 'course-title')}
              hint={
                form.title.trim()
                  ? `${form.title.trim().length}/${TITLE_MAX} · zuviloai.com/courses/${slugify(form.title) || '…'}`
                  : 'Short and clear, e.g. “Fractions made simple” or “NEET Biology: Cell Structure”.'
              }
            >
              <Input
                id="course-title"
                value={form.title}
                maxLength={120}
                onChange={(e) => set('title', e.target.value)}
                placeholder="e.g. Fractions made simple"
                autoFocus={!course}
              />
            </Field>

            <Field
              label="Subtitle"
              optional
              error={errorFor(issues, 'course-subtitle')}
              hint={`${form.subtitle.length}/${SUBTITLE_MAX} · One line on what learners will be able to do.`}
            >
              <Input
                id="course-subtitle"
                value={form.subtitle}
                onChange={(e) => set('subtitle', e.target.value)}
                placeholder="e.g. Add, compare and simplify fractions with confidence"
              />
            </Field>

            <Field
              label="Description"
              error={errorFor(issues, 'course-description')}
              hint={`${form.description.length}/2,000 · Who it’s for, what it covers and how it’s taught. A few sentences is enough.`}
            >
              <Textarea
                id="course-description"
                rows={5}
                value={form.description}
                onChange={(e) => set('description', e.target.value)}
                placeholder="e.g. A six-week course for Class 6 students. Short videos and practice quizzes build confidence with adding, comparing and simplifying fractions."
              />
            </Field>

            <Field
              label="Category"
              optional
              hint={course ? undefined : `Left blank, the course goes in “${defaultCategory?.name ?? 'General'}”. You can move it any time.`}
            >
              <Select id="course-category" value={form.categoryId} onChange={(e) => set('categoryId', e.target.value)}>
                {!course && <option value="">{defaultCategory ? `${defaultCategory.name} (default)` : 'General (default)'}</option>}
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                    {c.status === 'hidden' ? ' (hidden)' : ''}
                  </option>
                ))}
              </Select>
            </Field>

            <div className={styles.group}>
              <p className={styles.groupLabel} id="course-pricing-label">
                Pricing
              </p>
              <p className={styles.groupHint}>
                A free course opens to learners straight away. A paid course opens once the payment is confirmed. The price is all-inclusive — nothing is added
                at checkout.
              </p>
              {canPrice ? (
                <div className={styles.groupBody}>
                  {form.pricing === 'unset' && <InlineMessage kind="warn">{UNSET_WARNING}</InlineMessage>}
                  <ChoiceCards<FormState['pricing']>
                    legend="Free or paid"
                    hideLegend
                    columns={2}
                    value={form.pricing}
                    onChange={(v) => set('pricing', v)}
                    choices={[
                      { value: 'free', label: 'Free', description: 'Learners enrol at no cost.', icon: <Gift size={18} /> },
                      { value: 'paid', label: 'Paid', description: 'Learners pay online once to open it.', icon: <CurrencyInr size={18} /> },
                    ]}
                  />
                  {form.pricing === 'paid' && (
                    <Field
                      label="Price (₹)"
                      error={errorFor(issues, 'course-price')}
                      hint={`Whole rupees, ₹1 to ₹5,00,000. Learners pay exactly this.`}
                      className={styles.priceField}
                    >
                      <Input
                        id="course-price"
                        inputMode="numeric"
                        autoComplete="off"
                        value={form.priceText}
                        onChange={(e) => set('priceText', e.target.value)}
                        placeholder="e.g. 1499"
                      />
                    </Field>
                  )}
                  {form.pricing === 'paid' && (
                    <Field
                      label="Sale price (₹)"
                      optional
                      error={errorFor(issues, 'course-sale-price')}
                      hint="Leave empty for no sale. Learners pay this instead, and see the list price struck through."
                      className={styles.priceField}
                    >
                      <Input
                        id="course-sale-price"
                        inputMode="numeric"
                        autoComplete="off"
                        value={form.saleText}
                        onChange={(e) => set('saleText', e.target.value)}
                      />
                    </Field>
                  )}
                </div>
              ) : (
                <div className={styles.groupBody}>
                  <p className={styles.contentTitle} id="course-price">
                    {course ? pricingSummary(course).label : 'Not chosen'}
                  </p>
                  <p className={styles.contentHint}>Only an admin sets a course’s price.</p>
                  {(!course || pricingSummary(course).unset) && (
                    <InlineMessage kind="warn">Learners can’t join this course until an admin chooses Free or Paid.</InlineMessage>
                  )}
                </div>
              )}
            </div>

            <div className={styles.group}>
              <p className={styles.groupLabel} id="course-instructors-label">
                Instructors
              </p>
              <p className={styles.groupHint}>Instructors can edit the course, run its live classes and review submissions.</p>
              {activeInstructors.length ? (
                <div
                  id="course-instructors"
                  tabIndex={-1}
                  role="group"
                  aria-labelledby="course-instructors-label"
                  aria-describedby={errorFor(issues, 'course-instructors') ? 'course-instructors-error' : undefined}
                  className={cx(styles.people, errorFor(issues, 'course-instructors') && styles.peopleInvalid)}
                >
                  {activeInstructors.map((person) => {
                    const locked = person.id === instructorId;
                    return (
                      <Checkbox
                        key={person.id}
                        className={styles.person}
                        checked={form.instructorIds.includes(person.id)}
                        disabled={locked}
                        onChange={(e) =>
                          set('instructorIds', e.target.checked ? [...form.instructorIds, person.id] : form.instructorIds.filter((id) => id !== person.id))
                        }
                        label={
                          <span className={styles.personLabel}>
                            <Avatar name={person.name} size={30} />
                            <span className={styles.personText}>
                              <span className={styles.personName}>
                                {person.name}
                                {locked && <span className={styles.subtle}> · you</span>}
                              </span>
                              <span className={styles.personTitle}>{person.title}</span>
                            </span>
                            {person.status === 'invited' && (
                              <Badge size="sm" tone="info">
                                Invited
                              </Badge>
                            )}
                          </span>
                        }
                      />
                    );
                  })}
                </div>
              ) : (
                <div id="course-instructors" tabIndex={-1} className={cx(styles.emptyPeople, errorFor(issues, 'course-instructors') && styles.peopleInvalid)}>
                  <p>No instructors yet. You can save the draft now and assign one later.</p>
                  {base === '/admin' && (
                    <LinkButton to="/admin/instructors" size="sm" iconEnd={<ArrowRight size={14} />}>
                      Add an instructor
                    </LinkButton>
                  )}
                </div>
              )}
              {errorFor(issues, 'course-instructors') && (
                <p id="course-instructors-error" className={styles.fieldError}>
                  {errorFor(issues, 'course-instructors')}
                </p>
              )}
            </div>

            <div className={styles.group}>
              <p className={styles.groupLabel}>
                Cover <span className={styles.optionalTag}>Optional</span>
              </p>
              <p className={styles.groupHint}>Upload an image, or keep the generated artwork.</p>
              <div className={styles.groupBody}>
                <CoverImageField
                  motif={form.coverMotif}
                  imageId={form.coverImageId}
                  preview={coverPreview}
                  onChange={(imageId, preview) => {
                    set('coverImageId', imageId);
                    setCoverPreview(preview);
                  }}
                />
                <ChoiceCards<CoverMotif>
                  legend="Cover artwork"
                  columns={4}
                  value={form.coverMotif}
                  onChange={(v) => set('coverMotif', v)}
                  choices={MOTIFS.map((m) => ({ ...m, visual: <CourseCover motif={m.value} className={styles.motif} /> }))}
                />
              </div>
            </div>
          </FormSection>

          {/* 2 · Course content — chapters and lessons live in the curriculum */}
          <FormSection id="content" title="Course content" description="Chapters and lessons — videos, readings, PDFs, quizzes and assignments.">
            <div className={styles.contentCard}>
              <ListNumbers size={22} aria-hidden="true" className={styles.contentIcon} />
              <div className={styles.contentText}>
                {course ? (
                  <>
                    <p className={styles.contentTitle}>
                      {course.chapters.length ? `${plural(course.chapters.length, 'chapter')} · ${plural(lessons, 'lesson')}` : 'No chapters yet'}
                    </p>
                    <p className={styles.contentHint}>
                      {hasPublishedLessons(course)
                        ? 'Edit chapters and lessons in the curriculum.'
                        : 'Add lessons whenever you’re ready — you can publish first and fill in the curriculum later.'}
                    </p>
                  </>
                ) : (
                  <>
                    <p className={styles.contentTitle}>Add lessons after saving</p>
                    <p className={styles.contentHint}>Save the draft, then build chapters and lessons in the curriculum. They aren’t needed to publish.</p>
                  </>
                )}
              </div>
              {course && (
                <LinkButton to={`${base}/courses/${course.id}/curriculum`} size="sm" iconEnd={<ArrowRight size={14} />}>
                  Open curriculum
                </LinkButton>
              )}
            </div>
          </FormSection>

          {/* 3 · Additional settings — optional, collapsed, sensible defaults until changed */}
          <section id="more" className={styles.more} aria-labelledby="more-title">
            <button type="button" className={styles.moreToggle} aria-expanded={panelOpen} aria-controls="more-panel" onClick={() => setMoreOpen(!panelOpen)}>
              <span className={styles.moreText}>
                <span className={styles.moreTitle} id="more-title">
                  Additional settings <span className={styles.optionalTag}>Optional</span>
                </span>
                <span className={styles.moreHint}>Learning outcomes, tags, level, format, visibility and certificate. Using: {defaultsLine}.</span>
              </span>
              <CaretDown size={18} className={cx(styles.moreCaret, panelOpen && styles.moreCaretOpen)} aria-hidden="true" />
            </button>

            {panelOpen && (
              <div id="more-panel" className={styles.morePanel}>
                <FormSection id="course-page" title="Outcomes & tags" description="Help learners decide to enrol, and find the course in search.">
                  <div id="course-outcomes" tabIndex={-1}>
                    <ListInput
                      label="Learning outcomes"
                      value={form.outcomes}
                      onChange={(v) => set('outcomes', v)}
                      placeholder="e.g. Simplify a fraction to its lowest terms"
                      addLabel="Add outcome"
                      max={8}
                      error={errorFor(issues, 'course-outcomes')}
                      hint="Optional. What a learner can do by the end — start each with a verb."
                    />
                  </div>
                  <TagInput
                    label="Tags"
                    value={form.tags}
                    onChange={(v) => set('tags', v)}
                    suggestions={tags}
                    placeholder="e.g. Class 6, Maths — press Enter after each"
                    hint="Optional. Words learners would search for."
                  />
                </FormSection>

                <FormSection id="classification" title="Classification" description="Where the course sits in the catalog and how it is delivered.">
                  {levels.length > 0 && (
                    <ChoiceCards
                      legend="Level"
                      columns={4}
                      value={form.levelId}
                      onChange={(v) => set('levelId', v)}
                      choices={levels.map((l) => ({ value: l.id, label: l.name, description: l.summary }))}
                    />
                  )}
                  <ChoiceCards<CourseFormat> legend="Format" columns={3} value={form.format} onChange={(v) => set('format', v)} choices={FORMATS} />
                  <div className={styles.threeUp}>
                    <Field label="Language" optional>
                      <Input value={form.language} onChange={(e) => set('language', e.target.value)} placeholder="e.g. English" />
                    </Field>
                    <Field label="Estimated length" optional hint="Weeks at the suggested pace" error={errorFor(issues, 'course-weeks')}>
                      <Input
                        id="course-weeks"
                        type="number"
                        inputMode="numeric"
                        min={1}
                        max={52}
                        placeholder="e.g. 6"
                        value={form.estimatedWeeks ?? ''}
                        onChange={(e) => set('estimatedWeeks', e.target.value === '' ? undefined : Number(e.target.value))}
                      />
                    </Field>
                    <Field label="Live sessions" optional hint="Planned for the course" error={errorFor(issues, 'course-live')}>
                      <Input
                        id="course-live"
                        type="number"
                        inputMode="numeric"
                        min={0}
                        max={60}
                        value={form.liveSessions}
                        onChange={(e) => set('liveSessions', e.target.value === '' ? 0 : Number(e.target.value))}
                      />
                    </Field>
                  </div>
                </FormSection>

                <FormSection
                  id="visibility"
                  title="Visibility & certificate"
                  description="Who can enrol once it is published, and what they receive on completion."
                >
                  <ChoiceCards
                    legend="Visibility after publishing"
                    columns={3}
                    value={form.visibility}
                    onChange={(v) => set('visibility', v)}
                    choices={(['public', 'unlisted', 'private'] as const).map((v) => ({
                      value: v,
                      label: visibilityMeta[v].label,
                      description: visibilityMeta[v].description,
                      icon: visibilityMeta[v].icon,
                    }))}
                  />
                  <Switch
                    checked={form.awardsCertificate}
                    onChange={(v) => set('awardsCertificate', v)}
                    label="Award a certificate on completion"
                    description="Issued automatically when a learner meets the course’s completion rules."
                  />
                  {form.awardsCertificate && (
                    <Field label="Certificate title" error={errorFor(issues, 'course-certificate')}>
                      <Input
                        id="course-certificate"
                        value={form.certificateTitle ?? ''}
                        onChange={(e) => set('certificateTitle', e.target.value)}
                        placeholder="e.g. Certificate in Class 6 Fractions"
                      />
                    </Field>
                  )}
                </FormSection>
              </div>
            )}
          </section>
        </form>

        <aside className={styles.aside} aria-label="Course summary">
          <div className={styles.summaryCard}>
            <CourseCover motif={form.coverMotif} imageUrl={form.coverImageId ? coverPreview : undefined} className={styles.summaryCover} />
            <div className={styles.summaryText}>
              <span className={styles.summaryTitle}>{form.title.trim() || 'Untitled course'}</span>
              {form.subtitle.trim() && <span className={styles.summarySubtitle}>{form.subtitle}</span>}
            </div>
            <p className={cx(styles.saveState, dirty && styles.saveStateDirty)} role="status">
              {dirty ? <PencilSimpleLine size={15} /> : <CheckCircle size={15} />}
              {stateLine}
            </p>
            {!isMobile && actions}
          </div>

          {course?.status !== 'archived' && (
            <div className={styles.readiness}>
              <p className={styles.readinessHead}>
                {isLive ? 'Required while live' : 'Ready to publish'}
                <span className={styles.readinessCount}>
                  {met}/{checks.length}
                </span>
              </p>
              <ul className={styles.readinessList}>
                {checks.map((c) => (
                  <li key={c.id} className={c.met ? styles.readyMet : undefined}>
                    <button type="button" className={styles.readyItem} onClick={() => focusField(CHECK_FIELD[c.id] ?? 'course-title')}>
                      {c.met ? <CheckCircle size={16} weight="fill" /> : <Circle size={16} />}
                      <span>{c.label}</span>
                      <span className={styles.readyState}>{c.met ? 'Done' : 'To do'}</span>
                    </button>
                  </li>
                ))}
              </ul>
              <p className={styles.readinessNote}>
                {met === checks.length
                  ? isLive
                    ? 'Everything a live course needs is in place.'
                    : `Ready. Publishing makes it ${visibility.label.toLowerCase()}: ${visibility.description.charAt(0).toLowerCase()}${visibility.description.slice(1)}`
                  : 'Everything else is optional — add it now or after publishing.'}
              </p>
            </div>
          )}

          <nav className={styles.sectionNav} aria-label="Form sections">
            {SECTIONS.map((s) => (
              <a
                key={s.id}
                href={`#${s.id}`}
                onClick={(e) => {
                  e.preventDefault();
                  document.getElementById(s.id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }}
              >
                {s.label}
              </a>
            ))}
          </nav>
        </aside>
      </div>

      {isMobile && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{actions}</div>}>
          <span />
        </StickyActionBar>
      )}

      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave without saving?"
        description={`Your changes to ${form.title.trim() || 'this course'} haven’t been saved.`}
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

/** The uploaded cover image: a drop zone while there is none, then a preview with Replace and Remove. */
function CoverImageField({
  motif,
  imageId,
  preview,
  onChange,
}: {
  motif: CoverMotif;
  imageId: string | null;
  preview?: string;
  onChange: (imageId: string | null, preview?: string) => void;
}) {
  const [replacing, setReplacing] = useState(false);
  const drop = (
    <MediaDrop
      id="course-cover-image"
      accept="image/png,image/jpeg,image/webp,.png,.jpg,.jpeg,.webp"
      label={imageId ? 'Drop the new cover image here' : 'Upload a cover image'}
      hint="PNG, JPG or WebP, up to 5 MB. A wide image (16:10) fits best."
      icon={<ImageIcon size={20} />}
      onDone={(file) => {
        setReplacing(false);
        if (file.id) onChange(file.id, file.url);
      }}
    />
  );
  if (!imageId) return drop;
  return (
    <div className={styles.coverImage}>
      <CourseCover motif={motif} imageUrl={preview} className={styles.coverImagePreview} label="Cover image preview" />
      <div className={styles.coverImageActions}>
        {replacing ? (
          <>
            {drop}
            <Button size="sm" variant="ghost" onClick={() => setReplacing(false)}>
              Keep the current image
            </Button>
          </>
        ) : (
          <>
            <Button size="sm" iconStart={<ArrowsClockwise size={15} />} onClick={() => setReplacing(true)}>
              Replace image
            </Button>
            <Button size="sm" variant="ghost" iconStart={<Trash size={15} />} onClick={() => onChange(null)}>
              Remove image
            </Button>
            <span className={styles.subtle}>Changes apply when you save the course. Without an image, the artwork below is shown.</span>
          </>
        )}
      </div>
    </div>
  );
}

function EditorSkeleton() {
  return (
    <div className={styles.page} role="status" aria-label="Loading the editor">
      <Skeleton width={120} height={12} />
      <Skeleton width={260} height={32} radius="var(--r-xs)" />
      <div className={styles.editor}>
        <div className={styles.form}>
          {Array.from({ length: 3 }, (_, i) => (
            <div key={i} className={styles.skeletonSection}>
              <Skeleton width={140} height={14} />
              <Skeleton height={40} radius="var(--r-sm)" />
              <Skeleton height={40} radius="var(--r-sm)" />
            </div>
          ))}
        </div>
        <div className={styles.aside}>
          <Skeleton height={220} radius="var(--r-lg)" />
        </div>
      </div>
    </div>
  );
}
