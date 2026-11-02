import { X } from '@phosphor-icons/react';
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';

import { IconButton } from '@/components/ui/Button';

import { InlineAlert, type AlertTone } from './InlineAlert';
import styles from './Feedback.module.css';

export interface ToastInput {
  tone?: AlertTone;
  title: ReactNode;
  description?: ReactNode;
  /** e.g. an Undo button. */
  action?: { label: string; onClick: () => void };
  /** Milliseconds; errors stay longer. 0 keeps it until dismissed. */
  duration?: number;
}

interface ToastEntry extends ToastInput {
  id: number;
}

interface ToastApi {
  show: (toast: ToastInput) => number;
  dismiss: (id: number) => void;
}

const ToastContext = createContext<ToastApi | null>(null);

/** Feedback after an action. Never the only place a validation error appears (forms show those inline). */
export function useToast(): ToastApi {
  const api = useContext(ToastContext);
  if (!api) throw new Error('useToast must be used inside <ToastProvider>.');
  return api;
}

function ToastItem({ toast, dismiss }: { toast: ToastEntry; dismiss: (id: number) => void }) {
  const [paused, setPaused] = useState(false);
  const duration = toast.duration ?? (toast.tone === 'danger' ? 10000 : 5000);
  const onDismiss = useCallback(() => dismiss(toast.id), [dismiss, toast.id]);

  useEffect(() => {
    if (!duration || paused) return;
    const timer = window.setTimeout(onDismiss, duration);
    return () => window.clearTimeout(timer);
  }, [duration, paused, onDismiss]);

  return (
    <li
      className={styles.toast}
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocus={() => setPaused(true)}
      onBlur={() => setPaused(false)}
    >
      <InlineAlert
        tone={toast.tone ?? 'success'}
        title={toast.title}
        action={
          <span className={styles.toastActions}>
            {toast.action && (
              <button
                type="button"
                onClick={() => {
                  toast.action!.onClick();
                  onDismiss();
                }}
                className={styles.toastAction}
              >
                {toast.action.label}
              </button>
            )}
            <IconButton label="Dismiss notification" icon={<X size={14} />} size="sm" onClick={onDismiss} />
          </span>
        }
      >
        {toast.description}
      </InlineAlert>
    </li>
  );
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastEntry[]>([]);
  const next = useRef(1);

  const dismiss = useCallback((id: number) => setToasts((list) => list.filter((toast) => toast.id !== id)), []);
  const show = useCallback((toast: ToastInput) => {
    const id = next.current++;
    setToasts((list) => [...list.slice(-3), { ...toast, id }]);
    return id;
  }, []);
  const api = useMemo(() => ({ show, dismiss }), [show, dismiss]);

  return (
    <ToastContext.Provider value={api}>
      {children}
      <ol className={styles.toaster} aria-label="Notifications">
        {toasts.map((toast) => (
          <ToastItem key={toast.id} toast={toast} dismiss={dismiss} />
        ))}
      </ol>
    </ToastContext.Provider>
  );
}
