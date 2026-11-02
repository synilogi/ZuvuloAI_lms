import type { Course, CoursePurchaseStatus } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';
import { courseSale, formatMoney, pricingOf } from '@syniastrolms/domain';
import { formatINR } from './format';

/*
 * How a course's price reads, wherever it is shown. One rule (`courseSale`, shared with the API): a free course
 * never shows a price, a paid one shows exactly the server's all-inclusive price, and one whose price no admin chose
 * is open to nobody — it never reads as free.
 */

export const NOT_OPEN = 'Not open for enrolment yet';
export const ALL_INCLUSIVE = 'All-inclusive price';

export type SaleDisplay =
  { kind: 'free'; label: 'Free' } | { kind: 'paid'; label: string; amount: number; wasLabel?: string } | { kind: 'unavailable'; label: typeof NOT_OPEN };

export function saleDisplay(course: Pick<Course, 'pricing' | 'price' | 'salePrice'>): SaleDisplay {
  const sale = courseSale(course);
  if (sale.kind === 'free') return { kind: 'free', label: 'Free' };
  if (sale.kind === 'paid')
    return { kind: 'paid', label: formatINR(sale.price.amount), amount: sale.price.amount, ...(sale.listPrice ? { wasLabel: formatINR(sale.listPrice) } : {}) };
  return { kind: 'unavailable', label: NOT_OPEN };
}

/** "Price, low to high": free first, then by price; a course nobody can join yet sorts last. */
export function priceSortKey(course: Pick<Course, 'pricing' | 'price' | 'salePrice'>): number {
  const sale = courseSale(course);
  return sale.kind === 'free' ? 0 : sale.kind === 'paid' ? sale.price.amount : Number.POSITIVE_INFINITY;
}

/** The admin's view of a course's pricing, as the editor and the overview show it. */
export function pricingSummary(course: Pick<Course, 'pricing' | 'price' | 'salePrice'>): { label: string; unset: boolean } {
  const pricing = pricingOf(course);
  if (pricing === 'free') return { label: 'Free', unset: false };
  const sale = courseSale(course);
  if (pricing === 'paid' && sale.kind === 'paid')
    return { label: `Paid · ${formatINR(sale.price.amount)}${sale.listPrice ? ` (list ${formatINR(sale.listPrice)})` : ''}`, unset: false };
  return { label: 'Not chosen', unset: true };
}

export const UNSET_WARNING = 'Choose Free or Paid — learners can’t join this course until you do.';

/** A purchase's amount (paise) as money. */
export const purchaseAmount = (p: { amount: number; currency: string }) => formatMoney(p.amount, p.currency);

export const PURCHASE_STATUS: Record<CoursePurchaseStatus, { label: string; tone: Tone }> = {
  paid: { label: 'Paid', tone: 'accent' },
  created: { label: 'Awaiting payment', tone: 'info' },
  failed: { label: 'Payment failed — try again', tone: 'danger' },
  expired: { label: 'Not completed', tone: 'neutral' },
};
