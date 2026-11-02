import type { CoursePurchase, CourseQuote, Enrollment } from '@syniastrolms/domain';
import { chargeOf, courseSale } from '@syniastrolms/domain';
import { ServiceError, type CoursePurchaseConfirmation, type CoursePurchaseStart } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { mockNowIso } from './clock';
import { courses } from './fixtures/catalog';
import { personas } from './fixtures/learner';
import { enrollments } from './fixtures/people';

/*
 * The demo build's course purchases. There is no gateway: an order is "paid" on the demo's own test checkout
 * (`/sandbox-checkout/:orderId`, the page the sandbox gateway uses), and — as on the API — the course opens only
 * when the purchase is next checked (`status`), never because the page said so.
 */

const ME = personas.student.id;

interface Held {
  view: CoursePurchase;
  orderId: string;
  payments: ('paid' | 'failed')[];
}

const held = new Map<string, Held>();
const byOrder = new Map<string, string>();
let seq = 0;

const holds = (courseId: string) => enrollments.some((e) => e.studentId === ME && e.courseId === courseId && e.status !== 'expired');
const refresh = (h: Held): CoursePurchase => ({ ...h.view, enrolled: holds(h.view.courseId) });

/** What the demo learner would pay. The demo has no coupons: a code is the API's to check. */
export function quoteMockPurchase(courseId: string): CourseQuote {
  const course = courses.find((c) => c.id === courseId);
  const sale = course ? courseSale(course) : null;
  if (!sale || sale.kind !== 'paid') throw new ServiceError('This course isn’t for sale.', 'conflict', 'COURSE_NOT_FOR_SALE', undefined, 409);
  const charge = chargeOf(sale.price);
  return { listPrice: sale.listPrice ?? sale.price.amount, charge, discount: 0, total: charge };
}

/** Opens (or reuses) the demo learner's order for a paid course, priced from the course itself. */
export function startMockPurchase(courseId: string): CoursePurchaseStart {
  const course = courses.find((c) => c.id === courseId);
  if (!course || course.status !== 'published' || course.visibility === 'private') throw new ServiceError('Course not found.', 'not-found');
  const sale = courseSale(course);
  if (sale.kind === 'free') throw new ServiceError('This course is free. Enrol in it instead.', 'conflict', 'CONFLICT', undefined, 409);
  if (sale.kind === 'unavailable')
    throw new ServiceError('This course isn’t open for enrolment yet. Contact the LMS.', 'conflict', 'COURSE_NOT_FOR_SALE', undefined, 409);
  if (holds(courseId)) throw new ServiceError('You already have this course.', 'conflict', 'ALREADY_ENROLLED', undefined, 409);

  // A failed attempt leaves the order open for another: the same purchase is handed back.
  let open = [...held.values()].find((h) => h.view.courseId === courseId && (h.view.status === 'created' || h.view.status === 'failed'));
  if (open && open.view.amount !== chargeOf(sale.price)) {
    open.view.status = 'expired';
    open = undefined;
  }
  if (!open) {
    seq += 1;
    const id = `mock-purchase-${seq}`;
    const orderId = `mock_order_${seq}_${Date.now().toString(36)}`;
    open = {
      orderId,
      payments: [],
      view: {
        id,
        orderNumber: `ORD-DEMO-${String(seq).padStart(6, '0')}`,
        courseId,
        courseTitle: course.title,
        status: 'created',
        amount: chargeOf(sale.price),
        currency: 'INR',
        listPrice: sale.listPrice ?? sale.price.amount,
        enrolled: false,
        createdAt: mockNowIso(),
      },
    };
    held.set(id, open);
    byOrder.set(orderId, id);
  }
  const persona = personas.student;
  return {
    purchase: refresh(open),
    checkout: {
      provider: 'sandbox',
      orderId: open.orderId,
      amount: open.view.amount,
      currency: 'INR',
      redirectUrl: `${typeof window === 'undefined' ? 'http://localhost' : window.location.origin}/sandbox-checkout/${open.orderId}`,
      description: course.title,
      prefill: { name: persona.name, email: persona.email },
    },
  };
}

/** Settles a purchase whose order has a paid payment: marks it paid and opens the course, once. */
function settle(h: Held) {
  if (h.view.status === 'paid' || !h.payments.includes('paid')) return;
  h.view.status = 'paid';
  h.view.paidAt = mockNowIso();
  h.view.paymentReference = `pay_demo_${h.view.id}`;
  delete h.view.failureMessage;
  if (holds(h.view.courseId)) {
    h.view.needsReview = true;
    return;
  }
  const enrollment: Enrollment = {
    id: `en-${Date.now().toString(36)}`,
    studentId: ME,
    courseId: h.view.courseId,
    enrolledAt: mockNowIso(),
    status: 'active',
    progress: 0,
    source: 'purchase',
    lastActiveAt: mockNowIso(),
  };
  enrollments.push(enrollment);
  const course = courses.find((c) => c.id === h.view.courseId);
  if (course) course.enrolledCount += 1;
  invalidateAnalytics();
}

function own(purchaseId: string) {
  const h = held.get(purchaseId);
  if (!h) throw new ServiceError('Purchase not found.', 'not-found');
  return h;
}

export function mockPurchaseStatus(purchaseId: string): CoursePurchase {
  const h = own(purchaseId);
  settle(h);
  return refresh(h);
}

/** The demo has no signatures to check: a completion settles only what the test checkout actually paid. */
export function confirmMockPurchase(purchaseId: string): CoursePurchaseConfirmation {
  const h = own(purchaseId);
  settle(h);
  const purchase = refresh(h);
  if (purchase.status === 'paid')
    return { purchase, outcome: { status: 'paid', enrolled: purchase.enrolled, message: 'Payment confirmed. The course is open.' } };
  if (purchase.status === 'failed')
    return { purchase, outcome: { status: 'failed', enrolled: false, message: purchase.failureMessage ?? 'The payment was declined. You can try again.' } };
  return { purchase, outcome: { status: 'pending', enrolled: false, message: 'Your payment is being confirmed. The course opens as soon as it is.' } };
}

export const listMockPurchases = (): CoursePurchase[] =>
  [...held.values()].map((h) => (settle(h), refresh(h))).sort((a, b) => b.createdAt.localeCompare(a.createdAt));

/* ─── The demo's test checkout ─── */

export function mockOrder(orderId: string) {
  const id = byOrder.get(orderId);
  const h = id ? held.get(id) : undefined;
  if (!h) return undefined;
  return {
    orderId,
    amount: h.view.amount,
    currency: h.view.currency,
    receipt: h.view.id,
    status: h.payments.includes('paid') ? 'paid' : (h.payments[h.payments.length - 1] ?? 'created'),
  };
}

export function payMockOrder(orderId: string, outcome: 'success' | 'failure') {
  const id = byOrder.get(orderId);
  const h = id ? held.get(id) : undefined;
  if (!h) throw new ServiceError('No such order at the demo checkout.', 'not-found');
  if (h.payments.includes('paid')) throw new ServiceError('This order is already paid.', 'conflict');
  h.payments.push(outcome === 'success' ? 'paid' : 'failed');
  if (outcome === 'failure') {
    // As on the API: the latest attempt was declined — failed, and retryable on the same order.
    h.view.status = 'failed';
    h.view.failureMessage = 'The test card was declined.';
  }
  return { paymentId: `mock_pay_${h.payments.length}`, status: outcome === 'success' ? 'paid' : 'failed', webhookDelivered: false };
}
