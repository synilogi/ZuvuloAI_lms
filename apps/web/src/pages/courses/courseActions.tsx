import { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Archive,
  ArrowCounterClockwise,
  CheckCircle,
  Circle,
  DotsThree,
  Eye,
  EyeSlash,
  LinkSimple,
  PencilSimple,
  RocketLaunch,
  SquaresFour,
  UserPlus,
} from '@phosphor-icons/react';
import type { Course } from '@syniastrolms/domain';
import { hasPublishedLessons, publishChecklist } from '@syniastrolms/domain';
import { formatCount } from '@/lib/format';
import { IconButton } from '@/components/ui/Button/Button';
import { Menu, type MenuSection } from '@/components/ui/Menu/Menu';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { visibilityMeta } from '@/components/lms/course/CourseStatus';
import { services } from '@/services';
import styles from './Courses.module.css';

export type StatusAction = 'publish' | 'unpublish' | 'archive' | 'restore';

/** Where a learner joins this course, and the platform it belongs to: the course's enrolment link. */
export const enrolmentLinkFor = (courseId: string, origin = window.location.origin) => `${origin}/courses/${courseId}/enroll`;

/** Only a published course that isn't private takes learners through its link. */
export const hasEnrolmentLink = (course: Pick<Course, 'status' | 'visibility'>) => course.status === 'published' && course.visibility !== 'private';

/** Copies the course's enrolment link, saying so in a toast. */
export function useCopyEnrolmentLink() {
  const toast = useToast();
  return async (course: Pick<Course, 'id' | 'title'>) => {
    const link = enrolmentLinkFor(course.id);
    try {
      await navigator.clipboard.writeText(link);
      toast({ kind: 'success', title: 'Enrolment link copied', text: `Learners who open it join the platform and enrol in ${course.title}.` });
    } catch {
      toast({ kind: 'error', title: 'Couldn’t copy the link', text: link });
    }
  };
}

/** Publish, unpublish, archive and restore — each behind a dialog that states its consequences. */
export function useCourseStatusActions(base: string, onChanged: (course: Course) => void) {
  const [pending, setPending] = useState<{ action: StatusAction; course: Course } | null>(null);
  const toast = useToast();
  const close = () => setPending(null);

  const run = async () => {
    if (!pending) return;
    const { action, course } = pending;
    const next = await services.courses[action](course.id);
    close();
    onChanged(next);
    const messages: Record<StatusAction, { title: string; text: string }> = {
      publish: { title: 'Course published', text: `${course.title} is live for learners.` },
      unpublish: { title: 'Moved to drafts', text: `${course.title} is no longer in the catalog.` },
      archive: { title: 'Course archived', text: `${course.title} is closed to new learners.` },
      restore: { title: 'Restored to drafts', text: `${course.title} can be edited and published again.` },
    };
    toast({ kind: 'success', ...messages[action] });
  };

  const dialog = pending ? <StatusDialog action={pending.action} course={pending.course} base={base} onClose={close} onConfirm={run} /> : null;
  return { request: (action: StatusAction, course: Course) => setPending({ action, course }), dialog };
}

