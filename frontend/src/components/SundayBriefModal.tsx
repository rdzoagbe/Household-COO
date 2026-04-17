import React, { useEffect, useState } from 'react';
import { Modal, View, Text, StyleSheet, ScrollView, ActivityIndicator, ImageBackground } from 'react-native';
import { BlurView } from 'expo-blur';
import { X, Sparkles } from 'lucide-react-native';
import { PressScale } from './PressScale';
import { useStore } from '../store';
import { api } from '../api';

interface Props {
  visible: boolean;
  onClose: () => void;
}

const BG_URL = 'https://static.prod-images.emergentagent.com/jobs/096ff1e5-0337-4e7f-a0c1-6a43a75126d3/images/c54dfb594feff59886f35731ad1a1d593ce3d04827e4d753eab304e381593173.png';

export function SundayBriefModal({ visible, onClose }: Props) {
  const { t } = useStore();
  const [loading, setLoading] = useState(false);
  const [brief, setBrief] = useState<string | null>(null);
  const [generatedAt, setGeneratedAt] = useState<string | null>(null);

  useEffect(() => {
    if (visible) {
      setBrief(null);
      setGeneratedAt(null);
    }
  }, [visible]);

  const generate = async () => {
    setLoading(true);
    try {
      const res = await api.weeklyBrief();
      setBrief(res.brief);
      setGeneratedAt(res.generated_at);
    } catch (e) {
      console.log('brief error', e);
      setBrief('Unable to generate brief right now.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal visible={visible} animationType="fade" transparent onRequestClose={onClose}>
      <ImageBackground source={{ uri: BG_URL }} style={StyleSheet.absoluteFill} resizeMode="cover">
        <BlurView intensity={60} tint="dark" style={StyleSheet.absoluteFill} />
        <View style={styles.overlay} />
      </ImageBackground>
      <View style={styles.container}>
        <View style={styles.topBar}>
          <PressScale testID="close-brief" onPress={onClose} style={styles.closeBtn}>
            <X color="#fff" size={18} />
          </PressScale>
        </View>

        <View style={styles.content}>
          <View style={styles.badge}>
            <Sparkles color="#fff" size={14} />
            <Text style={styles.badgeText}>AI · Gemini 3 Flash</Text>
          </View>
          <Text style={styles.heading}>{t('sunday_brief')}</Text>
          <Text style={styles.sub}>{t('sunday_brief_subtitle')}</Text>

          {!brief && !loading && (
            <PressScale testID="generate-brief" onPress={generate} style={styles.ctaBtn}>
              <Sparkles color="#080910" size={16} />
              <Text style={styles.ctaText}>{t('generate_brief')}</Text>
            </PressScale>
          )}

          {loading && (
            <View style={styles.loadingWrap}>
              <ActivityIndicator color="#fff" />
              <Text style={styles.loadingText}>{t('generating')}</Text>
            </View>
          )}

          {brief && (
            <ScrollView
              style={styles.briefScroll}
              contentContainerStyle={styles.briefContent}
              testID="brief-scroll"
            >
              <Text style={styles.briefText}>{brief}</Text>
              {generatedAt ? (
                <Text style={styles.generatedAt}>
                  {new Date(generatedAt).toLocaleString()}
                </Text>
              ) : null}
            </ScrollView>
          )}
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8,9,16,0.7)' },
  container: { flex: 1, paddingHorizontal: 24, paddingTop: 60, paddingBottom: 40 },
  topBar: { flexDirection: 'row', justifyContent: 'flex-end' },
  closeBtn: {
    padding: 10,
    borderRadius: 9999,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.15)',
    backgroundColor: 'rgba(255,255,255,0.05)',
  },
  content: { flex: 1, justifyContent: 'center' },
  badge: {
    flexDirection: 'row',
    alignSelf: 'flex-start',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.12)',
    borderRadius: 9999,
    marginBottom: 20,
  },
  badgeText: {
    color: '#fff',
    fontFamily: 'Inter_500Medium',
    fontSize: 11,
    letterSpacing: 0.4,
  },
  heading: {
    fontFamily: 'PlayfairDisplay_400Regular_Italic',
    color: '#fff',
    fontSize: 48,
    lineHeight: 52,
    marginBottom: 8,
  },
  sub: {
    fontFamily: 'Inter_400Regular',
    color: 'rgba(255,255,255,0.6)',
    fontSize: 15,
    marginBottom: 28,
  },
  ctaBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    alignSelf: 'flex-start',
    backgroundColor: '#fff',
    paddingHorizontal: 22,
    paddingVertical: 14,
    borderRadius: 9999,
    gap: 8,
  },
  ctaText: { color: '#080910', fontFamily: 'Inter_600SemiBold', fontSize: 15 },
  loadingWrap: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  loadingText: { color: 'rgba(255,255,255,0.7)', fontFamily: 'Inter_400Regular', fontSize: 14 },
  briefScroll: { maxHeight: 420 },
  briefContent: { paddingRight: 8 },
  briefText: {
    fontFamily: 'Inter_400Regular',
    color: '#fff',
    fontSize: 17,
    lineHeight: 28,
    letterSpacing: 0.1,
  },
  generatedAt: {
    marginTop: 20,
    color: 'rgba(255,255,255,0.35)',
    fontFamily: 'Inter_400Regular',
    fontSize: 11,
  },
});
