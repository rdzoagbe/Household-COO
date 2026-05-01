# Household COO - Vault Board 2.0 polish helper
# Adds a premium command-center layout to the Vault screen without backend changes.

$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\TheKwekuRO\Documents\Household-COO"
$FrontendPath = Join-Path $RepoPath "frontend"
$VaultFile = Join-Path $FrontendPath "app\(tabs)\vault.tsx"
$BranchName = "feature/vault-board-2"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Set-Location $RepoPath

git fetch origin
git switch $BranchName
git pull origin $BranchName

if (!(Test-Path $VaultFile)) {
  throw "vault.tsx not found at $VaultFile"
}

$content = [System.IO.File]::ReadAllText($VaultFile, [System.Text.Encoding]::UTF8)
$newLine = if ($content.Contains("`r`n")) { "`r`n" } else { "`n" }

# Extend imports safely.
$content = $content.Replace(
  "import React, { useCallback, useEffect, useState } from 'react';",
  "import React, { useCallback, useEffect, useMemo, useState } from 'react';"
)
$content = $content.Replace(
  "import { Plus, X, Lock, Trash2, Stethoscope, BookOpen, Shield, Scale } from 'lucide-react-native';",
  "import { Plus, X, Lock, Trash2, Stethoscope, BookOpen, Shield, Scale, AlertTriangle, CheckCircle2, FileText, Search, Sparkles } from 'lucide-react-native';"
)
$content = $content.Replace(", Clock3", "")

# Add board helpers after CATEGORIES.
$helperMarker = "type ToastState = {"
$helperBlock = @'

type VaultStatus = 'Valid' | 'Needs info';

function vaultStatus(doc: VaultDoc): VaultStatus {
  if (!doc.title?.trim() || !doc.category?.trim()) return 'Needs info';
  if (!doc.image_base64) return 'Needs info';
  return 'Valid';
}

function vaultCategoryTone(category: string) {
  return CATEGORIES.find((c) => c.key === category)?.tone || '#F97316';
}

const VAULT_IDEAS = ['Passport', 'Residence card', 'School form', 'Insurance', 'Medical record', 'Warranty'];
'@
if ($content -notmatch "type VaultStatus") {
  if ($content.IndexOf($helperMarker) -lt 0) { throw "Could not find ToastState marker." }
  $content = $content.Replace($helperMarker, $helperBlock.Replace("`n", $newLine) + $newLine + $helperMarker)
}

# Add derived metrics after showToast callback.
$stateMarker = "  const load = useCallback(async () => {"
$derivedBlock = @'

  const vaultStats = useMemo(() => {
    const valid = docs.filter((doc) => vaultStatus(doc) === 'Valid').length;
    const needsInfo = docs.filter((doc) => vaultStatus(doc) === 'Needs info').length;
    return { valid, needsInfo };
  }, [docs]);

  const attentionDocs = useMemo(() => docs.filter((doc) => vaultStatus(doc) !== 'Valid').slice(0, 3), [docs]);
'@
if ($content -notmatch "const vaultStats = useMemo") {
  if ($content.IndexOf($stateMarker) -lt 0) { throw "Could not find load marker." }
  $content = $content.Replace($stateMarker, $derivedBlock.Replace("`n", $newLine) + $newLine + $stateMarker)
}

# Replace header/add/top area with premium board header and dashboard sections.
$startMarker = "          <View style={styles.headerRow}>"
$endMarker = "          {showBlockingError ? ("
$start = $content.IndexOf($startMarker)
$end = $content.IndexOf($endMarker)
if ($start -lt 0 -or $end -lt 0 -or $end -le $start) {
  throw "Could not find Vault header block."
}
$topBlock = @'
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
                  <Text style={[styles.attentionMeta, { color: theme.colors.textMuted }]}>{vaultStatus(doc)} - {doc.category}</Text>
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

'@
$content = $content.Substring(0, $start) + $topBlock.Replace("`n", $newLine) + $content.Substring($end)
$content = $content.Replace("<View style={{ height: 220 }} />", "<View style={{ height: 130 }} />")

# Replace the entire StyleSheet block to avoid missing generated styles.
$stylesStart = $content.IndexOf("const styles = StyleSheet.create({")
if ($stylesStart -lt 0) { throw "Could not find styles block." }
$styleBlock = @'
const styles = StyleSheet.create({
  container: { flex: 1 },
  safeArea: { flex: 1 },
  scroll: { paddingHorizontal: 20, paddingTop: 34, paddingBottom: 130 },
  headerRow: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: 20 },
  kicker: { fontFamily: 'Inter_800ExtraBold', fontSize: 12, textTransform: 'uppercase', letterSpacing: 1.1, marginBottom: 4 },
  title: { fontFamily: 'Inter_800ExtraBold', fontSize: 39, lineHeight: 45, letterSpacing: -0.8 },
  subRow: { flexDirection: 'row', alignItems: 'center', gap: 7, marginTop: 5 },
  sub: { fontFamily: 'Inter_500Medium', fontSize: 15 },
  addBtn: { width: 58, height: 58, borderRadius: 9999, alignItems: 'center', justifyContent: 'center', shadowOffset: { width: 0, height: 10 }, shadowOpacity: 0.12, shadowRadius: 16, elevation: 5 },
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
  ideaText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 14, justifyContent: 'space-between' },
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
'@
$content = $content.Substring(0, $stylesStart) + $styleBlock.Replace("`n", $newLine)

[System.IO.File]::WriteAllText($VaultFile, $content, $Utf8NoBom)

Set-Location $FrontendPath
npm run verify

if ($LASTEXITCODE -ne 0) {
  Write-Host "Verification failed. Not committing." -ForegroundColor Red
  exit $LASTEXITCODE
}

Set-Location $RepoPath

git add "frontend/app/(tabs)/vault.tsx"

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
  Write-Host "No Vault changes to commit." -ForegroundColor Yellow
  exit 0
}

git commit -m "Polish Vault board"
git push origin $BranchName

Write-Host "Vault Board 2.0 polish committed and pushed." -ForegroundColor Green
