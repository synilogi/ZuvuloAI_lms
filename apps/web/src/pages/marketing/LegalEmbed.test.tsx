import { describe, expect, it } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { MemoryRouter } from 'react-router-dom';
import PrivacyPage from './PrivacyPage';
import TermsPage from './TermsPage';
import RefundPolicyPage from './RefundPolicyPage';
import { COMPANY } from './siteContent';
import { MarketingChrome } from './MarketingChrome';

/* The mobile app shows the policies inside itself (`?embed=app`): only the policy text, no site header or footer. */
const at = (url: string, node: React.ReactNode) => renderToStaticMarkup(<MemoryRouter initialEntries={[url]}>{node}</MemoryRouter>);

describe('the policies, opened from the app', () => {
  it.each([
    ['privacy', <PrivacyPage key="p" />, 'Privacy policy'],
    ['terms', <TermsPage key="t" />, 'Terms'],
    ['refunds', <RefundPolicyPage key="r" />, 'Refund policy'],
  ])('/%s?embed=app shows only the policy', (path, page, heading) => {
    const html = at(`/${path}?embed=app`, page);
    expect(html).toContain(heading);
    // Each policy names who provides the service, and gives a contact that receives mail.
    expect(html).toContain(COMPANY.name);
    expect(html).toContain(COMPANY.email);
    expect(html).not.toMatch(/(privacy|legal)@zuviloai\.com/);
    expect(html).not.toContain('<footer');
    expect(html).not.toContain('All rights reserved');
  });

  it('keeps the site chrome on a normal visit', () => {
    const html = at('/privacy', <PrivacyPage />);
    expect(html).toContain('<footer');
  });

  it('never strips the chrome from a page that is not embeddable', () => {
    const html = at('/pricing?embed=app', <MarketingChrome>page</MarketingChrome>);
    expect(html).toContain('<footer');
  });
});
