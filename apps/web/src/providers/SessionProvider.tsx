import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import type { Role, UserProfile } from '@syniastrolms/domain';
import { personas, type DemoRole } from '@/services/mock/fixtures/learner';
import * as httpAuth from '@/services/http/auth';
import { ACCOUNT_CLOSED_EVENT, getToken, UNAUTHORIZED_EVENT } from '@/services/http/client';
import { API_MODE } from '@/lib/apiMode';

export { API_MODE };

interface Session {
  user: UserProfile;
  role: Role;
  /** Demo only — switches the mock persona. In http mode this is a no-op; sign in with a real account instead. */
  switchRole: (role: Role) => void;
  /** http mode only: true once a real account is signed in. Always true in mock mode. */
  isAuthenticated: boolean;
  /** http mode only: true while the stored token is still being checked against the API. */
  authLoading: boolean;
  login: (email: string, password: string) => Promise<UserProfile>;
  register: (name: string, email: string, password: string) => Promise<UserProfile>;
  /** Takes over a session the API has already started — a verified self-serve registration (SAAS-026). */
  adopt: (session: { token: string; user: UserProfile }) => void;
  logout: () => void;
}

const SessionContext = createContext<Session | null>(null);
const KEY = 'syniastrolms:demo-role';
/** Design-system device frames pass role in the URL and must not overwrite the parent's stored role. */
const isFramed = typeof window !== 'undefined' && new URLSearchParams(window.location.search).has('frame');

const GUEST: UserProfile = { id: 'guest', name: 'Guest', email: '', role: 'student', descriptor: 'Not signed in' };

function initialRole(): DemoRole {
  const fromUrl = new URLSearchParams(window.location.search).get('role');
  if (fromUrl === 'student' || fromUrl === 'instructor' || fromUrl === 'admin') return fromUrl;
  try {
    const stored = localStorage.getItem(KEY);
    if (stored === 'student' || stored === 'instructor' || stored === 'admin') return stored;
  } catch {
    /* ignore */
  }
  return 'student';
}

function MockSessionProvider({ children }: { children: ReactNode }) {
  const [role, setRole] = useState<DemoRole>(initialRole);

  useEffect(() => {
    if (isFramed) return;
    try {
      localStorage.setItem(KEY, role);
    } catch {
      /* ignore */
    }
  }, [role]);

  const value = useMemo<Session>(
    () => ({
      user: personas[role],
      role,
      // The demo build has no Super Admin persona, so asking for that role leaves the session as it is.
      switchRole: (next: Role) => {
        if (next !== 'superadmin') setRole(next);
      },
      isAuthenticated: true,
      authLoading: false,
      login: async () => personas[role],
      register: async () => personas[role],
      adopt: ({ user }) => {
        if (user.role !== 'superadmin') setRole(user.role);
      },
      logout: () => setRole('student'),
    }),
    [role],
  );
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

/** Real, token-backed session — used when VITE_API_MODE=http. */
function HttpSessionProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [authLoading, setAuthLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    if (!getToken()) {
      setAuthLoading(false);
      return;
    }
    httpAuth
      .me()
      .then((u) => !cancelled && setUser(u))
      .catch((error: unknown) => !cancelled && httpAuth.sessionRefused(error) && httpAuth.logout())
      .finally(() => !cancelled && setAuthLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  // The account's workspace has closed (docs/16, D-PLAT-02): sign out and say why on the sign-in page.
  useEffect(() => {
    const onClosed = () => {
      setUser(null);
      window.location.assign('/login?closed=workspace');
    };
    window.addEventListener(ACCOUNT_CLOSED_EVENT, onClosed);
    return () => window.removeEventListener(ACCOUNT_CLOSED_EVENT, onClosed);
  }, []);

  // A 401 anywhere in the app means the token is no longer good: drop to signed-out.
  useEffect(() => {
    const onUnauthorized = () => setUser(null);
    window.addEventListener(UNAUTHORIZED_EVENT, onUnauthorized);
    return () => window.removeEventListener(UNAUTHORIZED_EVENT, onUnauthorized);
  }, []);

  const value = useMemo<Session>(
    () => ({
      user: user ?? GUEST,
      role: user?.role ?? 'student',
      switchRole: () => {
        /* Real accounts have a fixed role — sign in with a different account instead. */
      },
      isAuthenticated: !!user,
      authLoading,
      login: async (email, password) => {
        const u = await httpAuth.login(email, password);
        setUser(u);
        return u;
      },
      register: async (name, email, password) => {
        const u = await httpAuth.register(name, email, password);
        setUser(u);
        return u;
      },
      adopt: ({ token, user: next }) => {
        httpAuth.adoptSession(token);
        setUser(next);
      },
      logout: () => {
        httpAuth.logout();
        setUser(null);
      },
    }),
    [user, authLoading],
  );
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function SessionProvider({ children }: { children: ReactNode }) {
  return API_MODE === 'http' ? <HttpSessionProvider>{children}</HttpSessionProvider> : <MockSessionProvider>{children}</MockSessionProvider>;
}

export function useSession() {
  const ctx = useContext(SessionContext);
  if (!ctx) throw new Error('useSession must be used inside <SessionProvider>');
  return ctx;
}
