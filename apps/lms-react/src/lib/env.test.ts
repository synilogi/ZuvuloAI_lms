import { describe, expect, it } from 'vitest';

import { resolveApiBaseUrl } from './env';

describe('resolveApiBaseUrl', () => {
  it('uses the configured URL without a trailing slash', () => {
    expect(resolveApiBaseUrl({ VITE_API_BASE_URL: 'https://lms.example.com/api/', PROD: true })).toBe('https://lms.example.com/api');
  });

  it('falls back to the development proxy', () => {
    expect(resolveApiBaseUrl({ PROD: false })).toBe('/api');
    expect(resolveApiBaseUrl({ VITE_API_BASE_URL: '  ', PROD: false })).toBe('/api');
  });

  it('refuses a production build with no API URL', () => {
    expect(() => resolveApiBaseUrl({ PROD: true })).toThrow(/VITE_API_BASE_URL/);
  });
});
