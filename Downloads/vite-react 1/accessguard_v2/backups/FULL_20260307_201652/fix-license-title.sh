#!/bin/bash
set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}Fixing LicenseManagement title...${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

old = '<h1 className="text-4xl font-black mb-2">📜 License Management</h1>'
new = '<h1 className="text-4xl font-black mb-2">{t(\'licenses\') || "License Management"}</h1>'

if new in src:
    print("  ✅  Already translated")
elif old in src:
    src = src.replace(old, new, 1)
    print("  ✅  Title translated")
else:
    print("  ❌  Pattern not found"); import sys; sys.exit(1)

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(src)
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }
firebase deploy --only hosting
echo -e "\n${GREEN}✓ Done!${NC}\n"
