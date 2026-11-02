import { useState } from 'react';
import { CalendarBlank, FileText, PaperPlaneTilt, Target, Trophy } from '@phosphor-icons/react';
import type { AssignmentInput, MediaFile } from '@syniastrolms/domain';
import { assignmentMaxScore } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { plural } from '@/lib/format';
import { FileCard, MediaDrop } from '@/components/forms/Upload';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input, Textarea } from '@/components/ui/Field/Field';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { ArticleBody } from '@/components/lms/content/ArticleBody';
import { dueText, FORMATS } from './assignmentMeta';
import styles from './Assignments.module.css';

const words = (text: string) => (text.trim() ? text.trim().split(/\s+/).length : 0);

/** The assignment as a learner meets it: the brief, how it is graded, and where to hand in. Nothing is submitted. */
export function AssignmentPreview({ assignment, courseTitle, chapterLabel }: { assignment: AssignmentInput; courseTitle: string; chapterLabel?: string }) {
  const toast = useToast();
  const [file, setFile] = useState<MediaFile | null>(null);
  const [text, setText] = useState('');
  const [birth, setBirth] = useState({ date: '', time: '', place: '' });
  const max = assignmentMaxScore(assignment);
  const count = words(text);
  const over = assignment.wordLimit !== undefined && count > assignment.wordLimit;
  const previewOnly = (what: string) =>
    toast({ kind: 'info', title: 'Preview only', text: `${what} works for learners once the assignment is published. Nothing was sent.` });

  return (
    <article className={styles.learner}>
      <header className={styles.learnerHead}>
        <span className={styles.context}>
          {courseTitle}
          {chapterLabel && ` · ${chapterLabel}`}
        </span>
        <h2 className={styles.learnerTitle}>{assignment.title.trim() || 'Untitled assignment'}</h2>
        <ul className={styles.learnerFacts}>
          <li>
            <CalendarBlank size={16} aria-hidden="true" /> {dueText(assignment.due)}
          </li>
          <li>
            <Trophy size={16} aria-hidden="true" /> {plural(max, 'point')}
          </li>
          <li>
            <Target size={16} aria-hidden="true" /> Pass with {assignment.passMark}
          </li>
          <li>
            {FORMATS[assignment.format].icon(16)} {FORMATS[assignment.format].label}
          </li>
        </ul>
        {assignment.due.kind !== 'none' && (
          <p className={styles.blockHint}>
            {assignment.acceptsLate
              ? assignment.latePenalty
                ? `Late work is accepted with ${assignment.latePenalty}% off the score.`
                : 'Late work is accepted without a penalty.'
              : 'Submissions close at the due date.'}
          </p>
        )}
      </header>

      <section className={styles.learnerSection} aria-labelledby="preview-brief">
        <h3 id="preview-brief" className={styles.learnerHeading}>
          What to do
        </h3>
        {assignment.instructions.trim() ? <ArticleBody body={assignment.instructions} /> : <p className={styles.muted}>The instructions will appear here.</p>}
        {assignment.attachments.length > 0 && (
          <ul className={styles.attachments} aria-label="Resources">
            {assignment.attachments.map((a) => (
              <li key={a.id}>
                <FileCard icon={<FileText size={18} />} file={a} detail={a.pages ? plural(a.pages, 'page') : 'Resource'} />
              </li>
            ))}
          </ul>
        )}
      </section>

      {assignment.rubric.length > 0 && (
        <section className={styles.learnerSection} aria-labelledby="preview-rubric">
          <h3 id="preview-rubric" className={styles.learnerHeading}>
            How it’s graded
          </h3>
          <ul className={styles.rubricView}>
            {assignment.rubric.map((c) => (
              <li key={c.id}>
                <span className={styles.rubricViewText}>
                  <strong>{c.title || 'Untitled criterion'}</strong>
                  {c.description && <span>{c.description}</span>}
                </span>
                <span className={cx(styles.rubricViewPoints, 'tabular')}>{plural(c.points || 0, 'pt')}</span>
              </li>
            ))}
          </ul>
        </section>
      )}

      <section className={cx(styles.learnerSection, styles.handIn)} aria-labelledby="preview-submit">
        <h3 id="preview-submit" className={styles.learnerHeading}>
          Your submission
        </h3>
        {assignment.format === 'file' &&
          (file ? (
            <FileCard icon={<FileText size={18} />} file={file} detail="Ready to submit" onRemove={() => setFile(null)} />
          ) : (
            <MediaDrop
              id="preview-upload"
              accept=".pdf,.png,.jpg,.jpeg"
              label="Upload your work"
              hint="One PDF, or a clear photo of handwritten work"
              icon={<FileText size={18} />}
              onDone={setFile}
            />
          ))}
        {assignment.format === 'chart' && (
          <div className={styles.birthGrid}>
            <Field label="Date of birth">
              <Input type="date" value={birth.date} onChange={(e) => setBirth((b) => ({ ...b, date: e.target.value }))} />
            </Field>
            <Field label="Time of birth">
              <Input type="time" value={birth.time} onChange={(e) => setBirth((b) => ({ ...b, time: e.target.value }))} />
            </Field>
            <Field label="Place of birth">
              <Input value={birth.place} placeholder="Pune, Maharashtra" onChange={(e) => setBirth((b) => ({ ...b, place: e.target.value }))} />
            </Field>
          </div>
        )}
        {assignment.format !== 'file' && (
          <Field
            label={assignment.format === 'chart' ? 'Your interpretation' : 'Your response'}
            hint={
              <span className={cx(over && styles.overdueText)}>
                {assignment.wordLimit ? `${count} of ${plural(assignment.wordLimit, 'word')}` : plural(count, 'word')}
              </span>
            }
          >
            <Textarea rows={7} value={text} onChange={(e) => setText(e.target.value)} placeholder="Write here. Your work saves as a draft until you submit." />
          </Field>
        )}
        <div className={styles.handInActions}>
          <Button onClick={() => previewOnly('Saving a draft')}>Save draft</Button>
          <Button variant="primary" iconStart={<PaperPlaneTilt size={16} />} onClick={() => previewOnly('Submitting')}>
            Submit assignment
          </Button>
        </div>
      </section>
    </article>
  );
}
