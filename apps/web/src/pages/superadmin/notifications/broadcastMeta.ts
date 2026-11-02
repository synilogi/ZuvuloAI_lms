import { BROADCAST_SUMMARY_MAX, BROADCAST_TITLE_MAX, type BroadcastAudience, type BroadcastHistoryRow } from '@syniastrolms/domain';

export const AUDIENCE_LABEL: Record<BroadcastAudience, string> = {
  all: 'Everyone',
  students: 'Students',
  instructors: 'Instructors',
  staff: 'Admins and owners',
};

export const AUDIENCE_HINT: Record<BroadcastAudience, string> = {
  all: 'Every account that can sign in.',
  students: 'Learners, except suspended ones.',
  instructors: 'Approved instructors, except inactive ones.',
  staff: 'Staff admin accounts and the platform’s owners.',
};

/** "1 person", "1,204 people". */
export const reachText = (count: number) => (count === 1 ? '1 person' : `${count.toLocaleString('en-IN')} people`);

/** The question the confirm dialog asks: how many people, in so many words. */
export const confirmTitle = (count: number) => `Send this to ${reachText(count)}?`;

/** Why the message can't go yet, or undefined when it can. The API checks the same limits. */
export function broadcastDraftIssue(title: string, summary: string): string | undefined {
  const t = title.trim();
  const s = summary.trim();
  if (t.length < 3) return 'Give it a title.';
  if (t.length > BROADCAST_TITLE_MAX) return `Keep the title to ${BROADCAST_TITLE_MAX} characters.`;
  if (/[\r\n]/.test(t)) return 'Keep the title to one line.';
  if (s.length < 3) return 'Write the message.';
  if (s.length > BROADCAST_SUMMARY_MAX) return `Keep the message to ${BROADCAST_SUMMARY_MAX} characters.`;
  return undefined;
}

/** How a broadcast went, for the history. */
export function outcomeText(row: Pick<BroadcastHistoryRow, 'state' | 'recipients' | 'delivered' | 'failed'>): string {
  if (row.state === 'unfinished') return `Started for ${reachText(row.recipients)}; no record that it finished`;
  const delivered = row.delivered ?? 0;
  const held = row.recipients - delivered - (row.failed ?? 0);
  return [
    `Delivered to ${delivered.toLocaleString('en-IN')} of ${row.recipients.toLocaleString('en-IN')}`,
    ...(held > 0 ? [`${held.toLocaleString('en-IN')} paused`] : []),
    ...(row.failed ? [`${row.failed.toLocaleString('en-IN')} failed`] : []),
  ].join(' · ');
}
