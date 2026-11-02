import { useLayoutEffect, useRef, useState, type ReactNode } from 'react';
import { FilePdf, ListBullets, ListNumbers, LinkSimple, Play, Plus, Quotes, TextB, TextHOne, TextItalic, X } from '@phosphor-icons/react';
import { useParams } from 'react-router-dom';
import type { LessonContent, LessonType } from '@syniastrolms/domain';
import { readingMinutes } from '@syniastrolms/domain';
import { formatClock, plural } from '@/lib/format';
import { ChoiceCards, Switch } from '@/components/forms/Forms';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Field, Input, Textarea } from '@/components/ui/Field/Field';
import { FileCard, MediaDrop } from '@/components/forms/Upload';
import styles from './LessonEditor.module.css';

/* ─── Editors by type ──────────────────────────────────────────────────── */

interface EditorProps {
  type: LessonType;
  content: LessonContent;
  onChange: (content: LessonContent) => void;
  errorFor: (field: string) => string | undefined;
  onUseDuration: (minutes: number) => void;
  base: string;
  title: string;
}

export function ContentEditor(props: EditorProps) {
  switch (props.type) {
    case 'video':
      return <VideoEditor {...props} />;
    case 'reading':
    case 'practice':
      return <ArticleEditor {...props} />;
    case 'document':
      return <DocumentEditor {...props} />;
    case 'assessment':
      return <QuizEditor {...props} />;
    case 'assignment':
      return <AssignmentEditor {...props} />;
    case 'live':
      return <LiveEditor {...props} />;
  }
}

function parseClock(text: string) {
  const parts = text.split(':').map((p) => Number(p));
  if (parts.some((n) => Number.isNaN(n))) return undefined;
  return parts.length === 3 ? parts[0] * 3600 + parts[1] * 60 + parts[2] : parts.length === 2 ? parts[0] * 60 + parts[1] : parts[0];
}

function VideoEditor({ content, onChange, errorFor, onUseDuration, title }: EditorProps) {
  const video = content.video ?? { captions: false, markers: [] };
  const set = (patch: Partial<typeof video>) => onChange({ ...content, video: { ...video, ...patch } });
  const [replacing, setReplacing] = useState(false);

  return (
    <div className={styles.editorBlock}>
      {video.file && !replacing ? (
        <>
          <div className={styles.videoFrame} aria-label={`Video preview: ${title}`} role="img">
            <span className={styles.playBadge} aria-hidden="true">
              <Play size={22} weight="fill" />
            </span>
            {video.durationSec && <span className={styles.videoDuration}>{formatClock(video.durationSec)}</span>}
          </div>
          <FileCard
            icon={<Play size={18} />}
            file={video.file}
            detail={video.durationSec ? `${formatClock(video.durationSec)} · HD` : 'Processed'}
            onReplace={() => setReplacing(true)}
            onRemove={() => set({ file: undefined, durationSec: undefined, markers: [] })}
          />
          {video.durationSec && (
            <button type="button" className={styles.inlineAction} onClick={() => onUseDuration(Math.max(1, Math.round((video.durationSec ?? 0) / 60)))}>
              Use the video length ({Math.round(video.durationSec / 60)} min) as the lesson duration
            </button>
          )}
        </>
      ) : (
        <MediaDrop
          id="lesson-media"
          accept="video/*"
          label={replacing ? 'Replace the video' : 'Add the lesson video'}
          hint="MP4 or MOV up to 4 GB · 1080p recommended"
          icon={<Play size={18} />}
          error={errorFor('lesson-media')}
          onDone={(file) => {
            setReplacing(false);
            const durationSec = 780 + Math.round(Math.random() * 900);
            set({ file, durationSec, markers: [{ atSec: 0, title: 'Introduction' }] });
          }}
        />
      )}

      <Switch
        checked={video.captions}
        onChange={(captions) => set({ captions })}
        label="Captions"
        description={
          video.captions
            ? 'Auto-generated English captions are on. Learners can turn them off in the player.'
            : 'Learners who study with sound off can’t follow this video.'
        }
        disabled={!video.file}
      />

      <div>
        <p className={styles.blockLabel}>Chapters in the video</p>
        <p className={styles.blockHint}>Timestamps let learners jump to a section and show as marks on the progress bar.</p>
        <ol className={styles.markers}>
          {video.markers.map((marker, i) => (
            <li key={i} className={styles.marker}>
              <Input
                aria-label={`Marker ${i + 1} time`}
                className={styles.markerTime}
                defaultValue={formatClock(marker.atSec)}
                onBlur={(e) => {
                  const at = parseClock(e.target.value);
                  if (at !== undefined) set({ markers: video.markers.map((m, j) => (j === i ? { ...m, atSec: at } : m)).sort((a, b) => a.atSec - b.atSec) });
                }}
              />
              <Input
                aria-label={`Marker ${i + 1} title`}
                value={marker.title}
                onChange={(e) => set({ markers: video.markers.map((m, j) => (j === i ? { ...m, title: e.target.value } : m)) })}
              />
              <IconButton
                size="sm"
                label={`Remove marker ${marker.title}`}
                icon={<X size={14} />}
                onClick={() => set({ markers: video.markers.filter((_, j) => j !== i) })}
              />
            </li>
          ))}
        </ol>
        <Button
          size="sm"
          variant="ghost"
          iconStart={<Plus size={14} />}
          disabled={!video.file}
          onClick={() => {
            const last = video.markers[video.markers.length - 1]?.atSec ?? 0;
            set({ markers: [...video.markers, { atSec: Math.min((video.durationSec ?? 600) - 30, last + 240), title: 'New section' }] });
          }}
        >
          Add marker
        </Button>
      </div>
    </div>
  );
}

