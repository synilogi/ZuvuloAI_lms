import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Certificate, MagnifyingGlass, SealCheck, Stamp, WarningCircle } from '@phosphor-icons/react';
import type { IssuedCertificateStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { formatDate, formatRelative, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { RouteTabs } from '@/components/page/RouteTabs';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { services, type CertificateRow } from '@/services';
import { CertificateStatusBadge, Verification } from './certificateMeta';
import styles from './Certificates.module.css';

const PAGE_SIZE = 25;

export function CertificateTabs() {
  return (
    <RouteTabs
      label="Certificates"
      tabs={[
        { to: '/admin/certificates', label: 'Issued', icon: <SealCheck size={16} />, end: true },
        { to: '/admin/certificates/templates', label: 'Templates', icon: <Stamp size={16} /> },
      ]}
    />
  );
}

export default function CertificatesPage() {
  const navigate = useNavigate();
  const now = useNow();
  const { isMobile } = useViewport();
  const [params, setParams] = useSearchParams();
  const search = params.get('q') ?? '';
  const courseId = params.get('course') ?? '';
  const status = (params.get('status') as IssuedCertificateStatus | 'all' | null) ?? 'all';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const update = (next: Record<string, string | undefined>, keepPage = false) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || v === 'all') p.delete(k);
      else p.set(k, v);
    }
    if (!keepPage) p.delete('page');
    setParams(p, { replace: true });
  };

  const query = { search, courseId: courseId || undefined, status, page, pageSize: PAGE_SIZE };
  const list = useAsync(`certificates:${JSON.stringify(query)}`, () => services.certificates.list(query));
  const courses = useAsync('certificate-courses', () => services.courses.list({ page: 1, pageSize: 100 }));
  const data = list.data;
  const rows = data?.rows ?? [];
  const filtered = Boolean(search || courseId || status !== 'all');
  const to = (r: CertificateRow) => `/admin/certificates/${r.certificate.id}`;

  const columns: Column<CertificateRow>[] = [
    {
      key: 'certificate',
      header: 'Certificate',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <Link to={to(r)} className={styles.cellTitle}>
            {r.certificate.title}
          </Link>
          <span className={styles.cellMeta}>{r.courseTitle}</span>
        </span>
      ),
    },
    {
      key: 'student',
      header: 'Learner',
      mobile: 'meta',
      render: (r) => (
        <span className={styles.person}>
          <Avatar name={r.studentName} size={28} />
          <span className={styles.stack}>
            <span className={styles.personName}>{r.studentName}</span>
            <span className={styles.cellMeta}>{r.studentEmail}</span>
          </span>
        </span>
      ),
    },
    {
      key: 'issued',
      header: 'Issued',
      width: '130px',
      mobile: 'detail',
      render: (r) =>
        r.certificate.issuedAt ? (
          <time dateTime={r.certificate.issuedAt} title={formatDate(r.certificate.issuedAt)} className={styles.nowrap}>
            {formatDate(r.certificate.issuedAt)}
          </time>
        ) : (
          <span className={styles.muted}>Completed {formatRelative(r.certificate.completedAt, now)}</span>
        ),
    },
    {
      key: 'credential',
      header: 'Credential ID',
      width: '170px',
      mobile: 'detail',
      render: (r) => <span className={styles.mono}>{r.certificate.credentialId}</span>,
    },
    { key: 'status', header: 'Status', width: '120px', mobile: 'status', render: (r) => <CertificateStatusBadge status={r.certificate.status} /> },
    { key: 'verification', header: 'Verification', width: '150px', mobile: 'detail', render: (r) => <Verification certificate={r.certificate} /> },
    {
      key: 'actions',
      header: 'Actions',
      width: '100px',
      align: 'end',
      mobile: 'hidden',
      render: (r) => (
        <LinkButton size="sm" variant={r.certificate.status === 'pending' ? 'primary' : 'secondary'} to={to(r)}>
          {r.certificate.status === 'pending' ? 'Review' : 'Open'}
        </LinkButton>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        title="Certificates"
        count={data ? plural(data.counts.all, 'certificate') : undefined}
        description="Certificates earned across the platform. Issue the ones waiting, check a credential, or revoke one after a review."
      />
      <CertificateTabs />

      <div className={styles.controls} hidden={data?.counts.all === 0 && !filtered}>
        <SegmentedControl<IssuedCertificateStatus | 'all'>
          label="Certificate status"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: data?.counts.all },
            { value: 'pending', label: 'Ready to issue', count: data?.counts.pending },
            { value: 'issued', label: 'Issued', count: data?.counts.issued },
            { value: 'revoked', label: 'Revoked', count: data?.counts.revoked },
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput
              value={search}
              onValueChange={(v) => update({ q: v })}
              placeholder="Search learner, email or credential ID"
              aria-label="Search certificates"
            />
          </div>
          <Field label="Course" hideLabel className={styles.filter}>
            <Select value={courseId} onChange={(e) => update({ course: e.target.value })}>
              <option value="">All courses</option>
              {courses.data?.rows
                .filter((c) => c.certificateTitle)
                .map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.title}
                  </option>
                ))}
            </Select>
          </Field>
        </div>
      </div>

      {data && data.counts.pending > 0 && status === 'all' && !search && (
        <div className={styles.notice}>
          <WarningCircle size={18} aria-hidden="true" />
          <span>
            {plural(data.counts.pending, 'certificate')} {data.counts.pending === 1 ? 'is' : 'are'} ready to issue — learners finished in the last ten days.
          </span>
          <Button size="sm" onClick={() => update({ status: 'pending' })}>
            Review
          </Button>
        </div>
      )}

      {list.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="Certificates didn’t load"
          actions={
            <Button variant="primary" onClick={() => list.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {list.error.message}
        </StateMessage>
      ) : data && rows.length === 0 ? (
        filtered ? (
          <StateMessage
            icon={<MagnifyingGlass size={26} />}
            title="No certificates match"
            actions={<Button onClick={() => setParams(new URLSearchParams(), { replace: true })}>Clear filters</Button>}
          >
            Try a learner’s name, their email or the full credential ID.
          </StateMessage>
        ) : (
          <StateMessage icon={<Certificate size={26} />} title="No certificates yet">
            Certificates appear here as learners complete courses that award one.
          </StateMessage>
        )
      ) : isMobile ? (
        <ul className={styles.cards} aria-label="Certificates" aria-busy={!data || undefined}>
          {!data
            ? Array.from({ length: 4 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <Skeleton width="70%" height={12} />
                  <Skeleton width="50%" height={8} />
                </li>
              ))
            : rows.map((r) => (
                <li key={r.certificate.id} className={styles.card}>
                  <button type="button" className={styles.cardButton} onClick={() => navigate(to(r))}>
                    <span className={styles.person}>
                      <Avatar name={r.studentName} size={34} />
                      <span className={styles.stack}>
                        <span className={styles.personName}>{r.studentName}</span>
                        <span className={styles.cellMeta}>{r.certificate.title}</span>
                      </span>
                    </span>
                    <span className={styles.cardFacts}>
                      <CertificateStatusBadge status={r.certificate.status} />
                      <span className={styles.mono}>{r.certificate.credentialId}</span>
                      {r.certificate.issuedAt && <span>{formatDate(r.certificate.issuedAt)}</span>}
                    </span>
                  </button>
                </li>
              ))}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Certificates"
            rows={rows}
            columns={columns}
            rowKey={(r) => r.certificate.id}
            rowLabel={(r) => `${r.studentName} — ${r.certificate.title}`}
            loading={!data}
            skeletonRows={8}
          />
        </div>
      )}

      {data && data.total > PAGE_SIZE && (
        <Pagination
          page={page}
          pageCount={Math.ceil(data.total / PAGE_SIZE)}
          onChange={(p) => update({ page: String(p) }, true)}
          summary={`${((page - 1) * PAGE_SIZE + 1).toLocaleString('en-IN')}–${Math.min(page * PAGE_SIZE, data.total).toLocaleString('en-IN')} of ${plural(data.total, 'certificate')}`}
        />
      )}
    </div>
  );
}
