#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fix: Language switching v3${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}Backup done${NC}\n"

python3 - << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

# ── 1. Nuke every existing LanguageProvider tag — start clean ──
app = re.sub(r'\s*<LanguageProvider>\n?', '\n', app)
app = re.sub(r'\s*</LanguageProvider>\n?', '\n', app)
print(f"  After cleanup — open:{app.count('<LanguageProvider>')} close:{app.count('</LanguageProvider>')}")

# ── 2. Wrap BrowserRouter with LanguageProvider ───────────────
OLD = "      <BrowserRouter>"
NEW = "      <LanguageProvider>\n      <BrowserRouter>"
assert OLD in app, "BrowserRouter not found!"
app = app.replace(OLD, NEW, 1)

OLD2 = "      </BrowserRouter>\n    </QueryClientProvider>"
NEW2 = "      </BrowserRouter>\n      </LanguageProvider>\n    </QueryClientProvider>"
assert OLD2 in app, "BrowserRouter closing not found!"
app = app.replace(OLD2, NEW2, 1)

# ── 3. SidebarFooter: local state → context ───────────────────
OLD3 = "  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');\n"
if OLD3 in app:
    app = app.replace(OLD3, "  const { language, setLanguage } = useLang();\n", 1)
    print("  SidebarFooter: useLang() applied")

# ── 4. Remove SidebarFooter localStorage sync ─────────────────
app = re.sub(
    r"\n  // Sync language from localStorage on mount\n"
    r"  useEffect\(\(\) => \{\n"
    r"    const savedLang = localStorage\.getItem\('language'\);\n"
    r"    if \(savedLang && savedLang !== language\) \{\n"
    r"      setLanguage\(savedLang\);\n"
    r"    \}\n"
    r"  \}, \[\]\);\n",
    '\n', app
)

# ── 5. Fix changeLanguage ─────────────────────────────────────
m = re.search(r'  const changeLanguage = \(code\) => \{[^}]+\};', app, re.DOTALL)
if m and ('dispatchEvent' in m.group() or 'localStorage' in m.group()):
    app = app[:m.start()] + "  const changeLanguage = (code) => {\n    setLanguage(code);\n    setShowLangMenu(false);\n  };" + app[m.end():]
    print("  changeLanguage: cleaned")

# ── 6. Remove LanguageProvider event dispatch ─────────────────
app = app.replace("    window.dispatchEvent(new CustomEvent('languagechange', { detail: lang }));\n", '')

# ── 7. Remove all stale listeners ────────────────────────────
STALE = (
    "    const handleLangChange = (e) => {\n"
    "      const newLang = e.detail || localStorage.getItem('language') || 'en';\n"
    "      setLanguage(newLang);\n"
    "    };\n"
    "    window.addEventListener('languagechange', handleLangChange);\n"
    "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
    "  }, []);\n"
)
n = 0
while STALE in app:
    idx = app.find(STALE)
    ue = app.rfind('\n  useEffect(() => {\n', 0, idx)
    cm = app.rfind('\n  //', 0, ue)
    start = cm if cm != -1 and ue - cm < 80 else ue
    app = app[:start] + '\n' + app[idx + len(STALE):]
    n += 1
print(f"  Removed {n} stale listeners")

# ── 8. Remove force-sync useEffects ──────────────────────────
app = re.sub(
    r"\n  // Force sync language from localStorage on mount\n"
    r"  useEffect\(\(\) => \{\n"
    r"    const savedLang = localStorage\.getItem\('language'\);\n"
    r"    if \(savedLang && savedLang !== language\) \{\n"
    r"      setLanguage\(savedLang\);\n"
    r"    \}\n"
    r"  \}, \[\]\);\n",
    '\n', app
)

# ── Verify ────────────────────────────────────────────────────
lo = app.count('<LanguageProvider>')
lc = app.count('</LanguageProvider>')
print(f"  <LanguageProvider> open={lo} close={lc} {'OK' if lo==lc else 'MISMATCH'}")
print(f"  Remaining event listeners: {app.count('addEventListener')}")
print(f"  Lines: {app.count(chr(10))}")

assert lo == lc, f"Tag mismatch: {lo} open, {lc} close"

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  File saved OK")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}Done! Click a language flag — page updates instantly.${NC}\n"
