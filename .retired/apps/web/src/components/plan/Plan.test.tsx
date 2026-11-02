import { describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { MemoryRouter } from 'react-router-dom';
import type { ReactNode } from 'react';
import type { Plan } from '@syniastrolms/domain';

// The session module reads the address bar when it loads; the server renderer has none.
vi.hoisted(() => {
  (globalThis as { window?: unknown }).window ??= { location: { search: '', origin: 'http://localhost' } };
});

const { PlanGateView } = await import('./PlanGate');
const { PlanActionView } = await import('./PlanAction');

/* A plan-gated area in each of its states, and a gated create action — drawn the way the browser gets them. */

const render = (node: ReactNode) => renderToStaticMarkup(<MemoryRouter>{node}</MemoryRouter>);

const plan = (over: Partial<Plan>): Plan =>
  ({
    id: 'growth',
    name: 'Growth',
    description: '',
    code: 'GROWTH',
    monthlyPrice: 399900,
    annualPrice: 3999000,
    currency: 'INR',
    cycles: ['monthly', 'annual'],
    trialEnabled: true,
    trialDays: 14,
    limits: {},
    features: ['courses.manage', 'assessments.manage'],
    status: 'active',
    order: 2,
    createdAt: '',
    updatedAt: '',
    ...over,
  }) as Plan;

const page = <p>The quizzes page</p>;
const base = { module: 'quizzes' as const, isAdmin: true, settingUp: false, plansState: 'ready' as const, children: page };

describe('a plan-gated area', () => {
  it('is the page itself when the plan includes it', () => {
    expect(render(<PlanGateView {...base} access="open" />)).toBe('<p>The quizzes page</p>');
  });

  it('keeps the page readable under a notice when the plan that had it has ended', () => {
    const html = render(<PlanGateView {...base} access="read-only" />);
    expect(html).toContain('The quizzes page');
    expect(html).toContain('data-plan-gate="read-only"');
    expect(html).toContain('Quizzes are read-only.');
    expect(html).toContain('nothing new can be added');
    expect(html).toContain('href="/admin/billing"');
    expect(html).toContain('Renew plan');
  });

  it('tells an instructor on a read-only plan to ask their admin, with no billing link', () => {
    const html = render(<PlanGateView {...base} isAdmin={false} access="read-only" />);
    expect(html).toContain('Ask your admin to renew.');
    expect(html).not.toContain('/admin/billing');
  });

  it('replaces the page with what unlocks it, and the plans that include it', () => {
    const plans = [
      plan({}),
      plan({ id: 'starter', name: 'Starter', features: ['courses.manage'], order: 1 }),
      plan({ id: 'old', name: 'Old', status: 'archived' }),
    ];
    const html = render(<PlanGateView {...base} access="locked" plans={plans} />);
    expect(html).not.toContain('The quizzes page');
    expect(html).toContain('data-plan-gate="locked"');
    expect(html).toMatch(/<h1[^>]*>Unlock Quizzes<\/h1>/);
    expect(html).toContain('Not in your current plan');
    expect(html).toContain('Quizzes and assignments with grading and review queues.');
    expect(html).toContain('Included in');
    expect(html).toContain('Growth');
    expect(html).not.toContain('Starter');
    expect(html).not.toContain('Old');
    expect(html).toContain('14-day free trial');
    expect(html).toMatch(/href="\/admin\/billing"[^>]*>.*See plans/);
  });

  it('sends an academy still choosing its first plan to the plans page', () => {
    const html = render(<PlanGateView {...base} access="locked" settingUp plans={[plan({})]} />);
    expect(html).toMatch(/href="\/admin\/welcome"[^>]*>.*See plans/);
  });

  it('says so when no plan on sale includes it', () => {
    const html = render(<PlanGateView {...base} module="branding" access="locked" plans={[plan({})]} />);
    expect(html).toContain('Unlock Custom branding');
    expect(html).toContain('No plan on sale includes it yet');
  });

  it('asks an instructor to talk to their admin, with no prices', () => {
    const html = render(<PlanGateView {...base} isAdmin={false} access="locked" plansState="none" />);
    expect(html).toContain('Ask your admin to upgrade.');
    expect(html).not.toContain('Included in');
    expect(html).not.toContain('See plans');
  });

  it('shows an instructor of an academy being set up a friendly state, not a sales page', () => {
    const html = render(<PlanGateView {...base} isAdmin={false} settingUp access="locked" plansState="none" />);
    expect(html).toContain('Your LMS is being set up');
    expect(html).not.toContain('Unlock');
  });

  it('locks a single feature inside a page, compactly', () => {
    const html = render(<PlanGateView {...base} module={undefined} feature="reports.advanced" compact access="locked" plans={[]} />);
    expect(html).toMatch(/<h2[^>]*>Unlock Advanced reports<\/h2>/);
    expect(html).not.toContain('Back to dashboard');
  });
});

describe('a gated create action', () => {
  const action = { module: 'courses' as const, to: '/admin/courses/new', canSeeBilling: true, children: 'Add course' };
  const capacity = (used: number, allowed: number) => ({
    limit: 'courses.max' as const,
    label: 'Courses',
    used,
    allowed,
    remaining: Math.max(0, allowed - used),
    reached: used >= allowed,
  });

  it('is a plain link while the plan allows it, with what is left of the limit', () => {
    const html = render(<PlanActionView {...action} access="open" capacity={capacity(7, 10)} />);
    expect(html).toContain('href="/admin/courses/new"');
    expect(html).toContain('3 of 10 courses left');
  });

  it('is disabled with the reason at the limit, pointing at the plans', () => {
    const html = render(<PlanActionView {...action} access="open" capacity={capacity(10, 10)} />);
    expect(html).not.toContain('href="/admin/courses/new"');
    expect(html).toMatch(/<button[^>]*disabled/);
    expect(html).toContain('Limit reached');
    expect(html).toContain('Your plan allows 10 courses, and all of them are in use.');
  });

  it('is disabled, saying why, when the plan has ended or does not include the module', () => {
    const ended = render(<PlanActionView {...action} access="read-only" capacity={null} />);
    expect(ended).toMatch(/<button[^>]*disabled/);
    expect(ended).toContain('Your plan has ended, so nothing new can be added to courses.');
    const locked = render(<PlanActionView {...action} access="locked" capacity={null} />);
    expect(locked).toContain('Courses are not included in your plan.');
  });
});
