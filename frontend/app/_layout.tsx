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
              const res = await api.exchangeSession(sessionId);
              await setUserFromAuth(res.user, res.session_token);
              // clean url
              window.history.replaceState(null, '', window.location.pathname);
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
  }, [setUserFromAuth]);

  useEffect(() => {
    if (loading || processingSession) return;
    const inTabs = segments[0] === '(tabs)';
    if (!user && inTabs) {
      router.replace('/');
    } else if (user && !inTabs) {
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
        </AuthGate>
      </StoreProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, backgroundColor: '#080910', alignItems: 'center', justifyContent: 'center' },
});
