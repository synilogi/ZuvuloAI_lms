import { describe, expect, it } from 'vitest';

import { applyPageMeta, metaDescription, setPageMeta } from './pageMeta';

interface FakeElement {
  tag: string;
  rel: string;
  href: string;
  attrs: Record<string, string>;
  setAttribute: (name: string, value: string) => void;
  remove: () => void;
}

/** Just enough of a document for the title, the canonical link and the meta tags (the suite runs without a DOM). */
function fakeDocument() {
  const elements: FakeElement[] = [];
  const doc = {
    title: '',
    head: {
      querySelector: (selector: string) => {
        if (selector === 'link[rel="canonical"]') return elements.find((el) => el.tag === 'link') ?? null;
        const [, attribute, key] = /^meta\[(\w+)="([^"]+)"\]$/.exec(selector)!;
        return elements.find((el) => el.tag === 'meta' && el.attrs[attribute] === key) ?? null;
      },
      appendChild: (el: FakeElement) => elements.push(el),
    },
    createElement: (tag: string) => {
      const el: FakeElement = {
        tag,
        rel: '',
        href: '',
        attrs: {},
        setAttribute: (name, value) => {
          el.attrs[name] = value;
        },
        remove: () => elements.splice(elements.indexOf(el), 1),
      };
      return el;
    },
  };
  const meta = (attribute: string, key: string) => elements.find((el) => el.tag === 'meta' && el.attrs[attribute] === key)?.attrs.content;
  return {
    doc: doc as unknown as Document,
    canonical: () => elements.find((el) => el.tag === 'link')?.href ?? null,
    description: () => meta('name', 'description'),
    og: (key: string) => meta('property', `og:${key}`),
    count: () => elements.length,
  };
}

describe('page meta', () => {
  it('names each public page and points it at its own canonical URL', () => {
    const { doc, canonical } = fakeDocument();
    applyPageMeta('/faq', doc);
    expect(doc.title).toBe('Frequently asked questions · ZuviloAI');
    expect(canonical()).toBe('https://zuviloai.com/faq');
    applyPageMeta('/welcome/', doc);
    expect(canonical()).toBe('https://zuviloai.com/');
  });

  it('gives pages behind sign-in the product name and no canonical', () => {
    const { doc, canonical } = fakeDocument();
    applyPageMeta('/features', doc);
    applyPageMeta('/admin/courses', doc);
    expect(doc.title).toBe('ZuviloAI');
    expect(canonical()).toBeNull();
  });

  it('writes a description and Open Graph tags for each page, reusing the tags on the next navigation', () => {
    const { doc, description, og, count } = fakeDocument();
    applyPageMeta('/refunds', doc);
    expect(description()).toMatch(/refund/i);
    expect(og('title')).toBe('Refund Policy · ZuviloAI');
    expect(og('description')).toBe(description());
    expect(og('url')).toBe('https://zuviloai.com/refunds');
    const tags = count();
    applyPageMeta('/about', doc);
    expect(og('title')).toBe('About · ZuviloAI');
    expect(count()).toBe(tags);
  });

  it('handles the public pages whose address carries an id', () => {
    const { doc, canonical, description, og } = fakeDocument();
    applyPageMeta('/support/article/reset-password', doc);
    expect(doc.title).toBe('Help article · ZuviloAI');
    expect(canonical()).toBe('https://zuviloai.com/support/article/reset-password');
    expect(description()).toMatch(/Help Centre/);
    applyPageMeta('/support/payments', doc);
    expect(doc.title).toBe('Help topic · ZuviloAI');
    expect(canonical()).toBe('https://zuviloai.com/support/payments');
    applyPageMeta('/verify/ABC-123', doc);
    expect(doc.title).toBe('Certificate verification · ZuviloAI');
    expect(og('url')).toBe('https://zuviloai.com/verify/ABC-123');
  });

  it('lets a page set its own words from what it loaded', () => {
    const { doc, canonical, description, og } = fakeDocument();
    applyPageMeta('/courses/foundations', doc);
    expect(canonical()).toBeNull();
    setPageMeta({ title: 'Foundations · ZuviloAI', description: 'Start here.', path: '/courses/foundations' }, doc);
    expect(doc.title).toBe('Foundations · ZuviloAI');
    expect(description()).toBe('Start here.');
    expect(og('title')).toBe('Foundations · ZuviloAI');
    expect(canonical()).toBe('https://zuviloai.com/courses/foundations');
  });

  it('keeps a description to one line of a sensible length, and never empty', () => {
    expect(metaDescription('  Two\n lines ')).toBe('Two lines');
    const long = metaDescription('word '.repeat(100));
    expect(long.length).toBeLessThanOrEqual(160);
    expect(long.endsWith('…')).toBe(true);
    expect(metaDescription('')).toMatch(/Online courses/);
  });

  it('promises no income on any public page', () => {
    const { doc, description } = fakeDocument();
    for (const path of ['/', '/affiliate-program', '/become-an-instructor']) {
      applyPageMeta(path, doc);
      expect(description()).not.toMatch(/income|earn up to|make money|guarantee/i);
    }
  });
});
