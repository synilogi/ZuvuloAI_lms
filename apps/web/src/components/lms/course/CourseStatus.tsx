import type { ReactNode } from 'react';
import { Archive, CheckCircle, Globe, LinkSimple, LockSimple, PencilSimpleLine } from '@phosphor-icons/react';
import type { CourseStatus, CourseVisibility } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';
import { Badge } from '@/components/ui/Badge/Badge';
import styles from './Course.module.css';

/** Publishing state of a course — a content state, separate from a learner's progress states. */
export const courseStatusMeta: Record<CourseStatus, { label: string; tone: Tone; icon: ReactNode; meaning: string }> = {
  draft: { label: 'Draft', tone: 'warn', icon: <PencilSimpleLine size={13} />, meaning: 'Only staff can see it. Nothing is visible to learners.' },
  published: { label: 'Published', tone: 'accent', icon: <CheckCircle size={13} />, meaning: 'Learners can find it and enrol, subject to visibility.' },
  archived: { label: 'Archived', tone: 'neutral', icon: <Archive size={13} />, meaning: 'Closed to new learners. Enrolled learners keep access.' },
};

export const visibilityMeta: Record<CourseVisibility, { label: string; icon: ReactNode; description: string }> = {
  public: { label: 'Public', icon: <Globe size={15} />, description: 'Listed in the catalog and search.' },
  unlisted: { label: 'Unlisted', icon: <LinkSimple size={15} />, description: 'Anyone with the link can enrol; hidden from the catalog.' },
  private: { label: 'Private', icon: <LockSimple size={15} />, description: 'Only learners you add or invite can enrol.' },
};

export function CourseStatusBadge({ status, size = 'md' }: { status: CourseStatus; size?: 'sm' | 'md' }) {
  const meta = courseStatusMeta[status];
  return (
    <Badge tone={meta.tone} icon={meta.icon} size={size} title={meta.meaning}>
      {meta.label}
    </Badge>
  );
}

export function VisibilityLabel({ visibility }: { visibility: CourseVisibility }) {
  const meta = visibilityMeta[visibility];
  return (
    <span className={styles.visibility}>
      {meta.icon}
      {meta.label}
    </span>
  );
}
