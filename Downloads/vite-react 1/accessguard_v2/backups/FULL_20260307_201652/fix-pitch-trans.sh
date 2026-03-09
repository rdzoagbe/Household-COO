#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fix: Translation keys + build${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
[ -f "src/translations.js" ] && cp src/translations.js "backups/$TS/translations.js"
echo -e "${GREEN}Backup done${NC}\n"

python3 << 'PYEOF'
import re, sys

# ── Fix App.jsx: remove the bad injected lines ─────────────────
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

# Remove malformed injection that caused the build error
BAD_INJECT = re.search(
    r'\n\s*cost_management: \'Cost Management\',\n\s*analytics: \'Analytics\',\n\s*settings: \'Settings\',\n\s*contracts: \'Contracts\',\}',
    app
)
if BAD_INJECT:
    app = app[:BAD_INJECT.start()] + app[BAD_INJECT.end()-1:]  # keep the closing }
    print("  App.jsx: removed bad injected translation lines")
    with open('src/App.jsx', 'w', encoding='utf-8') as f:
        f.write(app)
else:
    print("  App.jsx: no bad injection found (already clean)")

# ── Fix translations.js: add missing keys to EN block cleanly ──
trans_path = 'src/translations.js'
if not __import__('os').path.exists(trans_path):
    print("  translations.js not found — skipping")
    sys.exit(0)

with open(trans_path, 'r', encoding='utf-8') as f:
    t = f.read()

NEW_KEYS = {
    'cost_management': 'Cost Management',
    'analytics':       'Analytics',
    'settings':        'Settings',
    'contracts':       'Contracts',
    'security':        'Security',
    'access':          'Access Map',
    'wrench':          'Settings',
}

# Find the EN block specifically — it's the first language block
en_start = t.find('  en: {')
en_end   = t.find('\n  },', en_start)  # first },  after en: {

if en_start == -1 or en_end == -1:
    print("  Could not find EN block in translations.js")
    sys.exit(1)

en_block = t[en_start:en_end]
added = []
for key, val in NEW_KEYS.items():
    if key + ':' not in en_block:
        t = t[:en_end] + "\n    " + key + ": '" + val + "'," + t[en_end:]
        en_end += len("\n    " + key + ": '" + val + "',")
        added.append(key)

if added:
    with open(trans_path, 'w', encoding='utf-8') as f:
        f.write(t)
    print("  translations.js EN: added " + ", ".join(added))
else:
    print("  translations.js: all keys already present")

print("  Done")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}Done! NexusIQ is live.${NC}\n"
