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
import {
  Plus,
  X,
  Lock,
  Trash2,
  Stethoscope,
  BookOpen,
  Shield,
  Scale,
  AlertTriangle,
  CheckCircle2,
  FileText,
  Search,
  Sparkles,
  Clock3,
  Eye,
  CalendarDays,
  FolderOpen,
  Home,
} from 'lucide-react-native';

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

type VaultStatus = 'Valid' | 'Needs info' | 'Review soon' | 'Reviewed';

type CategoryMeta = {
  key: string;
  label: string;
  icon: any;
  tone: string;
  cadenceDays: number;
};

const CATEGORIES: CategoryMeta[] = [
  { key: 'Medical', label: 'Medical', icon: Stethoscope, tone: '#F97316', cadenceDays: 180 },
  { key: 'School', label: 'School', icon: BookOpen, tone: '#6366F1', cadenceDays: 90 },
  { key: 'Insurance', label: 'Insurance', icon: Shield, tone: '#10B981', cadenceDays: 180 },
  { key: 'Legal', label: 'Legal', icon: Scale, tone: '#EAB308', cadenceDays: 365 },
  { key: 'Identity', label: 'Identity', icon: Shield, tone: '#38BDF8', cadenceDays: 365 },
  { key: 'Home', label: 'Home', icon: Home, tone: '#A855F7', cadenceDays: 365 },
];

const VAULT_IDEAS = ['Passport', 'Residence card', 'School form', 'Insurance', 'Medical record', 'Warranty'];
const IMPORTANT_CATEGORIES = new Set(['Identity', 'Legal', 'Insurance', 'Medical']);

type ToastState = {
  message: string;
  tone: ToastTone;
};

function categoryMeta(category?: string | null) {
  return CATEGORIES.find((c) => c.key === category) || CATEGORIES[0];
}

function createdTime(doc: VaultDoc) {
  const value = new Date(doc.created_at).getTime();
  return Number.isNaN(value) ? Date.now() : value;
}

function nextReviewDate(doc: VaultDoc) {
  const meta = categoryMeta(doc.category);
  return new Date(createdTime(doc) + meta.cadenceDays * 24 * 60 * 60 * 1000);
}

function daysUntilReview(doc: VaultDoc) {
  const diff = nextReviewDate(doc).getTime() - Date.now();
  return Math.ceil(diff / (24 * 60 * 60 * 1000));
}

function vaultStatus(doc: VaultDoc, reviewedIds: Set<string>): VaultStatus {
  if (reviewedIds.has(doc.doc_id)) return 'Reviewed';
  if (!doc.title?.trim() || !doc.category?.trim() || !doc.image_base64) return 'Needs info';
  if (daysUntilReview(doc) <= 30) return 'Review soon';
  return 'Valid';
}

function statusTone(status: VaultStatus) {
  if (status === 'Reviewed' || status === 'Valid') return '#10B981';
  if (status === 'Review soon') return '#F97316';
  return '#EF4444';
}

