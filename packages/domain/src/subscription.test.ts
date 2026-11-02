import { describe, expect, it } from 'vitest';
import {
  annualSavingPercent,
  daysUntil,
  invoiceSubtotal,
  invoiceTax,
  invoiceTotal,
  isBilling,
  monthlyValue,
  planChangeEffect,
  normalisePlanCode,
  reachablePlanStatuses,
  validatePlan,
  validatePlanTerms,
  type Invoice,
  type Plan,
  type PlanInput,
} from './subscription';
import { BYTES_PER_GB } from './entitlement';

const plan = (over: Partial<PlanInput> = {}): PlanInput => ({
  name: 'Growth',
  description: 'A small faculty running scheduled batches.',
  code: 'GROWTH',
  monthlyPrice: 399900,
  annualPrice: 3999000,
  currency: 'INR',
  cycles: ['monthly', 'annual'],
  trialEnabled: true,
  trialDays: 14,
  limits: {
    'learners.max': 750,
    'instructors.max': 8,
    'courses.max': 40,
    'storage.bytes': 150 * BYTES_PER_GB,
    'live_classes.max': 20,
    'admin_accounts.max': 3,
  },
  features: ['courses.manage'],
  status: 'active',
  order: 2,
  ...over,
});

describe('validatePlan', () => {
  it('accepts a well-formed plan', () => {
    expect(validatePlan(plan())).toEqual([]);
  });

  it('rejects a duplicate code regardless of case or padding', () => {
    expect(validatePlan(plan({ code: ' growth ' }), ['GROWTH'])).toContainEqual({
      field: 'code',
      message: 'The code GROWTH already belongs to another plan.',
    });
  });

  it('accepts its own code when the plan is being edited', () => {
    // The caller passes the codes of *other* plans, so editing never trips over itself.
    expect(validatePlan(plan(), ['STARTER', 'PRO'])).toEqual([]);
  });

  it('refuses a code that is not in the agreed shape', () => {
    for (const code of ['', 'g', 'has space', '-LEADING', 'LOWERcase!']) {
      expect(validatePlan(plan({ code })).some((i) => i.field === 'code')).toBe(true);
    }
  });

  it('only prices the cycles the plan is sold on', () => {
    const annualOnly = plan({ cycles: ['annual'], monthlyPrice: -10000 });
    expect(validatePlan(annualOnly)).toEqual([]);
  });

  it('refuses a negative price on a cycle that is offered', () => {
    expect(validatePlan(plan({ monthlyPrice: -1 }))).toContainEqual({
      field: 'monthlyPrice',
      message: 'Enter a price above zero, to at most 2 decimal places.',
    });
  });

  it('refuses a zero price on a cycle that is offered, and allows it on one that is not', () => {
    expect(validatePlan(plan({ monthlyPrice: 0 }))).toContainEqual({
      field: 'monthlyPrice',
      message: 'Enter a price above zero for the monthly cycle, or stop offering it.',
    });
    expect(validatePlan(plan({ cycles: ['annual'], monthlyPrice: 0 })).some((i) => i.field === 'monthlyPrice')).toBe(false);
  });

  it('refuses a year that costs more than twelve months', () => {
    expect(validatePlan(plan({ annualPrice: 399900 * 12 + 1 })).some((i) => i.field === 'annualPrice')).toBe(true);
    expect(validatePlan(plan({ annualPrice: 399900 * 12 })).some((i) => i.field === 'annualPrice')).toBe(false);
  });

  it('bounds the trial only when a trial is offered', () => {
    expect(validatePlan(plan({ trialDays: 0 })).some((i) => i.field === 'trialDays')).toBe(true);
    expect(validatePlan(plan({ trialDays: 91 })).some((i) => i.field === 'trialDays')).toBe(true);
    expect(validatePlan(plan({ trialEnabled: false, trialDays: 0 })).some((i) => i.field === 'trialDays')).toBe(false);
  });

  it('treats null as unlimited rather than as zero', () => {
    const unlimited = plan({
      limits: {
        'learners.max': null,
        'instructors.max': null,
        'courses.max': null,
        'storage.bytes': null,
        'live_classes.max': null,
        'admin_accounts.max': null,
      },
    });
    expect(validatePlan(unlimited)).toEqual([]);
    expect(validatePlan(plan({ limits: { ...plan().limits, 'courses.max': 0 } })).some((i) => i.field === 'limits')).toBe(true);
  });

  it('needs a value for every catalogue limit, and only catalogue limits', () => {
    const withoutCourses = Object.fromEntries(Object.entries(plan().limits).filter(([key]) => key !== 'courses.max'));
    expect(validatePlan(plan({ limits: withoutCourses as never })).some((i) => i.field === 'limits')).toBe(true);
    expect(validatePlan(plan({ limits: { ...plan().limits, 'seats.max': 5 } as never })).some((i) => i.field === 'limits')).toBe(true);
    expect(validatePlan(plan({ limits: { ...plan().limits, 'storage.bytes': 1.5 } })).some((i) => i.field === 'limits')).toBe(true);
  });

  it('grants only catalogue features, each once', () => {
    expect(validatePlan(plan({ features: ['course-management' as never] })).some((i) => i.field === 'features')).toBe(true);
    expect(validatePlan(plan({ features: ['courses.manage', 'courses.manage'] })).some((i) => i.field === 'features')).toBe(true);
    expect(validatePlan(plan({ features: ['courses.manage', 'custom_branding'] }))).toEqual([]);
  });

  it('takes prices only as whole minor units', () => {
    // Half a paisa is not an amount anyone can be charged.
    expect(validatePlan(plan({ monthlyPrice: 3999.5 })).some((i) => i.field === 'monthlyPrice')).toBe(true);
    expect(validatePlan(plan({ monthlyPrice: Number.NaN })).some((i) => i.field === 'monthlyPrice')).toBe(true);
    expect(validatePlan(plan({ monthlyPrice: 399950 }))).toEqual([]);
  });

  it('bounds a price in the currency it is written in', () => {
    expect(validatePlan(plan({ monthlyPrice: 10_000_000 * 100 }))).toEqual([]);
    expect(validatePlan(plan({ monthlyPrice: 10_000_000 * 100 + 1, annualPrice: 0 })).some((i) => i.field === 'monthlyPrice')).toBe(true);
    // Yen has no minor unit, so the same ceiling is a smaller number.
    expect(validatePlan(plan({ currency: 'JPY', monthlyPrice: 10_000_001, annualPrice: 0 })).some((i) => i.field === 'monthlyPrice')).toBe(true);
  });

  it('needs a currency the runtime knows', () => {
    for (const currency of ['', 'inr', 'RUPEES', 'ZZZ']) {
      expect(
        validatePlan(plan({ currency })).some((i) => i.field === 'currency'),
        currency,
      ).toBe(true);
    }
  });

  it('needs at least one feature and one cycle', () => {
    expect(validatePlan(plan({ features: [] })).some((i) => i.field === 'features')).toBe(true);
    expect(validatePlan(plan({ cycles: [] })).some((i) => i.field === 'cycles')).toBe(true);
  });
});

