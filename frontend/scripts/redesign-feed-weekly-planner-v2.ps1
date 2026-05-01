# Household COO - Redesign Feed Weekly Planner v2
# Promotes Next Up / This Week into a compact actionable weekly agenda.
# Removes Feed capture actions without relying on fragile JSX tag parsing.

$ErrorActionPreference = "Stop"

$RepoPath = "C:\Users\TheKwekuRO\Documents\Household-COO"
$FrontendPath = Join-Path $RepoPath "frontend"
$FeedFile = Join-Path $FrontendPath "app\(tabs)\feed.tsx"
$BranchName = "feature/vault-board-2"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Set-Location $RepoPath

git fetch origin
git switch $BranchName
git pull origin $BranchName

if (!(Test-Path $FeedFile)) {
  throw "feed.tsx not found at $FeedFile"
}

$content = [System.IO.File]::ReadAllText($FeedFile, [System.Text.Encoding]::UTF8)
$content = $content.Replace("`r`n", "`n").Replace("`r", "`n")
$content = $content.Replace("Â·", "·")
$content = [regex]::Replace($content, "\n{3,}", "`n`n")

# Clean the icon import block after previous automated edits.
$content = [regex]::Replace(
  $content,
  "(?s)import \{\s*ArrowRight,.*?UsersRound,\s*\} from 'lucide-react-native';",
@'
import {
  ArrowRight,
  Bell,
  CalendarDays,
  CheckCircle2,
  Clock3,
  FileText,
  ShieldCheck,
  Sparkles,
  Star,
  Trash2,
  UsersRound,
} from 'lucide-react-native';
'@.Trim(),
  1
)

# Remove capture/search entry from Feed.
$content = [regex]::Replace(
  $content,
  '(?s)\n\s*<PressScale\s+testID="command-capture"[\s\S]*?</PressScale>\s*',
  "`n",
  1
)

# Remove Quick Actions title and row from Feed.
$content = [regex]::Replace(
  $content,
  '(?s)\n\s*<View style=\{styles\.section\}>\s*<Text[^>]*>\{labels\.quickActions\}</Text>\s*</View>\s*',
  "`n",
  1
)
$content = [regex]::Replace(
  $content,
  '(?s)\n\s*<View style=\{styles\.actionRow\}>[\s\S]*?</View>\s*',
  "`n",
  1
)

# Remove capture modals from this screen.
$content = [regex]::Replace($content, '(?s)\n\s*<CameraCaptureModal[\s\S]*?\n\s*/>\s*', "`n", 1)
$content = [regex]::Replace($content, '(?s)\n\s*<VoiceCaptureModal[\s\S]*?\n\s*/>\s*', "`n", 1)
$content = [regex]::Replace($content, '(?s)\n\s*<AddCardModal[\s\S]*?\n\s*/>\s*', "`n", 1)

# Remove unused imports and capture state/function.
$content = [regex]::Replace($content, "(?m)^import \{ SmartCard \} from '../../src/components/SmartCard';\s*\n", "")
$content = [regex]::Replace($content, "(?m)^import \{ AddCardModal \} from '../../src/components/AddCardModal';\s*\n", "")
$content = [regex]::Replace($content, "(?m)^import \{ VoiceCaptureModal \} from '../../src/components/VoiceCaptureModal';\s*\n", "")
$content = [regex]::Replace($content, "(?m)^import \{ CameraCaptureModal \} from '../../src/components/CameraCaptureModal';\s*\n", "")
$content = $content.Replace("import { api, Card, CardType, FamilyMember } from '../../src/api';", "import { api, Card, FamilyMember } from '../../src/api';")
$content = [regex]::Replace($content, "(?s)interface VoiceDraft \{.*?\}\s*\n\s*type Labels =", "type Labels =", 1)
$content = [regex]::Replace($content, "(?m)^\s*const \[showAdd, setShowAdd\] = useState\(false\);\s*\n", "")
$content = [regex]::Replace($content, "(?m)^\s*const \[showVoice, setShowVoice\] = useState\(false\);\s*\n", "")
$content = [regex]::Replace($content, "(?m)^\s*const \[showCamera, setShowCamera\] = useState\(false\);\s*\n", "")
$content = [regex]::Replace($content, "(?m)^\s*const \[addSource, setAddSource\] = useState<[^\n]+\n", "")
$content = [regex]::Replace($content, "(?m)^\s*const \[voiceDraft, setVoiceDraft\] = useState<[^\n]+\n", "")
$content = [regex]::Replace($content, "(?s)\n\s*const openManual = \(\) => \{.*?\n\s*\};\s*\n", "`n", 1)

