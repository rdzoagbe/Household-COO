import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  Platform,
  Image,
  Alert,
  Modal,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';
import { useFocusEffect } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import { Plus, X, Lock, Trash2, Stethoscope, BookOpen, Shield, Scale, AlertTriangle, CheckCircle2, Clock3, FileText, Search, Sparkles } from 'lucide-react-native';

import { AmbientBackground } from '../../src/components/AmbientBackground';
import { PressScale } from '../../src/components/PressScale';
import KeyboardAwareBottomSheet from '../../src/components/KeyboardAwareBottomSheet';
import AppToast, { ToastTone } from '../../src/components/AppToast';
import EmptyState from '../../src/components/EmptyState';
import ErrorState from '../../src/components/ErrorState';
import LoadingOverlay from '../../src/components/LoadingOverlay';

import { useStore } from '../../src/store';
import { api, VaultDoc } from '../../src/api';
import { logger } from '../../src/logger';

const CATEGORIES = [
  { key: 'Medical', icon: Stethoscope, tone: '#F97316' },
  { key: 'School', icon: BookOpen, tone: '#6366F1' },
  { key: 'Insurance', icon: Shield, tone: '#10B981' },
  { key: 'Legal', icon: Scale, tone: '#EAB308' },
];


type VaultStatus = 'Valid' | 'Needs info' | 'Review';

function vaultStatus(doc: VaultDoc): VaultStatus {
  if (!doc.title?.trim() || !doc.category?.trim()) return 'Needs info';
  if (!doc.image_base64) return 'Needs info';
  return 'Valid';
}

function vaultCategoryTone(category: string) {
  return CATEGORIES.find((c) => c.key === category)?.tone || '#F97316';
}

const VAULT_IDEAS = ['Passport', 'Residence card', 'School form', 'Insurance', 'Medical record', 'Warranty'];
type ToastState = {
  message: string;
  tone: ToastTone;
};

