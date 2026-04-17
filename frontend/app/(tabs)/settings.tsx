import React, { useCallback, useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Image } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Globe, LogOut, Users, Mail } from 'lucide-react-native';
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
});
