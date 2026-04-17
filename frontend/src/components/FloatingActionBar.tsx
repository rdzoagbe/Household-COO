import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { BlurView } from 'expo-blur';
import { Mic, Camera, Plus } from 'lucide-react-native';
import { PressScale } from './PressScale';
import { useStore } from '../store';

interface Props {
  onManual: () => void;
  onCamera: () => void;
  onVoice: () => void;
}

export function FloatingActionBar({ onManual, onCamera, onVoice }: Props) {
  const { t } = useStore();
  return (
    <View style={styles.wrap} pointerEvents="box-none">
      <View style={styles.shell}>
        <BlurView intensity={40} tint="dark" style={StyleSheet.absoluteFill} />
        <View style={styles.tint} pointerEvents="none" />
        <View style={styles.row}>
          <PressScale testID="fab-voice" onPress={onVoice} style={styles.sideBtn}>
            <Mic color="#fff" size={20} />
            <Text style={styles.sideLabel}>{t('voice')}</Text>
          </PressScale>
          <PressScale testID="fab-camera" onPress={onCamera} style={styles.centerBtn}>
            <View style={styles.centerInner}>
              <Camera color="#080910" size={22} />
            </View>
          </PressScale>
          <PressScale testID="fab-manual" onPress={onManual} style={styles.sideBtn}>
            <Plus color="#fff" size={20} />
            <Text style={styles.sideLabel}>{t('manual')}</Text>
          </PressScale>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 24,
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  shell: {
    width: '100%',
    maxWidth: 420,
    borderRadius: 9999,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.12)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.55,
    shadowRadius: 24,
  },
  tint: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(14,15,22,0.7)',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  sideBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 9999,
  },
  sideLabel: {
    fontFamily: 'Inter_500Medium',
    color: 'rgba(255,255,255,0.85)',
    fontSize: 13,
  },
  centerBtn: {
    padding: 4,
  },
  centerInner: {
    width: 56,
    height: 56,
    borderRadius: 9999,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#fff',
    shadowOpacity: 0.25,
    shadowRadius: 16,
  },
});
