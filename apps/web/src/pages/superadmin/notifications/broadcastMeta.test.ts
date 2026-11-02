import { describe, expect, it } from 'vitest';
import { broadcastDraftIssue, confirmTitle, outcomeText, reachText } from './broadcastMeta';

describe('reachText and confirmTitle', () => {
  it('name how many people, in words', () => {
    expect(reachText(0)).toBe('0 people');
    expect(reachText(1)).toBe('1 person');
    expect(reachText(120450)).toBe('1,20,450 people');
    expect(confirmTitle(1204)).toBe('Send this to 1,204 people?');
  });
});

describe('broadcastDraftIssue', () => {
  it('needs a one-line title and a message within the limits', () => {
    expect(broadcastDraftIssue('', 'Message')).toMatch(/title/);
    expect(broadcastDraftIssue('  a ', 'Message')).toMatch(/title/);
    expect(broadcastDraftIssue('x'.repeat(121), 'Message')).toMatch(/120/);
    expect(broadcastDraftIssue('Two\nlines', 'Message')).toMatch(/one line/);
    expect(broadcastDraftIssue('Title', ' ')).toMatch(/message/);
    expect(broadcastDraftIssue('Title', 'x'.repeat(501))).toMatch(/500/);
    expect(broadcastDraftIssue('x'.repeat(120), 'x'.repeat(500))).toBeUndefined();
  });
});

describe('outcomeText', () => {
  it('says what was delivered, and only mentions what went otherwise', () => {
    expect(outcomeText({ state: 'sent', recipients: 10, delivered: 10, failed: 0 })).toBe('Delivered to 10 of 10');
    expect(outcomeText({ state: 'sent', recipients: 10, delivered: 7, failed: 1 })).toBe('Delivered to 7 of 10 · 2 paused · 1 failed');
  });

  it('does not claim a broadcast with no closing record finished', () => {
    expect(outcomeText({ state: 'unfinished', recipients: 9 })).toBe('Started for 9 people; no record that it finished');
  });
});
