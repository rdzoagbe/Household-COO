const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const repo = path.resolve(__dirname, '..', '..');
const frontend = path.join(repo, 'frontend');
const kidsFile = path.join(frontend, 'app', '(tabs)', 'kids.tsx');
const feedFile = path.join(frontend, 'app', '(tabs)', 'feed.tsx');

function run(command, cwd = repo) {
  cp.execSync(command, { cwd, stdio: 'inherit', shell: true });
}

function readFile(file) {
  return fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').replace(/\r/g, '\n');
}

function writeFile(file, content) {
  fs.writeFileSync(file, content.replace(/\n{3,}/g, '\n\n').replace(/\n/g, '\r\n'), 'utf8');
}

function insertBefore(content, marker, insert, guard) {
  if (guard && content.includes(guard)) return content;
  const index = content.indexOf(marker);
  if (index < 0) throw new Error(`Marker not found: ${marker}`);
  return content.slice(0, index) + insert + content.slice(index);
}

function insertAfter(content, marker, insert, guard) {
  if (guard && content.includes(guard)) return content;
  const index = content.indexOf(marker);
  if (index < 0) throw new Error(`Marker not found: ${marker}`);
  return content.slice(0, index + marker.length) + insert + content.slice(index + marker.length);
}

function addLucideImports(content, names) {
  return content.replace(/import \{([\s\S]*?)\} from 'lucide-react-native';/, (full, body) => {
    const current = body.split(',').map((name) => name.trim()).filter(Boolean);
    for (const name of names) {
      if (!current.includes(name)) current.push(name);
    }
    current.sort((a, b) => a.localeCompare(b));
    return `import {\n  ${current.join(',\n  ')}\n} from 'lucide-react-native';`;
  });
}

