import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { CheckCircle, Info, Warning, X, XCircle } from '@phosphor-icons/react';
import { useViewport } from '@/hooks/useViewport';
import { cx } from '@/lib/cx';
import { IconButton } from '../../ui/Button/Button';
import styles from './Toast.module.css';

export type ToastKind = 'success' | 'info' | 'warn' | 'error';

export interface ToastInput {
  kind?: ToastKind;
  title: string;
  text?: string;
  action?: { label: string; onClick: () => void };
}

interface ToastRecord extends ToastInput {
  id: number;
}

const ICONS: Record<ToastKind, ReactNode> = {
  success: <CheckCircle size={20} />,
  info: <Info size={20} />,
  warn: <Warning size={20} />,
  error: <XCircle size={20} />,
};

const ToastContext = createContext<((t: ToastInput) => void) | null>(null);

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used inside <ToastProvider>');
  return ctx;
}

/** Shell toasts: 380px, r-md, border, sh-lg, tone ink icon; bottom-right on desktop, above the bottom bar on mobile. */
export function ToastProvider({ children, bottomOffset = 0 }: { children: ReactNode; bottomOffset?: number }) {
  const [toasts, setToasts] = useState<ToastRecord[]>([]);
  const timers = useRef(new Map<number, number>());
  const { isMobile } = useViewport();

  const dismiss = useCallback((id: number) => {
    setToasts((all) => all.filter((t) => t.id !== id));
    window.clearTimeout(timers.current.get(id));
    timers.current.delete(id);
  }, []);

  const push = useCallback(
    (input: ToastInput) => {
      const id = Date.now() + Math.random();
      setToasts((all) => [...all.slice(-2), { kind: 'info', ...input, id }]);
      timers.current.set(
        id,
        window.setTimeout(() => dismiss(id), input.action ? 6500 : 4200),
      );
    },
    [dismiss],
  );

  useEffect(() => {
    const map = timers.current;
    return () => map.forEach((t) => window.clearTimeout(t));
  }, []);

  const value = useMemo(() => push, [push]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      {createPortal(
        <div
          className={cx(styles.region, isMobile && styles.mobile)}
          style={isMobile ? { bottom: `calc(${bottomOffset + 12}px + env(safe-area-inset-bottom))` } : undefined}
          aria-live="polite"
          aria-relevant="additions"
        >
          {toasts.map((t) => (
            <div key={t.id} role="status" className={cx(styles.toast, styles[t.kind ?? 'info'])}>
              {ICONS[t.kind ?? 'info']}
              <span className={styles.text}>
                <span className={styles.title}>{t.title}</span>
                {t.text && <span className={styles.body}>{t.text}</span>}
              </span>
              {t.action && (
                <button
                  type="button"
                  className={styles.action}
                  onClick={() => {
                    t.action?.onClick();
                    dismiss(t.id);
                  }}
                >
                  {t.action.label}
                </button>
              )}
              <IconButton label="Dismiss" size="sm" icon={<X size={14} />} onClick={() => dismiss(t.id)} />
            </div>
          ))}
        </div>,
        document.body,
      )}
    </ToastContext.Provider>
  );
}
