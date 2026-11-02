import { useState } from 'react';
import { EnvelopeSimple, MagnifyingGlass, Tray } from '@phosphor-icons/react';
import type { Inquiry, InquiryKind, InquiryStatus } from '@syniastrolms/domain';
import { INQUIRY_KIND_LABEL, INQUIRY_KINDS, INQUIRY_STATUS_LABEL, INQUIRY_STATUSES, isInquiryKind, isInquiryStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { AdaptivePanel } from '@/components/overlays/AdaptivePanel';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import { PAGE_SIZE, PLATFORM_EYEBROW, PlatformError, pageCount, rangeSummary } from '../platformMeta';
import { useListParams } from '../subscriptions/subscriptionMeta';
import platformStyles from '../Platform.module.css';
import styles from './Inquiries.module.css';

/*
 * The platform team's inbox (SAAS-027): demo, sales and support requests from the company website and from academy
 * admins, newest first. A request is moved along — new, in progress, closed — with a private note; it is never deleted.
 */

const STATUS_TONE: Record<InquiryStatus, 'accent' | 'info' | 'neutral'> = { new: 'accent', in_progress: 'info', closed: 'neutral' };

export const InquiryStatusBadge = ({ status }: { status: InquiryStatus }) => (
  <Badge size="sm" tone={STATUS_TONE[status]}>
    {INQUIRY_STATUS_LABEL[status]}
  </Badge>
);

export default function InquiriesPage() {
  const { params, update, reset, page } = useListParams();
  const search = params.get('q') ?? '';
  const statusParam = params.get('status');
  const kindParam = params.get('kind');
  const status: InquiryStatus | 'all' = isInquiryStatus(statusParam) ? statusParam : 'all';
  const kind: InquiryKind | undefined = isInquiryKind(kindParam) ? kindParam : undefined;
  const [open, setOpen] = useState<Inquiry | null>(null);

  const list = useAsync(`platform:inquiries:${status}:${kind}:${search}:${page}`, () =>
    services.platform.listInquiries({ status: status === 'all' ? undefined : status, kind, search: search || undefined, page, pageSize: PAGE_SIZE }),
  );
  const data = list.data;
  const reload = () => list.run().catch(() => undefined);
  const filtered = status !== 'all' || !!kind || !!search;

  const columns: Column<Inquiry>[] = [
    {
      key: 'from',
      header: 'From',
      mobile: 'primary',
      render: (r) => (
        <button type="button" className={styles.fromButton} onClick={() => setOpen(r)}>
          <span className={styles.fromName}>{r.name}</span>
          <span className={styles.fromMeta}>{r.organisation ?? r.email}</span>
        </button>
      ),
    },
    { key: 'kind', header: 'Type', width: '150px', mobile: 'meta', render: (r) => INQUIRY_KIND_LABEL[r.kind] },
    { key: 'status', header: 'Status', width: '130px', mobile: 'status', render: (r) => <InquiryStatusBadge status={r.status} /> },
    { key: 'received', header: 'Received', width: '130px', mobile: 'detail', render: (r) => formatDate(r.createdAt) },
  ];

  return (
    <div className={platformStyles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Inbox"
        count={data ? data.total : undefined}
        description="Demo requests, sales questions and support messages — from the website and from Admins. Open one to reply and update it. Nothing is ever deleted: mark a request Closed once it’s handled."
      />

      <div className={styles.toolbar}>
        <SegmentedControl<InquiryStatus | 'all'>
          label="Status"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All' },
            ...INQUIRY_STATUSES.map((s) => ({ value: s, label: data ? `${INQUIRY_STATUS_LABEL[s]} (${data.counts[s]})` : INQUIRY_STATUS_LABEL[s] })),
          ]}
        />
        <div className={styles.filters}>
          <Select aria-label="Type" value={kind ?? ''} onChange={(e) => update({ kind: e.target.value || undefined })}>
            <option value="">Every type</option>
            {INQUIRY_KINDS.map((k) => (
              <option key={k} value={k}>
                {INQUIRY_KIND_LABEL[k]}
              </option>
            ))}
          </Select>
          <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search name, email or message" aria-label="Search the inbox" />
        </div>
      </div>

      {list.status === 'error' && !data ? (
        <PlatformError title="The inbox didn’t load" error={list.error} onRetry={reload} />
      ) : data && data.rows.length === 0 && filtered ? (
        <StateMessage icon={<MagnifyingGlass size={26} />} title="Nothing matches" actions={<Button onClick={reset}>Clear filters</Button>}>
          Try another status, type or search.
        </StateMessage>
      ) : (
        <>
          <DataTable
            framed
            label="Inbox"
            rows={data?.rows ?? []}
            columns={columns}
            rowKey={(r) => r.id}
            rowLabel={(r) => `${r.name}, ${INQUIRY_KIND_LABEL[r.kind]}`}
            loading={!data}
            skeletonRows={6}
            empty={
              <StateMessage icon={<Tray size={26} />} title="The inbox is empty" compact>
                Requests from the website’s contact form and from Admins arrive here.
              </StateMessage>
            }
          />
          {data && data.total > data.pageSize && (
            <Pagination
              page={page}
              pageCount={pageCount(data.total, data.pageSize)}
              onChange={(next) => update({ page: next > 1 ? String(next) : undefined }, true)}
              summary={rangeSummary(data.total, data.page, data.pageSize)}
            />
          )}
        </>
      )}

      {open && (
        <InquiryPanel
          inquiry={open}
          onClose={() => setOpen(null)}
          onSaved={(saved) => {
            setOpen(saved);
            reload();
          }}
        />
      )}
    </div>
  );
}

