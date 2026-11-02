import { useState } from 'react';
import { useParams } from 'react-router-dom';
import { Certificate, DesktopTower, DeviceMobile, Eye, Infinity as InfinityIcon, Lock, SignOut, VideoCamera } from '@phosphor-icons/react';
import { courseDurationMin } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { cx } from '@/lib/cx';
import { formatDuration, pad2 } from '@/lib/format';
import { ALL_INCLUSIVE, saleDisplay } from '@/lib/coursePricing';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { Tooltip } from '@/components/ui/Tooltip/Tooltip';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CourseCurriculum } from '@/components/lms/course/CourseCurriculum';
import { CourseIdentity } from '@/components/lms/course/CourseIdentity';
import { courseStatusMeta } from '@/components/lms/course/CourseStatus';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import styles from './CoursePreview.module.css';

type Device = 'desktop' | 'mobile';

/** The course page exactly as a learner would meet it, with enrollment switched off. */
export default function CoursePreviewPage() {
  const { courseId } = useParams();
  const { base, instructorId } = useWorkspace();
  const { isMobile } = useViewport();
  const toast = useToast();
  const [device, setDevice] = useState<Device>('desktop');

  const query = useAsync(`course-preview:${courseId}`, () =>
    Promise.all([
      services.courses.get(courseId!, instructorId),
      services.catalog.listLevels(),
      services.catalog.listCategories(),
      services.catalog.listInstructors(),
    ]).then(([course, levels, categories, instructors]) => ({ course, levels, categories, instructors })),
  );
  const to = `${base}/courses/${courseId}`;
  usePageCrumbs(query.data ? [{ label: query.data.course.title, to }, { label: 'Preview' }] : [{ label: 'Preview' }]);

  if (query.status === 'error' && !query.data) {
    return (
      <StateMessage kind="error" title="Preview didn’t load" actions={<LinkButton to={`${base}/courses`}>Back to courses</LinkButton>}>
        {query.error.message}
      </StateMessage>
    );
  }

  const data = query.data;
  const course = data?.course;
  const note = course ? courseStatusMeta[course.status] : undefined;
  const frame = isMobile ? 'desktop' : device;

  return (
    <div className={styles.page}>
      <div className={styles.bar} role="region" aria-label="Preview controls">
        <span className={styles.barLabel}>
          <Eye size={18} /> Learner preview
        </span>
        {course && note && (
          <span className={styles.barNote}>
            {course.status === 'published'
              ? 'This is what learners see now.'
              : `${note.label} — ${course.status === 'draft' ? 'learners can’t see this yet.' : 'closed to new learners.'}`}
          </span>
        )}
        <span className={styles.barActions}>
          {!isMobile && (
            <SegmentedControl<Device>
              size="sm"
              label="Preview width"
              value={device}
              onChange={setDevice}
              segments={[
                { value: 'desktop', label: 'Desktop', icon: <DesktopTower size={15} /> },
                { value: 'mobile', label: 'Mobile', icon: <DeviceMobile size={15} /> },
              ]}
            />
          )}
          <LinkButton to={to} size="sm" iconStart={<SignOut size={15} />}>
            Exit preview
          </LinkButton>
        </span>
      </div>

      <div className={cx(styles.stage, frame === 'mobile' && styles.stageMobile)}>
        <div className={styles.canvas}>
          {!data || !course ? (
            <div className={styles.skeleton} role="status" aria-label="Loading preview">
              <Skeleton width="40%" height={12} />
              <Skeleton width="70%" height={36} radius="var(--r-xs)" />
              <Skeleton height={220} radius="var(--r-lg)" />
            </div>
          ) : (
            <>
              <CourseIdentity
                course={course}
                levels={data.levels}
                category={data.categories.find((c) => c.id === course.categoryId)}
                instructors={course.instructorIds.map((id) => data.instructors.find((i) => i.id === id)!).filter(Boolean)}
              />
              <div className={styles.body}>
                <div className={styles.main}>
                  {course.description && (
                    <section>
                      <h2 className={styles.sectionTitle}>About this course</h2>
                      <p className={styles.prose}>{course.description}</p>
                    </section>
                  )}
                  {course.outcomes.length > 0 && (
                    <section>
                      <h2 className={styles.sectionTitle}>What you’ll learn</h2>
                      <ol className={styles.outcomes}>
                        {course.outcomes.map((o, i) => (
                          <li key={o}>
                            <span className={styles.outcomeIndex} aria-hidden="true">
                              {pad2(i + 1)}
                            </span>
                            {o}
                          </li>
                        ))}
                      </ol>
                    </section>
                  )}
                  <section>
                    <h2 className={styles.sectionTitle}>Curriculum</h2>
                    {course.chapters.length ? (
                      <CourseCurriculum
                        course={course}
                        enrolled={false}
                        onSelectLesson={(l) =>
                          toast({
                            kind: 'info',
                            title: l.isPreview ? `Free preview: ${l.title}` : 'Locked for learners who aren’t enrolled',
                            text: l.isPreview ? 'Visitors can watch this lesson before enrolling.' : 'Mark a lesson as a free preview to open it to visitors.',
                          })
                        }
                      />
                    ) : (
                      <p className={styles.empty}>The curriculum is being prepared. Learners will see chapters here once they are added.</p>
                    )}
                  </section>
                  {course.instructorIds.length > 0 && (
                    <section>
                      <h2 className={styles.sectionTitle}>Your {course.instructorIds.length === 1 ? 'instructor' : 'instructors'}</h2>
                      <ul className={styles.instructors}>
                        {course.instructorIds.map((id) => {
                          const person = data.instructors.find((i) => i.id === id);
                          if (!person) return null;
                          return (
                            <li key={id}>
                              <Avatar name={person.name} size={48} />
                              <div>
                                <p className={styles.instructorName}>{person.name}</p>
                                <p className={styles.instructorTitle}>
                                  {person.title}
                                  {person.yearsTeaching ? ` · ${person.yearsTeaching} years teaching` : ''}
                                </p>
                                <p className={styles.instructorBio}>{person.bio}</p>
                              </div>
                            </li>
                          );
                        })}
                      </ul>
                    </section>
                  )}
                </div>
                <aside className={styles.aside}>
                  <div className={styles.enroll}>
                    <p className={styles.price}>{saleDisplay(course).label}</p>
                    <p className={styles.priceNote}>
                      {saleDisplay(course).kind === 'paid'
                        ? `${ALL_INCLUSIVE} · learners pay online`
                        : saleDisplay(course).kind === 'free'
                          ? 'No payment needed'
                          : 'Choose Free or Paid in the course editor first'}
                    </p>
                    <Tooltip content="Enrollment is switched off in preview" side="bottom">
                      <Button
                        variant="primary"
                        size="lg"
                        block
                        iconStart={<Lock size={16} />}
                        aria-disabled="true"
                        onClick={() => toast({ kind: 'info', title: 'Preview only', text: 'Learners enrol here once the course is published.' })}
                      >
                        Enroll now
                      </Button>
                    </Tooltip>
                    <ul className={styles.includes}>
                      {courseDurationMin(course) > 0 && (
                        <li>
                          <InfinityIcon size={16} />
                          {formatDuration(courseDurationMin(course))} of lessons, yours to revisit
                        </li>
                      )}
                      {course.liveSessions > 0 && (
                        <li>
                          <VideoCamera size={16} />
                          {course.liveSessions} live sessions with recordings
                        </li>
                      )}
                      {course.certificateTitle && (
                        <li>
                          <Certificate size={16} />
                          {course.certificateTitle}
                        </li>
                      )}
                    </ul>
                  </div>
                </aside>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
