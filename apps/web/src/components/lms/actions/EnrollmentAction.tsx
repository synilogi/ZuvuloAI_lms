import { useState } from 'react';
import { ArrowRight, Certificate, CheckCircle, Eye, Infinity as InfinityIcon, VideoCamera } from '@phosphor-icons/react';
import type { Course } from '@syniastrolms/domain';
import { courseDurationMin } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatDuration } from '@/lib/format';
import { ALL_INCLUSIVE, saleDisplay } from '@/lib/coursePricing';
import { Button } from '@/components/ui/Button/Button';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import styles from './Actions.module.css';

export type EnrollmentPhase = 'available' | 'enrolling' | 'enrolled' | 'error' | 'closed';

interface EnrollmentActionProps {
  course: Course;
  /** Start in a given phase — for documentation and for courses already enrolled. */
  initialPhase?: EnrollmentPhase;
  nextCohort?: string;
  onEnrolled?: () => void;
  onStart?: () => void;
  layout?: 'panel' | 'inline';
}

/**
 * Enroll → confirm → enrolled. Confirmation is a modal because it commits money; the success
 * state replaces the action in place so the learner's next step is right where their eye already is.
 */
export function EnrollmentAction({ course, initialPhase = 'available', nextCohort, onEnrolled, onStart, layout = 'panel' }: EnrollmentActionProps) {
  const [phase, setPhase] = useState<EnrollmentPhase>(initialPhase);
  const [confirming, setConfirming] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const toast = useToast();

  const enroll = async () => {
    setConfirming(false);
    setPhase('enrolling');
    setError(null);
    try {
      await services.enrollment.enroll(course.id);
      setPhase('enrolled');
      toast({ kind: 'success', title: 'You’re enrolled', text: `${course.title} is now in My courses.` });
      onEnrolled?.();
    } catch (e) {
      setError((e as Error).message);
      setPhase('error');
    }
  };

  // What joining takes, by the shared rule: free, the course's all-inclusive price, or not open yet. This pattern
  // enrols free courses only; a paid course is bought on the course page (pages/learn/CoursePurchase.tsx).
  const sale = saleDisplay(course);
  const price = sale.label;

  const totalMin = courseDurationMin(course);
  const includes = [
    ...(totalMin > 0 ? [{ icon: <InfinityIcon size={16} />, text: `${formatDuration(totalMin)} of lessons, yours to revisit` }] : []),
    { icon: <VideoCamera size={16} />, text: `${course.liveSessions} live sessions with recordings` },
    ...(course.certificateTitle ? [{ icon: <Certificate size={16} />, text: course.certificateTitle }] : []),
  ];

  const primary =
    phase === 'enrolled' ? (
      <Button variant="primary" size="lg" block={layout === 'panel'} iconEnd={<ArrowRight size={16} />} onClick={onStart}>
        Start learning
      </Button>
    ) : phase === 'closed' ? (
      <Button size="lg" block={layout === 'panel'} disabled>
        Enrollment closed
      </Button>
    ) : (
      <Button variant="primary" size="lg" block={layout === 'panel'} loading={phase === 'enrolling'} onClick={() => setConfirming(true)}>
        {phase === 'error' ? 'Try again' : 'Enroll now'}
      </Button>
    );

  return (
    <div className={cx(styles.enroll, layout === 'inline' && styles.enrollInline)}>
      {layout === 'panel' && (
        <div className={styles.priceRow}>
          {phase === 'enrolled' ? (
            <span className={styles.enrolledNote}>
              <CheckCircle size={20} weight="fill" /> Enrolled
            </span>
          ) : (
            <>
              <span className={styles.price}>{price}</span>
              <span className={styles.priceNote}>
                {phase === 'closed'
                  ? 'This cohort is full'
                  : sale.kind === 'free'
                    ? 'No payment needed'
                    : sale.kind === 'paid'
                      ? ALL_INCLUSIVE
                      : 'The platform hasn’t opened it yet'}
              </span>
            </>
          )}
        </div>
      )}

      <div className={styles.enrollButtons}>
        {primary}
        {phase !== 'enrolled' && (
          <Button variant={layout === 'panel' ? 'quiet' : 'secondary'} size="lg" block={layout === 'panel'} iconStart={<Eye size={16} />}>
            Preview a lesson
          </Button>
        )}
      </div>

      {phase === 'error' && (
        <InlineMessage kind="error" title="Enrollment didn’t go through.">
          {error ?? 'We couldn’t complete your enrolment. Try again in a moment.'}
        </InlineMessage>
      )}
      {phase === 'closed' && nextCohort && <InlineMessage kind="info">Next cohort opens {nextCohort}. We’ll email you when enrollment starts.</InlineMessage>}

      {layout === 'panel' && (
        <ul className={styles.includes}>
          {includes.map((item) => (
            <li key={item.text}>
              {item.icon}
              {item.text}
            </li>
          ))}
        </ul>
      )}

      <Modal
        open={confirming}
        onClose={() => setConfirming(false)}
        icon={<Certificate size={20} />}
        title="Confirm enrollment"
        description="You can start immediately. Live session links appear in your calendar once enrolled."
        footer={
          <>
            <Button onClick={() => setConfirming(false)}>Cancel</Button>
            <Button variant="primary" onClick={enroll} data-autofocus>
              Confirm enrollment
            </Button>
          </>
        }
      >
        <dl className={styles.confirmList}>
          <div>
            <dt>Course</dt>
            <dd>{course.title}</dd>
          </div>
          <div>
            <dt>Format</dt>
            <dd className={styles.capitalize}>{course.format.replace('-', ' ')}</dd>
          </div>
          <div>
            <dt>Total</dt>
            <dd className={styles.confirmTotal}>{price}</dd>
          </div>
        </dl>
      </Modal>
    </div>
  );
}