function StatusDialog({
  action,
  course,
  base,
  onClose,
  onConfirm,
}: {
  action: StatusAction;
  course: Course;
  base: string;
  onClose: () => void;
  onConfirm: () => Promise<void>;
}) {
  if (action === 'publish') {
    const checks = publishChecklist(course);
    const unmet = checks.filter((c) => !c.met).length;
    return (
      <ConfirmDialog
        open
        onClose={onClose}
        onConfirm={onConfirm}
        icon={<RocketLaunch size={20} />}
        title={unmet ? 'Not ready to publish yet' : `Publish ${course.title}?`}
        description={
          unmet
            ? `${unmet} ${unmet === 1 ? 'item needs' : 'items need'} attention before learners can see this course.`
            : `${visibilityMeta[course.visibility].label}: ${visibilityMeta[course.visibility].description}`
        }
        confirmLabel="Publish course"
        blocked={unmet > 0}
      >
        <ul className={styles.checklist} aria-label="Publishing checklist">
          {checks.map((check) => (
            <li key={check.id} className={check.met ? styles.checkMet : styles.checkUnmet}>
              {check.met ? <CheckCircle size={18} weight="fill" /> : <Circle size={18} />}
              <span>{check.label}</span>
              <span className="sr-only">{check.met ? 'done' : 'not done'}</span>
            </li>
          ))}
        </ul>
        {unmet > 0 ? (
          <Link to={`${base}/courses/${course.id}/edit`} className={styles.dialogLink} onClick={onClose}>
            Open the editor to finish
          </Link>
        ) : (
          !hasPublishedLessons(course) && (
            <p className={styles.impactText}>
              No published lessons yet. Learners who enrol will see an empty curriculum until you add some — you can do that after publishing.
            </p>
          )
        )}
      </ConfirmDialog>
    );
  }

  if (action === 'unpublish') {
    return (
      <ConfirmDialog
        open
        onClose={onClose}
        onConfirm={onConfirm}
        icon={<EyeSlash size={20} />}
        title="Move this course to drafts?"
        description={course.title}
        confirmLabel="Move to drafts"
      >
        <ul className={styles.impact}>
          <li>It leaves the catalog and search, and new learners can’t enrol.</li>
          <li>
            {course.enrolledCount
              ? `${formatCount(course.enrolledCount)} enrolled learners keep access to everything they’ve started.`
              : 'No one is enrolled yet.'}
          </li>
          <li>You can publish it again at any time.</li>
        </ul>
      </ConfirmDialog>
    );
  }

  if (action === 'archive') {
    return (
      <ConfirmDialog
        open
        onClose={onClose}
        onConfirm={onConfirm}
        tone="danger"
        icon={<Archive size={20} />}
        title="Archive this course?"
        description={course.title}
        confirmLabel="Archive course"
        acknowledge="I understand new learners can no longer enrol"
      >
        <ul className={styles.impact}>
          <li>The course closes to new enrollments and leaves every catalog.</li>
          <li>
            {course.enrolledCount
              ? `${formatCount(course.enrolledCount)} enrolled learners keep access to lessons and recordings.`
              : 'No learners are affected.'}
          </li>
          <li>Certificates already issued stay valid and verifiable.</li>
          <li>Archived courses can be restored to drafts later.</li>
        </ul>
      </ConfirmDialog>
    );
  }

  return (
    <ConfirmDialog
      open
      onClose={onClose}
      onConfirm={onConfirm}
      icon={<ArrowCounterClockwise size={20} />}
      title="Restore to drafts?"
      description={course.title}
      confirmLabel="Restore course"
    >
      <p className={styles.impactText}>The course returns as a draft. Review its content before publishing it again.</p>
    </ConfirmDialog>
  );
}

interface CourseMenuProps {
  course: Course;
  base: string;
  canArchive: boolean;
  onAction: (action: StatusAction, course: Course) => void;
  navigate: (to: string) => void;
  /** Hide "View details" when already on the details page. */
  onDetails?: boolean;
  size?: 'sm' | 'md';
}

/** The overflow menu for a course. Destructive and status-changing actions are grouped last. */
export function CourseMenu({ course, base, canArchive, onAction, navigate, onDetails, size = 'sm' }: CourseMenuProps) {
  const toast = useToast();
  const copyEnrolmentLink = useCopyEnrolmentLink();
  const to = `${base}/courses/${course.id}`;
  const sections: MenuSection[] = [
    {
      items: [
        ...(onDetails ? [] : [{ id: 'view', label: 'View details', icon: <SquaresFour size={17} />, onSelect: () => navigate(to) }]),
        { id: 'edit', label: 'Edit course', icon: <PencilSimple size={17} />, onSelect: () => navigate(`${to}/edit`) },
        { id: 'preview', label: 'Preview as learner', icon: <Eye size={17} />, onSelect: () => navigate(`${to}/preview`) },
        {
          id: 'copy',
          label: 'Copy course link',
          icon: <LinkSimple size={17} />,
          onSelect: () => {
            navigator.clipboard?.writeText(`https://zuviloai.com/courses/${course.slug}`).catch(() => undefined);
            toast({ kind: 'success', title: 'Link copied', text: `zuviloai.com/courses/${course.slug}` });
          },
        },
        ...(hasEnrolmentLink(course)
          ? [{ id: 'enrolment-link', label: 'Copy enrolment link', icon: <UserPlus size={17} />, onSelect: () => void copyEnrolmentLink(course) }]
          : []),
      ],
    },
    {
      items: [
        ...(course.status === 'draft'
          ? [{ id: 'publish', label: 'Publish…', icon: <RocketLaunch size={17} />, onSelect: () => onAction('publish', course) }]
          : []),
        ...(course.status === 'published'
          ? [{ id: 'unpublish', label: 'Move to drafts…', icon: <EyeSlash size={17} />, onSelect: () => onAction('unpublish', course) }]
          : []),
        ...(canArchive && course.status !== 'archived'
          ? [{ id: 'archive', label: 'Archive…', icon: <Archive size={17} />, tone: 'danger' as const, onSelect: () => onAction('archive', course) }]
          : []),
        ...(canArchive && course.status === 'archived'
          ? [{ id: 'restore', label: 'Restore to drafts…', icon: <ArrowCounterClockwise size={17} />, onSelect: () => onAction('restore', course) }]
          : []),
      ],
    },
  ].filter((s) => s.items.length > 0);

  return (
    <Menu
      align="end"
      width={220}
      sections={sections}
      trigger={(props) => <IconButton {...props} size={size} label={`Actions for ${course.title}`} icon={<DotsThree size={18} weight="bold" />} />}
    />
  );
}
