/**
 * Platform subscription data for the prototype billing layer.
 *
 * Every academy, price, invoice and timeline entry below is invented. It is generated from a fixed
 * seed so the same figures appear on every load and the overview's totals agree with the lists they
 * summarise. Nothing here corresponds to a real customer, a real payment or a real card: payment
 * methods carry a brand and four digits and nothing else.
 */

import type { Invoice, PaymentMethod, PaymentStatus, Plan, Subscription, SubscriptionEvent, SubscriptionStatus } from '@syniastrolms/domain';
import { BYTES_PER_GB, formatMoney, majorToMinor, type PlanLimits } from '@syniastrolms/domain';
import { addDays, createRandom, toIST } from '../random';
import { DEMO_NOW } from './learner';

const now = new Date(DEMO_NOW);

/** An ISO timestamp `days` from the demo clock, at a given IST wall-clock time. */
function stamp(days: number, hhmm = '11:20'): string {
  return `${toIST(addDays(now, days)).slice(0, 11)}${hhmm}:00+05:30`;
}

export const CURRENCY = 'INR';

/** Every amount in these fixtures is in paise; prices are written in whole rupees for readability. */
const inr = (rupees: number) => majorToMinor(rupees, CURRENCY);

/**
 * A plan's limits in the order learners, instructors, courses, storage (GB), live classes a month and
 * admin accounts, keyed by the entitlement catalogue. Storage is written in GB and held in bytes.
 */
const limits = (
  learners: number | null,
  instructors: number | null,
  courses: number | null,
  storageGb: number | null,
  liveClasses: number | null,
  admins: number | null,
): PlanLimits => ({
  'learners.max': learners,
  'instructors.max': instructors,
  'courses.max': courses,
  'storage.bytes': storageGb === null ? null : storageGb * BYTES_PER_GB,
  'live_classes.max': liveClasses,
  'admin_accounts.max': admins,
});

/* ─── Plans ─────────────────────────────────────────────────────────────── */

