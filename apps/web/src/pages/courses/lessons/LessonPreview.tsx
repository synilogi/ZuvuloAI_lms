import type { ReactNode } from 'react';
import {
  ArrowLeft,
  ArrowRight,
  CalendarBlank,
  CheckCircle,
  ClipboardText,
  DownloadSimple,
  Exam,
  FilePdf,
  Play,
  Target,
  VideoCamera,
} from '@phosphor-icons/react';
import type { Lesson } from '@syniastrolms/domain';
import { formatClock, formatDay, formatDuration, formatTimeRange } from '@/lib/format';
import { Button } from '@/components/ui/Button/Button';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { lessonTypeMeta } from '@/components/lms/course/CourseIdentity';
import { VideoProgress } from '@/components/lms/progress/Meters';
import { ArticleBody } from '@/components/lms/content/ArticleBody';
import styles from './LessonPreview.module.css';

/* ─── Learner view of a lesson ─────────────────────────────────────────── */

interface LessonPreviewProps {
  lesson: Lesson;
  courseTitle: string;
  chapterTitle: string;
  chapterIndex: number;
  lessonIndex: number;
  lessonCount: number;
  previous?: string;
  next?: string;
}

export function LessonPreview({ lesson, courseTitle, chapterTitle, chapterIndex, lessonIndex, lessonCount, previous, next }: LessonPreviewProps) {
  const toast = useToast();
  const previewOnly = (what: string) => toast({ kind: 'info', title: 'Preview only', text: `${what} works for learners once the lesson is published.` });
  const c = lesson.content ?? {};

  return (
    <article className={styles.lesson}>
      <header className={styles.header}>
        <span className={styles.context}>
          {courseTitle} · Chapter {chapterIndex + 1}: {chapterTitle}
        </span>
        <h2 className={styles.title}>{lesson.title || 'Untitled lesson'}</h2>
        <span className={styles.meta}>
          {lessonTypeMeta[lesson.type].icon}
          {lessonTypeMeta[lesson.type].label} · {formatDuration(lesson.durationMin || 0)} · Lesson {lessonIndex + 1} of {lessonCount}
        </span>
      </header>

      {lesson.type === 'video' &&
        (c.video?.file ? (
          <div className={styles.player}>
            <button type="button" className={styles.playerScreen} onClick={() => previewOnly('The player')} aria-label={`Play ${lesson.title}`}>
              <span className={styles.playButton}>
                <Play size={28} weight="fill" />
              </span>
              {c.video.captions && <span className={styles.cc}>CC</span>}
            </button>
            <div className={styles.playerBar}>
              <VideoProgress
                positionSec={0}
                durationSec={c.video.durationSec ?? lesson.durationMin * 60}
                chapters={c.video.markers.map((m) => m.atSec)}
                showTimes={false}
              />
              <span className={styles.playerTime}>0:00 / {formatClock(c.video.durationSec ?? lesson.durationMin * 60)}</span>
            </div>
            {c.video.markers.length > 0 && (
              <ol className={styles.markers}>
                {c.video.markers.map((m) => (
                  <li key={m.atSec}>
                    <span className="tabular">{formatClock(m.atSec)}</span> {m.title}
                  </li>
                ))}
              </ol>
            )}
          </div>
        ) : (
          <Missing>The video hasn’t been added yet.</Missing>
        ))}

      {(lesson.type === 'reading' || lesson.type === 'practice') &&
        (c.article?.body.trim() ? (
          <ArticleBody body={c.article.body} />
        ) : (
          <Missing>{lesson.type === 'practice' ? 'The exercise hasn’t been written yet.' : 'The article is empty.'}</Missing>
        ))}

      {lesson.type === 'document' &&
        (c.document?.file ? (
          <div className={styles.pdf}>
            <div className={styles.pages} aria-hidden="true">
              <span />
              <span />
              <span />
            </div>
            <div className={styles.pdfText}>
              <FilePdf size={22} />
              <span>
                <strong>{c.document.file.name}</strong>
                <span className={styles.subtle}>
                  {c.document.pages} pages · {c.document.file.sizeMb} MB
                </span>
              </span>
            </div>
            <div className={styles.row}>
              <Button variant="primary" onClick={() => previewOnly('Reading the PDF')}>
                Read in the browser
              </Button>
              {c.document.downloadable && (
                <Button iconStart={<DownloadSimple size={16} />} onClick={() => previewOnly('Downloading')}>
                  Download
                </Button>
              )}
            </div>
          </div>
        ) : (
          <Missing>The PDF hasn’t been attached yet.</Missing>
        ))}

      {lesson.type === 'assessment' && c.quiz && (
        <Panel icon={<Exam size={22} />} title={`${c.quiz.questions || 'No'} questions`}>
          <dl className={styles.facts}>
            <div>
              <dt>Pass mark</dt>
              <dd>{c.quiz.passMark}%</dd>
            </div>
            <div>
              <dt>Attempts</dt>
              <dd>{c.quiz.attempts || 'Unlimited'}</dd>
            </div>
            <div>
              <dt>Time limit</dt>
              <dd>{c.quiz.timeLimitMin ? `${c.quiz.timeLimitMin} min` : 'None'}</dd>
            </div>
          </dl>
          <Button variant="primary" onClick={() => previewOnly('Starting the quiz')}>
            Start quiz
          </Button>
        </Panel>
      )}

      {lesson.type === 'assignment' && c.assignment && (
        <Panel icon={<ClipboardText size={22} />} title="Your task">
          {c.assignment.brief ? <p className={styles.brief}>{c.assignment.brief}</p> : <Missing>The brief hasn’t been written yet.</Missing>}
          <dl className={styles.facts}>
            <div>
              <dt>Due</dt>
              <dd>{c.assignment.dueAfterDays} days after you reach it</dd>
            </div>
            <div>
              <dt>Marked out of</dt>
              <dd>{c.assignment.maxScore}</dd>
            </div>
            <div>
              <dt>Submit as</dt>
              <dd>{c.assignment.submission === 'file' ? 'File upload' : c.assignment.submission === 'text' ? 'Written answer' : 'Chart workings'}</dd>
            </div>
          </dl>
          <Button variant="primary" onClick={() => previewOnly('Submitting')}>
            Start submission
          </Button>
        </Panel>
      )}

      {lesson.type === 'live' && c.live && (
        <Panel icon={<VideoCamera size={22} />} title={c.live.startsAt ? formatDay(c.live.startsAt) : 'Not scheduled yet'}>
          {c.live.startsAt && <p className={styles.brief}>{formatTimeRange(c.live.startsAt, c.live.durationMin)}</p>}
          <p className={styles.subtle}>{c.live.recorded ? 'Recorded — watch it here afterwards for 30 days.' : 'Not recorded.'}</p>
          <Button iconStart={<CalendarBlank size={16} />} onClick={() => previewOnly('Reminders')}>
            Remind me
          </Button>
        </Panel>
      )}

      {lesson.description && <p className={styles.description}>{lesson.description}</p>}

      {lesson.objectives && lesson.objectives.filter(Boolean).length > 0 && (
        <section className={styles.objectives}>
          <h3>
            <Target size={18} /> In this lesson you will
          </h3>
          <ul>
            {lesson.objectives.filter(Boolean).map((o) => (
              <li key={o}>{o}</li>
            ))}
          </ul>
        </section>
      )}

      <footer className={styles.footer}>
        <Button variant="ghost" iconStart={<ArrowLeft size={16} />} disabled={!previous} onClick={() => previewOnly('Navigation')}>
          {previous ? 'Previous' : 'First lesson'}
        </Button>
        <Button variant="primary" iconStart={<CheckCircle size={16} />} onClick={() => previewOnly('Marking complete')}>
          Mark complete
        </Button>
        <Button variant="ghost" iconEnd={<ArrowRight size={16} />} disabled={!next} onClick={() => previewOnly('Navigation')}>
          {next ? 'Next' : 'Last lesson'}
        </Button>
      </footer>
    </article>
  );
}

function Panel({ icon, title, children }: { icon: ReactNode; title: string; children: ReactNode }) {
  return (
    <div className={styles.panel}>
      <span className={styles.panelIcon}>{icon}</span>
      <div className={styles.panelBody}>
        <h3 className={styles.panelTitle}>{title}</h3>
        {children}
      </div>
    </div>
  );
}

function Missing({ children }: { children: ReactNode }) {
  return <p className={styles.missing}>{children}</p>;
}