function patchKids() {
  let content = readFile(kidsFile);

  const customFunction = `  const customAddStars = async () => {\n    if (!activeChild) {\n      showToast('Select a child first.', 'error');\n      return;\n    }\n\n    const amount = parseInt(starAmount || '0', 10);\n    if (!amount || amount < 1) {\n      showToast('Enter a valid star amount.', 'error');\n      return;\n    }\n\n    const reason = starReason.trim() || 'Custom stars';\n    setSaving(true);\n    try {\n      const result = await api.adjustMemberStars(activeChild.member_id, {\n        delta: amount,\n        reason,\n      });\n\n      setMembers((prev) => prev.map((member) => (member.member_id === result.member.member_id ? result.member : member)));\n      showToast(amount === 1 ? 'Added 1 star.' : \`Added \${amount} stars.\`, 'success');\n      setStarAmount('5');\n      setStarReason('');\n      await refreshHistory(activeChild.member_id);\n    } catch (e: any) {\n      logger.warn('Custom add stars failed:', e?.message || e);\n      showToast(e?.message || 'Could not add stars.', 'error');\n    } finally {\n      setSaving(false);\n    }\n  };\n\n`;

  content = insertBefore(content, '  const adjustStars = async () => {', customFunction, 'const customAddStars = async');

  content = content.replace(/\n\s*<PressScale testID="quick-stars-custom"[\s\S]*?<\/PressScale>\s*/m, '\n');

  const customCard = `\n              <GlassCard testID="custom-star-card" style={[styles.customStarCard, activeKidsView !== 'overview' && styles.hiddenSection]}>\n                <View style={styles.customStarHeader}>\n                  <View style={{ flex: 1 }}>\n                    <Text style={[styles.customStarTitle, { color: theme.colors.text }]}>Custom stars</Text>\n                    <Text style={[styles.customStarSub, { color: theme.colors.textMuted }]}>Add a specific amount without leaving the page.</Text>\n                  </View>\n                  <View style={[styles.customStarBadge, { backgroundColor: theme.colors.accentSoft }]}>\n                    <Star color={theme.colors.accent} size={16} fill={theme.colors.accent} />\n                  </View>\n                </View>\n\n                <View style={styles.customStarControls}>\n                  <View style={[styles.customAmountBox, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>\n                    <Text style={[styles.customAmountLabel, { color: theme.colors.textMuted }]}>Stars</Text>\n                    <TextInput\n                      testID="custom-star-amount"\n                      value={starAmount}\n                      onChangeText={(value) => setStarAmount(cleanNumber(value))}\n                      keyboardType="number-pad"\n                      placeholder="5"\n                      placeholderTextColor={theme.colors.textSoft}\n                      style={[styles.customAmountInput, { color: theme.colors.text }]}\n                    />\n                  </View>\n                  <PressScale\n                    testID="custom-add-stars"\n                    onPress={customAddStars}\n                    disabled={saving || !activeChild}\n                    style={[styles.customStarSubmit, { backgroundColor: theme.colors.primary }, (saving || !activeChild) && { opacity: 0.5 }]}\n                  >\n                    <Plus color={theme.colors.primaryText} size={16} />\n                    <Text style={[styles.customStarSubmitText, { color: theme.colors.primaryText }]}>Add</Text>\n                  </PressScale>\n                </View>\n\n                <View style={styles.customPresetRow}>\n                  {[1, 3, 5, 10].map((amount) => (\n                    <PressScale key={amount} onPress={() => setStarAmount(String(amount))} style={[styles.customPresetChip, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>\n                      <Text style={[styles.customPresetText, { color: theme.colors.text }]}>+{amount}</Text>\n                    </PressScale>\n                  ))}\n                </View>\n\n                <View style={styles.customReasonRow}>\n                  {['Homework', 'Chores', 'Reading', 'Kindness'].map((reason) => {\n                    const active = starReason === reason;\n                    return (\n                      <PressScale key={reason} onPress={() => setStarReason(active ? '' : reason)} style={[styles.customReasonChip, { backgroundColor: active ? theme.colors.accentSoft : theme.colors.bgSoft, borderColor: active ? theme.colors.accent : theme.colors.cardBorder }]}>\n                        <Text style={[styles.customReasonText, { color: active ? theme.colors.accent : theme.colors.textMuted }]}>{reason}</Text>\n                      </PressScale>\n                    );\n                  })}\n                </View>\n              </GlassCard>\n`;

  content = insertBefore(
    content,
    "              <View style={[styles.kidsSegmentWrap",
    customCard,
    'testID="custom-star-card"'
  );

  const kidsStyles = `  customStarCard: { marginBottom: 18, padding: 16 },\n  customStarHeader: { flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 14 },\n  customStarTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 18, lineHeight: 23 },\n  customStarSub: { fontFamily: 'Inter_600SemiBold', fontSize: 12, lineHeight: 17, marginTop: 2 },\n  customStarBadge: { width: 38, height: 38, borderRadius: 9999, alignItems: 'center', justifyContent: 'center' },\n  customStarControls: { flexDirection: 'row', alignItems: 'center', gap: 10 },\n  customAmountBox: { flex: 1, minHeight: 58, borderRadius: 18, borderWidth: 1, paddingHorizontal: 14, justifyContent: 'center' },\n  customAmountLabel: { fontFamily: 'Inter_800ExtraBold', fontSize: 10, textTransform: 'uppercase', letterSpacing: 0.8 },\n  customAmountInput: { fontFamily: 'Inter_800ExtraBold', fontSize: 21, paddingVertical: 0, marginTop: 2 },\n  customStarSubmit: { minHeight: 58, borderRadius: 18, paddingHorizontal: 18, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 7 },\n  customStarSubmitText: { fontFamily: 'Inter_800ExtraBold', fontSize: 14 },\n  customPresetRow: { flexDirection: 'row', gap: 8, marginTop: 12 },\n  customPresetChip: { flex: 1, minHeight: 38, borderRadius: 9999, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },\n  customPresetText: { fontFamily: 'Inter_800ExtraBold', fontSize: 12 },\n  customReasonRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },\n  customReasonChip: { minHeight: 34, borderRadius: 9999, borderWidth: 1, paddingHorizontal: 11, alignItems: 'center', justifyContent: 'center' },\n  customReasonText: { fontFamily: 'Inter_800ExtraBold', fontSize: 11 },\n`;

  if (!content.includes('customStarCard:')) {
    content = content.replace('const styles = StyleSheet.create({\n', `const styles = StyleSheet.create({\n${kidsStyles}`);
  }

  content = content.replace(/kidsSegmentWrap:\s*\{[^}]+\},/, "kidsSegmentWrap: { minHeight: 58, borderRadius: 9999, borderWidth: 1, padding: 8, flexDirection: 'row', gap: 10, marginBottom: 18 },");
  content = content.replace(/kidsSegmentBtn:\s*\{[^}]+\},/, "kidsSegmentBtn: { flex: 1, minHeight: 42, borderRadius: 9999, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 12 },");

  writeFile(kidsFile, content);
}

