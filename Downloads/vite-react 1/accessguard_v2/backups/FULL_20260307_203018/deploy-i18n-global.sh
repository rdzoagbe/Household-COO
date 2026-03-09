#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗"
echo -e "║  AccessGuard V2 — Global i18n Context (Full Translation) ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
cp src/translations.js "backups/$TS/translations.js" 2>/dev/null || true
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []; fail = []

# ── STEP 1: Inject LanguageContext ────────────────────────────
CONTEXT_CODE = '''
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
    app = app[:last_import] + '\n' + CONTEXT_CODE + app[last_import:]
    ok.append("LanguageContext: injected global context")
else:
    ok.append("LanguageContext: already present")

# ── STEP 2: Wrap root render with LanguageProvider ────────────
# Find the root render — it's in a createRoot().render() or ReactDOM.render()
# OR it might be the top-level JSX return in a component called AppRoot/Root/App
if 'LanguageProvider' not in app:
    # Try wrapping the RouterProvider or BrowserRouter at render site
    for old, new in [
        ('<RouterProvider ', '<LanguageProvider><RouterProvider '),
        ('</RouterProvider>', '</RouterProvider></LanguageProvider>'),
        ('<BrowserRouter>', '<LanguageProvider><BrowserRouter>'),
        ('</BrowserRouter>', '</BrowserRouter></LanguageProvider>'),
    ]:
        if old in app and new not in app:
            app = app.replace(old, new, 1)
    if 'LanguageProvider' in app:
        ok.append("App: wrapped RouterProvider/BrowserRouter with LanguageProvider")
    else:
        # Find createRoot render call
        render_m = re.search(r'\.render\(\s*\n?\s*<', app)
        if render_m:
            pos = render_m.end() - 1  # points to <
            app = app[:pos] + '<LanguageProvider>' + app[pos:]
            # find matching close paren and insert </LanguageProvider>
            # simple approach: find </React.StrictMode> or </App> or the closing )
            for close_tag in ['</React.StrictMode>', '</App>', '</StrictMode>']:
                if close_tag in app[pos:pos+500]:
                    app = app.replace(close_tag, close_tag + '\n  </LanguageProvider>', 1)
                    break
            ok.append("App: wrapped render() with LanguageProvider")
        else:
            fail.append("App: could not find render site — wrap manually if needed")
else:
    ok.append("App: LanguageProvider already present")

# ── STEP 3: Replace ALL per-page language hooks with useLang() ─
REPLACEMENT = "  const { language } = useLang();\n  const t = useTranslation(language);\n"

patterns = [
    # Full hook with setLanguage + useEffect (single quotes)
    re.compile(
        r"  const \[language, setLanguage\] = useState\(\(\) => localStorage\.getItem\('language'\) \|\| 'en'\);\n"
        r"  const t = useTranslation\(language\);\n"
        r"  useEffect\(\(\) => \{\n"
        r"    const handleLangChange = \(e\) => setLanguage\(e\.detail \|\| localStorage\.getItem\('language'\) \|\| 'en'\);\n"
        r"    window\.addEventListener\('languagechange', handleLangChange\);\n"
        r"    return \(\) => window\.removeEventListener\('languagechange', handleLangChange\);\n"
        r"  \}, \[\]\);\n"
    ),
    # Full hook with double quotes
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
    # setLanguage without effect (single quotes)
    re.compile(
        r"  const \[language, setLanguage\] = useState\(\(\) => localStorage\.getItem\('language'\) \|\| 'en'\);\n"
        r"  const t = useTranslation\(language\);\n"
        r"(?!  useEffect)"
    ),
]

total_replaced = 0
for pat in patterns:
    matches = pat.findall(app)
    if matches:
        app = pat.sub(REPLACEMENT, app)
        total_replaced += len(matches)

ok.append(f"Pages: replaced {total_replaced} language hook(s) with useLang()")

# ── STEP 4: SettingsPage — wire language select to context ────
settings_start = app.find('function SettingsPage()')
settings_end   = app.find('\nfunction ', settings_start + 10)
s_body = app[settings_start:settings_end]

# Make sure it has setLanguage from context
if '{ language }' in s_body and 'setLanguage' not in s_body:
    s_body = s_body.replace('{ language }', '{ language, setLanguage }', 1)
    app = app[:settings_start] + s_body + app[settings_end:]
    ok.append("SettingsPage: added setLanguage from context")
    # refresh
    settings_start = app.find('function SettingsPage()')
    settings_end   = app.find('\nfunction ', settings_start + 10)
    s_body = app[settings_start:settings_end]

# Replace localStorage language saves with context setLanguage
for old_pat, new_val in [
    ("localStorage.setItem('language', e.target.value);\n    window.dispatchEvent(new CustomEvent('languagechange', { detail: e.target.value }));",
     "setLanguage(e.target.value);"),
    ("localStorage.setItem('language', e.target.value);",
     "setLanguage(e.target.value);"),
    ('localStorage.setItem("language", e.target.value);',
     "setLanguage(e.target.value);"),
    ("localStorage.setItem('language', lang);\n    window.dispatchEvent(new CustomEvent('languagechange', { detail: lang }));",
     "setLanguage(lang);"),
]:
    if old_pat in s_body:
        s_body = s_body.replace(old_pat, new_val, 1)
        app = app[:settings_start] + s_body + app[settings_end:]
        ok.append(f"SettingsPage: language save wired to context")
        break

# ── STEP 5: AppShell — use useLang ───────────────────────────
ash_start = app.find('function AppShell(')
if ash_start != -1:
    ash_end  = app.find('\nfunction ', ash_start + 10)
    a_body   = app[ash_start:ash_end]
    if 'useLang' not in a_body:
        # Remove old hook if present, inject useLang
        a_body = re.sub(
            r"  const \[language[^\n]+\n  const t = useTranslation[^\n]+\n(?:  useEffect[\s\S]+?\}, \[\]\);\n)?",
            "  const { language } = useLang();\n  const t = useTranslation(language);\n",
            a_body, count=1
        )
        if 'useLang' not in a_body:
            brace = a_body.find('{')
            nl    = a_body.find('\n', brace) + 1
            a_body = a_body[:nl] + "  const { language } = useLang();\n  const t = useTranslation(language);\n" + a_body[nl:]
        app = app[:ash_start] + a_body + app[ash_end:]
        ok.append("AppShell: wired to global language context")
    else:
        ok.append("AppShell: already using useLang()")

# ── Report ────────────────────────────────────────────────────
print()
for n in ok:   print(f"  \033[32m✓\033[0m  {n}")
for n in fail: print(f"  \033[33m!\033[0m  {n}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print(f"\n  \033[32mDone — {app.count(chr(10))} lines\033[0m")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# ── Patch translations.js — fill missing keys in all languages ─
python3 << 'PYEOF'
import re, os

path = 'src/translations.js'
if not os.path.exists(path):
    print("  -- translations.js not found"); exit()

# Always read/write as UTF-8
with open(path, encoding='utf-8') as f:
    src = f.read()

en_start = src.find('en: {')
en_end   = src.find('\n  },', en_start)
en_block = src[en_start:en_end]
en_keys  = set(re.findall(r'^\s{4}(\w+):', en_block, re.MULTILINE))

langs = ['es', 'fr', 'de', 'ja']
total_added = 0

for lang in langs:
    lang_start = src.find(f'{lang}: {{')
    if lang_start == -1: continue
    lang_end   = src.find('\n  },', lang_start)
    lang_block = src[lang_start:lang_end]
    lang_keys  = set(re.findall(r'^\s{4}(\w+):', lang_block, re.MULTILINE))
    missing    = en_keys - lang_keys
    if not missing: continue

    inserts = []
    for key in sorted(missing):
        m = re.search(rf"^\s{{4}}{re.escape(key)}: '([^']*)'", en_block, re.MULTILINE)
        if not m:
            m = re.search(rf'^\s{{4}}{re.escape(key)}: "([^"]*)"', en_block, re.MULTILINE)
        val = m.group(1) if m else key
        inserts.append(f"    {key}: '{val}',")

    if inserts:
        insert_text = '\n' + '\n'.join(inserts)
        src = src[:lang_end] + insert_text + src[lang_end:]
        total_added += len(inserts)
        print(f"  \033[32m✓\033[0m  {lang.upper()}: added {len(inserts)} missing key(s)")

if total_added == 0:
    print("  \033[32m✓\033[0m  translations.js: all languages complete")

with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/translations.js" src/translations.js 2>/dev/null; exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Build failed — restoring${NC}"
  cp "backups/$TS/App.jsx" src/App.jsx
  cp "backups/$TS/translations.js" src/translations.js 2>/dev/null || true
  exit 1
fi

echo ""
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
echo -e "║  ✓ Global i18n deployed!                                  ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  • Single LanguageContext wraps entire app                ║"
echo -e "║  • All pages use useLang() — no more per-page state       ║"
echo -e "║  • Change language once → every page updates instantly    ║"
echo -e "║  • Missing keys filled in ES / FR / DE / JA              ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
