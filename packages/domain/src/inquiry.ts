/*
 * Requests to the platform team (SAAS-027, SAAS-029): a demo, a sales conversation or support. A website visitor's
 * request belongs to no academy; an academy admin's support request carries their academy, from the server context.
 * The Super Admin's inbox lists both, and moves each from new to closed.
 */

export const INQUIRY_KINDS = ['demo', 'sales', 'support'] as const;
export type InquiryKind = (typeof INQUIRY_KINDS)[number];

export const INQUIRY_STATUSES = ['new', 'in_progress', 'closed'] as const;
export type InquiryStatus = (typeof INQUIRY_STATUSES)[number];

export const INQUIRY_KIND_LABEL: Record<InquiryKind, string> = { demo: 'General', sales: 'Courses & orders', support: 'Support' };
export const INQUIRY_STATUS_LABEL: Record<InquiryStatus, string> = { new: 'New', in_progress: 'In progress', closed: 'Closed' };

export const isInquiryKind = (v: unknown): v is InquiryKind => typeof v === 'string' && (INQUIRY_KINDS as readonly string[]).includes(v);
export const isInquiryStatus = (v: unknown): v is InquiryStatus => typeof v === 'string' && (INQUIRY_STATUSES as readonly string[]).includes(v);

/** What the company website's contact form sends (`POST /public/inquiries`). */
export interface PublicInquiryInput {
  kind: InquiryKind;
  name: string;
  email: string;
  organisation?: string;
  phone?: string;
  /** How many learners the visitor expects, in their words. */
  size?: string;
  message: string;
}

/** A request as the Super Admin's inbox shows it. */
export interface Inquiry {
  id: string;
  kind: InquiryKind;
  status: InquiryStatus;
  name: string;
  email: string;
  organisation?: string;
  phone?: string;
  size?: string;
  subject?: string;
  message: string;
  /** The academy that raised it — absent for a website visitor. */
  academy?: { id: string; name: string; slug: string };
  note?: string;
  closedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface InquiryListResult {
  rows: Inquiry[];
  total: number;
  page: number;
  pageSize: number;
  /** Open requests by state, across the whole inbox — the badge counts. */
  counts: Record<InquiryStatus, number>;
}
