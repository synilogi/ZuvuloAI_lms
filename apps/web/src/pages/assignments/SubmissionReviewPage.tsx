import { useEffect, useRef, useState } from 'react';
import { Link, useBlocker, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import {
  ArrowCounterClockwise,
  ArrowLeft,
  CaretLeft,
  CaretRight,
  CheckCircle,
  ClipboardText,
  FileText,
  FloppyDisk,
  Lock,
  PaperPlaneTilt,
  PencilSimple,
  ImageSquare,
  WarningCircle,
} from '@phosphor-icons/react';
import type { CourseAssignment, Submission } from '@syniastrolms/domain';
import { reviewScore, validateReview } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { cx } from '@/lib/cx';
import { formatDate, formatRelative, formatTime, plural } from '@/lib/format';
import { FileCard } from '@/components/forms/Upload';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Field, Input, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { Meter } from '@/components/lms/progress/Meters';
import { refreshNavCounts } from '@/shell/NavCounts';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type ReviewInput, type SubmissionDetail } from '@/services';
import { ArticleBody } from '@/components/lms/content/ArticleBody';
import { dueText, FORMATS, ReviewBadge, waitingFor } from './assignmentMeta';
import styles from './Assignments.module.css';

export default function SubmissionReviewPage() {
  const { assignmentId, submissionId } = useParams();
  const { base, instructorId } = useWorkspace();
  const [params] = useSearchParams();
  const fromQueue = params.get('from') === 'queue';
  const detail = useAsync(`submission:${submissionId}`, () => services.assignments.submission(submissionId!, instructorId));
  const backTo = fromQueue ? `${base}/assignments/review` : `${base}/assignments/${assignmentId}/submissions`;

  const d = detail.data;
  usePageCrumbs(d ? [{ label: d.assignment.title, to: `${base}/assignments/${d.assignment.id}` }, { label: d.student.name }] : [{ label: 'Submission' }]);

  if (detail.status === 'error' && !d) {
    const notFound = (detail.error as { code?: string }).code === 'not-found';
    return (
      <StateMessage
        kind="error"
        title={notFound ? 'Submission not found' : 'The submission didn’t load'}
        actions={
          notFound ? (
            <LinkButton to={backTo} iconStart={<ArrowLeft size={16} />}>
              {fromQueue ? 'Back to the review queue' : 'Back to submissions'}
            </LinkButton>
          ) : (
            <Button variant="primary" onClick={() => detail.run().catch(() => undefined)}>
              Try again
            </Button>
          )
        }
      >
        {detail.error.message}
      </StateMessage>
    );
  }
  if (!d || d.submission.id !== submissionId) {
    return (
      <div className={styles.page} role="status" aria-label="Loading submission">
        <Skeleton width={140} height={12} />
        <Skeleton width="40%" height={30} radius="var(--r-xs)" />
        <div className={styles.reviewGrid}>
          <Skeleton height={520} radius="var(--r-lg)" />
          <Skeleton height={420} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }
  return (
    <Review
      key={d.submission.id}
      detail={d}
      backTo={backTo}
      fromQueue={fromQueue}
      onSaved={(next) =>
        detail
          .run()
          .then(() => next)
          .catch(() => next)
      }
    />
  );
}

interface ReviewProps {
  detail: SubmissionDetail;
  backTo: string;
  fromQueue: boolean;
  onSaved: (submission: Submission) => void;
}

function Review({ detail, backTo, fromQueue, onSaved }: ReviewProps) {
  const { base } = useWorkspace();
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const { submission, assignment, student, queue } = detail;
  const suffix = fromQueue ? '?from=queue' : '';
  const reviewTo = (id: string) => `${base}/assignments/${assignment.id}/submissions/${id}${suffix}`;

  const initial = (): ReviewInput => ({
    decision: 'draft',
    scores: submission.review.scores,
    points: submission.review.points,
    feedback: submission.review.feedback,
    privateNote: submission.review.privateNote ?? '',
  });
  const [baseline, setBaseline] = useState(initial);
  const [form, setForm] = useState(initial);
  const [editing, setEditing] = useState(submission.review.status === 'waiting' || submission.review.status === 'in-review');
  const [attempt, setAttempt] = useState<null | 'graded' | 'returned'>(null);
  const [saving, setSaving] = useState<null | ReviewInput['decision']>(null);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState<null | 'graded' | 'returned'>(null);
  const leaving = useRef(false);

  const dirty = editing && JSON.stringify({ ...form, decision: 'draft' }) !== JSON.stringify({ ...baseline, decision: 'draft' });
  const blocker = useBlocker(({ currentLocation, nextLocation }) => dirty && !leaving.current && currentLocation.pathname !== nextLocation.pathname);
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const issues = attempt ? validateReview(assignment, form, attempt) : [];
  const issueFor = (field: string, criterionId?: string) => issues.find((i) => i.field === field && (!criterionId || i.criterionId === criterionId))?.message;
  const total = reviewScore(assignment, form, submission.late);
  const passed = total.score >= assignment.passMark;
  const scored = assignment.rubric.length ? assignment.rubric.every((c) => form.scores[c.id] !== undefined) : form.points !== undefined;

  const submit = async (decision: ReviewInput['decision']) => {
    setError(null);
    if (decision !== 'draft') {
      setAttempt(decision);
      if (validateReview(assignment, form, decision).length) {
        requestAnimationFrame(() => document.getElementById('review-issues')?.focus());
        return;
      }
    }
    setSaving(decision);
    try {
      const saved = await services.assignments.review(submission.id, { ...form, decision });
      const next = { ...form, decision: 'draft' as const };
      setBaseline(next);
      setForm(next);
      setAttempt(null);
      if (decision === 'draft') {
        toast({ kind: 'success', title: 'Draft review saved', text: `Only instructors can see it until you submit.` });
      } else {
        leaving.current = true;
        setEditing(false);
        setSent(decision);
        toast({
          kind: 'success',
          title: decision === 'graded' ? `Review sent to ${student.name.split(' ')[0]}` : `Resubmission requested from ${student.name.split(' ')[0]}`,
          text: decision === 'graded' ? `${saved.review.score} / ${assignment.maxScore} · ${assignment.title}` : assignment.title,
        });
        leaving.current = false;
      }
      onSaved(saved);
      refreshNavCounts();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(null);
    }
  };

  const setScore = (id: string, raw: string) =>
    setForm((f) => {
      const scores = { ...f.scores };
      if (raw === '') delete scores[id];
      else scores[id] = Number(raw);
      return { ...f, scores };
    });

  const format = FORMATS[assignment.format];
  const text = submission.text ?? '';
  const wordCount = text.trim() ? text.trim().split(/\s+/).length : 0;
  const reviewed = submission.review.status === 'graded' || submission.review.status === 'returned';

  const decisionButtons = (compact = false) => (
    <>
      {!compact && (
        <Button variant="ghost" iconStart={<FloppyDisk size={16} />} loading={saving === 'draft'} disabled={Boolean(saving)} onClick={() => submit('draft')}>
          Save draft
        </Button>
      )}
      <Button iconStart={<ArrowCounterClockwise size={16} />} loading={saving === 'returned'} disabled={Boolean(saving)} onClick={() => submit('returned')}>
        {compact ? 'Return' : 'Request resubmission'}
      </Button>
      <Button
        variant="primary"
        iconStart={<PaperPlaneTilt size={16} />}
        loading={saving === 'graded'}
        disabled={Boolean(saving)}
        onClick={() => submit('graded')}
      >
        Submit review
      </Button>
    </>
  );

  return (
    <div className={styles.page}>
      <header className={styles.top}>
        <Link to={backTo} className={styles.back}>
          <ArrowLeft size={14} aria-hidden="true" /> {fromQueue ? 'To mark' : `Submissions · ${assignment.title}`}
        </Link>
        <div className={styles.topRow}>
          <div className={styles.reviewIdentity}>
            <Avatar name={student.name} size={48} />
            <div className={styles.topText}>
              <span className={styles.context}>
                <Link to={`${base}/assignments/${assignment.id}`} className={styles.contextLink}>
                  {assignment.title}
                </Link>
              </span>
              <h1 className={styles.heading}>{student.name}</h1>
              <div className={styles.topMeta}>
                <ReviewBadge
                  submission={submission}
                  overdue={
                    submission.review.status !== 'graded' &&
                    submission.review.status !== 'returned' &&
                    now.getTime() - new Date(submission.submittedAt).getTime() > 48 * 3_600_000
                  }
                  size="md"
                />
                <span>
                  Submitted {formatDate(submission.submittedAt)}, {formatTime(submission.submittedAt)}
                </span>
                {submission.late && <Badge tone="warn">Late</Badge>}
                <span>Attempt {submission.attempt}</span>
              </div>
            </div>
          </div>
          {queue.total > 0 && (
            <nav className={styles.queueNav} aria-label="Review queue">
              <span className={styles.queueText}>
                {queue.position ? `${queue.position} of ${plural(queue.total, 'submission')} to review` : `${plural(queue.total, 'submission')} to review`}
              </span>
              <IconButton
                boxed
                label="Previous submission to review"
                icon={<CaretLeft size={16} />}
                disabled={!queue.previousId}
                onClick={() => queue.previousId && navigate(reviewTo(queue.previousId))}
              />
              <IconButton
                boxed
                label="Next submission to review"
                icon={<CaretRight size={16} />}
                disabled={!queue.nextId}
                onClick={() => queue.nextId && navigate(reviewTo(queue.nextId))}
              />
            </nav>
          )}
        </div>
      </header>

      <div className={styles.reviewGrid}>
        <div className={styles.main}>
          <section className={styles.panel} aria-labelledby="response-title">
            <div className={styles.panelHead}>
              <h2 id="response-title" className={styles.panelTitle}>
                {format.icon(18)} {assignment.format === 'file' ? 'Handed-in work' : assignment.format === 'chart' ? 'Chart and interpretation' : 'Response'}
              </h2>
              <span className={styles.muted}>{waitingFor(submission.submittedAt, now)} ago</span>
            </div>

            {submission.chart && (
              <dl className={styles.birth}>
                <div className={styles.birthWide}>
                  <dt>Chart</dt>
                  <dd>{submission.chart.label}</dd>
                </div>
                <div>
                  <dt>Born</dt>
                  <dd>
                    {formatDate(`${submission.chart.date}T12:00:00+05:30`)}, {submission.chart.time} IST
                  </dd>
                </div>
                <div>
                  <dt>Place</dt>
                  <dd>{submission.chart.place}</dd>
                </div>
                <div>
                  <dt>Lagna</dt>
                  <dd>{submission.chart.lagna}</dd>
                </div>
                <div>
                  <dt>Moon</dt>
                  <dd>
                    {submission.chart.moonSign} · {submission.chart.nakshatra}
                  </dd>
                </div>
              </dl>
            )}

            {submission.files.length > 0 && (
              <ul className={styles.attachments} aria-label="Files">
                {submission.files.map((f) => (
                  <li key={f.id}>
                    <FileCard
                      icon={f.name.endsWith('.pdf') ? <FileText size={18} /> : <ImageSquare size={18} />}
                      file={f}
                      detail={f.pages ? plural(f.pages, 'page') : 'Image'}
                    />
                  </li>
                ))}
              </ul>
            )}

            {text && (
              <div className={styles.response}>
                {text.split(/\n{2,}/).map((p, i) => (
                  <p key={i}>{p}</p>
                ))}
              </div>
            )}
            {text && assignment.format !== 'file' && (
              <p className={cx(styles.muted, assignment.wordLimit && wordCount > assignment.wordLimit && styles.overdueText)}>
                {assignment.wordLimit
                  ? `${wordCount} of ${plural(assignment.wordLimit, 'word')}${wordCount > assignment.wordLimit ? ' — over the limit' : ''}`
                  : plural(wordCount, 'word')}
              </p>
            )}
          </section>

          <details className={styles.brief}>
            <summary>
              <ClipboardText size={18} aria-hidden="true" /> Assignment brief and rubric
            </summary>
            <div className={styles.briefBody}>
              <p className={styles.muted}>
                {dueText(assignment.due)} · {format.label} · pass with {assignment.passMark} of {assignment.maxScore}
                {assignment.acceptsLate && assignment.latePenalty ? ` · late work ${assignment.latePenalty}% off` : ''}
              </p>
              <ArticleBody body={assignment.instructions} />
              {assignment.attachments.length > 0 && (
                <ul className={styles.attachments} aria-label="Resources">
                  {assignment.attachments.map((a) => (
                    <li key={a.id}>
                      <FileCard icon={<FileText size={18} />} file={a} detail={a.pages ? plural(a.pages, 'page') : 'Resource'} />
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </details>

          <section className={cx(styles.panel, styles.learnerPanel)} aria-labelledby="learner-title">
            <h2 id="learner-title" className={styles.panelTitle}>
              About the learner
            </h2>
            <Meter value={student.progress} showLabel label={`${student.name}’s progress in ${detail.courseTitle}`} valueText={`${student.progress}%`} />
            <dl className={styles.learnerFactsList}>
              <div>
                <dt>Course</dt>
                <dd>{detail.courseTitle}</dd>
              </div>
              <div>
                <dt>Enrolled</dt>
                <dd>{formatRelative(student.enrolledAt, now)}</dd>
              </div>
              <div>
                <dt>City</dt>
                <dd>{student.city || '—'}</dd>
              </div>
              <div>
                <dt>Email</dt>
                <dd className={styles.breakAll}>{student.email}</dd>
              </div>
            </dl>
          </section>
        </div>

        <aside className={styles.gradePanel} aria-labelledby="grade-title">
          <div className={styles.panelHead}>
            <h2 id="grade-title" className={styles.panelTitle}>
              Review
            </h2>
            {reviewed && !editing && (
              <Button size="sm" variant="ghost" iconStart={<PencilSimple size={15} />} onClick={() => setEditing(true)}>
                Edit review
              </Button>
            )}
          </div>

          {sent && !editing && (
            <InlineMessage kind="success" title={sent === 'graded' ? `Review sent to ${student.name}` : 'Resubmission requested'}>
              {sent === 'graded' ? 'They’ll see their grade and your feedback in the lesson.' : 'They’ll see your feedback and can hand in a new attempt.'}
            </InlineMessage>
          )}

          {!editing ? (
            <ReviewSummary assignment={assignment} submission={submission} />
          ) : (
            <>
              {error && (
                <InlineMessage kind="error" title="The review wasn’t saved.">
                  {error}
                </InlineMessage>
              )}
              {issues.length > 0 && (
                <div id="review-issues" tabIndex={-1} className={styles.issueBox} role="alert">
                  <WarningCircle size={18} />
                  <div>
                    <p className={styles.issueBoxTitle}>{attempt === 'returned' ? 'Before returning this' : 'Before submitting this review'}</p>
                    <ul>
                      {issues.map((i) => (
                        <li key={`${i.field}-${i.criterionId ?? ''}`}>{i.message}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              )}

              {assignment.rubric.length > 0 ? (
                <ol className={styles.scoring} aria-label="Score each criterion">
                  {assignment.rubric.map((c) => {
                    const value = form.scores[c.id];
                    const issue = issueFor('scores', c.id);
                    return (
                      <li key={c.id} className={cx(styles.scoreRow, issue && styles.scoreRowError)}>
                        <div className={styles.scoreText}>
                          <label htmlFor={`score-${c.id}`} className={styles.scoreLabel}>
                            {c.title}
                          </label>
                          <span className={styles.scoreHint}>{c.description}</span>
                        </div>
                        <span className={styles.scoreInput}>
                          <Input
                            id={`score-${c.id}`}
                            type="number"
                            inputMode="decimal"
                            min={0}
                            max={c.points}
                            step={0.5}
                            value={value ?? ''}
                            onChange={(e) => setScore(c.id, e.target.value)}
                            aria-invalid={Boolean(issue) || undefined}
                          />
                          <span aria-hidden="true">/ {c.points}</span>
                        </span>
                        <div className={styles.scoreQuick} role="group" aria-label={`Quick scores for ${c.title}`}>
                          {[0, Math.round(c.points / 2), c.points].map((v, i) => (
                            <button
                              key={i}
                              type="button"
                              className={cx(styles.quick, value === v && styles.quickOn)}
                              aria-pressed={value === v}
                              onClick={() => setScore(c.id, String(v))}
                            >
                              {i === 2 ? `Full ${v}` : v}
                            </button>
                          ))}
                        </div>
                      </li>
                    );
                  })}
                </ol>
              ) : (
                <Field label="Score" error={issueFor('points')} hint={`Out of ${assignment.maxScore}`} className={styles.narrowField}>
                  <Input
                    type="number"
                    inputMode="decimal"
                    min={0}
                    max={assignment.maxScore}
                    step={0.5}
                    value={form.points ?? ''}
                    onChange={(e) => setForm((f) => ({ ...f, points: e.target.value === '' ? undefined : Number(e.target.value) }))}
                  />
                </Field>
              )}

              <div className={styles.totalBox} aria-live="polite">
                <div className={styles.totalRow}>
                  <span>Score</span>
                  <strong className="tabular">
                    {total.raw} / {total.max}
                  </strong>
                </div>
                {total.penalty > 0 && (
                  <div className={styles.totalRow}>
                    <span>Late, {assignment.latePenalty}% off</span>
                    <span className="tabular">−{total.penalty}</span>
                  </div>
                )}
                <Meter
                  value={total.max ? (total.score / total.max) * 100 : 0}
                  threshold={total.max ? (assignment.passMark / total.max) * 100 : undefined}
                  tone={scored ? (passed ? 'accent' : 'warn') : 'info'}
                  label="Score against the pass mark"
                />
                <div className={styles.totalRow}>
                  <span>{scored ? (passed ? 'Passes' : 'Below the pass mark') : 'Not fully scored yet'}</span>
                  <span className={cx(styles.muted, 'tabular')}>
                    Final {total.score} · pass {assignment.passMark}
                  </span>
                </div>
              </div>

              <Field label="Feedback for the learner" error={issueFor('feedback')} hint="Sent with the grade. Say what worked and one thing to do next.">
                <Textarea
                  id="review-feedback"
                  rows={6}
                  value={form.feedback}
                  onChange={(e) => setForm((f) => ({ ...f, feedback: e.target.value }))}
                  placeholder="Your working is right throughout. Next time, say why the discriminant decides the nature of the roots rather than stating it."
                />
              </Field>
              <div className={styles.phrases} role="group" aria-label="Add a comment">
                {[
                  'Clear reasoning — each judgement is traced to the chart.',
                  'Recheck the house lordships before drawing conclusions.',
                  'Show your working so mistakes can be found.',
                ].map((p) => (
                  <button
                    key={p}
                    type="button"
                    className={styles.phrase}
                    onClick={() => setForm((f) => ({ ...f, feedback: f.feedback.trim() ? `${f.feedback.trim()} ${p}` : p }))}
                  >
                    + {p}
                  </button>
                ))}
              </div>
              <Field label="Note for instructors" optional hint="Never shown to the learner.">
                <Textarea rows={2} value={form.privateNote ?? ''} onChange={(e) => setForm((f) => ({ ...f, privateNote: e.target.value }))} />
              </Field>

              {!isMobile && <div className={styles.decisions}>{decisionButtons()}</div>}
              {reviewed && (
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => {
                    setForm(baseline);
                    setAttempt(null);
                    setEditing(false);
                  }}
                >
                  Cancel editing
                </Button>
              )}
            </>
          )}

          {!editing && (queue.nextId || fromQueue) && (
            <div className={styles.decisions}>
              {queue.nextId ? (
                <LinkButton variant={sent ? 'primary' : 'secondary'} to={reviewTo(queue.nextId)} iconEnd={<CaretRight size={16} />}>
                  Next to review
                </LinkButton>
              ) : (
                <LinkButton to={backTo}>Back to the queue</LinkButton>
              )}
            </div>
          )}
        </aside>
      </div>

      {isMobile && editing && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{decisionButtons(true)}</div>}>
          <span />
        </StickyActionBar>
      )}

      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave this review?"
        description={`Your scores and feedback for ${student.name} haven’t been saved.`}
        footer={
          <>
            <Button onClick={() => blocker.reset?.()}>Keep reviewing</Button>
            <Button
              onClick={async () => {
                await services.assignments.review(submission.id, { ...form, decision: 'draft' }).catch(() => undefined);
                blocker.proceed?.();
              }}
            >
              Save draft and leave
            </Button>
            <Button variant="danger" onClick={() => blocker.proceed?.()}>
              Discard
            </Button>
          </>
        }
      />
    </div>
  );
}

function ReviewSummary({ assignment, submission }: { assignment: CourseAssignment; submission: Submission }) {
  const r = submission.review;
  if (r.status !== 'graded' && r.status !== 'returned') return null;
  const total = reviewScore(assignment, r, submission.late);
  return (
    <div className={styles.summaryView}>
      {r.status === 'graded' ? (
        <div className={styles.bigScore}>
          <span className="tabular">{r.score ?? total.score}</span>
          <span className={styles.bigScoreMax}>/ {assignment.maxScore}</span>
          <Badge tone={(r.score ?? total.score) >= assignment.passMark ? 'accent' : 'warn'}>
            {(r.score ?? total.score) >= assignment.passMark ? 'Passed' : 'Below pass mark'}
          </Badge>
        </div>
      ) : (
        <p className={styles.returnedNote}>
          <ArrowCounterClockwise size={16} aria-hidden="true" /> Returned for another attempt. The learner hasn’t resubmitted yet.
        </p>
      )}
      {assignment.rubric.length > 0 && Object.keys(r.scores).length > 0 && (
        <ul className={styles.breakdown}>
          {assignment.rubric.map((c) => (
            <li key={c.id}>
              <span>{c.title}</span>
              <span className="tabular">
                {r.scores[c.id] ?? '—'} / {c.points}
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
      <div className={styles.feedbackView}>
        <span className={styles.scoreLabel}>Feedback</span>
        <p>{r.feedback || 'No feedback was left.'}</p>
      </div>
      {r.privateNote && (
        <div className={styles.feedbackView}>
          <span className={styles.scoreLabel}>
            <Lock size={13} aria-hidden="true" /> Note for instructors
          </span>
          <p>{r.privateNote}</p>
        </div>
      )}
      {r.updatedAt && (
        <p className={styles.muted}>
          <CheckCircle size={13} aria-hidden="true" /> Reviewed {formatDate(r.updatedAt)}
        </p>
      )}
    </div>
  );
}