function formatCreated(doc: VaultDoc) {
  const date = new Date(createdTime(doc));
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function formatReview(doc: VaultDoc) {
  const days = daysUntilReview(doc);
  if (days < 0) return `${Math.abs(days)}d overdue`;
  if (days === 0) return 'Due today';
  if (days === 1) return 'Due tomorrow';
  if (days <= 30) return `Due in ${days}d`;
  return nextReviewDate(doc).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function docMatches(doc: VaultDoc, query: string) {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  return `${doc.title} ${doc.category}`.toLowerCase().includes(q);
}

function healthScore(total: number, valid: number, needsInfo: number, reviewSoon: number) {
  if (total === 0) return 0;
  return Math.max(12, Math.min(100, Math.round((valid / total) * 100) - needsInfo * 6 - reviewSoon * 3));
}

export default function VaultScreen() {
  const { t, theme } = useStore();

  const [docs, setDocs] = useState<VaultDoc[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [preview, setPreview] = useState<VaultDoc | null>(null);
  const [query, setQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [reviewedIds, setReviewedIds] = useState<Set<string>>(() => new Set());

  const [title, setTitle] = useState('');
  const [category, setCategory] = useState('Medical');
  const [image, setImage] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<ToastState | null>(null);

  const showToast = useCallback((message: string, tone: ToastTone = 'info') => {
    setToast({ message, tone });
    setTimeout(() => setToast(null), 2300);
  }, []);

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

    const res = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      base64: true,
      quality: 0.6,
    });
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
    setReviewedIds((prev) => {
      const next = new Set(prev);
      next.delete(doc.doc_id);
      return next;
    });
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

  const markReviewed = (doc: VaultDoc) => {
    setReviewedIds((prev) => {
      const next = new Set(prev);
      next.add(doc.doc_id);
      return next;
    });
    showToast('Marked reviewed.', 'success');
  };

  const vaultStats = useMemo(() => {
    const valid = docs.filter((doc) => vaultStatus(doc, reviewedIds) === 'Valid' || vaultStatus(doc, reviewedIds) === 'Reviewed').length;
    const needsInfo = docs.filter((doc) => vaultStatus(doc, reviewedIds) === 'Needs info').length;
    const reviewSoon = docs.filter((doc) => vaultStatus(doc, reviewedIds) === 'Review soon').length;
    const categories = new Set(docs.map((doc) => doc.category).filter(Boolean)).size;
    const score = healthScore(docs.length, valid, needsInfo, reviewSoon);
    return { valid, needsInfo, reviewSoon, categories, score };
  }, [docs, reviewedIds]);

  const filteredDocs = useMemo(() => {
    return docs
      .filter((doc) => selectedCategory === 'All' || doc.category === selectedCategory)
      .filter((doc) => docMatches(doc, query))
      .sort((a, b) => createdTime(b) - createdTime(a));
  }, [docs, query, selectedCategory]);

  const reviewQueue = useMemo(() => {
    return docs
      .filter((doc) => vaultStatus(doc, reviewedIds) !== 'Valid' && vaultStatus(doc, reviewedIds) !== 'Reviewed')
      .sort((a, b) => daysUntilReview(a) - daysUntilReview(b))
      .slice(0, 4);
  }, [docs, reviewedIds]);

  const importantDocs = useMemo(() => {
    const important = filteredDocs.filter((doc) => IMPORTANT_CATEGORIES.has(doc.category)).slice(0, 4);
    return important.length > 0 ? important : filteredDocs.slice(0, 4);
  }, [filteredDocs]);

  const recentDocs = useMemo(() => filteredDocs.slice(0, 6), [filteredDocs]);
  const showBlockingError = !loading && Boolean(errorMessage) && docs.length === 0;

  const renderDocMiniCard = (doc: VaultDoc, testPrefix: string) => {
    const meta = categoryMeta(doc.category);
    const Icon = meta.icon;
    const status = vaultStatus(doc, reviewedIds);
    return (
      <View key={`${testPrefix}-${doc.doc_id}`} style={[styles.miniCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}>
        <PressScale onPress={() => setPreview(doc)} style={styles.miniMain}>
          <View style={[styles.miniIcon, { backgroundColor: `${meta.tone}22` }]}>
            <Icon color={meta.tone} size={18} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.miniTitle, { color: theme.colors.text }]} numberOfLines={1}>{doc.title || 'Untitled document'}</Text>
            <Text style={[styles.miniMeta, { color: theme.colors.textMuted }]} numberOfLines={1}>{meta.label} · {formatReview(doc)}</Text>
          </View>
          <View style={[styles.statusPill, { backgroundColor: `${statusTone(status)}1F` }]}>
            <Text style={[styles.statusText, { color: statusTone(status) }]}>{status}</Text>
          </View>
        </PressScale>
        <View style={styles.inlineActions}>
          <PressScale testID={`${testPrefix}-open-${doc.doc_id}`} onPress={() => setPreview(doc)} style={[styles.inlineBtn, { borderColor: theme.colors.cardBorder }]}>
            <Eye color={theme.colors.textMuted} size={15} />
            <Text style={[styles.inlineText, { color: theme.colors.textMuted }]}>Open</Text>
          </PressScale>
          <PressScale testID={`${testPrefix}-review-${doc.doc_id}`} onPress={() => markReviewed(doc)} style={[styles.inlineBtn, { borderColor: theme.colors.cardBorder }]}>
            <CheckCircle2 color={theme.colors.success} size={15} />
            <Text style={[styles.inlineText, { color: theme.colors.textMuted }]}>Reviewed</Text>
          </PressScale>
          <PressScale testID={`${testPrefix}-delete-${doc.doc_id}`} onPress={() => remove(doc)} style={[styles.inlineDanger, { borderColor: theme.colors.cardBorder }]}>
            <Trash2 color="#EF4444" size={15} />
          </PressScale>
        </View>
      </View>
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.bg }]}> 
      <AmbientBackground />
      <SafeAreaView style={styles.safeArea} edges={['top']}>
        <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false}>
          <View style={styles.headerRow}>
            <View style={{ flex: 1 }}>
              <Text style={[styles.kicker, { color: theme.colors.textMuted }]}>Family document control room</Text>
              <Text style={[styles.title, { color: theme.colors.text }]}>Vault Board</Text>
              <View style={styles.subRow}>
                <Lock color={theme.colors.textMuted} size={14} />
                <Text style={[styles.sub, { color: theme.colors.textMuted }]}>Secure, organized, ready when you need it</Text>
              </View>
            </View>
            <PressScale testID="vault-add" onPress={openAdd} style={[styles.addBtn, { backgroundColor: theme.colors.primary, shadowColor: theme.colors.shadow }]}>
              <Plus color={theme.colors.primaryText} size={22} />
            </PressScale>
          </View>

          <View style={[styles.searchShell, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder, shadowColor: theme.colors.shadow }]}>
            <Search color={theme.colors.textSoft} size={19} />
            <TextInput
              value={query}
              onChangeText={setQuery}
              placeholder="Search documents"
              placeholderTextColor={theme.colors.textSoft}
              style={[styles.searchInput, { color: theme.colors.text }]}
            />
          </View>

          <View style={[styles.heroCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder, shadowColor: theme.colors.shadow }]}>
            <View style={styles.heroCopy}>
              <View style={[styles.heroBadge, { backgroundColor: theme.colors.accentSoft }]}> 
                <Sparkles color={theme.colors.accent} size={14} />
                <Text style={[styles.heroBadgeText, { color: theme.colors.accent }]}>Vault health</Text>
              </View>
              <Text style={[styles.heroTitle, { color: theme.colors.text }]}>{docs.length} documents protected</Text>
              <Text style={[styles.heroSub, { color: theme.colors.textMuted }]}>Important family papers, review dates, and quick actions in one premium board.</Text>
            </View>
            <View style={[styles.healthCircle, { borderColor: theme.colors.cardBorder, backgroundColor: theme.colors.bgSoft }]}> 
              <Text style={[styles.healthValue, { color: theme.colors.text }]}>{vaultStats.score}</Text>
              <Text style={[styles.healthLabel, { color: theme.colors.textMuted }]}>/100</Text>
            </View>
          </View>

          <View style={styles.statGrid}>
            <View style={[styles.statCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
              <FileText color={theme.colors.accent} size={18} />
              <Text style={[styles.statValue, { color: theme.colors.text }]}>{docs.length}</Text>
              <Text style={[styles.statLabel, { color: theme.colors.textMuted }]}>Saved</Text>
            </View>
            <View style={[styles.statCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
              <Clock3 color="#F97316" size={18} />
              <Text style={[styles.statValue, { color: theme.colors.text }]}>{vaultStats.reviewSoon}</Text>
              <Text style={[styles.statLabel, { color: theme.colors.textMuted }]}>Review soon</Text>
            </View>
            <View style={[styles.statCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
              <AlertTriangle color="#EF4444" size={18} />
              <Text style={[styles.statValue, { color: theme.colors.text }]}>{vaultStats.needsInfo}</Text>
              <Text style={[styles.statLabel, { color: theme.colors.textMuted }]}>Missing info</Text>
            </View>
            <View style={[styles.statCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
              <FolderOpen color={theme.colors.success} size={18} />
              <Text style={[styles.statValue, { color: theme.colors.text }]}>{vaultStats.categories}</Text>
              <Text style={[styles.statLabel, { color: theme.colors.textMuted }]}>Categories</Text>
            </View>
          </View>

          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.categoryRail}>
            {['All', ...CATEGORIES.map((c) => c.key)].map((key) => {
              const active = selectedCategory === key;
              const meta = key === 'All' ? null : categoryMeta(key);
              const Icon = meta?.icon || FolderOpen;
              return (
                <PressScale
                  key={key}
                  onPress={() => setSelectedCategory(key)}
                  style={[
                    styles.filterChip,
                    {
                      backgroundColor: active ? theme.colors.primary : theme.colors.card,
                      borderColor: active ? theme.colors.primary : theme.colors.cardBorder,
                    },
                  ]}
                >
                  <Icon color={active ? theme.colors.primaryText : meta?.tone || theme.colors.textMuted} size={14} />
                  <Text style={[styles.filterText, { color: active ? theme.colors.primaryText : theme.colors.text }]}>{key}</Text>
                </PressScale>
              );
            })}
          </ScrollView>

          <View style={styles.sectionRow}>
            <Text style={[styles.sectionTitle, { color: theme.colors.text }]}>Expiring / review soon</Text>
            <Text style={[styles.sectionCount, { color: theme.colors.textMuted }]}>{reviewQueue.length}</Text>
          </View>

          {reviewQueue.length === 0 ? (
            <View style={[styles.attentionEmpty, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}>
              <CheckCircle2 color={theme.colors.success} size={20} />
              <Text style={[styles.attentionEmptyText, { color: theme.colors.text }]}>No document needs attention right now.</Text>
            </View>
          ) : (
            reviewQueue.map((doc) => renderDocMiniCard(doc, 'review'))
          )}

          <View style={styles.sectionRow}>
            <Text style={[styles.sectionTitle, { color: theme.colors.text }]}>Important family docs</Text>
            <Text style={[styles.sectionCount, { color: theme.colors.textMuted }]}>{importantDocs.length}</Text>
          </View>
          {importantDocs.length > 0 ? (
            importantDocs.map((doc) => renderDocMiniCard(doc, 'important'))
          ) : null}

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
            <Text style={[styles.sectionTitle, { color: theme.colors.text }]}>Recent documents</Text>
            <Text style={[styles.sectionCount, { color: theme.colors.textMuted }]}>{recentDocs.length}/{filteredDocs.length}</Text>
          </View>
          {showBlockingError ? (
            <ErrorState title="Vault unavailable" message={errorMessage || 'Could not load vault.'} onRetry={load} />
          ) : docs.length === 0 && !loading ? (
            <EmptyState title={t('no_docs')} message="Store school slips, insurance papers, IDs, and household documents." actionLabel={t('add_document')} onAction={openAdd} />
          ) : (
            <View style={styles.grid}>
              {recentDocs.map((d) => {
                const meta = categoryMeta(d.category);
                const Icon = meta.icon;
                const status = vaultStatus(d, reviewedIds);
                return (
                  <PressScale key={d.doc_id} testID={`vault-doc-${d.doc_id}`} onPress={() => setPreview(d)} style={[styles.tile, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder, shadowColor: theme.colors.shadow }]}> 
                    {d.image_base64 ? <Image source={{ uri: d.image_base64 }} style={styles.tileImg} /> : null}
                    <View style={styles.tileOverlay} />
                    <View style={styles.tileTop}>
                      <View style={[styles.catPill, { borderColor: `${meta.tone}88`, backgroundColor: 'rgba(255,255,255,0.88)' }]}> 
                        <Icon color={meta.tone} size={12} />
                        <Text style={[styles.catText, { color: meta.tone }]}>{meta.label}</Text>
                      </View>
                      <View style={[styles.tileStatus, { backgroundColor: `${statusTone(status)}DD` }]}>
                        <Text style={styles.tileStatusText}>{status === 'Review soon' ? 'Review' : status}</Text>
                      </View>
                    </View>
                    <View>
                      <Text style={styles.tileTitle} numberOfLines={2}>{d.title}</Text>
                      <Text style={styles.tileMeta}>{formatReview(d)}</Text>
                    </View>
                  </PressScale>
                );
              })}
            </View>
          )}

          <View style={styles.footerBoard}>
            <CalendarDays color={theme.colors.textMuted} size={14} />
            <Text style={[styles.footerText, { color: theme.colors.textMuted }]}>Review dates are estimated from category cadence until expiry fields are added to the backend.</Text>
          </View>

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

        <Text style={[styles.label, { color: theme.colors.textMuted }]}>Category</Text>
        <View style={styles.catRow}>
          {CATEGORIES.map((c) => {
            const Icon = c.icon;
            const active = category === c.key;
            return (
              <PressScale key={c.key} testID={`vault-cat-${c.key}`} onPress={() => setCategory(c.key)} style={[styles.catBtn, { borderColor: active ? c.tone : theme.colors.cardBorder, backgroundColor: active ? `${c.tone}18` : theme.colors.bgSoft }]}> 
                <Icon color={active ? c.tone : theme.colors.textMuted} size={15} />
                <Text style={[styles.catBtnLabel, { color: active ? c.tone : theme.colors.textMuted }]}>{c.label}</Text>
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
              <View style={{ flex: 1 }}>
                <Text style={styles.previewTitle}>{preview.title}</Text>
                <Text style={styles.previewMeta}>{categoryMeta(preview.category).label} · Added {formatCreated(preview)} · {formatReview(preview)}</Text>
              </View>
              <View style={styles.previewActions}>
                <PressScale testID="preview-reviewed" onPress={() => markReviewed(preview)} style={styles.previewIconBtn}>
                  <CheckCircle2 color="#10B981" size={20} />
                </PressScale>
                <PressScale testID="preview-delete" onPress={() => remove(preview)} style={styles.previewIconBtn}>
                  <Trash2 color="#EF4444" size={20} />
                </PressScale>
                <PressScale testID="preview-close" onPress={() => setPreview(null)} style={styles.previewIconBtn}>
                  <X color="#fff" size={20} />
                </PressScale>
              </View>
            </View>
            {preview.image_base64 ? <Image source={{ uri: preview.image_base64 }} style={styles.previewImg} /> : null}
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
  scroll: { paddingHorizontal: 20, paddingTop: 34, paddingBottom: 130 },
  headerRow: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: 16 },
  kicker: { fontFamily: 'Inter_800ExtraBold', fontSize: 12, textTransform: 'uppercase', letterSpacing: 1.1, marginBottom: 4 },
  title: { fontFamily: 'Inter_800ExtraBold', fontSize: 39, lineHeight: 45, letterSpacing: -0.8 },
  subRow: { flexDirection: 'row', alignItems: 'center', gap: 7, marginTop: 5 },
  sub: { fontFamily: 'Inter_500Medium', fontSize: 15 },
  addBtn: { width: 58, height: 58, borderRadius: 9999, alignItems: 'center', justifyContent: 'center', shadowOffset: { width: 0, height: 10 }, shadowOpacity: 0.12, shadowRadius: 16, elevation: 5 },
  searchShell: { minHeight: 52, borderRadius: 9999, borderWidth: 1, paddingHorizontal: 16, flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 16, shadowOffset: { width: 0, height: 10 }, shadowOpacity: 0.08, shadowRadius: 18, elevation: 3 },
  searchInput: { flex: 1, fontFamily: 'Inter_600SemiBold', fontSize: 15, paddingVertical: 0 },
  heroCard: { minHeight: 176, borderRadius: 30, borderWidth: 1, padding: 20, marginBottom: 16, flexDirection: 'row', alignItems: 'center', gap: 16, shadowOffset: { width: 0, height: 16 }, shadowOpacity: 0.10, shadowRadius: 24, elevation: 4 },
  heroCopy: { flex: 1 },
  heroBadge: { alignSelf: 'flex-start', flexDirection: 'row', alignItems: 'center', gap: 6, paddingHorizontal: 10, paddingVertical: 7, borderRadius: 9999, marginBottom: 12 },
  heroBadgeText: { fontFamily: 'Inter_800ExtraBold', fontSize: 11, textTransform: 'uppercase', letterSpacing: 0.7 },
  heroTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 25, lineHeight: 31, letterSpacing: -0.4, marginBottom: 8 },
  heroSub: { fontFamily: 'Inter_500Medium', fontSize: 14, lineHeight: 20 },
  healthCircle: { width: 86, height: 86, borderRadius: 9999, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  healthValue: { fontFamily: 'Inter_800ExtraBold', fontSize: 27, lineHeight: 31 },
  healthLabel: { fontFamily: 'Inter_700Bold', fontSize: 12 },
  statGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 16 },
  statCard: { width: '48%', borderRadius: 22, borderWidth: 1, padding: 13, gap: 6 },
  statValue: { fontFamily: 'Inter_800ExtraBold', fontSize: 22, lineHeight: 26 },
  statLabel: { fontFamily: 'Inter_700Bold', fontSize: 11, lineHeight: 14 },
  categoryRail: { gap: 10, paddingRight: 12, paddingBottom: 4, marginBottom: 18 },
  filterChip: { minHeight: 40, borderRadius: 9999, borderWidth: 1, paddingHorizontal: 13, flexDirection: 'row', alignItems: 'center', gap: 7 },
  filterText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
  sectionRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 6, marginBottom: 12 },
  sectionTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 20, letterSpacing: -0.2 },
  sectionCount: { fontFamily: 'Inter_800ExtraBold', fontSize: 13 },
  attentionEmpty: { minHeight: 58, borderRadius: 20, borderWidth: 1, paddingHorizontal: 14, flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 18 },
  attentionEmptyText: { flex: 1, fontFamily: 'Inter_700Bold', fontSize: 13, lineHeight: 18 },
  miniCard: { borderRadius: 24, borderWidth: 1, padding: 12, marginBottom: 10 },
  miniMain: { flexDirection: 'row', alignItems: 'center', gap: 11 },
  miniIcon: { width: 43, height: 43, borderRadius: 16, alignItems: 'center', justifyContent: 'center' },
  miniTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 15, lineHeight: 19 },
  miniMeta: { fontFamily: 'Inter_600SemiBold', fontSize: 12, marginTop: 2 },
  statusPill: { borderRadius: 9999, paddingHorizontal: 9, paddingVertical: 5 },
  statusText: { fontFamily: 'Inter_800ExtraBold', fontSize: 10 },
  inlineActions: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 12 },
  inlineBtn: { minHeight: 34, borderRadius: 9999, borderWidth: 1, paddingHorizontal: 10, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 5 },
  inlineDanger: { width: 34, height: 34, borderRadius: 9999, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  inlineText: { fontFamily: 'Inter_800ExtraBold', fontSize: 11 },
  ideaRail: { gap: 10, paddingRight: 12, paddingBottom: 4, marginBottom: 18 },
  ideaChip: { minHeight: 42, borderRadius: 9999, borderWidth: 1, paddingHorizontal: 13, flexDirection: 'row', alignItems: 'center', gap: 7 },
  ideaText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 14, justifyContent: 'space-between' },
  tile: { width: '48%', aspectRatio: 0.82, borderRadius: 24, borderWidth: 1, overflow: 'hidden', justifyContent: 'space-between', padding: 12, shadowOffset: { width: 0, height: 12 }, shadowOpacity: 0.10, shadowRadius: 20, elevation: 4 },
  tileImg: { ...StyleSheet.absoluteFillObject, resizeMode: 'cover' },
  tileOverlay: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(15,23,42,0.50)' },
  tileTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 6 },
  catPill: { flexDirection: 'row', alignItems: 'center', gap: 5, paddingHorizontal: 9, paddingVertical: 5, borderWidth: 1, borderRadius: 9999 },
  catText: { fontFamily: 'Inter_800ExtraBold', fontSize: 10, letterSpacing: 0.25 },
  tileStatus: { borderRadius: 9999, paddingHorizontal: 8, paddingVertical: 5 },
  tileStatusText: { color: '#FFFFFF', fontFamily: 'Inter_800ExtraBold', fontSize: 10 },
  tileTitle: { color: '#FFFFFF', fontFamily: 'Inter_800ExtraBold', fontSize: 17, lineHeight: 22, textShadowColor: 'rgba(0,0,0,0.45)', textShadowRadius: 10 },
  tileMeta: { color: 'rgba(255,255,255,0.78)', fontFamily: 'Inter_700Bold', fontSize: 11, marginTop: 4 },
  footerBoard: { flexDirection: 'row', alignItems: 'center', gap: 7, marginTop: 20, paddingHorizontal: 4 },
  footerText: { flex: 1, fontFamily: 'Inter_600SemiBold', fontSize: 11, lineHeight: 15 },
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
  previewTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14, gap: 12 },
  previewTitle: { color: '#fff', fontFamily: 'Inter_800ExtraBold', fontSize: 24 },
  previewMeta: { color: 'rgba(255,255,255,0.68)', fontFamily: 'Inter_600SemiBold', fontSize: 12, marginTop: 4 },
  previewActions: { flexDirection: 'row', gap: 8 },
  previewIconBtn: { padding: 10, borderRadius: 9999, borderWidth: 1, borderColor: 'rgba(255,255,255,0.18)', backgroundColor: 'rgba(15,23,42,0.55)' },
  previewImg: { width: '100%', aspectRatio: 0.75, borderRadius: 24, borderWidth: 1, borderColor: 'rgba(255,255,255,0.16)' },
});
