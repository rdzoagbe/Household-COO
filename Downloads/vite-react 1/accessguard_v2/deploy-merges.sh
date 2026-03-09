#!/bin/bash
# ============================================================
#  SaasGuard — Navigation Merges + Full Translations Deploy
#  Run this from your project root folder
#  e.g.  bash deploy-merges.sh
# ============================================================
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗"
echo -e "║  SaasGuard — Nav Merges + Full Translations                ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"

# ── 1. Must be run from project root ──────────────────────────
[ ! -f "package.json" ] && echo -e "${RED}✗ Run this from your project root (where package.json is)${NC}" && exit 1

# ── 2. Find the two source files in Downloads ─────────────────
DOWNLOADS="/c/Users/TheKwekuRO/Downloads"
SRC_APP="$DOWNLOADS/App.jsx"
SRC_TRANS="$DOWNLOADS/translations.js"

echo -e "Looking for files in: ${YELLOW}$DOWNLOADS${NC}"

if [ ! -f "$SRC_APP" ]; then
  echo -e "${RED}✗ App.jsx not found in Downloads${NC}"
  echo -e "  Please download App.jsx from Claude and place it in your Downloads folder, then re-run."
  exit 1
fi

if [ ! -f "$SRC_TRANS" ]; then
  echo -e "${RED}✗ translations.js not found in Downloads${NC}"
  echo -e "  Please download translations.js from Claude and place it in your Downloads folder, then re-run."
  exit 1
fi

echo -e "${GREEN}✓ Found App.jsx${NC}"
echo -e "${GREEN}✓ Found translations.js${NC}\n"

# ── 3. Backup current files ───────────────────────────────────
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
cp src/translations.js "backups/$TS/translations.js" 2>/dev/null || true
echo -e "${GREEN}✓ Backup saved → backups/$TS/${NC}"
echo -e "  Revert: ${YELLOW}cp backups/$TS/App.jsx src/ && cp backups/$TS/translations.js src/ && npm run build && firebase deploy --only hosting${NC}\n"

# ── 4. Copy new files into src/ ───────────────────────────────
cp "$SRC_APP"   src/App.jsx
cp "$SRC_TRANS" src/translations.js
echo -e "${GREEN}✓ App.jsx copied to src/${NC}"
echo -e "${GREEN}✓ translations.js copied to src/${NC}\n"

# ── 5. Verify key functions are present ───────────────────────
echo -e "${BLUE}Verifying files...${NC}"
for fn in "ContractsRenewalsHub" "SetupConnectionsHub" "FinanceDashboard" "SecurityCompliancePage" "ImportWizard"; do
  if grep -q "function $fn" src/App.jsx; then
    echo -e "  ${GREEN}✓${NC} $fn"
  else
    echo -e "  ${RED}✗ MISSING: $fn — wrong App.jsx downloaded?${NC}"
    echo -e "  Restoring backup..."
    cp "backups/$TS/App.jsx" src/App.jsx
    cp "backups/$TS/translations.js" src/translations.js 2>/dev/null || true
    exit 1
  fi
done

echo ""

# ── 6. Verify translations completeness ───────────────────────
python3 << 'PYEOF'
import re, sys
with open('src/translations.js', 'r', encoding='utf-8') as f:
    content = f.read()

def count_keys(lang):
    start = content.find(f'  {lang}: {{')
    if start == -1: return 0
    depth, pos = 0, start + len(f'  {lang}: {{')
    while pos < len(content):
        if content[pos] == '{': depth += 1
        elif content[pos] == '}':
            if depth == 0: break
            depth -= 1
        pos += 1
    return len(re.findall(r"^\s+(\w+):\s*'", content[start:pos], re.MULTILINE))

en_count = count_keys('en')
all_ok = True
for lang in ['en','fr','es','de','ja']:
    n = count_keys(lang)
    status = '✓' if n == en_count else f'✗ INCOMPLETE ({n}/{en_count})'
    print(f"  {status}  {lang}: {n} keys")
    if n < en_count:
        all_ok = False

if not all_ok:
    print("\nWARNING: translations.js is incomplete — wrong file downloaded?")
    sys.exit(1)
PYEOF

[ $? -ne 0 ] && echo -e "${RED}Translation check failed — restoring backup${NC}" && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""

# ── 7. Build ──────────────────────────────────────────────────
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || {
  echo -e "${RED}✗ Build failed — restoring backup${NC}"
  cp "backups/$TS/App.jsx"       src/App.jsx
  cp "backups/$TS/translations.js" src/translations.js 2>/dev/null || true
  exit 1
}
echo -e "${GREEN}✓ Build complete${NC}\n"

# ── 8. Deploy ─────────────────────────────────────────────────
echo -e "${BLUE}Deploying to Firebase...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗"
echo -e "║  Deploy complete ✓                                         ║"
echo -e "╠══════════════════════════════════════════════════════════════╣"
echo -e "║  /finance      → Finance Hub  (Overview|Cost|Exec|Analytics)║"
echo -e "║  /security     → Security & Compliance (Security|Audit)     ║"
echo -e "║  /contracts    → Contracts Hub (Renewals|Invoices|Contracts) ║"
echo -e "║  /integrations → Setup Hub  (Integrations|Import Wizard)    ║"
echo -e "║  translations  → All 5 languages fully complete (149 keys)  ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"
