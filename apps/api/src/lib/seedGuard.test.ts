import { describe, expect, it } from 'vitest';

import { demoSeedRefusal } from '../../prisma/seedGuard.js';

/* The demo seed wipes every academy platform-wide. It must refuse anything that could be production — including an
 * operator's shell on the server, which reads apps/api/.env but usually has no NODE_ENV. */

const local = { DATABASE_URL: 'mysql://root@127.0.0.1:3306/zuviloai_dev', APP_URL: 'http://localhost:5173', CORS_ORIGIN: 'http://localhost:5173' };

describe('the demo seed guard', () => {
  it('runs against a development or test database file', () => {
    expect(demoSeedRefusal(local)).toBeNull();
    expect(demoSeedRefusal({ ...local, DATABASE_URL: 'mysql://root@localhost:3306/zuviloai_test' })).toBeNull();
    expect(demoSeedRefusal({ ...local, DATABASE_URL: 'mysql://root@127.0.0.1:3306/run1_e2e' })).toBeNull();
  });

  it('refuses the production database even when NODE_ENV is not set', () => {
    expect(demoSeedRefusal({ DATABASE_URL: 'mysql://zuviloai:x@127.0.0.1:3306/zuviloai' })).toMatch(/not named/);
    expect(demoSeedRefusal({ ...local, DATABASE_URL: 'mysql://root@127.0.0.1:3306/prod?connection_limit=1' })).toMatch(/not named/);
    expect(demoSeedRefusal({ ...local, DATABASE_URL: 'mysql://db.example.com/lms_test' })).toMatch(/not this machine/);
    expect(demoSeedRefusal({ ...local, DATABASE_URL: undefined })).toMatch(/not named/);
  });

  it('refuses anything that says production, whatever the file is called', () => {
    expect(demoSeedRefusal({ ...local, NODE_ENV: 'production' })).toMatch(/production/);
    expect(demoSeedRefusal({ ...local, APP_ENV: 'production' })).toMatch(/production/);
    for (const url of ['https://zuviloai.com', 'https://www.zuviloai.com/', 'https://zuviloai.com.', 'https://ZUVILOAI.COM:443']) {
      expect(demoSeedRefusal({ ...local, APP_URL: url }), url).toMatch(/zuviloai.com/);
      expect(demoSeedRefusal({ ...local, CORS_ORIGIN: url }), url).toMatch(/zuviloai.com/);
    }
    expect(demoSeedRefusal({ ...local, APP_URL: 'https://notzuviloai.com' })).toBeNull();
  });
});