const TOOLS: { id: string; label: string; icon: ReactNode; wrap?: [string, string]; line?: string }[] = [
  { id: 'h', label: 'Heading', icon: <TextHOne size={16} />, line: '## ' },
  { id: 'b', label: 'Bold', icon: <TextB size={16} />, wrap: ['**', '**'] },
  { id: 'i', label: 'Italic', icon: <TextItalic size={16} />, wrap: ['_', '_'] },
  { id: 'q', label: 'Quote', icon: <Quotes size={16} />, line: '> ' },
  { id: 'ul', label: 'Bulleted list', icon: <ListBullets size={16} />, line: '- ' },
  { id: 'ol', label: 'Numbered list', icon: <ListNumbers size={16} />, line: '1. ' },
  { id: 'a', label: 'Link', icon: <LinkSimple size={16} />, wrap: ['[', '](https://)'] },
];

function ArticleEditor({ type, content, onChange, errorFor, onUseDuration }: EditorProps) {
  const body = content.article?.body ?? '';
  const ref = useRef<HTMLTextAreaElement>(null);
  const pendingCursor = useRef<number | null>(null);
  const words = body.trim() ? body.trim().split(/\s+/).length : 0;
  const set = (next: string) => onChange({ ...content, article: { body: next } });

  // Restore the caret after a formatting change re-renders the text, before the next keystroke lands.
  useLayoutEffect(() => {
    const el = ref.current;
    if (el && pendingCursor.current !== null) {
      el.focus();
      el.setSelectionRange(pendingCursor.current, pendingCursor.current);
      pendingCursor.current = null;
    }
  }, [body]);

  const apply = (tool: (typeof TOOLS)[number]) => {
    const el = ref.current;
    if (!el) return;
    const { selectionStart: s, selectionEnd: e } = el;
    const selected = body.slice(s, e);
    let next: string;
    let cursor: number;
    if (tool.wrap) {
      next = body.slice(0, s) + tool.wrap[0] + (selected || tool.label.toLowerCase()) + tool.wrap[1] + body.slice(e);
      cursor = s + tool.wrap[0].length + (selected || tool.label.toLowerCase()).length;
    } else {
      const lineStart = body.lastIndexOf('\n', s - 1) + 1;
      next = body.slice(0, lineStart) + tool.line + body.slice(lineStart);
      cursor = e + (tool.line?.length ?? 0);
    }
    pendingCursor.current = cursor;
    set(next);
  };

  return (
    <div className={styles.editorBlock}>
      <div className={styles.writer}>
        <div className={styles.toolbar} role="toolbar" aria-label="Formatting">
          {TOOLS.map((tool) => (
            <IconButton key={tool.id} size="sm" label={tool.label} icon={tool.icon} onMouseDown={(e) => e.preventDefault()} onClick={() => apply(tool)} />
          ))}
          <span className={styles.wordCount}>
            {words.toLocaleString('en-IN')} words · {readingMinutes(body)} min read
          </span>
        </div>
        <Field label={type === 'practice' ? 'Exercise instructions' : 'Article'} hideLabel error={errorFor('lesson-body')}>
          <Textarea
            id="lesson-body"
            ref={ref}
            className={styles.writerArea}
            value={body}
            onChange={(e) => set(e.target.value)}
            placeholder={
              type === 'practice'
                ? '## The exercise\n\nDescribe the chart to use, the steps to follow and what to note down…'
                : '## A heading\n\nWrite the lesson. Use headings, lists and quotes to give it rhythm…'
            }
          />
        </Field>
      </div>
      {words > 0 && (
        <button type="button" className={styles.inlineAction} onClick={() => onUseDuration(readingMinutes(body))}>
          Use the reading time ({readingMinutes(body)} min) as the lesson duration
        </button>
      )}
    </div>
  );
}

