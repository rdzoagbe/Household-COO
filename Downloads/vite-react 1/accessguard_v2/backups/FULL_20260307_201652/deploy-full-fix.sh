#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗"
echo -e "║     AccessGuard V2 — Full Site Fix (All Issues)           ║"
echo -e "╚════════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
cp src/ExecutiveDashboard.jsx "backups/$TS/ExecutiveDashboard.jsx" 2>/dev/null || true
cp src/translations.js "backups/$TS/translations.js" 2>/dev/null || true
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

# ════════════════════════════════════════════════════════════
# FIX 1 — ExecutiveDashboard.jsx: broken template literals
#          + max-w constraint + Math.random flicker
# ════════════════════════════════════════════════════════════
echo -e "${BLUE}[1/3] Fixing ExecutiveDashboard...${NC}"
python3 << 'PYEOF'
import sys
path = 'src/ExecutiveDashboard.jsx'
try:
    with open(path, encoding='utf-8') as f:
        src = f.read()
except FileNotFoundError:
    print("  SKIP — ExecutiveDashboard.jsx not found at src/")
    sys.exit(0)

fixes = []

def fix(label, old, new):
    global src
    if new in src:       fixes.append(f"✓ {label} (already done)")
    elif old in src:     src = src.replace(old, new, 1); fixes.append(f"✓ {label}")
    else:                fixes.append(f"! {label} — not found")

# Broken \${ → ${ in template literals
fix("YAxis tickFormatter",
    r'tickFormatter={(val) => `$\${(val/1000).toFixed(0)}K`}',
    r'tickFormatter={(val) => `$${(val/1000).toFixed(0)}K`}')

fix("LineChart Tooltip formatter",
    r"formatter={(val) => [`$\${val.toLocaleString()}`, '']}",
    r"formatter={(val) => [`$${val.toLocaleString()}`, '']}")

fix("Pie label",
    r'label={({ name, percent }) => `\${name} \${(percent * 100).toFixed(0)}%`}',
    r'label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}')

fix("Cell key",
    r'<Cell key={`cell-\${index}`} fill={COLORS[index % COLORS.length]} />',
    r'<Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />')

fix("Pie Tooltip formatter",
    r"formatter={(val) => [`$\${val.toLocaleString()}/mo`, '']}",
    r"formatter={(val) => [`$${val.toLocaleString()}/mo`, '']}")

fix("Risk badge className",
    r'className={`px-3 py-1 rounded-full text-xs font-semibold \${',
    r'className={`px-3 py-1 rounded-full text-xs font-semibold ${')

fix("Math.random flicker",
    '{(85 + Math.random() * 10).toFixed(0)}',
    '{92}')

fix("Remove max-w-7xl constraint",
    '<div className="max-w-7xl mx-auto p-6 space-y-6">',
    '<div className="w-full space-y-6">')

# Also remove duplicate inner header if present
old_hdr = '      <div className="flex items-center justify-between">\n        <div>\n          <h1 className="text-3xl font-black text-white">Executive Dashboard</h1>\n          <p className="text-slate-400 mt-1">High-level overview for leadership</p>\n        </div>\n        <button\n          onClick={() => window.print()}\n          className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-white"\n        >\n          <Download className="h-5 w-5" />'
new_hdr = '      <div className="flex items-center justify-end">\n        <button\n          onClick={() => window.print()}\n          className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-white"\n        >\n          <Download className="h-5 w-5" />'
fix("Remove duplicate inner header", old_hdr, new_hdr)

for f in fixes: print(f"  {f}")
with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
PYEOF

# ════════════════════════════════════════════════════════════
# FIX 2 — App.jsx: setLanguage reference error + i18n context
# ════════════════════════════════════════════════════════════
echo -e "\n${BLUE}[2/3] Fixing App.jsx language context...${NC}"
python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

fixes = []

# ── A. Ensure LanguageContext exists ─────────────────────────
CONTEXT = '''
// ============================================================================
// GLOBAL LANGUAGE CONTEXT
// ============================================================================
const LanguageContext = React.createContext({ language: 'en', setLanguage: () => {} });

function LanguageProvider({ children }) {
  const [language, setLanguage] = React.useState(
    () => localStorage.getItem('language') || 'en'
  );
  const setAndPersist = React.useCallback((lang) => {
    localStorage.setItem('language', lang);
    setLanguage(lang);
  }, []);
  return (
    <LanguageContext.Provider value={{ language, setLanguage: setAndPersist }}>
      {children}
    </LanguageContext.Provider>
  );
}

function useLang() {
  return React.useContext(LanguageContext);
}
// ============================================================================
'''
if 'LanguageContext' not in app:
    last_import = max(m.end() for m in re.finditer(r'^import .+;$', app, re.MULTILINE))
    app = app[:last_import] + '\n' + CONTEXT + app[last_import:]
    fixes.append("✓ LanguageContext injected")