export const plans: Plan[] = [
  {
    id: 'starter',
    name: 'Starter',
    description: 'One teacher taking a first cohort online, with quizzes and a course catalog.',
    code: 'STARTER',
    monthlyPrice: inr(1499),
    annualPrice: inr(14990),
    currency: CURRENCY,
    cycles: ['monthly', 'annual'],
    trialEnabled: true,
    trialDays: 14,
    limits: limits(150, 2, 10, 25, 4, 1),
    features: ['courses.manage', 'assessments.manage'],
    status: 'active',
    order: 1,
    createdAt: stamp(-520, '10:00'),
    updatedAt: stamp(-96, '15:40'),
  },
  {
    id: 'growth',
    name: 'Growth',
    description: 'A small faculty running scheduled batches, certificates and weekly live classes.',
    code: 'GROWTH',
    monthlyPrice: inr(3999),
    annualPrice: inr(39990),
    currency: CURRENCY,
    cycles: ['monthly', 'annual'],
    trialEnabled: true,
    trialDays: 14,
    limits: limits(750, 8, 40, 150, 20, 3),
    features: ['courses.manage', 'assessments.manage', 'certificates.manage', 'live_classes', 'reports.basic'],
    status: 'active',
    order: 2,
    createdAt: stamp(-520, '10:05'),
    updatedAt: stamp(-41, '12:10'),
  },
  {
    id: 'professional',
    name: 'Professional',
    description: 'An established academy with several tracks, deep reporting and its own branding.',
    code: 'PRO',
    monthlyPrice: inr(8999),
    annualPrice: inr(89990),
    currency: CURRENCY,
    cycles: ['monthly', 'annual'],
    trialEnabled: true,
    trialDays: 21,
    limits: limits(2500, 25, 150, 500, 80, 8),
    features: [
      'courses.manage',
      'assessments.manage',
      'certificates.manage',
      'live_classes',
      'reports.basic',
      'reports.advanced',
      'analytics.advanced',
      'custom_branding',
    ],
    status: 'active',
    order: 3,
    createdAt: stamp(-520, '10:10'),
    updatedAt: stamp(-18, '17:25'),
  },
  {
    id: 'enterprise',
    name: 'Enterprise',
    description: 'Institutions with no ceiling on learners or courses, billed against a signed agreement.',
    code: 'ENTERPRISE',
    monthlyPrice: inr(24999),
    annualPrice: inr(249990),
    currency: CURRENCY,
    cycles: ['annual'],
    trialEnabled: false,
    trialDays: 0,
    limits: limits(null, null, null, 2000, null, 20),
    features: [
      'courses.manage',
      'assessments.manage',
      'certificates.manage',
      'live_classes',
      'reports.basic',
      'reports.advanced',
      'analytics.advanced',
      'custom_branding',
      'priority_support',
    ],
    status: 'active',
    order: 4,
    createdAt: stamp(-470, '16:00'),
    updatedAt: stamp(-7, '09:50'),
  },
  {
    id: 'scholar',
    name: 'Scholar',
    description: 'A single teacher with one course — being written for astrology tutors teaching part time.',
    code: 'SCHOLAR',
    monthlyPrice: inr(749),
    annualPrice: inr(7490),
    currency: CURRENCY,
    cycles: ['monthly', 'annual'],
    trialEnabled: true,
    trialDays: 7,
    limits: limits(60, 1, 5, 10, 2, 1),
    features: ['courses.manage', 'assessments.manage'],
    status: 'draft',
    order: 5,
    createdAt: stamp(-23, '14:30'),
    updatedAt: stamp(-2, '18:05'),
  },
  {
    id: 'legacy-professional',
    name: 'Professional (2025)',
    description: 'The previous Professional pricing. Closed to new sign-ups; the academies on it keep it.',
    code: 'PRO-2025',
    monthlyPrice: inr(6999),
    annualPrice: inr(69990),
    currency: CURRENCY,
    cycles: ['monthly', 'annual'],
    trialEnabled: false,
    trialDays: 0,
    limits: limits(2000, 20, 120, 400, 60, 5),
    features: ['courses.manage', 'assessments.manage', 'certificates.manage', 'live_classes', 'reports.basic'],
    status: 'archived',
    order: 6,
    createdAt: stamp(-700, '11:00'),
    updatedAt: stamp(-150, '11:00'),
  },
];

/* ─── Customers ─────────────────────────────────────────────────────────── */

interface Seed {
  name: string;
  city: string;
  planId: string;
  status: SubscriptionStatus;
  cycle: 'monthly' | 'annual';
}

/*
 * The customer list is written out rather than generated, so the mix of plans and states is
 * deliberate: enough trials to fill the trial tab, enough past-due to show the grace-period UI, a
 * couple of academies still on the archived 2025 plan, and a mix of cycles on every live plan.
 */
