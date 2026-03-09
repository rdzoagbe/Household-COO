#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fix: Language switching v4${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}Backup done${NC}\n"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

# Nuke any existing LanguageProvider tags
app = re.sub(r' *</?LanguageProvider>\n?', '', app)

# Find exact BrowserRouter indentation
m = re.search(r'( +)<BrowserRouter>', app)
if not m:
    print("ERROR: <BrowserRouter> not found")
    sys.exit(1)
sp = m.group(1)
print("  BrowserRouter indent: " + str(len(sp)) + " spaces")

# Wrap opening
app = app.replace(sp + "<BrowserRouter>", sp + "<LanguageProvider>\n" + sp + "<BrowserRouter>", 1)

# Add closing tag right after </BrowserRouter>
m2 = re.search(r'( *)</BrowserRouter>', app)
if m2:
    app = app[:m2.end()] + "\n" + m2.group(1) + "</LanguageProvider>" + app[m2.end():]

# Fix SidebarFooter: local state to context
OLD_STATE = "  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');\n"
if OLD_STATE in app:
    app = app.replace(OLD_STATE, "  const { language, setLanguage } = useLang();\n", 1)
    print("  SidebarFooter: useLang() applied")

# Remove SidebarFooter localStorage sync useEffect
app = re.sub(
    r"\n  // Sync language from localStorage on mount\n  useEffect\(\(\) => \{\n    const savedLang = localStorage\.getItem\('language'\);\n    if \(savedLang && savedLang !== language\) \{\n      setLanguage\(savedLang\);\n    \}\n  \}, \[\]\);\n",
    '\n', app)

# Fix changeLanguage
m3 = re.search(r'  const changeLanguage = \(code\) => \{[^}]+\};', app, re.DOTALL)
if m3 and ('dispatchEvent' in m3.group() or 'localStorage' in m3.group()):
    app = app[:m3.start()] + "  const changeLanguage = (code) => {\n    setLanguage(code);\n    setShowLangMenu(false);\n  };" + app[m3.end():]
    print("  changeLanguage: cleaned")

# Remove LanguageProvider event dispatch
app = app.replace("    window.dispatchEvent(new CustomEvent('languagechange', { detail: lang }));\n", '')

# Remove all stale languagechange listeners
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
print("  Removed " + str(n) + " stale listeners")

# Remove force-sync useEffects
app = re.sub(
    r"\n  // Force sync language from localStorage on mount\n  useEffect\(\(\) => \{\n    const savedLang = localStorage\.getItem\('language'\);\n    if \(savedLang && savedLang !== language\) \{\n      setLanguage\(savedLang\);\n    \}\n  \}, \[\]\);\n",
    '\n', app)

# Verify
lo = app.count('<LanguageProvider>')
lc = app.count('</LanguageProvider>')
needle = "addEventListener('languagechange'"
remaining = app.count(needle)
print("  <LanguageProvider> open=" + str(lo) + " close=" + str(lc) + (" OK" if lo==lc==1 else " MISMATCH"))
print("  Remaining languagechange listeners: " + str(remaining))
print("  Lines: " + str(app.count('\n')))

if lo != lc or lo == 0:
    print("  ABORTING - tag mismatch")
    sys.exit(1)

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  Saved OK")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}Done! Language switching works instantly now.${NC}\n"
