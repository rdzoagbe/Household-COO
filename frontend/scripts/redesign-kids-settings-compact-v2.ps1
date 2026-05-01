# Household COO - Compact Kids + Settings redesign v2
# Safe version: restores failed local edits, then uses conditional display styles instead of JSX wrapping.

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

function Replace-Required {
  param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][string]$Old,
    [Parameter(Mandatory=$true)][string]$New
  )
  if (-not $Text.Contains($Old)) { throw "Could not find required text: $Old" }
  return $Text.Replace($Old, $New)
}

Set-Location $RepoPath

git fetch origin
git switch $BranchName
git pull origin $BranchName

# Reset failed local edits from v1 while keeping the helper scripts from the branch.
git restore -- "frontend/app/(tabs)/kids.tsx" "frontend/app/(tabs)/settings.tsx"

# -----------------------------------------------------------------------------
# Kids: add Overview / Rewards / Activity segments and hide heavy sections by view
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

if ($kids -notmatch "kidsSegmentWrap") {
  $kids = Replace-Required -Text $kids -Old "              </View>`n`n              <View style={styles.statRow}>" -New ("              </View>" + $kidsTabs + "`n              <View style={[styles.statRow, activeKidsView !== 'overview' && styles.hiddenSection]}>")
} else {
  $kids = $kids.Replace("              <View style={styles.statRow}>", "              <View style={[styles.statRow, activeKidsView !== 'overview' && styles.hiddenSection]}>")
}

$kids = $kids.Replace("<GlassCard style={styles.historyCard}>", "<GlassCard style={[styles.historyCard, activeKidsView === 'rewards' && styles.hiddenSection]}>")
$kids = $kids.Replace("<View style={[styles.rewardShopShell, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}>" , "<View style={[styles.rewardShopShell, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }, activeKidsView !== 'rewards' && styles.hiddenSection]}>")

if ($kids -notmatch "hiddenSection:") {
  $kidsStyles = @'
  hiddenSection: { display: 'none' },
  kidsSegmentWrap: { minHeight: 48, borderRadius: 9999, borderWidth: 1, padding: 6, flexDirection: 'row', gap: 6, marginBottom: 14 },
  kidsSegmentBtn: { flex: 1, minHeight: 36, borderRadius: 9999, alignItems: 'center', justifyContent: 'center' },
  kidsSegmentText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
'@
  $kids = $kids.Replace("const styles = StyleSheet.create({`n", "const styles = StyleSheet.create({`n" + $kidsStyles)
}

$kids = $kids.Replace("scroll: { paddingHorizontal: 24, paddingTop: 10", "scroll: { paddingHorizontal: 20, paddingTop: 8")
$kids = $kids.Replace("marginBottom: 22", "marginBottom: 14")
$kids = $kids.Replace("marginTop: 24", "marginTop: 14")
$kids = $kids.Replace("minHeight: 82", "minHeight: 58")

Write-AppFile $KidsFile $kids

# -----------------------------------------------------------------------------
# Settings: add segmented settings groups and hide non-active groups by style
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

if ($settings -notmatch "settingsSegmentWrap") {
  $settings = Replace-Required -Text $settings -Old "          </GlassCard>`n`n          <SectionTitle icon={<ShieldCheck" -New ("          </GlassCard>" + $settingsTabs + "`n          <SectionTitle hidden={activeSettingsView !== 'plan'} icon={<ShieldCheck")
} else {
  $settings = $settings.Replace("          <SectionTitle icon={<ShieldCheck", "          <SectionTitle hidden={activeSettingsView !== 'plan'} icon={<ShieldCheck")
}

$settings = $settings.Replace("          <SectionTitle icon={<Bell", "          <SectionTitle hidden={activeSettingsView !== 'alerts'} icon={<Bell")
$settings = $settings.Replace("          <SectionTitle icon={<Globe", "          <SectionTitle hidden={activeSettingsView !== 'prefs'} icon={<Globe")
$settings = $settings.Replace("          <SectionTitle icon={<Users", "          <SectionTitle hidden={activeSettingsView !== 'family'} icon={<Users")
$settings = $settings.Replace("          <SectionTitle icon={<CalendarDays", "          <SectionTitle hidden={activeSettingsView !== 'family'} icon={<CalendarDays")
$settings = $settings.Replace("          <SectionTitle icon={<Lock", "          <SectionTitle hidden={activeSettingsView !== 'security'} icon={<Lock")