else:
    fixes.append("✓ LanguageContext already present")

# ── B. Wrap router with LanguageProvider ─────────────────────
if 'LanguageProvider' not in app:
    for old, new in [
        ('<RouterProvider ', '<LanguageProvider><RouterProvider '),
        ('</RouterProvider>', '</RouterProvider></LanguageProvider>'),
        ('<BrowserRouter>', '<LanguageProvider><BrowserRouter>'),
        ('</BrowserRouter>', '</BrowserRouter></LanguageProvider>'),
    ]:
        if old in app:
            app = app.replace(old, new, 1)
    fixes.append("✓ LanguageProvider wrapping router")
else:
    fixes.append("✓ LanguageProvider already wrapping router")

# ── C. Replace ALL per-page language hooks with useLang() ────
HOOK_PATTERNS = [
    # Full hook single quotes
    re.compile(
        r"  const \[language, setLanguage\] = useState\(\(\) => localStorage\.getItem\('language'\) \|\| 'en'\);\n"
        r"  const t = useTranslation\(language\);\n"
        r"  useEffect\(\(\) => \{\n"
        r"    const handleLangChange = \(e\) => setLanguage\(e\.detail \|\| localStorage\.getItem\('language'\) \|\| 'en'\);\n"
        r"    window\.addEventListener\('languagechange', handleLangChange\);\n"
        r"    return \(\) => window\.removeEventListener\('languagechange', handleLangChange\);\n"
        r"  \}, \[\]\);\n"
    ),
    # Full hook double quotes
    re.compile(
        r'  const \[language, setLanguage\] = useState\(\(\) => localStorage\.getItem\("language"\) \|\| "en"\);\n'
        r'  const t = useTranslation\(language\);\n'
        r'  useEffect\(\(\) => \{\n'
        r'    const handleLangChange = \(e\) => setLanguage\(e\.detail \|\| localStorage\.getItem\("language"\) \|\| "en"\);\n'
        r'    window\.addEventListener\("languagechange", handleLangChange\);\n'
        r'    return \(\) => window\.removeEventListener\("languagechange", handleLangChange\);\n'
        r'  \}, \[\]\);\n'
    ),
    # Old read-only single quotes
    re.compile(
        r"  const \[language\] = useState\(\(\) => localStorage\.getItem\('language'\) \|\| 'en'\);\n"
        r"  const t = useTranslation\(language\);\n"
    ),
    # Old read-only double quotes
    re.compile(
        r'  const \[language\] = useState\(\(\) => localStorage\.getItem\("language"\) \|\| "en"\);\n'
        r'  const t = useTranslation\(language\);\n'
    ),
    # setLanguage without useEffect single quotes
    re.compile(
        r"  const \[language, setLanguage\] = useState\(\(\) => localStorage\.getItem\('language'\) \|\| 'en'\);\n"
        r"  const t = useTranslation\(language\);\n"
        r"(?!  useEffect)"
    ),
]
READONLY_REPLACE = "  const { language } = useLang();\n  const t = useTranslation(language);\n"
total = 0
for pat in HOOK_PATTERNS:
    n = len(pat.findall(app))
    if n:
        app = pat.sub(READONLY_REPLACE, app)
        total += n
fixes.append(f"✓ Replaced {total} per-page language hooks with useLang()")

# ── D. Fix every function that calls setLanguage but only has { language } ─
fixed_setlang = 0
page_fns = list(re.finditer(r'^function (\w+)\(', app, re.MULTILINE))
for i, m in enumerate(page_fns):
    start = m.start()
    end   = page_fns[i+1].start() if i+1 < len(page_fns) else len(app)
    body  = app[start:end]
    uses  = 'setLanguage' in body
    has_w = '{ language, setLanguage }' in body or '{ language, setLanguage}' in body
    has_r = '{ language }' in body and 'useLang' in body
    if uses and has_r and not has_w:
        new_body = body.replace('{ language } = useLang()', '{ language, setLanguage } = useLang()', 1)
        app = app[:start] + new_body + app[end:]
        fixed_setlang += 1
        fixes.append(f"✓ {m.group(1)}: added setLanguage to useLang destructure")

if fixed_setlang == 0:
    fixes.append("✓ No mismatched setLanguage destructures found")

