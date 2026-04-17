import React, { useCallback, useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  Modal,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  TouchableWithoutFeedback,
  Keyboard,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { BlurView } from 'expo-blur';
import { Globe, LogOut, Users, Mail, UserPlus, X, Send } from 'lucide-react-native';
import { AmbientBackground } from '../../src/components/AmbientBackground';
import { GlassCard } from '../../src/components/GlassCard';
import { PressScale } from '../../src/components/PressScale';
import { LanguageModal } from '../../src/components/LanguageModal';
import { useStore } from '../../src/store';
import { api, FamilyMember } from '../../src/api';

export default function SettingsScreen() {
  const { user, t, lang, logout } = useStore();
  const router = useRouter();
  const [members, setMembers] = useState<FamilyMember[]>([]);
  const [showLang, setShowLang] = useState(false);
  const [showInvite, setShowInvite] = useState(false);
  const [inviteEmail, setInviteEmail] = useState('');
  const [sending, setSending] = useState(false);
  const [inviteResult, setInviteResult] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      const res = await api.familyMembers();
      setMembers(res);
    } catch (e) {
      console.log(e);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const doLogout = async () => {
    await logout();
    router.replace('/');
  };

  return (
    <View style={styles.container}>
      <AmbientBackground />
      <SafeAreaView style={{ flex: 1 }} edges={['top']}>
        <ScrollView contentContainerStyle={styles.scroll}>
          <Text style={styles.title}>{t('settings')}</Text>

          {/* Profile */}
          <GlassCard style={{ marginTop: 12, marginBottom: 18 }}>
            <View style={styles.profileRow}>
              {user?.picture ? (
                <Image source={{ uri: user.picture }} style={styles.avatar} />
              ) : (
                <View style={[styles.avatar, styles.avatarFallback]}>
                  <Text style={styles.avatarText}>{(user?.name?.[0] || 'C').toUpperCase()}</Text>
                </View>
              )}
              <View style={{ flex: 1 }}>
                <Text style={styles.name}>{user?.name}</Text>
                <View style={styles.emailRow}>
                  <Mail color="rgba(255,255,255,0.45)" size={11} />
                  <Text style={styles.email}>{user?.email}</Text>
                </View>
              </View>
            </View>
          </GlassCard>

          {/* Family */}
          <View style={styles.sectionRow}>
            <Users color="rgba(255,255,255,0.6)" size={14} />
            <Text style={styles.sectionLabel}>{t('family')}</Text>
          </View>
          <GlassCard>
            {members.map((m, i) => (
              <View key={m.member_id} style={[styles.memberRow, i > 0 && styles.memberBorder]}>
                <View style={styles.memberAvatar}>
                  <Text style={styles.memberInitial}>{m.name[0]?.toUpperCase()}</Text>
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={styles.memberName}>{m.name}</Text>
                  <Text style={styles.memberRole}>{m.role}</Text>
                </View>
              </View>
            ))}
            {members.length === 0 && (
              <Text style={styles.emptyRow}>No family members yet.</Text>
            )}
          </GlassCard>

          <PressScale
            testID="open-invite"
            onPress={() => {
              setInviteEmail('');
              setInviteResult(null);
              setShowInvite(true);
            }}
            style={styles.inviteBtn}
          >
            <UserPlus color="#fff" size={16} />
            <Text style={styles.inviteBtnText}>Invite co-parent</Text>
          </PressScale>

          {/* Language */}
          <View style={styles.sectionRow}>
            <Globe color="rgba(255,255,255,0.6)" size={14} />
            <Text style={styles.sectionLabel}>{t('language')}</Text>
          </View>
          <GlassCard>
            <PressScale
              testID="settings-lang"
              onPress={() => setShowLang(true)}
              style={styles.actionRow}
            >
              <Text style={styles.actionLabel}>{t('language')}</Text>
              <Text style={styles.actionValue}>
                {lang === 'en' ? 'English' : 'Español'}
              </Text>
            </PressScale>
          </GlassCard>

          {/* Logout */}
          <PressScale testID="logout" onPress={doLogout} style={styles.logoutBtn}>
            <LogOut color="#EF4444" size={16} />
            <Text style={styles.logoutText}>{t('log_out')}</Text>
          </PressScale>

          <View style={{ height: 220 }} />
        </ScrollView>
      </SafeAreaView>
      <LanguageModal visible={showLang} onClose={() => setShowLang(false)} />

      {/* Invite modal */}
      <Modal visible={showInvite} transparent animationType="fade" onRequestClose={() => setShowInvite(false)}>
        <BlurView intensity={40} tint="dark" style={StyleSheet.absoluteFill} />
        <View style={styles.backdrop} />
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          style={{ flex: 1, justifyContent: 'flex-end' }}
        >
          <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
            <View style={styles.sheet}>
              <View style={styles.sheetHeader}>
                <Text style={styles.sheetTitle}>Invite co-parent</Text>
                <PressScale testID="close-invite" onPress={() => setShowInvite(false)} style={styles.iconBtn}>
                  <X color="#fff" size={18} />
                </PressScale>
              </View>
              <Text style={styles.inviteHelp}>
                They&apos;ll get an email with a join link. Signing in merges them into your family feed, calendar, vault, and kids.
              </Text>

              <Text style={styles.label}>Email</Text>
              <TextInput
                testID="invite-email"
                value={inviteEmail}
                onChangeText={setInviteEmail}
                placeholder="partner@example.com"
                placeholderTextColor="rgba(255,255,255,0.3)"
                autoCapitalize="none"
                keyboardType="email-address"
                style={styles.input}
              />

              {inviteResult ? (
                <Text style={styles.resultText}>{inviteResult}</Text>
              ) : null}

              <View style={styles.sheetFooter}>
                <PressScale testID="cancel-invite" onPress={() => setShowInvite(false)} style={styles.cancelBtn}>
                  <Text style={styles.cancelText}>{t('cancel')}</Text>
                </PressScale>
                <PressScale
                  testID="send-invite"
                  onPress={async () => {
                    if (!inviteEmail.trim() || !inviteEmail.includes('@')) return;
                    setSending(true);
                    setInviteResult(null);
                    try {
                      const res = await api.invite(inviteEmail.trim());
                      if (res.sent) {
                        setInviteResult(`✓ Invitation sent to ${inviteEmail}`);
                        setInviteEmail('');
                      } else {
                        setInviteResult(res.error || 'Email not sent, but invite link created.');
                      }
                    } catch (e: any) {
                      setInviteResult(e?.message || 'Error');
                    } finally {
                      setSending(false);
                    }
                  }}
                  disabled={sending || !inviteEmail.trim()}
                  style={[styles.saveBtn, (!inviteEmail.trim() || sending) && { opacity: 0.5 }]}
                >
                  <Send color="#080910" size={14} />
                  <Text style={styles.saveText}>{sending ? '...' : 'Send invite'}</Text>
                </PressScale>
              </View>
            </View>
          </TouchableWithoutFeedback>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#080910' },
  scroll: { paddingHorizontal: 20, paddingTop: 14 },
  title: { fontFamily: 'PlayfairDisplay_400Regular_Italic', color: '#fff', fontSize: 40, lineHeight: 46 },
  profileRow: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  avatar: { width: 56, height: 56, borderRadius: 9999, borderWidth: 1, borderColor: 'rgba(255,255,255,0.15)' },
  avatarFallback: { backgroundColor: 'rgba(255,255,255,0.08)', alignItems: 'center', justifyContent: 'center' },
  avatarText: { color: '#fff', fontFamily: 'Inter_600SemiBold', fontSize: 20 },
  name: { color: '#fff', fontFamily: 'Inter_600SemiBold', fontSize: 17 },
  emailRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 4 },
  email: { color: 'rgba(255,255,255,0.55)', fontFamily: 'Inter_400Regular', fontSize: 12 },
  sectionRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 18, marginBottom: 10 },
  sectionLabel: {
    fontFamily: 'Inter_500Medium', fontSize: 11, color: 'rgba(255,255,255,0.55)',
    textTransform: 'uppercase', letterSpacing: 1,
  },
  memberRow: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingVertical: 10 },
  memberBorder: { borderTopWidth: 1, borderTopColor: 'rgba(255,255,255,0.06)' },
  memberAvatar: {
    width: 40, height: 40, borderRadius: 9999,
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)',
    alignItems: 'center', justifyContent: 'center',
  },
  memberInitial: { color: '#fff', fontFamily: 'Inter_600SemiBold', fontSize: 15 },
  memberName: { color: '#fff', fontFamily: 'Inter_500Medium', fontSize: 15 },
  memberRole: { color: 'rgba(255,255,255,0.5)', fontFamily: 'Inter_400Regular', fontSize: 11, marginTop: 2 },
  emptyRow: { color: 'rgba(255,255,255,0.5)', fontFamily: 'Inter_400Regular', fontSize: 13, paddingVertical: 6 },
  actionRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 4 },
  actionLabel: { color: '#fff', fontFamily: 'Inter_500Medium', fontSize: 15 },
  actionValue: { color: 'rgba(255,255,255,0.6)', fontFamily: 'Inter_400Regular', fontSize: 14 },
  logoutBtn: {
    marginTop: 28, flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    gap: 8, paddingVertical: 14, borderRadius: 14,
    borderWidth: 1, borderColor: 'rgba(239,68,68,0.25)',
    backgroundColor: 'rgba(239,68,68,0.08)',
  },
  logoutText: { color: '#EF4444', fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  inviteBtn: {
    marginTop: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 13,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    backgroundColor: 'rgba(255,255,255,0.04)',
  },
  inviteBtnText: { color: '#fff', fontFamily: 'Inter_500Medium', fontSize: 14 },
  backdrop: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8,9,16,0.5)' },
  sheet: {
    backgroundColor: 'rgba(20,22,32,0.96)',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    padding: 24,
    paddingBottom: 36,
  },
  sheetHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  sheetTitle: { fontFamily: 'PlayfairDisplay_400Regular_Italic', fontSize: 26, color: '#fff' },
  iconBtn: { padding: 8, borderRadius: 9999, borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)' },
  inviteHelp: {
    color: 'rgba(255,255,255,0.6)',
    fontFamily: 'Inter_400Regular',
    fontSize: 13,
    lineHeight: 19,
    marginTop: 4,
    marginBottom: 8,
  },
  label: {
    fontFamily: 'Inter_500Medium', fontSize: 11, color: 'rgba(255,255,255,0.5)',
    textTransform: 'uppercase', letterSpacing: 1, marginTop: 12, marginBottom: 8,
  },
  input: {
    backgroundColor: 'rgba(255,255,255,0.04)',
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.08)',
    borderRadius: 14, paddingHorizontal: 14, paddingVertical: 12,
    color: '#fff', fontFamily: 'Inter_400Regular', fontSize: 15,
  },
  resultText: {
    marginTop: 12,
    color: 'rgba(255,255,255,0.75)',
    fontFamily: 'Inter_400Regular',
    fontSize: 13,
  },
  sheetFooter: { flexDirection: 'row', gap: 12, marginTop: 18 },
  cancelBtn: {
    flex: 1, borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 14, paddingVertical: 14, alignItems: 'center',
  },
  cancelText: { color: 'rgba(255,255,255,0.7)', fontFamily: 'Inter_500Medium', fontSize: 15 },
  saveBtn: {
    flex: 1, backgroundColor: '#fff', borderRadius: 14, paddingVertical: 14,
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8,
  },
  saveText: { color: '#080910', fontFamily: 'Inter_600SemiBold', fontSize: 15 },
});
