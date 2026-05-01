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

# Extend imports.
$content = $content.Replace(
  "import React, { useCallback, useEffect, useState } from 'react';",
  "import React, { useCallback, useEffect, useMemo, useState } from 'react';"
)
$content = $content.Replace(
  "import { Plus, X, Lock, Trash2, Stethoscope, BookOpen, Shield, Scale } from 'lucide-react-native';",
  "import { Plus, X, Lock, Trash2, Stethoscope, BookOpen, Shield, Scale, AlertTriangle, CheckCircle2, Clock3, FileText, Search, Sparkles } from 'lucide-react-native';"
)

# Add board labels and helpers after CATEGORIES.
$helperMarker = "type ToastState = {"
$helperBlock = @'

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
'@
if ($content -notmatch "type VaultStatus") {
  $content = $content.Replace($helperMarker, $helperBlock.Replace("`n", $newLine) + $newLine + $helperMarker)
}

# Add derived metrics after showToast callback.
$stateMarker = "  const load = useCallback(async () => {"
$derivedBlock = @'

  const vaultStats = useMemo(() => {
    const valid = docs.filter((doc) => vaultStatus(doc) === 'Valid').length;
    const needsInfo = docs.filter((doc) => vaultStatus(doc) === 'Needs info').length;
    const categories = new Set(docs.map((doc) => doc.category).filter(Boolean)).size;
    return { valid, needsInfo, categories };
  }, [docs]);

  const attentionDocs = useMemo(() => docs.filter((doc) => vaultStatus(doc) !== 'Valid').slice(0, 3), [docs]);
'@
if ($content -notmatch "const vaultStats = useMemo") {
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
                  <Text style={[styles.attentionMeta, { color: theme.colors.textMuted }]}>{vaultStatus(doc)} · {doc.category}</Text>
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

# Reduce end spacing.
$content = $content.Replace("<View style={{ height: 220 }} />", "<View style={{ height: 130 }} />")

# Insert/override styles before grid.
$styleNames = @('kicker','heroCard','heroCopy','heroBadge','heroBadgeText','heroTitle','heroSub','healthCircle','healthValue','healthLabel','statGrid','statCard','statValue','statLabel','sectionRow','sectionTitle','sectionCount','attentionEmpty','attentionEmptyText','attentionCard','attentionIcon','attentionTitle','attentionMeta','ideaRail','ideaChip','ideaText')
foreach ($styleName in $styleNames) {
  $content = [regex]::Replace($content, "(?m)^\s*$styleName\s*:\s*.*\r?\n", "")
}
$styles = @'
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
  ideaText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
'@
$content = [regex]::Replace($content, "(?m)^\s*grid:\s*\{", $styles.Replace("`n", $newLine) + '$&', 1)

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
