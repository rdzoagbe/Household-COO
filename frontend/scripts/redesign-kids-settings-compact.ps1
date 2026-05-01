# Household COO - Compact Kids + Settings redesign
# Reduces scroll fatigue by adding segmented views and tighter premium layouts.

$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\TheKwekuRO\Documents\Household-COO"
$FrontendPath = Join-Path $RepoPath "frontend"
$KidsFile = Join-Path $FrontendPath "app\(tabs)\kids.tsx"
$SettingsFile = Join-Path $FrontendPath "app\(tabs)\settings.tsx"
$BranchName = "feature/vault-board-2"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-AppFile([string]$Path) {
  if (!(Test-Path $Path)) { throw "File not found: $Path" }
  $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
  return $text.Replace("`r`n", "`n").Replace("`r", "`n")
}

function Write-AppFile([string]$Path, [string]$Text) {
  $clean = [regex]::Replace($Text, "\n{3,}", "`n`n")
  [System.IO.File]::WriteAllText($Path, $clean.Replace("`n", "`r`n"), $Utf8NoBom)
}

function Insert-Once {
  param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][string]$Needle,
    [Parameter(Mandatory=$true)][string]$Insert,
    [Parameter(Mandatory=$true)][string]$Guard
  )
  if ($Text.Contains($Guard)) { return $Text }
  $idx = $Text.IndexOf($Needle)
  if ($idx -lt 0) { throw "Could not find insertion marker: $Needle" }
  return $Text.Insert($idx + $Needle.Length, $Insert)
}

function Replace-Once {
  param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][string]$Old,
    [Parameter(Mandatory=$true)][string]$New
  )
  $idx = $Text.IndexOf($Old)
  if ($idx -lt 0) { throw "Could not find replacement marker: $Old" }
  return $Text.Substring(0, $idx) + $New + $Text.Substring($idx + $Old.Length)
}

function Wrap-Between {
  param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][string]$StartMarker,
    [Parameter(Mandatory=$true)][string]$EndMarker,
    [Parameter(Mandatory=$true)][string]$OpenWrap,
    [Parameter(Mandatory=$true)][string]$CloseWrap,
    [Parameter(Mandatory=$true)][string]$Guard
  )
  if ($Text.Contains($Guard)) { return $Text }
  $start = $Text.IndexOf($StartMarker)
  if ($start -lt 0) { throw "Could not find wrap start: $StartMarker" }
  $end = $Text.IndexOf($EndMarker, $start + $StartMarker.Length)
  if ($end -lt 0) { throw "Could not find wrap end: $EndMarker" }
  return $Text.Substring(0, $start) + $OpenWrap + $Text.Substring($start, $end - $start) + $CloseWrap + $Text.Substring($end)
}

Set-Location $RepoPath

git fetch origin
git switch $BranchName
git pull origin $BranchName

# -----------------------------------------------------------------------------
# Kids page segmented redesign
# -----------------------------------------------------------------------------
$kids = Read-AppFile $KidsFile

if ($kids -notmatch "type KidsView") {
  $kids = $kids.Replace("type StarMode = 'add' | 'remove';", "type StarMode = 'add' | 'remove';`ntype KidsView = 'overview' | 'rewards' | 'activity';")
}

if ($kids -notmatch "activeKidsView") {
  $kids = $kids.Replace("  const [selectedChild, setSelectedChild] = useState<string | null>(null);", "  const [selectedChild, setSelectedChild] = useState<string | null>(null);`n  const [activeKidsView, setActiveKidsView] = useState<KidsView>('overview');")
}

