import React, { useState } from 'react';
import { View, Text, StyleSheet, Platform, ImageBackground } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Globe, Sparkles, ShieldCheck } from 'lucide-react-native';
import { AmbientBackground } from '../src/components/AmbientBackground';
import { PressScale } from '../src/components/PressScale';
import { LanguageModal } from '../src/components/LanguageModal';
import { useStore } from '../src/store';

const BG_URL = 'https://static.prod-images.emergentagent.com/jobs/096ff1e5-0337-4e7f-a0c1-6a43a75126d3/images/6b243a1cf4a6ac9e40857ce24db4ef57d5831d303169f63507bb73111fe11fac.png';

export default function Landing() {
  const { t, lang } = useStore();
  const [showLang, setShowLang] = useState(false);

  const signIn = () => {
    // REMINDER: DO NOT HARDCODE THE URL, OR ADD ANY FALLBACKS OR REDIRECT URLS, THIS BREAKS THE AUTH
    if (Platform.OS === 'web' && typeof window !== 'undefined') {
      const redirectUrl = window.location.origin + '/';
      window.location.href = `https://auth.emergentagent.com/?redirect=${encodeURIComponent(
        redirectUrl
      )}`;
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

          <PressScale testID="google-signin" onPress={signIn} style={styles.cta}>
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
          <Text style={styles.foot}>Household COO · v1</Text>
        </View>
      </SafeAreaView>

      <LanguageModal visible={showLang} onClose={() => setShowLang(false)} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#080910' },
  overlay: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8,9,16,0.55)' },
  safe: { flex: 1, paddingHorizontal: 28 },
  top: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 10,
  },
  logoRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  logoDot: {
    width: 10,
    height: 10,
    borderRadius: 9999,
    backgroundColor: '#10B981',
    shadowColor: '#10B981',
    shadowOpacity: 0.9,
    shadowRadius: 10,
  },
  logoText: {
    color: '#fff',
    fontFamily: 'Inter_600SemiBold',
    letterSpacing: 3,
    fontSize: 13,
  },
  langBtn: {
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
  langText: { color: 'rgba(255,255,255,0.8)', fontFamily: 'Inter_500Medium', fontSize: 11, letterSpacing: 1 },
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
  footer: { paddingVertical: 10 },
  foot: { color: 'rgba(255,255,255,0.35)', fontFamily: 'Inter_400Regular', fontSize: 11 },
});
