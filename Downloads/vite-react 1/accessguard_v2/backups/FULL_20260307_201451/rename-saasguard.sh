#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
echo -e "\n${BLUE}Renaming NexusIQ → SaasGuard sitewide${NC}\n"
[ ! -f "package.json" ] && echo "Run from project root" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
[ -f src/translations.js ] && cp src/translations.js "backups/$TS/translations.js"

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8', errors='replace') as f:
    app = f.read()

# Count before
before = app.count('NexusIQ')
print(f"  NexusIQ occurrences: {before}")

# Core rename
app = app.replace('NexusIQ', 'SaasGuard')

# Fix email addresses that got renamed
app = app.replace('sales@saasguard.io', 'sales@saasguard.io')  # already correct
app = app.replace('support@saasguard.io', 'support@saasguard.io')
app = app.replace('finance@saasguard.io', 'finance@saasguard.io')
app = app.replace('it@saasguard.io', 'it@saasguard.io')

# Fix the gradient wordmark — update text
app = app.replace(
    '>NexusIQ<',
    '>SaasGuard<'
)

# Fix logo SVG title if any
app = app.replace('NexusIQ Security Whitepaper', 'SaasGuard Security Whitepaper')

# Fix any URL slugs / page titles
app = app.replace('Welcome to NexusIQ', 'Welcome to SaasGuard')

after = app.count('NexusIQ')
print(f"  Renamed: {before - after} occurrences → SaasGuard")
print(f"  Remaining NexusIQ: {after}")
if after > 0:
    for m in re.finditer('NexusIQ', app):
        lno = app[:m.start()].count('\n') + 1
        print(f"    L{lno}: {app[m.start()-30:m.start()+50].replace(chr(10),' ')[:80]}")

print(f"  Lines: {app.count(chr(10))}")
with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  Saved ✓")
PYEOF

# Fix translations.js
python3 << 'PYEOF'
import os, sys
tp = 'src/translations.js'
if not os.path.exists(tp): sys.exit(0)
with open(tp, 'r', encoding='utf-8', errors='replace') as f:
    t = f.read()
before = t.count('NexusIQ')
t = t.replace('NexusIQ', 'SaasGuard')
with open(tp, 'w', encoding='utf-8') as f:
    f.write(t)
print(f"  translations.js: {before} occurrences renamed ✓")
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}Done — site is now SaasGuard throughout.${NC}\n"