$kidsTabs = @'

              <View style={[styles.kidsSegmentWrap, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
                {([
                  { key: 'overview', label: 'Overview' },
                  { key: 'rewards', label: 'Rewards' },
                  { key: 'activity', label: 'Activity' },
                ] as const).map((item) => {
                  const active = activeKidsView === item.key;
                  return (
                    <PressScale key={item.key} onPress={() => setActiveKidsView(item.key)} style={[styles.kidsSegmentBtn, active && { backgroundColor: theme.colors.primary }]}>
                      <Text style={[styles.kidsSegmentText, { color: active ? theme.colors.primaryText : theme.colors.textMuted }]}>{item.label}</Text>
                    </PressScale>
                  );
                })}
              </View>
'@

$kids = Insert-Once -Text $kids -Needle "              </View>`n`n              <View style={styles.statRow}>" -Insert $kidsTabs -Guard "activeKidsView === item.key"
$kids = $kids.Replace("              <View style={styles.statRow}>", "              {activeKidsView === 'overview' ? (`n              <>`n              <View style={styles.statRow}>")
$kids = $kids.Replace("              <View style={[styles.rewardShopShell, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}>" , "              </>`n              ) : null}`n`n              {activeKidsView === 'rewards' ? (`n              <View style={[styles.rewardShopShell, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}>" )

$kidsActivity = @'
              ) : null}

              {activeKidsView === 'activity' ? (
                <GlassCard style={styles.historyCard}>
                  <View style={styles.sectionHeader}>
                    <View style={styles.sectionRowInline}>
                      <History color={theme.colors.textMuted} size={16} />
                      <Text style={[styles.sectionLabel, { color: theme.colors.textMuted }]}>Activity log</Text>
                    </View>
                  </View>
                  {historyLoading ? (
                    <Text style={[styles.emptyMini, { color: theme.colors.textMuted }]}>Loading activity...</Text>
                  ) : historyItems.length === 0 ? (
                    <Text style={[styles.emptyMini, { color: theme.colors.textMuted }]}>No activity yet.</Text>
                  ) : (
                    historyItems.slice(0, 10).map((item) => {
                      const positive = item.delta > 0;
                      return (
                        <View key={`activity-tab-${item.transaction_id}`} style={styles.activityRow}>
                          <Text style={[styles.activityDelta, { color: positive ? theme.colors.success : '#EF4444' }]}>
                            {positive ? '+' : ''}{item.delta}
                          </Text>
                          <View style={{ flex: 1 }}>
                            <Text style={[styles.activityReason, { color: theme.colors.text }]} numberOfLines={1}>{item.reason || 'Star adjustment'}</Text>
                            <Text style={[styles.activityDate, { color: theme.colors.textMuted }]}>{formatActivityDate(item.created_at)}</Text>
                          </View>
                        </View>
                      );
                    })
                  )}
                </GlassCard>
              ) : null}

'@
$kids = Replace-Once -Text $kids -Old "`n`n              <View style={styles.tip}>" -New ($kidsActivity + "              <View style={styles.tip}>")

if ($kids -notmatch "kidsSegmentWrap") {
  $kidsStyles = @'
  kidsSegmentWrap: { minHeight: 48, borderRadius: 9999, borderWidth: 1, padding: 6, flexDirection: 'row', gap: 6, marginBottom: 14 },
  kidsSegmentBtn: { flex: 1, minHeight: 36, borderRadius: 9999, alignItems: 'center', justifyContent: 'center' },
  kidsSegmentText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
'@
  $kids = $kids.Replace("const styles = StyleSheet.create({`n", "const styles = StyleSheet.create({`n" + $kidsStyles)
}

# Tighten the Kids page vertically without changing the premium style.
$kids = $kids.Replace("scroll: { paddingHorizontal: 24, paddingTop: 10", "scroll: { paddingHorizontal: 20, paddingTop: 8")
$kids = $kids.Replace("marginBottom: 20", "marginBottom: 14")
$kids = $kids.Replace("marginBottom: 22", "marginBottom: 14")
$kids = $kids.Replace("marginTop: 24", "marginTop: 14")
$kids = $kids.Replace("minHeight: 82", "minHeight: 58")

Write-AppFile $KidsFile $kids

# -----------------------------------------------------------------------------
# Settings page grouped tab redesign
# -----------------------------------------------------------------------------
$settings = Read-AppFile $SettingsFile

if ($settings -notmatch "type SettingsView") {
  $settings = $settings.Replace("function formatBytes(bytes?: number | null) {", "type SettingsView = 'plan' | 'alerts' | 'prefs' | 'family' | 'security';`n`nfunction formatBytes(bytes?: number | null) {")
}

if ($settings -notmatch "activeSettingsView") {
  $settings = $settings.Replace("  const [entitlements, setEntitlements] = useState<Entitlements | null>(null);", "  const [entitlements, setEntitlements] = useState<Entitlements | null>(null);`n  const [activeSettingsView, setActiveSettingsView] = useState<SettingsView>('plan');")
}

