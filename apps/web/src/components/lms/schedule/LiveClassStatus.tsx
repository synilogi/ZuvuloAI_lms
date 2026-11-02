import { ArrowRight, CalendarPlus, PlayCircle, VideoCamera } from '@phosphor-icons/react';
import type { LiveClass, LiveClassPhase } from '@syniastrolms/domain';
import { canJoin, deriveLiveClassPhase } from '@syniastrolms/domain';
import { formatDate, formatDuration, formatRelative, formatTimeRange } from '@/lib/format';
import { Button } from '@/components/ui/Button/Button';
import { StatusBadge, StatusLabel } from '../status/Status';
import { DateBlock, WorkRow } from '../shared/WorkRow';

interface LiveClassStatusProps {
  liveClass: LiveClass;
  instructorName?: string;
  now: Date;
  onJoin?: (cls: LiveClass) => void;
  onWatch?: (cls: LiveClass) => void;
  /** Take a place, so the learner is reminded before it starts. */
  onRemind?: (cls: LiveClass) => void;
  /** Open the class's page — offered while a built-in room waits for its host. */
  onOpen?: (cls: LiveClass) => void;
  /** The class being joined, or a place being taken: its button shows progress. */
  busy?: boolean;
}

/** A live class as a learner sees it right now — the phase decides the status and the one action offered. */
export function LiveClassStatus({ liveClass, instructorName, now, onJoin, onWatch, onRemind, onOpen, busy }: LiveClassStatusProps) {
  const phase = deriveLiveClassPhase(liveClass, now);
  const { status, action } = present(phase, liveClass, now, { onJoin, onWatch, onRemind, onOpen, busy });

  return (
    <WorkRow
      lead={<DateBlock iso={liveClass.startsAt} highlight={phase === 'live'} />}
      title={liveClass.title}
      meta={
        <>
          {formatTimeRange(liveClass.startsAt, liveClass.durationMin)}
          {instructorName && <> · {instructorName}</>}
        </>
      }
      status={status}
      action={action}
      emphasis={phase === 'live' ? 'live' : undefined}
      muted={phase === 'recording-expired' || phase === 'cancelled'}
    />
  );
}

function present(
  phase: LiveClassPhase,
  cls: LiveClass,
  now: Date,
  handlers: Pick<LiveClassStatusProps, 'onJoin' | 'onWatch' | 'onRemind' | 'onOpen' | 'busy'>,
) {
  // The built-in room opens only once its host starts it; until then there is nothing to join.
  const joinable = canJoin(phase, cls);
  const waiting = (
    <Button iconEnd={<ArrowRight size={15} />} onClick={() => handlers.onOpen?.(cls)}>
      See the class
    </Button>
  );
  switch (phase) {
    case 'live':
      return {
        status: (
          <>
            <StatusBadge status="live" />
            {cls.attending !== undefined && <span className="type-meta">{cls.attending} joined</span>}
          </>
        ),
        action: joinable ? (
          <Button variant="primary" iconStart={<VideoCamera size={16} />} loading={handlers.busy} onClick={() => handlers.onJoin?.(cls)}>
            Join now
          </Button>
        ) : null,
      };
    case 'starting-soon':
      return {
        status: (
          <>
            <StatusBadge status="starting-soon" label={`Starts ${formatRelative(cls.startsAt, now)}`} />
            {!joinable && <span className="type-meta">Waiting for the instructor to start</span>}
          </>
        ),
        action: joinable ? (
          <Button variant="primary" iconEnd={<ArrowRight size={15} />} loading={handlers.busy} onClick={() => handlers.onJoin?.(cls)}>
            Join class
          </Button>
        ) : handlers.onOpen ? (
          waiting
        ) : null,
      };
    case 'upcoming':
      return {
        status: <StatusLabel status="upcoming" label={`Starts ${formatRelative(cls.startsAt, now)}`} />,
        action: (
          <Button iconStart={<CalendarPlus size={16} />} loading={handlers.busy} onClick={() => handlers.onRemind?.(cls)}>
            Remind me
          </Button>
        ),
      };
    case 'ended': {
      // Only a recording the video service has delivered can be played; one being prepared is said so.
      const ready = cls.recording?.status === 'ready';
      return {
        status: (
          <>
            <StatusLabel
              status="completed"
              label="Ended"
              detail={
                cls.recording?.status === 'processing'
                  ? 'Recording being prepared'
                  : ready
                    ? `Recording · ${formatDuration(cls.recording?.durationMin ?? cls.durationMin)}`
                    : undefined
              }
            />
            {ready && cls.recording && <span className="type-meta">Available until {formatDate(cls.recording.availableUntil)}</span>}
          </>
        ),
        action: ready ? (
          <Button iconStart={<PlayCircle size={16} />} onClick={() => handlers.onWatch?.(cls)}>
            Watch recording
          </Button>
        ) : null,
      };
    }
    case 'recording-expired':
      return {
        // Over with no recording ever kept is just "Ended"; "expired" only when there was one.
        status: cls.recording ? <StatusLabel status="expired" label="Recording expired" /> : <StatusLabel status="completed" label="Ended" />,
        action: null,
      };
    case 'cancelled':
      return {
        status: (
          <>
            <StatusLabel status="cancelled" />
            {cls.cancelReason && <span className="type-meta">{cls.cancelReason}</span>}
          </>
        ),
        action: null,
      };
  }
}
