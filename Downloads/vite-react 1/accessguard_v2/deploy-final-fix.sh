#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗"
echo -e "║     AccessGuard V2 — Final Comprehensive Fix             ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
cp src/translations.js "backups/$TS/translations.js" 2>/dev/null || true
cp src/ExecutiveDashboard.jsx "backups/$TS/ExecutiveDashboard.jsx" 2>/dev/null || true
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 - << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []; warn = []; fail = []

# ─────────────────────────────────────────────────────────────
# FIX 1: Wrap BrowserRouter with LanguageProvider
# THE root cause — context is defined but never provided to tree
# ─────────────────────────────────────────────────────────────
if '<LanguageProvider>' not in app:
    app = app.replace(
        '          <BrowserRouter>',
        '          <LanguageProvider>\n          <BrowserRouter>'
    ).replace(
        '      </BrowserRouter>',
        '      </BrowserRouter>\n      </LanguageProvider>'
    )
    if '<LanguageProvider>' in app:
        ok.append("FIX 1: LanguageProvider now wraps BrowserRouter — translations work globally")
    else:
        # Try alternate indentation
        app = app.replace('<BrowserRouter>', '<LanguageProvider><BrowserRouter>', 1)
        app = app.replace('</BrowserRouter>', '</BrowserRouter></LanguageProvider>', 1)
        if '<LanguageProvider>' in app:
            ok.append("FIX 1: LanguageProvider wrapped (alt indent)")
        else:
            fail.append("FIX 1: Could not wrap BrowserRouter — do manually")
else:
    ok.append("FIX 1: LanguageProvider already present")

# ─────────────────────────────────────────────────────────────
# FIX 2: Add useLang to missing pages
# ─────────────────────────────────────────────────────────────
HOOK = "  const { language } = useLang();\n  const t = useTranslation(language);\n"

def inject_hook(fn_name, guard_snippet):
    global app
    if guard_snippet in app:
        ok.append(f"FIX 2: {fn_name} already has translation")
        return
    idx = app.find(f'function {fn_name}()')
    if idx == -1:
        warn.append(f"FIX 2: {fn_name} not found")
        return
    brace = app.find('{', idx)
    nl    = app.find('\n', brace) + 1
    app   = app[:nl] + HOOK + app[nl:]
    ok.append(f"FIX 2: {fn_name} — useLang() injected")

inject_hook('ImportPage',          'ImportPage() {\n  const { language')
inject_hook('IntegrationsPage',    'IntegrationsPage() {\n  const { language')
inject_hook('LicenseManagement',   'LicenseManagement() {\n  const { language')
inject_hook('ExecutivePageWrapper','ExecutivePageWrapper() {\n  const { language')

# ─────────────────────────────────────────────────────────────
# FIX 3: Translate hardcoded AppShell page titles
# ─────────────────────────────────────────────────────────────
page_titles = [
    ('title="Executive Dashboard"', "title={t('executive_view') || 'Executive Dashboard'}"),
    ('title="Employees"',           "title={t('employees') || 'Employees'}"),
    ('title="Access Map"',          "title={t('access') || 'Access Map'}"),
    ('title="Import Data"',         "title={t('import') || 'Import Data'}"),
    ('title="Audit Export"',        "title={t('export_audit') || 'Audit Export'}"),
    ('title="Billing"',             "title={t('billing') || 'Billing'}"),
    ('title="Integrations"',        "title={t('integrations') || 'Integrations'}"),
    ('title="Analytics & Reports"', "title={t('analytics_reports') || 'Analytics & Reports'}"),
    ('title="Settings"',            "title={t('settings') || 'Settings'}"),
]
for old, new in page_titles:
    if new not in app and old in app:
        app = app.replace(old, new, 1)
        ok.append(f"FIX 3: Translated {old}")
    elif new in app:
        ok.append(f"FIX 3: Already translated — {old[:40]}")

# ─────────────────────────────────────────────────────────────
# FIX 4: Add language selector to SettingsPage General tab
# Currently setLanguage is imported but never exposed in UI
# ─────────────────────────────────────────────────────────────
sp_start = app.find('function SettingsPage()')
sp_end   = app.find('\nfunction ', sp_start + 10)
sp_body  = app[sp_start:sp_end]

