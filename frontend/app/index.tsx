import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Platform, ImageBackground, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Globe, Sparkles, ShieldCheck } from 'lucide-react-native';
import { AmbientBackground } from '../src/components/AmbientBackground';
import { PressScale } from '../src/components/PressScale';
import { LanguageModal } from '../src/components/LanguageModal';
import { useStore } from '../src/store';
import * as WebBrowser from 'expo-web-browser';
import * as Google from 'expo-auth-session/providers/google';

WebBrowser.maybeCompleteAuthSession();

const BG_URL = 'https://static.prod-images.emergentagent.com/jobs/096ff1e5-0337-4e7f-a0c1-6a43a75126d3/images/6b243a1cf4a6ac9e40857ce24db4ef57d5831d303169f63507bb73111fe11fac.png';

export default function Landing() {
  const { t, lang, setUserFromAuth } = useStore();
  const router = useRouter();
  const [showLang, setShowLang] = useState(false);

  const [request, response, promptAsync] = Google.useIdTokenAuthRequest(
    {
      clientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID || '',
      redirectUri: ''
    }
  );

  useEffect(() => {
    const handle = async () => {
      if (response?.type !== 'success') return;

      try {
        const idToken = response.params?.id_token;
        if (!idToken) {
          Alert.alert('Sign-in failed', 'Google did not return an ID token.');
          return;
        }

        const { api } = await import('../src/api');
        const res = await api.exchangeSession(idToken);
        await setUserFromAuth(res.user, res.session_token);
        router.replace('/(tabs)/feed');
      } catch (error: any) {
        console.error('google sign-in exchange failed', error);
        Alert.alert('Sign-in failed', error?.message || 'Please try again.');
      }
    };

    handle();
  }, [response, router, setUserFromAuth]);

  const signIn = async () => {
    try {
      await promptAsync();
    } catch (error: any) {
      console.error('google prompt failed', error);
      Alert.alert('Sign-in failed', error?.message || 'Please try again.');
    }
  };

  return (
    <View style={styles.container}>
      <ImageBackground source={{ uri: BG_URL }} style={StyleSheet.absoluteFill} resizeMode="cover" />
      <View style={styles.overlay} pointerEvents="none" />
      <AmbientBackground />

      <SafeAreaView style={styles.safe} edges={['top', 'bottom']}>
        <View style={styles.top}>
          <View style={styles.logoRow}>
            <View style={styles.logoDot} />
            <Text style={styles.logoText}>COO</Text>
          </View>
          <PressScale testID="landing-lang" onPress={() => setShowLang(true)} style={styles.langBtn}>
            <Globe color="rgba(255,255,255,0.7)" size={14} />
            <Text style={styles.langText}>{lang.toUpperCase()}</Text>
          </PressScale>
        </View>

        <View style={styles.center}>
          <View style={styles.badge}>
            <Sparkles color="#fff" size={12} />
            <Text style={styles.badgeText}>{t('app_name')}</Text>
          </View>

          <Text style={styles.heading}>{t('tagline')}</Text>
          <Text style={styles.sub}>{t('subtitle')}</Text>

          <PressScale
            testID="google-signin"
            onPress={signIn}
            style={[styles.cta, !request && { opacity: 0.6 }]}
          >
            <View style={styles.googleDot}>
              <Text style={{ fontWeight: '700', color: '#4285F4' }}>G</Text>
            </View>
            <Text style={styles.ctaText}>{t('sign_in')}</Text>
          </PressScale>

          <View style={styles.secureRow}>
            <ShieldCheck color="rgba(255,255,255,0.5)" size={12} />
            <Text style={styles.secureText}>{t('sign_in_secure')}</Text>
          </View>
        </View>

        <View style={styles.footer}>
          <PressScale
            testID="landing-pricing-link"
            onPress={() => router.push('/pricing')}
            style={styles.footerPricingBtn}
          >
            <Text style={styles.footerPricingText}>{t('pricing_link')}</Text>
          </PressScale>
          <Text style={styles.foot}>Household COO · v1</Text>
        </View>
      </SafeAreaView>

      <LanguageModal visible={showLang} onClose={() => setShowLang(false)} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0c0c0c' },
  overlay: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(0,0,0,0.35)' },
  safe: { flex: 1, paddingHorizontal: 22, justifyContent: 'space-between' },
  top: { paddingTop: 8, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  logoRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  logoDot: { width: 10, height: 10, borderRadius: 999, backgroundColor: '#f59e0b' },
  logoText: { color: '#fff', fontSize: 16, fontFamily: 'Inter_700Bold' },
  langBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 7,
    borderRadius: 999,
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
  },
  langText: { color: 'rgba(255,255,255,0.85)', fontFamily: 'Inter_500Medium', fontSize: 12 },
  center: { flex: 1, justifyContent: 'center' },
  badge: {
    alignSelf: 'flex-start',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
    backgroundColor: 'rgba(255,255,255,0.07)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 9999,
    marginBottom: 22,
  },
  badgeText: { color: '#fff', fontFamily: 'Inter_500Medium', fontSize: 11, letterSpacing: 0.5 },
  heading: {
    fontFamily: 'PlayfairDisplay_400Regular_Italic',
    color: '#fff',
    fontSize: 48,
    lineHeight: 54,
    marginBottom: 14,
    maxWidth: 380,
  },
  sub: {
    fontFamily: 'Inter_400Regular',
    color: 'rgba(255,255,255,0.65)',
    fontSize: 16,
    lineHeight: 24,
    marginBottom: 36,
    maxWidth: 360,
  },
  cta: {
    flexDirection: 'row',
    alignSelf: 'flex-start',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#fff',
    paddingHorizontal: 18,
    paddingVertical: 14,
    borderRadius: 9999,
    shadowColor: '#fff',
    shadowOpacity: 0.2,
    shadowRadius: 20,
  },
  googleDot: {
    width: 22,
    height: 22,
    borderRadius: 9999,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#e0e0e0',
    alignItems: 'center',
    justifyContent: 'center',
  },
  ctaText: { color: '#080910', fontFamily: 'Inter_600SemiBold', fontSize: 15 },
  secureRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 16 },
  secureText: { color: 'rgba(255,255,255,0.5)', fontFamily: 'Inter_400Regular', fontSize: 12 },
  footer: { paddingVertical: 10, flexDirection: 'row', alignItems: 'center', gap: 14 },
  footerPricingBtn: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 9999,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.15)',
    backgroundColor: 'rgba(255,255,255,0.04)',
  },
  footerPricingText: {
    color: 'rgba(255,255,255,0.85)',
    fontFamily: 'Inter_500Medium',
    fontSize: 12,
    letterSpacing: 0.3,
  },
  foot: { color: 'rgba(255,255,255,0.35)', fontFamily: 'Inter_400Regular', fontSize: 11 },
});