import type { InquiryKind, PublicInquiryInput } from '@syniastrolms/domain';
import { isInquiryKind } from '@syniastrolms/domain';

/* The contact form's rules, apart from its markup. The API applies the same ones. */

export interface ContactForm {
  kind: InquiryKind;
  name: string;
  email: string;
  phone: string;
  message: string;
  /** The honeypot: never shown to people. */
  website: string;
}

/** The topic from `/contact?topic=…`, or a general question by default. */
export const topicFrom = (params: URLSearchParams): InquiryKind => {
  const topic = params.get('topic');
  return isInquiryKind(topic) ? topic : 'demo';
};

export const emptyContact = (kind: InquiryKind): ContactForm => ({
  kind,
  name: '',
  email: '',
  phone: '',
  message: '',
  website: '',
});

export function contactIssues(form: ContactForm): Partial<Record<keyof ContactForm, string>> {
  const issues: Partial<Record<keyof ContactForm, string>> = {};
  if (form.name.trim().length < 2) issues.name = 'Enter your name.';
  if (!/^\S+@\S+\.\S+$/.test(form.email.trim())) issues.email = 'Enter a valid email address.';
  if (form.phone && !/^[+()\d\s-]*$/.test(form.phone)) issues.phone = 'Enter a phone number with digits, spaces, + ( ) or -.';
  if (form.message.trim().length < 10) issues.message = 'Tell us a little more — at least 10 characters.';
  return issues;
}

/** What is sent: trimmed, with empty optional fields left out. */
export function contactPayload(form: ContactForm): PublicInquiryInput & { website?: string } {
  const opt = (v: string) => (v.trim() ? v.trim() : undefined);
  return {
    kind: form.kind,
    name: form.name.trim(),
    email: form.email.trim(),
    phone: opt(form.phone),
    message: form.message.trim(),
    ...(form.website ? { website: form.website } : {}),
  };
}

export const CONTACT_COPY: Record<InquiryKind, { title: string; lead: string; button: string; message: string }> = {
  demo: {
    title: 'Contact us',
    lead: 'Questions about courses, teaching or the affiliate program. Tell us what you need, and we’ll reply by email.',
    button: 'Send message',
    message: 'How can we help?',
  },
  sales: {
    title: 'Courses and orders',
    lead: 'Ask about a course before you buy, or about an order you have placed. An order number helps if you have one.',
    button: 'Send message',
    message: 'Which course or order is this about?',
  },
  support: {
    title: 'Get support',
    lead: 'Having trouble with your account or a course? Tell us what happened, and we’ll reply by email.',
    button: 'Send to support',
    message: 'What happened, and what did you expect?',
  },
};
