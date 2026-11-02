import { useEffect, useRef, useState, type FormEvent } from 'react';
import { Link, useBlocker, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { ArrowLeft, CalendarBlank, FloppyDisk } from '@phosphor-icons/react';
import type { CalendarEvent, CalendarEventInput, CalendarTiming, Course, MilestoneKind, ReminderAudience } from '@syniastrolms/domain';
import { calendarEventEnd, validateCalendarEvent } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { useSession } from '@/providers/SessionProvider';
import { formatDuration, pad2 } from '@/lib/format';
import { ChoiceCards, ErrorSummary, FormSection, type FieldIssue } from '@/components/forms/Forms';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type QuizRow } from '@/services';
import { isDayKey, istKey } from './calendarDates';
import { MILESTONE_LABEL, NOTIFY_OPTIONS, TYPE_META } from './calendarMeta';
import styles from './Calendar.module.css';

type EditableType = 'quiz' | 'milestone' | 'reminder';

export default function EventEditorPage() {
  const { eventId } = useParams();
  const { base, instructorId } = useWorkspace();
  const { user } = useSession();
  const now = useNow();
  const [params] = useSearchParams();
  const query = useAsync(`calendar-editor:${eventId ?? 'new'}`, () =>
    Promise.all([
      eventId ? services.calendar.get(eventId, user.id, instructorId) : Promise.resolve(null),
      services.courses.list({ scopeInstructorId: instructorId, page: 1, pageSize: 100 }),
      services.quizzes.list({ scopeInstructorId: instructorId, status: 'all' }),
    ]).then(([detail, courses, quizzes]) => ({ detail, courses: courses.rows.filter((c) => c.status !== 'archived'), quizzes: quizzes.rows })),
  );
  const detail = query.data?.detail;
  usePageCrumbs(
    detail ? [{ label: detail.event.title, to: `${base}/calendar/${detail.event.id}` }, { label: 'Edit' }] : [{ label: eventId ? 'Edit event' : 'Add event' }],
  );

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'Event not found' : 'The form didn’t load'}
          actions={
            notFound ? (
              <LinkButton to={`${base}/calendar`} iconStart={<ArrowLeft size={16} />}>
                Back to the calendar
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
        <Skeleton height={560} radius="var(--r-lg)" />
      </div>
    );
  }
  if (detail && (detail.event.source || calendarEventEnd(detail.event).getTime() <= now.getTime())) {
    const source = detail.event.source;
    return (
      <div className={styles.page}>
        <StateMessage
          icon={<CalendarBlank size={26} />}
          title={source ? `This ${source.kind === 'live-class' ? 'live class' : 'deadline'} is changed on its own page` : 'This event has already happened'}
          actions={
            <>
              <LinkButton to={`${base}/calendar/${detail.event.id}`} iconStart={<ArrowLeft size={16} />}>
                Back to the event
              </LinkButton>
              {source && (
                <LinkButton variant="primary" to={source.kind === 'live-class' ? `${base}/live/${source.id}/edit` : `${base}/assignments/${source.id}`}>
                  {source.kind === 'live-class' ? 'Edit the class' : 'Edit the assignment'}
                </LinkButton>
              )}
            </>
          }
        >
          {source ? 'The calendar shows it so everything is in one place.' : 'Past events stay on the calendar as a record. Add a new event instead.'}
        </StateMessage>
      </div>
    );
  }
  return (
    <Editor
      key={detail?.event.id ?? 'new'}
      event={detail?.event ?? null}
      courses={query.data.courses}
      quizzes={query.data.quizzes}
      base={base}
      ownerId={user.id}
      dateParam={params.get('date')}
      typeParam={params.get('type')}
      courseParam={params.get('course')}
    />
  );
}

const FIELD: Record<string, string> = {
  type: 'event-type',
  title: 'event-title',
  course: 'event-course',
  quiz: 'event-quiz',
  milestone: 'event-milestone',
  chapter: 'event-chapter',
  startsAt: 'event-date',
  duration: 'event-end',
};

const toMinutes = (hhmm: string) => {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
};

const endAfter = (start: string, minutes: number) => {
  const total = toMinutes(start) + minutes;
  return `${pad2(Math.floor(total / 60) % 24)}:${pad2(total % 60)}`;
};

const isEditable = (value: string | null): value is EditableType => value === 'quiz' || value === 'milestone' || value === 'reminder';

