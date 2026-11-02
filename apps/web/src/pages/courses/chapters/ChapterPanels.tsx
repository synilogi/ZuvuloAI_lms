import { useEffect, useState, type FormEvent } from 'react';
import { ArrowsDownUp, Trash } from '@phosphor-icons/react';
import type { Chapter, ChapterInput, ContentStatus, Course } from '@syniastrolms/domain';
import { chapterDurationMin } from '@syniastrolms/domain';
import { formatCount, formatDuration, pad2, plural } from '@/lib/format';
import { ChoiceCards, ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { AdaptivePanel } from '@/components/overlays/AdaptivePanel';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Modal } from '@/components/overlays/Overlay';
import { services } from '@/services';
import styles from './Chapters.module.css';

const STATUS_CHOICES: { value: ContentStatus; label: string; description: string }[] = [
  { value: 'published', label: 'Published', description: 'Enrolled learners see this chapter and its published lessons.' },
  { value: 'draft', label: 'Draft', description: 'Hidden from learners while you build it.' },
];

/* ─── Add / edit ───────────────────────────────────────────────────────── */

interface ChapterFormProps {
  course: Course;
  chapter?: Chapter;
  onClose: () => void;
  onSaved: (chapter: Chapter, created: boolean) => void;
}

/** Add or edit a chapter. A drawer on desktop, a bottom sheet on phones. */
export function ChapterForm({ course, chapter, onClose, onSaved }: ChapterFormProps) {
  const index = chapter ? course.chapters.findIndex((c) => c.id === chapter.id) : -1;
  const initial: ChapterInput & { position: number } = {
    title: chapter?.title ?? '',
    summary: chapter?.summary ?? '',
    objective: chapter?.objective ?? '',
    estimatedMin: chapter?.estimatedMin,
    status: chapter?.status ?? 'draft',
    position: chapter ? index + 1 : course.chapters.length + 1,
  };
  const [form, setForm] = useState(initial);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmDiscard, setConfirmDiscard] = useState(false);
  const dirty = JSON.stringify(form) !== JSON.stringify(initial);
  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) => setForm((f) => ({ ...f, [key]: value }));
  const lessonMinutes = chapter ? chapterDurationMin(chapter) : 0;

  const validate = (): FieldIssue[] => {
    const issues: FieldIssue[] = [];
    const title = form.title.trim();
    if (!title) issues.push({ field: 'chapter-title', message: 'Give the chapter a title.' });
    else if (title.length < 3) issues.push({ field: 'chapter-title', message: 'The title needs at least 3 characters.' });
    else if (title.length > 80) issues.push({ field: 'chapter-title', message: 'Keep the title under 80 characters.' });
    else if (course.chapters.some((c) => c.id !== chapter?.id && c.title.trim().toLowerCase() === title.toLowerCase()))
      issues.push({ field: 'chapter-title', message: 'Another chapter in this course already has this title.' });
    if ((form.summary ?? '').length > 200) issues.push({ field: 'chapter-summary', message: 'Keep the description under 200 characters.' });
    if ((form.objective ?? '').length > 160) issues.push({ field: 'chapter-objective', message: 'Keep the objective under 160 characters.' });
    if (form.estimatedMin !== undefined && (!Number.isInteger(form.estimatedMin) || form.estimatedMin < 5 || form.estimatedMin > 1200))
      issues.push({ field: 'chapter-duration', message: 'Estimated duration must be between 5 and 1,200 minutes.' });
    if (form.status === 'published' && chapter && chapter.lessons.length === 0)
      issues.push({ field: 'chapter-status', message: 'Add at least one lesson before publishing this chapter.' });
    if (form.status === 'published' && !chapter) issues.push({ field: 'chapter-status', message: 'New chapters start as drafts — add lessons, then publish.' });
    return issues;
  };
  const issues = attempt ? validate() : [];
  const errorFor = (field: string) => issues.find((i) => i.field === field)?.message;

  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const submit = async (e?: FormEvent) => {
    e?.preventDefault();
    setAttempt((a) => a + 1);
    setError(null);
    if (validate().length) return;
    setSaving(true);
    const { position, ...input } = form;
    try {
      if (chapter) {
        const saved = await services.chapters.update(course.id, chapter.id, input);
        if (position !== index + 1) await services.chapters.move(course.id, chapter.id, position);
        onSaved(saved, false);
      } else {
        onSaved(await services.chapters.create(course.id, input, position), true);
      }
    } catch (err) {
      setError((err as Error).message);
      setSaving(false);
    }
  };

  const requestClose = () => (dirty && !saving ? setConfirmDiscard(true) : onClose());
  const positions = chapter ? course.chapters.length : course.chapters.length + 1;

  return (
    <>
      <AdaptivePanel
        open
        onClose={requestClose}
        eyebrow={chapter ? `Chapter ${pad2(index + 1)}` : course.title}
        title={chapter ? 'Edit chapter' : 'Add a chapter'}
        width={520}
        footer={
          <>
            <Button onClick={requestClose} disabled={saving}>
              Cancel
            </Button>
            <Button type="submit" form="chapter-form" variant="primary" loading={saving}>
              {chapter ? 'Save chapter' : 'Add chapter'}
            </Button>
          </>
        }
      >
        <form id="chapter-form" className={styles.form} onSubmit={submit} noValidate>
          <ErrorSummary issues={issues} attempt={attempt} />
          {error && (
            <InlineMessage kind="error" title="Couldn’t save.">
              {error}
            </InlineMessage>
          )}
          <Field label="Chapter title" error={errorFor('chapter-title')} hint={`${form.title.trim().length}/80`}>
            <Input id="chapter-title" value={form.title} onChange={(e) => set('title', e.target.value)} placeholder="Quadratic equations" autoFocus />
          </Field>
          <Field label="Short description" optional error={errorFor('chapter-summary')} hint="One line under the title in the curriculum.">
            <Textarea
              id="chapter-summary"
              rows={2}
              value={form.summary}
              onChange={(e) => set('summary', e.target.value)}
              placeholder="Solving equations in one variable, with word problems."
            />
          </Field>
          <Field label="Learning objective" optional error={errorFor('chapter-objective')} hint="What a learner can do after this chapter. Start with a verb.">
            <Input
              id="chapter-objective"
              value={form.objective}
              onChange={(e) => set('objective', e.target.value)}
              placeholder="Solve a linear equation and check the answer"
            />
          </Field>
          <Field
            label="Estimated duration"
            optional
            error={errorFor('chapter-duration')}
            hint={
              lessonMinutes
                ? `Lessons currently add up to ${formatDuration(lessonMinutes)}, which is what learners see.`
                : 'Minutes — used until lessons are added.'
            }
          >
            <Input
              id="chapter-duration"
              type="number"
              inputMode="numeric"
              min={5}
              max={1200}
              value={form.estimatedMin ?? ''}
              onChange={(e) => set('estimatedMin', e.target.value === '' ? undefined : Number(e.target.value))}
            />
          </Field>
          <div id="chapter-status" tabIndex={-1}>
            <ChoiceCards
              legend="Visibility"
              columns={2}
              value={form.status}
              onChange={(v) => set('status', v)}
              choices={STATUS_CHOICES}
              error={errorFor('chapter-status')}
            />
          </div>
          <Field label={chapter ? 'Position in the course' : 'Add it'}>
            <Select value={form.position} onChange={(e) => set('position', Number(e.target.value))}>
              {Array.from({ length: positions }, (_, i) => {
                const others = course.chapters.filter((c) => c.id !== chapter?.id);
                const label = i === 0 ? 'First' : `After ${pad2(i)} · ${others[i - 1]?.title ?? ''}`;
                return (
                  <option key={i} value={i + 1}>
                    {!chapter && i === positions - 1 ? `At the end · after ${others[i - 1]?.title ?? 'the last chapter'}` : label}
                  </option>
                );
              })}
            </Select>
          </Field>
        </form>
      </AdaptivePanel>
      <Modal
        open={confirmDiscard}
        onClose={() => setConfirmDiscard(false)}
        title="Discard your changes?"
        description={chapter ? `Edits to “${chapter.title}” haven’t been saved.` : 'This chapter hasn’t been added yet.'}
        footer={
          <>
            <Button onClick={() => setConfirmDiscard(false)}>Keep editing</Button>
            <Button variant="danger" onClick={onClose}>
              Discard
            </Button>
          </>
        }
      />
    </>
  );
}