$settingsTabs = @'

          <View style={[styles.settingsSegmentWrap, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}> 
            {([
              { key: 'plan', label: 'Plan' },
              { key: 'alerts', label: 'Alerts' },
              { key: 'prefs', label: 'Prefs' },
              { key: 'family', label: 'Family' },
              { key: 'security', label: 'Security' },
            ] as const).map((item) => {
              const active = activeSettingsView === item.key;
              return (
                <PressScale key={item.key} onPress={() => setActiveSettingsView(item.key)} style={[styles.settingsSegmentBtn, active && { backgroundColor: theme.colors.primary }]}>
                  <Text style={[styles.settingsSegmentText, { color: active ? theme.colors.primaryText : theme.colors.textMuted }]}>{item.label}</Text>
                </PressScale>
              );
            })}
          </View>
'@
$settings = Insert-Once -Text $settings -Needle "          </GlassCard>`n`n          <SectionTitle icon={<ShieldCheck" -Insert $settingsTabs -Guard "activeSettingsView === item.key"

$settings = Wrap-Between -Text $settings -StartMarker "          <SectionTitle icon={<ShieldCheck" -EndMarker "          <SectionTitle icon={<Bell" -OpenWrap "          {activeSettingsView === 'plan' ? (`n          <>`n" -CloseWrap "          </>`n          ) : null}`n`n" -Guard "activeSettingsView === 'plan'"
$settings = Wrap-Between -Text $settings -StartMarker "          <SectionTitle icon={<Bell" -EndMarker "          <SectionTitle icon={<Globe" -OpenWrap "          {activeSettingsView === 'alerts' ? (`n          <>`n" -CloseWrap "          </>`n          ) : null}`n`n" -Guard "activeSettingsView === 'alerts'"
$settings = Wrap-Between -Text $settings -StartMarker "          <SectionTitle icon={<Globe" -EndMarker "          <SectionTitle icon={<Users" -OpenWrap "          {activeSettingsView === 'prefs' ? (`n          <>`n" -CloseWrap "          </>`n          ) : null}`n`n" -Guard "activeSettingsView === 'prefs'"
$settings = Wrap-Between -Text $settings -StartMarker "          <SectionTitle icon={<Users" -EndMarker "          <SectionTitle icon={<Lock" -OpenWrap "          {activeSettingsView === 'family' ? (`n          <>`n" -CloseWrap "          </>`n          ) : null}`n`n" -Guard "activeSettingsView === 'family'"
$settings = Wrap-Between -Text $settings -StartMarker "          <SectionTitle icon={<Lock" -EndMarker "          <View style={{ height: 150 }} />" -OpenWrap "          {activeSettingsView === 'security' ? (`n          <>`n" -CloseWrap "          </>`n          ) : null}`n`n" -Guard "activeSettingsView === 'security'"

if ($settings -notmatch "settingsSegmentWrap") {
  $settingsStyles = @'
  settingsSegmentWrap: { minHeight: 48, borderRadius: 9999, borderWidth: 1, padding: 6, flexDirection: 'row', gap: 5, marginBottom: 14 },
  settingsSegmentBtn: { flex: 1, minHeight: 36, borderRadius: 9999, alignItems: 'center', justifyContent: 'center' },
  settingsSegmentText: { fontFamily: 'Inter_800ExtraBold', fontSize: 11 },
'@
  $settings = $settings.Replace("const styles = StyleSheet.create({`n", "const styles = StyleSheet.create({`n" + $settingsStyles)
}

# Tighten the Settings page vertically.
$settings = $settings.Replace("scroll: { paddingHorizontal: 20, paddingTop: 34, paddingBottom: 190 }", "scroll: { paddingHorizontal: 20, paddingTop: 24, paddingBottom: 150 }")
$settings = $settings.Replace("fontSize: 38", "fontSize: 34")
$settings = $settings.Replace("marginBottom: 22", "marginBottom: 14")
$settings = $settings.Replace("marginTop: 26", "marginTop: 14")
$settings = $settings.Replace("marginBottom: 14", "marginBottom: 10")
$settings = $settings.Replace("minHeight: 104", "minHeight: 82")
$settings = $settings.Replace("minHeight: 82", "minHeight: 58")
$settings = $settings.Replace("marginVertical: 18", "marginVertical: 12")

Write-AppFile $SettingsFile $settings

Set-Location $FrontendPath
npm run verify

if ($LASTEXITCODE -ne 0) {
  Write-Host "Verification failed. Not committing." -ForegroundColor Red
  exit $LASTEXITCODE
}

Set-Location $RepoPath

git add "frontend/app/(tabs)/kids.tsx" "frontend/app/(tabs)/settings.tsx"

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
  Write-Host "No Kids/Settings redesign changes to commit." -ForegroundColor Yellow
  exit 0
}

git commit -m "Compact Kids and Settings pages"
git push origin $BranchName

Write-Host "Kids and Settings compact redesign committed and pushed." -ForegroundColor Green