function DocumentEditor({ content, onChange, errorFor }: EditorProps) {
  const doc = content.document ?? { downloadable: true };
  const set = (patch: Partial<typeof doc>) => onChange({ ...content, document: { ...doc, ...patch } });
  return (
    <div className={styles.editorBlock}>
      {doc.file ? (
        <FileCard
          icon={<FilePdf size={18} />}
          file={doc.file}
          detail={`${doc.pages ?? '—'} pages`}
          onRemove={() => set({ file: undefined, pages: undefined })}
        />
      ) : (
        <MediaDrop
          id="lesson-media"
          accept="application/pdf"
          label="Attach the PDF"
          hint="PDF up to 50 MB · worksheets, chart tables, reading packs"
          icon={<FilePdf size={18} />}
          error={errorFor('lesson-media')}
          onDone={(file) => set({ file, pages: 6 + Math.round(Math.random() * 18) })}
        />
      )}
      <Switch
        checked={doc.downloadable}
        onChange={(downloadable) => set({ downloadable })}
        label="Allow download"
        description="Learners can save the PDF to read offline. Turn off for exam papers."
      />
    </div>
  );
}

function QuizEditor({ content, onChange, base }: EditorProps) {
  const { courseId, lessonId } = useParams();
  const quiz = content.quiz ?? { questions: 0, passMark: 70, attempts: 2 };
  const set = (patch: Partial<typeof quiz>) => onChange({ ...content, quiz: { ...quiz, ...patch } });

  if (quiz.quizId) {
    const rules = [
      `Pass mark ${quiz.passMark}%`,
      quiz.attempts ? plural(quiz.attempts, 'attempt') : 'Unlimited attempts',
      quiz.timeLimitMin ? `${quiz.timeLimitMin} min limit` : 'No time limit',
    ];
    return (
      <div className={styles.editorBlock}>
        <div className={styles.linked}>
          <p className={styles.linkedTitle}>{quiz.questions ? plural(quiz.questions, 'question') : 'No questions yet'}</p>
          <p className={styles.blockHint}>{rules.join(' · ')}</p>
          <p className={styles.blockHint}>Questions, answers, scoring and time limit belong to the quiz, so they stay the same wherever it is used.</p>
          <div className={styles.linkedActions}>
            <LinkButton to={`${base}/quizzes/${quiz.quizId}`} size="sm">
              Edit questions
            </LinkButton>
            <LinkButton to={`${base}/quizzes/${quiz.quizId}/settings`} size="sm" variant="ghost">
              Quiz settings
            </LinkButton>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.editorBlock}>
      <div className={styles.linked}>
        <p className={styles.linkedTitle}>No quiz yet</p>
        <p className={styles.blockHint}>Write the questions in the quiz builder. The rules below become the quiz’s starting settings.</p>
        <LinkButton to={`${base}/quizzes/new?course=${courseId ?? ''}${lessonId ? `&lesson=${lessonId}` : ''}`} size="sm">
          Build the quiz
        </LinkButton>
      </div>
      <div className={styles.threeUp}>
        <Field label="Pass mark" hint="Percent needed to pass">
          <Input type="number" min={1} max={100} value={quiz.passMark} onChange={(e) => set({ passMark: Number(e.target.value) })} />
        </Field>
        <Field label="Attempts" hint="0 for unlimited">
          <Input type="number" min={0} max={10} value={quiz.attempts} onChange={(e) => set({ attempts: Number(e.target.value) })} />
        </Field>
        <Field label="Time limit" hint="Minutes · blank for none">
          <Input
            type="number"
            min={1}
            max={180}
            value={quiz.timeLimitMin ?? ''}
            onChange={(e) => set({ timeLimitMin: e.target.value ? Number(e.target.value) : undefined })}
          />
        </Field>
      </div>
    </div>
  );
}