# Hide major cards by active group. These replacements are intentionally exact and conservative.
$settings = $settings.Replace("          <GlassCard>`n            <View style={styles.cardHeaderRow}>", "          <GlassCard style={activeSettingsView !== 'plan' && styles.hiddenSection}>`n            <View style={styles.cardHeaderRow}>")
$settings = $settings.Replace("          <GlassCard>`n            <SettingSwitch", "          <GlassCard style={activeSettingsView !== 'alerts' && styles.hiddenSection}>`n            <SettingSwitch")
$settings = $settings.Replace("          <GlassCard>`n            <View style={styles.preferenceHeader}>", "          <GlassCard style={activeSettingsView !== 'prefs' && styles.hiddenSection}>`n            <View style={styles.preferenceHeader}>")
$settings = $settings.Replace("          <GlassCard>`n            {members.length === 0", "          <GlassCard style={activeSettingsView !== 'family' && styles.hiddenSection}>`n            {members.length === 0")
$settings = $settings.Replace("          <GlassCard style={styles.topGap}>", "          <GlassCard style={[styles.topGap, activeSettingsView !== 'family' && styles.hiddenSection]}>")
$settings = $settings.Replace("          <GlassCard>`n            {calendarContacts.length === 0", "          <GlassCard style={activeSettingsView !== 'family' && styles.hiddenSection}>`n            {calendarContacts.length === 0")
$settings = $settings.Replace("          <GlassCard>`n            {childMembers.length === 0", "          <GlassCard style={activeSettingsView !== 'security' && styles.hiddenSection}>`n            {childMembers.length === 0")
$settings = $settings.Replace("          <PressScale testID=\"logout\" onPress={doLogout} style={styles.logoutBtn}>", "          <PressScale testID=\"logout\" onPress={doLogout} style={[styles.logoutBtn, activeSettingsView !== 'security' && styles.hiddenSection]}>")
$settings = $settings.Replace("<SecondaryButton label=\"Invite co-parent\" onPress={() => openInvite()} icon={<UserPlus color={theme.colors.text} size={20} />} />", "<SecondaryButton label=\"Invite co-parent\" onPress={() => openInvite()} icon={<UserPlus color={theme.colors.text} size={20} />} hidden={activeSettingsView !== 'family'} />")

# Allow SectionTitle and SecondaryButton to hide themselves.
$settings = $settings.Replace(
"function SectionTitle({ icon, label, color }: { icon: React.ReactNode; label: string; color: string }) {
  return <View style={styles.sectionRow}>{icon}<Text style={[styles.sectionLabel, { color }]}>{label}</Text></View>;
}",
"function SectionTitle({ icon, label, color, hidden }: { icon: React.ReactNode; label: string; color: string; hidden?: boolean }) {
  return <View style={[styles.sectionRow, hidden && styles.hiddenSection]}>{icon}<Text style={[styles.sectionLabel, { color }]}>{label}</Text></View>;
}")

$settings = $settings.Replace(
"function SecondaryButton({ label, onPress, testID, icon, compact }: { label: string; onPress: () => void; testID?: string; icon?: React.ReactNode; compact?: boolean }) {",
"function SecondaryButton({ label, onPress, testID, icon, compact, hidden }: { label: string; onPress: () => void; testID?: string; icon?: React.ReactNode; compact?: boolean; hidden?: boolean }) {")
$settings = $settings.Replace(
"style={[styles.secondaryButton, compact && styles.secondaryButtonCompact, { borderColor: theme.colors.cardBorder, backgroundColor: theme.colors.card }]}>",
"style={[styles.secondaryButton, compact && styles.secondaryButtonCompact, hidden && styles.hiddenSection, { borderColor: theme.colors.cardBorder, backgroundColor: theme.colors.card }]}>")

if ($settings -notmatch "settingsSegmentWrap") {
  throw "Settings tabs were not inserted."
}

if ($settings -notmatch "hiddenSection:") {
  $settingsStyles = @'
  hiddenSection: { display: 'none' },
  settingsSegmentWrap: { minHeight: 48, borderRadius: 9999, borderWidth: 1, padding: 6, flexDirection: 'row', gap: 5, marginBottom: 14 },
  settingsSegmentBtn: { flex: 1, minHeight: 36, borderRadius: 9999, alignItems: 'center', justifyContent: 'center' },
  settingsSegmentText: { fontFamily: 'Inter_800ExtraBold', fontSize: 11 },
'@
  $settings = $settings.Replace("const styles = StyleSheet.create({`n", "const styles = StyleSheet.create({`n" + $settingsStyles)
}

$settings = $settings.Replace("scroll: { paddingHorizontal: 20, paddingTop: 34, paddingBottom: 190 }", "scroll: { paddingHorizontal: 20, paddingTop: 24, paddingBottom: 150 }")
$settings = $settings.Replace("fontSize: 38", "fontSize: 34")
$settings = $settings.Replace("marginBottom: 22", "marginBottom: 14")
$settings = $settings.Replace("marginTop: 26", "marginTop: 14")
$settings = $settings.Replace("minHeight: 104", "minHeight: 82")
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
