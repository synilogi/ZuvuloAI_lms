import type { ReactNode } from 'react';
import { CaretDown, UserCircle } from '@phosphor-icons/react';
import type { MlmLeg, TreeNodeView } from '@syniastrolms/domain';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import styles from './BinaryTree.module.css';

/*
 * A binary genealogy, a few levels at a time: each node shows the person, their status and rank, and its two
 * positions. An empty position is drawn so the shape of the tree is visible; a node whose children lie beyond the
 * levels loaded offers to open it as the new root. Plain HTML and CSS — no canvas — so it reads at any width and
 * scrolls horizontally when a level is wider than the page.
 */

const STATUS_TONE: Record<TreeNodeView['status'], 'neutral' | 'accent' | 'warn' | 'danger'> = {
  pending: 'neutral',
  active: 'accent',
  suspended: 'warn',
  terminated: 'danger',
};
const STATUS_LABEL: Record<TreeNodeView['status'], string> = { pending: 'Not active', active: 'Active', suspended: 'Suspended', terminated: 'Closed' };

export interface BinaryTreeProps {
  root: TreeNodeView;
  /** Called when a person asks to open a node as the root (a deeper level, or a node itself). */
  onOpen?: (id: string) => void;
  /** Extra line under a node: figures a later module adds (leg CV, rank). */
  extra?: (node: TreeNodeView) => ReactNode;
  /** The id that is "me", drawn apart. */
  highlightId?: string;
}

export function BinaryTree({ root, onOpen, extra, highlightId }: BinaryTreeProps) {
  return (
    <div className={styles.scroller} role="tree" aria-label={`Team of ${root.name}`}>
      <Node node={root} leg={null} onOpen={onOpen} extra={extra} highlightId={highlightId} />
    </div>
  );
}

function Node({ node, leg, onOpen, extra, highlightId }: { node: TreeNodeView; leg: MlmLeg | null } & Omit<BinaryTreeProps, 'root'>) {
  const unopened = node.children === null && (node.hasChildren.A || node.hasChildren.B);
  return (
    <div className={styles.node} role="treeitem" aria-expanded={node.children !== null}>
      <div className={`${styles.card} ${highlightId === node.id ? styles.me : ''}`}>
        {leg && <span className={styles.legTag}>{leg}</span>}
        <div className={styles.cardHead}>
          <UserCircle size={22} aria-hidden="true" className={styles.avatar} />
          <div className={styles.cardText}>
            <button type="button" className={styles.name} onClick={() => onOpen?.(node.id)} title="Open as the root of the view">
              {node.name}
            </button>
            <span className={styles.code}>{node.code}</span>
          </div>
        </div>
        <div className={styles.cardMeta}>
          <Badge size="sm" tone={STATUS_TONE[node.status]}>
            {STATUS_LABEL[node.status]}
          </Badge>
          {node.currentRankOrder > 0 && (
            <Badge size="sm" tone="info">
              Rank {node.currentRankOrder}
            </Badge>
          )}
          <span className={styles.faint}>{node.directReferrals} referred</span>
        </div>
        {extra && <div className={styles.cardExtra}>{extra(node)}</div>}
        {unopened && (
          <Button size="sm" variant="ghost" iconStart={<CaretDown size={14} />} onClick={() => onOpen?.(node.id)}>
            Show team
          </Button>
        )}
      </div>
      {node.children && (
        <div className={styles.legs}>
          <div className={styles.leg}>
            {node.children.A ? <Node node={node.children.A} leg="A" onOpen={onOpen} extra={extra} highlightId={highlightId} /> : <Empty leg="A" />}
          </div>
          <div className={styles.leg}>
            {node.children.B ? <Node node={node.children.B} leg="B" onOpen={onOpen} extra={extra} highlightId={highlightId} /> : <Empty leg="B" />}
          </div>
        </div>
      )}
    </div>
  );
}

function Empty({ leg }: { leg: MlmLeg }) {
  return (
    <div className={styles.node} role="treeitem" aria-label={`${leg} position open`}>
      <div className={styles.empty}>
        <span className={styles.legTag}>{leg}</span>
        <span>Open</span>
      </div>
    </div>
  );
}
