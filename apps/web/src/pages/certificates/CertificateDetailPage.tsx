import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, ArrowSquareOut, Prohibit, SealCheck, Stamp } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { formatDate, formatTime, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Field, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CertificateDocument } from '@/components/lms/certificate/CertificateDocument';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { CertificateActions, documentProps } from './CertificateActions';
import { CertificateStatusBadge, Verification } from './certificateMeta';
import styles from './Certificates.module.css';

export default function CertificateDetailPage() {
  const { can } = usePermissions();
  const { certificateId } = useParams();
  const toast = useToast();
  const query = useAsync(`certificate:${certificateId}`, () => services.certificates.get(certificateId!));
  const [busy, setBusy] = useState(false);
  const [revoking, setRevoking] = useState(false);
  const [reason, setReason] = useState('');
  usePageCrumbs(query.data ? [{ label: `${query.data.student.name} · ${query.data.certificate.credentialId}` }] : [{ label: 'Certificate' }]);

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'Certificate not found' : 'This certificate didn’t load'}
          actions={
            notFound ? (
              <LinkButton to="/admin/certificates" iconStart={<ArrowLeft size={16} />}>
                Back to certificates
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!query.data || query.data.certificate.id !== certificateId) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton width="40%" height={30} radius="var(--r-xs)" />
        <div className={styles.detailGrid}>
          <Skeleton height={480} radius="var(--r-lg)" />
          <Skeleton height={420} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }

  const d = query.data;
  const c = d.certificate;
  const refresh = () => query.run().catch(() => undefined);

  const issue = async () => {
    setBusy(true);
    try {
      await services.certificates.issue(c.id);
      toast({ kind: 'success', title: 'Certificate issued', text: `${d.student.name} has been notified · ${c.credentialId}` });
      refresh();
    } catch (e) {
      toast({ kind: 'error', title: 'Not issued', text: (e as Error).message });
    } finally {
      setBusy(false);
    }
  };
  const restore = async () => {
    setBusy(true);
    try {
      await services.certificates.restore(c.id);
      toast({ kind: 'success', title: 'Certificate restored', text: 'The verification link confirms it again.' });
      refresh();
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader
        back={{ label: 'Certificates', to: '/admin/certificates' }}
        eyebrow={d.courseTitle}
        title={c.title}
        meta={<CertificateStatusBadge status={c.status} size="md" />}
        actions={
          /* Issuing a credential and withdrawing one are separate permissions. */
          c.status === 'pending'
            ? can('certificates.issue') && (
                <Button variant="primary" iconStart={<SealCheck size={16} />} loading={busy} onClick={issue}>
                  Issue certificate
                </Button>
              )
            : c.status === 'issued'
              ? can('certificates.revoke') && (
                  <Button variant="danger" iconStart={<Prohibit size={16} />} onClick={() => setRevoking(true)}>
                    Revoke…
                  </Button>
                )
              : can('certificates.revoke') && (
                  <Button iconStart={<SealCheck size={16} />} loading={busy} onClick={restore}>
                    Restore
                  </Button>
                )
        }
      />

      {c.status === 'revoked' && (
        <InlineMessage kind="error" title={`Revoked ${c.revokedAt ? formatDate(c.revokedAt) : ''}`}>
          {c.revokedReason} The verification link now tells anyone who checks that this certificate is no longer valid.
        </InlineMessage>
      )}
      {c.status === 'pending' && (
        <InlineMessage kind="info" title="Ready to issue">
          {d.student.name} met every requirement on {formatDate(c.completedAt)}. Issuing makes the certificate downloadable and its verification link public.
        </InlineMessage>
      )}

      <div className={styles.detailGrid}>
        <section className={styles.docPanel} aria-label="Certificate preview">
          <CertificateDocument {...documentProps(d)} />
          <CertificateActions detail={d} />
        </section>

        <aside className={styles.side} aria-label="Certificate details">
          <section className={styles.panel} aria-labelledby="cert-learner">
            <h2 id="cert-learner" className={styles.panelTitle}>
              Learner
            </h2>
            <Link to={`/admin/students/${d.student.id}`} className={styles.personLink}>
              <Avatar name={d.student.name} size={40} />
              <span className={styles.stack}>
                <span className={styles.personName}>{d.student.name}</span>
                <span className={styles.cellMeta}>
                  {d.student.email} · {d.student.city}
                </span>
              </span>
            </Link>
          </section>

          <section className={styles.panel} aria-labelledby="cert-record">
            <h2 id="cert-record" className={styles.panelTitle}>
              Record
            </h2>
            <dl className={styles.facts}>
              <div>
                <dt>Credential ID</dt>
                <dd className={styles.mono}>{c.credentialId}</dd>
              </div>
              <div>
                <dt>Course</dt>
                <dd>
                  <Link to={`/admin/courses/${c.courseId}`}>{d.courseTitle}</Link>
                </dd>
              </div>
              <div>
                <dt>Completed</dt>
                <dd>{formatDate(c.completedAt)}</dd>
              </div>
              <div>
                <dt>Issued</dt>
                <dd>{c.issuedAt ? `${formatDate(c.issuedAt)}, ${formatTime(c.issuedAt)}` : 'Not yet'}</dd>
              </div>
              {c.finalScore !== undefined && (
                <div>
                  <dt>Final assessment</dt>
                  <dd>{c.finalScore}%</dd>
                </div>
              )}
              <div>
                <dt>Study time</dt>
                <dd>{plural(c.hours, 'hour')}</dd>
              </div>
            </dl>
          </section>

          <section className={styles.panel} aria-labelledby="cert-verify">
            <h2 id="cert-verify" className={styles.panelTitle}>
              Verification
            </h2>
            <Verification certificate={c} />
            {c.status !== 'pending' && (
              <Link to={`/verify/${c.credentialId}`} target="_blank" rel="noopener" className={styles.inlineLink}>
                See the public verification page <ArrowSquareOut size={13} aria-hidden="true" />
              </Link>
            )}
          </section>

          <section className={styles.panel} aria-labelledby="cert-template">
            <h2 id="cert-template" className={styles.panelTitle}>
              Template
            </h2>
            <Link to={`/admin/certificates/templates/${d.template.id}`} className={styles.inlineLink}>
              <Stamp size={15} aria-hidden="true" /> {d.template.name}
            </Link>
            <p className={styles.muted}>Printed with the template’s signatories and layout at the time of issue.</p>
          </section>
        </aside>
      </div>

      {revoking && (
        <ConfirmDialog
          open
          onClose={() => {
            setRevoking(false);
            setReason('');
          }}
          onConfirm={async () => {
            await services.certificates.revoke(c.id, reason);
            toast({ kind: 'success', title: 'Certificate revoked', text: `${d.student.name} · ${c.credentialId}` });
            setRevoking(false);
            setReason('');
            refresh();
          }}
          tone="danger"
          icon={<Prohibit size={20} />}
          title={`Revoke ${d.student.name}’s certificate?`}
          description={`${c.title} · ${c.credentialId}`}
          confirmLabel="Revoke certificate"
        >
          <div className={styles.dialogBody}>
            <ul className={styles.impact}>
              <li>The verification link will show the certificate as revoked, with your reason.</li>
              <li>The learner can no longer download or share it. Their course progress is kept.</li>
            </ul>
            <Field label="Reason" hint="At least a sentence. The learner and anyone verifying the certificate will see it.">
              <Textarea
                rows={3}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="Final project found to be substantially copied from another learner’s submission."
              />
            </Field>
          </div>
        </ConfirmDialog>
      )}
    </div>
  );
}