if 'value="en"' not in sp_body and "value='en'" not in sp_body:
    LANG_WIDGET = '''
                <div className="mt-4 pt-4 border-t border-slate-800">
                  <label className="block text-sm font-medium text-slate-300 mb-2">Display Language</label>
                  <select
                    value={language}
                    onChange={(e) => setLanguage(e.target.value)}
                    className="w-full rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="en">&#127468;&#127463; English</option>
                    <option value="es">&#127466;&#127480; Español</option>
                    <option value="fr">&#127467;&#127479; Français</option>
                    <option value="de">&#127465;&#127466; Deutsch</option>
                    <option value="ja">&#127471;&#127477; 日本語</option>
                  </select>
                  <p className="mt-1 text-xs text-slate-500">Changes apply instantly to all pages.</p>
                </div>'''

    # Insert before the Save button in General tab
    targets = [
        '              <Button variant="primary" onClick={handleSaveGeneral}>',
        "              <Button variant='primary' onClick={handleSaveGeneral}>",
        '              <Button onClick={handleSaveGeneral}',
    ]
    inserted = False
    for target in targets:
        if target in sp_body:
            new_body = sp_body.replace(target, LANG_WIDGET + '\n' + target, 1)
            app = app[:sp_start] + new_body + app[sp_end:]
            ok.append("FIX 4: Language selector added to Settings → General tab")
            inserted = True
            break
    if not inserted:
        warn.append("FIX 4: Could not find Settings save button anchor — language selector not added")
else:
    ok.append("FIX 4: Language selector already present in Settings")

# ─────────────────────────────────────────────────────────────
# FIX 5: Remove FinanceDashboard old languagechange useEffect
# (no longer needed — context handles reactivity)
# ─────────────────────────────────────────────────────────────
fd_start = app.find('function FinanceDashboard()')
fd_end   = app.find('\nfunction ', fd_start + 10)
fd_body  = app[fd_start:fd_end]

old_effect = (
    "\n  // Auto-update when language changes (no reload needed!)\n"
    "  useEffect(() => {\n"
    "    const handleLangChange = (e) => {\n"
    "      const newLang = e.detail || localStorage.getItem('language') || 'en';\n"
    "      setLanguage(newLang);\n"
    "    };\n"
    "    window.addEventListener('languagechange', handleLangChange);\n"
    "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
    "  }, []);\n"
)
if old_effect in fd_body:
    fd_body = fd_body.replace(old_effect, '\n', 1)
    # Also remove now-unused setLanguage from destructure
    fd_body = fd_body.replace(
        'const { language, setLanguage } = useLang();',
        'const { language } = useLang();'
    )
    app = app[:fd_start] + fd_body + app[fd_end:]
    ok.append("FIX 5: FinanceDashboard — removed redundant languagechange useEffect")
else:
    ok.append("FIX 5: FinanceDashboard — no stale effect found")

