import { EnvelopeSimple, Moon } from '@phosphor-icons/react';
import type { InstructorStatus } from '@syniastrolms/domain';
import { Badge } from '@/components/ui/Badge/Badge';

export function InstructorStatusBadge({ status, size = 'sm' }: { status: InstructorStatus; size?: 'sm' | 'md' }) {
  if (status === 'active')
    return (
      <Badge size={size} tone="accent" dot>
        Active
      </Badge>
    );
  if (status === 'invited')
    return (
      <Badge size={size} tone="info" icon={<EnvelopeSimple size={13} />}>
        Invited
      </Badge>
    );
  return (
    <Badge size={size} tone="neutral" icon={<Moon size={13} />}>
      Inactive
    </Badge>
  );
}

export const EXPERTISE_SUGGESTIONS = [
  'Mathematics',
  'Physics',
  'Chemistry',
  'Biology',
  'English grammar',
  'Hindi',
  'History',
  'Geography',
  'Indian Polity',
  'Economics',
  'Rajasthan GK',
  'Reasoning',
  'Quantitative aptitude',
  'General awareness',
  'Child development and pedagogy',
  'Computer basics',
  'Exam strategy',
];

export const LANGUAGE_SUGGESTIONS = ['English', 'Hindi', 'Sanskrit', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Marathi', 'Gujarati', 'Bengali', 'Punjabi'];