/* ─── Delete ───────────────────────────────────────────────────────────── */

export function DeleteChapterDialog({
  course,
  chapter,
  learners,
  onClose,
  onDeleted,
}: {
  course: Course;
  chapter: Chapter;
  learners: number;
  onClose: () => void;
  onDeleted: (lessonsRemoved: number) => void;
}) {
  const hasLessons = chapter.lessons.length > 0;
  const affectsLearners = hasLessons && chapter.status === 'published' && learners > 0;
  return (
    <ConfirmDialog
      open
      onClose={onClose}
      onConfirm={async () => onDeleted((await services.chapters.remove(course.id, chapter.id)).lessonsRemoved)}
      tone="danger"
      icon={<Trash size={20} />}
      title="Delete this chapter?"
      description={chapter.title}
      confirmLabel="Delete chapter"
      acknowledge={affectsLearners ? 'I understand learners lose progress recorded on these lessons' : undefined}
    >
      <ul className={styles.impact}>
        <li>{hasLessons ? `${plural(chapter.lessons.length, 'lesson')} inside it will be deleted too.` : 'It has no lessons, so nothing else is removed.'}</li>
        {affectsLearners && <li>{formatCount(learners)} enrolled learners will no longer see it, and their progress on its lessons is removed.</li>}
        <li>Chapters after it move up one place. This can’t be undone.</li>
      </ul>
      {hasLessons && <p className={styles.note}>To keep the lessons, duplicate the chapter or move its lessons first.</p>}
    </ConfirmDialog>
  );
}

