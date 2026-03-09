#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fixing language auto-switch...${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 - << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []; warn = []

# ── 1. LanguageProvider: remove the event dispatch entirely ──
# The context IS the single source of truth — no event needed.
# All pages use useLang() → useTranslation(language) so they
# re-render automatically when context state changes.
old_lp = (
    "  const setAndPersist = React.useCallback((lang) => {\n"
    "    localStorage.setItem('language', lang);\n"
    "    setLanguage(lang);\n"
    "    window.dispatchEvent(new CustomEvent('languagechange', { detail: lang }));\n"
    "  }, []);\n"
)
new_lp = (
    "  const setAndPersist = React.useCallback((lang) => {\n"
    "    localStorage.setItem('language', lang);\n"
    "    setLanguage(lang);\n"
    "  }, []);\n"
)
if old_lp in app:
    app = app.replace(old_lp, new_lp, 1)
    ok.append("LanguageProvider: removed redundant event dispatch")
elif "window.dispatchEvent(new CustomEvent('languagechange'" in app:
    # Generic removal of the dispatch line inside setAndPersist
    app = re.sub(
        r"    window\.dispatchEvent\(new CustomEvent\('languagechange', \{ detail: lang \}\)\);\n",
        "", app, count=1
    )
    ok.append("LanguageProvider: removed dispatch (alt match)")
else:
    ok.append("LanguageProvider: already clean (no dispatch)")

# ── 2. SidebarFooter changeLanguage: use ONLY context setter ─
# Must not duplicate dispatch or localStorage — context handles both.
# Pattern: find the changeLanguage function and replace its body.
old_cl = re.search(
    r"  const changeLanguage = \(code\) => \{[^}]+\};",
    app, re.DOTALL
)
new_cl = (
    "  const changeLanguage = (code) => {\n"
    "    setLanguage(code);  // Updates context → all pages re-render instantly\n"
    "    setShowLangMenu(false);\n"
    "  };"
)
if old_cl:
    app = app[:old_cl.start()] + new_cl + app[old_cl.end():]
    ok.append("SidebarFooter: changeLanguage now uses context setter only")
else:
    warn.append("SidebarFooter: changeLanguage pattern not found")

# ── 3. Remove ALL stale languagechange useEffect listeners ───
# These are the cause of the infinite loop AND they bypass the
# context, causing inconsistent state. Since all pages read from
# useLang() context, these effects are completely unnecessary.
stale_inner = (
    "    const handleLangChange = (e) => {\n"
    "      const newLang = e.detail || localStorage.getItem('language') || 'en';\n"
    "      setLanguage(newLang);\n"
    "    };\n"
    "    window.addEventListener('languagechange', handleLangChange);\n"
    "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
    "  }, []);\n"
)
count = 0
while stale_inner in app:
    idx = app.find(stale_inner)
    # Walk back to find opening of useEffect block
    ue = app.rfind('\n  useEffect(() => {\n', 0, idx)
    # Also remove comment above it if present
    cm = app.rfind('\n  //', 0, ue)
    start = cm if cm != -1 and ue - cm < 80 else ue
    app = app[:start] + '\n' + app[idx + len(stale_inner):]
    count += 1
if count:
    ok.append(f"Removed {count} stale languagechange useEffect(s)")

# ── 4. Remove Sidebar force-sync useEffect ───────────────────
force = (
    "\n  // Force sync language from localStorage on mount\n"
    "  useEffect(() => {\n"
    "    const savedLang = localStorage.getItem('language');\n"
    "    if (savedLang && savedLang !== language) {\n"
    "      setLanguage(savedLang);\n"
    "    }\n"
    "  }, []);\n"
)
if force in app:
    app = app.replace(force, '\n')
    ok.append("Sidebar: removed force-sync useEffect")

# ── 5. Ensure SidebarFooter has setLanguage from useLang ─────
# Find SidebarFooter function and verify it destructures setLanguage
sf_idx = app.find('function SidebarFooter(')
sf_end = app.find('\nfunction ', sf_idx + 10)
sf_body = app[sf_idx:sf_end]

if 'setLanguage' not in sf_body:
    # It only has language — add setLanguage to destructure
    app = app.replace(
        'const { language } = useLang();\n',
        'const { language, setLanguage } = useLang();\n',
        1  # only first match (in SidebarFooter)
    ) if 'function SidebarFooter' in app else app
    ok.append("SidebarFooter: added setLanguage to useLang destructure")
else:
    ok.append("SidebarFooter: setLanguage already destructured")

# ── 6. Ensure Sidebar itself does NOT hold setLanguage ───────
# Sidebar only reads language for t() — it doesn't change it
# SidebarFooter (child) handles the changing
sb_idx = app.find('function Sidebar(')
sb_end = app.find('\nfunction ', sb_idx + 10)
sb_body = app[sb_idx:sb_end]
if '{ language, setLanguage }' in sb_body:
    # Replace with read-only destructure in Sidebar
    new_sb = sb_body.replace(
        'const { language, setLanguage } = useLang();',
        'const { language } = useLang();'
    )
    app = app[:sb_idx] + new_sb + app[sb_end:]
    ok.append("Sidebar: removed unneeded setLanguage (read-only)")

# ── Report ────────────────────────────────────────────────────
print()
for s in ok:   print(f"  \033[32m✓\033[0m  {s}")
for s in warn: print(f"  \033[33m!\033[0m  {s}")

# ── Verify no remaining language-related issues ───────────────
remaining_dispatch = app.count("dispatchEvent(new CustomEvent('languagechange'")
remaining_listeners = app.count("addEventListener('languagechange'")
print(f"\n  Event dispatches remaining: {remaining_dispatch}")
print(f"  Event listeners remaining:  {remaining_listeners}")
print(f"  File lines: {app.count(chr(10))}")

if remaining_dispatch == 0 and remaining_listeners == 0:
    print(f"  \033[32m✓ Clean — pure React context, zero event bus\033[0m")
else:
    print(f"  \033[33m! Some event wiring remains — check manually\033[0m")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
echo -e "║  ✓ Language switching fixed and deployed!                ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  HOW IT WORKS NOW                                        ║"
echo -e "║  User clicks language → SidebarFooter calls              ║"
echo -e "║  setLanguage(code) from useLang() context →             ║"
echo -e "║  React re-renders every component that reads            ║"
echo -e "║  useLang() or useTranslation(language) →                ║"
echo -e "║  All pages update instantly, no page reload needed      ║"
echo -e "║                                                          ║"
echo -e "║  Root cause of previous infinite loop:                  ║"
echo -e "║  Context setter dispatched an event → listeners called  ║"
echo -e "║  setLanguage again → infinite re-render loop            ║"
echo -e "║  Fixed: event bus removed, pure React context only      ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
