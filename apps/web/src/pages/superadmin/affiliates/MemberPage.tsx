import { useState, type FormEvent } from 'react';
import { Link, useParams, useSearchParams } from 'react-router-dom';
import { ArrowsLeftRight, DownloadSimple, Prohibit, UserSwitch } from '@phosphor-icons/react';
import { MLM_KYC_STATUS_LABEL, type AffiliateMemberRow, type MlmKycStatus, type MlmLeg } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { PageHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { BinaryTree } from '@/components/mlm/BinaryTree';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, ServiceError } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { AFFILIATES_BASE, AffiliateStatusBadge } from './affiliateMeta';
import { MemberPicker, type PickedMember } from './MemberPicker';
import { MemberKyc, MemberMatching, MemberOrders, MemberRewards, MemberWallet } from './MemberTabs';
import styles from './Affiliates.module.css';

const SECTIONS = ['position', 'wallet', 'kyc', 'orders', 'matching', 'rewards'] as const;
type Section = (typeof SECTIONS)[number];

/** One affiliate (MLM-002): identity, sponsor, position, team, money and identity check; and the Super Admin's hands on them: move, re-sponsor, suspend, close. */
export default function MemberPage() {
  const { memberId = '' } = useParams();
  const toast = useToast();
  const [params, setParams] = useSearchParams();
  const section: Section = SECTIONS.find((s) => s === params.get('section')) ?? 'position';
  const member = useAsync(`affiliates:member:${memberId}`, () => services.affiliatesPlatform.getMember(memberId));
  const [treeRoot, setTreeRoot] = useState<string | undefined>(undefined);
  const tree = useAsync(`affiliates:member-tree:${treeRoot ?? memberId}`, () => services.affiliatesPlatform.memberTree(treeRoot ?? memberId, 3));
  const ancestors = useAsync(`affiliates:member-ancestors:${memberId}`, () => services.affiliatesPlatform.memberAncestors(memberId));
  const [dialog, setDialog] = useState<'place' | 'sponsor' | null>(null);
  const [statusChange, setStatusChange] = useState<'suspended' | 'active' | 'terminated' | null>(null);
  usePageCrumbs(
    member.data
      ? [{ label: 'Members', to: `${AFFILIATES_BASE}/members` }, { label: member.data.name }]
      : [{ label: 'Members', to: `${AFFILIATES_BASE}/members` }],
  );

  const reload = async () => {
    await member.run().catch(() => undefined);
    await tree.run().catch(() => undefined);
    await ancestors.run().catch(() => undefined);
  };

  if (member.status === 'error' && !member.data) {
    const missing = member.error instanceof ServiceError && member.error.code === 'not-found';
    return (
      <div className={styles.page}>
        {missing ? (
          <StateMessage kind="error" title="Affiliate not found" actions={<Link to={`${AFFILIATES_BASE}/members`}>Back to members</Link>} />
        ) : (
          <PlatformError title="The affiliate didn’t load" error={member.error} onRetry={() => void reload()} />
        )}
      </div>
    );
  }
  if (!member.data) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton width="40%" height={30} radius="var(--r-xs)" />
        <Skeleton height={420} radius="var(--r-lg)" />
      </div>
    );
  }
  const m = member.data;
  const changeStatus = async () => {
    if (!statusChange) return;
    await services.affiliatesPlatform.setMemberStatus(m.id, statusChange, '');
    setStatusChange(null);
    toast({
      kind: 'success',
      title:
        statusChange === 'terminated'
          ? `${m.name}’s affiliate account is closed`
          : statusChange === 'suspended'
            ? `${m.name} is suspended`
            : `${m.name} is active again`,
    });
    await reload();
  };
  const exportCsv = async () => {
    try {
      const csv = await services.affiliatesPlatform.networkCsv(m.id);
      const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
      const a = document.createElement('a');
      a.href = url;
      a.download = `network-${m.code}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      toast({ kind: 'error', title: 'Couldn’t export the network', text: (err as Error).message });
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        back={{ label: 'Members', to: `${AFFILIATES_BASE}/members` }}
        title={m.name}
        description={`${m.code} · ${m.email}`}
        meta={<AffiliateStatusBadge status={m.status} />}
        actions={
          <>
            <Button iconStart={<ArrowsLeftRight size={16} />} onClick={() => setDialog('place')} disabled={m.status === 'terminated'}>
              Move
            </Button>
            <Button iconStart={<UserSwitch size={16} />} onClick={() => setDialog('sponsor')} disabled={m.status === 'terminated'}>
              Change sponsor
            </Button>
            <Button iconStart={<DownloadSimple size={16} />} onClick={() => void exportCsv()}>
              Export team
            </Button>
          </>
        }
      />
      <div className={styles.facts}>
        <Fact label="Sponsor" value={m.sponsor ? `${m.sponsor.name} · ${m.sponsor.code}` : 'None'} />
        <Fact
          label="Placed under"
          value={m.placement ? `${m.placement.parentCode} · leg ${m.placement.leg} · level ${m.placement.depth}` : 'Root (no parent)'}
        />
        <Fact label="Direct referrals" value={String(m.directReferrals)} />
        <Fact label="Team size" value={String(m.teamSize)} />
        <Fact label="Own referrals go to leg" value={m.preferredLeg} />
        <Fact label="Joined on a link for leg" value={m.requestedLeg ?? 'No leg named'} />
        <Fact label="Rank" value={m.currentRankOrder ? `Rank ${m.currentRankOrder}` : 'None yet'} />
        <Fact label="KYC" value={MLM_KYC_STATUS_LABEL[m.kycStatus as MlmKycStatus] ?? m.kycStatus} />
        <Fact label="Activated" value={m.activatedAt ? new Date(m.activatedAt).toLocaleDateString('en-IN') : 'Not yet'} />
      </div>

      <SegmentedControl<Section>
        label="Section"
        value={section}
        onChange={(s) => setParams(s === 'position' ? {} : { section: s }, { replace: true })}
        segments={[
          { value: 'position', label: 'Position' },
          { value: 'wallet', label: 'Wallet' },
          { value: 'kyc', label: 'Identity check' },
          { value: 'orders', label: 'Orders' },
          { value: 'matching', label: 'Matching' },
          { value: 'rewards', label: 'Rewards' },
        ]}
      />
      {section === 'wallet' && <MemberWallet key={m.id} memberId={m.id} code={m.code} />}
      {section === 'kyc' && <MemberKyc key={m.id} memberId={m.id} />}
      {section === 'orders' && <MemberOrders key={m.id} code={m.code} />}
      {section === 'matching' && <MemberMatching key={m.id} memberId={m.id} />}
      {section === 'rewards' && <MemberRewards key={m.id} memberId={m.id} />}
      {section === 'position' && (
        <section className={styles.panel}>
          <div className={styles.panelHead}>
            <div>
              <h2 className={styles.panelTitle}>Position</h2>
              <p className={styles.panelHint}>
                {ancestors.data && ancestors.data.length > 0
                  ? `Under: ${ancestors.data.map((a) => `${a.name} (${a.code})`).join(' → ')}`
                  : 'At the root of a tree.'}
              </p>
            </div>
            <div className={styles.formActions}>
              {m.status === 'active' && (
                <Button iconStart={<Prohibit size={16} />} onClick={() => setStatusChange('suspended')}>
                  Suspend
                </Button>
              )}
              {m.status === 'suspended' && <Button onClick={() => setStatusChange('active')}>Reactivate</Button>}
              {m.status !== 'terminated' && (
                <Button variant="danger" onClick={() => setStatusChange('terminated')}>
                  Close account
                </Button>
              )}
            </div>
          </div>
          {tree.status === 'error' && !tree.data ? (
            <PlatformError title="The team didn’t load" error={tree.error} onRetry={() => void tree.run().catch(() => undefined)} />
          ) : !tree.data ? (
            <Skeleton height={280} radius="var(--r-md)" />
          ) : (
            <>
              {treeRoot && (
                <div>
                  <Button size="sm" onClick={() => setTreeRoot(undefined)}>
                    Back to {m.name}
                  </Button>
                </div>
              )}
              <BinaryTree root={tree.data} onOpen={(id) => setTreeRoot(id === m.id ? undefined : id)} highlightId={m.id} />
            </>
          )}
        </section>
      )}

      <PlacementDialog open={dialog === 'place'} member={m} onClose={() => setDialog(null)} onDone={reload} />
      <SponsorDialog open={dialog === 'sponsor'} member={m} onClose={() => setDialog(null)} onDone={reload} />
      <ConfirmDialog
        open={statusChange !== null}
        onClose={() => setStatusChange(null)}
        onConfirm={changeStatus}
        title={
          statusChange === 'terminated' ? `Close ${m.name}’s affiliate account?` : statusChange === 'suspended' ? `Suspend ${m.name}?` : `Reactivate ${m.name}?`
        }
        confirmLabel={statusChange === 'terminated' ? 'Close account' : statusChange === 'suspended' ? 'Suspend' : 'Reactivate'}
        tone={statusChange === 'active' ? 'default' : 'danger'}
      >
        {statusChange === 'terminated' && (
          <p>Final. The position stays in the tree so nobody else moves; the person earns nothing further and their code stops opening referrals.</p>
        )}
        {statusChange === 'suspended' && <p>Nothing is credited to this account while suspended. CV still passes through the position to the people above.</p>}
        {statusChange === 'active' && <p>Earning resumes from the next matching run.</p>}
      </ConfirmDialog>
    </div>
  );
}

function Fact({ label, value }: { label: string; value: string }) {
  return (
    <div className={styles.fact}>
      <span className={styles.factLabel}>{label}</span>
      <span className={styles.factValue}>{value}</span>
    </div>
  );
}

function PlacementDialog({ open, member, onClose, onDone }: { open: boolean; member: AffiliateMemberRow; onClose: () => void; onDone: () => Promise<void> }) {
  const toast = useToast();
  const [parent, setParent] = useState<PickedMember | null>(null);
  const [leg, setLeg] = useState<MlmLeg>('A');
  const [reason, setReason] = useState('');
  const [moveSubtree, setMoveSubtree] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!parent) return;
    setSaving(true);
    setError(undefined);
    try {
      await services.affiliatesPlatform.placeMember(member.id, { parentId: parent.id, leg, reason: reason.trim(), moveSubtree });
      toast({ kind: 'success', title: `${member.name} moved`, text: `Now under ${parent.name} (${parent.code}) on leg ${leg}.` });
      onClose();
      await onDone();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };
  return (
    <Modal open={open} onClose={onClose} title={`Move ${member.name}`}>
      <form className={styles.form} onSubmit={submit} noValidate>
        {error && (
          <InlineMessage kind="error" title="Couldn’t move.">
            {error}
          </InlineMessage>
        )}
        <MemberPicker
          label="New parent"
          hint="The member they are placed under. Refused for a cycle or a filled position."
          value={parent}
          onChange={setParent}
          excludeId={member.id}
        />
        <Field label="Leg">
          <Select value={leg} onChange={(e) => setLeg(e.target.value as MlmLeg)}>
            <option value="A">A / Left</option>
            <option value="B">B / Right</option>
          </Select>
        </Field>
        <Field label="Reason" hint="Written to the placement history and the audit trail.">
          <Textarea rows={2} value={reason} onChange={(e) => setReason(e.target.value)} required />
        </Field>
        {member.teamSize > 0 && (
          <Checkbox
            label={`Move the whole team under ${member.name} too (${member.teamSize}). Every ancestor’s leg history changes.`}
            checked={moveSubtree}
            onChange={(e) => setMoveSubtree(e.target.checked)}
          />
        )}
        <div className={styles.formActions}>
          <Button onClick={onClose} disabled={saving}>
            Cancel
          </Button>
          <Button type="submit" variant="primary" loading={saving} disabled={!parent || reason.trim().length < 3}>
            Move
          </Button>
        </div>
      </form>
    </Modal>
  );
}

function SponsorDialog({ open, member, onClose, onDone }: { open: boolean; member: AffiliateMemberRow; onClose: () => void; onDone: () => Promise<void> }) {
  const toast = useToast();
  const [sponsor, setSponsor] = useState<PickedMember | null>(null);
  const [reason, setReason] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await services.affiliatesPlatform.changeSponsor(member.id, sponsor?.id ?? null, reason.trim());
      toast({ kind: 'success', title: 'Sponsor changed', text: 'Past CV stays where it was attributed; placement is unchanged.' });
      onClose();
      await onDone();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };
  return (
    <Modal open={open} onClose={onClose} title={`Change ${member.name}’s sponsor`}>
      <form className={styles.form} onSubmit={submit} noValidate>
        {error && (
          <InlineMessage kind="error" title="Couldn’t change the sponsor.">
            {error}
          </InlineMessage>
        )}
        <MemberPicker label="New sponsor" hint="Leave empty for no sponsor." value={sponsor} onChange={setSponsor} excludeId={member.id} />
        <Field label="Reason">
          <Textarea rows={2} value={reason} onChange={(e) => setReason(e.target.value)} required />
        </Field>
        <div className={styles.formActions}>
          <Button onClick={onClose} disabled={saving}>
            Cancel
          </Button>
          <Button type="submit" variant="primary" loading={saving} disabled={reason.trim().length < 3}>
            Save
          </Button>
        </div>
      </form>
    </Modal>
  );
}