# Make Next Up cover the next 7 days instead of only 24 hours.
$content = $content.Replace("    const tomorrow = now + 24 * 60 * 60 * 1000;", "    const weekEnd = now + 7 * 24 * 60 * 60 * 1000;")
$content = [regex]::Replace($content, "return Boolean\(time && time >= now && time <= (tomorrow|weekEnd)\);", "return Boolean(time && time >= now && time <= weekEnd);", 1)

# Add Snooze action.
if ($content -notmatch "const snooze = async") {
  $snoozeBlock = @'

  const snooze = async (card: Card) => {
    const base = card.due_date ? new Date(card.due_date) : new Date();
    const nextDue = new Date(base.getTime() + 24 * 60 * 60 * 1000).toISOString();
    setCards((prev) => prev.map((c) => (c.card_id === card.card_id ? { ...c, due_date: nextDue } : c)));
    try {
      await api.updateCard(card.card_id, { due_date: nextDue });
    } catch {
      load();
    }
  };
'@
  $content = $content.Replace("`n  const activeCards = useMemo(() => cards.filter((c) => c.status === 'OPEN'), [cards]);", $snoozeBlock + "`n  const activeCards = useMemo(() => cards.filter((c) => c.status === 'OPEN'), [cards]);")
}

# Add grouped weekly planner data.
if ($content -notmatch "const weeklyAgenda = useMemo") {
  $agendaBlock = @'

  const weeklyAgenda = useMemo(() => {
    const dayMs = 24 * 60 * 60 * 1000;
    const today = new Date();
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime();
    const tomorrowStart = todayStart + dayMs;
    const laterStart = todayStart + dayMs * 2;
    const weekEnd = todayStart + dayMs * 7;

    const tomorrowLabel = lang === 'fr' ? 'Demain' : lang === 'es' ? 'Mañana' : lang === 'de' ? 'Morgen' : 'Tomorrow';
    const laterLabel = lang === 'fr' ? 'Plus tard cette semaine' : lang === 'es' ? 'Más tarde esta semana' : lang === 'de' ? 'Später diese Woche' : 'Later this week';

    const items = dashboard.nextUp.filter((card) => {
      const time = dueTime(card);
      return Boolean(time && time >= todayStart && time < weekEnd);
    });

    const sections = [
      {
        key: 'today',
        title: labels.today,
        cards: items.filter((card) => {
          const time = dueTime(card) || 0;
          return time >= todayStart && time < tomorrowStart;
        }).slice(0, 3),
      },
      {
        key: 'tomorrow',
        title: tomorrowLabel,
        cards: items.filter((card) => {
          const time = dueTime(card) || 0;
          return time >= tomorrowStart && time < laterStart;
        }).slice(0, 3),
      },
      {
        key: 'later',
        title: laterLabel,
        cards: items.filter((card) => {
          const time = dueTime(card) || 0;
          return time >= laterStart && time < weekEnd;
        }).slice(0, 4),
      },
    ].filter((section) => section.cards.length > 0);

    return { total: items.length, sections };
  }, [dashboard.nextUp, labels.today, lang]);

  const boardPreviewCards = useMemo(() => activeCards.slice(0, 6), [activeCards]);
'@
  $marker = "`n  const childMembers = useMemo(() => members.filter((m) => m.role?.toLowerCase() === 'child'), [members]);"
  if (-not $content.Contains($marker)) {
    throw "Could not find childMembers marker for weekly agenda insertion."
  }
  $content = $content.Replace($marker, $agendaBlock + $marker)
}

