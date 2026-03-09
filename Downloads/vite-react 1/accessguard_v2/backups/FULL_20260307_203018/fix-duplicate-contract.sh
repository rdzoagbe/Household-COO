#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
echo -e "\n${BLUE}Fixing duplicate ContractComparisonPage...${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 - << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

# Find ALL occurrences of ContractComparisonPage function declarations
occ = [m.start() for m in re.finditer(r'\nfunction ContractComparisonPage\(\)', app)]
print(f"  Found {len(occ)} ContractComparisonPage declaration(s)")

if len(occ) <= 1:
    print("  Nothing to remove — only one declaration")
else:
    # Remove ALL but the LAST one (newest version)
    for start in reversed(occ[:-1]):
        # Find where this function ends — next top-level function or export default
        search_from = start + 10
        next_fn = app.find('\nfunction ', search_from)
        next_ex = app.find('\nexport default', search_from)
        # Pick the closest one
        candidates = [x for x in [next_fn, next_ex] if x != -1]
        end = min(candidates) if candidates else len(app)
        removed_lines = app[start:end].count('\n')
        app = app[:start] + app[end:]
        print(f"  ✓  Removed duplicate at char {start} ({removed_lines} lines)")

    # Verify
    remaining = len(re.findall(r'\nfunction ContractComparisonPage\(\)', app))
    print(f"  Remaining declarations: {remaining}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print(f"  Done — {app.count(chr(10))} lines")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}✓ Done! Duplicate removed and deployed.${NC}\n"