const SEEDS: Seed[] = [
  { name: 'Nakshatra Vidya Peeth', city: 'Pune', planId: 'professional', status: 'active', cycle: 'annual' },
  { name: 'Brihat Jyotish Academy', city: 'Varanasi', planId: 'enterprise', status: 'active', cycle: 'annual' },
  { name: 'Saptarishi School of Astrology', city: 'Bengaluru', planId: 'professional', status: 'active', cycle: 'monthly' },
  { name: 'Kundali Kendra', city: 'Jaipur', planId: 'growth', status: 'active', cycle: 'monthly' },
  { name: 'Aadhya Vedic Institute', city: 'Hyderabad', planId: 'growth', status: 'active', cycle: 'annual' },
  { name: 'Chandra Marga Gurukul', city: 'Ujjain', planId: 'starter', status: 'active', cycle: 'monthly' },
  { name: 'Drishti Jyotish Kendra', city: 'Kolkata', planId: 'growth', status: 'past-due', cycle: 'monthly' },
  { name: 'Panchanga Research Trust', city: 'Thiruvananthapuram', planId: 'professional', status: 'active', cycle: 'annual' },
  { name: 'Surya Siddhanta Academy', city: 'Ahmedabad', planId: 'growth', status: 'trial', cycle: 'monthly' },
  { name: 'Vastu and Jyotish Vidyalaya', city: 'Chennai', planId: 'starter', status: 'trial', cycle: 'monthly' },
  { name: 'Graha Shanti Learning', city: 'Nashik', planId: 'starter', status: 'past-due', cycle: 'monthly' },
  { name: 'Parashari Study Circle', city: 'Indore', planId: 'growth', status: 'canceling', cycle: 'monthly' },
  { name: 'Lagna Institute of Astrology', city: 'Mumbai', planId: 'professional', status: 'active', cycle: 'monthly' },
  { name: 'Rashi Chakra Academy', city: 'Lucknow', planId: 'starter', status: 'active', cycle: 'annual' },
  { name: 'Hora Shastra Kendra', city: 'Mysuru', planId: 'starter', status: 'canceled', cycle: 'monthly' },
  { name: 'Muhurta Vidya Sadan', city: 'Bhopal', planId: 'growth', status: 'active', cycle: 'monthly' },
  { name: 'Jyotirvid Parishad', city: 'Patna', planId: 'legacy-professional', status: 'active', cycle: 'annual' },
  { name: 'Ketu Marga Research', city: 'Guwahati', planId: 'starter', status: 'paused', cycle: 'monthly' },
  { name: 'Ashtakavarga Academy', city: 'Coimbatore', planId: 'growth', status: 'active', cycle: 'annual' },
  { name: 'Navamsa Learning Trust', city: 'Vadodara', planId: 'growth', status: 'trial', cycle: 'annual' },
  { name: 'Dasha Phala Institute', city: 'Amritsar', planId: 'starter', status: 'expired', cycle: 'monthly' },
  { name: 'Shodasha Varga Vidyalaya', city: 'Madurai', planId: 'professional', status: 'active', cycle: 'annual' },
  { name: 'Tithi Nirnaya Academy', city: 'Nagpur', planId: 'starter', status: 'active', cycle: 'monthly' },
  { name: 'Prashna Marga Kendra', city: 'Kochi', planId: 'growth', status: 'active', cycle: 'monthly' },
  { name: 'Yoga Karaka School', city: 'Surat', planId: 'starter', status: 'trial', cycle: 'monthly' },
  { name: 'Bhava Chalita Institute', city: 'Ranchi', planId: 'legacy-professional', status: 'canceling', cycle: 'monthly' },
  { name: 'Grahan Vidya Kendra', city: 'Raipur', planId: 'starter', status: 'canceled', cycle: 'monthly' },
  { name: 'Sarvatobhadra Academy', city: 'Kanpur', planId: 'growth', status: 'active', cycle: 'annual' },
  { name: 'Chara Karaka Gurukul', city: 'Dehradun', planId: 'starter', status: 'active', cycle: 'monthly' },
  { name: 'Vimshottari Study Centre', city: 'Chandigarh', planId: 'growth', status: 'past-due', cycle: 'annual' },
  { name: 'Aruna Jyotish Peeth', city: 'Bhubaneswar', planId: 'starter', status: 'active', cycle: 'monthly' },
  { name: 'Kaala Purusha Institute', city: 'Jodhpur', planId: 'professional', status: 'paused', cycle: 'monthly' },
  { name: 'Shubha Muhurta Vidyalaya', city: 'Tiruchirappalli', planId: 'starter', status: 'active', cycle: 'annual' },
  { name: 'Trikona Research Academy', city: 'Shimla', planId: 'growth', status: 'active', cycle: 'monthly' },
  { name: 'Nadi Granth Sansthan', city: 'Tanjore', planId: 'enterprise', status: 'active', cycle: 'annual' },
  { name: 'Upagraha Learning', city: 'Agra', planId: 'starter', status: 'expired', cycle: 'monthly' },
  { name: 'Kendra Trikona Academy', city: 'Gwalior', planId: 'growth', status: 'active', cycle: 'monthly' },
  { name: 'Panchang Pathshala', city: 'Haridwar', planId: 'starter', status: 'canceled', cycle: 'monthly' },
];