interface EditorProps {
  event: CalendarEvent | null;
  courses: Course[];
  quizzes: QuizRow[];
  base: string;
  ownerId: string;
  dateParam: string | null;
  typeParam: string | null;
  courseParam: string | null;
}

function Editor({ event, courses, quizzes, base, ownerId, dateParam, typeParam, courseParam }: EditorProps) {
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const today = istKey(now);
  const startTime = event && event.timing !== 'all-day' ? event.startsAt.slice(11, 16) : '10:00';
  const initial = {
    type: (event?.type as EditableType | undefined) ?? (isEditable(typeParam) ? typeParam : 'reminder'),
    title: event?.title ?? '',
    description: event?.description ?? '',
    courseId: event?.courseId ?? (courses.some((c) => c.id === courseParam) ? courseParam! : ''),
    chapterId: event?.chapterId ?? '',
    quizId: event?.quizId ?? '',
    milestone: event?.milestone ?? ('' as MilestoneKind | ''),
    audience: event?.audience ?? ('me' as ReminderAudience),
    quizTiming: event?.type === 'quiz' && event.timing === 'timed' ? ('timed' as const) : ('moment' as const),
    allDay: event?.type === 'reminder' ? event.timing === 'all-day' : false,
    date: event ? istKey(event.startsAt) : isDayKey(dateParam) && dateParam >= today ? dateParam : today,
    start: startTime,
    end: endAfter(startTime, event?.timing === 'timed' ? (event.durationMin ?? 60) : 60),
    notify: event ? (event.notifyMin === undefined ? '' : String(event.notifyMin)) : '60',
  };

  const [form, setForm] = useState(initial);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
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
  const courseQuizzes = quizzes.filter((q) => q.quiz.courseId === form.courseId);
  const quiz = courseQuizzes.find((q) => q.quiz.id === form.quizId);
  const timing: CalendarTiming = form.type === 'milestone' ? 'all-day' : form.type === 'quiz' ? form.quizTiming : form.allDay ? 'all-day' : 'moment';
  const durationMin = timing === 'timed' && form.end ? toMinutes(form.end) - toMinutes(form.start) : undefined;
  const input: CalendarEventInput = {
    type: form.type,
    title: form.title.trim(),
    description: form.description.trim() || undefined,
    timing,
    startsAt: `${form.date}T${timing === 'all-day' ? '00:00' : form.start}:00+05:30`,
    durationMin,
    courseId: form.courseId || undefined,
    chapterId: form.chapterId || undefined,
    quizId: form.type === 'quiz' ? form.quizId || undefined : undefined,
    milestone: form.type === 'milestone' ? form.milestone || undefined : undefined,
    audience: form.type === 'reminder' ? form.audience : undefined,
    notifyMin: form.notify === '' ? undefined : Number(form.notify),
  };
  const all = validateCalendarEvent(input, now);
  const issues: FieldIssue[] = attempt ? all.map((i) => ({ field: FIELD[i.field], message: i.message })) : [];
  const errorFor = (field: string) => issues.find((i) => i.field === FIELD[field])?.message;
  const courseOptional = form.type === 'reminder' && form.audience === 'me';

  const save = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setError(null);
    if (all.length) return;
    setSaving(true);
    try {
      const saved = event ? await services.calendar.update(event.id, input) : await services.calendar.create(input, ownerId);
      leaving.current = true;
      toast({ kind: 'success', title: event ? 'Event updated' : 'Added to the calendar', text: saved.title });
      navigate(`${base}/calendar/${saved.id}?date=${istKey(saved.startsAt)}`, { replace: true });
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const cancelTo = event ? `${base}/calendar/${event.id}?date=${istKey(event.startsAt)}` : `${base}/calendar${dateParam ? `?date=${dateParam}` : ''}`;
  const actions = (
    <div className={styles.formActions}>
      <Button onClick={() => navigate(cancelTo)} disabled={saving}>
        Cancel
      </Button>
      <Button type="submit" form="event-form" variant="primary" loading={saving} iconStart={<FloppyDisk size={16} />}>
        {event ? 'Save changes' : 'Add to calendar'}
      </Button>
    </div>
  );

  const titlePlaceholder =
    form.type === 'quiz' ? 'Chapter 3 checkpoint' : form.type === 'milestone' ? 'October cohort starts' : 'Approve pricing for the October cohorts';

  return (
    <div className={styles.page}>
      <PageHeader
        back={{ label: event ? event.title : 'Calendar', to: cancelTo }}
        title={event ? `Edit ${TYPE_META[event.type].label.toLowerCase()}` : 'Add an event'}
        description={
          event
            ? 'Changes show on the calendar straight away. Learners who can see the event are told about a new date or time.'
            : 'Quiz windows, course milestones and reminders. Live classes and assignment deadlines appear on the calendar by themselves.'
        }
      />
      <form id="event-form" className={styles.form} onSubmit={save} noValidate>
        <ErrorSummary issues={issues} attempt={attempt} />
        {error && (
          <InlineMessage kind="error" title="Couldn’t save.">
            {error}
          </InlineMessage>
        )}

        <FormSection id="what" title="What" description="The kind of event decides who sees it and what it links to.">
          {event ? (
            <p className={styles.fixedType}>
              {TYPE_META[event.type].label} <span className={styles.muted}>· the type can’t be changed after it’s added</span>
            </p>
          ) : (
            <div id="event-type" tabIndex={-1} className={styles.typeChoice}>
              <ChoiceCards<EditableType>
                legend="Event type"
                columns={3}
                value={form.type}
                onChange={(v) => setForm((f) => ({ ...f, type: v, quizTiming: 'moment' }))}
                choices={[
                  { value: 'reminder', label: 'Reminder', description: 'A note for yourself, or a nudge to a course’s learners.' },
                  { value: 'milestone', label: 'Course milestone', description: 'A cohort start, a chapter opening, a launch date.' },
                  { value: 'quiz', label: 'Quiz window', description: 'A deadline for a quiz, or a time to sit it together.' },
                ]}
              />
              <p className={styles.muted}>
                Scheduling a live class? Use <Link to={`${base}/live/new`}>Schedule a live class</Link>. Assignment deadlines are set on each{' '}
                <Link to={`${base}/assignments`}>assignment</Link>.
              </p>
            </div>
          )}
          <Field label="Title" error={errorFor('title')}>
            <Input id="event-title" value={form.title} onChange={(e) => set('title', e.target.value)} placeholder={titlePlaceholder} autoFocus={!event} />
          </Field>
          <Field label="Notes" optional hint={form.type === 'reminder' && form.audience === 'me' ? 'Only you see these.' : 'Shown with the event.'}>
            <Textarea rows={3} value={form.description} onChange={(e) => set('description', e.target.value)} />
          </Field>
        </FormSection>

        <FormSection
          id="course"
          title={form.type === 'reminder' ? 'Who it’s for' : 'Course'}
          description={
            form.type === 'reminder'
              ? 'Keep it to yourself, or remind the learners of a course at the same time.'
              : 'Learners of the course see the event in their schedule.'
          }
        >
          {form.type === 'reminder' && (
            <ChoiceCards<ReminderAudience>
              legend="Reminder for"
              hideLegend
              columns={2}
              value={form.audience}
              onChange={(v) => set('audience', v)}
              choices={[
                { value: 'me', label: 'Just me', description: 'A private note on your calendar.' },
                { value: 'learners', label: 'Learners of a course', description: 'They get the reminder in the app and by email.' },
              ]}
            />
          )}
          <div className={styles.twoUp}>
            <Field label="Course" optional={courseOptional} error={errorFor('course')}>
              <Select id="event-course" value={form.courseId} onChange={(e) => setForm((f) => ({ ...f, courseId: e.target.value, chapterId: '', quizId: '' }))}>
                <option value="">{courseOptional ? 'Not about a course' : 'Choose a course'}</option>
                {courses.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.title}
                    {c.status === 'draft' ? ' (draft)' : ''}
                  </option>
                ))}
              </Select>
            </Field>
            {form.type === 'milestone' && (
              <Field label="Milestone" error={errorFor('milestone')}>
                <Select id="event-milestone" value={form.milestone} onChange={(e) => set('milestone', e.target.value as MilestoneKind)}>
                  <option value="">Choose a milestone</option>
                  {(Object.keys(MILESTONE_LABEL) as MilestoneKind[]).map((m) => (
                    <option key={m} value={m}>
                      {MILESTONE_LABEL[m]}
                    </option>
                  ))}
                </Select>
              </Field>
            )}
            {(form.type === 'quiz' || (form.type === 'milestone' && form.milestone === 'chapter-release')) && (
              <Field label="Chapter" optional={form.type === 'quiz'} error={errorFor('chapter')}>
                <Select id="event-chapter" value={form.chapterId} disabled={!course} onChange={(e) => set('chapterId', e.target.value)}>
                  <option value="">{course ? (form.type === 'quiz' ? 'Whole course' : 'Choose a chapter') : 'Choose a course first'}</option>
                  {course?.chapters.map((c, i) => (
                    <option key={c.id} value={c.id}>
                      {pad2(i + 1)} · {c.title}
                    </option>
                  ))}
                </Select>
              </Field>
            )}
            {form.type === 'quiz' && (
              <Field label="Quiz" error={errorFor('quiz')} hint={course && courseQuizzes.length === 0 ? 'This course has no quizzes yet.' : undefined}>
                <Select
                  id="event-quiz"
                  value={form.quizId}
                  disabled={!course || courseQuizzes.length === 0}
                  onChange={(e) => {
                    const picked = courseQuizzes.find((q) => q.quiz.id === e.target.value);
                    setForm((f) => ({
                      ...f,
                      quizId: e.target.value,
                      chapterId: picked?.quiz.chapterId ?? f.chapterId,
                      title: f.title || picked?.quiz.title || '',
                    }));
                  }}
                >
                  <option value="">{course ? 'Choose a quiz' : 'Choose a course first'}</option>
                  {courseQuizzes.map((q) => (
                    <option key={q.quiz.id} value={q.quiz.id}>
                      {q.quiz.title}
                      {q.quiz.status === 'draft' ? ' (draft)' : ''}
                    </option>
                  ))}
                </Select>
              </Field>
            )}
          </div>
          {quiz?.quiz.status === 'draft' && (
            <InlineMessage kind="warn" title="This quiz is still a draft.">
              Learners can’t take it until it’s published. <Link to={`${base}/quizzes/${quiz.quiz.id}`}>Open the quiz</Link>
            </InlineMessage>
          )}
          {course?.status === 'draft' && form.type !== 'milestone' && (
            <InlineMessage kind="info">{course.title} isn’t published yet, so no learners are enrolled to see this.</InlineMessage>
          )}
        </FormSection>

        <FormSection id="when" title="When" description="India Standard Time.">
          {form.type === 'quiz' && (
            <ChoiceCards<'moment' | 'timed'>
              legend="How learners take it"
              columns={2}
              value={form.quizTiming}
              onChange={(v) => set('quizTiming', v)}
              choices={[
                { value: 'moment', label: 'By a deadline', description: 'Learners take it any time before it closes.' },
                { value: 'timed', label: 'Sit it together', description: 'The quiz opens for everyone for a set time.' },
              ]}
            />
          )}
          <div className={styles.threeUp}>
            <Field label="Date" error={errorFor('startsAt')}>
              <Input id="event-date" type="date" min={today} value={form.date} onChange={(e) => set('date', e.target.value)} />
            </Field>
            {timing !== 'all-day' && (
              <Field label={form.type === 'quiz' && timing === 'moment' ? 'Closes at' : timing === 'timed' ? 'Starts' : 'Time'}>
                <Input type="time" step={300} value={form.start} onChange={(e) => set('start', e.target.value)} />
              </Field>
            )}
            {timing === 'timed' && (
              <Field label="Ends" error={errorFor('duration')} hint={durationMin && durationMin > 0 ? formatDuration(durationMin) : undefined}>
                <Input id="event-end" type="time" step={300} value={form.end} onChange={(e) => set('end', e.target.value)} />
              </Field>
            )}
          </div>
          {form.type === 'reminder' && <Checkbox label="All day" checked={form.allDay} onChange={(e) => set('allDay', e.target.checked)} />}
          <Field
            label="Notification"
            className={styles.notify}
            hint={form.type === 'reminder' && form.audience === 'me' ? 'Sent to you in the app.' : 'Sent to you and to learners who can see the event.'}
          >
            <Select value={form.notify} onChange={(e) => set('notify', e.target.value)}>
              <option value="">No notification</option>
              {NOTIFY_OPTIONS.filter((o) => timing !== 'all-day' || o.minutes === 1440).map((o) => (
                <option key={o.minutes} value={o.minutes}>
                  {o.label}
                </option>
              ))}
            </Select>
          </Field>
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
        description="Your changes to this event haven’t been saved."
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
