import type { CertificateTemplate, IssuedCertificateStatus } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatDate } from '@/lib/format';
import { CertificateSeal } from './CertificateStatus';
import styles from './CertificateDocument.module.css';

export interface CertificateDocumentProps {
  template: Pick<CertificateTemplate, 'style' | 'accent' | 'heading' | 'statement' | 'signatories' | 'showScore' | 'showHours'>;
  learnerName: string;
  courseTitle: string;
  levelTitle?: string;
  completedAt: string;
  issuedAt?: string;
  credentialId: string;
  hours?: number;
  finalScore?: number;
  status?: IssuedCertificateStatus;
  /** The issuing LMS's name, as its Admin set it. */
  issuer?: string;
  className?: string;
}

/** A hand-drawn-looking signature line, the same for the same name. Decorative only. */
function Signature({ name }: { name: string }) {
  let h = 0;
  for (const ch of name) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  const r = (n: number) => ((h >> n) & 15) / 15;
  const d = `M 4 ${22 - r(1) * 8} C ${18 + r(2) * 10} ${4 + r(3) * 6}, ${28 + r(4) * 8} ${30 - r(5) * 4}, ${44 + r(6) * 6} ${14 + r(7) * 6} S ${70 + r(8) * 8} ${6 + r(9) * 8}, ${86 + r(10) * 6} ${20 - r(11) * 6} S ${108} ${24 - r(12) * 10}, 116 ${12 + r(13) * 6}`;
  return (
    <svg viewBox="0 0 120 34" className={styles.signature} aria-hidden="true">
      <path d={d} />
    </svg>
  );
}

/**
 * The certificate itself. Every size is relative to the document's own width, so the same
 * layout reads the same on a phone as in print — nothing reflows, nothing is cropped.
 */
export function CertificateDocument({
  template,
  learnerName,
  courseTitle,
  levelTitle,
  completedAt,
  issuedAt,
  credentialId,
  hours,
  finalScore,
  status = 'issued',
  issuer,
  className,
}: CertificateDocumentProps) {
  const details = [
    `Completed ${formatDate(completedAt)}`,
    template.showHours && hours ? `${hours} hours of study` : null,
    template.showScore && finalScore ? `Final assessment ${finalScore}%` : null,
  ].filter(Boolean);

  return (
    <div
      className={cx(styles.doc, styles[template.style], styles[template.accent], className)}
      role="img"
      aria-label={`${template.heading}: ${learnerName}, ${courseTitle}${status === 'revoked' ? ' (revoked)' : status === 'pending' ? ' (preview, not yet issued)' : ''}`}
    >
      <div className={styles.paper} aria-hidden="true">
        <span className={styles.frame} />
        {template.style === 'classic' && (
          <>
            {(['tl', 'tr', 'bl', 'br'] as const).map((corner) => (
              <svg key={corner} viewBox="0 0 40 40" className={cx(styles.corner, styles[corner])}>
                <circle cx="0" cy="0" r="30" />
                <circle cx="0" cy="0" r="22" />
                {Array.from({ length: 4 }, (_, i) => {
                  const a = ((i + 0.5) / 4) * (Math.PI / 2);
                  return <line key={i} x1={22 * Math.cos(a)} y1={22 * Math.sin(a)} x2={30 * Math.cos(a)} y2={30 * Math.sin(a)} />;
                })}
              </svg>
            ))}
          </>
        )}
        {template.style === 'modern' && <span className={styles.band} />}

        <div className={styles.content}>
          <div className={styles.brand}>
            <span className={styles.mark}>s</span>
            <span className={styles.academy}>{issuer ?? 'ZuviloAI'}</span>
          </div>
          <p className={styles.heading}>{template.heading}</p>
          <p className={styles.small}>This certifies that</p>
          <p className={styles.name}>{learnerName}</p>
          <p className={styles.small}>{template.statement}</p>
          <p className={styles.course}>{courseTitle}</p>
          {levelTitle && <p className={styles.level}>{levelTitle} level</p>}
          <p className={styles.details}>{details.join('  ·  ')}</p>

          <div className={styles.signoff}>
            {template.signatories.slice(0, 1).map((s) => (
              <div key={s.name} className={styles.signer}>
                <Signature name={s.name} />
                <span className={styles.signLine} />
                <span className={styles.signName}>{s.name}</span>
                <span className={styles.signTitle}>{s.title}</span>
              </div>
            ))}
            <div className={styles.seal}>
              <CertificateSeal state={status === 'issued' ? 'issued' : status === 'pending' ? 'eligible' : 'not-eligible'} size={96} />
            </div>
            {template.signatories.length > 1 ? (
              template.signatories.slice(1, 2).map((s) => (
                <div key={s.name} className={styles.signer}>
                  <Signature name={s.name} />
                  <span className={styles.signLine} />
                  <span className={styles.signName}>{s.name}</span>
                  <span className={styles.signTitle}>{s.title}</span>
                </div>
              ))
            ) : (
              <div className={styles.signer}>
                <span className={styles.issued}>{issuedAt ? formatDate(issuedAt) : 'Not yet issued'}</span>
                <span className={styles.signLine} />
                <span className={styles.signTitle}>Date of issue</span>
              </div>
            )}
          </div>

          <p className={styles.credential}>Credential {credentialId} · Verify at zuviloai.com/verify</p>
        </div>

        {status !== 'issued' && (
          <span className={cx(styles.watermark, status === 'revoked' && styles.revoked)}>{status === 'revoked' ? 'Revoked' : 'Preview'}</span>
        )}
      </div>
    </div>
  );
}