describe('validatePlanTerms', () => {
  it('is the part of validatePlan that knows nothing about limits or features', () => {
    const full = plan({ features: [] });
    const terms = {
      name: full.name,
      description: full.description,
      code: full.code,
      monthlyPrice: full.monthlyPrice,
      annualPrice: full.annualPrice,
      currency: full.currency,
      cycles: full.cycles,
      trialEnabled: full.trialEnabled,
      trialDays: full.trialDays,
    };
    expect(validatePlanTerms(terms)).toEqual([]);
    expect(validatePlan(plan({ features: [] })).map((i) => i.field)).toEqual(['features']);
  });

  it('normalises a code the way it is stored', () => {
    expect(normalisePlanCode('  growth-2 ')).toBe('GROWTH-2');
  });
});

describe('recurring value', () => {
  it('counts only the states that are actually billed', () => {
    expect(isBilling('active')).toBe(true);
    expect(isBilling('past-due')).toBe(true);
    expect(isBilling('canceling')).toBe(true);
    for (const status of ['trial', 'canceled', 'paused', 'expired'] as const) expect(isBilling(status)).toBe(false);
  });

  it('spreads an annual subscription over twelve months', () => {
    expect(monthlyValue({ amount: 3999000, cycle: 'annual', status: 'active' })).toBe(333250);
    expect(monthlyValue({ amount: 399900, cycle: 'monthly', status: 'active' })).toBe(399900);
  });

  it('counts a trial as worth nothing, because nothing has been charged', () => {
    expect(monthlyValue({ amount: 399900, cycle: 'monthly', status: 'trial' })).toBe(0);
  });

  it('reports the saving from paying yearly', () => {
    expect(annualSavingPercent({ monthlyPrice: 100000, annualPrice: 1000000 })).toBe(17);
    expect(annualSavingPercent({ monthlyPrice: 100000, annualPrice: 1200000 })).toBe(0);
    expect(annualSavingPercent({ monthlyPrice: 0, annualPrice: 0 })).toBe(0);
  });
});

