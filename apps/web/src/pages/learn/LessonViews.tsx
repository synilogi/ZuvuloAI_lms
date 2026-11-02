import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowCounterClockwise, ArrowClockwise, BookOpen, CaretLeft, CaretRight, ClosedCaptioning, FilePdf, Pause, Play } from '@phosphor-icons/react';
import type { LiveClass } from '@syniastrolms/domain';
import { useNow } from '@/hooks/useNow';
import { cx } from '@/lib/cx';
import { formatClock, plural } from '@/lib/format';
import { FileCard } from '@/components/forms/Upload';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { LiveClassStatus } from '@/components/lms/schedule/LiveClassStatus';
import { RecordingViewer, useLiveJoin } from '@/pages/live/LiveRoom';
import { services, type LessonView } from '@/services';
import styles from './Learn.module.css';

const CAPTIONS = [
  'The fourth house describes the ground a person stands on.',
  'Begin with the sign on the cusp, then find its ruler.',
  'Note where that ruler sits, by house and by dignity.',
  'Read the house, its lord and the Moon together.',
  'Three witnesses to the same question.',
];

/**
 * A video lesson. Playback is simulated in real time — the position advances, can be scrubbed,
 * sped up and resumed — and progress is saved as the learner watches.
 */
export function VideoLesson({ view, onWatched }: { view: LessonView; onWatched: (fraction: number) => void }) {
  const video = view.lesson.content?.video;
  const duration = video?.durationSec ?? view.lesson.durationMin * 60;
  const completed = view.state === 'completed';
  const [position, setPosition] = useState(completed ? 0 : (view.lessonProgress?.positionSec ?? 0));
  const [furthest, setFurthest] = useState(completed ? duration : (view.lessonProgress?.positionSec ?? 0));
  const [playing, setPlaying] = useState(false);
  const [speed, setSpeed] = useState(1);
  const [captions, setCaptions] = useState(Boolean(video?.captions));
  const lastSaved = useRef(position);
  const positionRef = useRef(position);
  positionRef.current = position;

  useEffect(() => {
    if (!playing) return;
    const id = window.setInterval(() => {
      setPosition((p) => {
        const next = Math.min(duration, p + 0.5 * speed);
        if (next >= duration) setPlaying(false);
        return next;
      });
    }, 500);
    return () => window.clearInterval(id);
  }, [playing, speed, duration]);

  useEffect(() => {
    setFurthest((f) => Math.max(f, position));
  }, [position]);

  useEffect(() => {
    onWatched(furthest / duration);
  }, [furthest, duration, onWatched]);

  // Save the position every ten seconds of playback, and when paused or leaving.
  const save = (p: number) => {
    if (!view.enrolled || completed || Math.abs(p - lastSaved.current) < 3) return;
    lastSaved.current = p;
    services.learning.savePosition(view.course.id, view.lesson.id, p, p / duration).catch(() => undefined);
  };
  useEffect(() => {
    if (playing && position - lastSaved.current >= 10) save(position);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [position, playing]);
  useEffect(
    () => () => save(positionRef.current),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );

  const seek = (to: number) => {
    const next = Math.max(0, Math.min(duration, to));
    setPosition(next);
    save(next);
  };
  const toggle = () => {
    if (position >= duration) setPosition(0);
    if (playing) save(position);
    setPlaying((p) => !p);
  };
  const markers = video?.markers ?? [];
  const caption = CAPTIONS[Math.floor(position / 40) % CAPTIONS.length];

  return (
    <div className={styles.video}>
      <div
        className={styles.screen}
        role="region"
        aria-label={`Video: ${view.lesson.title}`}
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === ' ' || e.key === 'k') {
            e.preventDefault();
            toggle();
          } else if (e.key === 'ArrowRight') seek(position + 10);
          else if (e.key === 'ArrowLeft') seek(position - 10);
        }}
      >
        <CourseCover motif={view.course.coverMotif} imageUrl={view.course.coverImageUrl} className={styles.screenArt} />
        <button
          type="button"
          className={cx(styles.bigPlay, playing && styles.bigPlayHidden)}
          onClick={toggle}
          aria-label={playing ? 'Pause' : position > 0 ? 'Resume video' : 'Play video'}
        >
          {playing ? <Pause size={30} weight="fill" /> : <Play size={30} weight="fill" />}
        </button>
        {captions && playing && <span className={styles.caption}>{caption}</span>}
        {!playing && position > 0 && position < duration && <span className={styles.resumeChip}>Paused at {formatClock(position)}</span>}
      </div>
      <div className={styles.controls}>
        <IconButton
          size="sm"
          label={playing ? 'Pause' : 'Play'}
          icon={playing ? <Pause size={16} weight="fill" /> : <Play size={16} weight="fill" />}
          onClick={toggle}
        />
        <IconButton size="sm" label="Back 10 seconds" icon={<ArrowCounterClockwise size={16} />} onClick={() => seek(position - 10)} />
        <IconButton size="sm" label="Forward 10 seconds" icon={<ArrowClockwise size={16} />} onClick={() => seek(position + 10)} />
        <span className={styles.time}>
          {formatClock(position)} / {formatClock(duration)}
        </span>
        <input
          type="range"
          className={styles.seek}
          min={0}
          max={duration}
          step={1}
          value={Math.round(position)}
          onChange={(e) => seek(Number(e.target.value))}
          aria-label="Seek"
          aria-valuetext={`${formatClock(position)} of ${formatClock(duration)}`}
          style={{ '--played': `${(position / duration) * 100}%`, '--watched': `${(furthest / duration) * 100}%` } as React.CSSProperties}
        />
        <select className={styles.speed} value={speed} onChange={(e) => setSpeed(Number(e.target.value))} aria-label="Playback speed">
          {[0.75, 1, 1.25, 1.5, 2].map((s) => (
            <option key={s} value={s}>
              {s}×
            </option>
          ))}
        </select>
        {video?.captions && (
          <IconButton
            size="sm"
            label={captions ? 'Turn captions off' : 'Turn captions on'}
            aria-pressed={captions}
            icon={<ClosedCaptioning size={18} weight={captions ? 'fill' : 'regular'} />}
            onClick={() => setCaptions((c) => !c)}
          />
        )}
      </div>
      {markers.length > 0 && (
        <ol className={styles.markers} aria-label="Video chapters">
          {markers.map((m, i) => {
            const end = markers[i + 1]?.atSec ?? duration;
            const current = position >= m.atSec && position < end;
            return (
              <li key={m.atSec}>
                <button
                  type="button"
                  className={cx(styles.marker, current && styles.markerOn)}
                  onClick={() => seek(m.atSec)}
                  aria-current={current || undefined}
                >
                  <span className="tabular">{formatClock(m.atSec)}</span> {m.title}
                </button>
              </li>
            );
          })}
        </ol>
      )}
    </div>
  );
}

