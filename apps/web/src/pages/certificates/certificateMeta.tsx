import { HourglassMedium, Prohibit, SealCheck, ShieldCheck } from '@phosphor-icons/react';
import type { IssuedCertificate, IssuedCertificateStatus } from '@syniastrolms/domain';
import { plural } from '@/lib/format';
import { Badge } from '@/components/ui/Badge/Badge';
import styles from './Certificates.module.css';

export function CertificateStatusBadge({ status, size = 'sm' }: { status: IssuedCertificateStatus; size?: 'sm' | 'md' }) {
  if (status === 'issued')
    return (
      <Badge size={size} tone="accent" icon={<SealCheck size={13} weight="fill" />}>
        Issued
      </Badge>
    );
  if (status === 'pending')
    return (
      <Badge size={size} tone="warn" icon={<HourglassMedium size={13} />}>
        Ready to issue
      </Badge>
    );
  return (
    <Badge size={size} tone="danger" icon={<Prohibit size={13} />}>
      Revoked
    </Badge>
  );
}

/** Whether the public verification link confirms the certificate, and how often it has been checked. */
export function Verification({ certificate: c }: { certificate: IssuedCertificate }) {
  if (c.status === 'issued')
    return (
      <span className={styles.verified}>
        <ShieldCheck size={15} weight="fill" aria-hidden="true" />
        <span>
          Verifiable
          <span className={styles.cellMeta}> · {c.verifications ? plural(c.verifications, 'check') : 'not checked yet'}</span>
        </span>
      </span>
    );
  if (c.status === 'revoked') return <span className={styles.unverified}>Shows as revoked</span>;
  return <span className={styles.muted}>Not public yet</span>;
}