const CARD_BRANDS = ['Visa', 'Mastercard', 'RuPay'];
const BANKS = ['HDFC Bank', 'ICICI Bank', 'Axis Bank', 'State Bank of India'];

const CANCEL_REASONS = [
  'Moved the programme back to in-person teaching.',
  'Cohort finished and no new intake is planned.',
  'Cost — the academy is between funding rounds.',
  'Consolidating onto the parent institute’s platform.',
];

const slug = (name: string) =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');

const emailFor = (name: string) => `billing@${slug(name).split('-').slice(0, 2).join('')}.in`;

function paymentMethod(random: ReturnType<typeof createRandom>, planId: string): PaymentMethod {
  if (planId === 'enterprise') return { kind: 'invoice', brand: 'Bank transfer' };
  const roll = random.next();
  if (roll < 0.62) {
    const brand = random.pick(CARD_BRANDS);
    return { kind: 'card', brand, last4: String(random.int(1000, 9999)), expiry: `${String(random.int(1, 12)).padStart(2, '0')}/${random.int(27, 31)}` };
  }
  // A UPI mandate has no card number to mask, so it carries a brand and nothing else.
  if (roll < 0.84) return { kind: 'upi', brand: 'UPI autopay' };
  return { kind: 'netbanking', brand: random.pick(BANKS), last4: String(random.int(1000, 9999)) };
}

const planFor = (id: string) => plans.find((p) => p.id === id)!;

function build(): Subscription[] {
  return SEEDS.map((seed, index) => {
    const random = createRandom(4700 + index * 31);
    const plan = planFor(seed.planId);
    const amount = seed.cycle === 'annual' ? plan.annualPrice : plan.monthlyPrice;
    const id = `sub-${String(index + 1).padStart(4, '0')}`;
    const ageDays = random.int(seed.status === 'trial' ? 2 : 40, seed.status === 'trial' ? 11 : 780);
    const startedAt = stamp(-ageDays, `${String(random.int(9, 19)).padStart(2, '0')}:${random.pick(['05', '15', '30', '45'])}`);
    const method = paymentMethod(random, seed.planId);
    const learners = plan.limits['learners.max'] === null ? random.int(1800, 4200) : Math.round(plan.limits['learners.max'] * random.between(0.24, 0.94));

    const base: Subscription = {
      id,
      customer: {
        id: `acad-${slug(seed.name)}`,
        name: seed.name,
        email: emailFor(seed.name),
        city: seed.city,
        country: 'India',
        learners,
      },
      planId: seed.planId,
      status: seed.status,
      cycle: seed.cycle,
      amount,
      currency: CURRENCY,
      startedAt,
      renewsAt: stamp(random.int(2, seed.cycle === 'annual' ? 220 : 27), '06:00'),
      paymentMethod: method,
      lastPaymentAt: stamp(-random.int(3, seed.cycle === 'annual' ? 180 : 28), '06:04'),
      lastPaymentStatus: 'paid',
    };

    switch (seed.status) {
      case 'trial': {
        const trialDay = random.int(2, Math.max(3, plan.trialDays - 2));
        return {
          ...base,
          trialStartedAt: stamp(-trialDay, '10:00'),
          trialEndsAt: stamp(plan.trialDays - trialDay, '10:00'),
          renewsAt: stamp(plan.trialDays - trialDay, '10:00'),
          lastPaymentAt: undefined,
          lastPaymentStatus: undefined,
        };
      }
      case 'past-due': {
        const failedDaysAgo = random.int(2, 9);
        return {
          ...base,
          lastPaymentAt: stamp(-failedDaysAgo, '06:04'),
          lastPaymentStatus: 'failed',
          amountDue: amount,
          retriesUsed: Math.min(3, Math.floor(failedDaysAgo / 3)),
          nextRetryAt: stamp(random.int(1, 3), '06:04'),
          graceEndsAt: stamp(14 - failedDaysAgo, '23:59'),
          renewsAt: stamp(-failedDaysAgo, '06:00'),
        };
      }
      case 'canceling': {
        const requested = random.int(1, 12);
        return {
          ...base,
          canceledAt: stamp(-requested, '15:20'),
          cancelReason: random.pick(CANCEL_REASONS),
          cancelAt: 'period-end',
          renewsAt: stamp(random.int(4, 24), '06:00'),
        };
      }
      case 'canceled': {
        const ended = random.int(6, 140);
        return {
          ...base,
          canceledAt: stamp(-ended, '15:20'),
          cancelReason: random.pick(CANCEL_REASONS),
          cancelAt: random.chance(0.4) ? 'immediately' : 'period-end',
          renewsAt: stamp(-ended, '06:00'),
          lastPaymentAt: stamp(-ended - random.int(1, 30), '06:04'),
        };
      }
      case 'paused': {
        const pausedDaysAgo = random.int(4, 40);
        const resumeIn = random.int(9, 75);
        return {
          ...base,
          pausedAt: stamp(-pausedDaysAgo, '12:00'),
          resumesAt: stamp(resumeIn, '06:00'),
          renewsAt: stamp(resumeIn, '06:00'),
        };
      }
      case 'expired': {
        const expiredDaysAgo = random.int(12, 120);
        return {
          ...base,
          trialStartedAt: stamp(-expiredDaysAgo - plan.trialDays, '10:00'),
          trialEndsAt: stamp(-expiredDaysAgo, '10:00'),
          renewsAt: stamp(-expiredDaysAgo, '10:00'),
          lastPaymentAt: undefined,
          lastPaymentStatus: undefined,
        };
      }
      default:
        return base;
    }
  });
}

