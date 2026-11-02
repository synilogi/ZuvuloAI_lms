import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import type { InvitationRow } from '@/services/contracts';

vi.hoisted(() => {
  (globalThis as { window?: unknown }).window ??= { location: { search: '', origin: 'https://lms.example.com' } };
});

const { CreatedInvitation, InvitationList } = await import('./InviteLearnersDialog');
const { invitationService } = await import('@/services/mock/invitations');
const { simulation } = await import('@/services/mock/simulation');

/* An Admin's Invite learners dialog: the link made (shown once), the list with each link's state, and withdrawing. */

const row = (over: Partial<InvitationRow>): InvitationRow => ({
  id: 'inv-1',
  email: null,
  status: 'pending',
  expiresAt: '2026-10-12T10:00:00.000Z',
  createdAt: '2026-10-05T10:00:00.000Z',
  usedAt: null,
  ...over,
});

describe('the invitation just created', () => {
  it('shows the link to copy, says it works once for 7 days, and who it was emailed to', () => {
    const url = `https://lms.example.com/invite/${'c'.repeat(64)}`;
    const html = renderToStaticMarkup(<CreatedInvitation url={url} email="meera@example.com" onCopy={() => undefined} />);
    expect(html).toContain(`value="${url}"`);
    expect(html).toContain('Copy');
    expect(html).toContain('It works once and expires in 7 days.');
    expect(html).toContain('We’ve also emailed it to meera@example.com.');
  });
});

describe('the list of invitations', () => {
  it('badges each state and offers Withdraw for pending ones only', () => {
    const html = renderToStaticMarkup(
      <InvitationList
        rows={[
          row({ id: 'a', email: 'meera@example.com' }),
          row({ id: 'b', status: 'accepted', usedAt: '2026-10-06T10:00:00.000Z' }),
          row({ id: 'c', status: 'revoked' }),
          row({ id: 'd', status: 'expired' }),
        ]}
        onWithdraw={() => undefined}
      />,
    );
    for (const label of ['Pending', 'Accepted', 'Withdrawn', 'Expired']) expect(html).toContain(label);
    expect(html.match(/>Withdraw</g)).toHaveLength(1);
    expect(html).toContain('meera@example.com');
    expect(html).toContain('Link for one learner');
  });

  it('says when there are none', () => {
    expect(renderToStaticMarkup(<InvitationList rows={[]} onWithdraw={() => undefined} />)).toContain('No invitations yet');
  });
});

describe('creating, listing and withdrawing in the demo build', () => {
  beforeAll(() => {
    vi.stubGlobal('window', Object.assign(globalThis, { location: { search: '', origin: 'https://lms.example.com' } }));
    simulation.latencyMs = 0;
  });
  afterAll(() => vi.unstubAllGlobals());

  it('lists a new link as pending, and as withdrawn once withdrawn', async () => {
    const { invitation, url } = await invitationService.create({ email: 'learner@example.com' });
    expect(url).toMatch(/\/invite\/[a-f0-9]{64}$/);
    expect((await invitationService.list())[0]).toMatchObject({ id: invitation.id, status: 'pending', email: 'learner@example.com' });
    await invitationService.revoke(invitation.id);
    const listed = (await invitationService.list()).find((r) => r.id === invitation.id)!;
    expect(listed.status).toBe('revoked');
    expect(renderToStaticMarkup(<InvitationList rows={[listed]} onWithdraw={() => undefined} />)).not.toContain('>Withdraw<');
  });
});
