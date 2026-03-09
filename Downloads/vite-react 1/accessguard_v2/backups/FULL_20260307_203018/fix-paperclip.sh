#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fixing Paperclip icon reference...${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"

python3 - << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

fixes = 0

# 1. Replace all Paperclip icon usages with Upload (already imported)
count = app.count('Paperclip')
app = app.replace('Paperclip', 'Upload')
if count:
    print(f"  \033[32m✓\033[0m  Replaced {count} Paperclip → Upload")
    fixes += count

# 2. Replace ArrowLeftRight with RefreshCw if still missing
if 'ArrowLeftRight' in app:
    # Check if it's imported
    luc_end = app.find('} from "lucide-react"')
    imported_block = app[:luc_end]
    if 'ArrowLeftRight' not in imported_block:
        app = app.replace('ArrowLeftRight', 'RefreshCw')
        print(f"  \033[32m✓\033[0m  Replaced ArrowLeftRight → RefreshCw")
        fixes += 1
    else:
        print(f"  ✓  ArrowLeftRight already imported")

# 3. Replace Bot with Sparkles if not imported
if 'Bot' in app:
    luc_end = app.find('} from "lucide-react"')
    if 'Bot' not in app[:luc_end]:
        app = app.replace('<Bot ', '<Sparkles ').replace('<Bot\n', '<Sparkles\n')
        print(f"  \033[32m✓\033[0m  Replaced Bot → Sparkles")
        fixes += 1

# 4. Replace Send with MessageCircle if not imported  
if 'Send' in app:
    luc_end = app.find('} from "lucide-react"')
    if 'Send' not in app[:luc_end]:
        app = app.replace('<Send ', '<MessageCircle ').replace('<Send\n', '<MessageCircle\n')
        print(f"  \033[32m✓\033[0m  Replaced Send → MessageCircle")
        fixes += 1

# 5. Add any truly missing icons to imports
needed = []
luc_end = app.find('} from "lucide-react"')
imported_block = app[:luc_end]

# Check each icon used in ContractComparisonPage
cp_idx = app.rfind('function ContractComparisonPage()')  # last occurrence
if cp_idx != -1:
    cp_end = app.find('\nexport default', cp_idx)
    cp_body = app[cp_idx:cp_end]
    used = set(re.findall(r'<([A-Z][a-zA-Z]+)\s', cp_body))
    for icon in used:
        if icon not in imported_block and icon not in ['AppShell','Card','CardHeader','CardBody','Button','Pill','Select','Textarea','EmptyState','SkeletonRow']:
            needed.append(icon)

if needed:
    print(f"  ! Still missing icons: {needed}")
    # Add them
    app = app.replace(
        '  MessageCircle,\n} from "lucide-react"',
        '  MessageCircle,\n  ' + ',\n  '.join(needed) + ',\n} from "lucide-react"'
    )
    print(f"  \033[32m✓\033[0m  Added: {', '.join(needed)}")

print(f"\n  Total fixes: {fixes}")
print(f"  File lines: {app.count(chr(10))}")

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
echo -e "\n${GREEN}✓ Fixed and deployed!${NC}\n"