/** A PDF lesson: the file, and a page-by-page reader. */
export function DocumentLesson({ view, onOpened }: { view: LessonView; onOpened: () => void }) {
  const doc = view.lesson.content?.document;
  const pages = doc?.pages ?? 8;
  const [open, setOpen] = useState(false);
  const [page, setPage] = useState(1);
  if (!doc?.file) return null;
  return (
    <div className={styles.document}>
      <FileCard icon={<FilePdf size={18} />} file={doc.file} detail={`${plural(pages, 'page')}${doc.downloadable ? ' · available offline in the app' : ''}`} />
      <ol className={styles.pageStrip} aria-label="Pages">
        {Array.from({ length: Math.min(pages, 6) }, (_, i) => (
          <li key={i}>
            <button
              type="button"
              className={styles.pageThumb}
              onClick={() => {
                setPage(i + 1);
                setOpen(true);
                onOpened();
              }}
              aria-label={`Open page ${i + 1}`}
            >
              <span className={styles.pageLines} aria-hidden="true" />
              <span className={styles.pageNumber}>{i + 1}</span>
            </button>
          </li>
        ))}
      </ol>
      <Button
        iconStart={<BookOpen size={16} />}
        onClick={() => {
          setOpen(true);
          onOpened();
        }}
      >
        Open reader
      </Button>
      <Modal
        open={open}
        onClose={() => setOpen(false)}
        width={640}
        title={doc.file.name}
        description={`Page ${page} of ${pages}`}
        footer={
          <>
            <IconButton boxed label="Previous page" icon={<CaretLeft size={16} />} disabled={page <= 1} onClick={() => setPage((p) => p - 1)} />
            <span className={styles.muted}>
              {page} / {pages}
            </span>
            <IconButton boxed label="Next page" icon={<CaretRight size={16} />} disabled={page >= pages} onClick={() => setPage((p) => p + 1)} />
          </>
        }
      >
        <div className={styles.sheet} aria-label={`Page ${page}`}>
          <span className={styles.sheetHeading}>{page === 1 ? view.lesson.title : `${view.course.title} · ${page}`}</span>
          <span className={styles.pageLines} aria-hidden="true" />
          <span className={styles.pageLines} aria-hidden="true" />
          <span className={cx(styles.pageLines, styles.pageLinesShort)} aria-hidden="true" />
        </div>
      </Modal>
    </div>
  );
}

/**
 * A live-session lesson: join while it runs — the same way in as the Live page (the built-in room, or the outside
 * meeting's link handed over by the API) — or watch the recording afterwards. Joining doesn't complete the lesson;
 * the learner marks it complete as with any other.
 */
export function LiveLesson({ live, instructorName }: { live: LiveClass; instructorName?: string }) {
  const now = useNow();
  const toast = useToast();
  const navigate = useNavigate();
  const [watching, setWatching] = useState(false);
  const [reminding, setReminding] = useState(false);
  const { join, busyId, element: joinFlow } = useLiveJoin();
  return (
    <>
      <LiveClassStatus
        liveClass={live}
        instructorName={instructorName}
        now={now}
        busy={busyId === live.id || reminding}
        onJoin={() => join(live)}
        onOpen={() => navigate(`/live/${live.id}`)}
        onWatch={() => setWatching(true)}
        onRemind={async () => {
          if (reminding) return;
          setReminding(true);
          try {
            // Taking a place is what gets the reminders; asked twice, the place is simply kept.
            await services.live.register(live.id, true);
            toast({ kind: 'success', title: 'You’re registered', text: `${live.title} · we’ll remind you before it starts` });
          } catch (e) {
            toast({ kind: 'error', title: 'Couldn’t register', text: (e as Error).message });
          } finally {
            setReminding(false);
          }
        }}
      />
      {joinFlow}
      {watching && <RecordingViewer open onClose={() => setWatching(false)} liveClass={live} />}
    </>
  );
}
