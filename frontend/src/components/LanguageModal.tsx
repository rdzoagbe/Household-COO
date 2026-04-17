import React from 'react';
import { Modal, View, Text, StyleSheet } from 'react-native';
import { BlurView } from 'expo-blur';
import { X, Check } from 'lucide-react-native';
import { PressScale } from './PressScale';
import { Lang, useStore } from '../store';

interface Props {
  visible: boolean;
  onClose: () => void;
}

const OPTIONS: { code: Lang; label: string; native: string }[] = [
  { code: 'en', label: 'English', native: 'English' },
  { code: 'es', label: 'Spanish', native: 'Español' },
];

export function LanguageModal({ visible, onClose }: Props) {
  const { t, lang, setLang } = useStore();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <BlurView intensity={40} tint="dark" style={StyleSheet.absoluteFill} />
      <View style={styles.backdrop} />
      <View style={styles.center}>
        <View style={styles.sheet}>
          <View style={styles.header}>
            <Text style={styles.heading}>{t('language')}</Text>
            <PressScale testID="close-lang" onPress={onClose} style={styles.closeBtn}>
              <X color="#fff" size={18} />
            </PressScale>
          </View>
          {OPTIONS.map((o) => {
            const selected = lang === o.code;
            return (
              <PressScale
                key={o.code}
                testID={`lang-${o.code}`}
                onPress={async () => {
                  await setLang(o.code);
                  onClose();
                }}
                style={[styles.row, selected && styles.rowSelected]}
              >
                <View>
                  <Text style={styles.native}>{o.native}</Text>
                  <Text style={styles.label}>{o.label}</Text>
                </View>
                {selected ? <Check color="#10B981" size={18} /> : null}
              </PressScale>
            );
          })}
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8,9,16,0.5)' },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  sheet: {
    width: '100%',
    maxWidth: 380,
    backgroundColor: 'rgba(20,22,32,0.96)',
    borderRadius: 24,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    padding: 22,
  },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
  heading: { fontFamily: 'PlayfairDisplay_400Regular_Italic', fontSize: 26, color: '#fff' },
  closeBtn: { padding: 8, borderRadius: 9999, borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)' },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 14,
    paddingHorizontal: 14,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'transparent',
    marginTop: 8,
  },
  rowSelected: {
    borderColor: 'rgba(16,185,129,0.35)',
    backgroundColor: 'rgba(16,185,129,0.08)',
  },
  native: { fontFamily: 'Inter_600SemiBold', fontSize: 16, color: '#fff' },
  label: { fontFamily: 'Inter_400Regular', fontSize: 12, color: 'rgba(255,255,255,0.5)', marginTop: 2 },
});
