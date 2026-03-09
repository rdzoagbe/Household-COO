#!/bin/bash
# ============================================================
#  SaasGuard — 9/10 Upgrade: Backup + Deploy
#  1. Put this script + App.jsx in Downloads folder
#  2. cp "/c/Users/TheKwekuRO/Downloads/upgrade-pages.sh" .
#  3. bash upgrade-pages.sh
# ============================================================
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗"
echo -e "║  SaasGuard — 9/10 Upgrade: Backup + Build + Deploy         ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}Error: run from your project root${NC}" && exit 1
[ ! -f "src/App.jsx"  ] && echo -e "${RED}Error: src/App.jsx not found${NC}" && exit 1

# ── STEP 1: Full backup ────────────────────────────────────
TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/FULL_$TS"
mkdir -p "$BACKUP_DIR"
echo -e "${BLUE}Step 1/4 — Backing up current project...${NC}"
[ -d "src" ]    && cp -r src    "$BACKUP_DIR/src"
[ -d "public" ] && cp -r public "$BACKUP_DIR/public"
for f in package.json vite.config.js vite.config.ts tailwind.config.js postcss.config.js firebase.json .firebaserc index.html .env .env.local; do
  [ -f "$f" ] && cp "$f" "$BACKUP_DIR/$f"
done
for sh in *.sh; do [ -f "$sh" ] && cp "$sh" "$BACKUP_DIR/$sh"; done
echo -e "${GREEN}  ✓ Backup saved → $BACKUP_DIR/${NC}\n"

# ── STEP 2: Copy fixed App.jsx ─────────────────────────────
echo -e "${BLUE}Step 2/4 — Copying fixed App.jsx from Downloads...${NC}"
FIXED="/c/Users/TheKwekuRO/Downloads/App.jsx"
[ ! -f "$FIXED" ] && echo -e "${RED}Error: App.jsx not found in Downloads${NC}" && exit 1
cp "$FIXED" src/App.jsx
echo -e "${GREEN}  ✓ App.jsx copied to src/App.jsx${NC}\n"

# ── STEP 3: Build ──────────────────────────────────────────
echo -e "${BLUE}Step 3/4 — Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || {
  echo -e "${RED}Build failed — restoring backup${NC}"
  cp -r "$BACKUP_DIR/src" src
  exit 1
}
echo -e "${GREEN}  ✓ Build complete${NC}\n"

# ── STEP 4: Deploy ─────────────────────────────────────────
echo -e "${BLUE}Step 4/4 — Deploying to Firebase...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗"
echo -e "║  9/10 Upgrade Live ✓                                        ║"
echo -e "╠══════════════════════════════════════════════════════════════╣"
echo -e "║  ✓ Auth modal subtitle fixed                                 ║"
echo -e "║  ✓ Book a Demo email fixed (nexusiq.io removed)              ║"
echo -e "║  ✓ How It Works raw t() call removed                        ║"
echo -e "║  ✓ Security page hosting fixed (GCP, not AWS)                ║"
echo -e "║  ✓ Company logos — styled pill chips                         ║"
echo -e "║  ✓ G2 + SOC2 + GDPR trust badges in hero                    ║"
echo -e "║  ✓ Instant Live Demo button in nav (no sign-up)              ║"
echo -e "║  ✓ Auth modal Try Live Demo more prominent                   ║"
echo -e "║  ✓ 4 testimonials with specific, credible quotes             ║"
echo -e "║  ✓ FAQ security answer detailed + trustworthy                ║"
echo -e "║  ✓ Full enterprise Security/Trust Centre page                ║"
echo -e "║  ✓ Footer Security link fixed → /security-info               ║"
echo -e "╠══════════════════════════════════════════════════════════════╣"
echo -e "║  Backup: $BACKUP_DIR/      ║"
echo -e "║  Revert: cp -r $BACKUP_DIR/src src                          ║"
echo -e "║          npm run build && firebase deploy --only hosting     ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"
