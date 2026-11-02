import { useEffect, useMemo, useRef, useState, type FormEvent } from 'react';
import { useBlocker, useNavigate, useParams } from 'react-router-dom';
import { Camera, CheckCircle, FloppyDisk, Trash, WarningCircle } from '@phosphor-icons/react';
import type { Course, Instructor, InstructorInput, MediaFile } from '@syniastrolms/domain';
import { validateInstructor } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useViewport } from '@/hooks/useViewport';
import { cx } from '@/lib/cx';
import { plural } from '@/lib/format';
import { ChoiceCards, ErrorSummary, FormSection, TagInput, type FieldIssue } from '@/components/forms/Forms';
import { PageHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input, SearchInput, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { CourseStatusBadge } from '@/components/lms/course/CourseStatus';
import { Meter } from '@/components/lms/progress/Meters';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { EXPERTISE_SUGGESTIONS, InstructorStatusBadge, LANGUAGE_SUGGESTIONS } from './instructorMeta';
import styles from './Instructors.module.css';

export default function InstructorEditorPage() {
  const { instructorId } = useParams();
  const query = useAsync(`instructor-editor:${instructorId ?? 'new'}`, () =>
    Promise.all([
      instructorId ? services.instructors.get(instructorId) : Promise.resolve(null),
      services.courses.list({ page: 1, pageSize: 100 }),
      services.catalog.listInstructors(),
    ]).then(([profile, courses, instructors]) => ({ profile, courses: courses.rows, instructors })),
  );

  usePageCrumbs(
    query.data?.profile
      ? [{ label: query.data.profile.instructor.name, to: `/admin/instructors/${instructorId}` }, { label: 'Edit' }]
      : [{ label: instructorId ? 'Edit' : 'Add instructor' }],
  );

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'Instructor not found' : 'The form didn’t load'}
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
  if (!query.data) {
    return (
      <div className={styles.page} role="status" aria-label="Loading the form">
        <Skeleton width="30%" height={30} radius="var(--r-xs)" />
        <div className={styles.editor}>
          <Skeleton height={620} radius="var(--r-lg)" />
          <Skeleton height={260} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }
  const { profile, courses, instructors } = query.data;
  return (
    <Editor
      key={profile?.instructor.id ?? 'new'}
      instructor={profile?.instructor ?? null}
      assigned={profile?.courses.map((c) => c.id) ?? []}
      courses={courses}
      instructors={instructors}
    />
  );
}

const blank: InstructorInput = {
  name: '',
  title: '',
  email: '',
  phone: '',
  bio: '',
  expertise: [],
  status: 'invited',
  city: '',
  languages: ['English'],
  yearsTeaching: undefined,
  courseIds: [],
};

const FIELD_ID: Record<string, string> = {
  name: 'instructor-name',
  title: 'instructor-title',
  email: 'instructor-email',
  phone: 'instructor-phone',
  bio: 'instructor-bio',
  expertise: 'instructor-expertise',
  languages: 'instructor-languages',
  yearsTeaching: 'instructor-years',
};

interface EditorProps {
  instructor: Instructor | null;
  assigned: string[];
  courses: Course[];
  instructors: Instructor[];
}

function Editor({ instructor, assigned, courses, instructors }: EditorProps) {
  const navigate = useNavigate();
  const toast = useToast();
  const { isMobile } = useViewport();
  const initial: InstructorInput = instructor
    ? {
        name: instructor.name,
        title: instructor.title,
        email: instructor.email,
        phone: instructor.phone ?? '',
        bio: instructor.bio,
        expertise: instructor.expertise,
        status: instructor.status,
        city: instructor.city,
        languages: instructor.languages,
        yearsTeaching: instructor.yearsTeaching,
        photo: instructor.photo,
        courseIds: assigned,
      }
    : blank;
  const [form, setForm] = useState<InstructorInput>(initial);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [courseSearch, setCourseSearch] = useState('');
  const leaving = useRef(false);
  const set = <K extends keyof InstructorInput>(key: K, value: InstructorInput[K]) => setForm((f) => ({ ...f, [key]: value }));

  const dirty = JSON.stringify(form) !== JSON.stringify(initial);
  const blocker = useBlocker(({ currentLocation, nextLocation }) => dirty && !leaving.current && currentLocation.pathname !== nextLocation.pathname);
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const taken = instructors.filter((i) => i.id !== instructor?.id).map((i) => i.email);
  const clean = { ...form, phone: form.phone?.trim() || undefined };
  const allIssues = validateInstructor(clean, taken);
  const issues: FieldIssue[] = attempt ? allIssues.map((i) => ({ field: FIELD_ID[i.field], message: i.message })) : [];
  const errorFor = (field: string) => issues.find((i) => i.field === FIELD_ID[field])?.message;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setSaveError(null);
    if (allIssues.length) return;
    setSaving(true);
    try {
      const saved = instructor ? await services.instructors.update(instructor.id, clean) : await services.instructors.create(clean);
      leaving.current = true;
      toast({
        kind: 'success',
        title: instructor ? 'Changes saved' : clean.status === 'invited' ? `Invitation sent to ${saved.name}` : `${saved.name} added`,
        text: instructor ? saved.name : clean.status === 'invited' ? saved.email : `${plural(clean.courseIds.length, 'course')} assigned`,
      });
      navigate(`/admin/instructors/${saved.id}`, { replace: true });
    } catch (err) {
      setSaveError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const available = courses.filter((c) => c.status !== 'archived' || form.courseIds.includes(c.id));
  const q = courseSearch.trim().toLowerCase();
  const shownCourses = available.filter((c) => !q || c.title.toLowerCase().includes(q));
  const nameOf = (id: string) => instructors.find((i) => i.id === id)?.name ?? '';
  const checklist = [
    { done: clean.name.trim().length >= 3 && clean.title.trim().length >= 3, label: 'Name and title' },
    { done: !allIssues.some((i) => i.field === 'email'), label: 'A valid email for the invitation' },
    { done: clean.bio.trim().length >= 60, label: 'A bio learners can read' },
    { done: clean.expertise.length > 0, label: 'Expertise' },
    { done: clean.courseIds.length > 0, label: 'At least one course' },
  ];

  const actions = (
    <div className={styles.actions}>
      <Button onClick={() => navigate(instructor ? `/admin/instructors/${instructor.id}` : '/admin/instructors')} disabled={saving}>
        Cancel
      </Button>
      <Button type="submit" form="instructor-form" variant="primary" loading={saving} iconStart={<FloppyDisk size={16} />}>
        {instructor ? 'Save changes' : form.status === 'invited' ? 'Send invitation' : 'Add instructor'}
      </Button>
    </div>
  );

  return (
    <div className={styles.page}>
      <PageHeader
        back={{ label: instructor ? instructor.name : 'Instructors', to: instructor ? `/admin/instructors/${instructor.id}` : '/admin/instructors' }}
        title={instructor ? 'Edit instructor' : 'Add instructor'}
        description={
          instructor
            ? 'Changes show on their profile and every course page they teach.'
            : 'Invite an instructor by email. They set a password, then can edit their assigned courses, run live classes and review submissions.'
        }
        meta={instructor && <InstructorStatusBadge status={instructor.status} size="md" />}
      />

      <div className={styles.editor}>
        <form id="instructor-form" className={styles.form} onSubmit={submit} noValidate>
          <div className={styles.messages}>
            <ErrorSummary issues={issues} attempt={attempt} />
            {saveError && (
              <InlineMessage kind="error" title="Couldn’t save.">
                {saveError}
              </InlineMessage>
            )}
          </div>

          <FormSection id="identity" title="Identity" description="How the instructor appears on course pages, certificates and the live class room.">
            <PhotoPicker name={form.name} photo={form.photo} onChange={(photo) => set('photo', photo)} />
            <div className={styles.twoUp}>
              <Field label="Full name" error={errorFor('name')}>
                <Input
                  id="instructor-name"
                  value={form.name}
                  onChange={(e) => set('name', e.target.value)}
                  placeholder="Dr. Lalitha Raman"
                  autoComplete="name"
                  autoFocus={!instructor}
                />
              </Field>
              <Field label="Professional title" error={errorFor('title')}>
                <Input id="instructor-title" value={form.title} onChange={(e) => set('title', e.target.value)} placeholder="Prashna specialist" />
              </Field>
              <Field label="Email" error={errorFor('email')} hint={instructor ? undefined : 'The invitation is sent here.'}>
                <Input
                  id="instructor-email"
                  type="email"
                  value={form.email}
                  onChange={(e) => set('email', e.target.value)}
                  placeholder="name@zuviloai.com"
                  autoComplete="email"
                />
              </Field>
              <Field label="Phone" optional error={errorFor('phone')}>
                <Input
                  id="instructor-phone"
                  type="tel"
                  value={form.phone ?? ''}
                  onChange={(e) => set('phone', e.target.value)}
                  placeholder="+91 98200 12345"
                  autoComplete="tel"
                />
              </Field>
              <Field label="City">
                <Input value={form.city} onChange={(e) => set('city', e.target.value)} placeholder="Madurai" />
              </Field>
              <Field label="Years teaching" optional error={errorFor('yearsTeaching')}>
                <Input
                  id="instructor-years"
                  type="number"
                  inputMode="numeric"
                  min={0}
                  max={70}
                  value={form.yearsTeaching ?? ''}
                  onChange={(e) => set('yearsTeaching', e.target.value === '' ? undefined : Number(e.target.value))}
                />
              </Field>
            </div>
          </FormSection>

          <FormSection id="about" title="About" description="Learners read this on every course page. Lead with lineage and what they’re known for.">
            <Field
              label="Bio"
              error={errorFor('bio')}
              hint={`${form.bio.trim().length} characters${form.status === 'active' ? ' · at least 60 for an active instructor' : ''}`}
            >
              <Textarea
                id="instructor-bio"
                rows={6}
                value={form.bio}
                onChange={(e) => set('bio', e.target.value)}
                placeholder="Lalitha has taught Class 9–12 mathematics in Jaipur for fifteen years and prepares students for RPSC exams…"
              />
            </Field>
            <div id="instructor-expertise" tabIndex={-1}>
              <TagInput
                label="Expertise"
                value={form.expertise}
                onChange={(v) => set('expertise', v)}
                suggestions={EXPERTISE_SUGGESTIONS}
                placeholder="Add an area and press Enter"
                max={6}
                hint={errorFor('expertise') ?? 'Shown as tags on their profile. Up to six.'}
              />
            </div>
            <div id="instructor-languages" tabIndex={-1}>
              <TagInput
                label="Teaching languages"
                value={form.languages}
                onChange={(v) => set('languages', v)}
                suggestions={LANGUAGE_SUGGESTIONS}
                placeholder="Add a language"
                max={5}
                hint={errorFor('languages')}
              />
            </div>
          </FormSection>

          <FormSection
            id="courses"
            title="Courses"
            description="Instructors can edit these courses, run their live classes and review submissions. The first instructor on a course leads it."
          >
            {available.length > 6 && (
              <SearchInput value={courseSearch} onValueChange={setCourseSearch} placeholder="Find a course" aria-label="Find a course" />
            )}
            <ul className={styles.assign} aria-label="Assign courses">
              {shownCourses.map((c) => {
                const checked = form.courseIds.includes(c.id);
                const others = c.instructorIds.filter((id) => id !== instructor?.id);
                const sole = Boolean(instructor) && c.instructorIds.length === 1 && c.instructorIds[0] === instructor?.id;
                return (
                  <li key={c.id} className={cx(styles.assignRow, checked && styles.assignOn)}>
                    <Checkbox
                      checked={checked}
                      disabled={sole}
                      onChange={(e) => set('courseIds', e.target.checked ? [...form.courseIds, c.id] : form.courseIds.filter((id) => id !== c.id))}
                      label={
                        <span className={styles.assignText}>
                          <span className={styles.cellStrong}>{c.title}</span>
                          <span className={styles.cellMeta}>
                            {sole
                              ? 'Only instructor — assign someone else before removing'
                              : others.length
                                ? `With ${others.map(nameOf).join(', ')}`
                                : 'No instructor yet'}
                          </span>
                        </span>
                      }
                    />
                    <CourseStatusBadge status={c.status} />
                  </li>
                );
              })}
              {shownCourses.length === 0 && <li className={styles.muted}>No courses match “{courseSearch}”.</li>}
            </ul>
          </FormSection>

          <FormSection
            id="access"
            title="Access"
            description="Invited instructors can’t sign in until they accept. Inactive instructors keep their name on courses but can’t sign in."
          >
            <ChoiceCards
              legend="Status"
              hideLegend
              columns={3}
              value={form.status}
              onChange={(v) => set('status', v)}
              choices={[
                {
                  value: 'invited',
                  label: 'Invited',
                  description:
                    instructor && instructor.status !== 'invited'
                      ? 'Already accepted — their account is set up.'
                      : 'An email with a link to set up their account.',
                  disabled: Boolean(instructor && instructor.status !== 'invited'),
                },
                { value: 'active', label: 'Active', description: 'Signed in and teaching. Needs a full bio.' },
                { value: 'inactive', label: 'Inactive', description: 'No sign-in; courses keep their name.', disabled: !instructor },
              ]}
            />
          </FormSection>
        </form>

        <aside className={styles.aside} aria-label="Instructor summary">
          <div className={styles.summaryCard}>
            <Avatar name={form.name.trim() || '?'} size={56} className={cx(form.photo && styles.hasPhoto)} />
            <div className={styles.personText}>
              <span className={styles.summaryName}>{form.name.trim() || 'New instructor'}</span>
              <span className={styles.personMeta}>{form.title.trim() || 'Professional title'}</span>
            </div>
          </div>
          <div className={styles.readiness}>
            <p className={styles.readinessHead}>
              Profile{' '}
              <span className="tabular">
                {checklist.filter((c) => c.done).length}/{checklist.length}
              </span>
            </p>
            <ul className={styles.readinessList}>
              {checklist.map((c) => (
                <li key={c.label} className={cx(c.done && styles.readinessDone)}>
                  {c.done ? <CheckCircle size={15} weight="fill" /> : <WarningCircle size={15} />} {c.label}
                </li>
              ))}
            </ul>
          </div>
          {!isMobile && actions}
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
        description={`Your changes to ${form.name.trim() || 'this instructor'} haven’t been saved.`}
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

/** Display image. The upload is simulated; initials stand in for the picture. */
function PhotoPicker({ name, photo, onChange }: { name: string; photo?: MediaFile; onChange: (photo?: MediaFile) => void }) {
  const input = useRef<HTMLInputElement>(null);
  const timer = useRef<number>();
  const [progress, setProgress] = useState<number | null>(null);
  useEffect(() => () => window.clearInterval(timer.current), []);
  const start = (file: File) => {
    let p = 0;
    setProgress(0);
    timer.current = window.setInterval(() => {
      p = Math.min(100, p + 18 + Math.random() * 20);
      setProgress(p);
      if (p >= 100) {
        window.clearInterval(timer.current);
        setProgress(null);
        onChange({ name: file.name, sizeMb: Math.max(0.1, Math.round((file.size / 1_048_576) * 10) / 10) });
      }
    }, 180);
  };
  const initials = useMemo(() => name.trim() || '?', [name]);
  return (
    <div className={styles.photo}>
      <Avatar name={initials} size={72} className={cx(photo && styles.hasPhoto)} />
      <div className={styles.photoText}>
        <span className={styles.cellStrong}>Display image</span>
        {progress !== null ? (
          <Meter value={progress} size="sm" showLabel label="Uploading image" valueText={`${Math.round(progress)}%`} />
        ) : photo ? (
          <span className={styles.cellMeta}>
            {photo.name} · {photo.sizeMb} MB
          </span>
        ) : (
          <span className={styles.cellMeta}>A square portrait, at least 400 × 400 px. Initials are shown until one is added.</span>
        )}
        <span className={styles.photoActions}>
          <Button size="sm" iconStart={<Camera size={15} />} onClick={() => input.current?.click()} disabled={progress !== null}>
            {photo ? 'Replace' : 'Upload image'}
          </Button>
          {photo && (
            <Button size="sm" variant="ghost" iconStart={<Trash size={15} />} onClick={() => onChange(undefined)}>
              Remove
            </Button>
          )}
        </span>
      </div>
      <input
        ref={input}
        type="file"
        accept="image/png,image/jpeg,image/webp"
        className="sr-only"
        tabIndex={-1}
        aria-hidden="true"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) start(file);
          e.target.value = '';
        }}
      />
    </div>
  );
}