/* ─── Move to position ─────────────────────────────────────────────────── */

export function MoveChapterDialog({
  course,
  chapter,
  onClose,
  onMoved,
}: {
  course: Course;
  chapter: Chapter;
  onClose: () => void;
  onMoved: (position: number) => void;
}) {
  const current = course.chapters.findIndex((c) => c.id === chapter.id) + 1;
  const [position, setPosition] = useState(current);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const others = course.chapters.filter((c) => c.id !== chapter.id);

  const move = async () => {
    setBusy(true);
    setError(null);
    try {
      await services.chapters.move(course.id, chapter.id, position);
      onMoved(position);
    } catch (e) {
      setError((e as Error).message);
      setBusy(false);
    }
  };

  return (
    <Modal
      open
      onClose={onClose}
      icon={<ArrowsDownUp size={20} />}
      title="Move chapter"
      description={chapter.title}
      footer={
        <>
          <Button onClick={onClose} disabled={busy}>
            Cancel
          </Button>
          <Button variant="primary" onClick={move} loading={busy} disabled={position === current}>
            Move to position {position}
          </Button>
        </>
      }
    >
      <ol className={styles.positions} role="radiogroup" aria-label="New position">
        {Array.from({ length: course.chapters.length }, (_, i) => {
          const pos = i + 1;
          const neighbour = pos === 1 ? 'Before everything' : `After ${others[pos - 2]?.title}`;
          return (
            <li key={pos}>
              <label className={styles.position}>
                <input type="radio" name="chapter-position" checked={position === pos} onChange={() => setPosition(pos)} />
                <span className={styles.positionIndex}>{pad2(pos)}</span>
                <span className={styles.positionText}>
                  {neighbour}
                  {pos === current && <span className={styles.note}> · current position</span>}
                </span>
              </label>
            </li>
          );
        })}
      </ol>
      {error && (
        <InlineMessage kind="error" title="The chapter didn’t move.">
          {error}
        </InlineMessage>
      )}
    </Modal>
  );
}
