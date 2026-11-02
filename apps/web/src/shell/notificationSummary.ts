import { useCallback, useEffect, useState } from 'react';
import type { AppNotification, Role } from '@syniastrolms/domain';
import { services } from '@/services';

const EVENT = 'astro:notifications-changed';

/** Tell the bell (and any open notification list) that read state or the list changed. */
export const announceNotificationsChanged = () => window.dispatchEvent(new Event(EVENT));

/** Where each role's notification centre lives. Exhaustive so a new role cannot inherit another's centre by default. */
const NOTIFICATIONS_HOME: Record<Role, string> = {
  student: '/notifications',
  instructor: '/teach/notifications',
  admin: '/admin/notifications',
  // Super Admin has no workspace of its own yet; `/notifications` is the role-neutral centre, not the learner's.
  superadmin: '/notifications',
};

export const notificationsHome = (role: Role) => NOTIFICATIONS_HOME[role];

/** Unread count and the newest few, kept fresh when anything marks or removes notifications. */
export function useNotificationSummary(recipientId: string, latest = 5) {
  const [state, setState] = useState<{ unread: number; rows: AppNotification[]; loaded: boolean; failed: boolean }>({
    unread: 0,
    rows: [],
    loaded: false,
    failed: false,
  });

  const refresh = useCallback(() => {
    services.notifications.list({ recipientId, limit: latest }).then(
      (page) => setState({ unread: page.unread, rows: page.rows, loaded: true, failed: false }),
      () => setState((s) => ({ ...s, loaded: true, failed: true })),
    );
  }, [recipientId, latest]);

  useEffect(() => {
    refresh();
    window.addEventListener(EVENT, refresh);
    return () => window.removeEventListener(EVENT, refresh);
  }, [refresh]);

  return { ...state, refresh };
}

export function useNotificationsChanged(callback: () => void) {
  useEffect(() => {
    window.addEventListener(EVENT, callback);
    return () => window.removeEventListener(EVENT, callback);
  }, [callback]);
}
