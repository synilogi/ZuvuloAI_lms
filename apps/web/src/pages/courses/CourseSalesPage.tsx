import { Link } from 'react-router-dom';
import type { CourseSalesRow } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { services } from '@/services';

/**
 * An instructor's courses and how they are doing (docs/16, D-PLAT-10): enrolments and orders. It shows counts and not money,
 * because no revenue share has been agreed, and an amount here would read as money owed.
 */
export default function CourseSalesPage() {
  const query = useAsync('reports:course-sales', () => services.reports.courseSales());
  const rows = query.data;
  const columns: Column<CourseSalesRow>[] = [
    { key: 'course', header: 'Course', mobile: 'primary', render: (r) => <Link to={`/teach/courses/${r.courseId}`}>{r.title}</Link> },
    { key: 'pricing', header: 'Type', width: '90px', mobile: 'meta', render: (r) => (r.pricing === 'paid' ? 'Paid' : 'Free') },
    { key: 'enrolled', header: 'Enrolled', width: '100px', mobile: 'detail', render: (r) => r.enrolled.toLocaleString('en-IN') },
    { key: 'orders', header: 'Paid orders', width: '110px', mobile: 'detail', render: (r) => r.paidOrders.toLocaleString('en-IN') },
    { key: 'refunded', header: 'Refunded', width: '100px', mobile: 'detail', render: (r) => r.refundedOrders.toLocaleString('en-IN') },
  ];
  return (
    <>
      <PageHeader
        title="Course sales"
        description="Enrolments and orders for your courses. For anything about payment for your teaching, please contact the team."
      />
      {query.status === 'error' && !rows ? (
        <StateMessage kind="error" title="The figures didn’t load" actions={<Button onClick={() => void query.run().catch(() => undefined)}>Try again</Button>}>
          {query.error.message}
        </StateMessage>
      ) : !rows ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : rows.length === 0 ? (
        <StateMessage title="No courses yet">Your courses appear here once you are assigned to them.</StateMessage>
      ) : (
        <DataTable<CourseSalesRow> rows={rows} columns={columns} rowKey={(r) => r.courseId} label="Course sales" rowLabel={(r) => r.title} framed />
      )}
    </>
  );
}
