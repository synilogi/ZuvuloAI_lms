import { describe, expect, it } from 'vitest';
import type { MlmLeg } from './plan';
import { findFreePosition, legUnderRoot, otherLeg, pathUnder, rebasedPath, wouldCycle } from './genealogy';

/** A small binary tree as `childOf` reads it: X has Rahul on A and Rohit on B; Rahul has Rohan on A (the PDF's example). */
const tree = new Map<string, { A?: string; B?: string }>([
  ['X', { A: 'Rahul', B: 'Rohit' }],
  ['Rahul', { A: 'Rohan' }],
  ['Rohan', { A: 'Deep' }],
  ['Rohit', { B: 'Seema' }],
]);
const childOf = (id: string, leg: MlmLeg) => tree.get(id)?.[leg] ?? null;

describe('spillover', () => {
  it('extreme-outer follows the chosen leg outward to its first free position', () => {
    expect(findFreePosition('extreme-outer', 'X', 'A', childOf)).toEqual({ parentId: 'Deep', leg: 'A' });
    expect(findFreePosition('extreme-outer', 'X', 'B', childOf)).toEqual({ parentId: 'Seema', leg: 'B' });
    // A free position directly under the sponsor is taken first.
    expect(findFreePosition('extreme-outer', 'Rohan', 'B', childOf)).toEqual({ parentId: 'Rohan', leg: 'B' });
  });

  it('breadth-first takes the first free position in the leg, level by level, A before B', () => {
    expect(findFreePosition('breadth-first', 'X', 'A', childOf)).toEqual({ parentId: 'Rahul', leg: 'B' });
    expect(findFreePosition('breadth-first', 'X', 'B', childOf)).toEqual({ parentId: 'Rohit', leg: 'A' });
    expect(findFreePosition('breadth-first', 'Seema', 'A', childOf)).toEqual({ parentId: 'Seema', leg: 'A' });
  });
});

describe('paths', () => {
  it('build, detect cycles and rebase after a move', () => {
    expect(pathUnder(['X', 'Rahul'], 'Rohan')).toEqual(['X', 'Rahul', 'Rohan']);
    expect(wouldCycle('Rahul', 'Rahul', ['X'])).toBe(true); // under itself
    expect(wouldCycle('Rahul', 'Deep', ['X', 'Rahul', 'Rohan'])).toBe(true); // under its own descendant
    expect(wouldCycle('Rahul', 'Rohit', ['X'])).toBe(false);
    // Rohan (path X, Rahul) moves under Rohit (path X): Deep's path keeps everything from Rohan on.
    expect(rebasedPath(['X', 'Rahul', 'Rohan'], 'Rohan', ['X', 'Rohit'])).toEqual(['X', 'Rohit', 'Rohan']);
    expect(() => rebasedPath(['X'], 'Rohan', ['X', 'Rohit'])).toThrow();
  });

  it('names the root leg a node sits under', () => {
    const legOf = (id: string): MlmLeg | null => (id === 'Rahul' || id === 'Rohan' || id === 'Deep' ? 'A' : id === 'Rohit' || id === 'Seema' ? 'B' : null);
    expect(legUnderRoot('X', ['X'], 'A', legOf)).toBe('A'); // a direct child
    expect(legUnderRoot('X', ['X', 'Rahul', 'Rohan'], 'A', legOf)).toBe('A'); // Deep, under Rahul
    expect(legUnderRoot('X', ['X', 'Rohit'], 'B', legOf)).toBe('B');
    expect(legUnderRoot('Rohit', ['X', 'Rahul'], 'A', legOf)).toBeNull(); // not under Rohit at all
    expect(otherLeg('A')).toBe('B');
  });
});