function InquiryPanel({ inquiry, onClose, onSaved }: { inquiry: Inquiry; onClose: () => void; onSaved: (i: Inquiry) => void }) {
  const toast = useToast();
  const [status, setStatus] = useState<InquiryStatus>(inquiry.status);
  const [note, setNote] = useState(inquiry.note ?? '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const changed = status !== inquiry.status || note !== (inquiry.note ?? '');

  const save = async () => {
    setSaving(true);
    setError(undefined);
    try {
      const saved = await services.platform.updateInquiry(inquiry.id, { status, note });
      toast({ kind: 'success', title: 'Request updated', text: `${inquiry.name} · ${INQUIRY_STATUS_LABEL[saved.status]}` });
      onSaved(saved);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'The request could not be updated.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <AdaptivePanel
      open
      onClose={onClose}
      eyebrow={INQUIRY_KIND_LABEL[inquiry.kind]}
      title={inquiry.name}
      width={480}
      footer={
        <>
          <Button onClick={onClose}>Close</Button>
          <Button variant="primary" onClick={save} loading={saving} disabled={!changed}>
            Save
          </Button>
        </>
      }
    >
      <div className={styles.panel}>
        <dl className={styles.facts}>
          <div>
            <dt>Email</dt>
            <dd>
              <a href={`mailto:${inquiry.email}`}>
                <EnvelopeSimple size={14} aria-hidden="true" /> {inquiry.email}
              </a>
            </dd>
          </div>
          {inquiry.phone && (
            <div>
              <dt>Phone</dt>
              <dd>{inquiry.phone}</dd>
            </div>
          )}
          {inquiry.academy && (
            <div>
              <dt>Admin</dt>
              <dd>
                {inquiry.academy.name} <span className={styles.muted}>({inquiry.academy.slug})</span>
              </dd>
            </div>
          )}
          {inquiry.organisation && (
            <div>
              <dt>Organisation</dt>
              <dd>{inquiry.organisation}</dd>
            </div>
          )}
          {inquiry.size && (
            <div>
              <dt>Size</dt>
              <dd>{inquiry.size}</dd>
            </div>
          )}
          <div>
            <dt>Received</dt>
            <dd>{formatDate(inquiry.createdAt)}</dd>
          </div>
        </dl>
        {inquiry.subject && <p className={styles.subject}>{inquiry.subject}</p>}
        <p className={styles.message}>{inquiry.message}</p>
        {error && (
          <InlineMessage kind="error" title="Not saved.">
            {error}
          </InlineMessage>
        )}
        <Field label="Status">
          <Select value={status} onChange={(e) => setStatus(e.target.value as InquiryStatus)}>
            {INQUIRY_STATUSES.map((s) => (
              <option key={s} value={s}>
                {INQUIRY_STATUS_LABEL[s]}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Team note" optional hint="Only the platform team sees this.">
          <Textarea rows={4} value={note} onChange={(e) => setNote(e.target.value)} />
        </Field>
      </div>
    </AdaptivePanel>
  );
}
