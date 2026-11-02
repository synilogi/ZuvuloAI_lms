import type { LiveClass, LiveClassPhase } from '@syniastrolms/domain';
import { StatusBadge } from '@/components/lms/status/Status';

/**
 * A class's phase as a badge. A class that is over with no recording ever kept is simply "Ended" — the phase calls it
 * recording-expired, but saying so of a class that was never recorded would be wrong.
 */
export function PhaseBadge({ phase, size = 'sm', liveClass }: { phase: LiveClassPhase; size?: 'sm' | 'md'; liveClass?: Pick<LiveClass, 'recording'> }) {
  if (phase === 'recording-expired' && liveClass && !liveClass.recording) return <StatusBadge status="completed" size={size} label="Ended" />;
  if (phase === 'live') return <StatusBadge status="live" size={size} />;
  if (phase === 'starting-soon') return <StatusBadge status="starting-soon" size={size} />;
  if (phase === 'upcoming') return <StatusBadge status="upcoming" size={size} label="Scheduled" />;
  if (phase === 'ended') return <StatusBadge status="completed" size={size} label="Ended" />;
  if (phase === 'recording-expired') return <StatusBadge status="expired" size={size} label="Recording expired" />;
  return <StatusBadge status="cancelled" size={size} />;
}

export const REMINDER_OPTIONS: { minutes: number; label: string }[] = [
  { minutes: 1440, label: 'A day before' },
  { minutes: 60, label: 'An hour before' },
  { minutes: 15, label: '15 minutes before' },
];

export const seatsText = (registered = 0, capacity?: number) => (capacity ? `${registered} of ${capacity} places` : `${registered} registered`);