describe('planChangeEffect', () => {
  const growth = { id: 'growth', name: 'Growth', monthlyPrice: 399900, annualPrice: 3999000 } as Plan;

  it('quotes the new plan on the cycle being moved to', () => {
    expect(planChangeEffect(149900, growth, 'monthly')).toEqual({ currentAmount: 149900, newAmount: 399900, difference: 250000, direction: 'upgrade' });
    expect(planChangeEffect(899900, growth, 'monthly').direction).toBe('downgrade');
    expect(planChangeEffect(3999000, growth, 'annual').direction).toBe('same');
  });
});

describe('invoice arithmetic', () => {
  const invoice = {
    lines: [
      { description: 'Growth — monthly subscription', quantity: 1, unitAmount: 399900 },
      { description: 'Extra storage', quantity: 2, unitAmount: 50000 },
    ],
    taxPercent: 18,
  } as Invoice;

  it('adds the lines, then the tax', () => {
    expect(invoiceSubtotal(invoice)).toBe(499900);
    expect(invoiceTax(invoice)).toBe(89982);
    expect(invoiceTotal(invoice)).toBe(589882);
  });

  it('rounds the tax to a whole paisa, so every figure stays an integer', () => {
    const odd = { lines: [{ description: 'Starter', quantity: 1, unitAmount: 149950 }], taxPercent: 18 } as Invoice;
    // 18% of 149950 is 26991 exactly; of 149951 it is 26991.18, which is charged as 26991.
    expect(invoiceTax(odd)).toBe(26991);
    expect(invoiceTax({ ...odd, lines: [{ ...odd.lines[0], unitAmount: 149951 }] })).toBe(26991);
    for (const figure of [invoiceSubtotal(odd), invoiceTax(odd), invoiceTotal(odd)]) expect(Number.isInteger(figure)).toBe(true);
  });
});

describe('daysUntil', () => {
  const now = new Date('2026-09-15T18:52:00+05:30');

  it('rounds up so the last day still reads as a day', () => {
    expect(daysUntil('2026-09-18T18:52:00+05:30', now)).toBe(3);
    expect(daysUntil('2026-09-15T23:59:00+05:30', now)).toBe(1);
  });

  it('never goes below zero, and treats a missing date as none', () => {
    expect(daysUntil('2026-09-01T00:00:00+05:30', now)).toBe(0);
    expect(daysUntil(undefined, now)).toBe(0);
  });
});

describe('reachablePlanStatuses', () => {
  it('offers a new plan or a draft as a draft or on sale', () => {
    expect(reachablePlanStatuses(null)).toEqual(['draft', 'active']);
    expect(reachablePlanStatuses('draft')).toEqual(['draft', 'active']);
  });

  it('never takes a plan that has been offered back to draft', () => {
    expect(reachablePlanStatuses('active')).toEqual(['active', 'archived']);
    expect(reachablePlanStatuses('archived')).toEqual(['archived', 'active']);
  });
});
