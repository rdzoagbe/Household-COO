# Household COO - Polish Kids Reward Shop
# Run from repo root or frontend. It patches kids.tsx, verifies, commits, and pushes.

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

$content = [System.IO.File]::ReadAllText($KidsFile, [System.Text.Encoding]::UTF8)

# Repair small syntax/style glitches from earlier patch attempts.
$content = [regex]::Replace($content, "(?m)(rewardIdeaCost\s*:\s*\{[^\r\n]*\},)\s*(rewardCard\s*:\s*\{)", '$1' + "`r`n  " + '$2')
$content = [regex]::Replace($content, "(?m)(editText\s*:\s*\{[^\r\n]*\},)\s*(sheet\s*:\s*\{)", '$1' + "`r`n  " + '$2')
$content = $content.Replace("Reward good habits Â· keep it fair", "Reward good habits - keep it fair")
$content = $content.Replace("Reward good habits · keep it fair", "Reward good habits - keep it fair")
$content = $content.Replace("<View style={{ height: 220 }} />", "<View style={{ height: 170 }} />")
$content = $content.Replace("<View style={{ height: 190 }} />", "<View style={{ height: 170 }} />")

# Suggested icon chips should update the selected icon directly.
$content = [regex]::Replace(
  $content,
  '<PressScale key=\{icon\} testID=\{`reward-icon-\$\{icon\}`\}[^>]*>',
  '<PressScale key={icon} testID={`reward-icon-${icon}`} onPress={() => setRewardIcon(icon)} style={[styles.iconChip, { backgroundColor: rewardIcon === icon ? theme.colors.accentSoft : theme.colors.bgSoft, borderColor: rewardIcon === icon ? theme.colors.accent : theme.colors.cardBorder }]}>'
)

