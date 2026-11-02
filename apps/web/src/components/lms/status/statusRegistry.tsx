import type { Icon } from '@phosphor-icons/react';
import {
  BookmarkSimple,
  Broadcast,
  CalendarBlank,
  Certificate,
  CheckCircle,
  Circle,
  CircleDashed,
  CircleHalf,
  ClockCounterClockwise,
  HourglassMedium,
  LockSimple,
  PaperPlaneTilt,
  PencilSimpleLine,
  Prohibit,
  SealCheck,
  Timer,
  WarningCircle,
  XCircle,
} from '@phosphor-icons/react';
import type { LmsStatus } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';

/**
 * How a state is drawn when it sits on a path (journey, timeline, curriculum).
 * Shape is the non-color channel: a reader who can't separate the tones can still
 * tell filled from ring from dashed.
 */
export type NodeShape = 'filled' | 'partial' | 'ring' | 'dashed' | 'soft' | 'pulse';

export interface StatusDefinition {
  label: string;
  tone: Tone;
  icon: Icon;
  shape: NodeShape;
  /** One line explaining the state — used in documentation and as tooltip text. */
  meaning: string;
}

/** Presentation-only states derived from domain data (a draft, an overdue deadline). They reuse the same tones and shapes. */
export type DerivedStatus = 'not-started' | 'draft' | 'overdue' | 'starting-soon' | 'cancelled';
export type StatusKey = LmsStatus | DerivedStatus;

export const statusRegistry: Record<StatusKey, StatusDefinition> = {
  locked: { label: 'Locked', tone: 'neutral', icon: LockSimple, shape: 'dashed', meaning: 'Prerequisites are not met yet. Always shown with the reason.' },
  'not-enrolled': { label: 'Not enrolled', tone: 'neutral', icon: CircleDashed, shape: 'dashed', meaning: 'Visible for discovery; preview lessons only.' },
  enrolled: { label: 'Enrolled', tone: 'info', icon: BookmarkSimple, shape: 'ring', meaning: 'Access granted, nothing started.' },
  'in-progress': { label: 'In progress', tone: 'accent', icon: CircleHalf, shape: 'partial', meaning: 'Started and not finished.' },
  completed: { label: 'Completed', tone: 'accent', icon: CheckCircle, shape: 'filled', meaning: 'Finished by the learner.' },
  upcoming: { label: 'Upcoming', tone: 'info', icon: CalendarBlank, shape: 'ring', meaning: 'Scheduled in the future.' },
  live: { label: 'Live now', tone: 'danger', icon: Broadcast, shape: 'pulse', meaning: 'Happening now — the one state that animates.' },
  expired: {
    label: 'Expired',
    tone: 'neutral',
    icon: ClockCounterClockwise,
    shape: 'soft',
    meaning: 'The window has closed. Explain what, if anything, remains.',
  },
  submitted: { label: 'Submitted', tone: 'info', icon: PaperPlaneTilt, shape: 'soft', meaning: 'Received, waiting to be picked up for review.' },
  'under-review': { label: 'Under review', tone: 'warn', icon: HourglassMedium, shape: 'soft', meaning: 'An instructor is assessing it.' },
  passed: { label: 'Passed', tone: 'accent', icon: SealCheck, shape: 'filled', meaning: 'Met or exceeded the pass mark.' },
  failed: { label: 'Not passed', tone: 'danger', icon: XCircle, shape: 'soft', meaning: 'Below the pass mark. Always pair with the next step.' },
  eligible: { label: 'Eligible', tone: 'accent', icon: Certificate, shape: 'filled', meaning: 'Every requirement is met; the learner can claim.' },
  'not-eligible': { label: 'Not yet eligible', tone: 'neutral', icon: Certificate, shape: 'dashed', meaning: 'Requirements outstanding — show what is left.' },

  // Derived
  'not-started': { label: 'Not started', tone: 'neutral', icon: Circle, shape: 'ring', meaning: 'Available and untouched.' },
  draft: { label: 'Draft saved', tone: 'accent', icon: PencilSimpleLine, shape: 'partial', meaning: 'Work saved but not submitted.' },
  overdue: { label: 'Overdue', tone: 'danger', icon: WarningCircle, shape: 'soft', meaning: 'Past the deadline; late submission still accepted.' },
  'starting-soon': { label: 'Starting soon', tone: 'info', icon: Timer, shape: 'ring', meaning: 'Within the join window — joining is open.' },
  cancelled: { label: 'Cancelled', tone: 'neutral', icon: Prohibit, shape: 'soft', meaning: 'Will not take place. Say what replaces it.' },
};
