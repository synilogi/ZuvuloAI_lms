import { useEffect, useRef, useState, type FormEvent } from 'react';
import { useBlocker, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { ArrowLeft, FloppyDisk, Plus, Trash, VideoCamera } from '@phosphor-icons/react';
import type { Course, Instructor, LiveClass } from '@syniastrolms/domain';
import { validateLiveClass } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { usePermissions } from '@/hooks/usePermissions';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatDuration, pad2, plural } from '@/lib/format';
import { ChoiceCards, ErrorSummary, FormSection, type FieldIssue } from '@/components/forms/Forms';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { REMINDER_OPTIONS } from './liveMeta';
import { LIVE_FIELD, buildLivePayload, forValidation, serverFieldIssues, toLiveForm, toMinutes } from './liveForm';
import { canEditLiveClass } from './liveRules';
import styles from './Live.module.css';

export default function LiveClassEditorPage() {
  const { liveId } = useParams();
  const { base, instructorId } = useWorkspace();
  const [params] = useSearchParams();
  const { can } = usePermissions();
  const now = useNow();
  // `?from=<id>`: a new class copied from another (a cancelled class run again).
  const from = liveId ? null : params.get('from');
  const query = useAsync(`live-editor:${liveId ?? 'new'}:${from ?? ''}`, () =>
    Promise.all([
      liveId ? services.live.get(liveId, instructorId) : Promise.resolve(null),
      services.courses.list({ scopeInstructorId: instructorId, status: 'published', page: 1, pageSize: 100 }),
      services.catalog.listInstructors(),
      // A copy that can't be read just starts blank.
      from ? services.live.get(from, instructorId).catch(() => null) : Promise.resolve(null),
    ]).then(([detail, courses, instructors, template]) => ({ detail, courses: courses.rows, instructors, template })),
  );
  usePageCrumbs(
    query.data?.detail
      ? [{ label: query.data.detail.liveClass.title, to: `${base}/live/${liveId}` }, { label: 'Edit' }]
      : [{ label: liveId ? 'Edit' : 'Schedule a class' }],
  );

  if (!can('live.manage')) {
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title="You can’t schedule live classes"
          actions={
            <LinkButton to={`${base}/live`} iconStart={<ArrowLeft size={16} />}>
              Back to live classes
            </LinkButton>
          }
        >
          Scheduling and editing classes needs the “Manage live classes” permission. Ask a super admin to grant it.
        </StateMessage>
      </div>
    );
  }
  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'Live class not found' : 'The form didn’t load'}
          actions={
            notFound ? (
              <LinkButton to={`${base}/live`} iconStart={<ArrowLeft size={16} />}>
                Back to live classes
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
  if (!query.data) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton width="30%" height={30} radius="var(--r-xs)" />
        <Skeleton height={640} radius="var(--r-lg)" />
      </div>
    );
  }
  const { detail, courses, instructors, template } = query.data;
  // The API refuses to edit a class once it is cancelled, started, or past its start time.
  if (detail && !canEditLiveClass(detail.liveClass, now)) {
    return (
      <div className={styles.page}>
        <StateMessage
          icon={<VideoCamera size={26} />}
          title={detail.phase === 'cancelled' ? 'This class is cancelled' : 'This class has already started'}
          actions={
            <LinkButton to={`${base}/live/${detail.liveClass.id}`} iconStart={<ArrowLeft size={16} />}>
              Back to the class
            </LinkButton>
          }
        >
          Only classes that haven’t started can be edited. Schedule a new class to run it again.
        </StateMessage>
      </div>
    );
  }
  return (
    <Editor
      key={detail?.liveClass.id ?? 'new'}
      liveClass={detail?.liveClass ?? null}
      courseTitle={detail?.courseTitle}
      template={template?.liveClass ?? null}
      courses={courses}
      instructors={instructors}
      base={base}
      defaultInstructor={instructorId}
      courseParam={params.get('course')}
    />
  );
}

