import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import {
  BookOpenText,
  CaretRight,
  ChalkboardTeacher,
  CheckCircle,
  CreditCard,
  CurrencyInr,
  Handshake,
  PaintBrush,
  Plus,
  Pulse,
  Tray,
  UserPlus,
  UsersThree,
} from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { formatRelative, greeting, plural } from '@/lib/format';
import { useNow } from '@/hooks/useNow';
import type { Tone } from '@/design/tokens';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { StatCards, StatCardsSkeleton, type StatItem } from '@/components/data/StatCards';
import { IconChip } from '@/components/ui/Badge/Badge';
import { LinkButton } from '@/components/ui/Button/Button';
import { Skeleton } from '@/components/ui/Feedback/Feedback';
import { useSession } from '@/providers/SessionProvider';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from './platformMeta';
import { money } from './subscriptions/subscriptionMeta';
import styles from './Platform.module.css';

const count = (n: number) => n.toLocaleString('en-IN');

interface AttentionRow {
  id: string;
  tone: Tone;
  icon: ReactNode;
  title: string;
  detail: string;
  action: string;
  to: string;
}

/**
 * The platform at a glance (docs/16 §2.2): the four numbers that matter, what needs doing today with a button for
 * each, and the jobs done most often. Every figure comes from `GET /superadmin/overview` — this screen only reads and
 * arranges them. Course sales, orders and the affiliate program get their own pages in later modules.
 */
