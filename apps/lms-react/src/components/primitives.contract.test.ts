import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'vitest';

// REACT-001 doneWhen: "No primitive fetches data". Shared components take data as props; only src/api talks to
// the network, and only feature hooks call it.
const root = join(__dirname);
const files = (dir: string): string[] =>
  readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? files(path) : /\.tsx?$/.test(name) && !/\.test\.tsx?$/.test(name) ? [path] : [];
  });

describe('shared components', () => {
  it('never fetch data or import the API layer', () => {
    const offenders = files(root).filter((file) =>
      /\bfetch\(|XMLHttpRequest|@tanstack\/react-query|from '@\/api|from '@\/features/.test(readFileSync(file, 'utf8')),
    );
    expect(offenders).toEqual([]);
  });
});
