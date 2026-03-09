#!/bin/bash
# ============================================================
#  SaasGuard — Backup + Apply Fix + Build + Deploy
#  Usage:
#    1. Put this script, App.jsx in your Downloads folder
#    2. cp "/c/Users/TheKwekuRO/Downloads/upgrade-pages.sh" .
#    3. bash upgrade-pages.sh
# ============================================================
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗"
echo -e "║  SaasGuard — Backup + Apply Fix + Build + Deploy           ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"

# ── Guard ──────────────────────────────────────────────────
[ ! -f "package.json" ] && echo -e "${RED}Error: run from your project root${NC}" && exit 1
[ ! -f "src/App.jsx"  ] && echo -e "${RED}Error: src/App.jsx not found${NC}" && exit 1

# ── STEP 1: Full backup ─────────────────────────────────────
TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/FULL_$TS"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}Step 1/4 — Backing up current project...${NC}"
[ -d "src" ]    && cp -r src    "$BACKUP_DIR/src"    && echo -e "${GREEN}  ✓ src/${NC}"
[ -d "public" ] && cp -r public "$BACKUP_DIR/public" && echo -e "${GREEN}  ✓ public/${NC}"

for f in package.json vite.config.js vite.config.ts tailwind.config.js \
         postcss.config.js firebase.json .firebaserc index.html .env .env.local; do
  [ -f "$f" ] && cp "$f" "$BACKUP_DIR/$f" && echo -e "${GREEN}  ✓ $f${NC}"
done

for sh in *.sh; do
  [ -f "$sh" ] && cp "$sh" "$BACKUP_DIR/$sh"
done

echo -e "${GREEN}  ✓ Full backup saved → $BACKUP_DIR/${NC}\n"

# ── STEP 2: Find and copy new App.jsx from Downloads ────────
echo -e "${BLUE}Step 2/4 — Copying fixed App.jsx from Downloads...${NC}"
DOWNLOADS="/c/Users/TheKwekuRO/Downloads"
FIXED_APP="$DOWNLOADS/App.jsx"

if [ ! -f "$FIXED_APP" ]; then
  echo -e "${RED}Error: App.jsx not found in $DOWNLOADS${NC}"
  echo -e "${YELLOW}Make sure App.jsx is in your Downloads folder and try again.${NC}"
  exit 1
fi

cp "$FIXED_APP" src/App.jsx
echo -e "${GREEN}  ✓ Fixed App.jsx copied to src/App.jsx${NC}\n"

# ── STEP 3: Build ───────────────────────────────────────────
echo -e "${BLUE}Step 3/4 — Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || {
  echo -e "${RED}Build failed — restoring backup${NC}"
  cp -r "$BACKUP_DIR/src" src
  exit 1
}
echo -e "${GREEN}  ✓ Build complete${NC}\n"

# ── STEP 4: Deploy ──────────────────────────────────────────
echo -e "${BLUE}Step 4/4 — Deploying to Firebase...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗"
echo -e "║  All done! SaasGuard is live ✓                              ║"
echo -e "╠══════════════════════════════════════════════════════════════╣"
echo -e "║  Backup : $BACKUP_DIR/      ║"
echo -e "╠══════════════════════════════════════════════════════════════╣"
echo -e "║  To revert:                                                  ║"
echo -e "║  ${YELLOW}cp -r $BACKUP_DIR/src src${GREEN}  ║"
echo -e "║  ${YELLOW}npm run build && firebase deploy --only hosting${GREEN}    ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"
