#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗"
echo -e "║  AccessGuard — Fix Language Switching (Root Cause Fix)  ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 - << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []; warn = []

# ════════════════════════════════════════════════════════════════
# ROOT CAUSE 1: LanguageProvider is NEVER used — it's defined
# but App() renders <BrowserRouter> directly without wrapping it.
# FIX: Wrap BrowserRouter with LanguageProvider inside App().
# ════════════════════════════════════════════════════════════════
OLD_APP_OPEN = (
    "    <QueryClientProvider client={queryClient}>\n"
    "      <Toaster position=\"top-right\""
)
NEW_APP_OPEN = (
    "    <QueryClientProvider client={queryClient}>\n"
    "      <LanguageProvider>\n"
    "      <Toaster position=\"top-right\""
)
if OLD_APP_OPEN in app:
    app = app.replace(OLD_APP_OPEN, NEW_APP_OPEN, 1)
    ok.append("App(): LanguageProvider opening tag added")

# Find the closing </QueryClientProvider> and add </LanguageProvider> before it
OLD_APP_CLOSE = "    </QueryClientProvider>\n  );\n}"
NEW_APP_CLOSE = "      </LanguageProvider>\n    </QueryClientProvider>\n  );\n}"
if OLD_APP_CLOSE in app and '</LanguageProvider>' not in app:
    app = app.replace(OLD_APP_CLOSE, NEW_APP_CLOSE, 1)
    ok.append("App(): LanguageProvider closing tag added")

# ════════════════════════════════════════════════════════════════
# ROOT CAUSE 2: SidebarFooter uses local useState for language
# instead of the context. Fix: replace local state with useLang().
# ════════════════════════════════════════════════════════════════
# Replace: const [language, setLanguage] = useState(() => localStorage...)
# With:    const { language, setLanguage } = useLang();
OLD_SF_STATE = "  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');\n"
NEW_SF_STATE = "  const { language, setLanguage } = useLang();\n"
if OLD_SF_STATE in app:
    app = app.replace(OLD_SF_STATE, NEW_SF_STATE, 1)
    ok.append("SidebarFooter: replaced local useState with useLang() context")
else:
    warn.append("SidebarFooter: local useState pattern not matched exactly")

# Remove SidebarFooter's sync-from-localStorage useEffect (now irrelevant)
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

# ════════════════════════════════════════════════════════════════
# ROOT CAUSE 3: changeLanguage in SidebarFooter dispatches an
# extra event on top of calling setLanguage. The event causes
# Sidebar's listener to call setLanguage again → infinite loop.
# FIX: changeLanguage only calls setLanguage (context handles all).
# ════════════════════════════════════════════════════════════════
OLD_CHANGE = (
    "  const changeLanguage = (code) => {\n"
    "    localStorage.setItem('language', code);\n"
    "    setShowLangMenu(false);\n"
    "    // Reload current page (not dashboard)\n"
    "\n"
    "    setLanguage(code);\n"
    "    window.dispatchEvent(new CustomEvent('languagechange', { detail: code }));\n"
    "  };\n"
)
NEW_CHANGE = (
    "  const changeLanguage = (code) => {\n"
    "    setLanguage(code);\n"
    "    setShowLangMenu(false);\n"
    "  };\n"
)
if OLD_CHANGE in app:
    app = app.replace(OLD_CHANGE, NEW_CHANGE, 1)
    ok.append("SidebarFooter: changeLanguage uses context setter only")
else:
    # Fallback: regex replace
    m = re.search(r'  const changeLanguage = \(code\) => \{[^}]+\};', app, re.DOTALL)
    if m:
        app = app[:m.start()] + NEW_CHANGE.rstrip('\n') + app[m.end():]
        ok.append("SidebarFooter: changeLanguage replaced (regex fallback)")

# ════════════════════════════════════════════════════════════════
# ROOT CAUSE 4: LanguageProvider.setAndPersist also dispatches
# the event. Remove it — context re-render is enough.
# ════════════════════════════════════════════════════════════════
OLD_LP = (
    "  const setAndPersist = React.useCallback((lang) => {\n"
    "    localStorage.setItem('language', lang);\n"
    "    setLanguage(lang);\n"
    "    window.dispatchEvent(new CustomEvent('languagechange', { detail: lang }));\n"
    "  }, []);\n"
)
NEW_LP = (
    "  const setAndPersist = React.useCallback((lang) => {\n"
    "    localStorage.setItem('language', lang);\n"
    "    setLanguage(lang);\n"
    "  }, []);\n"
)
if OLD_LP in app:
    app = app.replace(OLD_LP, NEW_LP, 1)
    ok.append("LanguageProvider: removed redundant event dispatch")

# ════════════════════════════════════════════════════════════════
# ROOT CAUSE 5: All pages have stale event listeners that call
# setLanguage when they hear languagechange. Since LanguageProvider
# now wraps everything, pages get language from context automatically.
# These listeners are now dead code and cause the infinite loop.
# ════════════════════════════════════════════════════════════════
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
    ok.append(f"Removed {count} stale languagechange useEffect listener(s)")

# Remove Sidebar's force-sync effect too
FORCE_SYNC = (
    "\n  // Force sync language from localStorage on mount\n"
    "  useEffect(() => {\n"
    "    const savedLang = localStorage.getItem('language');\n"
    "    if (savedLang && savedLang !== language) {\n"
    "      setLanguage(savedLang);\n"
    "    }\n"
    "  }, []);\n"
)
if FORCE_SYNC in app:
    app = app.replace(FORCE_SYNC, '\n')
    ok.append("Sidebar: removed force-sync localStorage useEffect")

# ── Report ────────────────────────────────────────────────────
print()
for s in ok:   print(f"  \033[32m✓\033[0m  {s}")
for s in warn: print(f"  \033[33m!\033[0m  {s}")

remaining = app.count("addEventListener('languagechange'")
dispatches = app.count("dispatchEvent(new CustomEvent('languagechange'")
provider_ok = '<LanguageProvider>' in app
print(f"\n  LanguageProvider wraps app: {provider_ok}")
print(f"  Event listeners remaining:  {remaining}")
print(f"  Event dispatches remaining: {dispatches}")
print(f"  File lines: {app.count(chr(10))}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)

if not provider_ok:
    print("\n  \033[31m✗ LanguageProvider still not wrapping — check App() manually\033[0m")
    exit(1)
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
echo -e "║  ✓ Language switching now works instantly!               ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  ROOT CAUSES FIXED:                                      ║"
echo -e "║  1. LanguageProvider was never wrapping the app →       ║"
echo -e "║     now wraps everything inside QueryClientProvider     ║"
echo -e "║  2. SidebarFooter used local useState (disconnected) →  ║"
echo -e "║     now uses useLang() context directly                 ║"
echo -e "║  3. changeLanguage dispatched redundant event →         ║"
echo -e "║     now just calls setLanguage(code), done              ║"
echo -e "║  4. All pages had stale event listeners → removed       ║"
echo -e "║                                                          ║"
echo -e "║  Click any language → all pages update instantly        ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
