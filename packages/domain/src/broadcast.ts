/* The Super Admin's notification broadcast: one message to one audience. */

export const BROADCAST_AUDIENCES = ['all', 'students', 'instructors', 'staff'] as const;
export type BroadcastAudience = (typeof BROADCAST_AUDIENCES)[number];

export const BROADCAST_TITLE_MAX = 120;
export const BROADCAST_SUMMARY_MAX = 500;

export interface BroadcastInput {
  audience: BroadcastAudience;
  title: string;
  summary: string;
}

/** What one broadcast did: `recipients` were attempted, `delivered` got it on some channel, `failed` raised an error. */
export interface BroadcastResult {
  id: string;
  audience: BroadcastAudience;
  recipients: number;
  delivered: number;
  failed: number;
}

/** A line of the history, read from the audit log. `unfinished` began and has no closing record: a crash, or still running. */
export interface BroadcastHistoryRow {
  id: string;
  audience: BroadcastAudience;
  title: string;
  summary: string;
  recipients: number;
  delivered?: number;
  failed?: number;
  state: 'sent' | 'unfinished';
  sentBy: string;
  createdAt: string;
}
