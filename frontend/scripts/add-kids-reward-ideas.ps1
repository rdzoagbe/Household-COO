# Household COO - Add premium reward idea cards to the Kids screen
# Run from anywhere. It patches frontend/app/(tabs)/kids.tsx, verifies, commits, and pushes.

$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\TheKwekuRO\Documents\Household-COO"
$FrontendPath = Join-Path $RepoPath "frontend"
$KidsFile = Join-Path $FrontendPath "app\(tabs)\kids.tsx"
$BranchName = "fix/kids-premium-dark-default"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Set-Location $RepoPath

git fetch origin
git switch $BranchName
git pull origin $BranchName

if (!(Test-Path $KidsFile)) {
  throw "kids.tsx not found at $KidsFile"
}

$content = [System.IO.File]::ReadAllText($KidsFile, [System.Text.Encoding]::UTF8)

# 1) Add reward idea data. Use JS unicode escapes to avoid Windows PowerShell emoji encoding issues.
if ($content -notmatch "const REWARD_IDEAS") {
  $content = $content -replace "const DEFAULT_REWARD_ICON = '🎁';", @"
const DEFAULT_REWARD_ICON = '🎁';

const REWARD_IDEAS = [
  { title: 'Pizza night', cost_stars: 50, icon: '\u{1F355}' },
  { title: 'Movie night', cost_stars: 75, icon: '\u{1F3AC}' },
  { title: 'Ice cream treat', cost_stars: 40, icon: '\u{1F366}' },
  { title: 'Game time', cost_stars: 60, icon: '\u{1F3AE}' },
] as const;
"@
}

# 2) Add reward idea cards under the Reward Shop heading.
$ideaBlock = @"

              <View style={styles.rewardIdeaGrid}>
                {REWARD_IDEAS.map((idea) => (
                  <PressScale
                    key={idea.title}
                    testID={`reward-idea-${idea.title.toLowerCase().replace(/\s+/g, '-')}`}
                    onPress={() => {
                      setRewardMode('create');
                      setEditingReward(null);
                      setRewardTitle(idea.title);
                      setRewardCost(String(idea.cost_stars));
                      setRewardIcon(idea.icon);
                      setShowRewardSheet(true);
                    }}
                    style={[styles.rewardIdeaCard, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}
                  >
                    <Text style={styles.rewardIdeaIcon}>{idea.icon}</Text>
                    <View style={{ flex: 1 }}>
                      <Text style={[styles.rewardIdeaTitle, { color: theme.colors.text }]} numberOfLines={1}>{idea.title}</Text>
                      <View style={styles.rewardIdeaCostRow}>
                        <Star color={theme.colors.accent} size={11} fill={theme.colors.accent} />
                        <Text style={[styles.rewardIdeaCost, { color: theme.colors.textMuted }]}>{idea.cost_stars} {t('stars')}</Text>
                      </View>
                    </View>
                  </PressScale>
                ))}
              </View>
"@

if ($content -notmatch "styles\.rewardIdeaGrid") {
  $marker = "              {rewards.length === 0 ? ("
  if ($content.Contains($marker)) {
    $content = $content.Replace($marker, $ideaBlock + "`n" + $marker)
  } else {
    throw "Could not find Reward Shop insertion marker."
  }
}

# 3) Add styles.
$styleBlock = @"
  rewardIdeaGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 14 },
  rewardIdeaCard: { flexGrow: 1, flexBasis: '47%', minHeight: 74, borderRadius: 22, borderWidth: 1, paddingHorizontal: 12, paddingVertical: 12, flexDirection: 'row', alignItems: 'center', gap: 10 },
  rewardIdeaIcon: { fontSize: 26 },
  rewardIdeaTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 14, lineHeight: 18 },
  rewardIdeaCostRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 4 },
  rewardIdeaCost: { fontFamily: 'Inter_700Bold', fontSize: 12 },
"@

if ($content -notmatch "rewardIdeaCard:") {
  $styleMarker = "  rewardCard: { marginBottom:"
  $index = $content.IndexOf($styleMarker)
  if ($index -ge 0) {
    $content = $content.Insert($index, $styleBlock)
  } else {
    throw "Could not find rewardCard style insertion marker."
  }
}

# 4) Keep ESLint array type happy.
$content = $content -replace "const ICON_LIBRARY: Array<\{ match: string\[\]; icons: string\[\] \}> = \[", "const ICON_LIBRARY: { match: string[]; icons: string[] }[] = ["

[System.IO.File]::WriteAllText($KidsFile, $content, $Utf8NoBom)

Set-Location $FrontendPath
npm run verify

Set-Location $RepoPath
git status --short

git add "frontend/app/(tabs)/kids.tsx"

$hasChanges = git diff --cached --name-only
if (-not $hasChanges) {
  Write-Host "No changes to commit. Reward ideas may already be applied." -ForegroundColor Yellow
  exit 0
}

git commit -m "Add reward idea cards to Kids screen"
git push origin $BranchName

Write-Host "Reward idea cards added and pushed." -ForegroundColor Green
