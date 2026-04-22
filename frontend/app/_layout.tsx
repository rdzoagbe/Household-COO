import React, { useEffect } from 'react';
import { View, StyleSheet, ActivityIndicator, Platform } from 'react-native';
import { Stack, useRouter, useSegments } from 'expo-router';
import {
  useFonts,
  PlayfairDisplay_400Regular_Italic,
} from '@expo-google-fonts/playfair-display';
import {
  Inter_400Regular,
  Inter_500Medium,
  Inter_600SemiBold,
  Inter_700Bold,
} from '@expo-google-fonts/inter';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StoreProvider, useStore } from '../src/store';
import { api, tokenStore } from '../src/api';
import { UpgradeModal } from '../src/components/UpgradeModal';

// Public routes that don't require auth
const PUBLIC_ROUTES = ['pricing'];

function AuthGate({ children }: { children: React.ReactNode }) {
  const { user, loading, setUserFromAuth } = useStore();
  const segments = useSegments();
  const router = useRouter();
  const [processingSession, setProcessingSession] = React.useState(true);

  // Process session_id from URL fragment (Emergent Auth callback) -- web only
  useEffect(() => {
    const handle = async () => {
      if (Platform.OS === 'web' && typeof window !== 'undefined') {
        const hash = window.location.hash || '';
        if (hash.includes('session_id=')) {
          const match = hash.match(/session_id=([^&]+)/);
          const sessionId = match ? match[1] : null;
          if (sessionId) {
            try {
              let inviteToken: string | undefined = undefined;
              try {
                const pending = window.sessionStorage.getItem('pending_invite');
                if (pending) inviteToken = pending;
              } catch { /* ignore */ }
              const res = await api.exchangeSession(sessionId, inviteToken);
              await setUserFromAuth(res.user, res.session_token);
              try { window.sessionStorage.removeItem('pending_invite'); } catch { /* ignore */ }
              // clean url
              window.history.replaceState(null, '', window.location.pathname);
              // honor post-auth redirect
              try {
                const dest = window.sessionStorage.getItem('post_auth_redirect');
                if (dest) {
                  window.sessionStorage.removeItem('post_auth_redirect');
                  router.replace(dest as any);
                  setProcessingSession(false);
                  return;
                }
              } catch { /* ignore */ }
            } catch (e) {
              console.log('session exchange failed', e);
              await tokenStore.clear();
            }
          }
        }
      }
      setProcessingSession(false);
    };
    handle();
  }, [setUserFromAuth, router]);

  useEffect(() => {
    if (loading || processingSession) return;
    const inTabs = segments[0] === '(tabs)';
    const isPublic = PUBLIC_ROUTES.includes(segments[0] as string);
    if (!user && inTabs) {
      router.replace('/');
    } else if (user && !inTabs && !isPublic && segments.length > 0 && segments[0] !== 'index') {
      // authenticated user on a non-tab screen that isn't public -- leave alone
    } else if (user && segments.length === 0) {
      router.replace('/(tabs)/feed');
    }
  }, [user, loading, processingSession, segments, router]);

  if (loading || processingSession) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color="#fff" />
      </View>
    );
  }

  return <>{children}</>;
}

export default function RootLayout() {
  const [fontsLoaded] = useFonts({
    PlayfairDisplay_400Regular_Italic,
    Inter_400Regular,
    Inter_500Medium,
    Inter_600SemiBold,
    Inter_700Bold,
  });

  if (!fontsLoaded) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color="#fff" />
      </View>
    );
  }

  return (
    <SafeAreaProvider>
      <StoreProvider>
        <AuthGate>
          <StatusBar style="light" />
          <Stack
            screenOptions={{
              headerShown: false,
              animation: 'fade',
              contentStyle: { backgroundColor: '#080910' },
            }}
          />
          <UpgradeModal />
        </AuthGate>
      </StoreProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, backgroundColor: '#080910', alignItems: 'center', justifyContent: 'center' },
});
