# Household COO - Repair Kids reward idea cards after bad JSX insertion
# This fixes the parse error around the reward idea testID, restores icons using safe Unicode code points,
# verifies the app, commits only kids.tsx, and pushes the fix branch.

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

# Restore the constants with encoding-safe icons. This avoids Windows PowerShell emoji mojibake.
$constants = @'
const DEFAULT_REWARD_ICON = String.fromCodePoint(0x1F381);

const REWARD_IDEAS = [
  { title: 'Pizza night', cost_stars: 50, icon: String.fromCodePoint(0x1F355) },
  { title: 'Movie night', cost_stars: 75, icon: String.fromCodePoint(0x1F3AC) },
  { title: 'Ice cream treat', cost_stars: 40, icon: String.fromCodePoint(0x1F366) },
  { title: 'Game time', cost_stars: 60, icon: String.fromCodePoint(0x1F3AE) },
] as const;

const ICON_LIBRARY: { match: string[]; icons: string[] }[] = [
  { match: ['pizza', 'dinner', 'restaurant', 'food'], icons: [String.fromCodePoint(0x1F355), String.fromCodePoint(0x1F37D), String.fromCodePoint(0x1F389), String.fromCodePoint(0x1F354)] },
  { match: ['movie', 'cinema', 'film'], icons: [String.fromCodePoint(0x1F3AC), String.fromCodePoint(0x1F37F), String.fromCodePoint(0x1F39F), String.fromCodePoint(0x2B50)] },
  { match: ['ice', 'cream', 'sweet', 'cake', 'cupcake', 'dessert'], icons: [String.fromCodePoint(0x1F366), String.fromCodePoint(0x1F9C1), String.fromCodePoint(0x1F370), String.fromCodePoint(0x1F369)] },
  { match: ['game', 'gaming', 'playstation', 'xbox', 'switch'], icons: [String.fromCodePoint(0x1F3AE), String.fromCodePoint(0x1F579), String.fromCodePoint(0x1F3C6), String.fromCodePoint(0x26A1)] },
  { match: ['park', 'outside', 'walk', 'trip'], icons: [String.fromCodePoint(0x1F333), String.fromCodePoint(0x1F6DD), String.fromCodePoint(0x2600), String.fromCodePoint(0x1F6B2)] },
  { match: ['book', 'reading', 'story'], icons: [String.fromCodePoint(0x1F4DA), String.fromCodePoint(0x1F4D6), String.fromCodePoint(0x2728), String.fromCodePoint(0x1F3C5)] },
  { match: ['toy', 'lego', 'gift'], icons: [String.fromCodePoint(0x1F9F8), String.fromCodePoint(0x1F381), String.fromCodePoint(0x1FA80), String.fromCodePoint(0x2728)] },
  { match: ['sleepover', 'friend', 'party'], icons: [String.fromCodePoint(0x1F389), String.fromCodePoint(0x1F3E0), String.fromCodePoint(0x1F9C3), String.fromCodePoint(0x2B50)] },
];
'@

$content = [regex]::Replace(
  $content,
  "const DEFAULT_REWARD_ICON[\s\S]*?function suggestedIcons",
  $constants + "`r`n`r`nfunction suggestedIcons",
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# Restore the suggested icon fallback if it was corrupted by Windows encoding.
$content = [regex]::Replace(
  $content,
  "return matches\?\.icons \|\| \[[^\]]*\];",
  "return matches?.icons || [DEFAULT_REWARD_ICON, String.fromCodePoint(0x2B50), String.fromCodePoint(0x1F389), String.fromCodePoint(0x1F3C6), String.fromCodePoint(0x2728), String.fromCodePoint(0x1F355), String.fromCodePoint(0x1F3AC), String.fromCodePoint(0x1F3AE)];"
)

# Fix the bad JSX line inserted by the previous script.
$content = $content.Replace("testID={\reward-idea-}", "testID={idea.title}")

# Repair mojibake text created by the previous PowerShell write.
$content = $content.Replace("Reward good habits Â· keep it fair", "Reward good habits - keep it fair")
$content = $content.Replace("âˆ’ Stars", "- Stars")

# Make sure the reward ideas block exists. If the previous insertion failed, insert a clean one.
if ($content -notmatch "styles\.rewardIdeaGrid") {
$ideaBlock = @'

              <View style={styles.rewardIdeaGrid}>
                {REWARD_IDEAS.map((idea) => (
                  <PressScale
                    key={idea.title}
                    testID={idea.title}
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
'@
  $marker = "              {rewards.length === 0 ? ("
  if (!$content.Contains($marker)) {
    throw "Could not find Reward Shop insertion marker."
  }
  $content = $content.Replace($marker, $ideaBlock + "`r`n" + $marker)
}

# Make sure styles exist.
if ($content -notmatch "rewardIdeaCard:") {
$styleBlock = @'
  rewardIdeaGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 14 },
  rewardIdeaCard: { flexGrow: 1, flexBasis: '47%', minHeight: 74, borderRadius: 22, borderWidth: 1, paddingHorizontal: 12, paddingVertical: 12, flexDirection: 'row', alignItems: 'center', gap: 10 },
  rewardIdeaIcon: { fontSize: 26 },
  rewardIdeaTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 14, lineHeight: 18 },
  rewardIdeaCostRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 4 },
  rewardIdeaCost: { fontFamily: 'Inter_700Bold', fontSize: 12 },
'@
  $styleMarker = "  rewardCard: { marginBottom:"
  $index = $content.IndexOf($styleMarker)
  if ($index -lt 0) {
    throw "Could not find rewardCard style insertion marker."
  }
  $content = $content.Insert($index, $styleBlock)
}

[System.IO.File]::WriteAllText($KidsFile, $content, $Utf8NoBom)

Set-Location $FrontendPath
npm run verify
if ($LASTEXITCODE -ne 0) {
  throw "npm run verify failed. Not committing."
}

Set-Location $RepoPath
git status --short

git add "frontend/app/(tabs)/kids.tsx"

$cached = git diff --cached --name-only
if (-not $cached) {
  Write-Host "No kids.tsx changes to commit." -ForegroundColor Yellow
} else {
  git commit -m "Repair Kids reward idea cards"
  git push origin $BranchName
}

Write-Host "Kids reward idea cards repaired and pushed." -ForegroundColor Green
Write-Host "Run: cd `"$FrontendPath`"; npx expo start --clear" -ForegroundColor Cyan
