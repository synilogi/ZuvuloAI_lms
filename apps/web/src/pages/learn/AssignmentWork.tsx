import { useState } from 'react';
import {
  ArrowCounterClockwise,
  CalendarBlank,
  CheckCircle,
  FileText,
  FloppyDisk,
  HourglassMedium,
  Lock,
  PaperPlaneTilt,
  Target,
  Trophy,
} from '@phosphor-icons/react';
import type { Attachment } from '@syniastrolms/domain';
import { reviewScore } from '@syniastrolms/domain';
import { useNow } from '@/hooks/useNow';
import { cx } from '@/lib/cx';
import { formatDate, formatRelative, formatTime, plural } from '@/lib/format';
import { FileCard, MediaDrop } from '@/components/forms/Upload';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services, type LearnerAssignment } from '@/services';
import { FORMATS } from '@/pages/assignments/assignmentMeta';
import { ArticleBody } from '@/components/lms/content/ArticleBody';
import styles from './Learn.module.css';

const words = (text = '') => (text.trim() ? text.trim().split(/\s+/).length : 0);

interface AssignmentWorkProps {
  item: LearnerAssignment;
  /** Called with the updated assignment after a submission. */
  onSubmitted: (next: LearnerAssignment) => void;
  /** Hide the brief when the surrounding page already shows it. */
  showBrief?: boolean;
}

