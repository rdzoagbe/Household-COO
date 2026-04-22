import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { api, User, tokenStore, Subscription } from './api';
import { Lang, SUPPORTED_LANGS, translate } from './i18n';

export type { Lang } from './i18n';

interface StoreState {
  user: User | null;
  loading: boolean;
  lang: Lang;
  subscription: Subscription | null;
  t: (key: string, params?: Record<string, string | number>) => string;
  setLang: (l: Lang) => Promise<void>;
  refreshUser: () => Promise<void>;
  refreshSubscription: () => Promise<void>;
  logout: () => Promise<void>;
  setUserFromAuth: (user: User, token: string) => Promise<void>;
  // Upgrade prompt
  upgradePrompt: { feature: string; message: string } | null;
  showUpgradePrompt: (feature: string, message: string) => void;
  dismissUpgradePrompt: () => void;
}

const StoreContext = createContext<StoreState | null>(null);

export function StoreProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [lang, setLangState] = useState<Lang>('en');
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [upgradePrompt, setUpgradePrompt] = useState<{ feature: string; message: string } | null>(null);

  const t = useCallback(
    (key: string, params?: Record<string, string | number>) => translate(lang, key, params),
    [lang]
  );

  const refreshSubscription = useCallback(async () => {
    try {
      const s = await api.getSubscription();
      setSubscription(s);
    } catch {
      setSubscription(null);
    }
  }, []);

  const refreshUser = useCallback(async () => {
    try {
      const u = await api.me();
      setUser(u);
      if (SUPPORTED_LANGS.includes(u.language as Lang)) setLangState(u.language as Lang);
      // fetch subscription in parallel (fire-and-forget)
      api.getSubscription().then(setSubscription).catch(() => {});
    } catch {
      setUser(null);
      setSubscription(null);
      await tokenStore.clear();
    } finally {
      setLoading(false);
    }
  }, []);

  const setLang = useCallback(
    async (l: Lang) => {
      setLangState(l);
      if (user) {
        try {
          await api.setLanguage(l);
        } catch {
          /* ignore */
        }
      }
    },
    [user]
  );

  const logout = useCallback(async () => {
    try {
      await api.logout();
    } catch {
      /* ignore */
    }
    await tokenStore.clear();
    setUser(null);
    setSubscription(null);
  }, []);

  const setUserFromAuth = useCallback(async (u: User, token: string) => {
    await tokenStore.set(token);
    setUser(u);
    if (SUPPORTED_LANGS.includes(u.language as Lang)) setLangState(u.language as Lang);
    setLoading(false);
    api.getSubscription().then(setSubscription).catch(() => {});
  }, []);

  const showUpgradePrompt = useCallback((feature: string, message: string) => {
    setUpgradePrompt({ feature, message });
  }, []);

  const dismissUpgradePrompt = useCallback(() => setUpgradePrompt(null), []);

  useEffect(() => {
    refreshUser();
  }, [refreshUser]);

  return (
    <StoreContext.Provider
      value={{
        user,
        loading,
        lang,
        subscription,
        t,
        setLang,
        refreshUser,
        refreshSubscription,
        logout,
        setUserFromAuth,
        upgradePrompt,
        showUpgradePrompt,
        dismissUpgradePrompt,
      }}
    >
      {children}
    </StoreContext.Provider>
  );
}

export function useStore() {
  const ctx = useContext(StoreContext);
  if (!ctx) throw new Error('useStore must be inside StoreProvider');
  return ctx;
}
