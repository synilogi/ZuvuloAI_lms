import { useId, useState } from 'react';
import { Check, Copy, DownloadSimple, EnvelopeSimple, Eye, ShareNetwork } from '@phosphor-icons/react';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { Modal } from '@/components/overlays/Overlay';
import { CertificateDocument } from '@/components/lms/certificate/CertificateDocument';
import { fieldProps } from '@/lib/fieldProps';
import type { CertificateDetail } from '@/services';
import styles from './Certificates.module.css';

export function documentProps(d: CertificateDetail) {
  const c = d.certificate;
  return {
    template: d.template,
    learnerName: d.student.name,
    courseTitle: d.courseTitle,
    levelTitle: d.levelTitle,
    completedAt: c.completedAt,
    issuedAt: c.issuedAt,
    credentialId: c.credentialId,
    hours: c.hours,
    finalScore: c.finalScore,
    status: c.status,
    issuer: d.issuer,
  };
}

/** View, download and share — the actions a certificate carries wherever it's shown. */
export function CertificateActions({ detail, compact }: { detail: CertificateDetail; compact?: boolean }) {
  const [open, setOpen] = useState<null | 'view' | 'download' | 'share'>(null);
  const issued = detail.certificate.status === 'issued';
  return (
    <>
      <div className={styles.actions}>
        <Button size={compact ? 'sm' : 'md'} iconStart={<Eye size={16} />} onClick={() => setOpen('view')}>
          View
        </Button>
        <Button size={compact ? 'sm' : 'md'} iconStart={<DownloadSimple size={16} />} disabled={!issued} onClick={() => setOpen('download')}>
          Download
        </Button>
        <Button size={compact ? 'sm' : 'md'} iconStart={<ShareNetwork size={16} />} disabled={!issued} onClick={() => setOpen('share')}>
          Share
        </Button>
      </div>
      <Modal
        open={open === 'view'}
        onClose={() => setOpen(null)}
        width={980}
        title={detail.certificate.title}
        description={`${detail.student.name} · ${detail.certificate.credentialId}`}
      >
        <div className={styles.viewer}>
          <CertificateDocument {...documentProps(detail)} />
        </div>
      </Modal>
      {open === 'download' && <DownloadDialog detail={detail} onClose={() => setOpen(null)} />}
      {open === 'share' && <ShareDialog detail={detail} onClose={() => setOpen(null)} />}
    </>
  );
}

/**
 * There is no file renderer behind this, so nothing pretends to prepare one: `window.print()` is a real capability
 * every browser has, and "Save as PDF" in its dialog gives the learner an actual file.
 */
function DownloadDialog({ detail, onClose }: { detail: CertificateDetail; onClose: () => void }) {
  return (
    <Modal
      open
      onClose={onClose}
      title="Download certificate"
      description={detail.certificate.title}
      footer={
        <>
          <Button onClick={onClose}>Close</Button>
          <Button variant="primary" iconStart={<DownloadSimple size={16} />} onClick={() => window.print()}>
            Print / Save as PDF
          </Button>
        </>
      }
    >
      <div className={styles.dialogBody}>
        <p>Use your browser’s print dialog and choose “Save as PDF” to keep a copy of certificate {detail.certificate.credentialId}.</p>
      </div>
    </Modal>
  );
}

function ShareDialog({ detail, onClose }: { detail: CertificateDetail; onClose: () => void }) {
  const linkId = useId();
  const [copied, setCopied] = useState(false);
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(detail.verifyUrl);
      setCopied(true);
    } catch {
      setCopied(false);
    }
  };
  const subject = encodeURIComponent(`My ${detail.certificate.title}`);
  const body = encodeURIComponent(
    `I’ve completed ${detail.courseTitle} at ${detail.issuer ?? 'ZuviloAI'}. You can verify my certificate here: ${detail.verifyUrl}`,
  );
  return (
    <Modal
      open
      onClose={onClose}
      title="Share certificate"
      description="Anyone with the link can confirm the certificate is genuine. It shows the learner’s name, the course and the date — nothing else."
      footer={<Button onClick={onClose}>Done</Button>}
    >
      <div className={styles.dialogBody}>
        <Field label="Verification link" id={linkId}>
          <div className={styles.copyRow}>
            <Input {...fieldProps(linkId, false, false)} readOnly value={detail.verifyUrl} onFocus={(e) => e.target.select()} />
            <Button variant="primary" iconStart={copied ? <Check size={16} /> : <Copy size={16} />} onClick={copy}>
              {copied ? 'Copied' : 'Copy'}
            </Button>
          </div>
        </Field>
        <a className={styles.mailLink} href={`mailto:?subject=${subject}&body=${body}`}>
          <EnvelopeSimple size={16} aria-hidden="true" /> Send by email
        </a>
      </div>
    </Modal>
  );
}
