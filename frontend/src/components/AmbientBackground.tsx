import React from 'react';
import { View, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

export function AmbientBackground() {
  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      <View style={styles.base} />
      {/* top-left indigo glow */}
      <LinearGradient
        colors={['rgba(99,102,241,0.35)', 'rgba(99,102,241,0)']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={[styles.glow, { top: -180, left: -180, width: 520, height: 520 }]}
      />
      {/* bottom-right orange glow */}
      <LinearGradient
        colors={['rgba(249,115,22,0.22)', 'rgba(249,115,22,0)']}
        start={{ x: 1, y: 1 }}
        end={{ x: 0, y: 0 }}
        style={[styles.glow, { bottom: -200, right: -200, width: 560, height: 560 }]}
      />
      {/* center-left emerald glow */}
      <LinearGradient
        colors={['rgba(16,185,129,0.14)', 'rgba(16,185,129,0)']}
        start={{ x: 0, y: 0.5 }}
        end={{ x: 1, y: 0.5 }}
        style={[styles.glow, { top: 380, left: -160, width: 400, height: 400 }]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  base: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: '#080910',
  },
  glow: {
    position: 'absolute',
    borderRadius: 9999,
    opacity: 0.9,
  },
});
