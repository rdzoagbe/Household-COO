import React, { useState } from 'react';
import {
  Modal,
  View,
  Text,
  TextInput,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  TouchableWithoutFeedback,
  Keyboard,
} from 'react-native';
import { X, FileSignature, Mail, ListTodo } from 'lucide-react-native';
import { BlurView } from 'expo-blur';
import { PressScale } from './PressScale';
import { useStore } from '../store';
import { api, CardType } from '../api';

interface Props {
  visible: boolean;
  onClose: () => void;
  onCreated: () => void;
  initialSource?: 'MANUAL' | 'VOICE' | 'CAMERA';
}

const TYPES: { key: CardType; color: string; icon: any }[] = [
  { key: 'SIGN_SLIP', color: '#F97316', icon: FileSignature },
  { key: 'RSVP', color: '#6366F1', icon: Mail },
  { key: 'TASK', color: '#10B981', icon: ListTodo },
];

export function AddCardModal({ visible, onClose, onCreated, initialSource = 'MANUAL' }: Props) {
  const { t } = useStore();
  const [type, setType] = useState<CardType>('TASK');
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [assignee, setAssignee] = useState('');
  const [saving, setSaving] = useState(false);

  const reset = () => {
    setTitle('');
    setDesc('');
    setAssignee('');
    setType('TASK');
  };

  const handleSave = async () => {
    if (!title.trim()) return;
    setSaving(true);
    try {
      await api.createCard({
        type,
        title: title.trim(),
        description: desc.trim(),
        assignee: assignee.trim(),
        source: initialSource,
      });
      reset();
      onCreated();
      onClose();
    } catch (e) {
      console.log('create card error', e);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal visible={visible} animationType="fade" transparent onRequestClose={onClose}>
      <BlurView intensity={50} tint="dark" style={StyleSheet.absoluteFill} />
      <View style={styles.backdrop} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.container}
      >
        <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
          <View style={styles.sheet}>
            <View style={styles.header}>
              <Text style={styles.heading}>{t('add_card')}</Text>
              <PressScale testID="close-add-card" onPress={onClose} style={styles.closeBtn}>
                <X color="#fff" size={18} />
              </PressScale>
            </View>

            <ScrollView style={{ maxHeight: 480 }} keyboardShouldPersistTaps="handled">
              <Text style={styles.label}>{t('choose_type')}</Text>
              <View style={styles.typeRow}>
                {TYPES.map((typ) => {
                  const Icon = typ.icon;
                  const active = type === typ.key;
                  return (
                    <PressScale
                      key={typ.key}
                      testID={`type-${typ.key}`}
                      onPress={() => setType(typ.key)}
                      style={[
                        styles.typeBtn,
                        {
                          borderColor: active ? typ.color : 'rgba(255,255,255,0.1)',
                          backgroundColor: active ? typ.color + '22' : 'rgba(255,255,255,0.03)',
                        },
                      ]}
                    >
                      <Icon color={active ? typ.color : 'rgba(255,255,255,0.6)'} size={18} />
                      <Text
                        style={[
                          styles.typeLabel,
                          { color: active ? typ.color : 'rgba(255,255,255,0.7)' },
                        ]}
                      >
                        {typ.key === 'SIGN_SLIP'
                          ? t('sign_slip')
                          : typ.key === 'RSVP'
                          ? t('rsvp')
                          : t('task')}
                      </Text>
                    </PressScale>
                  );
                })}
              </View>

              <Text style={styles.label}>{t('title')}</Text>
              <TextInput
                testID="input-title"
                value={title}
                onChangeText={setTitle}
                placeholder={t('title')}
                placeholderTextColor="rgba(255,255,255,0.3)"
                style={styles.input}
              />

              <Text style={styles.label}>{t('description')}</Text>
              <TextInput
                testID="input-description"
                value={desc}
                onChangeText={setDesc}
                placeholder={t('description')}
                placeholderTextColor="rgba(255,255,255,0.3)"
                multiline
                style={[styles.input, { minHeight: 72, textAlignVertical: 'top' }]}
              />

              <Text style={styles.label}>{t('assignee')}</Text>
              <TextInput
                testID="input-assignee"
                value={assignee}
                onChangeText={setAssignee}
                placeholder={t('assignee')}
                placeholderTextColor="rgba(255,255,255,0.3)"
                style={styles.input}
              />
            </ScrollView>

            <View style={styles.footer}>
              <PressScale testID="cancel-add-card" onPress={onClose} style={styles.cancelBtn}>
                <Text style={styles.cancelText}>{t('cancel')}</Text>
              </PressScale>
              <PressScale
                testID="save-add-card"
                onPress={handleSave}
                disabled={saving || !title.trim()}
                style={[styles.saveBtn, (!title.trim() || saving) && { opacity: 0.5 }]}
              >
                <Text style={styles.saveText}>{saving ? '...' : t('save')}</Text>
              </PressScale>
            </View>
          </View>
        </TouchableWithoutFeedback>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8,9,16,0.6)' },
  container: { flex: 1, justifyContent: 'flex-end' },
  sheet: {
    backgroundColor: 'rgba(20,22,32,0.95)',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    padding: 24,
    paddingBottom: 34,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 18,
  },
  heading: {
    fontFamily: 'PlayfairDisplay_400Regular_Italic',
    fontSize: 26,
    color: '#fff',
  },
  closeBtn: {
    padding: 8,
    borderRadius: 9999,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  label: {
    fontFamily: 'Inter_500Medium',
    fontSize: 11,
    color: 'rgba(255,255,255,0.5)',
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginTop: 12,
    marginBottom: 8,
  },
  typeRow: { flexDirection: 'row', gap: 10 },
  typeBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderRadius: 16,
    paddingVertical: 12,
    gap: 8,
  },
  typeLabel: { fontFamily: 'Inter_600SemiBold', fontSize: 12 },
  input: {
    backgroundColor: 'rgba(255,255,255,0.04)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: '#fff',
    fontFamily: 'Inter_400Regular',
    fontSize: 15,
  },
  footer: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 18,
  },
  cancelBtn: {
    flex: 1,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
  },
  cancelText: { color: 'rgba(255,255,255,0.7)', fontFamily: 'Inter_500Medium', fontSize: 15 },
  saveBtn: {
    flex: 1,
    backgroundColor: '#fff',
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
  },
  saveText: { color: '#080910', fontFamily: 'Inter_600SemiBold', fontSize: 15 },
});
