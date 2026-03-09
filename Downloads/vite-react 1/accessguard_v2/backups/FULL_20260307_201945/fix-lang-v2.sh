#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fix: Language switching — correct provider wrapping${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 - << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []; warn = []

# ── STEP 1: Remove any bad LanguageProvider tags added by previous scripts ──
# Previous script added <LanguageProvider> after <QueryClientProvider> opening
# but never properly closed it — causing the mismatched tag error.
app = re.sub(r'\n      <LanguageProvider>\n', '\n', app)
app = re.sub(r'\n      </LanguageProvider>\n', '\n', app)
app = re.sub(r'\n    <LanguageProvider>\n', '\n', app)
app = re.sub(r'\n    </LanguageProvider>\n', '\n', app)
ok.append("Removed any malformed LanguageProvider tags from previous run")

# ── STEP 2: Wrap BrowserRouter correctly ────────────────────────────────────
# Exact strings from the file:
OLD_BROWSER  = "      <BrowserRouter>\n"
NEW_BROWSER  = "      <LanguageProvider>\n      <BrowserRouter>\n"
OLD_CLOSE    = "      </BrowserRouter>\n    </QueryClientProvider>"
NEW_CLOSE    = "      </BrowserRouter>\n      </LanguageProvider>\n    </QueryClientProvider>"

if '<LanguageProvider>' not in app:
    if OLD_BROWSER in app:
        app = app.replace(OLD_BROWSER, NEW_BROWSER, 1)
        ok.append("Wrapped <BrowserRouter> with <LanguageProvider>")
    if OLD_CLOSE in app:
        app = app.replace(OLD_CLOSE, NEW_CLOSE, 1)
        ok.append("Added </LanguageProvider> closing tag")
else:
    ok.append("LanguageProvider already present — skipping wrap")

# ── STEP 3: Fix SidebarFooter — use context not local state ─────────────────
OLD_LOCAL = "  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');\n"
NEW_CONTEXT = "  const { language, setLanguage } = useLang();\n"
if OLD_LOCAL in app:
    app = app.replace(OLD_LOCAL, NEW_CONTEXT, 1)
    ok.append("SidebarFooter: local useState → useLang() context")
elif NEW_CONTEXT in app[app.find('function SidebarFooter'):app.find('function SidebarFooter')+300]:
    ok.append("SidebarFooter: already uses useLang()")
else:
    warn.append("SidebarFooter: useState pattern not matched — check manually")

# ── STEP 4: Remove SidebarFooter localStorage sync useEffect ────────────────
OLD_SF_SYNC = (
    "\n  // Sync language from localStorage on mount\n"
    "  useEffect(() => {\n"
    "    const savedLang = localStorage.getItem('language');\n"
    "    if (savedLang && savedLang !== language) {\n"
    "      setLanguage(savedLang);\n"
    "    }\n"
    "  }, []);\n"
)
if OLD_SF_SYNC in app:
    app = app.replace(OLD_SF_SYNC, '\n')
    ok.append("SidebarFooter: removed stale localStorage sync useEffect")

# ── STEP 5: Fix changeLanguage — only call context setter ───────────────────
cl_m = re.search(r'  const changeLanguage = \(code\) => \{[^}]+\};', app, re.DOTALL)
if cl_m:
    body = cl_m.group()
    if 'dispatchEvent' in body or 'localStorage' in body:
        new_cl = (
            "  const changeLanguage = (code) => {\n"
            "    setLanguage(code);\n"
            "    setShowLangMenu(false);\n"
            "  };"
        )
        app = app[:cl_m.start()] + new_cl + app[cl_m.end():]
        ok.append("SidebarFooter: changeLanguage cleaned up")
    else:
        ok.append("SidebarFooter: changeLanguage already clean")

# ── STEP 6: Remove LanguageProvider's own event dispatch ────────────────────
OLD_LP_DISPATCH = "    window.dispatchEvent(new CustomEvent('languagechange', { detail: lang }));\n"
if OLD_LP_DISPATCH in app:
    app = app.replace(OLD_LP_DISPATCH, '')
    ok.append("LanguageProvider: removed redundant event dispatch")

# ── STEP 7: Remove all stale languagechange useEffect listeners ─────────────
STALE = (
    "    const handleLangChange = (e) => {\n"
    "      const newLang = e.detail || localStorage.getItem('language') || 'en';\n"
    "      setLanguage(newLang);\n"
    "    };\n"
    "    window.addEventListener('languagechange', handleLangChange);\n"
    "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
    "  }, []);\n"
)
count = 0
while STALE in app:
    idx = app.find(STALE)
    ue = app.rfind('\n  useEffect(() => {\n', 0, idx)
    cm = app.rfind('\n  //', 0, ue)
    start = cm if cm != -1 and ue - cm < 80 else ue
    app = app[:start] + '\n' + app[idx + len(STALE):]
    count += 1
if count:
    ok.append(f"Removed {count} stale languagechange listener(s)")

# ── STEP 8: Remove Sidebar force-sync useEffect ─────────────────────────────
FORCE = (
    "\n  // Force sync language from localStorage on mount\n"
    "  useEffect(() => {\n"
    "    const savedLang = localStorage.getItem('language');\n"
    "    if (savedLang && savedLang !== language) {\n"
    "      setLanguage(savedLang);\n"
    "    }\n"
    "  }, []);\n"
)
if FORCE in app:
    app = app.replace(FORCE, '\n')
    ok.append("Sidebar: removed force-sync useEffect")

# ── Verify JSX balance ───────────────────────────────────────────────────────
lp_open  = app.count('<LanguageProvider>')
lp_close = app.count('</LanguageProvider>')
qp_open  = app.count('<QueryClientProvider')
qp_close = app.count('</QueryClientProvider>')

print()
for s in ok:   print(f"  \033[32m✓\033[0m  {s}")
for s in warn: print(f"  \033[33m!\033[0m  {s}")
print(f"\n  <LanguageProvider>  open={lp_open}  close={lp_close}  {'✓' if lp_open==lp_close else '✗ MISMATCH'}")
print(f"  <QueryClientProvider> open={qp_open} close={qp_close} {'✓' if qp_open==qp_close else '✗ MISMATCH'}")
print(f"  Event listeners: {app.count('addEventListener')}")
print(f"  File lines: {app.count(chr(10))}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)

if lp_open != lp_close or qp_open != qp_close:
    print("\n  \033[31mTag mismatch — aborting build\033[0m")
    exit(1)
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}✓ Language switching deployed. Click a flag → instant update.${NC}\n"
