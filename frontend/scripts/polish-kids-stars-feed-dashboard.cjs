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
    const current = body
      .split(',')
      .map((name) => name.trim())
      .filter(Boolean);

    for (const name of names) {
      if (!current.includes(name)) current.push(name);
    }

    current.sort((a, b) => a.localeCompare(b));
    return `import {\n  ${current.join(',\n  ')}\n} from 'lucide-react-native';`;
  });
}

function ensureStyle(content, styleBlock, guard) {
  if (content.includes(guard)) return content;
  return content.replace('const styles = StyleSheet.create({\n', `const styles = StyleSheet.create({\n${styleBlock}`);
}

function patchKids() {
  let content = readFile(kidsFile);

  if (!content.includes('selectedStarReason')) {
    content = content.replace(
      "  const [starReason, setStarReason] = useState('');",
      "  const [starReason, setStarReason] = useState('');\n  const [selectedStarReason, setSelectedStarReason] = useState('Homework');"
    );
  }

  content = content.replace(
    /\n\s*const customAddStars = async \(\) => \{[\s\S]*?\n\s*\};\n\n(?=\s*const adjustStars = async)/,
    '\n'
  );

  content = content.replace(
    /\n\s*<GlassCard testID="custom-star-card"[\s\S]*?\n\s*<\/GlassCard>\s*\n(?=\s*<View style=\{\[styles\.kidsSegmentWrap)/,
    '\n'
  );

  content = content.replace(
    /\n\s*<PressScale testID="quick-stars-custom"[\s\S]*?<\/PressScale>\s*/m,
    '\n'
  );

  content = content.replace("{['5', '10', '20'].map((amount) => (", "{['5', '10', '15', '20', '25', '30'].map((amount) => (");

  content = content.replace(
    "reason: amount === 1 ? 'Quick star' : `Quick +${amount} stars`,",
    "reason: selectedStarReason ? `${selectedStarReason} +${amount}` : amount === 1 ? 'Quick star' : `Quick +${amount} stars`,"
  );

  const reasonChips = `\n              <View style={styles.starReasonRow}>\n                {['Homework', 'Chores', 'Reading', 'Kindness'].map((reason) => {\n                  const active = selectedStarReason === reason;\n                  return (\n                    <PressScale\n                      key={reason}\n                      testID={\`star-reason-\${reason.toLowerCase()}\`}\n                      onPress={() => setSelectedStarReason(active ? '' : reason)}\n                      style={[\n                        styles.starReasonChip,\n                        { backgroundColor: active ? theme.colors.accentSoft : theme.colors.card, borderColor: active ? theme.colors.accent : theme.colors.cardBorder },\n                      ]}\n                    >\n                      <Text style={[styles.starReasonText, { color: active ? theme.colors.accent : theme.colors.textMuted }]}>{reason}</Text>\n                    </PressScale>\n                  );\n                })}\n              </View>\n`;

  content = insertBefore(content, '              <View style={[styles.kidsSegmentWrap', reasonChips, 'testID={`star-reason-${reason.toLowerCase()}`}');

  content = content.replace(
    /quickRow:\s*\{[^}]+\},/,
    "quickRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 10 },"
  );
  content = content.replace(
    /quickBtn:\s*\{[^}]+\},/,
    "quickBtn: { minHeight: 44, minWidth: '30%', flexGrow: 1, borderRadius: 9999, borderWidth: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 12 },"
  );
  content = content.replace(
    /kidsSegmentWrap:\s*\{[^}]+\},/,
    "kidsSegmentWrap: { minHeight: 58, borderRadius: 9999, borderWidth: 1, padding: 8, flexDirection: 'row', gap: 10, marginBottom: 18 },"
  );
  content = content.replace(
    /kidsSegmentBtn:\s*\{[^}]+\},/,
    "kidsSegmentBtn: { flex: 1, minHeight: 42, borderRadius: 9999, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 12 },"
  );

  const reasonStyles = `  starReasonRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 18 },\n  starReasonChip: { minHeight: 36, borderRadius: 9999, borderWidth: 1, paddingHorizontal: 12, alignItems: 'center', justifyContent: 'center' },\n  starReasonText: { fontFamily: 'Inter_800ExtraBold', fontSize: 11 },\n`;
  content = ensureStyle(content, reasonStyles, 'starReasonRow:');

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

  if (!content.includes('CardType')) {
    content = content.replace("import { api, Card, FamilyMember } from '../../src/api';", "import { api, Card, CardType, FamilyMember } from '../../src/api';");
  }

  const voiceDraft = `\ninterface VoiceDraft {\n  transcript: string;\n  type: CardType;\n  title: string;\n  description: string;\n  assignee: string;\n  due_date?: string | null;\n  image_base64?: string | null;\n  vault_category?: string;\n  save_to_vault?: boolean;\n}\n`;
  content = insertBefore(content, 'type Labels = {', voiceDraft, 'interface VoiceDraft');

  const captureStates = `  const [showAdd, setShowAdd] = useState(false);\n  const [showVoice, setShowVoice] = useState(false);\n  const [showCamera, setShowCamera] = useState(false);\n  const [addSource, setAddSource] = useState<'MANUAL' | 'VOICE' | 'CAMERA'>('MANUAL');\n  const [voiceDraft, setVoiceDraft] = useState<VoiceDraft | null>(null);\n`;
  content = insertAfter(content, '  const [showBrief, setShowBrief] = useState(false);\n', captureStates, 'const [showAdd, setShowAdd]');

  const openManual = `\n  const openManual = () => {\n    setVoiceDraft(null);\n    setAddSource('MANUAL');\n    setShowAdd(true);\n  };\n`;
  content = insertAfter(content, "  const firstName = (user?.name || '').split(' ')[0] || '';\n", openManual, 'const openManual = () =>');

  const compactActions = `\n\n          <GlassCard testID="compact-feed-actions" style={styles.compactActionPanel}>\n            <View style={styles.compactActionHeader}>\n              <Text style={[styles.compactActionTitle, { color: theme.colors.text }]}>{labels.quickActions}</Text>\n              <Text style={[styles.compactActionSub, { color: theme.colors.textMuted }]}>Voice, camera or manual capture</Text>\n            </View>\n            <View style={styles.compactActionRow}>\n              <PressScale testID="feed-action-voice" onPress={() => setShowVoice(true)} style={[styles.compactActionChip, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>\n                <View style={[styles.compactActionIcon, { backgroundColor: theme.colors.accentSoft }]}>\n                  <Mic color={theme.colors.accent} size={16} />\n                </View>\n                <Text style={[styles.compactActionLabel, { color: theme.colors.text }]}>{labels.voice}</Text>\n              </PressScale>\n              <PressScale testID="feed-action-camera" onPress={() => setShowCamera(true)} style={[styles.compactActionChip, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>\n                <View style={[styles.compactActionIcon, { backgroundColor: theme.colors.accentSoft }]}>\n                  <Camera color={theme.colors.accent} size={16} />\n                </View>\n                <Text style={[styles.compactActionLabel, { color: theme.colors.text }]}>{labels.scan}</Text>\n              </PressScale>\n              <PressScale testID="feed-action-manual" onPress={openManual} style={[styles.compactActionChip, { backgroundColor: theme.colors.bgSoft, borderColor: theme.colors.cardBorder }]}>\n                <View style={[styles.compactActionIcon, { backgroundColor: theme.colors.accentSoft }]}>\n                  <PlusCircle color={theme.colors.accent} size={16} />\n                </View>\n                <Text style={[styles.compactActionLabel, { color: theme.colors.text }]}>{labels.manual}</Text>\n              </PressScale>\n            </View>\n          </GlassCard>\n`;
  content = insertBefore(content, '          <View style={styles.statGrid}>', compactActions, 'testID="compact-feed-actions"');

  const modalBlock = `\n\n      <CameraCaptureModal\n        visible={showCamera}\n        onClose={() => setShowCamera(false)}\n        onDraft={(d) => {\n          setVoiceDraft({\n            transcript: '',\n            type: d.type,\n            title: d.title,\n            description: d.description,\n            assignee: d.assignee,\n            due_date: d.due_date || null,\n            image_base64: d.image_base64 || null,\n            vault_category: d.vault_category || 'School',\n            save_to_vault: d.save_to_vault !== false,\n          });\n          setAddSource('CAMERA');\n          setShowCamera(false);\n          setShowAdd(true);\n        }}\n      />\n\n      <VoiceCaptureModal\n        visible={showVoice}\n        onClose={() => setShowVoice(false)}\n        onDraft={(d) => {\n          setVoiceDraft(d);\n          setAddSource('VOICE');\n          setShowVoice(false);\n          setShowAdd(true);\n        }}\n      />\n\n      <AddCardModal\n        visible={showAdd}\n        onClose={() => {\n          setShowAdd(false);\n          setVoiceDraft(null);\n        }}\n        onCreated={load}\n        initialSource={addSource}\n        initialDraft={voiceDraft}\n      />\n`;
  content = insertBefore(content, '      <SundayBriefModal visible={showBrief}', modalBlock, '<CameraCaptureModal');

  const feedStyles = `  compactActionPanel: { marginBottom: 16, padding: 14 },\n  compactActionHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10, marginBottom: 12 },\n  compactActionTitle: { fontFamily: 'Inter_800ExtraBold', fontSize: 17, lineHeight: 22 },\n  compactActionSub: { flex: 1, textAlign: 'right', fontFamily: 'Inter_600SemiBold', fontSize: 11, lineHeight: 15 },\n  compactActionRow: { flexDirection: 'row', gap: 10 },\n  compactActionChip: { flex: 1, minHeight: 58, borderRadius: 20, borderWidth: 1, paddingHorizontal: 10, alignItems: 'center', justifyContent: 'center', gap: 6 },\n  compactActionIcon: { width: 30, height: 30, borderRadius: 9999, alignItems: 'center', justifyContent: 'center' },\n  compactActionLabel: { fontFamily: 'Inter_800ExtraBold', fontSize: 11 },\n`;
  content = ensureStyle(content, feedStyles, 'compactActionPanel:');

  writeFile(feedFile, content);
}

function main() {
  console.log('Polishing Kids star shortcuts and Feed dashboard actions...');
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
    run('git commit -m "Polish Kids stars and Feed dashboard actions"');
    run('git push origin feature/vault-board-2');
  }

  console.log('Done. Ready to test.');
}

main();
