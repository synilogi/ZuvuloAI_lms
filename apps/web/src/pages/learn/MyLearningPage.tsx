import { useParams } from 'react-router-dom';
import { BookmarkSimple, BookOpenText, CheckCircle, Hourglass, Receipt } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { RouteTabs } from '@/components/page/RouteTabs';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { services } from '@/services';
import { CourseCard, SavedCard } from './learnParts';
import styles from './Learn.module.css';

type Tab = 'in-progress' | 'completed' | 'saved';

export default function MyLearningPage() {
  const { tab: raw } = useParams();
  const tab: Tab = raw === 'completed' || raw === 'saved' ? raw : 'in-progress';
  const query = useAsync('my-learning', () => services.learning.listCourses());
  const data = query.data;
  const inProgress = data?.courses.filter((c) => c.enrollment.status !== 'completed') ?? [];
  const completed = data?.courses.filter((c) => c.enrollment.status === 'completed') ?? [];

  return (
    <div className={styles.page}>
      <PageHeader
        title="My courses"
        description="The courses you’re studying, the ones you’ve finished, and the ones you’ve saved for later."
        count={data ? plural(data.courses.length, 'course') : undefined}
        actions={
          <LinkButton variant="ghost" to="/purchases" iconStart={<Receipt size={16} />}>
            Purchases
          </LinkButton>
        }
      />
      <RouteTabs
        label="My courses"
        tabs={[
          { to: '/my-learning/in-progress', label: 'In progress', icon: <Hourglass size={16} />, count: data ? inProgress.length : undefined },
          { to: '/my-learning/completed', label: 'Completed', icon: <CheckCircle size={16} />, count: data ? completed.length : undefined },
          { to: '/my-learning/saved', label: 'Saved', icon: <BookmarkSimple size={16} />, count: data ? data.saved.length : undefined },
        ]}
      />

      {query.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="Your courses didn’t load"
          actions={
            <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      ) : !data ? (
        <ul className={`${styles.courseGrid} ${styles.courseGridWide}`} aria-busy="true">
          {Array.from({ length: 3 }, (_, i) => (
            <li key={i}>
              <Skeleton height={260} radius="var(--r-lg)" />
            </li>
          ))}
        </ul>
      ) : tab === 'saved' ? (
        data.saved.length === 0 ? (
          <StateMessage icon={<BookmarkSimple size={26} />} title="Nothing saved yet">
            Save a course from its page to keep it here until you’re ready to enroll.
          </StateMessage>
        ) : (
          <ul className={`${styles.courseGrid} ${styles.courseGridWide}`}>
            {data.saved.map((s) => (
              <SavedCard key={s.course.id} item={s} onChange={() => query.run().catch(() => undefined)} />
            ))}
          </ul>
        )
      ) : (tab === 'completed' ? completed : inProgress).length === 0 ? (
        tab === 'completed' ? (
          <StateMessage
            icon={<CheckCircle size={26} />}
            title="No finished courses yet"
            actions={
              inProgress.length ? (
                <LinkButton to="/my-learning/in-progress" variant="primary">
                  Back to your courses
                </LinkButton>
              ) : undefined
            }
          >
            Courses move here when every lesson is complete, along with any certificate you’ve earned.
          </StateMessage>
        ) : (
          <StateMessage
            icon={<BookOpenText size={26} />}
            title={data.courses.length ? 'Nothing in progress' : 'You haven’t enrolled in a course yet'}
            actions={
              data.saved.length ? (
                <LinkButton to="/my-learning/saved" variant="primary">
                  See saved courses
                </LinkButton>
              ) : undefined
            }
          >
            {data.courses.length
              ? 'You’ve finished everything you started. Pick a saved course when you’re ready for the next one.'
              : 'When you enroll, the course appears here with your next lesson ready.'}
          </StateMessage>
        )
      ) : (
        <ul className={`${styles.courseGrid} ${styles.courseGridWide}`}>
          {(tab === 'completed' ? completed : inProgress).map((c) => (
            <CourseCard key={c.course.id} item={c} />
          ))}
        </ul>
      )}
    </div>
  );
}