/** An assignment from the learner's side: the brief, where it stands, and the hand-in form or the feedback. */
export function AssignmentWork({ item, onSubmitted, showBrief = true }: AssignmentWorkProps) {
  const { assignment: a, submission } = item;
  const now = useNow();
  const toast = useToast();
  const [text, setText] = useState(item.draft?.text ?? '');
  const [files, setFiles] = useState<Attachment[]>(item.draft?.files ?? []);
  const [chart, setChart] = useState(item.draft?.chart ?? { label: 'My own chart', date: '', time: '', place: '', lagna: '', moonSign: '', nakshatra: '' });
  const [saving, setSaving] = useState<null | 'draft' | 'submit'>(null);
  const [error, setError] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState<string | null>(null);

  const returned = submission?.review.status === 'returned';
  const waiting = submission && (submission.review.status === 'waiting' || submission.review.status === 'in-review');
  const graded = submission?.review.status === 'graded';
  const canHandIn = !waiting && !graded && item.state !== 'closed';
  const count = words(text);
  const draft = { text, files, chart: a.format === 'chart' ? chart : undefined };

  const saveDraft = async () => {
    setSaving('draft');
    setError(null);
    try {
      const r = await services.learning.saveAssignmentDraft(a.id, draft);
      setSavedAt(r.savedAt);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(null);
    }
  };

  const submit = async () => {
    setSaving('submit');
    setError(null);
    try {
      const next = await services.learning.submitAssignment(a.id, draft);
      toast({ kind: 'success', title: 'Submitted for review', text: `${a.title} · feedback usually arrives within two days` });
      onSubmitted(next);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(null);
    }
  };

  const total = graded && submission ? reviewScore(a, submission.review, submission.late) : null;

  return (
    <div className={styles.work}>
      <ul className={styles.facts}>
        <li>
          <CalendarBlank size={16} aria-hidden="true" />
          {item.dueAt ? `Due ${formatDate(item.dueAt)}, ${formatTime(item.dueAt)}` : 'No due date'}
        </li>
        <li>
          <Trophy size={16} aria-hidden="true" /> {plural(a.maxScore, 'point')}
        </li>
        <li>
          <Target size={16} aria-hidden="true" /> Pass with {a.passMark}
        </li>
        <li>
          {FORMATS[a.format].icon(16)} {FORMATS[a.format].label}
        </li>
      </ul>

      {showBrief && (
        <section className={styles.workSection} aria-label="Brief">
          <ArticleBody body={a.instructions} />
          {a.attachments.length > 0 && (
            <ul className={styles.fileList} aria-label="Resources">
              {a.attachments.map((f) => (
                <li key={f.id}>
                  <FileCard icon={<FileText size={18} />} file={f} detail={f.pages ? plural(f.pages, 'page') : 'Resource'} />
                </li>
              ))}
            </ul>
          )}
        </section>
      )}

      {a.rubric.length > 0 && !graded && (
        <details className={styles.rubric}>
          <summary>How it’s graded · {plural(a.maxScore, 'point')}</summary>
          <ul>
            {a.rubric.map((c) => (
              <li key={c.id}>
                <span>
                  <strong>{c.title}</strong>
                  <span className={styles.muted}>{c.description}</span>
                </span>
                <span className="tabular">{plural(c.points, 'pt')}</span>
              </li>
            ))}
          </ul>
        </details>
      )}

      {waiting && submission && (
        <div className={styles.stateCard}>
          <HourglassMedium size={22} aria-hidden="true" />
          <div>
            <p className={styles.stateTitle}>
              {submission.review.status === 'in-review' ? 'Your instructor is reviewing this' : 'Submitted — waiting for review'}
            </p>
            <p className={styles.muted}>
              Handed in {formatRelative(submission.submittedAt, now)}
              {submission.late ? ' · marked late' : ''} · attempt {submission.attempt}. You’ll get a notification when feedback is ready.
            </p>
            {(submission.files.length > 0 || submission.text) && (
              <div className={styles.submitted}>
                {submission.files.map((f) => (
                  <FileCard key={f.id} icon={<FileText size={18} />} file={f} detail="Submitted" />
                ))}
                {submission.text && <p className={styles.excerpt}>{submission.text.length > 280 ? `${submission.text.slice(0, 280)}…` : submission.text}</p>}
              </div>
            )}
          </div>
        </div>
      )}

      {graded && submission && total && (
        <div className={cx(styles.stateCard, styles.gradedCard)}>
          <div className={styles.gradeScore}>
            <span className="tabular">{submission.review.score}</span>
            <span className={styles.gradeMax}>/ {a.maxScore}</span>
          </div>
          <div className={styles.gradeText}>
            <p className={styles.stateTitle}>
              {(submission.review.score ?? 0) >= a.passMark ? (
                <Badge tone="accent" icon={<CheckCircle size={13} weight="fill" />}>
                  Passed
                </Badge>
              ) : (
                <Badge tone="warn">Below the pass mark</Badge>
              )}
              <span className={styles.muted}>Reviewed {submission.review.updatedAt ? formatDate(submission.review.updatedAt) : ''}</span>
            </p>
            {Object.keys(submission.review.scores).length > 0 && (
              <ul className={styles.breakdown}>
                {a.rubric.map((c) => (
                  <li key={c.id}>
                    <span>{c.title}</span>
                    <span className="tabular">
                      {submission.review.scores[c.id] ?? '—'} / {c.points}
                    </span>
                  </li>
                ))}
                {total.penalty > 0 && (
                  <li>
                    <span>Late penalty</span>
                    <span className="tabular">−{total.penalty}</span>
                  </li>
                )}
              </ul>
            )}
            {submission.review.feedback && (
              <blockquote className={styles.feedback}>
                <span className={styles.feedbackLabel}>Feedback</span>
                {submission.review.feedback}
              </blockquote>
            )}
          </div>
        </div>
      )}

      {returned && submission?.review.feedback && (
        <InlineMessage kind="warn" title="Your instructor asked for another attempt">
          {submission.review.feedback}
        </InlineMessage>
      )}

      {item.state === 'closed' && !submission && (
        <div className={styles.stateCard}>
          <Lock size={22} aria-hidden="true" />
          <div>
            <p className={styles.stateTitle}>Submissions are closed</p>
            <p className={styles.muted}>The due date has passed and this assignment doesn’t accept late work. Your instructor can reopen it for you.</p>
          </div>
        </div>
      )}

      {canHandIn && (
        <section className={styles.handIn} aria-labelledby={`hand-in-${a.id}`}>
          <h3 id={`hand-in-${a.id}`} className={styles.sectionTitle}>
            {returned ? 'Hand in a new attempt' : 'Your submission'}
          </h3>
          {item.state === 'overdue' && (
            <InlineMessage kind="warn" title="This is past its due date">
              Late work is still accepted{a.latePenalty ? `, with ${a.latePenalty}% off the score` : ''}.
            </InlineMessage>
          )}
          {error && (
            <InlineMessage kind="error" title="Not submitted yet">
              {error}
            </InlineMessage>
          )}
          {a.format === 'file' && (
            <>
              {files.map((f) => (
                <FileCard
                  key={f.id}
                  icon={<FileText size={18} />}
                  file={f}
                  detail="Ready to submit"
                  onRemove={() => setFiles(files.filter((x) => x.id !== f.id))}
                />
              ))}
              {files.length < 3 && (
                <MediaDrop
                  id={`upload-${a.id}`}
                  accept=".pdf,.png,.jpg,.jpeg"
                  label={files.length ? 'Add another file' : 'Upload your work'}
                  hint="PDF, or a clear photo of handwritten work · up to 3 files"
                  icon={<FileText size={18} />}
                  onDone={(file) => setFiles((list) => [...list, { id: file.id ?? `f-${Date.now().toString(36)}`, name: file.name, sizeMb: file.sizeMb }])}
                />
              )}
            </>
          )}
          {a.format === 'chart' && (
            <div className={styles.birthGrid}>
              <Field label="Date of birth">
                <Input type="date" value={chart.date} onChange={(e) => setChart({ ...chart, date: e.target.value })} />
              </Field>
              <Field label="Time of birth">
                <Input type="time" value={chart.time} onChange={(e) => setChart({ ...chart, time: e.target.value })} />
              </Field>
              <Field label="Place of birth">
                <Input value={chart.place} onChange={(e) => setChart({ ...chart, place: e.target.value })} placeholder="Bengaluru, Karnataka" />
              </Field>
            </div>
          )}
          {(a.format !== 'file' || files.length > 0) && (
            <Field
              label={a.format === 'file' ? 'Note for your instructor' : a.format === 'chart' ? 'Your interpretation' : 'Your response'}
              optional={a.format === 'file'}
              hint={
                <span className={cx(a.wordLimit && count > a.wordLimit && styles.over)}>
                  {a.wordLimit ? `${count} of ${plural(a.wordLimit, 'word')}` : plural(count, 'word')}
                </span>
              }
            >
              <Textarea
                rows={a.format === 'file' ? 3 : 9}
                value={text}
                onChange={(e) => setText(e.target.value)}
                placeholder={a.format === 'file' ? 'Anything your reviewer should know' : 'Write here. Save a draft any time.'}
              />
            </Field>
          )}
          <div className={styles.handInActions}>
            <span className={styles.muted}>{savedAt ? `Draft saved ${formatRelative(savedAt, now)}` : item.draft ? 'Draft saved earlier' : ''}</span>
            <Button iconStart={<FloppyDisk size={16} />} loading={saving === 'draft'} disabled={Boolean(saving)} onClick={saveDraft}>
              Save draft
            </Button>
            <Button
              variant="primary"
              iconStart={returned ? <ArrowCounterClockwise size={16} /> : <PaperPlaneTilt size={16} />}
              loading={saving === 'submit'}
              disabled={Boolean(saving)}
              onClick={submit}
            >
              {returned ? 'Resubmit' : 'Submit for review'}
            </Button>
          </div>
        </section>
      )}
    </div>
  );
}