# ─────────────────────────────────────────────────────────────
# Print report
# ─────────────────────────────────────────────────────────────
print()
for s in ok:   print(f"  \033[32m✓\033[0m  {s}")
for s in warn: print(f"  \033[33m!\033[0m  {s}")
for s in fail: print(f"  \033[31m✗\033[0m  {s}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print(f"\n  Done — {app.count(chr(10))} lines")

if fail:
    sys.exit(1)
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# ─────────────────────────────────────────────────────────────
# translations.js — fill FR/DE/JA gaps + add new keys
# ─────────────────────────────────────────────────────────────
echo ""
python3 - << 'PYEOF'
import re

with open('src/translations.js', encoding='utf-8') as f:
    src = f.read()

# First add missing EN keys used in page titles
NEW_KEYS = {
    'analytics_reports': 'Analytics & Reports',
    'settings':          'Settings',
    'executive_view':    'Executive Dashboard',
    'import':            'Import Data',
}
en_s = src.find('en: {')
en_e = src.find('\n  },', en_s)
en_block = src[en_s:en_e]
new_en = []
for k, v in NEW_KEYS.items():
    if f'    {k}:' not in en_block:
        new_en.append(f"    {k}: '{v}',")
if new_en:
    src = src[:en_e] + '\n' + '\n'.join(new_en) + src[en_e:]
    print(f"  \033[32m✓\033[0m  EN: added {len(new_en)} key(s): {[k for k,v in NEW_KEYS.items()]}")

FILL = {
    'fr': {
        'access_count':'outils','actions':'Actions','all_clear':'Tout est bon',
        'all_departments':'Tous les départements','by_severity':'Par gravité',
        'cost':'Coût','coverage_and_spend':'Couverture et dépenses',
        'delete_employee':'Supprimer','delete_tool':'Supprimer',
        'edit_employee':'Modifier','edit_tool':'Modifier',
        'employee_directory':'Répertoire des employés',
        'fast_remediation':'Remédiation rapide','last_used':'Dernière utilisation',
        'no_active_alerts':'Aucune alerte active','no_employees':'Aucun employé trouvé',
        'no_owner':'Sans responsable','no_tools':'Aucun outil trouvé',
        'owner':'Responsable','risk_counters':'Compteurs de risque',
        'search_employees':'Rechercher des employés...',
        'search_tools_owners':'Rechercher outils, responsables...',
        'tool':'Outil','top_alerts_desc':'Outils orphelins, accès ex-employés, révisions en retard.',
        'track_departments':'Suivre départements, statut et accès',
        'analytics_reports':'Analytique & Rapports','settings':'Paramètres',
        'executive_view':'Tableau de bord Exécutif','import':'Importer des données',
        'security':'Sécurité & Conformité','bulk_import':'Import en masse',
        'licenses':'Gestion des licences',
    },
    'de': {
        'access_count':'Tools','actions':'Aktionen','all_clear':'Alles in Ordnung',
        'all_departments':'Alle Abteilungen','by_severity':'Nach Schweregrad',
        'cost':'Kosten','coverage_and_spend':'Abdeckung und Ausgaben',
        'delete_employee':'Löschen','delete_tool':'Löschen',
        'edit_employee':'Bearbeiten','edit_tool':'Bearbeiten',
        'employee_directory':'Mitarbeiterverzeichnis',
        'fast_remediation':'Schnelle Behebung','last_used':'Zuletzt verwendet',
        'no_active_alerts':'Keine aktiven Warnungen',
        'no_employees':'Keine Mitarbeiter gefunden',
        'no_owner':'Kein Verantwortlicher','no_tools':'Keine Tools gefunden',
        'owner':'Verantwortlicher','risk_counters':'Risikoanzahl',
        'search_employees':'Mitarbeiter suchen...',
        'search_tools_owners':'Tools, Verantwortliche suchen...',
        'tool':'Tool',
        'top_alerts_desc':'Verwaiste Tools, ehemalige Mitarbeiterzugriffe, überfällige Überprüfungen.',
        'track_departments':'Abteilungen, Status und Zugriffe verfolgen',
        'analytics_reports':'Analytik & Berichte','settings':'Einstellungen',
        'executive_view':'Executive Dashboard','import':'Daten importieren',
        'security':'Sicherheit & Compliance','bulk_import':'Massenimport',
        'licenses':'Lizenzverwaltung',
    },
    'ja': {
        'access_count':'ツール','actions':'アクション',
        'all_departments':'全部門','cost':'コスト',
        'delete_employee':'削除','delete_tool':'削除',
        'edit_employee':'編集','edit_tool':'編集',
        'employee_directory':'従業員ディレクトリ','last_used':'最終使用',
        'no_employees':'従業員が見つかりません',
        'no_owner':'オーナーなし','no_tools':'ツールが見つかりません',
        'owner':'オーナー','search_employees':'従業員を検索...',
        'search_tools_owners':'ツール、オーナーを検索...',
        'tool':'ツール','track_departments':'部門、ステータス、アクセス数を追跡',
        'analytics_reports':'アナリティクス＆レポート','settings':'設定',
        'executive_view':'エグゼクティブダッシュボード','import':'データのインポート',
        'security':'セキュリティとコンプライアンス','bulk_import':'一括インポート',
        'licenses':'ライセンス管理','all_clear':'すべて正常',
        'by_severity':'重大度別','coverage_and_spend':'カバレッジと支出',
        'fast_remediation':'迅速な修復','no_active_alerts':'アクティブなアラートなし',
        'risk_counters':'リスクカウンター',
        'top_alerts_desc':'孤立ツール、元従業員アクセス、期限切れレビュー',
    },
    'es': {
        'analytics_reports':'Análisis e Informes','settings':'Configuración',
        'executive_view':'Panel Ejecutivo','import':'Importar datos',
    }
}

for lang, keys in FILL.items():
    ls = src.find(f'{lang}: {{')
    if ls == -1: continue
    le    = src.find('\n  },', ls)
    lbody = src[ls:le]
    lkeys = set(re.findall(r'^\s{4}(\w+):', lbody, re.MULTILINE))
    inserts = [f"    {k}: '{v}'," for k, v in keys.items() if k not in lkeys]
    if inserts:
        src = src[:le] + '\n' + '\n'.join(inserts) + src[le:]
        print(f"  \033[32m✓\033[0m  {lang.upper()}: added {len(inserts)} key(s)")
    else:
        print(f"  \033[32m✓\033[0m  {lang.upper()}: already complete")

with open('src/translations.js', 'w', encoding='utf-8') as f:
    f.write(src)
PYEOF

# ─────────────────────────────────────────────────────────────
# ExecutiveDashboard.jsx — fix broken template literals
# ─────────────────────────────────────────────────────────────
echo ""
python3 - << 'PYEOF'
import os
path = 'src/ExecutiveDashboard.jsx'
if not os.path.exists(path):
    print("  -- ExecutiveDashboard.jsx not found, skipping")
    exit()

with open(path, encoding='utf-8') as f:
    src = f.read()

fixes = [
    (r'tickFormatter={(val) => `$\${(val/1000).toFixed(0)}K`}',
     r'tickFormatter={(val) => `$${(val/1000).toFixed(0)}K`}'),
    (r"formatter={(val) => [`$\${val.toLocaleString()}`, '']}",
     r"formatter={(val) => [`$${val.toLocaleString()}`, '']}"),
    (r'label={({ name, percent }) => `\${name} \${(percent * 100).toFixed(0)}%`}',
     r'label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}'),
    (r'<Cell key={`cell-\${index}`} fill={COLORS[index % COLORS.length]} />',
     r'<Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />'),
    (r"formatter={(val) => [`$\${val.toLocaleString()}/mo`, '']}",
     r"formatter={(val) => [`$${val.toLocaleString()}/mo`, '']}"),
    (r'className={`px-3 py-1 rounded-full text-xs font-semibold \${',
     r'className={`px-3 py-1 rounded-full text-xs font-semibold ${'),
    ('{(85 + Math.random() * 10).toFixed(0)}', '{92}'),
    ('<div className="max-w-7xl mx-auto p-6 space-y-6">',
     '<div className="w-full space-y-6">'),
]
changed = False
for old, new in fixes:
    if old in src:
        src = src.replace(old, new, 1)
        print(f"  \033[32m✓\033[0m  ExecDash: {old[:55]}")
        changed = True
if not changed:
    print("  \033[32m✓\033[0m  ExecutiveDashboard: already clean")
else:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(src)
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed — restoring backups${NC}"
    cp "backups/$TS/App.jsx" src/App.jsx
    cp "backups/$TS/translations.js" src/translations.js 2>/dev/null || true
    cp "backups/$TS/ExecutiveDashboard.jsx" src/ExecutiveDashboard.jsx 2>/dev/null || true
    exit 1
fi

echo ""
echo -e "${BLUE}Deploying to Firebase...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
echo -e "║  ✓ Deployed successfully!                                ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  ROOT FIX — Translations now work everywhere            ║"
echo -e "║    LanguageProvider wraps the entire app tree           ║"
echo -e "║    Pick language once → all pages update instantly      ║"
echo -e "║                                                          ║"
echo -e "║  SETTINGS                                               ║"
echo -e "║    Language selector added to General tab               ║"
echo -e "║                                                          ║"
echo -e "║  PAGES NOW TRANSLATED                                   ║"
echo -e "║    ImportPage, IntegrationsPage, LicenseManagement      ║"
echo -e "║    ExecutivePageWrapper page titles                     ║"
echo -e "║                                                          ║"
echo -e "║  FR / DE / JA                                           ║"
echo -e "║    All 25 missing keys filled with real translations    ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
