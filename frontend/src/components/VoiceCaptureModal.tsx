import React, { useEffect, useRef, useState } from 'react';
import {
  Modal,
  View,
  Text,
  StyleSheet,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { X, Mic, Square, Sparkles } from 'lucide-react-native';
import { PressScale } from './PressScale';
import { useStore } from '../store';
import { api, CardType } from '../api';

interface Draft {
  transcript: string;
  type: CardType;
  title: string;
  description: string;
  assignee: string;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onDraft: (d: Draft) => void;
}

type Phase = 'idle' | 'recording' | 'transcribing' | 'error';

export function VoiceCaptureModal({ visible, onClose, onDraft }: Props) {
  const { t } = useStore();
  const [phase, setPhase] = useState<Phase>('idle');
  const [elapsed, setElapsed] = useState(0);
  const [errMsg, setErrMsg] = useState<string | null>(null);
  const recorderRef = useRef<any>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<any>(null);
  const streamRef = useRef<MediaStream | null>(null);

  useEffect(() => {
    if (!visible) {
      cleanup();
      setPhase('idle');
      setElapsed(0);
      setErrMsg(null);
    }
    return cleanup;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [visible]);

  const cleanup = () => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (recorderRef.current && recorderRef.current.state === 'recording') {
      try {
        recorderRef.current.stop();
      } catch { /* ignore */ }
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    }
    recorderRef.current = null;
    chunksRef.current = [];
  };

  const start = async () => {
    setErrMsg(null);
    if (Platform.OS !== 'web' || typeof navigator === 'undefined' || !navigator.mediaDevices) {
      setErrMsg(t('not_supported_web'));
      setPhase('error');
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;
      const mimeType =
        typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported('audio/webm')
          ? 'audio/webm'
          : undefined;
      const rec = new MediaRecorder(stream, mimeType ? { mimeType } : undefined);
      chunksRef.current = [];
      rec.ondataavailable = (e) => {
        if (e.data && e.data.size > 0) chunksRef.current.push(e.data);
      };
      rec.onstop = async () => {
        const blob = new Blob(chunksRef.current, { type: rec.mimeType || 'audio/webm' });
        if (streamRef.current) {
          streamRef.current.getTracks().forEach((t) => t.stop());
          streamRef.current = null;
        }
        if (blob.size < 500) {
          setErrMsg('Recording too short.');
          setPhase('error');
          return;
        }
        setPhase('transcribing');
        try {
          const draft = await api.voiceTranscribe(blob);
          onDraft(draft);
        } catch (err: any) {
          console.log('transcribe error', err);
          setErrMsg(err?.message || 'Transcription failed');
          setPhase('error');
        }
      };
      rec.start();
      recorderRef.current = rec;
      setPhase('recording');
      setElapsed(0);
      timerRef.current = setInterval(() => setElapsed((e) => e + 1), 1000);
    } catch (e: any) {
      setErrMsg(e?.message || 'Microphone access denied');
      setPhase('error');
    }
  };

  const stop = () => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (recorderRef.current && recorderRef.current.state === 'recording') {
      recorderRef.current.stop();
    }
  };

  const fmt = (s: number) =>
    `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;

  return (
    <Modal visible={visible} animationType="fade" transparent onRequestClose={onClose}>
      <BlurView intensity={50} tint="dark" style={StyleSheet.absoluteFill} />
      <View style={styles.backdrop} />
      <View style={styles.center}>
        <View style={styles.sheet}>
          <View style={styles.header}>
            <View style={styles.badge}>
              <Sparkles color="#fff" size={12} />
              <Text style={styles.badgeText}>Whisper + Gemini</Text>
            </View>
            <PressScale testID="voice-close" onPress={onClose} style={styles.iconBtn}>
              <X color="#fff" size={18} />
            </PressScale>
          </View>

          <Text style={styles.heading}>{t('voice_capture')}</Text>
          <Text style={styles.sub}>{t('voice_hint')}</Text>

          <View style={styles.stage}>
            {phase === 'recording' && (
              <>
                <View style={styles.pulseOuter}>
                  <View style={styles.pulseInner} />
                </View>
                <Text style={styles.timer}>{fmt(elapsed)}</Text>
                <Text style={styles.stageLabel}>{t('listening')}</Text>
              </>
            )}
            {phase === 'transcribing' && (
              <>
                <ActivityIndicator color="#fff" size="large" />
                <Text style={[styles.stageLabel, { marginTop: 18 }]}>{t('transcribing')}</Text>
              </>
            )}
            {phase === 'idle' && (
              <View style={[styles.pulseOuter, { opacity: 0.35 }]}>
                <View style={styles.pulseInner} />
              </View>
            )}
            {phase === 'error' && (
              <Text style={styles.errText}>{errMsg}</Text>
            )}
          </View>

          <View style={styles.controls}>
            {phase === 'idle' && (
              <PressScale testID="voice-record" onPress={start} style={styles.recordBtn}>
                <Mic color="#080910" size={18} />
                <Text style={styles.recordText}>{t('record')}</Text>
              </PressScale>
            )}
            {phase === 'recording' && (
              <PressScale testID="voice-stop" onPress={stop} style={styles.stopBtn}>
                <Square color="#fff" size={16} />
                <Text style={styles.stopText}>{t('stop')}</Text>
              </PressScale>
            )}
            {phase === 'error' && (
              <PressScale testID="voice-retry" onPress={start} style={styles.recordBtn}>
                <Mic color="#080910" size={18} />
                <Text style={styles.recordText}>{t('retry')}</Text>
              </PressScale>
            )}
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8,9,16,0.6)' },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  sheet: {
    width: '100%',
    maxWidth: 400,
    backgroundColor: 'rgba(20,22,32,0.96)',
    borderRadius: 28,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    padding: 26,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 18,
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.12)',
    borderRadius: 9999,
  },
  badgeText: { color: '#fff', fontFamily: 'Inter_500Medium', fontSize: 11, letterSpacing: 0.4 },
  iconBtn: { padding: 8, borderRadius: 9999, borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)' },
  heading: {
    fontFamily: 'PlayfairDisplay_400Regular_Italic',
    color: '#fff',
    fontSize: 30,
    lineHeight: 36,
  },
  sub: {
    fontFamily: 'Inter_400Regular',
    color: 'rgba(255,255,255,0.6)',
    fontSize: 13,
    marginTop: 4,
    marginBottom: 22,
  },
  stage: {
    height: 180,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 10,
  },
  pulseOuter: {
    width: 120,
    height: 120,
    borderRadius: 9999,
    backgroundColor: 'rgba(99,102,241,0.14)',
    borderWidth: 1,
    borderColor: 'rgba(99,102,241,0.4)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  pulseInner: {
    width: 68,
    height: 68,
    borderRadius: 9999,
    backgroundColor: 'rgba(99,102,241,0.6)',
  },
  timer: {
    fontFamily: 'Inter_600SemiBold',
    color: '#fff',
    fontSize: 22,
    marginTop: 14,
    letterSpacing: 1,
  },
  stageLabel: {
    fontFamily: 'Inter_500Medium',
    color: 'rgba(255,255,255,0.7)',
    fontSize: 13,
    marginTop: 4,
  },
  errText: {
    fontFamily: 'Inter_400Regular',
    color: '#F97316',
    fontSize: 13,
    textAlign: 'center',
    paddingHorizontal: 20,
  },
  controls: { alignItems: 'center', marginTop: 10 },
  recordBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: '#fff',
    paddingHorizontal: 30,
    paddingVertical: 14,
    borderRadius: 9999,
  },
  recordText: { color: '#080910', fontFamily: 'Inter_600SemiBold', fontSize: 15 },
  stopBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: '#EF4444',
    paddingHorizontal: 30,
    paddingVertical: 14,
    borderRadius: 9999,
  },
  stopText: { color: '#fff', fontFamily: 'Inter_600SemiBold', fontSize: 15 },
});
