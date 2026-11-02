import { useState } from 'react';
import { CheckCircle, DownloadSimple, Eye, ShareNetwork } from '@phosphor-icons/react';
import type { CertificateRecord, CertificateState } from '@syniastrolms/domain';
import { certificateState, criteriaPercent, criterionMet } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatDate } from '@/lib/format';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Meter } from '../progress/Meters';
import { StatusBadge } from '../status/Status';
import styles from './CertificateStatus.module.css';

/** A quiet seal: twelve divisions around a ring. Dashed until earned. */
export function CertificateSeal({ state, size = 64 }: { state: CertificateState; size?: number }) {
  const mid = size / 2;
  const r = size / 2 - 3;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className={cx(styles.seal, styles[`seal-${state}`])} aria-hidden="true">
      <circle cx={mid} cy={mid} r={r} className={styles.sealRing} />
      <circle cx={mid} cy={mid} r={r - 7} className={styles.sealInner} />
      {Array.from({ length: 12 }, (_, i) => {
        const a = (i / 12) * Math.PI * 2;
        return (
          <line
            key={i}
            x1={mid + (r - 3.5) * Math.cos(a)}
            y1={mid + (r - 3.5) * Math.sin(a)}
            x2={mid + r * Math.cos(a)}
            y2={mid + r * Math.sin(a)}
            className={styles.sealTick}
          />
        );
      })}
      {state !== 'not-eligible' && <path d={`M ${mid - 7} ${mid} l 5 5 l 9 -10`} className={styles.sealCheck} />}
    </svg>
  );
}

interface CertificateStatusProps {
  record: CertificateRecord;
  onClaim?: (record: CertificateRecord) => Promise<void> | void;
  onView?: (record: CertificateRecord) => void;
}

export function CertificateStatus({ record, onClaim, onView }: CertificateStatusProps) {
  const [claiming, setClaiming] = useState(false);
  const state = certificateState(record);
  const met = record.criteria.filter(criterionMet).length;

  const claim = async () => {
    setClaiming(true);
    try {
      await onClaim?.(record);
    } finally {
      setClaiming(false);
    }
  };

  return (
    <article
      className={cx(styles.root, styles[state])}
      aria-label={`${record.title} — ${state === 'issued' ? 'issued' : state === 'eligible' ? 'eligible to claim' : 'not yet eligible'}`}
    >
      <CertificateSeal state={state} />
      <div className={styles.body}>
        <div className={styles.head}>
          <h4 className={styles.title}>{record.title}</h4>
          {state === 'issued' ? <StatusBadge status="completed" label="Issued" /> : <StatusBadge status={state} />}
        </div>

        {state === 'issued' && (
          <>
            <dl className={styles.credential}>
              <div>
                <dt>Issued</dt>
                <dd>{record.issuedAt && formatDate(record.issuedAt)}</dd>
              </div>
              <div>
                <dt>Credential ID</dt>
                <dd className={styles.mono}>{record.credentialId}</dd>
              </div>
            </dl>
            <div className={styles.actions}>
              <Button size="sm" iconStart={<Eye size={15} />} onClick={() => onView?.(record)}>
                View
              </Button>
              <LinkButton size="sm" variant="quiet" iconStart={<DownloadSimple size={15} />} to={`/certificates/${record.id}`}>
                PDF
              </LinkButton>
              <LinkButton size="sm" variant="quiet" iconStart={<ShareNetwork size={15} />} to={`/certificates/${record.id}`}>
                Share
              </LinkButton>
            </div>
          </>
        )}

        {state === 'eligible' && (
          <>
            <p className={styles.lead}>
              <CheckCircle size={15} weight="fill" className={styles.okIcon} /> All {record.criteria.length} requirements met. Your certificate is ready to
              issue.
            </p>
            <div className={styles.actions}>
              <Button variant="primary" loading={claiming} onClick={claim}>
                Claim certificate
              </Button>
            </div>
          </>
        )}

        {state === 'not-eligible' && (
          <>
            <p className={styles.lead}>{`${met} of ${record.criteria.length} requirements met · ${criteriaPercent(record.criteria)}% of the way there`}</p>
            <ul className={styles.criteria}>
              {record.criteria.map((c) => {
                const ok = criterionMet(c);
                const unit = c.unit === '%' ? '%' : '';
                return (
                  <li key={c.id} className={cx(styles.criterion, ok && styles.criterionMet)}>
                    <span className={styles.criterionHead}>
                      <span className={styles.criterionLabel}>
                        {ok && <CheckCircle size={14} weight="fill" className={styles.okIcon} />}
                        {c.label}
                      </span>
                      <span className={styles.criterionValue}>
                        {c.current}
                        {unit}{' '}
                        <span className={styles.of}>
                          / {c.required}
                          {unit}
                        </span>
                      </span>
                    </span>
                    <Meter value={(c.current / c.required) * 100} label={c.label} size="xs" />
                  </li>
                );
              })}
            </ul>
          </>
        )}
      </div>
    </article>
  );
}