/** Mutable: the screens change these records, and the change lasts until the page is reloaded. */
export const subscriptions: Subscription[] = build();

/* ─── History ───────────────────────────────────────────────────────────── */

const money = (minor: number) => formatMoney(minor, CURRENCY);

function historyFor(subscription: Subscription): SubscriptionEvent[] {
  const random = createRandom(9100 + Number(subscription.id.slice(4)) * 17);
  const plan = planFor(subscription.planId);
  const events: SubscriptionEvent[] = [];
  const push = (kind: SubscriptionEvent['kind'], at: string, summary: string, actor = 'Billing') =>
    events.push({ id: `${subscription.id}-${kind}-${events.length}`, subscriptionId: subscription.id, kind, at, summary, actor });

  push('created', subscription.startedAt, `${subscription.customer.name} signed up on ${plan.name}.`, 'Customer');
  if (subscription.trialStartedAt) push('trial-started', subscription.trialStartedAt, `${plan.trialDays}-day trial started.`, 'Customer');

  if (subscription.status !== 'trial' && subscription.status !== 'expired') {
    if (subscription.trialStartedAt)
      push('trial-converted', subscription.startedAt, `Trial converted to a paid ${subscription.cycle} subscription.`, 'Customer');

    // A couple of renewals, oldest first, ending just before the last payment.
    const renewals = subscription.cycle === 'annual' ? 1 : random.int(2, 4);
    for (let i = renewals; i >= 1; i--) {
      const days = i * (subscription.cycle === 'annual' ? 365 : 30) + random.int(0, 2);
      push('payment-received', stamp(-days, '06:04'), `${money(subscription.amount)} collected for the ${subscription.cycle} period.`);
    }
    if (random.chance(0.28)) {
      push('plan-changed', stamp(-random.int(60, 200), '14:10'), `Moved from Starter to ${plan.name} on the ${subscription.cycle} cycle.`, 'Platform admin');
    }
  }

  if (subscription.lastPaymentStatus === 'failed' && subscription.lastPaymentAt) {
    push(
      'payment-failed',
      subscription.lastPaymentAt,
      `${money(subscription.amount)} declined — ${subscription.paymentMethod.kind === 'card' ? 'the card was refused' : 'the mandate was refused'}.`,
    );
  } else if (subscription.lastPaymentAt) {
    push('payment-received', subscription.lastPaymentAt, `${money(subscription.amount)} collected.`);
  }

  if (subscription.pausedAt) {
    push('paused', subscription.pausedAt, `Paused until ${subscription.resumesAt?.slice(0, 10)}.`, 'Platform admin');
  }
  if (subscription.canceledAt) {
    push('cancellation-requested', subscription.canceledAt, subscription.cancelReason ?? 'Cancellation requested.', 'Customer');
    if (subscription.status === 'canceled') {
      push('cancellation-completed', subscription.renewsAt, 'Access closed at the end of the paid period.');
    }
  }
  return events.sort((a, b) => b.at.localeCompare(a.at));
}