# Replace old Next Up rows and long This Week SmartCard list with compact weekly planner and compact board preview.
if ($content -notmatch "testID='weekly-planner'") {
  $nextTitle = $content.IndexOf('{labels.nextUp}')
  if ($nextTitle -lt 0) {
    throw "Could not find the Next up section title."
  }
  $plannerStart = $content.LastIndexOf('          <View style={styles.section}>', $nextTitle)
  if ($plannerStart -lt 0) {
    throw "Could not find the start of the Next up section."
  }
  $footerStart = $content.IndexOf('          <View style={styles.footerSignal}>', $plannerStart)
  if ($footerStart -lt 0) {
    throw "Could not find the footer marker after This Week."
  }

  $plannerBlock = @'
          <GlassCard testID='weekly-planner' style={styles.plannerCard}>
            <View style={styles.plannerHeader}>
              <View style={{ flex: 1 }}>
                <Text style={[styles.plannerKicker, { color: theme.colors.textMuted }]}>{t('this_week')}</Text>
                <Text style={[styles.plannerTitle, { color: theme.colors.text }]}>{labels.nextUp}</Text>
                <Text style={[styles.plannerSub, { color: theme.colors.textMuted }]}>{weeklyAgenda.total} upcoming · {openCount} active</Text>
              </View>
              <PressScale onPress={() => router.push('/calendar')} style={[styles.plannerViewAll, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>
                <Text style={[styles.plannerViewAllText, { color: theme.colors.text }]}>View all</Text>
                <ArrowRight color={theme.colors.text} size={15} />
              </PressScale>
            </View>

            {weeklyAgenda.total === 0 ? (
              <View style={styles.plannerEmpty}>
                <CalendarDays color={theme.colors.success} size={22} />
                <Text style={[styles.plannerEmptyTitle, { color: theme.colors.text }]}>Nothing planned this week.</Text>
                <Text style={[styles.plannerSub, { color: theme.colors.textMuted }]}>Your calendar and household tasks are clear.</Text>
              </View>
            ) : (
              weeklyAgenda.sections.map((section) => (
                <View key={section.key} style={styles.plannerSection}>
                  <View style={styles.plannerDayHeader}>
                    <Text style={[styles.plannerDayTitle, { color: theme.colors.text }]}>{section.title}</Text>
                    <Text style={[styles.plannerDayCount, { color: theme.colors.textMuted }]}>{section.cards.length}</Text>
                  </View>

                  {section.cards.map((card) => (
                    <View key={`agenda-${card.card_id}`} style={[styles.agendaRow, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>
                      <View style={[styles.agendaDot, { backgroundColor: card.source === 'CALENDAR' ? theme.colors.success : theme.colors.accent }]} />
                      <View style={{ flex: 1 }}>
                        <Text style={[styles.agendaTitle, { color: theme.colors.text }]} numberOfLines={1}>{card.title}</Text>
                        <Text style={[styles.agendaMeta, { color: theme.colors.textMuted }]} numberOfLines={1}>{formatCardDate(card)} · {card.assignee || t('family')}</Text>
                      </View>
                      <View style={styles.agendaActions}>
                        <PressScale testID={`agenda-done-${card.card_id}`} onPress={() => toggle(card)} style={[styles.agendaDoneBtn, { backgroundColor: theme.colors.primary }]}>
                          <CheckCircle2 color={theme.colors.primaryText} size={15} />
                        </PressScale>
                        <PressScale testID={`agenda-snooze-${card.card_id}`} onPress={() => snooze(card)} style={[styles.agendaIconBtn, { borderColor: theme.colors.cardBorder }]}>
                          <Clock3 color={theme.colors.textMuted} size={15} />
                        </PressScale>
                        <PressScale testID={`agenda-delete-${card.card_id}`} onPress={() => remove(card)} style={[styles.agendaIconBtn, { borderColor: theme.colors.cardBorder }]}>
                          <Trash2 color={theme.colors.textMuted} size={15} />
                        </PressScale>
                      </View>
                    </View>
                  ))}
                </View>
              ))
            )}
          </GlassCard>

          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: theme.colors.text }]}>{t('this_week')}</Text>
            <Text style={[styles.sectionSub, { color: theme.colors.textMuted }]}>{boardPreviewCards.length}/{openCount} active</Text>
          </View>

          <GlassCard style={styles.boardPreviewCard}>
            {boardPreviewCards.length === 0 && !loading ? (
              <Text style={[styles.emptyTitle, { color: theme.colors.text }]}>{t('no_items')}</Text>
            ) : (
              boardPreviewCards.map((card) => (
                <View key={`board-${card.card_id}`} style={[styles.boardMiniRow, { borderColor: theme.colors.cardBorder }]}>
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.boardMiniTitle, { color: theme.colors.text }]} numberOfLines={1}>{card.title}</Text>
                    <Text style={[styles.boardMiniMeta, { color: theme.colors.textMuted }]} numberOfLines={1}>{formatCardDate(card)} · {card.assignee || t('family')}</Text>
                  </View>
                  <View style={styles.boardMiniActions}>
                    <PressScale testID={`board-done-${card.card_id}`} onPress={() => toggle(card)} style={[styles.miniDoneButton, { backgroundColor: theme.colors.primary }]}>
                      <CheckCircle2 color={theme.colors.primaryText} size={14} />
                      <Text style={[styles.miniDoneText, { color: theme.colors.primaryText }]}>Done</Text>
                    </PressScale>
                    <PressScale testID={`board-delete-${card.card_id}`} onPress={() => remove(card)} style={[styles.miniDeleteButton, { borderColor: theme.colors.cardBorder }]}>
                      <Trash2 color={theme.colors.textMuted} size={14} />
                    </PressScale>
                  </View>
                </View>
              ))
            )}
          </GlassCard>

