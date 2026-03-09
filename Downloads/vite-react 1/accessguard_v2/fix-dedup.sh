#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fix: remove duplicate reviewedApps declaration then rebuild${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8', errors='replace') as f:
    app = f.read()

# Remove the second (duplicate) declaration — keep only the first
DUP = '  const [reviewedApps, setReviewedApps] = useState([]);\n'
first = app.find(DUP)
second = app.find(DUP, first + 1)
if second != -1:
    app = app[:second] + app[second + len(DUP):]
    print("  Removed duplicate reviewedApps declaration")
else:
    print("  No duplicate found — already clean")

# Also deduplicate any other doubled state lines just in case
for state in ['selectedInvoice', 'showInvoiceDetail']:
    pat = f'  const [{state},'
    if app.count(pat) > 1:
        idx = app.find(pat)
        second = app.find(pat, idx+1)
        line_end = app.find('\n', second) + 1
        app = app[:second] + app[line_end:]
        print(f"  Removed duplicate {state} declaration")

print(f"  Lines: {app.count(chr(10))}")
with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  Saved ✓")
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}Done! Everything is live.${NC}\n"
