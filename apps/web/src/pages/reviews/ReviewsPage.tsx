import { useState } from 'react';
import { ChatCircleText, MagnifyingGlass } from '@phosphor-icons/react';
import type { CourseReviewStatus, StaffCourseReview } from '@syniastrolms/domain';
import { REVIEW_STATUSES } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatDate } from '@/lib/format';
import { canModerateReviews, REVIEW_STATUS_LABEL } from '@/lib/reviews';
import { PageHeader } from '@/components/page/PageHeader';
import { Rating } from '@/components/lms/shared/Rating';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Select } from '@/components/ui/Field/Field';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { useSession } from '@/providers/SessionProvider';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import styles from './Reviews.module.css';

const PAGE_SIZE = 20;

/**
 * Course reviews for staff: an instructor reads those of the courses they teach, an admin reads every course's and can
 * hide or show one. The API decides the scope from the token. Comments are plain text, shown as text.
 */
export default function ReviewsPage() {
  usePageCrumbs([{ label: 'Reviews' }]);
  const toast = useToast();
  const { role } = useSession();
  const { can } = usePermissions();
  const { isTeaching, instructorId } = useWorkspace();
  const canModerate = canModerateReviews(role, can);

  const [status, setStatus] = useState<CourseReviewStatus | 'all'>('all');
  const [courseId, setCourseId] = useState('');
  const [page, setPage] = useState(1);
  const [hiding, setHiding] = useState<StaffCourseReview | null>(null);
  const [busyId, setBusyId] = useState<string>();

  const list = useAsync(`staff-reviews:${isTeaching}:${status}:${courseId}:${page}`, () =>
    services.reports.reviews({
      status: status === 'all' ? undefined : status,
      courseId: courseId || undefined,
      page,
      pageSize: PAGE_SIZE,
      ...(isTeaching ? { scopeInstructorId: instructorId } : {}),
    }),
  );
  const data = list.data;
  const reload = () => list.run().catch(() => undefined);
  const filtered = status !== 'all' || Boolean(courseId);

  const show = async (review: StaffCourseReview) => {
    setBusyId(review.id);
    try {
      await services.reports.showReview(review.id);
      toast({ kind: 'success', title: 'The review is back on the course page', text: review.courseTitle });
      await reload();
    } catch (err) {
      toast({ kind: 'error', title: 'Couldn’t show the review', text: (err as Error).message });
    } finally {
      setBusyId(undefined);
    }
  };

  const hide = async (review: StaffCourseReview) => {
    await services.reports.hideReview(review.id);
    toast({ kind: 'success', title: 'The review is hidden', text: 'It no longer counts towards the course’s rating.' });
    setHiding(null);
    await reload();
  };

  const columns: Column<StaffCourseReview>[] = [
    {
      key: 'review',
      header: 'Review',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <Rating value={r.rating} />
          <span className={r.comment ? styles.comment : styles.noComment}>{r.comment || 'No comment'}</span>
        </span>
      ),
    },
    {
      key: 'course',
      header: 'Course',
      width: '220px',
      mobile: 'meta',
      render: (r) => r.courseTitle,
    },
    { key: 'learner', header: 'Learner', width: '170px', mobile: 'detail', render: (r) => r.learnerName },
    {
      key: 'status',
      header: 'Status',
      width: '110px',
      mobile: 'status',
      render: (r) => (
        <Badge size="sm" tone={r.status === 'published' ? 'accent' : 'warn'}>
          {REVIEW_STATUS_LABEL[r.status]}
        </Badge>
      ),
    },
    { key: 'date', header: 'Written', width: '120px', mobile: 'detail', render: (r) => formatDate(r.createdAt) },
    ...(canModerate
      ? [
          {
            key: 'actions',
            header: '',
            align: 'end' as const,
            width: '90px',
            mobile: 'detail' as const,
            render: (r: StaffCourseReview) =>
              r.status === 'published' ? (
                <Button size="sm" onClick={() => setHiding(r)}>
                  Hide
                </Button>
              ) : (
                <Button size="sm" loading={busyId === r.id} onClick={() => void show(r)}>
                  Show
                </Button>
              ),
          },
        ]
      : []),
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        title="Reviews"
        count={data ? data.total : undefined}
        description={
          isTeaching
            ? 'What learners say about the courses you teach, including anything an admin has hidden. Hiding a review is for admins.'
            : 'What learners say about every course. A hidden review leaves the course page and stops counting towards its rating; its author can still see and edit it.'
        }
      />
      <div className={styles.controls}>
        <SegmentedControl<CourseReviewStatus | 'all'>
          label="Status"
          value={status}
          onChange={(v) => {
            setStatus(v);
            setPage(1);
          }}
          segments={[{ value: 'all', label: 'All' }, ...REVIEW_STATUSES.map((s) => ({ value: s, label: REVIEW_STATUS_LABEL[s] }))]}
        />
        <Select
          aria-label="Course"
          value={courseId}
          onChange={(e) => {
            setCourseId(e.target.value);
            setPage(1);
          }}
        >
          <option value="">Every course</option>
          {data?.courses.map((c) => (
            <option key={c.id} value={c.id}>
              {c.title}
            </option>
          ))}
        </Select>
      </div>

      {list.status === 'error' && !data ? (
        <StateMessage kind="error" title="The reviews didn’t load" actions={<Button onClick={() => void reload()}>Try again</Button>}>
          {list.error.message}
        </StateMessage>
      ) : (
        <>
          <DataTable<StaffCourseReview>
            framed
            rows={data?.rows ?? []}
            columns={columns}
            rowKey={(r) => r.id}
            label="Course reviews"
            rowLabel={(r) => `${r.courseTitle}, ${r.rating} of 5, by ${r.learnerName}`}
            loading={!data}
            empty={
              filtered ? (
                <StateMessage
                  icon={<MagnifyingGlass size={26} />}
                  title="No reviews match"
                  compact
                  actions={
                    <Button
                      onClick={() => {
                        setStatus('all');
                        setCourseId('');
                        setPage(1);
                      }}
                    >
                      Clear filters
                    </Button>
                  }
                >
                  Try another status or course.
                </StateMessage>
              ) : (
                <StateMessage icon={<ChatCircleText size={26} />} title="No reviews yet" compact>
                  {isTeaching ? 'Reviews of your courses appear here as learners write them.' : 'Reviews appear here as learners write them.'}
                </StateMessage>
              )
            }
          />
          {data && data.total > PAGE_SIZE && <Pagination page={page} pageCount={Math.ceil(data.total / PAGE_SIZE)} onChange={setPage} />}
        </>
      )}

      <ConfirmDialog
        open={hiding !== null}
        onClose={() => setHiding(null)}
        onConfirm={() => (hiding ? hide(hiding) : undefined)}
        title="Hide this review?"
        description={hiding?.courseTitle}
        confirmLabel="Hide review"
        tone="danger"
      >
        <p>It leaves the course page and stops counting towards the course’s rating. You can show it again at any time, and its author is not told.</p>
      </ConfirmDialog>
    </div>
  );
}