export default function VaultScreen() {
  const { t, theme } = useStore();

  const [docs, setDocs] = useState<VaultDoc[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [preview, setPreview] = useState<VaultDoc | null>(null);

  const [title, setTitle] = useState('');
  const [category, setCategory] = useState('Medical');
  const [image, setImage] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<ToastState | null>(null);

  const showToast = useCallback((message: string, tone: ToastTone = 'info') => {
    setToast({ message, tone });
    setTimeout(() => setToast(null), 2300);
  }, []);


  const vaultStats = useMemo(() => {
    const valid = docs.filter((doc) => vaultStatus(doc) === 'Valid').length;
    const needsInfo = docs.filter((doc) => vaultStatus(doc) === 'Needs info').length;
    const categories = new Set(docs.map((doc) => doc.category).filter(Boolean)).size;
    return { valid, needsInfo, categories };
  }, [docs]);

  const attentionDocs = useMemo(() => docs.filter((doc) => vaultStatus(doc) !== 'Valid').slice(0, 3), [docs]);
  const load = useCallback(async () => {
    try {
      setErrorMessage(null);
      const res = await api.listVault();
      setDocs(res);
    } catch (e: any) {
      logger.warn('Vault load failed:', e?.message || e);
      setErrorMessage(e?.message || 'Could not load vault.');
    } finally {
      setLoading(false);
    }
  }, []);

  useFocusEffect(useCallback(() => { load(); }, [load]));
  useEffect(() => { load(); }, [load]);

  const openAdd = () => {
    setTitle('');
    setCategory('Medical');
    setImage(null);
    setShowAdd(true);
  };

  const closeAdd = () => setShowAdd(false);

  const pickImage = async () => {
    if (Platform.OS !== 'web') {
      const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (!perm.granted) {
        Alert.alert('Permission needed', 'Gallery access is required.');
        return;
      }
    }

    const res = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Images, base64: true, quality: 0.6 });
    if (!res.canceled && res.assets?.[0]) {
      const asset = res.assets[0];
      const imageValue = asset.base64 ? `data:image/jpeg;base64,${asset.base64}` : asset.uri;
      setImage(imageValue);
    }
  };

  const save = async () => {
    if (!title.trim() || !image) return;
    setSaving(true);
    try {
      const created = await api.createVaultDoc({ title: title.trim(), category, image_base64: image });
      setDocs((prev) => [created, ...prev]);
      setTitle('');
      setImage(null);
      setCategory('Medical');
      setShowAdd(false);
      showToast('Document saved.', 'success');
    } catch (e: any) {
      logger.warn('Save vault document failed:', e?.message || e);
      showToast(e?.message || 'Could not save document.', 'error');
    } finally {
      setSaving(false);
    }
  };

  const remove = async (doc: VaultDoc) => {
    const previous = docs;
    setDocs((prev) => prev.filter((d) => d.doc_id !== doc.doc_id));
    setPreview(null);
    try {
      await api.deleteVaultDoc(doc.doc_id);
      showToast('Document deleted.', 'success');
    } catch (e: any) {
      logger.warn('Delete vault document failed:', e?.message || e);
      setDocs(previous);
      showToast('Could not delete document.', 'error');
      load();
    }
  };

  const showBlockingError = !loading && Boolean(errorMessage) && docs.length === 0;

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.bg }]}> 
      <AmbientBackground />
      <SafeAreaView style={styles.safeArea} edges={['top']}>
        <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false}>
          <View style={styles.headerRow}>
            <View style={{ flex: 1 }}>
              <Text style={[styles.kicker, { color: theme.colors.textMuted }]}>Family document control room</Text>
              <Text style={[styles.title, { color: theme.colors.text }]}>{t('vault')}</Text>
              <View style={styles.subRow}>
                <Lock color={theme.colors.textMuted} size={14} />
                <Text style={[styles.sub, { color: theme.colors.textMuted }]}>Secure, organized, ready when you need it</Text>
              </View>
            </View>
            <PressScale testID="vault-add" onPress={openAdd} style={[styles.addBtn, { backgroundColor: theme.colors.primary, shadowColor: theme.colors.shadow }]}>
              <Plus color={theme.colors.primaryText} size={22} />
            </PressScale>
          </View>

          <View style={[styles.heroCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder, shadowColor: theme.colors.shadow }]}> 
            <View style={styles.heroCopy}>
              <View style={[styles.heroBadge, { backgroundColor: theme.colors.accentSoft }]}> 
                <Sparkles color={theme.colors.accent} size={14} />
                <Text style={[styles.heroBadgeText, { color: theme.colors.accent }]}>Vault health</Text>
              </View>
              <Text style={[styles.heroTitle, { color: theme.colors.text }]}>{docs.length} documents protected</Text>
              <Text style={[styles.heroSub, { color: theme.colors.textMuted }]}>Scan, classify, and track important family papers before they become urgent.</Text>
            </View>
            <View style={[styles.healthCircle, { borderColor: theme.colors.cardBorder, backgroundColor: theme.colors.bgSoft }]}> 
              <Text style={[styles.healthValue, { color: theme.colors.text }]}>{Math.max(0, Math.min(100, docs.length === 0 ? 0 : Math.round((vaultStats.valid / docs.length) * 100)))}</Text>
              <Text style={[styles.healthLabel, { color: theme.colors.textMuted }]}>/100</Text>
            </View>
          </View>

          <View style={styles.statGrid}>
            <View style={[styles.statCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
              <FileText color={theme.colors.accent} size={18} />
              <Text style={[styles.statValue, { color: theme.colors.text }]}>{docs.length}</Text>
              <Text style={[styles.statLabel, { color: theme.colors.textMuted }]}>Total docs</Text>
            </View>
            <View style={[styles.statCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
              <AlertTriangle color="#F97316" size={18} />
              <Text style={[styles.statValue, { color: theme.colors.text }]}>{vaultStats.needsInfo}</Text>
              <Text style={[styles.statLabel, { color: theme.colors.textMuted }]}>Needs info</Text>
            </View>
            <View style={[styles.statCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
              <CheckCircle2 color={theme.colors.success} size={18} />
              <Text style={[styles.statValue, { color: theme.colors.text }]}>{vaultStats.valid}</Text>
              <Text style={[styles.statLabel, { color: theme.colors.textMuted }]}>Valid</Text>
            </View>
          </View>

          <View style={styles.sectionRow}>
            <Text style={[styles.sectionTitle, { color: theme.colors.text }]}>Needs attention</Text>
            <Text style={[styles.sectionCount, { color: theme.colors.textMuted }]}>{attentionDocs.length}</Text>
          </View>

          {attentionDocs.length === 0 ? (
            <View style={[styles.attentionEmpty, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
              <CheckCircle2 color={theme.colors.success} size={20} />
              <Text style={[styles.attentionEmptyText, { color: theme.colors.text }]}>No document needs attention right now.</Text>
            </View>
          ) : (
            attentionDocs.map((doc) => (
              <PressScale key={`attention-${doc.doc_id}`} onPress={() => setPreview(doc)} style={[styles.attentionCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
                <View style={[styles.attentionIcon, { backgroundColor: `${vaultCategoryTone(doc.category)}22` }]}> 
                  <AlertTriangle color={vaultCategoryTone(doc.category)} size={18} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={[styles.attentionTitle, { color: theme.colors.text }]} numberOfLines={1}>{doc.title || 'Untitled document'}</Text>
                  <Text style={[styles.attentionMeta, { color: theme.colors.textMuted }]}>{vaultStatus(doc)} Â· {doc.category}</Text>
                </View>
              </PressScale>
            ))
          )}

          <View style={styles.sectionRow}>
            <Text style={[styles.sectionTitle, { color: theme.colors.text }]}>Quick scan ideas</Text>
          </View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.ideaRail}>
            {VAULT_IDEAS.map((idea) => (
              <PressScale key={idea} onPress={() => { setTitle(idea); setShowAdd(true); }} style={[styles.ideaChip, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
                <Search color={theme.colors.textMuted} size={14} />
                <Text style={[styles.ideaText, { color: theme.colors.text }]}>{idea}</Text>
              </PressScale>
            ))}
          </ScrollView>

          <View style={styles.sectionRow}>
            <Text style={[styles.sectionTitle, { color: theme.colors.text }]}>Documents</Text>
            <Text style={[styles.sectionCount, { color: theme.colors.textMuted }]}>{docs.length}</Text>
          </View>
          {showBlockingError ? (
            <ErrorState title="Vault unavailable" message={errorMessage || 'Could not load vault.'} onRetry={load} />
          ) : docs.length === 0 && !loading ? (
            <EmptyState title={t('no_docs')} message="Store school slips, insurance papers, IDs, and household documents." actionLabel={t('add_document')} onAction={openAdd} />
          ) : (
            <View style={styles.grid}>
              {docs.map((d) => {
                const cat = CATEGORIES.find((c) => c.key === d.category) || CATEGORIES[0];
                const Icon = cat.icon;
                return (
                  <PressScale key={d.doc_id} testID={`vault-doc-${d.doc_id}`} onPress={() => setPreview(d)} style={[styles.tile, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder, shadowColor: theme.colors.shadow }]}> 
                    <Image source={{ uri: d.image_base64 }} style={styles.tileImg} />
                    <View style={styles.tileOverlay} />
                    <View style={styles.tileTop}>
                      <View style={[styles.catPill, { borderColor: `${cat.tone}88`, backgroundColor: 'rgba(255,255,255,0.88)' }]}> 
                        <Icon color={cat.tone} size={12} />
                        <Text style={[styles.catText, { color: cat.tone }]}>{t(d.category.toLowerCase())}</Text>
                      </View>
                    </View>
                    <Text style={styles.tileTitle} numberOfLines={2}>{d.title}</Text>
                  </PressScale>
                );
              })}
            </View>
          )}
          <View style={{ height: 130 }} />
        </ScrollView>
      </SafeAreaView>

      <KeyboardAwareBottomSheet visible={showAdd} onClose={closeAdd} contentStyle={[styles.sheet, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
        <View style={styles.sheetHeader}>
          <Text style={[styles.sheetTitle, { color: theme.colors.text }]}>{t('add_document')}</Text>
          <PressScale testID="vault-close" onPress={closeAdd} style={[styles.iconBtn, { borderColor: theme.colors.cardBorder, backgroundColor: theme.colors.bgSoft }]}> 
            <X color={theme.colors.text} size={20} />
          </PressScale>
        </View>

        <Text style={[styles.label, { color: theme.colors.textMuted }]}>{t('title')}</Text>
        <TextInput testID="vault-title" value={title} onChangeText={setTitle} placeholder={t('title')} placeholderTextColor={theme.colors.textSoft} style={[styles.input, { color: theme.colors.text, backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]} returnKeyType="next" />

        <Text style={[styles.label, { color: theme.colors.textMuted }]}>{t('doc_category')}</Text>
        <View style={styles.catRow}>
          {CATEGORIES.map((c) => {
            const Icon = c.icon;
            const active = category === c.key;
            return (
              <PressScale key={c.key} testID={`vault-cat-${c.key}`} onPress={() => setCategory(c.key)} style={[styles.catBtn, { borderColor: active ? c.tone : theme.colors.cardBorder, backgroundColor: active ? `${c.tone}18` : theme.colors.bgSoft }]}> 
                <Icon color={active ? c.tone : theme.colors.textMuted} size={15} />
                <Text style={[styles.catBtnLabel, { color: active ? c.tone : theme.colors.textMuted }]}>{t(c.key.toLowerCase())}</Text>
              </PressScale>
            );
          })}
        </View>

        <PressScale testID="vault-pick" onPress={pickImage} style={[styles.pick, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}> 
          {image ? <Image source={{ uri: image }} style={styles.pickImg} /> : <Text style={[styles.pickText, { color: theme.colors.textMuted }]}>Tap to pick document image</Text>}
        </PressScale>

        <View style={styles.sheetFooter}>
          <PressScale testID="vault-cancel" onPress={closeAdd} style={[styles.cancelBtn, { borderColor: theme.colors.cardBorder }]}> 
            <Text style={[styles.cancelText, { color: theme.colors.textMuted }]}>{t('cancel')}</Text>
          </PressScale>
          <PressScale testID="vault-save" onPress={save} disabled={saving || !title.trim() || !image} style={[styles.saveBtn, { backgroundColor: theme.colors.primary }, (!title.trim() || !image || saving) && { opacity: 0.5 }]}> 
            <Text style={[styles.saveText, { color: theme.colors.primaryText }]}>{saving ? '...' : t('save')}</Text>
          </PressScale>
        </View>
      </KeyboardAwareBottomSheet>

      <Modal visible={!!preview} transparent animationType="fade" onRequestClose={() => setPreview(null)}>
        <BlurView intensity={60} tint="dark" style={StyleSheet.absoluteFill} />
        <View style={styles.backdrop} />
        {preview ? (
          <View style={styles.previewWrap}>
            <View style={styles.previewTop}>
              <Text style={styles.previewTitle}>{preview.title}</Text>
              <View style={styles.previewActions}>
                <PressScale testID="preview-delete" onPress={() => remove(preview)} style={styles.previewIconBtn}>
                  <Trash2 color="#EF4444" size={20} />
                </PressScale>
                <PressScale testID="preview-close" onPress={() => setPreview(null)} style={styles.previewIconBtn}>
                  <X color="#fff" size={20} />
                </PressScale>
              </View>
            </View>
            <Image source={{ uri: preview.image_base64 }} style={styles.previewImg} />
          </View>
        ) : null}
      </Modal>

      <LoadingOverlay visible={loading} label="Loading vault..." />
      <AppToast visible={Boolean(toast)} message={toast?.message || null} tone={toast?.tone || 'info'} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  safeArea: { flex: 1 },
  scroll: { paddingHorizontal: 20, paddingTop: 34, paddingBottom: 190 },
  headerRow: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: 26 },
  title: { fontFamily: 'Inter_800ExtraBold', fontSize: 39, lineHeight: 45, letterSpacing: -0.8 },
  subRow: { flexDirection: 'row', alignItems: 'center', gap: 7, marginTop: 5 },
  sub: { fontFamily: 'Inter_500Medium', fontSize: 15 },
  addBtn: { width: 58, height: 58, borderRadius: 9999, alignItems: 'center', justifyContent: 'center', shadowOffset: { width: 0, height: 10 }, shadowOpacity: 0.12, shadowRadius: 16, elevation: 5 },
  kicker: { fontFamily: 'Inter_800ExtraBold', fontSize: 12, textTransform: 'uppercase', letterSpacing: 1.1, marginBottom: 4 },
  heroCard: { minHeight: 176, borderRadius: 30, borderWidth: 1, padding: 20, marginBottom: 16, flexDirection: 'row', alignItems: 'center', gap: 16, shadowOffset: { width: 0, height: 16 }, shadowOpacity: 0.10, shadowRadius: 24, elevation: 4 },
  heroCopy: { flex: 1 },
  heroBadge: { alignSelf: 'flex-start', flexDirection: 'row', alignItems: 'center', gap: 6, paddingHorizontal: 10, paddingVertical: 7, borderRadius: 9999, marginBottom: 12 },
  heroBadgeText: { fontFamily: 'Inter_800ExtraBold', fontSize: 11, textTransform: 'uppercase', letterSpacing: 0.7 },
  heroTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 25, lineHeight: 31, letterSpacing: -0.4, marginBottom: 8 },
  heroSub: { fontFamily: 'Inter_500Medium', fontSize: 14, lineHeight: 20 },
  healthCircle: { width: 86, height: 86, borderRadius: 9999, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  healthValue: { fontFamily: 'Inter_800ExtraBold', fontSize: 27, lineHeight: 31 },
  healthLabel: { fontFamily: 'Inter_700Bold', fontSize: 12 },
  statGrid: { flexDirection: 'row', gap: 10, marginBottom: 20 },
  statCard: { flex: 1, borderRadius: 22, borderWidth: 1, padding: 13, gap: 6 },
  statValue: { fontFamily: 'Inter_800ExtraBold', fontSize: 22, lineHeight: 26 },
  statLabel: { fontFamily: 'Inter_700Bold', fontSize: 11, lineHeight: 14 },
  sectionRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 6, marginBottom: 12 },
  sectionTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 20, letterSpacing: -0.2 },
  sectionCount: { fontFamily: 'Inter_800ExtraBold', fontSize: 13 },
  attentionEmpty: { minHeight: 58, borderRadius: 20, borderWidth: 1, paddingHorizontal: 14, flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 18 },
  attentionEmptyText: { flex: 1, fontFamily: 'Inter_700Bold', fontSize: 13, lineHeight: 18 },
  attentionCard: { minHeight: 70, borderRadius: 22, borderWidth: 1, padding: 13, flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 10 },
  attentionIcon: { width: 42, height: 42, borderRadius: 15, alignItems: 'center', justifyContent: 'center' },
  attentionTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 15, lineHeight: 20 },
  attentionMeta: { fontFamily: 'Inter_600SemiBold', fontSize: 12, marginTop: 2 },
  ideaRail: { gap: 10, paddingRight: 12, paddingBottom: 4, marginBottom: 18 },
  ideaChip: { minHeight: 42, borderRadius: 9999, borderWidth: 1, paddingHorizontal: 13, flexDirection: 'row', alignItems: 'center', gap: 7 },
  ideaText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 14, justifyContent: 'space-between' },
  tile: { width: '48%', aspectRatio: 0.82, borderRadius: 24, borderWidth: 1, overflow: 'hidden', justifyContent: 'space-between', padding: 12, shadowOffset: { width: 0, height: 12 }, shadowOpacity: 0.10, shadowRadius: 20, elevation: 4 },
  tileImg: { ...StyleSheet.absoluteFillObject, resizeMode: 'cover' },
  tileOverlay: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(15,23,42,0.46)' },
  tileTop: { flexDirection: 'row' },
  catPill: { flexDirection: 'row', alignItems: 'center', gap: 5, paddingHorizontal: 9, paddingVertical: 5, borderWidth: 1, borderRadius: 9999 },
  catText: { fontFamily: 'Inter_800ExtraBold', fontSize: 11, letterSpacing: 0.35 },
  tileTitle: { color: '#FFFFFF', fontFamily: 'Inter_800ExtraBold', fontSize: 17, lineHeight: 22, textShadowColor: 'rgba(0,0,0,0.45)', textShadowRadius: 10 },
  backdrop: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8,9,16,0.5)' },
  sheet: { borderTopLeftRadius: 34, borderTopRightRadius: 34, borderWidth: 1, padding: 26, paddingBottom: 140 },
  sheetHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
  sheetTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 26, letterSpacing: -0.4 },
  iconBtn: { padding: 9, borderRadius: 9999, borderWidth: 1 },
  label: { fontFamily: 'Inter_800ExtraBold', fontSize: 12, textTransform: 'uppercase', letterSpacing: 1, marginTop: 14, marginBottom: 8 },
  input: { borderWidth: 1, borderRadius: 16, paddingHorizontal: 15, paddingVertical: 13, fontFamily: 'Inter_500Medium', fontSize: 16 },
  catRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 9 },
  catBtn: { flexDirection: 'row', alignItems: 'center', gap: 7, paddingHorizontal: 13, paddingVertical: 10, borderRadius: 9999, borderWidth: 1 },
  catBtnLabel: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
  pick: { marginTop: 18, height: 150, borderRadius: 18, borderWidth: 1, borderStyle: 'dashed', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  pickImg: { ...StyleSheet.absoluteFillObject, resizeMode: 'cover' },
  pickText: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  sheetFooter: { flexDirection: 'row', gap: 12, marginTop: 22 },
  cancelBtn: { flex: 1, borderWidth: 1, borderRadius: 18, paddingVertical: 15, alignItems: 'center' },
  cancelText: { fontFamily: 'Inter_800ExtraBold', fontSize: 15 },
  saveBtn: { flex: 1, borderRadius: 18, paddingVertical: 15, alignItems: 'center' },
  saveText: { fontFamily: 'Inter_800ExtraBold', fontSize: 15 },
  previewWrap: { flex: 1, padding: 24, justifyContent: 'center' },
  previewTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 },
  previewTitle: { flex: 1, color: '#fff', fontFamily: 'Inter_800ExtraBold', fontSize: 24 },
  previewActions: { flexDirection: 'row', gap: 8 },
  previewIconBtn: { padding: 10, borderRadius: 9999, borderWidth: 1, borderColor: 'rgba(255,255,255,0.18)', backgroundColor: 'rgba(15,23,42,0.55)' },
  previewImg: { width: '100%', aspectRatio: 0.75, borderRadius: 24, borderWidth: 1, borderColor: 'rgba(255,255,255,0.16)' },
});
