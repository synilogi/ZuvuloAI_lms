import type { ReactNode } from 'react';
import { useSearchParams } from 'react-router-dom';
import { WarningCircle } from '@phosphor-icons/react';
import { formatMoney, minorToMajor } from '@syniastrolms/domain';
import { API_MODE } from '@/lib/apiMode';
import styles from './Subscriptions.module.css';

/*
 * Helpers the platform pages share: money, facts, URL-held list state, the demo note. The subscription screens they
 * were written for are retired (docs/16, D-PLAT-04); the payment setup, affiliate and inbox pages still use these.
 */

export const PAYMENT_GATEWAYS_PATH = '/superadmin/payment-gateways';

export const PAGE_SIZE = 20;

/* ─── Formatting ────────────────────────────────────────────────────────── */

/** An amount in minor units (paise), written in its own currency: 399900 is "₹3,999". */
export const money = (amount: number, currency = 'INR'): string => formatMoney(amount, currency);

const compact = new Intl.NumberFormat('en-IN', { notation: 'compact', maximumFractionDigits: 1 });

/** ₹1.4L, ₹18L — for chart axes and KPI headlines where the exact rupee doesn't help. Takes minor units. */
export const moneyCompact = (amount: number, currency = 'INR') => `${currency === 'INR' ? '₹' : ''}${compact.format(minorToMajor(amount, currency))}`;

/** One labelled fact inside a `<dl className={styles.facts}>`. */
export function Fact({ label, value }: { label: ReactNode; value: ReactNode }) {
  return (
    <div className={styles.fact}>
      <dt className={styles.factLabel}>{label}</dt>
      <dd className={styles.factValue}>{value}</dd>
    </div>
  );
}

/* ─── URL state ─────────────────────────────────────────────────────────── */

/**
 * Filters, search, sort and page live in the URL, the way every other management screen in the
 * application keeps them, so a filtered list can be linked to and the back button works.
 */
export function useListParams() {
  const [params, setParams] = useSearchParams();
  const update = (next: Record<string, string | undefined>, keepPage = false) => {
    const p = new URLSearchParams(params);
    for (const [key, value] of Object.entries(next)) {
      if (!value || value === 'all') p.delete(key);
      else p.set(key, value);
    }
    if (!keepPage) p.delete('page');
    setParams(p, { replace: true });
  };
  const reset = () => setParams(new URLSearchParams(), { replace: true });
  return { params, update, reset, page: Math.max(1, Number(params.get('page')) || 1) };
}

/** "1–20 of 148" — the line beside a pager. */
export function rangeSummary(total: number, page: number, pageSize: number, noun: string): string {
  if (total === 0) return `No ${noun}`;
  const first = (page - 1) * pageSize + 1;
  return `${first.toLocaleString('en-IN')}–${Math.min(total, page * pageSize).toLocaleString('en-IN')} of ${total.toLocaleString('en-IN')}`;
}

/**
 * The note a subscription screen carries where its data is invented: in the demo build (mock mode) only.
 * Against the billing API every figure is a stored record, so the note is not shown.
 */
export function PrototypeNote({ children }: { children?: ReactNode }) {
  if (API_MODE !== 'mock') return null;
  return (
    <p className={styles.prototypeNote}>
      <WarningCircle size={14} aria-hidden="true" />
      <span>{children ?? 'Demo data. Every Admin, price and payment here is invented — nothing is charged, refunded or collected.'}</span>
    </p>
  );
}