export const subscriptionEvents: Record<string, SubscriptionEvent[]> = Object.fromEntries(subscriptions.map((s) => [s.id, historyFor(s)]));

/* ─── Invoices ──────────────────────────────────────────────────────────── */

const FAILURE_NOTES = [
  'The card issuer declined the charge (insufficient funds).',
  'The mandate has expired and needs the academy to re-authorise it.',
  'The card was reported lost and has been blocked.',
];

const REFUND_NOTES = ['Refunded in full after a duplicate charge.', 'Pro-rated refund agreed when the academy downgraded mid-period.'];

function invoicesFor(subscription: Subscription, counter: { next: number }): Invoice[] {
  const random = createRandom(5500 + Number(subscription.id.slice(4)) * 13);
  const plan = planFor(subscription.planId);
  if (subscription.status === 'trial') return [];

  const periodDays = subscription.cycle === 'annual' ? 365 : 30;
  const count = subscription.status === 'expired' ? 0 : subscription.cycle === 'annual' ? random.int(1, 2) : random.int(2, 5);
  const out: Invoice[] = [];

  for (let i = 0; i < count; i++) {
    const issuedDaysAgo = i * periodDays + random.int(0, 3);
    const isLatest = i === 0;
    let status: PaymentStatus = 'paid';
    if (isLatest && subscription.lastPaymentStatus === 'failed') status = 'failed';
    else if (isLatest && subscription.status === 'active' && random.chance(0.12)) status = 'pending';
    else if (!isLatest && random.chance(0.07)) status = 'refunded';

    const number = `INV-2026-${String(counter.next++).padStart(4, '0')}`;
    const lines = [
      {
        description: `${plan.name} — ${subscription.cycle === 'annual' ? 'annual' : 'monthly'} subscription`,
        quantity: 1,
        unitAmount: subscription.amount,
      },
    ];
    if (subscription.planId === 'enterprise' && random.chance(0.5)) {
      lines.push({ description: 'Additional media storage — 500 GB', quantity: 1, unitAmount: inr(7500) });
    }

    out.push({
      id: number.toLowerCase(),
      number,
      subscriptionId: subscription.id,
      customerId: subscription.customer.id,
      customerName: subscription.customer.name,
      planName: plan.name,
      cycle: subscription.cycle,
      issuedAt: stamp(-issuedDaysAgo, '06:00'),
      periodStart: stamp(-issuedDaysAgo, '06:00'),
      periodEnd: stamp(-issuedDaysAgo + periodDays, '06:00'),
      lines,
      taxPercent: 18,
      currency: CURRENCY,
      status,
      paidAt: status === 'paid' || status === 'refunded' ? stamp(-issuedDaysAgo, '06:04') : undefined,
      method: subscription.paymentMethod,
      note: status === 'failed' ? random.pick(FAILURE_NOTES) : status === 'refunded' ? random.pick(REFUND_NOTES) : undefined,
      billingAddress: [
        subscription.customer.name,
        `${random.int(12, 480)} ${random.pick(['Shastri Marg', 'Temple Road', 'Ashram Lane', 'Gandhi Path'])}`,
        `${subscription.customer.city}, India`,
      ],
    });
  }
  return out;
}

const counter = { next: 1 };

/** Every invoice on the platform, newest first. Mutable so a recorded payment can change one. */
export const invoices: Invoice[] = subscriptions.flatMap((s) => invoicesFor(s, counter)).sort((a, b) => b.issuedAt.localeCompare(a.issuedAt));
