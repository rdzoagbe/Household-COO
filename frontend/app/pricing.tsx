import React from 'react';
import { View, Text, StyleSheet, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { ArrowLeft } from 'lucide-react-native';
import { PricingView } from '../src/components/PricingView';
import { PressScale } from '../src/components/PressScale';
import { AmbientBackground } from '../src/components/AmbientBackground';
import { useStore } from '../src/store';

export default function PricingScreen() {
  const router = useRouter();
  const { t, user } = useStore();

  const goBack = () => {
    if (Platform.OS === 'web' && typeof window !== 'undefined' && window.history.length > 1) {
      router.back();
    } else {
      router.replace(user ? '/(tabs)/feed' : '/');
    }
  };

  const handleAuthRequired = () => {
    // Send user to landing to sign in; keep them on /pricing after
    if (Platform.OS === 'web' && typeof window !== 'undefined') {
      window.sessionStorage.setItem('post_auth_redirect', '/pricing');
    }
    router.replace('/');
  };

  return (
    <View style={styles.container}>
      <AmbientBackground />
      <SafeAreaView style={styles.safe} edges={['top', 'bottom']}>
        <View style={styles.topBar}>
          <PressScale testID="pricing-back" onPress={goBack} style={styles.backBtn}>
            <ArrowLeft color="rgba(255,255,255,0.8)" size={16} />
            <Text style={styles.backText}>{t('back')}</Text>
          </PressScale>
        </View>
        <PricingView onAuthRequired={handleAuthRequired} />
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#080910' },
  safe: { flex: 1 },
  topBar: {
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 4,
    flexDirection: 'row',
    alignItems: 'center',
  },
  backBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 9999,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    backgroundColor: 'rgba(255,255,255,0.04)',
  },
  backText: {
    color: 'rgba(255,255,255,0.85)',
    fontFamily: 'Inter_500Medium',
    fontSize: 12,
    letterSpacing: 0.4,
  },
});