interface EditorProps {
  liveClass: LiveClass | null;
  /** The edited class's course, which may not be among the published courses offered for a new class. */
  courseTitle?: string;
  /** A class to copy into a new one. */
  template: LiveClass | null;
  courses: Course[];
  instructors: Instructor[];
  base: string;
  defaultInstructor?: string;
  courseParam: string | null;
}

function Editor({ liveClass, courseTitle, template, courses, instructors, base, defaultInstructor, courseParam }: EditorProps) {
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const startCourse = courses.find((c) => c.id === (liveClass?.courseId ?? template?.courseId ?? courseParam)) ?? courses[0];
  // The time is read as an IST wall clock — `startsAt` comes back in UTC — so saving it again keeps the same moment.
  const [initial] = useState(() =>
    toLiveForm(liveClass, {
      now,
      template: template && courses.some((c) => c.id === template.courseId) ? template : null,
      courseId: startCourse?.id ?? '',
      instructorId: defaultInstructor ?? startCourse?.instructorIds[0] ?? '',
    }),
  );
  const [form, setForm] = useState(initial);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  /** What the server found wrong with the last save, beside each field; cleared on the next try. */
  const [serverIssues, setServerIssues] = useState<FieldIssue[]>([]);
  const leaving = useRef(false);
  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) => setForm((f) => ({ ...f, [key]: value }));
  const dirty = JSON.stringify(form) !== JSON.stringify(initial);

  const blocker = useBlocker(({ currentLocation, nextLocation }) => dirty && !leaving.current && currentLocation.pathname !== nextLocation.pathname);
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const course = courses.find((c) => c.id === form.courseId);
  const durationMin = toMinutes(form.end) - toMinutes(form.start);
  const input = buildLivePayload(form, Boolean(liveClass));
  const all = validateLiveClass(forValidation(input), now, liveClass?.registered ?? 0);
  const issues: FieldIssue[] = attempt ? [...all.map((i) => ({ field: LIVE_FIELD[i.field], message: i.message })), ...serverIssues] : [];
  const errorFor = (field: keyof typeof LIVE_FIELD) => issues.find((i) => i.field === LIVE_FIELD[field])?.message;
  const agendaTotal = form.agenda.reduce((n, a) => n + (a.minutes || 0), 0);
  // "Cohort only" is not enforced anywhere (it lets in everyone enrolled), so it is offered only to a class that has it.
  const keepsCohort = liveClass?.visibility === 'cohort';
  const teaching = course ? instructors.filter((i) => course.instructorIds.includes(i.id) || i.id === form.instructorId) : instructors;

  const save = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setError(null);
    setServerIssues([]);
    if (all.length) return;
    setSaving(true);
    try {
      const saved = liveClass ? await services.live.update(liveClass.id, input) : await services.live.create(input);
      leaving.current = true;
      // What the API tells learners: a new class, or a new start time — nothing for other edits.
      const moved = liveClass && Date.parse(liveClass.startsAt) !== Date.parse(saved.startsAt);
      toast({
        kind: 'success',
        title: liveClass ? 'Class updated' : 'Class scheduled',
        text: !liveClass ? `${saved.title} · learners of the course are told` : moved ? `${saved.title} · learners are told the new time` : saved.title,
      });
      navigate(`${base}/live/${saved.id}`, { replace: true });
    } catch (err) {
      setServerIssues(serverFieldIssues(err));
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const actions = (
    <div className={styles.formActions}>
      <Button onClick={() => navigate(liveClass ? `${base}/live/${liveClass.id}` : `${base}/live`)} disabled={saving}>
        Cancel
      </Button>
      <Button type="submit" form="live-form" variant="primary" loading={saving} iconStart={<FloppyDisk size={16} />}>
        {liveClass ? 'Save changes' : 'Schedule class'}
      </Button>
    </div>
  );

  return (
    <div className={styles.page}>
      <PageHeader
        back={{ label: liveClass ? liveClass.title : 'Live classes', to: liveClass ? `${base}/live/${liveClass.id}` : `${base}/live` }}
        title={liveClass ? 'Edit live class' : 'Schedule a live class'}
        description={
          liveClass
            ? `${plural(liveClass.registered ?? 0, 'learner')} registered. Learners of the course are told if the start time changes.`
            : template
              ? `A new class, copied from “${template.title}”. Choose its date and time.`
              : 'Learners of the course see it in their schedule straight away and can register.'
        }
      />
      <form id="live-form" className={styles.form} onSubmit={save} noValidate>
        <ErrorSummary issues={issues} attempt={attempt} />
        {error && (
          <InlineMessage kind="error" title="Couldn’t save.">
            {error}
          </InlineMessage>
        )}

        <FormSection id="about" title="About the class" description="What learners see in their schedule and on the class page.">
          <Field label="Title" error={errorFor('title')}>
            <Input
              id="live-title"
              value={form.title}
              onChange={(e) => set('title', e.target.value)}
              placeholder="Quadratic equations: doubt-clearing class"
              autoFocus={!liveClass}
            />
          </Field>
          <Field label="Description" optional hint="A sentence or two on what you’ll cover and what to bring.">
            <Textarea rows={3} value={form.description} onChange={(e) => set('description', e.target.value)} />
          </Field>
          <div className={styles.twoUp}>
            <Field label="Course" error={errorFor('course')}>
              <Select
                id="live-course"
                value={form.courseId}
                disabled={Boolean(liveClass)}
                onChange={(e) => setForm((f) => ({ ...f, courseId: e.target.value, chapterId: '' }))}
              >
                {liveClass && !courses.some((c) => c.id === liveClass.courseId) && (
                  <option value={liveClass.courseId}>{courseTitle ?? 'This class’s course'}</option>
                )}
                {courses.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.title}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="Chapter" optional>
              <Select value={form.chapterId} onChange={(e) => set('chapterId', e.target.value)}>
                <option value="">Whole course</option>
                {course?.chapters.map((c, i) => (
                  <option key={c.id} value={c.id}>
                    {pad2(i + 1)} · {c.title}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="Instructor" error={errorFor('instructor')}>
              <Select id="live-instructor" value={form.instructorId} onChange={(e) => set('instructorId', e.target.value)}>
                {teaching.map((i) => (
                  <option key={i.id} value={i.id}>
                    {i.name}
                  </option>
                ))}
              </Select>
            </Field>
          </div>
        </FormSection>

        <FormSection id="when" title="When" description="India Standard Time. The room opens 15 minutes before the start.">
          <div className={styles.threeUp}>
            <Field label="Date" error={errorFor('startsAt')}>
              <Input id="live-date" type="date" value={form.date} onChange={(e) => set('date', e.target.value)} />
            </Field>
            <Field label="Starts">
              <Input id="live-start" type="time" step={300} value={form.start} onChange={(e) => set('start', e.target.value)} />
            </Field>
            <Field label="Ends" error={errorFor('duration')} hint={durationMin > 0 ? formatDuration(durationMin) : undefined}>
              <Input id="live-end" type="time" step={300} value={form.end} onChange={(e) => set('end', e.target.value)} />
            </Field>
          </div>
        </FormSection>

        <FormSection id="room" title="Room and places" description="Where the class runs and how many learners can join.">
          <ChoiceCards
            legend="Meeting"
            columns={2}
            value={form.meetingKind}
            onChange={(v) => set('meetingKind', v)}
            choices={[
              {
                value: 'room',
                label: 'Built-in live room',
                description: 'Video in the browser and the app. You start and end it; learners who join from here are marked as joined.',
              },
              {
                value: 'external',
                label: 'Outside meeting link',
                description: 'Zoom, Meet or a partner’s room. Learners get the link when the class opens; no attendance is taken.',
              },
            ]}
          />
          {form.meetingKind === 'external' && (
            <Field label="Meeting link" error={errorFor('meeting')}>
              <Input id="live-link" type="url" value={form.link} onChange={(e) => set('link', e.target.value)} placeholder="https://" />
            </Field>
          )}
          <Field
            label="Capacity"
            error={errorFor('capacity')}
            hint={liveClass?.registered ? `${liveClass.registered} already registered` : 'Leave empty for no limit.'}
            className={styles.narrow}
          >
            <Input
              id="live-capacity"
              type="number"
              inputMode="numeric"
              min={1}
              max={1000}
              value={form.capacity}
              onChange={(e) => set('capacity', e.target.value)}
            />
          </Field>
          <ChoiceCards
            legend="Who can join"
            columns={keepsCohort ? 3 : 2}
            value={form.visibility}
            onChange={(v) => set('visibility', v)}
            choices={[
              { value: 'enrolled', label: 'Enrolled learners', description: 'Everyone enrolled in the course.' },
              ...(keepsCohort
                ? [
                    {
                      value: 'cohort' as const,
                      label: 'Cohort (as set before)',
                      description: 'Works the same as enrolled learners: everyone enrolled can join.',
                    },
                  ]
                : []),
              { value: 'public', label: 'Any learner', description: 'Open to every signed-in learner, as a taster.' },
            ]}
          />
        </FormSection>

        <FormSection
          id="agenda"
          title="Agenda"
          description={`${plural(agendaTotal, 'minute')} planned of ${durationMin > 0 ? formatDuration(durationMin) : 'the class'}.`}
        >
          <div id="live-agenda" tabIndex={-1} className={styles.agendaEditor}>
            {form.agenda.map((a, i) => (
              <div key={i} className={styles.agendaRow}>
                <span className={styles.agendaNumber}>{i + 1}</span>
                <Input
                  aria-label={`Agenda item ${i + 1}`}
                  value={a.title}
                  onChange={(e) =>
                    set(
                      'agenda',
                      form.agenda.map((x, j) => (j === i ? { ...x, title: e.target.value } : x)),
                    )
                  }
                  placeholder="Worked chart"
                />
                <span className={styles.minutes}>
                  <Input
                    aria-label={`Minutes for item ${i + 1}`}
                    type="number"
                    inputMode="numeric"
                    min={1}
                    max={240}
                    value={a.minutes}
                    onChange={(e) =>
                      set(
                        'agenda',
                        form.agenda.map((x, j) => (j === i ? { ...x, minutes: Number(e.target.value) } : x)),
                      )
                    }
                  />
                  <span aria-hidden="true">min</span>
                </span>
                <IconButton
                  label={`Remove item ${i + 1}`}
                  icon={<Trash size={16} />}
                  onClick={() =>
                    set(
                      'agenda',
                      form.agenda.filter((_, j) => j !== i),
                    )
                  }
                />
              </div>
            ))}
            {errorFor('agenda') && <p className={styles.error}>{errorFor('agenda')}</p>}
            {form.agenda.length < 8 && (
              <Button size="sm" variant="ghost" iconStart={<Plus size={14} />} onClick={() => set('agenda', [...form.agenda, { title: '', minutes: 10 }])}>
                Add agenda item
              </Button>
            )}
          </div>
        </FormSection>

        <FormSection id="reminders" title="Reminders" description="Sent to registered learners by email and in the app.">
          <div className={styles.reminderChecks}>
            {REMINDER_OPTIONS.map((o) => (
              <Checkbox
                key={o.minutes}
                label={o.label}
                checked={form.reminders.includes(o.minutes)}
                onChange={(e) => set('reminders', e.target.checked ? [...form.reminders, o.minutes] : form.reminders.filter((m) => m !== o.minutes))}
              />
            ))}
          </div>
        </FormSection>

        {!isMobile && actions}
      </form>

      {isMobile && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{actions}</div>}>
          <span />
        </StickyActionBar>
      )}

      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave without saving?"
        description="Your changes to this class haven’t been saved."
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