'@
  $content = $content.Substring(0, $plannerStart) + $plannerBlock + $content.Substring($footerStart)
}

# Insert styles for the weekly planner and compact board.
if ($content -notmatch "plannerCard:") {
  $plannerStyles = @'
  plannerCard: { marginBottom: 18, paddingVertical: 18, gap: 14 },
  plannerHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  plannerKicker: { fontFamily: 'Inter_800ExtraBold', fontSize: 11, letterSpacing: 1.1, textTransform: 'uppercase' },
  plannerTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 25, letterSpacing: -0.8, marginTop: 2 },
  plannerSub: { fontFamily: 'Inter_600SemiBold', fontSize: 12, marginTop: 3 },
  plannerViewAll: { minHeight: 38, borderRadius: 999, borderWidth: 1, paddingHorizontal: 13, flexDirection: 'row', alignItems: 'center', gap: 5 },
  plannerViewAllText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
  plannerEmpty: { minHeight: 104, alignItems: 'center', justifyContent: 'center', gap: 5 },
  plannerEmptyTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 15 },
  plannerSection: { gap: 8, marginTop: 2 },
  plannerDayHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 2 },
  plannerDayTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 15 },
  plannerDayCount: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
  agendaRow: { minHeight: 62, borderRadius: 20, borderWidth: 1, flexDirection: 'row', alignItems: 'center', gap: 10, paddingHorizontal: 12, paddingVertical: 9 },
  agendaDot: { width: 9, height: 9, borderRadius: 99 },
  agendaTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 14 },
  agendaMeta: { fontFamily: 'Inter_600SemiBold', fontSize: 11, marginTop: 2 },
  agendaActions: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  agendaDoneBtn: { width: 34, height: 34, borderRadius: 999, alignItems: 'center', justifyContent: 'center' },
  agendaIconBtn: { width: 34, height: 34, borderRadius: 999, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  boardPreviewCard: { marginBottom: 18, paddingVertical: 8 },
  boardMiniRow: { minHeight: 58, borderBottomWidth: StyleSheet.hairlineWidth, flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 9 },
  boardMiniTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 14 },
  boardMiniMeta: { fontFamily: 'Inter_600SemiBold', fontSize: 11, marginTop: 2 },
  boardMiniActions: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  miniDoneButton: { minHeight: 32, borderRadius: 999, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 5, paddingHorizontal: 10 },
  miniDoneText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },
  miniDeleteButton: { width: 32, height: 32, borderRadius: 999, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
'@
  $content = $content.Replace("const styles = StyleSheet.create({`n", "const styles = StyleSheet.create({`n" + $plannerStyles)
}

# Remove stale styles for removed capture actions.
$staleStyles = @('searchShell', 'searchText', 'filterButton', 'actionRow', 'actionTile', 'actionText')
foreach ($styleName in $staleStyles) {
  $content = [regex]::Replace($content, "(?m)^\s*$styleName:\s*\{[^\n]*\},\s*\n", "")
  $content = [regex]::Replace($content, "(?ms)^\s*$styleName:\s*\{.*?\n\s*\},\s*\n", "")
}

$content = [regex]::Replace($content, "\n{3,}", "`n`n")
[System.IO.File]::WriteAllText($FeedFile, $content.Replace("`n", "`r`n"), $Utf8NoBom)

Set-Location $FrontendPath
npm run verify

if ($LASTEXITCODE -ne 0) {
  Write-Host "Verification failed. Not committing." -ForegroundColor Red
  exit $LASTEXITCODE
}

Set-Location $RepoPath

git add "frontend/app/(tabs)/feed.tsx"

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
  Write-Host "No feed planner changes to commit." -ForegroundColor Yellow
  exit 0
}

git commit -m "Redesign feed weekly planner"
git push origin $BranchName

Write-Host "Feed weekly planner redesigned and pushed." -ForegroundColor Green
