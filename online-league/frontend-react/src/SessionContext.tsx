import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import type { AppUser } from './models';
import { api, getToken, clearToken } from './api';

interface SessionState {
  user: AppUser | null;
  loading: boolean;
  isAdmin: boolean;
  adminViewActive: boolean;
  effectiveIsAdmin: boolean;
  login: () => void;
  logout: () => void;
  toggleAdminView: () => void;
  reload: () => Promise<void>;
}

const SessionContext = createContext<SessionState | null>(null);

export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [adminViewActive, setAdminViewActive] = useState(true);

  const load = useCallback(async () => {
    if (!getToken()) { setLoading(false); return; }
    try {
      const u = await api.me();
      setUser(u);
    } catch {
      clearToken();
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const login = () => { window.location.href = api.loginUrl; };

  const logout = () => {
    clearToken();
    setUser(null);
    setAdminViewActive(true);
  };

  const toggleAdminView = () => {
    if (user?.is_admin) setAdminViewActive(v => !v);
  };

  const isAdmin = user?.is_admin ?? false;
  const effectiveIsAdmin = isAdmin && adminViewActive;

  return (
    <SessionContext.Provider value={{
      user, loading, isAdmin, adminViewActive, effectiveIsAdmin,
      login, logout, toggleAdminView, reload: load,
    }}>
      {children}
    </SessionContext.Provider>
  );
}

export function useSession(): SessionState {
  const ctx = useContext(SessionContext);
  if (!ctx) throw new Error('useSession must be used within SessionProvider');
  return ctx;
}
