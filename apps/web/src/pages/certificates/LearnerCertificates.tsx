import { useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Certificate, MagnifyingGlass, Prohibit, SealCheck, ShieldCheck } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { formatDate, plural } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CertificateDocument } from '@/components/lms/certificate/CertificateDocument';
import { CertificateStatus } from '@/components/lms/certificate/CertificateStatus';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type CertificateDetail } from '@/services';
import { CertificateActions, documentProps } from './CertificateActions';
import styles from './Certificates.module.css';

export function MyCertificatesPage() {
  const navigate = useNavigate();
  const toast = useToast();
  const query = useAsync('my-certificates', () => services.learning.listCertificates());
  const [claiming, setClaiming] = useState<string | null>(null);
  const data = query.data;

  const claim = async (d: CertificateDetail) => {
    setClaiming(d.certificate.id);
    try {
      const issued = await services.learning.claimCertificate(d.certificate.id);
      toast({ kind: 'success', title: 'Your certificate is ready', text: `${issued.certificate.title} · ${issued.certificate.credentialId}` });
      query.run().catch(() => undefined);
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t claim it', text: (e as Error).message });
    } finally {
      setClaiming(null);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader title="Certificates" description="Certificates you’ve earned — ready to download and share — and how close you are to the next ones." />
      {query.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="Your certificates didn’t load"
          actions={
            <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      ) : !data ? (
        <div className={styles.learnerGrid} aria-busy="true">
          <Skeleton height={300} radius="var(--r-lg)" />
          <Skeleton height={300} radius="var(--r-lg)" />
        </div>
      ) : data.issued.length + data.pending.length + data.working.length === 0 ? (
        <StateMessage icon={<Certificate size={28} />} title="No certificates yet">
          Complete a course that awards a certificate and it appears here, ready to download and share.
        </StateMessage>
      ) : (
        <>
          {data.pending.map((d) => (
            <section key={d.certificate.id} className={styles.claim} aria-labelledby={`claim-${d.certificate.id}`}>
              <div className={styles.claimDoc}>
                <CertificateDocument {...documentProps(d)} />
              </div>
              <div className={styles.claimText}>
                <span className={styles.eyebrow}>You’ve earned it</span>
                <h2 id={`claim-${d.certificate.id}`} className={styles.claimTitle}>
                  {d.certificate.title}
                </h2>
                <p className={styles.muted}>
                  You completed {d.courseTitle} on {formatDate(d.certificate.completedAt)}
                  {d.certificate.finalScore ? ` with ${d.certificate.finalScore}% in the final assessment` : ''}. Check your name is right, then claim your
                  certificate.
                </p>
                <Button variant="primary" iconStart={<SealCheck size={16} />} loading={claiming === d.certificate.id} onClick={() => claim(d)}>
                  Claim certificate
                </Button>
              </div>
            </section>
          ))}

          {data.issued.length > 0 && (
            <section aria-labelledby="issued-title">
              <SectionHeader id="issued-title" title="Earned" count={data.issued.length} />
              <ul className={styles.learnerGrid}>
                {data.issued.map((d) => (
                  <li key={d.certificate.id} className={styles.earned}>
                    <Link to={`/certificates/${d.certificate.id}`} className={styles.earnedDoc} aria-label={`Open ${d.certificate.title}`}>
                      <CertificateDocument {...documentProps(d)} />
                    </Link>
                    <div className={styles.earnedBody}>
                      <Link to={`/certificates/${d.certificate.id}`} className={styles.cellTitle}>
                        {d.certificate.title}
                      </Link>
                      <span className={styles.cellMeta}>
                        Issued {d.certificate.issuedAt ? formatDate(d.certificate.issuedAt) : ''} ·{' '}
                        <span className={styles.mono}>{d.certificate.credentialId}</span>
                      </span>
                      <CertificateActions detail={d} compact />
                    </div>
                  </li>
                ))}
              </ul>
            </section>
          )}

          {data.working.length > 0 && (
            <section aria-labelledby="working-title">
              <SectionHeader id="working-title" title="Working towards" count={data.working.length} />
              <div className={styles.working}>
                {data.working.map((r) => (
                  <div key={r.id} className={styles.panel}>
                    <CertificateStatus record={r} onView={() => navigate(`/learn/${r.courseId}`)} />
                  </div>
                ))}
              </div>
            </section>
          )}
        </>
      )}
    </div>
  );
}

export function MyCertificatePage() {
  const { certificateId } = useParams();
  const query = useAsync(`my-certificate:${certificateId}`, () => services.learning.getCertificate(certificateId!));
  usePageCrumbs(query.data ? [{ label: query.data.certificate.title }] : [{ label: 'Certificate' }]);

  if (query.status === 'error' && !query.data) {
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title="This certificate isn’t available"
          actions={
            <LinkButton to="/certificates" iconStart={<ArrowLeft size={16} />}>
              Back to certificates
            </LinkButton>
          }
        >
          It may have been withdrawn. Contact support if you think this is a mistake.
        </StateMessage>
      </div>
    );
  }
  if (!query.data) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton height={520} radius="var(--r-lg)" />
      </div>
    );
  }
  const d = query.data;
  return (
    <div className={styles.page}>
      <PageHeader back={{ label: 'Certificates', to: '/certificates' }} eyebrow={d.courseTitle} title={d.certificate.title} />
      <div className={styles.detailGrid}>
        <section className={styles.docPanel} aria-label="Certificate">
          <CertificateDocument {...documentProps(d)} />
          <CertificateActions detail={d} />
        </section>
        <aside className={styles.side}>
          <section className={styles.panel} aria-labelledby="my-record">
            <h2 id="my-record" className={styles.panelTitle}>
              Details
            </h2>
            <dl className={styles.facts}>
              <div>
                <dt>Credential ID</dt>
                <dd className={styles.mono}>{d.certificate.credentialId}</dd>
              </div>
              <div>
                <dt>Issued</dt>
                <dd>{d.certificate.issuedAt ? formatDate(d.certificate.issuedAt) : 'Not yet'}</dd>
              </div>
              <div>
                <dt>Completed</dt>
                <dd>{formatDate(d.certificate.completedAt)}</dd>
              </div>
              <div>
                <dt>Study time</dt>
                <dd>{plural(d.certificate.hours, 'hour')}</dd>
              </div>
            </dl>
          </section>
          <section className={styles.panel} aria-labelledby="my-verify">
            <h2 id="my-verify" className={styles.panelTitle}>
              <ShieldCheck size={18} aria-hidden="true" /> Verification
            </h2>
            <p className={styles.muted}>
              Employers and clients can confirm this certificate with its credential ID. The link shows your name, the course and the date — nothing else.
            </p>
            <Link to={`/verify/${d.certificate.credentialId}`} target="_blank" rel="noopener" className={styles.inlineLink}>
              Open the verification page
            </Link>
          </section>
        </aside>
      </div>
    </div>
  );
}

