#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}Fixing build errors + stack overflow...${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 - << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []; warn = []

# ── 1. Remove stale languagechange listeners (all variants) ──
# Pattern: remove the full useEffect block including the comment above it
patterns = [
    # With comment
    "\n  // Auto-update when language changes (no reload needed!)\n"
    "  useEffect(() => {\n"
    "    const handleLangChange = (e) => {\n"
    "      const newLang = e.detail || localStorage.getItem('language') || 'en';\n"
    "      setLanguage(newLang);\n"
    "    };\n"
    "    window.addEventListener('languagechange', handleLangChange);\n"
    "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
    "  }, []);\n",
    # Without comment
    "\n  useEffect(() => {\n"
    "    const handleLangChange = (e) => {\n"
    "      const newLang = e.detail || localStorage.getItem('language') || 'en';\n"
    "      setLanguage(newLang);\n"
    "    };\n"
    "    window.addEventListener('languagechange', handleLangChange);\n"
    "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
    "  }, []);\n",
]
total_removed = 0
for pat in patterns:
    count = app.count(pat)
    if count:
        app = app.replace(pat, '\n')
        total_removed += count
ok.append(f"Removed {total_removed} stale languagechange listener(s)")

# ── 2. Remove Sidebar force-sync useEffect ────────────────────
force_sync = (
    "\n  // Force sync language from localStorage on mount\n"
    "  useEffect(() => {\n"
    "    const savedLang = localStorage.getItem('language');\n"
    "    if (savedLang && savedLang !== language) {\n"
    "      setLanguage(savedLang);\n"
    "    }\n"
    "  }, []);\n"
)
if force_sync in app:
    app = app.replace(force_sync, '\n')
    ok.append("Removed Sidebar force-sync useEffect")

# ── 3. Fix SidebarFooter changeLanguage ──────────────────────
old_change = (
    "  const changeLanguage = (code) => {\n"
    "    localStorage.setItem('language', code);\n"
    "    setShowLangMenu(false);\n"
    "    // Reload current page (not dashboard)\n"
    "    \n"
    "    setLanguage(code);\n"
    "    window.dispatchEvent(new CustomEvent('languagechange', { detail: code }));\n"
    "  };\n"
)
new_change = (
    "  const changeLanguage = (code) => {\n"
    "    setLanguage(code);\n"
    "    setShowLangMenu(false);\n"
    "  };\n"
)
if old_change in app:
    app = app.replace(old_change, new_change, 1)
    ok.append("SidebarFooter: changeLanguage uses context only")
else:
    warn.append("changeLanguage: pattern not matched exactly")

# ── 4. Remove duplicate ContractComparisonPage ───────────────
# Keep only the LAST occurrence (newest/most complete version)
occurrences = [m.start() for m in re.finditer(r'\nfunction ContractComparisonPage\(\)', app)]
if len(occurrences) > 1:
    # Remove all but the last
    for start in reversed(occurrences[:-1]):
        # Find the end of this function
        next_fn = app.find('\nfunction ', start + 10)
        if next_fn == -1:
            next_fn = app.find('\nexport default', start + 10)
        app = app[:start] + app[next_fn:]
    ok.append(f"Removed {len(occurrences)-1} duplicate ContractComparisonPage declaration(s)")
elif len(occurrences) == 1:
    ok.append("ContractComparisonPage: single declaration (no duplicates)")
else:
    warn.append("ContractComparisonPage not found")

# ── 5. Add contracts to NAV array ─────────────────────────────
old_nav_end = "  { to: \"/invoices\", label: \"invoices\", icon: Upload },\n];"
new_nav_end = (
    "  { to: \"/invoices\", label: \"invoices\", icon: Upload },\n"
    "  { separator: true, label: \"Contracts\" },\n"
    "  { to: \"/contracts\", label: \"contracts\", icon: FileText },\n"
    "];"
)
if old_nav_end in app and '{ to: "/contracts"' not in app[app.find('const NAV'):app.find('];', app.find('const NAV'))]:
    app = app.replace(old_nav_end, new_nav_end, 1)
    ok.append("NAV: /contracts added")
elif '{ to: "/contracts"' in app:
    ok.append("NAV: /contracts already present")
else:
    warn.append("NAV: could not add /contracts")

# ── 6. Add /contracts route if missing ───────────────────────
if '<ContractComparisonPage />' not in app:
    old_route = '          <Route path="*" element={<NotFound />} />'
    new_route = (
        '          <Route\n'
        '            path="/contracts"\n'
        '            element={<RequireAuth><ContractComparisonPage /></RequireAuth>}\n'
        '          />\n'
        '          <Route path="*" element={<NotFound />} />'
    )
    app = app.replace(old_route, new_route, 1)
    ok.append("Router: /contracts route added")
else:
    ok.append("Router: /contracts route already present")

# ── 7. Ensure FileDiff / ArrowLeftRight imported ─────────────
if 'ArrowLeftRight' not in app:
    app = app.replace(
        '  MessageCircle,\n} from "lucide-react"',
        '  MessageCircle,\n  ArrowLeftRight,\n  FileDiff,\n} from "lucide-react"'
    )
    ok.append("Icons: ArrowLeftRight, FileDiff added")

# ── Report ────────────────────────────────────────────────────
print()
for s in ok:   print(f"  \033[32m✓\033[0m  {s}")
for s in warn: print(f"  \033[33m!\033[0m  {s}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print(f"\n  Done — {app.count(chr(10))} lines")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# translations.js — add contracts key
python3 - << 'PYEOF'
import os
path = 'src/translations.js'
if not os.path.exists(path): exit()
with open(path, encoding='utf-8') as f: src = f.read()
KEYS = {'en':'Contracts','es':'Contratos','fr':'Contrats','de':'Verträge','ja':'契約管理'}
for lang, val in KEYS.items():
    ls = src.find(f'{lang}: {{')
    le = src.find('\n  },', ls)
    if '    contracts:' not in src[ls:le]:
        ins = src.find('\n', src.find(f'{lang}: {{')) + 1
        src = src[:ins] + f"    contracts: '{val}',\n" + src[ins:]
        print(f"  \033[32m✓\033[0m  {lang}: contracts key added")
with open(path, 'w', encoding='utf-8') as f: f.write(src)
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}✓ Done! Stack overflow fixed, Contracts page working.${NC}\n"