$rewardShop = @'
              <View style={[styles.rewardShopShell, { backgroundColor: theme.colors.card, borderColor: theme.colors.cardBorder }]}>
                <View style={styles.rewardShopHeaderCard}>
                  <View style={[styles.rewardShopBadge, { backgroundColor: theme.colors.accentSoft, borderColor: theme.colors.cardBorder }]}>
                    <Gift color={theme.colors.accent} size={18} />
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.rewardShopTitle, { color: theme.colors.text }]}>Reward Shop</Text>
                    <Text style={[styles.rewardShopSubtitle, { color: theme.colors.textMuted }]}>Beautiful little goals to keep good habits exciting.</Text>
                  </View>
                  <View style={[styles.rewardShopCountPill, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>
                    <Star color={theme.colors.accent} size={12} fill={theme.colors.accent} />
                    <Text style={[styles.rewardShopCountText, { color: theme.colors.text }]}>{affordableRewards}/{totalRewards}</Text>
                  </View>
                </View>

                <Text style={[styles.rewardIdeasSub, { color: theme.colors.textMuted }]}>Quick reward ideas</Text>
                <View style={styles.rewardIdeaGrid}>
                  {REWARD_IDEAS.map((idea) => (
                    <PressScale key={idea.title} testID={idea.title} onPress={() => { setRewardMode('create'); setEditingReward(null); setRewardTitle(idea.title); setRewardCost(String(idea.cost_stars)); setRewardIcon(idea.icon); setShowRewardSheet(true); }} style={[styles.rewardIdeaCard, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder, shadowColor: theme.colors.shadow }]}>
                      <View style={[styles.rewardIdeaIconWrap, { backgroundColor: theme.colors.accentSoft, borderColor: theme.colors.cardBorder }]}>
                        <Text style={styles.rewardIdeaIcon}>{idea.icon}</Text>
                      </View>
                      <View style={{ flex: 1 }}>
                        <Text style={[styles.rewardIdeaTitle, { color: theme.colors.text }]} numberOfLines={1}>{idea.title}</Text>
                        <View style={styles.rewardIdeaCostRow}>
                          <Star color={theme.colors.accent} size={11} fill={theme.colors.accent} />
                          <Text style={[styles.rewardIdeaCost, { color: theme.colors.textMuted }]}>{idea.cost_stars} {t('stars')}</Text>
                        </View>
                        <Text style={[styles.rewardIdeaHint, { color: theme.colors.textMuted }]}>Tap to create</Text>
                      </View>
                    </PressScale>
                  ))}
                </View>

                {rewards.length === 0 ? (
                  <EmptyState title={t('no_rewards')} message="Create a small reward to make chores feel more motivating." actionLabel="Add Reward" onAction={openCreateReward} />
                ) : (
                  <View style={styles.rewardList}>
                    {rewards.map((reward) => {
                      const affordable = stars >= reward.cost_stars;
                      const starsNeeded = Math.max(0, reward.cost_stars - stars);
                      const progressWidth = `${Math.min(100, Math.round((stars / reward.cost_stars) * 100))}%`;

                      return (
                        <GlassCard key={reward.reward_id} style={[styles.rewardCard, { borderColor: affordable ? theme.colors.accent : theme.colors.cardBorder }]}>
                          <View style={styles.rewardTopRow}>
                            <View style={[styles.rewardIconWrap, { backgroundColor: theme.colors.accentSoft, borderColor: theme.colors.cardBorder }]}>
                              <Text style={styles.rewardIcon}>{reward.icon || DEFAULT_REWARD_ICON}</Text>
                            </View>
                            <View style={{ flex: 1 }}>
                              <Text style={[styles.rewardTitle, { color: theme.colors.text }]} numberOfLines={2}>{reward.title}</Text>
                              <View style={styles.rewardMetaRow}>
                                <View style={[styles.rewardCostPill, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>
                                  <Star color={theme.colors.accent} size={12} fill={theme.colors.accent} />
                                  <Text style={[styles.rewardCost, { color: theme.colors.textMuted }]}>{reward.cost_stars} {t('stars')}</Text>
                                </View>
                                <Text style={[styles.rewardAvailability, { color: affordable ? theme.colors.success : theme.colors.textMuted }]}>{affordable ? 'Ready to redeem' : `${starsNeeded} more needed`}</Text>
                              </View>
                            </View>
                          </View>
                          <View style={[styles.rewardProgressTrack, { backgroundColor: theme.colors.bgSoft }]}>
                            <View style={[styles.rewardProgressFill, { width: progressWidth as any, backgroundColor: theme.colors.accent }]} />
                          </View>
                          <View style={styles.rewardActions}>
                            <PressScale testID={`redeem-${reward.reward_id}`} onPress={() => redeem(reward)} disabled={!affordable} style={[styles.redeemBtn, { backgroundColor: theme.colors.primary }, !affordable && { opacity: 0.45 }]}>
                              <Text style={[styles.redeemText, { color: theme.colors.primaryText }]}>{affordable ? t('redeem') : 'Not enough stars'}</Text>
                            </PressScale>
                            <PressScale testID={`edit-reward-${reward.reward_id}`} onPress={() => openEditReward(reward)} style={[styles.editBtn, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>
                              <Pencil color={theme.colors.textMuted} size={15} />
                              <Text style={[styles.editText, { color: theme.colors.textMuted }]}>Edit</Text>
                            </PressScale>
                          </View>
                        </GlassCard>
                      );
                    })}
                  </View>
                )}
              </View>

              <View style={styles.tip}>
'@

$pattern = "(?s)\s*<View style=\{styles\.sectionRow\}>\s*<Gift[\s\S]*?<Text style=\{\[styles\.sectionLabel, \{ color: theme\.colors\.textMuted \}\]\}>Reward Shop</Text>\s*</View>[\s\S]*?<View style=\{styles\.tip\}>"
if (-not [regex]::IsMatch($content, $pattern)) { throw "Reward Shop block not found." }
$content = [regex]::Replace($content, $pattern, "`r`n" + $rewardShop, 1)

$styleNames = 'rewardShopShell','rewardShopHeaderCard','rewardShopBadge','rewardShopTitle','rewardShopSubtitle','rewardShopCountPill','rewardShopCountText','rewardIdeasHeader','rewardIdeasTitle','rewardIdeasSub','rewardIdeaGrid','rewardIdeaCard','rewardIdeaIconWrap','rewardIdeaIcon','rewardIdeaTitle','rewardIdeaCostRow','rewardIdeaCost','rewardIdeaHint','rewardList','rewardCard','rewardTopRow','rewardRow','rewardIconWrap','rewardIcon','rewardTitle','rewardMetaRow','rewardCostPill','rewardCostRow','rewardCost','rewardAvailability','rewardProgressTrack','rewardProgressFill','rewardActions','redeemBtn','redeemText','editBtn','editText'
foreach ($styleName in $styleNames) { $content = [regex]::Replace($content, "(?m)^\s*$styleName\s*:\s*.*\r?\n", "") }

$styles = @'
  rewardShopShell: { borderWidth: 1, borderRadius: 32, padding: 16, marginTop: 6, marginBottom: 16, shadowColor: '#000', shadowOffset: { width: 0, height: 14 }, shadowOpacity: 0.08, shadowRadius: 22, elevation: 4 },
  rewardShopHeaderCard: { flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 16 },
  rewardShopBadge: { width: 48, height: 48, borderRadius: 18, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  rewardShopTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 22, lineHeight: 27, letterSpacing: -0.4 },
  rewardShopSubtitle: { fontFamily: 'Inter_500Medium', fontSize: 13, lineHeight: 18, marginTop: 3 },
  rewardShopCountPill: { flexDirection: 'row', alignItems: 'center', gap: 5, borderRadius: 9999, borderWidth: 1, paddingHorizontal: 9, paddingVertical: 7 },
  rewardShopCountText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
  rewardIdeasSub: { fontFamily: 'Inter_700Bold', fontSize: 12, lineHeight: 16, marginBottom: 10, textTransform: 'uppercase', letterSpacing: 0.9 },
  rewardIdeaGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 16 },
  rewardIdeaCard: { flexGrow: 1, flexBasis: '47%', minHeight: 92, borderRadius: 24, borderWidth: 1, paddingHorizontal: 12, paddingVertical: 12, flexDirection: 'row', alignItems: 'center', gap: 10, shadowOffset: { width: 0, height: 8 }, shadowOpacity: 0.06, shadowRadius: 14, elevation: 2 },
  rewardIdeaIconWrap: { width: 52, height: 52, borderRadius: 18, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  rewardIdeaIcon: { fontSize: 28 },
  rewardIdeaTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 14, lineHeight: 18 },
  rewardIdeaCostRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 4 },
  rewardIdeaCost: { fontFamily: 'Inter_700Bold', fontSize: 12 },
  rewardIdeaHint: { fontFamily: 'Inter_600SemiBold', fontSize: 11, lineHeight: 15, marginTop: 6 },
  rewardList: { gap: 12 },
  rewardCard: { padding: 16, borderRadius: 28, borderWidth: 1 },
  rewardTopRow: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  rewardIconWrap: { width: 58, height: 58, borderRadius: 20, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  rewardIcon: { fontSize: 30 },
  rewardTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 18, lineHeight: 23 },
  rewardMetaRow: { marginTop: 8, gap: 7 },
  rewardCostPill: { alignSelf: 'flex-start', flexDirection: 'row', alignItems: 'center', gap: 6, borderWidth: 1, borderRadius: 9999, paddingHorizontal: 10, paddingVertical: 6 },
  rewardCost: { fontFamily: 'Inter_700Bold', fontSize: 12 },
  rewardAvailability: { fontFamily: 'Inter_700Bold', fontSize: 12, lineHeight: 16 },
  rewardProgressTrack: { height: 8, borderRadius: 9999, overflow: 'hidden', marginTop: 16 },
  rewardProgressFill: { height: 8, borderRadius: 9999 },
  rewardActions: { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 15 },
  redeemBtn: { flex: 1, minHeight: 46, borderRadius: 18, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 14 },
  redeemText: { fontFamily: 'Inter_800ExtraBold', fontSize: 14 },
  editBtn: { minHeight: 46, borderRadius: 18, borderWidth: 1, paddingHorizontal: 14, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 6 },
  editText: { fontFamily: 'Inter_800ExtraBold', fontSize: 13 },
'@

if (-not [regex]::IsMatch($content, "(?m)^\s*sheet:\s*\{")) { throw "Style insertion point not found." }
$content = [regex]::Replace($content, "(?m)^\s*sheet:\s*\{", $styles + '$&', 1)

[System.IO.File]::WriteAllText($KidsFile, $content, $Utf8NoBom)
Set-Location $FrontendPath
npm run verify
if ($LASTEXITCODE -ne 0) { Write-Host "Verification failed. Not committing." -ForegroundColor Red; exit $LASTEXITCODE }
Set-Location $RepoPath
git add "frontend/app/(tabs)/kids.tsx"
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host "No kids.tsx changes to commit." -ForegroundColor Yellow; exit 0 }
git commit -m "Polish Kids reward shop cards"
git push origin $BranchName
Write-Host "Kids Reward Shop polish committed and pushed." -ForegroundColor Green