function patchFeed() {
  let content = readFile(feedFile);

  content = addLucideImports(content, ['Camera', 'Mic', 'PlusCircle']);

  if (!content.includes("AddCardModal")) {
    content = content.replace(
      "import { SundayBriefModal } from '../../src/components/SundayBriefModal';",
      "import { AddCardModal } from '../../src/components/AddCardModal';\nimport { SundayBriefModal } from '../../src/components/SundayBriefModal';\nimport { VoiceCaptureModal } from '../../src/components/VoiceCaptureModal';\nimport { CameraCaptureModal } from '../../src/components/CameraCaptureModal';"
    );
  }

  content = content.replace("import { api, Card, FamilyMember } from '../../src/api';", "import { api, Card, CardType, FamilyMember } from '../../src/api';");

  const voiceDraft = `\ninterface VoiceDraft {\n  transcript: string;\n  type: CardType;\n  title: string;\n  description: string;\n  assignee: string;\n  due_date?: string | null;\n  image_base64?: string | null;\n  vault_category?: string;\n  save_to_vault?: boolean;\n}\n`;
  content = insertBefore(content, 'type Labels = {', voiceDraft, 'interface VoiceDraft');

  const captureStates = `\n  const [showAdd, setShowAdd] = useState(false);\n  const [showVoice, setShowVoice] = useState(false);\n  const [showCamera, setShowCamera] = useState(false);\n  const [addSource, setAddSource] = useState<'MANUAL' | 'VOICE' | 'CAMERA'>('MANUAL');\n  const [voiceDraft, setVoiceDraft] = useState<VoiceDraft | null>(null);\n`;
  content = insertAfter(content, '  const [showBrief, setShowBrief] = useState(false);\n', captureStates, 'const [showAdd, setShowAdd]');

  const openManual = `\n  const openManual = () => {\n    setVoiceDraft(null);\n    setAddSource('MANUAL');\n    setShowAdd(true);\n  };\n`;
  content = insertAfter(content, "  const firstName = (user?.name || '').split(' ')[0] || '';\n", openManual, 'const openManual = () =>');

  const compactActions = `\n\n          <GlassCard testID="compact-feed-actions" style={styles.compactActionPanel}>\n            <View style={styles.compactActionHeader}>\n              <Text style={[styles.compactActionTitle, { color: theme.colors.text }]}>{labels.quickActions}</Text>\n              <Text style={[styles.compactActionSub, { color: theme.colors.textMuted }]}>Capture without crowding the feed</Text>\n            </View>\n            <View style={styles.compactActionRow}>\n              <PressScale testID="feed-action-voice" onPress={() => setShowVoice(true)} style={[styles.compactActionChip, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>\n                <View style={[styles.compactActionIcon, { backgroundColor: theme.colors.accentSoft }]}>\n                  <Mic color={theme.colors.accent} size={16} />\n                </View>\n                <Text style={[styles.compactActionLabel, { color: theme.colors.text }]}>{labels.voice}</Text>\n              </PressScale>\n              <PressScale testID="feed-action-camera" onPress={() => setShowCamera(true)} style={[styles.compactActionChip, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>\n                <View style={[styles.compactActionIcon, { backgroundColor: theme.colors.accentSoft }]}>\n                  <Camera color={theme.colors.accent} size={16} />\n                </View>\n                <Text style={[styles.compactActionLabel, { color: theme.colors.text }]}>{labels.scan}</Text>\n              </PressScale>\n              <PressScale testID="feed-action-manual" onPress={openManual} style={[styles.compactActionChip, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>\n                <View style={[styles.compactActionIcon, { backgroundColor: theme.colors.accentSoft }]}>\n                  <PlusCircle color={theme.colors.accent} size={16} />\n                </View>\n                <Text style={[styles.compactActionLabel, { color: theme.colors.text }]}>{labels.manual}</Text>\n              </PressScale>\n            </View>\n          </GlassCard>\n`;
  content = insertBefore(content, '          <View style={styles.statGrid}>', compactActions, 'testID="compact-feed-actions"');

  const modalBlock = `\n\n      <CameraCaptureModal\n        visible={showCamera}\n        onClose={() => setShowCamera(false)}\n        onDraft={(d) => {\n          setVoiceDraft({\n            transcript: '',\n            type: d.type,\n            title: d.title,\n            description: d.description,\n            assignee: d.assignee,\n            due_date: d.due_date || null,\n            image_base64: d.image_base64 || null,\n            vault_category: d.vault_category || 'School',\n            save_to_vault: d.save_to_vault !== false,\n          });\n          setAddSource('CAMERA');\n          setShowCamera(false);\n          setShowAdd(true);\n        }}\n      />\n\n      <VoiceCaptureModal\n        visible={showVoice}\n        onClose={() => setShowVoice(false)}\n        onDraft={(d) => {\n          setVoiceDraft(d);\n          setAddSource('VOICE');\n          setShowVoice(false);\n          setShowAdd(true);\n        }}\n      />\n\n      <AddCardModal\n        visible={showAdd}\n        onClose={() => {\n          setShowAdd(false);\n          setVoiceDraft(null);\n        }}\n        onCreated={load}\n        initialSource={addSource}\n        initialDraft={voiceDraft}\n      />\n`;
  content = insertBefore(content, '      <SundayBriefModal visible={showBrief}', modalBlock, '<CameraCaptureModal');

  const feedStyles = `  compactActionPanel: { marginBottom: 16, padding: 14 },\n  compactActionHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10, marginBottom: 12 },\n  compactActionTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 17, lineHeight: 22 },\n  compactActionSub: { flex: 1, textAlign: 'right', fontFamily: 'Inter_600SemiBold', fontSize: 11, lineHeight: 15 },\n  compactActionRow: { flexDirection: 'row', gap: 10 },\n  compactActionChip: { flex: 1, minHeight: 58, borderRadius: 20, borderWidth: 1, paddingHorizontal: 10, alignItems: 'center', justifyContent: 'center', gap: 6 },\n  compactActionIcon: { width: 30, height: 30, borderRadius: 9999, alignItems: 'center', justifyContent: 'center' },\n  compactActionLabel: { fontFamily: 'Inter_800ExtraBold', fontSize: 11 },\n`;
  if (!content.includes('compactActionPanel:')) {
    content = content.replace('const styles = StyleSheet.create({\n', `const styles = StyleSheet.create({\n${feedStyles}`);
  }

  writeFile(feedFile, content);
}

function main() {
  console.log('Applying Kids custom-star and Feed compact-action refinements...');
  patchKids();
  patchFeed();

  console.log('Running verification...');
  run('npm run verify', frontend);

  console.log('Committing changes...');
  run('git add "frontend/app/(tabs)/kids.tsx" "frontend/app/(tabs)/feed.tsx"');
  try {
    run('git diff --cached --quiet');
    console.log('No app changes to commit.');
  } catch {
    run('git commit -m "Refine Kids custom stars and Feed actions"');
    run('git push origin feature/vault-board-2');
  }

  console.log('Done. Kids custom stars and Feed compact actions are ready to test.');
}

main();