export default function PlatformOverviewPage() {
  const now = useNow();
  const { user } = useSession();
  const overview = useAsync('platform:overview', () => services.platform.overview());
  const data = overview.data;
  const firstName = user.name.split(' ')[0];

  const cards: StatItem[] = data
    ? [
        {
          id: 'students',
          label: 'Students',
          help: 'Everyone learning on the platform.',
          icon: <UsersThree size={18} weight="duotone" />,
          hue: 'blue',
          value: count(data.users.students),
          note: data.people.suspendedStudents ? `${count(data.people.suspendedStudents)} suspended` : 'None suspended',
          to: '/admin/students',
          linkLabel: 'Open students',
        },
        {
          id: 'revenue',
          label: 'Course sales',
          help: 'What paid course orders have brought in, all time.',
          icon: <CurrencyInr size={18} weight="duotone" />,
          hue: 'green',
          value: money(data.sales.revenue),
          note: `${plural(data.sales.paid, 'paid order')} · ${count(data.sales.orders)} opened`,
          to: '/superadmin/sales/orders',
          linkLabel: 'See orders',
        },
        {
          id: 'instructors',
          label: 'Instructors',
          help: 'Teaching staff, approved and invited.',
          icon: <ChalkboardTeacher size={18} weight="duotone" />,
          hue: 'violet',
          value: count(data.people.instructorProfiles),
          note: data.people.inactiveInstructors ? `${count(data.people.inactiveInstructors)} inactive` : 'All active',
          to: '/admin/instructors',
          linkLabel: 'Open instructors',
        },
        {
          id: 'courses',
          label: 'Published courses',
          help: 'Courses students can join or buy.',
          icon: <BookOpenText size={18} weight="duotone" />,
          hue: 'gold',
          value: count(data.courses.published),
          note: `${count(data.learning.enrollments)} enrolments · ${count(data.learning.certificatesIssued)} certificates`,
          to: '/admin/courses',
          linkLabel: 'Open courses',
        },
      ]
    : [];

  const attention: AttentionRow[] = [];
  if (data?.inbox.new)
    attention.push({
      id: 'inbox',
      tone: 'warn',
      icon: <Tray size={18} />,
      title: `${plural(data.inbox.new, 'new request')} in the inbox`,
      detail: 'Contact and support requests waiting for a reply.',
      action: 'Open inbox',
      to: '/superadmin/inquiries?status=new',
    });
  if (data?.courses.draft)
    attention.push({
      id: 'drafts',
      tone: 'info',
      icon: <BookOpenText size={18} />,
      title: `${plural(data.courses.draft, 'course')} still in draft`,
      detail: 'Not yet visible to students. Review and publish when ready.',
      action: 'See drafts',
      to: '/admin/courses?status=draft',
    });

  const actions = [
    { id: 'course', label: 'Add a course', hint: 'Private until you publish it', icon: <Plus size={18} />, to: '/admin/courses/new' },
    { id: 'admin', label: 'Add an admin user', hint: 'A staff account with its own permissions', icon: <UserPlus size={18} />, to: '/superadmin/admins' },
    { id: 'payments', label: 'Payment setup', hint: 'The gateway course money settles to', icon: <CreditCard size={18} />, to: '/superadmin/payment-gateways' },
    { id: 'affiliates', label: 'Affiliate program', hint: 'Members, orders and the plan', icon: <Handshake size={18} />, to: '/superadmin/affiliates/members' },
    { id: 'system', label: 'Check system health', hint: 'Database, emails and storage', icon: <Pulse size={18} />, to: '/superadmin/system' },
    { id: 'branding', label: 'Change the logo', hint: 'Logo and browser icon', icon: <PaintBrush size={18} />, to: '/superadmin/branding' },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Platform overview"
        description={`${greeting(now)}, ${firstName}. Here is how the platform is doing, and what needs you today.`}
        meta={data ? <span className={styles.muted}>Updated {formatRelative(data.generatedAt, now)}</span> : undefined}
        actions={
          <LinkButton variant="primary" to="/admin/courses/new" iconStart={<Plus size={16} />}>
            Add a course
          </LinkButton>
        }
      />

      {overview.status === 'error' && !data ? (
        <PlatformError title="The overview didn’t load" error={overview.error} onRetry={() => overview.run().catch(() => undefined)} />
      ) : !data ? (
        <>
          <StatCardsSkeleton labels={['Students', 'Course sales', 'Instructors', 'Published courses']} />
          <div className={styles.overviewGrid}>
            <Skeleton height={220} radius="var(--r-lg)" />
            <Skeleton height={220} radius="var(--r-lg)" />
          </div>
        </>
      ) : (
        <>
          <StatCards items={cards} label="Key numbers" columns={4} />

          <div className={styles.overviewGrid}>
            <section className={styles.panel} aria-labelledby="platform-attention">
              <SectionHeader
                id="platform-attention"
                title="Needs your attention"
                count={attention.length || undefined}
                description={attention.length ? 'Most urgent first. Each one has a button that takes you straight there.' : undefined}
              />
              {attention.length === 0 ? (
                <p className={styles.allClear}>
                  <CheckCircle size={20} weight="duotone" aria-hidden="true" />
                  You’re all caught up — no new requests and nothing waiting in draft.
                </p>
              ) : (
                <ul className={styles.todoList}>
                  {attention.map((item) => (
                    <li key={item.id}>
                      <Link to={item.to} className={styles.todo}>
                        <IconChip tone={item.tone}>{item.icon}</IconChip>
                        <span className={styles.todoText}>
                          <span className={styles.todoTitle}>{item.title}</span>
                          <span className={styles.todoDetail}>{item.detail}</span>
                        </span>
                        <span className={styles.todoAction}>
                          {item.action}
                          <CaretRight size={12} weight="bold" aria-hidden="true" />
                        </span>
                      </Link>
                    </li>
                  ))}
                </ul>
              )}
            </section>

            <nav className={styles.panel} aria-labelledby="platform-actions">
              <SectionHeader id="platform-actions" title="Quick actions" description="The jobs done most often." />
              <ul className={styles.quickList}>
                {actions.map((a) => (
                  <li key={a.id}>
                    <Link to={a.to} className={styles.quickItem}>
                      <span className={styles.quickIcon} aria-hidden="true">
                        {a.icon}
                      </span>
                      <span className={styles.quickLabel}>
                        {a.label}
                        <span className={styles.quickHint}>{a.hint}</span>
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            </nav>
          </div>
        </>
      )}
    </div>
  );
}
