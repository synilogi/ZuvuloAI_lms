import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { ArrowUUpLeft, DownloadSimple, TreeStructure } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { BinaryTree } from '@/components/mlm/BinaryTree';
import { PageHeader } from '@/components/page/PageHeader';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Button } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AffiliateTabs } from './affiliateMeta';
import { saveCsv } from './earningsParts';
import { MemberPicker } from './MemberPicker';
import styles from './Affiliates.module.css';

/** The binary network from any member (docs/15 §7.1): find them, walk down their team, export what is on show. */
export default function NetworkPage() {
  const toast = useToast();
  const [params, setParams] = useSearchParams();
  const memberId = params.get('member') ?? '';
  const rootId = params.get('root') || memberId;
  const [exporting, setExporting] = useState(false);
  const member = useAsync(`affiliates:network-member:${memberId}`, () => (memberId ? services.affiliatesPlatform.getMember(memberId) : Promise.resolve(null)));
  const tree = useAsync(`affiliates:network-tree:${rootId}`, () => (rootId ? services.affiliatesPlatform.memberTree(rootId, 3) : Promise.resolve(null)));
  const go = (next: { member?: string; root?: string }) => {
    const p = new URLSearchParams();
    if (next.member) p.set('member', next.member);
    if (next.root && next.root !== next.member) p.set('root', next.root);
    setParams(p, { replace: true });
  };
  const exportCsv = async () => {
    if (!tree.data) return;
    setExporting(true);
    try {
      saveCsv(await services.affiliatesPlatform.networkCsv(tree.data.id), `network-${tree.data.code}.csv`);
    } catch (err) {
      toast({ kind: 'error', title: 'Couldn’t export the network', text: (err as Error).message });
    } finally {
      setExporting(false);
    }
  };
  const failed = member.status === 'error' ? member : tree.status === 'error' ? tree : null;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Network"
        description="The binary tree from any member. Open a person to walk further down their team."
        actions={
          <Button iconStart={<DownloadSimple size={16} />} loading={exporting} disabled={!tree.data} onClick={() => void exportCsv()}>
            Export this team
          </Button>
        }
      />
      <AffiliateTabs />
      <PrototypeNote>A demo network: changes last until the page is reloaded.</PrototypeNote>
      <section className={styles.panel}>
        <MemberPicker
          label="Member"
          hint="Search by affiliate code or name."
          value={member.data && member.data.id === memberId ? member.data : null}
          onChange={(m) => go({ member: m?.id })}
        />
      </section>
      {!memberId ? (
        <StateMessage icon={<TreeStructure size={26} />} title="Choose a member">
          Their team appears here, two legs at a time.
        </StateMessage>
      ) : failed ? (
        <PlatformError
          title="The network didn’t load"
          error={failed.error}
          onRetry={() => {
            void member.run().catch(() => undefined);
            void tree.run().catch(() => undefined);
          }}
        />
      ) : !tree.data || tree.data.id !== rootId ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : (
        <section className={styles.panel}>
          {rootId !== memberId && (
            <div>
              <Button size="sm" iconStart={<ArrowUUpLeft size={14} />} onClick={() => go({ member: memberId })}>
                Back to {member.data?.name ?? 'the member'}
              </Button>
            </div>
          )}
          <BinaryTree root={tree.data} onOpen={(id) => go({ member: memberId, root: id })} highlightId={memberId} />
        </section>
      )}
    </div>
  );
}