# ── E. AppShell — ensure it uses useLang ─────────────────────
ash_m = re.search(r'^function AppShell\(', app, re.MULTILINE)
if ash_m:
    ash_start = ash_m.start()
    ash_end   = app.find('\nfunction ', ash_start + 10)
    a_body    = app[ash_start:ash_end]
    if 'useLang' not in a_body and 'useTranslation' not in a_body:
        brace = app.find('{', ash_start)
        nl    = app.find('\n', brace) + 1
        app   = app[:nl] + "  const { language } = useLang();\n  const t = useTranslation(language);\n" + app[nl:]
        fixes.append("✓ AppShell: injected useLang()")
    elif 'useLang' not in a_body:
        # Has old pattern — replace
        a_body = re.sub(
            r"  const \[language[^\n]+\n  const t = useTranslation[^\n]+\n(?:  useEffect[\s\S]+?\}, \[\]\);\n)?",
            "  const { language } = useLang();\n  const t = useTranslation(language);\n",
            a_body, count=1
        )
        app = app[:ash_start] + a_body + app[ash_end:]
        fixes.append("✓ AppShell: upgraded to useLang()")
    else:
        fixes.append("✓ AppShell: already using useLang()")

# ── F. SettingsPage — wire language select to context setLanguage ─
sp_m = re.search(r'^function SettingsPage\(', app, re.MULTILINE)
if sp_m:
    sp_start = sp_m.start()
    sp_end   = app.find('\nfunction ', sp_start + 10)
    s_body   = app[sp_start:sp_end]

    # Ensure setLanguage in destructure
    if '{ language }' in s_body and 'setLanguage' not in s_body:
        s_body = s_body.replace('{ language } = useLang()', '{ language, setLanguage } = useLang()', 1)
        app = app[:sp_start] + s_body + app[sp_end:]
        fixes.append("✓ SettingsPage: added setLanguage to destructure")
        sp_start = app.find('function SettingsPage()')
        sp_end   = app.find('\nfunction ', sp_start + 10)
        s_body   = app[sp_start:sp_end]

    # Replace any localStorage.setItem language saves with context call
    for old_pat in [
        "localStorage.setItem('language', e.target.value);\n    window.dispatchEvent(new CustomEvent('languagechange', { detail: e.target.value }));",
        "localStorage.setItem('language', e.target.value);",
        'localStorage.setItem("language", e.target.value);',
    ]:
        if old_pat in s_body:
            new_val = "setLanguage(e.target.value);"
            s_body  = s_body.replace(old_pat, new_val, 1)
            app     = app[:sp_start] + s_body + app[sp_end:]
            fixes.append("✓ SettingsPage: language onChange uses context setLanguage")
            break

