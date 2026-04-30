# Household COO - Refine Feed Board
# Makes Needs Attention actionable and removes the duplicate floating action bar.

$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\TheKwekuRO\Documents\Household-COO"
$FrontendPath = Join-Path $RepoPath "frontend"
$FeedFile = Join-Path $FrontendPath "app\(tabs)\feed.tsx"
$BranchName = "feed-actionable-attention"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Set-Location $RepoPath

git fetch origin
git switch $BranchName
git pull origin $BranchName

if (!(Test-Path $FeedFile)) {
  throw "feed.tsx not found at $FeedFile"
}

$content = [System.IO.File]::ReadAllText($FeedFile, [System.Text.Encoding]::UTF8)

# Remove the duplicate floating action bar import and usage. Quick Actions already provides these actions.
$content = $content.Replace("import { FloatingActionBar } from '../../src/components/FloatingActionBar';`r`n", "")
$content = $content.Replace("import { FloatingActionBar } from '../../src/components/FloatingActionBar';`n", "")
$content = [regex]::Replace(
  $content,
  "\r?\n\s*<FloatingActionBar\s*\r?\n\s*onManual=\{openManual\}\s*\r?\n\s*onCamera=\{\(\) => setShowCamera\(true\)\}\s*\r?\n\s*onVoice=\{\(\) => setShowVoice\(true\)\}\s*\r?\n\s*/>\r?\n",
  "`r`n"
)

# Use a smaller bottom spacer now that the floating buttons are gone.
$content = $content.Replace("<View style={{ height: 220 }} />", "<View style={{ height: 120 }} />")

# Replace the non-actionable Needs Attention preview with actionable compact cards.
$oldBlockPattern = "(?s)dashboard\.priority\.slice\(0, 3\)\.map\(\(card\) => \(\s*<PressScale key=\{`priority-\$\{card\.card_id\}`\} style=\{\[styles\.priorityCard,[\s\S]*?</PressScale>\s*\)\)"
$newBlock = @'
dashboard.priority.slice(0, 4).map((card) => (
              <GlassCard key={`priority-${card.card_id}`} style={styles.attentionCard}>
                <View style={styles.attentionTopRow}>
                  <View style={[styles.priorityIcon, { backgroundColor: card.type === 'TASK' ? theme.colors.bgSoft : theme.colors.accentSoft }]}> 
                    {card.type === 'TASK' ? <CheckCircle2 color={theme.colors.success} size={18} /> : <FileText color={theme.colors.accent} size={18} />}
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.priorityTitle, { color: theme.colors.text }]} numberOfLines={2}>{card.title}</Text>
                    <Text style={[styles.priorityMeta, { color: theme.colors.textMuted }]} numberOfLines={1}>{formatCardDate(card)} · {card.assignee || t('family')}</Text>
                  </View>
                </View>

                <View style={styles.attentionActions}>
                  <PressScale testID={`attention-done-${card.card_id}`} onPress={() => toggle(card)} style={[styles.attentionDoneBtn, { backgroundColor: theme.colors.primary }]}>
                    <CheckCircle2 color={theme.colors.primaryText} size={16} />
                    <Text style={[styles.attentionDoneText, { color: theme.colors.primaryText }]}>Done</Text>
                  </PressScale>
                  <PressScale testID={`attention-delete-${card.card_id}`} onPress={() => remove(card)} style={[styles.attentionDeleteBtn, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>
                    <Trash2 color={theme.colors.textMuted} size={16} />
                  </PressScale>
                </View>
              </GlassCard>
            ))
'@

if (-not [regex]::IsMatch($content, $oldBlockPattern)) {
  throw "Could not find the Needs Attention priority block."
}
$content = [regex]::Replace($content, $oldBlockPattern, $newBlock, 1)

# Insert compact actionable styles.
$styleNames = @('attentionCard', 'attentionTopRow', 'attentionActions', 'attentionDoneBtn', 'attentionDoneText', 'attentionDeleteBtn')
foreach ($styleName in $styleNames) {
  $content = [regex]::Replace($content, "(?m)^\s*$styleName\s*:\s*.*\r?\n", "")
}

$styles = @'
  attentionCard: { marginBottom: 12, borderRadius: 26, paddingVertical: 14 },
  attentionTopRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  attentionActions: { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 14 },
  attentionDoneBtn: { flex: 1, minHeight: 44, borderRadius: 9999, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 7, paddingHorizontal: 14 },
  attentionDoneText: { fontFamily: 'Inter_800ExtraBold', fontSize: 14 },
  attentionDeleteBtn: { minWidth: 44, minHeight: 44, borderRadius: 9999, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
'@

if (-not [regex]::IsMatch($content, "(?m)^\s*priorityCard:\s*\{")) {
  throw "Could not find priorityCard style insertion point."
}
$content = [regex]::Replace($content, "(?m)^\s*priorityCard:\s*\{", $styles + '$&', 1)

[System.IO.File]::WriteAllText($FeedFile, $content, $Utf8NoBom)

Set-Location $FrontendPath
npm run verify

if ($LASTEXITCODE -ne 0) {
  Write-Host "Verification failed. Not committing." -ForegroundColor Red
  exit $LASTEXITCODE
}

Set-Location $RepoPath

git add "frontend/app/(tabs)/feed.tsx"
git commit -m "Make feed attention cards actionable"
git push origin $BranchName

Write-Host "Feed board refinement committed and pushed." -ForegroundColor Green