/** Anyone can confirm a credential ID here. */
export function VerifyPage() {
  const { credentialId } = useParams();
  const navigate = useNavigate();
  const [value, setValue] = useState(credentialId ?? '');
  const query = useAsync(`verify:${credentialId ?? ''}`, () => services.certificates.verify(credentialId!), { immediate: Boolean(credentialId) });
  usePageCrumbs([{ label: 'Verify a certificate' }]);

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (value.trim()) navigate(`/verify/${value.trim().toUpperCase()}`);
  };
  const d = query.data;
  const notFound = query.status === 'error' && (query.error as { code?: string }).code === 'not-found';

  return (
    <div className={styles.narrow}>
      <PageHeader title="Verify a certificate" description="Enter the credential ID printed at the foot of an ZuviloAI certificate." />
      <form className={styles.verifyForm} onSubmit={submit}>
        <Field label="Credential ID" hideLabel>
          <Input value={value} onChange={(e) => setValue(e.target.value)} placeholder="SA-JY-2026-04817" aria-label="Credential ID" />
        </Field>
        <Button type="submit" variant="primary" iconStart={<MagnifyingGlass size={16} />}>
          Verify
        </Button>
      </form>

      {!credentialId ? null : query.status === 'loading' && !d ? (
        <Skeleton height={220} radius="var(--r-lg)" />
      ) : notFound ? (
        <StateMessage kind="error" title="No certificate matches this ID">
          Check the ID for typos. Certificates that haven’t been issued yet can’t be verified.
        </StateMessage>
      ) : query.status === 'error' ? (
        <StateMessage
          kind="error"
          title="Verification didn’t load"
          actions={
            <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      ) : d && d.certificate.credentialId === credentialId?.toUpperCase() ? (
        <section className={d.certificate.status === 'revoked' ? styles.verifyRevoked : styles.verifyValid} aria-live="polite">
          <div className={styles.verifyHead}>
            {d.certificate.status === 'revoked' ? <Prohibit size={28} aria-hidden="true" /> : <ShieldCheck size={28} weight="fill" aria-hidden="true" />}
            <div>
              <p className={styles.verifyTitle}>{d.certificate.status === 'revoked' ? 'This certificate has been revoked' : 'This certificate is genuine'}</p>
              <p className={styles.muted}>
                {d.certificate.status === 'revoked'
                  ? d.certificate.revokedReason
                  : `Issued by ${d.issuer ?? 'ZuviloAI'} on ${d.certificate.issuedAt ? formatDate(d.certificate.issuedAt) : ''}.`}
              </p>
            </div>
          </div>
          <dl className={styles.facts}>
            <div>
              <dt>Awarded to</dt>
              <dd>{d.student.name}</dd>
            </div>
            <div>
              <dt>Certificate</dt>
              <dd>{d.certificate.title}</dd>
            </div>
            <div>
              <dt>Course</dt>
              <dd>{d.courseTitle}</dd>
            </div>
            <div>
              <dt>Credential ID</dt>
              <dd className={styles.mono}>{d.certificate.credentialId}</dd>
            </div>
          </dl>
        </section>
      ) : null}
    </div>
  );
}
