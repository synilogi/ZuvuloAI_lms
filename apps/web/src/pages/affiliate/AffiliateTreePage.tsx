import { useSearchParams } from 'react-router-dom';
import { ArrowUUpLeft } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { BinaryTree } from '@/components/mlm/BinaryTree';
import { services, ServiceError } from '@/services';
import { AffiliateNav } from './affiliateNav';
import styles from './Affiliate.module.css';

/** The learner's binary tree (MLM-002): their own node and a few levels under it; any node opens as the new root. */
export default function AffiliateTreePage() {
  const [params, setParams] = useSearchParams();
  const root = params.get('root') ?? undefined;
  const tree = useAsync(`affiliate:tree:${root ?? 'me'}`, () => services.affiliate.tree(root, 3));
  const open = (id?: string) => {
    const p = new URLSearchParams(params);
    if (id) p.set('root', id);
    else p.delete('root');
    setParams(p, { replace: true });
  };

  if (tree.status === 'error' && tree.error instanceof ServiceError && tree.error.reason === 'NOT_AN_AFFILIATE') {
    return (
      <div className={styles.page}>
        <PageHeader title="My team" />
        <StateMessage title="You’re not in the affiliate program yet" actions={<LinkButton to="/affiliate">Open the overview</LinkButton>}>
          You can read about it and join from the overview.
        </StateMessage>
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <PageHeader
        title="My team"
        description="Everyone placed under you, two legs at a time. A is your left leg and B your right; matching income is paid on the weaker leg’s verified sales."
        actions={
          root ? (
            <Button iconStart={<ArrowUUpLeft size={16} />} onClick={() => open()}>
              Back to me
            </Button>
          ) : undefined
        }
      />
      <AffiliateNav />
      {tree.status === 'error' && !tree.data ? (
        <StateMessage kind="error" title="Your team didn’t load" actions={<Button onClick={() => tree.run().catch(() => undefined)}>Try again</Button>}>
          {tree.error?.message}
        </StateMessage>
      ) : !tree.data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : (
        <section className={styles.panel}>
          <BinaryTree root={tree.data} onOpen={(id) => open(id)} highlightId={root ? undefined : tree.data.id} />
        </section>
      )}
    </div>
  );
}
