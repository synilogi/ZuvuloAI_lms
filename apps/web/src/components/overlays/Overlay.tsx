import { useId, useRef, type KeyboardEvent, type PointerEvent, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { X } from '@phosphor-icons/react';
import { useBodyScrollLock } from '@/hooks/useBodyScrollLock';
import { useFocusTrap } from '@/hooks/useFocusTrap';
import { cx } from '@/lib/cx';
import { IconButton } from '../ui/Button/Button';
import styles from './Overlay.module.css';

interface OverlayFrameProps {
  open: boolean;
  onClose: () => void;
  kind: 'modal' | 'drawer' | 'sheet';
  labelledBy?: string;
  label?: string;
  className?: string;
  children: ReactNode;
}

/**
 * Shared dialog mechanics: portal, scrim, focus trap, scroll lock, Escape and backdrop dismissal.
 *
 * The frame carries `data-overlay` and its scrim `data-overlay-scrim` so a dialog whose contents are
 * worth printing (an invoice, a certificate) can be sent to paper on its own — see the print rules
 * in `styles/base.css`.
 */
function OverlayFrame({ open, onClose, kind, labelledBy, label, className, children }: OverlayFrameProps) {
  const panelRef = useRef<HTMLDivElement>(null);
  useFocusTrap(open, panelRef);
  useBodyScrollLock(open);

  if (!open) return null;

  const onKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      e.stopPropagation();
      onClose();
    }
  };

  return createPortal(
    <div className={cx(styles.root, styles[`${kind}Root`])} data-overlay={kind} onKeyDown={onKeyDown}>
      <div className={styles.scrim} data-overlay-scrim onClick={onClose} aria-hidden="true" />
      <div
        ref={panelRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={labelledBy}
        aria-label={labelledBy ? undefined : label}
        tabIndex={-1}
        className={cx(styles.panel, styles[kind], className)}
      >
        {children}
      </div>
    </div>,
    document.body,
  );
}

interface DialogChrome {
  open: boolean;
  onClose: () => void;
  title: ReactNode;
  eyebrow?: ReactNode;
  description?: ReactNode;
  icon?: ReactNode;
  footer?: ReactNode;
  children?: ReactNode;
  width?: number;
}

export function Modal({ open, onClose, title, description, icon, footer, children, width = 500 }: DialogChrome) {
  const titleId = useId();
  return (
    <OverlayFrame open={open} onClose={onClose} kind="modal" labelledBy={titleId}>
      <div className={styles.modalInner} style={{ width: `min(${width}px, 100%)` }}>
        <div className={styles.modalHead}>
          {icon && (
            <span className={styles.modalIcon} aria-hidden="true">
              {icon}
            </span>
          )}
          <span className={styles.headText}>
            <h3 id={titleId} className={styles.title}>
              {title}
            </h3>
            {description && <p className={styles.description}>{description}</p>}
          </span>
          <IconButton label="Close" size="sm" icon={<X size={16} />} onClick={onClose} data-print-hide />
        </div>
        {children && <div className={styles.body}>{children}</div>}
        {footer && <div className={styles.footer}>{footer}</div>}
      </div>
    </OverlayFrame>
  );
}

export function Drawer({ open, onClose, title, eyebrow, footer, children, width = 440 }: DialogChrome) {
  const titleId = useId();
  return (
    <OverlayFrame open={open} onClose={onClose} kind="drawer" labelledBy={titleId}>
      <div className={styles.drawerInner} style={{ width: `min(94vw, ${width}px)` }}>
        <div className={styles.drawerHead}>
          <span className={styles.headText}>
            {eyebrow && <span className="type-eyebrow">{eyebrow}</span>}
            <h3 id={titleId} className={styles.title}>
              {title}
            </h3>
          </span>
          <IconButton label="Close panel" size="sm" icon={<X size={16} />} onClick={onClose} data-print-hide />
        </div>
        <div className={styles.scrollBody}>{children}</div>
        {footer && <div className={styles.footer}>{footer}</div>}
      </div>
    </OverlayFrame>
  );
}

/** Mobile counterpart of the drawer — anchored to the bottom edge, thumb-reachable actions. */
export function BottomSheet({ open, onClose, title, eyebrow, footer, children }: DialogChrome) {
  const titleId = useId();
  const startY = useRef<number | null>(null);
  const sheetRef = useRef<HTMLDivElement>(null);

  const onPointerDown = (e: PointerEvent) => {
    startY.current = e.clientY;
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
  };
  const onPointerMove = (e: PointerEvent) => {
    if (startY.current === null || !sheetRef.current) return;
    const dy = Math.max(0, e.clientY - startY.current);
    sheetRef.current.style.transform = `translateY(${dy}px)`;
  };
  const onPointerUp = (e: PointerEvent) => {
    if (startY.current === null || !sheetRef.current) return;
    const dy = e.clientY - startY.current;
    startY.current = null;
    sheetRef.current.style.transform = '';
    if (dy > 90) onClose();
  };

  return (
    <OverlayFrame open={open} onClose={onClose} kind="sheet" labelledBy={titleId}>
      <div ref={sheetRef} className={styles.sheetInner}>
        <div className={styles.grabZone} onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerUp} aria-hidden="true">
          <span className={styles.grabber} />
        </div>
        <div className={styles.sheetHead}>
          <span className={styles.headText}>
            {eyebrow && <span className="type-eyebrow">{eyebrow}</span>}
            <h3 id={titleId} className={styles.title}>
              {title}
            </h3>
          </span>
          <IconButton label="Close" size="lg" icon={<X size={20} />} onClick={onClose} />
        </div>
        <div className={styles.scrollBody}>{children}</div>
        {footer && <div className={cx(styles.footer, styles.sheetFooter)}>{footer}</div>}
      </div>
    </OverlayFrame>
  );
}