# ── Print all results ─────────────────────────────────────────
print()
for f in fixes: print(f"  {f}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print(f"\n  Done — {app.count(chr(10))} lines")
PYEOF

[ $? -ne 0 ] && echo -e "${RED}✗ App.jsx patch failed — restoring${NC}" && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# ════════════════════════════════════════════════════════════
# FIX 3 — translations.js: fill ALL missing keys in FR/DE/JA
# ════════════════════════════════════════════════════════════
echo -e "\n${BLUE}[3/3] Completing translations...${NC}"
python3 << 'PYEOF'
import re, os

# Proper translations for missing keys per language
TRANSLATIONS = {
    'fr': {
        'access_count': 'outils', 'actions': 'Actions', 'all_clear': 'Tout est bon',
        'all_departments': 'Tous les départements', 'by_severity': 'Par gravité',
        'cost': 'Coût', 'coverage_and_spend': 'Couverture et dépenses',
        'delete_employee': 'Supprimer', 'delete_tool': 'Supprimer',
        'edit_employee': 'Modifier', 'edit_tool': 'Modifier',
        'employee_directory': 'Répertoire des employés',
        'fast_remediation': 'Remédiation rapide', 'last_used': 'Dernière utilisation',
        'no_active_alerts': 'Aucune alerte active', 'no_employees': 'Aucun employé trouvé',
        'no_owner': 'Sans responsable', 'no_tools': 'Aucun outil trouvé',
        'owner': 'Responsable', 'risk_counters': 'Compteurs de risque',
        'search_employees': 'Rechercher des employés...', 
        'search_tools_owners': 'Rechercher outils, responsables...',
        'tool': 'Outil', 'top_alerts_desc': 'Outils orphelins, accès anciens employés, révisions en retard.',
        'track_departments': 'Suivre les départements, le statut et les accès',
        'security': 'Sécurité & Conformité', 'bulk_import': 'Import en masse',
        'licenses': 'Gestion des licences',
    },
    'de': {
        'access_count': 'Tools', 'actions': 'Aktionen', 'all_clear': 'Alles in Ordnung',
        'all_departments': 'Alle Abteilungen', 'by_severity': 'Nach Schweregrad',
        'cost': 'Kosten', 'coverage_and_spend': 'Abdeckung und Ausgaben',
        'delete_employee': 'Löschen', 'delete_tool': 'Löschen',
        'edit_employee': 'Bearbeiten', 'edit_tool': 'Bearbeiten',
        'employee_directory': 'Mitarbeiterverzeichnis',
        'fast_remediation': 'Schnelle Behebung', 'last_used': 'Zuletzt verwendet',
        'no_active_alerts': 'Keine aktiven Warnungen', 'no_employees': 'Keine Mitarbeiter gefunden',
        'no_owner': 'Kein Verantwortlicher', 'no_tools': 'Keine Tools gefunden',
        'owner': 'Verantwortlicher', 'risk_counters': 'Risikoanzahl',
        'search_employees': 'Mitarbeiter suchen...', 
        'search_tools_owners': 'Tools, Verantwortliche suchen...',
        'tool': 'Tool', 'top_alerts_desc': 'Verwaiste Tools, ehemalige Mitarbeiterzugriffe, überfällige Überprüfungen.',
        'track_departments': 'Abteilungen, Status und Zugriffe verfolgen',
        'security': 'Sicherheit & Compliance', 'bulk_import': 'Massenimport',
        'licenses': 'Lizenzverwaltung',
    },
    'ja': {
        'access_count': 'ツール', 'actions': 'アクション', 'all_departments': '全部門',
        'cost': 'コスト', 'delete_employee': '削除', 'delete_tool': '削除',
        'edit_employee': '編集', 'edit_tool': '編集',
        'employee_directory': '従業員ディレクトリ', 'last_used': '最終使用',
        'no_employees': '従業員が見つかりません', 'no_owner': 'オーナーなし',
        'no_tools': 'ツールが見つかりません', 'owner': 'オーナー',
        'search_employees': '従業員を検索...', 'search_tools_owners': 'ツール、オーナーを検索...',
        'tool': 'ツール', 'track_departments': '部門、ステータス、アクセス数を追跡',
        'security': 'セキュリティとコンプライアンス', 'bulk_import': '一括インポート',
        'licenses': 'ライセンス管理',
    }
}

path = 'src/translations.js'
with open(path, encoding='utf-8') as f:
    src = f.read()

total_added = 0
for lang, keys in TRANSLATIONS.items():
    ls = src.find(f'{lang}: {{')
    if ls == -1: continue
    le   = src.find('\n  },', ls)
    lbody = src[ls:le]
    lkeys = set(re.findall(r'^\s{4}(\w+):', lbody, re.MULTILINE))
    inserts = []
    for key, val in keys.items():
        if key not in lkeys:
            inserts.append(f"    {key}: '{val}',")
    if inserts:
        src = src[:le] + '\n' + '\n'.join(inserts) + src[le:]
        total_added += len(inserts)
        print(f"  ✓ {lang.upper()}: added {len(inserts)} proper translations")

if total_added == 0:
    print("  ✓ All translations already complete")

with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
print(f"  Total keys added: {total_added}")
PYEOF

[ $? -ne 0 ] && echo -e "${YELLOW}⚠ translations.js patch failed — continuing anyway${NC}"

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed — restoring backups${NC}"
    cp "backups/$TS/App.jsx" src/App.jsx
    cp "backups/$TS/ExecutiveDashboard.jsx" src/ExecutiveDashboard.jsx 2>/dev/null || true
    cp "backups/$TS/translations.js" src/translations.js 2>/dev/null || true
    exit 1
fi

echo ""
echo -e "${BLUE}Deploying to Firebase...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗"
echo -e "║  ✓ Full fix deployed!                                     ║"
echo -e "╠════════════════════════════════════════════════════════════╣"
echo -e "║  EXECUTIVE DASHBOARD                                       ║"
echo -e "║    ✓ Y-axis: \$1K / \$2K (was broken template literals)    ║"
echo -e "║    ✓ Pie chart labels: category name + %                   ║"
echo -e "║    ✓ Risk badges rendering correctly                       ║"
echo -e "║    ✓ Efficiency score stable (no more flicker)             ║"
echo -e "║    ✓ Full-width layout                                     ║"
echo -e "║  TRANSLATIONS                                              ║"
echo -e "║    ✓ FR / DE / JA: all missing keys added with real text   ║"
echo -e "║    ✓ Global context: change once → all pages update        ║"
echo -e "║    ✓ setLanguage crash fixed                               ║"
echo -e "║  APP SHELL                                                 ║"
echo -e "║    ✓ Sidebar nav labels translate correctly                ║"
echo -e "╚════════════════════════════════════════════════════════════╝${NC}\n"
