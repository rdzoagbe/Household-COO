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


  useEffect(() => {
    if (loading || processingSession) return;
    const inTabs = segments[0] === '(tabs)';
    const isPublic = PUBLIC_ROUTES.includes(segments[0] as string);
    const segmentCount = segments.length as number;
    if (!user && inTabs) {
      router.replace('/');
    } else if (user && !inTabs && !isPublic && segmentCount > 0) {
      // authenticated user on a non-tab screen that isn't public -- leave alone
    } else if (user && segmentCount === 0) {
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