function AssignmentEditor({ content, onChange, errorFor, base }: EditorProps) {
  const { courseId, lessonId } = useParams();
  const a = content.assignment ?? { brief: '', dueAfterDays: 7, maxScore: 20, submission: 'file' as const };
  const set = (patch: Partial<typeof a>) => onChange({ ...content, assignment: { ...a, ...patch } });

  if (a.assignmentId) {
    return (
      <div className={styles.editorBlock}>
        <div className={styles.linked}>
          <p className={styles.linkedTitle}>
            {a.submission === 'file' ? 'File upload' : a.submission === 'text' ? 'Written response' : 'Structured details'} · {plural(a.maxScore, 'point')}
          </p>
          <p className={styles.blockHint}>{a.brief}</p>
          <p className={styles.blockHint}>The brief, rubric, due date and reviews belong to the assignment, so learners and reviewers see one version.</p>
          <div className={styles.linkedActions}>
            <LinkButton to={`${base}/assignments/${a.assignmentId}`} size="sm">
              Edit assignment
            </LinkButton>
            <LinkButton to={`${base}/assignments/${a.assignmentId}/submissions`} size="sm" variant="ghost">
              Submissions
            </LinkButton>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.editorBlock}>
      <Field label="What learners should submit" error={errorFor('lesson-brief')} hint="Be specific about the chart, the steps and the format.">
        <Textarea
          id="lesson-brief"
          rows={5}
          value={a.brief}
          onChange={(e) => set({ brief: e.target.value })}
          placeholder="Work out the lord of every house for an Aries ascendant…"
        />
      </Field>
      <ChoiceCards
        legend="Submission"
        columns={a.submission === 'chart' ? 3 : 2}
        value={a.submission}
        onChange={(submission) => set({ submission })}
        choices={[
          { value: 'file', label: 'File upload', description: 'PDF, image or document' },
          { value: 'text', label: 'Written answer', description: 'Typed in the lesson' },
          // Retired: shown only for a lesson that already uses it.
          ...(a.submission === 'chart' ? [{ value: 'chart' as const, label: 'Structured details', description: 'An older format' }] : []),
        ]}
      />
      <div className={styles.threeUp}>
        <Field label="Due after" hint="Days after the learner reaches it">
          <Input type="number" min={1} max={60} value={a.dueAfterDays} onChange={(e) => set({ dueAfterDays: Number(e.target.value) })} />
        </Field>
        <Field label="Maximum score">
          <Input type="number" min={1} max={100} value={a.maxScore} onChange={(e) => set({ maxScore: Number(e.target.value) })} />
        </Field>
      </div>
      <div className={styles.linked}>
        <p className={styles.blockHint}>Add a rubric, resources and reviews by writing the full assignment. The brief above becomes its starting point.</p>
        <LinkButton to={`${base}/assignments/new?course=${courseId ?? ''}${lessonId ? `&lesson=${lessonId}` : ''}`} size="sm">
          Write the full assignment
        </LinkButton>
      </div>
    </div>
  );
}

function LiveEditor({ content, onChange, errorFor, base }: EditorProps) {
  const live = content.live ?? { durationMin: 60, recorded: true };
  const set = (patch: Partial<typeof live>) => onChange({ ...content, live: { ...live, ...patch } });
  const local = live.startsAt ? live.startsAt.slice(0, 16) : '';
  return (
    <div className={styles.editorBlock}>
      <div className={styles.threeUp}>
        <Field label="Starts" error={errorFor('lesson-live')} hint="India Standard Time">
          <Input
            id="lesson-live"
            type="datetime-local"
            value={local}
            onChange={(e) => set({ startsAt: e.target.value ? `${e.target.value}:00+05:30` : undefined })}
          />
        </Field>
        <Field label="Length" hint="Minutes">
          <Input type="number" min={15} max={240} value={live.durationMin} onChange={(e) => set({ durationMin: Number(e.target.value) })} />
        </Field>
      </div>
      <Switch
        checked={live.recorded}
        onChange={(recorded) => set({ recorded })}
        label="Record the session"
        description="The recording appears in this lesson for 30 days after the class."
      />
      <p className={styles.blockHint}>
        The join link is created when the session is scheduled. Attendance and reminders are in{' '}
        <LinkButton to={`${base}/live`} variant="ghost" size="sm">
          Live classes
        </LinkButton>
      </p>
    </div>
  );
}
